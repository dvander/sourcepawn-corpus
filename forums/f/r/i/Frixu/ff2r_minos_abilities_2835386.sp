/*
	"rage_judgement"
	{
		"slot"					"0"									// Ability slot
   	    
    	"delay"					"1.0"   							// Seconds before dash
   		"dashforce"    			"700.0"   							// Force of dash
    	"damage"       			"300.0"   							// Explosion damage
   		"radius"      			"450.0"  							// Explosion radius
   	 	"freeze"      			"1"     							// Freeze boss in one place? (1 = yes, 0 = no)
    
    	"plugin_name"  			"ff2r_minos_abilities"
	}
	
	"rage_knock_up"
	{
		"slot"					"0"									// Ability slot
		
    	"forceup"  				"1000.0"  							// Force of dash
    	"damage"       			"50.0"   							// Explosion damage

    	"plugin_name" 			"ff2r_minos_abilities"
	}

	"rage_die" 
	{
		"slot"					"0"									// Ability slot		
    	
    	"delay"        			"1.5"   							// Seconds before dash
    	"dashforce"   			"3000.0"   							// Force of dash
    	"damage"       			"300.0"   							// Explosion damage
    	"radius"       			"450.0"   							// Explosion radius
    	"freeze"       			"1"     							// Freeze boss in one place? (1 = yes, 0 = no)

    	"plugin_name"  			"ff2r_minos_abilities"
	}
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#undef REQUIRE_PLUGIN
#include <tf2attributes>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2 Rewrite: Minos Prime Abilities"
#define PLUGIN_AUTHOR 	"Haunted Bone" 
#define PLUGIN_DESC 	"Unique Abilities"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define INACTIVE 		100000000.0

// Rage Judgement Variables
float RJ_Delay[MAXTF2PLAYERS]; 
float RJ_DashForce[MAXTF2PLAYERS]; 
float RJ_Damage[MAXTF2PLAYERS]; 
float RJ_Radius[MAXTF2PLAYERS]; 
float RJ_EffectTime[MAXTF2PLAYERS]; 
bool RJ_Freeze[MAXTF2PLAYERS]; 
bool RJ_IsDashing[MAXTF2PLAYERS]; 
float RJ_DashStartPos[MAXTF2PLAYERS][3]; 

// Rage Knock Up Variables
float KU_ForceUp[MAXTF2PLAYERS]; 
float KU_Damage[MAXTF2PLAYERS]; 
bool KU_IsDashing[MAXTF2PLAYERS]; 

// Rage Die Variables
float RD_Delay[MAXTF2PLAYERS]; 
float RD_DashForce[MAXTF2PLAYERS]; 
float RD_Damage[MAXTF2PLAYERS]; 
float RD_Radius[MAXTF2PLAYERS]; 
bool RD_Freeze[MAXTF2PLAYERS]; 
bool RD_IsDashing[MAXTF2PLAYERS]; 
float RD_DashStartPos[MAXTF2PLAYERS][3]; 

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
};

public void OnPluginStart()
{	
	//
}

public void OnClientPutInServer(int clientIdx)
{
	RJ_IsDashing[clientIdx] = false;
	KU_IsDashing[clientIdx] = false;
}

public void OnPluginEnd()
{
	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		SDKUnhook(clientIdx, SDKHook_PreThink, RageJudgement_PreThink);
		SDKUnhook(clientIdx, SDKHook_PreThink, RageKnockUp_PreThink);
	}
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg)
{
    if(!cfg.IsMyPlugin())	
        return;
    
    if(!StrContains(ability, "rage_judgement", false))
    {
        Ability_RageJudgement(clientIdx, ability, cfg);
    }
    else if(!StrContains(ability, "rage_knock_up", false))
    {
        Ability_RageKnockUp(clientIdx, ability, cfg);
    }
    else if(!StrContains(ability, "rage_die", false)) 
    {
        Ability_RageDie(clientIdx, ability, cfg);
    }
}

public void Ability_RageJudgement(int clientIdx, const char[] ability_name, AbilityData ability)
{
    RJ_Delay[clientIdx] = ability.GetFloat("delay", 1.0); 
    RJ_DashForce[clientIdx] = ability.GetFloat("dashforce", 1000.0); 
    RJ_Damage[clientIdx] = ability.GetFloat("damage", 300.0);
    RJ_Radius[clientIdx] = ability.GetFloat("radius", 450.0);
    RJ_Freeze[clientIdx] = ability.GetBool("freeze", true);
    RJ_EffectTime[clientIdx] = GetGameTime() + RJ_DashForce[clientIdx];

    float velocity[3];
    GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
    velocity[2] = 500.0; 
    TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);

    if(RJ_Freeze[clientIdx])
    {
        CreateTimer(0.5, Timer_FreezeBoss, clientIdx); 
    }

    CreateTimer(RJ_Delay[clientIdx], Timer_StartDash, clientIdx);
}

public void Ability_RageKnockUp(int clientIdx, const char[] ability_name, AbilityData ability)
{
    KU_ForceUp[clientIdx] = ability.GetFloat("forceup", 1000.0);
    KU_Damage[clientIdx] = ability.GetFloat("damage", 50.0);
    KU_IsDashing[clientIdx] = true;

    float velocity[3];
    GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
    velocity[2] = 400.0; 
    TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);


    CreateTimer(0.5, Timer_StartKnockUpDash, clientIdx);
}

public void Ability_RageDie(int clientIdx, const char[] ability_name, AbilityData ability)
{
    RD_Delay[clientIdx] = ability.GetFloat("delay", 1.5); 
    RD_DashForce[clientIdx] = ability.GetFloat("dashforce", 3000.0); 
    RD_Damage[clientIdx] = ability.GetFloat("damage", 300.0);
    RD_Radius[clientIdx] = ability.GetFloat("radius", 450.0);
    RD_Freeze[clientIdx] = ability.GetBool("freeze", true);

    float velocity[3];
    GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
    velocity[2] = 2000.0; 
    TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);

    if(RD_Freeze[clientIdx])
    {
        CreateTimer(0.5, Timer_FreezeBoss, clientIdx); 
    }

    CreateTimer(RD_Delay[clientIdx], Timer_StartRageDieDash, clientIdx);
}

public Action Timer_StartRageDieDash(Handle timer, int clientIdx)
{
    if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
    {
        if(RD_Freeze[clientIdx])
        {
            SetEntityMoveType(clientIdx, MOVETYPE_WALK);
        }

        RD_IsDashing[clientIdx] = true;
        GetClientAbsOrigin(clientIdx, RD_DashStartPos[clientIdx]);

        float dashDirection[3];
        GetClientEyeAngles(clientIdx, dashDirection);
        GetAngleVectors(dashDirection, dashDirection, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(dashDirection, RD_DashForce[clientIdx]);
        TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, dashDirection);

        SDKHook(clientIdx, SDKHook_PreThink, RageDie_PreThink);
    }

    return Plugin_Handled;
}


public void RageDie_PreThink(int clientIdx)
{
    if(!RD_IsDashing[clientIdx])
        return;

    float currentPos[3];
    GetClientAbsOrigin(clientIdx, currentPos);

    if(IsClientOnGround(clientIdx) || IsClientStuck(clientIdx))
    {
        RD_IsDashing[clientIdx] = false;
        SDKUnhook(clientIdx, SDKHook_PreThink, RageDie_PreThink);
        
        CreateExplosionEffects(currentPos);
        DealExplosionDamage(clientIdx, currentPos, RD_Damage[clientIdx], RD_Radius[clientIdx]);
    }
}

public void RageKnockUp_PreThink(int clientIdx)
{
    if (!KU_IsDashing[clientIdx])
        return;

    float currentPos[3];
    GetClientAbsOrigin(clientIdx, currentPos);

    int target = FindNearestEnemy(clientIdx);
    if (target != -1)
    {
        float targetPos[3];
        GetClientAbsOrigin(target, targetPos);

        if (GetVectorDistance(currentPos, targetPos) <= 105.0)
        {
            KU_IsDashing[clientIdx] = false;
            SDKUnhook(clientIdx, SDKHook_PreThink, RageKnockUp_PreThink);

            SDKHooks_TakeDamage(target, clientIdx, clientIdx, KU_Damage[clientIdx], DMG_CLUB);

            float velocity[3];
            velocity[0] = 0.0;
            velocity[1] = 0.0;
            velocity[2] = KU_ForceUp[clientIdx]; 
            TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velocity);

            EmitSoundToAll("weapons/halloween_boss/knight_axe_hit.wav", target);
        }
    }
}

int FindNearestEnemy(int clientIdx)
{
    int nearestTarget = -1;
    float nearestDistance = INACTIVE;
    float clientPos[3];
    GetClientAbsOrigin(clientIdx, clientPos);

    for(int target = 1; target <= MaxClients; target++)
    {
        if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(clientIdx))
        {
            float targetPos[3];
            GetClientAbsOrigin(target, targetPos);

            float distance = GetVectorDistance(clientPos, targetPos);
            if(distance < nearestDistance)
            {
                nearestTarget = target;
                nearestDistance = distance;
            }
        }
    }

    return nearestTarget;
}

public Action Timer_StartKnockUpDash(Handle timer, int clientIdx)
{
    if (IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
    {
        int target = FindNearestEnemy(clientIdx);
        if (target != -1)
        {
            float targetPos[3];
            GetClientAbsOrigin(target, targetPos);

            float bossPos[3];
            GetClientAbsOrigin(clientIdx, bossPos);

            float dashDirection[3];
            MakeVectorFromPoints(bossPos, targetPos, dashDirection);
            NormalizeVector(dashDirection, dashDirection);
            ScaleVector(dashDirection, KU_ForceUp[clientIdx]);

            TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, dashDirection);
            SDKHook(clientIdx, SDKHook_PreThink, RageKnockUp_PreThink);

        }
    }

    return Plugin_Handled;
}

public Action Timer_FreezeBoss(Handle timer, int clientIdx)
{
    if(IsValidClient(clientIdx)) 
    {
        CreateFreezeEffect(clientIdx);
        SetEntityMoveType(clientIdx, MOVETYPE_NONE);
    }
    return Plugin_Handled;
}

void CreateFreezeEffect(int clientIdx)
{
	int particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle))
	{
		float pos[3];
		GetClientAbsOrigin(clientIdx, pos);
		pos[2] += 50.0; 

		DispatchKeyValue(particle, "effect_name", "freeze_overlay");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(particle, "Start");
		CreateTimer(2.0, Timer_RemoveEntity, particle); 
	}
}

public Action Timer_StartDash(Handle timer, int clientIdx)
{
    if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
    {
        if(RJ_Freeze[clientIdx])
        {
            SetEntityMoveType(clientIdx, MOVETYPE_WALK);
        }

        RJ_IsDashing[clientIdx] = true;
        GetClientAbsOrigin(clientIdx, RJ_DashStartPos[clientIdx]);

        float dashDirection[3];
        GetClientAbsAngles(clientIdx, dashDirection);
        GetAngleVectors(dashDirection, dashDirection, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(dashDirection, RJ_DashForce[clientIdx]);
        TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, dashDirection);

        SDKHook(clientIdx, SDKHook_PreThink, RageJudgement_PreThink);
    }

    return Plugin_Handled;
}

public void RageJudgement_PreThink(int clientIdx)
{
    if(!RJ_IsDashing[clientIdx])
        return;

    float currentPos[3];
    GetClientAbsOrigin(clientIdx, currentPos);

    if(IsClientOnGround(clientIdx) || IsClientStuck(clientIdx))
    {
        RJ_IsDashing[clientIdx] = false;
        SDKUnhook(clientIdx, SDKHook_PreThink, RageJudgement_PreThink);

        CreateExplosionEffect(currentPos);
        DealExplosionDamage(clientIdx, currentPos, RJ_Damage[clientIdx], RJ_Radius[clientIdx]);
    }
}

bool IsClientOnGround(int clientIdx)
{
    return GetEntPropEnt(clientIdx, Prop_Send, "m_hGroundEntity") != -1;
}

void CreateExplosionEffect(float pos[3])
{
    int particle = CreateEntityByName("info_particle_system");
    if(IsValidEntity(particle))
    {
        DispatchKeyValue(particle, "effect_name", "explosionCore_buildings");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(particle, "Start");
        CreateTimer(2.0, Timer_RemoveEntity, particle);
    }

    int flashParticle = CreateEntityByName("info_particle_system");
    if(IsValidEntity(flashParticle))
    {
        DispatchKeyValue(flashParticle, "effect_name", "fluidSmokeExpl_ring_mvm");
        DispatchSpawn(flashParticle);
        ActivateEntity(flashParticle);
        TeleportEntity(flashParticle, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(flashParticle, "Start");
        CreateTimer(2.0, Timer_RemoveEntity, flashParticle);
    }

    EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, 1.0, _, _, pos);
}

void CreateExplosionEffects(float pos[3])
{
    int particle = CreateEntityByName("info_particle_system");
    if(IsValidEntity(particle))
    {
        DispatchKeyValue(particle, "effect_name", "explosionCore_buildings");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(particle, "Start");
        CreateTimer(2.0, Timer_RemoveEntity, particle);
    }

    int flashParticle = CreateEntityByName("info_particle_system");
    if(IsValidEntity(flashParticle))
    {
        DispatchKeyValue(flashParticle, "effect_name", "rd_robot_explosion");
        DispatchSpawn(flashParticle);
        ActivateEntity(flashParticle);
        TeleportEntity(flashParticle, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(flashParticle, "Start");
        CreateTimer(2.0, Timer_RemoveEntity, flashParticle);
    }

    EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, 1.0, _, _, pos);
}

public Action Timer_RemoveEntity(Handle timer, int entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEntity(entity);
	}
	return Plugin_Handled;
}


void DealExplosionDamage(int attacker, float pos[3], float damage, float radius)
{
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(attacker))
		{
			float targetPos[3];
			GetClientAbsOrigin(target, targetPos);

			if(GetVectorDistance(pos, targetPos) <= radius)
			{
				SDKHooks_TakeDamage(target, attacker, attacker, damage, DMG_BLAST);
			}
		}
	}
}

bool IsClientStuck(int clientIdx)
{
	float mins[3], maxs[3], pos[3];
	GetClientMins(clientIdx, mins);
	GetClientMaxs(clientIdx, maxs);
	GetClientAbsOrigin(clientIdx, pos);

	TR_TraceHullFilter(pos, pos, mins, maxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers, clientIdx);
	return TR_DidHit();
}

public bool TraceEntityFilterPlayers(int entity, int contentsMask, int clientIdx)
{
	return entity != clientIdx && entity > MaxClients;
}

public void FF2R_OnBossRemoved(int clientIdx)
{
    SDKUnhook(clientIdx, SDKHook_PreThink, RageJudgement_PreThink);
    SDKUnhook(clientIdx, SDKHook_PreThink, RageKnockUp_PreThink);
    SDKUnhook(clientIdx, SDKHook_PreThink, RageDie_PreThink); 
}

stock bool IsValidClient(int clientIdx, bool replaycheck=true)
{
	if(clientIdx <= 0 || clientIdx > MaxClients)
		return false;

	if(!IsClientInGame(clientIdx) || !IsClientConnected(clientIdx))
		return false;

	if(GetEntProp(clientIdx, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(clientIdx) || IsClientReplay(clientIdx)))
		return false;

	return true;
}