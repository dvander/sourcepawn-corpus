#include <sourcemod>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
new g_Target[MAXPLAYERS+1]

new gametype = 0
new String:GameName[64]
new class_offset

#define PLUGIN_VERSION "1.0.104"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Health",
	author = "<eVa>Dog",
	description = "Give a player 1hp",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_evilhealth_version", PLUGIN_VERSION, " Evil Health Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	RegAdminCmd("sm_evilhealth", Command_EvilHealth, ADMFLAG_SLAY, "sm_evilhealth <#userid|name>")
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	LoadTranslations("common.phrases")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	if (StrEqual(GameName, "tf"))
	{
		gametype = 1
		class_offset = FindSendPropInfo("CTFPlayer", "m_iClass")
		if (class_offset == -1)
			SetFailState("Could not find \"m_iClass\" offset")
	}
	else
	{
		gametype = 0
	}
	
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_disconnect", PlayerDisconnectEvent)
	
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		g_Target[i] = 0
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client > 0)
	{
		if (g_Target[client] == 1)
		{
			CreateTimer(0.1, SetPlayerHealth, client)
		}
	}
}

public Action:SetPlayerHealth(Handle:timer, any:client) 
{
	SetEntityHealth(client, 1)
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client > 0)
		g_Target[client] = 0
}

public Action:Command_EvilHealth(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilhealth <#userid|name>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
		{
			PerformEvilHealth(client, target_list[i])
		}
	}
	return Plugin_Handled
}

PerformEvilHealth(client, target)
{
	if (g_Target[target] == 0)
	{
		SetEntityHealth(target, 1)
		LogAction(client, target, "\"%L\" changed the health of \"%L\" to 1hp", client, target)
		ShowActivity(client, "set %N's health to 1hp", target) 
		g_Target[target] = 1
	}
	else
	{
		if (gametype == 0)
			SetEntityHealth(target, 100)
			
		else
		{
			new class = GetPlayerClass(target)
			switch (class)
			{
				case 1, 2, 8, 9:
				{
					SetEntityHealth(target, 125)
				}
				case 3:
				{
					SetEntityHealth(target, 200)
				}
				case 4, 7:
				{
					SetEntityHealth(target, 175)
				}
				case 5:
				{
					SetEntityHealth(target, 150)
				}
				case 6:
				{
					SetEntityHealth(target, 300)
				}
			}
		}
		
		LogAction(client, target, "\"%L\" reset the health of \"%L\"", client, target)
		ShowActivity(client, "set %N's health to normal", target) 
		g_Target[target] = 0
	}			
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_evilhealth",
			TopMenuObject_Item,
			AdminMenu_Health, 
			player_commands,
			"sm_evilhealth",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Health( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Health")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param)
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	decl String:title[100]
	Format(title, sizeof(title), "Choose Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, true)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		new userid, target
		
		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target")
		}
		else
		{					
			PerformEvilHealth(param1, target)
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

stock GetPlayerClass(client)
	return GetEntData(client, class_offset)