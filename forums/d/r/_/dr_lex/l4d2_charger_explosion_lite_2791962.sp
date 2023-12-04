#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"
#define ENTITY_OXYGEN	"models/props_equipment/oxygentank01.mdl"

bool bg_blockevent[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[L4D2] Charger Impact Explosion (lite)",
	author = "dr lex",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("charger_charge_end", Event_ChargerChargeEnd);
	HookEvent("ability_use", AbilityUse);
}

public void OnMapStart()
{
	CheckPrecacheModel("models/props_junk/propanecanister001a.mdl");
	CheckPrecacheModel("models/props_equipment/oxygentank01.mdl");
}

public void AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidCharger(client))
	{
		bg_blockevent[client] = true;
	}
}

public void Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidCharger(client))
	{
		if (bg_blockevent[client])
		{
			bg_blockevent[client] = false;
			float position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			Boom(position);
			Boom2(position);
		}
	}
}

public void CheckPrecacheModel(const char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model);
	}
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}

stock bool IsValidCharger(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 6)
		{
			return true;
		}
	}
	return false;
}

stock void Boom(float fxyz[3])
{
	int iEnt = CreateEntityByName("prop_physics", -1);
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "model", ENTITY_PROPANE);
		TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(iEnt);
		SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
		AcceptEntityInput(iEnt, "break", -1, -1, 0);
	}
}

stock void Boom2(float fxyz[3])
{
	int iEnt = CreateEntityByName("prop_physics", -1);
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "model", ENTITY_OXYGEN);
		TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(iEnt);
		SetEntData(iEnt, GetEntSendPropOffs(iEnt, "m_CollisionGroup"), 1, 1, true);
		AcceptEntityInput(iEnt, "break", -1, -1, 0);
	}
}