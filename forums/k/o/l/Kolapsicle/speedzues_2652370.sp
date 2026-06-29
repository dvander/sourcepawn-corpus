#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Speed Zues", 
	author = "Kolapsicle", 
	description = "Increases player movement speed when a Zues is fired.", 
	version = "1.0"
};

ConVar g_cvVelocity;

public void OnPluginStart()
{
	g_cvVelocity = CreateConVar("sm_zues_velocity", "500.0", "Movement speed modifier.");
	HookEvent("weapon_fire", Event_WeaponFire);
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	char classname[32];
	event.GetString("weapon", classname, sizeof(classname));
	if (!StrEqual("weapon_taser", classname))
	{
		return Plugin_Continue;
	}
	
	ApplyFowardVelocity(client, GetConVarFloat(g_cvVelocity));
	return Plugin_Continue;
}

void ApplyFowardVelocity(int client, float increase)
{
	float angle[3], fwd[3], vel[3];
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, fwd, NULL_VECTOR, NULL_VECTOR);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	
	vel[0] += increase * fwd[0];
	vel[1] += increase * fwd[1];
	vel[2] += increase * fwd[2];
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 