/*
Some maps (like ctf_battle_creek_s) do not have a func_respawnroom brush, so this plugin will not be active on them.
If a map has too many func_respawnrooms, the plugin will not be active.
Beware of maps that have large func_respawnrooms, they might cause gameplay imbalances.
func_respawnroom brushes are located in spawn and prevent building, so that should give an idea of where it is if you need to know.
Another way of checking is to decompile the map, but requires a little knowledge of Hammer.
See https://developer.valvesoftware.com/wiki/Decompiling_Maps for more info.
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#define VERSION "1.2"

#define X 0
#define Y 1
#define Z 2

new bool:LATELOAD = false;
new bool:FAILED = false;

new Handle:ghEnabled = INVALID_HANDLE;
new Handle:ghDamage = INVALID_HANDLE;
new Handle:ghRevisit = INVALID_HANDLE;
new Handle:ghNotify = INVALID_HANDLE;
new Handle:ghTeams = INVALID_HANDLE;
new Handle:ghTimer = INVALID_HANDLE;
new Handle:ghTimerLength = INVALID_HANDLE;
new bool:gEnabled = true;
new bool:gRevisit = false;
new bool:gNotify = true;
new bool:gTeams = true;
new bool:gTimer = false;
new Float:gTimerLength = 1.0;
new bool:gTimerActive[MAXPLAYERS+1] = false;

#define damageOn 2
new damageOff = 1;

#define gMaxSpawns 12
new gNumSpawns = 0;
new Float:spawnRooms[gMaxSpawns][3][2];
new spawnRoomsTeams[gMaxSpawns] = 0;

new bool:protectedList[MAXPLAYERS+1] = false;
new bool:revisitList[MAXPLAYERS+1] = false;

public Plugin:myinfo = {
	name = "Spawn Protection",
	author = "Giloh",
	description = "[SP]Players inside func_respawnroom are invincible",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=174293"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	if(late) LATELOAD = true;
	return APLRes_Success;
}

public OnPluginStart(){
	HookConVarChange(ghEnabled = CreateConVar("sp_enabled", "1", "Is the plugin enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghDamage = CreateConVar("sp_knockback", "1", "Are protected players affected by knockback?", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghRevisit = CreateConVar("sp_revisit", "0", "If a player revisits spawn after leaving, are they given protection?", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghNotify = CreateConVar("sp_notify", "1", "Should players be notified when their protection is removed?", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghTeams = CreateConVar("sp_teams", "1", "If 0: players will be given invinciblity in the other teams spawn too?\nMay only be useful if sp_revisit is 1 or if spawned inside a func_respawnroom that overlaps with the other teams func_respawnroom.", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghTimer = CreateConVar("sp_timer", "0", "After the player leaves spawn, should there be a delay before protection is removed?", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarChanged_Control);
	HookConVarChange(ghTimerLength = CreateConVar("sp_timer_length", "1.0", "How long should the delay be?", FCVAR_PLUGIN, true, 0.1, true, 10.0), ConVarChanged_Control);
	HookEvent("player_spawn", Event_Spawn);
	
	RegAdminCmd("sm_listspawns", Command_ListSpawns, ADMFLAG_GENERIC);
	//RegConsoleCmd("sm_test", Command_Test);
	
	new String:CFGPATH[32] = "sourcemod";
	//GetConVarString(FindConVar("sm_cf_path"), CFGPATH, 32); //for multiplay clanforge
	AutoExecConfig(true, "spawnprotect", CFGPATH);
	
	if(LATELOAD) OnMapStart();
}

public OnMapStart(){
	CalcSpawns();
}
/*
public Action:Command_Test(client, args){
	return Plugin_Handled;
}
*/
public Action:Command_ListSpawns(client, args){
	if(client > 0){
		new Float:clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		ReplyToCommand(client, "You are at: %d, %d, %d", RoundFloat(clientPos[0]), RoundFloat(clientPos[1]), RoundFloat(clientPos[2]));
	}
	for(new i = 0; i < gNumSpawns; i++){
		ReplyToCommand(client, "%d Start: %d, %d, %d", i, RoundFloat(spawnRooms[i][X][0]), RoundFloat(spawnRooms[i][Y][0]), RoundFloat(spawnRooms[i][Z][0]));
		ReplyToCommand(client, "%d End: %d, %d, %d", i, RoundFloat(spawnRooms[i][X][1]), RoundFloat(spawnRooms[i][Y][1]), RoundFloat(spawnRooms[i][Z][1]));
	}
	return Plugin_Handled;
}

public OnConfigsExecuted(){
	gEnabled = GetConVarBool(ghEnabled);
	damageOff = GetConVarInt(ghDamage);
	gRevisit = !GetConVarBool(ghRevisit);
	gNotify = GetConVarBool(ghNotify);
	gTeams = GetConVarBool(ghTeams);
	gTimer = GetConVarBool(ghTimer);
	gTimerLength = GetConVarFloat(ghTimerLength);
}

public ConVarChanged_Control(Handle:convar, const String:oldValue[], const String:newValue[]){
	OnConfigsExecuted();
	if(convar == ghEnabled) CalcSpawns();
}

CalcSpawns(){
	FAILED = false;
	for(new spawn = 0; spawn < gMaxSpawns; spawn++){
		spawnRoomsTeams[spawn] = 0;
		for(new xyz = 0; xyz < 3; xyz++){
			for(new i = 0; i < 2; i++){
				spawnRooms[spawn][xyz][i] = 0.0;
			}
		}
	}
	
	gNumSpawns = 0;
	new spawnEnt = FindEntityByClassname(-1, "func_respawnroom");
	new Float:minVec[3], Float:maxVec[3];
	while(spawnEnt != -1 && gNumSpawns < gMaxSpawns){
		spawnRoomsTeams[gNumSpawns] = GetEntProp(spawnEnt, Prop_Send, "m_iTeamNum");
		GetEntPropVector(spawnEnt, Prop_Send, "m_vecMins", minVec);
		GetEntPropVector(spawnEnt, Prop_Send, "m_vecMaxs", maxVec);
		for(new xyz = 0; xyz < 3; xyz++){
			spawnRooms[gNumSpawns][xyz][0] = minVec[xyz];
			spawnRooms[gNumSpawns][xyz][1] = maxVec[xyz];
		}
		
		gNumSpawns++;
		spawnEnt = FindEntityByClassname(spawnEnt, "func_respawnroom");
	}
	
	if(gNumSpawns == 0){
		new String:mapName[255];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("func_respawnroom could not be found on %s", mapName);
		FAILED = true;
	}
	if(gNumSpawns > gMaxSpawns){
		new String:mapName[255];
		GetCurrentMap(mapName, sizeof(mapName));
		LogError("Too many func_respawnrooms on %s", mapName);
		FAILED = true;
	}
	
	return true;
}

bool:IsClientInSpawn(client){
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	
	for(new i = 0; i < gNumSpawns; i++){
		if(spawnRooms[i][X][0] == spawnRooms[i][X][1]) continue;
		if(clientPos[X] >= spawnRooms[i][X][0] && clientPos[X] <= spawnRooms[i][X][1] && \
		   clientPos[Y] >= spawnRooms[i][Y][0] && clientPos[Y] <= spawnRooms[i][Y][1] && \
		   clientPos[Z] >= spawnRooms[i][Z][0] && clientPos[Z] <= spawnRooms[i][Z][1]){
			if(gTeams){
				if(GetClientTeam(client) != spawnRoomsTeams[i]){
					return false;
				}
			}
			return true;
		}
	}
	return false;
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntProp(client, Prop_Data, "m_takedamage", damageOn, 1);
	revisitList[client] = false;
	protectedList[client] = false;
	return Plugin_Continue;
}

public OnGameFrame(){
	if(gEnabled && !FAILED){
		for(new client = 1; client <= MaxClients; client++){
			if(IsClientInGame(client) && IsPlayerAlive(client)){
				if(IsClientInSpawn(client)){
					if(!protectedList[client] && !revisitList[client]){
						protectedList[client] = true;
						SetEntProp(client, Prop_Data, "m_takedamage", damageOff, 1);
					}
				} else {
					if(protectedList[client]){
						if(gTimer){
							if(!gTimerActive[client]){
								CreateTimer(gTimerLength, Timer_ProtectionEnd, client);
								gTimerActive[client] = true;
							}
						} else RemoveProtection(client);
					}
				}
			}
		}
	}
}

public Action:Timer_ProtectionEnd(Handle:timer, any:client){
	gTimerActive[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client)){
		RemoveProtection(client);
	}

	return Plugin_Continue;
}

RemoveProtection(client){
	if(gNotify) PrintToChat(client, "\x03[SP] \x01Spawn protection disabled");
	protectedList[client] = false;
	if(gRevisit) revisitList[client] = true;
	SetEntProp(client, Prop_Data, "m_takedamage", damageOn, 1);
}

public OnClientPutInServer(client){
	SetEntProp(client, Prop_Data, "m_takedamage", damageOn, 1);
	revisitList[client] = false;
	protectedList[client] = false;
	gTimerActive[client] = false;
}

public OnPluginEnd(){
	for(new client = 1; client <= MaxClients; client++){
		if(IsClientInGame(client)){
			SetEntProp(client, Prop_Data, "m_takedamage", damageOn, 1);
		}
	}
}