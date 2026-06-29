#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <glow>

ConVar cvarGameMode, arsDuration[2], arsNotify;
bool bNotify, bSystemInit, bManualLock, bReady[MAXPLAYERS+1], bBlockSolid[20], bBlockRotate[20],
	bCountdownStarted;

int iConnecting, iFailedChecks, iReady, iCountdown, iSaferoomDoor, iBlockCount;
float fBlockPos[20][3], fBlockAng[20][3], fDuration[2];
char sDataFilePath[PLATFORM_MAX_PATH], sMap[64], sGameMode[16], sBlockModel[20][128], sDoorModel[128];
Handle hCountdownTime = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[ARS] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] Anti-Rush System (Reloaded)",
	author = "cravenge",
	description = "Blocks Paths And Lock Saferoom Doors To Prevent Rushing.",
	version = "1.82",
	url = "http://forums.alliedmods.net/"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, sDataFilePath, sizeof(sDataFilePath), "data/anti-rush_system-l4d2.cfg");
	if (!FileExists(sDataFilePath))
	{
		SetFailState("[ARS] Data File Not Found!");
	}
	
	cvarGameMode = FindConVar("mp_gamemode");
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	cvarGameMode.AddChangeHook(OnARSCVarsChanged);
	
	CreateConVar("anti-rush_system-l4d2_version", "1.82", "Anti-Rush System (Reloaded) Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	arsDuration[0] = CreateConVar("ars-l4d2_duration_1st", "30.0", "Duration In 1st Round", FCVAR_NOTIFY|FCVAR_SPONLY, true, 15.0, true, 60.0);
	arsDuration[1] = CreateConVar("ars-l4d2_duration_2nd", "30.0", "Duration In 2nd Round", FCVAR_NOTIFY|FCVAR_SPONLY, true, 15.0, true, 60.0);
	arsNotify = CreateConVar("anti-rush_system-l4d2_notify", "1", "Enable/Disable Notifications", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	bNotify = arsNotify.BoolValue;
	arsNotify.AddChangeHook(OnARSCVarsChanged);
	
	for (int i = 0; i < 2; i++)
	{
		fDuration[i] = arsDuration[i].FloatValue;
		arsDuration[i].AddChangeHook(OnARSCVarsChanged);
	}
	
	AutoExecConfig(true, "anti-rush_system-l4d2");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("vote_passed", OnVotePassed);
	
	HookEvent("round_end", OnRoundEvents);
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	RegConsoleCmd("sm_ready", OnReadyCmd, "Mark As Prepared");
	RegConsoleCmd("sm_unready", OnUnreadyCmd, "Mark As Unprepared");
	
	RegConsoleCmd("sm_allready", OnAllReadyCmd, "Mark All As Prepared");
	RegConsoleCmd("sm_allunready", OnAllUnreadyCmd, "Mark All As Unprepared");
	
	RegAdminCmd("sm_lock", OnLockCmd, ADMFLAG_ROOT, "Locks Starting Saferoom Door Or Barricades Path");
	RegAdminCmd("sm_unlock", OnUnlockCmd, ADMFLAG_ROOT, "Unlocks Starting Saferoom Door Or Clears Path");
}

public void OnARSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	bNotify = arsNotify.BoolValue;
	for (int i = 0; i < 2; i++)
	{
		fDuration[i] = arsDuration[i].FloatValue;
	}
}

public Action OnReadyCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) < 2 || GetClientTeam(client) > 3)
	{
		return Plugin_Handled;
	}
	
	if ((GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Has Started!");
		return Plugin_Handled;
	}
	
	if (iCountdown < 1)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Finished!");
		return Plugin_Handled;
	}
	
	if (bReady[client])
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 You're Already \x04Ready\x01!");
		return Plugin_Handled;
	}
	
	bReady[client] = true;
	
	PrintToChat(client, "\x05[\x03ARS\x05]\x01 You Are \x04Ready\x01!");
	PrintToChat(client, "\x05[\x03ARS\x05]\x01 If You're Uncertain, Type \x04!unready\x01.");
	
	iReady += 1;
	return Plugin_Handled;
}

public Action OnUnreadyCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) < 2 || GetClientTeam(client) > 3)
	{
		return Plugin_Handled;
	}
	
	if ((GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Has Started!");
		return Plugin_Handled;
	}
	
	if (iCountdown < 1)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Finished!");
		return Plugin_Handled;
	}
	
	if (!bReady[client])
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 You're Already \x04Not Ready\x01!");
		return Plugin_Handled;
	}
	
	bReady[client] = false;
	
	PrintToChat(client, "\x05[\x03ARS\x05]\x01 You Are \x04Not Ready\x01!");
	PrintToChat(client, "\x05[\x03ARS\x05]\x01 If You're Certain, Type \x04!ready\x01.");
	
	iReady -= 1;
	return Plugin_Handled;
}

public Action OnAllReadyCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	AdminId aIdVal = GetUserAdmin(client);
	int iUserFlags = GetUserFlagBits(client);
	
	if (aIdVal == INVALID_ADMIN_ID || (iUserFlags & ADMFLAG_CUSTOM6) || (iUserFlags & ADMFLAG_CUSTOM5) || 
		(iUserFlags & ADMFLAG_CUSTOM4))
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Invalid Access!");
		return Plugin_Handled;
	}
	
	if ((GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Has Started!");
		return Plugin_Handled;
	}
	
	if (iCountdown < 1)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Finished!");
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && GetClientTeam(i) < 4 && !IsFakeClient(i))
		{
			if (bReady[i])
			{
				continue;
			}
			
			bReady[i] = true;
			
			PrintToChat(i, "\x05[\x03ARS\x05]\x01 You've Been Forced To Be \x04Ready\x01!");
			PrintToChat(i, "\x05[\x03ARS\x05]\x01 If You're Still Uncertain, Type \x04!unready\x01.");
			
			iReady += 1;
		}
	}
	
	return Plugin_Handled;
}

public Action OnAllUnreadyCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	AdminId aIdVal = GetUserAdmin(client);
	int iUserFlags = GetUserFlagBits(client);
	
	if (aIdVal == INVALID_ADMIN_ID || (iUserFlags & ADMFLAG_CUSTOM6) || (iUserFlags & ADMFLAG_CUSTOM5) || 
		(iUserFlags & ADMFLAG_CUSTOM4))
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Invalid Access!");
		return Plugin_Handled;
	}
	
	if ((GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Has Started!");
		return Plugin_Handled;
	}
	
	if (iCountdown < 1)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Finished!");
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && GetClientTeam(i) < 4 && !IsFakeClient(i))
		{
			if (!bReady[i])
			{
				continue;
			}
			
			bReady[i] = false;
			
			PrintToChat(i, "\x05[\x03ARS\x05]\x01 You've Been Forced To Be \x04Not Ready\x01!");
			PrintToChat(i, "\x05[\x03ARS\x05]\x01 If You're Fully Certain, Type \x04!ready\x01.");
			
			iReady -= 1;
		}
	}
	
	return Plugin_Handled;
}

public Action OnLockCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (iCountdown > 0)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Still Ongoing!");
		return Plugin_Handled;
	}
	
	if (!bManualLock)
	{
		bManualLock = true;
		
		if (IsValidEnt(iSaferoomDoor))
		{
			SetVariantString("spawnflags 32768");
			AcceptEntityInput(iSaferoomDoor, "AddOutput");
			
			AcceptEntityInput(iSaferoomDoor, "Close");
			
			L4D2_SetEntGlow(iSaferoomDoor, L4D2Glow_Constant, 550, 1, {255, 0, 0}, false);
		}
		else
		{
			InitConfig(sMap);
			
			float fMins[3], fMaxs[3], fTemp[4];
			
			for (int i = 0; i < iBlockCount; i++)
			{
				if (sBlockModel[i][0] == '\0')
				{
					continue;
				}
				
				int iPathBlock = CreateEntityByName("prop_dynamic");
				DispatchKeyValue(iPathBlock, "targetname", "ars-l4d2_barricade");
				
				if (bBlockSolid[i])
				{
					DispatchKeyValue(iPathBlock, "solid", "6");
				}
				else
				{
					DispatchKeyValue(iPathBlock, "solid", "0");
				}
				DispatchKeyValue(iPathBlock, "model", sBlockModel[i]);
				
				TeleportEntity(iPathBlock, fBlockPos[i], fBlockAng[i], NULL_VECTOR);
				DispatchSpawn(iPathBlock);
				
				if (!bBlockSolid[i])
				{
					GetEntPropVector(iPathBlock, Prop_Send, "m_vecMins", fMins);
					GetEntPropVector(iPathBlock, Prop_Send, "m_vecMaxs", fMaxs);
					
					if (bBlockRotate[i])
					{
						fTemp[0] = fMins[0]; fTemp[2] = fMaxs[0];
						fTemp[1] = fMins[1]; fTemp[3] = fMaxs[1];
						
						fMins[0] = fTemp[1]; fMaxs[0] = fTemp[3];
						fMins[1] = fTemp[0]; fMaxs[1] = fTemp[2];
					}
					
					int iPathBlock2 = CreateEntityByName("env_player_blocker");
					DispatchKeyValue(iPathBlock2, "targetname", "ars-l4d2_barricade");
					
					DispatchKeyValueVector(iPathBlock2, "origin", fBlockPos[i]);
					DispatchKeyValueVector(iPathBlock2, "mins", fMins);
					DispatchKeyValueVector(iPathBlock2, "maxs", fMaxs);
					
					DispatchKeyValue(iPathBlock2, "initialstate", "0");
					DispatchKeyValue(iPathBlock2, "BlockType", "1");
					
					DispatchSpawn(iPathBlock2);
					
					AcceptEntityInput(iPathBlock2, "Enable");
				}
			}
		}
	}
	else
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x04 %s!", (!IsValidEnt(iSaferoomDoor)) ? "Path Already Barricaded" : "Saferoom Door Already Shut!");
	}
	
	return Plugin_Handled;
}

public Action OnUnlockCmd(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (iCountdown > 0)
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Countdown Is Still Ongoing!");
		return Plugin_Handled;
	}
	
	if (bManualLock)
	{
		bManualLock = false;
		
		if (IsValidEnt(iSaferoomDoor))
		{
			SetVariantString("spawnflags 8192");
			AcceptEntityInput(iSaferoomDoor, "AddOutput");
			
			L4D2_SetEntGlow(iSaferoomDoor, L4D2Glow_Constant, 550, 1, {0, 255, 0}, false);
		}
		else
		{
			ExecuteCommand(client, "ent_fire", "ars-l4d2_barricade KillHierarchy");
		}
	}
	else
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x04 %s!", (!IsValidEnt(iSaferoomDoor)) ? "Path Already Freed" : "Saferoom Door Already Unlocked!");
	}
	
	return Plugin_Handled;
}

public void OnPluginEnd()
{
	if (iSaferoomDoor > 0)
	{
		if (IsValidEntity(iSaferoomDoor) && IsValidEdict(iSaferoomDoor))
		{
			L4D2_SetEntGlow(iSaferoomDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			
			UnhookSingleEntityOutput(iSaferoomDoor, "OnOpen", OnSDOpen);
			UnhookSingleEntityOutput(iSaferoomDoor, "OnBlockedOpening", OnSDOpenBlocked);
			
			SetVariantString("spawnflags 8192");
			AcceptEntityInput(iSaferoomDoor, "AddOutput");
		}
		
		iSaferoomDoor = 0;
	}
	else
	{
		int iRandClient = GetRandomClient();
		if (iRandClient == 0)
		{
			return;
		}
		
		ExecuteCommand(iRandClient, "ent_fire", "ars-l4d2_barricade KillHierarchy");
		
		Event ePlayerLeftStartArea = CreateEvent("player_left_start_area", true);
		ePlayerLeftStartArea.SetInt("userid", GetClientUserId(iRandClient));
		ePlayerLeftStartArea.Fire();
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (iCountdown > 0)
	{
		CreateTimer(1.0, SeekAvailability, GetClientUserId(client));
	}
}

public Action SeekAvailability(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	
	if (GetClientTeam(client) > 1 && GetClientTeam(client) < 4)
	{
		if ((GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
		{
			return Plugin_Stop;
		}
		
		CreateTimer(10.0, InformARSPerk, GetClientUserId(client), TIMER_REPEAT);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action InformARSPerk(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || GetClientTeam(client) < 2)
	{
		return Plugin_Stop;
	}
	
	if ((GetConnectingCount() > 1 || GetUnassignedCount() > 1) && iReady < GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		PrintToChat(client, "\x05[\x03ARS\x05]\x01 Type \x04!ready\x01 If Countdown Hasn't Started!");
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
	InitConfig(sMap, true);
	
	if (sDoorModel[0] != '\0' && !IsModelPrecached(sDoorModel))
	{
		PrecacheModel(sDoorModel, true);
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (StrContains(sGameMode, "versus", false) != -1 && GameRules_GetProp("m_bInSecondHalfOfRound"))
	{
		iCountdown = RoundFloat(fDuration[1]);
	}
	else
	{
		iCountdown = RoundFloat(fDuration[0]);
	}
	iConnecting = GetConnectingCount();
	
	iFailedChecks = 0;
	iReady = 0;
	
	bManualLock = false;
	bCountdownStarted = false;
	
	if (!bSystemInit)
	{
		bSystemInit = true;
		CreateTimer(2.5, PrepareSystem);
	}
}

public Action PrepareSystem(Handle timer)
{
	int iSaferoom = GetSaferoomDoor();
	if (IsValidEnt(iSaferoom))
	{
		SetVariantString("spawnflags 32768");
		AcceptEntityInput(iSaferoom, "AddOutput");
		
		AcceptEntityInput(iSaferoom, "Close");
		
		L4D2_SetEntGlow(iSaferoom, L4D2Glow_Constant, 550, 1, {255, 0, 0}, false);
	}
	else
	{
		float fMins[3], fMaxs[3], fTemp[4];
		
		for (int i = 0; i < iBlockCount; i++)
		{
			if (sBlockModel[i][0] == '\0')
			{
				continue;
			}
			
			int iPathBlock = CreateEntityByName("prop_dynamic");
			DispatchKeyValue(iPathBlock, "targetname", "ars-l4d2_barricade");
			
			if (bBlockSolid[i])
			{
				DispatchKeyValue(iPathBlock, "solid", "6");
			}
			else
			{
				DispatchKeyValue(iPathBlock, "solid", "0");
			}
			DispatchKeyValue(iPathBlock, "model", sBlockModel[i]);
			
			TeleportEntity(iPathBlock, fBlockPos[i], fBlockAng[i], NULL_VECTOR);
			DispatchSpawn(iPathBlock);
			
			if (!bBlockSolid[i])
			{
				GetEntPropVector(iPathBlock, Prop_Send, "m_vecMins", fMins);
				GetEntPropVector(iPathBlock, Prop_Send, "m_vecMaxs", fMaxs);
				
				if (bBlockRotate[i])
				{
					fTemp[0] = fMins[0]; fTemp[2] = fMaxs[0];
					fTemp[1] = fMins[1]; fTemp[3] = fMaxs[1];
					
					fMins[0] = fTemp[1]; fMaxs[0] = fTemp[3];
					fMins[1] = fTemp[0]; fMaxs[1] = fTemp[2];
				}
				
				int iPathBlock2 = CreateEntityByName("env_player_blocker");
				DispatchKeyValue(iPathBlock2, "targetname", "ars-l4d2_barricade");
				
				DispatchKeyValueVector(iPathBlock2, "origin", fBlockPos[i]);
				DispatchKeyValueVector(iPathBlock2, "mins", fMins);
				DispatchKeyValueVector(iPathBlock2, "maxs", fMaxs);
				
				DispatchKeyValue(iPathBlock2, "initialstate", "0");
				DispatchKeyValue(iPathBlock2, "BlockType", "1");
				
				DispatchSpawn(iPathBlock2);
				
				AcceptEntityInput(iPathBlock2, "Enable");
			}
		}
	}
	
	if (hCountdownTime == null)
	{
		hCountdownTime = CreateTimer(1.0, CheckAntiRush, iSaferoom, TIMER_REPEAT);
	}
	return Plugin_Stop;
}

public Action CheckAntiRush(Handle timer, any entity)
{
	if (GetHumanCount() < 1)
	{
		return Plugin_Continue;
	}
	
	if (hCountdownTime == null)
	{
		return Plugin_Stop;
	}
	
	if (bCountdownStarted || iFailedChecks >= 60 || (GetConnectingCount() < 1 && GetUnassignedCount() < 1) || iReady >= GetRealSurvivorsCount() + GetRealInfectedCount())
	{
		if (iCountdown < 1)
		{
			iFailedChecks = 0;
		
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) > 1 && GetClientTeam(i) < 4 && !IsFakeClient(i))
				{
					if (!bReady[i])
					{
						continue;
					}
					
					bReady[i] = false;
					
					iReady -= 1;
				}
			}
			if (!IsValidEnt(entity))
			{
				int iRandClient = GetRandomClient();
				if (iRandClient != 0)
				{
					ExecuteCommand(iRandClient, "ent_fire", "ars-l4d2_barricade KillHierarchy");
					
					Event ePlayerLeftStartArea = CreateEvent("player_left_start_area", true);
					ePlayerLeftStartArea.SetInt("userid", GetClientUserId(iRandClient));
					ePlayerLeftStartArea.Fire();
				}
			}
			else
			{
				SetVariantString("spawnflags 8192");
				AcceptEntityInput(entity, "AddOutput");
				
				L4D2_SetEntGlow(entity, L4D2Glow_Constant, 550, 1, {0, 255, 0}, false);
			}
			
			if (bNotify)
			{
				PrintToChatAll("\x05[\x03ARS\x05] \x04%s\x01!", (IsValidEnt(entity)) ? "Saferoom Door Can Now Be Opened" : "Path Is Now Clear");
				PrintHintTextToAll("%s!", (!IsValidEnt(entity)) ? "Path Unblocked" : "Saferoom Door Unlocked");
			}
			
			if (hCountdownTime != null)
			{
				KillTimer(hCountdownTime);
				hCountdownTime = null;
			}
			
			return Plugin_Stop;
		}
		
		if (!bCountdownStarted)
		{
			bCountdownStarted = true;
		}
		
		if (bNotify)
		{
			PrintHintTextToAll("%i Second%sBefore %s!", iCountdown, (iCountdown == 1) ? " " : "s ", (!IsValidEnt(entity)) ? "Path Is Unblocked" : "Saferoom Door Is Unlocked");
			
			if (iCountdown == 5)
			{
				PrintToChatAll("\x05[\x03ARS\x05] \x04%s In 5 Seconds\x01!", (!IsValidEnt(entity)) ? "Path Will Be Freed" : "Saferoom Door Will Be Unlocked");
			}
		}
		
		iCountdown -= 1;
	}
	else
	{
		if (GetConnectingCount() != iConnecting)
		{
			iConnecting = GetConnectingCount();
			if (iFailedChecks > 0)
			{
				iFailedChecks = 0;
			}
		}
		else
		{
			iFailedChecks += 1;
		}
	}
	
	return Plugin_Continue;
}

public void OnVotePassed(Event event, const char[] name, bool dontBroadcast)
{
	char sDetails[64];
	event.GetString("details", sDetails, sizeof(sDetails));
	if (!StrEqual(sDetails, "#L4D_vote_passed_mission_change", false) && !StrEqual(sDetails, "#L4D_vote_passed_restart_game", false))
	{
		return;
	}
	
	if (bSystemInit)
	{
		bSystemInit = false;
		
		if (iSaferoomDoor > 0)
		{
			if (IsValidEntity(iSaferoomDoor) && IsValidEdict(iSaferoomDoor))
			{
				L4D2_SetEntGlow(iSaferoomDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				
				UnhookSingleEntityOutput(iSaferoomDoor, "OnOpen", OnSDOpen);
				UnhookSingleEntityOutput(iSaferoomDoor, "OnBlockedOpening", OnSDOpenBlocked);
				
				SetVariantString("spawnflags 8192");
				AcceptEntityInput(iSaferoomDoor, "AddOutput");
			}
			
			iSaferoomDoor = 0;
		}
		else
		{
			int iRandClient = GetRandomClient();
			if (iRandClient != 0)
			{
				ExecuteCommand(iRandClient, "ent_fire", "ars-l4d2_barricade KillHierarchy");
			}
		}
		
		if (hCountdownTime != null)
		{
			KillTimer(hCountdownTime);
			hCountdownTime = null;
		}
	}
}

public Action OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "round_end") && StrContains(sGameMode, "versus", false) == -1)
	{
		return;
	}
	
	if (bSystemInit)
	{
		bSystemInit = false;
		
		if (iSaferoomDoor > 0)
		{
			if (IsValidEntity(iSaferoomDoor) && IsValidEdict(iSaferoomDoor))
			{
				L4D2_SetEntGlow(iSaferoomDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				
				UnhookSingleEntityOutput(iSaferoomDoor, "OnOpen", OnSDOpen);
				UnhookSingleEntityOutput(iSaferoomDoor, "OnBlockedOpening", OnSDOpenBlocked);
				
				SetVariantString("spawnflags 8192");
				AcceptEntityInput(iSaferoomDoor, "AddOutput");
			}
			
			iSaferoomDoor = 0;
		}
		else
		{
			int iRandClient = GetRandomClient();
			if (iRandClient != 0)
			{
				ExecuteCommand(iRandClient, "ent_fire", "ars-l4d2_barricade KillHierarchy");
			}
		}
		
		if (hCountdownTime != null)
		{
			KillTimer(hCountdownTime);
			hCountdownTime = null;
		}
	}
}

int GetRandomClient()
{
	int iClient = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iClient = i;
			break;
		}
	}
	return iClient;
}

void InitConfig(char sMapName[64], bool bPrecache = false)
{
	KeyValues kvData = new KeyValues("ars_data");
	if (!kvData.ImportFromFile(sDataFilePath))
	{
		SetFailState("[ARS] 'ars_data' Value Not Found!");
		
		delete kvData;
		return;
	}
	
	if (kvData.JumpToKey("path"))
	{
		if (!kvData.JumpToKey(sMapName))
		{
			PrintToServer("[ARS] '%s' Key Not Configured In 'Path' Category!", sMapName);
		}
		else
		{
			iBlockCount = kvData.GetNum("blocks", 0);
			
			char sTemp[16];
			for (int i = 1; i < iBlockCount + 1; i++)
			{
				IntToString(i, sTemp, sizeof(sTemp));
				if (kvData.JumpToKey(sTemp))
				{
					kvData.GetString("model", sBlockModel[i - 1], 128);
					if (bPrecache || !IsModelPrecached(sBlockModel[i - 1]))
					{
						PrecacheModel(sBlockModel[i - 1], true);
					}
					
					kvData.GetVector("origin", fBlockPos[i - 1]);
					kvData.GetVector("angles", fBlockAng[i - 1]);
					
					bBlockSolid[i - 1] = (kvData.GetNum("IsSolid", 0) == 0) ? false : true;
					bBlockRotate[i - 1] = (kvData.GetNum("NeedsRotate", 0) != 0) ? true : false;
					
					if (i < iBlockCount)
					{
						kvData.GoBack();
					}
				}
				
				if (i >= iBlockCount)
				{
					kvData.Rewind();
				}
			}
		}
		
		kvData.GoBack();
	}
	else
	{
		PrintToServer("[ARS] 'Path' Category Not Configured!");
	}
	
	if (!kvData.JumpToKey("custom_doors"))
	{
		SetFailState("[ARS] 'Custom Doors' Category Not Configured!");
	}
	else
	{
		kvData.GetString(sMapName, sDoorModel, 128, "N/A");
		if (StrEqual(sDoorModel, "N/A", false))
		{
			PrintToServer("[ARS] '%s' Key Not Configured In 'Custom Doors' Category! Using 'All' Instead!", sMapName);
			
			kvData.GetString("All", sDoorModel, 128, "N/A");
			if (StrEqual(sDoorModel, "N/A", false))
			{
				SetFailState("[ARS] 'All' Key Not Configured In 'Custom Doors' Category!");
			}
		}
	}
	
	delete kvData;
}

int GetSaferoomDoor()
{
	int iSaferoomEnt = -1;
	while ((iSaferoomEnt = FindEntityByClassname(iSaferoomEnt, "prop_door_rotating_checkpoint")) != -1)
	{
		if (!IsValidEntity(iSaferoomEnt) || !IsValidEdict(iSaferoomEnt))
		{
			continue;
		}
		
		char sEntityName[128], sEntityModel[128];
		
		GetEntPropString(iSaferoomEnt, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
		GetEntPropString(iSaferoomEnt, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
		
		if (StrEqual(sEntityName, "checkpoint_exit", false) || StrEqual(sEntityModel, sDoorModel, false) || StrEqual(sEntityModel, "models/props_doors/checkpoint_door_-01.mdl", false))
		{
			if (sEntityName[0] == '\0')
			{
				DispatchKeyValue(iSaferoomEnt, "targetname", "checkpoint_exit");
			}
			
			HookSingleEntityOutput(iSaferoomEnt, "OnOpen", OnSDOpen);
			HookSingleEntityOutput(iSaferoomEnt, "OnBlockedOpening", OnSDOpenBlocked);
			
			iSaferoomDoor = iSaferoomEnt;
			return iSaferoomEnt;
		}
	}
	
	return -1;
}

public void OnSDOpen(const char[] output, int caller, int activator, float delay)
{
	SetVariantString("spawnflags 32768");
	AcceptEntityInput(caller, "AddOutput");
}

public void OnSDOpenBlocked(const char[] output, int caller, int activator, float delay)
{
	if (!IsCommonInfected(activator))
	{
		return;
	}
	
	AcceptEntityInput(activator, "BecomeRagdoll");
}

int GetConnectingCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

int GetHumanCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

int GetUnassignedCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) < 1 || !IsValidEntity(i)) && !IsFakeClient(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

int GetRealSurvivorsCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

int GetRealInfectedCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

stock bool IsCommonInfected(int entity)
{
	if (IsValidEnt(entity))
	{
		char sEntityClass[64];
		GetEdictClassname(entity, sEntityClass, sizeof(sEntityClass));
		return StrEqual(sEntityClass, "infected");
	}
	
	return false;
}

stock void ExecuteCommand(int client, const char[] sCommand, const char[] sArgument)
{
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArgument);
	SetCommandFlags(sCommand, iFlags);
}

