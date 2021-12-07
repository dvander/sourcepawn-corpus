#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls  required

// =========================================================================

public Plugin myinfo =
{
    name        = "Nova Jumping",
    author      = "Nyuu",
    description = "Expels the player when he shoots with the Nova",
    version     = "1.0.0",
    url         = ""
}

// =========================================================================
// >> GLOBAL VARIABLES
// =========================================================================

ConVar gl_hNovaKnockback;
ConVar gl_hNovaVelocityKept;
ConVar gl_hNovaGround;

// =========================================================================
// >> PLUGIN
// =========================================================================

public void OnPluginStart()
{
    // === Create cvars
    gl_hNovaKnockback    = CreateConVar("sm_nova_knockback",     "650.0", "Set the Nova knockback value");
    gl_hNovaVelocityKept = CreateConVar("sm_nova_velocity_kept", "0.300", "Set the player velocity factor to keep");
    gl_hNovaGround       = CreateConVar("sm_nova_ground",        "0",     "Set if the knockback works when on the ground");
    
    // === Hook events
    HookEvent("weapon_fire", OnWeaponFirePost, EventHookMode_Post);
}

// =========================================================================
// >> EVENT
// =========================================================================

public void OnWeaponFirePost(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    int iPlayer = GetClientOfUserId(hEvent.GetInt("userid"));
    
    if (1 <= iPlayer <= MaxClients)
    {
        char szWeapon[32];
        hEvent.GetString("weapon", szWeapon, sizeof(szWeapon));
        
        if (StrEqual(szWeapon, "weapon_nova"))
        {
            PlayerKnockback(iPlayer);
        }
    }
}

// =========================================================================
// >> PLAYER
// =========================================================================

public void PlayerKnockback(int iPlayer)
{
    // === Check if the player is on the ground
    if (!(GetEntityFlags(iPlayer) & FL_ONGROUND) || (gl_hNovaGround.BoolValue))
    {
        float vVelocity[3];
        float vEyeAngles[3];
        float vInvVector[3];
        
        // === Get the player data
        GetEntPropVector(iPlayer, Prop_Data, "m_vecVelocity", vVelocity);
        GetClientEyeAngles(iPlayer, vEyeAngles);
        
        // === Compute the vectors
        GetAngleVectors(vEyeAngles, vInvVector, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(vInvVector, -(gl_hNovaKnockback.FloatValue));
        ScaleVector(vVelocity, gl_hNovaVelocityKept.FloatValue);
        AddVectors(vVelocity, vInvVector, vVelocity);
            
        // === Apply the new velocity to the player
        TeleportEntity(iPlayer, NULL_VECTOR, NULL_VECTOR, vVelocity);
    }
}

// =========================================================================
