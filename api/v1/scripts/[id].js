import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { requireAdmin } from '../_lib/admin.js';
import { validateString } from '../_lib/validate.js';

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  const { id } = req.query;
  if (!id) throw new ApiError(400, 'Missing id');

  const supabase = getSupabase();

  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('scripts')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) throw new ApiError(404, 'Not found');
    return successResponse(res, req, data);
  }

  if (req.method === 'PUT') {
    requireAdmin(req);

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

    const updates = {};
    if (body.title !== undefined) updates.title = validateString(body.title, 'title', { min: 1, max: 100 });
    if (body.description !== undefined) updates.description = validateString(body.description, 'description', { min: 1, max: 500 });
    if (body.loadstring !== undefined) updates.loadstring = validateString(body.loadstring, 'loadstring', { min: 1, max: 10000 });
    if (body.rawUrl !== undefined) updates.raw_url = body.rawUrl ? validateString(body.rawUrl, 'rawUrl', { max: 2000 }) : null;
    if (body.tags !== undefined) updates.tags = Array.isArray(body.tags) ? body.tags.slice(0, 20) : [];
    if (body.buttonText !== undefined) updates.button_text = validateString(body.buttonText, 'buttonText', { max: 50 });
    if (body.updated !== undefined) updates.updated = validateString(body.updated, 'updated', { max: 50 });
    updates.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('scripts')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new ApiError(500, 'Failed to update');
    if (!data) throw new ApiError(404, 'Not found');
    return successResponse(res, req, data);
  }

  if (req.method === 'DELETE') {
    requireAdmin(req);

    const { error } = await supabase
      .from('scripts')
      .delete()
      .eq('id', id);

    if (error) throw new ApiError(500, 'Failed to delete');
    return successResponse(res, req, { deleted: true });
  }

  throw new ApiError(405, 'Method not allowed');
}

export { handler_fn as handler };
