/*
*	Charger Punch Force
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

*	Name	:	[L4D2] Charger Punch Force
*	Author	:	SilverShot
*	Descrp	:	Survivors are flung when punched by Chargers.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=320939
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (22-Nov-2023)
	- Added cvar "l4d2_charger_punch_type" to control if Survivors or Special Infected or both can be affected.

1.6 (10-Apr-2022)
	- Fixed rare error if a client disconnects 1 frame after punching.

1.5 (14-Nov-2021)
	- Changes to fix warnings when compiling on SourceMod 1.11.
	- Updated GameData signatures to avoid breaking when detoured by the "Left4DHooks" plugin.

1.4 (23-May-2020)
	- Fixed conflict with "Charger Actions" plugin when punch to carry is enabled.
	- Fixed flinging a Survivor too far due to multiple hits within the same frame.
	- Fixed not disabling punches if the plugin was turned off while a Charger was alive.
	- Now teleports incapacitated players instead of flinging which makes them play the get up animation.

1.3 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.2 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.1 (04-Mar-2020)
	- Extra simple check incase of errors from invalid clients spawning.

1.0 (17-Jan-2020)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"honorcode23" for "[L4D & L4D2] New custom commands" - FlingPlayer function.
	https://forums.alliedmods.net/showthread.php?t=133475

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d2_charger_punch"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarCharge, g_hCvarFling, g_hCvarForce, g_hCvarForceZ, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad;
int g_iCvarCharge, g_iCvarFling, g_iCvarType;
float g_fCvarForce, g_fCvarForceZ;
Handle g_hDetour, sdkCallPushPlayer;
float g_fLastPunch[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Charger Punch Force",
	author = "SilverShot",
	description = "Survivors are flung when punched by Chargers.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320939"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

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

	// Detour
	g_hDetour = DHookCreateFromConf(hGameData, "CClaw::OnPlayerHit");

	if( !g_hDetour )
		SetFailState("Failed to find \"CClaw::OnPlayerHit\" signature.");

	// SDKCall
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if( sdkCallPushPlayer == null )
		SetFailState("Unable to find the \"CTerrorPlayer_Fling\" signature, check the file version!");

	delete hGameData;



	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d2_charger_punch_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_charger_punch_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_charger_punch_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_charger_punch_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarCharge =			CreateConVar(	"l4d2_charger_punch_charging",		"0",				"Only fling survivors when punched by a Charger that is charging. 0=No. 1=Yes. Very hard to punch and hit while charging, added by request.", CVAR_FLAGS );
	g_hCvarFling =			CreateConVar(	"l4d2_charger_punch_fling",			"1",				"The type of fling. 1=Fling with get up animation. 2=Teleport player away from Charger.", CVAR_FLAGS );
	g_hCvarForce =			CreateConVar(	"l4d2_charger_punch_force",			"200.0",			"The velocity a survivor is flung when punched by the Charger.", CVAR_FLAGS );
	g_hCvarForceZ =			CreateConVar(	"l4d2_charger_punch_forcez",		"251.0",			"The vertical velocity a survivors is flung when punched by the Charger. Must be greater than 250 to lift a Survivor.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d2_charger_punch_type",			"1",				"Which team does this plugin affect. 1=Survivors. 2=Special Infected. 3=Both.", CVAR_FLAGS );
	CreateConVar(							"l4d2_charger_punch_version",		PLUGIN_VERSION,		"Charger Punch Force plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_charger_punch");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarCharge.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFling.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForce.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarForceZ.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);

	IsAllowed();
}

public void OnPluginEnd()
{
	HookEvents(false);
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
	g_iCvarCharge = g_hCvarCharge.IntValue;
	g_iCvarFling = g_hCvarFling.IntValue;
	g_fCvarForce = g_hCvarForce.FloatValue;
	g_fCvarForceZ = g_hCvarForceZ.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		if( g_bLateLoad )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					HookClient(i);
				}
			}
		}

		HookEvents(true);
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bLateLoad = true; // To-rehook active chargers if plugin re-enabled.
		HookEvents(false);
		g_bCvarAllow = false;
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
//					DETOUR
// ====================================================================================================
void HookEvents(bool hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		HookEvent("player_spawn", Event_PlayerSpawn);
	}
	else if( hooked && !hook )
	{
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client ) HookClient(client);
}

void HookClient(int client)
{
	g_fLastPunch[client] = 0.0;

	if( GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEdict(weapon) )
		{
			DHookEntity(g_hDetour, true, weapon, INVALID_FUNCTION, OnPlayerHit);
		}
	}
}

MRESReturn OnPlayerHit(int pThis, Handle hReturn, Handle hParams)
{
	if( !g_bCvarAllow ) return MRES_Ignored;

	int attacker = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	if( g_iCvarCharge )
	{
		int ability = GetEntPropEnt(attacker, Prop_Send, "m_customAbility"); // ability_charge
		if( ability > 0 && IsValidEdict(ability) && GetEntProp(ability, Prop_Send, "m_isCharging") == 0 ) return MRES_Ignored;
	}

	// Because this detour triggers first and "Charger Actions" punch to carry survivors uses the player_hurt event, have to delay flinging.
	int victim = DHookGetParam(hParams, 1);

	switch( g_iCvarType )
	{
		case 1:
		{
			if( GetClientTeam(victim) != 2 ) return MRES_Ignored;
		}
		case 2:
		{
			if( GetClientTeam(victim) != 3 ) return MRES_Ignored;
		}
	}

	DataPack dPack = new DataPack();
	dPack.WriteCell(GetClientUserId(victim));
	dPack.WriteCell(GetClientUserId(attacker));
	RequestFrame(OnFrame, dPack);

	return MRES_Ignored;
}

void OnFrame(DataPack dPack)
{
	dPack.Reset();
	int victim = dPack.ReadCell();
	int attacker = dPack.ReadCell();
	delete dPack;

	victim = GetClientOfUserId(victim);
	if( !victim || !IsClientInGame(victim) ) return;

	attacker = GetClientOfUserId(attacker);
	if( !attacker || !IsClientInGame(attacker) ) return;

	// Prevent multiple hits
	if( g_fLastPunch[victim] > GetGameTime() ) return;
	g_fLastPunch[victim] = GetGameTime() + 0.5;

	// Prevent conflict with grab from "Charger Actions" plugin.
	if( GetEntPropEnt(victim, Prop_Send, "m_carryAttacker") > 0 ) return;

	float vPos[3], vEnd[3];
	GetClientAbsOrigin(attacker, vPos);
	GetClientAbsOrigin(victim, vEnd);

	MakeVectorFromPoints(vPos, vEnd, vEnd);
	NormalizeVector(vEnd, vEnd);
	ScaleVector(vEnd, g_fCvarForce);
	vEnd[2] = g_fCvarForceZ;

	if( g_iCvarFling == 1 && GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0 )
		SDKCall(sdkCallPushPlayer, victim, vEnd, 76, attacker, 3.0);
	else
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vEnd);
}