#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

#define STEAM_API		"http://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001/"

new Handle:cvarApiKey;
new Handle:cvarDealMethod;
new Handle:cvarFailMethod;

new bool:needsToBeWarned[MAXPLAYERS + 1];

public Plugin:myinfo = {
	name        = "[TF2] Backpack Checker",
	author      = "Dr. McKay",
	description = "Checks if a client's backpack is public and deals with them if it's not",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

public OnPluginStart() {
	cvarApiKey = CreateConVar("backpack_checker_api_key", "", "Steam Web API key, obtained from steamcommunity.com/dev");
	cvarDealMethod = CreateConVar("backpack_checker_deal_method", "1", "When a client's backpack is private: 1 = kick, 2 = warn client, 3 = warn admins, 4 = warn client and admins");
	cvarFailMethod = CreateConVar("backpack_checker_fail_method", "1", "When Steam is down: 1 = allow them on the server, 2 = allow & warn admins");
	HookEvent("player_spawn", Event_PlayerSpawn);
	LoadTranslations("backpackchecker.phrases");
}

public OnClientAuthorized(client, const String:auth[]) {
	needsToBeWarned[client] = false;
	if(IsFakeClient(client) || StrEqual(auth, "BOT", false)) {
		return;
	}
	decl String:steamid[64], String:apiKey[64];
	GetConVarString(cvarApiKey, apiKey, sizeof(apiKey));
	Steam_GetCSteamIDForClient(client, steamid, sizeof(steamid));
	new HTTPRequestHandle:request = Steam_CreateHTTPRequest(HTTPMethod_GET, STEAM_API);
	Steam_SetHTTPRequestGetOrPostParameter(request, "key", apiKey);
	Steam_SetHTTPRequestGetOrPostParameter(request, "steamid", steamid);
	Steam_SetHTTPRequestGetOrPostParameter(request, "format", "vdf");
	Steam_SendHTTPRequest(request, OnSteamAPI, GetClientUserId(client));
}

public OnSteamAPI(HTTPRequestHandle:request, bool:successful, HTTPStatusCode:statusCode, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	if(!successful || statusCode != HTTPStatusCode_OK) {
		LogError("%L Steam API error. Request %s, status code %d.", client, successful ? "successful" : "unsuccessful", _:statusCode);
		if(GetConVarInt(cvarFailMethod) == 2) {
			SendMessageToAdmins("Steam failed", client);
		}
		Steam_ReleaseHTTPRequest(request);
		return;
	}
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/backpack_checker.txt");
	Steam_WriteHTTPResponseBody(request, path);
	Steam_ReleaseHTTPRequest(request);
	new Handle:kv = CreateKeyValues("response");
	if(!FileToKeyValues(kv, path)) {
		LogError("%L Steam API returned invalid KeyValues.", client);
		CloseHandle(kv);
		if(GetConVarInt(cvarFailMethod) == 2) {
			SendMessageToAdmins("Steam failed", client);
		}
		return;
	}
	new status = KvGetNum(kv, "status");
	CloseHandle(kv);
	if(status == 15) {
		switch(GetConVarInt(cvarDealMethod)) {
			case 1: KickClient(client, "%t", "Kick message");
			case 2: needsToBeWarned[client] = true;
			case 3: SendMessageToAdmins("Client private backpack", client);
			case 4: {
				needsToBeWarned[client] = true;
				SendMessageToAdmins("Client private backpack", client);
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) < 2) {
		return; // Spawning into spectate or Unassigned
	}
	if(needsToBeWarned[client]) {
		needsToBeWarned[client] = false;
		PrintToChat(client, "\x04[SM] \x01%t", "Warning message");
	}
}

SendMessageToAdmins(const String:translationName[], client) {
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || !CheckCommandAccess(client, "BackpackCheckerAdmin", ADMFLAG_GENERIC)) {
			continue;
		}
		PrintToChat(i, "\x04[SM] \x01%t", translationName, name);
	}
}