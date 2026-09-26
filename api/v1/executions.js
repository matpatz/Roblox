import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { validateString, rateLimit } from '../_lib/validate.js';
import { createHash } from 'crypto';

export const config = { runtime: 'nodejs' };

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 20, window: 60 });

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

  const raw = validateString(body.identifier, 'identifier', { min: 1, max: 150 });
  const identifier = createHash('sha256').update(raw).digest('hex');
  const supabase = getSupabase();

  const { data, error } = await supabase
    .from('identifiers')
    .insert({ identifier })
    .select('id')
    .single();

  if (error) {
    console.error('Insert failed:', error.message);
    throw new ApiError(500, 'Failed to save');
  }

  // No counter call here on purpose. `totals.total_executions` is bumped by the
  // identifiers_bump_totals trigger, so the counter is an invariant of the table
  // itself. The old `supabase.rpc('increment_executions')` was fire-and-forget --
  // when the RPC stopped resolving in production the number froze at 1512 while
  // ~3k executions/day kept being logged, and nothing ever reported it.
  // See supabase-executions-counter.sql.

  return successResponse(res, req, { id: data.id }, 201);
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
