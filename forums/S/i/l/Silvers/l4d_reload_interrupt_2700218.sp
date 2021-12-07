/*
*	Reload Interrupt
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.7"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Reload Interrupt
*	Author	:	SilverShot
*	Descrp	:	Shooting cancels reloading like TF2 weapons. Also can auto reload weapons after shooting.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=324395
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (13-Apr-2021)
	- Another precache sound fix attempt. Should be right now.

1.6 (27-Mar-2021)
	- Fixed precache sound errors by verifying files exist before. Thanks to "Maur0" for reporting.

1.5 (20-Mar-2021)
	- Fixed some console errors due to not precaching sounds. Thanks to "Balloons" for reporting.

1.4 (28-Sep-2020)
	- Blocked bots from using to prevent any bugs.
	- Fixed the plugin sometimes wiping ammo when quickly switching weapons (Gear Transfer - grenades issue).

1.3 (07-Jun-2020)
	- Fixed L4D1 issues. Thanks to "jamalsheref2" for reporting.

1.2 (19-May-2020)
	- Added extra check on switching weapons. Thanks to "Crasher_3637" for reporting.
	- Added reset vars on player spawn and death.

1.1 (16-May-2020)
	- Fixed reserve ammo increasing. Thanks to "Crasher_3637" for reporting.

1.0 (15-May-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRestart, g_hCvarWeapons;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iCvarRestart, g_iOffsetAmmo, g_iCvarWeapons;
int g_iForceTicks;		// How many times to force the IN_RELOAD buttons (otherwise some weapons e.g. shotguns will not auto reload after multiple shots).

int g_iLastAmmo[MAXPLAYERS+1];
int g_iLastClip[MAXPLAYERS+1];
int g_iLastHook[MAXPLAYERS+1];
int g_iWasShoot[MAXPLAYERS+1];
int g_iAutoReload[MAXPLAYERS+1];

StringMap g_hWeaponOffsets;
StringMap g_hWeaponClasses;
StringMap g_hWeaponAllowed;

// Primary sound + incendiary sound (if available)
char g_sWeaponSounds[][][] =
{
	{
		")weapons/pistol/gunfire/pistol_fire.wav",
		")weapons/pistol/gunfire/pistol_fire.wav"
	},
	{
		")weapons/magnum/gunfire/magnum_shoot.wav",
		")weapons/magnum/gunfire/magnum_shoot.wav"
	},
	{
		")weapons/awp/gunfire/awp1.wav",
		")weapons/awp/gunfire/awp1.wav"
	},
	{
		")weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav",
		")weapons/hunting_rifle/gunfire/hunting_rifle_fire_1_incendiary.wav"
	},
	{
		")weapons/rifle/gunfire/rifle_fire_1.wav",
		")weapons/rifle/gunfire/rifle_fire_1_incendiary.wav"
	},
	{
		")weapons/rifle_ak47/gunfire/rifle_fire_1.wav",
		")weapons/rifle_ak47/gunfire/rifle_fire_1_incendiary.wav"
	},
	{
		")weapons/rifle_desert/gunfire/rifle_fire_1.wav",
		")weapons/rifle_desert/gunfire/rifle_fire_1_incendiary.wav"
	},
	{
		")weapons/scout/gunfire/scout_fire-1.wav",
		")weapons/scout/gunfire/scout_fire-1.wav"
	},
	{
		")weapons/sg552/gunfire/sg552-1.wav",
		")weapons/sg552/gunfire/sg552-1.wav"
	},
	{
		")weapons/smg/gunfire/smg_fire_1.wav",
		")weapons/smg/gunfire/smg_fire_1_incendiary.wav"
	},
	{
		")weapons/smg_silenced/gunfire/smg_fire_1.wav",
		")weapons/smg_silenced/gunfire/smg_fire_1_incendiary.wav"
	},
	{
		")weapons/mp5navy/gunfire/mp5-1.wav",
		")weapons/mp5navy/gunfire/mp5-1.wav"
	},
	{
		")weapons/sniper_military/gunfire/sniper_military_fire_1.wav",
		")weapons/sniper_military/gunfire/sniper_military_fire_1_incendiary.wav"
	}
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Reload Interrupt",
	author = "SilverShot",
	description = "Shooting cancels reloading like TF2 weapons. Also can auto reload weapons after shooting.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=324395"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =		CreateConVar(	"l4d_reload_interrupt_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_reload_interrupt_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_reload_interrupt_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_reload_interrupt_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRestart =	CreateConVar(	"l4d_reload_interrupt_restart",			"1",				"0=Off. 1=Restart reloading when reloading was interrupted by shooting. 2=Auto reload anytime shooting stops.", CVAR_FLAGS );
	g_hCvarWeapons =	CreateConVar(	"l4d_reload_interrupt_weapons",			"131071",			"Allowed weapons (add numbers together). See plugin thread for details (values and classnames are too long to display in cvar description). 131071=All.", CVAR_FLAGS );
	CreateConVar(						"l4d_reload_interrupt_version",			PLUGIN_VERSION,		"Reload Interrupt plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_reload_interrupt");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRestart.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWeapons.AddChangeHook(ConVarChanged_Cvars);



	// ====================================================================================================
	// STUFF
	// ====================================================================================================
	// Required to press reload over several frames otherwise shotguns for example will not reload. They will stop on multiple shots anyway when restart is set to 1 because the game resets m_bInReload to 0 sometimes.
	g_iForceTicks = RoundFloat(1 / GetTickInterval());
	g_iForceTicks = RoundToFloor(g_iForceTicks / 5.0);

	// Offsets to setting reserve ammo
	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

	g_hWeaponOffsets = new StringMap();
	g_hWeaponOffsets.SetValue("weapon_rifle", 12);
	g_hWeaponOffsets.SetValue("weapon_smg", 20);
	g_hWeaponOffsets.SetValue("weapon_pumpshotgun", 28);
	g_hWeaponOffsets.SetValue("weapon_shotgun_chrome", 28);
	g_hWeaponOffsets.SetValue("weapon_autoshotgun", 32);
	g_hWeaponOffsets.SetValue("weapon_hunting_rifle", 36);

	if( g_bLeft4Dead2 )
	{
		g_hWeaponOffsets.SetValue("weapon_rifle_sg552", 12);
		g_hWeaponOffsets.SetValue("weapon_rifle_desert", 12);
		g_hWeaponOffsets.SetValue("weapon_rifle_ak47", 12);
		g_hWeaponOffsets.SetValue("weapon_smg_silenced", 20);
		g_hWeaponOffsets.SetValue("weapon_smg_mp5", 20);
		g_hWeaponOffsets.SetValue("weapon_shotgun_spas", 32);
		g_hWeaponOffsets.SetValue("weapon_sniper_scout", 40);
		g_hWeaponOffsets.SetValue("weapon_sniper_military", 40);
		g_hWeaponOffsets.SetValue("weapon_sniper_awp", 40);
		// g_hWeaponOffsets.SetValue("weapon_grenade_launcher", 68);
	}

	// Indexes for sounds
	g_hWeaponClasses = new StringMap();
	g_hWeaponClasses.SetValue("weapon_pistol", 0);
	g_hWeaponClasses.SetValue("weapon_hunting_rifle", 3);
	g_hWeaponClasses.SetValue("weapon_rifle", 4);
	g_hWeaponClasses.SetValue("weapon_smg", 9);

	if( g_bLeft4Dead2 )
	{
		g_hWeaponClasses.SetValue("weapon_pistol_magnum", 1);
		g_hWeaponClasses.SetValue("weapon_sniper_awp", 2);
		g_hWeaponClasses.SetValue("weapon_rifle_ak47", 5);
		g_hWeaponClasses.SetValue("weapon_rifle_desert", 6);
		g_hWeaponClasses.SetValue("weapon_sniper_scout", 7);
		g_hWeaponClasses.SetValue("weapon_rifle_sg552", 8);
		g_hWeaponClasses.SetValue("weapon_smg_silenced", 10);
		g_hWeaponClasses.SetValue("weapon_smg_mp5", 11);
		g_hWeaponClasses.SetValue("weapon_sniper_military", 12);
	}

	// Allowed weapons cvar
	g_hWeaponAllowed = new StringMap();
	g_hWeaponAllowed.SetValue("weapon_autoshotgun", 1);
	g_hWeaponAllowed.SetValue("weapon_hunting_rifle", 2);
	g_hWeaponAllowed.SetValue("weapon_pistol", 4);
	g_hWeaponAllowed.SetValue("weapon_pistol_magnum", 8);
	g_hWeaponAllowed.SetValue("weapon_pumpshotgun", 16);
	g_hWeaponAllowed.SetValue("weapon_rifle", 32);
	g_hWeaponAllowed.SetValue("weapon_rifle_ak47", 64);
	g_hWeaponAllowed.SetValue("weapon_rifle_desert", 128);
	g_hWeaponAllowed.SetValue("weapon_rifle_sg552", 256);
	g_hWeaponAllowed.SetValue("weapon_shotgun_chrome", 512);
	g_hWeaponAllowed.SetValue("weapon_shotgun_spas", 1024);
	g_hWeaponAllowed.SetValue("weapon_smg", 2048);
	g_hWeaponAllowed.SetValue("weapon_smg_mp5", 4096);
	g_hWeaponAllowed.SetValue("weapon_smg_silenced", 8192);
	g_hWeaponAllowed.SetValue("weapon_sniper_awp", 16384);
	g_hWeaponAllowed.SetValue("weapon_sniper_military", 32768);
	g_hWeaponAllowed.SetValue("weapon_sniper_scout", 65536);

	// L4D1 fix:
	if( !g_bLeft4Dead2 )
	{
		for( int i = 0; i < sizeof(g_sWeaponSounds); i++ )
		{
			g_sWeaponSounds[i][0][0] = '^';
			g_sWeaponSounds[i][1][0] = '^';
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarWeapons = g_hCvarWeapons.IntValue;
	g_iCvarRestart = g_hCvarRestart.IntValue;
	HookFireEvent(!g_bLeft4Dead2 || g_iCvarRestart == 2);
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookFireEvent(!g_bLeft4Dead2 ||g_iCvarRestart == 2);
		HookEvents();

		// Hook active clients
		int weapon;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) )
			{
				SDKHook(i, SDKHook_WeaponSwitchPost, OnSwitchWeapon);

				// Validate current weapon
				weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if( weapon > 0 )
				{
					OnSwitchWeapon(i, weapon);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		HookFireEvent(false);
		UnhookEvents();
		ResetPlugin();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

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
// Only hook fire event if auto reload 2 enabled.
void HookFireEvent(bool hook)
{
	static bool hooked;
	if( hook == true && hooked == false )
	{
		hooked = true;
		HookEvent("weapon_fire",			Event_WeaponFire);
	}
	else if( hook == false && hooked == true )
	{
		hooked = false;
		UnhookEvent("weapon_fire",			Event_WeaponFire);
	}
}

void HookEvents()
{
	if( !g_bLeft4Dead2 )
		HookEvent("weapon_reload",			Event_WeaponReload);
	HookEvent("ammo_pickup",				Event_AmmoPickup);
	HookEvent("player_spawn",				Event_PlayerSpawn);
	HookEvent("player_death",				Event_PlayerDeath);
	HookEvent("player_team",				Event_PlayerTeam);
	HookEvent("round_end",					Event_RoundEnd, EventHookMode_PostNoCopy);
}

void UnhookEvents()
{
	if( !g_bLeft4Dead2 )
		UnhookEvent("weapon_reload",		Event_WeaponReload);
	UnhookEvent("ammo_pickup",				Event_AmmoPickup);
	UnhookEvent("player_spawn",				Event_PlayerSpawn);
	UnhookEvent("player_death",				Event_PlayerDeath);
	UnhookEvent("player_team",				Event_PlayerTeam);
	UnhookEvent("round_end",				Event_RoundEnd, EventHookMode_PostNoCopy);
}

// Auto reload after shooting
public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( (g_iAutoReload[client] || !g_bLeft4Dead2) && !IsFakeClient(client) )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > -1 )
		{
			if( !g_bLeft4Dead2 )
				g_iLastClip[client] = GetEntProp(weapon, Prop_Send, "m_iClip1") - 1;

			if( g_iCvarRestart == 2 )
				g_iWasShoot[client] = g_iForceTicks;
		}
	}
}

public void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && !IsFakeClient(client) )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if( weapon != -1 && EntIndexToEntRef(weapon) == g_iLastHook[client] )
		{
			OnReload(weapon);
		}
	}
}

// Correct stored ammo values when picking up ammo during reload
public void Event_AmmoPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && !IsFakeClient(client) )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon != -1 && GetEntProp(weapon, Prop_Send, "m_bInReload") )
		{
			g_iLastAmmo[client] = GetOrSetPlayerAmmo(client, weapon) - g_iLastClip[client];
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && GetClientTeam(client) == 2 && !IsFakeClient(client) )
	{
		ResetVars(client);

		SDKHook(client, SDKHook_WeaponSwitchPost, OnSwitchWeapon);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetVars(client);

		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnSwitchWeapon);
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		ResetVars(client);

		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnSwitchWeapon);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	char sPath[PLATFORM_MAX_PATH];

	for( int i = 0; i < sizeof(g_sWeaponSounds); i++ )
	{
		Format(sPath, sizeof(sPath), "sound/%s", g_sWeaponSounds[i][0][1]);
		if( FileExists(sPath) )
		{
			// PrintToServer("CACHE SOUND A %d [%s]", i, sPath);
			PrecacheSound(g_sWeaponSounds[i][0][1]);
		}

		Format(sPath, sizeof(sPath), "sound/%s", g_sWeaponSounds[i][1][1]);
		if( FileExists(sPath) )
		{
			// PrintToServer("CACHE SOUND B %d [%s]", i, sPath);
			PrecacheSound(g_sWeaponSounds[i][1][1]);
		}
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		ResetVars(i);

		if( IsClientInGame(i) )
		{
			SDKUnhook(i, SDKHook_WeaponSwitchPost, OnSwitchWeapon);
		}
	}
}

void ResetVars(int client)
{
	g_iLastAmmo[client] = 0;
	g_iLastClip[client] = 0;
	g_iLastHook[client] = 0;
	g_iWasShoot[client] = 0;
	g_iAutoReload[client] = 0;

}



// ====================================================================================================
//					RELOAD STUFF
// ====================================================================================================
void OnSwitchWeapon(int client, int weapon)
{
	// Unhook last weapon
	if( g_bLeft4Dead2 )
	{
		int last = g_iLastHook[client];
		if( last && EntRefToEntIndex(last) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(last, SDKHook_Reload, OnReload);
		}
	}

	g_iLastAmmo[client] = 0;
	g_iLastClip[client] = 0;
	g_iLastHook[client] = 0;
	g_iWasShoot[client] = 0;
	g_iAutoReload[client] = 0;

	if( !IsValidEntity(weapon) || IsFakeClient(client) )
		return;

	// Validate new weapon
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	// Allowed weapons
	int offset;
	g_hWeaponAllowed.GetValue(sWeapon, offset);
	if( offset == 0 || !(g_iCvarWeapons & offset) )
		return;

	// Ignore melee - probably not required since above check doesn't include melee weapons
	if( g_bLeft4Dead2 && strcmp(sWeapon[7], "melee") == 0 )
		return;

	if( strncmp(sWeapon[7], "pistol", 6) == 0 )
	{
		g_iAutoReload[client] = 2;
		g_iLastHook[client] = EntIndexToEntRef(weapon);
		if( g_bLeft4Dead2 ) // Exception reported: Hook type not supported on this game
			SDKHook(weapon, SDKHook_Reload, OnReload);

		if( !g_bLeft4Dead2 )
		{
			g_iLastAmmo[client] = GetOrSetPlayerAmmo(client, weapon);
			g_iLastClip[client] = GetEntProp(weapon, Prop_Send, "m_iClip1");
		}
	}
	else
	{
		offset = 0;
		g_hWeaponOffsets.GetValue(sWeapon, offset);

		if( offset )
		{
			g_iAutoReload[client] = (offset == 28 || offset == 32) ? 3 : 1;
			g_iLastHook[client] = EntIndexToEntRef(weapon);
			if( g_bLeft4Dead2 )
				SDKHook(weapon, SDKHook_Reload, OnReload);

			if( !g_bLeft4Dead2 )
			{
				g_iLastAmmo[client] = GetOrSetPlayerAmmo(client, weapon);
				g_iLastClip[client] = GetEntProp(weapon, Prop_Send, "m_iClip1");
			}
		}
	}
}

// Store reserve ammo and clip ammo to restore if shooting interrupts reloading.
void OnReload(int weapon)
{
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");

	if( g_iAutoReload[client] == 3 ) // Shotguns don't store clip size, they don't reset to 0 on reload
	{
		g_iLastClip[client] = -1;
	}
	else
	{
		if( g_iAutoReload[client] == 1 ) // Save reserve ammo value for non-pistols
			g_iLastAmmo[client] = GetOrSetPlayerAmmo(client, weapon);

		if( g_bLeft4Dead2 )
			g_iLastClip[client] = GetEntProp(weapon, Prop_Send, "m_iClip1");

		RequestFrame(OnFrame, EntIndexToEntRef(weapon)); // Set clip ammo so it doesn't display as 0
	}
}

public void OnFrame(int weapon)
{
	weapon = EntRefToEntIndex(weapon);
	if( IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_bInReload") )
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
		if( client > 0 )
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", g_iLastClip[client]);

			if( g_bLeft4Dead2 )
				GetOrSetPlayerAmmo(client, weapon, g_iLastAmmo[client]);
			else
				GetOrSetPlayerAmmo(client, weapon, g_iLastAmmo[client] - g_iLastClip[client]);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Survivor shooting
	if( buttons & IN_ATTACK && g_iAutoReload[client] && !IsFakeClient(client) )
	{
		if( g_iLastClip[client] ) // && GetClientTeam(client) == 2 && IsPlayerAlive(client)  // Probably don't need checks, they should be handled via events and hooking OnReload
		{
			// Has weapon, is reloading and clip not empty
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			if( weapon > 0 && GetEntProp(weapon, Prop_Send, "m_bInReload") )
			{
				// Play shooting sounds since it bugs and doesn't play when shooting after during reload
				int index = -1;
				static char classname[32];
				GetEdictClassname(weapon, classname, sizeof(classname));
				g_hWeaponClasses.GetValue(classname, index);
				if( index != -1 )
				{
					// Play incendiary ammo sound if required
					int type = g_bLeft4Dead2 && GetEntProp(weapon, Prop_Send, "m_upgradeBitVec") & 1;
					EmitSoundToClient(client, g_sWeaponSounds[index][type], client, SNDCHAN_WEAPON, SNDLEVEL_MINIBIKE, SND_NOFLAGS, index ? 1.0 : 0.649902); // Pistol has reduced volume
				}

				// Auto reload after shooting?
				if( g_iCvarRestart == 1 )
				{
					g_iWasShoot[client] = g_iForceTicks;
				}

				// Not a shotgun, interrupt reload
				if( g_iLastClip[client] != -1 )
				{
					// Stop reloading
					float time = GetGameTime();
					SetEntProp(weapon, Prop_Send, "m_bInReload", 0);
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", time);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", time);
					// SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", time); // No (enabled) secondary weapon functions in L4D/2

					// Restore clip and reserve ammo
					SetEntProp(weapon, Prop_Send, "m_iClip1", g_iLastClip[client]);
					if( g_bLeft4Dead2 )
						GetOrSetPlayerAmmo(client, weapon, g_iLastAmmo[client]);
					else
						GetOrSetPlayerAmmo(client, weapon, g_iLastAmmo[client] - g_iLastClip[client]);
				}
			}
		}
	}
	else if( g_iWasShoot[client] && !IsFakeClient(client) )
	{
		// Auto reload
		g_iWasShoot[client]--;
		buttons |= IN_RELOAD;
	}
}

// Reserve ammo
int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	char sWeapon[32];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

	int offset;
	g_hWeaponOffsets.GetValue(sWeapon, offset);

	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}