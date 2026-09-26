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

// PostgREST caps a plain select at 1000 rows (db-max-rows), even when a larger
// limit is requested. The 7-day window can exceed that, which silently drops the
// newest executions. Fetch in pages so the whole window is returned.
async function fetchWindowAddedAt(supabase, sinceIso) {
  const rows = [];
  const PAGE = 1000;
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from('identifiers')
      .select('added_at')
      .gte('added_at', sinceIso)
      .range(from, from + PAGE - 1);
    if (error || !data) break;
    rows.push(...data);
    if (data.length < PAGE) break;
    from += PAGE;
  }
  return rows;
}

// Same cap applies to the 30-day "active users" window, but there we need the
// DISTINCT identifier count, not the raw rows. Paging the whole window serially
// would be ~50 round-trips once the table grows past a few days, so fetch pages
// concurrently. Ordering by (added_at, id) keeps page boundaries stable across
// concurrent queries; without a deterministic order a row could land in two
// pages or none and the count would drift.
async function fetchActiveUsers(supabase, sinceIso) {
  const seen = new Set();
  const PAGE = 1000;
  const CONCURRENCY = 10;
  let from = 0;
  for (;;) {
    const offsets = [];
    for (let i = 0; i < CONCURRENCY; i++) offsets.push(from + i * PAGE);
    const results = await Promise.all(offsets.map((o) =>
      supabase
        .from('identifiers')
        .select('identifier')
        .gte('added_at', sinceIso)
        .order('added_at', { ascending: true })
        .order('id', { ascending: true })
        .range(o, o + PAGE - 1)
    ));
    let done = false;
    for (const { data, error } of results) {
      if (error || !data) { done = true; break; }
      for (const row of data) seen.add(row.identifier);
      if (data.length < PAGE) { done = true; break; }
    }
    if (done) break;
    from += CONCURRENCY * PAGE;
  }
  return seen.size;
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 20, window: 60 });

  const cached = await kv.get(CACHE_KEY);
  if (cached) return successResponse(res, req, cached);

  const supabase = getSupabase();
  // Invite code from the home page (discord.gg/bSPRYhBGtf). The public invite
  // endpoint returns approximate_member_count / approximate_presence_count with
  // no auth, unlike /guilds/{id} which needs a bot token and silently 401s
  // whenever BOT_TOKEN is unset/invalid (the stat showed 0 for this reason).
  const discordInvite = 'bSPRYhBGtf';

  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const oneHourAgo = new Date();
  oneHourAgo.setHours(oneHourAgo.getHours() - 1);

  // 7-day window aligned to UTC midnight so the query range exactly covers the
  // same UTC dates used by the history buckets below, regardless of server TZ.
  const now = new Date();
  const sevenDaysAgo = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 6));

  const [discordResult, totalsResult, activeResult, hourlyResult, historyResult] = await Promise.allSettled([
    fetch(`https://discord.com/api/v10/invites/${discordInvite}?with_counts=true`, {
      headers: { 'User-Agent': 'VoltexStats/1.0 (voltex.website)' }
    }).then(r => r.ok ? r.json() : null),
    supabase.from('totals').select('total_executions').eq('id', 1).single(),
    fetchActiveUsers(supabase, thirtyDaysAgo.toISOString()),
    supabase.from('identifiers').select('*', { count: 'exact', head: true })
      .gte('added_at', oneHourAgo.toISOString()),
    fetchWindowAddedAt(supabase, sevenDaysAgo.toISOString())
  ]);

  const discordCommunity = discordResult.status === 'fulfilled' && discordResult.value
    ? { presence_count: discordResult.value.approximate_presence_count || 0, member_count: discordResult.value.approximate_member_count || 0 }
    : { presence_count: 0, member_count: 0 };

  const totalExecutions = totalsResult.status === 'fulfilled' ? totalsResult.value?.data?.total_executions || 0 : 0;

  const activeUsers = activeResult.status === 'fulfilled' && typeof activeResult.value === 'number'
    ? activeResult.value
    : 0;

  const executionsLastHour = hourlyResult.status === 'fulfilled' ? hourlyResult.value?.count || 0 : 0;

  let executionHistory = [];
  if (historyResult.status === 'fulfilled' && historyResult.value?.length) {
    const counts = {};
    for (let i = 6; i >= 0; i--) {
      const day = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - i));
      counts[day.toISOString().slice(0, 10)] = 0;
    }
    for (const row of historyResult.value) {
      const day = toUtcDay(row.added_at);
      if (day in counts) counts[day]++;
    }
    executionHistory = Object.entries(counts).map(([date, count]) => ({ date, count }));
  }

  const payload = {
    total_executions: totalExecutions,
    active_users: activeUsers,
    executions_last_hour: executionsLastHour,
    api_status: 'Operational',
    discord_community: discordCommunity,
    execution_history: executionHistory
  };

  await kv.set(CACHE_KEY, payload, { ex: CACHE_TTL });

  return successResponse(res, req, payload);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
