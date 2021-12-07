#include <sourcemod>
#include <sdktools>

#pragma newdecls required

// Teams
#define SPEC 1
#define TR 2
#define CT 3

// bool
bool b_enable;

public Plugin myinfo =
{
	name = "[CS:GO] Crazy Knife",
	author = "Kento from Akami Studio",
	version = "1.0",
	description = "Crazy Knife.",
	url = "http://steamcommunity.com/id/kentomatoryoshika"
};

public void OnPluginStart() 
{
	RegAdminCmd("sm_ck", Command_Enable, ADMFLAG_GENERIC, "Enable or disable Crazy knife.");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("item_pickup", Event_ItemPickUp);
}

public Action Command_Enable (int client, int args)
{
	if(b_enable)
	{
		PrintToChat(client, "Crazy knife has been disabled.");
		b_enable = false;
	}
	else if(!b_enable)
	{
		PrintToChat(client, "Crazy knife has been enabled.");
		b_enable = true;
	}
	return Plugin_Handled;
}

public Action Event_RoundStart(Handle event, const char[]name, bool dontBroadcast)
{
	// CK enabled
	if(b_enable)
	{
		PrintToChatAll("Crazy Knife Round!");
		
		// T Can't buy
		GameRules_SetProp("m_bTCantBuy", true, _, _, true);
		
		// Give CT 250 Health
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && (GetClientTeam(i) == CT))	SetEntityHealth(i, 250);
		}
	}
}

public Action Event_ItemPickUp(Handle event, const char[] name, bool dontBroadcast)
{
	char temp[32];
	GetEventString(event, "item", temp, sizeof(temp));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Player doesn't pickup knife
	if(b_enable && IsValidClient(client) && !StrEqual(temp, "weapon_knife") && (GetClientTeam(client) == TR))
	{
		// Remove primary weapon.
		int weapon_p = GetPlayerWeaponSlot(client, 0);
		if(weapon_p > 0)
		{
			RemovePlayerItem(client, weapon_p);
		}
		
		// Remove secondary weapon.
		int weapon_s = GetPlayerWeaponSlot(client, 1);
		if(weapon_s > 0)
		{
			RemovePlayerItem(client, weapon_s);
		}
		
		// Remove grenade.
		int weapon_g = GetPlayerWeaponSlot(client, 3);
		if(weapon_g > 0)
		{
			RemovePlayerItem(client, weapon_g);
		}
		
		// Remove C4.
		int weapon_c4 = GetPlayerWeaponSlot(client, 4);
		if(weapon_c4 > 0)
		{
			RemovePlayerItem(client, weapon_c4);
		}
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}