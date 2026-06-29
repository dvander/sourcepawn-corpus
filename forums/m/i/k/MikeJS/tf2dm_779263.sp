#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PL_VERSION "1.0"
new Handle:g_hKvSpawns = INVALID_HANDLE;
new Handle:g_hKvWeaponData = INVALID_HANDLE;
new bool:g_bRegen[MAXPLAYERS+1];
new Handle:g_hRegenTimer[MAXPLAYERS+1];
new Handle:g_hRegenEnable = INVALID_HANDLE;
new bool:g_bRegenEnable;
new Handle:g_hRegenHP = INVALID_HANDLE;
new g_iRegenHP;
new Handle:g_hRegenTick = INVALID_HANDLE;
new Float:g_fRegenTick;
new Handle:g_hRegenDelay = INVALID_HANDLE;
new Float:g_fRegenDelay;
new Handle:g_hSpawn = INVALID_HANDLE;
new Float:g_fSpawn;
new Handle:g_hSpawnRandom = INVALID_HANDLE;
new bool:g_bSpawnRandom;
new bool:g_bSpawnMap;
new g_iSpawnCount;
new Float:g_vecSpawnOrigin[32][3];
new Float:g_vecSpawnAngles[32][3];
new Handle:g_hClass = INVALID_HANDLE;
new g_iClass;
public Plugin:myinfo =
{
	name = "TF2 Deathmatch",
	author = "MikeJS",
	description = "I wonder",
	version = PL_VERSION,
	url = "http://mikejs.byethost18.com/"
};
public OnPluginStart() {
	CreateConVar("tf2dm", PL_VERSION, "TF2 Deathmatch version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hRegenEnable = CreateConVar("tf2dm_regen", "1", "Enable health regeneration.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hRegenHP = CreateConVar("tf2dm_regenhp", "1", "Health added per regeneration tick.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hRegenTick = CreateConVar("tf2dm_regentick", "0.1", "Delay between regeration ticks.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hRegenDelay = CreateConVar("tf2dm_regendelay", "4.0", "Seconds after damage before regeneration.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpawn = CreateConVar("tf2dm_spawn", "1.5", "Spawn timer.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSpawnRandom = CreateConVar("tf2dm_spawnrandom", "1", "Enable random spawns.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hClass = CreateConVar("tf2dm_class", "0", "Force everyone to be a certain class.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(g_hRegenEnable, Cvar_regenenable);
	HookConVarChange(g_hRegenHP, Cvar_regenhp);
	HookConVarChange(g_hRegenTick, Cvar_regentick);
	HookConVarChange(g_hRegenDelay, Cvar_regendelay);
	HookConVarChange(g_hSpawn, Cvar_spawn);
	HookConVarChange(g_hSpawnRandom, Cvar_spawnrandom);
	HookConVarChange(g_hClass, Cvar_class);
	HookEvent("player_death", Event_player_death);
	HookEvent("player_hurt", Event_player_hurt);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("teamplay_round_start", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
	g_hKvWeaponData = CreateKeyValues("Spawns");
	new String:path[128];
	BuildPath(Path_SM, path, sizeof(path), "data/tf2dm.txt");
	FileToKeyValues(g_hKvWeaponData, path);
}
public OnMapStart() {
	g_bSpawnMap = false;
	if(g_hKvSpawns!=INVALID_HANDLE) {
		CloseHandle(g_hKvSpawns);
	}
	g_hKvSpawns = CreateKeyValues("Spawns");
	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "configs/tf2dm.cfg");
	if(FileExists(path)) {
		FileToKeyValues(g_hKvSpawns, path);
		decl String:map[64];
		GetCurrentMap(map, sizeof(map));
		if(KvJumpToKey(g_hKvSpawns, map)) {
			KvGotoFirstSubKey(g_hKvSpawns);
			decl String:kvOrigin[24], String:arOrigin[3][8], String:kvAngles[24], String:arAngles[3][8];
			g_iSpawnCount = 0;
			do {
				KvGetString(g_hKvSpawns, "origin",  kvOrigin,  sizeof(kvOrigin));
				ExplodeString(kvOrigin, ",", arOrigin, 3, 8);
				KvGetString(g_hKvSpawns, "angles", kvAngles, sizeof(kvAngles));
				ExplodeString(kvAngles, ",", arAngles, 3, 8);
				g_vecSpawnOrigin[g_iSpawnCount][0] = StringToFloat(arOrigin[0]);
				g_vecSpawnOrigin[g_iSpawnCount][1] = StringToFloat(arOrigin[1]);
				g_vecSpawnOrigin[g_iSpawnCount][2] = StringToFloat(arOrigin[2]);
				g_vecSpawnAngles[g_iSpawnCount][0] = StringToFloat(arAngles[0]);
				g_vecSpawnAngles[g_iSpawnCount][1] = StringToFloat(arAngles[1]);
				g_vecSpawnAngles[g_iSpawnCount++][2] = StringToFloat(arAngles[2]);
			} while(KvGotoNextKey(g_hKvSpawns));
			if(g_iSpawnCount!=0) {
				g_bSpawnMap = true;
			}
		}
	} else {
		LogError("File Not Found: %s", path);
	}
}
public OnConfigsExecuted() {
	g_bRegenEnable = GetConVarBool(g_hRegenEnable);
	g_iRegenHP = GetConVarInt(g_hRegenHP);
	g_fRegenTick = GetConVarFloat(g_hRegenTick);
	g_fRegenDelay = GetConVarFloat(g_hRegenDelay);
	g_fSpawn = GetConVarFloat(g_hSpawn);
	g_bSpawnRandom = GetConVarBool(g_hSpawnRandom);
	g_iClass = GetConVarInt(g_hClass);
}
public Cvar_regenenable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bRegenEnable = GetConVarBool(g_hRegenEnable);
}
public Cvar_regenhp(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iRegenHP = GetConVarInt(g_hRegenHP);
}
public Cvar_regentick(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fRegenTick = GetConVarFloat(g_hRegenTick);
}
public Cvar_regendelay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fRegenDelay = GetConVarFloat(g_hRegenDelay);
}
public Cvar_spawn(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fSpawn = GetConVarFloat(g_hSpawn);
}
public Cvar_spawnrandom(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bSpawnRandom = GetConVarBool(g_hSpawnRandom);
}
public Cvar_class(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iClass = GetConVarInt(g_hClass);
}
public Action:RandomSpawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		new rand = GetRandomInt(0, g_iSpawnCount-1);
		TeleportEntity(client, g_vecSpawnOrigin[rand], g_vecSpawnAngles[rand], NULL_VECTOR);
	}
}
public Action:StartRegen(Handle:timer, any:client) {
	g_bRegen[client] = true;
	Regen(INVALID_HANDLE, client);
}
public Action:Regen(Handle:timer, any:client) {
	if(g_bRegen[client] && IsClientInGame(client) && IsPlayerAlive(client)) {
		new health = GetClientHealth(client)+g_iRegenHP;
		if(health>GetMaxHealth(_:TF2_GetPlayerClass(client))) {
			health = GetMaxHealth(_:TF2_GetPlayerClass(client));
		}
		SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
		SetEntProp(client, Prop_Data, "m_iHealth", health, 1);
		g_hRegenTimer[client] = CreateTimer(g_fRegenTick, Regen, client);
	}
}
public Action:Respawn(Handle:timer, any:client) {
	if(IsClientInGame(client) && IsClientOnTeam(client)) {
		TF2_RespawnPlayer(client);
	}
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(g_fSpawn, Respawn, GetClientOfUserId(GetEventInt(event, "userid")));
}
public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_bRegenEnable) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(client!=attacker && attacker!=0) {
			g_bRegen[client] = false;
			if(g_hRegenTimer[client]!=INVALID_HANDLE) {
				CloseHandle(g_hRegenTimer[client]);
			}
			g_hRegenTimer[client] = CreateTimer(g_fRegenDelay, StartRegen, client);
		}
	}
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_hRegenTimer[client] = CreateTimer(0.01, StartRegen, client);
	if(g_bSpawnRandom && g_bSpawnMap) {
		CreateTimer(0.01, RandomSpawn, client);
	}
	if(g_iClass>0 && _:TF2_GetPlayerClass(client)!=g_iClass) {
		TF2_SetPlayerClass(client, TFClassType:g_iClass);
	}
}
public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	new ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_regenerate"))!=-1) {
		AcceptEntityInput(ent, "Disable");
	}
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "item_medkit_small"))!=-1) {
		AcceptEntityInput(ent, "Disable");
	}
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "item_medkit_medium"))!=-1) {
		AcceptEntityInput(ent, "Disable");
	}
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "item_medkit_large"))!=-1) {
		AcceptEntityInput(ent, "Disable");
	}
	for(new i=0;i<=MaxClients;i++) {
		if(g_hRegenTimer[i]!=INVALID_HANDLE) {
			CloseHandle(g_hRegenTimer[i]);
		}
	}
}
GetMaxHealth(i) {
	switch(i) {
		case 1: return 125;
		case 2: return 125;
		case 3: return 200;
		case 4: return 175;
		case 5: return 150;
		case 6: return 300;
		case 7: return 175;
		case 8: return 125;
		case 9: return 125;
	}
	return -1;
}
IsClientOnTeam(client) {
	new team = GetClientTeam(client);
	switch(team) {
		case 2: return true;
		case 3: return true;
	}
	return false;
}