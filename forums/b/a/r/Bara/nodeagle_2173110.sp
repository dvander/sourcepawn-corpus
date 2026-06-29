#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "No Deagle",
	author = "Bara",
	description = "",
	version = "1.0",
	url = "www.bara.in"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = (GetClientOfUserId(GetEventInt(event, "userid")));
	
	CreateTimer(0.1, Timer_CheckWeapons, client);
}

public Action:Timer_CheckWeapons(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		CheckWeapons(client);
	}
}

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_WeaponCanUse, OnWeapon);
	SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeapon);
	SDKHook(i, SDKHook_WeaponSwitch, OnWeapon);
	SDKHook(i, SDKHook_WeaponEquip, OnWeapon);
}

public Action:OnWeapon(client, weapon)
{
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));

	if(StrEqual(sWeapon, "deagle"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock CheckWeapons(client)
{
	new iWeapon = -1;
	for(new i = CS_SLOT_PRIMARY; i<= CS_SLOT_C4; i++)
	{
		while((iWeapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
	
	new iKnife = GivePlayerItem(client, "weapon_knife");
	new iAWP = GivePlayerItem(client, "weapon_awp");
	EquipPlayerWeapon(client, iKnife);
	EquipPlayerWeapon(client, iAWP);
}