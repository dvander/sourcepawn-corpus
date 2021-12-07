/*
*	Molotov Shove
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



#define PLUGIN_VERSION 		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Molotov Shove
*	Author	:	SilverShot
*	Descrp	:	Ignites infected when shoved by players holding molotovs.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187941
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (05-Aug-2020)
	- Fixed not resetting when the Molotov breaks sometimes causing new Molotovs to instantly break.
	- Issue occurred when using the "l4d_molotov_shove_limited" cvar.

1.7 (15-May-2020)
	- Fixed the dropped fire from an exploded Molotov not crediting the owner.
	- Replaced "point_hurt" entity with "SDKHooks_TakeDamage" function.

1.6 (10-May-2020)
	- Added cvar "l4d_molotov_shove_limited" to limit how many times a Molotov can be used.
	- Added cvar "l4d_molotov_shove_remove" to remove or explode Molotov when reaching the limit.
	- Fixed cvar "l4d_molotov_shove_infected" not working for the Tank in L4D1.
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.5 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_molotov_shove_modes_tog" now supports L4D1.

1.4.1 (24-Mar-2018)
	- Added a couple checks to prevent errors being logged - Thanks to "Crasher_3637" for reporting.

1.4 (03-Jul-2012)
	- Fixed errors by adding some checks - Thanks to "disawar1" for reporting.

1.3 (02-Jul-2012)
	- Fixed errors logging when "m_flLifetime" was not found - Thanks to "disawar1" for reporting.
	- Fixed the Witch not following the "l4d_molotov_shove_timed" cvar setting.
	- No longer extinguishes players who are already on fire, when using the "l4d_molotov_shove_timeout" cvar.

1.2 (30-Jun-2012)
	- Fixed the plugin not working in L4D1.

1.1 (22-Jun-2012)
	- Added cvar "l4d_molotov_shove_timed" to control which infected use the following cvar.
	- Added cvar "l4d_molotov_shove_timeout" to set how long infected will burn for.

1.0 (20-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define	MODEL_GASCAN		"models/props_junk/gascan001a.mdl"
#define	SOUND_BREAK			"weapons/molotov/molotov_detonate_3.wav"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarInfected, g_hCvarLimited, g_hCvarLimit, g_hCvarRemove, g_hCvarTimed, g_hCvarTimeout;
int g_iCvarInfected, g_iCvarLimited, g_iCvarLimit, g_iCvarTimed, g_iCvarRemove, g_iLimiter[MAXPLAYERS+1], g_iLimited[2048], g_iClassTank;
bool g_bCvarAllow, g_bLeft4Dead2;
float g_fCvarTimeout;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Molotov Shove",
	author = "SilverShot",
	description = "Ignites infected when shoved by players holding molotovs.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187941"
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
	g_hCvarAllow = CreateConVar(		"l4d_molotov_shove_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d_molotov_shove_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d_molotov_shove_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d_molotov_shove_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarInfected = CreateConVar(		"l4d_molotov_shove_infected",		"511",			"Which infected to affect: 1=Common, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank, 511=All.", CVAR_FLAGS );
	g_hCvarLimited = CreateConVar(		"l4d_molotov_shove_limited",		"2",			"0=Infinite. How many times someone can use a molotov to ignite infected before it's removed by the remove cvar option.", CVAR_FLAGS );
	g_hCvarLimit = CreateConVar(		"l4d_molotov_shove_limit",			"0",			"0=Infinite. How many times per round can someone use their molotov to ignite infected.", CVAR_FLAGS );
	g_hCvarRemove = CreateConVar(		"l4d_molotov_shove_remove",			"2",			"0=Off. 1=Delete the entity when limit reached. 2=Explode on the ground when limit is reached.", CVAR_FLAGS );
	g_hCvarTimed = CreateConVar(		"l4d_molotov_shove_timed",			"256",			"These infected use l4d_molotov_shove_timeout, otherwise they burn forever. 0=None, 1=All, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank.", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(		"l4d_molotov_shove_timeout",		"10.0",			"0=Forever. How long should the infected be ignited for?", CVAR_FLAGS );
	CreateConVar(						"l4d_molotov_shove_version",		PLUGIN_VERSION,	"Molotov Shove plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_molotov_shove");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLimited.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRemove.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimed.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeout.AddChangeHook(ConVarChanged_Cvars);

	g_iClassTank = g_bLeft4Dead2 ? 9 : 6;
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
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_iCvarLimited = g_hCvarLimited.IntValue;
	g_iCvarLimit = g_hCvarLimit.IntValue;
	g_iCvarRemove = g_hCvarRemove.IntValue;
	g_iCvarTimed = g_hCvarTimed.IntValue;
	g_fCvarTimeout = g_hCvarTimeout.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("entity_shoved", Event_EntityShoved);
		HookEvent("player_shoved", Event_PlayerShoved);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_end", Event_RoundEnd);
		UnhookEvent("entity_shoved", Event_EntityShoved);
		UnhookEvent("player_shoved", Event_PlayerShoved);
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

public void OnMapStart()
{
	PrecacheModel(MODEL_GASCAN);
	PrecacheSound(SOUND_BREAK);
}

public void OnMapEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i < 2048; i++ )
	{
		g_iLimited[i] = 0;
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_EntityShoved(Event event, const char[] name, bool dontBroadcast)
{
	int infected = g_iCvarInfected & (1<<0);
	int witch = g_iCvarInfected & (1<<1);
	if( infected || witch )
	{
		int client = GetClientOfUserId(event.GetInt("attacker"));

		if( g_iCvarLimit && g_iLimiter[client] >= g_iCvarLimit )
			return;

		if( CheckWeapon(client) )
		{
			int target = event.GetInt("entityid");

			char sTemp[32];
			GetEntityClassname(target, sTemp, sizeof(sTemp));

			if( infected && strcmp(sTemp, "infected") == 0 )
			{
				HurtPlayer(target, client, 0);
				g_iLimiter[client]++;
			}
			else if( witch && strcmp(sTemp, "witch") == 0 )
			{
				HurtPlayer(target, client, g_iCvarTimed == 1 || g_iCvarTimed & (1<<1));
				g_iLimiter[client]++;
			}

			LimitedFunc(client);
		}
	}
}

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));

	if( g_iCvarLimit && g_iLimiter[client] >= g_iCvarLimit )
		return;

	int target = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(target) == 3 && CheckWeapon(client) )
	{
		int class = GetEntProp(target, Prop_Send, "m_zombieClass") + 1;
		if( class == g_iClassTank ) class = 8;
		if( g_iCvarInfected & (1 << class) )
		{
			HurtPlayer(target, client, class);
			g_iLimiter[client]++;

			LimitedFunc(client);
		}
	}
}

void LimitedFunc(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	g_iLimited[weapon]++;

	if( g_iCvarLimited && g_iLimited[weapon] >= g_iCvarLimited )
	{
		EmitSoundToAll(SOUND_BREAK, client);

		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
		g_iLimited[weapon] = 0;

		if( g_iCvarRemove == 2 )
		{
			CreateFires(client);
		}
	}
}

void CreateFires(int client)
{
	int entity = CreateEntityByName("prop_physics");
	if( entity != -1 )
	{
		SetEntityModel(entity, MODEL_GASCAN);

		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(entity);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
		AcceptEntityInput(entity, "Break");
	}
}

void HurtPlayer(int target, int client, int class)
{
	char sTemp[16];
	int entity = GetEntPropEnt(target, Prop_Data, "m_hEffectEntity");
	if( entity != -1 && IsValidEntity(entity) )
	{
		GetEntityClassname(entity, sTemp, sizeof(sTemp));
		if( strcmp(sTemp, "entityflame") == 0 )
		{
			return;
		}
	}

	SDKHooks_TakeDamage(target, client, client, 0.0, DMG_BURN);

	if( g_fCvarTimeout && g_iCvarTimed && class )
	{
		if( g_iCvarTimed == 1 || g_iCvarTimed & (1 << class) )
		{
			entity = GetEntPropEnt(target, Prop_Data, "m_hEffectEntity");
			if( entity != -1 )
			{
				GetEntityClassname(entity, sTemp, sizeof(sTemp));
				if( strcmp(sTemp, "entityflame") == 0 )
				{
					SetEntPropFloat(entity, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarTimeout);
				}
			}
		}
	}
}

bool CheckWeapon(int client)
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEntity(weapon) )
		{
			char sTemp[16];
			GetEntityClassname(weapon, sTemp, sizeof(sTemp));
			if( strncmp(sTemp[7], "molotov", 7) == 0 )
				return true;
		}
	}
	return false;
}