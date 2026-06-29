/*
*	Melee Range
*	Copyright (C) 2026 Silvers
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



#define PLUGIN_VERSION 		"2.3"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Melee Range
*	Author	:	SilverShot
*	Descrp	:	Adjustable melee range for each melee weapon.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=318958
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.3 (04-Jan-2026)
	- Fixed command "sm_melee_range" translations failing when targeting players.

2.2 (04-Jan-2025)
	- Added command "sm_melee_range" to set a specific clients melee range for all melee weapons. Requested by "IRONADE".
	- This range ignores the configs set ranges and resets on map change.

2.1 (05-Nov-2024)
	- Fixed the "Tonfa" from "Riot" zombies, and possibly other melee weapons not being recognized when missing their script name.

2.0 (21-Apr-2024)
	- Removed all the melee range cvars, now using a data config instead. Requested by "little_froy".
	- Added command "sm_melee_range_reload" to reload the data config.
	- Added command "sm_melee_range_set" to set a melee weapon range.

1.6 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.5 (24-Sep-2020)
	- Compatibility update for L4D2's "The Last Stand" update.
	- Added support for the 2 new melee weapons.
	- Added 2 new cvars "l4d2_melee_range_weapon_pitchfork" and "l4d2_melee_range_weapon_shovel".

1.4 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.2 (05-Feb-2020)
	- Added cvar "l4d2_melee_range_weapon_unknown" for 3rd party melee weapons.
	- Changed melee detection method and setting of range.
	- Should no longer conflict with simultaneous melee swings and set the correct range per weapon.
	- Optimized cvars for faster CPU processing.
	- Now requires DHooks and gamedata file.
	- Compiled with SourceMod 1.10.

1.1 (03-Oct-2019)
	- Increased string size to fix the plugin not working. Thanks to "xZk" for reporting.

1.0 (02-Oct-2019)
	- Initial release.

======================================================================================*/

// TESTING:
// give baseball_bat; give cricket_bat; give crowbar; give electric_guitar; give fireaxe; give frying_pan; give golfclub; give katana; give knife; give machete; give tonfa; give pitchfork; give shovel



#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define	MAX_MELEE			14
#define GAMEDATA			"l4d2_melee_range"
#define CONFIG_DATA			"data/l4d2_melee_range.cfg"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarMeleeRange;
bool g_bCvarAllow, g_bMapStarted;

int g_iClientRange[MAXPLAYERS+1];
int g_iStockRange;
Handle g_hDetour;
StringMap g_hScripts;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Melee Range",
	author = "SilverShot",
	description = "Adjustable melee range for each melee weapon.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=318958"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// GAMEDATA
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetour = DHookCreateFromConf(hGameData, "CTerrorMeleeWeapon::TestMeleeSwingCollision");
	delete hGameData;

	if( !g_hDetour )
		SetFailState("Failed to find \"CTerrorMeleeWeapon::GetPrimaryAttackActivity\" signature.");

	// Translations for "sm_melee_range" command
	LoadTranslations("common.phrases");

	// SCRIPTS - Must match cvars list and their index numbers. The "_unknown" cvar must be last and not in scripts list.
	// You must also increase MAX_MELEE by 1 for each script you add.
	g_hScripts = CreateTrie();
	g_hScripts.SetValue("baseball_bat",		0);
	g_hScripts.SetValue("cricket_bat",		1);
	g_hScripts.SetValue("crowbar",			2);
	g_hScripts.SetValue("electric_guitar",	3);
	g_hScripts.SetValue("fireaxe",			4);
	g_hScripts.SetValue("frying_pan",		5);
	g_hScripts.SetValue("golfclub",			6);
	g_hScripts.SetValue("katana",			7);
	g_hScripts.SetValue("knife",			8);
	g_hScripts.SetValue("machete",			9);
	g_hScripts.SetValue("tonfa",			10);
	g_hScripts.SetValue("pitchfork",		11);
	g_hScripts.SetValue("shovel",			12);
	// g_hScripts.SetValue("riotshield",		13); // Uncommenting? Increase MAX_MELEE at top of plugin by 1, change unknown cvar below from index [13] to [14] and uncomment [13] cvar.

	// CVARS
	g_hCvarAllow = CreateConVar(		"l4d2_melee_range_allow",					"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(		"l4d2_melee_range_modes",					"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(		"l4d2_melee_range_modes_off",				"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(		"l4d2_melee_range_modes_tog",				"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_melee_range_version",					PLUGIN_VERSION,	"Melee Range plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_melee_range");

	g_hCvarMeleeRange = FindConVar("melee_range");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarMeleeRange.AddChangeHook(ConVarChanged_Cvars);



	// =========================
	// COMMAND
	// =========================
	RegAdminCmd("sm_melee_range_reload", CmdReload, ADMFLAG_ROOT, "Reloads the Melee Weapon Range data config.");
	RegAdminCmd("sm_melee_range_set", CmdRangeSet, ADMFLAG_ROOT, "Usage: sm_melee_range_set <melee script name - must exist in the config> <range>. Set the melee range (does not update the config).");
	RegAdminCmd("sm_melee_range", CmdRange, ADMFLAG_ROOT, "Usage: sm_melee_range <#userid|name> <range or 0 to reset>.");

	g_hScripts = new StringMap();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapEnd()
{
	g_bMapStarted = false;

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_iClientRange[i] = 0;
	}
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
	g_iStockRange = g_hCvarMeleeRange.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		if( !DHookEnableDetour(g_hDetour, false, TestMeleeSwingCollisionPre) )
			SetFailState("Failed to detour pre \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");

		if( !DHookEnableDetour(g_hDetour, true, TestMeleeSwingCollisionPost) )
			SetFailState("Failed to detour post \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		if( !DHookDisableDetour(g_hDetour, false, TestMeleeSwingCollisionPre) )
			SetFailState("Failed to disable detour pre \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");

		if( !DHookDisableDetour(g_hDetour, true, TestMeleeSwingCollisionPost) )
			SetFailState("Failed to disable detour post \"CTerrorMeleeWeapon::TestMeleeSwingCollision\".");
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
//					CONFIG
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
	RequestFrame(OnFrameStart); // Melee weapon IDs are not valid from "Left4DHooks" until 1 frame after OnMapStart()
}

void OnFrameStart()
{
	LoadData();
}

Action CmdRange(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "Usage: sm_melee_range <#userid|name> <range or 0 to reset>");
		return Plugin_Handled;
	}

	char arg1[32], arg2[8];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		0,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target, range = StringToInt(arg2);
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		g_iClientRange[target] = range;
		ReplyToCommand(client, "[MeleeRange] Set %d on %N", range, target);
	}

	return Plugin_Handled;
}

Action CmdRangeSet(int client, int args)
{
	if( args != 2 )
	{
		ReplyToCommand(client, "Usage: sm_melee_range_set <melee script name - must exist in the config> <range>");
		return Plugin_Handled;
	}

	int range;
	char sTemp[32];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	if( g_hScripts.GetValue(sTemp, range) )
	{
		char sValue[8];
		GetCmdArg(2, sValue, sizeof(sValue));

		g_hScripts.SetValue(sTemp, StringToInt(sValue));
		ReplyToCommand(client, "[Melee Range] Set \"%s\" range to \"%d\"", sTemp, StringToInt(sValue));
		return Plugin_Handled;
	}

	ReplyToCommand(client, "[Melee Range] Cannot find the \"%s\" melee script from the config.", sTemp);

	return Plugin_Handled;
}

Action CmdReload(int client, int args)
{
	LoadData();
	ReplyToCommand(client, "[Melee Range] Reloaded the config file.");
	return Plugin_Handled;
}

void LoadData()
{
	delete g_hScripts;
	g_hScripts = new StringMap();

	// Verify config exists
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( FileExists(sPath) == false )
	{
		return;
	}

	// Load config
	KeyValues hFile = new KeyValues("melee_range");
	if( !hFile.ImportFromFile(sPath) )
	{
		LogError("Failed to load data config: \"%s\"", CONFIG_DATA);
		delete hFile;
		return;
	}

	// Grab entries
	char script[64];

	hFile.GotoFirstSubKey(true);
	do
	{
		// Get melee name from config
		hFile.GetSectionName(script, sizeof(script));

		// Get "time" value
		g_hScripts.SetValue(script, hFile.GetNum("range", 70));
	}
	while( hFile.GotoNextKey(false) );

	delete hFile;
}



// ====================================================================================================
//					DETOURS
// ====================================================================================================
MRESReturn TestMeleeSwingCollisionPre(int pThis, Handle hReturn)
{
	if( IsValidEntity(pThis) )
	{
		// Custom range for owner
		int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

		if( client && g_iClientRange[client] )
		{
			g_hCvarMeleeRange.SetInt(g_iClientRange[client]);
			return MRES_Ignored;
		}

		static char sTemp[32];
		GetEntPropString(pThis, Prop_Data, "m_strMapSetScriptName", sTemp, sizeof(sTemp));

		// Fix melee weapons that don't have a script name
		if( sTemp[0] == 0 )
		{
			GetEntPropString(pThis, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			if( strncmp(sTemp[23], "bat", 3) == 0 ) sTemp = "bat";
			else if( strncmp(sTemp[23], "cri", 3) == 0 ) sTemp = "cricket_bat";
			else if( strncmp(sTemp[23], "cro", 3) == 0 ) sTemp = "crowbar";
			else if( strncmp(sTemp[23], "ele", 3) == 0 ) sTemp = "electric_guitar";
			else if( strncmp(sTemp[23], "fir", 3) == 0 ) sTemp = "fireaxe";
			else if( strncmp(sTemp[23], "fry", 3) == 0 ) sTemp = "frying_pan";
			else if( strncmp(sTemp[23], "gol", 3) == 0 ) sTemp = "golfclub";
			else if( strncmp(sTemp[23], "kat", 3) == 0 ) sTemp = "katana";
			else if( strncmp(sTemp[23], "kni", 3) == 0 ) sTemp = "knife";
			else if( strncmp(sTemp[23], "mac", 3) == 0 ) sTemp = "machete";
			else if( strncmp(sTemp[23], "ton", 3) == 0 ) sTemp = "tonfa";
			else if( strncmp(sTemp[23], "pit", 3) == 0 ) sTemp = "pitchfork";
			else if( strncmp(sTemp[23], "sho", 3) == 0 ) sTemp = "shovel";

			if( sTemp[0] ) SetEntPropString(pThis, Prop_Data, "m_strMapSetScriptName", sTemp);
		}

		int range;
		if( g_hScripts.GetValue(sTemp, range) || g_hScripts.GetValue("unknown", range) )
		{
			g_hCvarMeleeRange.SetInt(range);
		}
	}

	return MRES_Ignored;
}

MRESReturn TestMeleeSwingCollisionPost(int pThis, Handle hReturn)
{
	g_hCvarMeleeRange.SetInt(g_iStockRange);
	return MRES_Ignored;
}