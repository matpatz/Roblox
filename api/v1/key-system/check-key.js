import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { getSupabase } from '../../_lib/supabase.js';
import { ApiError } from '../../_lib/errors.js';
import { rateLimit, validateString } from '../../_lib/validate.js';

export const config = { runtime: 'nodejs' };

const KEY_RE = /^[A-Za-z0-9]{32}$/;

async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req, { limit: 30, window: 60 });

  const key = validateString(req.query?.key, 'key', { min: 32, max: 32, pattern: KEY_RE });

  const supabase = getSupabase();
  const { data: rows, error } = await supabase
    .from('keys')
    .select('key, expires_at, used, created_at')
    .ilike('key', key)
    .limit(1);

  if (error) throw new ApiError(500, 'Key lookup failed, try again');

  const row = rows && rows[0];
  if (!row) {
    return successResponse(res, req, { status: 'not_found', message: 'Key not found' });
  }

  if (row.used) {
    return successResponse(res, req, { status: 'used', message: 'Key has already been used', ...row });
  }

  if (new Date(row.expires_at).getTime() < Date.now()) {
    return successResponse(res, req, { status: 'expired', message: 'Key has expired', ...row });
  }

  return successResponse(res, req, { status: 'valid', message: 'Key is valid', ...row });
}

export default (req, res) => handler(req, res, handler_fn);
export { handler_fn as handler };
