#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_hAdminName;
new Handle:g_hAdminSteamID;
new Handle:g_hAdminIsOnline;

enum ConfigState {
	State_None = 0,
	State_Root,
	State_Admin
}

new ConfigState:g_ConfigState = State_None;
new g_iCurrentKey;

public Plugin:myinfo = 
{
	name = "Admin List Menu",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Lists all admins registred in the server in a menu",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_adminlistmenu_version", PLUGIN_VERSION, "Admin List Menu version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hAdminName = CreateArray(ByteCountToCells(MAX_NAME_LENGTH));
	g_hAdminSteamID = CreateArray(ByteCountToCells(32));
	g_hAdminIsOnline = CreateArray();
	
	RegConsoleCmd("sm_admins", Cmd_Admins, "Lists all admins registred in the server in a menu.");
	ParseAdmins();
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if(part == AdminCache_Admins)
		ParseAdmins();
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client) && IsClientAuthorized(client) && !IsFakeClient(client))
	{
		new iSize = GetArraySize(g_hAdminSteamID);
		decl String:sSteam[32], String:sSteam2[32];
		for(new i=0;i<iSize;i++)
		{
			GetArrayString(g_hAdminSteamID, i, sSteam, sizeof(sSteam));
			GetClientAuthString(client, sSteam2, sizeof(sSteam2));
			if(StrEqual(sSteam, sSteam2))
			{
				SetArrayCell(g_hAdminIsOnline, i, false);
				break;
			}
		}
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(!IsFakeClient(client))
	{
		new iSize = GetArraySize(g_hAdminSteamID);
		decl String:sSteam[32];
		for(new i=0;i<iSize;i++)
		{
			GetArrayString(g_hAdminSteamID, i, sSteam, sizeof(sSteam));
			if(StrEqual(sSteam, auth))
			{
				SetArrayCell(g_hAdminIsOnline, i, true);
				break;
			}
		}
	}
}

public Action:Cmd_Admins(client, args)
{
	new iSize = GetArraySize(g_hAdminName);
	new Handle:hMenu;
	if(client)
	{
		hMenu = CreateMenu(Menu_HandleList);
		SetMenuTitle(hMenu, "Admin List:");
		SetMenuExitButton(hMenu, true);
	}
	else
	{
		PrintToServer("Admin list");
		PrintToServer("----------------");
	}
	
	decl String:sName[MAX_NAME_LENGTH], String:sBuffer[80];
	for(new i=0;i<iSize;i++)
	{
		GetArrayString(g_hAdminName, i, sName, sizeof(sName));
		Format(sBuffer, sizeof(sBuffer), "%s%s", sName, (GetArrayCell(g_hAdminIsOnline, i)?" (online)":""));
		if(client)
		{
			AddMenuItem(hMenu, "", sBuffer);
		}
		else
		{
			PrintToServer("%d. %s", i, sBuffer);
		}
	}
	
	if(client)
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Menu_HandleList(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
}

ParseAdmins()
{
	ClearArray(g_hAdminName);
	ClearArray(g_hAdminSteamID);
	ClearArray(g_hAdminIsOnline);
	
	g_ConfigState = State_None;
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/admins.cfg");
	if(!FileExists(sPath))
		SetFailState("Can't find configs/admins.cfg");
	
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, Config_OnNewSection, Config_OnKeyValue, Config_OnEndSection);
	
	new iLine, iColumn;
	new SMCError:smcResult = SMC_ParseFile(hSMC, sPath, iLine, iColumn);
	CloseHandle(hSMC);
	
	if(smcResult != SMCError_Okay)
	{
		decl String:sError[128];
		SMC_GetErrorString(smcResult, sError, sizeof(sError));
		SetFailState("Error parsing advanced admins: %s on line %d, col %d of %s", sError, iLine, iColumn, sPath);
	}
}

public SMCResult:Config_OnNewSection(Handle:parser, const String:section[], bool:quotes)
{
	if(g_ConfigState == State_None)
		g_ConfigState = State_Root;
	else if(g_ConfigState == State_Root)
	{
		g_ConfigState = State_Admin;
		g_iCurrentKey = PushArrayString(g_hAdminName, section);
		PushArrayString(g_hAdminSteamID, "");
		PushArrayCell(g_hAdminIsOnline, false);
	}
}

public SMCResult:Config_OnKeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!key[0])
		return SMCParse_Continue;
	
	// We just assume it's a steamid.. this may not work for admins with other auth type than "steam"!
	if(StrEqual(key, "identity"))
	{
		SetArrayString(g_hAdminSteamID, g_iCurrentKey, value);
		decl String:sSteam[32];
		// Check if that admin is currently online.
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && IsClientAuthorized(i))
			{
				GetClientAuthString(i, sSteam, sizeof(sSteam));
				if(StrEqual(sSteam, value))
					SetArrayCell(g_hAdminIsOnline, g_iCurrentKey, true);
			}
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:Config_OnEndSection(Handle:parser)
{
	if(g_ConfigState == State_Admin)
		g_ConfigState = State_Root;
}