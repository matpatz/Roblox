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

    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate");
    return res.status(200).json({
        total_executions: 0,
        active_users: 0,
        api_status: "Operational",
        discord_community
    });
}