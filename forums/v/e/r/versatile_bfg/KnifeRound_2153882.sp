#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new bool:g_t_knife = false;
new g_iAccount = -1;

/* Plugin info */
#define SM_VERSION				"0.1"
#define SM_DESCRIPTION			"Knife Round"

public Plugin:myinfo = {
	name = "Knife Round [BFG]",
	author = "Versatile_BFG",
	description = SM_DESCRIPTION,
	version = SM_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	RegAdminCmd("kniferound", KnifeOn3, ADMFLAG_CUSTOM1, "Remove all weapons except knife on next round start");
	RegAdminCmd("knife", KnifeOn3, ADMFLAG_CUSTOM1, "Remove all weapons except knife on next round start");
	HookEvent("round_start", Event_Round_Start);
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public Action:KnifeOn3(client, args)
{
	g_t_knife = true;
	PrintToChatAll("Next Round is a Knife Round");
	return Action:3;
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_t_knife)
	{
		// give player specified grenades
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1)
			{
				SetEntData(i, g_iAccount, 0);
				CS_StripButKnife(i);
			}
		}
	}
	g_t_knife = false;
}

/**
 *  strip all weapons from specified client but the knife
 * 
 * @noreturn
 */

stock CS_StripButKnife(client, bool:equip=true)
{
	if (!IsClientInGame(client) || GetClientTeam(client) <= 1)
	{
		return false;
	}
	
	new item_index;
	for (new i = 0; i < 5; i++)
	{
		if (i == 2)
		{
			continue;
		}
		if ((item_index = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, item_index);
			RemoveEdict(item_index);
		}
		if (equip)
		{
			CS_EquipKnife(client);
		}
	}

	return true;
}

/**
 *  equip the specified client with the knife
 * 
 * @noreturn
 */

stock CS_EquipKnife(client)
{
	ClientCommand(client, "slot3");
}