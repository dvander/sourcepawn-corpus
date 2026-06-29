/*
* Ghost Tank Lite
* 
* About:
* ===========================
* By now you have probably already heard or tried my Ghost Tank plugin for 
*  L4D. Simple stuff that I believed the tank need as the AI is really 
*  shitty.
* 
* But as time went on I began to play more and more with friends, and 
*  stopped pubbing all together. This is when I realized my Ghost Tank was
*  a bit... well bloated with stuff I didn't need for my friends matches.
* 
* So Ghost Tank Lite was born as a offspring of my Ghost Tank plugin.
* It’s pretty simple. The tank is frozen and ghosted until player takes 
*  control.
* Rock throw is disabled for the AI, incapacitated fix by DrThunder 
*  included, and of course features fire immunity for a short while.
* 
* Neither fire speed nor multi tank support. This is intended for L4D2, 
*  should work on L4D, but I claim the right to NOT provide support 
*  encase it doesn't.
* 
* Plugin Description:
* ===========================
* Upon tank spawn, the tank will be frozen and ghosted until a player 
*  takes over.
* 
* Changelog:
* ===========================
* Legend: 
*  + Added 
*  - Removed 
*  ~ Fixed or changed
* 
* Version 0.91a
* -----------------
* ~ Fixed entity validation
* 
* Version 0.91
* -----------------
* + Better tank death detection, for some reason the tank_killed event
*    doesn't get fired (especially in finales) replaced with player_death.
* + Added option for use the old selection time for the tank (4 seconds in
*    L4D2, 3 seconds in L4D).
* - Removed ghost cvar. Tanks will now be ghosted by default.
* ~ Set the default fire immune time to 3 seconds.
* 
* Version 0.90a
* -----------------
* ~ Accidentally removed a part of the code that prevented AI tanks 
*    throwing rocks, fixed.
* ~ Small changes in code and random fix ups
* 
* Version 0.90
* -----------------
* Initial release
* 
* - Mr. Zero
*/

// ***********************************************************************
// PREPROCESSOR
// ***********************************************************************
#pragma semicolon 1

// ========================================================
// Includes
// ========================================================
#include <sourcemod>
#include <sdktools>

// ***********************************************************************
// CONSTANTS
// ***********************************************************************
#define PLUGIN_VERSION 		"0.91a"
#define THROWRANGE			99999999.0

// ========================================================
// Plugin Info
// ========================================================
public Plugin:myinfo = 
{
	name = "Ghost Tank Lite",
	author = "Mr. Zero",
	description = "Upon tank spawn, the tank will be frozen and ghosted until a player takes over.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=111997"
};

// ***********************************************************************
// VARIABLES
// ***********************************************************************

// ========================================================
// General variables
// ========================================================
new bool:g_bPluginIsEnabled;
// Which client is the tank
new g_iTankClient;
// Boolean for prevention of pause the same tank twice
new bool:g_bTankIsInPlay;
// Boolean for whether the tank have fire immunity or not
new bool:g_bTankHasFireImmunity;

// ========================================================
// Convar handles
// ========================================================
// The plugin enable cvar
new Handle:g_hEnable;
// Fire immunity cvar
new Handle:g_hFireImmune;
// Fix punch convar
new Handle:g_hFixPunch;
// Incap health for survivors, need for fix punch
new Handle:g_hFixPunch_IncapHealth;
// Handle for a existing cvar, at what range the AI tank will throw rocks
new Handle:g_hRockThrowRange;
// Handle for a existing cvar, director selection time
new Handle:g_hSelectionTime;
// Use old selection time handle
new Handle:g_hOldSelectionTime;

// ***********************************************************************
// FUNCTIONS
// ***********************************************************************

// ////////////////////////////////////////////////////////
// Public functions
// ////////////////////////////////////////////////////////

public OnPluginStart()
{
	// ----------------------------------------------------
	// Convars
	// ----------------------------------------------------
	g_hEnable 				= CreateConVar("l4d2_gtl_enable"		, "1"	, "Sets whether the plugin is active or not.", FCVAR_PLUGIN);
	g_hFireImmune			= CreateConVar("l4d2_gtl_fireimmune"	, "3.0"	, "The amount of time the tank is fire immune (secs), after player takes control. 0 for disable fire immunity.", FCVAR_PLUGIN);
	g_hFixPunch				= CreateConVar("l4d2_gtl_fixpunch"		, "1"	, "Normally tanks would incap survivors on the spot. This fixes it and makes the Survivors still take a punch and fall back with force, before incapping them. All credits for this fix, goes to DrThunder on AlliedModders.",FCVAR_PLUGIN);
	g_hOldSelectionTime		= CreateConVar("l4d2_gtl_oldselecttime"	, "1"	, "Sets whether the plugin will make the selection cvar use the old time for selecting the tank (4 sec in L4D2, 3 sec in L4D).", FCVAR_PLUGIN);
	g_hFixPunch_IncapHealth	= FindConVar("survivor_incap_health");
	g_hRockThrowRange		= FindConVar("tank_throw_allow_range");
	g_hSelectionTime		= FindConVar("director_tank_lottery_selection_time");
	
	CreateConVar("l4d2_gtl_version", PLUGIN_VERSION, "Ghost Tank Lite Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "GhostTankLite");
	
	// ----------------------------------------------------
	// Hooking of events and convars
	// ----------------------------------------------------
	HookConVarChange(g_hEnable,ConVarChange_Enable);
	HookConVarChange(g_hOldSelectionTime,ConVarChange_SelectionTime);
	
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death",Event_TankKilled);
	HookEvent("player_hurt",Event_TankOnFire);
	HookEvent("round_start",Event_RoundStart);
	HookEvent("player_incapacitated", Event_PlayerIncap);
}

public OnConfigsExecuted()
{
	SetSelectionTime(true);
}

public ConVarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CheckDependencies();
}

public ConVarChange_SelectionTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetSelectionTime();
}

public OnMapStart()
{
	CheckDependencies();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Reset();
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bTankIsInPlay){return;}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != g_iTankClient){return;}
	Reset();
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;
	
	if(g_bTankIsInPlay){return;}
	
	g_bTankIsInPlay = true;
	
	if(!g_bPluginIsEnabled){return;}
	
	new Float:fFireImmunityTime = GetConVarFloat(g_hFireImmune);
	new Float:fSelectionTime = GetConVarFloat(g_hSelectionTime);
	
	if(IsFakeClient(client))
	{
		PauseTank();
		CreateTimer(fSelectionTime,ResumeTankTimer);
		fFireImmunityTime += fSelectionTime;
	}
	
	CreateTimer(fFireImmunityTime,FireImmunityTimer);
}

public Event_TankOnFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bTankIsInPlay || !g_bTankHasFireImmunity || !g_bPluginIsEnabled){return;}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_iTankClient != client){return;}
	
	new dmgtype = GetEventInt(event,"type");
	
	if(dmgtype != 8){return;}
	
	ExtinguishEntity(client);
	new CurHealth = GetClientHealth(client);
	new DmgDone	  = GetEventInt(event,"dmg_health");
	SetEntityHealth(client,(CurHealth + DmgDone));
}

public Event_PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!g_bTankIsInPlay || !g_bPluginIsEnabled || !GetConVarBool(g_hFixPunch)){return;}
	
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, 16);
	
	if(!StrEqual(weapon, "tank_claw")){return;}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	SetEntityHealth(client, 1);
	CreateTimer(0.4, IncapTimer, client);
}

public Action:IncapTimer(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	SetEntityHealth(client, GetConVarInt(g_hFixPunch_IncapHealth));
}

public Action:ResumeTankTimer(Handle:timer)
{
	ResumeTank();
}

public Action:FireImmunityTimer(Handle:timer)
{
	g_bTankHasFireImmunity = false;
}

// ////////////////////////////////////////////////////////
// Private functions
// ////////////////////////////////////////////////////////
PauseTank()
{
	SetConVarFloat(g_hRockThrowRange,THROWRANGE);
	if(!IsValidEntity(g_iTankClient)){return;}
	SetEntityMoveType(g_iTankClient,MOVETYPE_NONE);
	SetEntProp(g_iTankClient,Prop_Send,"m_isGhost",1,1);
}

ResumeTank()
{
	ResetConVar(g_hRockThrowRange);
	if(!IsValidEntity(g_iTankClient)){return;}
	SetEntityMoveType(g_iTankClient,MOVETYPE_CUSTOM);
	SetEntProp(g_iTankClient,Prop_Send,"m_isGhost",0,1);
}

Reset()
{
	g_bTankIsInPlay = false;
	g_bTankHasFireImmunity = true;
}

SetSelectionTime(bool:OnConfigExec=false)
{
	if(GetConVarBool(g_hOldSelectionTime))
	{
		SetConVarFloat(g_hSelectionTime,3.0);
	}
	else if(!OnConfigExec)
	{
		ResetConVar(g_hSelectionTime);
	}
}

CheckDependencies()
{
	g_bPluginIsEnabled = false;
	
	decl String:GameMode[10];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	if(StrContains(GameMode, "versus", false) == -1 || !GetConVarBool(g_hEnable)){return;}
	
	g_bPluginIsEnabled = true;
}