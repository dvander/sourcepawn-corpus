#include <sourcemod>
#include <sdktools>

// The interval which we use to check if any alive players are stuck and thus give them noblock, The lower the faster to catch stuck players but more CPU usage
#define CHECK_STUCK_INTERVAL 1.0

// The interval which we use to check if the player that were given noblock are no longer stuck and can be given normal collision back, The lower the faster to catch unstucked players but more CPU usage
#define CHECK_UNSTUCK_INTERVAL 1.0

enum
{
    COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
                                        // TF2, this filters out other players and CBaseObjects
    COLLISION_GROUP_NPC,			// Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,		// Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

    COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
    COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

    LAST_SHARED_COLLISION_GROUP
};

#define PLUGIN_VERSION	"1.0.0"

new Handle:g_hTimer_EndNoblock[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Noblock On Stuck", 
	author = "JustGo", 
	description = "Temporary noblock for player if they get stuck.", 
	version = PLUGIN_VERSION, 
	url = ""
}

public OnPluginStart() {
	CreateConVar("noblock_stuck_version", PLUGIN_VERSION, "noblock_stuck plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	CreateTimer(CHECK_STUCK_INTERVAL, Timer_CheckPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
}

public Action:Timer_CheckPlayers(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{	
		if (!IsValidAlive(client)) continue;

		int other = GetStuckPlayer(client);

		if(other != -1) {
			StartUnstuck(client)
			StartUnstuck(other)
		}
	}

	return Plugin_Continue
}

stock int GetStuckPlayer(client) {
	float min[3]; 
	float max[3]; 
	float origin[3];

	GetClientMins(client, min);
	GetClientMaxs(client, max);

	GetClientAbsOrigin(client, origin);

	TR_TraceHullFilter(origin, origin, 	min, max, MASK_ALL, trace_hit_player, client);
	int target = TR_GetEntityIndex();
	if (TR_DidHit() && IsValidAlive(target)) {
		return target;
	}
	
	return -1;
}

stock bool trace_hit_player(int hit, int mask, int client) 
{
    return client != hit && IsValidAlive(hit) && (!HasNoblock(client) && !HasNoblock(hit));
}

stock StartUnstuck(client) {
	if (!HasNoblock(client)) {
		SetEntityCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
	}

	if (!g_hTimer_EndNoblock[client]) {
		g_hTimer_EndNoblock[client] = CreateTimer(CHECK_UNSTUCK_INTERVAL, Timer_EndNoblock, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_EndNoblock(Handle:timer, any:client)
{
	if (!IsValidAlive(client)) {
		g_hTimer_EndNoblock[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if (GetStuckPlayer(client) == -1) {
		SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
		g_hTimer_EndNoblock[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock bool HasNoblock(int client) {
	return GetEntProp(client, Prop_Data, "m_CollisionGroup") == COLLISION_GROUP_DEBRIS_TRIGGER;
}

stock bool IsValidAlive(client) {
	return IsClientValid(client) && IsPlayerAlive(client)
}

stock bool IsClientValid(int client)
{
    if (client > 0 && client <= MaxClients)
    {
        if (!IsClientInGame(client))
        {
            return false;
        }

        if (IsClientSourceTV(client))
        {
            return false;
        }

        return true;
    }
    return false;
}