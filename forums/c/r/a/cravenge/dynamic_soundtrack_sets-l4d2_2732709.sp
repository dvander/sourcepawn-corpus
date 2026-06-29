#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.5.9"

enum struct MusicData
{
	char sSong[256];
	int iEntity;
	float fIntensity;
	bool bSurvivorOnly;
	bool bFromEntity;
}

MusicData md_Array;

int iSurvivorSet = 0;
char sLastMusic[256], sMusicPlayed[MAXPLAYERS+1][2][256];
Handle hDSSPlayMusic = null, hDSSStopMusic = null;

ArrayList al_Music;
StringMap sm_Music;

static bool bMusicFix = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[DSS] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Dynamic Soundtrack Sets",
	author = "DeathChaos25, Shadowysn, Lux, cravenge",
	description = "Adjusts soundtrack for both survivor sets.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=325391"
};

public void OnPluginStart()
{
	GameData gd_DSS = FetchGameData("dynamic_soundtrack_sets-l4d2");
	if (gd_DSS == null)
	{
		SetFailState("[DSS] Game Data Not Found!");
	}
	
	DynamicDetour dd_DSS = DynamicDetour.FromConf(gd_DSS, "Music::Play");
	if (dd_DSS == null)
	{
		SetFailState("[DSS] Signature \"Music::Play\" Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gd_DSS, SDKConf_Signature, "Music::Play");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hDSSPlayMusic = EndPrepSDKCall();
	if (hDSSPlayMusic == null)
	{
		SetFailState("[DSS] Signature \"Music::Play\" Broken!");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gd_DSS, SDKConf_Signature, "Music::StopPlaying");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hDSSStopMusic = EndPrepSDKCall();
	if (hDSSStopMusic == null)
	{
		SetFailState("[DSS] Signature \"Music::StopPlaying\" Broken!");
	}
	
	delete gd_DSS;
	
	CreateConVar("dynamic_soundtrack_sets-l4d2_version", PLUGIN_VERSION, "Dynamic Soundtrack Sets Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("finale_escape_start", OnFinaleEscapeStart);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("defibrillator_used", OnDefibrillatorUsed);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_left_start_area", OnPlayerLeftStartArea);
	HookEvent("player_death", OnPlayerDeath);
	
	al_Music = new ArrayList(sizeof(MusicData));
	
	ListDynamicTracks();
	
	if (!dd_DSS.Enable(Hook_Pre, dtrPlayMusicPre))
	{
		SetFailState("[DSS] Pre-Detour Of \"Music::Play\" Failed!");
	}
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	char sTemp[256];
	FormatEx(sTemp, sizeof(sTemp), "%s", (strcmp(name, "finale_win") != 0) ? ((strcmp(name, "map_transition") != 0) ? "Event.ScenarioLose" : "Event.SafeRoom") : "Event.ScenarioWin");
	SwapMusicSet(sTemp, (strcmp(name, "map_transition") == 0));
}

public void OnFinaleEscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	SwapMusicSet("Event.FinalBattle");
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (!revived || GetClientTeam(revived) != 2)
	{
		return;
	}
	
	if (sMusicPlayed[revived][0][0] != '\0')
	{
		if (StrContains(sMusicPlayed[revived][0], "Down") == -1 && StrContains(sMusicPlayed[revived][0], "BleedingOut") == -1)
		{
			return;
		}
		
		ToggleMusicTrack(revived, sMusicPlayed[revived][0], false, _, 1.0);
		sMusicPlayed[revived][0][0] = '\0';
	}
}

public void OnDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	int defibbed = GetClientOfUserId(event.GetInt("subject"));
	if (!defibbed || GetClientTeam(defibbed) != 2)
	{
		return;
	}
	
	char sTemp[256];
	
	FormatEx(sTemp, sizeof(sTemp), "Event.SurvivorDeath");
	if (GetEntProp(defibbed, Prop_Send, "m_survivorCharacter") > 3)
	{
		StrCat(sTemp, sizeof(sTemp), "_L4D1");
	}
	
	ToggleMusicTrack(defibbed, sTemp, false, _, 1.0);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int spawned = GetClientOfUserId(event.GetInt("userid"));
	if (spawned < 1 || !IsClientInGame(spawned) || GetClientTeam(spawned) != 2)
	{
		return;
	}
	
	for (int i = 0; i < 2; i++)
	{
		if (sMusicPlayed[spawned][i][0] == '\0')
		{
			continue;
		}
		
		ToggleMusicTrack(spawned, sMusicPlayed[spawned][i], false, _, 1.0);
		sMusicPlayed[spawned][i][0] = '\0';
	}
}

public void OnPlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("userid"));
	if (!player || GetClientTeam(player) != 2 || IsFakeClient(player))
	{
		return;
	}
	
	char sTemp[256];
	
	FormatEx(sTemp, sizeof(sTemp), "Event.LargeAreaRevealed");
	if (iSurvivorSet == 1)
	{
		StrCat(sTemp, sizeof(sTemp), "_L4D1");
	}
	
	int iIndex = al_Music.FindString(sTemp);
	if (iIndex != -1)
	{
		sm_Music.GetString(sTemp, sTemp, sizeof(sTemp));
		
		al_Music.GetArray(iIndex, md_Array);
		al_Music.Erase(iIndex);
		
		int iCharacter = GetEntProp(player, Prop_Send, "m_survivorCharacter");
		if ((StrContains(md_Array.sSong, "_L4D1") == -1 && iCharacter > 3) || (StrContains(md_Array.sSong, "_L4D1") != -1 && iCharacter < 4))
		{
			bMusicFix = true;
			
			ToggleMusicTrack(player, md_Array.sSong, false);
			ToggleMusicTrack(player, sTemp, true, md_Array.iEntity, md_Array.fIntensity, md_Array.bSurvivorOnly, md_Array.bFromEntity);
			
			bMusicFix = false;
		}
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (!died || GetClientTeam(died) != 2)
	{
		return;
	}
	
	for (int i = 0; i < 2; i++)
	{
		if (sMusicPlayed[died][i][0] == '\0')
		{
			continue;
		}
		
		if (i == 1 || StrContains(sMusicPlayed[died][i], "SurvivorDeath") == -1)
		{
			ToggleMusicTrack(died, sMusicPlayed[died][i], false);
		}
		sMusicPlayed[died][i][0] = '\0';
	}
}

public Action L4D_OnGetSurvivorSet(int &retVal)
{
	if (iSurvivorSet != 0 && iSurvivorSet == retVal)
	{
		return Plugin_Continue;
	}
	
	iSurvivorSet = retVal;
	return Plugin_Continue;
}

public Action L4D_OnFastGetSurvivorSet(int &retVal)
{
	if (iSurvivorSet != 0 && iSurvivorSet == retVal)
	{
		return Plugin_Continue;
	}
	
	iSurvivorSet = retVal;
	return Plugin_Continue;
}

GameData FetchGameData(const char[] sFileName)
{
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/%s.txt", sFileName);
	if (!FileExists(sFilePath))
	{
		File fileTemp = OpenFile(sFilePath, "w");
		if (fileTemp == null)
		{
			SetFailState("[DSS] Game Data Creation Aborted!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Functions\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			// Courtesy of Lux");
		fileTemp.WriteLine("			\"Music::Play\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"		\"Music::Play\"");
		fileTemp.WriteLine("				\"callconv\"		\"thiscall\"");
		fileTemp.WriteLine("				\"return\"			\"void\"");
		fileTemp.WriteLine("				\"this\"			\"ignore\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"	\"charptr\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a2\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"	\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a3\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"	\"float\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a4\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"	\"bool\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a5\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"	\"bool\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			// Courtesy of Lux");
		fileTemp.WriteLine("			\"Music::Play\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN5Music4PlayEPKcifbb\"");
		fileTemp.WriteLine("				\"mac\"		\"@_ZN5Music4PlayEPKcifbb\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x81\\xEC\\xDC\\x2A\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x33\\x2A\\x89\\x2A\\x2A\\xA1\"");
		fileTemp.WriteLine("				/* 55 8B ? 81 EC DC ? ? ? A1 ? ? ? ? 33 ? 89 ? ? A1 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"Music::StopPlaying\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN5Music11StopPlayingEPKcfb\"");
		fileTemp.WriteLine("				\"mac\"		\"@_ZN5Music11StopPlayingEPKcfb\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x83\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x2A\\x56\\x8B\\x2A\\x89\\x2A\\x2A\\x0F\\x84\\x25\"");
		fileTemp.WriteLine("				/* 55 8B ? 83 ? ? A1 ? ? ? ? 83 ? ? ? 56 8B ? 89 ? ? 0F 84 25 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	
	return new GameData(sFileName);
}

public MRESReturn dtrPlayMusicPre(DHookParam hParams)
{
	if (bMusicFix)
	{
		return MRES_Ignored;
	}
	
	char sParam[2][256];
	
	hParams.GetString(1, sParam[0], sizeof(sParam[]));
	if (sm_Music.GetString(sParam[0], sParam[1], sizeof(sParam[])))
	{
		int iParam = hParams.Get(2);
		if (iParam > 0)
		{
			if (iParam > MaxClients || GetClientTeam(iParam) != 2)
			{
				return MRES_Ignored;
			}
			
			int iCharacter = GetEntProp(iParam, Prop_Send, "m_survivorCharacter");
			if ((StrContains(sParam[0], "_L4D1") != -1 && iCharacter < 4) || (StrContains(sParam[0], "_L4D1") == -1 && iCharacter > 3))
			{
				if (StrContains(sParam[1], "ZombieChoir") == -1)
				{
					if (sLastMusic[0] == '\0' || strcmp(sLastMusic, sParam[1]) != 0)
					{
						strcopy(sLastMusic, sizeof(sLastMusic), sParam[1]);
					}
					
					if (sMusicPlayed[iParam][0][0] == '\0' || strcmp(sMusicPlayed[iParam][0], sParam[1]) != 0)
					{
						strcopy(sMusicPlayed[iParam][0], sizeof(sMusicPlayed[][]), sParam[1]);
						ReplaceStringEx(sMusicPlayed[iParam][0], sizeof(sMusicPlayed[][]), "Hit", "");
					}
				}
				
				hParams.SetString(1, sParam[1]);
				return MRES_ChangedHandled;
			}
		}
		else
		{
			if (sLastMusic[0] != '\0')
			{
				ReplaceStringEx(sLastMusic, sizeof(sLastMusic), "Hit", "");
				
				char sTemp[256];
				FormatEx(sTemp, sizeof(sTemp), "%s", sLastMusic);
				sLastMusic[0] = '\0';
				
				if (sParam[0][6] != sTemp[6])
				{
					return MRES_Ignored;
				}
				
				hParams.SetString(1, sTemp);
				return MRES_ChangedHandled;
			}
			
			if (al_Music.FindString(sParam[0]) == -1)
			{
				strcopy(md_Array.sSong, sizeof(md_Array.sSong), sParam[0]);
				
				md_Array.iEntity = iParam;
				
				md_Array.bSurvivorOnly = hParams.Get(4);
				md_Array.bFromEntity = hParams.Get(5);
				
				md_Array.fIntensity = hParams.Get(3);
				
				al_Music.PushArray(md_Array);
			}
		}
	}
	return MRES_Ignored;
}

void ListDynamicTracks()
{
	sm_Music = new StringMap();
	
	sm_Music.SetString("Event.Down", "Event.Down_L4D1");
	sm_Music.SetString("Event.DownHit", "Event.DownHit_L4D1");
	sm_Music.SetString("Event.BleedingOut", "Event.BleedingOut_L4D1");
	sm_Music.SetString("Event.BleedingOutHit", "Event.BleedingOutHit_L4D1");
	sm_Music.SetString("Event.BleedingOutEnd", "Event.BleedingOutEnd_L4D1");
	sm_Music.SetString("Event.SurvivorDeath", "Event.SurvivorDeath_L4D1");
	sm_Music.SetString("Event.SurvivorDeathHit", "Event.SurvivorDeathHit_L4D1");
	sm_Music.SetString("Event.ScenarioLose", "Event.ScenarioLose_L4D1");
	sm_Music.SetString("Event.FinalBattle", "Event.FinalBattle_L4D1");
	sm_Music.SetString("Event.ScenarioWin", "Event.ScenarioWin_L4D1");
	sm_Music.SetString("Event.SafeRoom", "Event.SafeRoom_L4D1");
	sm_Music.SetString("Event.ZombieChoir", "Event.ZombieChoir_L4D1");
	sm_Music.SetString("Event.LargeAreaRevealed", "Event.LargeAreaRevealed_L4D1");
	
	sm_Music.SetString("Event.Down_L4D1", "Event.Down");
	sm_Music.SetString("Event.DownHit_L4D1", "Event.DownHit");
	sm_Music.SetString("Event.BleedingOut_L4D1", "Event.BleedingOut");
	sm_Music.SetString("Event.BleedingOutHit_L4D1", "Event.BleedingOutHit");
	sm_Music.SetString("Event.BleedingOutEnd_L4D1", "Event.BleedingOutEnd");
	sm_Music.SetString("Event.SurvivorDeath_L4D1", "Event.SurvivorDeath");
	sm_Music.SetString("Event.SurvivorDeathHit_L4D1", "Event.SurvivorDeathHit");
	sm_Music.SetString("Event.ScenarioLose_L4D1", "Event.ScenarioLose");
	sm_Music.SetString("Event.FinalBattle_L4D1", "Event.FinalBattle");
	sm_Music.SetString("Event.ScenarioWin_L4D1", "Event.ScenarioWin");
	sm_Music.SetString("Event.SafeRoom_L4D1", "Event.SafeRoom");
	sm_Music.SetString("Event.ZombieChoir_L4D1", "Event.ZombieChoir");
	sm_Music.SetString("Event.LargeAreaRevealed_L4D1", "Event.LargeAreaRevealed");
}

void SwapMusicSet(char sGivenMusic[256], bool bIsAliveOnly = false)
{
	if (iSurvivorSet == 1)
	{
		StrCat(sGivenMusic, sizeof(sGivenMusic), "_L4D1");
	}
	
	DataPack dpMusicTrack = new DataPack();
	dpMusicTrack.WriteString(sGivenMusic);
	dpMusicTrack.WriteCell(bIsAliveOnly);
	RequestFrame(PlayProperTrack, dpMusicTrack);
}

public void PlayProperTrack(any data)
{
	bool bIsAliveOnly;
	char sTemp[256];
	
	DataPack dpTemp = data;
	dpTemp.Reset();
	
	dpTemp.ReadString(sTemp, sizeof(sTemp));
	bIsAliveOnly = dpTemp.ReadCell();
	
	delete dpTemp;
	
	int iIndex = al_Music.FindString(sTemp);
	if (iIndex == -1)
	{
		return;
	}
	
	sm_Music.GetString(sTemp, sTemp, sizeof(sTemp));
	
	al_Music.GetArray(iIndex, md_Array);
	al_Music.Erase(iIndex);
	
	bMusicFix = true;
	
	int iCharacter;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || (bIsAliveOnly && !IsPlayerAlive(i)) || IsFakeClient(i))
		{
			continue;
		}
		
		iCharacter = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		if ((StrContains(md_Array.sSong, "_L4D1") == -1 && iCharacter > 3) || (StrContains(md_Array.sSong, "_L4D1") != -1 && iCharacter < 4))
		{
			if (sMusicPlayed[i][1][0] == '\0' || strcmp(sMusicPlayed[i][1], sTemp) != 0)
			{
				strcopy(sMusicPlayed[i][1], sizeof(sMusicPlayed[][]), sTemp);
			}
			
			ToggleMusicTrack(i, md_Array.sSong, false);
			ToggleMusicTrack(i, sTemp, true, md_Array.iEntity, md_Array.fIntensity, md_Array.bSurvivorOnly, md_Array.bFromEntity);
		}
	}
	
	bMusicFix = false;
}

void ToggleMusicTrack(int client, char[] sGivenVal, bool bEnable, int iGivenVal = 0, float fGivenVal = 0.0, bool bGivenValA = false, bool bGivenValB = false)
{
	Address aTemp = GetEntityAddress(client) + view_as<Address>(GetEntSendPropOffs(client, "m_music"));
	
	if (!bEnable)
	{
		SDKCall(hDSSStopMusic, aTemp, sGivenVal, fGivenVal, bGivenValA);
		return;
	}
	
	SDKCall(hDSSPlayMusic, aTemp, sGivenVal, iGivenVal, fGivenVal, bGivenValA, bGivenValB);
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client));
}

