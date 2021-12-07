/**
 * WTCG: Woody's Tree Classic Game
 * ===============================
 *
 * This plugin provides classic style HL2DM gaming by preventing grav nades	and
 * fast orbs (or speed balls or whatever you call them):
 * 		-	For every grav nade the plugin checks the owner of the grenade and
 * 			if he/she equals the physcannon user. If so, NO GO.
 * 		-	The speed of fast orbs is checked regularly and set back to normal
 * 			when above.
 *
 * Note: requires the "SDK Hooks" extension, which is included with SourceMod
 * version 1.5 and later.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0.2"



/*==============================================================================

	P L U G I N   I N F O

==============================================================================*/

public Plugin:myinfo =
{
	name = "WTCG: Woody's Tree Classic Game",
	author = "Woody",
	description = "prevents the use of grav nades and fast orbs",
	version = PLUGIN_VERSION,
	url = "http://woodpecker.de"
};



/*==============================================================================

	G L O B A L   V A R S

==============================================================================*/

new g_grenade[MAXPLAYERS + 1] = {0, ...};
new g_physcannon[MAXPLAYERS + 1] = {0, ...};

new bool:g_bIsMapRunning = false;



/*==============================================================================

	F O R W A R D S

==============================================================================*/

public OnPluginStart()
{
	CreateConVar("wtcg_version", PLUGIN_VERSION, "the version of WTCG: Woody's Tree Classic Game", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



public OnMapStart()
{
		g_bIsMapRunning = true;
}



public OnMapEnd()
{
		g_bIsMapRunning = false;
}



public OnClientPutInServer(client)
{
	g_grenade[client] = 0;
	g_physcannon[client] = 0;

	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}




public OnEntityCreated(entity, const String:classname[])
{
	if (g_bIsMapRunning)
	{
		if (StrEqual(classname, "npc_grenade_frag"))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
		}
		else if (StrEqual(classname, "prop_combine_ball"))
		{
			SDKHook(entity, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
		}
	}
}



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_physcannon[client])
	{
		new attachedEntity = GetEntPropEnt(g_physcannon[client], Prop_Send, "m_hAttachedObject");

		if (attachedEntity == g_grenade[client])
		{
			NoGravNades(client, attachedEntity);
		}
	}

	return Plugin_Continue;
}



/*==============================================================================

	C A L L B A C K S

==============================================================================*/

public Action:OnWeaponSwitch(client, weapon)
{
	decl String:weaponClassname[MAX_NAME_LENGTH];
	GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

	if (StrEqual(weaponClassname, "weapon_physcannon"))
	{
		g_physcannon[client] = weapon;
	}
	else
	{
		g_physcannon[client] = 0;
	}

	return Plugin_Continue;
}



/**
 * Note: only hooked for "npc_grenade_frag" entities.
 */
public OnSpawnPost(grenade)
{
	new owner = GetEntPropEnt(grenade, Prop_Send, "m_hOwnerEntity");
	g_grenade[owner] = grenade;

	SDKHook(grenade, SDKHook_OnTakeDamage, OnTakeDamage);
}



/**
 * Note: only hooked for "npc_grenade_frag" entities.
 */
public Action:OnTakeDamage(grenade, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_PHYSGUN)
	{
		if (g_grenade[attacker] == grenade)
		{
			NoGravNades(attacker, grenade);
		}
	}

	return Plugin_Continue;
}



/**
 * Note: only hooked for "prop_combine_ball" entities.
 */
public OnVPhysicsUpdatePost(combineBall)
{
	decl Float:vecVelocity[3];
	GetEntPropVector(combineBall, Prop_Data, "m_vecAbsVelocity", vecVelocity);

	decl Float:velocity;
	velocity = GetVectorLength(vecVelocity);

	if (FloatCompare(velocity, 1000.0) == 1) // i.e. if velocity > 1000
	{
		decl Float:adjustmentFactor;
		adjustmentFactor = FloatDiv(1000.0, velocity);

		ScaleVector(vecVelocity, adjustmentFactor);

		TeleportEntity(combineBall, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	}
}



/*==============================================================================

	I N T E R N A L

==============================================================================*/

NoGravNades(client, grenade)
{
	AcceptEntityInput(grenade, "KillHierarchy");
	PrintCenterText(client, "NO GRAV NADES !!!");

	g_grenade[client] = 0;
}
