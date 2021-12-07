/*
*	Switch Upgrade Ammo Types
*	Copyright (C) 2020 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Switch Upgrade Ammo Types
*	Author	:	SilverShot
*	Descrp	:	Switch between normal bullets and upgraded ammo types.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=325300
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (21-Aug-2020)
	- Fixed the last update accidentally enabling unlimited usage of upgrade ammo piles.

1.1 (18-Aug-2020)
	- Blocked the M60 and Grenade Launcher from being able to switch ammo types.

1.0 (16-Jun-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define TYPE_FIRES			(1<<0)
#define TYPE_EXPLO			(1<<1)


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted;
int g_iOffsetAmmo;
int g_iAmmoCount[2048][3];				// Upgrade ammo [0]=UserId. [1]=Incendiary. [2]=Explosives.
int g_iAmmoBugFix[2048];				// Weapons reserve ammo.

float g_fSwitched[MAXPLAYERS+1];
int g_iLastWeapon[MAXPLAYERS+1];
int g_iTransition[MAXPLAYERS+1][3];
char g_sTransition[MAXPLAYERS+1][32];

StringMap g_hClipSize;
char g_sWeapons[][] =
{
	"weapon_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp"
	// "weapon_grenade_launcher"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Switch Upgrade Ammo Types",
	author = "SilverShot",
	description = "Switch between normal bullets and upgraded ammo types.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=325300"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =		CreateConVar(	"l4d2_switch_ammo_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_switch_ammo_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_switch_ammo_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_switch_ammo_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_switch_ammo_version",			PLUGIN_VERSION,		"Switch Ammo Types plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_switch_ammo");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	AddCommandListener(CommandListener, "give");
}

public Action CommandListener(int client, const char[] command, int args)
{
	if( args > 0 )
	{
		char buffer[6];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "ammo") == 0 )
		{
			RequestFrame(OnFrameEquip, GetClientUserId(client));
		}
	}
}

public void OnFrameEquip(int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if( weapon != -1 )
		{
			g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon);
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;

	// Get weapons max clip size, does not support any servers that dynamically change during gameplay.
	delete g_hClipSize;
	g_hClipSize = new StringMap();

	int index, entity;
	while( index < sizeof(g_sWeapons) - 1 )
	{
		entity = CreateEntityByName(g_sWeapons[index]);
		DispatchSpawn(entity);

		g_hClipSize.SetValue(g_sWeapons[index], GetEntProp(entity, Prop_Send, "m_iClip1"));
		RemoveEdict(entity);
		index++;
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetVars();
}

void ResetVars()
{
	for( int i = 1; i < 2048; i++ )
	{
		g_iAmmoCount[i][0] = 0;
		g_iAmmoCount[i][1] = 0;
		g_iAmmoCount[i][2] = 0;
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		// HookEvent("upgrade_pack_added",		upgrade_pack_added);
		HookEvent("map_transition",			Event_Transition);
		HookEvent("player_spawn",			Event_PlayerSpawn);
		HookEvent("weapon_fire",			Event_WeaponFire);
		HookEvent("receive_upgrade",		Event_GetUpgraded);
		HookEvent("ammo_pickup",			Event_AmmoPickup);

		// Late load
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2  && IsPlayerAlive(i) )
			{
				SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);

				int weapon = GetPlayerWeaponSlot(i, 0);
				if( weapon != -1 )
				{
					g_iLastWeapon[i] = EntIndexToEntRef(weapon);
					g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(i, weapon);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		// UnhookEvent("upgrade_pack_added",	upgrade_pack_added);
		UnhookEvent("map_transition",		Event_Transition);
		UnhookEvent("player_spawn",			Event_PlayerSpawn);
		UnhookEvent("weapon_fire",			Event_WeaponFire);
		UnhookEvent("receive_upgrade",		Event_GetUpgraded);
		UnhookEvent("ammo_pickup",			Event_AmmoPickup);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
			}
		}

		ResetVars();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_bMapStarted == false )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;

	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}

	if( iCvarModesTog != 0 )
	{
		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
// Re-create upgrade_pack for testing:
/*
public void upgrade_pack_added(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("upgradeid");
	{
		char class[32];
		float vOrigin[3], vAngles[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
		GetEdictClassname(entity, class, sizeof(class));
		AcceptEntityInput(entity, "Kill");

		if( strcmp(class, "upgrade_ammo_incendiary") == 0 )
			entity = CreateEntityByName("upgrade_ammo_incendiary");
		else if( strcmp(class, "upgrade_ammo_explosive") == 0 )
			entity = CreateEntityByName("upgrade_ammo_explosive");

		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		DispatchSpawn(entity);
	}
}
// */

public void Event_Transition(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCurrentMode == 1 )
	{
		int weapon;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) )
			{
				weapon = GetPlayerWeaponSlot(i, 0);
				if( weapon != -1 )
				{
					GetEdictClassname(weapon, g_sTransition[i], sizeof(g_sTransition[]));
					g_iTransition[i][0] = GetClientUserId(i);
					g_iTransition[i][1] = g_iAmmoCount[weapon][1];
					g_iTransition[i][2] = g_iAmmoCount[weapon][2];
				}
			}
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCurrentMode == 1 )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client )
		{
			if( IsFakeClient(client) ) return;

			SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
			SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);

			g_fSwitched[client] = 0.0;
			g_iLastWeapon[client] = 0;

			// Spawned after map transition:
			if( g_sTransition[client][0] )
			{
				RequestFrame(OnClientSpawn, GetClientUserId(client));
			}
		}
	}
}

public void OnClientSpawn(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && userid == g_iTransition[client][0] )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if( weapon != -1 )
		{
			char sTemp[32];
			GetEdictClassname(weapon, sTemp, sizeof(sTemp));
			if( strcmp(g_sTransition[client], sTemp) == 0 )
			{
				g_iAmmoCount[weapon][0] = EntIndexToEntRef(weapon);
				g_iAmmoCount[weapon][1] = g_iTransition[client][1];
				g_iAmmoCount[weapon][2] = g_iTransition[client][2];
			}
		}
	}
}

public void OnWeaponEquip(int client, int weapon)
{
	int main = GetPlayerWeaponSlot(client, 0);
	if( main != -1 && (g_iLastWeapon[client] == 0 || EntRefToEntIndex(g_iLastWeapon[client]) != main) )
	{
		g_iLastWeapon[client] = EntIndexToEntRef(main);
		RequestFrame(OnFrameEquip, GetClientUserId(client));
	}
}

// Fix ammo bug
public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) return;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// Has upgraded ammo
	if( weapon == GetPlayerWeaponSlot(client, 0) )
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		if( ammo )
		{
			// Using fire type, switch to explosive
			int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

			if( type & TYPE_FIRES ) type = TYPE_FIRES;
			else if( type & TYPE_EXPLO ) type = TYPE_EXPLO;
			else type = 0;

			if( type )
			{
				if( ammo == 1 )
				{
					g_iAmmoCount[weapon][type] = 0;
					ammo = GetMaxClip(weapon);
					GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon] + ammo - GetEntProp(weapon, Prop_Send, "m_iClip1") + 1);
				}
				else
				{
					g_iAmmoCount[weapon][type] = ammo - 1;
					GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
				}
			}
		}
		else
		{
			ammo = GetMaxClip(weapon);
			ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
			if( ammo < 0 ) ammo = 0;

			g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon) - ammo - 1;
		}
	}
}

public void Event_GetUpgraded(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) return;

	char sTemp[4];
	event.GetString("upgrade", sTemp, sizeof(sTemp));

	if( sTemp[0] == 'E' || sTemp[0] == 'I' )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

		if( type & TYPE_FIRES ) type = TYPE_FIRES;
		else if( type & TYPE_EXPLO ) type = TYPE_EXPLO;
		else type = 0;

		if( type )
		{
			int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");

			if( g_iAmmoCount[weapon][0] == 0 || EntRefToEntIndex(g_iAmmoCount[weapon][0]) != weapon )
			{
				g_iAmmoCount[weapon][0] = EntIndexToEntRef(weapon);
				g_iAmmoCount[weapon][1] = 0;
				g_iAmmoCount[weapon][2] = 0;
			}

			g_iAmmoCount[weapon][type] = ammo;

			GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
		}
	}
}

public void Event_AmmoPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) return;

	int weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon != -1 )
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon) - ammo;
		GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
	}
}



// ====================================================================================================
//					FUNCTION
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && buttons & IN_SPEED && buttons & IN_RELOAD && GetGameTime() > g_fSwitched[client] )
	{
		g_fSwitched[client] = GetGameTime() + 0.5;

		if( IsPlayerAlive(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) )
		{
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( weapon > 0 )
			{
				if( weapon == GetPlayerWeaponSlot(client, 0) )
				{
					static char classname[32];
					GetEdictClassname(weapon, classname, sizeof(classname));
					if( strcmp(classname[7], "rifle_m60") && strcmp(classname[7], "grenade_launcher") )
					{
						int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
						int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

						// Has upgraded ammo
						if( ammo )
						{
							// Using fire type, switch to explosive
							if( type & TYPE_FIRES )
								g_iAmmoCount[weapon][TYPE_FIRES] = ammo;
							else
								g_iAmmoCount[weapon][TYPE_EXPLO] = ammo;

							if( type & TYPE_FIRES && g_iAmmoCount[weapon][TYPE_EXPLO] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_EXPLO];

								type &= ~TYPE_FIRES;
								type |= TYPE_EXPLO;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);
							}
							// No explosive, reset to stock
							else
							{
								// Ammo bug fix
								ammo = GetMaxClip(weapon);
								ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
								if( ammo < 0 ) ammo = 0;
								GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon] + ammo);

								// Reset to stock ammo
								type &= ~TYPE_FIRES;
								type &= ~TYPE_EXPLO;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 0);
							}
						}
						// No upgraded ammo, switch to one
						else
						{
							// Ammo bug fix
							ammo = GetMaxClip(weapon);
							ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
							if( ammo < 0 ) ammo = 0;
							g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon) - ammo;
		
							// Set upgrade ammo
							if( g_iAmmoCount[weapon][TYPE_FIRES] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_FIRES];
								type |= TYPE_FIRES;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);
							}
							else if( g_iAmmoCount[weapon][TYPE_EXPLO] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_EXPLO];
								type |= TYPE_EXPLO;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);
							}
						}
					}
				}
			}
		}
	}
}

int GetMaxClip(int weapon)
{
	int ammo;
	static char sClass[32];
	GetEdictClassname(weapon, sClass, sizeof(sClass));
	g_hClipSize.GetValue(sClass, ammo);
	return ammo;
}

int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	// Offsets
	static StringMap hOffsets;
	if( hOffsets == null )
	{
		hOffsets = new StringMap();
		// L4D1 + L4D2
		hOffsets.SetValue("weapon_rifle", 12);
		hOffsets.SetValue("weapon_smg", 20);
		hOffsets.SetValue("weapon_pumpshotgun", 28);
		hOffsets.SetValue("weapon_shotgun_chrome", 28);
		hOffsets.SetValue("weapon_autoshotgun", 32);
		hOffsets.SetValue("weapon_hunting_rifle", 36);
		// L4D2
		hOffsets.SetValue("weapon_rifle_sg552", 12);
		hOffsets.SetValue("weapon_rifle_desert", 12);
		hOffsets.SetValue("weapon_rifle_ak47", 12);
		hOffsets.SetValue("weapon_smg_silenced", 20);
		hOffsets.SetValue("weapon_smg_mp5", 20);
		hOffsets.SetValue("weapon_shotgun_spas", 32);
		hOffsets.SetValue("weapon_sniper_scout", 40);
		hOffsets.SetValue("weapon_sniper_military", 40);
		hOffsets.SetValue("weapon_sniper_awp", 40);
		// hOffsets.SetValue("weapon_grenade_launcher", 68);
	}

	// Offset/Classname test
	char sWeapon[32];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

	int offset;
	hOffsets.GetValue(sWeapon, offset);

	// Get/Set
	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}
