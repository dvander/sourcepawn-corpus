/*

*/
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.4"
new Handle:grenade_rank = INVALID_HANDLE
new Handle:grenade_ammount = INVALID_HANDLE
new g_iLevel[MAXPLAYERS + 1]    = {1, ...}
new maxnades[MAXPLAYERS + 1]    = {1, ...}
new used_nades[MAXPLAYERS + 1]    = {1, ...}

public Plugin:myinfo = {
        name        = "CS:GO AR Grenade Mode",
        author      = "Darkranger",
        description = "adds HEGrenades to AR MODE",
        version     = PLUGIN_VERSION,
        url         = "http://dark.asmodis.at"
}

public OnPluginStart()
{
	CreateConVar("csgo_ar_grenade_mode_version", PLUGIN_VERSION, "CS:GO AR Grenade Mode", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	grenade_rank = CreateConVar("csgo_ar_grenade_mode_level", "15", "Level when HEGreandes should apear ", FCVAR_PLUGIN)
	grenade_ammount = CreateConVar("csgo_ar_grenade_mode_ammount", "8", "ammount of grenades", FCVAR_PLUGIN)
	AutoExecConfig(true, "csgo_ar_grenade_mode", "csgo_ar_grenade_mode")
	HookEvent("player_death", EventPlayerDeath)
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Pre)
	HookEvent("player_spawn", Event_nades_spawn)
	HookEvent("ggtr_player_levelup", Event_nades_levelup)
	HookEvent("ggprogressive_player_levelup", Event_nades_levelup)
	HookEvent("gg_player_levelup", Event_nades_levelup)
}

public OnClientPutInServer(client)
{
	g_iLevel[client] = 0	
	maxnades[client] = GetConVarInt(grenade_ammount)
	used_nades[client] = 1
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new iAttackerID = GetEventInt(event, "attacker")
	new iClientID = GetEventInt(event, "userid")
	new iAttacker   = GetClientOfUserId(iAttackerID)
	new client     = GetClientOfUserId(iClientID)
	if (iAttacker == 0 || iAttacker == client)
	{
		if (g_iLevel[client] >= 2)
		{
			g_iLevel[client]--
		}	
	}
}	

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!IsFakeClient(client))
	{
		new rank = g_iLevel[client]
		new String:weapon[32]
		GetEventString(event, "weapon", weapon, sizeof(weapon))
		if (StrEqual(weapon, "hegrenade", false))
		{
			if ((rank == GetConVarInt(grenade_rank)) && (used_nades[client] < GetConVarInt(grenade_ammount)))
			{
				GivePlayerItem(client, "weapon_hegrenade")
				used_nades[client]++
			}
		}
	}	
}

public Action:Event_nades_levelup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!IsFakeClient(client))
	{
		new rank = GetEventInt(event, "weaponrank")
		g_iLevel[client] = rank
		if (rank == GetConVarInt(grenade_rank))
		{
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")
			if (IsValidEdict(weapon))
			{
				RemoveEdict(weapon)
				RemovePlayerItem(client, weapon)
				AcceptEntityInput(weapon, "Kill")
				GivePlayerItem(client, "weapon_hegrenade")
			}
		}
		if (rank != GetConVarInt(grenade_rank))
		{
			// REMOVE UN-NEEDED GRENADE FROM LAST "EventWeaponFire"
			if (GetPlayerWeaponSlot(client, 3) != -1)
			{
				new weapon = GetPlayerWeaponSlot(client, 3);
				RemovePlayerItem(client, weapon)
			}
		}
	}
}	

public Action:Event_nades_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (!IsFakeClient(client))
	{
		new rank = g_iLevel[client]
		if (rank == GetConVarInt(grenade_rank))
		{
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")
			RemoveEdict(weapon)
			RemovePlayerItem(client, weapon)
			AcceptEntityInput(weapon, "Kill")
			GivePlayerItem(client, "weapon_hegrenade")
			used_nades[client] = 1
		}
	}
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", Event_nades_spawn)
	UnhookEvent("ggtr_player_levelup", Event_nades_levelup)
	UnhookEvent("ggprogressive_player_levelup", Event_nades_levelup)
	UnhookEvent("gg_player_levelup", Event_nades_levelup)
	UnhookEvent("weapon_fire", EventWeaponFire)
	UnhookEvent("player_death", EventPlayerDeath)
}



