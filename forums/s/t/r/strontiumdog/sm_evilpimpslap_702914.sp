#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE

new Handle:Cvar_SlapDmg = INVALID_HANDLE
new Handle:g_Target[MAXPLAYERS+1]

#define PLUGIN_VERSION "1.0.102"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Pimp Slap",
	author = "<eVa>Dog",
	description = "Pimp Slap a player",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_evilpimpslap_version", PLUGIN_VERSION, " Evil Pimp Slap Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_SlapDmg = CreateConVar("sm_evilpimpslap_dmg", "2", " Amount of damage to inflict each time a player is evil pimp slapped", FCVAR_PLUGIN)
	RegAdminCmd("sm_evilpimpslap", Command_EvilPimpSlap, ADMFLAG_SLAY, "sm_evilpimpslap <#userid|name>")
	
	LoadTranslations("common.phrases")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public Action:Command_EvilPimpSlap(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilpimpslap <#userid|name>");
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
			PerformEvilPimpSlap(client, target_list[i])
		}
	}
	return Plugin_Handled
}

PerformEvilPimpSlap(client, target)
{
	if (g_Target[target] == INVALID_HANDLE)
	{
		CreatePimpSlap(target)
		LogAction(client, target, "\"%L\" pimp slapped \"%L\"", client, target)
		ShowActivity(client, "evil pimp slapped %N", target) 
	}
	else
	{
		KillPimpSlap(target)
		LogAction(client, target, "\"%L\" stopped pimp slapping \"%L\"", client, target)
		ShowActivity(client, "stopped pimp slapping %N", target) 
	}			
}

CreatePimpSlap(client)
{
	g_Target[client] = CreateTimer(0.2, Timer_PimpSlap, client, TIMER_REPEAT)
}

KillPimpSlap(client)
{
	KillTimer(g_Target[client])
	g_Target[client] = INVALID_HANDLE
}


public Action:Timer_PimpSlap(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		KillPimpSlap(client)
		return Plugin_Handled
	}
	
	new damage = GetConVarInt(Cvar_SlapDmg)
	SlapPlayer(client, damage, true)
			
	return Plugin_Handled
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
			"sm_evilpimpslap",
			TopMenuObject_Item,
			AdminMenu_PimpSlap, 
			player_commands,
			"sm_evilpimpslap",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_PimpSlap( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Pimp Slap")
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
			PerformEvilPimpSlap(param1, target)
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

