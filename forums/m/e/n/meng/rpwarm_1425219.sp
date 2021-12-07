#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define NAME "RPWARM"
#define VERSION "0.1.7"

static const String:g_sPistolsSon[6][] = {
	"weapon_glock",
	"weapon_usp",
	"weapon_deagle",
	"weapon_fiveseven",
	"weapon_elite",
	"weapon_p228"
};

new bool:g_bWarming;
new g_iSecondHandSmoke;
new g_iWPOff;
new Handle:g_hWarmingTimer;
new Handle:g_CVarSeconds;

public OnPluginStart() {

	CreateConVar("sm_rpwarm", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarSeconds = CreateConVar("sm_rpwarm_seconds", "60", "Time in seconds the warmup lasts.", _, true, 15.0, true, 120.0);
	g_iWPOff = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	AddCommandListener(CmdJoinClass, "joinclass");
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
}

public OnConfigsExecuted() {

	if (g_hWarmingTimer != INVALID_HANDLE)
		KillTimer(g_hWarmingTimer);
	new maxent = GetMaxEntities(), String:ent[64];
	for (new i = MaxClients; i < maxent; i++) {
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, ent, sizeof(ent))) {
			if (StrContains(ent, "func_bomb_target") != -1 ||
			StrContains(ent, "func_hostage_rescue") != -1 ||
			StrContains(ent, "func_buyzone") != -1)
				AcceptEntityInput(i,"Disable");
		}
	}
	g_iSecondHandSmoke = GetConVarInt(g_CVarSeconds);
	g_bWarming = true;
	ServerCommand("exec prewarmup.cfg");
	g_hWarmingTimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
}

public Action:CancelWarmup() {

	g_bWarming = false;
	g_hWarmingTimer = INVALID_HANDLE;
	new maxent = GetMaxEntities(), String:ent[64];
	for (new i = MaxClients; i < maxent; i++)
		if (IsValidEdict(i) &&
		IsValidEntity(i) && 
		GetEdictClassname(i, ent, sizeof(ent)) &&
		((StrContains(ent, "func_bomb_target") != -1 ||
		StrContains(ent, "func_hostage_rescue") != -1 ||
		StrContains(ent, "func_buyzone") != -1)))
			AcceptEntityInput(i, "Enable");
	ServerCommand("exec postwarmup.cfg");
	ServerCommand("mp_restartgame 1");
}  

public Action:Countdown(Handle:timer) {

	if (g_iSecondHandSmoke > 0) {
		PrintHintTextToAll("Warmup: %i", g_iSecondHandSmoke);
		g_iSecondHandSmoke--;
	}
	else {
		g_iSecondHandSmoke = GetConVarInt(g_CVarSeconds);
		CancelWarmup();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bWarming) {
		new maxent = GetMaxEntities(), String:ent[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, ent, sizeof(ent)))
				if (StrContains(ent, "weapon_") != -1 && GetEntDataEnt2(i, g_iWPOff) == -1)
					RemoveEdict(i);
	}
}

public Action:SpawnLateJoiningPlayer(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
		CS_RespawnPlayer(client);
}

public Action:RespawnPlayer(Handle:timer, any:client) {

	if (IsClientInGame(client))
		CS_RespawnPlayer(client);
}

public Action:CmdJoinClass(client, const String:command[], argc) {

	if (g_bWarming)
		CreateTimer(2.0, SpawnLateJoiningPlayer, client);
}

public EventPlayerSpawn(Handle:event, const String:name[],bool:dontBroadcast) {

	if (g_bWarming) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(client) > 1) {
			new index;
			for (new i = 0; i < 4; i++) { /* first round..., nobody has projectiles n sh*t */
				if ((i != 2) && (index = GetPlayerWeaponSlot(client, i)) != -1) {  
					RemovePlayerItem(client, index);
					RemoveEdict(index);
				}
			}
			GivePlayerItem(client, g_sPistolsSon[GetURandomIntRange(0, sizeof(g_sPistolsSon) - 1)]);
			GivePlayerItem(client, "item_assaultsuit");
		}
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bWarming) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(1.0, RespawnPlayer, client);
	}
}

stock GetURandomIntRange(min, max) {

	return (GetURandomInt() % (max-min+1)) + min;
}