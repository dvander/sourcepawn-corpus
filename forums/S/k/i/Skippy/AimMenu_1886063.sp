/***************************************************************
		Special Thanks to Scipizoa for the Idea
	(https://forums.alliedmods.net/showthread.php?t=206780)
***************************************************************/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <morecolors>
#pragma semicolon 1

#define TEAM_SPECTATOR 1

new Handle:configFile = INVALID_HANDLE;
new Handle:g_hCookie_Use = INVALID_HANDLE;
new Handle:g_hCookie_Select = INVALID_HANDLE;

new targetname[MAXPLAYERS+1];

new String:BanString[255];

enum
{
	Kick = 0,
	Ban,
	EnumSize
};

new bool:g_bUse[MAXPLAYERS + 1];
new bool:g_bMenuSelect[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Aim Menu",
	author = "Skipper",
	description = "Admins Commands @Aim on the fly",
	version = "2.0",
	url = "http://steamcommunity.com/id/Skipperz/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_aim", Command_MainAimMenu, ADMFLAG_SLAY);
	RegAdminCmd("sm_reloadaim", Command_ReloadAimConfig, ADMFLAG_SLAY);
	LoadConfig();
	
	g_hCookie_Use = RegClientCookie("aimmenu_use", "Edit Aim Menu Settings", CookieAccess_Public);
	g_hCookie_Select = RegClientCookie("aimmenu_select", "Edit Aim Menu Settings", CookieAccess_Public);
	SetCookieMenuItem(AimSettingsMenu, 0, "Aim Menu Settings");
	
	CreateTimer(0.1, ButtonChecker, _, TIMER_REPEAT);
}

public Action:ButtonChecker(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientButtons(i) & IN_USE)
			{
				if(g_bUse[i])
				{
					ExecuteMenu(i);
				}
			}
		}
	}
	return Plugin_Continue;
}
	
/*public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientButtons(i) & IN_USE)
			{
				if(g_bUse[i])
				{
					ExecuteMenu(i);
				}
			}
		}
	}
}*/
	
LoadConfig()
{
	configFile = CreateKeyValues("Aim Menu");
	decl String:path[64];
	BuildPath(Path_SM, path, sizeof(path), "configs/AimMenu.cfg");
	if(!FileToKeyValues(configFile, path)) 
	{
		SetFailState("Aim Menu Config file missing");
	}
}

public Action:Command_ReloadAimConfig(client, args) 
{
	LoadConfig();
	ReplyToCommand(client, "Aim Menu Config has been refreshed.");
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	decl String:use[5];
	GetClientCookie(client, g_hCookie_Use, use, sizeof(use));
	g_bUse[client] = bool:StringToInt(use);
	
	decl String:select[5];
	GetClientCookie(client, g_hCookie_Select, select, sizeof(select));
	g_bMenuSelect[client] = bool:StringToInt(select);
}	

public Action:Command_MainAimMenu(client, args)
{
	if(IsClientInGame(client))
	{		
		if(g_bMenuSelect[client])
		{
			SelectMenu(client);
		}
		if(!g_bMenuSelect[client])
		{
			ExecuteMenu(client);
		}
	}
	else
	{
		ReplyToCommand(client, "You must be ingame to access this command.");
	}	
	return Plugin_Handled;	
}	

public SelectMenu(client)
{
	decl Handle:menu;
	menu = CreateMenu(SelectCallback);	
			
	SetMenuTitle(menu, "Select Your Target");
					
	AddMenuItem(menu, "select", "Select");
		
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}	

public SelectCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info, "select"))
		{
			ExecuteMenu(client);
		}
	}
}

public ExecuteMenu(client)
{	
	new Handle:menu = CreateMenu(ExecuteCallback);
		
	new spectator = GetEntPropEnt(client,Prop_Send,"m_hObserverTarget");
	new targetaim = GetClientAimTarget(client, true);
		
	if(GetClientTeam(client) == TEAM_SPECTATOR)
	{
		targetname[client] = spectator;
	}
	else
	{
		targetname[client] = targetaim;
	}				
	if(targetname[client] <= -1)
	{
		if(g_bMenuSelect[client])
		{
			SelectMenu(client);
		}		
		CPrintToChat(client, "{goldenrod}[Aim Menu] {lawngreen}Target not found.");
		return;
	}
	else
	{	
		decl String:name[32];
		GetClientName(targetname[client], name, sizeof(name));
	
		decl String:Auth[21];
		GetClientAuthString(targetname[client], Auth, sizeof(Auth));	
	
		SetMenuTitle(menu, "Your Target: %s [%s]", name, Auth);
			
		if(CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))  
		{
			AddMenuItem(menu, "sm_kick", "Kick");
		}
		if(CheckCommandAccess(client, "sm_ban", ADMFLAG_SLAY))  
		{
			AddMenuItem(menu, "sm_ban", "Ban");
		}	
		if(CheckCommandAccess(client, "sm_mute", ADMFLAG_GENERIC))  
		{
			AddMenuItem(menu, "sm_mute", "Mute");
		}
	
		new String:sCmd[32];
		new String:sSection[32];
		
		decl String:path[64];
	
		configFile = CreateKeyValues("Aim Menu");
		BuildPath(Path_SM, path, sizeof(path), "configs/AimMenu.cfg");
	
		if (FileToKeyValues(configFile, path))
		{
			KvRewind(configFile);			
			if (KvJumpToKey(configFile, "Custom"))		
			{
				KvGotoFirstSubKey(configFile);
				do
				{
					KvGetSectionName(configFile, sSection, sizeof(sSection));
					KvGetString(configFile, "cmd", sCmd, sizeof(sCmd));
					
					if(CheckCommandAccess(client, sCmd, ADMFLAG_GENERIC)) 
					{					
						AddMenuItem(menu, sCmd, sSection);
					}	
				}
				while(KvGotoNextKey(configFile));
			}	
		}
	}
	if(g_bMenuSelect[client])
	{
		SetMenuExitBackButton(menu, true);
	}	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}	

public ExecuteCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) SelectMenu(client);
	if (action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
				
		if(StrEqual(info, "sm_kick"))
		{
			AimMenu(client, Kick);
		}	
		else if(StrEqual(info, "sm_ban")) 
		{
			AimMenu(client, Ban);
		}	
		else if(StrEqual(info, "sm_mute")) 
		{
			FakeClientCommand(client, "sm_mute #%d", GetClientUserId(targetname[client]));
		}
		else
		{
			FakeClientCommand(client, "%s #%d", info, GetClientUserId(targetname[client]));
		}	
	}
}

public Action:AimMenu(client, id)
{
	new Handle:menu;

	switch(id)
	{
		case 0:
		{
			menu = CreateMenu(KickMenuCallback);
			SetMenuTitle(menu, "Kick Reason");
		}
		case 1:
		{
			menu = CreateMenu(BanMenuCallback);
			SetMenuTitle(menu, "Ban Reason");
		}
		default: return;
	}
	
	new String:sReason[32];
	new String:sSection[32];
		
	decl String:path[64];
	
	configFile = CreateKeyValues("Aim Menu");
	BuildPath(Path_SM, path, sizeof(path), "configs/AimMenu.cfg");
	
	if (FileToKeyValues(configFile, path))
	{
		KvRewind(configFile);			
		if (KvJumpToKey(configFile, "Reasons"))		
		{
			KvGotoFirstSubKey(configFile);
			do
			{
				KvGetSectionName(configFile, sSection, sizeof(sSection));
				KvGetString(configFile, "reason", sReason, sizeof(sReason));
		
				AddMenuItem(menu, sReason, sSection);
			}
			while(KvGotoNextKey(configFile));
		}	
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}	

public KickMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) AimMenu(client, Kick);
	if(action == MenuAction_Select)
	{
		new String:info[16];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(client, "sm_kick #%d %s", GetClientUserId(targetname[client]), info);
	}
}	

public BanMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) AimMenu(client, Ban);
	if(action == MenuAction_Select)
	{
		new String:banReason[32];
		GetMenuItem(menu, param2, banReason, sizeof(banReason));	
		
		if (strlen(banReason) > 0)
		{
			Format(BanString, sizeof(BanString), "%s %s", BanString, banReason); 
		}	
		
		TimeMenu(client);
	}
}

public Action:TimeMenu(client)
{
	new Handle:menu = CreateMenu(TimeMenuCallback);
	
	SetMenuTitle(menu, "Time");
	
	new String:sTime[16];
	new String:sSection[32];
		
	decl String:path[64];
	
	configFile = CreateKeyValues("Aim Menu");
	BuildPath(Path_SM, path, sizeof(path), "configs/AimMenu.cfg");
	
	if (FileToKeyValues(configFile, path))
	{
		KvRewind(configFile);			
		if (KvJumpToKey(configFile, "BanTimes"))		
		{
			KvGotoFirstSubKey(configFile);
			do
			{
				KvGetSectionName(configFile, sSection, sizeof(sSection));
				KvGetString(configFile, "time", sTime, sizeof(sTime));
		
				AddMenuItem(menu, sTime, sSection);
			}
			while(KvGotoNextKey(configFile));
		}	
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}	
		
public TimeMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) AimMenu(client, Ban);
	if(action == MenuAction_Select)
	{
		new String:BanTime[16];
		GetMenuItem(menu, param2, BanTime, sizeof(BanTime));	
		Format(BanString, sizeof(BanString), "%s %s", BanTime, BanString);
		
		FakeClientCommand(client, "sm_ban #%d %s", GetClientUserId(targetname[client]), BanString);		
	}
}	

public AimSettingsMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
    {
		new Handle:menu = CreateMenu(AimSettings);
		SetMenuTitle(menu, "Aim Menu Settings");
		if(g_bUse[client])
		{
			AddMenuItem(menu, "nouse", "Disable +use to target");
		}
		if(!g_bUse[client])
		{	
			AddMenuItem(menu, "use", "Enable +use to target");
		}
		if(g_bMenuSelect[client])
		{
			AddMenuItem(menu, "nomenu", "Disable menu to target");
		}
		if(!g_bMenuSelect[client])
		{			
			AddMenuItem(menu, "menu", "Enable menu to target");
		}	
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
}

public AimSettings(Handle:menu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)	
    {
		decl String:SelectionInfo[64];
		GetMenuItem(menu, selection, SelectionInfo, sizeof(SelectionInfo));
		
		if(StrEqual(SelectionInfo, "use"))
		{
			SetClientCookie(client, g_hCookie_Use, "1");
			g_bUse[client] = true;
		}
		if(StrEqual(SelectionInfo, "nouse"))
		{
			SetClientCookie(client, g_hCookie_Use, "0");
			g_bUse[client] = false;
		}
		if(StrEqual(SelectionInfo, "menu"))
		{
			SetClientCookie(client, g_hCookie_Select, "1");
			g_bMenuSelect[client] = true;
		}
		if(StrEqual(SelectionInfo, "nomenu"))
		{
			SetClientCookie(client, g_hCookie_Select, "0");
			g_bMenuSelect[client] = false;
		}	
    }
	else if (action == MenuAction_End)
    {
		CloseHandle(menu);
    }
}


	

	
