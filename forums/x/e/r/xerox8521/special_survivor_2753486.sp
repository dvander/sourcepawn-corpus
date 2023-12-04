#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVORS 2

#define DAMAGE_EVENTS_ONLY		1		// Call damage functions, but don't modify health
#define	DAMAGE_YES				2

ConVar SSSD_TankChance = null;
ConVar SSSD_WitchChance = null;
ConVar SSSD_SpawnChance = null;
ConVar SSSD_Enabled = null;
ConVar SSSD_SpawnIncap = null;

int iSpecialMax = 0;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Spawn Special Infected on Survivor Death",
	author = "XeroX",
	description = "Spawns a special infected where the survivor died",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2753486"
}

public void OnPluginStart()
{
    EngineVersion version = GetEngineVersion();
    if(version == Engine_Left4Dead)
    {
        iSpecialMax = 3;
    }
    else if(version == Engine_Left4Dead2)
    {
        iSpecialMax = 6;
    }
    else
    {
        SetFailState("Invalid Game Engine detected. This plugin only supports Left4Dead & Left4Dead2");
    }

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_incapacitated", Event_PlayerIncapacitated);

    SSSD_SpawnChance = CreateConVar("SSSD_SpawnChance", "60.0", "Chance that any special infected spawns at the survivors death location.\nthis chance is independent from the tank and witch chance", FCVAR_NOTIFY, true, 0.0, true, 100.0);
    SSSD_TankChance = CreateConVar("SSSD_TankChance", "10.0", "Chance that a tank spawns at the survivors death location", FCVAR_NOTIFY, true, 0.0, true, 100.0);
    SSSD_WitchChance = CreateConVar("SSSD_WitchChance", "5.0", "Chance that a witch spawns at the survivors death location", FCVAR_NOTIFY, true, 0.0, true, 100.0);
    SSSD_Enabled = CreateConVar("SSSD_Enabled", "1", "Enables (1) / Disables (0) the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    SSSD_SpawnIncap = CreateConVar("SSSD_SpawnIncap", "0", "If enabled (1) spawn specials also when the survivor becomes incapacitated\nNote that hanging from ledge does not count. 0 to disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    
    AutoExecConfig(true, "SpawnSpecialOnSurvivorDeath");
}


public void Event_PlayerIncapacitated(Event event, const char[] szName, bool dontBroadcast)
{
    if(SSSD_Enabled.IntValue == 0 || SSSD_SpawnIncap.IntValue == 0)
        return;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidEntity(victim))
        return;
    if(victim < 1 || victim > MaxClients)
        return;

    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    if(GetEntProp(victim, Prop_Send, "m_isHangingFromLedge") == 1)
        return;
    
    int damageType = event.GetInt("type");

    // Not drowning and not falling.
    // This is done to prevent special infected from spawning in insta kill areas
    if(damageType != DMG_DROWN && damageType != DMG_FALL)
    {
        if(GetRandomInt(1, 100) <= SSSD_SpawnChance.IntValue)
        {
            float Pos[3];
            GetClientAbsOrigin(victim, Pos);
            SpawnSpecialinfected(Pos);
        }
    }
}
public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
    if(SSSD_Enabled.IntValue == 0)
        return;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    if(!IsValidEntity(victim))
        return;
    if(victim < 1 || victim > MaxClients)
        return;

    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    int damageType = event.GetInt("type");

    // Not drowning and not falling
    // This is done to prevent special infected from spawning in insta kill areas
    if(damageType != DMG_DROWN && damageType != DMG_FALL)
    {
        if(GetRandomInt(1, 100) <= SSSD_SpawnChance.IntValue)
        {
            float Pos[3];
            GetClientAbsOrigin(victim, Pos);
            SpawnSpecialinfected(Pos);
        }  
    }
}


void SpawnSpecialinfected(float Pos[3])
{
    float Angle[3];
    if(SSSD_TankChance.IntValue > 0)
    {
        if(GetRandomInt(1, 100) <= SSSD_TankChance.IntValue)
        {
            int tank = L4D2_SpawnTank(Pos, Angle);
            if(IsValidEntity(tank))
            {
                // Freeze the Tank
                MoveType mv = GetEntityMoveType(tank);
                SetEntityMoveType(tank, MOVETYPE_NONE);
                SetEntityRenderColor(tank, 0, 0, 255, 255);

                SetEntProp(tank, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);

                // Prevent the tank from attacking for 2 seconds after spawning
                SetEntPropFloat(tank, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);

                int tankclaw = GetEntPropEnt(tank, Prop_Send, "m_hActiveWeapon");
                if(IsValidEntity(tankclaw))
                {
                    SetEntPropFloat(tankclaw, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
                }

                DataPack dp;
                CreateDataTimer(2.0, t_RleaseTank, dp);
                dp.WriteCell(EntIndexToEntRef(tank));
                dp.WriteCell(mv);
            }
            return;
        }
    }
    if(SSSD_WitchChance.IntValue > 0)
    {
        if(GetRandomInt(1, 100) <= SSSD_WitchChance.IntValue)
        {
            if(GetRandomInt(1, 2) == 2) // Rng between witch and witch as bride
            {
                L4D2_SpawnWitch(Pos, Angle);
            }
            else
            {
                L4D2_SpawnWitchBride(Pos, Angle);
            }
            return;
        }
    }
    // Spawn random special infected
    // This internally calls the appropriate functions for L4D
    L4D2_SpawnSpecial(GetRandomInt(1, iSpecialMax), Pos, Angle);
}

public Action t_RleaseTank(Handle timer, DataPack dp)
{
    dp.Reset();

    int tank = EntRefToEntIndex(dp.ReadCell());
    if(IsValidEntity(tank))
    {
        SetEntityMoveType(tank, view_as<MoveType>( dp.ReadCell() ));
        SetEntityRenderColor(tank, 255, 255, 255, 255);
        SetEntProp(tank, Prop_Data, "m_takedamage", DAMAGE_YES);
    }
}