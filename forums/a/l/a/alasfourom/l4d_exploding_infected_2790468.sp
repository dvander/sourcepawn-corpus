#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int g_iBeam;
int g_iHalo;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
	g_iBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int infected = GetClientOfUserId (event.GetInt("userid"));
	if (!infected || !IsClientInGame(infected) || GetClientTeam(infected) != 3) return;
	
	Explosion(infected);
	BeamLight(infected);
}

void Explosion(int client)
{
	int entity = CreateEntityByName("prop_physics");
	if (!IsValidEntity(entity)) return;
	
	float vPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
	
	DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "break");
}

void BeamLight(int client)
{
	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	vPos[2] += 20.0;
	
	TE_SetupBeamRingPoint(vPos, 10.0, 350.0, g_iBeam, g_iHalo, 0, 10, 1.5, 3.0, 0.5, {160, 160, 160, 80}, 400, 0);
	TE_SendToAll();
}