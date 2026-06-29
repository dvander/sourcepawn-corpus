/*
* Ghost Tank
* 
* Set up:
* ===========================
* You are ½ way through the map. The other team is doing well. Too well, 
*  in fact, with a 180 health bonus. This ain't good. 
* Your team is a bunch of solo players. But you, you are the single 
*  gifted player on the team. Pro tank, as some would say.
* 
* You keep making sure you have the highest score in case a tank spawns.
* Then, you see it! A tank is approaching! YES! You got it!
* But--oh no! What is the AI doing!? No--don't go that way! No don't walk
*  into the fire! What the hell!?
* 
* You inherit a tank, on fire, with 2 or 3 survivors unloading auto 
* shotguns into you. All because the AI thought it would be a good idea 
*  to rush in.
* 
* Great...
* 
* This plugin will remove this problem.
* 
* Plugin Description:
* ===========================
* When a tank spawns, this plugin will freeze the tank in place to prevent
*  the AI from being retarded. It will also make the tank a ghost in case
*  the survivors get cocky and rush forward to unload some shells into the
*  tank before you even get control.
* 
* Changelog:
* ===========================
* Legend: 
*  + Added 
*  - Removed 
*  ~ Fixed or changed
* 
* Version 0.96
* -----------------
* + Included the "Tank Punch Fix". All credit goes to DrThunder on Allied
*    Modders forums
* ~ Fixed PLUGIN_VERSION in plugin info
* 
* Version 0.95
* -----------------
* + Tank speed while on fire can now be adjusted
* ~ Change all convars from l4d_ghosttank to l4d_gt
* ~ Merged l4d_ghosttank_fireimmune_time and l4d_ghosttank_fireimmune
*    into l4d_gt_fireimmune
* ~ Better handling of tank spawn and tank AI
* ~ Various code change
* 
* Version 0.94a
* -----------------
* ~ Adjusted IsVersus check to OnMapStart instead of RoundStart
* 
* Version 0.94
* -----------------
* + Fire immunity added and cvars. l4d_ghosttank_fireimmune & 
*    l4d_ghosttank_fireimmune_time
* + Game mode check upon round restart
* - Unlimited tank support removed until a more suitable way have been 
*    found around a coding problem
* ~ Various code change
* 
* Version 0.93
* -----------------
* + Now supports unlimited tanks
* + Disabled rock throw for the AI tank while waiting for player to take
*    over
* - Removed freeze cvar. Freeze is now permanent.
* 
* Version 0.92a
* -----------------
* ~ Added is client connected check
* 
* Version 0.92
* -----------------
* + Added idle timer for AI tanks
* 
* Version 0.91
* -----------------
* + Cvars added for disable freezing or ghosting the tank
* ~ Better tank death detection
* ~ Various code change
* 
* Version 0.9
* -----------------
* Initial release
* 
* ~ Mr. Zero
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
#define PLUGIN_VERSION 		"0.96"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY
#define THROWRANGE			99999999.0
#define WARN_MESSAGE_LENGTH	256
#define WARN_MESSAGE_PREFIX	"\x04[INFO]\x01"

// ========================================================
// Plugin Info
// ========================================================
public Plugin:myinfo = 
{
	name = "Ghost Tank",
	author = "Mr. Zero",
	description = "Upon tank spawn, the tank will be frozen and ghosted until a player takes over, plus additonal features such as increased speed while on fire.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=99202"
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
// Boolean for when all regrading fire have been handled
new bool:g_bFireHaveBeenHandled;

// ========================================================
// Convar handles
// ========================================================
// The plugin enable cvar
new Handle:g_hEnable;
// Ghost tank cvar
new Handle:g_hGhost;
// Fire immunity cvar
new Handle:g_hFireImmune;
// The speed factor while tank on fire cvar
new Handle:g_hFireSpeed_Factor;
// The convar for whether players get notified about speed change for the
//  tank while on fire
new Handle:g_hFireSpeed_Notify;
// Convar for fire speed message
new Handle:g_hFireSpeed_Msg;
// Fix punch convar
new Handle:g_hFixPunch;
new Handle:g_hFixPunch_IncapHealth;
// Handle for a existing cvar, at what range the AI tank will throw 
//  rocks
new Handle:g_hRockThrowRange;
// Handle for a existing cvar, director selection time
new Handle:g_hSelectionTime;
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
	g_hEnable 				= CreateConVar("l4d_gt_enable"				, "1"	, "Sets whether the plugin is active or not.", CVAR_FLAGS);
	g_hGhost				= CreateConVar("l4d_gt_ghost"				, "1"	, "Sets whether tanks upon spawn will be set to ghost mode until a player takes over.", CVAR_FLAGS);
	g_hFireImmune			= CreateConVar("l4d_gt_fireimmune"			, "4.0"	, "The amount of time the tank is fire immune (secs), after player takes control. 0 for disable fire immunity.", CVAR_FLAGS);
	g_hFireSpeed_Factor		= CreateConVar("l4d_gt_firespeed_factor"	, "1.0"	, "The speed factor of the tank once hes on fire. 1.0 = 100% speed (fire speed disabled), 0.75 = 75% speed (lost 25% of normal speed), 1.25 = 125% speed (gain 25% of normal speed).", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hFireSpeed_Notify		= CreateConVar("l4d_gt_firespeed_notify"	, "1"	, "Sets whether the plugin will notify players on the server if the tank will gain speed while on fire. 0 = Disable, 1 = Notify in chat. This have no effect if the tank doesn't change speed while on fire.",CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hFireSpeed_Msg		= CreateConVar("l4d_gt_firespeed_msg"		, "On this server, once the tank have been set on fire, the tank will GAIN a speed boost. Choose wisely!", "The message to show for notifying players about fire speed",CVAR_FLAGS);
	g_hFixPunch				= CreateConVar("l4d_gt_fixpunch"			, "0"	, "Normal tanks will incap survivors on the spot. This fixes it and makes the Survivors still take a punch and fall back with force, before incapping them. All credits for this fix, goes to DrThunder on AlliedModders.",CVAR_FLAGS);
	g_hFixPunch_IncapHealth	= FindConVar("survivor_incap_health");
	g_hRockThrowRange		= FindConVar("tank_throw_allow_range");
	g_hSelectionTime		= FindConVar("director_tank_lottery_selection_time");
	
	CreateConVar("l4d_gt_version", PLUGIN_VERSION, "Ghost Tank Version", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "GhostTank");
	
	// ----------------------------------------------------
	// Hooking of events and convars
	// ----------------------------------------------------
	HookConVarChange(g_hEnable,ConVarChange_Enable);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("tank_killed",Event_TankKilled);
	HookEvent("player_hurt",Event_TankOnFire);
	HookEvent("round_start",Event_RoundStart);
	HookEvent("player_incapacitated", Event_PlayerIncap);
}

public OnPluginEnd(){Reset();}

public OnMapStart(){CheckDependencies();}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){Reset();}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast){Reset();}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;
	
	if(g_bTankIsInPlay){return;}
	
	g_bTankIsInPlay = true;
	
	if(!g_bPluginIsEnabled){return;}
	
	WarnFireSpeed();
	
	new Float:fFireImmunityTime = GetConVarFloat(g_hFireImmune);
	new Float:fSelectionTime = GetConVarFloat(g_hSelectionTime);
	
	if(IsFakeClient(client))
	{
		PauseTank();
		CreateTimer(fSelectionTime,ResumeTankTimer);
		fFireImmunityTime += fSelectionTime;
	}
	
	g_bTankIsInPlay = true;
	CreateTimer(fFireImmunityTime,FireImmunityTimer);
}

public Event_TankOnFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bTankIsInPlay || g_bFireHaveBeenHandled || !g_bPluginIsEnabled){return;}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_iTankClient != client){return;}
	
	new dmgtype = GetEventInt(event,"type");
	
	if(dmgtype != 8){return;}
	
	new Float:firespeed = GetConVarFloat(g_hFireSpeed_Factor);
	
	if(g_bTankHasFireImmunity)
	{
		ExtinguishEntity(client);
		new CurHealth = GetClientHealth(client);
		new DmgDone	  = GetEventInt(event,"dmg_health");
		SetEntityHealth(client,(CurHealth + DmgDone));
	}
	else if(firespeed != 1.00)
	{
		SetEntPropFloat(client,Prop_Send,"m_flLaggedMovementValue",firespeed);
		g_bFireHaveBeenHandled = true;
	}
}

public Event_PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hFixPunch)){return;}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	new String:weapon[128];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(!StrEqual(weapon, "tank_claw")){return;}
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	SetEntityHealth(client, 1);
	CreateTimer(0.4, IncapTimer, client);
}

public Action:IncapTimer(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	SetEntityHealth(client, GetConVarInt(g_hFixPunch_IncapHealth));
}

public Action:ResumeTankTimer(Handle:timer){ResumeTank();}

public Action:FireImmunityTimer(Handle:timer){g_bTankHasFireImmunity = false;}

public ConVarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){CheckDependencies();}

// ////////////////////////////////////////////////////////
// Private functions
// ////////////////////////////////////////////////////////
PauseTank()
{
	SetConVarFloat(g_hRockThrowRange,THROWRANGE,true,false);
	SetEntityMoveType(g_iTankClient,MOVETYPE_NONE);
	GhostTank(true);
}

ResumeTank()
{
	ResetConVar(g_hRockThrowRange,true,false);
	SetEntityMoveType(g_iTankClient,MOVETYPE_CUSTOM);
	GhostTank(false);
}

GhostTank(bool:IsGhost)
{
	if(IsGhost && GetConVarBool(g_hGhost))
	{
		SetEntProp(g_iTankClient,Prop_Send,"m_isGhost",1);
	}
	else if(!IsGhost)
	{
		SetEntProp(g_iTankClient,Prop_Send,"m_isGhost",0);
	}
}

WarnFireSpeed()
{
	if(!GetConVarBool(g_hFireSpeed_Notify) || GetConVarFloat(g_hFireSpeed_Factor) == 1.00){return;}
	
	new String:msg[WARN_MESSAGE_LENGTH];
	GetConVarString(g_hFireSpeed_Msg,msg,sizeof(msg));
	
	PrintToChatAll("%s %s",WARN_MESSAGE_PREFIX,msg);
}

Reset()
{
	g_iTankClient = -1;
	g_bTankIsInPlay = false;
	g_bTankHasFireImmunity = true;
	g_bFireHaveBeenHandled = false;
	ResetConVar(g_hRockThrowRange,true,false);
}

CheckDependencies()
{
	new String:GameMode[10];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	
	if(StrContains(GameMode, "versus", false) != -1 && GetConVarBool(g_hEnable))
	{
		g_bPluginIsEnabled = true;
	}
	else
	{
		g_bPluginIsEnabled = false;
	}
}