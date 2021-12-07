#include <sourcemod>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:g_hReset;

new bool:g_Target[MAXPLAYERS+1]
new fov_offset
new zoom_offset

#define PLUGIN_VERSION "1.0.106"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Vision",
	author = "<eVa>Dog",
	description = "Distorts a player's view",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_evilvision_version", PLUGIN_VERSION, " Evil Vision Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	RegAdminCmd("sm_evilvision", Command_Vision, ADMFLAG_SLAY, "sm_evilvision <#userid|name>")
	
	g_hReset	= CreateConVar("sm_evilvision_reset", "0", " Reset vision at death <0|1>", FCVAR_PLUGIN);
	
	fov_offset = FindSendPropOffs("CBasePlayer", "m_iFOV")
	zoom_offset = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_disconnect", PlayerDisconnectEvent)
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_disconnect", PlayerDisconnectEvent)
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsClientInGame(client))
	{
		if (g_Target[client] && GetConVarInt(g_hReset) == 0)
		{
			SetEntData(client, fov_offset, 160, 4, true)
			SetEntData(client, zoom_offset, 160, 4, true)
		}
		else
		{
			SetEntData(client, fov_offset, 90, 4, true)
			SetEntData(client, zoom_offset, 90, 4, true)
			g_Target[client] = false
		}
	}
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (client > 0)
		g_Target[client] = false
}

public Action:Command_Vision(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilvision <#userid|name>");
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
		PerformVision(client, target_list[i])
	}
	return Plugin_Handled
}

PerformVision(client, target)
{
	if (IsClientInGame(target) && IsPlayerAlive(target))
	{
		if (!g_Target[target])
		{
			SetEntData(target, fov_offset, 160, 4, true)
			SetEntData(target, zoom_offset, 160, 4, true)
			LogAction(client, target, "\"%L\" changed the FOV of \"%L\"", client, target)
			ShowActivity(client, "changed %N\'s view a bit", target)
			g_Target[target] = true
		}
		else
		{
			SetEntData(target, fov_offset, 90, 4, true)
			SetEntData(target, zoom_offset, 90, 4, true)
			LogAction(client, target, "\"%L\" reset the FOV of \"%L\"", client, target)
			ShowActivity(client, "set %N\'s view back to normal", target)
			g_Target[target] = false
		}
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
			"sm_evilvision",
			TopMenuObject_Item,
			AdminMenu_Vision, 
			player_commands,
			"sm_evilvision",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Vision( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Vision")
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
			PerformVision(param1, target)
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1)
		}
	}
}

