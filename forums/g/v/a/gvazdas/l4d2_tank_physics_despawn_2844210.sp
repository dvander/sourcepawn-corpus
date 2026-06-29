#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d2_tank_physics_despawn"
#define PLUGIN_VERSION 			"1.02"
#define CONFIG_FILENAME         PLUGIN_NAME
#define DEBUG 0

ConVar g_hCvarDespawn, g_hCvarStrict;
#define MAXENTITIES        2048
bool marked[MAXENTITIES+1]; // mark entities that have been processed already

public Plugin myinfo =
{
	name = "[L4D2] Tank Physics Despawn",
	author = "gvazdas",
	description = "Delay-despawn physics props hit by tank melee or rock that may be blocking survivors.",
	version = PLUGIN_VERSION,
	url = "https://knockout.chat/user/3022"
}

public void OnPluginStart()
{
    AutoExecConfig(true, CONFIG_FILENAME);
    g_hCvarDespawn = CreateConVar("l4d2_tank_physics_despawn", "30.0", "Time after first hit to despawn. 0.0 to disable plugin.",FCVAR_PROTECTED , true, 0.0, true, 1000.0);
    g_hCvarStrict = CreateConVar("l4d2_tank_physics_strict",  "1", "Despawn only entities that are marked as Tank props (red glow).",FCVAR_PROTECTED , true, 0.0, true, 1.0);
    HookEntityOutput("prop_physics",   "OnHitByTank", OnHitByTank);
    HookEntityOutput("prop_car_alarm", "OnHitByTank", OnHitByTank);
    HookEvent("round_start",            evtRound,          EventHookMode_PostNoCopy);
    HookEvent("round_end",              evtRound,          EventHookMode_PostNoCopy);
    reset_marked();
}

void evtRound(Event event, const char[] name, bool dontBroadcast)
{
	reset_marked();
}

public void OnMapStart()
{
    reset_marked();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (IsValidEdict(entity)) marked[entity] = false;
}

void OnHitByTank(const char[] output, int activator, int caller, float delay)
{
    if (g_hCvarDespawn.FloatValue<=0.0) return;
    if (activator!=caller) return;
    #if DEBUG
        LogMessage("%s %d %d %f", output, activator, caller, delay);
    #endif
    entity_hit_by_tank(activator);
}

// When a tank rock touches an entity to bounce
public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
    if (g_hCvarDespawn.FloatValue<=0.0) return;
    #if DEBUG
        static char class[64];
        GetEntityClassname(entity, class, sizeof(class));
        LogMessage("Rock_BounceTouch_Post %d %d %d %s", tank, rock, entity, class);
    #endif
    entity_hit_by_tank(entity);
}

// Entity was hit by tank melee or rock
void entity_hit_by_tank(int entity)
{
    if (entity_ignore(entity)) return;
    entity_mark(entity);
}

// Check if entity should be ignored
bool entity_ignore(int entity)
{
    if (!IsValidEdict(entity)) return true;
    if (marked[entity]) return true; // entity already checked
    marked[entity] = true; // mark entity as checked now
    if (entity<=MaxClients) return true;
    if (g_hCvarStrict.BoolValue && !L4D_IsTankProp(entity)) return true;
    MoveType movetype = GetEntityMoveType(entity);
    if (movetype!=MOVETYPE_VPHYSICS)
    {
        #if DEBUG
            LogMessage("entity_ignore %d: movetype %d", entity, movetype);
        #endif
        return true;
    }
    if (GetEntProp(entity,Prop_Send,"m_isCarryable")>0)
    {
        #if DEBUG
            LogMessage("entity_ignore %d: carryable", entity);
        #endif
        return true;
    }
    if (!entity_solid(entity))
    {
        #if DEBUG
            LogMessage("entity_ignore %d: not solid");
        #endif
        return true;
    }
    int spawnflags = GetEntProp(entity,Prop_Send,"m_spawnflags");
    #if DEBUG
        LogMessage("%d spawnflags %d", entity, spawnflags);
    #endif
    if (spawnflags & 4) return true; // Debris
    if (spawnflags & 2097152) return true; // No Collisions
    return false;
}

// Mark entity for death
void entity_mark(int entity)
{
    #if DEBUG
        LogMessage("%d marked for deletion", entity);
    #endif
    //marked[entity] = true;
    if (g_hCvarDespawn.FloatValue<0.1) Timer_Delete_Entity(null,EntIndexToEntRef(entity));
    else CreateTimer(g_hCvarDespawn.FloatValue,Timer_Delete_Entity,EntIndexToEntRef(entity),TIMER_FLAG_NO_MAPCHANGE);
}

// Kill entity
Action Timer_Delete_Entity(Handle timer, int entref)
{
    if (!IsValidEntRef(entref)) return Plugin_Stop;
    int entity = EntRefToEntIndex(entref);
    if (!IsValidEdict(entity)) return Plugin_Stop;
    if (marked[entity])
    {
        #if DEBUG
            LogMessage("Deleted %d", entity);
        #endif
        AcceptEntityInput(entity,"Kill");
        marked[entity] = false;
    }
    return Plugin_Stop;
}

// Reset marked entities.
void reset_marked()
{
    for(int i = 0; i<=MAXENTITIES; i++)
    {
        marked[i] = false;
    }
}

// Determine if entity is solid from m_CollisionGroup, m_nSolidType and m_usSolidFlags
stock bool entity_solid(int entity)
{
    if (GetEntProp(entity, Prop_Send, "m_nSolidType") == 0) return false;
    if (GetEntProp(entity, Prop_Send, "m_usSolidFlags") & 0x0004) return false; // FSOLID_NOT_SOLID 
    switch (GetEntProp(entity, Prop_Send, "m_CollisionGroup"))
    {
        case 1: return false; // COLLISION_GROUP_DEBRIS
        case 2: return false; // COLLISION_GROUP_DEBRIS_TRIGGER
    }
    return true;
}

stock bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;	
}