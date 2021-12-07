#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Move Type",
	author = "[GFL] Roy",
	description = "Sets the move type of players...",
	version = "1.0",
	url = "GFLClan.com"
};

// ConVars
new Handle:g_movetype = INVALID_HANDLE
new Handle:g_maxspeed = INVALID_HANDLE;
new Handle:g_settype = INVALID_HANDLE;

// ConVar values
new i_MoveType;
new Float:f_MaxSpeed;
new i_SetType;

public OnPluginStart() {
	// ConVars
	g_movetype = CreateConVar("sm_player_movetype", "1", "Move type of the players applied on spawn. (CS:GO default is 2)");
	g_maxspeed = CreateConVar("sm_player_maxspeed", "5000.00", "Maximum speed of the player applied on spawn. (CS:GO default is 260.00)");
	g_settype = CreateConVar("sm_player_movetype_type", "2", "1 = use SetEntProp() 2 = SetEntityMoveType (and more)");
	
	// Hook ConVar Changes
	HookConVarChange(g_movetype, MoveTypeChanged);
	HookConVarChange(g_maxspeed, MaxSpeedChanged);
	HookConVarChange(g_settype, SetTypeChanged);
	
	// Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	// Get the values!
	i_MoveType = GetConVarInt(g_movetype);
	f_MaxSpeed = GetConVarFloat(g_maxspeed);
	
	// Auto Execute Config
	AutoExecConfig(true, "sm_MoveType");
}

// On Configs Executed
public OnConfigsExecuted() {
	// Get the values!
	i_MoveType = GetConVarInt(g_movetype);
	f_MaxSpeed = GetConVarFloat(g_maxspeed);
	i_SetType = GetConVarInt(g_settype);
}

// Hook ConVar Changes (callbacks)
public MoveTypeChanged(Handle:convar, const String:oldv[], const String:newv[]) {
	i_MoveType = StringToInt(newv);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			// Apply the Move Type!
			ApplyMoveType(i);
		}
	}
}

public MaxSpeedChanged(Handle:convar, const String:oldv[], const String:newv[]) {
	f_MaxSpeed = StringToFloat(newv);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			// Apply the Maximum Speed!
			ApplyMaxSpeed(i);
		}
	}
}

public SetTypeChanged(Handle:convar, const String:oldv[], const String:newv[]) {
	i_SetType = StringToInt(newv);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			// Apply the Maximum Speed!
			ApplyMoveType(i);
		}
	}
}

// Events
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Request the next frame!
	RequestFrame(SetStuff, client);
}

public SetStuff(any:client) {
	ApplyMoveType(client);
	ApplyMaxSpeed(client);
}

// Functions (Stocks?)
stock ApplyMoveType(client) {
	if (IsClientInGame(client)) {
		if (i_SetType == 1) {
			// Type 1
			SetEntProp(client, Prop_Send, "movetype", i_MoveType);
		} else if (i_SetType == 2) {
			// Type 2
			switch (i_MoveType) {
				case 0:
					SetEntityMoveType(client, MOVETYPE_NONE);
					
				case 1:
					SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
				
				case 2:
					// Default
					SetEntityMoveType(client, MOVETYPE_WALK);
					
				case 3:
					SetEntityMoveType(client, MOVETYPE_STEP);
				
				case 4:
					SetEntityMoveType(client, MOVETYPE_FLY);
					
				case 5:
					SetEntityMoveType(client, MOVETYPE_FLYGRAVITY);
					
				case 6:
					SetEntityMoveType(client, MOVETYPE_VPHYSICS);
				
				case 7:
					SetEntityMoveType(client, MOVETYPE_PUSH);
					
				case 8:
					SetEntityMoveType(client, MOVETYPE_NOCLIP);
					
				case 9:
					SetEntityMoveType(client, MOVETYPE_LADDER);
					
				case 10:
					SetEntityMoveType(client, MOVETYPE_OBSERVER);
					
				case 11:
					SetEntityMoveType(client, MOVETYPE_CUSTOM);
				
				default:
					SetEntityMoveType(client, MOVETYPE_WALK);
			}
			
			// Now set some flags!
			
		}
	}
}

stock ApplyMaxSpeed(client) {
	if (IsClientInGame(client)) {
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", f_MaxSpeed);
	}
}