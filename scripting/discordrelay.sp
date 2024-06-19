#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <discord>
#include <multicolors>
#undef REQUIRE_EXTENSIONS
#include <ripext>
#include <autoexecconfig>

public Plugin myinfo = 
{
    name = "Discord Relay", 
    author = "log-ical (ampere version)", 
    description = "Discord and Server interaction", 
    version = "1.0", 
    url = "https://github.com/maxijabase/sp-discordrelay"    
}

DiscordBot g_dBot;

enum struct PlayerData
{
    int UserID;
    char AvatarURL[256];
}

PlayerData players[MAXPLAYERS + 1];

#define GREEN  "#008000"
#define RED    "#ff2222"
#define YELLOW "#daa520"

bool g_Late;

ConVar g_cvmsg_textcol;
char g_msg_textcol[32];
ConVar g_cvmsg_varcol;
char g_msg_varcol[32];

ConVar g_cvSteamApiKey;
char g_sSteamApiKey[128];
ConVar g_cvDiscordBotToken;
char g_sDiscordBotToken[128];
ConVar g_cvDiscordWebhook;
char g_sDiscordWebhook[256];
ConVar g_cvRCONWebhook;
char g_sRCONWebhook[256];

ConVar g_cvDiscordServerId;
char g_sDiscordServerId[64];
ConVar g_cvChannelId;
char g_sChannelId[64];
ConVar g_cvRCONChannelId;
char g_sRCONChannelId[64];

ConVar g_cvSBPPAvatar;
char g_sSBPPAvatar[64];

ConVar g_cvServerToDiscord; // requires Discord bot key
ConVar g_cvDiscordToServer; // requires Discord webhook
ConVar g_cvServerToDiscordAvatars; // requires steam api key
ConVar g_cvRCONDiscordToServer; // requires Discord bot key
ConVar g_cvPrintRCONResponse;

ConVar g_cvServerMessage;
ConVar g_cvConnectMessage;
ConVar g_cvDisconnectMessage;
ConVar g_cvMapChangeMessage;
ConVar g_cvMessage;
ConVar g_cvHideExclamMessage;

ConVar g_cvPrintSBPPBans;
ConVar g_cvPrintSBPPComms;

char lCommbanTypes[][] = {
    "", 
    "muted", 
    "gagged", 
    "silenced"
};

char CommbanTypes[][] = {
    "", 
    "Muted", 
    "Gagged", 
    "Silenced"
};

char sCommbanTypes[][] = {
    "", 
    "Mute", 
    "Gag", 
    "Silence"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Late = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("discordrelay");
    
    // Keys/Tokens
    g_cvSteamApiKey = AutoExecConfig_CreateConVar("discrelay_steamapikey", "", "Your Steam API key (needed for discrelay_servertodiscordavatars)");
    g_cvDiscordBotToken = AutoExecConfig_CreateConVar("discrelay_discordbottoken", "", "Your Discord bot key (needed for discrelay_discordtoserver)");
    g_cvDiscordWebhook = AutoExecConfig_CreateConVar("discrelay_discordwebhook", "", "Webhook for Discord channel (needed for discrelay_servertodiscord)");
    
    // IDs
    g_cvDiscordServerId = AutoExecConfig_CreateConVar("discrelay_discordserverid", "", "Discord Server Id, required for Discord to server");
    g_cvChannelId = AutoExecConfig_CreateConVar("discrelay_channelid", "", "Channel Id for Discord to server (This channel would be the one where the plugin check for messages to send to the server)");
    g_cvRCONChannelId = AutoExecConfig_CreateConVar("discrelay_rcon_channelid", "", "Channel ID where RCON commands should be sent");
    g_cvRCONWebhook = AutoExecConfig_CreateConVar("discrelay_rcon_webhook", "", "Webhook for RCON reponses, required for discrelay_rcon_printreponse");
    
    // Switches
    g_cvServerToDiscord = AutoExecConfig_CreateConVar("discrelay_servertodiscord", "1", "Enables messages sent in the server to be forwarded to discord");
    g_cvDiscordToServer = AutoExecConfig_CreateConVar("discrelay_discordtoserver", "1", "Enables messages sent in Discord to be forwarded to server (discrelay_discordtoserver and discrelay_discordbottoken need to be set)");
    g_cvServerToDiscordAvatars = AutoExecConfig_CreateConVar("discrelay_servertodiscordavatars", "1", "Changes webhook avatar to clients steam avatar (discrelay_servertodiscord needs to set to 1, and steamapi key needs to be set)");
    g_cvRCONDiscordToServer = AutoExecConfig_CreateConVar("discrelay_rcon_enabled", "0", "Enables RCON functionality");
    g_cvPrintRCONResponse = AutoExecConfig_CreateConVar("discrelay_rcon_printreponse", "1", "Prints reponse from command (discrelay_rcon_webhook required)");
    
    // Message Switches
    g_cvServerMessage = AutoExecConfig_CreateConVar("discrelay_servermessage", "1", "Prints server say commands to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvConnectMessage = AutoExecConfig_CreateConVar("discrelay_connectmessage", "1", "relays client connection to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvDisconnectMessage = AutoExecConfig_CreateConVar("discrelay_disconnectmessage", "1", "relays client disconnection messages to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMapChangeMessage = AutoExecConfig_CreateConVar("discrelay_mapchangemessage", "1", "relays map changes to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMessage = AutoExecConfig_CreateConVar("discrelay_message", "1", "relays client messages to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvHideExclamMessage = AutoExecConfig_CreateConVar("discrelay_hideexclammessage", "1", "Hides any message that begins with !");
    
    // Customization
    g_cvmsg_textcol = AutoExecConfig_CreateConVar("discrelay_msg_textcol", "{default}", "text color of Discord to server text (refer to github for support, the ways you can chose colors depends on game)");
    g_cvmsg_varcol = AutoExecConfig_CreateConVar("discrelay_msg_varcol", "{default}", "variable color of Discord to server text (refer to github for support, the ways you can chose colors depends on game)");
    
    // SBPP Customization
    g_cvPrintSBPPBans = AutoExecConfig_CreateConVar("discrelay_printsbppbans", "0", "Prints bans to channel that webhook points to, sbpp must be installed for this to function");
    g_cvPrintSBPPComms = AutoExecConfig_CreateConVar("discrelay_printsbppcomms", "0", "Prints comm bans to channel that webhook pints to, sbpp must be installed for this to function");
    g_cvSBPPAvatar = AutoExecConfig_CreateConVar("discrelay_sbppavatar", "", "Image url the webhook will use for profile avatar for sourcebans++ functions, leave blank for default Discord avatar");
    
    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();
    
    g_cvSteamApiKey.GetString(g_sSteamApiKey, sizeof(g_sSteamApiKey));
    g_cvDiscordWebhook.GetString(g_sDiscordWebhook, sizeof(g_sDiscordWebhook));
    g_cvRCONWebhook.GetString(g_sRCONWebhook, sizeof(g_sRCONWebhook));
    
    g_cvDiscordServerId.GetString(g_sDiscordServerId, sizeof(g_sDiscordServerId));
    g_cvDiscordBotToken.GetString(g_sDiscordBotToken, sizeof(g_sDiscordBotToken));
    g_cvChannelId.GetString(g_sChannelId, sizeof(g_sChannelId));
    g_cvRCONChannelId.GetString(g_sRCONChannelId, sizeof(g_sRCONChannelId));
    
    g_cvmsg_textcol.GetString(g_msg_textcol, sizeof(g_msg_textcol));
    g_cvmsg_varcol.GetString(g_msg_varcol, sizeof(g_msg_varcol));
    
    g_cvSBPPAvatar.GetString(g_sSBPPAvatar, sizeof(g_sSBPPAvatar));
    
    g_cvSteamApiKey.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordBotToken.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvRCONWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    
    g_cvDiscordServerId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvChannelId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvRCONChannelId.AddChangeHook(OnDiscordRelayCvarChanged);
    
    g_cvmsg_textcol.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvmsg_varcol.AddChangeHook(OnDiscordRelayCvarChanged);
    
    g_cvSBPPAvatar.AddChangeHook(OnDiscordRelayCvarChanged);
    
    if (g_Late)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientAuthorized(i);
            }
        }
    }

    if (g_cvDiscordToServer.BoolValue || g_cvRCONDiscordToServer.BoolValue)
    {
        CreateTimer(1.0, Timer_CreateBot);
    }
}

public Action Timer_CreateBot(Handle timer)
{
    if (!g_sDiscordBotToken[0])
    {
        LogError("Bot token not configured!");
        return Plugin_Handled;
    }

    if (g_dBot)
    {
        LogMessage("Bot already configured...");
        return Plugin_Handled;
    }

    g_dBot = new DiscordBot(g_sDiscordBotToken);
    CreateTimer(1.0, Timer_GetGuildList, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public void OnDiscordRelayCvarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    g_cvSteamApiKey.GetString(g_sSteamApiKey, sizeof(g_sSteamApiKey));
    g_cvDiscordBotToken.GetString(g_sDiscordBotToken, sizeof(g_sDiscordBotToken));
    g_cvDiscordWebhook.GetString(g_sDiscordWebhook, sizeof(g_sDiscordWebhook));
    g_cvRCONWebhook.GetString(g_sRCONWebhook, sizeof(g_sRCONWebhook));
    g_cvDiscordServerId.GetString(g_sDiscordServerId, sizeof(g_sDiscordServerId));
    g_cvChannelId.GetString(g_sChannelId, sizeof(g_sChannelId));
    g_cvRCONChannelId.GetString(g_sRCONChannelId, sizeof(g_sRCONChannelId));
    g_cvmsg_textcol.GetString(g_msg_textcol, sizeof(g_msg_textcol));
    g_cvmsg_varcol.GetString(g_msg_varcol, sizeof(g_msg_varcol));
    g_cvSBPPAvatar.GetString(g_sSBPPAvatar, sizeof(g_sSBPPAvatar));
}

public void OnClientAuthorized(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }
    
    players[client].UserID = GetClientUserId(client);
    
    if (g_cvServerToDiscordAvatars.BoolValue)
    {
        SteamAPIRequest(client);
    }
    else
    {
        if (g_cvConnectMessage.BoolValue)
        {
            PrintToDiscord(client, GREEN, "connected");
        }
    }
}

public void OnMapStart()
{
    if (g_sDiscordWebhook[0])
    {
        return;
    }
    
    CreateTimer(4.0, Timer_MapStart, _, TIMER_DATA_HNDL_CLOSE);
    if (g_cvDiscordToServer.BoolValue)
    {
        CreateTimer(2.0, Timer_CreateBot);
    }
}

public void OnMapEnd()
{
    // Deleting to refresh connection on map start
    if (g_dBot.IsListeningToChannelID(g_sChannelId))
    {
        g_dBot.StopListeningToChannelID(g_sChannelId);
    }
    
    if (g_dBot.IsListeningToChannelID(g_sRCONChannelId))
    {
        g_dBot.StopListeningToChannelID(g_sRCONChannelId);
    }
    
    delete g_dBot;
}

public Action Timer_MapStart(Handle timer)
{
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordMapChange(buffer, YELLOW);
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    if (!IsValidClient(client) || !g_cvDisconnectMessage.BoolValue)
    {
        return;
    }
    PrintToDiscord(client, RED, "disconnected");
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
    PrintToDiscordSay(client, buffer);
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

public void PrintToDiscord(int client, const char[] color, const char[] msg, any...)
{
    if (!g_cvServerToDiscord.BoolValue || !g_cvMessage.BoolValue)
    {
        return;
    }
    
    char name[32];
    GetClientName(client, name, sizeof(name));
    
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;
    
    if (g_cvServerToDiscordAvatars.BoolValue)
    {
        hook.SetAvatar(players[client].AvatarURL);
    }
    
    char steamid2[64];
    GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2));
    char buffer[128];
    Format(buffer, sizeof(buffer), "%s [%s]", name, steamid2);
    hook.SetUsername(buffer);
    
    MessageEmbed Embed = new MessageEmbed();
    Embed.SetColor(color);
    
    char steamid64[65];
    char playerName[512];

    if (GetClientAuthId(client, AuthId_SteamID64, steamid64, sizeof(steamid64)))
    {
        Format(playerName, sizeof(playerName), "[%N](http://www.steamcommunity.com/profiles/%s)", client, steamid64);
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

public void PrintToDiscordSay(int client, const char[] msg, any...)
{
    if (!g_cvServerToDiscord.BoolValue)
    {
        return;
    }
    
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
            hook.SetAvatar(players[client].AvatarURL);
        }

        char steamid[64];
        char buffer[128];
        if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
        {
            Format(buffer, sizeof(buffer), "%s [%s]", name, steamid);
        }
        else
        {
            Format(buffer, sizeof(buffer), "%s", name);
        }
        hook.SetUsername(buffer);
    }
    
    hook.SetContent(msg);
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
    g_dBot.GetGuilds(OnGuildsReceived);
    return Plugin_Continue;
}

public void OnGuildsReceived(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
    g_dBot.GetGuildChannels(id, OnChannelsReceived);
}

public void OnChannelsReceived(DiscordBot bot, const char[] guild, DiscordChannel chl, any data)
{
    if (!StrEqual(guild, g_sDiscordServerId))
    {
        return;
    }

    if (g_dBot == null || chl == null)
    {
        LogMessage("Invalid Bot or Channel!");
        return;
    }

    if (g_dBot.IsListeningToChannel(chl))
    {
        return;
    }
    
    char id[20];
    chl.GetID(id, sizeof(id));
    if (g_cvDiscordToServer.BoolValue && StrEqual(id, g_sChannelId))
    {
        g_dBot.StartListeningToChannel(chl, OnDiscordMessageSent);
    }
    if (g_cvRCONDiscordToServer.BoolValue && StrEqual(id, g_sRCONChannelId))
    {
        g_dBot.StartListeningToChannel(chl, OnDiscordMessageSent);
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

stock void SteamAPIRequest(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    HTTPRequest req = new HTTPRequest("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2");
    req.AppendQueryParam("steamids", steamid);
    req.AppendQueryParam("key", g_sSteamApiKey);
    
    req.Get(SteamResponse_Callback, GetClientUserId(client));
}

stock void SteamResponse_Callback(HTTPResponse response, int userid)
{
    int client = GetClientOfUserId(userid);

    if (response.Status != HTTPStatus_OK)
    {
        LogError("SteamAPI request fail, HTTPSResponse code %i", response.Status);
        if (g_cvConnectMessage.BoolValue)
        {
            PrintToDiscord(client, GREEN, "connected");
        }
        return;
    }

    JSONObject objects = view_as<JSONObject>(response.Data);
    JSONObject Response = view_as<JSONObject>(objects.Get("response"));
    JSONArray jsonPlayers = view_as<JSONArray>(Response.Get("players"));
    int playerlen = jsonPlayers.Length;
    JSONObject player;
    for (int i = 0; i < playerlen; i++)
    {
        player = view_as<JSONObject>(jsonPlayers.Get(i));
        player.GetString("avatarmedium", players[client].AvatarURL, sizeof(PlayerData::AvatarURL));
        delete player;
    }
    
    if (g_cvConnectMessage.BoolValue)
    {
        PrintToDiscord(client, GREEN, "connected");
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