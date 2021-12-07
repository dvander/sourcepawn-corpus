/*
*	Grenade Launcher Screen Shake
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



#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Grenade Launcher Screen Shake
*	Author	:	SilverShot
*	Descrp	:	Allows the Grenade Launcher explosion to create a screen shake near players.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332047
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (30-Jun-2021)
	- Fixed "Invalid edict" error. Thanks to "Iizuka07" for reporting.

1.0 (20-Apr-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRange, g_hCvarForce;
float g_fCvarRange, g_fCvarForce, g_fExplode;
bool g_bCvarAllow, g_bMapStarted;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Grenade Launcher Screen Shake",
	author = "SilverShot",
	description = "Allows the Grenade Launcher explosion to create a screen shake near players.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332047"
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
	g_hCvarAllow =			CreateConVar(	"l4d2_gl_shake_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_gl_shake_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_gl_shake_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_gl_shake_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRange =			CreateConVar(	"l4d2_gl_shake_range",			"600.0",			"The maximum distance the screen shake can affect players.", CVAR_FLAGS );
	g_hCvarForce =			CreateConVar(	"l4d2_gl_shake_force",			"32.0",				"How intense the screen shake will be, falls off over range.", CVAR_FLAGS );
	CreateConVar(							"l4d2_gl_shake_version",		PLUGIN_VERSION,		"Grenade Launcher Screen Shake plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_gl_shake");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);

	IsAllowed();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;

	// Pre-cache env_shake -_- WTF
	int shake = CreateEntityByName("env_shake");
	if( shake != -1 )
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		DispatchKeyValue(shake, "radius", "50");
		TeleportEntity(shake, view_as<float>({ 0.0, 0.0, -1000.0 }), NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");
		AcceptEntityInput(shake, "StartShake");
		RemoveEdict(shake);
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
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
	g_fCvarRange = g_hCvarRange.FloatValue;
	g_fCvarForce = g_hCvarForce.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		AddNormalSoundHook(SoundHook);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		RemoveNormalSoundHook(SoundHook);
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
// To detect Grenade Launcher Projectile detonation (whilst supporting Flare Gun plugin).
// There is no event or easy method to detect detonation. This uses sound event and OnEntityDestroyed to match.
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(
		(strcmp(sample, "weapons/hegrenade/explode1.wav") == 0 ) ||
		(strcmp(sample, "weapons/hegrenade/explode2.wav") == 0 ) ||
		(strcmp(sample, "weapons/hegrenade/explode3.wav") == 0 ) ||
		(strcmp(sample, "weapons/hegrenade/explode4.wav") == 0 ) ||
		(strcmp(sample, "weapons/hegrenade/explode5.wav") == 0 ) ||
		(strcmp(sample, ")weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav") == 0 ) ||
		(strcmp(sample, ")weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav") == 0 )
	)
	{
		g_fExplode = GetGameTime() + 0.1;
	}
}

public void OnEntityDestroyed(int entity)
{
	if( g_bCvarAllow && g_fExplode > GetGameTime() && IsValidEdict(entity) )
	{
		static char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));

		if( strcmp(classname, "grenade_launcher_projectile") == 0 )
		{
			g_fExplode = 0.0;

			float vPos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
			CreateShake(g_fCvarForce, g_fCvarRange, vPos);
		}
	}
}

void CreateShake(float intensity, float range, float vPos[3])
{
	if( !g_bMapStarted ) return;

	int entity = CreateEntityByName("env_shake");
	if( entity == -1 )
	{
		LogError("Failed to create 'env_shake'");
		return;
	}

	static char sTemp[8];
	FloatToString(intensity, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "amplitude", sTemp);
	DispatchKeyValue(entity, "frequency", "1.5");
	DispatchKeyValue(entity, "duration", "0.9");
	FloatToString(range, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "radius", sTemp);
	DispatchKeyValue(entity, "spawnflags", "8");
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Enable");

	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "StartShake");
	RemoveEdict(entity);
}