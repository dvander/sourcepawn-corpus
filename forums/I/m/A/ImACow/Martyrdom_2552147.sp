#include <sdkhooks>
#include <sdktools>
/* Plugin Info */
#define PLUGIN_NAME 			"Martyrdom"
#define PLUGIN_VERSION_M 			"1.0.0"
#define PLUGIN_AUTHOR 			"IAmACow"
#define PLUGIN_DESCRIPTION		"Drops a live grenade when you die."
#define PLUGIN_URL				"https://forums.alliedmods.net/member.php?u=258233"

#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

ConVar sm_martyrdom_enabled = null;
ConVar sm_martyrdom_always = null;
ConVar sm_martyrdom_consume_grenade = null;

public void OnPluginStart()
{
	RegisterCvars();
	HookEvents();
}

/* 
 * Create convars here
 */
public void RegisterCvars()
{
	CreateConVar("sm_martyrdom_version", PLUGIN_VERSION_M, "", FCVAR_NOTIFY);
	sm_martyrdom_enabled = CreateConVar("sm_martyrdom_enabled", "1", "[bool] (0/1) Enable / disable Martyrdom dropping", FCVAR_NOTIFY);
	sm_martyrdom_always = CreateConVar("sm_martyrdom_always", "0", "[bool] (0/1) Always drop a Martyrdom grenade (not checking if the player has a grenade)", FCVAR_NOTIFY);
	sm_martyrdom_consume_grenade = CreateConVar("sm_martyrdom_consume_grenade", "1", "[bool] (0/1) on dropping the Martyrdom, do we consume the needed grenade", FCVAR_NOTIFY);
}
/* 
 * Hook events here
 */
public void HookEvents()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex)
{
	if(!IsValidEntity(weaponIndex))
		return Plugin_Continue;
	if(sm_martyrdom_always.BoolValue)
		return Plugin_Continue;
	char cClassName[32];
	if(!GetEntityClassname(weaponIndex, cClassName, sizeof(cClassName)))
		return Plugin_Continue;
	if(!StrEqual(cClassName, "weapon_hegrenade"))
		return Plugin_Continue;
	if(sm_martyrdom_consume_grenade.BoolValue)
		AcceptEntityInput(weaponIndex, "Kill");
	SpawnGrenadeOn(client);
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_martyrdom_enabled.BoolValue || !sm_martyrdom_always.BoolValue) //skip logic.
		return Plugin_Continue;
	int deadguy = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(deadguy)) //check for valid client 
		return Plugin_Continue;
	SpawnGrenadeOn(deadguy);
	return Plugin_Continue;
}

public void SpawnGrenadeOn(int client)
{
	float fSpawnLocation[3];
	GetClientEyePosition(client, fSpawnLocation);
	SpawnGrenadeOnLocation(client, fSpawnLocation);
}

public void SpawnGrenadeOnLocation(const int thrower, const float fLoc[3])
{
	//https://developer.valvesoftware.com/wiki/Hegrenade_projectile
	int entity = CreateEntityByName("hegrenade_projectile");
	if(entity == -1)
		return;//its dead jim!
	SetVariantString("OnUser1 !self,InitializeSpawnFromWorld,,0.0,1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	DispatchSpawn(entity); 
	SetEntPropEnt(entity, Prop_Data, "m_hThrower", thrower);
	SetEntProp(entity, Prop_Data, "m_iTeamNum", GetClientTeam(thrower));
	TeleportEntity(entity, fLoc, NULL_VECTOR, NULL_VECTOR);
}

/**
 * This function will check if we have a valid player
 **/
stock bool IsValidClient(int client,bool allowconsole=false)
{
	if(client == 0 && allowconsole)
	{
		return true;
	}
	if(client <= 0)
	{
		return false;
	}
	if(client > MaxClients)
	{
		return false;
	}
	if (!IsClientConnected(client)) 
	{ 
		return false; 
	} 
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(IsFakeClient(client))
	{
		return false;
	}
	return true;
}