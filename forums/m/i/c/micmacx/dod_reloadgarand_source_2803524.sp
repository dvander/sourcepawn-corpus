//////////////////////////////////////////////
//
// SourceMod Script
//
// DoD ReloadGarand Source
//
// Developed by FeuerSturm
//
// - Thanks to all Beta Testers!
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
//
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo =
{
	name = "DoD ReloadGarand Source",
	author = "FeuerSturm, modif Micmacx",
	description = "Allow Players to reload their Garand like all other guns!",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net"
}

new Handle:ReloadGarandEnabled = INVALID_HANDLE
new Handle:ReloadGarandSaveAmmo = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("dod_reloadgarand_version", PLUGIN_VERSION, "DoD ReloadGarand Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	ReloadGarandEnabled = CreateConVar("dod_reloadgarand_source", "1", "<1/0> = enable/disable players being able to reload the Garand", FCVAR_SPONLY|FCVAR_REPLICATED, true, 0.0, true, 1.0)
	ReloadGarandSaveAmmo = CreateConVar("dod_reloadgarand_saveammo", "1", "<1/0> = enable/disable saving the Ammo when reloading", FCVAR_SPONLY|FCVAR_REPLICATED, true, 0.0, true, 1.0)
	AutoExecConfig(true, "dod_reloadgarand", "dod_reloadgarand");
}

new g_iAmmo, g_iClip1

public OnMapStart()
{
   g_iAmmo = FindSendPropInfo("CDODPlayer", "m_iAmmo")
   g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarInt(ReloadGarandEnabled) == 0)
	{
		return Plugin_Continue
	}

	if (IsValidClient(client) && IsPlayerAlive(client) && (buttons & IN_RELOAD) && GetClientTeam(client) > 1)
	{
		new String:CurWeapon[32]
		GetClientWeapon(client, CurWeapon, sizeof(CurWeapon))
		if(strcmp(CurWeapon, "weapon_garand", true) == 0)
		{
			new wpn = GetPlayerWeaponSlot(client, 0)
			new GarandClip = GetEntData(wpn, g_iClip1)
			new GarandOffs = g_iAmmo + 16
			new GarandBackPack = GetEntData(client, GarandOffs)
			if(GarandClip < 8 && GarandClip > 0 && GarandBackPack + GarandClip >= 8)
			{
				new FOV = GetEntProp(client, Prop_Send, "m_iFOV")
				if(FOV == 55)
				{
					SetEntProp(client, Prop_Data, "m_nButtons", IN_ATTACK2)
				}
				if(GetConVarInt(ReloadGarandSaveAmmo) == 1)
				{
					SetEntData(client, GarandOffs, (GarandBackPack + GarandClip), 4, true)
				}
				SetEntData(wpn, g_iClip1, 0)
				return Plugin_Continue
			}
		}
	}
	return Plugin_Continue
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}
