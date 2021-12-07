#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1

public Plugin myinfo =
{
	name = "fix map give usp",
	author = "Phoenix - Феникс",
	description = "fix game_player_equip give usp_silencer",
	version = "1.1",
	url = "zizt.ru hlmod.ru"
};

bool fix_spawn_usp;

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (StrEqual(sClassname, "game_player_equip")) SDKHook(iEntity, SDKHook_Use, UseHook);
}

public void OnMapStart()
{
	int iEntity = MaxClients+1;
	while((iEntity = FindEntityByClassname(iEntity, "game_player_equip")) != -1)
	{
		if(!(GetEntProp(iEntity, Prop_Data, "m_spawnflags") & 1) && NeedFixSpawnUsp(iEntity))
		{
			HookEvent("player_spawn", Event_PlayerSpawn);
			fix_spawn_usp = true;
			break;
		}
	}
}

public void OnMapEnd()
{
	if(fix_spawn_usp)
	{
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		fix_spawn_usp = false;
	}
}

public void Event_PlayerSpawn(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsPlayerAlive(iClient)) GivePlayerItem(iClient, "weapon_usp_silencer");
}

public Action UseHook(int iEntity, int iClient, int caller, UseType type, float value)
{
	if (0 < iClient <= MaxClients)
	{
		if(NeedFixSpawnUsp(iEntity)) GivePlayerItem(iClient, "weapon_usp_silencer");
	}
	return Plugin_Continue;
}

bool NeedFixSpawnUsp(int iEntity)
{
	char sWeapon[64];
	int iWeaponCount = GetEntPropArraySize(iEntity, Prop_Data, "m_weaponNames");
	
	for(int i; i < iWeaponCount; i++)
	{
		GetEntPropString(iEntity, Prop_Data, "m_weaponNames", sWeapon, sizeof(sWeapon), i);
		if(StrEqual(sWeapon, "weapon_usp_silencer")) return true;
	}
	return false;
}