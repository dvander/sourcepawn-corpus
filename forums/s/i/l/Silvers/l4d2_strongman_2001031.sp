/*
*	Strongman Game
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



#define PLUGIN_VERSION		"1.5"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Strongman Game
*	Author	:	SilverShot
*	Descrp	:	Auto-spawn the Strongman game on round start.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=221987
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.4 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.3 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Added better error log message when gamedata file is missing.

1.2 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.1.1 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.0 (29-Jul-2013)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified the SetTeleportEndPoint()
	https://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[\x04Strongman\x05] \x01"
#define CONFIG_SPAWNS		"data/l4d2_strongman.cfg"
#define MAX_SPAWNS			2
#define MAX_ENTS			23

#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"
#define MODEL_BELL			"models/props_fairgrounds/strongmangame_bell.mdl"
#define MODEL_PUCK			"models/props_fairgrounds/strongmangame_puck.mdl"
#define MODEL_GAME			"models/props_fairgrounds/strongmangame_tower.mdl"
#define MODEL_LVL1			"models/props_fairgrounds/strongman_baby.mdl"
#define MODEL_LVL2			"models/props_fairgrounds/strongman_lilpeanut.mdl"
#define MODEL_LVL3			"models/props_fairgrounds/strongman_cashew.mdl"
#define MODEL_LVL4			"models/props_fairgrounds/strongman_almondo.mdl"
#define MODEL_LVL5			"models/props_fairgrounds/strongman_moustachio.mdl"
#define MODEL_SPRITE		"sprites/glow01.spr"

#define SND_LIGHT_ON		"level/light_on.wav"
#define SND_BELL_BREAK		"level/loud/bell_break.wav"
#define SND_ADREN_IMPACT	"level/loud/adrenaline_impact.wav"
#define SND_STRONG_BELL		"level/bell_normal.wav"
#define SND_FAIL			"level/puck_fail.wav"

#define SND_ATTRACT_01		"npc/moustachio/strengthattract01.wav"
#define SND_ATTRACT_02		"npc/moustachio/strengthattract02.wav"
#define SND_ATTRACT_03		"npc/moustachio/strengthattract03.wav"
#define SND_ATTRACT_04		"npc/moustachio/strengthattract04.wav"
#define SND_ATTRACT_05		"npc/moustachio/strengthattract05.wav"
#define SND_ATTRACT_06		"npc/moustachio/strengthattract06.wav"
#define SND_ATTRACT_07		"npc/moustachio/strengthattract07.wav"
#define SND_ATTRACT_08		"npc/moustachio/strengthattract08.wav"
#define SND_ATTRACT_09		"npc/moustachio/strengthattract09.wav"
#define SND_ATTRACT_10		"npc/moustachio/strengthattract10.wav"

#define SND_LEVEL_1			"npc/moustachio/strengthlvl1_littlepeanut.wav"
#define SND_LEVEL_2			"npc/moustachio/strengthlvl2_babypeanut.wav"
#define SND_LEVEL_3			"npc/moustachio/strengthlvl3_oldpeanut.wav"
#define SND_LEVEL_4			"npc/moustachio/strengthlvl4_notbad.wav"
#define SND_LEVEL_5			"npc/moustachio/strengthlvl5_sostrong.wav"

#define SND_BREAK			"npc/moustachio/strengthbreakmachine.wav"


Menu g_hMenuPos;
ConVar g_hCvarAllow, g_hCvarEvent, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hDecayRate;
int g_iCvarEvent, g_iPlayerSpawn, g_iRoundStart, g_iStrongIndex[MAX_SPAWNS], g_iStrongmanCount, g_iStrongman[MAX_SPAWNS][MAX_ENTS];
bool g_bCvarAllow, g_bMapStarted, g_bSpawned;
float g_fDecayRate, g_vStrongPos[MAX_SPAWNS][3];


enum
{
	INDEX_STRONGMAN,
	INDEX_TOP,
	INDEX_TOP_2,
	INDEX_SPRITE_TOP,
	INDEX_BELL,
	INDEX_PUCK,
	INDEX_TIER_1,
	INDEX_TIER_2,
	INDEX_TIER_3,
	INDEX_TIER_4,
	INDEX_SPRITE_T1,
	INDEX_SPRITE_T2,
	INDEX_SPRITE_T3,
	INDEX_SPRITE_T4,
	INDEX_PROPANE,
	INDEX_LOGIC_SCRIPT,
	INDEX_SOUND_PUCK,
	INDEX_LOGIC_TIMER,
	INDEX_LOGIC_RELAY,
	INDEX_PARTICLE_BELL_1,
	INDEX_PARTICLE_BELL_2,
	INDEX_PARTICLE_BELL_3,
	INDEX_PARTICLE_BELL_4
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Strongman Game",
	author = "SilverShot",
	description = "Auto-spawn the Strongman game on round start.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=221987"
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
	g_hCvarAllow = CreateConVar(	"l4d2_strongman_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarEvent = CreateConVar(	"l4d2_strongman_event",			"0",			"0=Off. 1=Turns on the ability to receive the 'GONG SHOW' achievement for 'Proving you are stronger than Moustachio'.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d2_strongman_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d2_strongman_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d2_strongman_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d2_strongman_version",		PLUGIN_VERSION,	"Strongman Game plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_strongman");

	RegAdminCmd("sm_strong",		CmdStrong,		ADMFLAG_ROOT, 	"Spawns a Strongman where your crosshair is pointing.");
	RegAdminCmd("sm_strongman",		CmdStrongman,	ADMFLAG_ROOT, 	"Same as above, but saves the origin and angle to the Strongman spawns config.");
	RegAdminCmd("sm_strong_clear",	CmdStrongClear,	ADMFLAG_ROOT, 	"Removes the Strongman games from the current map only.");
	RegAdminCmd("sm_strong_del",	CmdStrongDel,	ADMFLAG_ROOT, 	"Deletes the Strongman game you are pointing at and removes from the config if saved.");
	RegAdminCmd("sm_strong_list",	CmdStrongList,	ADMFLAG_ROOT, 	"Lists all the Strongman games on the current map and their locations.");
	RegAdminCmd("sm_strong_pos",	CmdStrongPos,	ADMFLAG_ROOT, 	"Displays a menu to adjust the Strongman angles/origin your crosshair is over.");
	RegAdminCmd("sm_strong_wipe",	CmdStrongWipe,	ADMFLAG_ROOT, 	"Removes all the Strongman games from the current map and deletes them from config.");

	g_hDecayRate = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarEvent.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_PROPANE, true);
	PrecacheModel(MODEL_BELL, true);
	PrecacheModel(MODEL_PUCK, true);
	PrecacheModel(MODEL_GAME, true);
	PrecacheModel(MODEL_LVL1, true);
	PrecacheModel(MODEL_LVL2, true);
	PrecacheModel(MODEL_LVL3, true);
	PrecacheModel(MODEL_LVL4, true);
	PrecacheModel(MODEL_LVL5, true);
	PrecacheModel(MODEL_SPRITE, true);

	PrecacheSound(SND_LIGHT_ON);
	PrecacheSound(SND_BELL_BREAK);
	PrecacheSound(SND_ADREN_IMPACT);
	PrecacheSound(SND_STRONG_BELL);
	PrecacheSound(SND_FAIL);
	PrecacheSound(SND_ATTRACT_01);
	PrecacheSound(SND_ATTRACT_02);
	PrecacheSound(SND_ATTRACT_03);
	PrecacheSound(SND_ATTRACT_04);
	PrecacheSound(SND_ATTRACT_05);
	PrecacheSound(SND_ATTRACT_06);
	PrecacheSound(SND_ATTRACT_07);
	PrecacheSound(SND_ATTRACT_08);
	PrecacheSound(SND_ATTRACT_09);
	PrecacheSound(SND_ATTRACT_10);
	PrecacheSound(SND_LEVEL_1);
	PrecacheSound(SND_LEVEL_2);
	PrecacheSound(SND_LEVEL_3);
	PrecacheSound(SND_LEVEL_4);
	PrecacheSound(SND_LEVEL_5);
	PrecacheSound(SND_BREAK);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
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
	g_iCvarEvent = g_hCvarEvent.IntValue;
	g_fDecayRate = g_hDecayRate.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		if( g_bMapStarted )
			LoadStrongman();
		g_bCvarAllow = true;

		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;

		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
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
//					COMMANDS - STRONGMAN
// ====================================================================================================
Action CmdStrong(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Strongman] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iStrongmanCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Strongman. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	// Set player position as strongman spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place strongman, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}
	else if( g_iStrongmanCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Strongman. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	MakeStrongman(vPos, vAng);
	return Plugin_Handled;
}

Action CmdStrongman(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Strongman] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iStrongmanCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Strongman. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = OpenConfig();
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the strongman config (%s).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )	// Create key
	{
		PrintToChat(client, "%sError: Failed to add map to strongman spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Strongman are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Strongman. Used: (%d/%d).", CHAT_TAG, iCount, MAX_SPAWNS);
		delete hFile;
		return Plugin_Handled;
	}

	// Get position for strongman spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place strongman, please try again.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[10];
	Format(sTemp, sizeof(sTemp), "angle%d", iCount);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin%d", iCount);
	hFile.SetVector(sTemp, vPos);

	// Save cfg
	hFile.Rewind();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	hFile.ExportToFile(sPath);
	delete hFile;

	// Create strongman
	MakeStrongman(vPos, vAng, iCount);
	PrintToChat(client, "%s(%d/%d) - Created at pos:[%f %f %f] ang:[%f %f %f]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}


// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	float vAngles[3], vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if( TR_DidHit(trace) )
	{
		float vBuffer[3], vStart[3], distance;

		TR_GetEndPosition(vStart, trace);
		distance = -15.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] = vStart[0] + (vBuffer[0] * distance);
		vPos[1] = vStart[1] + (vBuffer[1] * distance);
		vPos[2] = vStart[2] + (vBuffer[2] * distance);
		vPos[2] = GetGroundHeight(vPos);
		if( vPos[2] == 0.0 )
		{
			delete trace;
			return false;
		}

		vAng = vAngles;
		vAng[0] = 0.0;
		vAng[1] += 90.0;
		vAng[2] = 0.0;
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

float GetGroundHeight(float vPos[3])
{
	float vAng[3];

	Handle trace = TR_TraceRayFilterEx(vPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	delete trace;
	return vAng[2];
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}



// ====================================================================================================
//					COMMANDS - CLEAR, DELETE, LIST, WIPE
// ====================================================================================================
int IsEntStored(int entity)
{
	int i, u;
	for( i = 0; i < MAX_SPAWNS; i++ )
	{
		for( u = INDEX_STRONGMAN; u <= INDEX_TIER_4; u++ )
			if( g_iStrongman[i][u] == entity )
				return i;
	}
	return -1;
}

Action CmdStrongClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Strongman] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Strongman games removed from the map", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

Action CmdStrongDel(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Strongman] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	// Check they are aiming at a strongman we made
	int index, entity = GetClientAimTarget(client, false);
	if( entity <= MaxClients || (index = IsEntStored(EntIndexToEntRef(entity))) == -1 )
	{
		PrintToChat(client, "%sInvalid target.", CHAT_TAG);
		return Plugin_Handled;
	}

	RemoveGame(index);
	g_iStrongmanCount--;

	// Load config
	KeyValues hFile = OpenConfig(false);
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the strongman config (%s).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sCannot find map.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Strongman
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	float fTempPos[3], vPos[3], vAng[3];
	char sTemp[10], sTempB[10];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fTempPos);

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "angle%d", i);
		Format(sTempB, sizeof(sTempB), "origin%d", i);

		hFile.GetVector(sTemp, vAng);
		hFile.GetVector(sTempB, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(fTempPos, vPos) <= 1.0 )
			{
				hFile.DeleteKey(sTemp);
				hFile.DeleteKey(sTempB);
				bMove = true;
			}
			else if( i == iCount ) // Not found any Strongman... exit
			{
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			hFile.DeleteKey(sTemp);
			hFile.DeleteKey(sTempB);

			// Replace with new
			Format(sTemp, sizeof(sTemp), "angle%d", i-1);
			hFile.SetVector(sTemp, vAng);
			Format(sTempB, sizeof(sTempB), "origin%d", i-1);
			hFile.SetVector(sTempB, vPos);
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);


	// Save to file
	hFile.Rewind();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(%d/%d) - Strongman removed from config, add new Strongman with sm_strongman.", CHAT_TAG, iCount, MAX_SPAWNS);
	return Plugin_Handled;
}
Action CmdStrongList(int client, int args)
{
	float vPos[3];
	int i, ent;

	for( i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iStrongman[i][INDEX_STRONGMAN];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);

			if( client == 0 )
				ReplyToCommand(client, "[Strongman] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		ReplyToCommand(client, "[Strongman] Total: %d/%d.", g_iStrongmanCount, MAX_SPAWNS);
	else
		PrintToChat(client, "%sTotal: %d/%d.", CHAT_TAG, g_iStrongmanCount, MAX_SPAWNS);

	return Plugin_Handled;
}

Action CmdStrongWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Strongman] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = OpenConfig(false);
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the strongman config (%s).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sCannot find map in strongman config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All Strongman removed from config, add new Strongman with sm_strongman.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
Action CmdStrongPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 8 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}

	return 0;
}

void SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vPos[3], vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iStrongman[i][INDEX_STRONGMAN];

			if( entity == aim )
			{
				if( index < 6 )
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

					switch( index )
					{
						case 0: vPos[0] += 0.5;
						case 1: vPos[1] += 0.5;
						case 2: vPos[2] += 0.5;
						case 3: vPos[0] -= 0.5;
						case 4: vPos[1] -= 0.5;
						case 5: vPos[2] -= 0.5;
					}

					TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				} else {
					GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

					if( index == 6 ) vAng[1] -= 5.0;
					else if( index == 7 ) vAng[1] += 5.0;

					TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);
					PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				}
				break;
			}
		}
	}
}

void SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if( aim == -1 )
	{
		PrintToChat(client, "%sError: No target, point at the Strongman game model.", CHAT_TAG);
		return;
	}

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iStrongman[i][INDEX_STRONGMAN];

		if( entity == aim )
		{
			index = g_iStrongIndex[i];
			break;
		}

		if( index ) break;
	}

	if( index == 0 )
	{
		PrintToChat(client, "%sError: Invalid target (point at the Strongman game model) or temporary spawn type (spawn and save with sm_strongman).", CHAT_TAG);
		return;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Strongman config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("Strongman");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Strongman config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Current map not in the Strongman config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[12];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	Format(sTemp, sizeof(sTemp), "angle%d", index);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin%d", index);
	hFile.SetVector(sTemp, vPos);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);

	PrintToChat(client, "%sSaved origin and angles to the data config.", CHAT_TAG);
}

void CreateMenus()
{
	if( g_hMenuPos == null )
	{
		g_hMenuPos = new Menu(PosMenuHandler);
		g_hMenuPos.AddItem("", "X + 0.5");
		g_hMenuPos.AddItem("", "Y + 0.5");
		g_hMenuPos.AddItem("", "Z + 0.5");
		g_hMenuPos.AddItem("", "X - 0.5");
		g_hMenuPos.AddItem("", "Y - 0.5");
		g_hMenuPos.AddItem("", "Z - 0.5");
		g_hMenuPos.AddItem("", "Rotate Left");
		g_hMenuPos.AddItem("", "Rotate Right");
		g_hMenuPos.AddItem("", "SAVE");
		g_hMenuPos.SetTitle("Strongman Position");
		g_hMenuPos.Pagination = MENU_NO_PAGINATION;
		g_hMenuPos.ExitButton = true;
	}
}



// ====================================================================================================
//					STUFF / CLEAN UP
// ====================================================================================================
void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iStrongmanCount = 0;
	g_bSpawned = false;

	for( int i = 0; i < MAX_SPAWNS; i ++ )
		RemoveGame(i);
}

void RemoveGame(int index)
{
	int i, entity;
	for( i = 0; i < MAX_ENTS; i ++ )
	{
		entity = g_iStrongman[index][i];
		g_iStrongman[index][i] = 0;

		if( i == INDEX_PROPANE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		}

		if( IsValidEntRef(entity) )
		{
			if( i == INDEX_SOUND_PUCK )
				AcceptEntityInput(entity, "StopSound");
			RemoveEntity(entity);
		}
	}
}



// ====================================================================================================
//					LOAD STRONGMANS
// ====================================================================================================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerMake, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerMake, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerMake(Handle timer)
{
	ResetPlugin();
	LoadStrongman();
	return Plugin_Continue;
}

void LoadStrongman()
{
	if( g_bSpawned )
		return;

	// Load config
	KeyValues hFile = OpenConfig(false);
	if( hFile == null )
		return;

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many Strongman to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;

	char sTemp[12];
	float vAng[3], vPos[3];

	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "angle%d", i);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin%d", i);
		hFile.GetVector(sTemp, vPos);
		MakeStrongman(vPos, vAng, i);
	}

	delete hFile;
	g_bSpawned = true;
}



// ====================================================================================================
//					CREATE STRONGMAN
// ====================================================================================================
int GetStrongmanID()
{
	for( int i = 0; i < MAX_SPAWNS; i++ )
		if( g_iStrongman[i][INDEX_STRONGMAN] == 0 )
			return i;
	return -1;
}

int GetIndex(int entity, int index)
{
	if( entity > -1 ) entity = EntIndexToEntRef(entity);
	for( int i = 0; i < MAX_SPAWNS; i++ )
		if( g_iStrongman[i][index] == entity )
			return i;
	return -1;
}

void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

void MakeStrongman(const float vOrigin[3], const float vAngles[3], int index = 0)
{
	char sTemp[64];
	float vPos[3], vAng[3];
	int entity, iDStrongman = GetStrongmanID();

	if( iDStrongman == -1 ) // This should never happen
	{
		LogError("MakeStrongman iDStrongman Fail: %d (%0.1f, %0.1f, %0.1f)", index, vOrigin[0], vOrigin[1], vOrigin[2]);
		return;
	}

	g_iStrongIndex[iDStrongman] = index;

	vPos = vOrigin;
	vAng = vAngles;


	// Prop - Strongman Tower
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_game_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_GAME);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "DefaultAnim", "ref");
		DispatchSpawn(entity);
		// vPos[2] -= 25.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_STRONGMAN] = EntIndexToEntRef(entity);
	}


	// Prop - Strongman Top
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_top_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL5);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 353.0;
		MoveForward(vPos, vAng, vPos, -40.0);
		MoveSideway(vPos, vAng, vPos, 2.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TOP] = EntIndexToEntRef(entity);
	}
	// Prop - Strongman Top
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_top_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL5);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 353.0;
		MoveForward(vPos, vAng, vPos, -45.0);
		MoveSideway(vPos, vAng, vPos, -2.0);
		vAng[1] -= 180;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TOP_2] = EntIndexToEntRef(entity);
	}

	// Sprite - Top
	entity = CreateEntityByName("env_sprite");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_top_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_SPRITE);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", "251 226 153");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchKeyValue(entity, "scale", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 65.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, -30.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SPRITE_TOP] = EntIndexToEntRef(entity);
	}


	// Prop - Strongman Bell
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_BELL);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 272.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_vStrongPos[iDStrongman] = vPos;

		g_iStrongman[iDStrongman][INDEX_BELL] = EntIndexToEntRef(entity);
	}


	// Prop - Strongman Puck
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_PUCK);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		// vPos[2] += 10.0;
		MoveForward(vPos, vAng, vPos, -27.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_PUCK] = EntIndexToEntRef(entity);

		Format(sTemp, sizeof(sTemp), "OnUser1 %d-strongman-strongman_puck_tick_sound:PlaySound::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnUser2 %d-strongman-strongman_puck_tick_sound:PlaySound::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnUser3 %d-strongman-strongman_puck_tick_sound:PlaySound::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnUser4 %d-strongman-strongman_puck_tick_sound:PlaySound::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnUser1", OnUserOutput1);
		HookSingleEntityOutput(entity, "OnUser2", OnUserOutput2);
		HookSingleEntityOutput(entity, "OnUser3", OnUserOutput3);
		HookSingleEntityOutput(entity, "OnUser4", OnUserOutput4);
	}

	// Prop - Tiers - 1
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_1_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL2);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 65.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, -30.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TIER_1] = EntIndexToEntRef(entity);
	}
	// Prop - Tiers - 2
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_2_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL1);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 115.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, 20.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TIER_2] = EntIndexToEntRef(entity);
	}
	// Prop - Tiers - 3
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_3_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL3);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 165.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, -22.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TIER_3] = EntIndexToEntRef(entity);
	}
	// Prop - Tiers - 4
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_4_model", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_LVL4);
		DispatchKeyValue(entity, "skin", "3");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 210.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, 20.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_TIER_4] = EntIndexToEntRef(entity);
	}

	// Sprite - Tiers - 1
	entity = CreateEntityByName("env_sprite");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_1_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_SPRITE);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", "251 226 153");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchKeyValue(entity, "scale", "2");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 65.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, -30.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SPRITE_T1] = EntIndexToEntRef(entity);
	}
	// Sprite - Tiers - 2
	entity = CreateEntityByName("env_sprite");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_2_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_SPRITE);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", "251 226 153");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchKeyValue(entity, "scale", "2");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 115.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, 20.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SPRITE_T2] = EntIndexToEntRef(entity);
	}
	// Sprite - Tiers - 3
	entity = CreateEntityByName("env_sprite");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_3_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_SPRITE);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", "251 226 153");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchKeyValue(entity, "scale", "2");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 165.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, -22.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SPRITE_T3] = EntIndexToEntRef(entity);
	}
	// Sprite - Tiers - 4
	entity = CreateEntityByName("env_sprite");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_4_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_SPRITE);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "rendercolor", "251 226 153");
		DispatchKeyValue(entity, "renderamt", "100");
		DispatchKeyValue(entity, "scale", "2");
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 210.0;
		MoveForward(vPos, vAng, vPos, -30.0);
		MoveSideway(vPos, vAng, vPos, 20.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SPRITE_T4] = EntIndexToEntRef(entity);
	}



	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck2", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		SetEntityModel(entity, MODEL_PROPANE);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);
		SetEntityRenderFx(entity, RENDERFX_HOLOGRAM);
		SetEntityRenderColor(entity, 0, 0, 0, 0);

		vPos = vOrigin;
		vAng = vAngles;
		MoveForward(vPos, vAng, vPos, 129.0);
		MoveSideway(vPos, vAng, vPos, 7.5);
		vPos[2] += 35.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 99999);
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

		SetVariantString("OnTrigger @director:ForcePanicEvent::3:-1");
		AcceptEntityInput(entity, "AddOutput");

		g_iStrongman[iDStrongman][INDEX_PROPANE] = EntIndexToEntRef(entity);
	}



	entity = CreateEntityByName("logic_script");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "vscripts", "carnival_games/strongman_game_script");
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_game_script", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck", iDStrongman);
		DispatchKeyValue(entity, "Group00", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_1_model", iDStrongman);
		DispatchKeyValue(entity, "Group01", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_1_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "Group02", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_2_model", iDStrongman);
		DispatchKeyValue(entity, "Group03", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_2_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "Group04", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_3_model", iDStrongman);
		DispatchKeyValue(entity, "Group05", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_3_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "Group06", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_4_model", iDStrongman);
		DispatchKeyValue(entity, "Group07", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_4_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "Group08", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_top_model", iDStrongman);
		DispatchKeyValue(entity, "Group09", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_tier_top_model_sprite", iDStrongman);
		DispatchKeyValue(entity, "Group10", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck_tick_sound", iDStrongman);
		DispatchKeyValue(entity, "Group11", sTemp);
		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 35.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_LOGIC_SCRIPT] = EntIndexToEntRef(entity);
	}


	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck_tick_sound", iDStrongman);
		DispatchKeyValue(entity, "message", "Strongman.puck_tick");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchSpawn(entity);
		ActivateEntity(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 35.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_SOUND_PUCK] = EntIndexToEntRef(entity);
	}


	entity = CreateEntityByName("logic_timer");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-$strongman_attract_mode_timer", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchKeyValue(entity, "StartDisabled", "0");
		DispatchKeyValue(entity, "LowerRandomBound", "10");
		DispatchKeyValue(entity, "UpperRandomBound", "20");
		DispatchKeyValue(entity, "UseRandomTime", "1");
		DispatchSpawn(entity);

		Format(sTemp, sizeof(sTemp), "OnTimer %d-strongman-strongman_attract_mode_rl:Trigger::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		vPos = vOrigin;
		vAng = vAngles;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_LOGIC_TIMER] = entity;
	}
	entity = CreateEntityByName("logic_relay");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_attract_mode_rl", iDStrongman);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchSpawn(entity);

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_wire_loop_particle_system:Start::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_wire_loop_particle_system:Stop::3:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_wire_loop_particle_system:Stop::6.5:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_wire_loop_particle_system:Start::4.5:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_attract_mode_moustachio_sound:PlaySound::0:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-strongman-strongman_attract_mode_moustachio_laugh_sound:PlaySound::1.5:-1", iDStrongman);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		HookSingleEntityOutput(entity, "OnTrigger", OnLogicTrigger, false);

		vPos = vOrigin;
		vAng = vAngles;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		g_iStrongman[iDStrongman][INDEX_LOGIC_RELAY] = entity;
	}

	g_iStrongmanCount++;
}


Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	static float lastHit;
	float time = GetGameTime();
	if( time - lastHit < 2 )
	{
		return Plugin_Continue;
	}
	lastHit = time;

	char sTemp[64];
	GetEdictClassname(inflictor, sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "weapon_melee") == 0 )
	{
		OnHitButton(attacker, victim);
	}

	return Plugin_Continue;
}

void OnHitButton(int client, int entity)
{
	int index = GetIndex(entity, INDEX_PROPANE);
	if( index == -1 )
	{
		LogError("OnHitButton Index Fail: %d %d", entity, client);
		return;
	}

	if( !IsClientInGame(client) ) return;
	int team = GetClientTeam(client);
	if( team != 2 ) return;

	// ON BREAK BY TANK
	// if( team == 3 )
	// {
		// new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		// if( class != 8 ) return;
	// }

	// STOP ATTRACT
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_RELAY], "CancelPending");
	SetVariantString("20");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_TIMER], "LowerRandomBound");
	SetVariantString("35");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_TIMER], "UpperRandomBound");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_TIMER], "ResetTimer");

	SetVariantString("hit");
	AcceptEntityInput(g_iStrongman[index][INDEX_STRONGMAN], "SetAnimation");

	char sTemp[4];

	// ADRENLAINE HIT
	if( GetEntProp(client, Prop_Send, "m_bAdrenalineActive") )
	{
		int kill = g_iStrongman[index][INDEX_PROPANE];
		if( IsValidEntRef(kill) )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			RemoveEntity(kill);
		}

		CreateTimer(0.4, TimerBreak, client | (index << 7));
	} else {
		int health = GetEntProp(client, Prop_Send, "m_iHealth");
		float fGameTime = GetGameTime();
		float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		fHealth -= (fGameTime - fHealthTime) * g_fDecayRate;
		if( fHealth < 0.0 ) fHealth = 0.0;

		health += RoundFloat(fHealth);

		if( health >= 95 )
		{
			SetVariantString("10");
			AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation"); // strongman-strongman_puck

			CreateTimer(0.4, TimerBell, index);
			CreateTimer(0.4, TimerBellPart, index);
		}
		else if( health <= 48 )
		{
			int rand = GetRandomInt(1, 3);
			IntToString(rand, sTemp, sizeof(sTemp));
			SetVariantString(sTemp);
			AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation");
			SetVariantString("TierOneLightFlash(0)");
			AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

			CreateTimer(0.4, TimerFail, index | (1 << 7));
		}
		else if( health >= 49 && health <= 69 )
		{
			int rand = GetRandomInt(4, 5);
			IntToString(rand, sTemp, sizeof(sTemp));
			SetVariantString(sTemp);
			AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation");
			SetVariantString("TierTwoLightFlash(0)");
			AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

			CreateTimer(0.4, TimerFail, index | (2 << 7));
		}
		else if( health >= 70 && health <= 84 )
		{
			int rand = GetRandomInt(6, 7);
			IntToString(rand, sTemp, sizeof(sTemp));
			SetVariantString(sTemp);
			AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation");
			SetVariantString("TierThreeLightFlash(0)");
			AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

			CreateTimer(0.4, TimerFail, index | (3 << 7));
		}
		else if( health >= 85 && health <= 94 )
		{
			int rand = GetRandomInt(8, 9);
			IntToString(rand, sTemp, sizeof(sTemp));
			SetVariantString(sTemp);
			AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation");
			SetVariantString("TierFourLightFlash(0)");
			AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

			CreateTimer(0.4, TimerFail, index | (4 << 7));
		}
	}
}

Action TimerBell(Handle timer, any index)
{
	SetVariantString("TierFourLightFlash(0)");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script
	SetVariantString("TierTopLightFlash(0)");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

	int arcade = g_iStrongman[index][INDEX_STRONGMAN];
	PlaySound(arcade, SND_LEVEL_5);
	PlaySound(arcade, SND_LIGHT_ON);
	PlaySound(arcade, SND_STRONG_BELL);

	return Plugin_Continue;
}

Action TimerFail(Handle timer, any bits)
{
	int index = bits & 0x7F;
	int level = bits >> 7;
	int arcade = g_iStrongman[index][INDEX_STRONGMAN];

	switch( level )
	{
		case 1: PlaySound(arcade, SND_LEVEL_1);
		case 2: PlaySound(arcade, SND_LEVEL_2);
		case 3: PlaySound(arcade, SND_LEVEL_3);
		case 4: PlaySound(arcade, SND_LEVEL_4);
		case 5: PlaySound(arcade, SND_LEVEL_5);
	}

	PlaySound(arcade, SND_FAIL);

	return Plugin_Continue;
}

Action TimerBellPart(Handle timer, any index)
{
	char sTemp[64];
	float vPos[3], vAng[3];
	int entity, particle;
	int bell = g_iStrongman[index][INDEX_BELL];
	if( !IsValidEntRef(bell) )
	{
		LogError("TimerBellPart::Invalid Ent Ref %d (%d)", bell, index);
		return Plugin_Continue;
	}
	GetEntPropVector(bell, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(bell, Prop_Data, "m_angRotation", vAng);
	MoveForward(vPos, vAng, vPos, -5.0);

	// RIGHT
	entity = CreateEntityByName("info_particle_target");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_1", index);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchSpawn(entity);
		g_iStrongman[index][INDEX_PARTICLE_BELL_2] = EntIndexToEntRef(entity);

		MoveSideway(vPos, vAng, vPos, 15.0);
		TeleportEntity(entity, vPos, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::3:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	// BOTTOM
	vPos[2] -= 15.0;
	entity = CreateEntityByName("info_particle_target");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_2", index);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchSpawn(entity);
		g_iStrongman[index][INDEX_PARTICLE_BELL_3] = EntIndexToEntRef(entity);

		MoveSideway(vPos, vAng, vPos, -15.0);
		TeleportEntity(entity, vPos, view_as<float>({90.0, 180.0, 0.0}), NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::3:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	// LEFT
	entity = CreateEntityByName("info_particle_target");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_3", index);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchSpawn(entity);
		g_iStrongman[index][INDEX_PARTICLE_BELL_4] = EntIndexToEntRef(entity);

		MoveSideway(vPos, vAng, vPos, -15.0);
		TeleportEntity(entity, vPos, view_as<float>({0.0, 180.0, 0.0}), NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::3:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	// TOP
	MoveSideway(vPos, vAng, vPos, 15.0);
	vPos[2] += 30.0;
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_system", index);
		DispatchKeyValue(entity, "targetname", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_1", index);
		DispatchKeyValue(entity, "cpoint1", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_2", index);
		DispatchKeyValue(entity, "cpoint2", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_point_3", index);
		DispatchKeyValue(entity, "cpoint3", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_circle_particle_system", index);
		DispatchKeyValue(entity, "cpoint4", sTemp);
		DispatchKeyValue(entity, "effect_name", "lights_moving_curved_loop_4");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iStrongman[index][INDEX_PARTICLE_BELL_1] = EntIndexToEntRef(entity);
		particle = entity;

		TeleportEntity(entity, vPos, view_as<float>({-90.0, 0.0, 0.0}), NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::3:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}

	AcceptEntityInput(particle, "Start");

	return Plugin_Continue;
}

Action TimerBreak(Handle timer, any bits)
{
	int client = bits & 0x7F;
	int index = bits >> 7;

	int arcade = g_iStrongman[index][INDEX_STRONGMAN];
	PlaySound(arcade, SND_LEVEL_5);
	PlaySound(arcade, SND_ADREN_IMPACT);
	PlaySound(arcade, SND_BELL_BREAK);
	PlaySound(arcade, SND_LIGHT_ON);
	PlaySound(arcade, SND_STRONG_BELL);
	PlaySound(arcade, SND_BREAK);

	float vPos[3];
	char sTemp[64];
	int bell = g_iStrongman[index][INDEX_BELL];
	GetEntPropVector(bell, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] -= 5.0;

	int expl = CreateEntityByName("env_physexplosion");
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_exp", index);
	DispatchKeyValue(expl, "targetname", sTemp);
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell", index);
	DispatchKeyValue(expl, "targetentityname", sTemp);
	DispatchKeyValue(expl, "spawnflags", "1");
	DispatchKeyValue(expl, "magnitude", "1200");
	TeleportEntity(expl, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(expl);
	ActivateEntity(expl);
	SetVariantString("OnUser1 !self:Kill::2:1");
	AcceptEntityInput(expl, "AddOutput");
	AcceptEntityInput(expl, "FireUser1");

	int phys = CreateEntityByName("phys_convert");
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_convert", index);
	DispatchKeyValue(phys, "targetname", sTemp);
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell", index);
	DispatchKeyValue(phys, "target", sTemp);
	DispatchKeyValue(phys, "massoverride", "0");
	TeleportEntity(phys, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(phys);
	Format(sTemp, sizeof(sTemp), "OnConvert %d-strongman-strongman_bell_exp:Explode::0:-1", index);
	SetVariantString(sTemp);
	AcceptEntityInput(phys, "AddOutput");
	SetVariantString("OnConvert !self:Kill::1:1");
	AcceptEntityInput(phys, "AddOutput");
	AcceptEntityInput(phys, "FireUser1");

	int shoot = CreateEntityByName("env_shooter");
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_puck_shooter", index);
	DispatchKeyValue(shoot, "targetname", sTemp);
	DispatchKeyValue(shoot, "angles", "0 -90 0");
	DispatchKeyValue(shoot, "gibangles", "0 90 0");
	DispatchKeyValue(shoot, "gibanglevelocity", "25");
	DispatchKeyValue(shoot, "simulation", "1");
	DispatchKeyValue(shoot, "m_flVariance", "0.2");
	DispatchKeyValue(shoot, "spawnflags", "1");
	DispatchKeyValue(shoot, "m_iGibs", "1");
	DispatchKeyValue(shoot, "shootmodel", "models/props_fairgrounds/strongmangame_puck_phys.mdl");
	TeleportEntity(shoot, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(shoot);
	SetVariantString("OnUser1 !self:Kill::1:1");
	AcceptEntityInput(shoot, "AddOutput");
	AcceptEntityInput(shoot, "FireUser1");

	int spark = CreateEntityByName("env_spark");
	Format(sTemp, sizeof(sTemp), "%d-strongman-strongman_bell_spark", index);
	DispatchKeyValue(spark, "targetname", sTemp);
	DispatchKeyValue(spark, "angles", "0 -90 0");
	DispatchKeyValue(spark, "TrailLength", "3");
	DispatchKeyValue(spark, "Magnitude", "8");
	TeleportEntity(spark, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(spark);
	ActivateEntity(spark);
	SetVariantString("OnUser1 !self:Kill::4:1");
	AcceptEntityInput(spark, "AddOutput");
	AcceptEntityInput(spark, "FireUser1");

	AcceptEntityInput(shoot, "Shoot");
	AcceptEntityInput(spark, "SparkOnce");
	AcceptEntityInput(phys, "ConvertTarget");


	int puck = g_iStrongman[index][INDEX_PUCK];
	SetVariantString("OnUser1 !self:Kill::0:1");
	AcceptEntityInput(puck, "AddOutput");
	AcceptEntityInput(puck, "FireUser1");

	SetVariantString("RepeatFlashAllTierLights()");
	AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode"); // strongman-strongman_game_script

	SetVariantString("11");
	AcceptEntityInput(g_iStrongman[index][INDEX_PUCK], "SetAnimation"); // strongman-strongman_puck

	if( g_iCvarEvent )
	{
		int entity = g_iStrongman[index][INDEX_PROPANE];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		int event = CreateEntityByName("info_game_event_proxy");
		if( event != -1 )
		{
			Format(sTemp, sizeof(sTemp), "%d-strongman_achievement_event", index);
			DispatchKeyValue(event, "targetname", sTemp);
			DispatchKeyValue(event, "event_name", "strongman_bell_knocked_off");
			DispatchKeyValue(event,"range", "50");

			TeleportEntity(event, vPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(event);

			AcceptEntityInput(event, "GenerateGameEvent", client, entity);
			SetVariantString("OnUser1 !self:Kill::1:1");
			AcceptEntityInput(event, "AddOutput");
			AcceptEntityInput(event, "FireUser1");
		}
	}

	return Plugin_Continue;
}

void OnUserOutput1(const char[] output, int caller, int activator, float delay)
{
	int entity;
	int index = GetRelayIndex(caller);
	if( index == -1 )
	{
		LogError("OnUserOutput1 Index Fail: %d %d", caller, activator);
		return;
	}

	entity = g_iStrongman[index][INDEX_LOGIC_SCRIPT];
	SetVariantString("TierOneLightFlash(0)");
	AcceptEntityInput(entity, "RunScriptCode");

}

void OnUserOutput2(const char[] output, int caller, int activator, float delay)
{
	int entity;
	int index = GetRelayIndex(caller);
	if( index == -1 )
	{
		LogError("OnUserOutput2 Index Fail: %d %d", caller, activator);
		return;
	}

	entity = g_iStrongman[index][INDEX_LOGIC_SCRIPT];
	SetVariantString("TierTwoLightFlash(0)");
	AcceptEntityInput(entity, "RunScriptCode");
}

void OnUserOutput3(const char[] output, int caller, int activator, float delay)
{
	int entity;
	int index = GetRelayIndex(caller);
	if( index == -1 )
	{
		LogError("OnUserOutput3 Index Fail: %d %d", caller, activator);
		return;
	}

	entity = g_iStrongman[index][INDEX_LOGIC_SCRIPT];
	SetVariantString("TierThreeLightFlash(0)");
	AcceptEntityInput(entity, "RunScriptCode");
}

void OnUserOutput4(const char[] output, int caller, int activator, float delay)
{
	int entity;
	int index = GetRelayIndex(caller);
	if( index == -1 )
	{
		LogError("OnUserOutput4 Index Fail: %d %d", caller, activator);
		return;
	}

	entity = g_iStrongman[index][INDEX_LOGIC_SCRIPT];
	SetVariantString("TierTopLightFlash(0)");
	AcceptEntityInput(entity, "RunScriptCode");

	entity = g_iStrongman[index][INDEX_LOGIC_SCRIPT];
	SetVariantString("TierFourLightFlash(0)");
	AcceptEntityInput(entity, "RunScriptCode");
}

int GetRelayIndex(int entity)
{
	if( entity > -1 ) entity = EntIndexToEntRef(entity);
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iStrongman[i][INDEX_PUCK] == entity ) return i;
	}
	return -1;
}

void OnLogicTrigger(const char[] output, int caller, int activator, float delay)
{
	int index = GetIndex(caller, INDEX_LOGIC_RELAY);
	if( index == -1 )
	{
		LogError("OnLogicTrigger Index Fail: %d %d", caller, activator);
	} else {
		SetVariantString("AttractModeTierLights()");
		AcceptEntityInput(g_iStrongman[index][INDEX_LOGIC_SCRIPT], "RunScriptCode");

		int rand = GetRandomInt(1, 10);
		switch (rand)
		{
			case 1: EmitAmbientSound(SND_ATTRACT_01, g_vStrongPos[index]);
			case 2: EmitAmbientSound(SND_ATTRACT_02, g_vStrongPos[index]);
			case 3: EmitAmbientSound(SND_ATTRACT_03, g_vStrongPos[index]);
			case 4: EmitAmbientSound(SND_ATTRACT_04, g_vStrongPos[index]);
			case 5: EmitAmbientSound(SND_ATTRACT_05, g_vStrongPos[index]);
			case 6: EmitAmbientSound(SND_ATTRACT_06, g_vStrongPos[index]);
			case 7: EmitAmbientSound(SND_ATTRACT_07, g_vStrongPos[index]);
			case 8: EmitAmbientSound(SND_ATTRACT_08, g_vStrongPos[index]);
			case 9: EmitAmbientSound(SND_ATTRACT_09, g_vStrongPos[index]);
			case 10: EmitAmbientSound(SND_ATTRACT_10, g_vStrongPos[index]);
		}
	}
}

KeyValues OpenConfig(bool create = true)
{
	// Create config if it does not exist
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		if( create == false )
			return null;

		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Open the strongman config
	KeyValues hFile = new KeyValues("Strongman");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return null;
	}

	return hFile;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void PlaySound(int entity, char[] sound)
{
	EmitSoundToAll(sound, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_SHOULDPAUSE, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR);
}