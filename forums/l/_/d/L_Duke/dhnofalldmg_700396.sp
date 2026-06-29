#pragma semicolon 1
#include <sourcemod>
#include <dukehacks>

#define PLUGIN_VERSION "0.0.1.7"

public Plugin:myinfo = 
{
	name = "no fall damage",
	author = "L. Duke",
	description = "prevent fall damage",
	version = PLUGIN_VERSION,
	url = "www.LDuke.com"
}

new Handle:cvFallDmg = INVALID_HANDLE;
new bool:gBlockFallDamage = true;

public OnPluginStart()
{
	// setup convars
	CreateConVar("sm_nofalldmg_version", PLUGIN_VERSION, "damage mod version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvFallDmg = CreateConVar("sm_nofalldmg", "1", "prevent fall damage (1=on 0=off)");
	HookConVarChange(cvFallDmg, cvChanged);
	
	// register the TakeDamageHook function to be notified of damage
	dhAddClientHook(CHK_TakeDamage, TakeDamageHook);
}

// Note that damage is BEFORE modifiers are applied by the game for
// things like crits, hitboxes, etc.  The damage shown here will NOT
// match the damage shown in player_hurt (which is after crits, hitboxes,
// etc. are applied).
public Action:TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{
	if (gBlockFallDamage)
	{
		if (damagetype & DMG_FALL)
		{
			// block damage
			return Plugin_Stop;
		}
	}
	
	// not a fall or not on, let game continue with damage
	return Plugin_Continue;
}

// update gBlockFallDamage when convar changes
public cvChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue)==1)
	{
		gBlockFallDamage = true;
	}
	else
	{
		gBlockFallDamage = false;
	}
}

