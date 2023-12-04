/*
*	DSP Effects
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



#define PLUGIN_VERSION 		"1.9"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] DSP Effects
*	Author	:	SilverShot
*	Descrp	:	Distorts and muffles a Survivors sound when pinned by Special Infected, incapacitated or black and white.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=335214
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (25-Sep-2023)
	- Fixed resetting the sound when incapacitated and special infected stop pinning.
	- Fixed not setting the sound if black and white after defib.
	- Thanks to "Automage" for reporting and helping.

1.8 (24-Sep-2023)
	- Fixed invalid handle errors. Thanks to "Automage" for reporting.

1.7 (22-Sep-2023)
	- No longer resets the DSP level when going AFK.
	- No longer resets the DSP level when using Adrenaline.
	- Changed the thirdstrike check.
	- Thanks to "Automage" for reporting and testing.

1.6 (01-Nov-2022)
	- Fixed the effect playing after being revived and not black and white, due to conflict with other plugins.

1.5 (01-Jun-2022)
	- Fixed random rare server crash.

1.4 (02-Feb-2022)
	- Fixed invalid client errors. Thanks to "sonic155" for reporting.

1.3 (20-Nov-2021)
	- Fixed ledge hanging distorting sound. Thanks to "TypicalType" for reporting.

1.2 (18-Nov-2021)
	- Changed gamemode check from creating an entity to use Left4DHooks "L4D_GetGameModeType" native.

1.1 (16-Nov-2021)
	- Fixed not restoring sound when healed. Thanks to "sonic155" for reporting.

1.0 (15-Nov-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarAdren, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarIncap, g_hCvarSpecial, g_hCvarStrike;
int g_iCvarIncap, g_iCvarSpecial, g_iCvarStrike;
bool g_bCvarAllow, g_bLeft4Dead2;
float g_fCvarAdren;
bool g_bSetDSP[MAXPLAYERS+1];
int g_iLevelDSP[MAXPLAYERS+1];
Handle g_gTimerAdren[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] DSP Effects",
	author = "SilverShot",
	description = "Distorts and muffles a Survivors sound when pinned by Special Infected, incapacitated or black and white.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335214"
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
	g_hCvarAllow =		CreateConVar(	"l4d_dsp_effects_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_dsp_effects_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_dsp_effects_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_dsp_effects_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarIncap =		CreateConVar(	"l4d_dsp_effects_incap",		"1",			"0=Off. 1=Apply muffle effect when incapacitated.", CVAR_FLAGS );
	g_hCvarSpecial =	CreateConVar(	"l4d_dsp_effects_special",		"1",			"0=Off. 1=Apply muffle effect when pinned by a Special Infected.", CVAR_FLAGS );
	g_hCvarStrike =		CreateConVar(	"l4d_dsp_effects_strike",		"1",			"0=Off. 1=Apply muffle effect when black and white.", CVAR_FLAGS );
	CreateConVar(						"l4d_dsp_effects_version",		PLUGIN_VERSION, "DSP Effects plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_dsp_effects");

	if( g_bLeft4Dead2 )
	{
		g_hCvarAdren = FindConVar("adrenaline_duration");
		g_hCvarAdren.AddChangeHook(ConVarChanged_Cvars);
	}

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecial.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarStrike.AddChangeHook(ConVarChanged_Cvars);
	AddCommandListener(CommandListener, "give");
}

Action CommandListener(int client, const char[] command, int args)
{
	if( g_bSetDSP[client] && args > 0 )
	{
		char buffer[8];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "health") == 0 )
		{
			SetEffects(client, 1);
			g_bSetDSP[client] = false;
		}
	}

	return Plugin_Continue;
}

public void OnPluginEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_bSetDSP[i] && IsClientInGame(i) )
		{
			SetEffects(i, 1);
		}

		g_bSetDSP[i] = false;
	}
}

public void OnMapEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bSetDSP[i] = false;
		g_iLevelDSP[i] = 0;
		delete g_gTimerAdren[i];
	}
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
	g_iCvarIncap = g_hCvarIncap.IntValue;
	g_iCvarSpecial = g_hCvarSpecial.IntValue;
	g_iCvarStrike = g_hCvarStrike.IntValue;

	if( g_bLeft4Dead2 )
	{
		g_fCvarAdren = g_hCvarAdren.FloatValue + 0.5;
	}
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_end",						Event_RoundEnd);
		HookEvent("player_bot_replace",				Event_Swap_Bot);
		HookEvent("bot_player_replace",				Event_Swap_User);
		HookEvent("player_spawn",					Event_PlayerSpawn);
		HookEvent("player_death",					Event_PlayerDeath);
		HookEvent("defibrillator_used",             Event_PlayerDefib);
		HookEvent("player_incapacitated",			Event_Incapped);
		HookEvent("revive_success",					Event_Revived);
		HookEvent("heal_success",					Event_Healed);
		HookEvent("lunge_pounce",					Event_Start);
		HookEvent("pounce_end",						Event_Stop);
		HookEvent("tongue_grab",					Event_Start);
		HookEvent("tongue_release",					Event_Stop);

		if( g_bLeft4Dead2 )
		{
			HookEvent("charger_carry_start",		Event_Start);
			HookEvent("charger_carry_end",			Event_Stop);
			HookEvent("charger_pummel_start",		Event_Start);
			HookEvent("charger_pummel_end",			Event_Stop);
			HookEvent("jockey_ride",				Event_Start);
			HookEvent("jockey_ride_end",			Event_Stop);
			HookEvent("adrenaline_used",			Event_Adren);
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("round_end",					Event_RoundEnd);
		UnhookEvent("player_bot_replace",			Event_Swap_Bot);
		UnhookEvent("bot_player_replace",			Event_Swap_User);
		UnhookEvent("player_spawn",					Event_PlayerSpawn);
		UnhookEvent("player_death",					Event_PlayerDeath);
		UnhookEvent("defibrillator_used",           Event_PlayerDefib);
		UnhookEvent("player_incapacitated",			Event_Incapped);
		UnhookEvent("revive_success",				Event_Revived);
		UnhookEvent("heal_success",					Event_Healed);
		UnhookEvent("lunge_pounce",					Event_Start);
		UnhookEvent("pounce_end",					Event_Stop);
		UnhookEvent("tongue_grab",					Event_Start);
		UnhookEvent("tongue_release",				Event_Stop);

		if( g_bLeft4Dead2 )
		{
			UnhookEvent("charger_carry_start",		Event_Start);
			UnhookEvent("charger_carry_end",		Event_Stop);
			UnhookEvent("charger_pummel_start",		Event_Start);
			UnhookEvent("charger_pummel_end",		Event_Stop);
			UnhookEvent("jockey_ride",				Event_Start);
			UnhookEvent("jockey_ride_end",			Event_Stop);
			UnhookEvent("adrenaline_used",			Event_Adren);
		}
	}
}

int g_iCurrentMode;
public void L4D_OnGameModeChange(int gamemode)
{
	g_iCurrentMode = gamemode;
}

bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_iCurrentMode == 0 ) g_iCurrentMode = L4D_GetGameModeType();

	int iCvarModesTog = g_hCvarModesTog.IntValue;

	if( iCvarModesTog && !(iCvarModesTog & g_iCurrentMode) )
		return false;

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



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnClientDisconnect(int client)
{
	delete g_gTimerAdren[client];
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

void Event_Swap_Bot(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_bSetDSP[bot] = g_bSetDSP[client];
	g_iLevelDSP[bot] = g_iLevelDSP[client];
}

void Event_Swap_User(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	g_bSetDSP[client] = g_bSetDSP[bot];
	g_iLevelDSP[client] = g_iLevelDSP[bot];

	if( g_bSetDSP[client] )
	{
		SetEffects(client, g_iLevelDSP[client]);
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( g_bSetDSP[client] )
	{
		g_bSetDSP[client] = false;
		SetEffects(client, 1);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( g_bSetDSP[client] )
	{
		g_bSetDSP[client] = false;
		SetEffects(client, 1);
	}
}

Action Event_PlayerDefib(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarStrike )
	{
		RequestFrame(OnFrameRevive, event.GetInt("subject"));
	}

	return Plugin_Continue;
}

void Event_Stop(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarSpecial )
	{
		int client = GetClientOfUserId(event.GetInt("victim"));
		if( client )
		{
			if( g_bSetDSP[client] && (!g_iCvarIncap || GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 0) )
			{
				g_bSetDSP[client] = false;
				SetEffects(client, 1);

				//PrintToChatAll("STOP DSP %N %s", client, name);
			}
		}
	}
}

void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarSpecial )
	{
		int client = GetClientOfUserId(event.GetInt("victim"));
		if( client )
		{
			g_bSetDSP[client] = true;
			SetEffects(client, 2); // Some muffle

			//PrintToChatAll("START DSP %N %s", client, name);
		}
	}
}

void Event_Adren(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	delete g_gTimerAdren[client];
	g_gTimerAdren[client] = CreateTimer(g_fCvarAdren, TimerAdren, userid);
}

Action TimerAdren(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		if( g_bSetDSP[client] )
		{
			SetEffects(client, g_iLevelDSP[client]);
		}

		g_gTimerAdren[client] = null;
	}

	return Plugin_Continue;
}

void Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( client && (g_iCvarIncap || g_bSetDSP[client]) && GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 0 )
	{
		g_bSetDSP[client] = true;
		SetEffects(client, 4); // More muffle

		//PrintToChatAll("INCAP DSP %N", client);
	}
}

void Event_Revived(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCvarIncap || g_iCvarStrike )
	{
		RequestFrame(OnFrameRevive, event.GetInt("subject"));
	}
}

void OnFrameRevive(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		if( g_iCvarStrike && GetEntProp(client, Prop_Send, g_bLeft4Dead2 ? "m_bIsOnThirdStrike" : "m_isGoingToDie") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 0 )
		{
			g_bSetDSP[client] = true;
			SetEffects(client, 2); // Some muffle

			//PrintToChatAll("B&W DSP %N", client);
		}
		else if( g_bSetDSP[client] )
		{
			g_bSetDSP[client] = false;
			SetEffects(client, 1);

			//PrintToChatAll("REVIVE DSP %N", client);
		}
	}
}

void Event_Healed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client )
	{
		if( g_bSetDSP[client] )
		{
			g_bSetDSP[client] = false;
			SetEffects(client, 1);
		}

		//PrintToChatAll("HEALED DSP %N", client);
	}
}

void SetEffects(int client, int effect)
{
	g_iLevelDSP[client] = effect;
	Terror_SetPendingDspEffect(client, 0.0, effect);
}