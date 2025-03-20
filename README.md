# Discord Relay (Also compatible with [Discord Utilities ](https://github.com/Cruze03/Discord-Utilities-v2)‼)
Discord ⇄ Server Relay for the Source Engine.

# Installation
Un-zip [`discordrelay.zip`](https://github.com/Heapons/sp-discordrelay/releases) inside of `<game>/addons/sourcemod/plugins/...` and update convars in `/cfg/sourcemod/discordrelay.cfg` after running the plugin.

# Dependencies
(Requires [Sourcemod 1.10](https://www.sourcemod.net/downloads.php?branch=1.10-dev) to Compile!)
- [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)
- [Discord API](https://github.com/Heapons/discord-api-Killstr3ak)
- [REST in Pawn](https://forums.alliedmods.net/showthread.php?t=298024)

> [!NOTE]
> If you plan to send messages/requests to the server from discord ensure you have Message Intents enabled in the app dashboard.

![Message Intents](https://user-images.githubusercontent.com/42725021/191847732-36a08338-ca11-4ae3-8584-ddc9a308400a.png)

# Configuration
## ConVars
### General Settings
| Cvar | Description |
|------|-------------|
| `discrelay_steamapikey` | This will be your steam API key which you can find at [Steam API Key](https://steamcommunity.com/dev/apikey). The key is used to grab the client's steam avatar. |
| `discrelay_discordbottoken` | Your discord bot token found/created by going to [Discord Developers](https://discord.com/developers/applications), creating an application, creating a bot, and copying the bot token. *You do not need the bot to be running, just having it in your server will work.* |
| `discrelay_discordserverid` | Enable Developer Mode in Discord, right click on the server name in the top left and click Copy ID. Required for communication between Discord and Source. |
| `discrelay_channelid` | Enable Developer Mode in Discord, right click on the channel name and click Copy ID. This is the channel messages will appear in. |
| `discrelay_discordwebhook` | Set this to your Discord channel's webhook URL. You can create one by going to your Discord server, entering a text channel's settings, then in integrations create a webhook and copy the URL. |
| `discrelay_rcon_channelid` | Discord channel ID for where RCON commands should be sent. |
| `discrelay_rcon_webhook` | Webhook for RCON response. |
> [!CAUTION] 
> **Warning to server owners:** Only let people you trust have access to the RCON channel; all messages sent in this channel are considered to be commands.

### Chat Settings
| Cvar | Description |
|------|-------------|
| `discrelay_servertodiscord` | Enable to allow messages sent in the server to be sent through Discord via webhook. |
| `discrelay_discordtoserver` | Enable to allow messages sent in Discord to be sent to the server. |
| `discrelay_servertodiscordavatars` | Change avatar in messages sent to Discord to the client's Steam avatar. Requires a valid Steam API key. |
| `discrelay_message` | Enable to allow client messages in the server to be sent to Discord. This is any message that's not a command, only exception is any ! command which can be hidden by enabling `discrelay_hideexclammessage`. |
| `discrelay_hidecommands` | Hides any message that begins with the specified command prefixes (e.g., `!`). Separated by commas. |
| `discrelay_msg_varcol` | The color used for the variable part of the message that will be sent to the server when doing Discord → Server. |
| `discrelay_msg_prefix` | The prefix for messages sent from Discord to the server. |
| `discrelay_showsteamid` | Displays a Player's Steam ID below every message. |
| `discrelay_showsteamid_mode` | Possible values: `bottom`, `top`, `name`, `prepend`, `append`, `message`. |

### RCON Settings
| Cvar | Description |
|------|-------------|
| `discrelay_rcon_enabled` | Enable RCON functionality. |
| `discrelay_rcon_printreponse` | Prints server response to the command. |
| `discrelay_rcon_highlight` | Syntax highlighting for RCON responses. See: https://highlightjs.org/demo |

### Server Status Settings
| Cvar | Description |
|------|-------------|
| `discrelay_showservertags` | Displays `sv_tags` in server status. |
| `discrelay_showservername` | Displays `hostname` in server status. |
| `discrelay_connectmessage` | Send client connection messages to Discord. |
| `discrelay_disconnectmessage` | Send client disconnection messages to Discord. |
| `discrelay_mapchangemessage` | Send map change messages to Discord. |
