#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"

public Plugin:myinfo = {
	name        = "TF2 Fast Respawn",
	author      = "Tsunami",
	description = "Fast Respawn for TF2.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iGameRules;
new Handle:g_hEnabled;
new Handle:g_hBlu;
new Handle:g_hRed;

public OnPluginStart() {
	CreateConVar("sm_fastrespawn_version", PL_VERSION, "Fast Respawn for TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled   = CreateConVar("sm_fastrespawn_enabled", "1",    "Enable/disable fast respawn for TF2.");
	g_hBlu       = CreateConVar("sm_fastrespawn_blu",     "10.0", "Respawn time for Blu team in TF2.");
	g_hRed       = CreateConVar("sm_fastrespawn_red",     "10.0", "Respawn time for Red team in TF2.");
	
	HookConVarChange(g_hEnabled,                                ConVarChange_SetRespawnTime);
	HookConVarChange(g_hBlu,                                    ConVarChange_SetRespawnTime);
	HookConVarChange(g_hRed,                                    ConVarChange_SetRespawnTime);
	
	HookEntityOutput("logic_auto",           "OnMapSpawn",      EntityOutput_SetRespawnTime);
	HookEntityOutput("logic_auto",           "OnMultiNewMap",   EntityOutput_SetRespawnTime);
	HookEntityOutput("logic_auto",           "OnMultiNewRound", EntityOutput_SetRespawnTime);
	HookEntityOutput("team_round_timer",     "On4MinRemain",    EntityOutput_SetRespawnTime);
	HookEntityOutput("team_round_timer",     "On3MinRemain",    EntityOutput_SetRespawnTime);
	HookEntityOutput("team_round_timer",     "On2MinRemain",    EntityOutput_SetRespawnTime);
	HookEntityOutput("team_round_timer",     "OnRoundStart",    EntityOutput_SetRespawnTime);
	HookEntityOutput("trigger_capture_area", "OnEndCap",        EntityOutput_SetRespawnTime);
}

public OnMapStart() {
	g_iGameRules = FindEntityByClassname(-1, "tf_gamerules");
	
	SetRespawnTime();
}

public ConVarChange_SetRespawnTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	SetRespawnTime();
}

public EntityOutput_SetRespawnTime(const String:output[], caller, activator, Float:delay) {
	SetRespawnTime();
}

public SetRespawnTime() {
	if (GetConVarBool(g_hEnabled) && g_iGameRules != -1) {
		SetVariantFloat(GetConVarFloat(g_hBlu));
		AcceptEntityInput(g_iGameRules, "SetBlueTeamRespawnWaveTime");
		
		SetVariantFloat(GetConVarFloat(g_hRed));
		AcceptEntityInput(g_iGameRules, "SetRedTeamRespawnWaveTime");
	}
}