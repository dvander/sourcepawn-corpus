#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.2.0"

new Handle:cvarEnabled;
new Handle:cvarLogs;
new Handle:cvarAnnounce;
new Handle:cvarRemember;
new Handle:Version;

new Handle:hAdminMenu;

new bool:isOutlined[MAXPLAYERS + 1] = { false, ... };

public Plugin:myinfo =
{
	name = "Player Outline",
	author = "ReFlexPoison",
	description = "Add outlines on players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1722483#post1722483"
}

public OnPluginStart()
{
	//Admin Menu
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	Version = CreateConVar("sm_outline_version", PLUGIN_VERSION, "Player Outline Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	
	//CVars
	cvarEnabled = CreateConVar("sm_outline_enabled", "1", "Enable Player Outline\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	cvarLogs = CreateConVar("sm_outline_logs", "1", "Enable logs of outline toggles\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("sm_outline_announce", "1", "Enable announcements of outline toggles\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	cvarRemember = CreateConVar("sm_outline_remember", "1", "Enable re-toggles of outlines on spawn\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);

	//CVar Changes
	HookConVarChange(Version, CVarChange);
	
	//Commands
	RegAdminCmd("sm_outline", OutlineCmd, 0, "sm_outline <#userid|name> <1/0> - Toggles outline on player(s)");

	//Events
	HookEvent("player_spawn", OnPlayerSpawn);

	//Translations
	LoadTranslations("common.phrases");

	//Configs
	AutoExecConfig(true, "plugin.playeroutline");
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarEnabled && !GetConVarBool(cvarEnabled))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			isOutlined[i] = false;
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	if(convar == Version)
	{
		SetConVarString(Version, PLUGIN_VERSION);
	}
}

public OnClientPutInServer(client)
{
	isOutlined[client] = false;
}

public Action:OutlineCmd(client, args)
{
	if(!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	if(args == 0)
	{
		if(client == 0)
		{
			PrintToServer("Usage: sm_outline <#userid|name> <1/0>");
			return Plugin_Handled;
		}
		else if(!isOutlined[client])
		{
			Outline(client, true);
			if(GetConVarBool(cvarLogs))
			{
				LogAction(client, client, "\"%L\" added player outline on \"%L\"", client, client);
			}
			return Plugin_Handled;
		}
		else if(isOutlined[client])
		{
			Outline(client, false);
			if(GetConVarBool(cvarLogs))
			{
				LogAction(client, client, "\"%L\" removed player outline from \"%L\"", client, client);
			}
			return Plugin_Handled;
		}
	}
	if(args == 1)
	{
		if(!CheckCommandAccess(client, "sm_outline_target", ADMFLAG_GENERIC))
		{
			ReplyToCommand(client, "[SM] %t.", "No Access");
			return Plugin_Handled;
		}
		ReplyToCommand(client, "[SM] Usage: sm_outline <#userid|name> <1/0>");
		return Plugin_Handled;
	}
	if(args == 2)
	{
		if(!CheckCommandAccess(client, "sm_outline_target", ADMFLAG_GENERIC))
		{
			ReplyToCommand(client, "[SM] %t.", "No Access");
			return Plugin_Handled;
		}
		new String:arg1[64];
		new String:arg2[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		new toggle = StringToInt(arg2);
		if(toggle == 0 && !StrEqual(arg2, "0"))
		{
			toggle = -1;
		}
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		if((target_count = ProcessTargetString(
						arg1,
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
		if(toggle != 0 && toggle != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_outline <#userid|name> <1/0>");
			return Plugin_Handled;
		}
		if(toggle == 1)
		{
			ShowActivity2(client, "[SM] ", "Added outline on %s.", target_name);
			for(new i = 0; i < target_count; i++)
			{
				if(IsValidClient(target_list[i]) && !isOutlined[target_list[i]])
				{
					Outline(target_list[i], true);
					if(GetConVarBool(cvarLogs))
					{
						LogAction(client, target_list[i], "\"%L\" added player outline on \"%L\"", client, target_list[i]);
					}
				}
			}
		}
		if(toggle == 0)
		{
			ShowActivity2(client, "[SM] ", "Removed outline from %s.", target_name);
			for(new i = 0; i < target_count; i++)
			{
				if(IsValidClient(target_list[i]) && isOutlined[target_list[i]])
				{
					Outline(target_list[i], false);
					if(GetConVarBool(cvarLogs))
					{
						LogAction(client, target_list[i], "\"%L\" removed player outline from \"%L\"", client, target_list[i]);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isOutlined[client] && GetConVarBool(cvarEnabled) && GetConVarBool(cvarRemember))
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
	else
	{
		isOutlined[client] = false;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == hAdminMenu)
	{
		return;
	}
	hAdminMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	if(player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "sm_outline", TopMenuObject_Item, AdminMenu_Outline, player_commands, "sm_outline_target", ADMFLAG_GENERIC);
	}
}

public AdminMenu_Outline( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Outline player");
	}
	else if(action == TopMenuAction_SelectOption)
	{
		DisplayOutlineMenu(param);
	}
}

public DisplayOutlineMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Outline);
	decl String:title[100];
	Format(title, sizeof(title), "Outline Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, true, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Outline(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if(action == MenuAction_Select)
	{
		decl String:info[32];
		new userid;
		new target;
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		if((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available.");
		}
		else if(!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target player.");
		}
		else if(IsValidClient(target))
		{
			if(!isOutlined[target])
			{
				Outline(target, true);
				ShowActivity2(param1, "[SM] ","Added outline on %N.", target);
				if(GetConVarBool(cvarLogs))
				{
					LogAction(param1, target, "\"%L\" added player outline on \"%L\"", param1, target);
				}
			}
			else if(isOutlined[target])
			{
				Outline(target, false);
				ShowActivity2(param1, "[SM] ","Removed outline from %N.", target);
				if(GetConVarBool(cvarLogs))
				{
					LogAction(param1, target, "\"%L\" removed player outline from \"%L\"", param1, target);
				}
			}
		}
		if(IsValidClient(param1) && !IsClientInKickQueue(param1))
		{
			DisplayOutlineMenu(param1);
		}
	}
}

stock Outline(client, bool:add = true)
{
	if(add)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		if(GetConVarBool(cvarAnnounce))
		{
			PrintToChat(client, "[SM] Player outline enabled.");
		}
		isOutlined[client] = true;
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		if(GetConVarBool(cvarAnnounce))
		{
			PrintToChat(client, "[SM] Player outline disabled.");
		}
		isOutlined[client] = false;
	}
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}