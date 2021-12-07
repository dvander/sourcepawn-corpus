/*
If you want to use SQL here is some info to get you started:

SQL TABLE INFO:

	CREATE TABLE IF NOT EXISTS `donators` (
	  `steamid` varchar(64) default NULL,
	  `tag` varchar(128) NOT NULL,
	  `level` tinyint(1) NOT NULL default '1'
	)

MANUALLY ADDING DONATORS:

	INSERT INTO `donators` ( `steamid` , `tag`, `level` ) VALUES ( 'STEAMID', 'THIS IS A TAG', 5 );

*/

#include <sourcemod>
#include <sdktools>
#include <adt>
#include <donator>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "0.6"

#define SQL_CONFIG		"donators"
#define SQL_DBNAME		"donators"

Handle g_hForward_OnDonatorConnect = INVALID_HANDLE;
Handle g_hForward_OnPostDonatorCheck = INVALID_HANDLE;
Handle g_hForward_OnDonatorsChanged = INVALID_HANDLE;

Handle g_hDonatorTrie = INVALID_HANDLE;
Handle g_hDonatorTagTrie = INVALID_HANDLE;
Handle g_hMenuItems = INVALID_HANDLE;

bool g_bIsDonator[MAXPLAYERS + 1];
int g_iMenuId, g_iMenuCount;

Handle g_hDataBase = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Basic Donator Interface",
	author = "n0:name, Nut",
	description = "A core to handle donator related plugins",
	version = VERSION,
	url = "www.f-o-g.eu"
}

public void OnPluginStart()
{
	CreateConVar("donator_version", VERSION, "Basic Donators Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_reloaddonators", Command_ReloadDonators, ADMFLAG_ROOT, "Reloads the donator database");
	
	RegConsoleCmd("sm_donator", Command_Donator, "");
	
	g_hDonatorTrie = CreateTrie();
	g_hDonatorTagTrie = CreateTrie();
	
	SQL_OpenConnection();
	
	g_hForward_OnDonatorConnect = CreateGlobalForward("OnDonatorConnect", ET_Event, Param_Cell);
	g_hForward_OnPostDonatorCheck = CreateGlobalForward("OnPostDonatorCheck", ET_Event, Param_Cell);
	g_hForward_OnDonatorsChanged = CreateGlobalForward("OnDonatorsChanged", ET_Event);

	g_hMenuItems = CreateArray();
}

public void OnPluginEnd()
{
	CloseHandle(g_hDataBase);
}

public void OnClientAuthorized(int iClient, const char[] szAuthId)
{
	if(IsFakeClient(iClient)) return;
	g_bIsDonator[iClient] = false;

	int iLevel;
	if (GetTrieValue(g_hDonatorTrie, szAuthId, iLevel))
	{
		g_bIsDonator[iClient] = true;
		Forward_OnDonatorConnect(iClient);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsFakeClient(iClient)) return;
	Forward_OnPostDonatorCheck(iClient);
}

public Action Command_Donator(int iClient, int args)
{
	if(IsClientInGame(iClient) && g_bIsDonator[iClient]) ShowDonatorMenu(iClient);
	return Plugin_Handled;
}

public Action ShowDonatorMenu(int client)
{
	Handle menu = CreateMenu(DonatorMenuSelected);
	SetMenuTitle(menu,"Donator Menu");

	Handle hItem;
	char szBuffer[64];
	char szItem[4];
	for(int i = 0; i < GetArraySize(g_hMenuItems); i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		hItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hItem, 1, szBuffer, sizeof(szBuffer));
		AddMenuItem(menu, szItem, szBuffer, ITEMDRAW_DEFAULT);
	}
	DisplayMenu(menu, client, 20);
}

public int DonatorMenuSelected(Handle menu, MenuAction action, int param1, int param2)
{
	char tmp[32];
	int iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			Handle hItem = GetArrayCell(g_hMenuItems, iSelected);
			Handle hFwd = GetArrayCell(hItem, 3);
			bool result;
			Call_StartForward(hFwd);
			Call_PushCell(param1);
			Call_Finish(result);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action Command_ReloadDonators(int client, int args)
{
	LoadDonators();

	//Update the donator array and fire a donator changed forward
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		
		g_bIsDonator[i] = false;
	
		int iLevel;
		char szAuthId[64];
		GetClientAuthId(i, AuthId_Steam2, szAuthId, sizeof(szAuthId));
		
		if (GetTrieValue(g_hDonatorTrie, szAuthId, iLevel)) g_bIsDonator[i] = true;
	}

	ReplyToCommand(client, "[SM] Donator database reloaded.");
	
	Forward_OnDonatorsChanged();
	
	return Plugin_Handled;
}

public void LoadDonators()
{
	char szBuffer[255];
	char szGame[32];
	
	GetGameFolderName(szGame, sizeof(szGame));
	
	FormatEx(szBuffer, sizeof(szBuffer), "SELECT steamid, level, tag FROM `%s` WHERE game = '%s' OR game = 'all'", SQL_DBNAME, szGame);
	SQL_TQuery(g_hDataBase, T_LoadDonators, szBuffer);
}

//--------------------------------------SQL---------------------------------------------
public void SQL_OpenConnection()
{
	if (SQL_CheckConfig(SQL_CONFIG))
		SQL_TConnect(T_InitDatabase, SQL_CONFIG);
	else
		SetFailState("Unabled to load cfg file (%s)", SQL_CONFIG);
}

public void T_InitDatabase(Handle owner, Handle hndl, const char[] error, int data)
{
	if (hndl != INVALID_HANDLE)
	{
		g_hDataBase = hndl;
		LoadDonators();
	}
	else 
	{
		LogError("DATABASE FAILURE: %s", error);
	}
}

public void T_LoadDonators(Handle owner, Handle hndl, const char[] error, int data)
{
	if (hndl != INVALID_HANDLE)
	{
		if (SQL_GetRowCount(hndl))
		{
			ClearTrie(g_hDonatorTagTrie);
			ClearTrie(g_hDonatorTrie);
			
			char szSteamId[64];
			char szTag[256];
			int iLevel;
			
			while (SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, szSteamId, sizeof(szSteamId));
				if (strlen(szSteamId) < 1) continue;
				iLevel = SQL_FetchInt(hndl, 1);
				SQL_FetchString(hndl, 2, szTag, sizeof(szTag));
				SetTrieValue(g_hDonatorTrie, szSteamId, iLevel);
				SetTrieString(g_hDonatorTagTrie, szSteamId, szTag);
			}
		}
	}
	else
	{
		LogError("Query failed! %s", error);
	}
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, int data)
{
	if (strlen(error) > 1) LogMessage("SQL Error: %s", error);
}
//-----------------------------------------------------------------------------------------

/*
* Natives
*/
public int Native_GetDonatorLevel(Handle plugin, int params)
{
	char szSteamId[64];
	int iLevel;
	
	GetClientAuthId(GetNativeCell(1), AuthId_Steam2, szSteamId, sizeof(szSteamId));
	
	return (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel))?iLevel:-1;
}

public int Native_IsClientDonator(Handle plugin, int params)
{
	char szSteamId[64];
	int iLevel;
	
	GetClientAuthId(GetNativeCell(1), AuthId_Steam2, szSteamId, sizeof(szSteamId));
	return (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel));
}

public int Native_FindDonatorBySteamId(Handle plugin, int params)
{
	char szSteamId[64];
	int iLevel;
	
	GetNativeString(1, szSteamId, sizeof(szSteamId));
	
	return (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel));
}

public int Native_GetDonatorMessage(Handle plugin, int params)
{
	char szBuffer[256];
	char szSteamId[64];
	
	GetClientAuthId(GetNativeCell(1), AuthId_Steam2, szSteamId, sizeof(szSteamId));

	if (GetTrieString(g_hDonatorTagTrie, szSteamId, szBuffer, 256))
	{
		SetNativeString(2, szBuffer, 256, true);
		return true;
	}
	return -1;
}

public int Native_SetDonatorMessage(Handle plugin, int params)
{
	char szOldTag[256];
	char szSteamId[64];
	char szNewTag[256];
	
	GetClientAuthId(GetNativeCell(1), AuthId_Steam2, szSteamId, sizeof(szSteamId));
	
	if (GetTrieString(g_hDonatorTagTrie, szSteamId, szOldTag, 256))
	{
		GetNativeString(2, szNewTag, sizeof(szNewTag));
		SetTrieString(g_hDonatorTagTrie, szSteamId, szNewTag);
		
		char szQuery[512];
		SQL_EscapeString(g_hDataBase, szNewTag, szNewTag, sizeof(szNewTag));
		SQL_EscapeString(g_hDataBase, szSteamId, szSteamId, sizeof(szSteamId));
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `%s` SET tag = '%s' WHERE `steamid` = '%s'", SQL_DBNAME, szNewTag, szSteamId);
		SQL_TQuery(g_hDataBase, SQLErrorCheckCallback, szQuery);
		return true;
	}
	return -1;
}

public int Native_RegisterMenuItem(Handle hPlugin, int iNumParams)
{
	char szCallerName[PLATFORM_MAX_PATH];
	char szBuffer[256];
	char szMenuTitle[256];
	GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
	
	Handle hFwd = CreateForward(ET_Single, Param_Cell, Param_CellByRef);	
	if (!AddToForward(hFwd, hPlugin, GetNativeCell(2))) ThrowError("Failed to add forward from %s", szCallerName);

	GetNativeString(1, szMenuTitle, 255);
	
	Handle hTempItem;
	for (int i = 0; i < g_iMenuCount; i++)	//make sure we aren't double registering
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hTempItem, 1, szBuffer, sizeof(szBuffer));
		if (StrEqual(szMenuTitle, szBuffer))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
		}
	}
	
	Handle hItem = CreateArray(15);
	int id = g_iMenuId++;
	g_iMenuCount++;
	
	PushArrayString(hItem, szCallerName);
	PushArrayString(hItem, szMenuTitle);
	PushArrayCell(hItem, id);
	PushArrayCell(hItem, hFwd);
	PushArrayCell(g_hMenuItems, hItem);
	
	return id;
}
public int Native_UnregisterMenuItem(Handle hPlugin, int iNumParams)
{
	Handle hTempItem;
	for (int i = 0; i < g_iMenuCount; i++)
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		int id = GetArrayCell(hTempItem, 2);
		if (id == GetNativeCell(1))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
			return true;
		}
	}
	return false;
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("donator.core");
	
	CreateNative("IsPlayerDonator", Native_IsClientDonator);
	CreateNative("FindDonatorBySteamId", Native_FindDonatorBySteamId);
	CreateNative("GetDonatorLevel", Native_GetDonatorLevel);
	CreateNative("GetDonatorMessage", Native_GetDonatorMessage);
	CreateNative("SetDonatorMessage", Native_SetDonatorMessage);
	CreateNative("Donator_RegisterMenuItem", Native_RegisterMenuItem);
	CreateNative("Donator_UnregisterMenuItem", Native_UnregisterMenuItem);
	
	return APLRes_Success;
}

//-------------------FORWARDS--------------------------
/*
* Forwards for donators connecting
*/
public bool Forward_OnDonatorConnect(int iClient)
{
	bool result;
	Call_StartForward(g_hForward_OnDonatorConnect);
	Call_PushCell(iClient);
	Call_Finish(view_as<int> result);
	return result;
}

/*
*  Forwards for everyone - use to check for admin status/ cookies should be cached now
*/

public bool Forward_OnPostDonatorCheck(int iClient)
{
	bool result;
	Call_StartForward(g_hForward_OnPostDonatorCheck);
	Call_PushCell(iClient);
	Call_Finish(view_as<int> result);
	return result;
}

/*
*  Forwards when the donators have been reloaded
*/

public bool Forward_OnDonatorsChanged()
{
	bool result;
	Call_StartForward(g_hForward_OnDonatorsChanged);
	Call_Finish(view_as<int> result);
	return result;
}