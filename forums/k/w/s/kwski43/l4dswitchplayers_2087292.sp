/********************************************************************************************
* Plugin	: L4DSwitchPlayers
* Version	: 1.5
* Game		: Left 4 Dead 2
* Author	: SkyDavid (djromero)
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugin allows admins to switch player's teams or swap 2 players
* 
* Version 1.0:
* 		- Initial release
* 
* Version 1.1:
* 		- Added check to prevent switching a player to a team that is already full
* 
* Version 1.2:
* 		- Added cvar to bypass team full check (l4dswitch_checkteams). Default = 1. 
* 		  Change to 0 to disable it.
* 		- Added new Swap Players option, that allows to immediately swap 2 player's teams.
* 		  (2 lines of code taken from Downtown1's L4d Ready up plugin)
* Version 1.2.1:
* 		- Added public cvar.
* Version 1.3:
* 		- Fixed plubic cvar to disable check of full teams.
* 		- Added validations to prevent log errors when a player leaves the game before it
* 		  gets switched/swapped.
* Version 1.4:
*		- Added support for L4D2. Thanks to AtomicStryker for finding the new signature.
* Version 1.5: ( By: https://forums.alliedmods.net/member.php?u=50161 )
* 		- Fixed swapping in L4D2
* 		- Fixed small bug in PerformSwitch()
*   
*********************************************************************************************/

#define PLUGIN_VERSION "1.5"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#undef REQUIRE_PLUGIN
#include <adminmenu>


// top menu
new Handle:hTopMenu = INVALID_HANDLE;

// Sdk calls
new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

new Handle:Survivor_Limit;
new Handle:Infected_Limit;
new Handle:h_Switch_CheckTeams;

new bool:IsSwapPlayers;
new bool:IsL4D2 = false;
new SwapPlayer1;
new SwapPlayer2;


public Plugin:myinfo = 
{
	name = "L4DSwitchPlayers",
	author = "SkyDavid (djromero)",
	description = "Adds options to players commands menu to switch and swap players' team",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	new String: GameName[64] = "";
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		IsL4D2 = true;
	
	// We register the version cvar
	CreateConVar("l4d_switchplayers_version", PLUGIN_VERSION, "Version of L4D Switch Players plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	
	// SDK Calls: Copied from L4DUnscrambler plugin, made by Fyren (http://forums.alliedmods.net/showthread.php?p=730278)
	gConf = LoadGameConfigFile("l4dswitchplayers");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	
	Survivor_Limit = FindConVar("survivor_limit");
	Infected_Limit = FindConVar("z_max_player_zombies");
	
	// New console variables
	h_Switch_CheckTeams = CreateConVar("l4dswitch_checkteams", "1", "Determines if the function should check if target team is full", ADMFLAG_KICK, true, 0.0, true, 1.0);
	
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
		AddToTopMenu (hTopMenu, "l4dteamswitch", TopMenuObject_Item, SkyAdmin_SwitchPlayer, players_commands, "l4dteamswitch", ADMFLAG_KICK);
		AddToTopMenu (hTopMenu, "l4dswapplayers", TopMenuObject_Item, SkyAdmin_SwapPlayers, players_commands, "l4dswapplayers", ADMFLAG_KICK);
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
	AddMenuItem(menu, "2", "Survivors");
	AddMenuItem(menu, "3", "Infected");
	
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
	if (team == 1)
		return false;
	
	new max;
	new count;
	new i;
	
	// we count the players in the survivor's team
	if (team == 2)
	{
		max = GetConVarInt(Survivor_Limit);
		count = 0;
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==2))
				count++;
		}
	else if (team == 3) // we count the players in the infected's team
	{
		max = GetConVarInt(Infected_Limit);
		count = 0;
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==3))
				count++;
		}
	
	// If full ...
	if (count >= max)
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
	
	// Just in case survivor's team becomes empty (copied from Downtown1's L4d Ready up plugin)
	if(!IsL4D2)
		SetConVarInt(FindConVar("sb_all_bot_team"), 1);
	else
		SetConVarInt(FindConVar("sb_all_bot_game"), 1);	
	
	// first we move both clients to spectators
	PerformSwitch(client, SwapPlayer1, 1, true);
	PerformSwitch(client, SwapPlayer2, 1, true);
	
	// Now we move each client to their respective team
	PerformSwitch(client, SwapPlayer1, team2, true);
	PerformSwitch(client, SwapPlayer2, team1, true);
	
	// Just in case survivor's team becomes empty
	if(!IsL4D2)
		ResetConVar(FindConVar("sb_all_bot_team"));
	else
		ResetConVar(FindConVar("sb_all_bot_game"));
	
	// Print swap info ..
	new String:PlayerName1[200];
	new String:PlayerName2[200];
	GetClientName(SwapPlayer1, PlayerName1, sizeof(PlayerName1));
	GetClientName(SwapPlayer2, PlayerName2, sizeof(PlayerName2));
	PrintToChat(client, "\x01[SM] \x03%s \x01has been swapped with \x03%s", PlayerName1, PlayerName2);
}


PerformSwitch (client, target, team, bool:silent)
{
	if ((!IsClientConnected(target)) || (!IsClientInGame(target)))
	{
		PrintToChat(client, "[SM] The player is not avilable anymore.");
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
				PrintToChat(client, "[SM] The \x03Survivor\x01's team is already full.");
			else
				PrintToChat(client, "[SM] The \x03Infected\x01's team is already full.");
			return;
		}
	}
	
	// If player was on infected .... 
	if (GetClientTeam(target) == 3)
	{
		// ... and he wasn't a tank ...
		new String:iClass[100];
		GetClientModel(target, iClass, sizeof(iClass));
		if (StrContains(iClass, "hulk", false) == -1)
			ForcePlayerSuicide(target);	// we kill him
	}
	
	// If target is survivors .... we need to do a little trick ....
	if (team == 2)
	{
		// first we switch to spectators ..
		ChangeClientTeam(target, 1); 
		
		// Search for an empty bot
		new bot = 1;
		while !(IsClientConnected(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)) do bot++;
			
		// force player to spec humans
		SDKCall(fSHS, bot, target); 
		
		// force player to take over bot
		SDKCall(fTOB, target, true); 
	}
	else // We change it's team ...
	{
		ChangeClientTeam(target, team);
	}
	
	// Print switch info ..
	new String:PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	if (!silent)
	{
		if (team == 1)
			PrintToChat(client, "\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
		else if (team == 2)
			PrintToChat(client, "\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
		else if (team == 3)
			PrintToChat(client, "\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
	}
}