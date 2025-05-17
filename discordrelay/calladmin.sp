#define PLUGIN_NAME "Discord Relay"

float g_fCallAdminLastUsed[MAXPLAYERS + 1];

public Action Command_CallAdmin(int client, int args)
{
    // Use admin webhook if set, otherwise fallback to RCON webhook
    if (!g_cvServerToDiscord.BoolValue || g_sAdminWebhook[0] == '\0')
    {
        ReplyToCommand(client, "[%s] Discord relay is not enabled or webhook is not set.", PLUGIN_NAME);
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[%s] Usage: sm_calladmin <reason>", PLUGIN_NAME);
        return Plugin_Handled;
    }

    // Individual cooldown check
    if (client > 0 && client <= MaxClients)
    {
        float now = GetEngineTime();
        if (g_fCallAdminLastUsed[client] > 0.0 && (now - g_fCallAdminLastUsed[client]) < g_fCallAdminCooldown)
        {
            int seconds = RoundToCeil(g_fCallAdminCooldown - (now - g_fCallAdminLastUsed[client]));
            ReplyToCommand(client, "[%s] Please wait %d seconds before using sm_calladmin again.", PLUGIN_NAME, seconds);
            return Plugin_Handled;
        }
        g_fCallAdminLastUsed[client] = now;
    }

    char msg[256];
    GetCmdArgString(msg, sizeof(msg));
    // Remove the command itself from the message
    int cmdlen = strlen("sm_calladmin");
    if (strncmp(msg, "sm_calladmin", cmdlen, false) == 0)
    {
        // Remove command and leading space
        strcopy(msg, sizeof(msg), msg[cmdlen]);
        TrimString(msg);
    }

    char name[MAX_NAME_LENGTH];
    char avatar[256];
    int userid = client ? GetClientUserId(client) : 0;
    if (IsValidClient(client))
    {
        Format(name, sizeof(name), "%N", client);
        strcopy(avatar, sizeof(avatar), g_Players[userid].AvatarURL);
    }
    else
    {
        strcopy(name, sizeof(name), "CONSOLE");
        avatar[0] = '\0';
    }

    DiscordWebHook hook = new DiscordWebHook(g_sAdminWebhook);
    hook.SetUsername(name);

    // Mention admin role outside the embed for proper ping
    char mention[128];
    if (g_sAdminRole[0])
        Format(mention, sizeof(mention), "-# <@&%s>", g_sAdminRole);
    else
        mention[0] = '\0';
    if (mention[0])
        hook.SetContent(mention);

    DiscordEmbed embed = new DiscordEmbed();
    embed.SetColor(g_sServerMessageColor);

    char title[128];
    Format(title, sizeof(title), "%T", "Player Report Title", LANG_SERVER, title);

    // Set embed title as the first field (DiscordEmbedField)
    embed.AddField(new DiscordEmbedField(title, "", false));

    // Description as another field (Player Report)
    char desc[256];
    Format(desc, sizeof(desc), "%T", "Player Report", LANG_SERVER, name, g_Players[userid].SteamID64);
    embed.AddField(new DiscordEmbedField("", desc, false));

    // Reason field
    char reasonTitle[64];
    Format(reasonTitle, sizeof(reasonTitle), "%T", "Player Report Reason", LANG_SERVER, msg);
    embed.AddField(new DiscordEmbedField(reasonTitle, msg, false));

    hook.SetAvatar(avatar);
    hook.Embed(embed);

    hook.Send();
    delete hook;

    ReplyToCommand(client, "[%s] Admins have been notified on Discord.", PLUGIN_NAME);
    return Plugin_Handled;
}