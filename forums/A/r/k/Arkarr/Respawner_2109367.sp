#include <sourcemod>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu;

public Plugin:myinfo =  
{  
	name = "Respawn Player",  
	author = "Arkarr",  
	description = "Allow you to respawn ANY player.",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{
	RegAdminCmd("sm_respawn", CMD_RespawnPlayer, ADMFLAG_CHEATS);
	
	LoadTranslations("common.phrases");
}

public Action:CMD_RespawnPlayer(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "{lightgreen}[Respawner]{default} Usage : sm_repsawn [TARGET]");
		return Plugin_Handled;
	}
	
	new String:target_name[MAX_TARGET_LENGTH], String:arg1[100];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{ 
		TF2_RespawnPlayer(target_list[i]);
	}
	
	return Plugin_Handled;
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
 
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
 
	AddToTopMenu(hAdminMenu, "sm_respawn", TopMenuObject_Item, AdminMenu_AddRespawner, player_commands, "sm_respawn", ADMFLAG_CHEATS);
}

public AdminMenu_AddRespawner(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Respawn a player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:hPlayerSelectMenu = CreateMenu(Menu_PlayerSelect);
		SetMenuTitle(hPlayerSelectMenu, "Select a player");
		
		new maxClients = GetMaxClients();
		for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			new String:infostr[128];
			Format(infostr, sizeof(infostr), "%N", i);
			
			new String:indexstr[32];
			IntToString(i, indexstr, sizeof(indexstr)); 
			
			AddMenuItem(hPlayerSelectMenu, indexstr, infostr)
		}
		
		InsertMenuItem(hPlayerSelectMenu, 0, "red", "Team RED");
		InsertMenuItem(hPlayerSelectMenu, 1, "blue", "Team Blu");
		InsertMenuItem(hPlayerSelectMenu, 2, "all", "All players");
		
		SetMenuExitButton(hPlayerSelectMenu, true);
		DisplayMenu(hPlayerSelectMenu, param, MENU_TIME_FOREVER);
	}
}

public Menu_PlayerSelect(Handle:menu, MenuAction:action, param1, param2)
{
	new String:target[32];
	GetMenuItem(menu, GetMenuItemCount(menu)-1, target, sizeof(target));
		
	if (action == MenuAction_Select)
	{
		if (!StrEqual(target, "blue") && !StrEqual(target, "red") && !StrEqual(target, "all"))
		{
			new client = StringToInt(target);
			
			if (IsClientInGame(client))
			{
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (StrEqual(target, "red") || StrEqual(target, "blue"))
			{
				new targetteam = FindTeamByName(target);
				
				new maxClients = GetMaxClients();
				for (new i=1; i<=maxClients; i++)
				{
					if (!IsClientInGame(i))
					{
						continue;
					}
					else if (IsFakeClient(i))
					{
						continue;
					}
					
					if (GetClientTeam(i) == targetteam)
					{
						TF2_RespawnPlayer(i);
					}
				}
			}
			else if (StrEqual(target, "all"))
			{
				new maxClients = GetMaxClients();
				for (new i=1; i<=maxClients; i++)
				{
					if (!IsClientInGame(i))
					{
						continue;
					}
					else if (IsFakeClient(i))
					{
						continue;
					}
					
					TF2_RespawnPlayer(i);
				}
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
