import { handler, successResponse, paginatedResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { parsePagination, rateLimit } from '../_lib/validate.js';

export const config = { runtime: 'nodejs' };

function sanitizeSearch(s) {
  return s.replace(/[,().]/g, '');
}

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req.headers['x-forwarded-for'] || 'unknown', { limit: 30, window: 60 });


  const { page, limit, offset } = parsePagination(req.query);
  const search = sanitizeSearch(req.query.search || '');
  const tag = req.query.tag || '';
  const supabase = getSupabase();

  let query = supabase
    .from('scripts')
    .select('*', { count: 'exact' });

  if (search) {
    query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
  }
  if (tag) {
    query = query.contains('tags', [tag]);
  }

  query = query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  const { data, error, count } = await query;
  if (error) throw new ApiError(500, 'Failed to fetch');

  return paginatedResponse(res, req, { data: data || [], total: count || 0, page, limit });
}

export { handler_fn as handler };
