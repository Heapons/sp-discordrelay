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

ConVar g_cvAdminWebhook;
char g_sAdminWebhook[256];

ConVar g_cvServerToDiscord;
ConVar g_cvDiscordToServer;
ConVar g_cvServerToDiscordAvatars;
ConVar g_cvRCONDiscordToServer;
ConVar g_cvPrintRCONResponse;
ConVar g_cvPrintRCONResponseColor;
char g_sPrintRCONResponseColor[32];
ConVar g_cvListenAnnounce;
ConVar g_cvListenAnnounceColor;
char g_sListenAnnounceColor[32];
ConVar g_cvServerHibernationEnterColor;
char g_sServerHibernationEnterColor[32];
ConVar g_cvServerHibernationExitColor;
char g_sServerHibernationExitColor[32];
ConVar g_cvConsoleMessageColor;
char g_sConsoleMessageColor[32];
ConVar g_cvBanMessageColor;
char g_sBanMessageColor[32];
ConVar g_cvCurrentMapColor;
char g_sCurrentMapColor[32];
ConVar g_cvPreviousMapColor;
char g_sPreviousMapColor[32];
ConVar g_cvServerStartColor;
char g_sServerStartColor[32];
ConVar g_cvServerHibernation;
ConVar g_cvShowServerIP;
char g_sShowServerIP[32];
ConVar g_cvFooterIconURL;
char g_sFooterIconURL[256];

ConVar g_cvServerMessage;
ConVar g_cvServerMessageColor;
char g_sServerMessageColor[32];
ConVar g_cvConnectMessage;
ConVar g_cvConnectMessageColor;
char g_sConnectMessageColor[32];
ConVar g_cvDisconnectMessage;
ConVar g_cvDisconnectMessageColor;
char g_sDisconnectMessageColor[32];
ConVar g_cvMapChangeMessage;
ConVar g_cvMessage;
ConVar g_cvHideCommands;
char g_sHideCommands[64];
ConVar g_cvShowServerTags;
ConVar g_cvShowServerName;
ConVar g_cvShowSteamID;
char g_sShowSteamID[32];
ConVar g_cvAdminRole;
char g_sAdminRole[64];
ConVar g_cvFilterWords;
char g_sFilterWords[MAX_MESSAGE_LENGTH];
ConVar g_cvBlockedMessageColor;
char g_sBlockedMessageColor[32];

ConVar g_cvCallAdminCooldown;
float g_fCallAdminCooldown = 60.0;

ConVar g_cvServerHibernationWebhook;
char g_sServerHibernationWebhook[256];
ConVar g_cvMapStatusWebhook;
char g_sMapStatusWebhook[256];
ConVar g_cvListenChatWebhook;
char g_sListenChatWebhook[256];
ConVar g_cvListenRCONWebhook;
char g_sListenRCONWebhook[256];
//ConVar g_cvPlayerStatusWebhook;
//char g_sPlayerStatusWebhook[256];

void SetupConvars() 
{
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("discordrelay");
    
    // Keys/Tokens
    g_cvSteamApiKey = AutoExecConfig_CreateConVar("discrelay_steamapikey", "", "Your Steam API key (needed for discrelay_servertodiscordavatars)");
    g_cvDiscordBotToken = AutoExecConfig_CreateConVar("discrelay_discordbottoken", "", "Your Discord bot key (needed for discrelay_discordtoserver)");
    g_cvDiscordWebhook = AutoExecConfig_CreateConVar("discrelay_discordwebhook", "", "Webhook for Discord channel (needed for discrelay_servertodiscord)");

    g_cvSteamApiKey.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordBotToken.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    
    // IDs
    g_cvDiscordServerId = AutoExecConfig_CreateConVar("discrelay_discordserverid", "", "Discord Server Id, required for Discord to server");
    g_cvChannelId = AutoExecConfig_CreateConVar("discrelay_channelid", "", "Channel Id for Discord to server (This channel would be the one where the plugin check for messages to send to the server)");
    g_cvRCONChannelId = AutoExecConfig_CreateConVar("discrelay_rcon_channelid", "", "Channel ID where RCON commands should be sent");
    g_cvRCONWebhook = AutoExecConfig_CreateConVar("discrelay_rcon_webhook", "", "Webhook for RCON reponses, required for discrelay_rcon_printreponse");
    
    g_cvDiscordServerId.GetString(g_sDiscordServerId, sizeof(g_sDiscordServerId));
    g_cvDiscordBotToken.GetString(g_sDiscordBotToken, sizeof(g_sDiscordBotToken));
    g_cvChannelId.GetString(g_sChannelId, sizeof(g_sChannelId));
    g_cvRCONChannelId.GetString(g_sRCONChannelId, sizeof(g_sRCONChannelId));

    g_cvDiscordServerId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvChannelId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvRCONChannelId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvRCONWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
        
    
    // Switches
    g_cvServerToDiscord = AutoExecConfig_CreateConVar("discrelay_servertodiscord", "1", "Enables messages sent in the server to be forwarded to discord");
    g_cvDiscordToServer = AutoExecConfig_CreateConVar("discrelay_discordtoserver", "1", "Enables messages sent in Discord to be forwarded to server (discrelay_discordtoserver and discrelay_discordbottoken need to be set)");
    g_cvServerToDiscordAvatars = AutoExecConfig_CreateConVar("discrelay_servertodiscordavatars", "1", "Changes webhook avatar to clients steam avatar (discrelay_servertodiscord needs to set to 1, and steamapi key needs to be set)");
    g_cvRCONDiscordToServer = AutoExecConfig_CreateConVar("discrelay_rcon_enabled", "0", "Enables RCON functionality");
    g_cvPrintRCONResponse = AutoExecConfig_CreateConVar("discrelay_rcon_printresponse", "1", "Prints response from command (discrelay_rcon_webhook required)");
    g_cvListenAnnounce = AutoExecConfig_CreateConVar("discrelay_listenannounce", "1", "Prints a message when the plugin is listening for messages");
    g_cvServerHibernation = AutoExecConfig_CreateConVar("discrelay_serverhibernation", "1", "Prints a message whenever the server enters/exits hibernation");
    
    // Message Switches
    g_cvServerMessage = AutoExecConfig_CreateConVar("discrelay_servermessage", "1", "Prints server say commands to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvConnectMessage = AutoExecConfig_CreateConVar("discrelay_connectmessage", "1", "Relays client connection to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvDisconnectMessage = AutoExecConfig_CreateConVar("discrelay_disconnectmessage", "1", "Relays client disconnection messages to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMapChangeMessage = AutoExecConfig_CreateConVar("discrelay_mapchangemessage", "1", "Relays map changes to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMessage = AutoExecConfig_CreateConVar("discrelay_message", "1", "Relays client messages to Discord (discrelay_servertodiscord needs to set to 1)");
    g_cvHideCommands = AutoExecConfig_CreateConVar("discrelay_hidecommands", "!,/", "Hides any message that begins with the specified prefixes (e.g., '!'). Separate multiple prefixes with commas.");
    g_cvShowServerTags = AutoExecConfig_CreateConVar("discrelay_showservertags", "1", "Displays sv_tags in server status");
    g_cvShowServerName = AutoExecConfig_CreateConVar("discrelay_showservername", "1", "Displays hostname in server status");
    g_cvShowSteamID = AutoExecConfig_CreateConVar("discrelay_showsteamid", "name", "Shows the client's Steam ID. Possible values: bottom, top, name, prepend, append (or leave it blank to hide it).");
    g_cvAdminRole = AutoExecConfig_CreateConVar("discrelay_adminrole", "", "Role to mention on Discord for sm_calladmin.");
    g_cvAdminWebhook = AutoExecConfig_CreateConVar("discrelay_admin_webhook", "", "Webhook for admin call notifications.");
    
    g_cvShowSteamID.GetString(g_sShowSteamID, sizeof(g_sShowSteamID));
    g_cvHideCommands.GetString(g_sHideCommands, sizeof(g_sHideCommands));
    g_cvAdminRole.GetString(g_sAdminRole, sizeof(g_sAdminRole));
    g_cvAdminWebhook.GetString(g_sAdminWebhook, sizeof(g_sAdminWebhook));
    
    g_cvShowSteamID.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvHideCommands.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvAdminRole.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvAdminWebhook.AddChangeHook(OnDiscordRelayCvarChanged);

    // Colors
    g_cvServerMessageColor = AutoExecConfig_CreateConVar("discrelay_servermessage_color", "8650AC", "HEX color for console messages");
    g_cvListenAnnounceColor = AutoExecConfig_CreateConVar("discrelay_listenannounce_color", "F8F8FF", "HEX color for the listening message");
    g_cvServerHibernationEnterColor = AutoExecConfig_CreateConVar("discrelay_serverhibernation_enter_color", "DC143C", "HEX color for the server hibernation message");
    g_cvServerHibernationExitColor = AutoExecConfig_CreateConVar("discrelay_serverhibernation_exit_color", "3CB371", "HEX color for the server hibernation message");
    g_cvConsoleMessageColor = AutoExecConfig_CreateConVar("discrelay_consolemessage_color", "8650AC", "HEX color for the console message");
    g_cvConnectMessageColor = AutoExecConfig_CreateConVar("discrelay_connectmessage_color", "3CB371", "HEX color for the connect message");
    g_cvDisconnectMessageColor = AutoExecConfig_CreateConVar("discrelay_disconnectmessage_color", "DC143C", "HEX color for the disconnect message");
    g_cvBanMessageColor = AutoExecConfig_CreateConVar("discrelay_banmessage_color", "DC143C", "HEX color for the ban message");
    g_cvCurrentMapColor = AutoExecConfig_CreateConVar("discrelay_currentmap_color", "FFD700", "HEX color for the current map message");
    g_cvPreviousMapColor = AutoExecConfig_CreateConVar("discrelay_previousmap_color", "DC143C", "HEX color for the previous map message");
    g_cvPrintRCONResponseColor = AutoExecConfig_CreateConVar("discrelay_rcon_printresponse_color", "2F4F4F", "HEX color for the RCON response message");
    g_cvServerStartColor = AutoExecConfig_CreateConVar("discrelay_serverstart_color", "3CB371", "HEX color for the server start message");
    g_cvBlockedMessageColor = AutoExecConfig_CreateConVar("discrelay_blockedmessage_color", "DC143C", "HEX color for blocked message embeds.");
    
    g_cvServerMessageColor.GetString(g_sServerMessageColor, sizeof(g_sServerMessageColor));
    g_cvListenAnnounceColor.GetString(g_sListenAnnounceColor, sizeof(g_sListenAnnounceColor));
    g_cvServerHibernationEnterColor.GetString(g_sServerHibernationEnterColor, sizeof(g_sServerHibernationEnterColor));
    g_cvServerHibernationExitColor.GetString(g_sServerHibernationExitColor, sizeof(g_sServerHibernationExitColor));
    g_cvConsoleMessageColor.GetString(g_sConsoleMessageColor, sizeof(g_sConsoleMessageColor));
    g_cvConnectMessageColor.GetString(g_sConnectMessageColor, sizeof(g_sConnectMessageColor));
    g_cvDisconnectMessageColor.GetString(g_sDisconnectMessageColor, sizeof(g_sDisconnectMessageColor));
    g_cvBanMessageColor.GetString(g_sBanMessageColor, sizeof(g_sBanMessageColor));
    g_cvCurrentMapColor.GetString(g_sCurrentMapColor, sizeof(g_sCurrentMapColor));
    g_cvPreviousMapColor.GetString(g_sPreviousMapColor, sizeof(g_sPreviousMapColor));
    g_cvPrintRCONResponseColor.GetString(g_sPrintRCONResponseColor, sizeof(g_sPrintRCONResponseColor));
    g_cvServerStartColor.GetString(g_sServerStartColor, sizeof(g_sServerStartColor));
    g_cvBlockedMessageColor.GetString(g_sBlockedMessageColor, sizeof(g_sBlockedMessageColor));


    g_cvListenAnnounceColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvServerHibernationEnterColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvServerHibernationExitColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvConsoleMessageColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvConnectMessageColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDisconnectMessageColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvBanMessageColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvCurrentMapColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvPreviousMapColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvPrintRCONResponseColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvServerStartColor.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvBlockedMessageColor.AddChangeHook(OnDiscordRelayCvarChanged);
    
    // Moderation
    g_cvCallAdminCooldown = AutoExecConfig_CreateConVar("discrelay_calladmin_cooldown", "60.0", "Cooldown in seconds for sm_calladmin per player.");
    g_cvCallAdminCooldown.AddChangeHook(OnDiscordRelayCvarChanged);
    g_fCallAdminCooldown = g_cvCallAdminCooldown.FloatValue;
    g_cvFilterWords = AutoExecConfig_CreateConVar("discrelay_filter_words", "", "Filter words through Regex expressions.");
    g_cvFilterWords.AddChangeHook(OnDiscordRelayCvarChanged);

    // More Webhooks
    g_cvServerHibernationWebhook = AutoExecConfig_CreateConVar("discrelay_serverhibernation_webhook", "", "Webhook for server hibernation notifications.");
    g_cvMapStatusWebhook = AutoExecConfig_CreateConVar("discrelay_mapstatus_webhook", "", "Webhook for map status (current/previous map) notifications.");
    g_cvListenChatWebhook = AutoExecConfig_CreateConVar("discrelay_listenchat_webhook", "", "Webhook for listening to chat notifications.");
    g_cvListenRCONWebhook = AutoExecConfig_CreateConVar("discrelay_listenrcon_webhook", "", "Webhook for listening to RCON notifications.");
    //g_cvPlayerStatusWebhook = AutoExecConfig_CreateConVar("discrelay_playerstatus_webhook", "", "Webhook for join/leave/ban notifications.");

    g_cvServerHibernationWebhook.GetString(g_sServerHibernationWebhook, sizeof(g_sServerHibernationWebhook));
    g_cvMapStatusWebhook.GetString(g_sMapStatusWebhook, sizeof(g_sMapStatusWebhook));
    g_cvListenChatWebhook.GetString(g_sListenChatWebhook, sizeof(g_sListenChatWebhook));
    g_cvListenRCONWebhook.GetString(g_sListenRCONWebhook, sizeof(g_sListenRCONWebhook));
    //g_cvPlayerStatusWebhook.GetString(g_sPlayerStatusWebhook, sizeof(g_sPlayerStatusWebhook));

    g_cvServerHibernationWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvMapStatusWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvListenChatWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvListenRCONWebhook.AddChangeHook(OnDiscordRelayCvarChanged);
    //g_cvPlayerStatusWebhook.AddChangeHook(OnDiscordRelayCvarChanged);

    g_cvFilterWords.GetString(g_sFilterWords, sizeof(g_sFilterWords));

    // Embeds
    g_cvShowServerIP = AutoExecConfig_CreateConVar("discrelay_showserverip", "1", "Display the server IP in Map Status.");
    g_cvFooterIconURL = AutoExecConfig_CreateConVar("discrelay_footericonurl", "https://raw.githubusercontent.com/Heapons/sp-discordrelay/refs/heads/main/steam.png", "Map Status footer icon.");

    AutoExecConfig_CleanFile();
    AutoExecConfig_ExecuteFile();
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
    g_cvShowSteamID.GetString(g_sShowSteamID, sizeof(g_sShowSteamID));
    g_cvHideCommands.GetString(g_sHideCommands, sizeof(g_sHideCommands));    
    g_cvListenAnnounceColor.GetString(g_sListenAnnounceColor, sizeof(g_sListenAnnounceColor));
    g_cvServerHibernationEnterColor.GetString(g_sServerHibernationEnterColor, sizeof(g_sServerHibernationEnterColor));
    g_cvServerHibernationExitColor.GetString(g_sServerHibernationExitColor, sizeof(g_sServerHibernationExitColor));
    g_cvConsoleMessageColor.GetString(g_sConsoleMessageColor, sizeof(g_sConsoleMessageColor));
    g_cvConnectMessageColor.GetString(g_sConnectMessageColor, sizeof(g_sConnectMessageColor));
    g_cvDisconnectMessageColor.GetString(g_sDisconnectMessageColor, sizeof(g_sDisconnectMessageColor));
    g_cvBanMessageColor.GetString(g_sBanMessageColor, sizeof(g_sBanMessageColor));
    g_cvCurrentMapColor.GetString(g_sCurrentMapColor, sizeof(g_sCurrentMapColor));
    g_cvPreviousMapColor.GetString(g_sPreviousMapColor, sizeof(g_sPreviousMapColor));
    g_cvPreviousMapColor.GetString(g_sPreviousMapColor, sizeof(g_sPreviousMapColor));
    g_cvPrintRCONResponseColor.GetString(g_sPrintRCONResponseColor, sizeof(g_sPrintRCONResponseColor));
    g_cvServerStartColor.GetString(g_sServerStartColor, sizeof(g_sServerStartColor));
    g_cvAdminRole.GetString(g_sAdminRole, sizeof(g_sAdminRole));
    g_cvServerHibernationWebhook.GetString(g_sServerHibernationWebhook, sizeof(g_sServerHibernationWebhook));
    g_cvMapStatusWebhook.GetString(g_sMapStatusWebhook, sizeof(g_sMapStatusWebhook));
    g_cvListenChatWebhook.GetString(g_sListenChatWebhook, sizeof(g_sListenChatWebhook));
    g_cvListenRCONWebhook.GetString(g_sListenRCONWebhook, sizeof(g_sListenRCONWebhook));
    g_cvAdminWebhook.GetString(g_sAdminWebhook, sizeof(g_sAdminWebhook));
    g_cvFilterWords.GetString(g_sFilterWords, sizeof(g_sFilterWords));
    g_cvBlockedMessageColor.GetString(g_sBlockedMessageColor, sizeof(g_sBlockedMessageColor));
    g_cvFooterIconURL.GetString(g_sFooterIconURL, sizeof(g_sFooterIconURL));
    g_cvShowServerIP.GetString(g_sShowServerIP, sizeof(g_sShowServerIP));
    //g_cvPlayerStatusWebhook.GetString(g_sPlayerStatusWebhook, sizeof(g_sPlayerStatusWebhook));
}