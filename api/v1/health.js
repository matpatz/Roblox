import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';

export const config = { runtime: 'nodejs' };

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);

  const supabase = getSupabase();
  let dbOk = false;

  try {
    await supabase.from('totals').select('id').limit(1);
    dbOk = true;
  } catch {
    dbOk = false;
  }

  return successResponse(res, req, {
    status: 'ok',
    version: 'v1',
    timestamp: new Date().toISOString(),
    services: {
      api: 'operational',
      database: dbOk ? 'operational' : 'degraded'
    }
  });
}

export { handler_fn as handler };
