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

/*
* 	Change Log:
* 		v0.1 - inital release
* 		v0.2 - Fixed menu expandability/ trigger cmd
* 		v0.3 - Safe SQL calls, API additions/ changes
* 		v0.4 - Added option for using a flatfile
*/

#include <sourcemod>
#include <sdktools>
#include <adt>
#include <donator>

#pragma semicolon 1

//uncomment to use SQL
//#define USESQL

#define DONATOR_VERSION "0.4"

#if defined USESQL

#define SQL_CONFIG		"default"
#define SQL_DBNAME		"donators"

#else
#include <clientprefs>

#define DONATOR_FILE	"donators.txt"

#endif

#define CHAT_TRIGGER 	"!donators"

new Handle:g_hForward_OnDonatorConnect = INVALID_HANDLE;
new Handle:g_hForward_OnPostDonatorCheck = INVALID_HANDLE;
new Handle:g_hForward_OnDonatorsChanged = INVALID_HANDLE;

new Handle:g_hDonatorTrie = INVALID_HANDLE;
new Handle:g_hDonatorTagTrie = INVALID_HANDLE;
new Handle:g_hMenuItems = INVALID_HANDLE;

new bool:g_bIsDonator[MAXPLAYERS + 1];
new g_iMenuId, g_iMenuCount;

#if defined USESQL
new Handle:g_hDataBase = INVALID_HANDLE;

//add cols to expand the sql storage
enum SQLCOLS
{
	steamid,
	level,
	tag
};

new const String:db_cols[SQLCOLS][] = 
{
	"steamid",
	"level",
	"tag"
};

#else
new Handle:g_CookieTag = INVALID_HANDLE;
new Handle:g_CookieLevel = INVALID_HANDLE;
#endif

public Plugin:myinfo = 
{
	name = "Basic Donator Interface",
	author = "Nut",
	description = "A core to handle donator related plugins",
	version = DONATOR_VERSION,
	url = "http://www.lolsup.com/tf2"
}

public OnPluginStart()
{
	CreateConVar("basicdonator_version", DONATOR_VERSION, "Basic Donators Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_reloaddonators", cmd_ReloadDonators, ADMFLAG_BAN, "Reloads the donator database");
	
	g_hDonatorTrie = CreateTrie();
	g_hDonatorTagTrie = CreateTrie();
	
	#if defined USESQL
	SQL_OpenConnection();
	#else
	g_CookieTag = RegClientCookie("donator.core.tag", "Donator tag", CookieAccess_Public);
	g_CookieLevel = RegClientCookie("donator.core.level", "Donator access level", CookieAccess_Private);
	LoadDonators();
	#endif
	
	g_hForward_OnDonatorConnect = CreateGlobalForward("OnDonatorConnect", ET_Event, Param_Cell);
	g_hForward_OnPostDonatorCheck = CreateGlobalForward("OnPostDonatorCheck", ET_Event, Param_Cell);
	g_hForward_OnDonatorsChanged = CreateGlobalForward("OnDonatorsChanged", ET_Event);

	g_hMenuItems = CreateArray();
	
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
}

#if defined USESQL
public OnPluginEnd()
	CloseHandle(g_hDataBase);
#endif

public OnClientAuthorized(iClient, const String:szAuthId[])
{
	if(IsFakeClient(iClient)) return;
	
	g_bIsDonator[iClient] = false;

	decl iLevel;
	if (GetTrieValue(g_hDonatorTrie, szAuthId, iLevel))
	{
		g_bIsDonator[iClient] = true;
		Forward_OnDonatorConnect(iClient);
	}
}

public OnClientPostAdminCheck(iClient)
{
	if(IsFakeClient(iClient)) return;
	
	#if !defined USESQL
	if (AreClientCookiesCached(iClient))
	{
		decl String:szLevelBuffer[2], String:szTagBuffer[256], String:szSteamId[64];
		GetClientCookie(iClient, g_CookieLevel, szLevelBuffer, sizeof(szLevelBuffer));
		GetClientCookie(iClient, g_CookieTag, szTagBuffer, sizeof(szTagBuffer));
		GetClientAuthString(iClient, szSteamId, sizeof(szSteamId));
		if (strlen(szLevelBuffer) > 1)
		{
			SetTrieValue(g_hDonatorTrie, szSteamId, StringToInt(szLevelBuffer));
			SetTrieString(g_hDonatorTagTrie, szSteamId, szTagBuffer, true);
		}			
	}
	#endif
	Forward_OnPostDonatorCheck(iClient);
}

public Action:SayCallback(iClient, const String:command[], argc)
{
	if(!iClient) return Plugin_Continue;
	if (!g_bIsDonator[iClient]) return Plugin_Continue;
	
	decl String:szArg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);
	
	if (StrEqual(szArg, CHAT_TRIGGER, false))
	{
		ShowDonatorMenu(iClient);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:ShowDonatorMenu(client)
{
	new Handle:menu = CreateMenu(DonatorMenuSelected);
	SetMenuTitle(menu,"Donator Menu");

	decl Handle:hItem, String:szBuffer[64], String:szItem[4];
	for(new i = 0; i < GetArraySize(g_hMenuItems); i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		hItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hItem, 1, szBuffer, sizeof(szBuffer));
		AddMenuItem(menu, szItem, szBuffer, ITEMDRAW_DEFAULT);
	}
	DisplayMenu(menu, client, 20);
}

public DonatorMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			new Handle:hItem = GetArrayCell(g_hMenuItems, iSelected);
			new Handle:hFwd = GetArrayCell(hItem, 3);
			new bool:result;
			Call_StartForward(hFwd);
			Call_PushCell(param1);
			Call_Finish(result);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public Action:cmd_ReloadDonators(client, args)
{
	LoadDonators();

	//Update the donator array and fire a donator changed forward
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		
		g_bIsDonator[i] = false;
	
		decl iLevel, String:szAuthId[64];
		GetClientAuthString(i, szAuthId, sizeof(szAuthId));
		
		if (GetTrieValue(g_hDonatorTrie, szAuthId, iLevel))
			g_bIsDonator[i] = true;
	}

	ReplyToCommand(client, "[SM] Donator database reloaded.");
	
	Forward_OnDonatorsChanged();
	
	return Plugin_Handled;
}

public LoadDonators()
{
	decl String:szBuffer[255];
	
	#if defined USESQL
	FormatEx(szBuffer, sizeof(szBuffer), "SELECT %s, %s, %s FROM `%s`", db_cols[steamid], db_cols[level], db_cols[tag], SQL_DBNAME);
	SQL_TQuery(g_hDataBase, T_LoadDonators, szBuffer);
	#else
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "data/%s", DONATOR_FILE);
	new Handle:file = OpenFile(szBuffer, "r");
	if (file != INVALID_HANDLE)
	{
		szBuffer = "";
		ClearTrie(g_hDonatorTagTrie);
		ClearTrie(g_hDonatorTrie);
		while (!IsEndOfFile(file) && ReadFileLine(file, szBuffer, sizeof(szBuffer)))
		{
			if (szBuffer[0] != ';' && strlen(szBuffer) > 1)
			{
				new String:szTemp[2][64];
				TrimString(szBuffer);
				ExplodeString(szBuffer, ";", szTemp, 2, sizeof(szTemp[]));
				SetTrieValue(g_hDonatorTrie, szTemp[0], StringToInt(szTemp[1]));
				SetTrieString(g_hDonatorTagTrie, szBuffer, "");
			}
		}
		CloseHandle(file);
	}
	else
		SetFailState("Unable to load donator file (%s)", DONATOR_FILE);
	#endif
}

//--------------------------------------SQL---------------------------------------------
#if defined USESQL
public SQL_OpenConnection()
{
	if (SQL_CheckConfig(SQL_CONFIG))
		SQL_TConnect(T_InitDatabase, SQL_CONFIG);
	else
		SetFailState("Unabled to load cfg file (%s)", SQL_CONFIG);
}

public T_InitDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		g_hDataBase = hndl;
		LoadDonators();
	}
	else  
		LogError("DATABASE FAILURE: %s", error);
}

public T_LoadDonators(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl != INVALID_HANDLE)
	{
		if (SQL_GetRowCount(hndl))
		{
			ClearTrie(g_hDonatorTagTrie);
			ClearTrie(g_hDonatorTrie);
			decl String:szSteamId[64], String:szTag[256], iLevel;
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
		LogError("Query failed! %s", error);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (strlen(error) > 1)
		LogMessage("SQL Error: %s", error);
}
#endif
//-----------------------------------------------------------------------------------------

/*
* Natives
*/
public Native_GetDonatorLevel(Handle:plugin, params)
{
	decl String:szSteamId[64], iLevel;
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));
	
	if (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel))
		return iLevel;
	else
		return -1;
}

public Native_SetDonatorLevel(Handle:plugin, params)
{
	/*
	decl String:szSteamId[64], iLevel;
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));

	if (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel))
	{
		iLevel = GetNativeCell(2);
		SetTrieValue(g_hDonatorTrie, szSteamId, iLevel);

		#if defined USESQL
		SQL_EscapeString(g_hDataBase, szSteamId, szSteamId, sizeof(szSteamId));
		decl String:szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `%s` SET %s = %i WHERE `steamid` LIKE '%s'", SQL_DBNAME, db_cols[level], iLevel, szSteamId);
		SQL_TQuery(g_hDataBase, SQLErrorCheckCallback, szQuery);
		#else
		decl String:szLevel[5];
		Format(szLevel, sizeof(szLevel), "%i", iLevel);
		SetClientCookie(GetNativeCell(1), g_CookieLevel, szLevel);
		#endif
		return true;
	}
	else
		return -1;*/
		
	ThrowNativeError(SP_ERROR_NATIVE, "Not implimented.");
}

public Native_IsClientDonator(Handle:plugin, params)
{
	decl String:szSteamId[64], iLevel;
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));
	if (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel))
		return true;
	return false;
}

public Native_FindDonatorBySteamId(Handle:plugin, params)
{
	decl String:szSteamId[64], iLevel;
	GetNativeString(1, szSteamId, sizeof(szSteamId));
	if (GetTrieValue(g_hDonatorTrie, szSteamId, iLevel))
		return true;
	return false;
}

public Native_GetDonatorMessage(Handle:plugin, params)
{
	decl String:szBuffer[256], String:szSteamId[64];
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));

	if (GetTrieString(g_hDonatorTagTrie, szSteamId, szBuffer, 256))
	{
		SetNativeString(2, szBuffer, 256, true);
		return true;
	}
	return -1;
}

public Native_SetDonatorMessage(Handle:plugin, params)
{
	decl String:szOldTag[256], String:szSteamId[64], String:szNewTag[256];
	GetClientAuthString(GetNativeCell(1), szSteamId, sizeof(szSteamId));
	
	if (GetTrieString(g_hDonatorTagTrie, szSteamId, szOldTag, 256))
	{
		GetNativeString(2, szNewTag, sizeof(szNewTag));
		SetTrieString(g_hDonatorTagTrie, szSteamId, szNewTag);
		
		#if defined USESQL
		decl String:szQuery[512];
		SQL_EscapeString(g_hDataBase, szNewTag, szNewTag, sizeof(szNewTag));
		SQL_EscapeString(g_hDataBase, szSteamId, szSteamId, sizeof(szSteamId));
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `%s` SET %s = '%s' WHERE `steamid` LIKE '%s'", SQL_DBNAME, db_cols[tag], szNewTag, szSteamId);
		SQL_TQuery(g_hDataBase, SQLErrorCheckCallback, szQuery);
		#else
		SetClientCookie(GetNativeCell(1), g_CookieTag, szNewTag);
		#endif
		return true;
	}
	return -1;
}

public Native_RegisterMenuItem(Handle:hPlugin, iNumParams)
{
	decl String:szCallerName[PLATFORM_MAX_PATH], String:szBuffer[256], String:szMenuTitle[256];
	GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
	
	new Handle:hFwd = CreateForward(ET_Single, Param_Cell, Param_CellByRef);	
	if (!AddToForward(hFwd, hPlugin, GetNativeCell(2)))
		ThrowError("Failed to add forward from %s", szCallerName);

	GetNativeString(1, szMenuTitle, 255);
	
	new Handle:hTempItem;
	for (new i = 0; i < g_iMenuCount; i++)	//make sure we aren't double registering
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		GetArrayString(hTempItem, 1, szBuffer, sizeof(szBuffer));
		if (StrEqual(szMenuTitle, szBuffer))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
		}
	}
	
	new Handle:hItem = CreateArray(15);
	new id = g_iMenuId++;
	g_iMenuCount++;
	PushArrayString(hItem, szCallerName);
	PushArrayString(hItem, szMenuTitle);
	PushArrayCell(hItem, id);
	PushArrayCell(hItem, hFwd);
	PushArrayCell(g_hMenuItems, hItem);
	return id;
}
public Native_UnregisterMenuItem(Handle:hPlugin, iNumParams)
{
	new Handle:hTempItem;
	for (new i = 0; i < g_iMenuCount; i++)
	{
		hTempItem = GetArrayCell(g_hMenuItems, i);
		new id = GetArrayCell(hTempItem, 2);
		if (id == GetNativeCell(1))
		{
			RemoveFromArray(g_hMenuItems, i);
			g_iMenuCount--;
			return true;
		}
	}
	return false;
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("donator.core");
	CreateNative("IsPlayerDonator", Native_IsClientDonator);
	CreateNative("FindDonatorBySteamId", Native_FindDonatorBySteamId);
	CreateNative("GetDonatorLevel", Native_GetDonatorLevel);
	CreateNative("SetDonatorLevel", Native_SetDonatorLevel);
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
public Forward_OnDonatorConnect(iClient)
{
	new bool:result;
	Call_StartForward(g_hForward_OnDonatorConnect);
	Call_PushCell(iClient);
	Call_Finish(_:result);
	return result;
}

/*
*  Forwards for everyone - use to check for admin status/ cookies should be cached now
*/

public Forward_OnPostDonatorCheck(iClient)
{
	new bool:result;
	Call_StartForward(g_hForward_OnPostDonatorCheck);
	Call_PushCell(iClient);
	Call_Finish(_:result);
	return result;
}

/*
*  Forwards when the donators have been reloaded
*/

public Forward_OnDonatorsChanged()
{
	new bool:result;
	Call_StartForward(g_hForward_OnDonatorsChanged);
	Call_Finish(_:result);
	return result;
}