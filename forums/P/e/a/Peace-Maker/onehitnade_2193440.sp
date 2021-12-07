#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

new Handle:g_hCVDamage;

public Plugin:myinfo = 
{
	name = "Grenade One-Hit",
	author = "Peace-Maker",
	description = "Hits with grenade projectiles are an instant kill.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	g_hCVDamage = CreateConVar("sm_onehitnade_damage", "1", "How much damage in addition to the target player's health should we deal? (client health + x)", _, true, 0.0);
	AutoExecConfig();
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
	
	// Give x damage more than the current health of the player from the proper direction.
	SDKHooks_TakeDamage(other, entity, iOwner, GetClientHealth(other)+GetConVarFloat(g_hCVDamage), DMG_BULLET|DMG_GENERIC, entity, fVelocity, fOrigin);
}