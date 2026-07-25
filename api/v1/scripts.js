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
    const tag = req.query.tag || '';

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
    if (error) throw new ApiError(500, 'Failed to fetch scripts');

    return paginatedResponse(res, req, { data: data || [], total: count || 0, page, limit });
  }

  if (req.method === 'POST') {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

    const title = validateString(body.title, 'title', { min: 1, max: 100 });
    const description = validateString(body.description, 'description', { min: 1, max: 500 });
    const loadstring = validateString(body.loadstring, 'loadstring', { min: 1 });
    const rawUrl = body.rawUrl ? validateString(body.rawUrl, 'rawUrl') : null;
    const tags = Array.isArray(body.tags) ? body.tags : [];
    const buttonText = body.buttonText || 'Copy Loadstring';
    const updated = body.updated || 'just now';

    const { data, error } = await supabase
      .from('scripts')
      .insert({
        title,
        description,
        loadstring,
        raw_url: rawUrl,
        tags,
        button_text: buttonText,
        updated
      })
      .select()
      .single();

    if (error) throw new ApiError(500, 'Failed to create script');
    return successResponse(res, req, data, 201);
  }

  throw new ApiError(405, 'Method not allowed');
}

export { handler_fn as handler };
