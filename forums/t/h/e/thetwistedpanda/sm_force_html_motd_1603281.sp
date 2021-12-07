/*
	Revision v1.0.5
	------------------
	Removed translation "Menu_Phrase_9" to make room for an exit button.
	Added translation "Menu_Phrase_Exit" which controls the exit button.
	Added an exit button to the information panel that only works when a user has enabled html motds.
	The information menu is no longer forced on clients that have had their html motds enabled.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.0.5"
#define TEAM_SPEC 1

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];
new bool:g_bDisabled[MAXPLAYERS + 1];
new Handle:g_hTimer_Notify[MAXPLAYERS + 1];
new Handle:g_hTimer_Query[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hRate = INVALID_HANDLE;
new Handle:g_hFlag = INVALID_HANDLE;

new g_iFlag;
new Float:g_fRate;
new bool:g_bLateLoad, bool:g_bEnabled;
new String:g_sPrefixChat[32], String:g_sPrefixCenter[32];

public Plugin:myinfo = 
{
	name = "Force HTML MOTDs",
	author = "Twisted|Panda",
	description = "Prevents players from joining a team as long as cl_disablehtmlmotd is enabled.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sm_force_html_motd.phrases");

	CreateConVar("sm_force_html_motd_version", PLUGIN_VERSION, "Force HTML MOTDs: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_force_html_motd_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hRate = CreateConVar("sm_force_html_motd_rate", "1.0", "How often the query runs to check client cvar values.", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hRate, OnSettingsChange);
	g_hFlag = CreateConVar("sm_force_html_motd_flag", "z", "Individuals that possess this flag, or the \"Allow_Html_Motd\" override, will not be checked by this plugin. (\"\" = Disabled)", FCVAR_NONE);
	HookConVarChange(g_hFlag, OnSettingsChange);
	AutoExecConfig(true, "sm_force_html_motd");

	RegConsoleCmd("sm_motdhelp", Command_Help);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);

	decl String:_sGame[32];
	GetGameFolderName(_sGame, sizeof(_sGame));
	if(StrEqual(_sGame, "cstrike", false))
	{
		AddCommandListener(Command_Join, "jointeam");
		AddCommandListener(Command_Join, "joinclass");
	}
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fRate = GetConVarFloat(g_hRate);
	GetConVarString(g_hFlag, _sGame, sizeof(_sGame));
	g_iFlag = strlen(_sGame) ? ReadFlagString(_sGame) : 0;
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, sizeof(g_sPrefixChat), "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixCenter, sizeof(g_sPrefixCenter), "%T", "Prefix_Center", LANG_SERVER);

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					if(!g_iFlag || !CheckCommandAccess(i, "Allow_Html_Motds", g_iFlag))
						g_hTimer_Query[i] = CreateTimer(g_fRate, Timer_QueryClient, i);
				}	
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
			if(!g_iFlag || !CheckCommandAccess(client, "Allow_Html_Motds", g_iFlag))
				g_hTimer_Query[client] = CreateTimer(g_fRate, Timer_QueryClient, client);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bLoaded[client] = false;
		g_bDisabled[client] = false;
		
		if(g_hTimer_Notify[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Notify[client]))
			g_hTimer_Notify[client] = INVALID_HANDLE;
		if(g_hTimer_Query[client] != INVALID_HANDLE && CloseHandle(g_hTimer_Query[client]))
			g_hTimer_Query[client] = INVALID_HANDLE;
	}
}

public Action:Command_Join(client, const String:command[], argc)
{
	if(client > 0 && IsClientInGame(client))
		if(g_bDisabled[client])
			return Plugin_Stop;

	return Plugin_Continue;
}

public Action:Timer_QueryClient(Handle:timer, any:client)
{
	g_hTimer_Query[client] = INVALID_HANDLE;
	if(IsClientInGame(client))
		QueryClientConVar(client, "cl_disablehtmlmotd", ConVar_QueryClient);

	return Plugin_Continue;
}

public ConVar_QueryClient(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(g_bEnabled && IsClientInGame(client))
	{
		if(result == ConVarQuery_Okay)
		{
			new bool:_bCurrent = StringToInt(cvarValue) ? true : false;
			if(_bCurrent != g_bDisabled[client])
			{
				g_bDisabled[client] = _bCurrent;
				if(!_bCurrent)
				{
					decl String:_sBuffer[192];
					Format(_sBuffer, sizeof(_sBuffer), "%T", "Motd_Panel_Title", client);
					ShowMOTDPanel(client, _sBuffer, "motd", MOTDPANEL_TYPE_INDEX);

					PrintCenterText(client, "%s%t", g_sPrefixCenter, "Phrase_Join_Permission");
				}
				else
				{
					ShowMenu(client);
					NotifyRestricted(client);
					g_hTimer_Notify[client] = CreateTimer(1.0, Timer_NotifyClient, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

					if(g_iTeam[client] > TEAM_SPEC)
						ChangeClientTeam(client, TEAM_SPEC);
				}
			}
			else if(g_bDisabled[client] && g_iTeam[client] > TEAM_SPEC)
				ChangeClientTeam(client, TEAM_SPEC);
		}

		g_hTimer_Query[client] = CreateTimer(g_fRate, Timer_QueryClient, client);
	}
}

public Action:Timer_NotifyClient(Handle:timer, any:client)
{
	if(IsClientInGame(client) && g_bDisabled[client])
	{
		NotifyRestricted(client);
		return Plugin_Continue;
	}

	g_hTimer_Notify[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

NotifyRestricted(client)
{
	PrintCenterText(client, "%s%t", g_sPrefixCenter, "Phrase_Join_Restricted");
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_bDisabled[client])
		{
			if(g_iTeam[client] > TEAM_SPEC)
			{
				ChangeClientTeam(client, TEAM_SPEC);
				CreateTimer(0.1, Timer_ConfirmSpectate, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}

			dontBroadcast = true;
			SetEventBroadcast(event, true);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_ConfirmSpectate(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0 && IsClientInGame(client))
		if(g_iTeam[client] > TEAM_SPEC)
			ChangeClientTeam(client, TEAM_SPEC);
	
	return Plugin_Continue;
}

public Action:Command_Help(client, args)
{	
	if(client > 0 && IsClientInGame(client) && g_bDisabled[client])
		ShowMenu(client);
	
	return Plugin_Continue;
}

ShowMenu(client)
{
	decl String:_sBuffer[128], String:_sPhase[24];

	new Handle:_hMenu = CreateMenu(MenuHandler_Main);
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Title", client);
	SetMenuTitle(_hMenu, _sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitBackButton(_hMenu, false);
	SetMenuExitButton(_hMenu, false);
	
	for(new i = 0; i <= 8; i++)
	{
		Format(_sPhase, sizeof(_sPhase), "Menu_Phrase_%d", i);
		Format(_sBuffer, sizeof(_sBuffer), "%T", _sPhase, client);	
		if(strlen(_sBuffer))
			AddMenuItem(_hMenu, "", _sBuffer, ITEMDRAW_DISABLED);
	}
	Format(_sBuffer, sizeof(_sBuffer), "%T", "Menu_Phrase_Exit", client);	
	AddMenuItem(_hMenu, "0", _sBuffer);

	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Main(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_Interrupted || param2 == MenuCancel_Exit)
				if(g_bDisabled[param1])
					ShowMenu(param1);
		}
		case MenuAction_Select:
		{
			decl String:_sBuffer[4];
			GetMenuItem(menu, param2, _sBuffer, sizeof(_sBuffer));
			
			if(g_bDisabled[param1])
				ShowMenu(param1);
		}
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hRate)
		g_fRate = StringToFloat(newvalue);
	else if(cvar == g_hFlag)
	{
		decl String:_sBuffer[32];
		strcopy(_sBuffer, sizeof(_sBuffer), newvalue);
		g_iFlag = ReadFlagString(_sBuffer);
	}
}