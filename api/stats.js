export default async function handler() {
    const guild_id = "1355796182143598804";

    const response = await fetch(
        `https://discord.com/api/v10/guilds/${guild_id}/widget.json?with_counts=true`
    );

    if (!response.ok) {
        // widget likely disabled in Discord server settings, or bad guild id
        return Response.json({
            total_executions: 0,
            active_users: 0,
            api_status: "Operational",
            discord_community: {}
        });
    }

    const discord_community = await response.json();

    return Response.json({
        total_executions: 0,
        active_users: 0,
        api_status: "Operational",
        discord_community
    });
}