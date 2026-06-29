#include <sourcemod>
#pragma semicolon 1
new Handle:g_time, Float:timertime;
public OnPluginStart() {
	g_time = CreateConVar("sm_godspawn_time", "5", "Number of seconds to give god mode after spawn");
	timertime = GetConVarFloat(g_time);
	HookConVarChange(g_time, Changed);
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) <= 1) { return; }	
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	CreateTimer(timertime, Timer_NoGod, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_NoGod(Handle:timer, any:serial) {
	new client = GetClientFromSerial(serial);	
	if (client == 0) { return Plugin_Continue; }	
	if (IsPlayerAlive(client)) { SetEntProp(client, Prop_Data, "m_takedamage", 2); }	
	return Plugin_Continue;
}
public Changed(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	timertime = GetConVarFloat(cvar);
}