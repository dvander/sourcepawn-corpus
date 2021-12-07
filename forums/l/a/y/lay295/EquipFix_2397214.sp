#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStarted);
}

public Action:Event_RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new j = -1;
	new bool:HasPlayerEquip = false;
	while ((j = FindEntityByClassname(j, "game_player_equip")) != -1)
	{
		SetEntProp(j, Prop_Data, "m_fFlags", 2);
		HasPlayerEquip = true;
	}
	
	if (HasPlayerEquip)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				strip_player(i);
			}
		}
	}
}

public Action:strip_player(client)
{
	for (new i = 0; i <5; i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		if(weapon == -1)
		{
			continue;
		}
		RemovePlayerItem(client, weapon);
		RemoveEdict(weapon);
	}
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}