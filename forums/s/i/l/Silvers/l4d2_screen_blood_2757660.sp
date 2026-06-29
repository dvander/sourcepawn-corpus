/*
*	Screen Blood Effect Block
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



#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Blood Screen Effect Block
*	Author	:	SilverShot
*	Descrp	:	Blocks the blood screen effect when using melee weapons.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334292
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (13-Sep-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarSound;
bool g_bCvarAllow, g_bMapStarted;
float g_fLastEmit;
UserMsg g_iUserMsgBlood;

char g_sSounds[6][] =
{
	"player/survivor/splat/zombie_blood_spray_01.wav",
	"player/survivor/splat/zombie_blood_spray_02.wav",
	"player/survivor/splat/zombie_blood_spray_03.wav",
	"player/survivor/splat/zombie_blood_spray_04.wav",
	"player/survivor/splat/zombie_blood_spray_05.wav",
	"player/survivor/splat/zombie_blood_spray_06.wav"
};

char g_sSounds2[3][] =
{
	"player/survivor/splat/blood_spurt1.wav",
	"player/survivor/splat/blood_spurt2.wav",
	"player/survivor/splat/blood_spurt3.wav"
};



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Blood Screen Effect Block",
	author = "SilverShot",
	description = "Blocks the blood screen effect when using melee weapons.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334292"
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
	g_hCvarAllow =			CreateConVar(	"l4d2_screen_blood_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_screen_blood_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_screen_blood_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_screen_blood_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarSound =			CreateConVar(	"l4d2_screen_blood_sound",			"2",				"0=Off. 1=Player blood slice sound to client doing the melee attack. 2=Play sound to everyone nearby.", CVAR_FLAGS );
	CreateConVar(							"l4d2_screen_blood_version",		PLUGIN_VERSION,		"Blood Screen Effect Block plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_screen_blood");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	g_iUserMsgBlood = GetUserMessageId("MeleeSlashSplatter");
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

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookUserMessage(g_iUserMsgBlood, OnMeleeSlashSplatter, true);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookUserMessage(g_iUserMsgBlood, OnMeleeSlashSplatter, true);
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
		if( entity != -1 )
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
//					FUNCTION
// ====================================================================================================
public void OnMapStart()
{
	for( int i = 0; i < sizeof(g_sSounds); i++ )
		PrecacheSound(g_sSounds[i]);

	for( int i = 0; i < sizeof(g_sSounds2); i++ )
		PrecacheSound(g_sSounds2[i]);

	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_fLastEmit = 0.0;
}

public Action OnMeleeSlashSplatter(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if( g_hCvarSound.IntValue && GetGameTime() - g_fLastEmit >= 0.1 )
	{
		g_fLastEmit = GetGameTime(); // Prevent playing multiple times close together

		int client = players[0];

		int i = GetRandomInt(0, sizeof(g_sSounds) - 1);
		int x = GetRandomInt(0, sizeof(g_sSounds2) - 1);

		switch( g_hCvarSound.IntValue )
		{
			case 1:
			{
				EmitSoundToClient(client, g_sSounds[i], client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				EmitSoundToClient(client, g_sSounds2[x], client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, _, _, SNDPITCH_HIGH);
			}

			case 2:
			{
				EmitSoundToAll(g_sSounds[i], client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER);
				EmitSoundToAll(g_sSounds2[x], client, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, _, _, SNDPITCH_HIGH);
			}

			// Crashing server:
			// case 1:		EmitGameSoundToClient(client, "Blood.Splat", client);
			// case 2:		EmitGameSoundToAll("Blood.Splat", client);
		}
	}

	// Block particles
	return Plugin_Handled;
}