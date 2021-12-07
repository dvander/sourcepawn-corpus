#pragma semicolon 1

//#define DEBUG 1

#define PLUGIN_NAME         "Discord Relay"
#define PLUGIN_AUTHOR       "log-ical"
#define PLUGIN_DESCRIPTION  "Discord and Server interaction"
#define PLUGIN_VERSION      "0.6.0"
#define PLUGIN_URL          "https://github.com/IsThatLogic/sp-discordrelay"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <discord>
#include <geoip>
#include <multicolors>
#undef REQUIRE_EXTENSIONS
#include <ripext>

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

DiscordBot g_dBot;

enum struct playerData
{
	int userid;
	char avatarurl[256];
}

playerData playersdata[MAXPLAYERS + 1];

#define GREEN "#008000"
#define RED "#ff2222"
#define YELLOW "#daa520"

bool maptimer = false;

ConVar g_cvmsg_textcol; char g_msg_textcol[32];
ConVar g_cvmsg_varcol; char g_msg_varcol[32];

ConVar g_cvSteamApiKey; char g_sSteamApiKey[128];
ConVar g_cvDiscordBotToken; char g_sDiscordBotToken[128];
ConVar g_cvDiscordWebhook; char g_sDiscordWebhook[256];

ConVar g_cvDiscordServerId; char g_sDiscordServerId[64];
ConVar g_cvChannelId; char g_sChannelId[64];

ConVar g_cvSBPPAvatar; char g_sSBPPAvatar[64];

ConVar g_cvServerToDiscord; //requires discord bot key
ConVar g_cvDiscordToServer; //requires discord webhook
ConVar g_cvServerToDiscordAvatars; //requires steam api key

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

public void OnPluginStart()
{
    g_cvSteamApiKey = CreateConVar("discrelay_steamapikey", "", "Your Steam API key (needed for discrelay_servertodiscordavatars)");
    g_cvDiscordBotToken = CreateConVar("discrelay_discordbottoken", "", "Your discord bot key (needed for discrelay_discordtoserver)");
    g_cvDiscordWebhook = CreateConVar("discrelay_discordwebhook", "", "Webhook for discord channel (needed for discrelay_servertodiscord)");

    g_cvDiscordServerId = CreateConVar("discrelay_discordserverid", "", "Discord Server Id, required for discord to server");
    g_cvChannelId = CreateConVar("discrelay_channelid", "", "Channel Id for discord to server (This channel would be the one where the plugin check for messages to send to the server)");

    g_cvServerToDiscord = CreateConVar("discrelay_servertodiscord", "1", "Enables messages sent in the server to be forwarded to discord");
    g_cvDiscordToServer = CreateConVar("discrelay_discordtoserver", "1", "Enables messages sent in discord to be forwarded to server (discrelay_discordtoserver and discrelay_discordbottoken need to be set)");
    g_cvServerToDiscordAvatars = CreateConVar("discrelay_servertodiscordavatars", "1", "Changes webhook avatar to clients steam avatar (discrelay_servertodiscord needs to set to 1, and steamapi key needs to be set)");

    g_cvServerMessage = CreateConVar("discrelay_servermessage", "1", "Prints server say commands to discord (discrelay_servertodiscord needs to set to 1)");
    g_cvConnectMessage = CreateConVar("discrelay_connectmessage", "1", "relays client connection to discord (discrelay_servertodiscord needs to set to 1)");
    g_cvDisconnectMessage = CreateConVar("discrelay_disconnectmessage", "1", "relays client disconnection messages to discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMapChangeMessage = CreateConVar("discrelay_mapchangemessage", "1", "relays map changes to discord (discrelay_servertodiscord needs to set to 1)");
    g_cvMessage = CreateConVar("discrelay_message", "1", "relays client messages to discord (discrelay_servertodiscord needs to set to 1)");
    g_cvHideExclamMessage = CreateConVar("discrelay_hideexclammessage", "1", "Hides any message that begins with !");

    g_cvmsg_textcol = CreateConVar("discrelay_msg_textcol", "{default}", "text color of discord to server text (refer to github for support, the ways you can chose colors depends on game)");
    g_cvmsg_varcol = CreateConVar("discrelay_msg_varcol", "{default}", "variable color of discord to server text (refer to github for support, the ways you can chose colors depends on game)");
    
    g_cvPrintSBPPBans = CreateConVar("discrelay_printsbppbans", "0", "Prints bans to channel that webhook points to, sbpp must be installed for this to function");
    g_cvPrintSBPPComms = CreateConVar("discrelay_printsbppcomms", "0", "Prints comm bans to channel that webhook pints to, sbpp must be installed for this to function");
    
    g_cvSBPPAvatar = CreateConVar("discrelay_sbppavatar", "", "Image url the webhook will use for profile avatar for sourcebans++ functions, leave blank for default discord avatar");
    AutoExecConfig(true, "discordrelay");

    
    GetConVarString(g_cvSteamApiKey, g_sSteamApiKey, sizeof(g_sSteamApiKey));
    GetConVarString(g_cvDiscordWebhook, g_sDiscordWebhook, sizeof(g_sDiscordWebhook));

    GetConVarString(g_cvDiscordServerId, g_sDiscordServerId, sizeof(g_sDiscordServerId));
    GetConVarString(g_cvChannelId, g_sChannelId, sizeof(g_sChannelId));

    GetConVarString(g_cvmsg_textcol, g_msg_textcol, sizeof(g_msg_textcol));
    GetConVarString(g_cvmsg_varcol, g_msg_varcol, sizeof(g_msg_varcol));

    GetConVarString(g_cvSBPPAvatar, g_sSBPPAvatar, sizeof(g_sSBPPAvatar));

    g_cvSteamApiKey.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordBotToken.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvDiscordWebhook.AddChangeHook(OnDiscordRelayCvarChanged);

    g_cvDiscordServerId.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvChannelId.AddChangeHook(OnDiscordRelayCvarChanged);

    g_cvmsg_textcol.AddChangeHook(OnDiscordRelayCvarChanged);
    g_cvmsg_varcol.AddChangeHook(OnDiscordRelayCvarChanged);

    g_cvSBPPAvatar.AddChangeHook(OnDiscordRelayCvarChanged);

    if(g_cvDiscordToServer.BoolValue) {
        CreateTimer(5.0, Timer_CreateBot);
    }
}


public Action Timer_CreateBot(Handle timer)
{
    GetConVarString(g_cvDiscordBotToken, g_sDiscordBotToken, sizeof(g_sDiscordBotToken));
    if(g_sDiscordBotToken[0]){
        g_dBot = new DiscordBot(g_sDiscordBotToken);
        CreateTimer(5.0, Timer_GetGuildList, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    else{
        //temp fix for bot being created with token that doesn't exist yet
        CreateTimer(5.0, Timer_CreateBot);
    }
}

public void OnDiscordRelayCvarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    g_cvSteamApiKey.GetString(g_sSteamApiKey, sizeof(g_sSteamApiKey));
    g_cvDiscordBotToken.GetString(g_sDiscordBotToken, sizeof(g_sDiscordBotToken));
    g_cvDiscordWebhook.GetString(g_sDiscordWebhook, sizeof(g_sDiscordWebhook));
    g_cvDiscordServerId.GetString(g_sDiscordServerId, sizeof(g_sDiscordServerId));
    g_cvChannelId.GetString(g_sChannelId, sizeof(g_sChannelId));
    g_cvmsg_textcol.GetString(g_msg_textcol, sizeof(g_msg_textcol));
    g_cvmsg_varcol.GetString(g_msg_varcol, sizeof(g_msg_varcol));
    g_cvSBPPAvatar.GetString(g_sSBPPAvatar, sizeof(g_sSBPPAvatar));
}

public void OnClientPutInServer(int client)
{
    if(!IsValidClient(client))
       return;
    
    playersdata[client].userid = GetClientUserId(client);
    
    if(g_cvServerToDiscordAvatars.BoolValue)
    {
        SteamAPIRequest(client);
    }
    else {
        if(g_cvConnectMessage.BoolValue) {
            PrintToDiscord(client, GREEN, "connected");
        }
    }
}

public void OnMapStart()
{   
    if(maptimer)
        return;
    maptimer = true;
    CreateTimer(5.0, mapstarttimer);
    char buffer[64];
    GetCurrentMap(buffer, sizeof(buffer));
    PrintToDiscordMapChange(buffer, YELLOW);
}

public Action mapstarttimer(Handle timer)
{
    maptimer = false;
}

public void OnClientDisconnect(int client)
{
    if(!IsValidClient(client))
        return;
    if(!g_cvDisconnectMessage.BoolValue)
        return;
    PrintToDiscord(client, RED, "disconnected");
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
    if(g_cvHideExclamMessage.BoolValue) {
        if(!strncmp(sArgs, "!", 1) || !strncmp(sArgs, "/", 1)) { 
            return;
        }
    }
    char buffer[128];
    //this might be unsafe
    //max amount of char in message is 127 so this should be fine
    strcopy(buffer, sizeof(buffer), sArgs);
    for(int i=0; i< sizeof(buffer) ; i++)
    {
        if(StrContains(buffer, "@", false))
        {
            ReplaceString(buffer, sizeof(buffer), "@", "＠");
        }
    }
    PrintToDiscordSay(client, buffer);
}

public void SBPP_OnBanPlayer(int admin, int target, int time, const char[] reason)
{
    if(!g_cvPrintSBPPBans.BoolValue)
        return;
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;

    hook.SetAvatar(g_sSBPPAvatar);
    
    hook.SetUsername("Player Banned");
    
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetColor("#e5e5e5");
    
    char bsteamid[65];
    char bplayerName[512];
    GetClientAuthId(target, AuthId_SteamID64, bsteamid, sizeof(bsteamid));
    Format(bplayerName, sizeof(bplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", target, bsteamid);
    //Banned Player Link Embed


    char asteamid[65];
    char aplayerName[512];
    if(!IsValidClient(admin))
    {
        Format(aplayerName, sizeof(aplayerName), "Server");
    }
    else{
    GetClientAuthId(admin, AuthId_SteamID64, asteamid, sizeof(asteamid));
    Format(aplayerName, sizeof(aplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", admin, asteamid);
    //Admin Link Embed
    }

    char banMsg[512];
    Format(banMsg, sizeof(banMsg), "%s has been banned by %s", bplayerName, aplayerName);
    Embed.AddField("", banMsg, false);


    Embed.AddField("Reason: ", reason, true);
    char sTime[16];
    IntToString(time, sTime, sizeof(sTime));
    Embed.AddField("Length: ", sTime, true);

    char hostname[64];
    GetHostName(hostname, sizeof(hostname));
    Embed.SetFooter(hostname);
    Embed.SetFooterIcon(g_sSBPPAvatar);

    Embed.SetTitle("SourceBans");
    
    hook.Embed(Embed);

    hook.Send();
    delete hook;
}
public void SourceComms_OnBlockAdded(int admin, int target, int time, int type, char[] reason)
{
    if(!g_cvPrintSBPPComms.BoolValue)
        return;
    if(type>3)
        return;
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    hook.SlackMode = true;

    hook.SetAvatar(g_sSBPPAvatar);
    
    char usrname[32];
    Format(usrname, sizeof(usrname), "Player %s", CommbanTypes[type]);
    hook.SetUsername(usrname);
    
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetColor("#e5e5e5");
    
    char bsteamid[65];
    char bplayerName[512];
    GetClientAuthId(target, AuthId_SteamID64, bsteamid, sizeof(bsteamid));
    Format(bplayerName, sizeof(bplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", target, bsteamid);
    //Banned Player Link Embed


    char asteamid[65];
    char aplayerName[512];
    if(!IsValidClient(admin))
    {
        Format(aplayerName, sizeof(aplayerName), "Server");
    }
    else{
    GetClientAuthId(admin, AuthId_SteamID64, asteamid, sizeof(asteamid));
    Format(aplayerName, sizeof(aplayerName), "[%N](http://www.steamcommunity.com/profiles/%s)", admin, asteamid);
    //Admin Link Embed
    }

    char banMsg[512];
    Format(banMsg, sizeof(banMsg), "%s has been %s by %s", bplayerName, lCommbanTypes[type], aplayerName);
    Embed.AddField("", banMsg, false);


    Embed.AddField("Reason: ", reason, true);
    char sTime[16];
    IntToString(time, sTime, sizeof(sTime));
    Embed.AddField("Length: ", sTime, true);

    char hostname[64];
    GetHostName(hostname, sizeof(hostname));
    Embed.SetFooter(hostname);
    Embed.SetFooterIcon(g_sSBPPAvatar);

    Embed.SetTitle("SourceComms");
    
    hook.Embed(Embed);

    hook.Send();
    delete hook;
}


public void PrintToDiscord(int client, const char[] color, const char[] msg, any ...)
{
    if(!g_cvServerToDiscord.BoolValue)
        return;
    if(!g_cvMessage.BoolValue)
        return;
    
    char clientName[32];
    GetClientName(client, clientName, 32);
    
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    
    hook.SlackMode = true;

    if(g_cvServerToDiscordAvatars.BoolValue)
        hook.SetAvatar(playersdata[client].avatarurl);
    
    char steamid1[64];
    GetClientAuthId(client, AuthId_Steam2, steamid1, sizeof(steamid1));
    char buffer[128];
    Format(buffer, 128, "%s [%s]", clientName, steamid1);
    hook.SetUsername(buffer);
    
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetColor(color);
    
    char steamid[65];
    char playerName[512];
    char embedMsg[64];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    Format(playerName, sizeof(playerName), "[%N](http://www.steamcommunity.com/profiles/%s)", client, steamid);

    Embed.AddField("", playerName, true);
    if(StrEqual(msg, "connected"))
    {
        char clientCountry[46];
        char clientIP[32];  
        GetClientIP(client, clientIP, sizeof(clientIP));
        GeoipCountry(clientIP, clientCountry, sizeof(clientCountry));
        Format(embedMsg, sizeof(embedMsg), "%s from %s", msg, clientCountry);
        Embed.AddField("", embedMsg, true);
    }
    else{
        Embed.AddField("", msg, true);
    }
    
    hook.Embed(Embed);

    hook.Send();
    delete hook;

}

public void PrintToDiscordSay(int client, const char[] msg, any ...)
{
    if(!g_cvServerToDiscord.BoolValue)
        return;

    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);

    hook.SlackMode = true;

    if(!IsValidClient(client))
    {
        if(!g_cvServerMessage.BoolValue)
            return;
        hook.SetContent(msg);
        //we will just assume that if it isn't a valid client then it must be the server
        hook.SetUsername("Server");
        hook.Send();
        return;
    }
    
    char clientName[32];
    GetClientName(client, clientName, 32);

    if(g_cvServerToDiscordAvatars.BoolValue)
        hook.SetAvatar(playersdata[client].avatarurl);

    hook.SetContent(msg);

    char steamid[64];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    char buffer[128];
    Format(buffer, 128, "%s [%s]", clientName, steamid);
    hook.SetUsername(buffer);

    hook.Send();
    delete hook;
}

public void PrintToDiscordMapChange(const char[] map, const char[] color)
{
    if(!g_cvServerToDiscord.BoolValue)
        return;
    if(!g_cvMapChangeMessage.BoolValue)
        return;
    DiscordWebHook hook = new DiscordWebHook(g_sDiscordWebhook);
    
    hook.SlackMode = true;
    
    hook.SetUsername("Map Change");
    
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetColor(color);
    
    Embed.AddField("New Map:", map, true);
    
    hook.Embed(Embed);

    hook.Send();
    delete hook;

}

public Action Timer_GetGuildList(Handle timer)
{
    ParseGuilds();
}

stock void ParseGuilds()
{	
    g_dBot.GetGuilds(GuildList);
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
    g_dBot.GetGuildChannels(id, ChannelList, INVALID_FUNCTION);
}

public void ChannelList(DiscordBot bot, const char[] guild, DiscordChannel chl, any data)
{
	if(StrEqual(guild, g_sDiscordServerId))
	{
		if(g_dBot == null || chl == null)
		{
			return;
		}
		if(g_dBot.IsListeningToChannel(chl))
		{
			return;
		}
		char id[20], name[32];
		chl.GetID(id, sizeof(id));
		chl.GetName(name, sizeof(name));
		if(StrEqual(id, g_sChannelId))
        {
			g_dBot.StartListeningToChannel(chl, OnDiscordMessageSent);
		}
	}
}

public void OnDiscordMessageSent(DiscordBot bot, DiscordChannel chl, DiscordMessage discordmessage)
{
	DiscordUser author = discordmessage.GetAuthor();
	if(author.IsBot()) 
	{
		delete author;
		return;
	}

	char message[512];
	char discorduser[32], discriminator[6];
	discordmessage.GetContent(message, sizeof(message));
	author.GetUsername(discorduser, sizeof(discorduser));
	author.GetDiscriminator(discriminator, sizeof(discriminator));
	delete author;

	CPrintToChatAll("%s[%sDiscord%s] %s%s%s#%s%s%s: %s", 	g_msg_textcol, g_msg_varcol, g_msg_textcol,
															g_msg_varcol, discorduser, g_msg_textcol,
															g_msg_varcol, discriminator, g_msg_textcol,
															message);
}

stock void SteamAPIRequest(int client)
{
    HTTPClient httpClient;
    char endpoint[1024];
    char steamid[64];

    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    Format(endpoint, sizeof(endpoint), "ISteamUser/GetPlayerSummaries/v2/?key=%s&steamids=%s", g_sSteamApiKey, steamid);
    httpClient = new HTTPClient("https://api.steampowered.com/");

    httpClient.Get(endpoint, SteamResponse_Callback, client);

}

stock void SteamResponse_Callback(HTTPResponse response, int client)
{
    if (response.Status != HTTPStatus_OK){
        LogError("SteamAPI request fail, HTTPSResponse code %i", response.Status);
        return;
    }
    JSONObject objects = view_as<JSONObject>(response.Data);
    JSONObject Response = view_as<JSONObject>(objects.Get("response"));
    JSONArray players = view_as<JSONArray>(Response.Get("players"));
    int playerlen = players.Length;
    JSONObject player;
    for (int i = 0; i < playerlen; i++)
    {
        player = view_as<JSONObject>(players.Get(i));
        player.GetString("avatarmedium", playersdata[client].avatarurl, sizeof(playerData::avatarurl));
        delete player;
    }
 
    /*connection message delayed so steamapi has time to fetch what it needs*/
    if(g_cvConnectMessage.BoolValue)
        PrintToDiscord(client, GREEN, "connected");
}

stock bool IsValidClient(int client)
{
    if (client <= 0)
        return false;
    
    if (client > MaxClients)
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    if (IsFakeClient(client))
        return false;

    return IsClientInGame(client);
}

void GetHostName(char[] str, int size)
{
    static Handle hHostName;
    
    if(hHostName == INVALID_HANDLE)
    {
        if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
        {
            return;
        }
    }
    GetConVarString(hHostName, str, size);
}  