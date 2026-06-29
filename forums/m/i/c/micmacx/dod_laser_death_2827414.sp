#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Laser Death",
	description = "Player death have a laser between client and attacker",
	author = "Micmacx",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349100"
};
int ld_laser;

public void OnPluginStart()
{
	CreateConVar("dod_laser_death_version", PLUGIN_VERSION, "Player laser Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	ld_laser = PrecacheModel("materials/sprites/laser.vmt", false);

}

public Action Laser(Handle event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client && attacker && IsClientInGame(client) && !IsFakeClient(client) && client != attacker)
	{
		LaserPlayer(client, attacker);
	}
}

void LaserPlayer(int client, int attacker)
{
	float clientOrigin[3];
	float impactOrigin[3];
	float vAngles[3];
	float vOrigin[3];
	int listclients[1];
	listclients[0] = client;
	GetClientEyePosition(attacker, vOrigin);
	GetClientEyeAngles(attacker, vAngles);
	int color[4];
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(impactOrigin, trace);
		CloseHandle(trace);
		GetClientEyePosition(attacker, clientOrigin);
		clientOrigin[2] -= 1;
		color = {75,75,255,255};
		TE_SetupBeamPoints(clientOrigin, impactOrigin, ld_laser, 0, 0, 0, 5.0, 1.0, 1.0, 10, 0.0, color, 0);
		TE_Send(listclients, 1, 0.0);
	}
	else
	{
		CloseHandle(trace);
	}
}

public bool TraceEntityFilterPlayer(int entity, int ContentsMask)
{
	return entity > MaxClients;
} 