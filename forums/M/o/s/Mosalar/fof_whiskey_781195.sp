/*
* A simple "medic" plugin for Fistful of Frags
* Credits go to Tsunami for his original DoD medic 
* which is the base for this plugn.
* 
* Changelog:
* 
* Ver 1.0 Initial release.
* Ver 1.1 Added cfg support/autocreate cfg.
* Ver 1.2 Added event logging for stats (ty psychonic)
*         Changed Plugin name
* 
* To be done: Auto subtract (x)notoriety on use.
* 
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.2"

new g_iCount[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_hAmount;
new Handle:g_hCount;
new Handle:g_hMaximum;

public Plugin:myinfo = {
	name        = "FoF Whiskey",
	author      = "Mosalar",
	description = "Gives players health when they call for whiskey",
	version     = PL_VERSION,
	url         = "http://www.budznetwork.com"
};

public OnPluginStart() {
	CreateConVar("sm_whiskey_version", PL_VERSION, "Gives players health when they call for a medic", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_whiskey_enabled", "1",  "Enable/disable being able to use !whiskey.",           FCVAR_PLUGIN);
	g_hAmount   = CreateConVar("sm_whiskey_amount",  "30", "Amount of health to give when !whiskey is used.",      FCVAR_PLUGIN);
	g_hCount    = CreateConVar("sm_whiskey_count",   "2",  "Amount of times per life to be able to use !whiskey.", FCVAR_PLUGIN);
	g_hMaximum  = CreateConVar("sm_whiskey_maximum", "30", "Maximum health left to be able to use !whiskey.",      FCVAR_PLUGIN);
	
	AutoExecConfig(true, "plugin.whiskey");
	
	HookEvent("player_spawn",    Event_PlayerSpawn);
	RegConsoleCmd("sm_whiskey",    Command_Whiskey);
}

public OnMapStart()
{	
	PrecacheSound("player/voice/whiskey_passwhiskey2.wav", true);
	PrecacheSound("player/whiskey_glug4.wav", true);
}

public Action:Command_Whiskey(client, args) {
	if (GetConVarBool(g_hEnabled)) {
		CreateTimer(0.1, Timer_Whiskey, client);
	}
	
	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	g_iCount[GetClientOfUserId(GetEventInt(event, "userid"))] = 0;
}

public Action:Timer_Whiskey(Handle:timer, any:client) {
	if (IsPlayerAlive(client)) {
		decl Float:fPosition[3];
		GetClientAbsOrigin(client, fPosition);
		new iCount = GetConVarInt(g_hCount), iHealth = GetClientHealth(client);
		if (iHealth <= GetConVarInt(g_hMaximum)) {
			if (g_iCount[client] < iCount) {
				g_iCount[client]++;
				SetEntityHealth(client, iHealth + GetConVarInt(g_hAmount));
				PrintToChat(client, "[SM] You've used %d of %d whiskey rations!", g_iCount[client], iCount);
				EmitAmbientSound("player/voice/whiskey_passwhiskey2.wav", fPosition, client, SNDLEVEL_NORMAL);
				CreateTimer(1.0, Timer_Glug, client);
				LogWhiskey(client);
				
			} else {
				PrintToChat(client, "[SM] You've used all your whiskey rations!");
			}
		} else {
			PrintToChat(client, "[SM] Quit whining pussy, you're fine!");
			EmitAmbientSound("player/voice/whiskey_passwhiskey2.wav", fPosition, client, SNDLEVEL_NORMAL);
		}
	} else {
		PrintToChat(client, "[SM] Ya can't drink when you're dead!");
	}
	
	return Plugin_Handled;
}

public Action:Timer_Glug(Handle:timer, any:client) {
	if (IsPlayerAlive(client)) {
		EmitSoundToClient(client, "player/whiskey_glug4.wav", _, _, _, _, 0.8); 
	}
	
	return Plugin_Handled;
}

LogWhiskey(client) {
	decl String:auth[33];
	decl String:name[65];
	decl String:tname[33];
	
	new userid = GetClientUserId(client);
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, auth, sizeof(auth));
	GetTeamName(GetClientTeam(client), tname, sizeof(tname));
	
	LogToGame("\"%s<%d><%s><%s>\" triggered \"self_whiskey\"", name, userid, auth, tname);
}