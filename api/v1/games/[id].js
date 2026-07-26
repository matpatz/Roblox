import { handler, successResponse } from '../../_lib/response.js';
import { handleOptions } from '../../_lib/cors.js';
import { getSupabase } from '../../_lib/supabase.js';
import { ApiError } from '../../_lib/errors.js';

export const config = { runtime: 'nodejs' };

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');

  const { id } = req.query;
  if (!id) throw new ApiError(400, 'Missing id');

  const supabase = getSupabase();
  const { data, error } = await supabase
    .from('games')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !data) throw new ApiError(404, 'Not found');
  return successResponse(res, req, data);
}

export { handler_fn as handler };
