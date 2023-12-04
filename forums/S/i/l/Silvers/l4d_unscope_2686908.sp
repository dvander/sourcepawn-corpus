/*
*	Unscope Sniper On Shoot
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"1.10"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Unscope Sniper On Shoot
*	Author	:	SilverShot
*	Descrp	:	Un-zooms Sniper scopes on each shot.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322064
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.10 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.9 (11-Oct-2021)
	- Fixed Zoom and Unzoom logic being inverted.

1.8 (02-Jul-2021)
	- Fixed randommly vocalizing. No more hackish workarounds, zooms and unzooms correctly. Thanks to "Iizuka07" for testing.

1.7 (01-Jul-2021)
	- Fixed crashing by deleting entities in "SDKHook_SpawnPost" instead of "OnEntityCreated". Thanks to "Iizuka07" for reporting.

1.6 (29-Jun-2021)
	- Fixed vocalizing when unscoping. Thanks to "Iizuka07" for reporting.

1.5 (26-Jun-2021)
	- Fixed rescope feature adding zoom when changing weapon straight after. Thanks to "Iizuka07" for reporting.

1.4 (24-May-2021)
	- Added cvar "l4d_unscope_rescope" to rescope bolt action snipers after shooting and reloading. Requested by "AI0702".

1.3 (23-May-2021)
	- Fixed not unscoping while the players eyes are moving into scoped view. Thanks to "AI0702" for reporting.
	- Removed gamedata dependency.

1.2a (24-Sep-2020)
	- Compatibility update for L4D2's "The Last Stand" update.
	- GameData .txt file updated.

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (14-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_unscope"


ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarMPGameMode, g_hCvarRescope, g_hCvarTypes;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iCvarRescope, g_iCvarTypes;
Handle g_hTimerRescope[MAXPLAYERS+1];
StringMap g_aWeaponIDs;
ArrayList g_hTypes;



// ====================================================================================================
//					PLUGIN START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Unscope Sniper On Shoot",
	author = "SilverShot",
	description = "Un-zooms Sniper scopes on each shot.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322064"
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
	g_hCvarAllow =		CreateConVar(	"l4d_unscope_allow",			"1",							"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_unscope_modes",			"",								"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_unscope_modes_off",		"",								"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_unscope_modes_tog",		"0",							"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRescope =	CreateConVar(	"l4d_unscope_rescope",			"1",							"0=Off. 1=Rescope the view after shooting and reloading bolt action rifles (AWP and Scout).", CVAR_FLAGS );
	g_hCvarTypes =		CreateConVar(	"l4d_unscope_types",			g_bLeft4Dead2 ? "15" : "1",		"1=Hunting Rifle. L4D2 only: 2=Sniper Military, 4=Sniper AWP, 8=Sniper Scout. 15=All. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d_unscope_version",			PLUGIN_VERSION,					"Unscope Sniper plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_unscope");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRescope.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);

	g_aWeaponIDs = new StringMap();
	g_hTypes = new ArrayList();

	g_aWeaponIDs.SetValue("weapon_hunting_rifle",	6);
	g_aWeaponIDs.SetValue("weapon_sniper_awp",		35);
	g_aWeaponIDs.SetValue("weapon_sniper_scout",	36);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarRescope = g_hCvarRescope.IntValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;

	g_hTypes.Clear();

	if( g_iCvarTypes & (1<<0) ) g_hTypes.Push(6);	// weapon_hunting_rifle
	if( g_bLeft4Dead2 )
	{
		if( g_iCvarTypes & (1<<1) ) g_hTypes.Push(10);	// weapon_sniper_military
		if( g_iCvarTypes & (1<<2) ) g_hTypes.Push(35);	// weapon_sniper_awp
		if( g_iCvarTypes & (1<<3) ) g_hTypes.Push(36);	// weapon_sniper_scout
	}
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("weapon_fire", Event_WeaponFire);
		HookEvent("weapon_zoom", Event_WeaponZoom);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("weapon_fire", Event_WeaponFire);
		UnhookEvent("weapon_zoom", Event_WeaponZoom);
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int weaponID = event.GetInt("weaponid");

	if( g_hTypes.FindValue(weaponID) != -1 )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		// Unscope
		if( GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") != -1 )
		{
			UnzoomWeapon(client);

			// Rescope
			if( g_iCvarRescope && (weaponID == 35 || weaponID == 36) )
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if( GetEntProp(weapon, Prop_Send, "m_iClip1") > 1 )
				{
					delete g_hTimerRescope[client];
					g_hTimerRescope[client] = CreateTimer(1.1, TimerRescope, GetClientUserId(client));
				}
			}
		} else {
			// Prevent rescoping if firing before scoping timer finishes
			delete g_hTimerRescope[client];
		}
	}
}

// Prevent scoping while reloading
void Event_WeaponZoom(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarRescope )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( g_hTimerRescope[client] != null )
		{
			if( GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") != -1 )
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if( weapon != -1 )
				{
					// Verify sniper?
					static char classname[24];
					GetEdictClassname(weapon, classname, sizeof(classname));

					if( g_aWeaponIDs.ContainsKey(classname) )
					{
						UnzoomWeapon(client);
					}
				}
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_hTimerRescope[client] = null;
}

Action TimerRescope(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		g_hTimerRescope[client] = null;

		// Only scope if on ground
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon != -1 && GetPlayerWeaponSlot(client, 0) == weapon && GetEntityFlags(client) & FL_ONGROUND )
		{
			ZoomWeapon(client);
		}
	}

	return Plugin_Continue;
}

void UnzoomWeapon(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.0);
	SetEntProp(client, Prop_Send, "m_iFOV", 0);
}

void ZoomWeapon(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", client);
	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.3000);
	SetEntProp(client, Prop_Send, "m_iFOV", 40);
}