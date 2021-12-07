#define AIRSHOT_HEIGHT 40

#include <sourcemod>
#include <sdktools>

// Uncomment this if you want to attach particles
#include <particle>

public OnPluginStart() HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)

public OnMapStart()
{	
	PrecacheSound("tf2stats/airshot.wav", true);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	if (attacker > 0 && victim != attacker)
	{
		new bool:airshot = !(GetEntityFlags(victim) & (FL_ONGROUND))
		if (airshot)
		{
			decl String:weapon[32]
			GetClientWeapon(attacker, weapon,sizeof(weapon))

			if (StrEqual(weapon, "tf_projectile_arrow") // bow arrow
            ||  StrEqual(weapon, "tf_projectile_energy_ball") // cow mangler's big projectile
            ||  StrEqual(weapon, "tf_projectile_energy_ring") // cow mangler's projectile
            ||  StrEqual(weapon, "tf_projectile_flare") // a flare
            ||  StrEqual(weapon, "tf_projectile_pipe") // grenade
            ||  StrEqual(weapon, "tf_projectile_rocket") // rocket
            ||  StrEqual(weapon, "tf_projectile_sentryrocket") // sentry rockets
            ||  StrEqual(weapon, "tf_projectile_stun_ball")) // scout's ball
			{
				new Float:dist = DistanceAboveGround(victim)
				if (dist >= AIRSHOT_HEIGHT)
                {
                    // Shows 'Critical hit' particle above victim's head
                    CreateParticle(victim, "crit_text", 10.0)

                    // Plays crit sounds for victim & attacker
                    EmitSoundToAll("tf2stats/airshot.wav")
                }
			}
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > MaxClients || !entity
}

Float:DistanceAboveGround(victim)
{
    decl Float:vStart[3], Float:vEnd[3]
    new Float:vAngles[3] = {90.0, 0.0, 0.0}
    GetClientAbsOrigin(victim, vStart)
    new Handle:trace = TR_TraceRayFilterEx(vStart, vAngles, MASK_SHOT, RayType_Infinite,TraceEntityFilterPlayer)

    new Float:distance = -1.0
    if(TR_DidHit(trace))
    {
        TR_GetEndPosition(vEnd, trace)
        distance = GetVectorDistance(vStart, vEnd, false)
    }

    CloseHandle(trace)
    return distance
}