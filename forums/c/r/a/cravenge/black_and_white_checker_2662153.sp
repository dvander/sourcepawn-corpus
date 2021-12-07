#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <glow>

#define PLUGIN_VERSION "1.8"

ConVar bawcNotify, bawcLivingAnnounce, bawcExclude, cvarGameMode, cvarPillsDecayRate, cvarMaxIncapCount;
int iNotify, iMaxIncapCount, iBWEnt[MAXPLAYERS+1];
bool bLivingAnnounce, bIsL4D1, bLateLoad, bCompatbility, bCheckFix;
float fPillsDecayRate;
char sExclude[512], sGameMode[16], sMap[64];

char sSurvivorModels[9][] =
{
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_adawong.mdl"
};

char sSurvivorNames[9][] =
{
	"Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis", "Ada Wong"
};

char sInfectednames[8][] =
{
	"Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead && evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[BAWC] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	bIsL4D1 = (evRetVal == Engine_Left4Dead) ? true : false;
	
	bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Black And White Checker",
	author = "cravenge, DarkNoghri, madcap, retsam, Merudo, Lux",
	description = "Lets Everyone Know When Someone Will Be Dying.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=317956"
};

public void OnPluginStart()
{
	AutoLoadTranslations("[BAWC]", "bawc.phrases");
	AutoLoadTranslations("[BAWC]", "l4d2.phrases");
	
	cvarGameMode = FindConVar("mp_gamemode");
	cvarPillsDecayRate = FindConVar("pain_pills_decay_rate");
	cvarMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	
	iMaxIncapCount = cvarMaxIncapCount.IntValue;
	fPillsDecayRate = cvarPillsDecayRate.FloatValue;
	
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	cvarGameMode.AddChangeHook(OnBAWCCVarsChanged);
	cvarPillsDecayRate.AddChangeHook(OnBAWCCVarsChanged);
	cvarMaxIncapCount.AddChangeHook(OnBAWCCVarsChanged);
	
	CreateConVar("black_and_white_checker_version", PLUGIN_VERSION, "Black And White Checker Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bawcNotify = CreateConVar("bawc_notify", "1", "Notifications: 0=Off, 1=Survivors Only, 2=On, 3=Infected Only", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	bawcLivingAnnounce = CreateConVar("bawc_living_announce", "1", "Enable/Disable Alive Survivors Announcements", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bawcExclude = CreateConVar("bawc_exclude", "l4d2_stadium3_city1,qe_", "Apply Aura Function Instead In These Maps", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	iNotify = bawcNotify.IntValue;
	bLivingAnnounce = bawcLivingAnnounce.BoolValue;
	
	bawcExclude.GetString(sExclude, sizeof(sExclude));
	
	bawcNotify.AddChangeHook(OnBAWCCVarsChanged);
	bawcLivingAnnounce.AddChangeHook(OnBAWCCVarsChanged);
	bawcExclude.AddChangeHook(OnBAWCCVarsChanged);
	
	AutoExecConfig(true, "black_and_white_checker");
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("player_death", OnPlayerDeath);
	if (!bIsL4D1)
	{
		HookEvent("defibrillator_used", OnDefibrillatorUsed);
	}
	
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	
	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnBAWCCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iMaxIncapCount = cvarMaxIncapCount.IntValue;
	fPillsDecayRate = cvarPillsDecayRate.FloatValue;
	
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	iNotify = bawcNotify.IntValue;
	bLivingAnnounce = bawcLivingAnnounce.BoolValue;
	
	bawcExclude.GetString(sExclude, sizeof(sExclude));
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			DetectBWState(i, false);
		}
	}
}

public void OnAllPluginsLoaded()
{
	bCompatbility = (FindConVar("l4d_graves_version") != null || FindConVar("l4d_hats_version") != null);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnPostThinkPost(int client)
{
	if (!bCheckFix || (GetClientTeam(client) != 2 && GetClientTeam(client) != 4))
	{
		return;
	}
	
	DetectBWState(client, (IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_currentReviveCount") >= iMaxIncapCount) ? true : false);
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (iNotify == 0 || !event.GetBool("lastlife"))
	{
		return;
	}
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (revived)
	{
		if (GetClientTeam(revived) != 2 && GetClientTeam(revived) != 4)
		{
			return;
		}
		
		int i, iNumMatch = -1;
		char sRevivedName[2][128], sHUDText[100];
		
		if (!IsFakeClient(revived))
		{
			char sRevivedModel[128];
			GetEntPropString(revived, Prop_Data, "m_ModelName", sRevivedModel, sizeof(sRevivedModel));
			
			for (i = 0; i < 9; i++)
			{
				if (strcmp(sRevivedModel, sSurvivorModels[i], false) != 0)
				{
					continue;
				}
				
				iNumMatch = i;
				break;
			}
		}
		
		GetClientName(revived, sRevivedName[0], sizeof(sRevivedName[]));
		for (i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || i == revived)
			{
				continue;
			}
			
			if (iNotify == 2 || (iNotify == 1 && (GetClientTeam(i) == 2 || GetClientTeam(i) == 4)) || (iNotify == 3 && GetClientTeam(i) == 3))
			{
				if (IsFakeClient(revived))
				{
					TranslateBotName(i, sRevivedName[0], sRevivedName[1], sizeof(sRevivedName[]));
					
					FormatEx(sHUDText, sizeof(sHUDText), "%T", "BAWC_FATAL_STATE_BOT", i, sRevivedName[1]);
				}
				else
				{
					if (iNumMatch == -1)
					{
						break;
					}
					
					TranslateBotName(i, sSurvivorNames[iNumMatch], sRevivedName[1], sizeof(sRevivedName[]));
					
					FormatEx(sHUDText, sizeof(sHUDText), "%T", "BAWC_FATAL_STATE_HUMAN", i, sRevivedName[0], sRevivedName[1]);
				}
				ShowHelpfulHint(i, revived, sHUDText, _, "icon_alert", "icon_alert", _, "2", "10", "20000.0", (!bIsL4D1) ? true : false, "bawc_help");
			}
		}
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bLivingAnnounce)
	{
		return;
	}
	
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (died)
	{
		if (GetClientTeam(died) != 2 && GetClientTeam(died) != 4)
		{
			return;
		}
		
		int killer = GetClientOfUserId(event.GetInt("attacker")),
			iAliveSurvivors = GetAliveSurvivorsCount();
		
		char sName[4][128];
		
		GetClientName(died, sName[0], sizeof(sName[]));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}
			
			if (IsFakeClient(died))
			{
				TranslateBotName(i, sName[0], sName[2], sizeof(sName[]));
			}
			
			if (killer < 1 || killer == died)
			{
				PrintHintText(i, "%t", "BAWC_DIED_HINT", (sName[2][0] == '\0') ? sName[0] : sName[2], iAliveSurvivors);
				
				if (sName[2][0] != '\0')
				{
					sName[2][0] = '\0';
				}
			}
			else
			{
				GetClientName(killer, sName[1], sizeof(sName[]));
				if (IsFakeClient(killer))
				{
					TranslateBotName(i, sName[1], sName[3], sizeof(sName[]), (GetClientTeam(killer) != 3) ? "" : sInfectednames[GetEntProp(killer, Prop_Send, "m_zombieClass") - 1]);
				}
				
				PrintHintText(i, "%t", "BAWC_KILLED_HINT", (sName[3][0] == '\0') ? sName[1] : sName[3], (sName[2][0] == '\0') ? sName[0] : sName[2], iAliveSurvivors);
				
				if (sName[3][0] != '\0')
				{
					sName[3][0] = '\0';
				}
			}
		}
	}
}

public void OnDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!bLivingAnnounce)
	{
		return;
	}
	
	int defibber = GetClientOfUserId(event.GetInt("userid")),
		defibbed = GetClientOfUserId(event.GetInt("subject"));
	
	if (defibber && (GetClientTeam(defibber) == 2 || GetClientTeam(defibber) == 4) && 
		defibbed && GetClientTeam(defibbed) == 2)
	{
		char sName[4][128];
		
		GetClientName(defibber, sName[0], sizeof(sName[]));
		GetClientName(defibbed, sName[1], sizeof(sName[]));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}
			
			if (IsFakeClient(defibber))
			{
				TranslateBotName(i, sName[0], sName[2], sizeof(sName[]));
			}
			
			if (IsFakeClient(defibbed))
			{
				TranslateBotName(i, sName[1], sName[3], sizeof(sName[]));
			}
			
			PrintHintText(i, "%t", "BAWC_DEFIBBED_HINT", (sName[2][0] == '\0') ? sName[0] : sName[2], (sName[3][0] == '\0') ? sName[1] : sName[3], GetAliveSurvivorsCount());
			
			if (sName[2][0] != '\0')
			{
				sName[2][0] = '\0';
			}
			
			if (sName[3][0] != '\0')
			{
				sName[3][0] = '\0';
			}
		}
	}
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0)
	{
		bCheckFix = true;
	}
	else
	{
		if (strcmp(name, "round_end") == 0 && StrContains(sGameMode, "versus") == -1 && StrContains(sGameMode, "scavenge") == -1)
		{
			return;
		}
		
		bCheckFix = false;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			DetectBWState(i, false);
		}
	}
}

public void OnReplaceEvents(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (player < 1 || !IsClientInGame(player) || GetClientTeam(player) != 2 || IsFakeClient(player))
	{
		return;
	}
	
	DetectBWState((strcmp(name, "player_bot_replace") == 0) ? player : GetClientOfUserId(event.GetInt("bot")), false);
}

void DetectBWState(int client, bool bApply)
{
	if (!bApply)
	{
		if (IsValidEntRef(iBWEnt[client]))
		{
			if (bIsL4D1 || bCompatbility || IsProblematicMap())
			{
				AcceptEntityInput(iBWEnt[client], "TurnOff");
				
				SetVariantString("!activator");
				AcceptEntityInput(iBWEnt[client], "Detach");
			}
			AcceptEntityInput(iBWEnt[client], "ClearParent");
			RemoveEntity(iBWEnt[client]);
			
			iBWEnt[client] = -1;
		}
		return;
	}
	
	static int iModelIndex[MAXPLAYERS+1] = {0, ...};
	
	if (!IsValidEntRef(iBWEnt[client]))
	{
		int iDeathMarkEnt = CreateEntityByName((!bIsL4D1 && !bCompatbility && !IsProblematicMap()) ? "prop_dynamic_override" : "prop_dynamic_ornament");
		if (iDeathMarkEnt == -1)
		{
			return;
		}
		
		iModelIndex[client] = GetEntProp(client, Prop_Data, "m_nModelIndex");
		
		if (bIsL4D1 || bCompatbility || IsProblematicMap())
		{
			char sModel[128];
			GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			SetEntityModel(iDeathMarkEnt, sModel);
			
			DispatchKeyValueFloat(iDeathMarkEnt, "fademindist", 20000.0);
			DispatchKeyValueFloat(iDeathMarkEnt, "fademaxdist", 22000.0);
		}
		else
		{
			if (!IsModelPrecached("models/props_cemetery/grave_07.mdl"))
			{
				PrecacheModel("models/props_cemetery/grave_07.mdl", true);
			}
			SetEntityModel(iDeathMarkEnt, "models/props_cemetery/grave_07.mdl");
		}
		
		SetVariantString("!activator");
		AcceptEntityInput(iDeathMarkEnt, "SetParent", client, iDeathMarkEnt);
		if (!bIsL4D1 && !bCompatbility && !IsProblematicMap())
		{
			SetVariantString("eyes");
			AcceptEntityInput(iDeathMarkEnt, "SetParentAttachment");
			
			TeleportEntity(iDeathMarkEnt, view_as<float>({-2.75, 0.0, 6.0}), NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			SetVariantString("!activator");
			AcceptEntityInput(iDeathMarkEnt, "SetAttached", client, iDeathMarkEnt);
		}
		
		DispatchSpawn(iDeathMarkEnt);
		if (bIsL4D1 || bCompatbility || IsProblematicMap())
		{
			ActivateEntity(iDeathMarkEnt);
			
			AcceptEntityInput(iDeathMarkEnt, "TurnOn");
			
			SetEntProp(iDeathMarkEnt, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(iDeathMarkEnt, Prop_Send, "m_nMinGPULevel", 1);
			SetEntProp(iDeathMarkEnt, Prop_Send, "m_nMaxGPULevel", 1);
		}
		else
		{
			SetEntProp(iDeathMarkEnt, Prop_Data, "m_iEFlags", 0);
			
			SetEntPropFloat(iDeathMarkEnt, Prop_Send, "m_flModelScale", 0.25);
		}
		
		L4D2_SetEntGlow(iDeathMarkEnt, L4D2Glow_Constant, 20000, 1, {255, 255, 255}, false);
		
		SetEntityRenderMode(iDeathMarkEnt, RENDER_NONE);
		
		SDKHook(iDeathMarkEnt, SDKHook_SetTransmit, OnSetTransmit);
		
		iBWEnt[client] = EntIndexToEntRef(iDeathMarkEnt);
		CreateTimer(0.1, MonitorHealthStatus, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if (iModelIndex[client] != 0 && GetEntProp(client, Prop_Data, "m_nModelIndex") == iModelIndex[client])
		{
			return;
		}
		
		iModelIndex[client] = GetEntProp(client, Prop_Data, "m_nModelIndex");
		
		if (bIsL4D1 || bCompatbility || IsProblematicMap())
		{
			char sModel[128];
			GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			SetEntityModel(iBWEnt[client], sModel);
		}
		else
		{
			SetVariantString("eyes");
			AcceptEntityInput(iBWEnt[client], "SetParentAttachment");
			
			TeleportEntity(iBWEnt[client], view_as<float>({-2.75, 0.0, 6.0}), NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action OnSetTransmit(int entity, int client)
{
	return (EntIndexToEntRef(entity) == iBWEnt[client] || GetClientTeam(client) != 3) ? Plugin_Continue : Plugin_Handled;
}

public Action MonitorHealthStatus(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client) || (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if (IsValidEntRef(iBWEnt[client]))
	{
		if (GetEntProp(client, Prop_Send, "m_iHealth") + RoundToCeil(GetTemporaryHealth(client)) >= GetEntProp(client, Prop_Send, "m_iMaxHealth") / 2)
		{
			if (!GetEntProp(iBWEnt[client], Prop_Send, "m_bFlashing", 1))
			{
				return Plugin_Continue;
			}
			
			SetEntProp(iBWEnt[client], Prop_Send, "m_bFlashing", 0, 1);
		}
		else
		{
			if (GetEntProp(iBWEnt[client], Prop_Send, "m_bFlashing", 1))
			{
				return Plugin_Continue;
			}
			
			SetEntProp(iBWEnt[client], Prop_Send, "m_bFlashing", 1, 1);
		}
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

bool IsProblematicMap()
{
	int iTemp = ReplaceString(sExclude, sizeof(sExclude), ",", ",");
	bool bRetVal = false;
	char[][] sTemp = new char[iTemp][64];
	
	ExplodeString(sExclude, ",", sTemp, iTemp, 64, true);
	
	for (int i = 0; i < iTemp; i++)
	{
		if ((sTemp[i][strlen(sTemp[i]) - 1] != '_' || StrContains(sMap, sTemp[i], false) == -1) && strcmp(sMap, sTemp[i]) != 0)
		{
			continue;
		}
		
		bRetVal = true;
		break;
	}
	
	return bRetVal;
}

int GetAliveSurvivorsCount()
{
	int iCount = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
		{
			continue;
		}
		
		iCount += 1;
	}
	
	return iCount;
}

float GetTemporaryHealth(int client)
{
	float fTempHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fTempHP -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * fPillsDecayRate;
	
	return (fTempHP >= 0.0) ? fTempHP : 0.0;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client));
}

stock bool IsSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEntRef(int entity)
{
	return (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE);
}

stock int TranslateBotName(int client, char[] sGivenName, char[] sTranslatedName, int iNameLength, char[] sBackupName = "")
{
	int iStringBytes;
	if (FindCharInString(sGivenName, ')') == -1)
	{
		iStringBytes = Format(sTranslatedName, iNameLength, "%T", (sBackupName[0] != '\0' && !TranslationPhraseExists(sGivenName)) ? sBackupName : sGivenName, client);
	}
	else
	{
		int iLang = GetClientLanguage(client);
		char sTemp[2][128];
		
		ExplodeString(sGivenName, ")", sTemp, 2, 128);
		
		Format(sTemp[1], 128, "%T", (sBackupName[0] != '\0' && !TranslationPhraseExists(sTemp[1])) ? sBackupName : sTemp[1], client);
		iStringBytes = ImplodeStrings(sTemp, 2, ")", sTranslatedName, iNameLength);
		
		if (iLang == 13 || iLang == 14 || iLang == 37)
		{
			ReplaceStringEx(sTranslatedName, iNameLength, "(", (iLang != 13 && iLang != 14) ? "（" : "（ ");
			ReplaceStringEx(sTranslatedName, iNameLength, ")", (iLang != 37) ? " ）" : "）");
		}
	}
	return iStringBytes;
}

stock void ShowHelpfulHint(int client = -1, int iHintTarget, 
						   char[] sHintCaption, 
						   char[] sHintColor = "255 255 255", 
						   const char[] sHintIconOn, 
						   const char[] sHintIconOff = "", 
						   const char[] sHintBind = "", 
						   char[] sHintSizePulse = "0", 
						   char[] sHintDuration = "1", 
						   char[] sHintRange = "0.1", 
						   bool bIsSequel = false, 
						   char[] sHintName = "", 
						   char[] sHintTimes = "0",
						   char[] sHintType = "2")
{
	int iHintEnt = CreateEntityByName("env_instructor_hint");
	if (iHintEnt == -1)
	{
		return;
	}
	
	char sTemp[64];
	FormatEx(sTemp, sizeof(sTemp), "hint%d", iHintTarget);
	DispatchKeyValue(iHintTarget, "targetname", sTemp);
	
	DispatchKeyValue(iHintEnt, "hint_target", sTemp);
	DispatchKeyValue(iHintEnt, "hint_allow_nodraw_target", "1");
	DispatchKeyValue(iHintEnt, "hint_caption", sHintCaption);
	DispatchKeyValue(iHintEnt, "hint_color", sHintColor);
	DispatchKeyValue(iHintEnt, "hint_forcecaption", "1");
	DispatchKeyValue(iHintEnt, "hint_icon_onscreen", sHintIconOn);
	DispatchKeyValue(iHintEnt, "hint_icon_offscreen", sHintIconOff);
	DispatchKeyValue(iHintEnt, "hint_nooffscreen", "0");
	DispatchKeyValue(iHintEnt, "hint_binding", sHintBind);
	DispatchKeyValue(iHintEnt, "hint_pulseoption", sHintSizePulse);
	DispatchKeyValue(iHintEnt, "hint_timeout", sHintDuration);
	DispatchKeyValue(iHintEnt, "hint_range", sHintRange);
	if (bIsSequel)
	{
		DispatchKeyValue(iHintEnt, "hint_name", sHintName);
		DispatchKeyValue(iHintEnt, "hint_display_limit", sHintTimes);
		DispatchKeyValue(iHintEnt, "hint_instance_type", sHintType);
	}
	
	DispatchSpawn(iHintEnt);
	AcceptEntityInput(iHintEnt, "ShowHint", client);
	
	FormatEx(sTemp, sizeof(sTemp), "OnUser1 !self:Kill::%.1f:1", float(StringToInt(sHintDuration)));
	SetVariantString(sTemp);
	AcceptEntityInput(iHintEnt, "AddOutput");
	AcceptEntityInput(iHintEnt, "FireUser1");
}

stock void AutoLoadTranslations(const char[] sErrorPrefix, const char[] sTranslationFile)
{
	char sTranslationFilePath[128];
	BuildPath(Path_SM, sTranslationFilePath, sizeof(sTranslationFilePath), "translations/%s.txt", sTranslationFile);
	if (!FileExists(sTranslationFilePath))
	{
		SetFailState("%s Translation File Not Found!", sErrorPrefix);
	}
	
	LoadTranslations(sTranslationFile);
}

