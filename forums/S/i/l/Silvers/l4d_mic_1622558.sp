/*
*	Mic Stand
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



#define PLUGIN_VERSION		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Mic Stand
*	Author	:	SilverShot
*	Descrp	:	Auto-Spawns Mic Stands and provides a command to attach the Dark Carnival finale stage microphone effect on players.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=175153
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (11-Dec-2022)
	- Various changes to tidy up code.

1.7 (29-Jun-2021)
	- L4D2: Fixed the Mic Stand not loading after restarting a round.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.4.1 (03-Jul-2019)
    - Minor changes to code, has no affect and not required.

1.4 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_mic_modes_tog" now supports L4D1.

1.3 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.2 (10-May-2012)
	- Added cvar "l4d_mic_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_mic_modes_tog" same as above, but only works for L4D2.

1.1 (31-Dec-2011)
	- Removed useless code.

1.0 (31-Dec-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Mic Stand] \x01"
#define CONFIG_SPAWNS		"data/l4d_mic_stand.cfg"
#define MAX_ALLOWED			16

#define MODEL_MICROPHONE	"models/props_fairgrounds/mic_stand.mdl"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom;
bool g_bAllow, g_bMapStarted, g_bLeft4Dead2, g_bLoaded;
int g_iCvarRandom, g_iMicrophones[MAXPLAYERS][2], g_iPlayerSpawn, g_iRoundStart, g_iStands[MAX_ALLOWED][3];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Mic Stand",
	author = "SilverShot",
	description = "Auto-Spawns Mic Stands and provides a command to attach the Dark Carnival finale stage microphone effect on players.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=175153"
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
	LoadTranslations("common.phrases");

	g_hCvarAllow =			CreateConVar(	"l4d_mic_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =			CreateConVar(	"l4d_mic_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_mic_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_mic_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarRandom =		CreateConVar(	"l4d_mic_random",		"2",			"-1=All, 0=Off, other value randomly spawns that many mics from the config.", CVAR_FLAGS);
	}
	CreateConVar(							"l4d_mic_version",		PLUGIN_VERSION,	"Mic plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_mic");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
	{
		g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	}

	RegAdminCmd(	"sm_mic",			CmdMic,			ADMFLAG_ROOT,	"Usage: sm_mic <#userid|name>. Attaches the mic effect to players.");
	if( g_bLeft4Dead2 )
	{
		RegAdminCmd("sm_micstand",		CmdMicStand,	ADMFLAG_ROOT,	"Spawns a temporary Mic Stand at your crosshair.");
		RegAdminCmd("sm_micsave",		CmdMicSave,		ADMFLAG_ROOT, 	"Spawns a Mic Stand at your crosshair and saves to config.");
		RegAdminCmd("sm_miclist",		CmdMicList,		ADMFLAG_ROOT, 	"Display a list Mic positions and the number of Mics.");
		RegAdminCmd("sm_micdel",		CmdMicDelete,	ADMFLAG_ROOT, 	"Removes the Mic you are nearest to and deletes from the config if saved.");
		RegAdminCmd("sm_micclear",		CmdMicClear,	ADMFLAG_ROOT, 	"Removes all Mics from the current map.");
		RegAdminCmd("sm_micwipe",		CmdMicWipe,		ADMFLAG_ROOT, 	"Removes all Mics from the current map and deletes them from the config.");
	}
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	if( g_bLeft4Dead2 )
		PrecacheModel(MODEL_MICROPHONE, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for( int i = 1; i < MAXPLAYERS; i++ )
	{
		if( IsValidEntRef(g_iMicrophones[i][0]) )
			RemoveEntity(g_iMicrophones[i][0]);
		if( IsValidEntRef(g_iMicrophones[i][1]) )
			RemoveEntity(g_iMicrophones[i][1]);

		g_iMicrophones[i][0] = 0;
		g_iMicrophones[i][1] = 0;
	}

	if( g_bLeft4Dead2 == false ) return;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( IsValidEntRef(g_iStands[i][0]) )
			RemoveEntity(g_iStands[i][0]);
		if( IsValidEntRef(g_iStands[i][1]) )
			RemoveEntity(g_iStands[i][1]);
		if( IsValidEntRef(g_iStands[i][2]) )
			RemoveEntity(g_iStands[i][2]);

		g_iStands[i][0] = 0;
		g_iStands[i][1] = 0;
		g_iStands[i][2] = 0;
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
	g_iCvarRandom =	g_hCvarRandom.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	if( g_bLeft4Dead2 ) GetCvars();

	if( g_bAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bAllow = true;
		HookEvents();

		if( g_bLeft4Dead2 == false ) return;
		LoadMics();
	}

	else if( g_bAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bAllow = false;
		ResetPlugin();
		UnhookEvents();
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
void HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	if( g_bLeft4Dead2 == false ) return;
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

void UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	if( g_bLeft4Dead2 == false ) return;
	UnhookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();

	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bLeft4Dead2 == false ) return;

	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		LoadMics();
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		LoadMics();
	g_iPlayerSpawn = 1;
}

void LoadMics()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarRandom == 0 )
		return;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("mics");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few
	int index, i, iRandom = g_iCvarRandom;
	int iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;

	// Spawn all saved mics or create random
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the mic origins and spawn
	char sTemp[10];
	float vPos[3], vAng[3];
	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		Format(sTemp, sizeof(sTemp), "angle_%d", index);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin_%d", index);
		hFile.GetVector(sTemp, vPos);

		if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
			SpawnMic(vAng, vPos);
	}

	delete hFile;
}

void SetupMic(int client, float vAng[3] = NULL_VECTOR, float vPos[3] = NULL_VECTOR)
{
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);

		vAng[0] = 0.0;
		vAng[2] = 0.0;
		SpawnMic(vAng, vPos);
	}

	delete trace;
}

bool TraceFilter(int entity, int contentsMask, any client)
{
	if( entity == client )
		return false;
	return true;
}

void SpawnMic(float vAng[3], float vPos[3])
{
	int index = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iStands[i][0]) )
		{
			if( IsValidEntRef(g_iStands[i][1]) )
				RemoveEntity(g_iStands[i][1]);
			if( IsValidEntRef(g_iStands[i][2]) )
				RemoveEntity(g_iStands[i][2]);

			g_iStands[i][1] = 0;
			g_iStands[i][2] = 0;
			index = i;
			break;
		}
	}

	if( index == -1 ) return;


	int entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		g_iStands[index][0] = EntIndexToEntRef(entity);

		DispatchKeyValue(entity, "model", MODEL_MICROPHONE);
		DispatchKeyValue(entity, "Solid", "2");
		DispatchSpawn(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		ToggleMic(0, 0, entity, index);
	}
}

void ToggleMic(int client, int clientchat, int mic = 0, int index = -1)
{
	if( client && IsValidEntRef(g_iMicrophones[client][1]) )
			RemoveEntity(g_iMicrophones[client][1]);

	if( client && IsValidEntRef(g_iMicrophones[client][0]) )
	{
		RemoveEntity(g_iMicrophones[client][0]);
		if( client && clientchat )
			PrintToChat(clientchat, "%s%N \x05Off", CHAT_TAG, client);
		return;
	}

	g_iMicrophones[client][0] = 0;
	g_iMicrophones[client][1] = 0;


	// --------------------------------------- ENV_MICROPHONE ---------------------------------------
	int entity = CreateEntityByName("env_microphone");
	if( entity != -1 )
	{
		char sSpeaker[16];
		float vAng[3], vPos[3];
		if( client )
		{
			GetClientEyeAngles(client, vAng);
			GetClientEyePosition(client, vPos);
		}
		else
		{
			GetEntPropVector(mic, Prop_Data, "m_angRotation", vAng);
			GetEntPropVector(mic, Prop_Data, "m_vecAbsOrigin", vPos);
			vPos[2] += 40.0;
		}

		Format(sSpeaker, sizeof(sSpeaker), "sm_mic%d%d", entity, mic);

		DispatchKeyValue(entity, "SpeakerName", sSpeaker);
		DispatchKeyValue(entity, "speaker_dsp_preset", "57");
		DispatchKeyValue(entity, "spawnflags", "63");
		DispatchKeyValue(entity, "SmoothFactor", "0");
		DispatchKeyValue(entity, "Sensitivity", "1");
		DispatchKeyValue(entity, "MaxRange", "60");
		DispatchSpawn(entity);
		ActivateEntity(entity);

		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		if( client )
			AcceptEntityInput(entity, "SetParent", client);
		else
			AcceptEntityInput(entity, "SetParent", mic);

		if( client )
		{
			SetVariantString("forward");
			AcceptEntityInput(entity, "SetParentAttachment");
			g_iMicrophones[client][0] = EntIndexToEntRef(entity);
		}
		else
			g_iStands[index][1] = EntIndexToEntRef(entity);


		// --------------------------------------- INFO_TARGET ---------------------------------------
		entity = CreateEntityByName("info_target");
		if( entity != -1 )
		{
			DispatchKeyValue(entity, "targetname", sSpeaker);
			DispatchKeyValue(entity, "spawnflags", "0");
			DispatchSpawn(entity);
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			if( client )
			{
				AcceptEntityInput(entity, "SetParent", client);
				SetVariantString("forward");
				AcceptEntityInput(entity, "SetParentAttachment", client);
				g_iMicrophones[client][1] = EntIndexToEntRef(entity);
			}
			else
			{
				AcceptEntityInput(entity, "SetParent", mic);
				g_iStands[index][2] = EntIndexToEntRef(entity);
			}

			if( client && clientchat )
				PrintToChat(clientchat, "%s%N \x05On", CHAT_TAG, client);
		}
	}
}



// ====================================================================================================
//					COMMANDS - MIC, TEMP, SAVE, LIST, DELETE, CLEAR, WIPE
// ====================================================================================================

// ====================================================================================================
//					sm_mic
// ====================================================================================================
Action CmdMic(int client, int args)
{
	if( args == 0 )
		ToggleMic(client, client);
	else
	{
		char arg1[32], target_name[MAX_TARGET_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));

		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int team;
		for( int i = 0; i < target_count; i++ )
		{
			team = GetClientTeam(target_list[i]);
			if( team == 2 || team == 3 )
				ToggleMic(target_list[i], client);
		}
	}

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_micstand
// ====================================================================================================
Action CmdMicStand(int client, int args)
{
	float vAng[3], vPos[3];
	SetupMic(client, vAng, vPos);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_micsave
// ====================================================================================================
Action CmdMicSave(int client, int args)
{
	if( !g_bAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mic] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("mics");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Mic config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Mic spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many mics are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore mics. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		delete hFile;
		return Plugin_Handled;
	}

	float vAng[3], vPos[3];
	SetupMic(client, vAng, vPos);

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[12];
	Format(sTemp, sizeof(sTemp), "angle_%d", iCount);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	hFile.SetVector(sTemp, vPos);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_miclist
// ====================================================================================================
Action CmdMicList(int client, int args)
{
	float vPos[3];
	int i, ent, count;

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iStands[i][0];

		if( IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Mic] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Mic] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_micdel
// ====================================================================================================
Action CmdMicDelete(int client, int args)
{
	if( !g_bAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mic] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int ent; int index = -1; float vDistance; float vDistanceLast = 250.0;
	float vEntPos[3]; float vPos[3]; float vAng[3];
	GetClientAbsOrigin(client, vAng);

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iStands[i][0];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
			vDistance = GetVectorDistance(vPos, vAng);
			if( vDistance < vDistanceLast )
			{
				vDistanceLast = vDistance;
				vEntPos = vPos;
				index = i;
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sCannot find a Mic Stand nearby to delete!", CHAT_TAG);
		return Plugin_Handled;
	}

	if( IsValidEntRef(g_iStands[index][0]) )
		RemoveEntity(g_iStands[index][0]);
	if( IsValidEntRef(g_iStands[index][1]) )
		RemoveEntity(g_iStands[index][1]);
	if( IsValidEntRef(g_iStands[index][2]) )
		RemoveEntity(g_iStands[index][2]);

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the Mic config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("mics");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the Mic config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the Mic config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many mics
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[10];

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 1.0 )
			{
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "angle_%d", i);
				hFile.DeleteKey(sTemp);

				bMove = true;
			}
			else if( i == iCount ) // No mics... exit
			{
				PrintToChat(client, "%sWarning: Cannot find the Mic inside the config.", CHAT_TAG);
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "angle_%d", i);
			hFile.GetVector(sTemp, vAng);
			hFile.DeleteKey(sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "angle_%d", i-1);
			hFile.SetVector(sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			hFile.SetVector(sTemp, vPos);
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(\x05%d/%d\x01) - Mic removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_micclear
// ====================================================================================================
Action CmdMicClear(int client, int args)
{
	if( !g_bAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ResetPlugin();
	PrintToChat(client, "%sAll mics removed from the map.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_micwipe
// ====================================================================================================
Action CmdMicWipe(int client, int args)
{
	if( !g_bAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Mic] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Mic config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("mics");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Mic config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Mic config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	ResetPlugin();
	PrintToChat(client, "%s(0/%d) - All mics removed from config, add new mics with \x05sm_micsave\x01.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}