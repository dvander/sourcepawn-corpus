#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2] Revive Patch",
	author = "BHaType",
	description = "Allows you to revive a survivor even if it takes damage",
	version = "0.3",
	url = "N/A"
}

ConVar 	sv_revive_damage_interrupt;

public void OnPluginStart()
{
	sv_revive_damage_interrupt = CreateConVar("sv_revive_damage_interrupt", "0");

	GameData data = new GameData("l4d2_revive_gamedata");

	Address ptr = data.GetAddress("OnTakeDamage_Alive");
	int byte = LoadFromAddress(ptr, NumberType_Int8);
	
	if ( 0x0F == byte )
	{
		StoreToAddress(ptr, 0x90, NumberType_Int8);
		StoreToAddress(ptr + view_as<Address>(1), 0xE9, NumberType_Int8);
	}
	else if ( 0x90 != byte )
	{
		StoreToAddress(ptr, 0xEB, NumberType_Int8);
	}
	
	delete data;

	HookEvent("player_hurt", player_hurt);
}

void player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int damagetype = event.GetInt("type");

	if (!client || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return;

	if (sv_revive_damage_interrupt.IntValue & damagetype)
	{
		StopRevive(client);
	}
}

void StopRevive(int client)
{
	int reviver = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);

	if (reviver != -1)
	{
		SetEntPropFloat(reviver, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(reviver, Prop_Send, "m_flProgressBarDuration", 0.0);
		SetEntPropEnt(reviver, Prop_Send, "m_reviveTarget", -1);
	}
}