/******************************************************************************
	WTCG: Woody's Tree Classic Game
*******************************************************************************
	Requires SourceMod extension "SDK Hooks" by DJ Tsunami:
	http://forums.alliedmods.net/showthread.php?t=106748
*******************************************************************************
TODO 
This plugin provides classic style HL2DM gaming by preventing grav nades and
fast orbs.
Version 2 is a complete rewrite using a totally different approach.
More details after beta phase...
TODO
******************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0-beta2"
#define MY_CLASSNAME_MAX_LEN 32



/******************************************************************************

	P L U G I N   I N F O

******************************************************************************/

public Plugin:myinfo =
{
	name = "WTCG: Woody's Tree Classic Game",
	author = "Woody",
	description = "prevents the use of grav nades and fast orbs",
	version = PLUGIN_VERSION,
	url = "http://woodystree.net"
};



/******************************************************************************

	G L O B A L   V A R S

******************************************************************************/

new bool:g_bPhyscannon[MAXPLAYERS + 1] = {false, ...};



/******************************************************************************

	F O R W A R D S

******************************************************************************/

public OnPluginStart()
{
	CreateConVar("wtcg_version", PLUGIN_VERSION, "the version of WTCG: Woody's Tree Classic Game", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}



public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "npc_grenade_frag"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_NPCGrenadeFrag);
	}
	else if (StrEqual(classname, "prop_combine_ball"))
	{
		SDKHook(entity, SDKHook_VPhysicsUpdate, OnVPhysicsUpdate_PropCombineBall);
	}
}



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_bPhyscannon[client])
	{
		if (buttons & IN_ATTACK2)
		{
			new target = GetClientAimTarget(client, false);
			
			if (IsValidEntity(target))
			{
				decl String:targetClassname[MY_CLASSNAME_MAX_LEN];
				GetEntityClassname(target, targetClassname, sizeof(targetClassname));
				
				if (StrEqual(targetClassname, "npc_grenade_frag"))
				{
					new owner = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
					
					if (client == owner)
					{
						NoGravNades(client, target);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}



/******************************************************************************

	S D K H O O K S   C A L L B A C K S

******************************************************************************/

public Action:OnWeaponSwitch(client, weapon)
{
	decl String:weaponClassname[MY_CLASSNAME_MAX_LEN];
	GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));
	
	if (StrEqual(weaponClassname, "weapon_physcannon"))
	{
		g_bPhyscannon[client] = true;
	}
	else
	{
		g_bPhyscannon[client] = false;
	}
	
	return Plugin_Continue;
}



public Action:OnTakeDamage_NPCGrenadeFrag(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_PHYSGUN)
	{
		new owner = GetEntPropEnt(victim, Prop_Send, "m_hOwnerEntity");
		
		if (owner == attacker)
		{
			NoGravNades(attacker, victim);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}



public OnVPhysicsUpdate_PropCombineBall(entity)
{
	decl Float:vecVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelocity);
	
	decl Float:velocity;
	velocity = GetVectorLength(vecVelocity);
	
	if (FloatCompare(velocity, 1000.0) == 1) // i.e. if velocity > 1000
	{
		decl Float:adjustmentFactor;
		adjustmentFactor = FloatDiv(1000.0, velocity);
		
		ScaleVector(vecVelocity, adjustmentFactor);
		
		SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vecVelocity);
	}
}



/******************************************************************************

	I N T E R N A L

******************************************************************************/

NoGravNades(client, entity)
{
	AcceptEntityInput(entity, "KillHierarchy");
	PrintCenterText(client, "NO GRAV NADES !!!");
}

