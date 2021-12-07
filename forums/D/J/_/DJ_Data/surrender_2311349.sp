#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

//=================================================================================================================================================================================================//
// Variables
//=================================================================================================================================================================================================//

new String:clientTeam[6] = "null";
new clientTeamIndex = 0;
new bool:isInCooldown = false;

//=================================================================================================================================================================================================//
// Plugin Info & Start
//=================================================================================================================================================================================================//

public Plugin:myinfo =
{
	name = "[TF2] Surrender",
	author = "Danian",
	description = "Allows a team to surrender if undergoing bad morale.",
	version = PLUGIN_VERSION,
	url = "http://danian.website"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_surrender", Command_SurrenderVote);

	CreateConVar("surrender_version", "1.0", "Version of the '[TF2] Surrender' plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	
	////Prevent broken boot////
	new String:sGameDir[32];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if (StrContains(sGameDir, "tf", false) == -1)
	{
		SetFailState("[TF2] Surrender only works for TF2. Please remove the plugin from your plugins folder.");
	}
}

//=================================================================================================================================================================================================//
// Custom Functions
//=================================================================================================================================================================================================//

stock bool:VoteMenuToTeam(Handle:menu, time, team, flags=0)
{
	CPrintToChatAll("{black}[{white}Surrender{black}] {gold}Team %s wants to surrender! Starting vote..", clientTeam);
	
	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != team)
		{
			continue;
		}
		players[total++] = i;
	}
	
	return VoteMenu(menu, players, total, time, flags);
}

SurrenderGame()
{
	new iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
		{
			CPrintToChatAll("{red}[Surrender] Unable to find or create a game_round_win entity!");
		}
	}
	
	new iWinningTeam;
	
	if(clientTeamIndex == 2) // if red surrendered
	{
		iWinningTeam = 3; // blue wins
	}
	else if(clientTeamIndex == 3) // if blue surrendered
	{
		iWinningTeam = 2; // red wins
	}
		
	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
}

//=================================================================================================================================================================================================//
// Timers
//=================================================================================================================================================================================================//

public Action:Cooldown(Handle:timer)
{
	isInCooldown = false;
}

//=================================================================================================================================================================================================//
// Commands
//=================================================================================================================================================================================================//

public Action:Command_SurrenderVote(client, args)
{
	if(isInCooldown)
	{
		CPrintToChat(client, "{black}[{white}Surrender{black}] {red}The {gold}!surrender {red}command is currently on cooldown! Try again later.");
		return Plugin_Handled;
	}
	else if(!isInCooldown)
	{
		isInCooldown = true;
		CreateTimer(600.0, Cooldown); // 600 second cooldown (10 min)
	}
	
	new team = GetClientTeam(client);
	
	if(team != 2 && team != 3)
	{
		CPrintToChat(client, "{black}[{white}Surrender{black}] {red}Please join a valid team.");
	}
	
	new Handle:menu = CreateMenu(menuhandle, MenuAction:MENU_ACTIONS_ALL); 
	SetMenuTitle(menu, "Your team wants to surrender!"); 

	AddMenuItem(menu, "yes", "Surrender.."); 
	AddMenuItem(menu, "no", "Fight on!"); 
	
	SetMenuExitButton(menu, false);
	
	if(team == 2)
	{
		clientTeam = "Red";
		clientTeamIndex = 2;
		VoteMenuToTeam(menu, 30, team);
	}
	else if(team == 3)
	{
		clientTeam = "Blue";
		clientTeamIndex = 3;
		VoteMenuToTeam(menu, 30, team);
	}

	return Plugin_Handled;
}

//=================================================================================================================================================================================================//
// Menus
//=================================================================================================================================================================================================//

public menuhandle(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action) 
	{ 
		case MenuAction_End: 
		{ 
			//
		} 

		case MenuAction_VoteEnd: 
		{ 
			//param1 is item 
			new String:item[64]; 
			GetMenuItem(menu, param1, item, sizeof(item)); 

			if (StrEqual(item, "yes")) 
			{ 
				CPrintToChatAll("{black}[{white}Surrender{black}] {gold}Team %s has surrendered.", clientTeam);
				SurrenderGame();
			} 
			else if (StrEqual(item, "no"))
			{ 
				CPrintToChatAll("{black}[{white}Surrender{black}] {gold}Team %s did not achieve enough votes to surrender. Fight on!", clientTeam);
			} 
		} 
	} 
}  

//=================================================================================================================================================================================================//
// End
//=================================================================================================================================================================================================//