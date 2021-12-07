#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>

new Handle:g_hCVStrength;

new g_iOutputLimit[MAXPLAYERS+1];
new Handle:g_hVeloTimer[MAXPLAYERS+1];

public OnPluginStart()
{
	g_hCVStrength = CreateConVar("sm_kb_strength", "1000.0");
	HookEvent("player_hurt", Event_OnPlayerHurt);
}


public Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker)
		return;

	new dmg_health = GetEventInt(event, "dmg_health");

	new Float:clientloc[3];
	new Float:attackerloc[3];

	GetClientAbsOrigin(client, clientloc);

	// Get attackers eye position.
	GetClientEyePosition(attacker, attackerloc);

	// Get attackers eye angles.
	new Float:attackerang[3];
	GetClientEyeAngles(attacker, attackerang);

	// Calculate knockback end-vector.
	TR_TraceRayFilter(attackerloc, attackerang, MASK_ALL, RayType_Infinite, KnockbackTRFilter);
	TR_GetEndPosition(clientloc);

	new Float:knockback = GetConVarFloat(g_hCVStrength);
	knockback *= float(dmg_health);

	KnockbackSetVelocity(client, attackerloc, clientloc, knockback);

	//if(g_hVeloTimer[client] == INVALID_HANDLE)
	//	g_hVeloTimer[client] = CreateTimer(0.01, Timer_PrintVelocity, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	//g_iOutputLimit[client] = 10;
}

public Action:Timer_PrintVelocity(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	new Float:fVel[3];
	Entity_GetAbsVelocity(client, fVel);
	
	new Float:fSpeed = GetVectorLength(fVel);
	PrintToServer("%N speed: %f", client, fSpeed);
	
	g_iOutputLimit[client]--;
	
	if(g_iOutputLimit[client] <= 0 || fSpeed <= 0.1)
	{
		g_iOutputLimit[client] = 0;
		g_hVeloTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 * Sets velocity on a player.
 *
 * @param client The client index.
 * @param startpoint The starting coordinate to push from.
 * @param endpoint The ending coordinate to push towards.
 * @param magnitude Magnitude of the push.
 */
KnockbackSetVelocity(client, const Float:startpoint[3], const Float:endpoint[3], Float:magnitude)
{
	// Create vector from the given starting and ending points.
	new Float:vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);

	// Normalize the vector (equal magnitude at varying distances).
	NormalizeVector(vector, vector);

	// Apply the magnitude by scaling the vector (multiplying each of its components).
	ScaleVector(vector, magnitude);

	// ADD the given vector to the client's current velocity.
	new Float:vVel[3];
	Entity_GetBaseVelocity(client, vVel);
	AddVectors(vVel, vector, vVel);
	//PrintToServer("Setting %N speed to %f", client, GetVectorLength(vVel));
	//Entity_SetBaseVelocity(client, vVel);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
}

/**
 * Trace Ray forward, used as a filter to continue tracing if told so. (See sdktools_trace.inc)
 *
 * @param entity The entity index.
 * @param contentsMask The contents mask.
 * @return True to allow hit, false to continue tracing.
 */
public bool:KnockbackTRFilter(entity, contentsMask)
{
    // If entity is a player, continue tracing.
    if (entity > 0 && entity <= MaxClients)
    {
        return false;
    }
    
    // Allow hit.
    return true;
}