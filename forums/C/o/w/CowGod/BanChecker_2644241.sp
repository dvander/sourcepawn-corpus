#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "CodingCow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <steamworks>
#include <ripext>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Ban Checker",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar adminOnly;
ConVar steamAPI;

public void OnPluginStart()
{
	adminOnly = CreateConVar("bc_admins_only", "1", "Only prints messages to admins");
	steamAPI = CreateConVar("bc_steamapi", "0", "SteamAPI key needed for api calls");
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client) && steamAPI.IntValue != 0)
	{	
		Handle vac_request = CreateRequest_VacCheck(client);
		SteamWorks_SendHTTPRequest(vac_request);
		
		Handle account_request = CreateRequest_AccountCheck(client);
		SteamWorks_SendHTTPRequest(account_request);
	}
}

Handle CreateRequest_VacCheck(int client)
{
	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	char api_key[128];
	steamAPI.GetString(api_key, sizeof(api_key));
	
	char request_url[256];
	Format(request_url, sizeof(request_url), "https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=%s", api_key);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamids", steamid);
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, VacCheck_OnHTTPResponse);
	return request;
}

public int VacCheck_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		delete request;
		return;
	}
	
	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	
	char[] sBody = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, sBody, iBufferSize);
	
	JSONObject object_root = JSONObject.FromString(sBody);
	JSONArray array_players = view_as<JSONArray>(object_root.Get("players"));
	JSONObject object_player = view_as<JSONObject>(array_players.Get(0));
	bool banned = object_player.GetBool("VACBanned");
	int ban_count = object_player.GetInt("NumberOfVACBans");
	int last_ban = object_player.GetInt("DaysSinceLastBan");
	
	if(banned)
	{
		if(adminOnly.BoolValue)
		{
			char message[255];
			Format(message, sizeof(message), "[\x02Ban-Check\x01] \x04%N \x01has connected with \x0F%i \x01Vac Ban(s) on record! (Last ban \x0F%i \x01days ago)", client, ban_count, last_ban);
			PrintToAdmins(message, "b");  
		}
		else
			PrintToChatAll("[\x02Ban-Check\x01] \x04%N \x01has connected with \x0F%i \x01Vac Ban(s) on record! (Last ban \x0F%i \x01days ago)", client, ban_count, last_ban);
	}
	
	delete object_player;
	delete array_players;
	delete object_root;
	delete request;
}

Handle CreateRequest_AccountCheck(int client)
{
	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	char api_key[128];
	steamAPI.GetString(api_key, sizeof(api_key));
	
	char request_url[256];
	Format(request_url, sizeof(request_url), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s", api_key);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamids", steamid);
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, AcountCheck_OnHTTPResponse);
	return request;
}

public int AcountCheck_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		delete request;
		return;
	}
	
	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	
	char[] sBody = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, sBody, iBufferSize);
	
	JSONObject object_root = JSONObject.FromString(sBody);
	JSONObject object_response = view_as<JSONObject>(object_root.Get("response"));
	JSONArray array_players = view_as<JSONArray>(object_response.Get("players"));
	JSONObject object_player = view_as<JSONObject>(array_players.Get(0));
	int time_created = object_player.GetInt("timecreated");
	
	if(time_created > 1)
	{
		if(GetTime() - time_created <= 604800)
		{
			int days_old = RoundFloat((GetTime() - time_created) / 86400.0);
			
			if(adminOnly.BoolValue)
			{
				char message[255];
				Format(message, sizeof(message), "[\x02Ban-Check\x01] \x04%N \x01has connected with an account \x0F%i \x01days old!", client, days_old);
				PrintToAdmins(message, "b");  
			}
			else
				PrintToChatAll("[\x02Ban-Check\x01] \x04%N \x01has connected with an account \x0F%i \x01days old!", client, days_old);
		}
	}
	else
	{
		if(adminOnly.BoolValue)
		{
			char message[255];
			Format(message, sizeof(message), "[\x02Ban-Check\x01] \x04%N \x01has connected on a \x0Fprivate \x01account!", client);
			PrintToAdmins(message, "b");  
		}
		else
			PrintToChatAll("[\x02Ban-Check\x01] \x04%N \x01has connected on a \x0Fprivate \x01account!", client);
	}
	
	delete object_player;
	delete array_players;
	delete object_root;
	delete object_response;
	delete request;
}

stock void PrintToAdmins(char message[255], char flags[32]) 
{ 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsValidClient(i) && IsValidAdmin(i, flags)) 
        { 
            PrintToChat(i, message); 
        } 
    } 
} 

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

stock bool IsValidAdmin(int client, char flags[32]) 
{ 
    int ibFlags = ReadFlagString(flags); 
    if ((GetUserFlagBits(client) & ibFlags) == ibFlags) 
    { 
        return true; 
    } 
    if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
    { 
        return true; 
    } 
    return false; 
} 