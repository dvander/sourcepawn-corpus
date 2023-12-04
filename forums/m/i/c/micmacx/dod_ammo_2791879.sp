#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name        = "DOD:S Ammo Settings",
	author      = "Silent_Water modif Micmacx",
	description = "Set the players ammo in DOD:S",
	version     = PLUGIN_VERSION,
	url         = "silentspam2000@yahoo.de"
}

new g_iClipOffset;
new g_iAmmoOffset;
new g_iAmmo[22] = {0, ... };
new g_iAmount[22] = {-1, ... };
new bool:g_bEnabled = true;
new Handle:g_hEnabled;
new String:g_sCWeapons[22][16] = {"Colt", "P38", "C96", "Garand", "K98", "K98Scoped", "M1Carbine", "Spring", "Thompson", "MP40", "MP44", "BAR", "30cal", "MG42", "Bazooka", "Pschreck", "HandGrenade", "StickGrenade", "SmokeGrenadeUS", "SmokeGrenadeGER", "RifleGrenadeUS", "RifleGrenadeGER"};
new String:g_sWeapons[22][16] = {"colt", "p38", "c96", "garand", "k98", "k98_scoped", "m1carbine", "spring", "thompson", "mp40", "mp44", "bar", "30cal", "mg42", "bazooka", "pschreck", "frag_us", "frag_ger", "smoke_us", "smoke_ger", "riflegren_us", "riflegren_ger"};
new g_iAmmoOffsets[22] = { 4, 8, 12, 16, 20, 20, 24, 28, 32, 32, 32, 36, 40, 44, 48, 48, 52, 56, 68, 72, 84, 88};

public OnPluginStart()
{
	CreateConVar("sm_dod_ammo_version", PLUGIN_VERSION, "DOD:S Ammo Settings", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_dod_ammo_enabled", "1", "Enable/disable DOD:S Ammo Settings", _, true, 0.0, true, 1.0);

	g_iClipOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	HookConVarChange(g_hEnabled, ConVarChange_Enabled);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	LoadConfig();
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled  = StrEqual(newValue, "1");
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(iClient) > 1)
		{
			CreateTimer(0.1, Timer_Ammo, iClient, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Ammo(Handle:timer, any:client)
{
	if (g_bEnabled)
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				decl String:sClassName[64];
				new iWeaponIndex = 0;
				for (new i = 0, iWeapon, iAmount, iAmmo; i < 5; i++) 
				{
					if ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1) 
					{
						iAmount = GetEntData(iWeapon, g_iClipOffset);
						GetEntityNetClass(iWeapon,sClassName,sizeof(sClassName));
						ReplaceString(sClassName,sizeof(sClassName),"CWeapon","");
						iWeaponIndex = GetWeaponIndex(sClassName);
						if (iWeaponIndex > -1 && g_iAmount[iWeaponIndex] > -1) 
						{
							iAmount = g_iAmount[iWeaponIndex];
							iAmmo = g_iAmmo[iWeaponIndex];
							SetEntData(client, iAmmo, iAmount, _, true);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

GetWeaponIndex(const String:name[])
{
	for (new i=0;i<sizeof(g_sCWeapons);i++) {
		if (StrEqual(g_sCWeapons[i], name)) {
			return i;
		}
	}
	return -1;
}

LoadConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sAmount[5];
	new Handle:hConfig = CreateKeyValues("Ammo");

	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/ammo.txt");

	if (FileExists(sPath) && FileToKeyValues(hConfig, sPath))
	{
		for (new i = 0; i < sizeof(g_sWeapons); i++)
		{
			KvRewind(hConfig);
			KvJumpToKey(hConfig, "Weapons");
			KvGetString(hConfig, g_sWeapons[i], sAmount, sizeof(sAmount));
			g_iAmmo[i]   = g_iAmmoOffset + g_iAmmoOffsets[i];
			if (StrEqual(sAmount, "")) {
				g_iAmount[i] = -1;
			} else {
				g_iAmount[i] = StringToInt(sAmount);
			}
		}
		KvRewind(hConfig);
	}
	else
	{
		SetFailState("File not found or corrupt: %s", sPath);
	}
	CloseHandle(hConfig);
}

