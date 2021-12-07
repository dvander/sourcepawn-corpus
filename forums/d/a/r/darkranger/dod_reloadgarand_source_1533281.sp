//////////////////////////////////////////////
//
// SourceMod Script
//
// DoD ReloadGarand Source
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
//
//
// USAGE:
// ======
//
//
// CVARs:
// ------
//
// dod_reloadgarand_source <1/0>		=	enable/disable players being able to reload the Garand
//
// dod_reloadgarand_saveammo <0/1>		=	enable/disable saving the Ammo when reloading
//
//
//
//
// CHANGELOG:
// ==========
// 
// - 04 April 2009 - Version 1.0
//   Initial Release
//
// - 22 January 2010 - Version 1.1
//   REQUIRES SourceMod >= 1.3.0 now!
//   * removed need for DukeHacks Extension,
//     SourceMod 1.3 standard features are used
//     instead now!
//   * fixed iron-sighted reloading
//
//
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "DoD ReloadGarand Source",
	author = "FeuerSturm",
	description = "Allow Players to reload their Garand like all other guns!",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net"
}

new Handle:ReloadGarandEnabled = INVALID_HANDLE
new Handle:ReloadGarandSaveAmmo = INVALID_HANDLE
new Float:gLastReload[MAXPLAYERS+1]

public OnPluginStart()
{
	CreateConVar("dod_reloadgarand_version", PLUGIN_VERSION, "DoD ReloadGarand Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_reloadgarand_version"), PLUGIN_VERSION)
	ReloadGarandEnabled = CreateConVar("dod_reloadgarand_source", "1", "<1/0> = enable/disable players being able to reload the Garand", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	ReloadGarandSaveAmmo = CreateConVar("dod_reloadgarand_saveammo", "1", "<1/0> = enable/disable saving the Ammo when reloading", FCVAR_PLUGIN, true, 0.0, true, 1.0)
}

new g_iAmmo, g_iClip1

public OnMapStart()
{
   g_iAmmo = FindSendPropOffs("CDODPlayer", "m_iAmmo")
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