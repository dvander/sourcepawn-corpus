#pragma semicolon 1
#include <sourcemod>
#include <left4downtown>
#define SUPRESS_TIME 2.0

new Float:fMaxSpawn;
new Float:fMinSpawn;
new Float:fDelayMinSpawn;

new bool:bLeftStartedZone;
new bool:bGhostTime[MAXPLAYERS+1];
new iSpawnCooldown[MAXPLAYERS+1];

new bool:bAlreadyDead[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name   = "L4D InstaRespawn VSFix",
	author = "JNC [rahzeL]",
	description = "Fix: When there are some survivors that didn't leave the saferoom and infecteds get instant respawn",
	version = "0.1",
	url     = " "
};

public OnPluginStart()
{
	HookEvent("round_start",Event_RoundStart);
	HookEvent("player_left_start_area", Event_LeftCheckPoint);
	HookEvent("ghost_spawn_time", Event_GhostSpawnTime);
	HookEvent("player_death",ePlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_LeftCheckPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	bLeftStartedZone = true;
	return Plugin_Continue;
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	
	iSpawnCooldown[client] = 0;
	
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bLeftStartedZone = false;
	
	for (new i = 1; i <=MaxClients; i++){
		bGhostTime[i] = false;
		iSpawnCooldown[i] = 0;
		bAlreadyDead[i] = false;
	}
	
	return Plugin_Continue;
}


public OnMapStart()
{
	bLeftStartedZone= false;
	fMaxSpawn = GetConVarFloat(FindConVar("z_ghost_delay_max"));
	fMinSpawn = GetConVarFloat(FindConVar("z_ghost_delay_min"));
	fDelayMinSpawn = GetConVarFloat(FindConVar("z_ghost_delay_minspawn"));
}
 
public L4D_OnEnterGhostState(client)
{ 
	if (bLeftStartedZone && !bGhostTime[client] && bAlreadyDead[client]){
		
		new Float:fRanSpwn;
		if (GetInfectedPlayers() > 3)
		{
			fRanSpwn = GetRandomFloat(fMinSpawn,fMaxSpawn) - SUPRESS_TIME;
		} else {
			fRanSpwn = (fDelayMinSpawn + SUPRESS_TIME) * GetInfectedPlayers();
			if (fRanSpwn > fMinSpawn)
				fRanSpwn = fMinSpawn - SUPRESS_TIME;
		}

		iSpawnCooldown[client] = RoundToCeil(fRanSpwn);
		CreateTimer(1.0, hTimerDelayCoolDown, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

GetInfectedPlayers()
{
	new players = 0;
	for(new i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		if (IsFakeClient(i))
			continue;
		if(GetClientTeam(i) != 3 )
			continue;
		
		players++;
	}
	
	return players;
}

public Action:hTimerDelayCoolDown(Handle:timer, any:client){
	
	if (!bLeftStartedZone) return Plugin_Stop;
	
	if (iSpawnCooldown[client] > 0) iSpawnCooldown[client]--;
	
	if (IsClientInGame(client))
		if (GetClientTeam(client) == 3 && IsPlayerGhosting(client) && iSpawnCooldown[client] > 0) 
			PrintCenterText(client , "Tendrás permitido aparecer en %i segundos.\nYou will be allowed to spawn in %i sec.", iSpawnCooldown[client], iSpawnCooldown[client]);
	
	
	if (iSpawnCooldown[client] < 1){
		if (IsClientInGame(client))
			if (GetClientTeam(client) == 3 && IsPlayerGhosting(client) && iSpawnCooldown[client] > 0) 
			PrintCenterText(client , " ");
		
		iSpawnCooldown[client] = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}


public Action:ePlayerDeath(Handle:event, const String:sEventName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	iSpawnCooldown[client] = 0;
	
	if (bLeftStartedZone)
		bAlreadyDead[client] = true;
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client)) 		return Plugin_Continue;
	if (IsFakeClient(client))			return Plugin_Continue;
	if (GetClientTeam(client) != 3)		return Plugin_Continue;
	
	if (iSpawnCooldown[client] != 0 && IsPlayerGhosting(client) && bLeftStartedZone){
		//SetEntProp(client, Prop_Send, "m_ghostSpawnState", 1);	//1: Disabled, 2: Waiting for survivors to leave  
		if (buttons & 1)
		{
			buttons = buttons & -2;
		}
	}

	return Plugin_Continue;	
}

public Action:Event_GhostSpawnTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	if (IsFakeClient(client))	return Plugin_Continue;

	bGhostTime[client] = true;

	return Plugin_Continue;
}

bool:IsValidClient(client)
{
	if (client < 1 || client > MaxClients)
	{
		return false;
	}
	return IsClientInGame(client);
}

bool:IsPlayerGhosting(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost") > 0;
} 