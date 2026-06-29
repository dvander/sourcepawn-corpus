/*
 * Trigger Commands
 * Author: Chase (chase@sybolt.com)
 * Date: October 23, 2009
 * 
 * Licensed under the GPL v2 or above.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dukehacks> 

#define PLUGIN_VERSION "1.0"

#define MAX_TRIGGERS 128
#define MAX_LENGTH 256

// *********************************************************************************
// Globals
// *********************************************************************************

/*	Trigger info storage */
new g_iTriggerCount;
new String:g_sTriggerId[MAX_TRIGGERS][MAX_LENGTH];
new String:g_sTriggerCommand[MAX_TRIGGERS][MAX_LENGTH];
new Float:g_fTriggerMultiplier[MAX_TRIGGERS];

// *********************************************************************************
// ConVars
// *********************************************************************************

//Toggle debug logging
new Handle:g_cvDebug = INVALID_HANDLE;

//The command to be issued on impact
new Handle:g_cvEnabled = INVALID_HANDLE;

//Store friendly fire status
new Handle:g_cvFriendlyFire = INVALID_HANDLE;

//Can multiple sections handle the same attack
//ex: obj_sentrygun running both obj_sentrygun trigger AND the trigger linked to the engies current weapon
//	or having the "player" inflictor trigger handle everything that isn't already predefined
new Handle:g_cvAllowMultipleMatches = INVALID_HANDLE;

// *********************************************************************************
// Main routines
// *********************************************************************************

public Plugin:myinfo =
{
	name = "Trigger Commands",
	author = "Chase",
	description = "Activates commands associated to various weapons",
	version = PLUGIN_VERSION,
	url = "http://www.sybolt.com"
};

public OnPluginStart()
{
	RegisterCVars();
	RegisterCommands();
	RegisterEvents();
	
	TC_ParseConfig();
	
	LogMessage("Trigger Commands Plugin Loaded");
}

RegisterCVars()
{
	g_cvEnabled = CreateConVar("tcmd_enabled", "1", "Toggle plugin. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvDebug = CreateConVar("tcmd_debug", "0", "Toggle debug logging. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvAllowMultipleMatches = CreateConVar("tcmd_allowmulti", "0", "Allow multiple triggers to activate at once. 1=On, 0=Off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	g_cvFriendlyFire = FindConVar("mp_friendlyfire");
	
	CreateConVar("tcmd_version", PLUGIN_VERSION, "Trigger Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "tcmd");
}

RegisterCommands()
{
	RegAdminCmd("tcmd_reload", TC_CommandReloadConfig, ADMFLAG_GENERIC, "Reload plugin configuration");
}

RegisterEvents()
{
	dhAddClientHook(CHK_TakeDamage, TC_PrehookTakeDamage);
}

/*	Read properties for each trigger */
TC_ParseConfig()
{
	new Handle:kvCommandList = CreateKeyValues("TriggerCommands");
	new String:sLocation[256];

	BuildPath(Path_SM, sLocation, 256, "configs/TriggerCommands.cfg");
	FileToKeyValues(kvCommandList, sLocation);
    
    //If it's an invalid file, tell 'em
	if (!KvGotoFirstSubKey(kvCommandList)) 
	{ 
		LogMessage("Failed to read: %s", sLocation); 
		return;
	}
	
	g_iTriggerCount = 0;
	new bool:printDebug = GetConVarBool(g_cvDebug);
	
	do
	{
		KvGetSectionName(kvCommandList, g_sTriggerId[g_iTriggerCount], MAX_LENGTH);
		KvGetString(kvCommandList, "command", g_sTriggerCommand[g_iTriggerCount], MAX_LENGTH);
		g_fTriggerMultiplier[g_iTriggerCount] = KvGetFloat(kvCommandList, "multiplier", 1.0);

		if (printDebug)
		{
			LogMessage("Loaded Trigger [%s] Command [%s] Multiplier [%.1f]", 
						g_sTriggerId[g_iTriggerCount], g_sTriggerCommand[g_iTriggerCount], g_fTriggerMultiplier[g_iTriggerCount]);
		}
		
		g_iTriggerCount++;
	}
	while (KvGotoNextKey(kvCommandList));

	CloseHandle(kvCommandList);
	
	LogMessage("Config loaded %i trigger(s)", g_iTriggerCount);
}

/*	Run the specified command on the target entity */
TC_Activate(target, index)
{
	if (strlen(g_sTriggerCommand[index]) < 1)
		return;

	//Get the command to modify 
	decl String:command[MAX_LENGTH];
	strcopy(command, sizeof(command), g_sTriggerCommand[index]);

	//Get the targets id
	decl String:id[32];
	Format(id, sizeof(id), "\"%N\"", target);
	
	//replace {target} with the targets id
	ReplaceString(command, sizeof(command), "{target}", id, false);
	
	if (GetConVarBool(g_cvDebug))
		LogMessage("Command Issued [%s]", command);

	//issue command
	ServerCommand("%s", command);
}

// *********************************************************************************
// Event hooks
// *********************************************************************************

/*	Reload commands/triggers from configuration file */
public Action:TC_CommandReloadConfig(client, args)
{
	TC_ParseConfig();
}

/*	Search through triggers for the appropriate inflictor. If found, run the associated command and apply the damage multiplier */
public Action:TC_PrehookTakeDamage(victim, attacker, inflictor, Float:dmg, &Float:dmgMultiplier, dmgType) //done
{
	if (!GetConVarBool(g_cvEnabled) || !IsValidClient(attacker) || !IsValidClient(victim))
		return Plugin_Continue;

	if (GetConVarBool(g_cvDebug))
		LogMessage("[TC_PrehookTakeDamage] Victim: %N for dmg: %.1f", victim, dmg);

	/*	If they're on different teams, or friendly fire is enabled, search for triggers */
	if (GetClientTeam(attacker) != GetClientTeam(victim) 
		|| (g_cvFriendlyFire != INVALID_HANDLE && GetConVarInt(g_cvFriendlyFire) == 1))
	{
		/*	Get the inflictor */
		decl String:classname[32];
		GetEdictClassname(inflictor, classname, sizeof(classname));

		/*	Get the weapon used */
		decl String:weapon[32];
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		if (GetConVarBool(g_cvDebug))
			LogMessage("Inflictor Classname [%s] Weapon [%s]", classname, weapon);

		//Search triggers for  a classname match OR a weapon match, if we find one, do it. 
		for (new i = 0; i < g_iTriggerCount; i++)
		{
			//for matching triggers, run command and apply multiplier
			if (StrEqual(classname, g_sTriggerId[i], false) || StrEqual(weapon, g_sTriggerId[i], false))
			{
				if (GetConVarBool(g_cvDebug))
					LogMessage("Activating on [%s] Multi [%0.1f]", g_sTriggerId[i], g_fTriggerMultiplier[i]);
					
				TC_Activate(victim, i);
				dmgMultiplier *= g_fTriggerMultiplier[i];
				
				//If we're only allowed one match, break out
				if (!GetConVarBool(g_cvAllowMultipleMatches))
					break;
			}
		}
	}
	
	return Plugin_Changed;
}

// *********************************************************************************
// Other generic functions
// *********************************************************************************

stock bool:IsValidClient(client)
{
    if (client < 0) return false;
    if (client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    return IsClientInGame(client);
}

