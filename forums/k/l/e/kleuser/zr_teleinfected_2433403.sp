#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

#define PLUGIN_NAME "ZR Tele Infected"
#define PLUGIN_VERSION "1.1.0"

new Handle:Spawn_Origins;
new Handle:Spawn_Angles;
new Float:OriginBuffer[3];
new Float:AnglesBuffer[3];
 
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Teleports all infected players back to spawn",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("zr_teleinfected_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	Spawn_Origins = CreateArray(3);
	Spawn_Angles = CreateArray(3);
}

public OnMapStart()
{
	/* Store all of the spawnpoints */
	decl String:sClassName[32];
	new iMaxEntities = GetMaxEntities();
	
	for (new iEntity = 0; iEntity < iMaxEntities; iEntity++)
	{
		if (!IsValidEntity(iEntity))
			continue;
		
		GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
		
		if (StrEqual("info_player_counterterrorist", sClassName) || StrEqual("info_player_terrorist", sClassName))
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", OriginBuffer);
			GetEntPropVector(iEntity, Prop_Send, "m_angRotation", AnglesBuffer);
			PushArrayArray(Spawn_Origins, OriginBuffer);
			PushArrayArray(Spawn_Angles, AnglesBuffer);
		}
	}
}

public OnMapEnd()
{
	/* Clear our arrays for the next map */
	ClearArray(Spawn_Origins);
	ClearArray(Spawn_Angles);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	/* There is already a Cvar for mother zombies */
	if (!motherInfect)
	{
		TelePlayer(client);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Adds support for older versions of ZR */
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (StrEqual("zombie_claws_of_death", weapon))
	{
		new victimId = GetEventInt(event, "userid");
		new victim = GetClientOfUserId(victimId);
		
		TelePlayer(victim);
	}
}

TelePlayer(client)
{
	/* Teleport the player to a random spawnpoint */
	new iSpawn = Math_GetRandomInt(0, GetArraySize(Spawn_Origins) - 1);
	
	GetArrayArray(Spawn_Origins, iSpawn, OriginBuffer);
	GetArrayArray(Spawn_Angles, iSpawn, AnglesBuffer);
	
	TeleportEntity(client, OriginBuffer, AnglesBuffer, NULL_VECTOR);
}