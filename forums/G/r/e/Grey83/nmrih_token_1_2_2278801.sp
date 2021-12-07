#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define sName "\x01[\x0700FF00Token\x01]"
#define sCom "\x0700FF00!token"
#define PLUGIN_VERSION 	"1.2"
#define PLUGIN_NAME 	 "[NMRiH] Token"

new Handle:hCvarEnable, bool:bCvarEnable,
	Handle:hTokenMessage, bool:bTokenMessage,
	Handle:hTopMenu = INVALID_HANDLE;

new bool:bSurvival,
	bool:g_bLateLoad = false;

public Plugin:myinfo =
{
	name =PLUGIN_NAME,
	author = "Grey83",
	description = "Give token to dead player",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nmrih_token.phrases");
	CreateConVar("nmrih_token_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvarEnable = CreateConVar("sm_token_enable", "1", "0 = Plugin disabled, 1 = enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	hTokenMessage = CreateConVar("sm_token_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	RegAdminCmd("sm_token", Give_Token, ADMFLAG_SLAY, "sm_token <#userid|name> - Give tocken to dead player.");
	RegConsoleCmd("token", Command_Token);

	bCvarEnable = GetConVarBool(hCvarEnable);
	bTokenMessage = GetConVarBool(hTokenMessage);
	
	HookConVarChange(hCvarEnable, OnConVarChange);
	HookConVarChange(hTokenMessage, OnConVarChange);

	AutoExecConfig(true, "nmrih_token");
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	LoadTranslations("common.phrases");
	LoadTranslations("nmrih_token.phrases");
	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hCvarEnable)
	{
		bCvarEnable = bool:StringToInt(newValue);
	}
	else if (hCvar == hTokenMessage)
	{
		bTokenMessage = bool:StringToInt(newValue);
	}
}

public OnLibraryRemoved(const String:name[])
{
	//remove this menu handle if adminmenu plugin unloaded
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	decl String:sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));

	if (StrContains(sMap, "nms_") == 0)
	{
		bSurvival = true;
	}
	else
	{
		bSurvival = false;
	}
}


public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && !IsPlayerAlive(client)&& bSurvival && bCvarEnable)
	{
		SendToken(client);
		LogAction(client, -1, "[Token] %L got token after join." , client);
 		if (bTokenMessage) PrintToChat(client, "%s %t %s", sName, "Welcome Message", sCom);
	}
}

public Action:Command_Token(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if (!bCvarEnable || !IsClientInGame(client) || !bSurvival)
		return Plugin_Handled;
	
	SendToken(client);

	return Plugin_Handled;
}

SendToken(client)
{
	SetEntProp(client, Prop_Send, "m_iTokens", 1);
}

public Action:Give_Token(client, args)
{
	decl String:target[32];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//validate args
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_token <#userid|name>");
		return Plugin_Handled;
	}
	
	if( !client )
	{
		ReplyToCommand(client, "[SM] Can't give token from rcon");
		return Plugin_Handled;	
	}
	
	//get argument
	GetCmdArg(1, target, sizeof(target));		
	
	//get target(s)
	if ((target_count = ProcessTargetString(
			target,
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
	
	if(!bSurvival)
	{
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SendToken(client);
	}
	
	ShowActivity2(client, "[SM] ", "%t", "got token", target_name);
	
	return Plugin_Handled;	
}
/*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
		AdminMenu
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
public OnAdminMenuReady(Handle:topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	//Save the Handle
	hTopMenu = topmenu;
	
	//Build the "Player Commands" category
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
 	if (player_commands != INVALID_TOPMENUOBJECT) Setup_AdminMenu_Give_Token(player_commands);
}
Setup_AdminMenu_Give_Token(TopMenuObject:parentmenu)
{
	AddToTopMenu(hTopMenu, 
		"sm_token",
		TopMenuObject_Item,
		AdminMenu_Token,
		parentmenu,
		"sm_token",
		ADMFLAG_SLAY);
}

public AdminMenu_Token(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Give token to player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayTokenMenu(param);
	}
}

DisplayTokenMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Token);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Give token to player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
//	AddTargetsToMenu(menu, client, true, false);
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public MenuHandler_Token(Handle:menu, MenuAction:action, param1, param2)
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
			
			if(IsClientInGame(target) && !IsPlayerAlive(target))
			{
				SendToken(target);
				ShowActivity2(param1, "[SM] ", "%t", "got token from admin", name);
			}
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayTokenMenu(param1);
		}
	}
}