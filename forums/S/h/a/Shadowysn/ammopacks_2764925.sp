/*
 *
 *  TF2 Ammopacks - SourceMod Plugin
 *  Copyright (C) 2009  Marc Hörsken
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#define PLUGIN_NAME "[TF2] Ammopacks"
#define PLUGIN_AUTHOR "Hunter, Shadowysn"
#define PLUGIN_DESC "Allows engineers to drop ammopacks on death or with secondary Wrench fire."
#define PLUGIN_VERSION "1.2.6c"
#define PLUGIN_URL "https://forums.alliedmods.net/showpost.php?p=2764925&postcount=87"
#define PLUGIN_NAME_SHORT "Ammopacks"
#define PLUGIN_NAME_TECH "ammopacks"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

enum OS
{
	OS_Windows,
	OS_Linux
}

OS os_RetVal;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		CreateNative("ControlAmmopacks", Native_ControlAmmopacks);
		CreateNative("SetAmmopack", Native_SetAmmopack);
		RegPluginLibrary("ammopacks");
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

#define SOUND_A "weapons/smg_clip_out.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

bool g_NativeControl = false;
bool g_EngiButtonDown[MAXPLAYERS+1];
float g_EngiPosition[MAXPLAYERS+1][3];
int g_NativeAmmopacks[MAXPLAYERS+1], g_EngiMetal[MAXPLAYERS+1];
int g_AmmopacksCount = 0, g_FilteredEntity = -1;
ConVar cvar_IsAmmopacksOn = null,
cvar_AmmopacksSmall = null,
cvar_AmmopacksSmall_Linux = null,
cvar_AmmopacksMedium = null,
cvar_AmmopacksFull = null,
cvar_AmmopacksKeep = null,
cvar_AmmopacksTeam = null,
cvar_AmmopacksLimit = null,
cvar_AmmopacksPhysics = null;
Handle g_hAmmopacksTime = null;
int g_iIsAmmopacksOn, g_iAmmopacksSmall, g_iAmmopacksMedium, g_iAmmopacksFull, g_iAmmopacksTeam, g_iAmmopacksLimit;
float g_fAmmopacksKeep;
bool g_bAmmopacksPhysics;

public void OnPluginStart()
{
	os_RetVal = GetServerOS();
	
	LoadTranslations("common.phrases");
	LoadTranslations("ammopacks.phrases");
	
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_tf_%s", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s", PLUGIN_NAME_TECH);
	cvar_IsAmmopacksOn = CreateConVar(cmd_str, "3", "Enable/Disable Ammopacks\n0 = Disabled.\n1 = On Death.\n2 = On Command.\n3 = On Death and Command.", FCVAR_NONE, true, 0.0, true, 3.0);
	cvar_IsAmmopacksOn.AddChangeHook(CC_AP_IsAmmopacksOn);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_small", PLUGIN_NAME_TECH);
	cvar_AmmopacksSmall = CreateConVar(cmd_str, "41", "(WINDOWS) Metal required for small Ammopacks", FCVAR_NONE, true, 0.0);
	Format(cmd_str, sizeof(cmd_str), "sm_%s_small_linux", PLUGIN_NAME_TECH);
	cvar_AmmopacksSmall_Linux = CreateConVar(cmd_str, "40", "(LINUX) Metal required for small Ammopacks", FCVAR_NONE, true, 0.0);
	switch (os_RetVal)
	{
		case OS_Windows:		cvar_AmmopacksSmall.AddChangeHook(CC_AP_AmmopacksSmall);
		case OS_Linux:		cvar_AmmopacksSmall_Linux.AddChangeHook(CC_AP_AmmopacksSmall);
	}
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_medium", PLUGIN_NAME_TECH);
	cvar_AmmopacksMedium = CreateConVar(cmd_str, "100", "Metal required for medium Ammopacks", FCVAR_NONE, true, 0.0);
	cvar_AmmopacksMedium.AddChangeHook(CC_AP_AmmopacksMedium);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_full", PLUGIN_NAME_TECH);
	cvar_AmmopacksFull = CreateConVar(cmd_str, "200", "Metal required for full Ammopacks", FCVAR_NONE, true, 0.0);
	cvar_AmmopacksFull.AddChangeHook(CC_AP_AmmopacksFull);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_keep", PLUGIN_NAME_TECH);
	cvar_AmmopacksKeep = CreateConVar(cmd_str, "60.0", "Time to keep Ammopacks on map.\n0 = Off.\n>0 = seconds", FCVAR_NONE, true, 0.0, true, 600.0);
	cvar_AmmopacksKeep.AddChangeHook(CC_AP_AmmopacksKeep);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_team", PLUGIN_NAME_TECH);
	cvar_AmmopacksTeam = CreateConVar(cmd_str, "3", "Team to drop Ammopacks for.\n0 = Any team.\n1 = Own team.\n2 = Opposing team.\n3 = Own on command, Any on death.", FCVAR_NONE, true, 0.0, true, 3.0);
	cvar_AmmopacksTeam.AddChangeHook(CC_AP_AmmopacksTeam);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_limit", PLUGIN_NAME_TECH);
	cvar_AmmopacksLimit = CreateConVar(cmd_str, "100", "Maximum number of extra Ammopacks on map at a time.\n0 = unlimited", FCVAR_NONE, true, 0.0, true, 512.0);
	cvar_AmmopacksLimit.AddChangeHook(CC_AP_AmmopacksLimit);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_physics", PLUGIN_NAME_TECH);
	cvar_AmmopacksPhysics = CreateConVar(cmd_str, "1", "How the Ammopacks will be dropped.\n0 = Spawn on floor.\n1 = Throw like Sandvich.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_AmmopacksPhysics.AddChangeHook(CC_AP_AmmopacksPhysics);
	
	g_hAmmopacksTime = CreateArray(_, GetMaxEntities());
	
	AutoExecConfig(true);
	SetCvarValues();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_TeamplayRoundStart, EventHookMode_Post);
	HookEntityOutput("item_ammopack_full", "OnPlayerTouch", Entity_OnPlayerTouch);
	HookEntityOutput("item_ammopack_medium", "OnPlayerTouch", Entity_OnPlayerTouch);
	HookEntityOutput("item_ammopack_small", "OnPlayerTouch", Entity_OnPlayerTouch);
	RegConsoleCmd("sm_ammopack", Command_Ammopack);
	RegAdminCmd("sm_metal", Command_MetalAmount, ADMFLAG_CHEATS);
	
	CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);
}

void CC_AP_IsAmmopacksOn(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int conVal = convar.IntValue;
	g_iIsAmmopacksOn = conVal;
	
	if (conVal > 0)
		PrintToChatAll("[SM] %t", "Enabled Ammopacks");
	else
		PrintToChatAll("[SM] %t", "Disabled Ammopacks");
}
void CC_AP_AmmopacksSmall(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iAmmopacksSmall =		convar.IntValue;		}
void CC_AP_AmmopacksMedium(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iAmmopacksMedium =	convar.IntValue;		}
void CC_AP_AmmopacksFull(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iAmmopacksFull =		convar.IntValue;		}
void CC_AP_AmmopacksKeep(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fAmmopacksKeep =		convar.FloatValue;	}
void CC_AP_AmmopacksTeam(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iAmmopacksTeam =		convar.IntValue;		}
void CC_AP_AmmopacksLimit(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iAmmopacksLimit =		convar.IntValue;		}
void CC_AP_AmmopacksPhysics(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bAmmopacksPhysics =	convar.BoolValue;		}
void SetCvarValues()
{
	CC_AP_IsAmmopacksOn(cvar_IsAmmopacksOn, "", "");
	switch (os_RetVal)
	{
		case OS_Windows:	CC_AP_AmmopacksSmall(cvar_AmmopacksSmall, "", "");
		case OS_Linux:	CC_AP_AmmopacksSmall(cvar_AmmopacksSmall_Linux, "", "");
	}
	CC_AP_AmmopacksMedium(cvar_AmmopacksMedium, "", "");
	CC_AP_AmmopacksFull(cvar_AmmopacksFull, "", "");
	CC_AP_AmmopacksKeep(cvar_AmmopacksKeep, "", "");
	CC_AP_AmmopacksTeam(cvar_AmmopacksTeam, "", "");
	CC_AP_AmmopacksLimit(cvar_AmmopacksLimit, "", "");
	CC_AP_AmmopacksPhysics(cvar_AmmopacksPhysics, "", "");
}

public void OnMapStart()
{
	PrecacheModel("models/items/ammopack_large.mdl", true);
	PrecacheModel("models/items/ammopack_medium.mdl", true);
	PrecacheModel("models/items/ammopack_small.mdl", true);
	
	PrecacheSound(SOUND_A, true);
	PrecacheSound(SOUND_B, true);
	PrecacheSound(SOUND_C, true);
	
	ClearArray(g_hAmmopacksTime);
	ResizeArray(g_hAmmopacksTime, GetMaxEntities());
	g_AmmopacksCount = 0;
	
	AutoExecConfig(true);
}

public void OnClientDisconnect(int client)
{
	g_EngiButtonDown[client] = false;
	g_EngiMetal[client] = 0;
	g_EngiPosition[client] = NULL_VECTOR;
}

public void OnClientPutInServer(int client)
{
	if (!g_NativeControl && view_as<bool>(g_iIsAmmopacksOn))
		CreateTimer(45.0, Timer_Advert, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnGameFrame()
{
	if (g_iIsAmmopacksOn < 2 && !g_NativeControl)
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_NativeControl && g_NativeAmmopacks[i] < 2)
			continue;

		if (!g_EngiButtonDown[i] && IsValidLoopClient(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
		{
			if (GetClientButtons(i) & IN_ATTACK2)
			{
				g_EngiButtonDown[i] = true;
				CreateTimer(0.5, Timer_ButtonUp, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				static char classname[64];
				TF_GetCurrentWeaponClass(i, classname, sizeof(classname));
				if (strcmp(classname, "CTFWrench", false) == 0 || strcmp(classname, "CTFRobotArm", false) == 0)
					TF_DropAmmopack(i, true);
			}
		}
	}
}

Action Command_Ammopack(int client, int args)
{
	int AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client] : g_iIsAmmopacksOn;
	if (AmmopacksOn < 2) return Plugin_Handled;
	
	if (TF2_GetPlayerClass(client) != TFClass_Engineer) return Plugin_Handled;
	
	static char classname[64];
	TF_GetCurrentWeaponClass(client, classname, sizeof(classname));
	if (strcmp(classname, "CWrench") != 0) return Plugin_Handled;
	
	TF_DropAmmopack(client, true);
	
	return Plugin_Handled;
}

Action Command_MetalAmount(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "Metal Usage");
		return Plugin_Handled;
	}
	
	static char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target = FindTarget(client, arg1);
	if (target == -1) return Plugin_Handled;
	
	static char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	if (!IsPlayerAliveNotGhost(target))
	{
		ReplyToCommand(client, "[SM] %t", "Cannot be performed on dead players", name);
		return Plugin_Handled;
	}
	
	if (TF2_GetPlayerClass(target) != TFClass_Engineer)
	{
		ReplyToCommand(client, "[SM] %t", "Not an Engineer", name);
		return Plugin_Handled;
	}
	
	int charge = 100;
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		charge = StringToInt(arg2);
		if (charge < 0 || charge > 200)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
	}
	
	TF_SetMetalAmount(target, charge);
	
	ReplyToCommand(client, "[SM] %t", "Changed Metal", name, charge);
	return Plugin_Handled;
}

Action Timer_Advert(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	
	if (!IsValidClient(client)) return Plugin_Continue;
	
	switch (g_iIsAmmopacksOn)
	{
		case 1:
			PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Ammopacks");
		case 2:
			PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Ammopacks");
		case 3:
			PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Ammopacks");
	}
	return Plugin_Continue;
}

Action Timer_Caching(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidLoopClient(i) && TF2_GetPlayerClass(i) == TFClass_Engineer)
		{
			g_EngiMetal[i] = TF_GetMetalAmount(i);
			GetClientAbsOrigin(i, g_EngiPosition[i]);
		}
	}
	
	if (g_fAmmopacksKeep > 0.0)
	{
		float mintime = GetGameTime() - g_fAmmopacksKeep;
		for (int c = MaxClients; c < GetMaxEntities(); c++)
		{
			float time = GetArrayCell(g_hAmmopacksTime, c);
			if (time > 0 && time < mintime)
			{
				SetArrayCell(g_hAmmopacksTime, c, 0);
				if (RealValidEntity(c))
				{
					static char classname[64];
					GetEntityClassname(c, classname, sizeof(classname));
					if (!strncmp(classname, "item_ammopack", 13, false))
					{
						EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
						AcceptEntityInput(c, "Kill");
						g_AmmopacksCount--;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

Action Timer_ButtonUp(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	
	g_EngiButtonDown[client] = false;
	return Plugin_Continue;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (!IsValidClient(client)) return;
	
	int AmmopacksOn = g_NativeControl ? g_NativeAmmopacks[client] : g_iIsAmmopacksOn;
	if (AmmopacksOn < 1 || AmmopacksOn == 2) return;
	
	if (TF2_GetPlayerClass(client) != TFClass_Engineer) return;
	
	if (event.GetInt("weaponid", 0) == TF_WEAPON_BAT_FISH && event.GetInt("customkill", 0) != TF_CUSTOM_FISH_KILL) // this isn't a kill 
		return;
	
	TF_DropAmmopack(client, false);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetInt("disconnect", 0)) return;
	
	if (event.GetInt("team", 0) > 1) return;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (!IsValidClient(client)) return;
	
	g_EngiButtonDown[client] = false;
	g_EngiMetal[client] = 0;
	g_EngiPosition[client] = NULL_VECTOR;
}

void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int full_reset = event.GetInt("full_reset");
	if (full_reset)
	{
		for (int c = MaxClients; c < GetMaxEntities(); c++)
		{
			int time = GetArrayCell(g_hAmmopacksTime, c);
			if (time > 0)
			{
				SetArrayCell(g_hAmmopacksTime, c, 0);
				g_AmmopacksCount--;
			}
		}
	}
}

void Entity_OnPlayerTouch(const char[] output, int caller, int activator, float delay)
{
	int time = GetArrayCell(g_hAmmopacksTime, caller);
	if (time > 0 && activator > 0)
	{
		SetArrayCell(g_hAmmopacksTime, caller, 0);
		g_AmmopacksCount--;
	}
}

bool AmmopackTraceFilter(int ent, int contentMask)
{
	return (ent != g_FilteredEntity);
}

stock void TF_SpawnAmmopack(int client, const char[] name, bool cmd)
{
	float PlayerPos[3];
	if (cmd)
		GetClientAbsOrigin(client, PlayerPos);
	else
		PlayerPos = g_EngiPosition[client];
	
	if (PlayerPos[0] != 0.0 && PlayerPos[1] != 0.0 && PlayerPos[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPos[2] += 4;
		g_FilteredEntity = client;
		float PhysicsVel[3]; PhysicsVel = NULL_VECTOR;
		
		float PlayerAngle[3];
		GetClientEyeAngles(client, PlayerAngle);
		
		if (cmd && !g_bAmmopacksPhysics)
		{
			float PlayerPosEx[3], PlayerPosAway[3];
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPos, PlayerPosEx, PlayerPosAway);

			Handle TraceEx = TR_TraceRayFilterEx(PlayerPos, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
			TR_GetEndPosition(PlayerPos, TraceEx);
			CloseHandle(TraceEx);
		}
		if (g_bAmmopacksPhysics)
		{
			PlayerAngle[0] -= 10.0;
			float vecForward[3], vecRight[3], vecUp[3];
			GetAngleVectors( PlayerAngle, vecForward, vecRight, vecUp );
			PhysicsVel[0] = vecForward[0] * 325.0;
			PhysicsVel[1] = vecForward[1] * 325.0;
			PhysicsVel[2] = vecForward[2] * 325.0;
		}

		float AmmoPos[3];
		if (!g_bAmmopacksPhysics)
		{
			float Direction[3];
			Direction[0] = PlayerPos[0];
			Direction[1] = PlayerPos[1];
			Direction[2] = PlayerPos[2]-1024;
			Handle Trace = TR_TraceRayFilterEx(PlayerPos, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
			TR_GetEndPosition(AmmoPos, Trace);
			CloseHandle(Trace);
		}
		else
		{
			AmmoPos[0] = PlayerPos[0];
			AmmoPos[1] = PlayerPos[1];
			AmmoPos[2] = PlayerPos[2] + 20;
		}

		AmmoPos[2] += 4;

		int Ammopack = CreateEntityByName(name);
		DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
		if (DispatchSpawn(Ammopack))
		{
			int team = 0;
			if (g_iAmmopacksTeam == 2)
				team = ((GetClientTeam(client)-1) % 2) + 2;
			else if (g_iAmmopacksTeam == 1 || (g_iAmmopacksTeam == 3 && cmd))
				team = GetClientTeam(client);
			
			DataPack dataP = CreateDataPack();
			CreateDataTimer(0.5, PreventPickup_Timer, dataP, TIMER_FLAG_NO_MAPCHANGE);
			dataP.WriteCell(EntIndexToEntRef(Ammopack));
			dataP.WriteCell(team);
			
			SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", TFTeam_Spectator); // This helps keep both teams from picking it up prematurely, including the thrower
			//SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team, 4);
			TeleportEntity(Ammopack, AmmoPos, NULL_VECTOR, PhysicsVel);
			EmitSoundToAll(SOUND_B, Ammopack, _, _, _, 0.75);
			SetArrayCell(g_hAmmopacksTime, Ammopack, GetGameTime());
			g_AmmopacksCount++;
			
			if (g_bAmmopacksPhysics)
			{
				DoPhysics(Ammopack, client);
			}
		}
	}
}

void DoPhysics(int pack, int client = -1)
{
	//DispatchKeyValue(pack, "velocity", "0.0 0.0 1.0");
	//DispatchKeyValue(pack, "basevelocity", "0.0 0.0 1.0");
	
	SetEntProp(pack, Prop_Data, "m_bActivateWhenAtRest", 1);
	SetEntProp(pack, Prop_Send, "m_ubInterpolationFrame", 0);
	SetEntPropEnt(pack, Prop_Send, "m_hOwnerEntity", client);
	SetEntityGravity(pack, 1.0);
	
	DispatchKeyValue(pack, "nextthink", "0.1"); // The fix to the laggy physics.
	
	RequestFrame(SpawnPack_FrameCallback, pack); // Have to change movetype in a frame callback
}

void SpawnPack_FrameCallback(int pack)
{
	if (!RealValidEntity(pack)) return;
	
	SetEntityMoveType(pack, MOVETYPE_FLYGRAVITY);
	SetEntProp(pack, Prop_Send, "movecollide", 1); // These two...
	SetEntProp(pack, Prop_Data, "m_MoveCollide", 1); // ...allow the pack to bounce.
}
Action PreventPickup_Timer(Handle timer, DataPack dataP)
{
	dataP.Reset();
	int entity = EntRefToEntIndex(dataP.ReadCell());
	int team = dataP.ReadCell();
	
	if (entity == -1) return Plugin_Continue;
	
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
	return Plugin_Continue;
}

stock OS GetServerOS()
{
	static char sCmdLine[4];
	GetCommandLine(sCmdLine, sizeof(sCmdLine));
	return (sCmdLine[0] == '.') ? OS_Linux : OS_Windows;
}

stock bool IsEntLimitReached()
{
	if (GetEntityCount() >= (GetMaxEntities()-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
		return true;
	}
	else
		return false;
}

stock int TF_GetMetalAmount(int client)
{
	return GetEntData(client, FindDataMapInfo(client, "m_iAmmo") + (3 * 4), 4);
}

stock void TF_SetMetalAmount(int client, int metal)
{
	g_EngiMetal[client] = metal;
	SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + (3 * 4), metal, 4, true);
}

stock void TF_GetCurrentWeaponClass(int client, char[] name, int maxlength)
{
	int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (RealValidEntity(index))
		GetEntityNetClass(index, name, maxlength);
	else
		name[0] = '\0';
}

stock bool TF_DropAmmopack(int client, bool cmd)
{
	int metal;
	if (cmd)
		metal = TF_GetMetalAmount(client);
	else
		metal = g_EngiMetal[client];
	
	if (g_iAmmopacksLimit > 0 && g_AmmopacksCount >= g_iAmmopacksLimit)
		metal = 0;
	
	if (metal >= g_iAmmopacksFull && g_iAmmopacksFull != 0)
	{
		if (cmd) TF_SetMetalAmount(client, (metal-g_iAmmopacksFull));
		TF_SpawnAmmopack(client, "item_ammopack_full", cmd);
		return true;
	}
	else if (metal >= g_iAmmopacksMedium && g_iAmmopacksMedium != 0)
	{
		if (cmd) TF_SetMetalAmount(client, (metal-g_iAmmopacksMedium));
		TF_SpawnAmmopack(client, "item_ammopack_medium", cmd);
		return true;
	}
	else if (metal >= g_iAmmopacksSmall && g_iAmmopacksSmall != 0)
	{
		if (cmd) TF_SetMetalAmount(client, (metal-g_iAmmopacksSmall));
		TF_SpawnAmmopack(client, "item_ammopack_small", cmd);
		return true;
	}
	if (cmd) EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
	
	return false;
}

public int Native_ControlAmmopacks(Handle plugin, int numParams)
{
	if (numParams == 0)
		g_NativeControl = true;
	else if (numParams == 1)
		g_NativeControl = GetNativeCell(1);
	return 0;
}

public int Native_SetAmmopack(Handle plugin, int numParams)
{
	if (numParams >= 1 && numParams <= 2)
	{
		int client = GetNativeCell(1);
		g_NativeAmmopacks[client] = (numParams >= 2) ? GetNativeCell(2) : 3;
	}
	return 0;
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsValidLoopClient(int client, bool replaycheck = true)
{
	if (IsClientInGame(client) && !GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }