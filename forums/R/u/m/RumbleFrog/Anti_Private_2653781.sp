/*
Anti Private - A sourcemod plugin that kicks private profile & inventory
Copyright (C) 2017  RumbleFrog

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1

#define PLUGIN_AUTHOR "Fishy"
#define PLUGIN_VERSION "1.2.7"

#define DEBUG

#include <sourcemod>
#include <smjansson>
#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#include <steamtools>
#define REQUIRE_EXTENSIONS

#pragma newdecls required

#define STEAMTOOLS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "Steam_CreateHTTPRequest") == FeatureStatus_Available)
#define STEAMWORKS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") == FeatureStatus_Available)

#define PlayerURL "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/"

enum RequestType
{
	t_PROFILE,
	t_INVENTORY
}

enum DealMethod
{
	d_KICK = 1,
	d_WARN
}

enum FailMethod
{
	f_STAY = 1,
	f_KICK,
}

ConVar cKey, cDeal, cFail, cInventory, cLog;

char sDKey[64], InventoryURL[256], LogPath[PLATFORM_MAX_PATH];

bool bInventory = true, bLog = true;

DealMethod iDealMethod;
FailMethod iFailMethod;

public Plugin myinfo = 
{
	name = "Anti Private",
	author = PLUGIN_AUTHOR,
	description = "Kicks private profile & inventory",
	version = PLUGIN_VERSION,
	url = "https://keybase.io/rumblefrog"
};

public void OnPluginStart()
{
	if (!STEAMTOOLS_AVAILABLE() && !STEAMWORKS_AVAILABLE())
		SetFailState("This plugin requires either SteamWorks OR SteamTools");
		
	switch (GetEngineVersion())
	{
		case Engine_TF2:
			InventoryURL = "https://api.steampowered.com/IEconItems_440/GetPlayerItems/v0001/";
		case Engine_DOTA:
			InventoryURL = "https://api.steampowered.com/IEconItems_570/GetPlayerItems/v1/";
		case Engine_Portal2:
			InventoryURL = "https://api.steampowered.com/IEconItems_620/GetPlayerItems/v1/";
		default:
			LogMessage("This game does not support private inventory check");
	}
	
	CreateConVar("sm_anti_private_version", PLUGIN_VERSION, "Anti Private Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	cKey = CreateConVar("sm_anti_private_key", "", "Steam Developer API Key", FCVAR_NONE | FCVAR_PROTECTED);
	cInventory = CreateConVar("sm_anti_private_inventory", "1", "0 - Disable inventory checking, 1 - Enable inventory checking", FCVAR_NONE, true, 0.0, true, 1.0);
	cDeal = CreateConVar("sm_anti_private_deal_method", "1", "1 - Kicks them from the server, 2 - Warns them", FCVAR_NONE, true, 1.0, true, 2.0);
	cFail = CreateConVar("sm_anti_private_fail_method", "1", "1 - Allow them to stay on the server, 2 - Kicks them from the server", FCVAR_NONE, true, 1.0, true, 2.0);
	cLog = CreateConVar("sm_anti_private_log", "1", "0 - Disable logging, 1 - Enable logging", FCVAR_NONE, true, 0.0, true, 1.0);
	
	RegAdminCmd("anti_private_admin", CmdVoid, ADMFLAG_RESERVATION, "Checks user permission level");
	
	LoadTranslations("anti_private.phrases");
	
	AutoExecConfig(true, "anti_private");
	
	BuildPath(Path_SM, LogPath, sizeof LogPath, "logs/anti_private.log");
}

public void OnConfigsExecuted()
{
	cKey.GetString(sDKey, sizeof sDKey);
	cKey.AddChangeHook(OnConVarChanged);
	
	if (StrEqual(sDKey, ""))
		LogError("Steam Developer API Key not set");
		
	bInventory = cInventory.BoolValue;
	cInventory.AddChangeHook(OnConVarChanged);
	
	iDealMethod = view_as<DealMethod>(cDeal.IntValue);
	cDeal.AddChangeHook(OnConVarChanged);
	
	iFailMethod = view_as<FailMethod>(cFail.IntValue);
	cFail.AddChangeHook(OnConVarChanged);
	
	bLog = cLog.BoolValue;
	cLog.AddChangeHook(OnConVarChanged);
}

public Action CmdVoid(int iClient, int iArgs) {}

public void OnClientPostAdminCheck(int iClient)
{
	if (StrEqual(sDKey, ""))
		return;
		
	if (!IsValidClient(iClient))
		return;
	
	if (CheckCommandAccess(iClient, "anti_private_admin", ADMFLAG_RESERVATION))
		return;
		
	char SteamID[64];
	
	GetClientAuthId(iClient, AuthId_SteamID64, SteamID, sizeof SteamID);
		
	if (STEAMWORKS_AVAILABLE())
	{
		Handle hPlayerRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, PlayerURL);
		SteamWorks_SetHTTPRequestGetOrPostParameter(hPlayerRequest, "key", sDKey);
		SteamWorks_SetHTTPRequestGetOrPostParameter(hPlayerRequest, "steamids", SteamID);
		SteamWorks_SetHTTPRequestContextValue(hPlayerRequest, iClient, t_PROFILE);
		SteamWorks_SetHTTPCallbacks(hPlayerRequest, OnSteamWorksHTTPComplete); 
		
		if (!SteamWorks_SendHTTPRequest(hPlayerRequest))
		{
			#if defined DEBUG
				PrintToServer("SteamWorks_SendHTTPRequest Failed");
			#endif

			CloseHandle(hPlayerRequest);
			HandleHTTPError(iClient);
			LogRequest(iClient, t_PROFILE, false);
		}
	}
	else if (STEAMTOOLS_AVAILABLE())
	{
		HTTPRequestHandle hPlayerRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, PlayerURL);
		Steam_SetHTTPRequestGetOrPostParameter(hPlayerRequest, "key", sDKey);
		Steam_SetHTTPRequestGetOrPostParameter(hPlayerRequest, "steamids", SteamID);
		
		DataPack pData = new DataPack();
		
		pData.WriteCell(iClient);
		pData.WriteCell(t_PROFILE);
		
		if (!Steam_SendHTTPRequest(hPlayerRequest, OnSteamToolsHTTPComplete, iClient))
		{
			#if defined DEBUG
				PrintToServer("Steam_SendHTTPRequest Failed");
			#endif

			Steam_ReleaseHTTPRequest(hPlayerRequest);
			HandleHTTPError(iClient);
			LogRequest(iClient, t_PROFILE, false);
		}
	}
}

public int OnSteamWorksHTTPComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int iClient, RequestType iType)
{
	if (bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
	{
		LogRequest(iClient, iType, true);
		
		int iSize;
		
		SteamWorks_GetHTTPResponseBodySize(hRequest, iSize);
		
		if (iSize >= 2048)
			return;
		
		char[] sBody = new char[iSize];
		
		SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, iSize);
		
		if (iType == t_PROFILE)
			ParseProfile(sBody, iClient);
		else if (iType == t_INVENTORY)
			ParseInventory(sBody, iClient);	
	} 
	else
	{
		#if defined DEBUG
				PrintToServer("OnSteamWorksHTTPComplete Failed, Status Code: %d", eStatusCode);
		#endif

		HandleHTTPError(iClient);
		LogRequest(iClient, iType, false);
	}
	
	CloseHandle(hRequest);
}

public int OnSteamToolsHTTPComplete(HTTPRequestHandle HTTPRequest, bool requestSuccessful, HTTPStatusCode statusCode, DataPack pData)
{
	pData.Reset();
	
	int iClient = pData.ReadCell();
	RequestType iType = view_as<RequestType>(pData.ReadCell());
	
	if (requestSuccessful && statusCode == HTTPStatusCode_OK)
	{
		LogRequest(iClient, iType, true);
		
		int iSize = Steam_GetHTTPResponseBodySize(HTTPRequest);
		
		if (iSize >= 2048)
			return;
		
		char[] sBody = new char[iSize];
		
		Steam_GetHTTPResponseBodyData(HTTPRequest, sBody, iSize);
		
		if (iType == t_PROFILE)
			ParseProfile(sBody, iClient);
		else if (iType == t_INVENTORY)
			ParseInventory(sBody, iClient);
			
	}
	else
	{
		#if defined DEBUG
				PrintToServer("OnSteamToolsHTTPComplete Failed, Status Code: %d", statusCode);
		#endif

		HandleHTTPError(iClient);
		LogRequest(iClient, iType, false);
	}
	
	Steam_ReleaseHTTPRequest(HTTPRequest);
}

void ParseProfile(const char[] sBody, int iClient)
{
	Handle hJson = json_load(sBody);
	
	Handle hResponse = json_object_get(hJson, "response");
	Handle hPlayers = json_object_get(hResponse, "players");
	Handle hPlayer = json_array_get(hPlayers, 0);
	
	if (hPlayer == INVALID_HANDLE)
		return;
	
	int iState = json_object_get_int(hPlayer, "communityvisibilitystate");
	
	if (hPlayer == INVALID_HANDLE) // I have no idea why the handle goes invalid here
		return;
		
	int iProfile = json_object_get_int(hPlayer, "profilestate");
	
	if (iState == 3 && iProfile == 1)
	{
		if (!bInventory)
			return;
		
		switch (GetEngineVersion())
		{
			case Engine_TF2, Engine_DOTA, Engine_Portal2: {}
			default:
				return;
		}
		
		char SteamID[64];
	
		GetClientAuthId(iClient, AuthId_SteamID64, SteamID, sizeof SteamID);
	
		if (STEAMWORKS_AVAILABLE())
		{
			Handle hInventoryRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, InventoryURL);
			
			SteamWorks_SetHTTPRequestGetOrPostParameter(hInventoryRequest, "key", sDKey);
			SteamWorks_SetHTTPRequestGetOrPostParameter(hInventoryRequest, "steamid", SteamID);
			SteamWorks_SetHTTPRequestContextValue(hInventoryRequest, iClient, t_INVENTORY);
			SteamWorks_SetHTTPCallbacks(hInventoryRequest, OnSteamWorksHTTPComplete);
			
			if (!SteamWorks_SendHTTPRequest(hInventoryRequest))
			{
				CloseHandle(hInventoryRequest);
				HandleHTTPError(iClient);
				LogRequest(iClient, t_INVENTORY, false);
			}
		}
		else if (STEAMTOOLS_AVAILABLE())
		{
			HTTPRequestHandle hInventoryRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, InventoryURL);
			Steam_SetHTTPRequestGetOrPostParameter(hInventoryRequest, "key", sDKey);
			Steam_SetHTTPRequestGetOrPostParameter(hInventoryRequest, "steamid", SteamID);
		
			DataPack pData = new DataPack();
		
			pData.WriteCell(iClient);
			pData.WriteCell(t_INVENTORY);
		
			if (!Steam_SendHTTPRequest(hInventoryRequest, OnSteamToolsHTTPComplete, iClient))
			{
				Steam_ReleaseHTTPRequest(hInventoryRequest);
				HandleHTTPError(iClient);
				LogRequest(iClient, t_INVENTORY, false);
			}
		}
	}
	else
		HandleDeal(t_PROFILE, iClient);
}

void ParseInventory(const char[] sBody, int iClient)
{
	Handle hJson = json_load(sBody);
	
	Handle hResult = json_object_get(hJson, "result");
	
	int iState = json_object_get_int(hResult, "status");
	
	if (iState != 1)
		HandleDeal(t_INVENTORY, iClient);
}

void HandleDeal(RequestType iType, int iClient)
{		
	switch (iDealMethod)
	{
		case d_KICK:
		{
			switch (iType)
			{
				case t_PROFILE:
					KickClient(iClient, "[Anti Private] %T", "Private Profile", iClient);
				case t_INVENTORY:
					KickClient(iClient, "[Anti Private] %T", "Private Inventory", iClient);
			}
		}
		case d_WARN:
		{
			switch (iType)
			{
				case t_PROFILE:
					PrintToChat(iClient, "[Anti Private] %T", "Private Profile", iClient);
				case t_INVENTORY:
					PrintToChat(iClient, "[Anti Private] %T", "Private Inventory", iClient);
			}
		}
	}
}

void HandleHTTPError(int iClient)
{
	if (iFailMethod == f_KICK)
		KickClient(iClient, "%T", "Error", iClient);
		
	LogError("Failed to send HTTP request (Is Steam Down?)");
}

void LogRequest(int iClient, RequestType iType, bool bSuccessful)
{
	if (!bLog)
		return;
		
	char sName[MAX_NAME_LENGTH], sSteamID[64];
	
	GetClientName(iClient, sName, sizeof sName);
	GetClientAuthId(iClient, AuthId_Steam3, sSteamID, sizeof sSteamID);
	
	LogToFile(LogPath, "%s %s for %s (%s)",
		(iType == t_PROFILE) ? "Profile request" : "Inventory request",
		(bSuccessful) ? "succeed" : "failed",
		sName,
		sSteamID
	);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cKey)
		cKey.GetString(sDKey, sizeof sDKey);
	if (convar == cInventory)
		bInventory = cInventory.BoolValue;
	if (convar == cDeal)
		iDealMethod = view_as<DealMethod>(cDeal.IntValue);
	if (convar == cFail)
		iFailMethod = view_as<FailMethod>(cFail.IntValue);
	if (convar == cLog)
		bLog = cLog.BoolValue;
}

stock bool IsValidClient(int iClient, bool bAlive = false)
{
	if (iClient >= 1 &&
	iClient <= MaxClients &&
	IsClientConnected(iClient) &&
	IsClientInGame(iClient) &&
	!IsFakeClient(iClient) &&
	(bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}

	return false;
}
