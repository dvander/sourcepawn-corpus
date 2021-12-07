#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE

#define PLUGIN_VERSION 			"1.3"

new Handle:sm_rweapons_show = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Remove Weapons",
	author = "Starman2098",
	description = "Lets an admin remove a players weapons.",
	version = PLUGIN_VERSION,
	url = "http://www.starman2098.com"
}

public OnPluginStart()
{
	CreateConVar("sm_rweapons_version", PLUGIN_VERSION, "Remove weapons plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_rweapons_show = CreateConVar("sm_rweapons_show", "1", "Toggles target messages on and off, 0 for off, 1 for on. - Default 1");
	RegAdminCmd("sm_rweapons", Command_Rweapons, ADMFLAG_KICK,"sm_rweapons <user id | name>");
	LoadTranslations("common.phrases")
	AutoExecConfig(true, "rweapons");
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public Action:Command_Rweapons(client, args)
{
	decl string:target[MAXPLAYERS];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rweapons <name>");
		return Plugin_Handled;
	}

	if (target[client] == -1)
	{
		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
	PerformRemoveWeapons(client,target_list[i]);
	}	
	return Plugin_Handled;
}

PerformRemoveWeapons(client,target)
{
	if((GetConVarInt(sm_rweapons_show) < 0) || (GetConVarInt(sm_rweapons_show) > 1))
	{
		ReplyToCommand(client, "[SM] Usage: sm_rweapons_show <0 - off | 1 - on> - Defaulting to 1");
		SetConVarInt(sm_rweapons_show, 1);
		return Plugin_Handled;
	}

	if(GetConVarInt(sm_rweapons_show) == 0)
	{
	TF2_RemoveAllWeapons(target);
	LogAction(client, target, "\"%L\" removed weapons on \"%L\"", client, target);
	return Plugin_Handled;
	}

	if(GetConVarInt(sm_rweapons_show) == 1)
	{
	TF2_RemoveAllWeapons(target);
	LogAction(client, target, "\"%L\" removed weapons on \"%L\"", client, target);
	ReplyToCommand(client, "You removed %N's weapons.", target);
	ShowActivity2(client, "", "%N has removed %N's weapons.", client,target);
	return Plugin_Handled;
	}
	return Plugin_Handled;
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
			"sm_rweapons",
			TopMenuObject_Item,
			AdminMenu_Particles, 
			player_commands,
			"sm_rweapons",
			ADMFLAG_KICK)
	}
}
 
public AdminMenu_Particles( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Remove Weapons")
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
			PerformRemoveWeapons(param1, target)
			if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
			{
				DisplayPlayerMenu(param1)
			}
			
		}
	}

}
