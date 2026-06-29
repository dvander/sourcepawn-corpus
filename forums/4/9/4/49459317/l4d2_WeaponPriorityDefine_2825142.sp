#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

static const char g_sWeaponName[][] =
{
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_shotgun_spas",
	"weapon_rifle",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_rifle_sg552",
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_sniper_awp"
};

ArrayList g_aWeaponIndex;

public Plugin myinfo =
{
	name = "l4d2_WeaponPriorityDefine",
	author = "X光",
	description = "Bot Take Weapon Priority Define",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=348547"
};

public void OnPluginStart()
{
	g_aWeaponIndex = new ArrayList();
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
}

bool GetItemName(int entity)
{
	char sName[32];
	GetEntityClassname(entity, sName, sizeof sName);
	for (int i = 0; i < sizeof g_sWeaponName; i++)
	{
		if (strcmp(sName, "weapon_spawn") == 0 || StrContains(sName, g_sWeaponName[i]) != -1)
			return true;
	}

	return false;
}

bool IsOwnedT0Weapon(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon != -1)
	{
		char sName[32];
		GetEntityClassname(weapon, sName, sizeof sName);
		if (strcmp(sName, "weapon_rifle_m60") == 0 || strcmp(sName, "weapon_grenade_launcher") == 0)
			return true;
	}

	return false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntity(entity))
		return;

	if (StrContains(classname, "weapon_rifle_m60") != -1 || StrContains(classname, "weapon_grenade_launcher") != -1)
		RequestFrame(WeaponNextFrame, EntIndexToEntRef(entity));
}

void WeaponNextFrame(int entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
		return;

	g_aWeaponIndex.Push(EntIndexToEntRef(entity));
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntity(entity) || !IsValidEdict(entity))
		return;

	int index = g_aWeaponIndex.FindValue(entity);
	if (index != -1)
		g_aWeaponIndex.Erase(index);
}

public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	if (!item)
	{
		if (!IsOwnedT0Weapon(client))
		{
			int entity = -1;
			float ClientPos[3], ItemPos[3];
			GetClientAbsOrigin(client, ClientPos);
			for (int i = 0; i < g_aWeaponIndex.Length; i++)
			{
				entity = EntRefToEntIndex(g_aWeaponIndex.Get(i));
				if (IsValidEntity(entity))
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ItemPos);
					if (GetVectorDistance(ClientPos, ItemPos) < 500.0)
					{
						item = entity;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	else if (GetItemName(item))
	{
		if (IsOwnedT0Weapon(client))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

void Event_RoundStart(Event event, const char[] sName, bool bDontBroadcast)
{
	g_aWeaponIndex.Clear();
}