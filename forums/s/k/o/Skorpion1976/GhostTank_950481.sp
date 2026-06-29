/*
* Ghost Tank
* 
* Mr. Zero
*/

#pragma semicolon 1

// INCLUDES
#include <sourcemod>
#include <sdktools>

// CONSTANTS
#define PLUGIN_VERSION			"0.94a"
#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_SPONLY
#define UNLIKELY_THROW_RANGE	999999999999.0

// GLOBAL VARIABLES
new g_iGhostStateOffset;
new g_iTankClient;
new g_bTankIsInPlay;
new g_bTankHasFireImmunity;
// Convars
new Handle:g_hGhostTank_Enable;
new Handle:g_hGhostTank_EnableGhosting;
new Handle:g_hGhostTank_Fireimmune;
new Handle:g_hGhostTank_FireimmuneTime;
// Handles for existing convars
new Handle:g_hTankRockThrowRangeConVar;
new Float:g_fTankRockThrowRangeReset;
new Handle:g_hSelectionTime;

public Plugin:myinfo = 
{
	name = "Ghost Tank",
	author = "Mr. Zero",
	description = "Upon tank spawn, the tank will be frozen and ghosted until a player takes over, plus additonal features.",
	version = "PLUGIN_VERSION",
	url = "http://forums.alliedmods.net/showthread.php?t=99202"
}

public OnPluginStart()
{
	CreateConVar("l4d_ghosttank_ver", PLUGIN_VERSION, "Ghost Tank Version", CVAR_FLAGS|FCVAR_REPLICATED);
	g_hGhostTank_Enable 		= CreateConVar("l4d_ghosttank_enable", "1", "Sets whether the plugin is active or not.", CVAR_FLAGS);
	g_hGhostTank_EnableGhosting	= CreateConVar("l4d_ghosttank_ghost", "1", "Sets whether tanks upon spawn will be set to ghost mode until a player takes over.", CVAR_FLAGS);
	g_hGhostTank_Fireimmune		= CreateConVar("l4d_ghosttank_fireimmune", "1", "Sets whether tanks upon spawn will be fireimmune for a period of time.", CVAR_FLAGS);
	g_hGhostTank_FireimmuneTime	= CreateConVar("l4d_ghosttank_fireimmune_time", "4.0", "The amount of time the tank is fire immune, after player takes control.", CVAR_FLAGS);
	
	AutoExecConfig(true, "GhostTank");
	
	g_iGhostStateOffset = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	g_hTankRockThrowRangeConVar = FindConVar("tank_throw_allow_range");
	g_hSelectionTime = FindConVar("director_tank_lottery_selection_time");
	g_fTankRockThrowRangeReset = GetConVarFloat(g_hTankRockThrowRangeConVar);
	
	HookEvent("tank_spawn", 	Event_TankSpawn);
	HookEvent("player_death",	Event_NotTank);
	HookEvent("player_hurt",	Event_TankOnFire);
	HookEvent("round_start", 	Event_RoundStart);
}

// Event_RoundStart
//  Reset the tank variables
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){ResetVars();}

// OnMapStart
//  Check on map start if gamemode is versus
public OnMapStart(){if(IsVersus()){SetConVarBool(g_hGhostTank_Enable,true);}else{SetConVarBool(g_hGhostTank_Enable,false);}}

// Event_NotTank
//  Get clientid of the player that died. If it was tank client, reset the tank variables.
public Event_NotTank(Handle:event, const String:name[], bool:dontBroadcast){new client = GetClientOfUserId(GetEventInt(event, "userid"));if(g_iTankClient == client){ResetVars();}}

// Event_TankSpawn
//  First check if the plugin is enabled.
//  Get the clientid of the spawned tank and set the tank client
//  If the tank is already in play (have been frozen once before) then return
//  Else check wether its a bot or real player and update the tank status.
public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hGhostTank_Enable)){return;}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;
	
	if(g_bTankIsInPlay){return;}
	
	if(IsFakeClient(client))
	{
		SetTankStatus(client,true);
		new Float:IdleTime = (GetConVarFloat(g_hSelectionTime) + 0.5);
		CreateTimer(IdleTime,AITimer,client);
	}
	else
	{
		SetTankStatus(client,false);
		g_bTankIsInPlay = true;
		CreateTimer(GetConVarFloat(g_hGhostTank_FireimmuneTime),FireImmunityTimer,0);
		PrintHintText(client, "You are fireimmune for 4 seconds!");
	}
}

// Event_TankOnFire
//  Triggers when a player gets hurt. Upon checks if the client was the tank client
//  if the tank is in play and have fire immunity.
//  If so check damage type (8 = fire), put out the fire and added the lost health to the current health
public Event_TankOnFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bTankHasFireImmunity || !g_bTankIsInPlay){return;}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_iTankClient != client){return;}
	
	new dmgtype = GetEventInt(event,"type");
	
	if(dmgtype == 8)
	{
		ExtinguishEntity(client);
		new CurHealth = GetClientHealth(client);
		new DmgDone	  = GetEventInt(event,"dmg_health");
		SetEntityHealth(client,(CurHealth + DmgDone));
	}
}

// AITimer
//  Check if the client is still connected and is a bot.
//  If so unfreeze and start fire immunity timer.
public Action:AITimer(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsFakeClient(client))
	{
		SetTankStatus(client, false);
		g_bTankIsInPlay = true;
		CreateTimer(GetConVarFloat(g_hGhostTank_FireimmuneTime),FireImmunityTimer,0);
	}
}

// FireImmunityTimer
//  Once fired just set fire immunity to false.
public Action:FireImmunityTimer(Handle:timer, any:junk){g_bTankHasFireImmunity = false;}

// SetTankStatus
//  Sets wether the tank is frozen or not
SetTankStatus(client, bool:IsFrozen)
{
	new any:movetype = MOVETYPE_CUSTOM;
	new Float:throwrange = g_fTankRockThrowRangeReset;
	new bool:ghoststate = false;
	new bool:ghostenabled = GetConVarBool(g_hGhostTank_EnableGhosting);
	
	if(IsFrozen){movetype = MOVETYPE_NONE;throwrange = UNLIKELY_THROW_RANGE;if(ghostenabled){ghoststate = true;}}
	
	SetEntityMoveType(client, movetype);
	SetConVarFloat(g_hTankRockThrowRangeConVar,throwrange,true,false);
	SetEntData(client, g_iGhostStateOffset, ghoststate, 1, true);
}

// ResetVars
//  Simple reset variables wrapper
ResetVars(){g_iTankClient = -1;g_bTankIsInPlay = 0;if(GetConVarBool(g_hGhostTank_Fireimmune)){g_bTankHasFireImmunity = 1;}}

// IsVersus
//  Returns wether gamemode is set to versus or not
bool:IsVersus()
{
	new String:GameMode[16];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (StrContains(GameMode, "versus", false) != -1){return true;}
	return false;
}