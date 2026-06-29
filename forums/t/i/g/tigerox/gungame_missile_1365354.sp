#include <gungame>
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "GunGame Missile",
	author = "TigerOx",
	description = "Allows GunGame:SM to work with Homing Missiles.",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:weapon[64];
	GetEventString(event,"weapon", weapon, 64);
	
	if(StrEqual(weapon, "env_explosion"))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		GG_GetLevelWeaponName(GG_GetClientLevel(attacker), weapon, 64);
		
		if(StrEqual(weapon, "hegrenade") && (GetClientOfUserId(GetEventInt(event, "victim")) != attacker))
		{
			GG_AddALevel(attacker);
		}
	}
}
