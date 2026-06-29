#include <sourcemod>
#include <sdktools>
#include <cstrike>

new g_BeamSprite;
new g_HaloSprite;

public Plugin:myinfo =
{
    name = "CT Circle",
    author = "Franc1sco franug",
    description = "",
    version = "1.0",
};

public OnPluginStart()
{	
	CreateTimer(0.1, Repetidor, _, TIMER_REPEAT);
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public Action:Repetidor(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
			SetupBeacon(i);
}

SetupBeacon(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	TE_SetupBeamRingPoint(vec, 50.0, 60.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, {255, 255, 255, 255}, 10, 0);
	TE_SendToAll();
}