#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new iAmmoOffset = -1;
new iClip1Offset = -1;

new Handle:hFreeTaser, bool:bFreeTaser,
	Handle:hInfTaser, bool:bInfTaser;

public Plugin:myinfo =
{
	name 		= "[CSGO] Free taser",
	author 		= "Grey83",
	description 	= "Give free and/or infinite taser to player on spawn in CSGO",
	version 		= PLUGIN_VERSION,
	url 			= ""
}

public OnPluginStart()
{
	CreateConVar("csgo_taser_version", PLUGIN_VERSION, "[CSGO] Free taser version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hFreeTaser = CreateConVar("sm_taser_free", "1", "On/Off free taser on spawn.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hInfTaser = CreateConVar("sm_taser_inf", "1", "On/Off Infinite taser.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	bFreeTaser = GetConVarBool(hFreeTaser);
	bInfTaser= GetConVarBool(hInfTaser);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_fire", Event_WeaponFire);

	HookConVarChange(hFreeTaser, OnConVarChange);
	HookConVarChange(hInfTaser, OnConVarChange);

	iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	iClip1Offset = FindSendPropInfo("CWeaponTaser", "m_iClip1");
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hFreeTaser)
	{
		bFreeTaser = bool:StringToInt(newValue);
	}
	else if (hCvar == hInfTaser)
	{
		bInfTaser = bool:StringToInt(newValue);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

public Action:Event_HandleSpawn(Handle:timer, any:user_index)
{
	new client = GetClientOfUserId(user_index);
	if (!client)
		return;

	new client_team = GetClientTeam(client);
	if ((client_team > 2) && (bFreeTaser))
		GivePlayerItem(client, "weapon_taser");
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bInfTaser)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client)
			return;

		new client_team = GetClientTeam(client);
		if(client_team > 2)
		{
			new String: weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			if(StrEqual("taser", weapon))
			{
				if (IsClientInGame(client) && IsPlayerAlive(client))
				{
					new iWeapon;
					iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if (IsValidEdict(iWeapon))
					{
 						if (iAmmoOffset)
							SetEntData(iWeapon, iClip1Offset, 2, _, true);
					}
				}
			}
		}
	}
}