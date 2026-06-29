#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:g_Target[MAXPLAYERS+1]

new Float:new_loc[MAXPLAYERS+1][3]
new Float:old_loc[MAXPLAYERS+1][3]

new g_BeamSprite
new g_HaloSprite

new TeamTwoColor[4] 
new TeamThreeColor[4]

new String:GameName[64]

#define PLUGIN_VERSION "1.0.100"

// Functions
public Plugin:myinfo =
{
	name = "Evil Admin - Beam",
	author = "<eVa>Dog",
	description = "Add a beam to a player's path",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_evilbeam_version", PLUGIN_VERSION, " Evil Beam Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	RegAdminCmd("sm_evilbeam", Command_EvilBeam, ADMFLAG_SLAY, "sm_evilbeam <#userid|name>")
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnMapStart()
{
	if (StrEqual(GameName, "dod"))
	{
		TeamTwoColor = {25, 255, 25, 255}
		TeamThreeColor = {255, 25, 25, 255}
	}
	else 
	{
		TeamTwoColor = {255, 25, 25, 255}
		TeamThreeColor = {25, 25, 255, 255}
	}

	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt")
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt")
}

public Action:Command_EvilBeam(client, args)
{
	decl String:target[65]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evilbeam <#userid|name>");
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
			PerformEvilBeam(client, target_list[i])
		}
	}
	return Plugin_Handled
}

PerformEvilBeam(client, target)
{
	if (g_Target[target] == INVALID_HANDLE)
	{
		CreateBeam(target)
		LogAction(client, target, "\"%L\" placed an evil beam on \"%L\"", client, target)
		ShowActivity(client, "placed an evil beam on %N", target) 
	}
	else
	{
		KillBeam(target)
		LogAction(client, target, "\"%L\" removed an evil beam from \"%L\"", client, target)
		ShowActivity(client, "removed an evil beam from %N", target) 
	}			
}

CreateBeam(client)
{
	g_Target[client] = CreateTimer(0.2, Timer_Beam, client, TIMER_REPEAT)
}

KillBeam(client)
{
	KillTimer(g_Target[client])
	g_Target[client] = INVALID_HANDLE
}


public Action:Timer_Beam(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillBeam(client)
		return Plugin_Handled
	}
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Handled
	}
	
	new team
	team = GetClientTeam(client)
	GetClientAbsOrigin(client, new_loc[client])

	if (team == 2)
		TE_SetupBeamPoints(old_loc[client], new_loc[client], g_BeamSprite, g_HaloSprite, 0, 0, 10.0, 20.0, 10.0, 5, 0.0, TeamTwoColor, 30)
	if (team == 3)
		TE_SetupBeamPoints(old_loc[client], new_loc[client], g_BeamSprite, g_HaloSprite, 0, 0, 10.0, 20.0, 10.0, 5, 0.0, TeamThreeColor, 30)
	
	TE_SendToAll()
	
	old_loc[client] = new_loc[client]
	
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
			"sm_evilbeam",
			TopMenuObject_Item,
			AdminMenu_beam, 
			player_commands,
			"sm_evilbeam",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_beam( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Beam")
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
			PerformEvilBeam(param1, target)
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

