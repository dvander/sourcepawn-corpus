#pragma semicolon 1                  // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>

#define PLUGIN_NAME             "[TF2] PowerPlay"
#define PLUGIN_AUTHOR           "Mecha the Slag"
#define PLUGIN_VERSION          "1.2"
#define PLUGIN_CONTACT          "www.mechaware.net/"

new bool:g_PowerPlay[MAXPLAYERS+1] = false;

new Handle:g_hTopMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_CONTACT
};

public OnPluginStart()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf")) SetFailState("This plugin is TF2 only.");
	
	RegAdminCmd("sm_powerplay", Command_PowerPlay, ADMFLAG_SLAY, "sm_powerplay <#userid|name> [0/1]");
	RegAdminCmd("sm_pp", Command_PowerPlay, ADMFLAG_SLAY, "sm_powerplay <#userid|name> [0/1]");
	CreateConVar("powerplay_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", Player_Spawn, EventHookMode_Post);
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice*/
	if (topmenu == g_hTopMenu) {
		return;
	}
	
	/* Save the Handle */
	g_hTopMenu = topmenu;
	
	new TopMenuObject:TopMenuPlayerCommands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	AddToTopMenu(g_hTopMenu, "sm_powerplay", TopMenuObject_Item, AdminMenu_PowerPlay, TopMenuPlayerCommands, "sm_powerplay", ADMFLAG_SLAY);
}

public AdminMenu_PowerPlay(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%s", "PowerPlay player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayPowerPlayMenu(param);
	}
}

public MenuHandler_PowerPlay(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
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
			
			g_PowerPlay[target] = !g_PowerPlay[target];
			GivePowerPlay(param1, target);
			ShowActivity2(param1, "[SM] ", "Toggled powerplay on target", "_s", name);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPowerPlayMenu(param1);
		}
	}
}

DisplayPowerPlayMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PowerPlay);
	
	decl String:title[100];
	Format(title, sizeof(title), "%s:", "PowerPlay player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:Command_PowerPlay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_powerplay <#userid|name> [0/1]");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:arg2[65];
	new bool:arg2_bool = false;
	if (args >= 2) {
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StringToInt(arg2) > 0) arg2_bool = true;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
	arg,
	client,
	target_list,
	MAXPLAYERS,
	COMMAND_FILTER_ALIVE,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client)) ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++) {
		new target = target_list[i];
		if (IsClientInGame(target) && IsPlayerAlive(target)) {
			if (args >= 2) g_PowerPlay[target] = arg2_bool;
			else g_PowerPlay[target] = (!g_PowerPlay[target]);
			GivePowerPlay(client, target);
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Toggled powerplay on target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Toggled powerplay on target", "_s", target_name);
	}
	
	return Plugin_Handled;
}

GivePowerPlay(client, target)
{
	if (g_PowerPlay[target])
	{
		TF2_SetPlayerPowerPlay(target, true);
		LogAction(client, target, "\"%L\" gave PowerPlay to \"%L\"", client, target);
	}
	else
	{
		TF2_SetPlayerPowerPlay(target, false);
		LogAction(client, target, "\"%L\" removed PowerPlay on \"%L\"", client, target);
	}
}

public Action:Player_Spawn(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_PowerPlay[client] = false;
}
