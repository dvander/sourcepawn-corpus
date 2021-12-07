#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

ConVar bhpDistance, bhpMaxAttempts, bhpCoolTime, bhpShowDamage, bhpShowDistance, bhpShowKills,
	bhpAvgDistance, bhpRankType, bhpListMax, bhpListType;

float fDistance, fCoolTime, fPouncePos[MAXPLAYERS+1][3];
int iMaxAttempts, iRankType, iListMax, iListType, iPounces[MAXPLAYERS+1], iPenalty[MAXPLAYERS+1],
	iListPage[MAXPLAYERS+1] = 1;

Handle hPenaltyTime[MAXPLAYERS+1] = null;
bool bShowDamage, bShowDistance, bShowKills, bAvgDistance, bShowPenalty[MAXPLAYERS+1], bListDone;
char sGame[12], sMap[64];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead", false) && !StrEqual(sGame, "left4dead2", false))
	{
		strcopy(error, err_max, "[BHP] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Brutal Hunter Pounce",
	author = "cravenge",
	description = "Makes Higher Pounces Deadly And Worth Taking.",
	version = "3.12",
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("brutal_hunter_pounce_version", "3.12", "Brutal Hunter Pounce Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	bhpDistance = CreateConVar("brutal_hunter_pounce_distance", "1750.0", "Distance To Make Deadly Hunter Pounces", FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0);
	bhpMaxAttempts = CreateConVar("brutal_hunter_pounce_max_attempts", "2", "Maximum Attempts Of Brutal Hunter Pounces", FCVAR_NOTIFY|FCVAR_SPONLY);
	bhpCoolTime = CreateConVar("brutal_hunter_pounce_cool_time", "60.0", "Cool Time For Every Smashing Hunter Pounce", FCVAR_NOTIFY|FCVAR_SPONLY);
	bhpShowDamage = CreateConVar("brutal_hunter_pounce_show_damage", "1", "Enable/Disable Damage Display", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bhpShowDistance = CreateConVar("brutal_hunter_pounce_show_distance", "1", "Enable/Disable Distance Display", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bhpShowKills = CreateConVar("brutal_hunter_pounce_show_kills", "1", "Enable/Disable Kills Display", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bhpAvgDistance = CreateConVar("brutal_hunter_pounce_avg_distance", "1", "Enable/Disable Average Distance", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bhpRankType = CreateConVar("brutal_hunter_pounce_rank_type", "0", "Rank Type: 0=By Kills, 1=By Damage, 2=By Distance", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	bhpListMax = CreateConVar("brutal_hunter_pounce_list_max", "10", "Maximum Number Of Players To List In The Stats", FCVAR_NOTIFY|FCVAR_SPONLY, true, 3.0, true, 10.0);
	bhpListType = CreateConVar("brutal_hunter_pounce_list_type", "1", "Stats Listing Type: 0=All Players, 1=Top Players Only", FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	fDistance = bhpDistance.FloatValue;
	fCoolTime = bhpCoolTime.FloatValue;
	
	iMaxAttempts = bhpMaxAttempts.IntValue;
	iRankType = bhpRankType.IntValue;
	iListMax = bhpListMax.IntValue;
	iListType = bhpListType.IntValue;
	
	bShowDamage = bhpShowDamage.BoolValue;
	bShowDistance = bhpShowDistance.BoolValue;
	bShowKills = bhpShowKills.BoolValue;
	bAvgDistance = bhpAvgDistance.BoolValue;
	
	bhpDistance.AddChangeHook(OnBHPCVarsChanged);
	bhpMaxAttempts.AddChangeHook(OnBHPCVarsChanged);
	bhpCoolTime.AddChangeHook(OnBHPCVarsChanged);
	bhpShowDamage.AddChangeHook(OnBHPCVarsChanged);
	bhpShowDistance.AddChangeHook(OnBHPCVarsChanged);
	bhpShowKills.AddChangeHook(OnBHPCVarsChanged);
	bhpAvgDistance.AddChangeHook(OnBHPCVarsChanged);
	bhpRankType.AddChangeHook(OnBHPCVarsChanged);
	bhpListMax.AddChangeHook(OnBHPCVarsChanged);
	bhpListType.AddChangeHook(OnBHPCVarsChanged);
	
	AutoExecConfig(true, "brutal_hunter_pounce");
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("ability_use", OnAbilityUse);
	HookEvent("lunge_pounce", OnLungePounce);
	
	RegConsoleCmd("sm_bhp_penalty", TogglePenalty, "Toggles Penalty Notification");
	RegConsoleCmd("sm_bhp_reset", ResetBHP, "Resets Brutal Pounce Count");
	
	RegConsoleCmd("sm_bhp_list", ListBHP, "Displays List Of Brutal Pounces Made");
	RegConsoleCmd("sm_tophunters", ListBHP, "Displays List Of Brutal Pounces Made");
}

public void OnBHPCVarsChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fDistance = bhpDistance.FloatValue;
	fCoolTime = bhpCoolTime.FloatValue;
	
	iMaxAttempts = bhpMaxAttempts.IntValue;
	iRankType = bhpRankType.IntValue;
	iListMax = bhpListMax.IntValue;
	iListType = bhpListType.IntValue;
	
	bShowDamage = bhpShowDamage.BoolValue;
	bShowDistance = bhpShowDistance.BoolValue;
	bShowKills = bhpShowKills.BoolValue;
	bAvgDistance = bhpAvgDistance.BoolValue;
}

public Action TogglePenalty(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (bShowPenalty[client])
	{
		bShowPenalty[client] = false;
	}
	else
	{
		bShowPenalty[client] = true;
	}
	PrintToChat(client, "\x04[\x05BHP\x04]\x01 Penalty Notification: \x03%s", (bShowPenalty[client]) ? "On" : "Off");
	return Plugin_Handled;
}

public Action ResetBHP(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	AdminId clientId = GetUserAdmin(client);
	if (clientId == INVALID_ADMIN_ID || iPounces[client] == 0)
	{
		PrintToChat(client, "\x04[\x05BHP\x04]\x01 Invalid!");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "\x04[\x05BHP\x04]\x01 BHP Counts Reset!");
	if (hPenaltyTime[client] != null)
	{
		hPenaltyTime[client] = null;
	}
	
	iPounces[client] = 0;
	iPenalty[client] = 0;
	
	return Plugin_Handled;
}

public Action ListBHP(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (iListPage[client] != 1)
	{
		iListPage[client] = 1;
	}
	BHPStats(client, _, _, _, _, iListPage[client]);
	
	return Plugin_Handled;
}

public void OnPluginEnd()
{
	bhpDistance.RemoveChangeHook(OnBHPCVarsChanged);
	bhpMaxAttempts.RemoveChangeHook(OnBHPCVarsChanged);
	bhpCoolTime.RemoveChangeHook(OnBHPCVarsChanged);
	bhpShowDamage.RemoveChangeHook(OnBHPCVarsChanged);
	bhpShowDistance.RemoveChangeHook(OnBHPCVarsChanged);
	bhpShowKills.RemoveChangeHook(OnBHPCVarsChanged);
	bhpAvgDistance.RemoveChangeHook(OnBHPCVarsChanged);
	bhpRankType.RemoveChangeHook(OnBHPCVarsChanged);
	bhpListMax.RemoveChangeHook(OnBHPCVarsChanged);
	bhpListType.RemoveChangeHook(OnBHPCVarsChanged);
	
	delete bhpDistance;
	delete bhpMaxAttempts;
	delete bhpCoolTime;
	delete bhpShowDamage;
	delete bhpShowDistance;
	delete bhpShowKills;
	delete bhpAvgDistance;
	delete bhpRankType;
	delete bhpListMax;
	delete bhpListType;
	
	UnhookEvent("round_start", OnRoundEvents);
	UnhookEvent("round_end", OnRoundEvents);
	UnhookEvent("map_transition", OnRoundEvents);
	
	UnhookEvent("ability_use", OnAbilityUse);
	UnhookEvent("lunge_pounce", OnLungePounce);
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (fDistance < 1.0)
	{
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iPounces[i] = 0;
			iPenalty[i] = 0;
			iListPage[i] = 1;
			
			bShowPenalty[i] = true;
			
			for (int i2 = 0; i2 < 3; i2++)
			{
				fPouncePos[i][i2] = 0.0;
			}
			if (hPenaltyTime[i] != null)
			{
				if (StrEqual(sGame, "left4dead2", false))
				{
					KillTimer(hPenaltyTime[i]);
				}
				hPenaltyTime[i] = null;
			}
		}
	}
}

public void OnAbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	if (fDistance <= 0.0)
	{
		return;
	}
	
	int user = GetClientOfUserId(event.GetInt("userid"));
	if (user < 1 || !IsClientInGame(user) || GetClientTeam(user) != 3 || GetEntProp(user, Prop_Send, "m_zombieClass") != 3)
	{
		return;
	}
	
	char sAbility[24];
	event.GetString("ability", sAbility, 24);
	if (StrEqual(sAbility, "ability_lunge", false))
	{
		if (iPounces[user] <= iMaxAttempts)
		{
			GetClientAbsOrigin(user, fPouncePos[user]);
		}
		
		if (!IsFakeClient(user))
		{
			CreateTimer(0.1, MakeFartherPounce, user);
		}
	}
}

public Action MakeFartherPounce(Handle timer, any client)
{
	KillTimer(timer);
	if (!IsServerProcessing())
	{
		return Plugin_Stop;
	}
	
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	fVelocity[0] *= 1.6;
	fVelocity[1] *= 1.6;
	fVelocity[2] *= 1.8;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	return Plugin_Stop;
}

public void OnLungePounce(Event event, const char[] name, bool dontBroadcast)
{
	if (fDistance < 1.0)
	{
		return;
	}
	
	int pouncer = GetClientOfUserId(event.GetInt("userid"));
	if (pouncer < 1 || pouncer > MaxClients || !IsClientInGame(pouncer) || GetClientTeam(pouncer) != 3 || GetEntProp(pouncer, Prop_Send, "m_zombieClass") != 3)
	{
		return;
	}
	
	int pounced = GetClientOfUserId(event.GetInt("victim"));
	if (pounced < 1 || pounced > MaxClients || !IsClientInGame(pounced) || GetClientTeam(pounced) != 2)
	{
		return;
	}
	
	float fLandedPos[3];
	GetClientAbsOrigin(pouncer, fLandedPos);
	
	if (GetVectorDistance(fPouncePos[pouncer], fLandedPos) < fDistance)
	{
		PrintToChat(pouncer, "\x04[\x05BHP\x04]\x01 Failed! \x05(\x04%.1f\x05 / \x04%.1f\x05)", GetVectorDistance(fPouncePos[pouncer], fLandedPos), fDistance);
		return;
	}
	
	if (iPounces[pouncer] > iMaxAttempts)
	{
		PrintToChat(pouncer, "\x04[\x05BHP\x04]\x01 Maximum Limits Reached!%s", (GetUserAdmin(pouncer) == INVALID_ADMIN_ID) ? "" : " Type \x04!bhp_reset\x01 To Reset Your BHP!");
		return;
	}
	
	if (iPenalty[pouncer] > 0)
	{
		if (!bShowPenalty[pouncer])
		{
			PrintToChat(pouncer, "\x04[\x05BHP\x04]\x01 Please Wait!");
		}
		return;
	}
	
	int iDmg = (GetEntProp(pounced, Prop_Send, "m_isIncapacitated", 1)) ? GetClientHealth(pounced) : (GetClientHealth(pounced) + FindConVar("survivor_incap_health").IntValue);
	BHPStats(pouncer, 1, iDmg, RoundFloat(GetVectorDistance(fPouncePos[pouncer], fLandedPos)), true);
	
	Event ePlayerHurt = CreateEvent("player_hurt", true);
	ePlayerHurt.SetInt("userid", GetClientUserId(pounced));
	ePlayerHurt.SetInt("attacker", GetClientUserId(pouncer));
	ePlayerHurt.SetString("weapon", "hunter_claw");
	ePlayerHurt.SetInt("dmg_health", iDmg);
	ePlayerHurt.Fire();
	
	if (!GetEntProp(pounced, Prop_Send, "m_isIncapacitated", 1) && GetEntProp(pounced, Prop_Send, "m_currentReviveCount") < FindConVar("survivor_max_incapacitated_count").IntValue)
	{
		Event ePlayerIncapacitated = CreateEvent("player_incapacitated", true);
		ePlayerIncapacitated.SetInt("userid", GetClientUserId(pounced));
		ePlayerIncapacitated.SetInt("attacker", GetClientUserId(pouncer));
		ePlayerIncapacitated.SetString("weapon", "hunter_claw");
		ePlayerIncapacitated.Fire();
	}
	ForcePlayerSuicide(pounced);
	
	Event ePlayerDeath = CreateEvent("player_death", true);
	ePlayerDeath.SetInt("userid", GetClientUserId(pounced));
	ePlayerDeath.SetInt("attacker", GetClientUserId(pouncer));
	ePlayerDeath.SetString("weapon", "hunter_claw");
	ePlayerDeath.Fire();
	
	iPounces[pouncer] += 1;
	PrintToChat(pouncer, "\x04[\x05BHP\x04]\x01 Attempts: \x04%d\x01 / \x04%i", iPounces[pouncer], iMaxAttempts + 1);
	
	if (bShowDamage && bShowDistance)
	{
		PrintToChatAll("\x04[\x05BHP\x04] \x03%N\x01 Brutally Pounced \x03%N\x01! \x05[%.2f Units / %i Dmg]", pouncer, pounced, GetVectorDistance(fPouncePos[pouncer], fLandedPos), iDmg);
	}
	else if (bShowDamage)
	{
		PrintToChatAll("\x04[\x05BHP\x04] \x03%N\x01 Brutally Pounced \x03%N\x01! \x05[%i Dmg]", pouncer, pounced, iDmg);
	}
	else if (bShowDistance)
	{
		PrintToChatAll("\x04[\x05BHP\x04] \x03%N\x01 Brutally Pounced \x03%N\x01! \x05[%.2f Units]", pouncer, pounced, GetVectorDistance(fPouncePos[pouncer], fLandedPos));
	}
	else
	{
		PrintToChatAll("\x04[\x05BHP\x04] \x03%N\x01 Brutally Pounced \x03%N\x01!", pouncer, pounced);
	}
	
	if (hPenaltyTime[pouncer] == null)
	{
		iPenalty[pouncer] = RoundToNearest(fCoolTime * iPounces[pouncer]);
		hPenaltyTime[pouncer] = CreateTimer(1.0, ShowNextBP, pouncer, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public Action ShowNextBP(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		if (hPenaltyTime[client] != null)
		{
			if (StrEqual(sGame, "left4dead2", false))
			{
				KillTimer(hPenaltyTime[client]);
			}
			hPenaltyTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	if (hPenaltyTime[client] == null)
	{
		return Plugin_Stop;
	}
	
	if (iPenalty[client] < 1)
	{
		PrintToChat(client, "\x04[\x05BHP\x04]\x01 You Can Brutal Pounce Again!");
		
		if (hPenaltyTime[client] != null)
		{
			if (StrEqual(sGame, "left4dead2", false))
			{
				KillTimer(hPenaltyTime[client]);
			}
			hPenaltyTime[client] = null;
		}
		return Plugin_Stop;
	}
	
	if (bShowPenalty[client])
	{
		PrintHintText(client, "%d %s Before Next Brutal Pounce!\nType !bhp_penalty To Toggle This Notification!", iPenalty[client], (iPenalty[client] == 1) ? "Second" : "Seconds");
	}
	iPenalty[client] -= 1;
	return Plugin_Continue;
}

void BHPStats(int client, int iKill = 0, int iDamage = 0, int iDistance = 0, bool bUpdate = false, int iPage = 1)
{
	char sRequirePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sRequirePath, sizeof(sRequirePath), "data/bhpstats");
	if (!DirExists(sRequirePath))
	{
		CreateDirectory(sRequirePath, FPERM_O_READ|FPERM_O_WRITE|FPERM_O_EXEC);
	}
	
	BuildPath(Path_SM, sRequirePath, sizeof(sRequirePath), "data/bhpstats/%s.txt", sMap);
	KeyValues kvStats = new KeyValues("bhpstats");
	
	if (!bUpdate)
	{
		if (!kvStats.ImportFromFile(sRequirePath))
		{
			PrintToChat(client, "\x04[\x05BHP\x04]\x01 No Saved Data!");
			delete kvStats;
			
			return;
		}
		
		kvStats.JumpToKey("pouncers");
		int iTotal = kvStats.GetNum("total", 0);
		
		decl String:bhpNames[iTotal][MAX_NAME_LENGTH];
		new bhpRecord[iTotal][4];
		
		kvStats.GoBack();
		kvStats.JumpToKey("records");
		kvStats.GotoFirstSubKey();
		
		for (int i = 0; i < iTotal; i++)
		{
			kvStats.GetString("name", bhpNames[i], MAX_NAME_LENGTH, "Unknown Player");
			
			bhpRecord[i][0] = i;
			bhpRecord[i][1] = kvStats.GetNum("kills", 0);
			bhpRecord[i][2] = kvStats.GetNum("dmg", 0);
			bhpRecord[i][3] = kvStats.GetNum("dist", 0);
			
			kvStats.GotoNextKey();
		}
		
		SortCustom2D(bhpRecord, iTotal, BPRankSort);
		
		Panel pStats = new Panel();
		
		char sTitle[128];
		Format(sTitle, sizeof(sTitle), "BHP Stats: (%s)", sMap);
		pStats.SetTitle(sTitle);
		
		pStats.DrawText(" \n");
		
		char sTextList[128];
		for (int i = (iListType == 0 && iPage > 1) ? iListMax * iPage : 0; i < iTotal; i++)
		{
			if (bShowKills)
			{
				if (bShowDamage && bShowDistance)
				{
					if (i == 0)
					{
						if (bAvgDistance)
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills  |  Damage  |  Avg. Distance");
						}
						else
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills  |  Damage  |  Distance");
						}
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d | %d | %d", i + 1, bhpNames[bhpRecord[i][0]], bhpRecord[i][1], bhpRecord[i][2], bhpRecord[i][3]);
				}
				else if (bShowDamage)
				{
					if (i == 0)
					{
						strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills  |  Damage");
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d | %d", i+1, bhpNames[bhpRecord[i][0]], bhpRecord[i][1], bhpRecord[i][2]);
				}
				else if (bShowDistance)
				{
					if (i == 0)
					{
						if (bAvgDistance)
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills  |  Avg. Distance");
						}
						else
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills  |  Distance");
						}
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d | %d", i+1, bhpNames[bhpRecord[i][0]], bhpRecord[i][1], bhpRecord[i][3]);
				}
				else
				{
					if (i == 0)
					{
						strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Kills");
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d", i + 1, bhpNames[bhpRecord[i][0]], bhpRecord[i][1]);
				}
			}
			else
			{
				if (bShowDamage && bShowDistance)
				{
					if (i == 0)
					{
						if (!bAvgDistance)
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Damage  |  Distance");
						}
						else
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Damage  |  Avg. Distance");
						}
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d | %d", i + 1, bhpNames[bhpRecord[i][0]], bhpRecord[i][2], bhpRecord[i][3]);
				}
				else if (bShowDamage)
				{
					if (i == 0)
					{
						strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Damage");
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d", i + 1, bhpNames[bhpRecord[i][0]], bhpRecord[i][2]);
				}
				else if (bShowDistance)
				{
					if (i == 0)
					{
						if (!bAvgDistance)
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Distance");
						}
						else
						{
							strcopy(sTextList, sizeof(sTextList), "No.    Name    -  Avg. Distance");
						}
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s - %d", i + 1, bhpNames[bhpRecord[i][0]], bhpRecord[i][3]);
				}
				else
				{
					if (i == 0)
					{
						strcopy(sTextList, sizeof(sTextList), "No.    Name    ");
						pStats.DrawText(sTextList);
					}
					Format(sTextList, sizeof(sTextList), "%i. %s", i + 1, bhpNames[bhpRecord[i][0]]);
				}
			}
			pStats.DrawText(sTextList);
			
			if (i >= (iListMax * iPage) - 1 || i >= iTotal)
			{
				pStats.DrawText(" \n");
				
				if (iListType != 1)
				{
					if (iPage > 1)
					{
						pStats.DrawItem("Back");
					}
					
					if (i + iListMax < iTotal)
					{
						pStats.DrawItem("Next");
					}
					pStats.DrawText(" \n");
				}
				
				break;
			}
		}
		
		Format(sTextList, sizeof(sTextList), "%d Brutal %s Recorded On This Map!", iTotal, (iTotal > 1) ? "Pouncers" : "Pouncer");
		pStats.DrawText(sTextList);
		
		pStats.Send(client, pStatsHandler, 20);
		delete pStats;
	}
	else
	{
		char sFileVersion[16];
		kvStats.GetString("Version", sFileVersion, sizeof(sFileVersion), "0.0");
		if (FileExists(sRequirePath) && !StrEqual(sFileVersion, "3.12", false))
		{
			DeleteFile(sRequirePath);
		}
		
		char sName[MAX_NAME_LENGTH], sSteamID[32];
		int iTotal, iTotalKill, iTotalDmg, iTotalDist;
		
		GetClientName(client, sName, sizeof(sName));
		GetClientAuthString(client, sSteamID, sizeof(sSteamID));
		
		kvStats.ImportFromFile(sRequirePath);
		kvStats.SetString("version", "3.12");
		kvStats.JumpToKey("records", true);
		
		if (!kvStats.JumpToKey(sSteamID))
		{
			kvStats.GoBack();
			kvStats.JumpToKey("pouncers", true);
			
			iTotal = kvStats.GetNum("total", 0);
			iTotal += 1;
			
			kvStats.SetNum("total", iTotal);
			kvStats.GoBack();
			
			kvStats.JumpToKey("records");
			kvStats.JumpToKey(sSteamID, true);
		}
		
		kvStats.SetString("name", sName);
		
		iTotalKill = kvStats.GetNum("kills", 0);
		iTotalKill += 1;
		
		kvStats.SetNum("kills", iTotalKill);
		
		iTotalDmg = kvStats.GetNum("dmg", 0);
		iTotalDmg += iDamage;
		
		kvStats.SetNum("dmg", iTotalDmg);
		
		iTotalDist = kvStats.GetNum("dist", 0);
		iTotalDist += iDistance;
		
		if (bAvgDistance)
		{
			kvStats.SetNum("dist", RoundFloat(float(iTotalDist) / float(iTotalKill)));
		}
		else
		{
			kvStats.SetNum("dist", iTotalDist);
		}
		
		kvStats.Rewind();
		kvStats.ExportToFile(sRequirePath);
	}
	
	delete kvStats;
}

public int BPRankSort(int[] array1, int[] array2, const int[][] completeArray, Handle hndl)
{
	if (array1[iRankType+1] > array2[iRankType+1])
	{
		return -1;
	}
	
	if (array1[iRankType+1] == array2[iRankType+1])
	{
		return 0;
	}
	
	return 1;
}

public int pStatsHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select && iListType != 0)
	{
		if (param1 > 0 && param1 <= MaxClients && IsClientInGame(param1))
		{
			iListPage[param1] += (param2 == 1) ? 1 : (-1);
			BHPStats(param1, _, _, _, _, iListPage[param1]);
		}
	}
}

