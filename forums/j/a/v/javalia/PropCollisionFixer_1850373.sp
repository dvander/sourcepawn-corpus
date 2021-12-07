#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new const String:PluginVersion[60] = "1.0.0.0";

public Plugin:myinfo = {
	
	name = "PropCollisionFixer",
	author = "javalia",
	description = "fixes collision of prop_multiplayer things to normal collision",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

//defines from hl2sdk
enum Collision_Group_t
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player
										
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

	LAST_SHARED_COLLISION_GROUP
};

public OnPluginStart(){

	CreateConVar("PropCollisionFixer_version", PluginVersion, "plugin info cvar", FCVAR_DONTRECORD | FCVAR_NOTIFY);

}

public OnEntityCreated(entity, const String:classname[]){
	
	if(StrContains(classname, "prop", false) != -1){
	
		SDKHook(entity, SDKHook_SpawnPost, SpawnPostHook);
		
	}

}

public SpawnPostHook(entity){
	
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE);

}