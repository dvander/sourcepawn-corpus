#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.14"

public Plugin:myinfo = {
	name = "TF2 FF on during waiting for players",
	author = "Ratty",
	description = "TF2 FF during waiting for players",
	version = PLUGIN_VERSION,
	url = "http://nom-nom-nom.us"
}

new bool:mp_friendlyfire = false;
new bool:Instaspawn = false;
new Handle:hCvarShowDeathSpam;
new Handle:hCvarBots;

public OnPluginStart() {
	CreateConVar("sm_pregamemayhem_ver", PLUGIN_VERSION, "Pregame Mayhem Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hCvarShowDeathSpam = CreateConVar("sm_pregamemayhem_deathspam", "1", "Pregame Mayhem - Show deaths", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarBots = CreateConVar("sm_pregamemayhem_botrespawn", "1", "Pregame Mayhem - Instantly respawn bots", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart() {
	Instaspawn = false;
	FindArena(true);
}

public OnMapEnd() {
	Instaspawn = false;
	if (!mp_friendlyfire) {
		SetConVarBool(FindConVar("mp_friendlyfire"), false);
	}
}

public OnConfigsExecuted() {
	mp_friendlyfire = GetConVarBool(FindConVar("mp_friendlyfire"));
}

public Action:Timer_Mayhem(Handle:timer) {
	if (Instaspawn) PrintToChatAll("[SM] Pregame mayhem is active. Friendlyfire and instaspawn active.");
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		CreateTimer(0.1, Timer_Respawn, GetEventInt(event, "userid"));
	}

	if (!GetConVarBool(hCvarShowDeathSpam)) {
		dontBroadcast = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (Instaspawn && client > 0 && client <= MaxClients && IsClientInGame(client) && (!IsFakeClient(client) || GetConVarBool(hCvarBots))) {
		TF2_RespawnPlayer(client);
	}
}

public TF2_OnWaitingForPlayersStart() {
	if (FindArena()) return;
	Instaspawn = true;
	CreateTimer(10.0, Timer_Mayhem);
//	CreateTimer(20.0, Timer_Mayhem);
	if (!mp_friendlyfire) {
		SetConVarBool(FindConVar("mp_friendlyfire"), true);
	}
}

public TF2_OnWaitingForPlayersEnd() {
	OnMapEnd();
	if (!FindArena()) PrintToChatAll("[SM] Game starting. Friendlyfire off.");
}

public OnPluginEnd() {
	OnMapEnd();
}

stock bool:FindArena(bool:forceRecalc = false)
{
	static bool:arena = false;
	static bool:found = false;
	if (forceRecalc)
	{
		found = false;
		arena = false;
	}
	if (!found)
	{
		new i = -1;
		while ((i = FindEntityByClassname2(i, "tf_logic_arena")) != -1)
		{
			arena = true;
		}
		found = true;
	}
	return arena;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}