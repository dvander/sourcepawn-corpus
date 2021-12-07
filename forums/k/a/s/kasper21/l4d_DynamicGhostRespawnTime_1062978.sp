// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
// *********************************************************************************
// DEFINE
// *********************************************************************************
#define PLUGIN_VERSION      "1.0"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define TEAM_INFECTED 3
// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name        = "Dynamic Ghost Respawn Time",
	author      = "Xx_Faxe_xX",
	description = "Decreases or Increases the min and max ghost respawn delays depending on number of infected players",
	version     = PLUGIN_VERSION,
	url         = "http://www.black-scorpions.com"
}; 
// *********************************************************************************
// PLUGINSTART
// *********************************************************************************
// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead", false) && !StrEqual(ModName, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead (2) only.");
	}

	CreateConVar("l4d_DynamicGhostRespawnTime", PLUGIN_VERSION, "Dynamic Ghost Respawn Time", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

// ------------------------------------------------------------------------
// OnClientPutInServer ()
// ------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	CreateTimer(0.1, ChangeRespawnTime, client);
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	CreateTimer(0.1, ChangeRespawnTime, client);
}

// ------------------------------------------------------------------------
// ChangeRespawnTime()
// ------------------------------------------------------------------------
public Action:ChangeRespawnTime(Handle:timer, any:client)
{
	if (GetInfCount(TEAM_INFECTED) == 4) //infected humcount is 4
	{
		SetConVarInt(FindConVar("z_ghost_delay_min"), 20);
		SetConVarInt(FindConVar("z_ghost_delay_max"), 30);
		return Plugin_Handled;
	}
	if (GetInfCount(TEAM_INFECTED) == 3) //infected humcount is 3
	{
		SetConVarInt(FindConVar("z_ghost_delay_min"), 15);
		SetConVarInt(FindConVar("z_ghost_delay_max"), 20);
		return Plugin_Handled;
	}
	if (GetInfCount(TEAM_INFECTED) == 2) //infected humcount is 2
	{
		SetConVarInt(FindConVar("z_ghost_delay_min"), 10);
		SetConVarInt(FindConVar("z_ghost_delay_max"), 15);
		return Plugin_Handled;
	}
	if (GetInfCount(TEAM_INFECTED) == 1) //infected humcount is 1
	{
		SetConVarInt(FindConVar("z_ghost_delay_min"), 5);
		SetConVarInt(FindConVar("z_ghost_delay_max"), 10);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// GetInfCount
// ------------------------------------------------------------------------
stock GetInfCount(team)
{
	new humans = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			humans++;
		}
	}
	return humans;
}
