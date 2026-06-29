/**
 * ==============================================================================
 * [TF2] Respawn System API!
 * Copyright (C) 2016 Benoist3012
 * ==============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2_respawn>

#define PLUGIN_VERSION "0.2"

#define TFTeam_Spectator 1
#define TFTeam_Red 2
#define TFTeam_Blue 3
#define TFTeam_Boss 5

#define MAX_TEAM 4

#define INFINITE_RESPAWN_TIME 99999.0

public Plugin myinfo = 
{
	name			= "[TF2] Respawn System API!",
	author			= "Benoist3012",
	description		= "Custom API to override client's respawn time!",
	version			= PLUGIN_VERSION,
	url				= "http://steamcommunity.com/id/Benoist3012/"
};
//Gameplay entities.
int g_iPlayerManager;

//Client respawn time.
float g_flClientRespawnTime[MAXPLAYERS + 1];

//Respawn time logic.
float g_flTeamRespawnTime[MAX_TEAM];
float g_flOldTeamRespawnTime[MAX_TEAM];

//Game's respawn convars.
ConVar cvarRespawnWaveTimes;

//Forwards
Handle fOnClientRespawnTimeSet;
Handle fOnTeamRespawnTimeChanged;
Handle fOnClientRespawnTimeUpdated;

/*
*
* General plugin hook functions
*
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error,int err_max)
{
	RegPluginLibrary("tf2_respawn_time");
	
	//Forwards
	fOnClientRespawnTimeSet = CreateGlobalForward("TF2_OnClientRespawnTimeSet", ET_Hook, Param_Cell, Param_FloatByRef);
	fOnTeamRespawnTimeChanged = CreateGlobalForward("TF2_OnTeamRespawnTimeChanged", ET_Hook, Param_Cell, Param_FloatByRef);
	fOnClientRespawnTimeUpdated = CreateGlobalForward("TF2_OnClientRespawnTimeUpdated", ET_Hook, Param_Cell, Param_FloatByRef);
	
	//Natives
	CreateNative("TF2_IsClientRespawning", Native_IsClientRespawning);
	CreateNative("TF2_GetTeamRespawnTime", Native_GetTeamRespawnTime);
	CreateNative("TF2_GetClientRespawnTime", Native_GetClientRespawnTime);
	CreateNative("TF2_SetClientRespawnTime", Native_SetClientRespawnTime);
	CreateNative("TF2_UpdateClientRespawnTime", Native_UpdateClientRespawnTime);
	CreateNative("TF2_SetTeamRespawnTime", Native_SetTeamRespawnTime);
	CreateNative("TF2_UpdateTeamRespawnTime", Native_UpdateTeamRespawnTime);
	
	return APLRes_Success;
}
	
public void OnPluginStart()
{
	//Event Hooks.
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	//Game's cvars.
	cvarRespawnWaveTimes = FindConVar("mp_respawnwavetime");
	HookConVarChange(cvarRespawnWaveTimes, Cvar_RespawnWaveTimeChange);
	
	//Start the respawn time logic.
	CreateTimer(1.0, Timer_AverageUpdateRespawnTime, _, TIMER_REPEAT);
	
	CreateConVar("tf2_respawn_api", PLUGIN_VERSION, "[TF2] Respawn System API!", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	//Find the tf_player_manager entity.
	g_iPlayerManager = GetPlayerResourceEntity();
	
	//Get the default respawn time
	g_flTeamRespawnTime[TFTeam_Blue] = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", TFTeam_Blue);
	g_flTeamRespawnTime[TFTeam_Red] = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", TFTeam_Red);
	
	if (g_flTeamRespawnTime[TFTeam_Blue] >= INFINITE_RESPAWN_TIME) g_flTeamRespawnTime[TFTeam_Blue] = 10.0;
	if (g_flTeamRespawnTime[TFTeam_Red] >= INFINITE_RESPAWN_TIME) g_flTeamRespawnTime[TFTeam_Blue] = 10.0;
	
	g_flTeamRespawnTime[TFTeam_Blue] += cvarRespawnWaveTimes.FloatValue;
	g_flTeamRespawnTime[TFTeam_Red] += cvarRespawnWaveTimes.FloatValue;
	
	g_flOldTeamRespawnTime[TFTeam_Blue] = g_flTeamRespawnTime[TFTeam_Blue];
	g_flOldTeamRespawnTime[TFTeam_Red] = g_flTeamRespawnTime[TFTeam_Red];
	
	//Start our hooking logic
	GameRules_SetPropFloat("m_TeamRespawnWaveTimes", INFINITE_RESPAWN_TIME, TFTeam_Blue);
	GameRules_SetPropFloat("m_TeamRespawnWaveTimes", INFINITE_RESPAWN_TIME, TFTeam_Red);
}

/*
*
* Events
*
*/

public Action Event_PlayerSpawn(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	//Reset the desired respawn time.
	g_flClientRespawnTime[iClient] = 0.0;
	//Remove the hook.
	SDKUnhook(iClient, SDKHook_SetTransmit, OverrideRespawnHud);
}

public Action Event_PlayerDeath(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
	//Actually respawning a spectator will result in a crash.
	if(GetClientTeam(iClient) > 1)
	{
		//Set the client's respawn time.
		if(g_flClientRespawnTime[iClient] <= 0.0)
		{
			//Call our forward (TF2_OnClientRespawnTimeSet)
			Action iAction;
			float flRespawnTime = g_flTeamRespawnTime[GetClientTeam(iClient)];
			float flRespawnTime2 = flRespawnTime;
			Call_StartForward(fOnClientRespawnTimeSet);
			Call_PushCell(iClient);
			Call_PushFloatRef(flRespawnTime2);
			Call_Finish(iAction);

			if (iAction == Plugin_Changed) flRespawnTime = flRespawnTime2;
			
			TF2_SetClientRespawnTimeEx(iClient, flRespawnTime);
		}
	}
}

/*
*
* Core
*
*/

public void Cvar_RespawnWaveTimeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	float flOldRespawnWaveTime = StringToFloat(oldValue);
	float flNewRespawnWaveTime = StringToFloat(newValue);
	
	for (int iTeam = TFTeam_Red; iTeam <= TFTeam_Blue; iTeam++)
	{
		g_flTeamRespawnTime[iTeam] -= flOldRespawnWaveTime;
		g_flTeamRespawnTime[iTeam] += flNewRespawnWaveTime;
	}
	TF2_RecalculateRespawnTime();
}

public Action Timer_AverageUpdateRespawnTime(Handle hTimer)
{
	for (int iTeam = TFTeam_Red; iTeam <= TFTeam_Blue; iTeam++)
	{
		float flCurrentTeamRespawnTime = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", iTeam);
		if (flCurrentTeamRespawnTime != INFINITE_RESPAWN_TIME) //The game has updated the respawntime.
		{
			flCurrentTeamRespawnTime += cvarRespawnWaveTimes.FloatValue;
			
			//Call our forward (TF2_OnTeamRespawnTimeChanged)
			Action iAction;
			float flCurrentTeamRespawnTime2 = flCurrentTeamRespawnTime;
			Call_StartForward(fOnTeamRespawnTimeChanged);
			Call_PushCell(iTeam);
			Call_PushFloatRef(flCurrentTeamRespawnTime2);
			Call_Finish(iAction);

			if (iAction == Plugin_Changed) flCurrentTeamRespawnTime = flCurrentTeamRespawnTime2;
		
			g_flTeamRespawnTime[iTeam] = flCurrentTeamRespawnTime;
			TF2_RecalculateRespawnTime();
			GameRules_SetPropFloat("m_TeamRespawnWaveTimes", INFINITE_RESPAWN_TIME, iTeam);
		}
	}
}

void TF2_RecalculateRespawnTime()//Re-sync respawntime of everyone on the server.
{
	for (int iTeam = TFTeam_Red; iTeam <= TFTeam_Blue; iTeam++)
	{
		if (g_flTeamRespawnTime[iTeam] != g_flOldTeamRespawnTime[iTeam])//Global team respawn time changed.
		{
			//Find out by how much the new respawn time changed, and add it to actual client respawning.
			float flDeltaRespawnTime = g_flTeamRespawnTime[iTeam]-g_flOldTeamRespawnTime[iTeam];
			TF2_UpdateTeamRespawnEx(iTeam, flDeltaRespawnTime);
			
			g_flOldTeamRespawnTime[iTeam] = g_flTeamRespawnTime[iTeam];
		}
	}
}

stock void TF2_SetClientRespawnTimeEx(int iClient,float flRespawnTime)
{
	//SetTransmit is faster than OnGameFrame to override the Respawn Hud, because the game tries to set it back.
	SDKHook(iClient, SDKHook_SetTransmit, OverrideRespawnHud);
	//Set our desired respawn time.
	g_flClientRespawnTime[iClient] = GetGameTime()+flRespawnTime;
}

stock void TF2_UpdateTeamRespawnEx(int iTeam,float flNewRespawnTime)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == iTeam && g_flClientRespawnTime[i] > 0.0)
		{
			if(!IsPlayerAlive(i))
			{
				//Call our forward (TF2_OnClientRespawnTimeUpdated)
				Action iAction;
				float flNewRespawnTime2 = flNewRespawnTime;
				Call_StartForward(fOnClientRespawnTimeUpdated);
				Call_PushCell(i);
				Call_PushFloatRef(flNewRespawnTime2);
				Call_Finish(iAction);

				if (iAction == Plugin_Changed) flNewRespawnTime = flNewRespawnTime2;
				
				//Update client's respawn time.
				g_flClientRespawnTime[i] += flNewRespawnTime;
			}
		}
	}
}

stock void TF2_UpdateTeamRespawnEx2(int iTeam,float flNewRespawnTime)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == iTeam && g_flClientRespawnTime[i] > 0.0)
		{
			if(!IsPlayerAlive(i))
			{
				//Update client's respawn time.
				g_flClientRespawnTime[i] += flNewRespawnTime;
			}
		}
	}
}

public Action OverrideRespawnHud(int iClient,int iOther)
{
	//Actually we are overriding the hud for one client only.
	if(iClient == iOther)
	{
		//Set the desired respawn time on the Hud.
		SetEntPropFloat(g_iPlayerManager, Prop_Send, "m_flNextRespawnTime", g_flClientRespawnTime[iClient], iClient);
		//Destroy the hook if the client is alive.
		if(IsPlayerAlive(iClient))
		{
			//Reset the desired respawn time.
			g_flClientRespawnTime[iClient] = 0.0;
			//Remove the hook.
			SDKUnhook(iClient, SDKHook_SetTransmit, OverrideRespawnHud);
		}
		//Make the client respawn if our desired respawn time is elapsed.
		if(g_flClientRespawnTime[iClient] < GetGameTime())
		{
			//Respawn the player.
			TF2_RespawnPlayer(iClient);
			//Reset the desired respawn time.
			g_flClientRespawnTime[iClient] = 0.0;
			//Remove the hook.
			SDKUnhook(iClient, SDKHook_SetTransmit, OverrideRespawnHud);
		}
	}
}

/*
*
* Natives
*
*/

public int Native_IsClientRespawning(Handle hPlugin,int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(g_flClientRespawnTime[iClient] > 0.0 && !IsPlayerAlive(iClient))
		return view_as<bool>(true);
	return view_as<bool>(false);
}


public int Native_GetTeamRespawnTime(Handle hPlugin,int iNumParams)
{
	int iTeam = GetNativeCell(1);
	float flRespawnTime = 0.0;
	if(1 < iTeam < 4)
		flRespawnTime = GameRules_GetPropFloat("m_TeamRespawnWaveTimes", iTeam);
	return view_as<int>(flRespawnTime);
}

public int Native_GetClientRespawnTime(Handle hPlugin,int iNumParams)
{
	int iClient = GetNativeCell(1);
	return view_as<int>(g_flClientRespawnTime[iClient]);
}

public int Native_SetClientRespawnTime(Handle hPlugin,int iNumParams)
{
	int iClient = GetNativeCell(1);
	float flRespawnTime = view_as<float>(GetNativeCell(2));
	if(IsClientInGame(iClient) && !IsPlayerAlive(iClient))
	{
		if(g_flClientRespawnTime[iClient] <= 0.0)
		{
			TF2_SetClientRespawnTimeEx(iClient, flRespawnTime);
			return view_as<bool>(true);
		}
	}
	return view_as<bool>(false);
}

public int Native_UpdateClientRespawnTime(Handle hPlugin,int iNumParams)
{
	int iClient = GetNativeCell(1);
	float flNewRespawnTime = view_as<float>(GetNativeCell(2));
	if(IsClientInGame(iClient) && !IsPlayerAlive(iClient))
	{
		g_flClientRespawnTime[iClient] += flNewRespawnTime;
		return view_as<bool>(true);
	}
	return view_as<bool>(false);
}

public int Native_SetTeamRespawnTime(Handle hPlugin,int iNumParams)
{
	int iTeam = GetNativeCell(1);
	float flRespawnTime = view_as<float>(GetNativeCell(2));
	if(1 < iTeam < 4)
	{
		GameRules_SetPropFloat("m_TeamRespawnWaveTimes", flRespawnTime, iTeam);
		return view_as<bool>(true);
	}
	return view_as<bool>(false);
}

public int Native_UpdateTeamRespawnTime(Handle hPlugin,int iNumParams)
{
	int iTeam = GetNativeCell(1);
	float flNewRespawnTime = view_as<float>(GetNativeCell(2));
	if(1 < iTeam < 4)
	{
		TF2_UpdateTeamRespawnEx2(iTeam, flNewRespawnTime);
		return view_as<bool>(true);
	}
	return view_as<bool>(false);
}