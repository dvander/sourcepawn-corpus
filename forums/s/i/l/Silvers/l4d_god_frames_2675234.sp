/*
*	God Frames Patch
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



#define PLUGIN_VERSION 		"1.7"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] God Frames Patch
*	Author	:	SilverShot
*	Descrp	:	Removes the IsInvulnerable function.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=320023
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (26-Oct-2023)
	- Fixed errors if the "m_zombieClass" is out of range. Thanks to "chungocanh12" for reporting.

1.6 (29-Apr-2022)
	- Added cvar "l4d_god_frames_incapacitated" to control damage on Incapacitated players. Requested by "ZBzibing".
	- Changed cvar "l4d_god_frames_allow" to allow the value "2" which only enables the forward.
	- Changed forward "OnTakeDamage_Invulnerable" params to show the damage type.
	- Potentially fixed reviving players instantly being incapacitated. Thanks to "Eyal282" for reporting.

1.5 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed delay cvars being read wrong for: world, fire, common, witch, tank.
	- Various changes to tidy up code.

1.4 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.3 (05-Feb-2020)
	- Moved forward creation to the correct place. Was rushed for demonstration.

1.2 (21-Jan-2020)
	- Fixed L4D1 not using IsInvulnerable function in OnTakeDamage. Thanks to "fbef0102" for reporting.
	- Thanks to Lux for various help. L4D1 now reads and sets the IsInvulnerable timer directly.
	- L4D1 gamedata update required.
	- L4D2 gamedata update required if updating from 1.0.

1.1.2 beta (13-Jan-2020)
	- Added forward "OnTakeDamage_Invulnerable" to allow 3rd party plugins to modify invulnerable damage.

1.1.1 beta (13-Jan-2020)
	- Fixed not resetting delay timers OnMapEnd.

1.1 beta (13-Jan-2020)
	- Added a heap of new cvars to control damage for individual infected etc.
	- New gamedata required.

1.0 (01-Dec-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_god_frames"
#define MAX_CVARS			12


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarIncap;
ConVar g_hCvarDmg[MAX_CVARS], g_hCvarDel[MAX_CVARS];
float g_fCvarDmg[MAX_CVARS], g_fCvarDel[MAX_CVARS];
float g_fLastHit[MAXPLAYERS+1][MAX_CVARS];
bool g_bCvarAllow, g_bCvarFoward, g_bMapStarted, g_bLateLoad, g_bLeft4Dead2, g_bCvarIncap;

Handle g_hDetour, g_hForwardInvul;
bool g_bInvulnerable[MAXPLAYERS+1];
float g_fIncapacitated[MAXPLAYERS+1];
int m_invulnerabilityTimer, g_iClassTank;
float g_fInvulDurr[MAXPLAYERS+1];
float g_fInvulTime[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] God Frames Patch",
	author = "SilverShot",
	description = "Removes the IsInvulnerable function.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320023"
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

	RegPluginLibrary("l4d_god_frames");

	g_hForwardInvul = CreateGlobalForward("OnTakeDamage_Invulnerable", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef, Param_CellByRef);

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// GAMEDATA
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	if( g_bLeft4Dead2 == false )
	{
		m_invulnerabilityTimer = GameConfGetOffset(hGameData, "m_invulnerabilityTimer");
		if( m_invulnerabilityTimer == -1 )
			SetFailState("Failed to find \"m_invulnerabilityTimer\" offset.");
	}

	g_hDetour = DHookCreateFromConf(hGameData, "CTerrorPlayer::IsInvulnerable");
	if( !g_hDetour )
		SetFailState("Failed to find \"CTerrorPlayer::IsInvulnerable\" signature.");

	delete hGameData;



	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow = CreateConVar(	"l4d_god_frames_allow",				"1",			"0=Plugin off, 1=Plugin on, 2=Enable forward only.", CVAR_FLAGS );
	g_hCvarDmg[0] = CreateConVar(	"l4d_god_frames_damage_survivor",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by other Survivors.", CVAR_FLAGS );
	g_hCvarDmg[1] = CreateConVar(	"l4d_god_frames_damage_world",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by World.", CVAR_FLAGS );
	g_hCvarDmg[2] = CreateConVar(	"l4d_god_frames_damage_fire",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Fire.", CVAR_FLAGS );
	g_hCvarDmg[3] = CreateConVar(	"l4d_god_frames_damage_common",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Common Infected.", CVAR_FLAGS );
	g_hCvarDmg[4] = CreateConVar(	"l4d_god_frames_damage_witch",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Witch.", CVAR_FLAGS );
	g_hCvarDmg[5] = CreateConVar(	"l4d_god_frames_damage_tank",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Tank.", CVAR_FLAGS );
	g_hCvarDmg[6] = CreateConVar(	"l4d_god_frames_damage_smoker",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Smoker.", CVAR_FLAGS );
	g_hCvarDmg[7] = CreateConVar(	"l4d_god_frames_damage_boomer",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Boomer.", CVAR_FLAGS );
	g_hCvarDmg[8] = CreateConVar(	"l4d_god_frames_damage_hunter",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Hunter.", CVAR_FLAGS );

	g_hCvarDel[0] = CreateConVar(	"l4d_god_frames_delay_survivor",	"0.0",			"0.0=None. Minimum time before damage can be dealt again by other Survivors.", CVAR_FLAGS );
	g_hCvarDel[1] = CreateConVar(	"l4d_god_frames_delay_world",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by World.", CVAR_FLAGS );
	g_hCvarDel[2] = CreateConVar(	"l4d_god_frames_delay_fire",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Fire.", CVAR_FLAGS );
	g_hCvarDel[3] = CreateConVar(	"l4d_god_frames_delay_common",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Common Infected.", CVAR_FLAGS );
	g_hCvarDel[4] = CreateConVar(	"l4d_god_frames_delay_witch",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Witch.", CVAR_FLAGS );
	g_hCvarDel[5] = CreateConVar(	"l4d_god_frames_delay_tank",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Tank.", CVAR_FLAGS );
	g_hCvarDel[6] = CreateConVar(	"l4d_god_frames_delay_smoker",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Smoker.", CVAR_FLAGS );
	g_hCvarDel[7] = CreateConVar(	"l4d_god_frames_delay_boomer",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Boomer.", CVAR_FLAGS );
	g_hCvarDel[8] = CreateConVar(	"l4d_god_frames_delay_hunter",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Hunter.", CVAR_FLAGS );

	if( g_bLeft4Dead2 )
	{
	g_hCvarDmg[9] = CreateConVar(	"l4d_god_frames_damage_spitter",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Spitter.", CVAR_FLAGS );
	g_hCvarDmg[10] = CreateConVar(	"l4d_god_frames_damage_jockey",		"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Jockey.", CVAR_FLAGS );
	g_hCvarDmg[11] = CreateConVar(	"l4d_god_frames_damage_charger",	"1.0",			"0.0=None. 1.0=Full. Scale damage dealt by Charger.", CVAR_FLAGS );

	g_hCvarDel[9] = CreateConVar(	"l4d_god_frames_delay_spitter",		"0.5",			"0.0=None. Minimum time before damage can be dealt again by Spitter.", CVAR_FLAGS );
	g_hCvarDel[10] = CreateConVar(	"l4d_god_frames_delay_jockey",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Jockey.", CVAR_FLAGS );
	g_hCvarDel[11] = CreateConVar(	"l4d_god_frames_delay_charger",		"0.0",			"0.0=None. Minimum time before damage can be dealt again by Charger.", CVAR_FLAGS );
	}

	g_hCvarIncap = CreateConVar(	"l4d_god_frames_incapacitated",		"0",			"0=Remove God Frames from incapacitated players, 1=Allow God Frames.", CVAR_FLAGS );

	g_hCvarModes = CreateConVar(	"l4d_god_frames_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d_god_frames_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d_god_frames_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d_god_frames_version",			PLUGIN_VERSION,	"God Frames Patch plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d_god_frames");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	for( int i = 0; i < MAX_CVARS; i++ )
	{
		if( g_bLeft4Dead2 == false && i == 9 ) break;
		g_hCvarDmg[i].AddChangeHook(ConVarChanged_Cvars);
		g_hCvarDel[i].AddChangeHook(ConVarChanged_Cvars);
	}

	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);

	g_iClassTank = g_bLeft4Dead2 ? 13 : 10;
}

public void OnPluginEnd()
{
	DetourAddress(false);
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 0; i <= MAXPLAYERS; i++ )
	{
		g_fIncapacitated[i] = 0.0;

		for( int x = 0; x < MAX_CVARS; x++ )
		{
			g_fLastHit[i][x] = 0.0;
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

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	for( int i = 0; i < MAX_CVARS; i++ )
	{
		if( g_bLeft4Dead2 == false && i == 9 ) break;
		g_fCvarDmg[i] = g_hCvarDmg[i].FloatValue;
		g_fCvarDel[i] = g_hCvarDel[i].FloatValue;
	}

	g_bCvarIncap = g_hCvarIncap.BoolValue;
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	g_bCvarFoward = g_hCvarAllow.IntValue == 2;
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		DetourAddress(true);
		g_bCvarAllow = true;

		HookEvent("round_start",		Event_RoundStart);
		HookEvent("revive_success",		Event_Revive);

		if( g_bLateLoad ) // Only on lateload, or if re-enabled.
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					OnClientPutInServer(i);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		DetourAddress(false);
		g_bCvarAllow = false;
		g_bLateLoad = true; // So SDKHooks can re-hook damage if re-enabled.

		UnhookEvent("round_start",		Event_RoundStart);
		UnhookEvent("revive_success",	Event_Revive);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				if( g_bLeft4Dead2 == false )
					SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamagePre);
				SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
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
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetInt("ledge_hang") == 1 ) return;

	int client = GetClientOfUserId(event.GetInt("subject"));
	g_fIncapacitated[client] = GetGameTime() + 0.1;
}



// ====================================================================================================
//					DAMAGE
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	if( g_bLeft4Dead2 == false )
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

Action OnTakeDamagePre(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( GetGameTime() < g_fIncapacitated[client] )
	{
		g_fIncapacitated[client] = 0.0;
		return Plugin_Continue;
	}

	float timestamp = view_as<float>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 8), NumberType_Int32));
	if( timestamp >= GetGameTime() )
	{
		// Instead of storing the timestamp inside this plugin on first detection which would make it inaccurate if the game ever changed it.
		// We'll remove timer to make vulnerable and...
		g_fInvulDurr[client] = view_as<float>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 4), NumberType_Int32));
		g_fInvulTime[client] = timestamp;
		g_bInvulnerable[client] = true;
		StoreToAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 4), view_as<int>(0.0), NumberType_Int32);	// m_duration
		StoreToAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 8), view_as<int>(0.0), NumberType_Int32);	// m_timestamp
	}
	else
	{
		g_bInvulnerable[client] = false;
	}

	return Plugin_Continue;
}

Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( g_bInvulnerable[client] )
	{
		// ... restore timer to continue tracking invul. Pre/Post.
		if( g_bLeft4Dead2 == false )
		{
			StoreToAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 4), view_as<int>(g_fInvulDurr[client]), NumberType_Int32);	// m_duration
			StoreToAddress(GetEntityAddress(client) + view_as<Address>(m_invulnerabilityTimer + 8), view_as<int>(g_fInvulTime[client]), NumberType_Int32);	// m_timestamp
		}

		// Allow god frames on incapped
		if( g_bCvarIncap && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) && GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 0 )
		{
			damage = 0.0;
			return Plugin_Changed;
		}

		// Allow God Frames when revived for 0.1 to prevent instant incap
		if( GetGameTime() < g_fIncapacitated[client] )
		{
			g_fIncapacitated[client] = 0.0;
			return Plugin_Continue;
		}

		// Forward
		Action aResult = Plugin_Continue;
		Call_StartForward(g_hForwardInvul);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_Finish(aResult);
		if( aResult != Plugin_Continue ) return aResult;

		// Only trigger the forward, allow god frames
		if( g_bCvarFoward )
		{
			damage = 0.0;
			return Plugin_Changed;
		}



		// Main subroutine
		if( attacker >= 1 && attacker <= MaxClients )
		{
			if( GetClientTeam(attacker) == 3 )
			{
				// Special Infected
				int index = GetEntProp(attacker, Prop_Send, "m_zombieClass") + 5;
				if( index == g_iClassTank ) index = 5; // Tank zombieClass == 8 (L4D2) or 5 (L4D1), and 5 in our indexing.
				if( index >= MAX_CVARS ) return Plugin_Continue;

				if( IsClientInvul(client, index) ) // Time delay between god frame damage.
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				damage *= g_fCvarDmg[index]; // Scaled damage
				return Plugin_Changed;
			} else { // Can be team 2 or 4 (support for some mods)
				// Survivors
				if( IsClientInvul(client, 0) ) // Time delay between god frame damage.
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				damage *= g_fCvarDmg[0]; // Scaled damage
				return Plugin_Changed;
			}
		} else {
			char classname[6];
			GetEdictClassname(attacker, classname, sizeof(classname));

			switch( classname[3] )
			{
				case 'l': // "worldspawn"
				{
					if( IsClientInvul(client, 1) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[1]; // Scaled damage
					return Plugin_Changed;
				}
				case 'i': // "entityflame"
				{
					if( IsClientInvul(client, 2) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[2]; // Scaled damage
					return Plugin_Changed;
				}
				case 'e': // "infected"
				{
					if( IsClientInvul(client, 3) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[3]; // Scaled damage
					return Plugin_Changed;
				}
				case 'c': // "witch"
				{
					if( IsClientInvul(client, 4) ) // Time delay between god frame damage.
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					damage *= g_fCvarDmg[4]; // Scaled damage
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

bool IsClientInvul(int client, int index)
{
	if( g_fCvarDel[index] )
	{
		float time = GetGameTime();
		if( time < g_fLastHit[client][index] )
		{
			return true;
		}
		g_fLastHit[client][index] = g_fCvarDel[index] + time;
	}
	return false;
}



// ====================================================================================================
//					DETOUR
// ====================================================================================================
void DetourAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		if( !DHookEnableDetour(g_hDetour, false, IsInvulnerablePre) )
			SetFailState("Failed to detour pre \"CTerrorPlayer::IsInvulnerable\".");

		if( !DHookEnableDetour(g_hDetour, true, IsInvulnerablePost) )
			SetFailState("Failed to detour post \"CTerrorPlayer::IsInvulnerable\".");
	}
	else if( patched && !patch )
	{
		if( !DHookDisableDetour(g_hDetour, false, IsInvulnerablePre) )
			SetFailState("Failed to disable detour pre \"CTerrorPlayer::IsInvulnerable\".");

		if( !DHookDisableDetour(g_hDetour, true, IsInvulnerablePost) )
			SetFailState("Failed to disable detour post \"CTerrorPlayer::IsInvulnerable\".");
	}
}

MRESReturn IsInvulnerablePre()
{
	// Unused but pre hook required to prevent crashing.
	return MRES_Ignored;
}

MRESReturn IsInvulnerablePost(int pThis, Handle hReturn)
{
	bool invul = DHookGetReturn(hReturn);
	g_bInvulnerable[pThis] = invul;

	if( invul )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}