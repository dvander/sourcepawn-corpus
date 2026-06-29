#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>
#include <smlib>

#define PLUGIN_VERSION "2.3.0"

new SpawnedZombie = 0;
new bool:SpawnOn = false;
new Handle:ChangeVariable[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:PodschetTimer = INVALID_HANDLE;
new Handle:ScaningSpawnTimer = INVALID_HANDLE;

new H;
new Z;

new Handle:c_cvar_Countzombiespawn = INVALID_HANDLE;
new g_cvar_Countzombiespawn;
new Handle: c_cvar_FreqCheckTime = INVALID_HANDLE;
new Float:g_cvar_FreqCheckTime;

new Handle: t_IncludingSpawnList[MAXPLAYERS + 1]    = {INVALID_HANDLE, ...};

new g_playerClass[MAXPLAYERS + 1];
new bool:JoinPlayer[MAXPLAYERS + 1] = true;


public Plugin:myinfo = {
	name = "SZSpawn",
	author = "The Running Man",
	description = "System respawns of zombies in a zombie (SystemZombieSpawn)",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart() {

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	c_cvar_FreqCheckTime = CreateConVar("szs_freqrespawn_time", "4.0", "The frequency of scan dead players and time respawn of the zombie, the range between 1.0 and CvarValue,Default = 4.0, Min: 2.0", 0, true, 2.0);
	g_cvar_FreqCheckTime = GetConVarFloat(c_cvar_FreqCheckTime);
	c_cvar_Countzombiespawn = CreateConVar("szs_balancezombie", "0.0", "How many zombies (Human vs Zombie + X), Default = 0 (Human = Zombie), -1 = Disabled spawn zombie, -2 = Always spawn zombie", 0, true, -2.0);
	g_cvar_Countzombiespawn = GetConVarInt(c_cvar_Countzombiespawn);
	CreateConVar("szs_version", PLUGIN_VERSION, "Version SZSpawn", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	AddCommandListener(Event_JoinClass, "jointeam");

	HookConVarChange(c_cvar_Countzombiespawn, OnConVarChanged);
	HookConVarChange(c_cvar_FreqCheckTime, OnConVarChanged);
	
	AutoExecConfig(true, "zombiereloaded/SZSpawn");
	LoadTranslations("SZSpawn.phrases");
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new IntNewValue = StringToInt(newValue);
	if (convar == c_cvar_FreqCheckTime)	{
		g_cvar_FreqCheckTime = StringToFloat(newValue);
		if(g_cvar_FreqCheckTime < 2.0)
			g_cvar_FreqCheckTime = 2.0;
		return;
	}else{
		if (convar == c_cvar_Countzombiespawn){
			if(IntNewValue == -1)
				Client_PrintToChatAll(true,"%t", "DisabledSpawn");
			else
				if (IntNewValue == 0)
					Client_PrintToChatAll(true,"%t", "EqualitySpawn");
					else
						if(IntNewValue > 0)
							Client_PrintToChatAll(true,"%t", "CountSpawn", IntNewValue);
							else
								if(IntNewValue == -2)
									Client_PrintToChatAll(true,"%t", "AlwaysResp", IntNewValue);
			if(IntNewValue < -2)
				IntNewValue = -2;
			g_cvar_Countzombiespawn = IntNewValue;
		}
	}
}

public OnClientPostAdminCheck(client){
	if (client && IsClientInGame(client) && !IsFakeClient(client))
		ChangeVariable[client] =CreateTimer(1.0, change, client);
}

public Action:change(Handle:timer, any:client){
	JoinPlayer[client] = true;
	ChangeVariable[client] = INVALID_HANDLE;
}

public Action:Event_JoinClass(client, const String:command[], argc){
   t_IncludingSpawnList[client] = CreateTimer(2.0, ExecRespawn, client);
   g_playerClass[client] = 1;
}

public Action:ExecRespawn(Handle:timer, any:client){
    if ( client && IsClientInGame(client) && (GetClientTeam(client) > 1) && (!IsPlayerAlive(client)) && g_playerClass[client] && JoinPlayer[client] && ((0 < Z <= (H-1+g_cvar_Countzombiespawn)) || g_cvar_Countzombiespawn == -2))    {
		PrintCenterText(client, "%t", "WaitResp");
		JoinPlayer[client] = false;
    }    
    t_IncludingSpawnList[client] = INVALID_HANDLE;
    return Plugin_Stop;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(PodschetTimer == INVALID_HANDLE)
	PodschetTimer = CreateTimer(0.1, Podschet, _, TIMER_REPEAT);

	if(ScaningSpawnTimer == INVALID_HANDLE)
	ScaningSpawnTimer = CreateTimer(g_cvar_FreqCheckTime, Respawn, _, TIMER_REPEAT);

	SpawnOn = true;
	SpawnedZombie = 0;
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client;
	Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(Client) && IsPlayerAlive(Client) && ZR_IsClientHuman(Client))
		JoinPlayer[Client] = false;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn) {
	SpawnedZombie++;
}

public Action:Podschet(Handle:timer)
{
	H = 0;
	Z = 0;
	for(new Client = 1; Client <= MaxClients; Client++)  
    {	
		if (IsClientInGame(Client) && IsPlayerAlive(Client)){
			if (ZR_IsClientHuman(Client))
				H++;
			else
				if (ZR_IsClientZombie(Client))
					Z++;
		}
	}
	if(SpawnOn == false){
		if (PodschetTimer != INVALID_HANDLE) {
			CloseHandle(PodschetTimer);
			PodschetTimer = INVALID_HANDLE;
		}
	}
}

public Action:Respawn(Handle:timer)
{
	if(SpawnOn == false){
		if (ScaningSpawnTimer != INVALID_HANDLE) {
			CloseHandle(ScaningSpawnTimer);
			ScaningSpawnTimer = INVALID_HANDLE;
		}
	}
	if(SpawnOn && SpawnedZombie > 0 && (0 < Z <= (H-1+g_cvar_Countzombiespawn) && g_cvar_Countzombiespawn > -1) || g_cvar_Countzombiespawn == -2){
		new random_client = Client_GetRandom(CLIENTFILTER_DEAD);
		new hTarget, Float:hOgigin[3];
		if(random_client > 0 && IsClientInGame(random_client) && !IsPlayerAlive(random_client) && GetClientTeam(random_client) > 1){
			hTarget = GetEntPropEnt(random_client, Prop_Send, "m_hObserverTarget");
			if (hTarget < 0 || random_client == hTarget || GetClientTeam(hTarget) == 3 || !IsPlayerAlive(hTarget))
				hTarget = GetRandomTarget();
				
			if (hTarget >= 0){
				GetClientAbsOrigin(hTarget, hOgigin);
				hOgigin[2] = hOgigin[2] + 15.0;
				ZR_RespawnClient(random_client, ZR_Respawn_Zombie);
				TeleportEntity(random_client, hOgigin, NULL_VECTOR, NULL_VECTOR);
			} else{
				LogError("ERROR: Could not select spawn target.");
			}
		}
	}
}

GetRandomTarget(){
	new PlayerList[MaxClients];
	new PlayerCount;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && (CheckIfPlayerIsStuck (i) == false))
			PlayerList[PlayerCount++] = i;
	}
	if (PlayerCount == 0)
		return -1;
	return PlayerList[GetRandomInt(0, PlayerCount-1)];
}

stock bool:CheckIfPlayerIsStuck(iClient){
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	GetClientMins(iClient, vecMin);
	GetClientMaxs(iClient, vecMax);
	GetClientAbsOrigin(iClient, vecOrigin);
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid, iClient);
	return TR_DidHit();
}

public bool:TraceEntityFilterSolid(entity, contentsMask, any:client){
	return (entity != client && Client_IsValid(entity, false));
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	SpawnOn = false;
	if (PodschetTimer != INVALID_HANDLE) {
		CloseHandle(PodschetTimer);
		PodschetTimer = INVALID_HANDLE;
	}
	if (ScaningSpawnTimer != INVALID_HANDLE) {
		CloseHandle(ScaningSpawnTimer);
		ScaningSpawnTimer = INVALID_HANDLE;
	}
	return Plugin_Continue;
}
