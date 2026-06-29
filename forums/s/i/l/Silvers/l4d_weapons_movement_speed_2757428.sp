/*
*	Weapons Movement Speed
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



#define PLUGIN_VERSION 		"1.1 beta"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Weapons Movement Speed
*	Author	:	SilverShot
*	Descrp	:	Sets player speed based on the weapon carried.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334240
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 beta (10-Sep-2021)
	- Now considers survivors limp health.
	- Added "hurt" key to the config for limp speed.
	- Changed the method of setting player speed.
	- Config default values are "0.0" now.
	- Removed Left4DHooks requirement.

1.0 (09-Sep-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// #include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CONFIG_DATA			"data/l4d_weapons_movement_speed.cfg"

#define GRAVITY_OFFSET		0.05	// Skew player gravity with this according to speed, not proper value to skew with, don't know how to adjust properly.
#define MAX_SPEED_RUN		150.0
#define MAX_SPEED_WALK		220.0
#define MAX_SPEED_CROUCH	85.0
#define MAX_SPEED_HURT		149.9


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDecayRate, g_hCvarLimpHealth;
bool g_bCvarAllow, g_bMapStarted;
bool g_bIsJumping[MAXPLAYERS+1];
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

	return APLRes_Success;
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
	g_hCvarAllow.AddChangeHook(ConVarChanged_Cvars);
}

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

		HookEvent("player_jump", Event_PlayerJump);

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

		UnhookEvent("player_jump", Event_PlayerJump);

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
}



// ====================================================================================================
// EVENTS
// ====================================================================================================
public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIsJumping[client] = true;
}



// ====================================================================================================
// WEAPON SWITCH
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	g_bHookedThink[client] = false;
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch(int client, int weapon)
{
	int current = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if( current != -1 )
	{
		static char sClass[64];
		GetEdictClassname(current, sClass, sizeof(sClass));

		// Match weapon classname to set speed, if available
		if( g_smSpeedHurt.GetValue(sClass,		g_fSpeedHurt[client]) == false )	g_fSpeedHurt[client] = 0.0;
		if( g_smSpeedRun.GetValue(sClass,		g_fSpeedRun[client]) == false )		g_fSpeedRun[client] = 0.0;
		if( g_smSpeedWalk.GetValue(sClass,		g_fSpeedWalk[client]) == false )	g_fSpeedWalk[client] = 0.0;
		if( g_smSpeedCrouch.GetValue(sClass,	g_fSpeedCrouch[client]) == false )	g_fSpeedCrouch[client] = 0.0;

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
				int g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
				SetEntDataFloat(client, g_flLagMovement, 1.0, true);
				SetEntityGravity(client, 1.0);
			}
		}
	} else {
		// Unhook - no speed setting
		if( g_bHookedThink[client] == true )
		{
			g_bHookedThink[client] = false;
			SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPost);
			int g_flLagMovement = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
			SetEntDataFloat(client, g_flLagMovement, 1.0, true);
			SetEntityGravity(client, 1.0);
		}
	}
}



// ====================================================================================================
// SET SPEED
// ====================================================================================================
public void PreThinkPost(int client)
{
	// Block changing things so gravity does not change while jumping
	if( g_bIsJumping[client] )
	{
		if( GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1 )
			return;
			
		g_bIsJumping[client] = false;
	}

	// Get health, check for limp speed
	if( g_fSpeedHurt[client] )
	{
		float fGameTime = GetGameTime();
		float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		fHealth -= (fGameTime - fHealthTime) * g_fCvarDecayRate;
		if( fHealth < 0.0 ) fHealth = 0.0;

		// Ignore when 1.0 hp, so it's slow like the game does, but change to "hurt" value for limping
		int iHealth = GetClientHealth(client);
		if( iHealth + fHealth > 1.0 && iHealth + fHealth <= g_iCvarLimpHealth )
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fSpeedHurt[client]);

			SetEntityGravity(client, 1.0 / g_fSpeedHurt[client] - GRAVITY_OFFSET);
			return;
		}
	}

	// Set speed
	int buttons = GetClientButtons(client);

	if( g_fSpeedCrouch[client] && buttons & IN_DUCK )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fSpeedCrouch[client]);

		SetEntityGravity(client, 1.0 / g_fSpeedCrouch[client] - GRAVITY_OFFSET);
	}
	else if( g_fSpeedWalk[client] && buttons & IN_SPEED )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fSpeedWalk[client]);

		SetEntityGravity(client, 1.0 / g_fSpeedWalk[client] - GRAVITY_OFFSET);
	}
	else if( g_fSpeedRun[client] )
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fSpeedRun[client]);

		SetEntityGravity(client, 1.0 / g_fSpeedRun[client] - GRAVITY_OFFSET);
	}
}

/*
// Old method using Left4DHooks - causes stutter.	
public Action L4D_OnGetRunTopSpeed(int client, float &retVal)
{
	if( g_fSpeedRun[client] )
	{
		retVal = g_fSpeedRun[client];
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_OnGetWalkTopSpeed(int client, float &retVal)
{
	if( g_fSpeedWalk[client] )
	{
		retVal = g_fSpeedWalk[client];
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_OnGetCrouchTopSpeed(int client, float &retVal)
{
	if( g_fSpeedCrouch[client] )
	{
		retVal = g_fSpeedCrouch[client];
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
*/