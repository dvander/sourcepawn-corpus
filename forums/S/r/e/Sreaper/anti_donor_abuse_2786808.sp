#include <sdkhooks>
#include <tf2_stocks>
#include <datapack>

#pragma semicolon 1
#pragma newdecls required

#define SOUND_SAPPER_NOISE "weapons/sapper_timer.wav"
#define SOUND_SAPPER_PLANT "weapons/sapper_plant.wav"

bool g_NoDamage[MAXPLAYERS + 1] = { false, ... };
// native bool Godmode_GetStatus(int client);
public Plugin myinfo =
{
	name        = "[TF2] Anti Donor Abuse",
	description = "Prevents resized and kartified players from damaging others",
	author      = "Banshee, Sreaper, Malifox",
	version     = "1.1.01",
	url         = "https://FirePowered.org"
};

public void OnPluginStart()
{
	HookEvent("player_sapped_object", Object_Sapped);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_NoDamage[i] = false;
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_NoDamage[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnEntityCreated(int building, const char[] classname)
{
	if (StrEqual(classname, "obj_sentrygun", false) || StrEqual(classname, "obj_dispenser", false) || StrEqual(classname, "obj_teleporter", false))
		SDKHook(building, SDKHook_Spawn, OnEntitySpawned);
}

public void OnEntitySpawned(int building)
{
	SDKHook(building, SDKHook_OnTakeDamage, BuildingTakeDamage);
}

public Action Object_Sapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int sapper = event.GetInt("sapperid");
	float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");

	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteCell(sapper);
	data.WriteCell(scale);
	
	RequestFrame(delay, data);
	LogDebug("%N was prevented from sapping a building while resized.", client);

	return Plugin_Continue;
}

void delay(DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int sapper = data.ReadCell();
	int scale = data.ReadCell();
	data.Close();

	if (scale != 1.0 && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "\x04[SM] \x01You cannot sap buildings while resized.");
		StopSound(sapper, 1, SOUND_SAPPER_NOISE);
		StopSound(sapper, 1, SOUND_SAPPER_PLANT);
		RemoveEntity(sapper);
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_HalloweenKart)
	{
		g_NoDamage[client] = true;
	}

	// Check for healing in god mode
	if (condition != TFCond_Healing && condition != TFCond_Overhealed)
	{
		return;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (TF2_GetPlayerClass(i) != TFClass_Medic)
			{
				continue;
			}
			int weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if (weapon == -1 || GetPlayerWeaponSlot(i, 1) != weapon)
			{
				continue;
			}
			int healingTarget = GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
			if (healingTarget == client && (GetEntProp(i, Prop_Data, "m_takedamage") == 1 || GetEntProp(i, Prop_Data, "m_takedamage") == 0))
			{
				LogDebug("%N prevented from healing %N", i, healingTarget);
				TF2_RemoveCondition(client, TFCond_Healing);
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_HalloweenKart)
	{
		g_NoDamage[client] = false;
	}
}

public Action BuildingTakeDamage(int building, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (attacker < 1 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	if (attacker > 0 && attacker <= MaxClients)
	{
		float scale = GetEntPropFloat(attacker, Prop_Send, "m_flModelScale");
		if (scale != 1.0)
		{
			damage = 0.0;
			LogDebug("%N was prevented from doing building damage while resized.", attacker);
			PrintToChat(attacker, "\x04[SM] \x01You cannot damage buildings while resized.");

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (victim == attacker)
	{
		return Plugin_Continue;
	}
	if (attacker > 0 && attacker <= MaxClients && !CheckCommandAccess(attacker, "sm_admin", ADMFLAG_GENERIC))
	{
		float scale = GetEntPropFloat(attacker, Prop_Send, "m_flModelScale");
		if (g_NoDamage[attacker])
		{
			LogDebug("%N was prevented from doing damage in kart", attacker);
			PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while in a kart.");
			return Plugin_Handled;
		}
		if (scale != 1.0)
		{
			LogDebug("%N was prevented from doing damage while resized", attacker);
			PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while resized.");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void LogDebug(const char[] format, any...)
{
#if defined DEBUG
	char buffer[128];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogError("[ANTI DONOR ABUSE] %s", buffer);
#endif
}