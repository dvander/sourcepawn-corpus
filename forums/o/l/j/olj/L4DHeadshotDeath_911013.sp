#define PLUGIN_VERSION "1.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "",
	author = "Olj",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("player_hurt", HurtEvent, EventHookMode_Pre);
}

public Action:HurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim ==0 || attacker == 0) return Plugin_Continue;
	if (GetClientTeam(attacker)==2&&GetClientTeam(victim)==2)
		{
			if (GetEventInt(event, "hitgroup")==1)
				{
					new dmgtype = GetEventInt(event, "type");
					if (dmgtype != 64 || dmgtype != 8 || dmgtype != 2056)
						{
							ForcePlayerSuicide(victim);
							return Plugin_Continue;
						}
				}
		}
	return Plugin_Continue;
}