import { createClient } from '@supabase/supabase-js';

export const config = { runtime: 'edge' };

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SECRET_KEY
);

export default async function handler(request) {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405 });
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const { identifier } = body;

  if (!identifier || typeof identifier !== 'string' || !identifier.trim()) {
    return Response.json({ error: 'identifier is required and must be a non-empty string' }, { status: 400 });
  }

  const { data, error } = await supabase
    .from('identifiers')
    .insert({ identifier: identifier.trim() })
    .select()
    .single();

  if (error) {
    console.error('Supabase insert error:', error);
    return Response.json({ error: 'Failed to save identifier' }, { status: 500 });
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

  return Response.json({ success: true, data }, { status: 201 });
}
