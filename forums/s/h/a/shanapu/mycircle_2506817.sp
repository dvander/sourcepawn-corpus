/*
 * MyCircle Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyCircle/
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <colors>
#include <emitsoundany>
#include <autoexecconfig>
#include <mystocks>

#undef REQUIRE_PLUGIN
#include <warden>
#include <hosties>
#include <lastrequest>
#define REQUIRE_PLUGIN

//#define DEBUG

#pragma semicolon 1
#pragma newdecls required

ConVar gc_fDistance;
ConVar gc_fAngle;
ConVar gc_bShowCircle;
ConVar gc_iColorCircleRed;
ConVar gc_iColorCircleGreen;
ConVar gc_iColorCircleBlue;
ConVar gc_iColorPlayerRed;
ConVar gc_iColorPlayerGreen;
ConVar gc_iColorPlayerBlue;
ConVar gc_bFreeze;
ConVar gc_bRelease;
ConVar gc_bRebel;
ConVar gc_bWeapons;
ConVar gc_bTeam;
ConVar gc_sTag;
ConVar gc_bSounds;
ConVar gc_sSoundFreezePath;
ConVar gc_sSoundUnFreezePath;
ConVar gc_sCustomCommandCircle;
ConVar gc_sCustomCommandRelease;
ConVar gc_iStuckMode;

bool gp_bWarden;
bool gp_bHosties;

bool g_bCircle;
bool g_bInCircle[MAXPLAYERS+1] = false;

char g_sTag[64];
char g_sSoundUnFreezePath[256];
char g_sSoundFreezePath[256];

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iColorCircle[4] =  { 255, 255, 255, 255 };
int g_iColorPlayer[4] =  { 255, 255, 255, 255 };
int g_iCountCircle;

Handle g_aCircle;
Handle g_hTimerCircle;

public Plugin myinfo =  {
	name = "MyCircle", 
	author = "shanapu", 
	description = "Telport players to a circle around admin/warden/ct", 
	version = "1.0.1", 
	url = "https://github.com/shanapu/MyCircle/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_circle", Command_Circle);
	RegConsoleCmd("sm_release", Command_Release);

	AutoExecConfig_SetFile("circle");
	AutoExecConfig_SetCreateFile(true);

	gc_sCustomCommandCircle = AutoExecConfig_CreateConVar("sm_circle_cmds", "ci, cir", "Set your custom chat command for circle(!circle (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands))");
	gc_sCustomCommandRelease = AutoExecConfig_CreateConVar("sm_circle_cmds_release", "unci, uncir, rel, unci, uncircle", "Set your custom chat command for release(!release (no 'sm_'/'!')(seperate with comma ', ')(max. 12 commands))");
	gc_sTag = AutoExecConfig_CreateConVar("sm_circle_tag", "{green}[{default}circle{green}]{default}", "tag/prefix in front of chat message", _, true, 0.0, true, 255.0);
	gc_fDistance = AutoExecConfig_CreateConVar("sm_circle_radius", "3", "meter distance (radius) if no radius is given in command", _, true, 1.0);
	gc_fAngle = AutoExecConfig_CreateConVar("sm_circle_angle", "360", "Angle to position players in circle if no angle is given in command", _, true, 1.0, true, 360.0);
	gc_bShowCircle = AutoExecConfig_CreateConVar("sm_circle_beam", "1", "0 - disabled, 1 - enabled circle beam on floor", _, true, 0.0, true, 1.0);
	gc_bFreeze = AutoExecConfig_CreateConVar("sm_circle_freeze", "1", "0 - disabled, 1 - freeze players after teleport", _, true, 0.0, true, 1.0);
	gc_bRelease = AutoExecConfig_CreateConVar("sm_circle_release", "1", "0 - disabled, 1 - release a single player by shoting his foot", _, true, 0.0, true, 1.0);
	gc_bRebel = AutoExecConfig_CreateConVar("sm_circle_rebel", "1", "0 - disabled, 1 - ignore rebels (need sm hosties)", _, true, 0.0, true, 1.0);
	gc_bWeapons = AutoExecConfig_CreateConVar("sm_circle_strip_weapons", "0", "0 - disabled, 1 - Strip the terrors weapons when porting to circle", _, true, 0.0, true, 1.0);
	gc_bTeam = AutoExecConfig_CreateConVar("sm_circle_team", "1", "0 - Ts & CTs, 1 - Only Terrors porting to circle", _, true, 0.0, true, 1.0);
	gc_iStuckMode = AutoExecConfig_CreateConVar("sm_circle_stuckmode", "1", "What do when player position in circle is blocked? 0 - do nothing (stuck in prop/wall), 1 - reduce the radius, 2 - try find new postion (experimental)", _, true, 0.0, true, 2.0);
	gc_iColorCircleRed = AutoExecConfig_CreateConVar("sm_circle_color_circle_red", "100", "What color to turn circle into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iColorCircleGreen = AutoExecConfig_CreateConVar("sm_circle_color_circle_green", "100", "What color to turn circle into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iColorCircleBlue = AutoExecConfig_CreateConVar("sm_circle_color_circle_blue", "255", "What color to turn circle into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_iColorPlayerRed = AutoExecConfig_CreateConVar("sm_circle_color_player_red", "0", "What color to turn player into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iColorPlayerGreen = AutoExecConfig_CreateConVar("sm_circle_color_player_green", "0", "What color to turn player into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iColorPlayerBlue = AutoExecConfig_CreateConVar("sm_circle_color_player_blue", "200", "What color to turn player into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_circle_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true, 0.0, true, 1.0);
	gc_sSoundFreezePath = AutoExecConfig_CreateConVar("sm_circle_sounds_circle", "music/MyJailbreak/freeze.mp3", "Path to the soundfile which should be played on circle.");
	gc_sSoundUnFreezePath = AutoExecConfig_CreateConVar("sm_circle_sounds_release", "music/MyJailbreak/unfreeze.mp3", "Path to the soundfile which should be played on release.");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	HookEvent("round_end", Event_RoundEnd);
	HookConVarChange(gc_sTag, OnSettingChanged);
	HookConVarChange(gc_sSoundFreezePath, OnSettingChanged);
	HookConVarChange(gc_sSoundUnFreezePath, OnSettingChanged);

	gc_sTag.GetString(g_sTag,sizeof(g_sTag));
	gc_sSoundFreezePath.GetString(g_sSoundFreezePath, sizeof(g_sSoundFreezePath));
	gc_sSoundUnFreezePath.GetString(g_sSoundUnFreezePath, sizeof(g_sSoundUnFreezePath));

	g_aCircle = CreateArray();
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sTag)
	{
		strcopy(g_sTag, sizeof(g_sTag), newValue);
	}
	else if (convar == gc_sSoundFreezePath)
	{
		strcopy(g_sSoundFreezePath, sizeof(g_sSoundFreezePath), newValue);
		if (gc_bSounds.BoolValue)
		{
			PrecacheSoundAnyDownload(g_sSoundFreezePath);
		}
	}
	else if (convar == gc_sSoundUnFreezePath)
	{
		strcopy(g_sSoundUnFreezePath, sizeof(g_sSoundUnFreezePath), newValue);
		if (gc_bSounds.BoolValue)
		{
			PrecacheSoundAnyDownload(g_sSoundUnFreezePath);
		}
	}
}

public void OnMapStart()
{
	if (GetEngineVersion() == Engine_CSS)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
	else if (GetEngineVersion() == Engine_CSGO)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/light_glow02.vmt");
	}
	else
	{
		SetFailState("Game is not supported. CS:GO/CSS? ONLY.  !Please contact me! for more game support - shanapu");
	}

	if (gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundFreezePath);
		PrecacheSoundAnyDownload(g_sSoundUnFreezePath);
	}
}

public void OnClientPutInServer(int client)
{
	g_bInCircle[client] = false;

	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public void OnMapEnd()
{
	Destroy_Circle();
}

public void OnConfigsExecuted()
{
	g_iColorCircle[0] = gc_iColorCircleRed.IntValue;
	g_iColorCircle[1] = gc_iColorCircleGreen.IntValue;
	g_iColorCircle[2] = gc_iColorCircleBlue.IntValue;

	g_iColorPlayer[0] = gc_iColorPlayerRed.IntValue;
	g_iColorPlayer[1] = gc_iColorPlayerGreen.IntValue;
	g_iColorPlayer[2] = gc_iColorPlayerBlue.IntValue;

	// Set custom Commands
	int iCount = 0;
	char sCommands[128], sCommandsL[12][32], sCommand[32];

	// Circle
	gc_sCustomCommandCircle.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ", "");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));

	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)
		{
			RegConsoleCmd(sCommand, Command_Circle);
		}
	}

	// Release
	gc_sCustomCommandRelease.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ", "");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));

	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)
		{
			RegConsoleCmd(sCommand, Command_Release);
		}
	}
}

public void OnAllPluginsLoaded()
{
	gp_bWarden = LibraryExists("warden");
	gp_bHosties = LibraryExists("lastrequest");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "warden"))
		gp_bWarden = false;

	if (StrEqual(name, "lastrequest"))
		gp_bHosties = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "warden"))
		gp_bWarden = true;

	if (StrEqual(name, "lastrequest"))
		gp_bHosties = true;
}

public Action Command_Circle(int client, int args)
{
	if (client == 0)
	{
		CReplyToCommand(client, "%s Command is in-game only", g_sTag);
		return Plugin_Handled;
	}

	if (!CheckCommandAccess(client, "circle_admin", ADMFLAG_SLAY))
	{
		if (gp_bWarden)
		{
			if (!warden_iswarden(client))
			{
				CReplyToCommand(client, "%s Command is warden only", g_sTag);
				return Plugin_Handled;
			}
		}
		else if (GetClientTeam(client) != CS_TEAM_CT)
		{
			CReplyToCommand(client, "%s Command is CT only", g_sTag);
			return Plugin_Handled;
		}
	}

	if (g_bCircle && args < 1)
	{
		Destroy_Circle();
		return Plugin_Handled;
	}

	float radius;
	float angle;

	if (args < 1) // Not enough parameters
	{
		angle = gc_fAngle.FloatValue;
		radius = gc_fDistance.FloatValue;

		Build_Circle(client, angle, radius);
		return Plugin_Handled;
	}

	char arg[10];
	GetCmdArg(1, arg, sizeof(arg));
	angle = StringToFloat(arg);

	if ((angle < 1) || (angle > 360))
	{
		CReplyToCommand(client, "%s Use an valid angle between 1 - 360", g_sTag);
		return Plugin_Handled;
	}

	if (args > 1)
	{
		GetCmdArg(2, arg, sizeof(arg));
		radius = StringToFloat(arg);
	}
	else
	{
		radius = gc_fDistance.FloatValue;
	}

	Build_Circle(client, angle, radius);

	return Plugin_Handled;
}

void Build_Circle(int client, float angle, float radius)
{
	g_iCountCircle = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (i == client)
			continue;

		if (gc_bTeam.BoolValue && GetClientTeam(i) == CS_TEAM_CT)
			continue;

		if (gp_bHosties)
		{
			if (IsClientRebel(i) && gc_bRebel.BoolValue)
				continue;
		}

		if(gc_bWeapons.BoolValue)
		{
			StripAllWeapons(i);
		}

		PushArrayCell(g_aCircle, i);
		g_iCountCircle++;
		g_bInCircle[i] = true;

		#if defined DEBUG
			CPrintToChatAll("DEBUG: Added to Array: %N", i);
		#endif
	}

	float clientPos[3], ang[3], unitradius;
	GetClientAbsOrigin(client, clientPos);
	GetClientEyeAngles(client, ang);
	unitradius = radius * 52.49343832020997;

	for (int i = 0; i < GetArraySize(g_aCircle); i++)
	{
		float newPos[3], vec[3], angles[3];
		newPos[0] = clientPos[0] + (Cosine(DegToRad(angle) * i / GetArraySize(g_aCircle)) * unitradius);
		newPos[1] = clientPos[1] + (Sine(DegToRad(angle) * i / GetArraySize(g_aCircle)) * unitradius);
		newPos[2] = clientPos[2] + 10;

		SubtractVectors(clientPos, newPos, vec);
		NormalizeVector(vec, vec);
		GetVectorAngles(vec, angles);

		int iClient = GetArrayCell(g_aCircle, i);
		SetEntityRenderColor(iClient, g_iColorPlayer[0], g_iColorPlayer[1], g_iColorPlayer[2], 255);
		TeleportEntity(iClient, newPos, angles, NULL_VECTOR);

		if (IsPlayerStuck(iClient) && gc_iStuckMode.IntValue > 0)
		{
			if (gc_iStuckMode.IntValue == 1)
			{
				newPos[0] = clientPos[0] + (Cosine(DegToRad(angle) * i / GetArraySize(g_aCircle)) * (unitradius-40));
				newPos[1] = clientPos[1] + (Sine(DegToRad(angle) * i / GetArraySize(g_aCircle)) * (unitradius-40));
			}
			else if (gc_iStuckMode.IntValue == 2)
			{
				newPos[0] = clientPos[0] + (Cosine(DegToRad(angle) * (i - 1.5) / GetArraySize(g_aCircle)) * unitradius);
				newPos[1] = clientPos[1] + (Sine(DegToRad(angle) * (i - 1.5) / GetArraySize(g_aCircle)) * unitradius);
			}

			newPos[2] = clientPos[2] + 10;
			TeleportEntity(iClient, newPos, angles, NULL_VECTOR);

#if defined DEBUG
			PrintToChatAll("DEBUG: Bad teleport %N", iClient);
			SetEntityRenderColor(iClient, 255, 0, 0, 255);
		}
		else
		{
			PrintToChatAll("DEBUG: Good teleport: %N", iClient);
#endif
		}

		if (gc_bFreeze)
		{
			SetEntityMoveType(iClient, MOVETYPE_NONE);
		}
	}

	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundFreezePath);
	}

	if (gc_bShowCircle.BoolValue && g_iBeamSprite != -1 && g_iHaloSprite != -1)
	{
		Handle hData = CreateDataPack();
		WritePackFloat(hData, clientPos[0]);
		WritePackFloat(hData, clientPos[1]);
		WritePackFloat(hData, clientPos[2]);
		WritePackFloat(hData, clientPos[2]);
		WritePackFloat(hData, unitradius);
		g_hTimerCircle = CreateTimer(1.0, Timer_ShowCircle, hData, TIMER_REPEAT);

		clientPos[2] += 3;
		TE_SetupBeamRingPoint(clientPos, (unitradius * 2 - 1.0), unitradius * 2, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 0.2, g_iColorCircle, 2, 0);
		TE_SendToAll();
	}

	g_bCircle = true;

	CPrintToChatAll("%s %N created an %.1f° circle with %i player and radius of %.1fm ", g_sTag, client, angle, GetArraySize(g_aCircle), radius);

	ClearArray(g_aCircle);
}

public Action Timer_ShowCircle(Handle timer, Handle hData)
{
	if (g_iCountCircle <= 0)
		return Plugin_Stop;

	ResetPack(hData);
	float clientPos[3], radius;
	clientPos[0] = ReadPackFloat(hData);
	clientPos[1] = ReadPackFloat(hData);
	clientPos[2] = ReadPackFloat(hData);
	clientPos[2] = ReadPackFloat(hData);
	radius = ReadPackFloat(hData);

	clientPos[2] += 3;
	TE_SetupBeamRingPoint(clientPos, (radius * 2 - 1.0), radius * 2, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 0.2, g_iColorCircle, 2, 0);
	TE_SendToAll();
	
	return Plugin_Continue;
}

bool IsPlayerStuck(int client)
{
	float vecMin[3], vecMax[3], vecOrigin[3];

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);

	GetClientAbsOrigin(client, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid, client);
	return TR_DidHit();
}

public bool TraceEntityFilterSolid(int entityhit, int contentsMask, int entity)
{
	if ((entityhit < MaxClients || entityhit > MaxClients) && entityhit != entity && entityhit != 0)
	{
		return true;
	}

	return false;
}

public Action Command_Release(int client, int args)
{
	if (client == 0)
	{
		CReplyToCommand(client, "Command is in-game only");
		return Plugin_Handled;
	}

	if (!CheckCommandAccess(client, "circle_admin", ADMFLAG_SLAY))
	{
		if (gp_bWarden)
		{
			if (!warden_iswarden(client))
			{
				CReplyToCommand(client, "Command is warden only");
				return Plugin_Handled;
			}
		}
		else if (GetClientTeam(client) != CS_TEAM_CT)
		{
			CReplyToCommand(client, "Command is CT only");
			return Plugin_Handled;
		}
	}

	Destroy_Circle();

	return Plugin_Handled;
}

public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	Destroy_Circle();
}

public void warden_OnWardenRemoved(int client)
{
	Destroy_Circle();
}

void Destroy_Circle()
{
	if (!g_bCircle || g_iCountCircle == 0)
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_bInCircle[i])
		{
			SetEntityRenderColor(i, 255, 255, 255, 255);

			if (gc_bFreeze)
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
			
			g_bInCircle[i] = false;
		}
	}

	if (gc_bSounds.BoolValue)
	{
		EmitSoundToAllAny(g_sSoundUnFreezePath);
	}

	delete g_hTimerCircle;

	g_iCountCircle = 0;
	g_bCircle = false;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!gc_bRelease.BoolValue)
		return Plugin_Continue;

	if (g_bInCircle[victim] && IsValidClient(attacker, true, false))
	{
	
		if (hitgroup == 6 || hitgroup == 7)
		{
			g_bInCircle[victim] = false;
			SetEntityMoveType(victim, MOVETYPE_WALK);
			SetEntityRenderColor(victim, 255, 255, 255, 255);

			g_iCountCircle--;

			CPrintToChatAll("%s %N has released %N", g_sTag, attacker, victim);

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}