#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define ALLIES 2
#define AXIS 3

public Plugin:myinfo = 
{
	name = "DoD Nostalgia Source",
	author = "FeuerSturm, playboycyberclub",
	description = "Get the famous DoD 1.3 weapon loadout in DoD:Source!",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.com/"
}

new Handle:NostalgiaON = INVALID_HANDLE
new String:WpnMelee[4][] = { "", "", "weapon_amerknife", "weapon_spade" }
new String:WpnPistol[4][] = { "", "", "weapon_colt", "weapon_p38" }
new String:WpnGrenade[4][] = { "", "", "weapon_frag_us", "weapon_frag_ger" }
new PistolOffset[4] = { 0, 0, 4, 8 }
new PistolAmmo[4] = { 0, 0, 14, 16 }
new GrenadeOffset[4] = { 0, 0, 52, 56 }
new GrenadeAmmo[6] = { 2, 1, 1, 0, 0, 0 }

public OnPluginStart()
{
	CreateConVar("dod_nostalgia_version", PLUGIN_VERSION, "DoD Nostalgia Source Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_nostalgia_version"),PLUGIN_VERSION)
	NostalgiaON = CreateConVar("dod_nostalgia_source", "1", "<1/0> = enable/disable DoD Nostalgia Source")
	HookEventEx("player_spawn", EventPlayerSpawn, EventHookMode_Post)
}


public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetConVarInt(NostalgiaON) == 1 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		RemoveWeapons(client)
		GiveWeapons(client)
		return Plugin_Continue
	}
	return Plugin_Continue
}

stock RemoveWeapons(client)
{
	for(new i = 1; i < 4; i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i)
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon)
			RemoveEdict(weapon)
		}
	}
}

stock GiveWeapons(client)
{
	new team = GetClientTeam(client)
	new ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo")
	new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
	GivePlayerItem(client,WpnMelee[team])
	GivePlayerItem(client,WpnPistol[team])
	if(class == 0 || class == 1 || class == 2)
	{
		GivePlayerItem(client,WpnGrenade[team])
		SetEntData(client, ammo_offset+GrenadeOffset[team], GrenadeAmmo[class], 4, true)
	}
	SetEntData(client, ammo_offset+PistolOffset[team], PistolAmmo[team], 4, true)
}