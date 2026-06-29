#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <adminmenu>

public Plugin:myinfo = {
	name = "M3Respawn - Respawn a dead player",
	author = "M3Studios, Inc.",
	description = "Let's admins respawn any dead player.",
	version = "0.1.2",
	url = "http://forums.alliedmods.net/showpost.php?p=1333238&postcount=26"
}

new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart() {
	LoadTranslations("common.phrases"); // Fix [SM] Native "ReplyToCommand" reported: Language phrase "No matching client" not found
	RegAdminCmd("sm_respawn", CmdRespawn, ADMFLAG_KICK, "sm_respawn <#userid|name>");

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Build the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, 
			"sm_respawn",
			TopMenuObject_Item,
			AdminMenu_Respawn,
			player_commands,
			"sm_respawn",
			ADMFLAG_KICK);
	}
}

public AdminMenu_Respawn(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Respawn dead player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRespawnMenu(param);
	}
}

DisplayRespawnMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Respawn);
	
	decl String:title[100];
	Format(title, sizeof(title), "Respawn dead player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	//AddTargetsToMenu(menu, client, false, false);
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD);
	if(GetMenuItemCount(menu) == 0)        
	{
		AddMenuItem(menu,"refresh","Refresh",ITEMDRAW_DEFAULT);
		AddMenuItem(menu,"no_client","No available clients",ITEMDRAW_DISABLED);
	}

	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Respawn(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		if(!StrEqual(info,"no_client",true) && !StrEqual(info,"refresh",true))
		{
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
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(target, name, sizeof(name));
				//ShowActivity2(param1, "[SM] ", "%t", "Kicked target", "_s", name);
				doRespawn(param1, target);
			}
			
			/* Re-draw the menu if they're still valid */
			if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
			{
				DisplayRespawnMenu(param1);
			}
		}
		else if(StrEqual(info,"refresh",true) && IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayRespawnMenu(param1);
		}
	}
}


public Action:CmdRespawn(client, args) {
/*	if (args != 1) {
		return Plugin_Handled;	
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:tnIsMl;
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_DEAD, targetName, sizeof(targetName), tnIsMl);

	if(targetCount == 0) {
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	} else {
		for (new i=0; i<targetCount; i++) {
			doRespawn(client, targetList[i]);
		}
	}
*/

	// I take this whole code snip from SM funcommands plugin
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
		doRespawn(client, target_list[i]);
	}

	//return Plugin_Continue;
	return Plugin_Handled; //Fix not show "Unknown command: sm_respawn" on console after respawn dead player
}

public doRespawn(client, target) {
	// Fix not respawn spectators, only players in team CT and T
	if(GetClientTeam(target) >= 2) {

		if(client != target) {
			new String:adminName[MAX_NAME_LENGTH];
			GetClientName(client, adminName, sizeof(adminName));
		
			PrintCenterText(target, "%s has given you another chance", adminName);
		}

		CS_RespawnPlayer(target);
	}
}