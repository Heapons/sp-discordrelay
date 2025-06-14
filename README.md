# Discord Relay (Also compatible with [Discord Utilities ](https://github.com/Cruze03/Discord-Utilities-v2)‼)
Discord ⇄ Server Relay for the Source Engine.

# Installation
Download the plugin from [releases](https://github.com/Heapons/sp-discordrelay/releases), put the `.smx` in `<game>/addons/sourcemod/plugins/...`, and edit the convars in `/cfg/sourcemod/discordrelay.cfg` after loading the plugin for the first time.

# Dependencies
(Requires [Sourcemod 1.10](https://www.sourcemod.net/downloads.php?branch=1.10-dev) to Compile!)
- [SteamWorks](https://github.com/KyleSanderson/SteamWorks/blob/master/Pawn/includes/SteamWorks.inc)
- [Discord API](https://github.com/Heapons/discord-api-Killstr3ak)
- [REST in Pawn](https://github.com/ErikMinekus/sm-ripext/tree/main/pawn/scripting/include)
- [AutoExecConfig](https://github.com/Impact123/AutoExecConfig) (Compile)

> [!NOTE]
> If you plan to send messages/requests to the server from discord ensure you have Message Intents enabled in the app dashboard.

![Message Intents](https://user-images.githubusercontent.com/42725021/191847732-36a08338-ca11-4ae3-8584-ddc9a308400a.png)

# Configuration
## ConVars
### Discord Setup
| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_discordbottoken` || Your Discord bot token from the [Discord Developer Portal](https://discord.com/developers/applications) (needed for `discrelay_discordtoserver`). |
| `discrelay_discordwebhook` || Webhook for Discord channel (needed for `discrelay_servertodiscord`). |
| `discrelay_discordserverid` || Discord Server ID, required for Discord to server. |
| `discrelay_channelid` || Channel ID for Discord to server (the channel where the plugin checks for messages to send to the server). |
| `discrelay_rcon_channelid` || Channel ID where RCON commands should be sent. |
| `discrelay_rcon_webhook` || Webhook for RCON responses (required for `discrelay_rcon_printresponse`). |
| `discrelay_serverhibernation_webhook` |  | Webhook for server hibernation notifications. |
| `discrelay_mapstatus_webhook` |  | Webhook for map status (current/previous map) notifications. |
| `discrelay_listenchat_webhook` |  | Webhook for listening to chat notifications. |
| `discrelay_listenrcon_webhook` |  | Webhook for listening to RCON notifications. |

### Plugin Settings
| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_servertodiscord` | `1` | Enables messages sent in the server to be forwarded to Discord. |
| `discrelay_discordtoserver` | `1` | Enables messages sent in Discord to be forwarded to the server (`discrelay_discordbottoken` and `discrelay_discordserverid` must be set). |
| `discrelay_listenannounce` | `1` | Prints a message when the plugin is listening for messages. |
| `discrelay_serverhibernation` | `1` | Prints a message whenever the server enters/exits hibernation. |
| `discrelay_servermessage` | `1` | Prints server say commands to Discord (`discrelay_servertodiscord` required). |
| `discrelay_connectmessage` | `1` | Relays client connection to Discord (`discrelay_servertodiscord` required). |
| `discrelay_disconnectmessage` | `1` | Relays client disconnection messages to Discord (`discrelay_servertodiscord` required). |
| `discrelay_mapchangemessage` | `1` | Relays map changes to Discord (`discrelay_servertodiscord` required). |
| `discrelay_message` | `1` | Relays client messages to Discord (`discrelay_servertodiscord` required). |
| `discrelay_hidecommands` | `!,/` | Hides any message that begins with the specified prefixes (e.g., `!`). Separate multiple prefixes with commas. |
| `discrelay_showservertags` | `1` | Displays `sv_tags` in server status. |
| `discrelay_showservername` | `1` | Displays hostname in server status. |
| `discrelay_showserverip` | `1` | Display the server IP in Map Status. |
| `discrelay_footericonurl` | `https://raw.githubusercontent.com/Heapons/sp-discordrelay/refs/heads/main/steam.png` | Map Status footer icon. |

### Steam API
| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_steamapikey` || Your Steam API key (needed for `discrelay_servertodiscordavatars`). |
| `discrelay_servertodiscordavatars` | `1` | Changes webhook avatar to client's Steam avatar (`discrelay_steamapikey` required). |
| `discrelay_showsteamid` | `name` | Shows the client's Steam ID. Possible values: `bottom`, `top`, `name`, `prepend`, `append` (or leave blank to hide it). |

### RCON
| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_rcon_enabled` | `0` | Enables RCON functionality. |
| `discrelay_rcon_printresponse` | `1` | Prints response from command (`discrelay_rcon_webhook` required). |

### Moderation
| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_adminrole` || Role to mention on Discord for `sm_calladmin`. |
| `discrelay_admin_webhook` || Webhook for admin call notifications. |
| `discrelay_calladmin_cooldown` | `60.0` | Cooldown in seconds for `sm_calladmin` per player.|
| `discrelay_filter_words` || Filter words through Regex expressions.|

### Embeds
> [!NOTE]
> Webhooks default to `discrelay_discordwebhook` when unspecified.

| Cvar | Default | Description |
|------|---------|-------------|
| `discrelay_servermessage_color` | `8650AC` | HEX color for console messages. |
| `discrelay_listenannounce_color` | `F8F8FF` | HEX color for the listening message. |
| `discrelay_serverhibernation_enter_color` | `DC143C` | HEX color for the server hibernation enter message. |
| `discrelay_serverhibernation_exit_color` | `3CB371` | HEX color for the server hibernation exit message. |
| `discrelay_consolemessage_color` | `8650AC` | HEX color for the console message. |
| `discrelay_connectmessage_color` | `3CB371` | HEX color for the connect message. |
| `discrelay_disconnectmessage_color` | `DC143C` | HEX color for the disconnect message. |
| `discrelay_banmessage_color` | `DC143C` | HEX color for the ban message. |
| `discrelay_currentmap_color` | `FFD700` | HEX color for the current map message. |
| `discrelay_previousmap_color` | `DC143C` | HEX color for the previous map message. |
| `discrelay_rcon_printresponse_color` | `2F4F4F` | HEX color for the RCON response message. |
| `discrelay_serverstart_color` | `3CB371` | HEX color for the server start message.|
| `discrelay_serverhibernation_webhook` |  | Webhook for server hibernation notifications. |
| `discrelay_mapstatus_webhook` |  | Webhook for map status (current/previous map) notifications. |
| `discrelay_listenchat_webhook` |  | Webhook for listening to chat notifications. |
| `discrelay_listenrcon_webhook` |  | Webhook for listening to RCON notifications. |
| `discrelay_showserverip` | `1` | Display the server IP in Map Status. |
| `discrelay_footericonurl` | https://raw.githubusercontent.com/Heapons/sp-discordrelay/refs/heads/main/steam.png | Map Status footer icon. |
