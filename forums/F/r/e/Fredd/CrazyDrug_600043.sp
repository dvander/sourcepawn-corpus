#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#define VERSION "0.1"

new bool:IsDrugged[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Crazy Drug",
	author = "Fredd",
	description = "Crazy Drug",
	version = VERSION,
	url = "http://www.sourcemod.net/"
}
new Handle:hTopMenu = INVALID_HANDLE;

public AdminMenu_CrazyDrug(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Crazy Drug player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayCrazyDrugMenu(param);
	}
}

DisplayCrazyDrugMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_CrazyDrug);
	
	decl String:title[100];
	Format(title, sizeof(title), "Crazy Drug player");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_CrazyDrug(Handle:menu, MenuAction:action, param1, param2)
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
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));
			
			if(IsDrugged[target])
			{
				ClientCommand(target, "r_screenoverlay 0");
				IsDrugged[target] = false;
				
			} else
			{
				ClientCommand(target, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				IsDrugged[target] = true;
			}
		}
		
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayCrazyDrugMenu(param1);
		}
	}
}
public Action:Command_CrazyDrug(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_crazy-drug <#userid|name> [0/1]");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new toggle = 2;
	if (args > 1)
	{
		decl String:arg2[2];
		GetCmdArg(2, arg2, sizeof(arg2));
		if (arg2[0])
		{
			toggle = 1;
		}
		else
		{
			toggle = 0;
		}
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
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		switch(toggle)
		{
			case 2:
			{
				if(IsDrugged[target_list[i]])
				{
					ClientCommand(target_list[i], "r_screenoverlay 0");
					IsDrugged[target_list[i]] = false;
					
				}else
				{
					ClientCommand(target_list[i], "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
					IsDrugged[target_list[i]] = true;
				}
			}
			case 1:
			{
				ClientCommand(target_list[i], "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
				IsDrugged[target_list[i]] = true;
			}
			case 0:
			{
				ClientCommand(target_list[i], "r_screenoverlay 0");
				IsDrugged[target_list[i]] = false;
			}
		}
	}
	return Plugin_Handled;
}
public OnPluginStart()
{
	CreateConVar("crazydrug_version", VERSION, "Crazy Drug Version");
	RegAdminCmd("sm_crazy-drug", Command_CrazyDrug, ADMFLAG_SLAY, "sm_crazy-drug <#userid|name> [0/1]");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
		"sm_crazy-drug",
		TopMenuObject_Item,
		AdminMenu_CrazyDrug,
		player_commands,
		"sm_crazy-drug",
		ADMFLAG_SLAY);	
	}
}
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	IsDrugged[client] = false;
	return true;
}

public OnClientDisconnect(client) IsDrugged[client] = false;