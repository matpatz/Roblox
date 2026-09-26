import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';
import { kv } from '@vercel/kv';

export const config = { runtime: 'nodejs' };

const CACHE_KEY = 'stats:cache';
const CACHE_TTL = 60;
// discord.gg code linked on the home page (src/frontend/index.html) — keep in sync.
const DISCORD_INVITE = 'bSPRYhBGtf';
const PAGE_SIZE = 1000;
const FETCH_CONCURRENCY = 10;
const ACTIVE_USERS_DAYS = 30;
const HISTORY_DAYS = 7;

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

function daysAgo(days) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - days);
  return d;
}

function hoursAgo(hours) {
  return new Date(Date.now() - hours * 60 * 60 * 1000);
}

// PostgREST hard-caps a plain select at 1000 rows (db-max-rows), so any window
// that can exceed that must be paged. This walks every row with `added_at >=
// since`, calling `consume(rows)` once per page. Pages are fetched in parallel
// batches; ordering by (added_at, id) keeps page boundaries stable so no row is
// skipped or double-counted across concurrent queries.
async function walkIdentifiers(supabase, since, columns, consume) {
  let from = 0;
  for (;;) {
    const offsets = [];
    for (let i = 0; i < FETCH_CONCURRENCY; i++) offsets.push(from + i * PAGE_SIZE);
    const pages = await Promise.all(offsets.map((offset) =>
      supabase
        .from('identifiers')
        .select(columns)
        .gte('added_at', since)
        .order('added_at', { ascending: true })
        .order('id', { ascending: true })
        .range(offset, offset + PAGE_SIZE - 1)
    ));

    for (const { data, error } of pages) {
      if (error || !data) return;
      consume(data);
      if (data.length < PAGE_SIZE) return;
    }
    from += FETCH_CONCURRENCY * PAGE_SIZE;
  }
}

async function countActiveUsers(supabase, since) {
  const seen = new Set();
  await walkIdentifiers(supabase, since, 'identifier', (rows) => {
    for (const row of rows) seen.add(row.identifier);
  });
  return seen.size;
}

async function buildExecutionHistory(supabase, startUtcMidnight) {
  const counts = {};
  for (let i = HISTORY_DAYS - 1; i >= 0; i--) {
    const day = new Date(startUtcMidnight);
    day.setUTCDate(day.getUTCDate() + i);
    counts[day.toISOString().slice(0, 10)] = 0;
  }
  await walkIdentifiers(supabase, startUtcMidnight.toISOString(), 'added_at', (rows) => {
    for (const row of rows) {
      const day = toUtcDay(row.added_at);
      if (day in counts) counts[day]++;
    }
  });
  return Object.entries(counts).map(([date, count]) => ({ date, count }));
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 20, window: 60 });

  const cached = await kv.get(CACHE_KEY);
  if (cached) return successResponse(res, req, cached);

  const supabase = getSupabase();

  const thirtyDaysAgo = daysAgo(ACTIVE_USERS_DAYS);
  const oneHourAgo = hoursAgo(1);

  // 7-day window aligned to UTC midnight so the query range exactly covers the
  // same UTC dates used by the history buckets, regardless of server TZ.
  const now = new Date();
  const sevenDaysAgo = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - (HISTORY_DAYS - 1)));

  const [discordResult, totalsResult, activeResult, hourlyResult, historyResult] = await Promise.allSettled([
    // The public invite endpoint returns approximate member/presence counts with
    // no auth. The old /guilds/{id} call needed a bot token and showed 0 whenever
    // BOT_TOKEN was unset/invalid.
    fetch(`https://discord.com/api/v10/invites/${DISCORD_INVITE}?with_counts=true`, {
      headers: { 'User-Agent': 'VoltexStats/1.0 (voltex.website)' }
    }).then((r) => (r.ok ? r.json() : null)).catch(() => null),
    supabase.from('totals').select('total_executions').eq('id', 1).single(),
    countActiveUsers(supabase, thirtyDaysAgo.toISOString()),
    supabase.from('identifiers').select('*', { count: 'exact', head: true })
      .gte('added_at', oneHourAgo.toISOString()),
    buildExecutionHistory(supabase, sevenDaysAgo)
  ]);

  const discord = discordResult.status === 'fulfilled' ? discordResult.value : null;

  const payload = {
    total_executions: totalsResult.status === 'fulfilled' ? totalsResult.value?.data?.total_executions ?? 0 : 0,
    active_users: activeResult.status === 'fulfilled' && typeof activeResult.value === 'number' ? activeResult.value : 0,
    executions_last_hour: hourlyResult.status === 'fulfilled' ? hourlyResult.value?.count ?? 0 : 0,
    api_status: 'Operational',
    discord_community: {
      presence_count: discord?.approximate_presence_count ?? 0,
      member_count: discord?.approximate_member_count ?? 0
    },
    execution_history: historyResult.status === 'fulfilled' && Array.isArray(historyResult.value) ? historyResult.value : []
  };

  await kv.set(CACHE_KEY, payload, { ex: CACHE_TTL });

  return successResponse(res, req, payload);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
