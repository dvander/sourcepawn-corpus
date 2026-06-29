#include <zombiereloaded>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION   "[ZR] 1.0"

public Plugin:myinfo =
{
	name = "[ZR] Show nickname on HUD",
	author = "Graffiti & Oshizu",
	description = "Show nickname on HUD for CSGO",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_show_nickname_on_hud_version", PLUGIN_VERSION, "Show nickname on HUD", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CreateTimer(0.5, Timer, _, TIMER_REPEAT);
}

public Action:Timer(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new target = GetClientAimTarget(i) 
			if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
			{
				if(!IsPlayerAlive(i) || ZR_IsClientHuman(i) == ZR_IsClientHuman(target) || ZR_IsClientZombie(i) == ZR_IsClientZombie(target))
					PrintHintText(i, "Player: \"%N\"", target);
			}
		}
	}
	return Plugin_Continue; 
}