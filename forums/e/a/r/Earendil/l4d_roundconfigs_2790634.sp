/**
 * ======================================================================================== *
 *                              [L4D & L4D2] Round Configs                                  *
 * ---------------------------------------------------------------------------------------- *
 *  Author      :   Eärendil                                                                *
 *  Descrp      :   Changes server configs if survivors fail the round                      *
 *  Version     :   1.0                                                                     *
 *  Link        :   https://github.com/Earendil-89/l4d_roundconfigs                         *
 * ======================================================================================== *
 *                                                                                          *
 *  CopyRight (C) 2022 Eduardo "Eärendil" Chueca                                            *
 * ---------------------------------------------------------------------------------------- *
 *  This program is free software; you can redistribute it and/or modify it under the       *
 *  terms of the GNU General Public License, version 3.0, as published by the Free          *
 *  Software Foundation.                                                                    *
 *                                                                                          *
 *  This program is distributed in the hope that it will be useful, but WITHOUT ANY         *
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A         *
 *  PARTICULAR PURPOSE. See the GNU General Public License for more details.                *
 *                                                                                          *
 *  You should have received a copy of the GNU General Public License along with            *
 *  this program. If not, see <http://www.gnu.org/licenses/>.                               *
 * ======================================================================================== *
 */
 
#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define FCVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"
#define CONFIG_FILE "data/l4d_round_configs.cfg"
#define CHAT_TRIGGERS "rc,roundconfig"

#define MAX_ROUNDS 128
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar g_hAllow;
ConVar g_hCurrGamemode;
ConVar g_hMenu;
ConVar g_hMaxRounds;
ConVar g_hConfigFile;
ConVar g_hLogs;
ConVar g_hChat;

bool g_bPluginOn;
bool g_bServerActive;
bool g_bMapStarted;

char g_sConfigFile[PLATFORM_MAX_PATH];
char g_sChatTriggers[8][32];

int g_iRoundCount;
int g_iMaxRounds;

ArrayList g_alLevelTexts;
Menu g_mMenu;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Round Configs",
	author = "Eärendil",
	description = "Changes server ConVars if survivors fail the round.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Earendil-89/l4d_roundconfigs",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if( ev == Engine_Left4Dead || ev == Engine_Left4Dead2)
		return APLRes_Success;
		
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	CreateConVar("l4d_roundconfigs_version",			PLUGIN_VERSION,			"Round Configs Version",			FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAllow =		CreateConVar("l4d_rc_enable",			"1",				"1 = Plugin On. 0 = Plugin Off.", FCVAR_FLAGS, true, 0.0, true, 1.0);
	g_hMaxRounds =	CreateConVar("l4d_rc_max_rounds",		"0",				"Max amount of rounds that the plugin will change ConVars.\n0 = use the max rounds defined in config file.", FCVAR_FLAGS, true, 0.0, true, float(MAX_ROUNDS));
	g_hMenu =		CreateConVar("l4d_rc_infomenu",			"1",				"Display menu to clients with info about the round. 1 = On, 0 = Off", FCVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConfigFile = CreateConVar("l4d_rc_configfile",		"server",			"The server config file to be called to restart all settings (.cfg extension is not needed).", FCVAR_FLAGS);
	g_hLogs =		CreateConVar("l4d_rc_logs",				"1",				"Log messages to SourceMod in case of config file errors. 0 = Off, 1 = On.", FCVAR_FLAGS, true, 0.0, true, 1.0);
	g_hChat =		CreateConVar("l4d_rc_chattriggers",		CHAT_TRIGGERS,		"Keywords to use as chat trigger to open round info menu.\nValues separated by comma, no space.\nMax 8 chat triggers.", FCVAR_FLAGS);
	g_hCurrGamemode = FindConVar("mp_gamemode");

	g_hAllow.AddChangeHook(CvarChange_Enable);
	g_hCurrGamemode.AddChangeHook(CvarChange_Enable);
	g_hMaxRounds.AddChangeHook(CvarChange_CVars);
	g_hConfigFile.AddChangeHook(CvarChange_CVars);
	g_hChat.AddChangeHook(CvarChange_CVars);
		
	AutoExecConfig(true, "l4d_roundconfigs");
}

public void OnConfigsExecuted()
{
	SwitchPlugin();
	GetCVars();
}

public void OnMapStart()
{
	g_iRoundCount = 1;
	g_iMaxRounds = GetMaxRounds();
	g_bMapStarted = true;
}

// Sourcemod doesn't dettect the first round start of the server, so use this to start the plugin on the first player connection
public void OnClientConnected(int client)
{	
	if( g_bServerActive )
		return;
		
	OnConfigsExecuted();
	g_bServerActive = true;
	if( ServerWithPlayers(client) )
		return;
		
	if( g_bPluginOn && !IsFakeClient(client) )
	{
		g_iMaxRounds = GetMaxRounds();
		g_iRoundCount = 1;	
		LoadLevelConfig(1);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if( g_bPluginOn && g_hMenu.BoolValue )
		ShowMenu(client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if( !client )
		return Plugin_Continue;
	
	int activator = sArgs[0] == '!' ? 1 : 0;
	activator = sArgs[0] == '/' ? 2 : activator;
	
	if( !activator )
		return Plugin_Continue;

	for( int i = 0; i < sizeof(g_sChatTriggers); i++ )
	{
		if( strncmp(sArgs[1], g_sChatTriggers[i], sizeof(g_sChatTriggers[])) == 0 )
		{
			ShowMenu(client);
			return activator == 1 ? Plugin_Continue : Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// If last client leaves the server, then restart the whole round count
public void OnClientDisconnect(int client)
{
	if( !g_bPluginOn || IsFakeClient(client) )
		return;
		
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != client && IsClientInGame(i) && !IsFakeClient(i) )
			return;
	}
	ResetConfig();
	g_iRoundCount = 0;
}

public void OnMapEnd()
{
	delete g_mMenu;
	g_bMapStarted = false;
}

public void OnPluginEnd()
{
	delete g_alLevelTexts;
	delete g_mMenu;
	ResetConfig();
}

/*******************************************************************************
 *                                   ConVars                                   *
 *******************************************************************************/

void CvarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	SwitchPlugin();
}

void CvarChange_CVars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

void GetCVars()
{
	g_iMaxRounds = GetMaxRounds();
		
	g_hConfigFile.GetString(g_sConfigFile, sizeof(g_sConfigFile));
	
	char sBuffer[512];
	g_hChat.GetString(sBuffer, sizeof(sBuffer));
	
	ExplodeString(sBuffer, ",", g_sChatTriggers, sizeof(g_sChatTriggers), sizeof(g_sChatTriggers[]));
}

void SwitchPlugin()
{
	bool bAllowMode = IsAllowedGameMode();
	if( g_bPluginOn == false && g_hAllow.BoolValue == true && bAllowMode == true )
	{
		g_bPluginOn = true;
		HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
	}
	
	if( g_bPluginOn == true && (g_hAllow.BoolValue == false || bAllowMode == false) )
	{
		g_bPluginOn = false;
		UnhookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
		ResetConfig();
	}
}

bool g_bIsCoop;
bool IsAllowedGameMode()
{
	if( !g_bMapStarted )
		return false;
	
	g_bIsCoop = false;
	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) )
			RemoveEdict(entity);
	}
	return g_bIsCoop;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	g_bIsCoop = true;
}

/*******************************************************************************
 *                                Events                                       *
 *******************************************************************************/

void Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	// If we reach the last round stop trying to look for more round settings
	if( g_iRoundCount < g_iMaxRounds )
		LoadLevelConfig(++g_iRoundCount);
	// Just check is there is something to display, if not, don't show the menu

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
			ShowMenu(i);
	}
}

/*******************************************************************************
 *                              Menu Display                                   *
 *******************************************************************************/

void ShowMenu(int client)
{
	if( g_mMenu != null )
	{
		if( g_hMenu.BoolValue )
			g_mMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}
	int iMenuSize = g_alLevelTexts.Length;
	if( iMenuSize == 0 )
		return;
	
	g_mMenu = new Menu(MenuHandler);
	char sBuffer[512];
	Format(sBuffer, sizeof(sBuffer), "Round [%i/%i] Settings", g_iRoundCount, g_iMaxRounds);
	g_mMenu.SetTitle(sBuffer);
	for( int i = 0; i < iMenuSize; i++ )
	{
		g_alLevelTexts.GetString(i, sBuffer, sizeof(sBuffer));
		g_mMenu.AddItem("", sBuffer);
	}
	if( IsClientInGame(client) )
		g_mMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler(Menu menu, MenuAction action, int client, int args)
{
	if( action == MenuAction_Select )
	{
		g_mMenu.Display(client, MENU_TIME_FOREVER);
	}
	return 0;
}

/*******************************************************************************
 *                        File read and ConVar setting                         *
 *******************************************************************************/

void LoadLevelConfig(int level)
{
	delete g_mMenu;
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_FILE);
	if( !FileExists(sPath) )
		SetFailState("Config file \"%s\" not found", CONFIG_FILE);
	
	KeyValues hKV = new KeyValues("Configs");
	if( !hKV.ImportFromFile(sPath) )
	{
		delete hKV;
		SetFailState("Failed to read \"%s\" file.", CONFIG_FILE);
	}
	
	char sMapName[32];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	// Creating/clearing the ArrayList that contains the texts that will be displayed via menu
	if( g_alLevelTexts == null )
		g_alLevelTexts = new ArrayList(512, 0);
	else
		g_alLevelTexts.Clear();
	
	// Creating arraylists that will store the ConVars and Values
	ArrayList alCVars = new ArrayList(128, 0);
	ArrayList alValues = new ArrayList(128, 0);
	
	if( !ReadKeyValues(level, sMapName, hKV, alCVars, alValues) )
	{
		if( !ReadKeyValues(level, "Default", hKV, alCVars, alValues) )
		{
			// No Settings for that map, or empty settings, silently log a message and stop working for that round
			delete hKV;
			delete alCVars;
			delete alValues;
			if( g_hLogs.BoolValue )
				LogMessage("There is no default or custom config for map \"%s\" and round %i.", sMapName, level);
			return;
		}
	}

	if( !ApplySettings(alCVars, alValues) && g_hLogs.BoolValue )
		LogMessage("Error setting ConVars for map \"%s\" and round %i. ConVars and value amounts does not match.", sMapName, level);
	delete hKV;
	delete alCVars;
	delete alValues;
}

bool ReadKeyValues(int level, const char[] sectionName ,KeyValues kv, ArrayList convars, ArrayList values)
{
	if( !kv.JumpToKey(sectionName) )
		return false;
	
	bool result = false;	// If any value has been correctly readed, it will return true, if not, try to read default or log the problem to server
	char sKey[16];
	
	// Read first the messages to display on menu
	Format(sKey, sizeof(sKey), "Text:%i", level);
	if( kv.JumpToKey(sKey) )
	{
		if( kv.GotoFirstSubKey(false) )
		{
			char sText[512];
			do
			{
				kv.GetString(NULL_STRING, sText, sizeof(sText));
				g_alLevelTexts.PushString(sText);
				result = true;
			} while( kv.GotoNextKey(false) );
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	// Read the ConVars and their values
	Format(sKey, sizeof(sKey), "CVars:%i", level);
	char sText[512];
	kv.GetSectionName(sText, sizeof(sText));
	if( kv.JumpToKey(sKey) )
	{
		if( kv.GotoFirstSubKey(false) )
		{
			char sCVar[128];
			char sValue[512];
			do
			{
				kv.GetSectionName(sCVar, sizeof(sCVar));
				convars.PushString(sCVar);
				kv.GetString(NULL_STRING, sValue, sizeof(sValue));
				values.PushString(sValue);
				result = true;
			} while( kv.GotoNextKey(false) );
		}
	}
	return result;
}

bool ApplySettings(ArrayList convar, ArrayList value)
{
	int length = convar.Length;
	if( length != value.Length )
		return false;
		
	char sCVar[128], sValue[128];
	for( int i = 0; i < length; i++ )
	{
		convar.GetString(i, sCVar, sizeof(sCVar));
		value.GetString(i, sValue, sizeof(sValue));
		
		// Extracted fom sm_cvar
		if (StrEqual(sCVar, "servercfgfile", false) || StrEqual(sCVar, "lservercfgfile", false))
		{
			int pos = StrContains(sValue, ";", true);
			if (pos != -1)
			{
				sValue[pos] = '\0';
			}
		}
		ConVar cv = FindConVar(sCVar);
		// Prevent exceptions if convar was invalid
		if( cv != null )
		{
			cv.SetString(sValue, true);
			delete cv;
		}
		else if( g_hLogs.BoolValue )
			LogToFile("ConVar \"%\" does not exist. Check plugin config file.", sCVar);
	}
	return true;
}

/*******************************************************************************
 *                                Functions                                    *
 *******************************************************************************/

int GetMaxRounds()
{
	if( g_hMaxRounds.IntValue > 0 )
		return g_hMaxRounds.IntValue;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_FILE);
	if( !FileExists(sPath) )
		SetFailState("Config file \"%s\" not found", CONFIG_FILE);
	
	KeyValues hKV = new KeyValues("Configs");
	if( !hKV.ImportFromFile(sPath) )
	{
		delete hKV;
		SetFailState("Failed to read \"%s\" file.", CONFIG_FILE);
	}
	
	char sMapName[32];
	GetCurrentMap(sMapName, sizeof(sMapName));

	int result = 0;
	if( !hKV.JumpToKey(sMapName) )
	{
		if( !hKV.JumpToKey("Default") )
			return result;

	}
	char sKey[512];
	for( int i = 1; i <= MAX_ROUNDS; i++ )
	{
		Format(sKey, sizeof(sKey), "Text:%i", i);
		if( hKV.JumpToKey(sKey) )
		{
			result = i;
			hKV.GoBack();
		}
	}
	for( int i = result; i <= MAX_ROUNDS; i++ )
	{
		Format(sKey, sizeof(sKey), "CVars:%i", i);
		if( hKV.JumpToKey(sKey) )
		{
			result = i;
			hKV.GoBack();
		}
	}
	delete hKV;
	return result;
}

void ResetConfig()
{
	// Because sometimes is not loaded (?)
	if( !g_sConfigFile[0] )
		GetCVars();

	ServerCommand("exec %s", g_sConfigFile);
}

bool ServerWithPlayers(int client)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != client && IsClientConnected(i) && !IsFakeClient(i) )
			return true;
	}
	return false;
}

/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.0	(08-Oct-2022)
	- Initial release.
==============================================================================================*/