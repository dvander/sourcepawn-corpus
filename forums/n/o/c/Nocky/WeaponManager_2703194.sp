#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int g_iArmor, g_iHelmet, g_iKnife;

char Path[PLATFORM_MAX_PATH], ItemName[128], PrimaryWeapon[128], SecondaryWeapon[128];

public Plugin myinfo = 
{
	name = "Weapon Manager", 
	author = "Nocky", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/nockys"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	BuildPath(Path_SM, Path, sizeof(Path), "configs/WeaponManager.cfg");
}

public void OnMapStart()
{
	KeyValues kv = new KeyValues("WManager");
	kv.ImportFromFile(Path);
	
	if (!FileExists(Path))
	{
		SetFailState("Configuration file %s is not found", Path);
		return;
	}
	if (!kv.GotoFirstSubKey())
	{
		SetFailState("In configuration file %s is errors", Path);
		return;
	}
	do
	{
		kv.GetSectionName(ItemName, sizeof(ItemName));
		kv.GetString("Primary weapon", PrimaryWeapon, sizeof(PrimaryWeapon));
		kv.GetString("Secondary weapon", SecondaryWeapon, sizeof(SecondaryWeapon));
		g_iArmor = kv.GetNum("Armor", 1);
		g_iHelmet = kv.GetNum("Helmet", 1);
		g_iKnife = kv.GetNum("Knife", 1);
		
	} while (kv.GotoNextKey());
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GiveWeapon(client);
}

public void OnGamePlayerEquipSpawn(int entity)
{
	if (GetEntProp(entity, Prop_Data, "m_spawnflags") & 1)
	{
		return;
	}
	SetEntProp(entity, Prop_Data, "m_spawnflags", 4);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "game_player_equip"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnGamePlayerEquipSpawn);
	}
}

void GiveWeapon(int client)
{
	if (IsClientValid(client) && IsPlayerAlive(client))
	{
		DisarmPlayer(client);
		GivePlayerItem(client, PrimaryWeapon);
		GivePlayerItem(client, SecondaryWeapon);
		if (g_iArmor == 1)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
		}
		if (g_iHelmet == 1)
		{
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
		}
		if (g_iKnife == 1)
		{
			GivePlayerItem(client, "weapon_knife");
		}
	}
}

stock int DisarmPlayer(int client)
{
	int length = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < length; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "KillHierarchy");
		}
	}
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
}

stock bool IsClientValid(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	return false;
} 