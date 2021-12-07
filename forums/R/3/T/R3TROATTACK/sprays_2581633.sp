#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <latedl>
#include <system2>
//#include <clientprefs>

#define BASE_PATH 	"materials/decals/sprays/"
#define BASE_PATH_REL "decals/sprays/"

#pragma newdecls required

enum PlayerSpray
{
	decalIndex, 
	Float:sprayPos[3], 
};

int g_iCustomSprays[MAXPLAYERS][PlayerSpray];
int g_iTransfers[MAXPLAYERS + 1];
float g_fLastSpray[MAXPLAYERS + 1];
bool g_bViewSprays[MAXPLAYERS + 1] = {true, ...};

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "Player Sdprays", 
	author = PLUGIN_AUTHOR, 
	description = "Allows for player created sprays", 
	version = PLUGIN_VERSION, 
	url = "www.memerland.com"
};

ConVar g_cDownloadUrl = null;
char g_sDownloadUrl[256];

ConVar g_cSprayDistance = null;
float g_fSprayDistance = 115.0;
ConVar g_cSprayDelay = null;
float g_fSprayDelay = 10.0;

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(!IsFakeClient(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
	g_cDownloadUrl = CreateConVar("sprays_url", "0.0.0.0", "Download url for player sprays.(ex. http://www.example.com/spraydirectory/sprays/) the trailing slash is important.", FCVAR_NONE);
	g_cSprayDistance = CreateConVar("sprays_distance", "115.0", "How close to the wall must a player be to use their spray", FCVAR_NONE, true, 0.0);
	g_cSprayDelay = CreateConVar("sprays_delay", "10.0", "Time between sprays", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "player_sprays");
	RegAdminCmd("sm_spray", Command_Spray, ADMFLAG_RESERVATION);
}

public void OnConfigsExecuted()
{
	g_fSprayDistance = g_cSprayDistance.FloatValue;
	g_fSprayDelay = g_cSprayDelay.FloatValue;
	g_cDownloadUrl.GetString(g_sDownloadUrl, sizeof(g_sDownloadUrl));
}

public Action Command_Spray(int client, int args)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Handled;
		
	if(g_iCustomSprays[client][decalIndex] == -1)
		return Plugin_Handled;
	
	if(GetGameTime() - g_fLastSpray[client] < g_fSprayDelay)
	{
		float time = GetGameTime() - g_fLastSpray[client];
		time = g_fSprayDelay - time;
		PrintToChat(client, " \x06[Player Sprays] \x01You can use your spray again in \x02%0.2f \x01seconds", time);
		return Plugin_Handled;
	}
	
	float fClientEyePosition[3];
	GetClientEyePosition(client, fClientEyePosition);

	float fClientEyeViewPoint[3];
	GetPlayerEyeViewPoint(client, fClientEyeViewPoint);

	float fVector[3];
	MakeVectorFromPoints(fClientEyeViewPoint, fClientEyePosition, fVector);
	if(GetVectorLength(fVector) > g_fSprayDistance)
	{
		PrintToChat(client, " \x06[Player Sprays] \x01You are too far away from the wall to use your spray.");
		return Plugin_Handled;
	}
	g_fLastSpray[client] = GetGameTime();
	g_iCustomSprays[client][sprayPos] = fClientEyeViewPoint;
	
	TE_SetupBSPDecal(fClientEyeViewPoint, g_iCustomSprays[client][decalIndex]);
	//I need to figure out how to actually do this
	/*int clients[MAXPLAYERS+1], numClients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(!IsFakeClient(i))
			{
				if(g_iTransfers[i] == 0)
				{
					clients[numClients] = i;
					numClients++;
				}
			}
		}
	}
	TE_Send(clients, numClients);*/
	PrintToChat(client, " \x06[Player Sprays] \x01You have sprayed your spray.");
	TE_SendToAll();
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	g_iCustomSprays[client][decalIndex] = -1;
	g_iCustomSprays[client][sprayPos] = NULL_VECTOR;
	g_fLastSpray[client] = GetGameTime();
	if (IsValidClient(client))
	{
		if(CheckCommandAccess(client, "sm_spray", ADMFLAG_RESERVATION))
			CheckForSpray(client);
		QueryClientConVar(client, "sv_allowupload", AllowUpload_Callback);
		//CreateTimer(1.0, Timer_CookieCheck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/*public Action Timer_CookieCheck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(IsFakeClient(client))
		return Plugin_Handled;
	
	if(!AreClientCookiesCached(client))
		return Plugin_Handled;
	return Plugin_Handled;
}*/

public void AllowUpload_Callback(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if(StrEqual(cvarValue, "0")){
		g_bViewSprays[client] = false;
		PrintToChat(client, "Set \"sv_allowupload\" to 1 and reconnect to enable custom player sprays.");
	}else{
		g_bViewSprays[client] = true;
	}
}


public void OnClientDisconnect(int client)
{
	g_iCustomSprays[client][decalIndex] = -1;
	g_iCustomSprays[client][sprayPos] = NULL_VECTOR;
	g_iTransfers[client] = 0;
	g_bViewSprays[client] = true;
}

public void CheckForSpray(int client)
{
	if (!IsValidClient(client))
		return;
	
	char sAuthid[32];
	GetClientAuthId(client, AuthId_SteamID64, sAuthid, sizeof(sAuthid));
	
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "%s%s.vtf", BASE_PATH, sAuthid);
	bool vtf = FileExists(path);
	ReplaceString(path, sizeof(path), ".vtf", ".vmt");
	bool vmt = FileExists(path);
	if (vmt && vtf)
	{
		ReplaceString(path, sizeof(path), ".vmt", "");
		DataPack data;
		CreateDataTimer(1.0, Timer_DownloadDelay, data, TIMER_FLAG_NO_MAPCHANGE);
		data.WriteCell(GetClientUserId(client));
		data.WriteString(path);
	}
	
	Format(path, sizeof(path), "%s%s.vmt", BASE_PATH, sAuthid);
	if(!vmt)
	{
		char sRequest[PLATFORM_MAX_PATH];
		Format(sRequest, sizeof(sRequest), "%s%s.vmt", g_sDownloadUrl, sAuthid);
		PrintToServer("[Player Sprays] Attempting to download %s from %s", path, sRequest);
		System2HTTPRequest httpRequest = new System2HTTPRequest(FileExists_Callback, sRequest);
		httpRequest.SetOutputFile(path);
		httpRequest.GET();
		delete httpRequest;
	}
	
	Format(path, sizeof(path), "%s%s.vtf", BASE_PATH, sAuthid);
	if(!vtf)
	{
		char sRequest[PLATFORM_MAX_PATH];
		Format(sRequest, sizeof(sRequest), "%s%s.vtf", g_sDownloadUrl, sAuthid);
		PrintToServer("[Player Sprays] Attempting to download %s from %s", path, sRequest);
		System2HTTPRequest httpRequest = new System2HTTPRequest(FileExists_Callback, sRequest);
		httpRequest.SetOutputFile(path);
		httpRequest.GET();
		delete httpRequest;
	}
}

public void AddFilesToDownload(char[] path, int client)
{
	char cachePath[PLATFORM_MAX_PATH];
	strcopy(cachePath, sizeof(cachePath), path);
	ReplaceString(cachePath, PLATFORM_MAX_PATH, "materials/", "");
	g_iCustomSprays[client][decalIndex] = PrecacheDecal(cachePath, true);
	char paths[2][PLATFORM_MAX_PATH];
	Format(paths[0], PLATFORM_MAX_PATH, "%s.vtf", path);
	Format(paths[1], PLATFORM_MAX_PATH, "%s.vmt", path);
	if(AddLateDownloads(paths, sizeof(paths)) > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (!IsFakeClient(i))
					g_iTransfers[i]++;
			}
		}
	}
}

public void FileExists_Callback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
	if (success)
	{
		if (response.StatusCode == 404)
			return;
			
		char path[256], sAuth[256];
		//Get the steamid64 and path from the url
		response.GetLastURL(path, sizeof(path));
		ReplaceString(path, sizeof(path), g_sDownloadUrl, "");
		strcopy(sAuth, sizeof(sAuth), path);
		Format(path, sizeof(path), "%s%s", BASE_PATH, path);
		
		ReplaceString(sAuth, sizeof(sAuth), ".vtf", "");
		ReplaceString(sAuth, sizeof(sAuth), ".vmt", "");
		char sOther[256];
		strcopy(sOther, sizeof(sOther), path);
		if(StrContains(sOther, ".vmt", true) != -1){
			ReplaceString(sOther, sizeof(sOther), ".vmt", ".vtf", true);
		}else{
			ReplaceString(sOther, sizeof(sOther), ".vtf", ".vmt", true);
		}
		if(FileExists(sOther))
		{
			int client = SteamidToClient(sAuth);
			if (IsValidClient(client))
			{
				ReplaceString(path, sizeof(path), ".vmt", "", true);
				ReplaceString(path, sizeof(path), ".vtf", "", true);
				DataPack data;
				CreateDataTimer(1.0, Timer_DownloadDelay, data, TIMER_FLAG_NO_MAPCHANGE);
				data.WriteCell(GetClientUserId(client));
				data.WriteString(path);
				//AddFilesToDownload(path, client);
			}
		}
	}
	else
	{
		PrintToServer("Error on request: %s", error);
	}
}

public Action Timer_DownloadDelay(Handle timer, DataPack data)
{
	ResetPack(data);
	int userid = ReadPackCell(data);
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client))
	{
		char path[PLATFORM_MAX_PATH];
		data.ReadString(path, sizeof(path));
		AddFilesToDownload(path, client);
	}
}

public int SteamidToClient(char[] auth)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		if (IsFakeClient(i))
			continue;
		
		char auth2[32];
		GetClientAuthId(i, AuthId_SteamID64, auth2, sizeof(auth2));
		if (StrEqual(auth, auth2, false))
			return i;
	}
	return -1;
}

public void OnDownloadSuccess(int client, char[] name)
{
	if (!IsValidClient(client))
		return;
	g_iTransfers[client]--;
	if (g_iTransfers[client] > 0) {
		PrintToChat(client, " \x06[Player Sprays] \x01You have \x02%d \x01files left to download.", g_iTransfers[client]);
	} else {
		PrintToChat(client, " \x06[Player Sprays] \x01Sprays have now been enabled for you");
	}
}


public void TE_SetupBSPDecal(const float vecOrigin[3], int index) {
	
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nIndex", index);
}

stock bool GetPlayerEyeViewPoint(int iClient, float fPosition[3])
{
	float fAngles[3];
	GetClientEyeAngles(iClient, fAngles);

	float fOrigin[3];
	GetClientEyePosition(iClient, fOrigin);

	Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fPosition, hTrace);
		CloseHandle(hTrace);
		return true;
	}
	CloseHandle(hTrace);
	return false;
}

public bool TraceEntityFilterPlayer(int iEntity, int iContentsMask)
{
	return iEntity > GetMaxClients();
}

public bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;
	if (!IsValidEntity(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsClientConnected(client))
		return false;
	return true;
} 