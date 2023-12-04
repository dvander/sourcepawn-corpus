/*
*	Vote Mode
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



#define PLUGIN_VERSION		"2.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Vote Mode
*	Author	:	SilverShot
*	Descrp	:	Allows players to vote change the game mode. Admins can force change the game mode.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=179279
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.2 (25-Sep-2023)
	- Added 0.1 second delay between changing mode and switching map, to allow other plugins to detect mode change. Thanks to "Alex101192" for reporting.
	- Changed cvar "l4d_votemode_restart" to remove round restart method. Will default to changelevel method.
	- This is to prevent errors with various mutations that need a full map change in order to work correctly.
	- Update is from February 2023 but never published. Thanks to "Alex101192" for testing back then.

2.1 (07-Dec-2022)
	- Potentially fixed cvar "l4d_votemode_reset" resetting the gamemode when connecting from a lobby. Thanks to "Mika Misori" for reporting.

2.0 (05-Dec-2022)
	- Re-wrote major parts of the plugin to use structs for storing the data. No more limitation on number mutations.
	- Now correctly changes map on gamemodes that are only playable on selected maps. See the "l4d_votemode.cfg" file and "holdout" for more details.
	- Added command "sm_votemode_config" to generate a config file with all the available modes and mutations.
	- Added sounds when voting begins, passes and fails.
	- Added Simplified Chinese (zho) and Traditional Chinese (chi) translations. Thanks to "NoroHime" for providing.
	- Updated "l4d_votemode.cfg" to support some new official gamemodes and those that only work on a select few maps.
	- Updated "l4d_votemode_all.cfg" to support new modes from "Rayman1103's Mutation Mod".
	- Thanks to "Rayman1103" for showing where the gamemodes set specific map.
	- Thanks to "Alex101192" for reporting and lots of help testing.

1.7 (15-Jan-2022)
	- Added cvar "l4d_votemode_reset" to reset the gamemode when the server is empty. Requested by "NoroHime".

1.6 (04-Dec-2021)
	- Changes to fix warnings when compiling on SourceMod 1.11.

1.5 (16-Jun-2020)
	- Added Hungarian translations to the "translations.zip", thanks to "KasperH" for providing.
	- Now sets Normal difficulty anytime the plugin changes to a new gamemode. Thanks to "Alex101192" for reporting.

1.4 (10-May-2020)
	- Fixed potential issues with some translations not being displayed in the right language.
	- Various changes to tidy up code.

1.3 (30-Apr-2020)
	- Optionally uses the "Info Editor" plugin (requires version 1.8 or newer) to detect and change to valid Survival/Scavenge maps.
	- This method will also set the difficulty to Normal when switching to Survival/Scavenge maps.
	- This method only works when l4d_votemode_restart is set to 1.
	- Thanks to "Alex101192" for testing.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1 (10-May-2012)
	- Fixed votes potentially not displaying to everyone.

1.0 (28-Feb-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "N3wton" for "[L4D2] Pause" - Used to make the voting system.
	https://forums.alliedmods.net/showthread.php?t=137765

*	Thanks to "chundo" for "Custom Votes" - Used to load the config via SMC Parser.
	https://forums.alliedmods.net/showthread.php?p=633808

*	Thanks to "Rayman1103" for the "All Mutations Unlocked" addon.
	https://forums.steampowered.com/forums/showthread.php?t=1529433

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define CHAT_TAG				"\x04[\x01Vote Mode\x04]\x01 "
#define CONFIG_VOTEMODE			"data/l4d_votemode.cfg"
#define CONFIG_GENERATE			"data/l4d_votemode_GENERATED.cfg"
#define SOUND_START				"ui/beep_synthtone01.wav"
#define SOUND_PASS				"ui/menu_enter05.wav"
#define SOUND_FAIL				"ui/beep_error01.wav"
#define MAX_STRING_LEN			64


// Cvar handles and variables
ConVar g_hCvarAdmin, g_hCvarMenu, g_hCvarReset, g_hCvarRestart, g_hCvarTimeout;
int g_iCvarAdmin, g_iCvarRestart;
float g_fCvarTimeout;
char g_sCvarReset[MAX_STRING_LEN];
bool g_bMapStarted;
Handle g_hTimerResetMap;

// Other handles
ConVar g_hMPGameMode, g_hRestartGame;
TopMenu g_hAdminMenu;

// Voting variables
bool g_bAllVoted, g_bVoteInProgress;
int g_iNoCount, g_iVoters, g_iYesCount;

// Distinguishes mode selected and if admin forced
bool g_bAdmin[MAXPLAYERS+1];
int g_iChangeModeTo, g_iSelected[MAXPLAYERS+1];

// Store where the different titles are within the commands list
int g_iModesCount, g_iConfigLevel, g_iModeIndex[64];

// Valid maps for modes
StringMap g_smModes;
char g_sMap[MAX_STRING_LEN];

// Used to restart the round after loading a new map, to fix issues with some modes not loading correctly
int g_iPlayerSpawn, g_iRoundStart;
bool g_bRestart;

// Used to find valid maps when switching mode (method A)
native void InfoEditor_GetString(int pThis, const char[] keyname, char[] dest, int destLen);
bool g_bInfoEditor;

// Stores the "l4d_votemode.cfg" data - used for menus and everything else
enum struct ConfigData
{
	ArrayList alMapsModes;
	char sCommand[MAX_STRING_LEN];		// mp_gamemode mutation command
	char sDisplay[MAX_STRING_LEN];		// Display name of mutation when voting
	char sMenu[MAX_STRING_LEN];			// Menu title for mode
	char sName[MAX_STRING_LEN];			// "Name" from "missions.txt"
	char sType[MAX_STRING_LEN];			// "Name" split from "l4d_votemode.cfg"
	bool bRestart;						// Restart after loading
	int iSection;						// Section Index
}

// Stores the "mission.txt" data (base modes) - to find valid maps when switching mode (method B)
StringMap g_smMissionData;
enum struct MissionData
{
	ArrayList alMaps;
	ArrayList alName;

	void Create()
	{
		if( this.alName == null )
		{
			this.alMaps = new ArrayList(ByteCountToCells(MAX_STRING_LEN));
			this.alName = new ArrayList(ByteCountToCells(MAX_STRING_LEN));
		}
	}

	void Add(const char[] sMaps, const char[] sName)
	{
		this.alMaps.PushString(sMaps);
		this.alName.PushString(sName);
	}
}

// Data storage
ConfigData g_hConfigData;				// Temporary store when loading the "l4d_votemode.cfg" file from LoadConfig
ArrayList g_alConfigSections;			// Section names, used for first menu entry titles

StringMap g_smConfigData;				// Using an index as key, stores the "l4d_votemode.cfg" data
StringMap g_smConfigIndex;				// Using the game mode as key, stores the related index used in g_smConfigData
StringMapSnapshot g_snapConfigIndex;	// A snapshot of the g_smConfigIndex StringMap to find a game mode by index



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Vote Mode",
	author = "SilverShot",
	description = "Allows players to vote change the game mode. Admins can force change the game mode.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=179279"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("InfoEditor_GetString");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "info_editor") == 0 )
		g_bInfoEditor = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "info_editor") == 0 )
		g_bInfoEditor = false;
	else if( strcmp(name, "adminmenu") == 0 )
		g_hAdminMenu = null;
}

public void OnPluginStart()
{
	// Game Cvars
	if( (g_hMPGameMode = FindConVar("mp_gamemode")) == null )
		SetFailState("Failed to find convar handle 'mp_gamemode'. Cannot load plugin.");

	if( (g_hRestartGame = FindConVar("mp_restartgame")) == null )
		SetFailState("Failed to find convar handle 'mp_restartgame'. Cannot load plugin.");

	// Translations
	LoadTranslations("votemode.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	// Plugin cvars
	g_hCvarMenu =		CreateConVar(	"l4d_votemode_admin_menu",		"1", 			"0=No, 1=Display in the Server Commands of admin menu.", CVAR_FLAGS );
	g_hCvarAdmin =		CreateConVar(	"l4d_votemode_admin_flag",		"", 			"Players with these flags can vote to change the game mode.", CVAR_FLAGS );
	g_hCvarReset =		CreateConVar(	"l4d_votemode_reset",			"",				"Specify the gamemode to reset when all players have disconnected. Empty string = Don't reset.", CVAR_FLAGS );
	g_hCvarRestart =	CreateConVar(	"l4d_votemode_restart",			"1",			"0=No restart, 1=With 'changelevel' command.", CVAR_FLAGS );
	g_hCvarTimeout =	CreateConVar(	"l4d_votemode_timeout",			"30.0",			"How long the vote should be visible.", CVAR_FLAGS, true, 5.0, true, 60.0 );
	CreateConVar(						"l4d_votemode_version",			PLUGIN_VERSION, "Vote Mode plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, 				"l4d_votemode");

	GetCvars();
	g_hCvarAdmin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReset.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRestart.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeout.AddChangeHook(ConVarChanged_Cvars);

	// Commands
	RegAdminCmd(	"sm_vetomode",				CommandVeto,	ADMFLAG_ROOT,	"Allows admins to veto a current vote.");
	RegAdminCmd(	"sm_passmode",				CommandPass,	ADMFLAG_ROOT,	"Allows admins to pass a current vote.");
	RegAdminCmd(	"sm_forcemode",				CommandForce,	ADMFLAG_ROOT,	"Allows admins to force the game into a different mode.");
	RegAdminCmd(	"sm_votemode_config",		CommandConfig,	ADMFLAG_ROOT,	"Generates the config saved to \"" ... CONFIG_GENERATE ... "\" based on available game modes.");
	RegConsoleCmd(	"sm_votemode",				CommandVote,					"Displays a menu to vote the game into a different mode.");

	// Admin meun
	Handle topmenu = GetAdminTopMenu();
	if( LibraryExists("adminmenu") && (topmenu != null) )
		OnAdminMenuReady(topmenu);

	// Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);

	// Load data
	g_smConfigData = new StringMap();
	g_smConfigIndex = new StringMap();
	g_smMissionData = new StringMap();

	LoadConfig();
	LoadMissions();

	// Debug stuff
	// ReadModes();
	// ListModes(); // Debug print all modes and maps
	// ListModes2(); // Debug print all modes and maps
}



// ====================================================================================================
//					VARIOUS FUNCTIONS USED TO BUILD AND DEBUG VERSION 2.0
// ====================================================================================================
stock void ReadModes()
{
	char sFile[PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	char sName[PLATFORM_MAX_PATH];

	DirectoryListing hDir;
	KeyValues hFile;
	FileType type;

	sPath = "modes";

	// Open mission directory
	// if( DirExists(sPath, true) ) // Fails for some reason
	{
		hDir = OpenDirectory(sPath, true);

		if( hDir )
		{
			// Loop files
			while( ReadDirEntry(hDir, sFile, sizeof(sFile), type) )
			{
				if( type == FileType_File )
				{
					Format(sPath, sizeof(sPath), "modes/%s", sFile);

					// Open mission file and jump to "modes" section
					hFile = new KeyValues("mission");
					if( hFile.ImportFromFile(sPath) )
					{
						KvGetString(hFile, "base", sPath, sizeof(sPath));
						KvGetString(hFile, "DisplayTitle", sName, sizeof(sName));
						ReplaceString(sFile, sizeof(sFile), ".txt", "");
						ReplaceString(sFile, sizeof(sFile), "modes/", "");
						PrintToServer("%s\t\t\"%s\"\t\t\"%s\"", sPath, sName, sFile);
					}

					delete hFile;
				}
			}
		}
	}
}

stock void ListModes()
{
	PrintToServer("");
	PrintToServer("");
	PrintToServer("READ MODES::");
	PrintToServer("");

	char sMaps[MAX_STRING_LEN];
	char sName[MAX_STRING_LEN];
	char sMode[MAX_STRING_LEN];

	StringMapSnapshot smSnap = g_smMissionData.Snapshot();
	MissionData data;

	int total;
	int lenMaps;
	int lenData = smSnap.Length;

	PrintToServer("MODES %d", lenData);
	PrintToServer("");

	// Loop through modes
	for( int i = 0; i < lenData; i++ )
	{
		smSnap.GetKey(i, sMode, sizeof(sMode));
		g_smMissionData.GetArray(sMode, data, sizeof(data));

		lenMaps = data.alMaps.Length;
		PrintToServer("MODE (%d) [%s]", lenMaps, sMode);

		for( int x = 0; x < lenMaps; x++ )
		{
			data.alMaps.GetString(x, sMaps, sizeof(sMaps));
			data.alName.GetString(x, sName, sizeof(sName));
			// PrintToServer(".. Map [%s] Name [%s]", sMaps, sName);
		}

		total += lenMaps;
	}

	PrintToServer("Total: %d", total);

	delete smSnap;
}

stock void ListModes2()
{
	int total;
	ArrayList aList;
	char sModes[256];
	char sValue[256];
	PrintToServer("");
	PrintToServer("");
	PrintToServer("READ MODES::");
	PrintToServer("");

	StringMapSnapshot smSnap = g_smModes.Snapshot();

	int length = smSnap.Length;
	PrintToServer("MODES %d", length);
	PrintToServer("");

	// Loop through modes
	for( int i = 0; i < length; i++ )
	{
		smSnap.GetKey(i, sValue, sizeof(sValue));
		g_smModes.GetValue(sValue, aList);

		// Loop through game types
		int lenMaps = aList.Length;

		PrintToServer("MODE (%d) [%s]", lenMaps, sValue);

		for( int x = 0; x < lenMaps; x++ )
		{
			aList.GetString(x, sModes, sizeof(sModes));
			// PrintToServer(".. val [%s]", sModes);
		}

		total += lenMaps;
	}

	PrintToServer("Total: %d", total);

	delete smSnap;
}



// ====================================================================================================
//					ADD TO ADMIN MENU
// ====================================================================================================
public void OnAdminMenuReady(Handle topmenu)
{
	if( topmenu == g_hAdminMenu || g_hCvarMenu.BoolValue == false )
		return;

	g_hAdminMenu = view_as<TopMenu>(topmenu);

	TopMenuObject player_commands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	if( player_commands == INVALID_TOPMENUOBJECT ) return;

	AddToTopMenu(g_hAdminMenu, "sm_forcemode_menu", TopMenuObject_Item, Handle_Category, player_commands, "sm_forcemode_menu", ADMFLAG_GENERIC);
}

int Handle_Category(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "%T", "VoteMode_Force", param);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "VoteMode_Force", param);
		case TopMenuAction_SelectOption:
		{
			g_bAdmin[param] = true;
			VoteMenu_Select(param);
		}
	}

	return 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	char sTemp[16];
	g_hCvarAdmin.GetString(sTemp, sizeof(sTemp));
	g_iCvarAdmin = ReadFlagString(sTemp);
	g_hCvarReset.GetString(g_sCvarReset, sizeof(g_sCvarReset));
	g_iCvarRestart = g_hCvarRestart.IntValue;
	g_fCvarTimeout = g_hCvarTimeout.FloatValue;
}

public void OnClientDisconnect_Post(int client)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientConnected(i) && !IsFakeClient(i) )
		{
			return;
		}
	}

	if( g_sCvarReset[0] )
	{
		delete g_hTimerResetMap;
		g_hTimerResetMap = CreateTimer(1.0, TimerReset);
	}
}

Action TimerReset(Handle timer)
{
	g_hTimerResetMap = null;

	if( g_bMapStarted && g_sCvarReset[0] )
	{
		char sMap[MAX_STRING_LEN];
		g_hMPGameMode.GetString(sMap, sizeof(sMap));

		if( strcmp(sMap, g_sCvarReset) )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientConnected(i) && !IsFakeClient(i) )
				{
					return Plugin_Continue;
				}
			}

			g_hMPGameMode.SetString(g_sCvarReset);

			GetCurrentMap(sMap, sizeof(sMap));

			// ServerCommand("z_difficulty normal; changelevel %s", sMap);
			ServerCommand("z_difficulty normal");
			ServerExecute();

			strcopy(g_sMap, sizeof(g_sMap), sMap);
			CreateTimer(0.1, TimerChangeLevel);
		}
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
	delete g_hTimerResetMap;

	g_bMapStarted = true;

	PrecacheSound(SOUND_START);
	PrecacheSound(SOUND_PASS);
	PrecacheSound(SOUND_FAIL);
}

public void OnMapEnd()
{
	delete g_hTimerResetMap;

	g_bMapStarted = false;
	g_iPlayerSpawn = 0;
	g_iRoundStart = 0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		ShouldRestart();
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		ShouldRestart();
	g_iPlayerSpawn = 1;
}

void ShouldRestart()
{
	if( g_bRestart )
	{
		g_bRestart = false;

		CreateTimer(0.1, TimerRestartGame);
	}
}



// ====================================================================================================
//					LOAD CONFIG
// ====================================================================================================
void LoadConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_VOTEMODE);

	if( !FileExists(sPath) )
	{
		SetFailState("Error: Cannot find the VoteMode config '%s'", sPath);
		return;
	}

	delete g_smConfigData;
	g_smConfigData = new StringMap();

	delete g_smConfigIndex;
	g_smConfigIndex = new StringMap();

	delete g_alConfigSections;
	g_alConfigSections = new ArrayList(ByteCountToCells(MAX_STRING_LEN));

	ParseConfigFile(sPath);
}

bool ParseConfigFile(const char[] file)
{
	// Load parser and set hook functions
	SMCParser parser = new SMCParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End); // Had to replace the methodmap for this call because it was flagged and blocked when uploading to AlliedMods.

	// Log errors detected in config
	char error[128];
	int line = 0, col = 0;
	SMCError result = parser.ParseFile(file, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		SetFailState("%s on line %d, col %d of %s [%d]", error, line, col, file, result);
	}

	delete parser;
	return (result == SMCError_Okay);
}

SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes)
{
	// Section strings, used for the first menu ModeTitles
	g_iConfigLevel++;
	if( g_iConfigLevel > 1 )
	{
		ConfigData data;
		g_hConfigData = data;

		g_hConfigData.iSection = g_iConfigLevel - 2;

		g_alConfigSections.PushString(section);

		g_iModeIndex[g_iConfigLevel - 2] = g_iModesCount;
	}
	return SMCParse_Continue;
}

SMCResult Config_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	static char sTemp[MAX_STRING_LEN];
	strcopy(sTemp, sizeof(sTemp), value);

	// Split "name|restart"
	int bar = StrContains(sTemp, "|");
	if( bar != -1 )
	{
		sTemp[bar] = 0;
		g_hConfigData.bRestart = StringToInt(sTemp[bar + 1]) == 1;
	}

	// Split "mode:name"
	int pos = StrContains(sTemp, ":");
	if( pos != -1 )
	{
		sTemp[pos] = 0;

		strcopy(g_hConfigData.sName, sizeof(g_hConfigData.sName), sTemp[pos + 1]);
	}

	// Key and value strings, used for the Mode Names and Mode Commands
	strcopy(g_hConfigData.sDisplay, sizeof(g_hConfigData.sDisplay), key);
	strcopy(g_hConfigData.sCommand, sizeof(g_hConfigData.sCommand), sTemp);

	g_smConfigIndex.SetValue(sTemp, g_iModesCount);

	IntToString(g_iModesCount, sTemp, sizeof(sTemp));
	g_smConfigData.SetArray(sTemp, g_hConfigData, sizeof(g_hConfigData));

	g_iModesCount++;
	return SMCParse_Continue;
}

SMCResult Config_EndSection(Handle parser)
{
	// Config finished loading
	g_iModeIndex[g_iConfigLevel -1] = g_iModesCount;
	return SMCParse_Continue;
}

void Config_End(Handle parser, bool halted, bool failed)
{
	g_snapConfigIndex = g_smConfigIndex.Snapshot();

	if( failed )
		SetFailState("Error: Cannot load the VoteMode config.");
}



// ====================================================================================================
//					LOAD MISSION FILES
// ====================================================================================================
void LoadMissions()
{
	// Load mission.txt files
	// This is used to identify which map is valid for the mode voted
	g_smModes = new StringMap();

	char sPath[PLATFORM_MAX_PATH];
	char sModes[256];
	char sValue[256];
	char sName[256];
	DirectoryListing hDir;
	FileType type;
	KeyValues hFile;
	bool loopKeys;
	int loopVals;

	sPath = "missions";

	// Open mission directory
	hDir = OpenDirectory(sPath, true);

	if( hDir )
	{
		// Loop files
		while( ReadDirEntry(hDir, sPath, sizeof(sPath), type) )
		{
			if( type == FileType_File )
			{
				if( strcmp(sPath, "credits.txt") ) // Ignore this file
				{
					Format(sPath, sizeof(sPath), "missions/%s", sPath);

					// Open mission file and jump to "modes" section
					hFile = new KeyValues("mission");
					if( hFile.ImportFromFile(sPath) )
					{
						KvGetString(hFile, "Name", sName, sizeof(sName));

						if( KvJumpToKey(hFile, "modes") )
						{
							// Read mode keys
							if( KvGotoFirstSubKey(hFile, true) )
							{
								// Loop mode keys
								loopKeys = true;
								while( loopKeys )
								{
									KvGetSectionName(hFile, sModes, sizeof(sModes));

									// Create or read array list of maps for the specific mode
									MissionData data;
									if( g_smMissionData.GetArray(sModes, data, sizeof(data)) == false )
									{
										data.Create();
									}

									// Loop value keys
									loopVals = 1;
									while( loopVals )
									{
										// Mode index
										IntToString(loopVals, sValue, sizeof(sValue));
										if( KvJumpToKey(hFile, sValue) )
										{
											// Get map name
											KvGetString(hFile, "map", sValue, sizeof(sValue));
											if( sValue[0] )
											{
												// Add map name with mode title
												data.Add(sValue, sName);

												loopVals++;
												KvGoBack(hFile);
											}
										}
										else
										{
											loopVals = 0;
											break;
										}
									}

									// Save
									g_smMissionData.SetArray(sModes, data, sizeof(data));

									// Move to next
									if( KvGotoNextKey(hFile, true) == false )
									{
										loopKeys = false;
										KvRewind(hFile);
										KvRewind(hFile);
										break;
									}
								}
							}
						}
					}

					delete hFile;
				}
			}
		}
	}

	delete hDir;
}



// ====================================================================================================
//					COMMAND - sm_votemode_config - to generate config
// ====================================================================================================
#define CHAR_SPLIT '@' // Character used to combine and split ArrayList string, should not appear in any mutation titles

Action CommandConfig(int client, int args)
{
	ReplyToCommand(client, "[VoteMode] Generating \"" ... CONFIG_GENERATE ... "\" config, please wait...");
	float fTime = GetEngineTime();

	char sFile[PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	char sPlay[4];
	char sBase[MAX_STRING_LEN];
	char sName[MAX_STRING_LEN];
	char sLast[MAX_STRING_LEN];
	char sTemp[256];
	ArrayList alModes;

	DirectoryListing hDir;
	KeyValues hFile;
	FileType type;
	File hCfg;



	// Ignore these modes read from the game files and from the Mutation Mod, they are part of the base game and added into the hardcoded list of modes when writing the config
	StringMap smIgnored = new StringMap();
	smIgnored.SetValue("dash", true);
	smIgnored.SetValue("gunbrain", true);
	smIgnored.SetValue("holdout", true);
	smIgnored.SetValue("l4d1coop", true);
	smIgnored.SetValue("l4d1survival", true);
	smIgnored.SetValue("l4d1vs", true);
	smIgnored.SetValue("rocketdude", true);
	smIgnored.SetValue("shootzones", true);
	smIgnored.SetValue("tankrun", true);



	// Array to store all modes, to sort list for writing to config
	alModes = new ArrayList(ByteCountToCells(256));

	// Folder to open and read files
	sPath = "modes";



	// Open mission directory
	// if( DirExists(sPath, true) ) // Fails for some reason
	{
		hDir = OpenDirectory(sPath, true);

		if( hDir )
		{
			// Loop files
			while( ReadDirEntry(hDir, sFile, sizeof(sFile), type) )
			{
				if( type == FileType_File )
				{
					Format(sPath, sizeof(sPath), "modes/%s", sFile);

					// Open mission file and jump to "modes" section
					hFile = new KeyValues("mission");
					if( hFile.ImportFromFile(sPath) )
					{
						KvGetString(hFile, "base", sBase, sizeof(sBase));
						KvGetString(hFile, "DisplayTitle", sName, sizeof(sName));
						KvGetString(hFile, "maxplayers", sPlay, sizeof(sPlay));
						// KvGetString(hFile, "Image", sTemp, sizeof(sTemp)); // To match "vgui/mutation_mod" and identify if the mode is from "Rayman1103's Mutation Mod" and split into different categories. Currently unused.
						ReplaceString(sFile, sizeof(sFile), ".txt", "");
						ReplaceString(sFile, sizeof(sFile), "modes/", "");

						if( StringToInt(sPlay) >= 4 && smIgnored.ContainsKey(sFile) == false )
						{
							Format(sTemp, sizeof(sTemp), "%s" ... CHAR_SPLIT ... "%s" ... CHAR_SPLIT ... "%s", sBase, sName, sFile);
							alModes.PushString(sTemp);
						}
					}

					delete hFile;
				}
			}
		}
	}



	// Create file and add default game modes
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_GENERATE);
	hCfg = OpenFile(sPath, "w");
	if( hCfg == null )
	{
		ThrowError("Cannot open file for writing: \"%s\"", sPath);
	}

	hCfg.WriteLine("\"gamemodes\"");
	hCfg.WriteLine("{");
	hCfg.WriteLine("	\"Coop\"");
	hCfg.WriteLine("	{");
	hCfg.WriteLine("		\"Coop\"						\"coop\"");
	hCfg.WriteLine("		\"Realism\"					\"realism\"");
	hCfg.WriteLine("		\"Bleed Out\"					\"mutation3\"");
	hCfg.WriteLine("		\"Chainsaw Massacre\"			\"mutation7\"");
	hCfg.WriteLine("		\"Four Swordsmen\"			\"mutation5\"");
	hCfg.WriteLine("		\"Gib Fest\"					\"mutation14\"");
	hCfg.WriteLine("		\"Hard Eight\"				\"mutation4\"");
	hCfg.WriteLine("		\"Healing Gnome\"				\"mutation20\"");
	hCfg.WriteLine("		\"Headshot\"					\"mutation2\"");
	hCfg.WriteLine("		\"Hunting Party\"				\"mutation16\"");
	hCfg.WriteLine("		\"Ironman\"					\"mutation8\"");
	hCfg.WriteLine("		\"Last Gnome On Earth\"		\"mutation9\"");
	hCfg.WriteLine("		\"Room For One\"				\"mutation10\"");
	hCfg.WriteLine("		\"Death's Door\"				\"community5\"");
	hCfg.WriteLine("		\"Special Delivery\"			\"community1\"");
	hCfg.WriteLine("		\"Flu Season\"				\"community2\"");
	hCfg.WriteLine("		\"GunBrain\"					\"gunbrain\"");
	hCfg.WriteLine("		\"L4D1 Co-op\"				\"l4d1coop\"");
	hCfg.WriteLine("		\"RocketDude\"				\"rocketdude\"");
	hCfg.WriteLine("		\"Tank Run\"					\"tankrun\"");
	hCfg.WriteLine("	}");
	hCfg.WriteLine("");
	hCfg.WriteLine("	\"Versus\"");
	hCfg.WriteLine("	{");
	hCfg.WriteLine("		\"Versus\"					\"versus\"");
	hCfg.WriteLine("		\"Team Versus\"				\"teamversus\"");
	hCfg.WriteLine("		\"Confogl\"					\"community6\"");
	hCfg.WriteLine("		\"Healthpackalypse!\"			\"mutation11\"");
	hCfg.WriteLine("		\"Realism Versus\"			\"mutation12\"");
	hCfg.WriteLine("		\"Taaannnkk!\"				\"mutation19\"");
	hCfg.WriteLine("		\"Versus Survival\"			\"mutation15\"");
	hCfg.WriteLine("		\"Versus Bleed Out\"			\"mutation18\"");
	hCfg.WriteLine("		\"Riding My Survivor\"		\"community3\"");
	hCfg.WriteLine("		\"L4D1 Versus\"				\"l4d1vs\"");
	hCfg.WriteLine("	}");
	hCfg.WriteLine("");
	hCfg.WriteLine("	\"Scavenge\"");
	hCfg.WriteLine("	{");
	hCfg.WriteLine("		\"Scavenge\"					\"scavenge\"");
	hCfg.WriteLine("		\"Team Scavenge\"				\"teamscavenge\"");
	hCfg.WriteLine("		\"Follow the liter\"			\"mutation13\"");
	hCfg.WriteLine("	}");
	hCfg.WriteLine("");
	hCfg.WriteLine("	\"Survival\"");
	hCfg.WriteLine("	{");
	hCfg.WriteLine("		\"Survival\"					\"survival\"");
	hCfg.WriteLine("		\"Nightmare\"					\"community4\"");
	hCfg.WriteLine("		 \"L4D1 Survival\"			\"l4d1survival\"");
	hCfg.WriteLine("	}");
	hCfg.WriteLine("");
	hCfg.WriteLine("	\"Map Specific Modes\"");
	hCfg.WriteLine("	{");
	hCfg.WriteLine("		// When a game mode only supports a few maps, we can use the \":\" char to determine which config the mode is from, allowing the plugin to select the valid maps");
	hCfg.WriteLine("		// Format: \"gamemode:name|restart\" - the name comes from the \"mission.txt\" file \"name\" key.");
	hCfg.WriteLine("		// Adding \"|1\" to the end will determine if the first round should be restarted after changing to the new game mode.");
	hCfg.WriteLine("		// For example: Inside \"missions/holdoutchallenge.txt\" the \"Name\" key value is \"HoldoutChallenge\" which is matched with the value after \":\" here:");
	hCfg.WriteLine("		\"Holdout Challenge (Hard Rain / Swamp Fever)\"		\"holdout:HoldoutChallenge|1\"");
	hCfg.WriteLine("		\"Holdout Training (Death Toll)\"						\"holdout:HoldoutTraining|1\"");
	hCfg.WriteLine("		\"Parish Dash\"										\"dash:parishdash|1\"");
	hCfg.WriteLine("		\"Carnival Shoot Zones\"								\"shootzones:shootzones|1\"");
	hCfg.WriteLine("		\"Wave (Hard Rain)\"									\"wave:Wave4\"");
	hCfg.WriteLine("		\"Wave (No Mercy)\"									\"wave:Wave8\"");



	// Sort, and read
	alModes.Sort(Sort_Ascending, Sort_String);

	int pos;
	int length = alModes.Length;

	if( length )
	{
		for( int i = 0; i < length; i++ )
		{
			alModes.GetString(i, sTemp, sizeof(sTemp));

			pos = FindCharInString(sTemp, CHAR_SPLIT, true);
			strcopy(sFile, sizeof(sFile), sTemp[pos + 1]);
			sTemp[pos] = 0;

			pos = FindCharInString(sTemp, CHAR_SPLIT, true);
			strcopy(sName, sizeof(sName), sTemp[pos + 1]);
			sTemp[pos] = 0;

			strcopy(sBase, sizeof(sBase), sTemp);

			if( strcmp(sLast, sBase) )
			{
				strcopy(sLast, sizeof(sLast), sBase);
				sBase[0] = CharToUpper(sBase[0]);
				hCfg.WriteLine("\t}");
				hCfg.WriteLine("");
				hCfg.WriteLine("\t\"Mutation Mod - %s\"", sBase);
				hCfg.WriteLine("\t{");
				sBase[0] = CharToLower(sBase[0]);
			}

			hCfg.WriteLine("\t\t\"%s\"\t\"%s\"", sName, sFile);
		}

		hCfg.WriteLine("\t}");
	}
	else
	{
		hCfg.WriteLine("\t}");
	}

	hCfg.WriteLine("}");

	delete hCfg;

	ReplyToCommand(client, "[VoteMode] Saved \"" ... CONFIG_GENERATE ... "\" config in %f seconds.", GetEngineTime() - fTime);

	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
Action CommandVeto(int client, int args)
{
	if( g_bAllVoted == false && g_bVoteInProgress == true )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				PrintToChat(i, "%s%T", CHAT_TAG, "VoteMode_Veto", client);
			}
		}
	}

	g_bAllVoted = true;
	g_bVoteInProgress = false;
	return Plugin_Handled;
}

Action CommandPass(int client, int args)
{
	if( g_bAllVoted == false && g_bVoteInProgress == true )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				PrintToChat(i, "%s%T", CHAT_TAG, "VoteMode_Pass", client);
			}
		}

		g_bAllVoted = true;
		g_bVoteInProgress = false;

		ChangeGameModeTo(g_iChangeModeTo);
	}
	return Plugin_Handled;
}

Action CommandForce(int client, int args)
{
	if( args == 1 )
	{
		char sTemp[MAX_STRING_LEN];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		// Change mode by index
		int len = strlen(sTemp);
		for( int i = 0; i < len; i++ )
		{
			// Validate integers only
			if( IsCharNumeric(sTemp[i]) )
			{
				// Whole string is integers only
				if( i == len - 1 )
				{
					// Index is within limit
					int index = StringToInt(sTemp);
					if( index < g_iModesCount )
					{
						int value;

						// Get gamemode by index
						for( int x = 0; x < g_iModesCount; x++ )
						{
							g_snapConfigIndex.GetKey(x, sTemp, sizeof(sTemp));
							g_smConfigIndex.GetValue(sTemp, value);

							if( value == index ) // Found
							{
								ChangeGameModeTo(index);
								return Plugin_Handled;
							}
						}
					}

					return Plugin_Handled;
				}
			}
			else
			{
				break;
			}
		}

		// Change mode by name
		if( g_smConfigIndex.ContainsKey(sTemp) )
		{
			int index;

			g_smConfigIndex.GetValue(sTemp, index);

			ChangeGameModeTo(index);
			return Plugin_Handled;
		}
	}

	g_bAdmin[client] = true;
	VoteMenu_Select(client);
	return Plugin_Handled;
}

Action CommandVote(int client, int args)
{
	// Admins only
	if( CheckCommandAccess(client, "", g_iCvarAdmin) == false )
	{
		PrintToChat(client, "%s%T", CHAT_TAG, "No Access", client);
		return Plugin_Handled;
	}

	// Don't allow multiple votes
	if( g_bVoteInProgress )
	{
		PrintToChat(client, "%s%T", CHAT_TAG, "VoteMode_InProgress", client);
		return Plugin_Handled;
	}

	// Start vote
	if( args == 1 )
	{
		char sTemp[MAX_STRING_LEN];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( g_smConfigIndex.ContainsKey(sTemp) )
		{
			int index;

			g_smConfigIndex.GetValue(sTemp, index);

			StartVote(client, index);
			return Plugin_Handled;
		}
	}

	g_bAdmin[client] = false;
	VoteMenu_Select(client);
	return Plugin_Handled;
}



// ====================================================================================================
//					DISPLAY MENU
// ====================================================================================================
void VoteMenu_Select(int client)
{
	Menu menu = new Menu(VoteMenuHandler_Select);
	if( g_bAdmin[client] )
		menu.SetTitle("%T", "VoteMode_Force", client);
	else
		menu.SetTitle("%T", "VoteMode_Vote", client);

	// Build menu
	char sTemp[MAX_STRING_LEN];
	int length = g_alConfigSections.Length;
	for( int i = 0; i < length; i++ )
	{
		g_alConfigSections.GetString(i, sTemp, sizeof(sTemp));
		menu.AddItem("", sTemp);
	}

	// Display menu
	if( g_bAdmin[client] )
		menu.ExitBackButton = true;
	else
		menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int VoteMenuHandler_Select(Menu menu, MenuAction action, int client, int param2)
{
	switch( action )
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack && g_bAdmin[client] && g_hAdminMenu != null )
				g_hAdminMenu.Display(client, TopMenuPosition_LastCategory); //TopMenuPosition_Start
		}
		case MenuAction_Select:
		{
			g_iSelected[client] = param2;
			VoteTwoMenu_Select(client, param2);
		}
	}

	return 0;
}

void VoteTwoMenu_Select(int client, int param2)
{
	Menu menu = new Menu(VoteMenuTwoMenu_Select);

	if( g_bAdmin[client] )
		menu.SetTitle("%T", "VoteMode_Force", client);
	else
		menu.SetTitle("%T", "VoteMode_Vote", client);

	// Build menu
	int param1 = g_iModeIndex[param2];
	param2 = g_iModeIndex[param2 + 1];

	char sTemp[4];
	ConfigData data;

	// Add all modes within the current section
	for( int i = param1; i < param2; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));
		g_smConfigData.GetArray(sTemp, data, sizeof(data));

		menu.AddItem("", data.sDisplay);
	}

	// Display menu
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int VoteMenuTwoMenu_Select(Menu menu, MenuAction action, int client, int param2)
{
	switch( action )
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if( param2 == MenuCancel_ExitBack )
				VoteMenu_Select(client);
		}
		case MenuAction_Select:
		{
			// Work out the mode command index
			int iSelected = g_iSelected[client];
			iSelected = g_iModeIndex[iSelected];
			iSelected += param2;

			// Admin force
			if( g_bAdmin[client] )
				ChangeGameModeTo(iSelected);
			else
				StartVote(client, iSelected);
		}
	}

	return 0;
}



// ====================================================================================================
//					VOTING STUFF
// ====================================================================================================
void StartVote(int client, int iMode)
{
	// Don't allow multiple votes
	if( g_bVoteInProgress )
	{
		PrintToChat(client, "%s%T", CHAT_TAG, "VoteMode_InProgress", client);
		return;
	}

	// Setup vote
	g_iYesCount = 0;
	g_iNoCount = 0;
	g_iVoters = 0;
	g_bAllVoted = false;
	g_bVoteInProgress = true;
	g_iChangeModeTo = iMode;

	char sTitle[128];
	Panel panel;

	// int index;
	char sTemp[4];
	ConfigData data;

	IntToString(iMode, sTemp, sizeof(sTemp));
	g_smConfigData.GetArray(sTemp, data, sizeof(data));

	// Display vote
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			panel = new Panel();
			SetGlobalTransTarget(i);

			Format(sTitle, sizeof(sTitle), "%t %s?", "VoteMode_Change", data.sDisplay);
			panel.SetTitle(sTitle);
			Format(sTitle, sizeof(sTitle), "%t", "Yes");
			panel.DrawItem(sTitle);
			Format(sTitle, sizeof(sTitle), "%t", "No");
			panel.DrawItem(sTitle);

			Format(sTitle, sizeof(sTitle), data.sDisplay);
			PrintToChat(i, "%s\x05%N \x01%t \x04%s?", CHAT_TAG, client, "VoteMode_Started", sTitle);

			panel.Send(i, VoteMenuHandler, RoundToCeil(g_fCvarTimeout));
			g_iVoters++;
			g_iNoCount++;
			delete panel;
		}
	}

	// Play sound
	EmitSoundToAll(SOUND_START);

	CreateTimer(g_fCvarTimeout + 1.0, Timer_VoteCheck);
}

int VoteMenuHandler(Menu menu, MenuAction action, int client, int choice)
{
	if( action == MenuAction_Select )
	{
		if( choice == 1 ) //yes
		{
			g_iNoCount--;
			g_iYesCount++;
			g_iVoters--;
		}
		else //No
			g_iVoters--;

		if( g_iVoters == 0 ) //Everyone Has Voted
			VoteCompleted();
	}

	return 0;
}

Action Timer_VoteCheck(Handle timer)
{
	if( !g_bAllVoted )
		VoteCompleted();

	return Plugin_Continue;
}

void VoteCompleted()
{
	if( g_bAllVoted == true && g_bVoteInProgress == false ) return;

	g_bAllVoted = true;
	g_bVoteInProgress = false;

	if( g_iYesCount > g_iNoCount )
	{
		// Play sound
		EmitSoundToAll(SOUND_PASS);

		// Notify
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SetGlobalTransTarget(i);
				PrintToChat(i, "%s'%t' %t", CHAT_TAG, "Yes", "VoteMode_Voted");
			}
		}

		ChangeGameModeTo(g_iChangeModeTo);
	}
	else
	{
		// Play sound
		EmitSoundToAll(SOUND_FAIL);

		// Notify
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SetGlobalTransTarget(i);
				PrintToChat(i, "%s'%t' %t", CHAT_TAG, "No", "VoteMode_Voted");
			}
		}
	}
}



// ====================================================================================================
//					SET GAME MODE
// ====================================================================================================
void ChangeGameModeTo(int iMode)
{
	if( g_iCvarRestart != 0 )
		CreateTimer(3.0, TimerChangeMode, iMode);

	char sTemp[4];
	ConfigData data;

	IntToString(iMode, sTemp, sizeof(sTemp));
	g_smConfigData.GetArray(sTemp, data, sizeof(data));

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SetGlobalTransTarget(i);
			PrintToChat(i, "%s%t \x04%s.", CHAT_TAG, "VoteMode_Changing", data.sDisplay);
			PrintToChat(i, "%s%t", CHAT_TAG, "VoteMode_Restarting");
		}
	}
}

Action TimerChangeMode(Handle timer, int index)
{
	// Change map
	bool change;
	char sMap[MAX_STRING_LEN];
	char sTemp[MAX_STRING_LEN];

	// Load config for mode
	IntToString(index, sTemp, sizeof(sTemp));

	ConfigData config;

	g_smConfigData.GetArray(sTemp, config, sizeof(config));



	// 1. Validate mode and maps from mission.txt files
	// Match current map "name" to other valid map names for the mode
	if( change == false )
	{
		ArrayList aList = new ArrayList(ByteCountToCells(MAX_STRING_LEN));
		int len;

		// Check if the mode from "l4d_votemode.cfg" is using the ":" separator to specify valid maps
		// Lookup current mode for valid maps
		if( config.sName[0] )
		{
			// Get list of modes
			MissionData mission;

			if( g_smMissionData.GetArray(config.sCommand, mission, sizeof(mission)) )
			{
				int lenMaps;

				lenMaps = mission.alMaps.Length;

				// Find current map, and get "name"
				for( int i = 0; i < lenMaps; i++ )
				{
					mission.alMaps.GetString(i, sMap, sizeof(sMap));
					mission.alName.GetString(i, sTemp, sizeof(sTemp));

					// Match the "name" between mission.txt and l4d_votemode.cfg
					if( strcmp(config.sName, sTemp) == 0 )
					{
						aList.PushString(sMap);
					}
				}

				// Select random valid map
				len = aList.Length;
				if( len )
				{
					aList.GetString(GetRandomInt(0, len - 1), sMap, sizeof(sMap));
					change = true;
				}
			}
		}
	}



	// 2. Verify valid mode for the current map/campaign with "Info Editor" plugin
	// Search the voted mode for valid maps
	if( change == false && g_bInfoEditor )
	{
		// Validate mode for current campaign
		int done;
		ArrayList hTemp;
		char sNews[MAX_STRING_LEN];

		hTemp = new ArrayList(ByteCountToCells(MAX_STRING_LEN));

		GetCurrentMap(sMap, sizeof(sMap));

		// Loop valid maps from mission file
		for( int i = 1; i < 15; i++ )
		{
			Format(sTemp, sizeof(sTemp), "modes/%s/%d/map", config.sCommand, i);
			InfoEditor_GetString(0, sTemp, sNews, sizeof(sNews));

			if( strcmp(sNews, "N/A") == 0 )			// Doesn't exist
			{
				break;
			}
			else if( strcmp(sNews, sMap) == 0 )		// Same as current map
			{
				change = true;
				done = 1;
				break;
			}
			else if( sNews[0] ) // Not empty string
			{
				hTemp.PushString(sNews);			// Store valid maps
			}
		}

		// Not same map
		if( !done )
		{
			// Get random valid map
			done = hTemp.Length;
			if( done )
			{
				hTemp.GetString(GetRandomInt(0, done-1), sMap, sizeof(sMap));
				change = true;
			}
		}

		delete hTemp;
	}

	// Fall back to use current map as valid if none found
	if( change == false )
	{
		GetCurrentMap(sMap, sizeof(sMap));
	}

	g_bRestart = config.bRestart;

	// Change mode and restart
	g_hMPGameMode.SetString(config.sCommand);

	strcopy(g_sMap, sizeof(g_sMap), sMap);
	CreateTimer(0.1, TimerChangeLevel);

	return Plugin_Continue;
}

Action TimerChangeLevel(Handle timer)
{
	// ServerCommand("z_difficulty normal; changelevel %s", g_sMap);
	ServerCommand("z_difficulty normal");
	ServerExecute();
	ForceChangeLevel(g_sMap, "VoteMode");

	return Plugin_Continue;
}

Action TimerRestartGame(Handle timer)
{
	g_hRestartGame.IntValue = 1;

	return Plugin_Continue;
}