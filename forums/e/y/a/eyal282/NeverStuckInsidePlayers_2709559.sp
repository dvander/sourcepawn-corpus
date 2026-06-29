#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <collisionhook>

new const String:PLUGIN_VERSION[] = "1.0";

new bool:StuckInsideEachother[MAXPLAYERS+1][MAXPLAYERS+1];

#define CHECK_DELAY 0.4

public Plugin:myinfo = 
{
	name = "Never get stuck inside players",
	author = "Eyal282",
	description = "Allows you to pass through players if you are stuck inside them.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnMapStart()
{
	CreateTimer(CHECK_DELAY, Timer_CheckStuckPlayers, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:Timer_CheckStuckPlayers(Handle:hTimer)
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		for(new otherClient=1;otherClient <= MaxClients;otherClient++)
		{
			if(!IsClientInGame(otherClient))
				continue;
				
			StuckInsideEachother[i][otherClient] = false;
				
			
			if(IsPlayerAlive(i) && IsPlayerAlive(otherClient) && ArePlayersStuckInsideEachother(i, otherClient))
				StuckInsideEachother[i][otherClient] = true;
		}
	}
}

public Action:CH_PassFilter(ent1, ent2, &bool:result)
{
	if(!IsPlayer(ent1) || !IsPlayer(ent2))
		return Plugin_Continue;
	
	if(StuckInsideEachother[ent1][ent2] || StuckInsideEachother[ent2][ent1])
	{
		result = false;
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}


stock bool:IsPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return true;
}


stock bool ArePlayersStuckInsideEachother(int client, int otherClient)
{
	float vecMin[3], vecMax[3], vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayHitSecondPlayer, otherClient);
	
	return TR_DidHit();
}


public bool TraceRayHitSecondPlayer(int entityhit, int mask, otherClient) 
{
    return entityhit == otherClient;
}