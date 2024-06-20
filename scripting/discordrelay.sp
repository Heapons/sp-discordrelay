#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <discord>
#include <multicolors>
#include <autoexecconfig>
#include <updater>
#undef REQUIRE_EXTENSIONS
#include <ripext>

#include "discordrelay/convars.sp"
#include "discordrelay/commbantypes.sp"
#include "discordrelay/globals.sp"

public Plugin myinfo = 
{
    name = "[ANY] Discord Relay", 
    author = "log-ical (ampere version)", 
    description = "Discord and Server interaction", 
    version = "1.0", 
    url = "https://github.com/maxijabase/sp-discordrelay"    
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Late = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    SetupConvars();

    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }

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
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
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

public void OnMapStart()
{
    if (!g_sDiscordWebhook[0])
    {
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
    
    delete g_Bot;
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
        LogMessage("Bot already configured, skipping...");
        return Plugin_Handled;
    }

    g_Bot = new DiscordBot(g_sDiscordBotToken);
    CreateTimer(1.0, Timer_GetGuildList, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public Action Timer_MapStart(Handle timer)
{
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordMapChange(buffer, YELLOW);
    return Plugin_Continue;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
    if (g_cvHideExclamMessage.BoolValue && (!strncmp(sArgs, "!", 1) || !strncmp(sArgs, "/", 1)))
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

    PrintToDiscordSay(GetClientUserId(client), buffer);
}

public void SBPP_OnBanPlayer(int admin, int target, int time, const char[] reason)
{
    if (!g_cvPrintSBPPBans.BoolValue)
    {
        return;
    }

    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;
    hook.SetAvatar(g_sSBPPAvatar);
    hook.SetUsername("Player Banned");
    
    MessageEmbed Embed = new MessageEmbed();
    Embed.SetColor("#FF0000");
    
    // Banned Player Link Embed
    char bsteamid[65];
    char bplayerName[512];
    if (GetClientAuthId(target, AuthId_SteamID64, bsteamid, sizeof(bsteamid)))
    {
        Format(bplayerName, sizeof(bplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", target, bsteamid);
    }
    else
    {
        Format(bplayerName, sizeof(bplayerName), "%N", target);
    }
    
    // Admin Link Embed
    char asteamid[65];
    char aplayerName[512];
    if (!IsValidClient(admin))
    {
        Format(aplayerName, sizeof(aplayerName), "CONSOLE");
    }
    else
    {
       if (GetClientAuthId(admin, AuthId_SteamID64, asteamid, sizeof(asteamid)))
        {
            Format(aplayerName, sizeof(aplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", target, asteamid);
        }
        else
        {
            Format(aplayerName, sizeof(aplayerName), "%N", admin);
        }
    }
    
    char banMsg[512];
    Format(banMsg, sizeof(banMsg), "%s has been banned by %s", bplayerName, aplayerName);
    Embed.AddField("", banMsg, false);
    
    Embed.AddField("Reason: ", reason, true);
    char sTime[16];
    IntToString(time, sTime, sizeof(sTime));
    Embed.AddField("Length: ", sTime, true);
    
    char CurrentMap[64];
    GetCurrentMap(CurrentMap, sizeof(CurrentMap));
    Embed.AddField("Map: ", CurrentMap, true);
    char sRealTime[32];
    FormatTime(sRealTime, sizeof(sRealTime), "%m-%d-%Y %I:%M:%S", GetTime());
    Embed.AddField("Time: ", sRealTime, true);
    
    char hostname[64];
    FindConVar("hostname").GetString(hostname, sizeof(hostname));
    Embed.SetFooter(hostname);

    if (g_sSBPPAvatar[0] != '\0')
    {
        Embed.SetFooterIcon(g_sSBPPAvatar);
    }
    
    Embed.SetTitle("SourceBans");
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void SourceComms_OnBlockAdded(int admin, int target, int time, int type, char[] reason)
{
    if (!g_cvPrintSBPPComms.BoolValue || type > 3)
    {
        return;
    }

    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;
    hook.SetAvatar(g_sSBPPAvatar);
    
    char name[32];
    Format(name, sizeof(name), "Player %s", CommbanTypes[type]);
    hook.SetUsername(name);
    
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetColor("#6495ED");
    
    // Blocked Player Link Embed
    char bsteamid[65];
    char bplayerName[512];
    if (GetClientAuthId(target, AuthId_SteamID64, bsteamid, sizeof(bsteamid)))
    {
        Format(bplayerName, sizeof(bplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", target, bsteamid);
    }
    else
    {
        Format(bplayerName, sizeof(bplayerName), "%N", target);
    }
    
    // Admin Link Embed
    char asteamid[65];
    char aplayerName[512];
    if (!IsValidClient(admin))
    {
        Format(aplayerName, sizeof(aplayerName), "CONSOLE");
    }
    else
    {
        if (GetClientAuthId(admin, AuthId_SteamID64, asteamid, sizeof(asteamid)))
        {
            Format(aplayerName, sizeof(aplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", admin, asteamid);
        }
        else
        {
            Format(aplayerName, sizeof(aplayerName), "%N", admin);
        }
    }
    
    char banMsg[512];
    Format(banMsg, sizeof(banMsg), "%s has been %s by %s", bplayerName, lCommbanTypes[type], aplayerName);
    Embed.AddField("", banMsg, false);
    
    Embed.AddField("Reason: ", reason, true);
    char sTime[16];
    IntToString(time, sTime, sizeof(sTime));
    Embed.AddField("Length: ", sTime, true);
    
    Embed.AddField("Type: ", sCommbanTypes[type], true);
    char CurrentMap[64];
    GetCurrentMap(CurrentMap, sizeof(CurrentMap));
    Embed.AddField("Map: ", CurrentMap, true);
    char sRealTime[32];
    FormatTime(sRealTime, sizeof(sRealTime), "%m-%d-%Y %I:%M:%S", GetTime());
    Embed.AddField("Time: ", sRealTime, true);
    
    char hostname[64];
    FindConVar("hostname").GetString(hostname, sizeof(hostname));
    Embed.SetFooter(hostname);

    if (g_sSBPPAvatar[0] != '\0')
    {
        Embed.SetFooterIcon(g_sSBPPAvatar);
    }
    
    Embed.SetTitle("SourceComms");
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public void PrintToDiscord(int userid, const char[] color, const char[] msg, any...)
{
    if (!g_cvServerToDiscord.BoolValue || !g_cvMessage.BoolValue)
    {
        return;
    }

    int client = GetClientOfUserId(userid);
    
    char name[32];
    GetClientName(client, name, sizeof(name));
    
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;
    
    if (g_cvServerToDiscordAvatars.BoolValue)
    {
        hook.SetAvatar(g_Players[userid].AvatarURL);
    }
    
    char buffer[128];
    Format(buffer, sizeof(buffer), "%s", name);
    hook.SetUsername(buffer);
    
    MessageEmbed Embed = new MessageEmbed();
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
    
    Embed.AddField("", playerName, true);
    Embed.AddField("", msg, true);
    
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

    int client = GetClientOfUserId(userid);
    
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;
    
    if (!IsValidClient(client))
    {
        if (!g_cvServerMessage.BoolValue)
        {
            return;
        }

        // If not a valid client, it must be the server
        hook.SetUsername("CONSOLE");
    }
    else
    {
        char name[32];
        GetClientName(client, name, sizeof(name));
        
        if (g_cvServerToDiscordAvatars.BoolValue)
        {
            hook.SetAvatar(g_Players[userid].AvatarURL);
        }

        char buffer[128];
        Format(buffer, sizeof(buffer), "%s", name);
        hook.SetUsername(buffer);
    }
    
    char formattedMessage[256];
    // Format(formattedMessage, sizeof(formattedMessage), "[`%s`](\\<http://www.steamcommunity.com/profiles/%s\\>) : %s", 
    //     g_Players[userid].SteamID2, g_Players[userid].SteamID64, msg);

    Format(formattedMessage, sizeof(formattedMessage), "`%s` : %s", g_Players[userid].SteamID2, msg);

    hook.SetContent(formattedMessage);
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
    hook.SlackMode = true;
    hook.SetUsername("Map Change");
    
    MessageEmbed Embed = new MessageEmbed();
    Embed.SetColor(color);
    
    Embed.AddField("New Map:", map, true);
    
    char buffer[512];
    Format(buffer, sizeof(buffer), "%d/%d", GetOnlinePlayers(), GetMaxHumanPlayers());
    Embed.AddField("Players Online:", buffer, true);
    
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

public Action Timer_GetGuildList(Handle timer)
{
    g_Bot.GetGuilds(OnGuildsReceived);
    return Plugin_Continue;
}

public void OnGuildsReceived(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
    g_Bot.GetGuildChannels(id, OnChannelsReceived);
}

public void OnChannelsReceived(DiscordBot bot, const char[] guild, DiscordChannel chl, any data)
{
    if (!StrEqual(guild, g_sDiscordServerId))
    {
        return;
    }

    if (g_Bot == null || chl == null)
    {
        LogError("Invalid Bot or Channel!");
        return;
    }

    if (g_Bot.IsListeningToChannel(chl))
    {
        return;
    }
    
    char id[20];
    chl.GetID(id, sizeof(id));
    char channelName[64];
    chl.GetName(channelName, sizeof(channelName));
    if (g_cvDiscordToServer.BoolValue && StrEqual(id, g_sChannelId))
    {
        g_Bot.StartListeningToChannel(chl, OnDiscordMessageSent);
        LogMessage("Listening to #%s for messages...", channelName);
    }
    if (g_cvRCONDiscordToServer.BoolValue && StrEqual(id, g_sRCONChannelId))
    {
        g_Bot.StartListeningToChannel(chl, OnDiscordMessageSent);
        LogMessage("Listening to #%s for RCON commands...", channelName);
    }
}

public void OnDiscordMessageSent(DiscordBot bot, DiscordChannel chl, DiscordMessage discordmessage)
{
    DiscordUser author = discordmessage.GetAuthor();
    if (author.IsBot())
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
        CPrintToChatAll("%s[%sDiscord%s] %s%s%s: %s", 
            g_msg_textcol, g_msg_varcol, g_msg_textcol, 
            g_msg_varcol, discorduser, g_msg_textcol, 
            message);

        delete author;
    }
    if (StrEqual(id, g_sRCONChannelId))
    {
        if (g_cvPrintRCONResponse.BoolValue)
        {
            char response[2048];
            ServerCommandEx(response, sizeof(response), message);
            Format(response, sizeof(response), "```%s```", response);
            
            DiscordWebHook hook = new DiscordWebHook(g_sRCONWebhook);
            hook.SlackMode = true;
            hook.SetContent(response);
            hook.SetUsername("RCON");
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