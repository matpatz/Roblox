import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { validateString } from '../_lib/validate.js';

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'POST') throw new ApiError(405, 'Method not allowed');

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  if (!body || typeof body !== 'object') throw new ApiError(400, 'Invalid request');

  const identifier = validateString(body.identifier, 'identifier', { min: 1, max: 255 });
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

  await supabase.rpc('increment_executions').catch(() => {
    return supabase.from('totals').upsert({ id: 1, total_executions: 1 });
  });

  return successResponse(res, req, { id: data.id }, 201);
}

export { handler_fn as handler };
