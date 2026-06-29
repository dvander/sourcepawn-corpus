/*
*	Weapons Movement Speed
*	Copyright (C) 2023 Silvers
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



#define PLUGIN_VERSION 		"2.7"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Weapons Movement Speed
*	Author	:	SilverShot
*	Descrp	:	Sets player speed based on the weapon carried.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334240
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.7 (24-Nov-2023)
	- Fixed movement speed bug after staggering when the stagger timer didn't reset (due to some plugins such as "Stagger Gravity").

2.6 (10-Feb-2023)
	- Fixed not hooking the "pain_pills_decay_rate" and "survivor_limp_health" cvar changes.
	- Minor changes to fix compatibility with the "Lagged Movement" plugin.

2.5 (26-Nov-2022)
	- Fixed fix property not found errors.
	- Plugin now resets speed to default on plugin end.

2.4 (12-Nov-2022)
	- Fixed the Run and Walk speeds being inverted.
	- Now optionally uses the "Lagged Movement" plugin by "Silvers" to prevent conflicts when multiple plugins try to set player speed:
	- https://forums.alliedmods.net/showthread.php?t=340345

2.3 (10-Nov-2022)
	- Fixed setting the wrong velocity when jumping. Thanks to "Maur0" for reporting.

2.2 (08-Nov-2022)
	- Fixed the players velocity resetting to default when jumping or staggering. Thanks to "Eärendil" for reporting.

2.1 (03-Nov-2022)
	- Fixed client not connected errors. Thanks to "sonic155" for reporting.

2.0 (02-Nov-2022)
	- Removed Left4DHooks plugin requirement.
	- Added "hurt" key to the config to consider the survivors limp health.
	- Added melee weapons support. Also supports all 3rd party melee weapons using their script name.
	- Changed the method of setting player speed.
	- Config default values are "0.0" now.
	- Fixed jumping or staggering movement speed bug.
	- Fixed affecting Special Infected ghosts.

1.0 (09-Sep-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CONFIG_DATA			"data/l4d_weapons_movement_speed.cfg"

#define MAX_SPEED_RUN		220.0
#define MAX_SPEED_WALK		150.0
#define MAX_SPEED_CROUCH	85.0
#define MAX_SPEED_HURT		149.9


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDecayRate, g_hCvarLimpHealth;
bool g_bCvarAllow, g_bMapStarted, g_bLaggedMovement;
bool g_bHookedThink[MAXPLAYERS+1];
float g_fSpeedHurt[MAXPLAYERS+1];
float g_fSpeedRun[MAXPLAYERS+1];
float g_fSpeedWalk[MAXPLAYERS+1];
float g_fSpeedCrouch[MAXPLAYERS+1];
float g_fCvarDecayRate;
int g_iCvarLimpHealth;
StringMap g_smSpeedHurt;
StringMap g_smSpeedRun;
StringMap g_smSpeedWalk;
StringMap g_smSpeedCrouch;

native any L4D_LaggedMovement(int client, float value, bool force = false);



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Weapons Movement Speed",
	author = "SilverShot",
	description = "Sets player speed based on the weapon carried.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334240"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("L4D_LaggedMovement");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "LaggedMovement") == 0 )
	{
		g_bLaggedMovement = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "LaggedMovement") == 0 )
	{
		g_bLaggedMovement = false;
	}
}

public void OnPluginStart()
{
	// ====================
	// CVARS
	// ====================
	g_hCvarAllow =		CreateConVar(	"l4d_weapons_movement_speed_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_weapons_movement_speed_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_weapons_movement_speed_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_weapons_movement_speed_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d_weapons_movement_speed_version",		PLUGIN_VERSION,		"Weapons Movement Speed plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_weapons_movement_speed");

	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarLimpHealth = FindConVar("survivor_limp_health");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDecayRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLimpHealth.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(i, 1.0, true) : 1.0);
		}
	}
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
	g_fCvarDecayRate = g_hCvarDecayRate.FloatValue;
	g_iCvarLimpHealth = g_hCvarLimpHealth.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("player_death", Event_PlayerDeath);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
				OnWeaponSwitch(i, -1);
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
				if( g_bHookedThink[i] )
				{
					g_bHookedThink[i] = false;
					SDKUnhook(i, SDKHook_PreThinkPost, PreThinkPost);
				}
			}
		}
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
// LOAD CONFIG
// ====================================================================================================
public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	LoadConfig();
}

void LoadConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	KeyValues hFile = new KeyValues("weapons");
	if( !hFile.ImportFromFile(sPath) )
	{
		SetFailState("Error loading file: \"%s\". Try replacing the file with the original.", sPath);
	}

	// ====================
	// FILL ARRAYS
	// ====================
	delete g_smSpeedHurt;
	delete g_smSpeedRun;
	delete g_smSpeedWalk;
	delete g_smSpeedCrouch;

	g_smSpeedHurt = new StringMap();
	g_smSpeedRun = new StringMap();
	g_smSpeedWalk = new StringMap();
	g_smSpeedCrouch = new StringMap();

	char sClass[64];
	hFile.GotoFirstSubKey();
	do
	{
		hFile.GetSectionName(sClass, sizeof(sClass));
		g_smSpeedHurt.SetValue(sClass,		hFile.GetFloat("hurt"));
		g_smSpeedRun.SetValue(sClass,		hFile.GetFloat("run"));
		g_smSpeedWalk.SetValue(sClass,		hFile.GetFloat("walk"));
		g_smSpeedCrouch.SetValue(sClass,	hFile.GetFloat("crouch"));
	} while (hFile.GotoNextKey());

	delete hFile;

	g_smSpeedHurt.SetValue("weapon_melee", -3.14);
	g_smSpeedRun.SetValue("weapon_melee", -3.14);
	g_smSpeedWalk.SetValue("weapon_melee", -3.14);
	g_smSpeedCrouch.SetValue("weapon_melee", -3.14);
}



// ====================================================================================================
// EVENTS
// ====================================================================================================
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		OnWeaponSwitch(client, -1);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
	{
		if( g_bHookedThink[client] == true )
		{
			g_bHookedThink[client] = false;
			SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_bHookedThink[client] = false;
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}



// ====================================================================================================
// WEAPON SWITCH
// ====================================================================================================
void OnWeaponSwitch(int client, int weapon)
{
	int current = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if( GetEntProp(client, Prop_Send, "m_isGhost") == 1 )
	{
		current = -1;
	}

	if( current != -1 )
	{
		static char sClass[64];
		GetEdictClassname(current, sClass, sizeof(sClass));

		// Match weapon classname to set speed, if available
		if( g_smSpeedHurt.GetValue(sClass,			g_fSpeedHurt[client]) == false )	g_fSpeedHurt[client] = 0.0;

		// Melee weapons
		if( g_fSpeedHurt[client] == -3.14 )
		{
			GetEntPropString(current, Prop_Data, "m_strMapSetScriptName", sClass, sizeof(sClass));

			if( g_smSpeedHurt.GetValue(sClass,		g_fSpeedHurt[client]) == false )	g_fSpeedHurt[client] = 0.0;
			if( g_smSpeedRun.GetValue(sClass,		g_fSpeedRun[client]) == false )		g_fSpeedRun[client] = 0.0;
			if( g_smSpeedWalk.GetValue(sClass,		g_fSpeedWalk[client]) == false )	g_fSpeedWalk[client] = 0.0;
			if( g_smSpeedCrouch.GetValue(sClass,	g_fSpeedCrouch[client]) == false )	g_fSpeedCrouch[client] = 0.0;
		}
		else
		{
			if( g_smSpeedRun.GetValue(sClass,		g_fSpeedRun[client]) == false )		g_fSpeedRun[client] = 0.0;
			if( g_smSpeedWalk.GetValue(sClass,		g_fSpeedWalk[client]) == false )	g_fSpeedWalk[client] = 0.0;
			if( g_smSpeedCrouch.GetValue(sClass,	g_fSpeedCrouch[client]) == false )	g_fSpeedCrouch[client] = 0.0;
		}

		// Work out percentage for "m_flLaggedMovementValue" value.
		if( g_fSpeedHurt[client] )		g_fSpeedHurt[client]		= g_fSpeedHurt[client]		/ MAX_SPEED_HURT;
		if( g_fSpeedRun[client] )		g_fSpeedRun[client]			= g_fSpeedRun[client]		/ MAX_SPEED_RUN;
		if( g_fSpeedWalk[client] )		g_fSpeedWalk[client]		= g_fSpeedWalk[client]		/ MAX_SPEED_WALK;
		if( g_fSpeedCrouch[client] )	g_fSpeedCrouch[client]		= g_fSpeedCrouch[client]	/ MAX_SPEED_CROUCH;

		if( g_fSpeedHurt[client] || g_fSpeedRun[client] || g_fSpeedWalk[client] || g_fSpeedCrouch[client] )
		{
			// Hook - set speed
			if( g_bHookedThink[client] == false )
			{
				g_bHookedThink[client] = true;
				SDKHook(client, SDKHook_PreThinkPost, PreThinkPost);
			}
		} else {
			// Unhook - no speed setting
			if( g_bHookedThink[client] == true )
			{
				g_bHookedThink[client] = false;
				SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);

				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			}
		}
	} else {
		// Unhook - no speed setting
		if( g_bHookedThink[client] == true )
		{
			g_bHookedThink[client] = false;
			SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
		}
	}
}



// ====================================================================================================
// SET SPEED
// ====================================================================================================
void PreThinkPost(int client)
{
	// =========================
	// Plugins should include this code within their PreThinkPost function when modifying the m_flLaggedMovementValue value to prevent bugs
	// Written by "Silvers"
	// =========================
	// Fix movement speed bug when jumping or staggering
	if( GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > GetGameTime() )
	{
		// Fix jumping resetting velocity to default
		float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
		if( value != 1.0 )
		{
			float vVec[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
			float height = vVec[2];

			ScaleVector(vVec, value);
			vVec[2] = height; // Maintain default jump height

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
		}

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
		return;
	}
	// =========================



	// Get health, check for limp speed
	if( g_fSpeedHurt[client] )
	{
		float fGameTime = GetGameTime();
		float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;
		if( fHealth < 0.0 ) fHealth = 0.0;

		// Ignore when 1.0 hp, so it's slow like the game does, but change to "hurt" value for limping
		fHealth += GetClientHealth(client);
		if( fHealth > 1.0 && fHealth <= g_iCvarLimpHealth )
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, g_fSpeedHurt[client]) : g_fSpeedHurt[client]);
			return;
		}
	}

	// Set speed
	int buttons = GetClientButtons(client);

	if( g_fSpeedCrouch[client] && buttons & IN_DUCK )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, g_fSpeedCrouch[client]) : g_fSpeedCrouch[client]);
	}
	else if( g_fSpeedWalk[client] && buttons & IN_SPEED )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, g_fSpeedWalk[client]) : g_fSpeedWalk[client]);
	}
	else if( g_fSpeedRun[client] )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_bLaggedMovement ? L4D_LaggedMovement(client, g_fSpeedRun[client]) : g_fSpeedRun[client]);
	}
}