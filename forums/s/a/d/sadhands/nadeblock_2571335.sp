#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define WEAPONTYPE_GRENADE 9
bool g_bRoundEnd = false;
String:GrenadeNames[] =
	{
		//"hegrenade",
		//"incgrenade",
		//"smokegrenade",
		"grenade",
		"flashbang",
		"molotov",
		"decoy"
	};

public Plugin myinfo = 
{
	name = "Grenade Blocker",
	author = "sadhands",
	description = "Blocks grenades from being used",
	version = "1.0.0",
	url = "http://www.imperfectgamers.org/"
};

public void OnPluginStart()
{
	HookEvent("round_poststart", Event_OnRoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("item_equip", CheckForNades, EventHookMode_Pre);
	HookEvent("weapon_fire", CheckForNades, EventHookMode_Pre);
	HookEvent("item_pickup", CheckForNades, EventHookMode_Pre);
}

public Action Event_OnRoundStart(Handle event, char[] name, bool dontBroadcast) { g_bRoundEnd = false; }

public Action Event_OnRoundEnd(Handle event, char[] name, bool dontBroadcast) { g_bRoundEnd = true; }

public Action CheckForNades(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsValidClient(client))
		return Plugin_Continue;

	char szName[7];
	event.GetName(szName, 7);
	
	char szBuffer[12];
	
	if (StrContains(szName, "item_", true) != -1)
		GetEventString(event, "item", szBuffer, 12);
	else if (StrContains(szName, "weapon_", true) != -1)
		GetEventString(event, "weapon", szBuffer, 12);
	
	new count = sizeof(GrenadeNames);
	for (new i = 0; i < count; i++)
	{
		if (StrContains(szBuffer, GrenadeNames[i], true) != -1)
			if (RemoveGrenade(client))
				return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;
		
	return true;
}

public bool RemoveGrenade(int client)
{
	if (g_bRoundEnd)
		return false;

	if (!IsValidClient(client))
		return false;
	
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE);
	
	if (weapon < 0) 
		return false;
		
	if (!IsValidWeapon(client, weapon))
		return false;
	
	if(!RemovePlayerItem(client, weapon)) {
		int iHudFlags = GetEntProp(client, Prop_Send, "m_iHideHUD");
		int iOwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		
		if (iOwnerEntity != client)
			SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
		
		if (weapon == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
			
		CS_DropWeapon(client, weapon, false, true);
		
		if (iOwnerEntity != client)
			SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", iOwnerEntity);
		
		SetEntProp(client, Prop_Send, "m_iHideHUD", iHudFlags);
	}
	
	AcceptEntityInput(weapon, "Kill");
	
	return true;
}

public bool IsValidWeapon(int client, int weapon)
{
	if (!IsValidClient(client))
		return false;

	if (!IsValidEntity(weapon) || !IsValidEdict(weapon) || weapon < 0)
		return false;
	
	if (!HasEntProp(weapon, Prop_Send, "m_hOwnerEntity"))
		return false;
	
	char szClassName[48];
	GetEntityClassname(weapon, szClassName, 48);
	
	if (StrContains(szClassName, "weapon_") == -1 && StrContains(szClassName, "base") == -1 && StrContains(szClassName, "case") == -1)
		return false;
	
	int item = -1;
	
	if (HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) 
		item = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if (item < 0 || item > 700)
		return false;

	if (HasEntProp(weapon, Prop_Send, "m_bInitialized"))
		if (GetEntProp(weapon, Prop_Send, "m_bInitialized") == 0)
			return false;

	if (HasEntProp(weapon, Prop_Send, "m_bStartedArming"))
		if (GetEntSendPropOffs(weapon, "m_bStartedArming") > -1)
			return false;

	return true;
}