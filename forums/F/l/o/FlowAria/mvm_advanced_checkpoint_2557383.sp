#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>


public Plugin myinfo =
{
	name = "MvM Advanced Checkpoint",
	author = "Flowaria",
	description = "Reuse of Checkpoint Yes/No Feature in population file",
	version = "1.0",
	url = "http://steamcommunity.com/id/flowaria/"
};

KeyValues	kvConfig;
int			iGotoWave[32+1]; //0 is empty
Handle		hSetCheckpoint;

public void OnPluginStart()
{
	Handle cfg = LoadGameConfigFile("tf2.mvm.checkpoint");
	if (cfg == INVALID_HANDLE)
	{
		SetFailState("Unable to find gamedata file ( gamedata/tf2.mvm.checkpoint.txt )");
		return;
	}
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Signature, "CPopulationManager::SetCheckpoint");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((hSetCheckpoint = EndPrepSDKCall()) == INVALID_HANDLE)
	{
		SetFailState("Unable to prepare CPopulationManager::SetCheckpoint");
		return;
	}
	CloseHandle(cfg);
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/tf.mvm.checkpoint.cfg");
	if(!FileExists(path))
	{
		SetFailState("Unable to find config file ( configs/tf2.mvm.checkpoint.txt )");
		return;
	}
	else if((kvConfig = CreateKeyValues("checkpoint")) && !kvConfig.ImportFromFile(path))
	{
		SetFailState("Unable to read config file");
		return;
	}
	
	HookEvent("teamplay_round_start", Game_Restart);
	HookEvent("ctf_flag_captured", Wave_End);
}

public void Game_Restart(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetBool("full_reset") && IsMvM())
	{
		char mission[128], file[128];
		if(GetMissionString(mission, sizeof(mission)))
		{
			if(!ReadPopfile(mission))
			{
				GetFilenameString(mission, file, sizeof(file));
				Config_ReadKey(file);
			}
		}
	}
}

public void Wave_End(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("capping_team") == _:TFTeam_Blue && IsMvM())
	{
		if(iGotoWave[GetCurrentWaveCount()] != -1)
		{
			SetCheckpointIndex(iGotoWave[GetCurrentWaveCount()]);
		}
	}
}

stock bool ReadPopfile(const char[] popfile)
{
	ClearGotoCache();

	bool IsSuccess = false;
	KeyValues pop = CreateKeyValues("population");
	if(pop.ImportFromFile(popfile))
	{
		if(pop.GotoFirstSubKey(true))
		{
			char buffer[128];
			int wTarget = -1, wCurrent = 1;
			do
			{
				pop.GetSectionName(buffer, sizeof(buffer));
				if(StrEqual(buffer, "Wave", false)) //Ignore Mission
				{
					pop.GetString("Checkpoint", buffer, sizeof(buffer), "null");
					if(StrEqual(buffer, "Yes", false) || StrEqual(buffer, "1", false))
					{
						wTarget = wCurrent;
					}
					else if(StrEqual(buffer, "No", false) || StrEqual(buffer, "0", false))
					{
						if(wCurrent == 1)
						{
							PrintToServer("Parse Warning in %s : First wave MUST have Checkpoint, Checkpoint setting Ignored", popfile);
						}
						else
						{
							IsSuccess = true;
							iGotoWave[wCurrent] = wTarget;
						}
					}
					wCurrent++;
				}
			}while (pop.GotoNextKey(false));
		}
	}
	delete pop;
	return IsSuccess;
}

stock bool Config_ReadKey(const char[] key)
{
	ClearGotoCache();
	
	char value[256];
	kvConfig.GetString(key, value, sizeof(value), "null");
	if(!StrEqual(value, "null"))
	{
		//Split Each Command
		char element[16][16];
		int length = ExplodeString(value, " || ", element, 16, 16);
		for(int i = 0 ; i < length ; i++)
		{
			//Split Two part
			char eSplitArgs[2][8];
			int lengSplitArgs = ExplodeString(element[i], " << ", eSplitArgs, 2, 8);
			if(lengSplitArgs == 2)
			{
				//:::: Front (to this wave)
				int targetidx;
				if((targetidx = StringToInt(eSplitArgs[0])) == 0)
				{
					SetFailState("Unable to parse config line: %s::%d (target wave is not valid)", key, i+1);
					return false;
				}
				
				//:::: Back (from this wave)
				if(StrContains(eSplitArgs[1], "~") != -1) //Range
				{
					char eFromRange[2][4];
					int lengFromRange = ExplodeString(eSplitArgs[1], "~", eFromRange, 2, 4);
					if(lengFromRange == 2)
					{
						int fromidx_st, fromidx_ed;
						if( ((fromidx_st = StringToInt(eFromRange[0])) == 0) || ((fromidx_ed = StringToInt(eFromRange[1])) == 0) || (fromidx_st >= fromidx_ed))
						{
							SetFailState("Unable to parse config line: %s::%d (from wave split number range is wrong)", key, i+1);
							return false;
						}
						for(;fromidx_st<=fromidx_ed;fromidx_st++)
						{
							iGotoWave[fromidx_st] = targetidx;
							//PrintToServer("When fail: w%d->w%d", fromidx_st, targetidx);
						}
					}
					else
					{
						SetFailState("Unable to parse config line: %s::%d (unknown format with ~)", key, i+1);
						return false;
					}
				}
				else //Single
				{
					int fromidx;
					if((fromidx = StringToInt(eSplitArgs[1])) == 0)
					{
						SetFailState("Unable to parse config line: %s::%d (from wave is not number)", key, i+1);
						return false;
					}
					iGotoWave[fromidx] = targetidx;
					//PrintToServer("When fail: w%d->w%d", fromidx, targetidx);
				}
			}
			else
			{
				SetFailState("Unable to parse Line: %s::%d (cannot split with '<<')", key, i+1);
				return false;
			}
		}
		return true;
	}
	else
	{
		return false;
	}
}

stock bool GetMissionString(char[] mission, int length)
{
	int entity = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(entity))
	{
		GetEntPropString(entity, Prop_Send, "m_iszMvMPopfileName", mission, length);
		return (mission[0]);
	}
	return false;
}

stock bool GetFilenameString(const char[] mission, char[] result, length)
{
	char element[10][128];
	int element_length = ExplodeString(mission, "/", element, 10, 128);
	
	if(element_length > 0)
	{
		strcopy(result, length, element[element_length-1]);
		return true;
	}
	return false;
}

stock void SetCheckpointIndex(int wave)
{
	int entity = FindEntityByClassname(-1, "info_populator");
	if(IsValidEntity(entity))
	{
		SDKCall(hSetCheckpoint, entity, wave-1);
	}
}

stock int GetCurrentWaveCount()
{
	int entity = FindEntityByClassname(-1, "tf_objective_resource");
	return (GetEntProp(entity, Prop_Send, "m_nMannVsMachineWaveCount"));
}

stock void ClearGotoCache()
{
	for(int i = 1; i < sizeof(iGotoWave); i++)
	{
		iGotoWave[i] = -1;
	}
}

stock bool IsMvM()
{
	return (GameRules_GetProp("m_bPlayingMannVsMachine") != 0);
}