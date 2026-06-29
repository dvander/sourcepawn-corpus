/*
	Credits to Meng's CS:S Restock
	- https://forums.alliedmods.net/showthread.php?t=148228
	- Took some logic from his code.
*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdkhooks>
#include <zombiereloaded>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hClip = INVALID_HANDLE;
new Handle:g_hReserve = INVALID_HANDLE;
new bool:g_bLateLoad;

new const String:g_sWeaponNames[24][32] = {

	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550"
};

new const g_AmmoData[24] =
{
	2, 3, 3,
	2, 3, 3,
	2, 4, 6,
	10, 8, 8,
	6, 7, 7,
	6, 8, 9,
	1, 6, 10,
	5, 2, 3
};

public Plugin:myinfo =
{
	name = "[ZR] Kill Clip",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "+Ammo on Zombie Kill. CS:S Only.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("zr_killclip");

	CreateConVar("zr_killclip_version", PLUGIN_VERSION, "[ZR] Kill Clip: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = AutoExecConfig_CreateConVar("zr_killclip_enabled", "1", "Enables/disables all features of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hClip = AutoExecConfig_CreateConVar("zr_killclip_refill_clip", "30", "Amount of ammo to refill the primary clip for each kill. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hReserve = AutoExecConfig_CreateConVar("zr_killclip_refill_reserve", "30", "Amount of ammo to refill the reserve ammo for each kill. (0 = Disabled)", FCVAR_NONE, true, 0.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	if(!GetConVarInt(g_hEnabled))
		return;

	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
			}
		}

		g_bLateLoad = false;
	}
}

public OnClientPutInServer(client)
{
	if(!GetConVarInt(g_hEnabled))
		return;

	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!GetConVarInt(g_hEnabled))
		return Plugin_Continue;

	if(!IsClientInGame(victim) || !IsPlayerAlive(victim) || !ZR_IsClientZombie(victim))
		return Plugin_Continue;

	if(attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || !ZR_IsClientHuman(attacker))
		return Plugin_Continue;

	new iHealth = GetClientHealth(victim);
	if(RoundToFloor(float(iHealth) - damage) <= 0)
	{
		new iWeapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
		if(iWeapon > 0 && IsValidEntity(iWeapon))
		{
			new iRecoverReserve = GetConVarInt(g_hReserve);
			if(iRecoverReserve)
			{
				decl String:sClassname[32];
				GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
				new iDataIndex = GetAmmoDataIndex(sClassname);
				if(iDataIndex != -1)
				{
					new iAmmoOffset = FindDataMapOffs(attacker, "m_iAmmo") + (g_AmmoData[iDataIndex] * 4);
					if(iAmmoOffset != -1)
					{
						new iReserve = GetEntData(attacker, iAmmoOffset);
						SetEntData(attacker, iAmmoOffset, iReserve + iRecoverReserve);
					}
				}
			}
			
			new iRecoverClip = GetConVarInt(g_hClip);
			if(iRecoverClip)
			{
				new iClip = GetEntProp(iWeapon, Prop_Data, "m_iClip1");
				if(iClip != -1)
					SetEntProp(iWeapon, Prop_Data, "m_iClip1", (iClip + iRecoverClip));
			}
		}
	}

	return Plugin_Continue;
}

GetAmmoDataIndex(const String:weapon[]) {

	for (new i = 0; i < 24; i++)
	{
		if (StrEqual(weapon, g_sWeaponNames[i]))
		{
			return i;
		}
	}

	return -1;
}