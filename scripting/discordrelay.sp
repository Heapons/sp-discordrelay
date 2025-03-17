#include <sdkhooks>
#include <sdktools>
#include <discord>
#include <multicolors>
#include <autoexecconfig>
#undef REQUIRE_EXTENSIONS
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

#include "discordrelay/convars.sp"
#include "discordrelay/globals.sp"

#define PLUGIN_VERSION "1.4.2"

public Plugin myinfo = 
{
    name = "[ANY] Discord Relay", 
    author = "Heapons (forked from log-ical and maxijabase)", 
    description = "Discord and Server interaction", 
    version = PLUGIN_VERSION, 
    url = "https://github.com/Heapons/sp-discordrelay"    
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Late = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    SetupConvars();

    g_ChatAnnounced = false;
    g_RCONAnnounced = false;
    if (g_Late)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientPostAdminCheck(i);
            }
        }
    }

    if (g_cvDiscordToServer.BoolValue || g_cvRCONDiscordToServer.BoolValue)
    {
        CreateTimer(1.0, Timer_CreateBot);
        CreateTimer(1.0, Timer_ServerStart);
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }
    
    Player player;
    player.Load(client);
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }
    int userid = GetClientUserId(client);
    if (g_cvDisconnectMessage.BoolValue)
    {
        PrintToDiscord(userid, RED, "disconnected");
    }

    Player newPlayer;
    g_Players[userid] = newPlayer;
}

public Action OnBanClient(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }
    int userid = GetClientUserId(client);
    if (g_cvDisconnectMessage.BoolValue)
    {
        PrintToDiscord(userid, RED, "banned");
    }

    Player newPlayer;
    g_Players[userid] = newPlayer;
}

public void OnMapStart()
{
    if (!g_sDiscordWebhook[0] || g_Late)
    {
        g_Late = false;
        return;
    }
    
    CreateTimer(4.0, Timer_MapStart);
    if (g_cvDiscordToServer.BoolValue)
    {
        CreateTimer(2.0, Timer_CreateBot);
    }
}

public void OnMapEnd()
{
    // Deleting to refresh connection on map start
    if (g_Bot.IsListeningToChannelID(g_sChannelId))
    {
        g_Bot.StopListeningToChannelID(g_sChannelId);
    }
    
    if (g_Bot.IsListeningToChannelID(g_sRCONChannelId))
    {
        g_Bot.StopListeningToChannelID(g_sRCONChannelId);
    }
    
    MapEnd();
    delete g_Bot;
}

public void OnServerEnterHibernation()
{
    AnnounceToChannel(g_sDiscordWebhook, "Server is currently empty!", RED);
}

public void OnServerExitHibernation()
{
    AnnounceToChannel(g_sDiscordWebhook, "Someone joined the server!", GREEN);
}

public void OnPluginEnd()
{
    if (g_ChatAnnounced)
    {
        PrintToChannel(g_sRCONWebhook, "RCON commands relay stopped!", RED);
    }

    if (g_RCONAnnounced)
    {
        PrintToChannel(g_sDiscordWebhook, "Chat relay stopped!", RED);
    }

    OnMapEnd();
}

public Action Timer_CreateBot(Handle timer)
{
    if (!g_sDiscordBotToken[0])
    {
        LogError("Bot token not configured!");
        return Plugin_Handled;
    }

    if (g_Bot)
    {
        PrintToServer("Bot already configured, skipping...");
        return Plugin_Handled;
    }

    g_Bot = new DiscordBot(g_sDiscordBotToken);
    CreateTimer(1.0, Timer_GetGuildList, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public Action Timer_ServerStart(Handle timer)
{
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordMapChange(buffer, GREEN);
    return Plugin_Continue;
}

public Action Timer_MapStart(Handle timer)
{
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordMapChange(buffer, YELLOW);
    return Plugin_Continue;
}

public Action MapEnd()
{
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordPreviousMap(buffer, RED);
    return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
    if (g_cvHideExclamMessage.BoolValue && (!strncmp(sArgs, "/", 1)))
    {
        return;
    }

    // Replace '@' character to prevent players from mentioning in Discord
    char buffer[128];
    strcopy(buffer, sizeof(buffer), sArgs);
    if (StrContains(buffer, "@", false) != -1)
    {
        ReplaceString(buffer, sizeof(buffer), "@", "＠");
    }
    // Remove '{<color>}' string from messages to prevent color tags from being sent to Discord
    char temp[128];
    int pos = 0;
    int len = strlen(buffer);
    for (int i = 0; i < len; i++)
    {
        if (buffer[i] == '{')
        {
            while (i < len && buffer[i] != '}')
            {
                i++;
            }
        }
        else
        {
            temp[pos++] = buffer[i];
        }
    }
    temp[pos] = '\0';
    strcopy(buffer, sizeof(buffer), temp);

    PrintToDiscordSay(client ? GetClientUserId(client) : 0, buffer);
}

public void PrintToDiscord(int userid, const char[] color, const char[] msg, any...)
{
    if (!g_cvServerToDiscord.BoolValue || !g_cvMessage.BoolValue)
    {
        return;
    }

    int client = GetClientOfUserId(userid);
    
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    
    if (g_cvServerToDiscordAvatars.BoolValue)
    {
        hook.SetAvatar(g_Players[userid].AvatarURL);
    }
    
    char buffer[128];
    Format(buffer, sizeof(buffer), "%N", client);
    hook.SetUsername(buffer);
    
    DiscordEmbed Embed = new DiscordEmbed();
    Embed.SetColor(color);
    
    char playerName[512];

    if (g_Players[userid].SteamID64[0] != '\0')
    {
        Format(playerName, sizeof(playerName), "[%N](http://www.steamcommunity.com/profiles/%s)", client, g_Players[userid].SteamID64);
    }
    else
    {
        Format(playerName, sizeof(playerName), "%N", client);
    }
    
	
    Embed.AddField(new DiscordEmbedField("", playerName, true));
    Embed.AddField(new DiscordEmbedField("", msg, true));
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void PrintToDiscordSay(int userid, const char[] msg, any...)
{
    if (!g_cvServerToDiscord.BoolValue)
    {
        return;
    }

    int client = userid ? GetClientOfUserId(userid) : 0;
    char formattedMessage[256];
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    
    if (!IsValidClient(client))
    {
        if (!g_cvServerMessage.BoolValue)
        {
            return;
        }

        // If not a valid client, it must be the server
        hook.SetUsername("CONSOLE");
        Format(formattedMessage, sizeof(formattedMessage), "```%s```", msg);

        // Use embeds for server messages
        DiscordEmbed Embed = new DiscordEmbed();
        Embed.SetColor(PURPLE);
        Embed.AddField(new DiscordEmbedField("", formattedMessage, false));
        hook.Embed(Embed);
    }
    else
    {
        if (g_cvServerToDiscordAvatars.BoolValue)
        {
            hook.SetAvatar(g_Players[userid].AvatarURL);
        }

        char buffer[128];
        Format(buffer, sizeof(buffer), "%N", client);
        hook.SetUsername(buffer);
        Format(formattedMessage, sizeof(formattedMessage), "%s", msg);
        hook.SetContent(formattedMessage);
    }

    hook.Send();
    delete hook;
}

public void PrintToDiscordMapChange(const char[] map, const char[] color)
{
    if (!g_cvServerToDiscord.BoolValue || !g_cvMapChangeMessage.BoolValue)
    {
        return;
    }

    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SetUsername("Server Status");
    
    DiscordEmbed Embed = new DiscordEmbed();
    Embed.SetColor(color);

    if (g_cvShowServerName.BoolValue)
    {
        char hostname[512];
        Format(hostname, sizeof(hostname), "%s", hostname);
        FindConVar("hostname").GetString(hostname, sizeof(hostname));
        Embed.AddField(new DiscordEmbedField("Name:", hostname, false));
    }

    if (g_cvShowServerTags.BoolValue)
    {
        char sv_tags[128];
        FindConVar("sv_tags").GetString(sv_tags, sizeof(sv_tags));
        Format(sv_tags, sizeof(sv_tags), "-# `%s`", sv_tags);
        Embed.AddField(new DiscordEmbedField("Tags:", sv_tags, false));
    }
    
    char mapFastDL[512];
    if (StrContains(map, "workshop/", false) != -1)
    {
        char workshopId[2][32];
        ExplodeString(map, "/", workshopId, sizeof(workshopId), sizeof(workshopId[]));

        char mapName[2][64];
        ExplodeString(workshopId[1], ".ugc", mapName, sizeof(mapName), sizeof(mapName[]));

        Format(mapFastDL, sizeof(mapFastDL), "[%s](https://steamcommunity.com/sharedfiles/filedetails/?id=%s)", mapName[0], mapName[1]);
    }
    else
    {
        char sv_downloadurl[512];
        FindConVar("sv_downloadurl").GetString(sv_downloadurl, sizeof(sv_downloadurl));
        Format(mapFastDL, sizeof(mapFastDL), "[%s](%s/maps/%s.bsp)", map, sv_downloadurl, map);
    }
    
    Embed.AddField(new DiscordEmbedField("Current Map:", mapFastDL, true));
    
    char buffer[512];
    Format(buffer, sizeof(buffer), "%d/%d", GetOnlinePlayers(), GetMaxHumanPlayers());
    Embed.AddField(new DiscordEmbedField("Player Count:", buffer, true));
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void PrintToDiscordPreviousMap(const char[] map, const char[] color)
{
    if (!g_cvServerToDiscord.BoolValue || !g_cvMapChangeMessage.BoolValue)
    {
        return;
    }

    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SetUsername("Server Status");
    
    DiscordEmbed Embed = new DiscordEmbed();
    Embed.SetColor(color);

    if (g_cvShowServerName.BoolValue)
    {
        char hostname[512];
        Format(hostname, sizeof(hostname), "%s", hostname);
        FindConVar("hostname").GetString(hostname, sizeof(hostname));
        Embed.AddField(new DiscordEmbedField("Name:", hostname, false));
    }

    if (g_cvShowServerTags.BoolValue)
    {
        char sv_tags[128];
        FindConVar("sv_tags").GetString(sv_tags, sizeof(sv_tags));
        Format(sv_tags, sizeof(sv_tags), "-# `%s`", sv_tags);
        Embed.AddField(new DiscordEmbedField("Tags:", sv_tags, false));
    }

    char mapFastDL[512];
    if (StrContains(map, "workshop/", false) != -1)
    {
        char workshopId[2][32];
        ExplodeString(map, "/", workshopId, sizeof(workshopId), sizeof(workshopId[]));

        char mapName[2][64];
        ExplodeString(workshopId[1], ".ugc", mapName, sizeof(mapName), sizeof(mapName[]));

        Format(mapFastDL, sizeof(mapFastDL), "[%s](https://steamcommunity.com/sharedfiles/filedetails/?id=%s)", mapName[0], mapName[1]);
    }
    else
    {
        char sv_downloadurl[512];
        FindConVar("sv_downloadurl").GetString(sv_downloadurl, sizeof(sv_downloadurl));
        Format(mapFastDL, sizeof(mapFastDL), "[%s](%s/maps/%s.bsp)", map, sv_downloadurl, map);
    }
    
    Embed.AddField(new DiscordEmbedField("Previous Map:", mapFastDL, true));
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void PrintToChannel(char[] webhook, const char[] msg, const char[] color)
{
    DiscordWebHook hook = new DiscordWebHook(webhook);
    hook.SetUsername("Server Status");

    DiscordEmbed Embed = new DiscordEmbed();
    Embed.SetColor(color);

    Embed.AddField(new DiscordEmbedField("", msg, false));

    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void AnnounceToChannel(char[] webhook, const char[] msg, const char[] color)
{
    DiscordWebHook hook = new DiscordWebHook(webhook);
    hook.SetUsername("Server Status");

    DiscordEmbed Embed = new DiscordEmbed();
    Embed.SetColor(color);

    Embed.AddField(new DiscordEmbedField(msg, "", false));

    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public Action Timer_GetGuildList(Handle timer)
{
    g_Bot.GetGuild(g_sDiscordServerId, false, OnGuildsReceived);
    return Plugin_Continue;
}

public void OnGuildsReceived(DiscordBot bot, DiscordGuild guild)
{
    g_Bot.GetChannel(g_sChannelId, OnRelayChannelReceived);
    g_Bot.GetChannel(g_sRCONChannelId, OnRCONChannelReceived);
}

public void OnRelayChannelReceived(DiscordBot bot, DiscordChannel channel)
{
    if (g_Bot == null || channel == null)
    {
        LogError("Invalid Bot or Channel!");
        return;
    }

    if (g_Bot.IsListeningToChannel(channel))
    {
        return;
    }
    
    if (g_cvDiscordToServer.BoolValue)
    {
		char channelName[64];
		channel.GetName(channelName, sizeof(channelName));

        g_Bot.StartListeningToChannel(channel, OnDiscordMessageSent);
        PrintToServer("Listening to #%s for messages...", channelName);
        if (!g_ChatAnnounced)
        {
            PrintToChannel(g_sDiscordWebhook, "Listening to chat messages...", WHITE);
            g_ChatAnnounced = true;
        }
    }
}

public void OnRCONChannelReceived(DiscordBot bot, DiscordChannel channel)
{
    if (g_Bot == null || channel == null)
    {
        LogError("Invalid Bot or Channel!");
        return;
    }

    if (g_Bot.IsListeningToChannel(channel))
    {
        return;
    }
    
    if (g_cvRCONDiscordToServer.BoolValue)
    {
		char channelName[64];
		channel.GetName(channelName, sizeof(channelName));

        g_Bot.StartListeningToChannel(channel, OnDiscordMessageSent);
        PrintToServer("Listening to #%s for RCON commands...", channelName);
        if (!g_RCONAnnounced)
        {
            PrintToChannel(g_sRCONWebhook, "Listening to RCON commands...", WHITE);
            g_RCONAnnounced = true;
        }
    }
}

public void OnDiscordMessageSent(DiscordBot bot, DiscordChannel chl, DiscordMessage discordmessage)
{
    DiscordUser author = discordmessage.GetAuthor();
    if (author.IsBot)
    {
        delete author;
        return;
    }

    char id[20];
    chl.GetID(id, sizeof(id));

    char message[512];
    discordmessage.GetContent(message, sizeof(message));
    
    if (StrEqual(id, g_sChannelId))
    {
        char discorduser[32];
        author.GetUsername(discorduser, sizeof(discorduser));
        
        char chatMessage[256];
        if (g_msg_prefix[0] != '\0')
        {
            Format(
            chatMessage, sizeof(chatMessage),
            "%s %s%s%s :  %s", 
            g_msg_prefix, g_msg_varcol, discorduser, g_msg_textcol, message
            );
        }
        else
        {
            Format(
            chatMessage, sizeof(chatMessage),
            "%s%s%s :  %s", 
            g_msg_varcol, discorduser, g_msg_textcol, message
            );
        }

        char consoleMessage[256];
        Format(consoleMessage, sizeof(consoleMessage), "*DISCORD* %s : %s", discorduser, message);

        CPrintToChatAll(chatMessage);
        PrintToServer(consoleMessage);
        delete author;
    }
    if (StrEqual(id, g_sRCONChannelId))
    {
        if (g_cvPrintRCONResponse.BoolValue)
        {
            char response[2048];
            ServerCommandEx(response, sizeof(response), "%s", message);
            Format(response, sizeof(response), "```%s\n%s\n```", g_rcon_highlight, response);
            
            DiscordWebHook hook = new DiscordWebHook(g_sRCONWebhook);
            hook.SetUsername("RCON");

            DiscordEmbed Embed = new DiscordEmbed();
            Embed.SetColor(BLACK);
            Embed.AddField(new DiscordEmbedField("", response, false));

            hook.Embed(Embed);
            hook.Send();
            delete hook;
        }
        else
        {
            ServerCommand(message);
        }
    }
}

stock bool IsValidClient(int client)
{
    return client > 0 &&
           client <= MaxClients && 
           IsClientConnected(client) && 
           !IsFakeClient(client) && 
           !IsClientSourceTV(client) && 
           IsClientInGame(client);
}

stock int GetOnlinePlayers()
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
        {
            count++;
        }
    }
    return count;
}