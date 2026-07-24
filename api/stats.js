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
            `https://discord.com/api/v10/guilds/${guild_id}/widget.json?with_counts=true`,
            { signal: controller.signal }
        );
        clearTimeout(timeout);
        if (response.ok) {
            discord_community = await response.json();
        }
    } catch (e) {}

    let total_executions = 0;
    let active_users = 0;
    let execution_history = [];

    try {
        const { count } = await supabase
            .from('identifiers')
            .select('*', { count: 'exact', head: true });
        total_executions = count || 0;
    } catch (e) {}

    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const { data: recent } = await supabase
            .from('identifiers')
            .select('created_at')
            .gte('created_at', sevenDaysAgo.toISOString());

        if (recent) {
            const counts = {};
            for (let i = 6; i >= 0; i--) {
                const d = new Date();
                d.setDate(d.getDate() - i);
                const key = d.toISOString().slice(0, 10);
                counts[key] = 0;
            }
            recent.forEach(function(row) {
                const day = row.created_at.slice(0, 10);
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
            .gte('created_at', thirtyDaysAgo.toISOString());
        if (users) {
            const unique = new Set(users.map(function(u) { return u.identifier; }));
            active_users = unique.size;
        }
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
