#include <sourcemod>
#include <sdktools>

#define VERSION "1.4f"

new g_iTeam
new Handle:g_Cvar_enabled = INVALID_HANDLE
new Handle:g_Cvar_PistolAmmoUS = INVALID_HANDLE
new Handle:g_Cvar_PistolAmmoGer = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Giver Grenades & Pistols in DoD:S",
	author = "][O.o][",
	description = "Adds pistols, smoke, shrapnel and rifle grenades - Machinegunner, Sniper and the Rifleman in DoD:S",
	version = VERSION,
	url = "dchub://sosnogorsk-hub.ru"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_ggp_version", VERSION, "Giver Grenades in DoD:S", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_enabled = CreateConVar("sm_dod_ggp_enabled", "1", "Enable or disable this plugin.", FCVAR_PLUGIN)
	g_Cvar_PistolAmmoUS = CreateConVar("sm_dod_pistols_ammo_us", "21", "The amount of ammo to give to Allies  <21 default>", FCVAR_PLUGIN)
	g_Cvar_PistolAmmoGer = CreateConVar("sm_dod_pistols_ammo_ger", "24", "The amount of ammo to give to Germans  <24 default>", FCVAR_PLUGIN)
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookConVarChange(g_Cvar_enabled, OnEnableChanged)
}

public OnEnableChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (strcmp(oldval, newval) != 0) {
		if (strcmp(newval, "0") == 0)
			UnhookEvent("player_spawn", PlayerSpawnEvent);
		else if (strcmp(newval, "1") == 0)
			HookEvent("player_spawn", PlayerSpawnEvent);
	}
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	CreateTimer(0.1, GiveClientItems, client)
}

public Action:GiveClientItems(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		g_iTeam = GetClientTeam(client)
		new ammo_offset = FindSendPropOffs("CDODPlayer", "m_iAmmo")
		new iClass = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		
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
