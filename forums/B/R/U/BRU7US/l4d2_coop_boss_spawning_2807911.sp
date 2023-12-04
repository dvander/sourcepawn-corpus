#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sourcescramble>

#define PLUGIN_NAME					"[L4D2] Coop Boss Spawning"
#define PLUGIN_AUTHOR				"sorallll, reworked by B[R]UTUS"
#define PLUGIN_DESCRIPTION			"Provides a possibility to customize Bosses spawn percents in co-op mode"
#define PLUGIN_VERSION				"2.0.0"
#define PLUGIN_URL					""

#define GAMEDATA					"coop_boss_spawning"
#define PATCH_NO_DIRECTOR_BOSS		"CDirector::OnThreatEncountered::Block"
#define PATCH_COOP_VERSUS_BOSS		"CDirectorVersusMode::UpdateNonVirtual::IsVersusMode"
#define PATCH_BLOCK_MARKERSTIMER	"CDirectorVersusMode::UpdateNonVirtual::UpdateMarkersTimer"
#define PATCH_TANKCOUNT_SPAWN_WITCH	"CDirectorVersusMode::UpdateVersusBossSpawning::m_iTankCount"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

int
	g_iMaxTanks,
	g_iChapterSpawnedTankCount,
	g_iTankSpawnChance[32],
	g_iTankMinSpawnPercent[32],
	g_iTankMaxSpawnPercent[32],
	g_iTankSpawnPercent[32],
	//-------------------------
	g_iMaxWitches,
	g_iChapterSpawnedWitchCount,
	g_iWitchSpawnChance[32],
	g_iWitchMinSpawnPercent[32],
	g_iWitchMaxSpawnPercent[32],
	g_iWitchSpawnPercent[32];

bool 
	g_bIsTankSpawnAllowed = false,
	g_bIsWitchSpawnAllowed = false,
	g_bIsGameStarted = false;

ConVar
	g_cvShowBossPercRules;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead2)
		return APLRes_Success;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
}

public void OnPluginStart() 
{
	InitGameData();
	g_cvShowBossPercRules = CreateConVar("l4d2_cbs_show_boss_percent_difficulties", "3", "Show a Bosses spawn percents for difficulties: 0 - Don't show for any difficulty | 1 - Easy | 2 - Normal and lower | 3 - Advanced and lower | 4 - Expert and lower");

	RegConsoleCmd("sm_boss", BossCmd);
	RegConsoleCmd("sm_current", CurrentCmd);
	RegAdminCmd("sm_debug", DebugCmd, ADMFLAG_KICK);
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal) 
{
	if (strcmp(key, "ProhibitBosses", false) == 0 || strcmp(key, "DisallowThreatType", false) == 0) 
    {
		retVal = 0;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void InitGameData() 
{
	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Patch(hGameData, PATCH_NO_DIRECTOR_BOSS);
	Patch(hGameData, PATCH_COOP_VERSUS_BOSS);
	Patch(hGameData, PATCH_BLOCK_MARKERSTIMER);
	Patch(hGameData, PATCH_TANKCOUNT_SPAWN_WITCH);

	delete hGameData;
}

void Patch(GameData hGameData = null, const char[] name) 
{
	MemoryPatch patch = MemoryPatch.CreateFromConf(hGameData, name);
	if (!patch.Validate())
		SetFailState("Failed to verify patch: \"%s\"", name);
	else if (patch.Enable())
		PrintToServer("Enabled patch: \"%s\"", name);
}

public void OnMapStart()
{
	char mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));
	Process_GetMapData(mapName);
	g_bIsGameStarted = false;
}

bool Process_GetMapData(const char[] mapName)
{
	if (!L4D_IsMissionFinalMap())
	{
		char szPath[256];
		BuildPath(Path_SM, szPath, sizeof(szPath), "data/l4d2_coop_boss_spawning.cfg");

		KeyValues kv = new KeyValues("CoopBossSpawnPercents");
		if (kv.ImportFromFile(szPath))
		{
			kv.Rewind();

			if (kv.JumpToKey(mapName))
			{
				//Getting maximum tank count for current map...
				g_iMaxTanks = kv.GetNum("max_tanks", 0);

				//Getting maximum witch count for current map...
				g_iMaxWitches = kv.GetNum("max_witches", 0);

				if (kv.JumpToKey("tanks"))
				{
					for (int i = 0; i <= g_iMaxTanks; i++)
					{
						if (kv.GotoFirstSubKey() || kv.GotoNextKey())
						{
							g_iTankSpawnChance[i]     = kv.GetNum("spawn_chance", 0);
							g_iTankMinSpawnPercent[i] = kv.GetNum("min_percent", 0);
							g_iTankMaxSpawnPercent[i] = kv.GetNum("max_percent", 0);

							LogMessage("TANK [#%i] -> [%s]: <spawn_chance> = %i", i + 1, mapName, g_iTankSpawnChance[i]);
							LogMessage("TANK [#%i] -> [%s]: <min_percent> = %i",  i + 1, mapName, g_iTankMinSpawnPercent[i]);
							LogMessage("TANK [#%i] -> [%s]: <max_percent> = %i",  i + 1, mapName, g_iTankMaxSpawnPercent[i]);
						}
					}
				}

				kv.GoBack();
				kv.GoBack();

				if (kv.JumpToKey("witches"))
				{
					for (int i = 0; i <= g_iMaxWitches; i++)
					{
						if (kv.GotoFirstSubKey() || kv.GotoNextKey())
						{
							g_iWitchSpawnChance[i]     = kv.GetNum("spawn_chance", 0);
							g_iWitchMinSpawnPercent[i] = kv.GetNum("min_percent", 0);
							g_iWitchMaxSpawnPercent[i] = kv.GetNum("max_percent", 0);

							LogMessage("WITCH [#%i] -> [%s]: <spawn_chance> = %i", i + 1, mapName,  g_iWitchSpawnChance[i]);
							LogMessage("WITCH [#%i] -> [%s]: <min_percent> = %i",  i + 1, mapName,  g_iWitchMinSpawnPercent[i]);
							LogMessage("WITCH [#%i] -> [%s]: <max_percent> = %i",  i + 1, mapName,  g_iWitchMaxSpawnPercent[i]);
						}
					}
				}
			}
			else
			{
				if (kv.JumpToKey("default"))
				{
					//Getting maximum tank count for current map...
					g_iMaxTanks = kv.GetNum("max_tanks", 0);

					//Getting maximum witch count for current map...
					g_iMaxWitches = kv.GetNum("max_witches", 0);

					if (kv.JumpToKey("tanks"))
					{
						for (int i = 0; i <= g_iMaxTanks; i++)
						{
							if (kv.GotoFirstSubKey() || kv.GotoNextKey())
							{
								g_iTankSpawnChance[i]     = kv.GetNum("spawn_chance", 0);

								if (g_iTankSpawnChance[i] == -1)
								{
									LogMessage("TANK [#%i] -> [%s]: <spawn_chance> = 'Event Spawn'", i + 1, mapName);
									continue;
								}

								g_iTankMinSpawnPercent[i] = kv.GetNum("min_percent", 0);
								g_iTankMaxSpawnPercent[i] = kv.GetNum("max_percent", 0);

								LogMessage("TANK [#%i] -> [%s]: <spawn_chance> = %i%%", i + 1, mapName, g_iTankSpawnChance[i]);
								LogMessage("TANK [#%i] -> [%s]: <min_percent> = %i%%",  i + 1, mapName, g_iTankMinSpawnPercent[i]);
								LogMessage("TANK [#%i] -> [%s]: <max_percent> = %i%%",  i + 1, mapName, g_iTankMaxSpawnPercent[i]);
							}
						}
					}

					kv.GoBack();
					kv.GoBack();

					if (kv.JumpToKey("witches"))
					{
						for (int i = 0; i <= g_iMaxWitches; i++)
						{
							if (kv.GotoFirstSubKey() || kv.GotoNextKey())
							{
								g_iWitchSpawnChance[i]     = kv.GetNum("spawn_chance", 0);
								g_iWitchMinSpawnPercent[i] = kv.GetNum("min_percent", 0);
								g_iWitchMaxSpawnPercent[i] = kv.GetNum("max_percent", 0);

								LogMessage("WITCH [#%i] -> [%s]: <spawn_chance> = %i%%", i + 1, mapName, g_iWitchSpawnChance[i]);
								LogMessage("WITCH [#%i] -> [%s]: <min_percent> = %i%%",  i + 1, mapName, g_iWitchMinSpawnPercent[i]);
								LogMessage("WITCH [#%i] -> [%s]: <max_percent> = %i%%",  i + 1, mapName, g_iWitchMaxSpawnPercent[i]);
							}
						}
					}
				}
				else
					ClearBossSpawnPercentsData();
			}

			delete kv;
			return true;
		}
		else
		{
			LogError("Couldn't find a <data/l4d2_coop_boss_spawning.cfg> file!");
			delete kv;
			return false;
		}
	}
	else
	{
		LogMessage("Can't to load a boss percent spawn config for current map! Reason: Final Map");
		return false;
	} 
}

void ClearBossSpawnPercentsData()
{
	g_iMaxTanks = 0;
	g_iChapterSpawnedTankCount = 0;
	//-----------------------------
	g_iMaxWitches = 0;
	g_iChapterSpawnedWitchCount = 0;

	for (int i = 0; i <= 31; i++)
	{
		g_iTankSpawnChance[i] = 0;
		g_iTankMinSpawnPercent[i] = 0;
		g_iTankMaxSpawnPercent[i] = 0;
		g_iTankSpawnPercent[i] = 0;
		//-------------------------
		g_iWitchSpawnChance[i] = 0;
		g_iWitchMinSpawnPercent[i] = 0;
		g_iWitchMaxSpawnPercent[i] = 0;
		g_iWitchSpawnPercent[i] = 0;
	}
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if (!L4D2_IsGenericCooperativeMode())
		return;

	RandomizeBossesSpawnPercent();
	g_bIsGameStarted = true;
}

public void RandomizeBossesSpawnPercent()
{
	g_iChapterSpawnedTankCount = 0;
	g_iChapterSpawnedWitchCount = 0;

	for (int i = 1; i <= g_iMaxTanks; i++)
	{
		if (g_iTankSpawnChance[i-1] == 0 || g_iTankMinSpawnPercent[i-1] == 0 || g_iTankMaxSpawnPercent[i-1] == 0)
		{
			g_iTankSpawnPercent[i-1] = -1;
			continue;
		}
		else
		{
			if (g_iTankSpawnChance[g_iChapterSpawnedTankCount] != -1)
			{
				int iChance = Math_GetRandomInt(0, 100);
				if (iChance <= g_iTankSpawnChance[g_iChapterSpawnedTankCount])
					g_iTankSpawnPercent[i-1] = Math_GetRandomInt(g_iTankMinSpawnPercent[i-1], g_iTankMaxSpawnPercent[i-1]);
				else
				{
					g_iTankSpawnPercent[i-1] = -1;
					g_iChapterSpawnedTankCount++;
				}
			}
			else continue;
		}
	}

	for (int i = 1; i <= g_iMaxWitches; i++)
	{
		if (g_iWitchSpawnChance[i-1] == 0 || g_iWitchMinSpawnPercent[i-1] == 0 || g_iWitchMaxSpawnPercent[i-1] == 0)
		{
			g_iWitchSpawnPercent[i-1] = -1;
			continue;
		}
		else 
		{
			int iChance = Math_GetRandomInt(0, 100);
			if (iChance <= g_iWitchSpawnChance[g_iChapterSpawnedWitchCount])
				g_iWitchSpawnPercent[i-1] = Math_GetRandomInt(g_iWitchMinSpawnPercent[i-1], g_iWitchMaxSpawnPercent[i-1]);
			else
			{
				g_iWitchSpawnPercent[i-1] = -1;
				g_iChapterSpawnedWitchCount++;
			}
		}
	}
}

// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/math.inc
#define SIZE_OF_INT	2147483647 // without 0
int Math_GetRandomInt(int min, int max) 
{
	int random = GetURandomInt();
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

public int GetCurrentSurvivorsMapCompletion()
{
	return RoundToNearest((L4D2_GetFurthestSurvivorFlow() / L4D2Direct_GetMapMaxFlowDistance()) * 100.0);
}

public int GetDifficultyIndex()
{
	char cDifficulty[16];
	ConVar cvDifficulty = FindConVar("z_difficulty");
	cvDifficulty.GetString(cDifficulty, sizeof(cDifficulty));

	if (StrEqual(cDifficulty, "Easy", true))
		return 1;
	if (StrEqual(cDifficulty, "Normal", true))
		return 2;
	if (StrEqual(cDifficulty, "Hard", true))
		return 3;
	if (StrEqual(cDifficulty, "Impossible", true))
		return 4;

	return 2;
}

public Action BossCmd(int client, int args)
{
	if (!L4D2_IsGenericCooperativeMode())
		return Plugin_Handled;

	if (!L4D_IsMissionFinalMap())
	{
		if (GetDifficultyIndex() <= g_cvShowBossPercRules.IntValue)
		{
			if (g_bIsGameStarted)
			{
				if (g_iTankSpawnChance[g_iChapterSpawnedTankCount] > 0)
				{
					if (g_iTankSpawnPercent[g_iChapterSpawnedTankCount] > 0)
						CPrintToChat(client, "{green}[{default}Tank{green}]{default}: {blue}%d%%", g_iTankSpawnPercent[g_iChapterSpawnedTankCount]);
					else
						CPrintToChat(client, "{green}[{default}Tank{green}]{default}: {blue}None");
				}
				else 
					if (g_iTankSpawnChance[g_iChapterSpawnedTankCount] == -1)
						CPrintToChat(client, "{green}[{default}Tank{green}]{default}: {blue}Event");
					else CPrintToChat(client, "{green}[{default}Tank{green}]{default}: {blue}None");

				if (g_iWitchSpawnPercent[g_iChapterSpawnedWitchCount] > 0)
					CPrintToChat(client, "{green}[{default}Witch{green}]{default}: {blue}%d%%", g_iWitchSpawnPercent[g_iChapterSpawnedWitchCount]);
				else
					CPrintToChat(client, "{green}[{default}Witch{green}]{default}: {blue}None");
			}
			else CPrintToChat(client, "{green}[{default}Bosses{green}]{default}: Spawn percents are not defined while game isn't started!");
		}
	}

	CPrintToChat(client, "{green}[{default}Current{green}]{default}: {blue}%d%%", GetCurrentSurvivorsMapCompletion());
	return Plugin_Handled;
}

public Action CurrentCmd(int client, int args)
{
	if (!L4D2_IsGenericCooperativeMode())
		return Plugin_Handled;

	CPrintToChat(client, "{green}[{default}Current{green}]{default}: {blue}%d%%", GetCurrentSurvivorsMapCompletion());
	return Plugin_Handled;
}

public Action DebugCmd(int client, int args)
{
	if (!L4D2_IsGenericCooperativeMode())
		return Plugin_Handled;

	if (!L4D_IsMissionFinalMap())
	{
		char mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));

		CPrintToChat(client, "{green}[{default}Debug Info{green}]{default}: Map {blue}%s", mapName);
		CPrintToChat(client, "{green}->{default} max_tanks: {blue}%i", g_iMaxTanks);

		for (int i = 1; i <= g_iMaxTanks; i++)
		{
			if (g_iTankSpawnChance[i-1] == -1)
				CPrintToChat(client, "{green}->{default} Tank #{olive}%i{default} -> {blue}Event Spawn", i, g_iTankSpawnChance[i-1], g_iTankMinSpawnPercent[i-1], g_iTankMaxSpawnPercent[i-1]);
			else
				CPrintToChat(client, "{green}->{default} Tank #{olive}%i{default} -> Chance: {blue}%i%%{default} | Min: {blue}%i%%{default} | Max: {blue}%i%%", i, g_iTankSpawnChance[i-1], g_iTankMinSpawnPercent[i-1], g_iTankMaxSpawnPercent[i-1]);
		}

		CPrintToChat(client, "{green}-------------------------------------");

		CPrintToChat(client, "{green}->{default} max_witches: {blue}%i", g_iMaxWitches);
		for (int i = 1; i <= g_iMaxWitches; i++)
			CPrintToChat(client, "{green}->{default} Witch #{olive}%i{default} -> Chance: {blue}%i%%{default} | Min: {blue}%i%%{default} | Max: {blue}%i%%", i, g_iWitchSpawnChance[i-1], g_iWitchMinSpawnPercent[i-1], g_iWitchMaxSpawnPercent[i-1]);
	}

	return Plugin_Handled;
}

public void OnGameFrame()
{
	if (!L4D2_IsGenericCooperativeMode())
		return;

	if (!L4D_IsMissionFinalMap())
	{
		if (g_iChapterSpawnedTankCount < g_iMaxTanks)
		{
			if (g_iTankSpawnPercent[g_iChapterSpawnedTankCount] > 0)
			if (GetCurrentSurvivorsMapCompletion() >= g_iTankSpawnPercent[g_iChapterSpawnedTankCount])
				Process_SpawnTank();
		}

		if (g_iChapterSpawnedWitchCount < g_iMaxWitches)
		{
			if (g_iWitchSpawnPercent[g_iChapterSpawnedWitchCount] > 0)
			if (GetCurrentSurvivorsMapCompletion() >= g_iWitchSpawnPercent[g_iChapterSpawnedWitchCount])
				Process_SpawnWitch();
		}
	}
}

void Process_SpawnTank()
{
	static float fSpawnPos[3];
	bool bFound = L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), 8, 30, fSpawnPos);

	if (bFound)
	{
		g_bIsTankSpawnAllowed = true;
		L4D2_SpawnTank(fSpawnPos, NULL_VECTOR);
		g_bIsTankSpawnAllowed = false;
	}
}

void Process_SpawnWitch()
{
	static float fSpawnPos[3];
	bool bFound = L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), 7, 30, fSpawnPos);

	if (bFound)
	{
		g_bIsWitchSpawnAllowed = true;
		L4D2_SpawnWitch(fSpawnPos, NULL_VECTOR);
		g_bIsWitchSpawnAllowed = false;
	}
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	if (!L4D2_IsGenericCooperativeMode())
		return Plugin_Continue;

	if (!L4D_IsMissionFinalMap())
	{
		if (g_iTankSpawnChance[g_iChapterSpawnedTankCount] == -1) // if Event Tank spawn...
		{
			g_iChapterSpawnedTankCount++;
			return Plugin_Continue;
		}
			
		if (g_bIsTankSpawnAllowed)
		{
			g_iChapterSpawnedTankCount++;
			return Plugin_Continue;
		}
		else return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3])
{
	if (!L4D2_IsGenericCooperativeMode())
		return Plugin_Continue;

	if (!L4D_IsMissionFinalMap())
	{
		if (g_bIsWitchSpawnAllowed)
		{
			g_iChapterSpawnedWitchCount++;
			return Plugin_Continue;
		}
		else return Plugin_Handled;
	}

	return Plugin_Continue;
}