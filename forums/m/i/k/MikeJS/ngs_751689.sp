#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PL_VERSION "1.1"
new Handle:g_hEnabled = INVALID_HANDLE;
new g_bEnabled = true;
new gamerules;
public Plugin:myinfo =
{
	name = "No Goal String",
	author = "Mike",
	description = "Remove the useless window that stays for half the match.",
	version = PL_VERSION,
	url = "http://mikejs.byethost18.com/"
};
public OnPluginStart() {
	CreateConVar("sm_nogoalstring", PL_VERSION, "No Goal String version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_ngs_enabled", "1", "Enable/disable No Goal String.", FCVAR_PLUGIN);
	HookEvent("arena_round_start", Event_round_start);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
	HookConVarChange(g_hEnabled, Cvar_enabled);
}
public OnMapStart() {
	gamerules = FindEntityByClassname(-1, "tf_gamerules");
	if(gamerules==-1) {
		gamerules = CreateEntityByName("tf_gamerules");
	}
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bEnabled) {
		SetVariantString("");
		AcceptEntityInput(gamerules, "SetBlueTeamGoalString");
		AcceptEntityInput(gamerules, "SetRedTeamGoalString");
	}
}