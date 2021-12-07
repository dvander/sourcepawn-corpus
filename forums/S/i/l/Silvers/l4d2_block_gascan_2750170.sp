/*
*	Scavenge Pouring - Unleaded Gas Only
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

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Scavenge Pouring - Unleaded Gas Only
*	Author	:	SilverShot
*	Descrp	:	Blocks pouring gascans which are not using the Scavenge model, configurable types.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=333064
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (17-Jun-2021)
	- Made compatible with the "Pour Gas" plugin.

1.0 (17-Jun-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d2_block_gascan"

Handle g_hDetourStart;
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDrop, g_hCvarPrint, g_hCvarStagger, g_hCvarTypes;
bool g_bCvarAllow, g_bMapStarted, g_bCvarDrop, g_bCvarPrint, g_bCvarStagger;
int g_iCvarTypes;
float g_fBlock[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Scavenge Pouring - Unleaded Gas Only",
	author = "SilverShot",
	description = "Blocks pouring gascans which are not using the Scavenge model, configurable types.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333064"
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
	// ====================
	// DETOUR
	// ====================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourStart = DHookCreateFromConf(hGameData, "CGasCan::ShouldStartAction");

	if( !g_hDetourStart )
		SetFailState("Failed to find \"CGasCan::ShouldStartAction\" signature.");

	delete hGameData;

	// ====================
	// CVARS
	// ====================
	g_hCvarAllow = CreateConVar(		"l4d2_block_gascan_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarDrop = CreateConVar(			"l4d2_block_gascan_drop",			"1",				"0=Off. 1=Prevent dropping the gascan when denied pouring.", CVAR_FLAGS );
	g_hCvarPrint = CreateConVar(		"l4d2_block_gascan_print",			"1",				"0=Off. 1=Print a message to the client explaining they cannot use this gascan.", CVAR_FLAGS );
	g_hCvarStagger = CreateConVar(		"l4d2_block_gascan_stagger",		"1",				"0=Off. 1=Stagger the client when denied pouring.", CVAR_FLAGS );
	g_hCvarTypes = CreateConVar(		"l4d2_block_gascan_types",			"9",				"Which models to block. 1=Standard, 2=Scavenge, 4=Green, 8=Green with Diesel text. Add numbers together.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d2_block_gascan_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d2_block_gascan_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d2_block_gascan_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_block_gascan_version",		PLUGIN_VERSION,		"Block Gascan plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_block_gascan");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarDrop.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPrint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStagger.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);
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

	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fBlock[i] = 0.0;
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

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarDrop = g_hCvarDrop.BoolValue;
	g_bCvarPrint = g_hCvarPrint.BoolValue;
	g_bCvarStagger = g_hCvarStagger.BoolValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		// Event
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

		// Detour
		if( !DHookEnableDetour(g_hDetourStart, false, ShouldStartAction) )
			SetFailState("Failed to detour \"CGasCan::ShouldStartAction\".");
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		// Event
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

		// Detour
		DHookDisableDetour(g_hDetourStart, false, ShouldStartAction);
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
// DETOUR
// ====================================================================================================
public MRESReturn ShouldStartAction(Handle hReturn, Handle hParams)
{
	int client = DHookGetParam(hParams, 2);

	if( client && client <= MaxClients )
	{
		// Verify not using "Pour Gas" plugin
		int entity = DHookGetParam(hParams, 3);
		int hammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
		if( !hammerID || hammerID > MaxClients )
		{
			// Validate weapon
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( weapon != -1 )
			{
				// Validate type
				int skin = GetEntProp(weapon, Prop_Send, "m_nSkin");
				if( g_iCvarTypes & (1 << skin) )
				{
					// Stagger
					if( g_bCvarStagger )
					{
						SetVariantString("self.Stagger(Vector())");
						AcceptEntityInput(client, "RunScriptCode");
					}

					// Prevent dropping gascan
					if( g_bCvarDrop )
					{
						g_fBlock[client] = GetGameTime() + 1.8;

						DataPack dPack = new DataPack();
						dPack.WriteCell(GetClientUserId(client));
						dPack.WriteCell(EntIndexToEntRef(weapon));
						RequestFrame(OnFrame, dPack);
					}

					// Hint
					if( g_bCvarPrint )
					{
						PrintToChat(client, "\x04[\x05Gascan\x04] \x01Cannot pour gas from this model.");
					}

					// Block using
					DHookSetReturn(hReturn, 0);
					return MRES_Supercede;
				}
			}
		}
	}

	return MRES_Ignored;
}



// ====================================================================================================
// BLOCK DROP
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && g_fBlock[client] > GetGameTime() )
	{
		buttons &= ~IN_ATTACK;
	}
}

public void OnFrame(DataPack dPack)
{
	dPack.Reset();

	int client = GetClientOfUserId(dPack.ReadCell());
	if( client && IsClientInGame(client) )
	{
		int weapon = EntRefToEntIndex(dPack.ReadCell());
		if( weapon != INVALID_ENT_REFERENCE )
		{
			EquipPlayerWeapon(client, weapon);
		}
	}

	delete dPack;
}