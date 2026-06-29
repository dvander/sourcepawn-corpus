#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:g_Cvar_DropAll = INVALID_HANDLE;
new Handle:g_Cvar_DropKnife = INVALID_HANDLE;
new g_AmmoOffset = -1;

public Plugin:myinfo =
{
	name = "Drop on Death",
	author = "bigbalaboom",
	description = "Drop all weapons on death.",
	version = "1.0.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	g_Cvar_DropAll = CreateConVar("sm_drop_all_on_death", "1", "Enables/Disables dropping all weapons on death.");
	g_Cvar_DropKnife = CreateConVar("sm_drop_knife_on_death", "0", "Enables/Disables dropping knife on death.");

	g_AmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(g_Cvar_DropAll) && IsClientInGame(client) && GetClientHealth(client) <= 0)
	{
		new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		decl String:active_weapon_name[64];
		GetEdictClassname(active_weapon, active_weapon_name, sizeof(active_weapon_name));

		new slot2, slot3;

		if ((slot2 = GetPlayerWeaponSlot(client, _:1)) != -1)
		{
			CS_DropWeapon(client, slot2, false);
		}

		if ((slot3 = GetPlayerWeaponSlot(client, _:2)) != -1 && GetConVarInt(g_Cvar_DropKnife))
		{
			CS_DropWeapon(client, slot3, false);
		}

		new number_of_hegrenades = GetEntData(client, g_AmmoOffset + 44);
		if (StrEqual(active_weapon_name, "weapon_hegrenade"))
		{
			number_of_hegrenades -= 1;
		}

		new number_of_flashbangs = GetEntData(client, g_AmmoOffset + 48);
		if (StrEqual(active_weapon_name, "weapon_flashbang"))
		{
			number_of_flashbangs -= 1;
		}

		new number_of_smokegrenades = GetEntData(client, g_AmmoOffset + 52);
		if (StrEqual(active_weapon_name, "weapon_smokegrenade"))
		{
			number_of_smokegrenades -= 1;
		}

		new slot4;
		while((slot4 = GetPlayerWeaponSlot(client, _:3)) != -1)
		{
			CS_DropWeapon(client, slot4, false);
			RemoveEdict(slot4);
		}

		SpawnWeapon(client, "weapon_hegrenade", number_of_hegrenades);
		SpawnWeapon(client, "weapon_flashbang", number_of_flashbangs);
		SpawnWeapon(client, "weapon_smokegrenade", number_of_smokegrenades);
	}
}

SpawnWeapon(client, const String:weapon[], amount)
{
	if (!amount)
	{
		return;
	}

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);

	for (new i = 0; i < amount; i++)
	{
		new entity = CreateEntityByName(weapon);
		vec[2] += 30;
		DispatchSpawn(entity);
		TeleportEntity(entity, vec, NULL_VECTOR, NULL_VECTOR);
	}
}