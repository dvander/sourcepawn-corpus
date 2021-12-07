
/* /////////////////////////////////
// ______________  ___________ 
// \______   \   \/  /  _____/ 
//  |       _/\     /   \  ___ 
//  |    |   \/     \    \_\  \
//  |____|_  /___/\  \______  /
//         \/      \_/      \/
//     R E F L E X  -  G A M E R S
*/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks> 

#pragma semicolon 1

// 1.2.0
//   use FL_EDICT_DONTSEND instead of settransmit hook
// 1.1.0
//   cleanup
//   disabled clients receiving volume data
//

//----------------------------------------------------------------------------------------------------------------------
public Plugin:myinfo = {
	name = "Smoke/Radar Bug Fix",
	author = "mukunda",
	description = "Fixes smoke/radar visibility bug",
	version = "1.2.0",
	url = "www.reflex-gamers.com"
};

//----------------------------------------------------------------------------------------------------------------------

#define MODEL "models/rxg/smokevol.mdl"
#define DURATION 18.0
 
//----------------------------------------------------------------------------------------------------------------------
public OnPluginStart() {
	HookEvent( "smokegrenade_detonate", OnSmokeDetonated );	 
//	HookEvent( "hegrenade_detonate", OnSmokeDetonated );	 //debug
}

//----------------------------------------------------------------------------------------------------------------------
public OnMapStart() {
 
	PrecacheModel( MODEL );
	
}

//----------------------------------------------------------------------------------------------------------------------
public OnSmokeDetonated( Handle:event, const String:name[], bool:dontBroadcast ) {
	new Float:pos[3];
	pos[0] = GetEventFloat( event, "x" );
	pos[1] = GetEventFloat( event, "y" );
	pos[2] = GetEventFloat( event, "z" );
	pos[2] += 40.0;
	new ent = CreateEntityByName( "prop_physics_multiplayer" );
	SetEntityModel( ent, MODEL );	
	
	TeleportEntity( ent, pos, NULL_VECTOR, NULL_VECTOR );
	DispatchSpawn( ent );
	SetEntityMoveType( ent, MOVETYPE_NONE );
	AcceptEntityInput( ent, "DisableMotion" );
	 
	SDKHook( ent, SDKHook_ShouldCollide, OnCollision ); 
	SetEdictFlags( ent, (GetEdictFlags(ent)&(~FL_EDICT_ALWAYS))|FL_EDICT_DONTSEND ); // allow settransmit hooks
	
	CreateTimer( DURATION, KillVolume, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE );
}
 
//----------------------------------------------------------------------------------------------------------------------
public bool:OnCollision(entity, collisiongroup, contentsmask, bool:originalResult) {
	if( collisiongroup == 13 || collisiongroup == 0 ) return false; // grenades and bullets should not clip
	
	// some things...like chickens... will still not be able to pass through the volume, but hey blame valve for this shit
	return true;
	
}

//----------------------------------------------------------------------------------------------------------------------
public Action:KillVolume( Handle:timer, any:ref ) {
	new ent = EntRefToEntIndex(ref);
	if( ent == INVALID_ENT_REFERENCE ) return  Plugin_Handled;	
	if( IsValidEntity( ent ) ) AcceptEntityInput( ent, "Kill" );
	return Plugin_Handled;
}
