#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.3"

new Handle:g_Cvar_PistolAmmoGer = INVALID_HANDLE;
new Handle:g_Cvar_PistolAmmoUS = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "DoD Pistols",
	author = "<eVa>Dog, playboycyberclub",
	description = "Adds a pistol for all players in DoD:S",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_dod_pistols_version", PLUGIN_VERSION, "DoD Pistols", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_PistolAmmoGer = CreateConVar("sm_dod_pistols_ammo_ger", "16");
	g_Cvar_PistolAmmoUS = CreateConVar("sm_dod_pistols_ammo_us", "14");

	HookEvent("player_spawn", PlayerSpawnEvent);
}


public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
    CreateTimer(0.1,GiveClientPistol,client)
}

public Action:GiveClientPistol(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		new ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo");


		new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		
		if ((class == 0) || (class == 2))
		{
			if (team == 2) 
			{
				GivePlayerItem(client, "weapon_colt")

				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}
			
			if (team == 3) 
			{
				GivePlayerItem(client, "weapon_p38")

				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		}
		else 
		{
			if (team == 2) 
			{
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}
			
			if (team == 3) 
			{
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		}
	}
	return Plugin_Handled
}

