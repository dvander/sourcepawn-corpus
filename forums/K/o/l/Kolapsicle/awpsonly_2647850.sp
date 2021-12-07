#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo =  {
	name = "AWPs Only", 
	author = "Kolapsicle", 
	description = "Spawns players with AWPs, and disables buy zones.", 
	version = "1.0"
};

#define WEAPON_KNIFE 2
#define WEAPON_C4 4

ConVar cvBuyZones, cvRemoveKnives, cvRemoveC4, cvWeaponOverride;
ArrayList alBuyZones;

public void OnPluginStart()
{
	cvBuyZones = CreateConVar("sm_awpsonly_enable_buyzones", "0", "Enables buy zones.");
	if (cvBuyZones != null)
	{
		cvBuyZones.AddChangeHook(onBuyZonesChanged);
	}
	
	cvRemoveKnives = CreateConVar("sm_awpsonly_remove_knives", "0", "Removes knives from players when spawned.");
	cvRemoveC4 = CreateConVar("sm_awpsonly_remove_c4", "1", "Removes C4 from Terrorists when spawned.");
	cvWeaponOverride = CreateConVar("sm_awpsonly_weapon_override", "weapon_awp", "Overrides players' primary weapons. (Note: Invalid weapon names may cause server issues!)");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	AutoExecConfig(true, "awpsonly");
}

public void onBuyZonesChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetBuyZones(view_as<bool>(StringToInt(newValue, 2)));
}

public void OnMapStart()
{
	if (alBuyZones != null)
	{
		delete alBuyZones;
		alBuyZones = null;
	}
	
	alBuyZones = new ArrayList(1);
	
	GetBuyZones();
	SetBuyZones(GetConVarBool(cvBuyZones));
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	// Delay strip function in order to catch C4
	RequestFrame(StripNextTick, event.GetInt("userid"));
	return Plugin_Continue;
}

void StripNextTick(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return;
	}
	
	StripWeapons(client, GetConVarBool(cvRemoveKnives), GetConVarBool(cvRemoveC4));
	
	char classname[32];
	cvWeaponOverride.GetString(classname, sizeof(classname));
	if (StrContains(classname, "weapon_", false) != -1)
	{
		GivePlayerItem(client, classname);
	}
	else
	{
		GivePlayerItem(client, "weapon_awp");
	}
}

void StripWeapons(int client, bool removeKnife = false, bool removeC4 = true)
{
	for (int i = 0; i < 5; i++)
	{
		if (!removeKnife && i == WEAPON_KNIFE)
		{
			continue;
		}
		
		if (!removeC4 && i == WEAPON_C4)
		{
			continue;
		}
		
		int weapon = GetPlayerWeaponSlot(client, i);
		if (!IsValidEntity(weapon))
		{
			continue;
		}
		
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}

void GetBuyZones()
{
	char classname[32];
	for (int i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		GetEntityClassname(i, classname, sizeof(classname));
		if (StrEqual("func_buyzone", classname, false))
		{
			alBuyZones.Push(i);
		}
	}
}

void SetBuyZones(bool enabled = true)
{
	for (int i = 0; i < alBuyZones.Length; i++)
	{
		int zone = alBuyZones.Get(i);
		if (!IsValidEntity(zone))
		{
			continue;
		}
		
		AcceptEntityInput(zone, enabled ? "Enable" : "Disable");
	}
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && 2 <= GetClientTeam(client) <= 3;
} 