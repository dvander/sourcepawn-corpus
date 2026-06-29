#pragma semicolon 1
#pragma dynamic 262144

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <steamworks>

public Plugin myinfo = 
{
	name = "Friends list checker",
	author = PLUGIN_AUTHOR,
	description = "Checks a targets friends to see if they are the server",
	version = PLUGIN_VERSION,
	url = "www.memerland.com"
};

char g_sAuthId[MAXPLAYERS + 1][128];
ConVar g_cAPIKey;

Handle g_hClientRequests[MAXPLAYERS + 1];
int g_hFriendTarget[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_cAPIKey = CreateConVar("friends_api_key", "12345", "Steam api key");
	RegAdminCmd("sm_friends", Command_Friends, ADMFLAG_GENERIC);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	GetClientAuthId(client, AuthId_SteamID64, g_sAuthId[client], sizeof(g_sAuthId[]));
}

public void OnClientDisconnect_Post(int client)
{
	Format(g_sAuthId[client], sizeof(g_sAuthId[]), "");
}

public Action Command_Friends(int client, int args)
{
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
		
	if(g_hClientRequests[client] != null)
		return Plugin_Handled;
		
	char sQuery[128], sAPIKey[128];
	g_cAPIKey.GetString(sAPIKey, sizeof(sAPIKey));
	if(StrEqual(sAPIKey, "12345", false))
		return Plugin_Handled;
	
	g_hFriendTarget[client] = target;
	Format(sQuery, sizeof(sQuery), "https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=%s&steamid=%s&relation=friend", sAPIKey, g_sAuthId[target]);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sQuery);
	g_hClientRequests[client] = request;
	if (!request || !SteamWorks_SetHTTPCallbacks(request, OnTransferComplete) || !SteamWorks_SendHTTPRequest(request))
	{
		CloseHandle(request);
	}
	return Plugin_Handled;
}

public int OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode:eStatusCode, any data)
{
	int client;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(g_hClientRequests[i] == hRequest)
			client = i;
	}
	if (!bFailure && bRequestSuccessful)
	{
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, APIWebResponse, client);
	}

	CloseHandle(hRequest);
	g_hClientRequests[client] = null;
}

public int APIWebResponse(const char[] sData, any client)
{
	int size = strlen(sData) - 1;
	char[] sTemp = new char[strlen(sData) - 1];
	Format(sTemp, size, "%s", sData);
	ReplaceString(sTemp, strlen(sTemp)-1, "\"friendslist\":", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "\"friends\":", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "{", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "}", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "}", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "[", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "]", "");
	ReplaceString(sTemp, strlen(sTemp)-1, ":", "");
	ReplaceString(sTemp, strlen(sTemp)-1, "\"", "");
	ReplaceString(sTemp, strlen(sTemp)-1, ",", "");
	char sBuffer[1024][512];
	int total = ExplodeString(sTemp, "\n", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]), false);
	Handle array2 = CreateArray();
	for (int i = 0; i < total; i++)
	{
		TrimString(sBuffer[i]);
		if(StrContains(sBuffer[i], "steamid", false) != -1)
		{
			ReplaceString(sBuffer[i], sizeof(sBuffer[]), "steamid", "");
			TrimString(sBuffer[i]);
			int ingame = -1;
			if((ingame = IsClientInServer(sBuffer[i])) != -1)
				PushArrayCell(array2, ingame);
		}
	}
	if(GetArraySize(array2) == 0)
		PrintToChat(client, " \x06[Friends] \x02%N \x01has no friends in this server", g_hFriendTarget[client]);
	else
	{
		int friends = GetArraySize(array2);
		PrintToChat(client, " \x06[Friends] \x02%N \x01has %i friend%s on this server!", g_hFriendTarget[client], friends, friends == 1 ? "" : "s");
		for (int i = 0; i < friends; i++)
		{
			PrintToChat(client, " \x06[Friends] \x01%N", GetArrayCell(array2, i));
		}
	}
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