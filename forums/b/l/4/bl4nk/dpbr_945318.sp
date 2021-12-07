#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.3"

public Plugin:myinfo =
{
	name = "Demoman Pipebomb Remover",
	author = "bl4nk",
	description = "Removes demomen pipebombs when a player changes team to spectator",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("dpbr_version", PLUGIN_VERSION, "DPBR Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_team", Event_PlayerTeam);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && GetEventInt(event, "team") == 1)
	{
		new aEnts[32], iCount;
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_DemoMan:
			{
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_pipe")) != -1)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hThrower") == client)
					{
						aEnts[iCount++] = ent;
					}
				}
			}
			case TFClass_Soldier:
			{
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_rocket")) != -1)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
					{
						aEnts[iCount++] = ent;
					}
				}
			}
			case TFClass_Sniper:
			{
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_arrow")) != -1)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
					{
						aEnts[iCount++] = ent;
					}
				}
			}
			case TFClass_Medic:
			{
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_syringe")) != -1)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
					{
						aEnts[iCount++] = ent;
					}
				}
			}
			case TFClass_Pyro:
			{
				new ent = -1;
				while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != -1)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
					{
						aEnts[iCount++] = ent;
					}
				}
			}
		}

		if (iCount > 0)
		{
			for (new i = 0; i < iCount; i++)
			{
				RemoveEdict(aEnts[i]);
			}
		}
	}
}