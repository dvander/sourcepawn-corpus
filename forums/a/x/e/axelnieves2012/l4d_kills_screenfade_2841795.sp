/*
*	Kills Screen Fade
*	Copyright (C) 2025 Axel Juan Nieves, thaivanco123
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



#define PLUGIN_VERSION		"1.1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Kills Screen Fade
*	Author	:	Axel Juan Nieves, JustMe (thaivanco123)
*	Descrp	:	This plugin will do a short screen fade to the survivor who killed a special infected.
*	Link	:	https://forums.alliedmods.net/showthread.php?p=2841795

========================================================================================
	Change Log:
1.0.1 (12-Jan-2025)
	- L4D1 and L4D2

1.0 (11-Jan-2025)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define FFADE_IN			0x0001
#define FFADE_OUT			0x0002
#define FFADE_PURGE			0x0010



// ====================================================================================================
//					PLUGIN VARS
// ====================================================================================================
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarColorR, g_hCvarColorG, g_hCvarColorB, g_hCvarColorA;
ConVar g_hCvarDuration, g_hCvarInfected, g_hCvarWitch, g_hCvarMolotov;

bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iCvarColorR, g_iCvarColorG, g_iCvarColorB, g_iCvarColorA;
int g_iCvarDuration, g_iCvarInfected, g_iCvarWitch;
bool g_bCvarMolotov;

int g_iWitchFireAttacker[2049];
float g_fWitchFireTime[2049];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Kills Screen Fade",
	author = "Axel Juan Nieves, JustMe (thaivanco123)",
	description = "This plugin will do a short screen fade to the survivor who killed a special infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2841795"
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
	// L4D1: 2=Smoker, 4=Boomer, 8=Hunter, 32=Tank -> Default 14, Max 46
	// L4D2: 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 256=Tank -> Default 126, Max 382
	char sDefaultInfected[8], sInfectedDesc[256];
	float fMaxInfected;

	if( g_bLeft4Dead2 )
	{
		sDefaultInfected = "126";
		fMaxInfected = 382.0;
		sInfectedDesc = "Which infected trigger screen fade? Add values: 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 256=Tank (Default 126 = all except Tank)";
	}
	else
	{
		sDefaultInfected = "14";
		fMaxInfected = 46.0;
		sInfectedDesc = "Which infected trigger screen fade? Add values: 2=Smoker, 4=Boomer, 8=Hunter, 32=Tank (Default 14 = all except Tank)";
	}

	// Cvars
	g_hCvarAllow =		CreateConVar(	"l4d_kills_screenfade_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_kills_screenfade_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_kills_screenfade_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_kills_screenfade_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarColorR =		CreateConVar(	"l4d_kills_screenfade_red",			"0",			"Red color value (0-255).", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarColorG =		CreateConVar(	"l4d_kills_screenfade_green",		"255",			"Green color value (0-255).", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarColorB =		CreateConVar(	"l4d_kills_screenfade_blue",		"0",			"Blue color value (0-255).", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarColorA =		CreateConVar(	"l4d_kills_screenfade_alpha",		"64",			"Alpha/transparency value (0-255).", CVAR_FLAGS, true, 0.0, true, 255.0 );
	g_hCvarDuration =	CreateConVar(	"l4d_kills_screenfade_duration",	"20",			"Screen fade hold duration in milliseconds.", CVAR_FLAGS, true, 0.0 );
	g_hCvarInfected =	CreateConVar(	"l4d_kills_screenfade_infected",	sDefaultInfected, sInfectedDesc, CVAR_FLAGS, true, 0.0, true, fMaxInfected );
	g_hCvarWitch =		CreateConVar(	"l4d_kills_screenfade_witch",		"1",			"Witch kill triggers screen fade? 0=No, 1=Always, 2=Crowned only.", CVAR_FLAGS, true, 0.0, true, 2.0 );
	g_hCvarMolotov =	CreateConVar(	"l4d_kills_screenfade_molotov",		"1",			"Fade screen if infected dies from fire? 0=No, 1=Yes (applies to both SI and Witch).", CVAR_FLAGS, true, 0.0, true, 1.0 );
	CreateConVar(						"l4d_kills_screenfade_version",		PLUGIN_VERSION,	"Kills Screen Fade plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_kills_screenfade");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarColorR.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorG.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorB.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColorA.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarWitch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMolotov.AddChangeHook(ConVarChanged_Cvars);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
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
	g_iCvarColorR = g_hCvarColorR.IntValue;
	g_iCvarColorG = g_hCvarColorG.IntValue;
	g_iCvarColorB = g_hCvarColorB.IntValue;
	g_iCvarColorA = g_hCvarColorA.IntValue;
	g_iCvarDuration = g_hCvarDuration.IntValue;
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_iCvarWitch = g_hCvarWitch.IntValue;
	g_bCvarMolotov = g_hCvarMolotov.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("witch_killed", Event_WitchKilled);
		HookEvent("infected_hurt", Event_InfectedHurt);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("witch_killed", Event_WitchKilled);
		UnhookEvent("infected_hurt", Event_InfectedHurt);
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
			if( IsValidEntity(entity) )
				RemoveEdict(entity);
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
//					MAP
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetWitchTracking();
}

void ResetWitchTracking()
{
	for( int i = 0; i < sizeof(g_iWitchFireAttacker); i++ )
	{
		g_iWitchFireAttacker[i] = 0;
		g_fWitchFireTime[i] = 0.0;
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("entityid");
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int type = event.GetInt("type");

	// DMG_BURN = 8
	if( !(type & 8) )
		return;

	if( !IsValidEntity(entity) )
		return;

	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	if( !StrEqual(classname, "witch") )
		return;

	if( attacker && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR )
	{
		g_iWitchFireAttacker[entity] = attacker;
		g_fWitchFireTime[entity] = GetGameTime();
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if( !attacker || !IsClientInGame(attacker) )
		return;

	if( !victim || !IsClientInGame(victim) )
		return;

	if( GetClientTeam(victim) != TEAM_INFECTED )
		return;

	if( GetClientTeam(attacker) != TEAM_SURVIVOR )
		return;

	int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if( zombieClass < 1 )
		return;

	if( !(g_iCvarInfected & (1 << zombieClass)) )
		return;

	// Fire kill
	if( !g_bCvarMolotov )
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));

		if( StrEqual(weapon, "inferno") )
			return;
	}

	ScreenFade(attacker);
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarWitch == 0 )
		return;

	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int witchId = event.GetInt("witchid");
	bool oneshot = event.GetBool("oneshot");
	bool killedByFire = false;

	// Fire damage tracking if no valid attacker
	if( !attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != TEAM_SURVIVOR )
	{
		if( IsValidEntity(witchId) && g_iWitchFireAttacker[witchId] > 0 )
		{
			float timeDiff = GetGameTime() - g_fWitchFireTime[witchId];
			if( timeDiff <= 5.0 )
			{
				attacker = g_iWitchFireAttacker[witchId];
				killedByFire = true;

				if( !attacker || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || GetClientTeam(attacker) != TEAM_SURVIVOR )
				{
					ClearWitchTracking(witchId);
					return;
				}
			}
			else
			{
				ClearWitchTracking(witchId);
				return;
			}
		}
		else
		{
			return;
		}
	}

	// If killed by fire
	if( !killedByFire && IsValidEntity(witchId) && g_iWitchFireAttacker[witchId] > 0 )
	{
		float timeDiff = GetGameTime() - g_fWitchFireTime[witchId];
		if( timeDiff <= 5.0 )
		{
			killedByFire = true;
		}
	}

	// Molotov setting
	if( killedByFire && !g_bCvarMolotov )
	{
		ClearWitchTracking(witchId);
		return;
	}

	// Witch mode
	if( g_iCvarWitch == 2 && !oneshot )
	{
		ClearWitchTracking(witchId);
		return;
	}

	ScreenFade(attacker);
	ClearWitchTracking(witchId);
}

void ClearWitchTracking(int witchId)
{
	if( IsValidEntity(witchId) )
	{
		g_iWitchFireAttacker[witchId] = 0;
		g_fWitchFireTime[witchId] = 0.0;
	}
}



// ====================================================================================================
//					SCREEN FADE
// ====================================================================================================
void ScreenFade(int client)
{
	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return;

	int duration = 500;
	int holdTime = g_iCvarDuration;
	int flags = FFADE_IN | FFADE_PURGE;

	Handle hFade = StartMessageOne("Fade", client);
	if( hFade != null )
	{
		BfWriteShort(hFade, duration);
		BfWriteShort(hFade, holdTime);
		BfWriteShort(hFade, flags);
		BfWriteByte(hFade, g_iCvarColorR);
		BfWriteByte(hFade, g_iCvarColorG);
		BfWriteByte(hFade, g_iCvarColorB);
		BfWriteByte(hFade, g_iCvarColorA);
		EndMessage();
	}
}
