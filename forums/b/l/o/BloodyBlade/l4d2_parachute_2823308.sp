#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PARACHUTE_MODEL "models/props_swamp/parachute01.mdl"

bool g_bParachute[MAXPLAYERS + 1] = {false, ...};
int g_iVelocity = -1, g_iParaEntRef[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Left 4 Parachute",
	author = "Joshe Gatito(edit. by BloodyBlade)",
	description = "Adds support for parachutes",
	version = "1.2",
	url = "https://steamcommunity.com/id/joshegatito/"
};

public void OnPluginStart()
{
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public void OnMapStart()
{
    PrecacheModel(PARACHUTE_MODEL);
    PrecacheModel(PARACHUTE_MODEL);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bParachute[client])
	{
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		float fOldSpeed = fVel[2];
		if(fVel[2] < 100.0 * -1.0) fVel[2] = 100.0 * -1.0;
		if(fOldSpeed != fVel[2]) TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
	}
	else
	{
		if(!(buttons & IN_USE) || !IsPlayerAlive(client)) return Plugin_Continue;
		if(GetEntityFlags(client) & FL_ONGROUND) return Plugin_Continue;

		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0) return Plugin_Continue;

		int iEntity = CreateEntityByName("prop_dynamic_override"); 
		DispatchKeyValue(iEntity, "model", PARACHUTE_MODEL);
		DispatchSpawn(iEntity);

		SetEntityMoveType(iEntity, MOVETYPE_NOCLIP);

		float ParachutePos[3], ParachuteAng[3];
		GetClientAbsOrigin(client, ParachutePos);
		GetClientAbsAngles(client, ParachuteAng);
		ParachutePos[2] += 80.0;
		ParachuteAng[0] = 0.0;

		TeleportEntity(iEntity, ParachutePos, ParachuteAng, NULL_VECTOR);

		SetEntPropFloat(iEntity, Prop_Data, "m_flModelScale", 0.4);

		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);

		g_iParaEntRef[client] = EntIndexToEntRef(iEntity);
		g_bParachute[client] = true;
	}
	return Plugin_Continue;
}

void DisableParachute(int client)
{
	int iEntity = EntRefToEntIndex(g_iParaEntRef[client]);
	if(iEntity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iEntity, "ClearParent");
		AcceptEntityInput(iEntity, "kill");
	}

	g_bParachute[client] = false;
	g_iParaEntRef[client] = INVALID_ENT_REFERENCE;
}