#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

new iSpottedOffset, bool:InDuck[MAXPLAYERS+1];

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name = "[ZR] Zombie Invisibility",
	author = "FrozDark (HLModders LLC)",
	description = "Zombie Invisibility",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	iSpottedOffset = FindSendPropOffs("CCSPlayerResource", "m_bPlayerSpotted");
}

public OnMapStart()
{
	SDKHook(FindEntityByClassname(-1, "cs_player_manager"), SDKHook_ThinkPost, OnThinkPost);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnClientDisconnect_Post(client)
{
	InDuck[client] = false;
}

public OnThinkPost(entity)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (InDuck[target]) SetEntData(entity, iSpottedOffset + target, false, 1, true);
	}
}

public OnPostThinkPost(client)
{
	static bool:OldState[MAXPLAYERS+1];
	static OldAlpha[MAXPLAYERS+1] = {-1, ...};
	if (!IsPlayerAlive(client) || !ZR_IsClientZombie(client))
	{
		if (InDuck[client])
		{
			InDuck[client] = false;
			OldAlpha[client] = -1;
		}
		return;
	}
	InDuck[client] = bool:((GetEntityFlags(client) & FL_ONGROUND) && bool:GetEntProp(client, Prop_Send, "m_bDucked", 1));
	
	if (OldState[client] != InDuck[client])
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		if (InDuck[client])
		{
			//SetEntityAlpha(client, 0);
			SetEntityRenderFx(client, RENDERFX_FADE_SLOW);
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (IsValidEdict(weapon))
			{
				OldAlpha[client] = GetEntityAlpha(weapon);
				SetEntityAlpha(weapon, 0);
			}
		}
		else
		{
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SetEntityRenderFx(client, RENDERFX_NONE);
			if (OldAlpha[client] != -1)
			{
				//SetEntityAlpha(client, OldAlpha[client]);
				if (IsValidEdict(weapon))
				{
					SetEntityAlpha(weapon, OldAlpha[client]);
				}
			}
			else
			{
				//SetEntityAlpha(client);
				if (IsValidEdict(weapon))
				{
					SetEntityAlpha(weapon);
				}
			}
		}
	}
	
	OldState[client] = InDuck[client];
}

stock SetEntityAlpha(entity, alpha = 255)
{
	new offset = GetEntSendPropOffs(entity, "m_clrRender");
	if (offset > 0)
	{
		SetEntData(entity, offset + 3, alpha, 4, true);
	}
}

stock GetEntityAlpha(entity)
{
	new offset = GetEntSendPropOffs(entity, "m_clrRender");
	if (offset > 0)
	{
		return GetEntData(entity, offset + 3);
	}
	return -1;
}