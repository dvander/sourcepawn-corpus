/*
*	Target Override
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



#define PLUGIN_VERSION 		"2.19"
#define DEBUG_BENCHMARK		0			// 0=Off. 1=Benchmark only (for command). 2=Benchmark (displays on server). 3=PrintToServer various data.



#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
// #include <left4dhooks>

// Left4DHooks natives - optional - (added here to avoid requiring Left4DHooks include)
native float L4D2Direct_GetFlowDistance(int client);
native Address L4D2Direct_GetTerrorNavArea(const float pos[3], float beneathLimit = 120.0);
native float L4D2Direct_GetTerrorNavAreaFlow(Address pTerrorNavArea);
native int L4D_GetHighestFlowSurvivor();



#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
#include <profiler>
Handle g_Prof;
float g_fBenchMin;
float g_fBenchMax;
float g_fBenchAvg;
float g_iBenchTicks;
#endif


#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_target_override"
#define CONFIG_DATA			"data/l4d_target_override.cfg"

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarSpecials, g_hCvarTeam, g_hCvarType, g_hDecayDecay;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad, g_bLeft4Dead2, g_bLeft4DHooks;
int g_iCvarSpecials, g_iCvarTeam, g_iCvarType;
float g_fDecayDecay;
Handle g_hDetour;

ArrayList g_BytesSaved;
Address g_iFixOffset;
int g_iFixCount, g_iFixMatch;



#define MAX_ORDERS		13
int g_iOrderTank[MAX_ORDERS];
int g_iOrderSmoker[MAX_ORDERS];
int g_iOrderBoomer[MAX_ORDERS];
int g_iOrderHunter[MAX_ORDERS];
int g_iOrderSpitter[MAX_ORDERS];
int g_iOrderJockeys[MAX_ORDERS];
int g_iOrderCharger[MAX_ORDERS];

#define MAX_SPECIAL		7
int g_iOptionLast[MAX_SPECIAL];
int g_iOptionPinned[MAX_SPECIAL];
int g_iOptionIncap[MAX_SPECIAL];
int g_iOptionVoms[MAX_SPECIAL];
int g_iOptionVoms2[MAX_SPECIAL];
int g_iOptionSafe[MAX_SPECIAL];
int g_iOptionTarg[MAX_SPECIAL];
float g_fOptionRange[MAX_SPECIAL];
float g_fOptionDist[MAX_SPECIAL];
float g_fOptionLast[MAX_SPECIAL];
float g_fOptionWait[MAX_SPECIAL];

#define MAX_PLAY		MAXPLAYERS+1
float g_fLastSwitch[MAX_PLAY];
float g_fLastAttack[MAX_PLAY];
int g_iLastAttacker[MAX_PLAY];
int g_iLastOrders[MAX_PLAY];
int g_iLastVictim[MAX_PLAY];
bool g_bIncapped[MAX_PLAY];
bool g_bLedgeGrab[MAX_PLAY];
bool g_bPinBoomer[MAX_PLAY];
bool g_bPinSmoker[MAX_PLAY];
bool g_bPinHunter[MAX_PLAY];
bool g_bPinJockey[MAX_PLAY];
bool g_bPinCharger[MAX_PLAY];
bool g_bPumCharger[MAX_PLAY];
bool g_bCheckpoint[MAX_PLAY];

enum
{
	INDEX_TANK		= 0,
	INDEX_SMOKER	= 1,
	INDEX_BOOMER	= 2,
	INDEX_HUNTER	= 3,
	INDEX_SPITTER	= 4,
	INDEX_JOCKEY	= 5,
	INDEX_CHARGER	= 6
}

enum
{
	INDEX_TARG_DIST,
	INDEX_TARG_VIC,
	INDEX_TARG_TEAM
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Target Override",
	author = "SilverShot",
	description = "Overrides Special Infected targeting of Survivors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322311"
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

	MarkNativeAsOptional("L4D2Direct_GetFlowDistance");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavArea");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavAreaFlow");
	MarkNativeAsOptional("L4D_GetHighestFlowSurvivor");

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] sName)
{
	if( strcmp(sName, "left4dhooks") == 0 )
		g_bLeft4DHooks = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if( strcmp(sName, "left4dhooks") == 0 )
		g_bLeft4DHooks = false;
}

public void OnAllPluginsLoaded()
{
	// =========================
	// PREVENT OLD PLUGIN
	// =========================
	if( FindConVar(g_bLeft4Dead2 ? "l4d2_target_patch_version" : "l4d_target_patch_version") != null )
		SetFailState("Error: Old plugin \"%s\" detected. This plugin supersedes the old version, delete it and restart server.", g_bLeft4Dead2 ? "l4d2_target_patch" : "l4d_target_patch");
}

public void OnPluginStart()
{
	// =========================
	// GAMEDATA
	// =========================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	// Detour
	g_hDetour = DHookCreateFromConf(hGameData, "BossZombiePlayerBot::ChooseVictim");

	if( !g_hDetour ) SetFailState("Failed to find \"BossZombiePlayerBot::ChooseVictim\" signature.");



	// =========================
	// PATCH
	// =========================
	if( g_bLeft4Dead2 )
	{
		g_iFixOffset = GameConfGetAddress(hGameData, "TankAttack::Update");
		if( !g_iFixOffset ) SetFailState("Failed to find \"TankAttack::Update\" signature.", GAMEDATA);

		int offs = GameConfGetOffset(hGameData, "TankAttack__Update_Offset");
		if( offs == -1 ) SetFailState("Failed to load \"TankAttack__Update_Offset\" offset.", GAMEDATA);

		g_iFixOffset += view_as<Address>(offs);

		g_iFixCount = GameConfGetOffset(hGameData, "TankAttack__Update_Count");
		if( g_iFixCount == -1 ) SetFailState("Failed to load \"TankAttack__Update_Count\" offset.", GAMEDATA);

		g_iFixMatch = GameConfGetOffset(hGameData, "TankAttack__Update_Match");
		if( g_iFixMatch == -1 ) SetFailState("Failed to load \"TankAttack__Update_Match\" offset.", GAMEDATA);

		g_BytesSaved = new ArrayList();

		for( int i = 0; i < g_iFixCount; i++ )
		{
			g_BytesSaved.Push(LoadFromAddress(g_iFixOffset + view_as<Address>(i), NumberType_Int8));
		}

		if( g_BytesSaved.Get(0) != g_iFixMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", offs, g_BytesSaved.Get(0), g_iFixMatch);
	}

	delete hGameData;



	// =========================
	// CVARS
	// =========================
	g_hCvarAllow =			CreateConVar(	"l4d_target_override_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_target_override_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_target_override_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_target_override_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarSpecials =	CreateConVar(	"l4d_target_override_specials",			"127",				"Override these Specials target function: 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 64=Tank. 127=All. Add numbers together.", CVAR_FLAGS );
	else
		g_hCvarSpecials =	CreateConVar(	"l4d_target_override_specials",			"15",				"Override these Specials target function: 1=Smoker, 2=Boomer, 4=Hunter, 8=Tank. 15=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarTeam =			CreateConVar(	"l4d_target_override_team",				"2",				"Which Survivor teams should be targeted. 2=Default Survivors. 4=Holding and Passing bots. 6=Both.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d_target_override_type",				"1",				"How should the plugin search through Survivors. 1=Nearest visible (defaults to games method on fail). 2=All Survivors from the nearest. 3=Nearest by flow distance (requires Left4DHooks plugin, defaults to type 2).", CVAR_FLAGS );
	CreateConVar(							"l4d_target_override_version",			PLUGIN_VERSION,		"Target Override plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_target_override");

	g_hDecayDecay = FindConVar("pain_pills_decay_rate");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hDecayDecay.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpecials.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTeam.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);



	// =========================
	// COMMANDS
	// =========================
	RegAdminCmd("sm_to_reload",		CmdReload,	ADMFLAG_ROOT, "Reloads the data config.");

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	RegAdminCmd("sm_to_stats",		CmdStats,	ADMFLAG_ROOT, "Displays benchmarking stats (min/avg/max).");
	#endif



	// =========================
	// LATELOAD
	// =========================
	if( g_bLateLoad )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) )
			{
				g_bIncapped[i]			= GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1;
				g_bLedgeGrab[i]			= GetEntProp(i, Prop_Send, "m_isHangingFromLedge", 1) == 1;
				g_bPinSmoker[i]			= GetEntPropEnt(i, Prop_Send, "m_tongueOwner") > 0;
				g_bPinHunter[i]			= GetEntPropEnt(i, Prop_Send, "m_pounceAttacker") > 0;
				if( g_bLeft4Dead2 )
				{
					g_bPinJockey[i]		= GetEntPropEnt(i, Prop_Send, "m_jockeyAttacker") > 0;
					g_bPinCharger[i]	= GetEntPropEnt(i, Prop_Send, "m_pummelAttacker") > 0;
					g_bPumCharger[i] = g_bPinCharger[i];
				}
				// g_bPinBoomer[i]		= Unvomit/Left4DHooks method could solve this, but only required for lateload - cba.
			}
		}
	}

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	g_Prof = CreateProfiler();
	#endif
}

public void OnPluginEnd()
{
	DetourAddress(false);
	PatchAddress(false);
}



// ====================================================================================================
//					LOAD DATA CONFIG
// ====================================================================================================
#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
Action CmdStats(int client, int args)
{
	ReplyToCommand(client, "Target Override: Stats: Min %f. Avg %f. Max %f", g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
	return Plugin_Handled;
}
#endif

Action CmdReload(int client, int args)
{
	OnMapStart();
	ReplyToCommand(client, "Target Override: Data config reloaded.");
	return Plugin_Handled;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	// Load config
	KeyValues hFile = new KeyValues("target_patch");
	if( !hFile.ImportFromFile(sPath) )
	{
		SetFailState("Error loading file: \"%s\". Try replacing the file with the original.", sPath);
	}

	ExplodeToArray("tank",			hFile,	INDEX_TANK,		g_iOrderTank);
	ExplodeToArray("smoker",		hFile,	INDEX_SMOKER,	g_iOrderSmoker);
	ExplodeToArray("boomer",		hFile,	INDEX_BOOMER,	g_iOrderBoomer);
	ExplodeToArray("hunter",		hFile,	INDEX_HUNTER,	g_iOrderHunter);
	if( g_bLeft4Dead2 )
	{
		ExplodeToArray("spitter",	hFile,	INDEX_SPITTER,	g_iOrderSpitter);
		ExplodeToArray("jockey",	hFile,	INDEX_JOCKEY,	g_iOrderJockeys);
		ExplodeToArray("charger",	hFile,	INDEX_CHARGER,	g_iOrderCharger);
	}

	delete hFile;
}

void ExplodeToArray(char[] key, KeyValues hFile, int index, int arr[MAX_ORDERS])
{
	if( hFile.JumpToKey(key) )
	{
		char buffer[32];
		char buffers[MAX_ORDERS][3];

		hFile.GetString("order", buffer, sizeof(buffer), "0,0,0,0,0,0,0,0,0,0,0,0,0");
		ExplodeString(buffer, ",", buffers, MAX_ORDERS, sizeof(buffers[]));

		for( int i = 0; i < MAX_ORDERS; i++ )
		{
			arr[i] = StringToInt(buffers[i]);
		}

		g_iOptionPinned[index] = hFile.GetNum("pinned");
		g_iOptionIncap[index] = hFile.GetNum("incap");
		g_iOptionVoms[index] = hFile.GetNum("voms");
		g_iOptionVoms2[index] = hFile.GetNum("voms2");
		g_fOptionDist[index] = hFile.GetFloat("dist");
		g_fOptionLast[index] = hFile.GetFloat("time");
		g_fOptionRange[index] = hFile.GetFloat("range");
		g_fOptionWait[index] = hFile.GetFloat("wait");
		g_iOptionLast[index] = hFile.GetNum("last");
		g_iOptionSafe[index] = hFile.GetNum("safe");
		g_iOptionTarg[index] = hFile.GetNum("targeted");
		hFile.Rewind();
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
	g_fDecayDecay =		g_hDecayDecay.FloatValue;
	g_iCvarSpecials =	g_hCvarSpecials.IntValue;
	g_iCvarTeam =		g_hCvarTeam.IntValue;
	g_iCvarType =		g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		HookPlayerHurt(true);

		HookEvent("player_spawn",						Event_PlayerSpawn);
		HookEvent("round_start",						Event_RoundStart);
		HookEvent("revive_success",						Event_ReviveSuccess);	// Revived
		HookEvent("player_incapacitated",				Event_Incapacitated);
		HookEvent("player_ledge_grab",					Event_LedgeGrab);		// Ledge
		HookEvent("player_now_it",						Event_BoomerStart);		// Boomer
		HookEvent("player_no_longer_it",				Event_BoomerEnd);
		HookEvent("lunge_pounce",						Event_HunterStart);		// Hunter
		HookEvent("pounce_end",							Event_HunterEnd);
		HookEvent("tongue_grab",						Event_SmokerStart);		// Smoker
		HookEvent("tongue_release",						Event_SmokerEnd);
		HookEvent("player_left_checkpoint",				Event_LeftCheckpoint);
		HookEvent("player_entered_checkpoint",			Event_EnteredCheckpoint);

		if( g_bLeft4Dead2 )
		{
			HookEvent("jockey_ride",					Event_JockeyStart);		// Jockey
			HookEvent("jockey_ride_end",				Event_JockeyEnd);
			HookEvent("charger_pummel_start",			Event_ChargerPummel);	// Charger
			HookEvent("charger_carry_start",			Event_ChargerStart);
			HookEvent("charger_carry_end",				Event_ChargerEnd);
			HookEvent("charger_pummel_end",				Event_ChargerEnd);
			HookEvent("player_entered_start_area",		Event_EnteredCheckpoint);
		}

		DetourAddress(true);
		PatchAddress(true);
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		HookPlayerHurt(false);

		UnhookEvent("player_spawn",						Event_PlayerSpawn);
		UnhookEvent("round_start",						Event_RoundStart);
		UnhookEvent("revive_success",					Event_ReviveSuccess);	// Revived
		UnhookEvent("player_incapacitated",				Event_Incapacitated);
		UnhookEvent("player_ledge_grab",				Event_LedgeGrab);		// Ledge
		UnhookEvent("player_now_it",					Event_BoomerStart);		// Boomer
		UnhookEvent("player_no_longer_it",				Event_BoomerEnd);
		UnhookEvent("lunge_pounce",						Event_HunterStart);		// Hunter
		UnhookEvent("pounce_end",						Event_HunterEnd);
		UnhookEvent("tongue_grab",						Event_SmokerStart);		// Smoker
		UnhookEvent("tongue_release",					Event_SmokerEnd);
		UnhookEvent("player_left_checkpoint",			Event_LeftCheckpoint);
		UnhookEvent("player_entered_checkpoint",		Event_EnteredCheckpoint);

		if( g_bLeft4Dead2 )
		{
			UnhookEvent("jockey_ride",					Event_JockeyStart);		// Jockey
			UnhookEvent("jockey_ride_end",				Event_JockeyEnd);
			UnhookEvent("charger_pummel_start",			Event_ChargerPummel);	// Charger
			UnhookEvent("charger_carry_start",			Event_ChargerStart);
			UnhookEvent("charger_carry_end",			Event_ChargerEnd);
			UnhookEvent("charger_pummel_end",			Event_ChargerEnd);
			UnhookEvent("player_entered_start_area",	Event_EnteredCheckpoint);
		}

		DetourAddress(false);
		PatchAddress(false);
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
public void OnClientDisconnect(int client)
{
	// Remove disconnected client from being targeted
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_iLastVictim[i] == client )
		{
			g_iLastVictim[i] = 0;
		}
	}
}

void Event_EnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = true;
}

void Event_LeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = false;
}

void HookPlayerHurt(bool doHook)
{
	// Hook player_hurt for order type 7 - target last attacker.
	bool hook;
	for( int i = 0; i < MAX_SPECIAL; i++ )
	{
		if( g_iOptionLast[i] )
		{
			hook = true;
			break;
		}
	}

	static bool bHookedHurt;

	if( doHook && hook && !bHookedHurt )
	{
		bHookedHurt = true;
		HookEvent("player_hurt",		Event_PlayerHurt);
	}
	else if( (!doHook || !hook) && bHookedHurt )
	{
		bHookedHurt = false;
		UnhookEvent("player_hurt",		Event_PlayerHurt);
	}
}

void ResetVars(int client)
{
	g_iLastAttacker[client] = 0;
	g_iLastOrders[client] = 0;
	g_iLastVictim[client] = 0;
	g_fLastSwitch[client] = 0.0;
	g_fLastAttack[client] = 0.0;
	g_bIncapped[client] = false;
	g_bLedgeGrab[client] = false;
	g_bPinBoomer[client] = false;
	g_bPinSmoker[client] = false;
	g_bPinHunter[client] = false;
	g_bPinJockey[client] = false;
	g_bPinCharger[client] = false;
	g_bPumCharger[client] = false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 0; i <= MaxClients; i++ )
	{
		ResetVars(i);

		if( i && IsClientInGame(i) && ValidateTeam(i) == 2 )
			g_bCheckpoint[i] = true;
		else
			g_bCheckpoint[i] = false;
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	ResetVars(client);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = event.GetInt("attacker");
	if( attacker )
	{
		int type = event.GetInt("type");

		if( type & (DMG_BULLET|DMG_SLASH|DMG_CLUB) )
		{
			g_iLastAttacker[client] = attacker;
			g_fLastAttack[client] = GetGameTime();
		}
	}
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	g_bIncapped[client] = false;
	g_bLedgeGrab[client] = false;
}

void Event_Incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIncapped[client] = true;
}

void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bLedgeGrab[client] = true;
}

void Event_SmokerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinSmoker[client] = true;
}

void Event_SmokerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinSmoker[client] = false;
}

void Event_BoomerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPinBoomer[client] = true;
}

void Event_BoomerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bPinBoomer[client] = false;
}

void Event_HunterStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinHunter[client] = true;
}

void Event_HunterEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinHunter[client] = false;
}

void Event_JockeyStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinJockey[client] = true;
}

void Event_JockeyEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinJockey[client] = false;
}

void Event_ChargerPummel(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPumCharger[client] = true;
	g_bPinCharger[client] = true;
}

void Event_ChargerStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinCharger[client] = true;
}

void Event_ChargerEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bPinCharger[client] = false;
	g_bPumCharger[client] = false;
}



// ====================================================================================================
//					PATCH + DETOUR
// ====================================================================================================
void PatchAddress(bool patch)
{
	if( !g_bLeft4Dead2 ) return;

	static bool patched;

	if( !patched && patch )
	{
		patched = true;	

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), 0x90, NumberType_Int8);
		}
	}
	else if( patched && !patch )
	{
		patched = false;

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), g_BytesSaved.Get(i), NumberType_Int8);
		}
	}
}

void DetourAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		if( !DHookEnableDetour(g_hDetour, false, ChooseVictim) )
			SetFailState("Failed to detour \"BossZombiePlayerBot::ChooseVictim\".");

		patched = true;
	}
	else if( patched && !patch )
	{
		if( !DHookDisableDetour(g_hDetour, false, ChooseVictim) )
			SetFailState("Failed to disable detour \"BossZombiePlayerBot::ChooseVictim\".");

		patched = false;
	}
}

MRESReturn ChooseVictim(int attacker, Handle hReturn)
{
	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	StartProfiling(g_Prof);
	#endif

	#if DEBUG_BENCHMARK == 3
	PrintToServer("");
	PrintToServer("");
	PrintToServer("CHOOSER %d (%N)", attacker, attacker);
	#endif



	// =========================
	// VALIDATE SPECIAL ALLOWED CHANGE TARGET
	// =========================
	// 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger, 5 (L4D1) / 8 (L4D2)=Tank
	int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
	if( class == (g_bLeft4Dead2 ? 8 : 5) ) class -= 1;
	if( g_iCvarSpecials & (1 << class - 1) == 0 )
	{
		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 1 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}

	// Change tank class for use as index
	if( class == (g_bLeft4Dead2 ? 7 : 4) )
	{
		class = 0;
	}



	// =========================
	// VALIDATE OLD TARGET, WAIT
	// =========================
	int newVictim;
	int lastVictim = g_iLastVictim[attacker];
	if( lastVictim )
	{
		// Player disconnected or player dead, otherwise validate last selected order still applies
		if( IsClientInGame(lastVictim) && IsPlayerAlive(lastVictim) )
		{
			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: Order: %d. newVictim %d (%N)", g_iLastOrders[attacker], lastVictim, lastVictim);
			#endif

			newVictim = OrderTest(attacker, lastVictim, ValidateTeam(lastVictim), class, g_iLastOrders[attacker]);

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: newVictim %d (%N)", lastVictim, lastVictim);
			#endif
		}

		// Not reached delay time
		if( newVictim && GetGameTime() <= g_fLastSwitch[attacker] )
		{
			#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
			StopProfiling(g_Prof);
			float speed = GetProfilerTime(g_Prof);
			if( speed < g_fBenchMin ) g_fBenchMin = speed;
			if( speed > g_fBenchMax ) g_fBenchMax = speed;
			g_fBenchAvg += speed;
			g_iBenchTicks++;
			#endif

			#if DEBUG_BENCHMARK == 2
			PrintToServer("ChooseVictim End 2 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
			#endif

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: wait delay (%0.2f).", GetGameTime() - g_fLastSwitch[attacker]);
			#endif

			// CONTINUE OVERRIDE LAST
			DHookSetReturn(hReturn, newVictim);
			return MRES_Supercede;
		}
		else
		{
			if( newVictim && g_fOptionDist[class] )
			{
				static float vPos[3], vVec[3];
				GetClientAbsOrigin(newVictim, vPos);
				GetClientAbsOrigin(attacker, vVec);
				float dist = GetVectorDistance(vPos, vVec);

				if( dist < g_fOptionDist[class] )
				{
					#if DEBUG_BENCHMARK == 3
					PrintToServer("=== Test Dist: within %0.2f / %0.2f range to keep target.", dist, g_fOptionDist[class]);
					#endif

					g_fLastSwitch[attacker] = GetGameTime() + g_fOptionWait[class];

					// CONTINUE OVERRIDE LAST
					DHookSetReturn(hReturn, newVictim);
					return MRES_Supercede;
				}
			}

			#if DEBUG_BENCHMARK == 3
			PrintToServer("=== Test Last: wait reset.");
			#endif

			g_iLastOrders[attacker] = 0;
			g_iLastVictim[attacker] = 0;
			g_fLastSwitch[attacker] = 0.0;
		}
	}



	// =========================
	// FIND NEAREST SURVIVORS
	// =========================
	// Visible near
	float vPos[3];
	int targets[MAX_PLAY];
	int numClients;


	// Search method
	switch( g_iCvarType )
	{
		case 1:
		{
			GetClientEyePosition(attacker, vPos);
			numClients = GetClientsInRange(vPos, RangeType_Visibility, targets, MAX_PLAY);
		}
		case 2, 3:
		{
			GetClientAbsOrigin(attacker, vPos);
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
				{
					targets[numClients++] = i;
				}
			}
		}
	}

	if( numClients == 0 )
	{
		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 3 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}



	// =========================
	// GET DISTANCE
	// =========================
	ArrayList aTargets = new ArrayList(3);
	float vTarg[3];
	float dist;
	float flow;
	int team;
	int index;
	int victim;

	// Check range by nav flow
	int type = g_iCvarType;
	if( type == 3 && g_bLeft4DHooks )
	{
		// Attempt to get flow distance from position and nav address
		flow = L4D2Direct_GetFlowDistance(attacker);
		if( flow == 0.0 || flow == -9999.0 ) // Invalid flows
		{
			// Failing that try backup method
			Address addy = L4D2Direct_GetTerrorNavArea(vPos);
			if( addy )
			{
				flow = L4D2Direct_GetTerrorNavAreaFlow(addy);

				if( flow == 0.0 || flow == -9999.0 ) // Invalid flows
				{
					type = 2;
				}
			} else {
				type = 2;
			}
		}
	} else {
		type = 2;
	}

	for( int i = 0; i < numClients; i++ )
	{
		victim = targets[i];

		if( victim && IsPlayerAlive(victim) )
		{
			team = ValidateTeam(victim);
			// Option "voms2" then allow attacking vomited survivors ELSE not vomited
			// Option "voms" then allow choosing team 3 when vomited
			if( (team == 2 && (g_iOptionVoms2[class] == 1 || g_bPinBoomer[i] == false) ) ||
				(team == 3 && g_iOptionVoms[class] == 1 && g_bPinBoomer[i] == true) )
			{
				// Saferoom test
				if( !g_iOptionSafe[class] || !g_bCheckpoint[victim] )
				{
					// Already targeted test
					if( g_iOptionTarg[class] )
					{
						for( int x = 1; x <= MaxClients; x++ )
						{
							if( x != attacker && g_iLastVictim[x] == victim )
							{
								#if DEBUG_BENCHMARK == 3
								if( IsClientInGame(x) )
								{
									PrintToServer("%N is ignoring %N already targeted by %N", attacker, victim, x);
								}
								#endif

								if( IsClientInGame(x) )
								{
									victim = 0;
									break;
								}

								g_iLastVictim[x] = 0;
							}
						}

						if( victim == 0 ) continue;
					}

					if( type == 3 )
					{
						// Attempt to get flow distance from position and nav address
						dist = L4D2Direct_GetFlowDistance(victim);
						if( dist == 0.0 || dist == -9999.0 ) // Invalid flows
						{
							// Failing that try backup method
							GetClientAbsOrigin(victim, vTarg);
							Address addy = L4D2Direct_GetTerrorNavArea(vTarg);
							if( addy )
							{
								dist = L4D2Direct_GetTerrorNavAreaFlow(addy);

								if( dist == 0.0 || dist == -9999.0 ) // Invalid flows
								{
									dist = 999999.0;
								}
							} else {
								dist = 999999.0;
							}
						}

						if( dist != 999999.0 ) // Invalid flows
						{
							dist -= flow;
							if( dist < 0.0 ) dist *= -1.0;
						}
					}
					else
					{
						GetClientAbsOrigin(victim, vTarg);
						dist = GetVectorDistance(vPos, vTarg);
					}

					if( dist != 999999.0 && (dist < g_fOptionRange[class] || g_fOptionRange[class] == 0.0) )
					{
						index = aTargets.Push(dist);
						aTargets.Set(index, victim, INDEX_TARG_VIC);
						aTargets.Set(index, team, INDEX_TARG_TEAM);
					}
				}
			}
		}
	}

	// Sort by nearest
	int len = aTargets.Length;
	if( len == 0 )
	{
		delete aTargets;

		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 4 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		return MRES_Ignored;
	}

	SortADTArray(aTargets, Sort_Ascending, Sort_Float);



	// =========================
	// ALL INCAPPED CHECK
	// OPTION: "incap" "3"
	// =========================
	// 3=Only attack incapacitated when everyone is incapacitated.
	bool allIncap;
	if( g_iOptionIncap[class] == 3 )
	{
		allIncap = true;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
			{
				if( g_bIncapped[i] == false )
				{
					allIncap = false;
					break;
				}
			}
		}
	}



	// =========================
	// ORDER VALIDATION
	// =========================
	// Loop through all orders progressing to the next on fail, and each time loop through all survivors from nearest to test the order preference
	bool allPinned = true;
	int order;

	int orders;
	for( ; orders < MAX_ORDERS; orders++ )
	{
		// Found someone last order loop, exit loop
		#if DEBUG_BENCHMARK == 3
		PrintToServer("=== ORDER LOOP %d. newVictim %d (%N)", orders + 1, newVictim, newVictim);
		#endif

		if( newVictim ) break;



		// =========================
		// OPTION: "order"
		// =========================
		switch( class )
		{
			case INDEX_TANK:		order = g_iOrderTank[orders];
			case INDEX_SMOKER:		order = g_iOrderSmoker[orders];
			case INDEX_BOOMER:		order = g_iOrderBoomer[orders];
			case INDEX_HUNTER:		order = g_iOrderHunter[orders];
			case INDEX_SPITTER:		order = g_iOrderSpitter[orders];
			case INDEX_JOCKEY:		order = g_iOrderJockeys[orders];
			case INDEX_CHARGER:		order = g_iOrderCharger[orders];
		}



		// Last Attacker enabled?
		if( order == 7 && g_iOptionLast[class] == 0 ) continue;



		// =========================
		// LOOP SURVIVORS
		// =========================
		for( int i = 0; i < len; i++ )
		{
			victim = aTargets.Get(i, INDEX_TARG_VIC);



			// All incapped, target nearest
			if( allIncap )
			{
				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break allIncap");
				#endif

				newVictim = victim;
				break;
			}



			team = aTargets.Get(i, INDEX_TARG_TEAM);
			// dist = aTargets.Get(i, INDEX_TARG_DIST);



			// =========================
			// OPTION: "incap"
			// =========================
			// 0=Ignore incapacitated players.
			// 1=Allow attacking incapacitated players.
			// 2=Only attack incapacitated players when they are vomited.
			// 3=Only attack incapacitated when everyone is incapacitated.
			// 3 is already checked above.
			if( team == 2 && g_bIncapped[victim] == true )
			{
				switch( g_iOptionIncap[class] )
				{
					case 0: continue;
					case 2: if( g_bPinBoomer[victim] == false ) continue;
				}
			}



			// =========================
			// OPTION: "pinned"
			// =========================
			// Validate pinned and allowed
			// 1=Smoker. 2=Hunter. 4=Jockey. 8=Charger.
			if( team == 2 )
			{
				if( g_iOptionPinned[class] & 1 && g_bPinSmoker[victim] ) continue;
				if( g_iOptionPinned[class] & 2 && g_bPinHunter[victim] ) continue;
				if( g_bLeft4Dead2 )
				{
					if( g_iOptionPinned[class] & 4 && g_bPinJockey[victim] ) continue;
					if( g_iOptionPinned[class] & 8 && g_bPinCharger[victim] ) continue;
				}

				allPinned = false;
			}



			// =========================
			// OPTION: "order"
			// =========================
			newVictim = OrderTest(attacker, victim, team, class, order);

			#if DEBUG_BENCHMARK == 3
			PrintToServer("Order %d newVictim %d (%N)", order, newVictim, newVictim);
			#endif

			if( newVictim || order == 0 ) break;
		}

		if( newVictim || order == 0 ) break;
	}



	// All pinned and not allowed to target, target self to avoid attacking pinned.
	if( allPinned && g_iOptionPinned[class] == 0 )
	{
		newVictim = attacker;
	}



	// =========================
	// NEW TARGET
	// =========================
	if( newVictim != g_iLastVictim[attacker] )
	{
		#if DEBUG_BENCHMARK == 3
		PrintToServer("New order victim selected: %d (%N) (order %d/%d)", newVictim, newVictim, order, orders);
		#endif

		g_iLastOrders[attacker] = order;
		g_iLastVictim[attacker] = newVictim;
		g_fLastSwitch[attacker] = GetGameTime() + g_fOptionWait[class];
	}



	// =========================
	// OVERRIDE VICTIM
	// =========================
	if( newVictim )
	{
		DHookSetReturn(hReturn, newVictim);

		#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
		StopProfiling(g_Prof);
		float speed = GetProfilerTime(g_Prof);
		if( speed < g_fBenchMin ) g_fBenchMin = speed;
		if( speed > g_fBenchMax ) g_fBenchMax = speed;
		g_fBenchAvg += speed;
		g_iBenchTicks++;
		#endif

		#if DEBUG_BENCHMARK == 2
		PrintToServer("ChooseVictim End 5 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
		#endif

		delete aTargets;
		return MRES_Supercede;
	}

	#if DEBUG_BENCHMARK == 1 || DEBUG_BENCHMARK == 2
	StopProfiling(g_Prof);
	float speed = GetProfilerTime(g_Prof);
	if( speed < g_fBenchMin ) g_fBenchMin = speed;
	if( speed > g_fBenchMax ) g_fBenchMax = speed;
	g_fBenchAvg += speed;
	g_iBenchTicks++;
	#endif

	#if DEBUG_BENCHMARK == 2
	PrintToServer("ChooseVictim End 6 in %f (Min %f. Avg %f. Max %f)", speed, g_fBenchMin, g_fBenchAvg / g_iBenchTicks, g_fBenchMax);
	#endif

	delete aTargets;
	return MRES_Ignored;
}

int OrderTest(int attacker, int victim, int team, int class, int order)
{
	#if DEBUG_BENCHMARK == 3
	PrintToServer("Begin OrderTest for (%d - %N). Test (%d - %N) with order: %d", attacker, attacker, victim, victim, order);
	#endif

	int newVictim;

	switch( order )
	{
		// 1=Normal Survivor
		case 1:
		{
			if( team == 2 &&
				g_bLedgeGrab[victim] == false &&
				g_bIncapped[victim] == false &&
				g_bPinBoomer[victim] == false &&
				g_bPinSmoker[victim] == false &&
				g_bPinHunter[victim] == false &&
				g_bPinJockey[victim] == false &&
				g_bPinCharger[victim] == false
			)
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 1");
				#endif
			}
		}

		// 2=Vomited Survivor
		case 2:
		{
			if( team == 2 && g_bPinBoomer[victim] == true )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 2");
				#endif
			}
		}

		// 3=Incapped
		case 3:
		{
			if( team == 2 && g_bIncapped[victim] == true && g_bLedgeGrab[victim] == false )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 3");
				#endif
			}
		}

		// 4=Pinned
		case 4:
		{
			if( team == 2 &&
				g_bPinSmoker[victim] == true ||
				g_bPinHunter[victim] == true ||
				g_bPinJockey[victim] == true ||
				g_bPinCharger[victim] == true
			)
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 4");
				#endif
			}
		}

		// 5=Ledge
		case 5:
		{
			if( team == 2 && g_bLedgeGrab[victim] )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 5");
				#endif
			}
		}

		// 6=Infected Vomited
		case 6:
		{
			if( team == 3 && victim != attacker && g_bPinBoomer[victim] )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 6");
				#endif
			}
		}

		// 7=Last Attacker
		case 7:
		{
			if( g_iLastAttacker[attacker] && g_fLastAttack[attacker] + g_fOptionLast[class] > GetGameTime() )
			{
				victim = GetClientOfUserId(g_iLastAttacker[attacker]);
				if( victim && IsPlayerAlive(victim) && ValidateTeam(victim) == 2 )
				{
					newVictim = victim;

					#if DEBUG_BENCHMARK == 3
					PrintToServer("Break order 7");
					#endif
				}
				else
				{
					g_iLastAttacker[attacker] = 0;
				}
			}
		}

		// 8=Lowest Health Survivor
		case 8:
		{
			int target;
			int health;
			int total = 10000;

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
				{
					health = RoundFloat(GetClientHealth(i) + GetTempHealth(i));
					if( health < total )
					{
						target = i;
						total = health;
					}
				}
			}

			if( target == victim )
			{
				newVictim = target;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 8");
				#endif
			}
		}

		// 9=Highest Health Survivor
		case 9:
		{
			int target;
			int health;
			int total;

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && ValidateTeam(i) == 2 && IsPlayerAlive(i) )
				{
					health = RoundFloat(GetClientHealth(i) + GetTempHealth(i));
					if( health > total )
					{
						target = i;
						total = health;
					}
				}
			}

			if( target == victim )
			{
				newVictim = target;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 9");
				#endif
			}
		}

		// 10=Pummelled Survivor
		case 10:
		{
			if( g_bPumCharger[victim] )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 10");
				#endif
			}
		}

		// 11=Mounted Mini Gun
		case 11:
		{
			if( GetEntProp(victim, Prop_Send, "m_usingMountedWeapon") > 0 )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 11");
				#endif
			}
		}

		// 12=Furthest Ahead
		case 12:
		{
			if( g_bLeft4DHooks && L4D_GetHighestFlowSurvivor() == victim )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 12");
				#endif
			}
		}

		// 13=Reviving someone
		case 13:
		{
			if( GetEntPropEnt(victim, Prop_Send, "m_reviveTarget") > 0 )
			{
				newVictim = victim;

				#if DEBUG_BENCHMARK == 3
				PrintToServer("Break order 12");
				#endif
			}
		}
		
		// 14=healing critical
		case 14:
		{
			int health = RoundFloat(GetClientHealth(victim) + GetTempHealth(victim));
			if( victim==GetEntPropEnt(victim, Prop_Send, "m_healOwner") && health < GetConVarInt(FindConVar("survivor_limp_health")) )
			{
				newVictim = victim;
			}
		}
	}

	// Ignore players using a minigun if not checking for that
	if( newVictim && order != 11 && GetEntProp(newVictim, Prop_Send, "m_usingMountedWeapon") > 0 )
	{
		newVictim = 0;
	}

	return newVictim;
}

float GetTempHealth(int client)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fDecayDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

int ValidateTeam(int client)
{
	int team = GetClientTeam(client);
	switch( team )
	{
		case 2:		if( 2 & g_iCvarTeam) return 2;
		case 4:		if( 4 & g_iCvarTeam) return 2;
		case 3:		return 3;
	}

	return 0;
}