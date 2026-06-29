#pragma semicolon 1

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <ripext>

public Plugin myinfo = 
{
	name = "Friend Checker",
	author = PLUGIN_AUTHOR,
	description = "Checks a targets friends to see if they are the server",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/R3TROATTACK/"
};

char g_sAuthId[MAXPLAYERS + 1][128];
ConVar g_cAPIKey;
char g_sAPIKey[255];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_cAPIKey = CreateConVar("friends_api_key", "", "Steam api key");
	g_cAPIKey.AddChangeHook(Hook_APiKeyChange);
	AutoExecConfig(true, "firend_checker");
	RegAdminCmd("sm_friends", Command_Friends, ADMFLAG_GENERIC);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void Hook_APiKeyChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Format(g_sAPIKey, sizeof(g_sAPIKey), newValue);
}

public void OnClientPostAdminCheck(int client)
{
	GetClientAuthId(client, AuthId_SteamID64, g_sAuthId[client], sizeof(g_sAuthId[]));
}

public void OnClientDisconnect_Post(int client)
{
	Format(g_sAuthId[client], sizeof(g_sAuthId[]), "");
}

public void OnConfigsExecuted()
{
	g_cAPIKey.GetString(g_sAPIKey, sizeof(g_sAPIKey));
}

public Action Command_Friends(int client, int args)
{
	if(StrEqual(g_sAPIKey, "", false))
		return Plugin_Handled;
	if(args < 1)
	{
		PrintToChat(client, " \x06[Friends] \x01Format: sm_friends <target>");
		return Plugin_Handled;
	}
	char sArg[128];
	GetCmdArg(1, sArg, sizeof(sArg));
	int target = FindTarget(client, sArg, true);
	if(!IsValidClient(target))
		return Plugin_Handled;

	char url[255];
	Format(url, sizeof(url),"https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=%s&steamid=%s&relation=friend", g_sAPIKey, g_sAuthId[target]);
	
	HTTPRequest request = new HTTPRequest(url);
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(GetClientUserId(target));
	request.Get(HTTPRquest_GetFriendsList, data);
	return Plugin_Handled;
}

public void HTTPRquest_GetFriendsList(HTTPResponse response, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int target = GetClientOfUserId(data.ReadCell());
	delete data;
	if(!IsValidClient(client) || !IsValidClient(target))
		return;
	
	if(response.Status != HTTPStatus_OK){
		PrintToChat(client, " \x06[Friends] \x01The request failed try the command again!");
		return;
	}
	
	JSONObject json = view_as<JSONObject>(response.Data);
	if(!json.HasKey("friendslist")){
		PrintToChat(client, " \x06[Friends] \x01The target has their profile set to either private or hidden!");
		delete json;
		return;
	}
	JSONObject list = view_as<JSONObject>(json.Get("friendslist"));
	delete json;
	if(!list.HasKey("friends")){
		delete list;
		return;
	}
	JSONArray friends = view_as<JSONArray>(list.Get("friends"));
	ArrayList online = new ArrayList();
	for(int i = 0; i < friends.Length; i++)
	{
		json = view_as<JSONObject>(friends.Get(i));
		char authid[64];
		json.GetString("steamid", authid, sizeof(authid));
		int index = IsClientInServer(authid);
		if(index != -1)
			online.Push(index);
		delete json;
	}
	delete friends;

	if(online.Length == 0){
		PrintToChat(client, " \x06[Friends] \x02%N \x01has no friends in this server", target);
	}
	else{
		PrintToChat(client, " \x06[Friends] \x02%N \x01has %d friend%s on this server!", target, online.Length, online.Length == 1 ? "" : "s");
		for (int i = 0; i < online.Length; i++)
			PrintToChat(client, "    \x06%N", online.Get(i));
	}

	delete online;
}

int IsClientInServer(char[] steamid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
			
		if(StrEqual(g_sAuthId[i], "", false))
			GetClientAuthId(i, AuthId_SteamID64, g_sAuthId[i], sizeof(g_sAuthId[]));
		if(StrEqual(steamid, g_sAuthId[i], false))
			return i;
	}
	return -1;
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;
	
	if (!IsClientInGame(client) || !IsClientConnected(client))
		return false;
	
	return true;
}