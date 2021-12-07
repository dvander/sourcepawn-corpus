/********************************************************************************************
* Plugin	: TF2SwitchPlayers
* Version	: 1.0
* Game		: Team Fortress 2
* Author	: Kevinbrunet
* 
* Purpose	: This plugin allows admins to switch player's teams or swap 2 players
* 
* Version 1.0:
* 		- Initial release
* Version 1.1:
* 		- Fix some bugs
*  
*********************************************************************************************/

#define PLUGIN_VERSION "1.1"
#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define TEAM_RED 2
#define TEAM_BLUE 3


// top menu
new Handle:hTopMenu = INVALID_HANDLE;

new Handle:h_Switch_CheckTeams;

new bool:IsSwapPlayers;
new SwapPlayer1;
new SwapPlayer2;


public Plugin:myinfo = 
{
	name = "TF2SwitchPlayers",
	author = "Kevinbrunet",
	description = "Adds options to players commands menu to switch and swap players' team",
	version = PLUGIN_VERSION,
	//url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	// We register the version cvar
	CreateConVar("tf2_switchplayers_version", PLUGIN_VERSION, "Version of TF2 Switch Players plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// New console variables
	h_Switch_CheckTeams = CreateConVar("tf2switch_checkteams", "1", "Determines if the function should check if target team is full", ADMFLAG_KICK, true, 0.0, true, 1.0);
	
	// First we check if menu is ready ..
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
}
new g_SwitchTo;
new g_SwitchTarget;

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Check ..
	if (topmenu == hTopMenu) return;
	
	// We save the handle
	hTopMenu = topmenu;
	
	// Find player's menu ...
	new TopMenuObject:players_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu (hTopMenu, "tf2teamswitch", TopMenuObject_Item, SkyAdmin_SwitchPlayer, players_commands, "tf2teamswitch", ADMFLAG_KICK);
		AddToTopMenu (hTopMenu, "tf2swapplayers", TopMenuObject_Item, SkyAdmin_SwapPlayers, players_commands, "tf2swapplayers", ADMFLAG_KICK);
	}
}

public SkyAdmin_SwitchPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	IsSwapPlayers = false;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch player", "", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//DisplaySwitchPlayerToMenu(param);
		DisplaySwitchPlayerMenu(param);
	}
}

public SkyAdmin_SwapPlayers(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	IsSwapPlayers = true;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Swap players", "", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//DisplaySwitchPlayerToMenu(param);
		DisplaySwitchPlayerMenu(param);
	}
}


DisplaySwitchPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayer);
	
	decl String:title[100];
	if (!IsSwapPlayers)
		Format(title, sizeof(title), "Switch player", "", client);
	else
	{
		if (SwapPlayer1 == -1)
			Format(title, sizeof(title), "Player 1", "", client);
		else
		Format(title, sizeof(title), "Player 2", "", client);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SwitchPlayer(Handle:menu, MenuAction:action, param1, param2)
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
		
		if (IsSwapPlayers)
		{
			if (SwapPlayer1 == -1)
				SwapPlayer1 = target;
			else
			SwapPlayer2 = target;
			
			if ((SwapPlayer1 != -1)&&(SwapPlayer2 != -1))
			{
				PerformSwap(param1);
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
			else
			DisplaySwitchPlayerMenu(param1);
			
		}
		else
		{
			g_SwitchTarget = target;
			DisplaySwitchPlayerToMenu(param1);
		}
	}
}

DisplaySwitchPlayerToMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayerTo);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose team", "", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "1", "Spectators");
	AddMenuItem(menu, "2", "Red");
	AddMenuItem(menu, "3", "Blue");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SwitchPlayerTo(Handle:menu, MenuAction:action, param1, param2)
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
		
		GetMenuItem(menu, param2, info, sizeof(info));
		g_SwitchTo = StringToInt(info);
		
		PerformSwitch(param1, g_SwitchTarget, g_SwitchTo, false);
		
		DisplaySwitchPlayerMenu(param1);
	}
}


bool:IsTeamFull (team)
{
	// Spectator's team is never full :P
	if (team == 1) return false;
	
	new count=0;
	new i;
	
	// we count the players in the Red team
	if (team == 2){
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==2))
				count++;
	}
	else if (team == 3) { // we count the players in the Blue team
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==3))
				count++;
	}
	
	// If full ...
	if (2*count >= MaxClients)
		return true;
	else
	return false;
}


PerformSwap (client)
{
	// If client 1 and 2 are the same ...
	if (SwapPlayer1 == SwapPlayer2)
	{
		PrintToChat(client, "[SM] Can't swap this player with himself.");
		return;
	}
	
	// Check if 1st player is still valid ...
	if ((!IsClientConnected(SwapPlayer1)) || (!IsClientInGame(SwapPlayer1)))
	{
		PrintToChat(client, "[SM] First player is not available anymore.");
		return;
	}

	// Check if 2nd player is still valid ....
	if ((!IsClientConnected(SwapPlayer2)) || (!IsClientInGame(SwapPlayer2)))
	{
		PrintToChat(client, "[SM] Second player is not available anymore.");
		return;
	}
	
	// get the teams of each player
	new team1 = GetClientTeam(SwapPlayer1);
	new team2 = GetClientTeam(SwapPlayer2);
	
	// If both players are on the same team ...
	if (team1 == team2)
	{
		PrintToChat(client, "[SM] Can't swap players that are on the same team.");
		return;
	}
	
	// first we move both clients to spectators
	PerformSwitch(client, SwapPlayer1, 1, true);
	PerformSwitch(client, SwapPlayer2, 1, true);
	
	// Now we move each client to their respective team
	PerformSwitch(client, SwapPlayer1, team2, true);
	PerformSwitch(client, SwapPlayer2, team1, true);	
	
	// Print swap info ..
	new String:PlayerName1[200];
	new String:PlayerName2[200];
	GetClientName(SwapPlayer1, PlayerName1, sizeof(PlayerName1));
	GetClientName(SwapPlayer2, PlayerName2, sizeof(PlayerName2));
	PrintToChatAll("\x01[SM] \x03%s \x01has been swapped with \x03%s", PlayerName1, PlayerName2);
}


PerformSwitch (client, target, team, bool:silent)
{
	if ((!IsClientConnected(client)) || (!IsClientInGame(client)))
	{
		PrintToChat(client, "[SM] The player is not available anymore.");
		return;
	}
	
	// If teams are the same ...
	if (GetClientTeam(target) == team)
	{
		PrintToChat(client, "[SM] That player is already on that team.");
		return;
	}
	
	// If we should check if teams are fulll ...
	if (GetConVarBool(h_Switch_CheckTeams))
	{
		// We check if target team is full...
		if (IsTeamFull(team))
		{
			if (team == 2)
				PrintToChat(client, "[SM] The \x03Red\x01 team is already full.");
			else
			PrintToChat(client, "[SM] The \x03Blue\x01 team is already full.");
			return;
		}
	}
	
	ChangeClientTeam(target, team);
	
	// Print switch info ..
	new String:PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	if (!silent)
	{
		if (team == 1)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
		else if (team == 2)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to the \x03Red Team", PlayerName);
		else if (team == 3)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to the \x03Blue Team", PlayerName);
	}
}