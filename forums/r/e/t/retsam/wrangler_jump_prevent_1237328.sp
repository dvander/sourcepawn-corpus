/*
* Engie Wrangler Jump Prevention (TF2) 
* Author(s): retsam
* File: wrangler_jump_prevent.sp
* Description: Prevents engies from rocket jumping with wrangler and getting into some spots they shouldnt.
*
*
* 0.4 - Changed damage check slightly. Put default velocity to 0.1.
* 0.3 - Added a velocity multiplier cvar. Velocity may now be changed to servers liking. Removed tf2 stocks as its not needed.
* 0.2 - Removed SDKhooks part.
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.4"

new Handle:Cvar_WJP_Enabled = INVALID_HANDLE;
new Handle:Cvar_WJP_Vel = INVALID_HANDLE;

new Float:g_fcvarVelocity;

new bool:g_bIsEnabled = true;

public Plugin:myinfo = 
{
	name = "WranglerJump Prevent",
	author = "retsam",
	description = "Prevents engies from rocket jumping with wrangler and getting into some spots they shouldnt.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=132222"
}

public OnPluginStart()
{
	CreateConVar("sm_wjp_version", PLUGIN_VERSION, "Version of WranglerJump Prevent", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_WJP_Enabled = CreateConVar("sm_wjp_enabled", "1", "Enable wrangler jump prevent plugin?(1/0 = yes/no)");
	Cvar_WJP_Vel = CreateConVar("sm_wjp_velocity", "0.1", "Velocity multiplier for calculation. (0.1 = 10%, 1.0 = 100% of original velocity)");

	HookEvent("player_hurt", Hook_PlayerHurt);

	HookConVarChange(Cvar_WJP_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_WJP_Vel, Cvars_Changed);
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_WJP_Enabled);
	g_fcvarVelocity = GetConVarFloat(Cvar_WJP_Vel);
}

public Hook_PlayerHurt(Handle:event,  const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(victim < 1 || victim > MaxClients)
	return;
	
	if(attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker))
	return;
	
	new damage = GetEventInt(event, "damageamount");
	
	//PrintToChatAll("Damage amount is: %i", damage);
	
	if(attacker == victim)
	{
		decl String:sWeapon[32];
		GetClientWeapon(victim, sWeapon, sizeof(sWeapon));
		//GetEventString(event, "weaponid", sWeapon, sizeof(sWeapon));
		
		//PrintToChatAll("Victim weapon is: %s", sWeapon);
		if(damage > 20 && StrEqual(sWeapon, "tf_weapon_laser_pointer", false))
		{
			//PrintToChatAll("Player shot himself with sentrygun rocket!");
			
			decl Float:fVelocity[3];
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", fVelocity);
			//PrintToChatAll("Player velocity is: %f", fVelocity);
			
			fVelocity[0] = fVelocity[0] * g_fcvarVelocity;
			fVelocity[1] = fVelocity[1] * g_fcvarVelocity;
			fVelocity[2] = fVelocity[2] * g_fcvarVelocity;
			
			//PrintToChatAll("Changed velocity is: %f", fVelocity);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
}

/*
public OnTakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype)
{
	if(!g_bIsEnabled)
	return;

	//PrintToChatAll("Victim: %i | Attacker: %i| Inflictor: %i | DMG: %f | DamageType: %i",victim,attacker,inflictor,damage,damagetype);

	if(attacker > 0 && attacker <= MaxClients)
	{ 
		if(IsClientInGame(attacker) && attacker == victim)
		{
			//decl String:sInflictor[32];
			//GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));
			//PrintToChatAll("Inflictor is: %s", sInflictor);
			decl String:sWeapon[32];
			GetClientWeapon(victim, sWeapon, sizeof(sWeapon));
			//PrintToChatAll("Victim weapon is: %s", sWeapon);
			if(damagetype & 2359360 && StrEqual(sWeapon, "tf_weapon_laser_pointer"))
			{
				//PrintToChatAll("Player shot himself with sentrygun rocket!");
				
				decl Float:fVelocity[3];
				fVelocity[2] = 1.000000;
				
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, fVelocity);
			}
		}
	}
}
*/

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_WJP_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_WJP_Vel)
	{
		g_fcvarVelocity = StringToFloat(newValue);
	}
}
