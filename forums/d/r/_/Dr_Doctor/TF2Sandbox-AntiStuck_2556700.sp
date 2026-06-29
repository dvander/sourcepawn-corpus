#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <build>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] SandBox - AntiStuck",
	author = PLUGIN_AUTHOR,
	description = "Antistuck System for TF2SB",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

Handle g_hEnabled;
Handle g_hAutoUnstuck;

bool g_bIN_ATTACK[MAXPLAYERS + 1] = false;

public void OnPluginStart()
{
	CreateConVar("sm_tf2sb_antistuck_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_tf2sb_antistuck", "1", "Enable the AntiStuck System?", 0, true, 0.0, true, 1.0);
	g_hAutoUnstuck = CreateConVar("sm_tf2sb_unstuckmode", "1", "Mode 0 = Disable Auto unstuck, Mode 1 = Enable Auto unstuck", 0, true, 0.0, true, 1.0);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{	
	if(!IsValidClient(client))
		return Plugin_Continue;
		
	if(GetConVarInt(g_hAutoUnstuck) == 1)
	{
		if(buttons & IN_ATTACK)
			g_bIN_ATTACK[client] = true;
		else
			g_bIN_ATTACK[client] = false;
	}
	
	if(GetConVarBool(g_hEnabled))
	{
		for(int ent = 0; ent < MAX_HOOK_ENTITIES; ent++)
		{
			if(IsValidEdict(ent) && !IsValidClient(ent))
			{
				int EntityOwner = -1;
				EntityOwner = Build_ReturnEntityOwner(ent);
				if(IsValidClient(EntityOwner))
				{
					char szClass[128];
					GetEdictClassname(ent, szClass, sizeof(szClass));
					if((StrContains(szClass, "prop_dynamic") >= 0 || StrContains(szClass, "prop_physics") >= 0) && !StrEqual(szClass, "prop_ragdoll"))
					{
						if(IsValidClient(client) && IsPlayerAlive(client) && IsPlayerStuckInEnt(client, ent) && GetEntityMoveType(client) != MOVETYPE_NOCLIP)
						{
							if(!g_bIN_ATTACK[EntityOwner])
							{
								if(GetConVarInt(g_hAutoUnstuck) == 1)
								{
									float iPosition[3]; 
									GetClientEyePosition(client, iPosition);
									iPosition[0] += 0.001;
									TeleportEntity(client, iPosition, NULL_VECTOR, NULL_VECTOR);
								}
							}
							AcceptEntityInput(ent, "DisableCollision");
						}
						else if(!IsPlayerStuckInEnt(client, ent))
						{	
							AcceptEntityInput(ent, "EnableCollision");
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}	

//-------------[	Stock	]---------------------------------------------------
stock bool IsPlayerStuckInEnt(int client, int ent)
{
	float vecMin[3], vecMax[3], vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
	
	GetClientAbsOrigin(client, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_ALL, TraceRayHitOnlyEnt, ent);
	return TR_DidHit();
}

public bool TraceRayHitOnlyEnt(int entity, int contentsMask, any data) 
{
	return entity==data;
}

stock bool IsValidClient(int client) 
{ 
    if(client <= 0 ) return false; 
    if(client > MaxClients) return false; 
    if(!IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}