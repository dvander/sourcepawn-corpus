#include <sourcemod>
#include <ripext>
#include <multicolors>

#pragma semicolon 1

#define PLUGIN_NAME 				"Sourcebridge"
#define PLUGIN_AUTHOR 				"gabuch2"
#define PLUGIN_DESCRIPTION    		"Allows chat connectivity between SRCDS and a Matterbridge instance"
#define PLUGIN_VERSION 				"0.9.2 beta"
#define PLUGIN_WEBSITE 				"https://www.daijobu.org/"

#define BRIDGE_MAX_MESSAGE_LENGTH 1024
#define BRIDGE_MAX_URL_LENGTH     512
#define BRIDGE_MAX_TOKEN_LENGTH   64
#define BRIDGE_MAX_GATEWAY_LENGTH 64
#define BRIDGE_MAX_DOMAIN_LENGTH  128
#define BRIDGE_MAX_PORT_LENGTH    8

ConVar g_cvarEnabled;
ConVar g_cvarBridgeProtocol;
ConVar g_cvarBridgeHost;
ConVar g_cvarBridgePort;
ConVar g_cvarBridgeGateway;
ConVar g_cvarToken;
ConVar g_cvarSteamToken;
ConVar g_cvarIncoming;
ConVar g_cvarOutgoing;
ConVar g_cvarOutgoing_SystemName;
ConVar g_cvarOutgoing_SystemAvatarUrl;
ConVar g_cvarOutgoing_Chat_ZeroifyAtSign;
//ConVar g_cvarOutgoing_Kills; currently a todo
ConVar g_cvarOutgoing_Join;
ConVar g_cvarOutgoing_Quit;
ConVar g_cvarOutgoing_DisplayMap;
ConVar g_cvarRetry_Delay;

char g_sIncomingUrl[BRIDGE_MAX_URL_LENGTH];
char g_sOutgoingUrl[BRIDGE_MAX_URL_LENGTH];
char g_sGateway[BRIDGE_MAX_GATEWAY_LENGTH];
char g_sToken[BRIDGE_MAX_TOKEN_LENGTH];
char g_sSteamToken[BRIDGE_MAX_TOKEN_LENGTH];
char g_sPlayerAvatar[BRIDGE_MAX_URL_LENGTH][MAXPLAYERS];
char g_sSystemAvatar[BRIDGE_MAX_URL_LENGTH];
char g_sSystemName[MAX_NAME_LENGTH];

public Plugin:myinfo =
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_WEBSITE
};

public OnPluginStart()
{
    g_cvarEnabled = CreateConVar("sm_sourcebridge_enabled", "1", "Enable Sourcebridge.");
    g_cvarBridgeProtocol = CreateConVar("sm_sourcebridge_protocol", "http", "Protocol of your Matterbridge instance (http/https).\nIt takes effect after restart.");
    g_cvarBridgeHost = CreateConVar("sm_sourcebridge_host", "localhost", "Domain of where your Matterbridge instance is hosted.\nIt takes effect after restart.");
    g_cvarBridgePort = CreateConVar("sm_sourcebridge_port", "1337", "Port on where your Matterbridge instance is running.\nIt takes effect after restart.");
    g_cvarBridgeGateway = CreateConVar("sm_sourcebridge_gateway", "", "Matterbridge gateway on where Sourcebridge should connect to.\nIt takes effect after restart.");
    g_cvarToken = CreateConVar("sm_sourcebridge_token", "", "Token of your Matterbridge gateway.\nIt takes effect after restart.");
    g_cvarSteamToken = CreateConVar("sm_sourcebridge_steam_token", "", "Token for Steam API queries. Required for player avatars.\nIt takes effect after restart.");
    g_cvarIncoming = CreateConVar("sm_sourcebridge_incoming", "1", "Define whether Sourcebridge should print incoming messages.");
    g_cvarOutgoing = CreateConVar("sm_sourcebridge_outgoing", "1", "Define whether Sourcebridge should send server chat messages.");
    g_cvarOutgoing_SystemName = CreateConVar("sm_sourcebridge_outgoing_system_name", "Server", "The name of system messages whenever they get send to the Matterbridge instance (join/leaves, kills, etc).\nIt takes effect after restart.");
    g_cvarOutgoing_SystemAvatarUrl = CreateConVar("sm_sourcebridge_outgoing_system_avatar", "", "URL pointing to the avatar system messages should use.\nIt takes effect after restart.");
    g_cvarOutgoing_Chat_ZeroifyAtSign = CreateConVar("sm_sourcebridge_outgoing_chat_zwsp_at", "1", "Define whether the plugin should add a zero-width space after the @ sign in the messages.");
    // g_cvarOutgoing_Kills = CreateConVar("sm_sourcebridge_outgoing_kills", "0", "Define whether the plugin should output kill messages."); TODO, it's not done yet
    g_cvarOutgoing_Join = CreateConVar("sm_sourcebridge_outgoing_join", "1", "Define whether the plugin should output join messages.");
    g_cvarOutgoing_Quit = CreateConVar("sm_sourcebridge_outgoing_quit", "1", "Define whether the plugin should output leave messages.");
    g_cvarOutgoing_DisplayMap = CreateConVar("sm_sourcebridge_outgoing_display_map", "1", "Define whether the plugin should output the map name at the start of the game.");
    g_cvarRetry_Delay = CreateConVar("sm_sourcebridge_retry_delay", "3", "Define how much Sourcebridge should wait before querying new incoming messages.\nIt takes effect after restart.");

    //Execute the config file
    AutoExecConfig(true, "sourcebridge");
}

public void OnConfigsExecuted()
{
    PrintToServer("***************************************************");
    PrintToServer("** Sourcebridge is in beta state.");
    PrintToServer("** The plugin is usable but it may have bugs.");
    PrintToServer("** It also may not have all the features");
    PrintToServer("** like its AMXX counterpart. (MatterAMXX)");
    PrintToServer("** ");
    PrintToServer("** Please report bugs on: https://forums.alliedmods.net/showthread.php?p=2780049");
    PrintToServer("***************************************************");

    if(GetConVarBool(g_cvarEnabled))
    {
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] Plugin is enabled, procesing initial cvars");
        char sPort[BRIDGE_MAX_PORT_LENGTH], 
            sHost[BRIDGE_MAX_DOMAIN_LENGTH], 
            sProtocol[BRIDGE_MAX_PORT_LENGTH];
        GetConVarString(g_cvarBridgeProtocol, sProtocol, sizeof(sProtocol));
        GetConVarString(g_cvarBridgeHost, sHost, sizeof(sHost));
        GetConVarString(g_cvarBridgePort, sPort, sizeof(sPort));

        FormatEx(g_sIncomingUrl, sizeof(g_sIncomingUrl), "%s://%s:%s/api/messages", sProtocol, sHost, sPort);
        FormatEx(g_sOutgoingUrl, sizeof(g_sOutgoingUrl), "%s://%s:%s/api/message", sProtocol, sHost, sPort);
        GetConVarString(g_cvarToken, g_sToken, sizeof(g_sToken));
        GetConVarString(g_cvarSteamToken, g_sSteamToken, sizeof(g_sSteamToken));
        GetConVarString(g_cvarBridgeGateway, g_sGateway, sizeof(g_sGateway));
        GetConVarString(g_cvarOutgoing_SystemAvatarUrl, g_sSystemAvatar, sizeof(g_sSystemAvatar));
        GetConVarString(g_cvarOutgoing_SystemName, g_sSystemName, sizeof(g_sSystemName));

        if(IsPluginDebugging(INVALID_HANDLE))
        {
            PrintToServer("[Sourcebridge Debug] Desired URL for incoming messages is %s", g_sIncomingUrl);
            PrintToServer("[Sourcebridge Debug] Desired URL for outgoing messages is %s", g_sIncomingUrl);
            PrintToServer("[Sourcebridge Debug] The bridge gateway is %s", g_sGateway);
            PrintToServer("[Sourcebridge Debug] The secret token is %s", g_sToken);
            PrintToServer("[Sourcebridge Debug] Creating initial timer of %f", GetConVarFloat(g_cvarRetry_Delay));
        }

        CreateTimer(GetConVarFloat(g_cvarRetry_Delay), ReadMessagesFromBridge, _, TIMER_REPEAT);

        if(GetConVarBool(g_cvarOutgoing_DisplayMap))
        {
            char sMessage[MAX_MESSAGE_LENGTH], sMapname[MAX_NAME_LENGTH];
            GetCurrentMap(sMapname, sizeof(sMapname));
            Format(sMessage, sizeof(sMessage), "* Starting map %s.", sMapname);
            SendMessageRest(g_sSystemName, sMessage, g_sSystemAvatar);
        }
    }
}

public Action ReadMessagesFromBridge(Handle timer, any param)
{
    if(GetConVarBool(g_cvarIncoming))
    {
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] Executing ReadMessagesFromBridge, procecssing GET request.");
        HTTPRequest http_hRequest = new HTTPRequest(g_sIncomingUrl); 
        http_hRequest.SetHeader("Authorization", "Bearer %s", g_sToken); 
        http_hRequest.Get(OnMessagesReceived);
    }
}

public void OnMessagesReceived(HTTPResponse http_oResponse, any uValue)
{
    if(IsPluginDebugging(INVALID_HANDLE))
    {
        PrintToServer("[Sourcebridge Debug] Got a response, processing.");
        PrintToServer("[Sourcebridge Debug] Response: %i", http_oResponse.Status);
    }

    if(http_oResponse.Status == HTTPStatus_OK)
    {
        char sResponse[4096]; //probably limited to 1024 anyway, same as AMXX's GRIP

        http_oResponse.Data.ToString(sResponse, sizeof(sResponse));

        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] JSON String: %s", sResponse);

        JSONArray json_aResponse = view_as<JSONArray>(JSONArray.FromString(sResponse));

        for(int x = 0; x < json_aResponse.Length;x++)
        {
            JSONObject json_oMessage = view_as<JSONObject>(json_aResponse.Get(x));
            char sUsername[MAX_NAME_LENGTH], sText[BRIDGE_MAX_MESSAGE_LENGTH];

            json_oMessage.GetString("username", sUsername, sizeof(sUsername));
            json_oMessage.GetString("text", sText, sizeof(sText));

            ReplaceString(sText, sizeof(sText), "{", "\\{");
            ReplaceString(sText, sizeof(sText), "}", "\\}");

            CPrintToChatAll("\x01{green}%s\x01 : %s\x01", sUsername, sText);

            delete json_oMessage;
        }

        delete json_aResponse;
    }
    else
    {
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] Failed to access URL");
    }
}  

public Action OnClientSayCommand(int iClient, const char[] sCommand, const char[] sArgs)
{
    if(GetConVarBool(g_cvarOutgoing))
    {
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] I want to send %N's message to the bridge: %s.", iClient, sArgs);
        char sUsername[MAX_NAME_LENGTH], sText[BRIDGE_MAX_MESSAGE_LENGTH];
        GetClientName(iClient, sUsername, sizeof(sUsername));
        strcopy(sText, sizeof(sText), sArgs);
        if(GetConVarBool(g_cvarOutgoing_Chat_ZeroifyAtSign))
        {
            if(IsPluginDebugging(INVALID_HANDLE))
                PrintToServer("[Sourcebridge Debug] Zeroifing at sign.");
            ReplaceString(sText, sizeof(sText), "@", "@​");
        }

        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] Calling SendMessageRest().");
        SendMessageRest(sUsername, sText, g_sPlayerAvatar[iClient]);
    }
    return Plugin_Continue;
}  

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
    if(!IsFakeClient(iClient))
    {
        if(strlen(g_sSteamToken) > 0)
        {
            char sApiUrl[BRIDGE_MAX_URL_LENGTH], sSteamId64[MAX_NAME_LENGTH];
            GetClientAuthId(iClient, AuthId_SteamID64, sSteamId64, sizeof(sSteamId64), true);
            Format(sApiUrl, sizeof(sApiUrl), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s", g_sSteamToken, sSteamId64);
            HTTPRequest http_hSteamReq = new HTTPRequest(sApiUrl); 
            http_hSteamReq.Get(OnPlayerSummaries, iClient);
        }

        if(GetConVarBool(g_cvarOutgoing_Join))
        {
            char sMessage[MAX_MESSAGE_LENGTH];
            Format(sMessage, sizeof(sMessage), "* %N has joined the game.", iClient);
            SendMessageRest(g_sSystemName, sMessage, g_sSystemAvatar);
        }
    }
}

public void OnClientDisconnect(int iClient)
{
    if(!IsFakeClient(iClient))
    {
        if(GetConVarBool(g_cvarOutgoing_Quit))
        {
            char sMessage[MAX_MESSAGE_LENGTH];
            Format(sMessage, sizeof(sMessage), "* %N has left the game.", iClient);
            SendMessageRest(g_sSystemName, sMessage, g_sSystemAvatar);
        }
    }
}

public void OnPlayerSummaries(HTTPResponse http_oResponse, any iClient)
{
    if(IsPluginDebugging(INVALID_HANDLE))
    {
        PrintToServer("[Sourcebridge Debug] Got a response, processing.");
        PrintToServer("[Sourcebridge Debug] Response: %i", http_oResponse.Status);
    }

    if(http_oResponse.Status == HTTPStatus_OK)
    {
        char sResponse[4096];
        http_oResponse.Data.ToString(sResponse, sizeof(sResponse));
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] JSON String: %s", sResponse);

        //this problably needs a refactor
        //pull requests welcomed
        JSONObject json_oHttpResponse = JSONObject.FromString(sResponse);
        JSONObject json_oResponse = view_as<JSONObject>(json_oHttpResponse.Get("response"));
        JSONArray json_aPlayers = view_as<JSONArray>(json_oResponse.Get("players"));
        JSONObject json_oPlayerSummary = view_as<JSONObject>(json_aPlayers.Get(0));
        json_oPlayerSummary.GetString("avatarfull", g_sPlayerAvatar[iClient], sizeof(g_sPlayerAvatar));
        if(IsPluginDebugging(INVALID_HANDLE))
            PrintToServer("[Sourcebridge Debug] Avatar of Client %d is %s", iClient, g_sPlayerAvatar[iClient]);

        delete json_oHttpResponse;
        delete json_oResponse;
        delete json_aPlayers;
        delete json_oPlayerSummary;
    }
}

void SendMessageRest(const char[] sUsername, const char[] sText, const char[] sAvatar, const char[] sId = "")
{
    JSONObject json_oPayload = new JSONObject();

    if(IsPluginDebugging(INVALID_HANDLE))
    {
        PrintToServer("[Sourcebridge Debug] Reached SendMessageRest().");
        PrintToServer("[Sourcebridge Debug] __ Preparing payload __");
        PrintToServer("[Sourcebridge Debug] text : %s", sText);
        PrintToServer("[Sourcebridge Debug] username : %s", sUsername);
        PrintToServer("[Sourcebridge Debug] avatar : %s", sAvatar);
        PrintToServer("[Sourcebridge Debug] gateway : %s", g_sGateway);
        PrintToServer("[Sourcebridge Debug] id : %s", sId);
    }
    json_oPayload.SetString("text", sText);
    json_oPayload.SetString("username", sUsername);
    json_oPayload.SetString("avatar", sAvatar); //todo, get avatar from steam API
    json_oPayload.SetString("gateway", g_sGateway);
    json_oPayload.SetString("id", sId);
    //payload.SetString("protocol", g_sGamename);

    HTTPRequest http_hRequest = new HTTPRequest(g_sOutgoingUrl);
    http_hRequest.SetHeader("Authorization", "Bearer %s", g_sToken); 
    http_hRequest.Post(json_oPayload, OnMessagesSent);
    delete json_oPayload;  
}

public void OnMessagesSent(HTTPResponse http_oResponse, any uValue)
{
    if(IsPluginDebugging(INVALID_HANDLE))
    {
        PrintToServer("[Sourcebridge Debug] Processing OnMessageSent().");
        PrintToServer("[Sourcebridge Debug] Got a response, processing.");
        PrintToServer("[Sourcebridge Debug] Response: %i", http_oResponse.Status);
    }
    // todo: should we store info about the succesful sent message?
    // if(response.Status == HTTPStatus_OK)
    // {
    //     //
    // }
}