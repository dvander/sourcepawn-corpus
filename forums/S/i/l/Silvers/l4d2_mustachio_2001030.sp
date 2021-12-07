/*
*	Mustachio Stache Whacker
*	Copyright (C) 2020 Silvers
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

*	Name	:	[L4D2] Mustachio Stache Whacker
*	Author	:	SilverShot
*	Descrp	:	Auto-spawn the Mustachio Stache Whacker game on round start.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=221986
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.4 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.2.1 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1 (25-Aug-2013)
	- Fixed the arcade model not spawning on some maps. Some areas of the affected maps will prevent the model spawning.

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
#define CHAT_TAG			"\x05[\x04Stache Whacker\x05] \x01"
#define CONFIG_SPAWNS		"data/l4d2_mustachio.cfg"
#define MAX_SPAWNS			2
#define MAX_ENTS			46

#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"
#define MODEL_MUST			"models/props_fairgrounds/mr_mustachio.mdl"
#define MODEL_ARCADE		"models/props_fairgrounds/arcadegame01.mdl"
#define MODEL_WHEEL			"models/props_fairgrounds/arcadegame01_wheel.mdl"
#define MODEL_SCREEN		"models/props_fairgrounds/arcadegame01_screen.mdl"
#define MODEL_PANEL			"models/props_fairgrounds/arcadegame01_panel.mdl"
#define MODEL_GLASS			"models/props_fairgrounds/arcadegame01_glasswhole.mdl"
#define MODEL_GLASSB		"models/props_fairgrounds/arcadegame01_glassbroken.mdl"

#define SOUND_START			"level/startwam.wav"
#define SOUND_OVER			"level/loud/wamover.wav"
#define SOUND_HIT			"level/popup.wav"

#define PARTICLE_TICKET		"ticket_stasche_wacker"
#define PARTICLE_JACKPOT	"ticket_stasche_wacker_jackpot"
#define PARTICLE_SPARKS		"sparks_generic_random"
#define PARTICLE_IMPACT_E	"impact_electronic"
#define PARTICLE_IMPACT_G	"impact_glass"
#define PARTICLE_LIGHT		"railroad_light_explode"
#define PARTICLE_BREAK		"stache_break"
#define PARTICLE_BREAK_M	"stache_break_metal"


Menu g_hMenuPos;
ConVar g_hCvarAllow, g_hCvarEvent, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
int g_iCvarEvent, g_iMustIndex[MAX_SPAWNS], g_iMustachioCount, g_iMustachios[MAX_SPAWNS][MAX_ENTS], g_iPlayerSpawn, g_iRoundStart;
bool g_bCvarAllow, g_bMapStarted, g_bSpawned;

enum
{
	INDEX_ARCADE,
	INDEX_PANEL,
	INDEX_GLASS,
	INDEX_GLASS_B,
	INDEX_SCREEN,
	INDEX_BUTTON,
	INDEX_SPARKS,
	INDEX_TICKET,
	INDEX_SMOKE_1,
	INDEX_SMOKE_2,
	INDEX_SMOKE_3,
	INDEX_SMOKE_4,
	INDEX_SMOKE_5,
	INDEX_SOUND_COUNT,
	INDEX_SOUND_MUSIC,
	INDEX_SOUND_HIGH,
	INDEX_SOUND_SCORE,
	INDEX_SOUND_LOWSCORE,
	INDEX_SOUND_SUPRISE,
	INDEX_ROT_1,
	INDEX_ROT_2,
	INDEX_ROT_3,
	INDEX_ROT_4,
	INDEX_ROT_5,
	INDEX_WHEEL_1,
	INDEX_WHEEL_2,
	INDEX_WHEEL_3,
	INDEX_WHEEL_4,
	INDEX_WHEEL_5,
	INDEX_DOOR_1,
	INDEX_DOOR_2,
	INDEX_DOOR_3,
	INDEX_DOOR_4,
	INDEX_DOOR_5,
	INDEX_PLUNGER_1,
	INDEX_PLUNGER_2,
	INDEX_PLUNGER_3,
	INDEX_PLUNGER_4,
	INDEX_PLUNGER_5,
	INDEX_LOGIC_TIMER,
	INDEX_LOGIC_COUNTER,
	INDEX_LOGIC_CONTINUE,
	INDEX_LOGIC_BREAK,
	INDEX_LOGIC_AT_1,
	INDEX_LOGIC_AT_2,
	INDEX_LOGIC_END
	// INDEX_INFO_PROXY
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Mustachio Stache Whacker",
	author = "SilverShot",
	description = "Auto-spawn the Mustachio Stache Whacker game on round start.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=221986"
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
	g_hCvarAllow = CreateConVar(	"l4d2_mustachio_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarEvent = CreateConVar(	"l4d2_mustachio_event",				"0",			"0=Off. 1=Turns on the ability to receive the 'STACHE WHACKER' achievement for 'Proving you are faster than Moustachio'.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d2_mustachio_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d2_mustachio_modes_disallow",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d2_mustachio_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"l4d2_mustachio_version",			PLUGIN_VERSION,	"Mustachio plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_mustachio");

	RegAdminCmd("sm_must",			CmdMust,		ADMFLAG_ROOT, 	"Spawns a Mustachio where your crosshair is pointing.");
	RegAdminCmd("sm_mustachio",		CmdMustachio,	ADMFLAG_ROOT, 	"Same as above, but saves the origin and angle to the Mustachio spawns config.");
	RegAdminCmd("sm_must_clear",	CmdMustClear,	ADMFLAG_ROOT, 	"Removes the Mustachio games from the current map only.");
	RegAdminCmd("sm_must_del",		CmdMustDelete,	ADMFLAG_ROOT, 	"Deletes the Mustachio you are pointing at and removes from the config if saved.");
	RegAdminCmd("sm_must_list",		CmdMustList,	ADMFLAG_ROOT, 	"Lists all the Mustachios on the current map and their locations.");
	RegAdminCmd("sm_must_pos",		CmdMustPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Mustachio angles/origin your crosshair is over.");
	RegAdminCmd("sm_must_wipe",		CmdMustWipe,	ADMFLAG_ROOT, 	"Removes all the Mustachios in game and deletes the current map from the config.");

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
	PrecacheModel(MODEL_MUST, true);
	PrecacheModel(MODEL_ARCADE, true);
	PrecacheModel(MODEL_WHEEL, true);
	PrecacheModel(MODEL_SCREEN, true);
	PrecacheModel(MODEL_PANEL, true);
	PrecacheModel(MODEL_GLASS, true);
	PrecacheModel(MODEL_GLASSB, true);

	PrecacheSound(SOUND_START);
	PrecacheSound(SOUND_OVER);
	PrecacheSound(SOUND_HIT);

	PrecacheParticle(PARTICLE_TICKET);
	PrecacheParticle(PARTICLE_JACKPOT);
	PrecacheParticle(PARTICLE_SPARKS);
	PrecacheParticle(PARTICLE_IMPACT_E);
	PrecacheParticle(PARTICLE_IMPACT_G);
	PrecacheParticle(PARTICLE_LIGHT);
	PrecacheParticle(PARTICLE_BREAK);
	PrecacheParticle(PARTICLE_BREAK_M);
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
	g_iCvarEvent = g_hCvarEvent.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		if( g_bMapStarted )
			LoadMustachios();
		g_bCvarAllow = true;

		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();

		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
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
//					COMMANDS - MUSTACHIO
// ====================================================================================================
public Action CmdMust(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Mustachio] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iMustachioCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore mustachios. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	// Set player position as mustachio spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place mustachio, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}
	else if( g_iMustachioCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore mustachios. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	MakeMustachio(vPos, vAng);
	return Plugin_Handled;
}

public Action CmdMustachio(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Mustachio] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iMustachioCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore mustachios. Used: (%d/%d).", CHAT_TAG, MAX_SPAWNS, MAX_SPAWNS);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = OpenConfig();
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the mustachio config (%s).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )	// Create key
	{
		PrintToChat(client, "%sError: Failed to add map to mustachio spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many mustachios are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore mustachios. Used: (%d/%d).", CHAT_TAG, iCount, MAX_SPAWNS);
		delete hFile;
		return Plugin_Handled;
	}

	// Get position for mustachio spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place mustachio, please try again.", CHAT_TAG);
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

	// Create mustachio
	MakeMustachio(vPos, vAng, iCount);
	PrintToChat(client, "%s(%d/%d) - Created at pos:[%f %f %f] ang:[%f %f %f]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}


// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	float vAngles[3], vOrigin[3], vBuffer[3], vStart[3], Distance;

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vStart, trace);
		Distance = -15.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] = vStart[0] + (vBuffer[0]*Distance);
		vPos[1] = vStart[1] + (vBuffer[1]*Distance);
		vPos[2] = vStart[2] + (vBuffer[2]*Distance);
		vPos[2] = GetGroundHeight(vPos);
		if( vPos[2] == 0.0 )
		{
			delete trace;
			return false;
		}

		vAng = vAngles;
		vAng[0] = 0.0;
		vAng[1] += 180.0;
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

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
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
		for( u = INDEX_ARCADE; u <= INDEX_GLASS_B; u++ )
			if( g_iMustachios[i][u] == entity )
				return i;
	}
	return -1;
}

public Action CmdMustClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Mustachio] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Mustachio games removed from the map", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

public Action CmdMustDelete(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Mustachio] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	// Check they are aiming at a mustachio we made
	int iD, entity = GetClientAimTarget(client, false);
	if( entity <= MaxClients || (iD = IsEntStored(EntIndexToEntRef(entity))) == -1 )
	{
		PrintToChat(client, "%sInvalid target.", CHAT_TAG);
		return Plugin_Handled;
	}

	RemoveGame(iD);
	g_iMustachioCount--;

	// Load config
	KeyValues hFile = OpenConfig(false);
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the mustachio config (%s).", CHAT_TAG, CONFIG_SPAWNS);
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

	// Retrieve how many mustachios
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
			else if( i == iCount ) // Not found any mustachios... exit
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

	PrintToChat(client, "%s(%d/%d) - Mustachio removed from config, add new mustachios with sm_mustachio.", CHAT_TAG, iCount, MAX_SPAWNS);
	return Plugin_Handled;
}

public Action CmdMustList(int client, int args)
{
	float vPos[3];
	int i, ent;

	for( i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iMustachios[i][INDEX_ARCADE];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);

			if( client == 0 )
				ReplyToCommand(client, "[Mustachio] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		ReplyToCommand(client, "[Mustachio] Total: %d/%d.", g_iMustachioCount, MAX_SPAWNS);
	else
		PrintToChat(client, "%sTotal: %d/%d.", CHAT_TAG, g_iMustachioCount, MAX_SPAWNS);

	return Plugin_Handled;
}

public Action CmdMustWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Mustachio] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = OpenConfig(false);
	if( hFile == null )
	{
		PrintToChat(client, "%sError: Cannot load the mustachio config (%s).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sCannot find map in mustachio config.", CHAT_TAG);
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

	PrintToChat(client, "%s(0/%d) - All mustachios removed from config, add new mustachios with sm_mustachio.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action CmdMustPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 8 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
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
			entity = g_iMustachios[i][INDEX_ARCADE];

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
		PrintToChat(client, "%sError: No target, point at the Mustachio game model.", CHAT_TAG);
		return;
	}

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iMustachios[i][INDEX_ARCADE];

		if( entity == aim )
		{
			index = g_iMustIndex[i];
			break;
		}

		if( index ) break;
	}

	if( index == 0 )
	{
		PrintToChat(client, "%sError: Invalid target (point at the Mustachio game model) or temporary spawn type (spawn and save with sm_mustachio).", CHAT_TAG);
		return;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Mustachio config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("Mustachio");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Mustachio config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Mustachio config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[32];
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
		g_hMenuPos.SetTitle("Mustachio Position");
		g_hMenuPos.Pagination = MENU_NO_PAGINATION;
		g_hMenuPos.ExitButton = true;
	}
}



// ====================================================================================================
//					CLEAN UP
// ====================================================================================================
void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iMustachioCount = 0;
	g_bSpawned = false;

	for( int i = 0; i < MAX_SPAWNS; i ++ )
		RemoveGame(i);
}

void RemoveGame(int index)
{
	int i, entity;
	for( i = 0; i < MAX_ENTS; i ++ )
	{
		entity = g_iMustachios[index][i];
		g_iMustachios[index][i] = 0;

		if( IsValidEntRef(entity) )
		{
			if( i >= INDEX_SOUND_COUNT && i <= INDEX_SOUND_SUPRISE )
			{
				AcceptEntityInput(entity, "StopSound");
			}
			AcceptEntityInput(entity, "kill");
		}
	}
}


// ====================================================================================================
//					LOAD MUSTACHIOS
// ====================================================================================================
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerMake, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerMake, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerMake(Handle timer)
{
	ResetPlugin();
	LoadMustachios();
}

void LoadMustachios()
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

	// Retrieve how many mustachios to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;

	// Get mustachio vectors and tracks
	char sTemp[10];
	float vPos[3], vAng[3];

	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "angle%d", i);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin%d", i);
		hFile.GetVector(sTemp, vPos);
		MakeMustachio(vPos, vAng, i);
	}

	delete hFile;
	g_bSpawned = true;
}



// ====================================================================================================
//					CREATE MUSTACHIO
// ====================================================================================================
int GetMustachioID()
{
	for( int i = 0; i < MAX_SPAWNS; i++ )
		if( g_iMustachios[i][INDEX_ARCADE] == 0 )
			return i;
	return -1;
}

int GetIndex(int entity, int index)
{
	if( entity > -1 ) entity = EntIndexToEntRef(entity);
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iMustachios[i][index] == entity ) return i;
	}
	return -1;
}

int GetPlungerIndex(int entity)
{
	if( entity > -1 ) entity = EntIndexToEntRef(entity);
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iMustachios[i][INDEX_PLUNGER_1] == entity ) return i | (1 << 7);
		if( g_iMustachios[i][INDEX_PLUNGER_2] == entity ) return i | (2 << 7);
		if( g_iMustachios[i][INDEX_PLUNGER_3] == entity ) return i | (3 << 7);
		if( g_iMustachios[i][INDEX_PLUNGER_4] == entity ) return i | (4 << 7);
		if( g_iMustachios[i][INDEX_PLUNGER_5] == entity ) return i | (5 << 7);
	}
	return -1;
}

int GetDoorIndex(int entity)
{
	if( entity > -1 ) entity = EntIndexToEntRef(entity);
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iMustachios[i][INDEX_DOOR_1] == entity ) return i | (1 << 7);
		if( g_iMustachios[i][INDEX_DOOR_2] == entity ) return i | (2 << 7);
		if( g_iMustachios[i][INDEX_DOOR_3] == entity ) return i | (3 << 7);
		if( g_iMustachios[i][INDEX_DOOR_4] == entity ) return i | (4 << 7);
		if( g_iMustachios[i][INDEX_DOOR_5] == entity ) return i | (5 << 7);
	}
	return 0;
}

void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

void MakeMustachio(const float vOrigin[3], const float vAngles[3], int index = 0)
{
	char sTemp[64];
	float vPos[3], vAng[3];
	int entity, iDMustachio = GetMustachioID();

	if( iDMustachio == -1 ) // This should never happen
		return;

	g_iMustIndex[iDMustachio] = index;

	vPos = vOrigin;
	vAng = vAngles;

	// Prop - Mustachio Arcade
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_ARCADE);
		Format(sTemp, sizeof(sTemp), "%d-game_start_button_model", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_ARCADE] = EntIndexToEntRef(entity);
	}

	// Prop - Panel
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_PANEL);
		Format(sTemp, sizeof(sTemp), "%d-wam_animated_sign", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");

		DispatchSpawn(entity);
		vPos[2] += 52.6;
		MoveSideway(vPos, vAng, vPos, 3.8);
		MoveForward(vPos, vAng, vPos, 13.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PANEL] = EntIndexToEntRef(entity);
	}

	// GLASS
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_GLASS);
		Format(sTemp, sizeof(sTemp), "%d-wam_glass_intact", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_GLASS] = EntIndexToEntRef(entity);
	}

	// GLASS BROKEN
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_GLASSB);
		Format(sTemp, sizeof(sTemp), "%d-wam_glass_broken", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "StartDisabled", "1");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_GLASS_B] = EntIndexToEntRef(entity);
	}

	// SCREEN - CONTINUE
	entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_SCREEN);
		Format(sTemp, sizeof(sTemp), "%d-wam_continue_sign", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "skin", "1");
		DispatchKeyValue(entity, "solid", "6");
		DispatchKeyValue(entity, "disableshadows", "1");

		DispatchSpawn(entity);

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 46;
		MoveSideway(vPos, vAng, vPos, 21.5);
		MoveForward(vPos, vAng, vPos, 23.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_SCREEN] = EntIndexToEntRef(entity);
	}


	// MOMENTARY ROT
	entity = CreateEntityByName("func_rotating"); // Yes Valve randomly use this, so I copy.
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-timer_0", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "74");
		DispatchKeyValue(entity, "maxspeed", "360");
		DispatchKeyValue(entity, "fanfriction", "0");
		DispatchKeyValue(entity, "_minlight", "1");
	// entity = CreateEntityByName("momentary_rot_button");
	// if( entity != -1 )
	// {
		// Format(sTemp, sizeof(sTemp), "%d-timer_0", iDMustachio);
		// DispatchKeyValue(entity, "targetname", sTemp);
		// DispatchKeyValue(entity, "spawnflags", "161");
		// DispatchKeyValue(entity, "distance", "360");
		// DispatchKeyValue(entity, "speed", "10000");
		// DispatchKeyValue(entity, "_minlight", "1");
		// DispatchKeyValue(entity, "startdirection", "1");

		// LEFT 3
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 41;
		MoveSideway(vPos, vAng, vPos, 13.0);
		MoveForward(vPos, vAng, vPos, 14.5);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_ROT_1] = EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	// MOMENTARY ROT
	entity = CreateEntityByName("momentary_rot_button");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-timer_1", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "161");
		DispatchKeyValue(entity, "distance", "360");
		DispatchKeyValue(entity, "speed", "10000");
		DispatchKeyValue(entity, "_minlight", "1");
		DispatchKeyValue(entity, "startdirection", "1");

		// LEFT 2
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 41;
		MoveSideway(vPos, vAng, vPos, 7.5);
		MoveForward(vPos, vAng, vPos, 15.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_ROT_2] = EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	entity = CreateEntityByName("momentary_rot_button");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-timer_2", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "161");
		DispatchKeyValue(entity, "distance", "360");
		DispatchKeyValue(entity, "speed", "10000");
		DispatchKeyValue(entity, "_minlight", "1");
		DispatchKeyValue(entity, "startdirection", "1");

		// LEFT 1
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 41;
		MoveSideway(vPos, vAng, vPos, 2.0);
		MoveForward(vPos, vAng, vPos, 15.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_ROT_3] = EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	entity = CreateEntityByName("momentary_rot_button");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-counter_0", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "161");
		DispatchKeyValue(entity, "distance", "360");
		DispatchKeyValue(entity, "speed", "10000");
		DispatchKeyValue(entity, "_minlight", "1");
		DispatchKeyValue(entity, "startdirection", "1");

		// RIGHT 1
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 41;
		MoveSideway(vPos, vAng, vPos, 54.0);
		MoveForward(vPos, vAng, vPos, 15.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_ROT_4] = EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		ActivateEntity(entity);
	}
	entity = CreateEntityByName("momentary_rot_button");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-counter_1", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "161");
		DispatchKeyValue(entity, "distance", "360");
		DispatchKeyValue(entity, "speed", "10000");
		DispatchKeyValue(entity, "_minlight", "1");
		DispatchKeyValue(entity, "startdirection", "1");

		// RIGHT 2
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 41;
		MoveSideway(vPos, vAng, vPos, 49.0);
		MoveForward(vPos, vAng, vPos, 15.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

		DispatchSpawn(entity);
		ActivateEntity(entity);

		g_iMustachios[iDMustachio][INDEX_ROT_5] = EntIndexToEntRef(entity);
	}
	// MOMENTARY WHEELS
	// vAng[1] = vAng[1];
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_WHEEL);
		DispatchKeyValue(entity, "disableshadows", "1");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_ROT_1]);

		DispatchSpawn(entity);

		TeleportEntity(entity, view_as<float>({-9.0,0.0,-9.0}), view_as<float>({0.0,0.0,0.0}), NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_WHEEL_1] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_WHEEL);
		DispatchKeyValue(entity, "disableshadows", "1");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_ROT_2]);

		DispatchSpawn(entity);

		TeleportEntity(entity, view_as<float>({-9.0,0.0,-9.0}), view_as<float>({0.0,0.0,0.0}), NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_WHEEL_2] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_WHEEL);
		DispatchKeyValue(entity, "disableshadows", "1");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_ROT_3]);

		DispatchSpawn(entity);

		TeleportEntity(entity, view_as<float>({-9.0,0.0,-9.0}), view_as<float>({0.0,0.0,0.0}), NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_WHEEL_3] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_WHEEL);
		DispatchKeyValue(entity, "disableshadows", "1");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_ROT_4]);

		DispatchSpawn(entity);

		TeleportEntity(entity, view_as<float>({-9.0,0.0,-9.0}), view_as<float>({0.0,0.0,0.0}), NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_WHEEL_4] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_WHEEL);
		DispatchKeyValue(entity, "disableshadows", "1");
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_ROT_5]);

		DispatchSpawn(entity);

		TeleportEntity(entity, view_as<float>({-9.0,0.0,-9.0}), view_as<float>({0.0,0.0,0.0}), NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_WHEEL_5] = EntIndexToEntRef(entity);
	}


	// PLUNGER DOORS
	entity = CreateEntityByName("func_door");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-plunger_1", iDMustachio);
		DispatchKeyValue(entity, "rendermode", "10");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "544");
		DispatchKeyValue(entity, "movedir", "-90 0 0");
		DispatchKeyValue(entity, "noise1", "WAM.popUp");
		DispatchKeyValue(entity, "lip", "-28");

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		// FRONT LEFT
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 5.0;
		MoveSideway(vPos, vAng, vPos, 22.0);
		MoveForward(vPos, vAng, vPos, 54.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(entity);

		SetVariantString("OnFullyOpen !self:Close::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-plunger_1_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-wam_target_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnFullyClosed", OnFullyClosed, false);
		g_iMustachios[iDMustachio][INDEX_DOOR_1] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("func_door");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-plunger_2", iDMustachio);
		DispatchKeyValue(entity, "rendermode", "10");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "544");
		DispatchKeyValue(entity, "movedir", "-90 0 0");
		DispatchKeyValue(entity, "noise1", "WAM.popUp");
		DispatchKeyValue(entity, "lip", "-28");

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		// FRONT RIGHT
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 5.0;
		MoveSideway(vPos, vAng, vPos, 42.5);
		MoveForward(vPos, vAng, vPos, 54.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(entity);

		SetVariantString("OnFullyOpen !self:Close::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-plunger_2_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-wam_target_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnFullyClosed", OnFullyClosed, false);
		g_iMustachios[iDMustachio][INDEX_DOOR_2] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("func_door");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-plunger_3", iDMustachio);
		DispatchKeyValue(entity, "rendermode", "10");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "544");
		DispatchKeyValue(entity, "movedir", "-90 0 0");
		DispatchKeyValue(entity, "noise1", "WAM.popUp");
		DispatchKeyValue(entity, "lip", "-28");

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		// BACK LEFT
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 5.0;
		MoveSideway(vPos, vAng, vPos, 12.5);
		MoveForward(vPos, vAng, vPos, 35.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(entity);

		SetVariantString("OnFullyOpen !self:Close::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-plunger_3_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-wam_target_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnFullyClosed", OnFullyClosed, false);
		g_iMustachios[iDMustachio][INDEX_DOOR_3] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("func_door");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-plunger_4", iDMustachio);
		DispatchKeyValue(entity, "rendermode", "10");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "544");
		DispatchKeyValue(entity, "movedir", "-90 0 0");
		DispatchKeyValue(entity, "noise1", "WAM.popUp");
		DispatchKeyValue(entity, "lip", "-28");

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		// BACK CENTER
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 5.0;
		MoveSideway(vPos, vAng, vPos, 32.0);
		MoveForward(vPos, vAng, vPos, 35.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(entity);

		SetVariantString("OnFullyOpen !self:Close::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-plunger_4_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-wam_target_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnFullyClosed", OnFullyClosed, false);
		g_iMustachios[iDMustachio][INDEX_DOOR_4] = EntIndexToEntRef(entity);
	}
	entity = CreateEntityByName("func_door");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-plunger_5", iDMustachio);
		DispatchKeyValue(entity, "rendermode", "10");
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "544");
		DispatchKeyValue(entity, "movedir", "-90 0 0");
		DispatchKeyValue(entity, "noise1", "WAM.popUp");
		DispatchKeyValue(entity, "lip", "-28");

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		// BACK RIGHT
		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 5.0;
		MoveSideway(vPos, vAng, vPos, 52.5);
		MoveForward(vPos, vAng, vPos, 35.0);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchSpawn(entity);

		SetVariantString("OnFullyOpen !self:Close::0.5:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-plunger_5_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnOpen %d-wam_target_surprise_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnFullyClosed", OnFullyClosed, false);
		g_iMustachios[iDMustachio][INDEX_DOOR_5] = EntIndexToEntRef(entity);
	}

	// PLUNGERS
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_MUST);
		Format(sTemp, sizeof(sTemp), "%d-plunger_1_target", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "LagCompensate", "1");
		DispatchKeyValue(entity, "solid", "6");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_DOOR_1]);

		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({0.0,0.0,0.0}), vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PLUNGER_1] = EntIndexToEntRef(entity);

		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_MUST);
		Format(sTemp, sizeof(sTemp), "%d-plunger_2_target", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "LagCompensate", "1");
		DispatchKeyValue(entity, "solid", "6");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_DOOR_2]);

		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({0.0,0.0,0.0}), vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PLUNGER_2] = EntIndexToEntRef(entity);

		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_MUST);
		Format(sTemp, sizeof(sTemp), "%d-plunger_3_target", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "LagCompensate", "1");
		DispatchKeyValue(entity, "solid", "6");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_DOOR_3]);

		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({0.0,0.0,0.0}), vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PLUNGER_3] = EntIndexToEntRef(entity);

		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_MUST);
		Format(sTemp, sizeof(sTemp), "%d-plunger_4_target", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "LagCompensate", "1");
		DispatchKeyValue(entity, "solid", "6");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_DOOR_4]);

		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({0.0,0.0,0.0}), vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PLUNGER_4] = EntIndexToEntRef(entity);

		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", MODEL_MUST);
		Format(sTemp, sizeof(sTemp), "%d-plunger_5_target", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "LagCompensate", "1");
		DispatchKeyValue(entity, "solid", "6");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", g_iMustachios[iDMustachio][INDEX_DOOR_5]);

		DispatchSpawn(entity);
		TeleportEntity(entity, view_as<float>({0.0,0.0,0.0}), vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_PLUNGER_5] = EntIndexToEntRef(entity);

		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}


	// SOUNDS
	vPos = vOrigin;
	vAng = vAngles;
	MoveSideway(vPos, vAng, vPos, 32.0);

	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_game_music", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "fadeoutsecs", "1");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "WAM.Music");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_MUSIC] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_game_countdown_sound", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "WAM.CountDown");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_COUNT] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_high_score_sound", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "WAM.HighScore");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_HIGH] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_point_score_sound", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "WAM.PointScored");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_SCORE] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_low_score_sound", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "WAM.LowScore");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_LOWSCORE] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}
	entity = CreateEntityByName("ambient_generic");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_target_surprise_sound", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "48");
		DispatchKeyValue(entity, "health", "0");
		DispatchKeyValue(entity, "radius", "1250");
		DispatchKeyValue(entity, "message", "Moustachio_WHACKPOPUP01");

		DispatchSpawn(entity);
		ActivateEntity(entity);
		g_iMustachios[iDMustachio][INDEX_SOUND_SUPRISE] = EntIndexToEntRef(entity);

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	}


	// PARTICLES
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 25;
	MoveSideway(vPos, vAng, vPos, 27.0);
	MoveForward(vPos, vAng, vPos, 65.0);
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-fx_ticket_single", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "start_active", "0");
		DispatchKeyValue(entity, "effect_name", PARTICLE_TICKET);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_TICKET] = EntIndexToEntRef(entity);
	}


	// BUTTON
	entity = CreateEntityByName("func_button");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-game_start_button", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "1025");
		DispatchKeyValue(entity, "speed", "0");
		DispatchKeyValue(entity, "wait", "3");

		vPos = vOrigin;
		vAng = vAngles;
		vPos[2] += 30;
		MoveSideway(vPos, vAng, vPos, 17.0);
		MoveForward(vPos, vAng, vPos, 65.0);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_BUTTON] = EntIndexToEntRef(entity);
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		float vMins[3]; vMins = view_as<float>({ 0.0, 0.0, 0.0 });
		float vMaxs[3]; vMaxs = view_as<float>({ 10.0, 10.0, 10.0 });
		SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);

		SetVariantString("OnPressed !self:Lock::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-game_start_button_model:SetAnimation:idle_on:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-wam_continue_sign:Skin:1:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-wam_game_music:PlaySound::4:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-wam_continue_relay:CancelPending::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-timer_script:RunScriptCode:EndContinueMode():0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-timer_script:RunScriptCode:StartGame():4:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-wam_attract_mode_rl:CancelPending::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-$wam_attract_mode_timer:Disable::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-$wam_attract_mode_timer:LowerRandomBound:20:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnPressed %d-$wam_attract_mode_timer:UpperRandomBound:30:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnIn", OnButtonIn, false);
		HookSingleEntityOutput(entity, "OnPressed", OnButtonIn, false);
	}


	// LOGIC - TIMER SCRIPT
	entity = CreateEntityByName("logic_script");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-timer_script", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "thinkfunction", "Think");
		DispatchKeyValue(entity, "vscripts", "carnival_games/whacker_timer");

		Format(sTemp, sizeof(sTemp), "%d-timer_0", iDMustachio);
		DispatchKeyValue(entity, "Group00", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-timer_1", iDMustachio);
		DispatchKeyValue(entity, "Group01", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-timer_2", iDMustachio);
		DispatchKeyValue(entity, "Group02", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-plunger_1", iDMustachio);
		DispatchKeyValue(entity, "Group03", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-plunger_2", iDMustachio);
		DispatchKeyValue(entity, "Group04", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-plunger_3", iDMustachio);
		DispatchKeyValue(entity, "Group05", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-plunger_4", iDMustachio);
		DispatchKeyValue(entity, "Group06", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-plunger_5", iDMustachio);
		DispatchKeyValue(entity, "Group07", sTemp);

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_TIMER] = EntIndexToEntRef(entity);

		Format(sTemp, sizeof(sTemp), "OnUser1 %d-end_game_rl:Trigger::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
	}
	// LOGIC - CONTINUE RELAY
	entity = CreateEntityByName("logic_relay");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_continue_relay", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);

		int skin = 0;
		for( int x = 0; x <= 9; x++ )
		{
			Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_continue_sign:Skin:%d:%d:-1", iDMustachio, skin, x);
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			skin++;
			if( skin > 1 ) skin = 0;
		}
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-counter_script:RunScriptCode:ResetScore():10:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-timer_script:RunScriptCode:BeginContinueMode():0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_CONTINUE] = entity;
	}
	// LOGIC - BREAK
	entity = CreateEntityByName("logic_relay");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_break_machine_rl", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchKeyValue(entity, "StartDisabled", "0");

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_continue_relay:CancelPending::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_continue_relay:Kill::0.01:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_target_hit_sound:Kill::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-$wam_attract_mode_timer:Kill::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_attract_mode_rl:CancelPending::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_attract_mode_rl:Kill::0.1:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_glass_broken:Enable::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_animated_sign_timer:Enable::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_game_music:FadeOut:1:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_1:Close::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_2:Close::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_3:Close::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_4:Close::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_5:Close::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_1_target:SetAnimation:break01:0.1:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_2_target:SetAnimation:break02:0.5:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_3_target:SetAnimation:break01:0.1:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_4_target:SetAnimation:break02:1:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-plunger_5_target:SetAnimation:break01:1.5:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-timer_script:RunScriptCode:StopTimer():0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnTrigger @director:ForcePanicEvent::4:-1");
		AcceptEntityInput(entity, "AddOutput");

		HookSingleEntityOutput(entity, "OnTrigger", OnTriggerWin, false);

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_BREAK] = entity;
	}

	// LOGIC - COUNTER SCRIPT
	entity = CreateEntityByName("logic_script");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-counter_script", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "vscripts", "carnival_games/whacker_counter");

		Format(sTemp, sizeof(sTemp), "%d-counter_0", iDMustachio);
		DispatchKeyValue(entity, "Group00", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-counter_1", iDMustachio);
		DispatchKeyValue(entity, "Group01", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-wam_high_score_sound", iDMustachio);
		DispatchKeyValue(entity, "Group02", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-wam_point_score_sound", iDMustachio);
		DispatchKeyValue(entity, "Group04", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-wam_break_machine_rl", iDMustachio);
		DispatchKeyValue(entity, "Group05", sTemp);
		Format(sTemp, sizeof(sTemp), "%d-fx_ticket_single", iDMustachio);
		DispatchKeyValue(entity, "Group06", sTemp);

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_COUNTER] = EntIndexToEntRef(entity);
	}

	// ATTRACT - LOGIC TIMER
	entity = CreateEntityByName("logic_timer");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-$wam_attract_mode_timer", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);
		DispatchKeyValue(entity, "UseRandomTime", "1");
		DispatchKeyValue(entity, "StartDisabled", "0");
		DispatchKeyValue(entity, "LowerRandomBound", "10");
		DispatchKeyValue(entity, "UpperRandomBound", "20");

		Format(sTemp, sizeof(sTemp), "OnTimer %d-wam_attract_mode_rl:Trigger::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_AT_1] = entity;
	}
	// ATTRACT - LOGIC RELAY
	entity = CreateEntityByName("logic_relay");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-wam_attract_mode_rl", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);

		int skin = 1;
		for( float x = 0.0; x <= 3.4; x += 0.2 )
		{
			if( x == 3.4 ) skin = 0;
			Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_animated_sign:Skin:%d:%f:-1", iDMustachio, skin, x);
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			skin++;
			if( skin > 3 ) skin = 1;
		}

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_AT_2] = entity;
	}

	// END GAME - LOGIC RELAY
	entity = CreateEntityByName("logic_relay");
	if( entity != -1 )
	{
		Format(sTemp, sizeof(sTemp), "%d-end_game_rl", iDMustachio);
		DispatchKeyValue(entity, "targetname", sTemp);

		Format(sTemp, sizeof(sTemp), "OnTrigger %d-game_start_button:Unlock::3:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-game_start_button_model:SetAnimation:idle_off:3:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_continue_relay:Trigger::3:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_low_score_sound:PlaySound::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-$wam_attract_mode_timer:Enable::0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		Format(sTemp, sizeof(sTemp), "OnTrigger %d-wam_game_music:FadeOut:1:0:-1", iDMustachio);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");

		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		g_iMustachios[iDMustachio][INDEX_LOGIC_END] = entity;
	}

	g_iMustachioCount++;
}



public void OnTriggerWin(const char[] output, int caller, int activator, float delay)
{
	int index = GetIndex(caller, INDEX_LOGIC_BREAK);
	int entity = g_iMustachios[index][INDEX_BUTTON];
	PlaySound(entity, SOUND_OVER);

	float vPos[3], vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
	MoveSideway(vPos, vAng, vPos, 9.9);
	vPos[2] -= 5.0;

	// fx_ticket_jackpot
	DisplayParticle(PARTICLE_JACKPOT, vPos, vAng);

	entity = g_iMustachios[index][INDEX_GLASS];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
	MoveSideway(vPos, vAng, vPos, 40.0);
	MoveForward(vPos, vAng, vPos, 1.0);
	vPos[2] += 15.0;

	// fx_sparks
	CreateTimer(0.5, TimerSparks, index);

	// fx_boom1
	vPos[2] += 5.0;
	MoveSideway(vPos, vAng, vPos, 10.0);
	int sparks = DisplayParticle(PARTICLE_SPARKS, vPos, vAng);
	g_iMustachios[index][INDEX_SPARKS] = EntIndexToEntRef(sparks);
	vPos[2] -= 5.0;
	MoveSideway(vPos, vAng, vPos, -10.0);

	MoveSideway(vPos, vAng, vPos, 2.0);
	DisplayParticle(PARTICLE_IMPACT_E, vPos, vAng);
	MoveSideway(vPos, vAng, vPos, -2.0);
	DisplayParticle(PARTICLE_IMPACT_E, vPos, vAng);
	DisplayParticle(PARTICLE_IMPACT_G, vPos, vAng);

	// fx_boom2
	CreateTimer(1.0, TimerMetal, index);

	// fx_smoke
	CreateTimer(1.0, TimerSmoke, index);

	if( g_iCvarEvent )
		CreateTimer(1.0, TimerEvent, activator | (index << 7));
}

// fx_boom2
public Action TimerMetal(Handle timer, any index)
{
	int entity =  g_iMustachios[index][INDEX_GLASS];
	float vPos[3], vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
	MoveSideway(vPos, vAng, vPos, 10.0);
	MoveForward(vPos, vAng, vPos, 1.0);
	vPos[2] += 5.0;

	DisplayParticle("impact_metal", vPos, vAng);
}

// fx_sparks
public Action TimerSparks(Handle timer, any index)
{
	int entity =  g_iMustachios[index][INDEX_GLASS];
	float vPos[3], vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
	MoveSideway(vPos, vAng, vPos, 50.0);
	MoveForward(vPos, vAng, vPos, 1.0);
	vPos[2] += 20.0;

	DisplayParticle(PARTICLE_LIGHT, vPos, vAng);
	MoveSideway(vPos, vAng, vPos, -2.0);
	DisplayParticle(PARTICLE_BREAK, vPos, vAng);
	MoveSideway(vPos, vAng, vPos, -1.0);
	DisplayParticle(PARTICLE_BREAK_M, vPos, vAng);
	MoveSideway(vPos, vAng, vPos, 1.0);
	DisplayParticle(PARTICLE_IMPACT_G, vPos, vAng);
}

// fx_smoke
public Action TimerSmoke(Handle timer, any index)
{
	char sTemp[64];
	int entity, target;
	float vPos[3];

	entity = g_iMustachios[index][INDEX_DOOR_1];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] += 20;
	target = CreateEntityByName("info_particle_target");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_1", index);
	DispatchKeyValue(target, "targetname", sTemp);
	DispatchSpawn(target);
	ActivateEntity(target);
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	g_iMustachios[index][INDEX_SMOKE_1] = EntIndexToEntRef(target);

	entity = g_iMustachios[index][INDEX_DOOR_2];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] += 20;
	target = CreateEntityByName("info_particle_target");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_2", index);
	DispatchKeyValue(target, "targetname", sTemp);
	DispatchSpawn(target);
	ActivateEntity(target);
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	g_iMustachios[index][INDEX_SMOKE_2] = EntIndexToEntRef(target);

	entity = g_iMustachios[index][INDEX_DOOR_3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] += 20;
	target = CreateEntityByName("info_particle_target");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_3", index);
	DispatchKeyValue(target, "targetname", sTemp);
	DispatchSpawn(target);
	ActivateEntity(target);
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	g_iMustachios[index][INDEX_SMOKE_3] = EntIndexToEntRef(target);

	entity = g_iMustachios[index][INDEX_DOOR_4];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] += 20;
	target = CreateEntityByName("info_particle_target");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_4", index);
	DispatchKeyValue(target, "targetname", sTemp);
	DispatchSpawn(target);
	ActivateEntity(target);
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	g_iMustachios[index][INDEX_SMOKE_4] = EntIndexToEntRef(target);

	entity = g_iMustachios[index][INDEX_DOOR_5];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	vPos[2] += 20;
	entity = CreateEntityByName("info_particle_system");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke", index);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "effect_name", "smoke_stache");
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_1", index);
	DispatchKeyValue(entity, "cpoint1", sTemp);
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_2", index);
	DispatchKeyValue(entity, "cpoint2", sTemp);
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_3", index);
	DispatchKeyValue(entity, "cpoint3", sTemp);
	Format(sTemp, sizeof(sTemp), "%d-fx_smoke_target_4", index);
	DispatchKeyValue(entity, "cpoint4", sTemp);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	g_iMustachios[index][INDEX_SMOKE_5] = EntIndexToEntRef(entity);
}

public Action TimerEvent(Handle timer, any bits)
{
	int client = bits & 0x7F;
	int index = bits >> 7;

	// END GAME - LOGIC RELAY
	if( g_iCvarEvent )
	{
		int entity;
		float vPos[3];

		entity = g_iMustachios[index][INDEX_BUTTON];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		int event = CreateEntityByName("info_game_event_proxy");
		if( event != -1 )
		{
			char sTemp[64];
			Format(sTemp, sizeof(sTemp), "%d-wam_achievement_event", index);
			DispatchKeyValue(event, "targetname", sTemp);
			DispatchKeyValue(event, "event_name", "stashwhacker_game_won");
			DispatchKeyValue(event, "range", "50");

			TeleportEntity(event, vPos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(event);

			AcceptEntityInput(event, "GenerateGameEvent", client);
			SetVariantString("OnUser1 !self:Kill::1:1");
			AcceptEntityInput(event, "AddOutput");
			AcceptEntityInput(event, "FireUser1");
		}
	}
}

public void OnButtonIn(const char[] output, int caller, int activator, float delay)
{
	PlaySound(caller, SOUND_START);
}

public void OnFullyClosed(const char[] output, int caller, int activator, float delay)
{
	int bits = GetDoorIndex(caller);
	int index = bits & 0x7F;
	// int plunger = bits >> 7;

	int entref = EntIndexToEntRef(caller);
	if( entref == g_iMustachios[index][INDEX_DOOR_1] )
	{
		SetVariantString("ClearHitTargetOne()");
		AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
	}
	if( entref == g_iMustachios[index][INDEX_DOOR_2] )
	{
		SetVariantString("ClearHitTargetTwo()");
		AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
	}
	if( entref == g_iMustachios[index][INDEX_DOOR_3] )
	{
		SetVariantString("ClearHitTargetThree()");
		AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
	}
	if( entref == g_iMustachios[index][INDEX_DOOR_4] )
	{
		SetVariantString("ClearHitTargetFour()");
		AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
	}
	if( entref == g_iMustachios[index][INDEX_DOOR_5] )
	{
		SetVariantString("ClearHitTargetFive()");
		AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Block multiple hits?
	// static Float:lastHit;
	// new Float:time = GetGameTime();
	// if( time - lastHit < 0.1 ) return Plugin_Continue;
	// lastHit = time;

	char sTemp[16];
	GetEdictClassname(inflictor, sTemp, sizeof(sTemp));

	if( strcmp(sTemp[7], "melee") == 0 )
	{
		OnHitMustachio(attacker, victim);
	}

	return Plugin_Continue;
}

void OnHitMustachio(int client, int entity)
{
	int bits = GetPlungerIndex(entity);
	int index = bits & 0x7F;
	int plunger = bits >> 7;

	if( index == -1 )
	{
		return;
	}

	if( !IsClientInGame(client) ) return;
	int team = GetClientTeam(client);
	if( team != 2 ) return;

	PlaySound(entity, SOUND_HIT);

	if( plunger == 1 ) SetVariantString("ScoreHitTargetOne()");
	if( plunger == 2 ) SetVariantString("ScoreHitTargetTwo()");
	if( plunger == 3 ) SetVariantString("ScoreHitTargetThree()");
	if( plunger == 4 ) SetVariantString("ScoreHitTargetFour()");
	if( plunger == 5 ) SetVariantString("ScoreHitTargetFive()");
	AcceptEntityInput(g_iMustachios[index][INDEX_LOGIC_COUNTER], "RunScriptCode");
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

	// Open the mustachio config
	KeyValues hFile = new KeyValues("Mustachios");
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

int DisplayParticle(const char[] sParticle, const float vPos[3], const float vAng[3])
{
	int entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		return entity;
	}
	return 0;
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}