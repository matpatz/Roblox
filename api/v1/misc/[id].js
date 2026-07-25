import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { validateString } from '../_lib/validate.js';

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  const { id } = req.query;
  if (!id) throw new ApiError(400, 'Missing misc item id');

  const supabase = getSupabase();

  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('misc')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) throw new ApiError(404, 'Misc item not found');
    return successResponse(res, req, data);
  }

  if (req.method === 'PUT') {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

    const updates = {};
    if (body.title !== undefined) updates.title = validateString(body.title, 'title', { min: 1, max: 100 });
    if (body.description !== undefined) updates.description = validateString(body.description, 'description', { min: 1, max: 500 });
    if (body.snippet !== undefined) updates.snippet = body.snippet ? validateString(body.snippet, 'snippet') : null;
    if (body.rawUrl !== undefined) updates.raw_url = body.rawUrl ? validateString(body.rawUrl, 'rawUrl') : null;
    if (body.buttonText !== undefined) updates.button_text = body.buttonText;
    updates.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('misc')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new ApiError(500, 'Failed to update misc item');
    if (!data) throw new ApiError(404, 'Misc item not found');
    return successResponse(res, req, data);
  }

  if (req.method === 'DELETE') {
    const { error } = await supabase
      .from('misc')
      .delete()
      .eq('id', id);

    if (error) throw new ApiError(500, 'Failed to delete misc item');
    return successResponse(res, req, { deleted: true });
  }

  throw new ApiError(405, 'Method not allowed');
}

export { handler_fn as handler };
