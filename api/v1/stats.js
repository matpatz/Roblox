import { handler, successResponse } from '../_lib/response.js';
import { handleOptions } from '../_lib/cors.js';
import { getSupabase } from '../_lib/supabase.js';
import { ApiError } from '../_lib/errors.js';
import { rateLimit } from '../_lib/validate.js';

export const config = { runtime: 'nodejs' };

export default async function handler_fn(req, res) {
  if (req.method === 'OPTIONS') return handleOptions(req, res);
  if (req.method !== 'GET') throw new ApiError(405, 'Method not allowed');
  await rateLimit(req.headers['x-forwarded-for'] || 'unknown', { limit: 20, window: 60 });

  const supabase = getSupabase();
  const guildId = '1355796182143598804';

  let discordCommunity = { presence_count: 0, member_count: 0 };
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const response = await fetch(
      `https://discord.com/api/v10/guilds/${guildId}?with_counts=true`,
      {
        signal: controller.signal,
        headers: { Authorization: `Bot ${process.env.BOT_TOKEN}` }
      }
    );
    clearTimeout(timeout);
    if (response.ok) {
      const data = await response.json();
      discordCommunity = {
        presence_count: data.approximate_presence_count || 0,
        member_count: data.approximate_member_count || 0
      };
    }
  } catch {}

  let totalExecutions = 0;
  try {
    const { data } = await supabase
      .from('totals')
      .select('total_executions')
      .eq('id', 1)
      .single();
    totalExecutions = data?.total_executions || 0;
  } catch {}

  let activeUsers = 0;
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const { data } = await supabase
      .from('identifiers')
      .select('identifier')
      .gte('added_at', thirtyDaysAgo.toISOString())
      .range(0, 99999);
    if (data) {
      activeUsers = new Set(data.map(u => u.identifier)).size;
    }
  } catch {}

  let executionsLastHour = 0;
  try {
    const oneHourAgo = new Date();
    oneHourAgo.setHours(oneHourAgo.getHours() - 1);
    const { count } = await supabase
      .from('identifiers')
      .select('*', { count: 'exact', head: true })
      .gte('added_at', oneHourAgo.toISOString());
    executionsLastHour = count || 0;
  } catch {}

  let executionHistory = [];
  try {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);
      days.push({ date: key, start: d.toISOString(), end: next.toISOString() });
    }
    const results = await Promise.all(
      days.map(day =>
        supabase
          .from('identifiers')
          .select('*', { count: 'exact', head: true })
          .gte('added_at', day.start)
          .lt('added_at', day.end)
      )
    );
    executionHistory = days.map((day, i) => ({
      date: day.date,
      count: results[i].count || 0
    }));
  } catch {}

  return successResponse(res, req, {
    total_executions: totalExecutions,
    active_users: activeUsers,
    executions_last_hour: executionsLastHour,
    api_status: 'Operational',
    discord_community: discordCommunity,
    execution_history: executionHistory
  });
}

export { handler_fn as handler };
