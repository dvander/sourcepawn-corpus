/*	=============================================
*	- NAME:
*	  + Critpoints
*
*	- AUTHOR:
*	  + Joel Gibson
*
*	- DESCRIPTION:
*	  + Allows players to grant themselves critical hits or critboosts
*	  + based on their in-game points.
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sm_critpoints_enabled <1|0>
*	 + Enables/Disables the plugin
*	
*	- sm_critpoints_multiplier <Default: 1.0>
*	 + Multiplier for critboost time based on crit points
*
*	- sm_critpoints_max <Default: 10>
*	 + The maximum number of stored critpoints a player is allowed (0 = unlimited)
*
*	- sm_critpoints_default <Default: 10.0>
*	 + The default time to use if no second argument is fed to sm_grant_critboost
* 	
*	-------------
*	Admin commands:
*	-------------
*	- sm_grant_critboost <#userid|name> <time>
*	 + Grants a critboost at target for a specified amount of seconds.
*
*	-------------
*	Client commands:
*	-------------
*	- sm_use_critpoints
*	 + Triggers the client's crit time, their critponts multiplied by sm_critpoints_multiplier
* 	
*	----------
*	Changelog:
*	----------
*	Version 0.1.3 (23/10/2009)
*	-- Swapped TF2_Addcond and TF2_RemoveCond for alternate functions
*	   which modify the flags of sv_cheats, rather than just turning
*	   sv_cheats on and off.
*	-- Fixed the HUD so now it shows info for before the critboost, and
*	   while a player is critboosting it shows a countdown.
*
*	Version 0.1.2 (19/10/2009)
*	-- Changed admin command 'sm_send_crits' to 'sm_grant_critboost'
*	-- Changed client command 'sm_use_crits' to 'sm_use_critpoints'
*	-- Added critboost effect by using TF2_AddCond and TF2_RemoveCond
*	   by MikeJS - http://forums.alliedmods.net/showthread.php?t=98542
*	-- Because of the above critboost effect, TF2_CalcIsAttackCritical
*	   is no longer needed.
*
*	Version 0.1.1 (18/10/2009)
*	-- Fixed targeting error in sm_send_crits
*	-- Added HUD showing critpoints and time
*
*	Version 0.1 (18/10/2009)
*	-- Initial Alpha
*
*	----------
*	Todo:
*	----------
*	+ Allow a successful taunt-kill to max out critpoints.
* 	
*/


//Includes
#include <sourcemod>
#include <tf2>
#include <sdktools>

#define PLUGIN_VERSION "0.1.3"
#define HUD_UPDATE_INTERVAL 0.5 //In seconds

//Array in which to store critpoints, init to 0
new CritPoints[MAXPLAYERS+1] = {0, ...};

//Array to tell if a client is currently critting
new bool:IsCritting[MAXPLAYERS+1] = {false, ...};

//Array to store time when user started critting
new Float:StartCritTime[MAXPLAYERS+1] = {0.0, ...};

//Now for some cvars
new Handle:sm_critpoints_enabled = INVALID_HANDLE;		//Plugin enabled
new Handle:sm_critpoints_multiplier = INVALID_HANDLE;	//Multiply critpoints by this for critboost time
new Handle:sm_critpoints_default = INVALID_HANDLE;		//Default time for sm_grant_critboost

public Plugin:myinfo = {
	name = "Critpoints",
	author = "Joel Gibson",
	description = "Grant user-triggered critical hits and critboosts.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=106709"
};

public OnPluginStart() {
	LoadTranslations("common.phrases");
	//Register the console commands
	RegConsoleCmd("sm_use_critpoints", Command_Use_Crits, "Uses stored crit time", 0);
	RegAdminCmd("sm_boost", Command_Send_Crits, ADMFLAG_SLAY);
	
	//Create the cvars
	sm_critpoints_enabled = CreateConVar("sm_critpoints_enabled", "1", "Critpoints plugin enabled"); //Yet to be implemented
	sm_critpoints_multiplier = CreateConVar("sm_critpoints_multiplier", "1.0", "Critpoints time multiplier");
	sm_critpoints_default = CreateConVar("sm_critpoints_default", "10.0", "Default time if no time argument supplied to sm_grant_critboost");
	
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	//New client just joined, he has no crits!
	CritPoints[client] = 0;
	IsCritting[client] = false;
	
	
	return true;
}

/****************************************
 AddCond - Taken from http://forums.alliedmods.net/showthread.php?t=98542
 ****************************************/

stock TF2_AddCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED));
		
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "addcond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}
stock TF2_RemoveCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED));
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}  
/****************************************
 Console command handlers
 ****************************************/

//Handler for (client) console command "sm_use_critpoints"
//Triggers the crits for x seconds
public Action:Command_Use_Crits(client, args) {
	if (!GetConVarBool(sm_critpoints_enabled)) return Plugin_Handled;
	new critpoints = CritPoints[client];
	new Float:timefactor = GetConVarFloat(sm_critpoints_multiplier);
	//Reset the client's crit points
	CritPoints[client] = 0;
	//Crit the client now
	CritForTime(client, timefactor * critpoints);
	return Plugin_Handled;
}

//Handler for Admin console command "send_crits"
//Triggers crits on target for x time
public Action:Command_Send_Crits(client, args)
{
	if (args < 1) {
		ReplyToCommand(client, "Usage: sm_grant_critboost <#userid|name> <time in seconds>");
		return Plugin_Handled;
	}
	
	if (!GetConVarBool(sm_critpoints_enabled)) return Plugin_Handled;
	new String:targetString[65], String:timeString[65];
	new Float:CritTime;
	
	//Retrieve first (target) argument
	GetCmdArg(1, targetString, sizeof(targetString));
	
	//Retrieve second (time) argument
	if (args >= 2 && GetCmdArg(2, timeString, sizeof(timeString))) {
		CritTime = StringToFloat(timeString);
	} else {
		//Use the value stored in sm_critpoints_default
		CritTime = GetConVarFloat(sm_critpoints_default);
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			targetString,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++) {
		CritForTime(target_list[i], CritTime);
	}
	
	if (tn_is_ml) {
		
	} else {
		
	}
	
	return Plugin_Handled;
}

/****************************************
 Handling Crits - Functions
 ****************************************/

//Crits client for time
public CritForTime(any:client, Float:time) {
	if (time) { //If time is non-zero
		IsCritting[client] = true;
		StartCritTime[client] = GetTickedTime() + time;
		CreateTimer(time, EndCritting, client);
		TF2_AddCond(client, 11);	//Add the krits effect
	}
}

//Ends critting on a client - called by CritForTime
public Action:EndCritting(Handle:timer, any:client) {
	IsCritting[client] = true;
	TF2_RemoveCond(client, 11);
}
/* This is not needed while using TF2_AddCond
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) {
	if (IsCritting[client] && GetConVarBool(sm_critpoints_enabled)) {
		result = true;
		return Plugin_Handled;
	}	
	return Plugin_Continue;
}*/