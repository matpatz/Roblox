import { handler, successResponse, paginatedResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { validateString, parsePagination } from '../_lib/validate.js';

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  const supabase = getSupabase();

  if (req.method === 'GET') {
    const { page, limit, offset } = parsePagination(req.query);
    const search = req.query.search || '';

    let query = supabase
      .from('misc')
      .select('*', { count: 'exact' });

    if (search) {
      query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data, error, count } = await query;
    if (error) throw new ApiError(500, 'Failed to fetch misc items');

    return paginatedResponse(res, req, { data: data || [], total: count || 0, page, limit });
  }

  if (req.method === 'POST') {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

    const title = validateString(body.title, 'title', { min: 1, max: 100 });
    const description = validateString(body.description, 'description', { min: 1, max: 500 });
    const snippet = body.snippet ? validateString(body.snippet, 'snippet') : null;
    const rawUrl = body.rawUrl ? validateString(body.rawUrl, 'rawUrl') : null;
    const buttonText = body.buttonText || 'Copy Snippet';

    const { data, error } = await supabase
      .from('misc')
      .insert({
        title,
        description,
        snippet,
        raw_url: rawUrl,
        button_text: buttonText
      })
      .select()
      .single();

    if (error) throw new ApiError(500, 'Failed to create misc item');
    return successResponse(res, req, data, 201);
  }

  throw new ApiError(405, 'Method not allowed');
}

export { handler_fn as handler };
