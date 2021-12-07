#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


public Plugin:myinfo =
{
	name = "SM ZR KnockBack",
	author = "Franc1sco steam: franug",
	description = "A knockback based in ZR",
	version = "v1.0",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
    HookEvent("player_hurt", OnPlayerHurt);

    CreateConVar("zr_knockback", "v1.0", _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!IsValidClient(attacker) || GetClientTeam(attacker) == GetClientTeam(client))
		return;


	new damage = GetEventInt(event, "dmg_health");

	new Float:knockback = 6.0; // knockback amount

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
    
    
    	// Apply damage knockback multiplier.
    	knockback *= damage;
    
    	// Apply knockback.
    	KnockbackSetVelocity(client, attackerloc, clientloc, knockback);
}

KnockbackSetVelocity(client, const Float:startpoint[3], const Float:endpoint[3], Float:magnitude)
{
    // Create vector from the given starting and ending points.
    new Float:vector[3];
    MakeVectorFromPoints(startpoint, endpoint, vector);
    
    // Normalize the vector (equal magnitude at varying distances).
    NormalizeVector(vector, vector);
    
    // Apply the magnitude by scaling the vector (multiplying each of its components).
    ScaleVector(vector, magnitude);
    

    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
}

public bool:KnockbackTRFilter(entity, contentsMask)
{
    // If entity is a player, continue tracing.
    if (entity > 0 && entity < MAXPLAYERS)
    {
        return false;
    }
    
    // Allow hit.
    return true;
}


public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}