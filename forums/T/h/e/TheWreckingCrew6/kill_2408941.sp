#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Kill Player",
	author = "TheWreckingCrew6",
	description = "Kill a player using Command",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

TopMenu hTopMenu;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("kill.phrases");

	RegAdminCmd("sm_kill", Command_Kill, ADMFLAG_SLAY, "sm_kill <#userid|name>");
	
	/* Account for late loading */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_kill", AdminMenu_Kill, player_commands, "sm_kill", ADMFLAG_SLAY);
	}
}

PerformKill(client, target)
{
	LogAction(client, target, "\"%L\" killed \"%L\"", client, target);
	
	SDKHooks_TakeDamage(target, client, client, 450.0);
}

DisplayKillMenu(client)
{
	Menu menu = CreateMenu(MenuHandler_Kill);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Kill player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, true);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public AdminMenu_Kill(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Kill player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayKillMenu(param);
	}
}

public MenuHandler_Kill(Menu menu, MenuAction action, param1, param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != null)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else if (!IsPlayerAlive(target))
		{
			ReplyToCommand(param1, "[SM] %t", "Player has since died");
		}
		else
		{
			decl String:name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			PerformKill(param1, target);
			/*ShowActivity2(param1, "[SM] ", "%t", "Kill target", "_s", name);*/
		}
		
		DisplayKillMenu(param1);
	}
}

public Action:Command_Kill(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_kill <#userid|name>");
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
		PerformKill(client, target_list[i]);
	}
	
	/*if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Killed target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Killed target", "_s", target_name);
	}*/

	return Plugin_Handled;
}