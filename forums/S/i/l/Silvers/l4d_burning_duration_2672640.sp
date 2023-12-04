/*
*	Special Infected Burn Duration
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



#define PLUGIN_VERSION 		"1.4"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Special Infected Burn Duration
*	Author	:	SilverShot
*	Descrp	:	Control flame duration for the Tank, Witch and Special Infected.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319621
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.3 (04-Jun-2020)
	- Fixed the plugin not always working 100% of the time.
	- Fixed multiple hooks over multiple spawns and not unhooking when dead or plugin turned off.

1.2 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (11-Nov-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarInfected, g_hCvarFlameSpec, g_hCvarFlameTank, g_hCvarFlameWitch;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
float g_fCvarFlameSpec, g_fCvarFlameTank, g_fCvarFlameWitch;
int g_iCvarInfected;
int TYPE_SPECIAL = 1;
int TYPE_TANK = 5;
int TYPE_WITCH = 0;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Burn Duration",
	author = "SilverShot",
	description = "Control flame duration for the Tank, Witch and Special Infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319621"
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
	// Cvars
	g_hCvarAllow =			CreateConVar(	"l4d_burn_duration_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_burn_duration_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_burn_duration_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_burn_duration_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarInfected =		CreateConVar(	"l4d_burn_duration_infected",		"63",				"Which Special Infected to affect: 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 63=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarFlameSpec =		CreateConVar(	"l4d_burn_duration_special",		"1.0",				"0.0=Game default. How long Special Infected stay ignited.", CVAR_FLAGS );
	g_hCvarFlameTank =		CreateConVar(	"l4d_burn_duration_tank",			"3.0",				"0.0=Game default. How long the Tank stays ignited.", CVAR_FLAGS );
	g_hCvarFlameWitch =		CreateConVar(	"l4d_burn_duration_witch",			"4.0",				"0.0=Game default. How long the Witch stays ignited.", CVAR_FLAGS );
	CreateConVar(							"l4d_burn_duration_version",		PLUGIN_VERSION,		"Burn Duration version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_burn_duration");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameSpec.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameTank.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlameWitch.AddChangeHook(ConVarChanged_Cvars);

	if( g_bLeft4Dead2 ) TYPE_TANK = 8;
	IsAllowed();
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
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_fCvarFlameSpec = g_hCvarFlameSpec.FloatValue;
	g_fCvarFlameTank = g_hCvarFlameTank.FloatValue;
	g_fCvarFlameWitch = g_hCvarFlameWitch.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		HookEvent("player_death",		Event_PlayerDeath);
		HookEvent("player_spawn",		Event_PlayerSpawn);
		HookEvent("witch_spawn",		Event_WitchSpawn);
		g_bCvarAllow = true;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 )
			{
				int class = GetEntProp(i, Prop_Send, "m_zombieClass");

				if( g_fCvarFlameTank && class == TYPE_TANK )
				{
					SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageT);
				}
				else if( g_fCvarFlameSpec && g_iCvarInfected & (1 << (class - 1)) )
				{
					SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageS);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		UnhookEvent("player_death",		Event_PlayerDeath);
		UnhookEvent("player_spawn",		Event_PlayerSpawn);
		UnhookEvent("witch_spawn",		Event_WitchSpawn);
		g_bCvarAllow = false;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 )
			{
				int class = GetEntProp(i, Prop_Send, "m_zombieClass");

				if( class == TYPE_TANK )
				{
					SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageT);
				}
				else
				{
					SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageS);
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
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		if( GetClientTeam(client) == 3 )
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");

			if( class == TYPE_TANK )
			{
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageT);
			}
			else
			{
				SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageS);
			}
		}
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client )
	{
		if( GetClientTeam(client) == 3 )
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");

			if( g_fCvarFlameTank && class == TYPE_TANK )
			{
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageT);
			}
			else if( g_fCvarFlameSpec && g_iCvarInfected & (1 << (class - 1)) )
			{
				SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageS);
			}
		}
	}
}

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_fCvarFlameWitch )
	{
		int witch = event.GetInt("witchid");
		SDKHook(witch, SDKHook_OnTakeDamageAlive, OnTakeDamageW);
	}
}



// ====================================================================================================
//					DAMAGE
// ====================================================================================================
Action OnTakeDamageS(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype & DMG_BURN ) OnDamage(victim, TYPE_SPECIAL);
	return Plugin_Continue;
}
Action OnTakeDamageT(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype & DMG_BURN ) OnDamage(victim, TYPE_TANK);
	return Plugin_Continue;
}
Action OnTakeDamageW(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( damagetype & DMG_BURN ) OnDamage(victim, TYPE_WITCH);
	return Plugin_Continue;
}

void OnDamage(int victim, int type)
{
	int flame = GetEntPropEnt(victim, Prop_Send, "m_hEffectEntity");
	if( flame != -1 )
	{
		if(			type == TYPE_SPECIAL	&& GetEntPropFloat(flame, Prop_Data, "m_flLifetime") > GetGameTime() + g_fCvarFlameSpec )		SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameSpec);
		else if(	type == TYPE_TANK		&& GetEntPropFloat(flame, Prop_Data, "m_flLifetime") > GetGameTime() + g_fCvarFlameTank )		SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameTank);
		else if(	type == TYPE_WITCH		&& GetEntPropFloat(flame, Prop_Data, "m_flLifetime") > GetGameTime() + g_fCvarFlameWitch )		SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarFlameWitch);
	}
}