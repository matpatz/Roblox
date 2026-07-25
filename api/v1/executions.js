import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { validateString } from '../_lib/validate.js';

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request body');

  const identifier = validateString(body.identifier, 'identifier', { min: 1, max: 255 });

  const supabase = getSupabase();

  const { data, error } = await supabase
    .from('identifiers')
    .insert({ identifier })
    .select()
    .single();

  if (error) {
    console.error('Supabase insert error:', error);
    throw new ApiError(500, 'Failed to save execution');
  }

  const { data: row } = await supabase
    .from('totals')
    .select('total_executions')
    .eq('id', 1)
    .single();

  const newTotal = (row?.total_executions || 0) + 1;
  await supabase
    .from('totals')
    .upsert({ id: 1, total_executions: newTotal });

  return successResponse(res, req, { id: data.id, identifier: data.identifier }, 201);
}

export { handler_fn as handler };
