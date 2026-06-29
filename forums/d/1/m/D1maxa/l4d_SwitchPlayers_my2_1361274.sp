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
* Version 1.5:
* 		- fixes by D1maxa
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

//for different admins in one time we need Dimensions
new bool:IsSwapPlayers[MAXPLAYERS+1];
new SwapPlayer1[MAXPLAYERS+1];
new SwapPlayer2[MAXPLAYERS+1];
new g_SwitchTarget[MAXPLAYERS+1];

new playerTeam[MAXPLAYERS+1];
new bool:timeout[MAXPLAYERS+1];
new Handle:mp_gamemode;
new Handle:sb_all_bot_team;

public Plugin:myinfo = 
{
	name = "L4DSwitchPlayers",
	author = "SkyDavid (djromero), fixes by D1maxa",
	description = "Adds optiosn to players commands menu to switch and swap players' team",
	version = PLUGIN_VERSION,
	url = "www.sky.zebgames.com"
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game,sizeof(game));
	if (StrEqual(game, "left4dead", false))
		sb_all_bot_team = FindConVar("sb_all_bot_team");
	else if (StrEqual(game, "left4dead2", false))
		sb_all_bot_team = FindConVar("sb_all_bot_game");
	else SetFailState("This plugin for L4D/L4D2 only");
	
	LoadTranslations("common.phrases");
	LoadTranslations("switchplayers.phrases");
	
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
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);	
	HookEvent("player_team", Event_PlayerTeam);	
	RegConsoleCmd("sm_afk", AfkCommand, "Switch yourself to spectators or back to team");
	mp_gamemode = FindConVar("mp_gamemode");	
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:Gamemode[16];
	GetConVarString(mp_gamemode,Gamemode,sizeof(Gamemode));
	if (StrEqual(Gamemode,"versus",false) || StrEqual(Gamemode,"mutation12",false))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if (3 - playerTeam[i] < 2)
				playerTeam[i] = 5 - playerTeam[i];
		}
	}
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new newTeam = GetEventInt(event, "team");
	new oldTeam = GetEventInt(event, "oldteam");
	new bool:isbot = GetEventBool(event,"isbot");	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!isbot && newTeam == 1)
	{
		playerTeam[client] = oldTeam;	 
	}
}

public OnClientDisconnect(client)
{
	playerTeam[client] = 0;
}

public Action:AfkCommand(client, Args)
{
	if (timeout[client])
	{
		PrintToChat(client, "%t", "Don't use afk command too often");
		return;
	}
	timeout[client] = true;
	CreateTimer(5.0,TimeoutOff,client);
	if (GetClientTeam(client) == 1)
	{
		//from spec to back
		new oldteam = playerTeam[client];
		
		if (oldteam == 2 || oldteam == 3)
		{
			if (IsTeamFull(oldteam))
			{
				if (IsTeamFull(5 - oldteam))
				{
					//impossible situation but...
					PrintToChat(client, "%t", "There is no place for you in both teams");
				}
				else
				{
					PerformSwitch(client,client,5-oldteam,false);
				}				
			}	
			else
			{
				PerformSwitch(client,client,oldteam,false);
			}
		}
		else
		{			
			if (GetTeamHumanCount(2) < GetTeamHumanCount(3))
				PerformSwitch(client,client,2,false);
			else
				PerformSwitch(client,client,3,false);			
		}
	}
	else
	{
		//to spectators
		PerformSwitch(client,client,1,false);		
	}	
}

public Action:TimeoutOff(Handle:timer,any:client)
{
	timeout[client] = false;	
}

GetTeamHumanCount(team)
{
	new num;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team) 
			num++;
	}	
	return num;
}

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
	IsSwapPlayers[param] = false;
	SwapPlayer1[param]  = -1;
	SwapPlayer2[param]  = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Switch player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{		
		DisplaySwitchPlayerMenu(param);
	}
}

public SkyAdmin_SwapPlayers(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	IsSwapPlayers[param] = true;
	SwapPlayer1[param] = -1;
	SwapPlayer2[param] = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Swap players", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{		
		DisplaySwitchPlayerMenu(param);
	}
}


DisplaySwitchPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayer);
	
	if (!IsSwapPlayers[client])
		SetMenuTitle(menu, "%T:", "Switch player", client);		
	else
	{
		if (SwapPlayer1[client] == -1)
			SetMenuTitle(menu, "%T 1:", "Player", client);			
		else
			SetMenuTitle(menu, "%T 2:", "Player", client);			
	}
	
	SetMenuExitBackButton(menu, true);
	
	decl String:clientid[4];
	decl String:name[MAX_NAME_LENGTH];
	//AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	
	//first set survivors to menu
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{			 
			IntToString(i, clientid, sizeof(clientid));
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, clientid, name);
		}
	}
	
	//second set infecteds to menu
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3)
		{			 
			IntToString(i, clientid, sizeof(clientid));
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, clientid, name);
		}
	}
	
	//third set spectators to menu
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 1)
		{			 
			IntToString(i, clientid, sizeof(clientid));
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, clientid, name);
		}
	}
	
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
		new target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		target = StringToInt(info);
		
		if (!IsClientInGame(target))
		{
			PrintToChat(param1, "%t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "%t", "Unable to target");
		}
		
		if (IsSwapPlayers[param1])
		{
			if (SwapPlayer1[param1] == -1)
				SwapPlayer1[param1] = target;
			else
				SwapPlayer2[param1] = target;
			
			if ((SwapPlayer1[param1] != -1)&&(SwapPlayer2[param1] != -1))
			{
				PerformSwap(param1);
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
			else
				DisplaySwitchPlayerMenu(param1);			
		}
		else
		{
			g_SwitchTarget[param1] = target;
			DisplaySwitchPlayerToMenu(param1);
		}
	}
}

DisplaySwitchPlayerToMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayerTo);
	
	SetMenuTitle(menu, "%T:", "Choose team", client);
	SetMenuExitBackButton(menu, true);
	
	//Translations
	new String:item[32];
	Format(item, sizeof(item), "%T", "Spectators", client);
	AddMenuItem(menu, "1", item);
	Format(item, sizeof(item), "%T", "Survivors", client);
	AddMenuItem(menu, "2", item);
	Format(item, sizeof(item), "%T", "Infecteds", client);
	AddMenuItem(menu, "3", item);
	
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
		new g_SwitchTo = StringToInt(info);
		
		if (IsClientInGame(g_SwitchTarget[param1]))
			PerformSwitch(param1, g_SwitchTarget[param1], g_SwitchTo, false);
		else
			PrintToChat(param1, "%t", "Player no longer available");
		
		DisplaySwitchPlayerMenu(param1);
	}
}


bool:IsTeamFull (team)
{
	// Spectator's team is never full :P
	if (team == 1)
		return false;
	
	new max;
	new count = GetTeamHumanCount(team);			
	
	if (team == 2)	
		max = GetConVarInt(Survivor_Limit);		
	else if (team == 3)
		max = GetConVarInt(Infected_Limit);		
	
	// If full ...
	return (count >= max);
}


PerformSwap (client)
{
	// If client 1 and 2 are the same ...
	if (SwapPlayer1[client] == SwapPlayer2[client])
	{
		PrintToChat(client, "%t", "Can't swap this player with himself.");
		return;
	}
	
	// Check if 1st player is still valid ...
	if (!IsClientInGame(SwapPlayer1[client]))
	{
		PrintToChat(client, "%t", "First player is not available anymore.");
		return;
	}

	// Check if 2nd player is still valid ....
	if (!IsClientInGame(SwapPlayer2[client]))
	{
		PrintToChat(client, "%t", "Second player is not available anymore.");
		return;
	}
	
	// get the teams of each player
	new team1 = GetClientTeam(SwapPlayer1[client]);
	new team2 = GetClientTeam(SwapPlayer2[client]);
	
	// If both players are on the same team ...
	if (team1 == team2)
	{
		PrintToChat(client, "%t", "Can't swap players that are on the same team.");
		return;
	}
	
	// Just in case survivor's team becomes empty (copied from Downtown1's L4d Ready up plugin)
	new prevValue = GetConVarInt(sb_all_bot_team);
	SetConVarInt(sb_all_bot_team, 1);
	
	// first we move both clients to spectators
	PerformSwitch(client, SwapPlayer1[client], 1, true);
	PerformSwitch(client, SwapPlayer2[client], 1, true);
	
	// Now we move each client to their respective team
	PerformSwitch(client, SwapPlayer1[client], team2, true);
	PerformSwitch(client, SwapPlayer2[client], team1, true);
	
	// Just in case survivor's team becomes empty
	SetConVarInt(sb_all_bot_team, prevValue);	
	
	// Print swap info ..
	new String:PlayerName1[MAX_NAME_LENGTH];
	new String:PlayerName2[MAX_NAME_LENGTH];
	GetClientName(SwapPlayer1[client], PlayerName1, sizeof(PlayerName1));
	GetClientName(SwapPlayer2[client], PlayerName2, sizeof(PlayerName2));
	//PrintToChatAll("\x01[SM] \x03%s \x01has been swapped with \x03%s", PlayerName1, PlayerName2);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			PrintToChat(i, "%t", "has been swapped with", PlayerName1, PlayerName2);
	}
}


PerformSwitch (client, target, team, bool:silent)
{
	if (!IsClientInGame(client))
	{
		//WTF!!!!!!!
		//PrintToChat(client, "[SM] The player is not avilable anymore.");
		return;
	}
	
	// If teams are the same ...
	if (GetClientTeam(target) == team)
	{
		PrintToChat(client, "%t", "That player is already on that team.");
		return;
	}
	
	// If we should check if teams are fulll ...
	if (GetConVarBool(h_Switch_CheckTeams))
	{
		// We check if target team is full...
		if (IsTeamFull(team))
		{
			if (team == 2)
				PrintToChat(client, "%t", "The Survivor's team is already full.");
			else
				PrintToChat(client, "%t", "The Infected's team is already full.");
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
		// Search for an empty bot
		new bot = 1;
		while (bot <= MaxClients && !(IsClientInGame(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)))
			bot++;
		if(bot>MaxClients)
		{
			PrintToChat(client, "%t", "Could not find Survivor bot.");
			return;
		}
		else
		{	
			// first we switch to spectators ..
			ChangeClientTeam(target, 1); 
			
			// force player to spec humans
			SDKCall(fSHS, bot, target); 
		
			// force player to take over bot
			SDKCall(fTOB, target, true); 
		}
	}
	else // We change it's team ...
	{
		ChangeClientTeam(target, team);
	}
	
	// Print switch info ..
	new String:PlayerName[MAX_NAME_LENGTH];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	if (!silent)
	{
		/*
		if (team == 1)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
		else if (team == 2)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
		else if (team == 3)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
		*/		
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (team == 1)
					PrintToChat(i, "%t \x03%t\x01.", "has been moved to", PlayerName, "Spectators");
				else if (team == 2)
					PrintToChat(i, "%t \x03%t\x01.", "has been moved to", PlayerName, "Survivors");
				else if (team == 3)
					PrintToChat(i, "%t \x03%t\x01.", "has been moved to", PlayerName, "Infecteds");
			}
		}
	}
}