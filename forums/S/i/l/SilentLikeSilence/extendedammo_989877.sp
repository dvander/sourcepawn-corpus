#include <sourcemod>
#include <sdktools_functions>

new bool:BoughtPrimary[MAXPLAYERS +1];
new bool:BoughtSecondary[MAXPLAYERS +1];

public Plugin:myinfo =
{
	name = "[CSS] Extended Ammo",
	author = "John B.",
	description = "Plugin gives more ammo on spawn and sets bigger clip size after reloading",
	version = "1.0.0",
	url = "www.sourcemod.net",
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_reload", Event_WeaponReload);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(10.0, CheckWeapon, client);
	CreateTimer(12.0, SetAmmo, client);

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	BoughtPrimary[client] = false;
	BoughtSecondary[client] = false;

	return Plugin_Continue;
}

public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new primary = GetPlayerWeaponSlot(client, 0);
	new secondary = GetPlayerWeaponSlot(client, 1);

	SetEntData(primary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*4), 300);
	SetEntData(secondary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*8), 150);

	return Plugin_Continue;
}

public Action:CheckWeapon(Handle:timer, any:client)
{
	new primary = GetPlayerWeaponSlot(client, 0);
	new secondary = GetPlayerWeaponSlot(client, 1);

	if(primary != -1 && secondary != -1)
	{
		BoughtPrimary[client] = true;
		BoughtSecondary[client] = true;
	}
	else if(primary != -1 && secondary == -1)
	{
		BoughtPrimary[client] = true;
	}
	else if(primary == -1 && secondary != -1)
	{
		BoughtSecondary[client] = true;
	}
	return Plugin_Continue;
}

public Action:SetAmmo(Handle:timer, any:client)
{
	new primary = GetPlayerWeaponSlot(client, 0);
	new secondary = GetPlayerWeaponSlot(client, 1);

	if(BoughtPrimary[client] == true && BoughtSecondary[client] == true)
	{
		SetEntData(primary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*4), 300);
		SetEntData(secondary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*8), 150);
	}
	else if(BoughtPrimary[client] == true && BoughtSecondary[client] == false)
	{
		SetEntData(primary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*4), 300);
	}
	else if(BoughtSecondary[client] == true && BoughtPrimary[client] == false)
	{
		SetEntData(secondary, FindSendPropInfo("CCSPlayer", "m_iAmmo") + (2*8), 150);
	}
	return Plugin_Continue;
}