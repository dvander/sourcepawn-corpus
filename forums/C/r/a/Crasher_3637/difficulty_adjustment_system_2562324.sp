// Difficulty Adjustment System
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define DAS_VERSION "14.0"
#define DAS_URL "https://forums.alliedmods.net/showthread.php?t=303117"

public Plugin myinfo =
{
	name = "Difficulty Adjustment System",
	author = "Psykotik (Crasher_3637)",
	description = "Adjusts difficulty based on the number of alive non-idle human survivors on the server.",
	version = DAS_VERSION,
	url = DAS_URL
};

bool g_bDASBools[4];
ConVar g_cvDASConVars[10];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "The Difficulty Adjustment System only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvDASConVars[0] = CreateConVar("das_advanceddifficulty", "3", "Minimum players required for Advanced.");
	g_cvDASConVars[1] = CreateConVar("das_announcedifficulty", "1", "Announce the difficulty when it is changed?\n(0: OFF)\n(1: ON)");
	g_cvDASConVars[2] = FindConVar("z_difficulty");
	g_cvDASConVars[3] = CreateConVar("das_disabledgamemodes", "versus,realismversus,survival,scavenge", "Disable the Difficulty Adjustment System in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Disabled in these game modes.)");
	g_cvDASConVars[4] = CreateConVar("das_easydifficulty", "1", "Minimum players required for Easy.");
	g_cvDASConVars[5] = CreateConVar("das_enabledgamemodes", "coop,realism,mutation1,mutation12", "Enable the Difficulty Adjustment System in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Enabled in these game modes.)");
	g_cvDASConVars[6] = CreateConVar("das_enableplugin", "1", "Enable the Difficulty Adjustment System?\n(0: OFF)\n(1: ON)");
	g_cvDASConVars[7] = CreateConVar("das_expertdifficulty", "4", "Minimum players required for Expert.");
	g_cvDASConVars[8] = FindConVar("mp_gamemode");
	g_cvDASConVars[9] = CreateConVar("das_normaldifficulty", "2", "Minimum players required for Normal.");
	CreateConVar("das_pluginversion", DAS_VERSION, "Difficulty Adjustment System version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvDASConVars[2].AddChangeHook(vDASDifficultyCvar);
	AutoExecConfig(true, "difficulty_adjustment_system");
}

public void OnMapStart()
{
	for (int iNumber = 0; iNumber <= 3; iNumber++)
	{
		g_bDASBools[iNumber] = false;
	}
}

public void OnConfigsExecuted()
{
	if (!g_cvDASConVars[6].BoolValue || !bIsPluginEnabled())
	{
		return;
	}
	CreateDirectory("cfg/sourcemod/difficulty_adjustment_system/", 511);
	char sDifficulty[32];
	for (int iDifficulty = 0; iDifficulty <= 3; iDifficulty++)
	{
		switch (iDifficulty)
		{
			case 0: sDifficulty = "easy";
			case 1: sDifficulty = "normal";
			case 2: sDifficulty = "hard";
			case 3: sDifficulty = "impossible";
		}
		vCreateConfigFile("cfg/sourcemod/", "difficulty_adjustment_system/", sDifficulty, sDifficulty);
	}
	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	if (g_cvDASConVars[2] != null && IsMapValid(sMap))
	{
		CreateTimer(1.0, tTimerUpdatePlayerCount, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		char sDifficultyConfig[512];
		g_cvDASConVars[2].GetString(sDifficultyConfig, sizeof(sDifficultyConfig));
		Format(sDifficultyConfig, sizeof(sDifficultyConfig), "cfg/sourcemod/difficulty_adjustment_system/%s.cfg", sDifficultyConfig);
		if (FileExists(sDifficultyConfig, true))
		{
			strcopy(sDifficultyConfig, sizeof(sDifficultyConfig), sDifficultyConfig[4]);
			ServerCommand("exec \"%s\"", sDifficultyConfig);
		}
		else
		{
			vCreateConfigFile("cfg/sourcemod/", "difficulty_adjustment_system/", sDifficultyConfig, sDifficultyConfig);
		}
	}
}

public void OnMapEnd()
{
	for (int iNumber = 0; iNumber <= 3; iNumber++)
	{
		g_bDASBools[iNumber] = false;
	}
}

public void vDASDifficultyCvar(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
	char sDifficultyConfig[512];
	g_cvDASConVars[2].GetString(sDifficultyConfig, sizeof(sDifficultyConfig));
	Format(sDifficultyConfig, sizeof(sDifficultyConfig), "cfg/sourcemod/difficulty_adjustment_system/%s.cfg", sDifficultyConfig);
	if (FileExists(sDifficultyConfig, true))
	{
		strcopy(sDifficultyConfig, sizeof(sDifficultyConfig), sDifficultyConfig[4]);
		ServerCommand("exec \"%s\"", sDifficultyConfig);
	}
}

void vCreateConfigFile(const char[] filepath, const char[] folder, const char[] filename, const char[] label = "")
{
	char sConfigFilename[128];
	char sConfigLabel[128];
	File fFilename;
	Format(sConfigFilename, sizeof(sConfigFilename), "%s%s%s.cfg", filepath, folder, filename);
	if (FileExists(sConfigFilename))
	{
		return;
	}
	fFilename = OpenFile(sConfigFilename, "w+");
	strlen(label) > 0 ? strcopy(sConfigLabel, sizeof(sConfigLabel), label) : strcopy(sConfigLabel, sizeof(sConfigLabel), sConfigFilename);
	if (fFilename != null)
	{
		fFilename.WriteLine("// This config file was auto-generated by the Difficulty Adjustment System v%s (%s)", DAS_VERSION, DAS_URL);
		fFilename.WriteLine("");
		fFilename.WriteLine("");
		delete fFilename;
	}
}

public Action tTimerUpdatePlayerCount(Handle timer)
{
	if (g_cvDASConVars[2] == null)
	{
		return Plugin_Stop;
	}
	if (!g_cvDASConVars[6].BoolValue || !bIsPluginEnabled())
	{
		return Plugin_Continue;
	}
	int iEasy = g_cvDASConVars[4].IntValue;
	int iNormal = g_cvDASConVars[9].IntValue;
	int iAdvanced = g_cvDASConVars[0].IntValue;
	int iExpert = g_cvDASConVars[7].IntValue;
	int iPlayerCount = iGetPlayerCount();
	if (!g_bDASBools[1] && (iPlayerCount == iEasy || (iPlayerCount > iEasy && iPlayerCount < iNormal)))
	{
		g_cvDASConVars[2].SetString("easy");
		g_bDASBools[1] = true;
		g_bDASBools[3] = false;
		g_bDASBools[0] = false;
		g_bDASBools[2] = false;
		if (g_bDASBools[1] && g_cvDASConVars[1].BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Easy\x01.");
		}
	}
	else if (!g_bDASBools[3] && (iPlayerCount == iNormal || (iPlayerCount > iNormal && iPlayerCount < iAdvanced)))
	{
		g_cvDASConVars[2].SetString("normal");
		g_bDASBools[1] = false;
		g_bDASBools[3] = true;
		g_bDASBools[0] = false;
		g_bDASBools[2] = false;
		if (g_bDASBools[3] && g_cvDASConVars[1].BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Normal\x01.");
		}
	}
	else if (!g_bDASBools[0] && (iPlayerCount == iAdvanced || (iPlayerCount > iAdvanced && iPlayerCount < iExpert)))
	{
		g_cvDASConVars[2].SetString("hard");
		g_bDASBools[1] = false;
		g_bDASBools[3] = false;
		g_bDASBools[0] = true;
		g_bDASBools[2] = false;
		if (g_bDASBools[0] && g_cvDASConVars[1].BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Advanced\x01.");
		}
	}
	else if (!g_bDASBools[2] && (iPlayerCount == iExpert || iPlayerCount > iExpert))
	{
		g_cvDASConVars[2].SetString("impossible");
		g_bDASBools[1] = false;
		g_bDASBools[3] = false;
		g_bDASBools[0] = false;
		g_bDASBools[2] = true;
		if (g_bDASBools[2] && g_cvDASConVars[1].BoolValue)
		{
			PrintToChatAll("\x04[DAS]\x01 Difficulty changed to\x03 Expert\x01.");
		}
	}
	return Plugin_Continue;
}

stock int iGetPlayerCount()
{
	int iPlayerCount = 0;
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsHumanSurvivor(iPlayer))
		{
			iPlayerCount += 1;
		}
	}
	return iPlayerCount;
}

stock bool bHasIdlePlayer(int client)
{
	char sClassname[12];
	GetEntityNetClass(client, sClassname, sizeof(sClassname));
	if (strcmp(sClassname, "SurvivorBot") == 0)
	{
		int iSpectatorUserId = GetEntProp(client, Prop_Send, "m_humanSpectatorUserID");
		if (iSpectatorUserId > 0)
		{
			int iIdler = GetClientOfUserId(iSpectatorUserId);
			if (iIdler > 0 && IsClientInGame(iIdler) && !IsFakeClient(iIdler) && (GetClientTeam(iIdler) != 2))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool bIsHumanSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsClientInKickQueue(client) && !IsFakeClient(client) && !bHasIdlePlayer(client) && !bIsPlayerIdle(client);
}

stock bool bIsPlayerIdle(int client)
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (!IsClientInGame(iPlayer) || GetClientTeam(iPlayer) != 2 || !IsFakeClient(iPlayer) || !bHasIdlePlayer(iPlayer))
		{
			continue;
		}
		char sClassname[12];
		GetEntityNetClass(iPlayer, sClassname, sizeof(sClassname));
		if (strcmp(sClassname, "SurvivorBot") == 0)
		{
			int iSpectatorUserId = GetEntProp(iPlayer, Prop_Send, "m_humanSpectatorUserID");
			if (iSpectatorUserId > 0)
			{
				int iIdler = GetClientOfUserId(iSpectatorUserId);
				if (iIdler == client)
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock bool bIsPluginEnabled()
{
	char sGameMode[32];
	char sConVarModes[32];
	g_cvDASConVars[8].GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_cvDASConVars[5].GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	g_cvDASConVars[3].GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	return true;
}