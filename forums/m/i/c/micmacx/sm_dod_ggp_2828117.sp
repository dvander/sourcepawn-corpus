#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define VERSION "1.5"

Handle g_Cvar_enabled = INVALID_HANDLE
Handle g_Cvar_PistolAmmoUS = INVALID_HANDLE
Handle g_Cvar_PistolAmmoGer = INVALID_HANDLE

public Plugin myinfo = 
{
	name = "Giver Grenades & Pistols in DoD:S",
	author = "][O.o][, modif Micmacx",
	description = "Adds pistols, smoke, shrapnel and rifle grenades - Machinegunner, Sniper and the Rifleman in DoD:S",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1290620"
}

public void OnPluginStart()
{
	CreateConVar("sm_dod_ggp_version", VERSION, "Giver Grenades in DoD:S", FCVAR_NOTIFY|FCVAR_DONTRECORD)
	g_Cvar_enabled = CreateConVar("sm_dod_ggp_enabled", "1", "Enable or disable this plugin.", _)
	g_Cvar_PistolAmmoUS = CreateConVar("sm_dod_pistols_ammo_us", "21", "The amount of ammo to give to Allies  <21 default>", _)
	g_Cvar_PistolAmmoGer = CreateConVar("sm_dod_pistols_ammo_ger", "24", "The amount of ammo to give to Germans  <24 default>", _)
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookConVarChange(g_Cvar_enabled, OnEnableChanged)
}

public void OnEnableChanged(Handle cvar, const char []oldval, const char []newval) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0)
			UnhookEvent("player_spawn", PlayerSpawnEvent);
		else if (strcmp(newval, "1") == 0)
			HookEvent("player_spawn", PlayerSpawnEvent);
	}
}

public void PlayerSpawnEvent(Handle event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (IsValidClient(client))
	{
		CreateTimer(0.1, GiveClientItems, client)
	}
}

public Action GiveClientItems(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		int g_iTeam = GetClientTeam(client)
		int ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo")
		int iClass = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		
		if ((iClass == 3) || (iClass == 4) || (iClass == 5))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_smoke_us")			
				GivePlayerItem(client, "weapon_frag_us")
				GivePlayerItem(client, "weapon_frag_us")
			}
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_smoke_ger")			
				GivePlayerItem(client, "weapon_frag_ger")
				GivePlayerItem(client, "weapon_frag_ger")

			}
		}
		if ((iClass == 0))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_smoke_us")
				GivePlayerItem(client, "weapon_riflegren_us")
			}
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_smoke_ger")
				GivePlayerItem(client, "weapon_riflegren_ger")
			}
		}
		if ((iClass == 1))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_frag_us")
				GivePlayerItem(client, "weapon_frag_us")
			}
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_frag_ger")
				GivePlayerItem(client, "weapon_frag_ger")
			}
		}
		if ((iClass == 2))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_smoke_us")
			}
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_smoke_ger")
			}
		}
		if ((iClass == 0) || (iClass == 2))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_colt")
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}			
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_p38")
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		}
		else 
		{
			if (g_iTeam == 2) 
			{
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}			
			if (g_iTeam == 3) 
			{
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		}
	}
	return Plugin_Handled
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}

