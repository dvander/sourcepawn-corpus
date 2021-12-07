#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Grenade One-Hit",
	author = "Peace-Maker",
	description = "Hits with grenade projectiles are an instant kill.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrContains(classname, "projectile") == -1)
		return;
	
	SDKHook(entity, SDKHook_SpawnPost, Hook_OnSpawnPost);
}

public Hook_OnSpawnPost(entity)
{
	// Wait until the owner is set.
	RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

public OnNextFrame(any:entityref)
{
	new iEntity = EntRefToEntIndex(entityref);
	if(iEntity == INVALID_ENT_REFERENCE)
		return;
	
	SDKHook(iEntity, SDKHook_TouchPost, Hook_OnTouchPost);
}

public Hook_OnTouchPost(entity, other)
{
	// Make sure we're touching a player
	if(other < 0 || other >= MaxClients)
		return;
	
	// Make sure the player is still alive.
	if(!IsClientInGame(other) || !IsPlayerAlive(other))
		return;
	
	// Don't damage the grenade thrower.
	new iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(iOwner == other)
		return;
	
	new Float:fOrigin[3], Float:fVelocity[3];
	GetEntPropVector(entity, Prop_Send, "m_vecVelocity", fVelocity);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
	
	// The nade is moving too slow or is laying still on the floor.
	if(GetVectorLength(fVelocity) < 5.0)
		return;
	
	// Give 1000 damage more than the current health of the player from the proper direction.
	// This should also kill players with rediculous high HP like zombies in ZR (happy Bara? :B)
	SDKHooks_TakeDamage(other, entity, iOwner, GetClientHealth(other)+1000.0, DMG_BULLET|DMG_GENERIC, entity, fVelocity, fOrigin);
}