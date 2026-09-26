import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { getSupabase } from '../../_lib/supabase.js';
import { ApiError } from '../../_lib/errors.js';

export const config = { runtime: 'nodejs' };

// Keep only what /api/v1/stats actually reads: the 7-day execution graph and
// the top-3 scripts leaderboard both walk the last 7 days of `identifiers`.
// Anything older is dead weight (slower page walks + storage). `totals.
// total_executions` is a monotonic counter bumped by the identifiers insert
// trigger and is deliberately NOT touched, so the headline number never drops.
// This endpoint is only reachable from the Vercel cron in vercel.json, which
// sends the CRON_SECRET bearer token.
const RETENTION_DAYS = 7;

function verifyCron(req) {
  const secret = process.env.CRON_SECRET;
  if (!secret) throw new ApiError(500, 'CRON_SECRET not configured');
  if (req.headers.authorization !== `Bearer ${secret}`) {
    throw new ApiError(401, 'Unauthorized');
  }
}

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');

  verifyCron(req);

  const cutoff = new Date();
  cutoff.setUTCDate(cutoff.getUTCDate() - RETENTION_DAYS);

  const supabase = getSupabase();
  const { count, error } = await supabase
    .from('identifiers')
    .delete({ count: 'exact' })
    .lt('added_at', cutoff.toISOString());

  if (error) {
    console.error('Cleanup failed:', error.message);
    throw new ApiError(500, 'Cleanup failed');
  }

  return successResponse(res, req, {
    deleted: count ?? 0,
    cutoff: cutoff.toISOString(),
    retention_days: RETENTION_DAYS
  });
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
