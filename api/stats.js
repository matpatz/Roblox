import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SECRET_KEY
);

export default async function handler(req, res) {
    const guild_id = "1355796182143598804";
    let discord_community = {};

    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);
        const response = await fetch(
            `https://discord.com/api/v10/guilds/${guild_id}?with_counts=true`,
            {
                signal: controller.signal,
                headers: { Authorization: `Bot ${process.env.BOT_TOKEN}` }
            }
        );
        clearTimeout(timeout);
        if (response.ok) {
            const data = await response.json();
            discord_community = {
                presence_count: data.approximate_presence_count || 0,
                member_count: data.approximate_member_count || 0
            };
        }
    } catch (e) {}

    let total_executions = 0;
    let active_users = 0;
    let execution_history = [];

    try {
        const { data: row } = await supabase
            .from('totals')
            .select('total_executions')
            .eq('id', 1)
            .single();
        total_executions = row?.total_executions || 0;
    } catch (e) {}

    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const { data: recent } = await supabase
            .from('identifiers')
            .select('added_at')
            .gte('added_at', sevenDaysAgo.toISOString());

        if (recent) {
            const counts = {};
            for (let i = 6; i >= 0; i--) {
                const d = new Date();
                d.setDate(d.getDate() - i);
                const key = d.toISOString().slice(0, 10);
                counts[key] = 0;
            }
            recent.forEach(function(row) {
                const day = row.added_at.slice(0, 10);
                if (counts[day] !== undefined) counts[day]++;
            });
            execution_history = Object.keys(counts).map(function(day) {
                return { date: day, count: counts[day] };
            });
        }
    } catch (e) {}

    try {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const { data: users } = await supabase
            .from('identifiers')
            .select('identifier')
            .gte('added_at', thirtyDaysAgo.toISOString());
        if (users) {
            const unique = new Set(users.map(function(u) { return u.identifier; }));
            active_users = unique.size;
        }
    } catch (e) {}

    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        await supabase
            .from('identifiers')
            .delete()
            .lt('added_at', sevenDaysAgo.toISOString());
    } catch (e) {}

    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate");
    return res.status(200).json({
        total_executions,
        active_users,
        api_status: "Operational",
        discord_community,
        execution_history
    });
}
