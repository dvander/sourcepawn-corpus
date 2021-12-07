#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define g_sTankNorm	"models/infected/hulk.mdl"
#define g_sTankSac	"models/infected/hulk_dlc3.mdl"

public Plugin:myinfo = 
{
	name = "RandomTank",
	author = "Ludastar (Armonic)",
	description = "Just Adds the 50% Chance between each tank model",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/ArmonicJourney"
}

public OnPluginStart()
{	
	HookEvent("tank_spawn", eTankSpawn);
}

public OnMapStart()
{
	PrecacheModel(g_sTankNorm, true);
	PrecacheModel(g_sTankSac, true);
}


public eTankSpawn(Handle:hEvent, const String:sname[], bool:bDontBroadcast)
{
	new iTank =  GetEventInt(hEvent, "tankid");
	if(iTank > 0 && iTank <= MaxClients && IsClientInGame(iTank) && GetClientTeam(iTank) == 3 && IsPlayerAlive(iTank))
	{
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				SetEntityModel(iTank, g_sTankSac);
			}
			case 2:
			{
				SetEntityModel(iTank, g_sTankNorm);
			}
		}
	}
}
