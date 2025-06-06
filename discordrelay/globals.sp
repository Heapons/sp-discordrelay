DiscordBot g_Bot;
bool g_Late;
bool g_ChatAnnounced;
bool g_RCONAnnounced;

enum struct Player
{
    char SteamID2[32];
    char SteamID64[32];
    int UserID;
    char AvatarURL[256];
    int retries;

    void Load(int client)
    {
        this.UserID = GetClientUserId(client);
        GetSteamID(this.UserID);
    }
}

Player g_Players[MAXPLAYERS + 1];

void GetSteamID(int userid)
{
    int client = GetClientOfUserId(userid);
    if (GetClientAuthId(client, AuthId_Steam2, g_Players[userid].SteamID2, sizeof(Player::SteamID2)) &&
        GetClientAuthId(client, AuthId_SteamID64, g_Players[userid].SteamID64, sizeof(Player::SteamID64)))
    {
        if (g_cvServerToDiscordAvatars.BoolValue)
        {
            SteamAPIRequest(userid);
        }
        else if (g_cvConnectMessage.BoolValue)
        {
            char phrase[128];
            char playerName[MAX_NAME_LENGTH];
            Format(playerName, sizeof(playerName), "%N", client);
            Format(phrase, sizeof(phrase), "%T", "Player Join", LANG_SERVER, playerName, g_Players[userid].SteamID64);
            PrintToDiscord(userid, g_sConnectMessageColor, phrase);
        }
    }
    else
    {
        CreateTimer(60.0, RetrySteamIDRetrieval, userid);
    }
}

Action RetrySteamIDRetrieval(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    g_Players[userid].retries++;
    LogMessage("Retrying Steam ID for %N... (%i) attempts.", client, g_Players[userid].retries);
    if (g_Players[userid].retries > 10)
    {
        LogError("Could not retrieve %N's Steam ID after 10 attempts.", client);
        return Plugin_Stop;
    }

    GetSteamID(userid);
    return Plugin_Continue;
}

stock void SteamAPIRequest(int userid)
{
    HTTPRequest req = new HTTPRequest("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2");
    req.AppendQueryParam("steamids", g_Players[userid].SteamID64);
    req.AppendQueryParam("key", g_sSteamApiKey);
    req.Get(SteamResponse_Callback, userid);
}

stock void SteamResponse_Callback(HTTPResponse response, int userid)
{
    int client = GetClientOfUserId(userid);
    if (response.Status != HTTPStatus_OK)
    {
        LogError("SteamAPI request fail, HTTPSResponse code %i", response.Status);
        if (g_cvConnectMessage.BoolValue)
        {
            char phrase[128];
            char playerName[MAX_NAME_LENGTH];
            Format(playerName, sizeof(playerName), "%N", client);
            Format(phrase, sizeof(phrase), "%T", "Player Join", LANG_SERVER, playerName, g_Players[userid].SteamID64);
            PrintToDiscord(userid, g_sConnectMessageColor, phrase);
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
        player.GetString("avatarmedium", g_Players[userid].AvatarURL, sizeof(Player::AvatarURL));
        delete player;
    }
    
    if (g_cvConnectMessage.BoolValue)
    {
        char phrase[128];
        char playerName[MAX_NAME_LENGTH];
        Format(playerName, sizeof(playerName), "%N", client);
        Format(phrase, sizeof(phrase), "%T", "Player Join", LANG_SERVER, playerName, g_Players[userid].SteamID64);
        PrintToDiscord(userid, g_sConnectMessageColor, phrase);
    }
}