#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo =
{
	name = "DoD Reload Garand Source",
	author = "FeuerSturm, darkranger, playboycyberclub",
	description = "Allow Players to reload their Garand like all other guns!",
	version = PLUGIN_VERSION,
	url = "http://www.dodsplugins.com"
}

new Handle:ReloadGarandEnabled = INVALID_HANDLE
new Handle:ReloadGarandSaveAmmo = INVALID_HANDLE
new Float:gLastReload[MAXPLAYERS+1]

public OnPluginStart()
{
	CreateConVar("dod_reloadgarand_version", PLUGIN_VERSION, "DoD Reload Garand Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_reloadgarand_version"), PLUGIN_VERSION)
	ReloadGarandEnabled = CreateConVar("dod_reloadgarand_source", "1", "<1/0> = enable/disable players being able to reload the Garand")
	ReloadGarandSaveAmmo = CreateConVar("dod_reloadgarand_saveammo", "1", "<1/0> = enable/disable saving the Ammo when reloading")
}

new g_iAmmo, g_iClip1

public OnMapStart()
{
   g_iAmmo = FindSendPropInfo("CDODPlayer", "m_iAmmo")
   g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")
}

public OnClientPutInServer(client)
{
	gLastReload[client] = GetGameTime()
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarInt(ReloadGarandEnabled) == 0)
	{
		return Plugin_Continue
	}
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(buttons & IN_RELOAD && GetClientTeam(client) > 1)
		{
			new String:CurWeapon[32]
			GetClientWeapon(client, CurWeapon, sizeof(CurWeapon))
			if(strcmp(CurWeapon, "weapon_garand", true) == 0)
			{
				if(gLastReload[client] + 2.5 >= GetGameTime())
				{
					return Plugin_Continue
				}
				gLastReload[client] = GetGameTime()
				new wpn = GetPlayerWeaponSlot(client, 0)
				new GarandClip = GetEntData(wpn, g_iClip1)
				new GarandOffs = g_iAmmo + 16
				new GarandBackPack = GetEntData(client, GarandOffs)
				if(GarandClip < 8 && GarandClip > 0 && GarandBackPack + GarandClip >= 8)
				{
					if(GetConVarInt(ReloadGarandSaveAmmo) == 1)
					{
						SetEntData(client, GarandOffs, (GarandBackPack + GarandClip), 4, true)
					}
					SetEntData(wpn, g_iClip1, 0)
					return Plugin_Continue
				}
			}
		}
	}
	return Plugin_Continue
}