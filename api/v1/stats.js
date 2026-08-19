import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';
import { kv } from '@vercel/kv';

export const config = { runtime: 'nodejs' };

const CACHE_KEY = 'stats:cache';
const CACHE_TTL = 60;

// PostgREST returns timestamptz values as ISO strings, but not necessarily in
// UTC (the offset can be +10:00, -05:00, +00, etc.). Slicing the raw string
// gives the *displayed* date, which is wrong whenever the offset isn't UTC.
// Parse the timestamp properly and return the true UTC calendar day (YYYY-MM-DD)
// so the daily buckets below stay consistent regardless of DB/server timezone.
function toUtcDay(ts) {
  let d = new Date(ts);
  if (isNaN(d.getTime())) {
    // Handle offsets written without minutes, e.g. "+00" instead of "+00:00",
    // which the JS engine won't parse on its own.
    d = new Date(String(ts).replace(/([+-]\d{2})$/, '$1:00'));
  }
  return isNaN(d.getTime()) ? String(ts).slice(0, 10) : d.toISOString().slice(0, 10);
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 20, window: 60 });

  const cached = await kv.get(CACHE_KEY);
  if (cached) return successResponse(res, req, cached);

  const supabase = getSupabase();
  const guildId = '1355796182143598804';

  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const oneHourAgo = new Date();
  oneHourAgo.setHours(oneHourAgo.getHours() - 1);

  // 7-day window aligned to UTC midnight so the query range exactly covers the
  // same UTC dates used by the history buckets below, regardless of server TZ.
  const now = new Date();
  const sevenDaysAgo = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 6));

  const [discordResult, totalsResult, activeResult, hourlyResult, historyResult] = await Promise.allSettled([
    fetch(`https://discord.com/api/v10/guilds/${guildId}?with_counts=true`, {
      headers: { Authorization: `Bot ${process.env.BOT_TOKEN}` }
    }).then(r => r.ok ? r.json() : null),
    supabase.from('totals').select('total_executions').eq('id', 1).single(),
    supabase.from('identifiers').select('identifier', { count: 'exact' })
      .gte('added_at', thirtyDaysAgo.toISOString()),
    supabase.from('identifiers').select('*', { count: 'exact', head: true })
      .gte('added_at', oneHourAgo.toISOString()),
    supabase.from('identifiers').select('added_at')
      .gte('added_at', sevenDaysAgo.toISOString())
  ]);

  const discordCommunity = discordResult.status === 'fulfilled' && discordResult.value
    ? { presence_count: discordResult.value.approximate_presence_count || 0, member_count: discordResult.value.approximate_member_count || 0 }
    : { presence_count: 0, member_count: 0 };

  const totalExecutions = totalsResult.status === 'fulfilled' ? totalsResult.value?.data?.total_executions || 0 : 0;

  const activeUsers = activeResult.status === 'fulfilled' && activeResult.value?.data
    ? new Set(activeResult.value.data.map(u => u.identifier)).size
    : 0;

  const executionsLastHour = hourlyResult.status === 'fulfilled' ? hourlyResult.value?.count || 0 : 0;

  let executionHistory = [];
  if (historyResult.status === 'fulfilled' && historyResult.value?.data) {
    const counts = {};
    for (let i = 6; i >= 0; i--) {
      const day = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - i));
      counts[day.toISOString().slice(0, 10)] = 0;
    }
    for (const row of historyResult.value.data) {
      const day = toUtcDay(row.added_at);
      if (day in counts) counts[day]++;
    }
    executionHistory = Object.entries(counts).map(([date, count]) => ({ date, count }));
  }

  // TEMP DEBUG (remove after fixing): ?debug=1 exposes raw added_at strings to
  // diagnose why recent days bucket to 0.
  let debug = null;
  try {
    if (new URL(req.url, 'http://x').searchParams.get('debug') === '1' && historyResult.status === 'fulfilled' && historyResult.value?.data) {
      const rows = historyResult.value.data;
      debug = {
        seven_days_ago: sevenDaysAgo.toISOString(),
        now_utc: new Date().toISOString(),
        total_rows: rows.length,
        samples: rows.slice(0, 10).map(r => ({ raw: r.added_at, utcDay: toUtcDay(r.added_at) }))
      };
    }
  } catch (e) { /* debug is best-effort */ }

  const payload = {
    total_executions: totalExecutions,
    active_users: activeUsers,
    executions_last_hour: executionsLastHour,
    api_status: 'Operational',
    discord_community: discordCommunity,
    execution_history: executionHistory
  };
  if (debug) payload.debug = debug;

  await kv.set(CACHE_KEY, payload, { ex: CACHE_TTL });

  return successResponse(res, req, payload);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
