// Thanks DJ Tsunami 

/*
 * Version Notes:
 * 1.7: Changed to more generic system based upon gamemode and difficulty settings.
 *		Idea from AtomicStrykers even more basic code.
 */

#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "Game Mode Config Loader",
	author = "Thraka & Dirka_Dirka",
	description = "Executes a config file based on the current mp_gamemode and z_difficulty",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=93212"
}

new Handle:g_hGameMode			=	INVALID_HANDLE;
new Handle:g_hDifficulty		=	INVALID_HANDLE;
//new bool:g_bGameModeChange		=	false;
//new bool:g_bDifficultyChange	=	false;

public OnPluginStart()
{
	CreateConVar("gamemode_cfg_ver", PLUGIN_VERSION, "Version of the game mode config loader plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hGameMode = FindConVar("mp_gamemode");		//coop, versus, survival
	g_hDifficulty = FindConVar("z_difficulty");		//Easy, Normal, Hard, Impossible
	
	HookConVarChange(g_hGameMode, ConVarChange_GameMode);
	HookConVarChange(g_hDifficulty, ConVarChange_Difficulty);
}

public OnMapStart()
{
	ExecuteGameModeConfig();
//	g_bGameModeChange = false;
//	g_bDifficultyChange = false;
}

public ConVarChange_GameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		ExecuteGameModeConfig();
//		g_bGameModeChange = true;
	}
}

public ConVarChange_Difficulty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		ExecuteGameModeConfig();
//		g_bDifficultyChange = true;
	}
}

ExecuteGameModeConfig()
{
	decl String:sConfigName[PLATFORM_MAX_PATH] = "";
	decl String:sConfigNameD[PLATFORM_MAX_PATH] = "";
	
	decl String:sGameMode[16] = "";
	GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
	
	decl String:sGameDifficulty[16] = "";
	GetConVarString(g_hDifficulty, sGameDifficulty, sizeof(sGameDifficulty));
	
	StrCat(String:sConfigName, sizeof(sConfigName), sGameMode);
	TrimString(sConfigName);
	
	StrCat(String:sConfigNameD, sizeof(sConfigName), sGameMode);
	StrCat(String:sConfigNameD, sizeof(sConfigName), sGameDifficulty);
	TrimString(sConfigNameD);
	
	new String:Temp1[] = "cfg\\";
	new String:Temp2[] = ".cfg";
	
	// the location of the config folder that exec looks for
	decl String:filePath[PLATFORM_MAX_PATH] = "";
	decl String:filePathD[PLATFORM_MAX_PATH] = "";
	
	StrCat(String:filePath, sizeof(filePath), String:Temp1);
	StrCat(String:filePath, sizeof(filePath), sConfigName);
	StrCat(String:filePath, sizeof(filePath), String:Temp2);
	TrimString(filePath);
	StrCat(String:filePathD, sizeof(filePathD), String:Temp1);
	StrCat(String:filePathD, sizeof(filePathD), sConfigNameD);
	StrCat(String:filePathD, sizeof(filePathD), String:Temp2);
	TrimString(filePathD);
	
	PrintToChatAll("EXEC: filePath: %s", filePath);
	PrintToChatAll("EXEC: filePathD: %s", filePathD);
	
	if (FileExists(filePathD))
	{
		PrintToChatAll("EXEC: executing %s", sConfigNameD);
		ServerCommand("exec %s", sConfigNameD);
	}
	else if (FileExists(filePath))
	{
		PrintToChatAll("EXEC: executing %s", sConfigName);
		ServerCommand("exec %s", sConfigName);
	}
	else
	{
		PrintToChatAll("EXEC: Nothing to execute..");
		return;		// no config file - will expand later
	}
}
