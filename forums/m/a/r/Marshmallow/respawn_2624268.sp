#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;

// This will be used for checking which team the player is on before repsawning them
#define SPECTATOR_TEAM 0
#define TEAM_SPEC  1
#define TEAM_1     2
#define TEAM_2     3

public Plugin:myinfo =
{
	name = "PRespawn",
	author = "",
	description = "Respawn dead players",
	version = "1.2",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_respawn_version", "1.2", "Player Respawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "dod"))
	{
		// Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
		g_hGameConfig = LoadGameConfigFile("plugin.instantrespawn");
		
		if (g_hGameConfig == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Missing File \"plugin.instantrespawn\"!");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");
		g_hPlayerRespawn = EndPrepSDKCall();
		
		if (g_hPlayerRespawn == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Unable to find signature for \"CDODPlayer::DODRespawn(void)\"!");
		}
	}
	
	LoadTranslations("common.phrases");
	LoadTranslations("respawn.phrases");
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_FILTER_DEAD,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		new team = GetClientTeam(target_list[i]);
		if(team == TEAM_1 || team == TEAM_2)
			RespawnPlayer(client, target_list[i]);
		else if(team == SPECTATOR_TEAM || team == TEAM_SPEC)
			PrintToChat(client, "[SM] %t", "Client not on active team");
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", "_s", target_name);
	}
	
	return Plugin_Handled;
}

public RespawnPlayer(client, target)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	LogAction(client, target, "\"%L\" respawned \"%L\"", client, target);
	
	if(StrEqual(game, "cstrike"))
	{
		CS_RespawnPlayer(target);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(target);
	}
	else if (StrEqual(game, "dod"))
	{
		SDKCall(g_hPlayerRespawn, target);
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
	
	hAdminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
		"sm_respawn",
		TopMenuObject_Item,
		AdminMenu_Respawn, 
		player_commands,
		"sm_respawn",
		ADMFLAG_SLAY);
	}
}

public AdminMenu_Respawn( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Respawn Player");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose Player to Respawn:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	// Lets only add dead players to the menu... we don't want to respawn alive players do we?
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
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
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));
			
			RespawnPlayer(param1, target);
			ShowActivity2(param1, "[SM] ", "%t", "Toggled respawn on target", "_s", name);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}
	