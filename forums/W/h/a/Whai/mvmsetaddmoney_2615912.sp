#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "1.2b"

new Handle:hAdminMenu = INVALID_HANDLE
new Handle:hPlayerSelectMenu = INVALID_HANDLE;
new Handle:hAmountSelectMenu = INVALID_HANDLE;
new Handle:cv_auto = INVALID_HANDLE;
new bool:clientCashed[MAXPLAYERS], Handle:clientCashTimer[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "MvM Set/Add Money",
	author = "Chefe - edited by Whai",
	description = "Add/set players amount of cash",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=197909"
}

public OnPluginStart()
{
	RegAdminCmd("sm_setmoney", Command_SetMoney, ADMFLAG_GENERIC, "Set money of specifed userid");
	RegAdminCmd("sm_addmoney", Command_AddMoney, ADMFLAG_GENERIC, "Set money of specifed userid");
	cv_auto = CreateConVar("sm_setaddmoney_auto", "0.0", "If non zero adding this amount of cash to each player who comes in", _, true, 0.0, true, 32767.0);
	CreateConVar("sm_setaddmoney_version", VERSION, "Version of the Plugin", FCVAR_NOTIFY);
	
	HookEvent("player_spawn", Event_Spawn);
	
	AutoExecConfig(true);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	for (new i=0; i<MAXPLAYERS; i++)
	{
		clientCashed[i] = false;
	}
}

public OnClientDisconnect(client)
{
	clientCashed[client] = false;
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!clientCashed[client] && IsPlayerAlive(client) && clientCashTimer[client] == INVALID_HANDLE && !IsFakeClient(client))
	{
		clientCashTimer[client] = CreateTimer(2.0, cashClient, client);
	}
}

public Action:cashClient(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		addClientCash(client, GetConVarInt(cv_auto));
		
		clientCashed[client] = true;
		clientCashTimer[client] = INVALID_HANDLE;
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
	/* Block us from being called twice */
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	/* If the category is third party, it will have its own unique name. */
	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		/* Error! */
		return;
	}
 
	AddToTopMenu(hAdminMenu, "sm_addmoney", TopMenuObject_Item, AdminMenu_AddMoney, player_commands, "sm_addmoney", ADMFLAG_GENERIC);
	AddToTopMenu(hAdminMenu, "sm_setmoney", TopMenuObject_Item, AdminMenu_SetMoney, player_commands, "sm_setmoney", ADMFLAG_GENERIC);
}

public AdminMenu_AddMoney(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Money Add (MvM)");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		hPlayerSelectMenu = CreateMenu(Menu_PlayerSelect);
		SetMenuTitle(hPlayerSelectMenu, "Select Target");
		
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
			
			new String:infostr[128];
			Format(infostr, sizeof(infostr), "%N (%i)", i, getClientCash(i));
			
			new String:indexstr[32];
			IntToString(i, indexstr, sizeof(indexstr)); 
			
			AddMenuItem(hPlayerSelectMenu,indexstr, infostr)
		}
		
		InsertMenuItem(hPlayerSelectMenu, 0, "red", "Red Team");
		InsertMenuItem(hPlayerSelectMenu, 1, "blue", "Blu Team");
		InsertMenuItem(hPlayerSelectMenu, 2, "all", "All Players");
		
		SetMenuExitButton(hPlayerSelectMenu, true);
		DisplayMenu(hPlayerSelectMenu, param, MENU_TIME_FOREVER);
	}
}

public AdminMenu_SetMoney(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Money Set (MvM)");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		hPlayerSelectMenu = CreateMenu(Menu_PlayerSelect1);
		SetMenuTitle(hPlayerSelectMenu, "Select Target");
		
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
			
			new String:infostr[128];
			Format(infostr, sizeof(infostr), "%N (%i)", i, getClientCash(i));
			
			new String:indexstr[32];
			IntToString(i, indexstr, sizeof(indexstr)); 
			
			AddMenuItem(hPlayerSelectMenu,indexstr, infostr)
		}
		
		InsertMenuItem(hPlayerSelectMenu, 0, "red", "Red Team");
		InsertMenuItem(hPlayerSelectMenu, 1, "blue", "Blu Team");
		InsertMenuItem(hPlayerSelectMenu, 2, "all", "All Players");
		
		SetMenuExitButton(hPlayerSelectMenu, true);
		DisplayMenu(hPlayerSelectMenu, param, MENU_TIME_FOREVER);
	}
}

public Menu_PlayerSelect(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		hAmountSelectMenu = CreateMenu(Menu_AmountSelect);
		SetMenuTitle(hAmountSelectMenu, "Select Amount");
		
		AddMenuItem(hAmountSelectMenu, "0", "0");
		AddMenuItem(hAmountSelectMenu, "50", "50");
		AddMenuItem(hAmountSelectMenu, "100", "100");
		AddMenuItem(hAmountSelectMenu, "500", "500");
		AddMenuItem(hAmountSelectMenu, "1000", "1000");
		AddMenuItem(hAmountSelectMenu, "5000", "5000");
		AddMenuItem(hAmountSelectMenu, "10000", "10000");
		AddMenuItem(hAmountSelectMenu, "30000", "30000");
		AddMenuItem(hAmountSelectMenu, "3000000", "3000000");
		
		AddMenuItem(hAmountSelectMenu, info, "", ITEMDRAW_IGNORE);
		
		SetMenuExitButton(hAmountSelectMenu, true);
		DisplayMenu(hAmountSelectMenu, param1, MENU_TIME_FOREVER);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_PlayerSelect1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		hAmountSelectMenu = CreateMenu(Menu_AmountSelect1);
		SetMenuTitle(hAmountSelectMenu, "Select Amount");
		
		AddMenuItem(hAmountSelectMenu, "0", "0");
		AddMenuItem(hAmountSelectMenu, "50", "50");
		AddMenuItem(hAmountSelectMenu, "100", "100");
		AddMenuItem(hAmountSelectMenu, "500", "500");
		AddMenuItem(hAmountSelectMenu, "1000", "1000");
		AddMenuItem(hAmountSelectMenu, "5000", "5000");
		AddMenuItem(hAmountSelectMenu, "10000", "10000");
		AddMenuItem(hAmountSelectMenu, "30000", "30000");
		AddMenuItem(hAmountSelectMenu, "3000000", "3000000");
		
		AddMenuItem(hAmountSelectMenu, info, "", ITEMDRAW_IGNORE);
		
		SetMenuExitButton(hAmountSelectMenu, true);
		DisplayMenu(hAmountSelectMenu, param1, MENU_TIME_FOREVER);
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_AmountSelect(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:stramount[32];
		GetMenuItem(menu, param2, stramount, sizeof(stramount));
		new amount = StringToInt(stramount);
		
		new String:target[32];
		GetMenuItem(menu, GetMenuItemCount(menu)-1, target, sizeof(target));
		
		if (!StrEqual(target, "blue") && !StrEqual(target, "red") && !StrEqual(target, "all"))
		{
			new client = StringToInt(target);
			
			if (IsClientInGame(client))
			{
				addClientCash(client, amount);
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
						addClientCash(i, amount);
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
					
					addClientCash(i, amount);
				}
			}
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_AmountSelect1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:stramount[32];
		GetMenuItem(menu, param2, stramount, sizeof(stramount));
		new amount = StringToInt(stramount);
		
		new String:target[32];
		GetMenuItem(menu, GetMenuItemCount(menu)-1, target, sizeof(target));
		
		if (!StrEqual(target, "blue") && !StrEqual(target, "red") && !StrEqual(target, "all"))
		{
			new client = StringToInt(target);
			
			if (IsClientInGame(client))
			{
				setClientCash(client, amount);
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
						setClientCash(i, amount);
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
					
					setClientCash(i, amount);
				}
			}
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_SetMoney(client, args)
{
	if (args > 2 && args < 1)
	{
		if(CheckCommandAccess(client, "sm_setaddmoney_target", ADMFLAG_KICK))
		{
			ReplyToCommand(client, "Usage: sm_setmoney <target> <amount>");
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "Usage: sm_setmoney <amount>");
			return Plugin_Handled;
		}
	}
	
	
	 
	if(args == 2)
	{
		new String:amount[64];
		GetCmdArg(2, amount, sizeof(amount));
		new String:arg1[MAX_NAME_LENGTH]
		GetCmdArg(1, arg1, sizeof(arg1));
		if(CheckCommandAccess(client, "sm_setaddmoney_target", ADMFLAG_KICK))
		{
			new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (new i = 0; i < target_count; i++)
			{
				new target = target_list[i];
				setClientCash(target, StringToInt(amount));
			}
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "Set cash to %s", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "Set cash to %s", target_name);
			}
		}
		else
		{
			ReplyToCommand(client, "You don't have access to target anyone");
		}
	}
	if(args == 1)
	{
		decl String:amount[64];
		GetCmdArg(1, amount, sizeof(amount));
		setClientCash(client, StringToInt(amount));
	}
	return Plugin_Handled;
}

public Action:Command_AddMoney(client, args)
{
	if (args > 2 && args < 1)
	{
		if(CheckCommandAccess(client, "sm_setaddmoney_target", ADMFLAG_KICK))
		{
			ReplyToCommand(client, "Usage: sm_addmoney <target> <amount>");
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "Usage: sm_addmoney <amount>");
			return Plugin_Handled;
		}
	}
	
	if(args == 2)
	{
		new String:arg1[MAX_NAME_LENGTH]
		GetCmdArg(1, arg1, sizeof(arg1));
		new String:amount[64];
		GetCmdArg(2, amount, sizeof(amount));
		if(CheckCommandAccess(client, "sm_setaddmoney_target", ADMFLAG_KICK))
		{
			new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
			if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (new i = 0; i < target_count; i++)
			{
				new target = target_list[i];
				addClientCash(target, StringToInt(amount));
			}
			if (tn_is_ml)
			{
				ShowActivity2(client, "[SM] ", "Add cash to %s", target_name);
			}
			else
			{
				ShowActivity2(client, "[SM] ", "Add cash to %s", target_name);
			}
		}
		else
		{
			ReplyToCommand(client, "You don't have access to target anyone");
		}
	}
	
	if(args == 1)
	{
		decl String:amount[64];
		GetCmdArg(1, amount, sizeof(amount));
		addClientCash(client, StringToInt(amount));
	}
	return Plugin_Handled;
}

stock hClientCash(amount) 
{
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (!IsFakeClient(i))
		{
			addClientCash(i, amount);
		}
	}
}

getClientCash(client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

setClientCash(client, amount)
{
	SetEntProp(client, Prop_Send, "m_nCurrency", amount);
}

addClientCash(client, amount)
{
	setClientCash(client, amount+getClientCash(client));
}