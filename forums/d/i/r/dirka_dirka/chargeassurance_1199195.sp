#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.2"

/*
	Version 1.2:
		Fixed MAXPLAYERS to MAXPLAYERS+1
		Added plugin version & cvar: charge_assurance_ver
		Renamed the only cvar the plugin originally had to sm_charge_boosthealth
		Added a check for Left 4 Dead 2... fail otherwise.
		Added check for if a client disconnects mid-charge.. remove the boost.
		Added check for invalid charger client.
		Added a min to the health boost.. also that min is effectively a way to disable this: 0 = off.
		Added a hook to the boost cvar so it can be changed on the fly (and turned on/off).
		Changed the health restore function.. Will now set health to 1 if the charger would have otherwise died without the boost.
		Cleaned up the code a bit.
		Unified the name of the plugin internally - author calls it something like 4 or 5 different things throughout the code and on his plugin post.
*/

new	bool:	g_bIsCharging[MAXPLAYERS+1]	=	{ false, ... };
new	Handle:	g_hConVarHealth				=	INVALID_HANDLE;
new			g_iConVarHealth;

public Plugin:myinfo = {
	name = "Charge Assurance",
	author = "Joshua Coffey & Dirka_Dirka",
	description = "Let chargers have a higher chance of survival during charges.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122544"
}

public OnPluginStart() {
	decl String:game_name[12];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
		
	CreateConVar(
		"charge_assurance_ver",
		PLUGIN_VERSION,
		"Version of the L4D2 Charger Assurance plugin.",
		FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD
	);
	
	g_hConVarHealth = CreateConVar(
		"sm_charge_boosthealth",
		"300",
		"The amount of health to give to a charger during a charge (and then take away afterwards).",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0
	);
	HookConVarChange(g_hConVarHealth, ConVarChange_Health);
	g_iConVarHealth = GetConVarInt(g_hConVarHealth);
	
	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);
}

public ConVarChange_Health(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iConVarHealth = GetConVarInt(g_hConVarHealth);
}

public OnClientPutInServer(client) {
    g_bIsCharging[client] = false;
}

public OnClientDisconnect(client) {
	if (g_bIsCharging[client]) {
		RemoveProtection(client);
	}
}

public Event_ChargeStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_iConVarHealth) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!charger) return;
	
	new healthboost = g_iConVarHealth + GetClientHealth(charger);
	
	if (!g_bIsCharging[charger]) {
		SetEntityHealth(charger, healthboost);
		g_bIsCharging[charger] = true;
	}
}

public Event_ChargeEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_iConVarHealth) return;
	
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!charger) return;
	
	RemoveProtection(charger);
}

stock RemoveProtection(client) {
	g_bIsCharging[client] = false;
	
	new damagehealth = GetClientHealth(client) - g_iConVarHealth;
	if (damagehealth < 1)
		damagehealth = 1;
	SetEntityHealth(client, damagehealth);
}
