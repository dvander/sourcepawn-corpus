#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1"
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "TOG No Scopes",
	author = "That One Guy",
	description = "Blocks scoping in with weapons",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.com"
}

public void OnPluginStart()
{
	CreateConVar("togns_version", PLUGIN_VERSION, "TOG No Scopes: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("weapon_zoom", EventWeaponZoom, EventHookMode_Post);
}

public Action EventWeaponZoom(Event oEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iUserID = oEvent.GetInt("userid");
	int client = GetClientOfUserId(iUserID);
	if(IsValidClient(client))
	{
		int iWeapon = GetPlayerWeaponSlot(client, 0);
		if(IsValidEdict(iWeapon))
		{
			char sWeapon[64];
			GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
			Handle hData = CreateDataPack();
			WritePackCell(hData, iUserID);
			WritePackString(hData, sWeapon);
			//save ammo counts so they can be restored
			WritePackCell(hData, GetEntProp(iWeapon, Prop_Data, "m_iClip1", 1));
			WritePackCell(hData, GetEntProp(iWeapon, Prop_Data, "m_iPrimaryReserveAmmoCount", 1));
			ResetPack(hData);
			CreateTimer(0.1, TimerCB_GiveWeapon, hData, TIMER_FLAG_NO_MAPCHANGE);
			PrintHintText(client, "Zooming is not allowed during no scope battle!");
		}
	}
	return Plugin_Continue;
}

public Action TimerCB_GiveWeapon(Handle hTimer, any hData)
{
	char sWeapon[64];
	int client = GetClientOfUserId(ReadPackCell(hData));
	ReadPackString(hData, sWeapon, sizeof(sWeapon));
	int iClipAmmo = ReadPackCell(hData);
	int iClipReserve = ReadPackCell(hData);
	CloseHandle(hData);
	
	if(IsValidClient(client))
	{
		int iWeapon = GivePlayerItem(client, sWeapon);
		if(IsValidEntity(iWeapon))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClipAmmo, 1);
			SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iClipReserve);
		}
	}
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

/*
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
	1.0.0
		* Initial creation.
	1.0.1
		* Minor edit to address not giving the weapon back.
*/