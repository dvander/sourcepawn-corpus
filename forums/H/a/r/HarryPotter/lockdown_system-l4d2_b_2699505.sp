
#include <sourcemod>
#include <sdktools>
#include <glow>

#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#define PLUGIN_VERSION "2.4"

#define UNLOCK 0
#define LOCK 1
#define MODEL_TANK "models/infected/hulk.mdl"

ConVar lsAnnounce, lsAntiFarmDuration, lsDuration, lsMobs, lsTankDemolition, lsType, lsNearByAllSurvivor, lsHint,
	cvarGameMode;

int iAntiFarmDuration, iDuration, iMobs, iType, iDoorStatus, iCheckpointDoor, iSystemTime;
float fDoorSpeed;
bool bAntiFarmInit, bLockdownInit, bLDFinished, bChoiceStarted, bAnnounce, bTankDemolition, bNearByAllSurvivor;
char sGameMode[16], sKeyMan[128], sLastName[2048][128];
Handle hAntiFarmTime = null, hLockdownTime = null;
bool bSpawnTank,bSurvivorsAssembleAlready,blsHint;
static Handle hCreateTank = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[LS] Plugin Supports L4D2 Only");
		return APLRes_SilentFailure;
	}

	CreateNative("Is_End_SafeRoom_Door_Open", Native_Is_End_SafeRoom_Door_Open);
	return APLRes_Success;
}

public int Native_Is_End_SafeRoom_Door_Open(Handle plugin, int numParams)
{
	return bLDFinished;
}

public Plugin myinfo = 
{
	name = "[L4D2] Lockdown System",
	author = "cravenge, Harry",
	description = "Locks Saferoom Door Until Someone Opens It.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	cvarGameMode = FindConVar("mp_gamemode");
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	cvarGameMode.AddChangeHook(OnLSCVarsChanged);
	
	CreateConVar("lockdown_system-l4d2_version", PLUGIN_VERSION, "Lockdown System Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	lsAnnounce = CreateConVar("lockdown_system-l4d2_announce", "1", "Enable/Disable Announcements", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsAntiFarmDuration = CreateConVar("lockdown_system-l4d2_anti-farm_duration", "300", "Duration Of Anti-Farm", FCVAR_SPONLY|FCVAR_NOTIFY);
	lsDuration = CreateConVar("lockdown_system-l4d2_duration", "150", "Duration Of Lockdown", FCVAR_SPONLY|FCVAR_NOTIFY);
	lsMobs = CreateConVar("lockdown_system-l4d2_mobs", "10", "Number Of Mobs To Spawn", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0, true, 10.0);
	lsTankDemolition = CreateConVar("lockdown_system-l4d2_tank_demolition", "1", "Enable/Disable Tank Demolition, server will spawn tank before door open and after door open", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsType = CreateConVar("lockdown_system-l4d2_type", "3", "Lockdown Type: 0=Random, 1=Improved, 2 & 3=Default", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	lsNearByAllSurvivor = CreateConVar("lockdown_system-l4d2_all_survivors_near_saferoom", "1", "If 1, all survivors must assemble near the saferoom door before open.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsHint = CreateConVar(	"lockdown_system-l4d2_spam_hint", "1", "0=Off. 1=Display a message showing who opened or closed the saferoom door.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	iAntiFarmDuration = lsAntiFarmDuration.IntValue;
	iDuration = lsDuration.IntValue;
	iMobs = lsMobs.IntValue;
	
	bAnnounce = lsAnnounce.BoolValue;
	bTankDemolition = lsTankDemolition.BoolValue;
	bNearByAllSurvivor = lsNearByAllSurvivor.BoolValue;
	
	lsAnnounce.AddChangeHook(OnLSCVarsChanged);
	lsAntiFarmDuration.AddChangeHook(OnLSCVarsChanged);
	lsDuration.AddChangeHook(OnLSCVarsChanged);
	lsMobs.AddChangeHook(OnLSCVarsChanged);
	lsTankDemolition.AddChangeHook(OnLSCVarsChanged);
	lsNearByAllSurvivor.AddChangeHook(OnLSCVarsChanged);
	lsHint.AddChangeHook(OnLSCVarsChanged);

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("player_use", OnPlayerUsePre, EventHookMode_Pre);
	HookEvent("entity_killed", TC_ev_EntityKilled);
	HookEvent("door_open",			Event_DoorOpen);
	HookEvent("door_close",			Event_DoorClose);

	Handle hGameConf = LoadGameConfigFile("lockdown_system-l4d2");
	if( hGameConf == null )
	{
		SetFailState("Unable to find gamedata \"lockdown_system-l4d2\".");
	}
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Tank>"))
		SetFailState("Unable to find NextBotCreatePlayerBot<Tank> signature in gamedata file.");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateTank = EndPrepSDKCall();
	if (hCreateTank == null)
		SetFailState("Cannot initialize NextBotCreatePlayerBot<Tank> SDKCall, signature is broken.") ;
	delete hGameConf;

	AutoExecConfig(true, "lockdown_system-l4d2");
}

public void OnLSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	iAntiFarmDuration = lsAntiFarmDuration.IntValue;
	iDuration = lsDuration.IntValue;
	iMobs = lsMobs.IntValue;
	
	bAnnounce = lsAnnounce.BoolValue;
	bTankDemolition = lsTankDemolition.BoolValue;
	bNearByAllSurvivor = lsNearByAllSurvivor.BoolValue;
	blsHint = lsHint.BoolValue;
	
	if (IsValidEnt(iCheckpointDoor))
	{
		if (iType != 1)
		{
			return;
		}
		
		SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", 89.0 / float(iDuration));
	}
}

public void OnPluginEnd()
{
	if (iCheckpointDoor != 0)
	{
		if (IsValidEntity(iCheckpointDoor) && IsValidEdict(iCheckpointDoor))
		{
			L4D2_SetEntGlow(iCheckpointDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			
			UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyOpen", OnDoorAntiSpam);
			UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyClosed", OnDoorAntiSpam);
			
			UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedOpening", OnDoorBlocked);
			UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedClosing", OnDoorBlocked);
			
			if (iType == 1)
			{
				SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", fDoorSpeed);
			}
			ControlDoor(iCheckpointDoor, UNLOCK);
		}
		
		iCheckpointDoor = 0;
	}
}

public void OnMapStart()
{
	if (!IsFinaleMap() && !HasSaferoomBug())
	{
		if (!IsModelPrecached("models/props_doors/checkpoint_door_02.mdl"))
		{
			PrecacheModel("models/props_doors/checkpoint_door_02.mdl", true);
		}
		
		if (!IsSoundPrecached("doors/latchlocked2.wav"))
		{
			PrecacheSound("doors/latchlocked2.wav", true);
		}
		
		if (!IsSoundPrecached("doors/door_squeek1.wav"))
		{
			PrecacheSound("doors/door_squeek1.wav", true);
		}
		
		if (!IsSoundPrecached("ambient/alarms/klaxon1.wav"))
		{
			PrecacheSound("ambient/alarms/klaxon1.wav", true);
		}

		if (!IsModelPrecached(MODEL_TANK))
		{
			PrecacheModel(MODEL_TANK, true);
		}
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (IsFinaleMap() || HasSaferoomBug())
	{
		return;
	}
	
	iType = (lsType.IntValue == 0) ? GetRandomInt(1, 3) : lsType.IntValue;
	
	bAntiFarmInit = false;
	bLockdownInit = false;
	bLDFinished = false;
	bSpawnTank = false;
	bSurvivorsAssembleAlready = false;
	
	InitDoor();
}

public Action TC_ev_EntityKilled(Event event, const char[] name, bool dontBroadcast) 
{
	if (IsFinaleMap() || HasSaferoomBug() || !bTankDemolition || !bLDFinished)
	{
		return;
	}

	if (IsPlayerTank(event.GetInt("entindex_killed")))
	{
		CreateTimer(1.5, Timer_SpawnTank, _,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_SpawnTank(Handle timer)
{
	if(RealFreePlayersOnInfected())
		CheatCommand(GetRandomClient(), "z_spawn_old", "tank auto");
	else
		ExecuteSpawn(GetRandomClient(), "tank auto", 1, true);
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if ((StrEqual(name, "round_end") && StrContains(sGameMode, "versus", false) == -1) || IsFinaleMap() || HasSaferoomBug())
	{
		return;
	}
	
	if (hAntiFarmTime != null)
	{
		if (!bLockdownInit)
		{
			bLockdownInit = true;
		}
		
		KillTimer(hAntiFarmTime);
		hAntiFarmTime = null;
		
		CreateTimer(1.75, ForceEndLockdown);
	}
	else
	{
		CreateTimer(1.5, ForceEndLockdown);
	}
	
	CreateTimer(2.0, OrderShutDown);
}

public Action ForceEndLockdown(Handle timer)
{
	if (hLockdownTime == null)
	{
		return Plugin_Stop;
	}
	
	if (!bLDFinished)
	{
		bLDFinished = true;
	}
	
	KillTimer(hLockdownTime);
	hLockdownTime = null;
	
	return Plugin_Stop;
}

public Action OrderShutDown(Handle timer)
{
	if (iCheckpointDoor == 0)
	{
		return Plugin_Stop;
	}
	
	if (IsValidEntity(iCheckpointDoor) && IsValidEdict(iCheckpointDoor))
	{
		L4D2_SetEntGlow(iCheckpointDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
		
		UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyOpen", OnDoorAntiSpam);
		UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyClosed", OnDoorAntiSpam);
		
		UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedOpening", OnDoorBlocked);
		UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedClosing", OnDoorBlocked);
		
		if (iType == 1)
		{
			SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", fDoorSpeed);
		}

		iDoorStatus = UNLOCK;
	}
	
	iCheckpointDoor = 0;
	return Plugin_Stop;
}

public Action OnPlayerUsePre(Event event, const char[] name, bool dontBroadcast)
{
	if (IsFinaleMap() || HasSaferoomBug())
	{
		return Plugin_Continue;
	}
	
	int user = GetClientOfUserId(event.GetInt("userid"));
	if (IsSurvivor(user))
	{
		if (!IsPlayerAlive(user))
		{
			return Plugin_Continue;
		}
		
		int used = event.GetInt("targetid");
		if (IsValidEnt(used))
		{
			char sEntityClass[64];
			GetEdictClassname(used, sEntityClass, sizeof(sEntityClass));
			if (!StrEqual(sEntityClass, "prop_door_rotating_checkpoint") || used != iCheckpointDoor)
			{
				return Plugin_Continue;
			}
			
			if (iDoorStatus != UNLOCK)
			{
				if(bNearByAllSurvivor && !bSurvivorsAssembleAlready)
				{
					float clientOrigin[3];
					float doorOrigin[3];
					GetEntPropVector(used, Prop_Send, "m_vecOrigin", doorOrigin);
					for (int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						{
							GetClientAbsOrigin(i, clientOrigin);
							if (GetVectorDistance(clientOrigin, doorOrigin, true) > 1000*1000)
							{
								PrintHintText(user, "[LS] 所有倖存者必須集合才能打開安全門！");
								PrintCenterTextAll("[LS] 所有倖存者必須集合才能打開安全門！");
								return Plugin_Continue;
							}
						}
					}
					bSurvivorsAssembleAlready = true;
				}

				if(bTankDemolition && !bSpawnTank) 
				{
					ExecuteSpawn(user, "tank auto", 1, true);
					bSpawnTank = true;
				}
				
				if (GetTankCount() > 0)
				{
					if (bLDFinished || bLockdownInit)
					{
						bAntiFarmInit = true;
						return Plugin_Continue;
					}
					
					
					if (!bAntiFarmInit)
					{
						bAntiFarmInit = true;
						iSystemTime = iAntiFarmDuration;
						
						PrintHintText(user, "[LS] Tank還活著，請先殺了Tank！");
						EmitSoundToAll("doors/latchlocked2.wav", used, SNDCHAN_AUTO);

						GetClientName(user, sKeyMan, sizeof(sKeyMan));
						
						ExecuteSpawn(user, "mob auto", iMobs);
						
						if (hAntiFarmTime == null)
						{
							hAntiFarmTime = CreateTimer(float(iAntiFarmDuration) + 1.0, EndAntiFarm);
						}
						CreateTimer(1.0, CheckAntiFarm, used, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else
				{
					if (bAntiFarmInit)
					{
						return Plugin_Continue;
					}
					
					if (!bLockdownInit)
					{
						bLockdownInit = true;
						
						iSystemTime = iDuration;
						GetClientName(user, sKeyMan, sizeof(sKeyMan));
						
						ExecuteSpawn(user, "mob auto", iMobs);
						if (iType == 1)
						{
							ControlDoor(iCheckpointDoor, UNLOCK);
						}
						
						if (hLockdownTime == null)
						{
							hLockdownTime = CreateTimer(float(iDuration) + 1.0, EndLockdown);
						}
						CreateTimer(1.0, CheckLockdown, used, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public int mSystemChoiceHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_VoteEnd:
		{
			if (!bChoiceStarted || GetProperSurvivorsCount() < 1)
			{
				return 0;
			}
			
			int iVoteCount[2];
			GetMenuVoteInfo(param2, iVoteCount[0], iVoteCount[1]);
			
			switch (param1)
			{
				case 0:
				{
					if (bLDFinished || bLockdownInit)
					{
						bAntiFarmInit = true;
						return 0;
					}
					
					
					if (!bAntiFarmInit)
					{
						bAntiFarmInit = true;
						iSystemTime = iAntiFarmDuration;
						
						PrintToChatAll("\x05[\x03LS\x05]\x04 Anti-Farm\x01 System Got Most Votes! \x03(\x05%d\x01 Out Of \x05\x03)", iVoteCount[0], iVoteCount[1]);
						EmitSoundToAll("doors/latchlocked2.wav", iCheckpointDoor, SNDCHAN_AUTO);
						ExecuteSpawn(GetRandomClient(), "mob auto", iMobs);
						
						if (hAntiFarmTime == null)
						{
							hAntiFarmTime = CreateTimer(float(iAntiFarmDuration) + 1.0, EndAntiFarm);
						}
						CreateTimer(1.0, CheckAntiFarm, iCheckpointDoor, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case 1:
				{
					if (bAntiFarmInit)
					{
						return 0;
					}
					
					PrintToChatAll("\x05[\x03LS\x05]\x04 Lockdown\x01 System Got Most Votes! \x03(\x05%d\x01 Out Of \x05%d\x03)", iVoteCount[0], iVoteCount[1]);
					
					if (!bLockdownInit)
					{
						bLockdownInit = true;
						
						iSystemTime = iDuration;
						
						ExecuteSpawn(GetRandomClient(), "mob auto", iMobs);
						if (iType == 1)
						{
							ControlDoor(iCheckpointDoor, UNLOCK);
						}
						
						if (hLockdownTime == null)
						{
							hLockdownTime = CreateTimer(float(iDuration) + 1.0, EndLockdown);
						}
						CreateTimer(1.0, CheckLockdown, iCheckpointDoor, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	
	return 0;
}

public Action CheckAntiFarm(Handle timer, any entity)
{
	if (GetTankCount() < 1 || hAntiFarmTime == null)
	{
		if (hAntiFarmTime != null)
		{
			KillTimer(hAntiFarmTime);
			hAntiFarmTime = null;
		}
		
		if (!bLockdownInit)
		{
			bLockdownInit = true;
			ExecuteSpawn(GetRandomClient(), "mob auto", iMobs);
			
			if (iType == 1)
			{
				ControlDoor(iCheckpointDoor, UNLOCK);
			}
			
			if (hLockdownTime == null)
			{
				hLockdownTime = CreateTimer(float(iDuration) + 1.0, EndLockdown);
			}
			iSystemTime = iDuration;
			CreateTimer(1.0, CheckLockdown, entity, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("[ANTI-FARM] Tank還活著，請先殺了Tank！\n否則等待 %d 秒!", iSystemTime);
	iSystemTime -= 1;
	
	return Plugin_Continue;
}

public Action EndAntiFarm(Handle timer)
{
	if (hAntiFarmTime == null)
	{
		return Plugin_Stop;
	}
	
	KillTimer(hAntiFarmTime);
	hAntiFarmTime = null;
	
	return Plugin_Stop;
}

public Action CheckLockdown(Handle timer, any entity)
{
	if (hLockdownTime == null)
	{
		if (!bLDFinished)
		{
			bLDFinished = true;
			
			EmitSoundToAll("doors/door_squeek1.wav", entity);
			if (iType != 1)
			{
				ControlDoor(entity, UNLOCK);
			}
			else
			{
				SetEntPropFloat(entity, Prop_Data, "m_flSpeed", fDoorSpeed);
			}
			
			PrintCenterTextAll("安全門已開啟!! 大家趕快進去!!");
			
			if (bAnnounce)
			{
				PrintToChatAll("\x05[\x03LS\x05]\x04 <\x05%s\x04>\x01 打開了 安全室大門!", sKeyMan);
			}
			
			CreateTimer(5.0, LaunchTankDemolition);
		}
		return Plugin_Stop;
	}
	
	EmitSoundToAll("ambient/alarms/klaxon1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	PrintCenterTextAll("[LOCKDOWN] 開門倒數 %d 秒!", iSystemTime);
	
	iSystemTime -= 1;
	return Plugin_Continue;
}

public Action EndLockdown(Handle timer)
{
	if (hLockdownTime == null)
	{
		return Plugin_Stop;
	}
	
	KillTimer(hLockdownTime);
	hLockdownTime = null;
	
	return Plugin_Stop;
}

public Action LaunchTankDemolition(Handle timer)
{
	if (!bTankDemolition)
	{
		return Plugin_Stop;
	}
	
	ExecuteSpawn(GetRandomClient(), "tank auto", 3, true);
	if (bAnnounce)
	{
		PrintToChatAll("\x05[\x03LS\x05]\x01 Tank Demolition Underway!");
	}
	
	return Plugin_Stop;
}

public void OnMapEnd()
{
	if (!StrEqual(sGameMode, "coop", false) && !StrEqual(sGameMode, "realism", false))
	{
		return;
	}
	
	if (!IsFinaleMap() && !HasSaferoomBug())
	{
		bAntiFarmInit = false;
		bLockdownInit = false;
		bLDFinished = false;
		
		if (iCheckpointDoor != 0)
		{
			if (IsValidEntity(iCheckpointDoor) && IsValidEdict(iCheckpointDoor))
			{
				L4D2_SetEntGlow(iCheckpointDoor, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				
				UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyOpen", OnDoorAntiSpam);
				UnhookSingleEntityOutput(iCheckpointDoor, "OnFullyClosed", OnDoorAntiSpam);
				
				UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedOpening", OnDoorBlocked);
				UnhookSingleEntityOutput(iCheckpointDoor, "OnBlockedClosing", OnDoorBlocked);
				
				if (iType == 1)
				{
					SetEntPropFloat(iCheckpointDoor, Prop_Data, "m_flSpeed", fDoorSpeed);
				}
				
				iDoorStatus = UNLOCK;
			}
			
			iCheckpointDoor = 0;
		}
	}
}

bool IsFinaleMap()
{
	int iTriggerEnt = -1;
	while ((iTriggerEnt = FindEntityByClassname(iTriggerEnt, "trigger_finale")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(iTriggerEnt) || !IsValidEdict(iTriggerEnt))
		{
			continue;
		}
		
		return true;
	}
	
	return false;
}

bool HasSaferoomBug()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "c10m3_ranchhouse", false) || StrEqual(sMap, "l4d_reverse_hos03_sewers", false) || StrEqual(sMap, "l4d2_stadium4_city2", false) || 
		StrEqual(sMap, "l4d_fairview10_church", false) || StrEqual(sMap, "l4d2_wanli01", false))
	{
		return true;
	}
	
	return false;
}

void InitDoor()
{
	if (IsValidEnt(iCheckpointDoor))
	{
		return;
	}
	
	int iCheckpointEnt = -1;
	while ((iCheckpointEnt = FindEntityByClassname(iCheckpointEnt, "prop_door_rotating_checkpoint")) != -1)
	{
		if (!IsValidEntity(iCheckpointEnt) || !IsValidEdict(iCheckpointEnt))
		{
			continue;
		}
		
		char sEntityName[128];
		GetEntPropString(iCheckpointEnt, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));
		if (StrEqual(sEntityName, "checkpoint_entrance", false))
		{
			if (sLastName[iCheckpointEnt][0] != '\0')
			{
				DispatchKeyValue(iCheckpointEnt, "targetname", sLastName[iCheckpointEnt]);
				sLastName[iCheckpointEnt][0] = '\0';
			}
			
			fDoorSpeed = GetEntPropFloat(iCheckpointEnt, Prop_Data, "m_flSpeed");
			
			ControlDoor(iCheckpointEnt, LOCK);
			
			HookSingleEntityOutput(iCheckpointEnt, "OnFullyOpen", OnDoorAntiSpam);
			HookSingleEntityOutput(iCheckpointEnt, "OnFullyClosed", OnDoorAntiSpam);
			
			HookSingleEntityOutput(iCheckpointEnt, "OnBlockedOpening", OnDoorBlocked);
			HookSingleEntityOutput(iCheckpointEnt, "OnBlockedClosing", OnDoorBlocked);
			
			iCheckpointDoor = iCheckpointEnt;
			break;
		}
		else if (!HasTwoCheckpointDoorMap())
		{
			char sEntityModel[128];
			GetEntPropString(iCheckpointEnt, Prop_Data, "m_ModelName", sEntityModel, sizeof(sEntityModel));
			if (!StrEqual(sEntityModel, "models/props_doors/checkpoint_door_02.mdl", false) && !StrEqual(sEntityModel, "models/props_doors/checkpoint_door_-02.mdl", false))
			{
				continue;
			}
			
			if (sEntityName[0] != '\0')
			{
				strcopy(sLastName[iCheckpointEnt], 128, sEntityName);
			}
			DispatchKeyValue(iCheckpointEnt, "targetname", "checkpoint_entrance");
			
			InitDoor();
			break;
		}
	}
}

public void OnDoorAntiSpam(const char[] output, int caller, int activator, float delay)
{
	if (StrEqual(output, "OnFullyClosed") && !bLDFinished)
	{
		return;
	}
	
	AcceptEntityInput(caller, "Lock");
	SetEntProp(caller, Prop_Data, "m_hasUnlockSequence", LOCK);
	
	L4D2_SetEntGlow(caller, L4D2Glow_Constant, 550, 0, {0, 0, 255}, false);
	
	CreateTimer(3.0, PreventDoorSpam, EntIndexToEntRef(caller));
}

public Action PreventDoorSpam(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	L4D2_SetEntGlow(entity, L4D2Glow_Constant, 550, 0, {255, 255, 0}, false);
	
	SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
	AcceptEntityInput(entity, "Unlock");
	
	return Plugin_Stop;
}

public void OnDoorBlocked(const char[] output, int caller, int activator, float delay)
{
	//PrintToChatAll("OnDoorBlockeding caller:%d, activator: %d, output: %s",caller,activator,output);
	if (!IsCommonInfected(activator))
	{
		return;
	}

	AcceptEntityInput(activator, "BecomeRagdoll");
}

void ControlDoor(int entity, int iOperation)
{
	iDoorStatus = iOperation;
	
	switch (iOperation)
	{
		case LOCK:
		{
			L4D2_SetEntGlow(entity, L4D2Glow_Constant, 550, 0, {0, 0, 255}, false);
			
			AcceptEntityInput(entity, "Close");
			if (iType == 1)
			{
				SetEntPropFloat(entity, Prop_Data, "m_flSpeed", 89.0 / float(iDuration));
			}
			AcceptEntityInput(entity, "Lock");
			if (iType != 1)
			{
				AcceptEntityInput(entity, "ForceClosed");
			}
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
		}
		case UNLOCK:
		{
			L4D2_SetEntGlow(entity, L4D2Glow_Constant, 550, 0, {255, 255, 0}, false);
			
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "ForceClosed");
			AcceptEntityInput(entity, "Open");
		}
	}
}

int GetRandomClient()
{
	int iClientCount, iClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			iClients[iClientCount++] = i;
		}
	}
	return (iClientCount == 0) ? 0 : iClients[GetRandomInt(0, iClientCount - 1)];
}

int GetTankCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

int GetProperSurvivorsCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
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

stock void ExecuteSpawn(int client, char[] sInfected, int iCount, bool btank = false)
{
	char sCommand[16];
	if (StrContains(sInfected, "mob", false) != -1)
	{
		strcopy(sCommand, sizeof(sCommand), "z_spawn");
	}
	else
	{
		strcopy(sCommand, sizeof(sCommand), "z_spawn_old");
	}
	
	int iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	if (btank)
	{
		bool resetGhostState[MAXPLAYERS+1];
		bool resetIsAlive[MAXPLAYERS+1];
		bool resetLifeState[MAXPLAYERS+1];
		for (int i=1; i<=MaxClients; i++){ 
			if (i == client) continue; //dont disable the chosen one
			if (!IsClientInGame(i)) continue; //not ingame? skip
			if (GetClientTeam(i) != 3) continue; //not infected? skip
			if (IsFakeClient(i)) continue; //a bot? skip
			
			if (IsPlayerGhost(i)){
				resetGhostState[i] = true;
				SetPlayerGhostStatus(i, false);
				resetIsAlive[i] = true; 
				SetPlayerIsAlive(i, true);
			}
			else if (!IsPlayerAlive(i)){
				resetLifeState[i] = true;
				SetPlayerLifeState(i, false);
			}
		}
		int tankbot = CreateFakeClient("Lock Down Tank Bot");
		ChangeClientTeam(tankbot, 3);
		FakeClientCommand(client, "%s %s", sCommand, sInfected);
		// We restore the player's status
		for (int i=1; i<=MaxClients; i++){
			if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
			if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
			if (resetLifeState[i]) SetPlayerLifeState(i, true);
		}
		if(IsPlayerAlive(tankbot))
		{
			float Origin[3], Angles[3];
			GetClientAbsOrigin(tankbot, Origin);
			GetClientAbsAngles(tankbot, Angles);
			iCount--;
			int newtankbot;
			for (int i = 0; i < iCount; i++)
			{
				newtankbot = SDKCall(hCreateTank, "Lock Down Tank Bot"); //召喚坦克
				if (newtankbot > 0 && IsValidClient(newtankbot))
				{
					SetEntityModel(newtankbot, MODEL_TANK);
					ChangeClientTeam(newtankbot, 3);
					SetEntProp(newtankbot, Prop_Send, "m_usSolidFlags", 16);
					SetEntProp(newtankbot, Prop_Send, "movetype", 2);
					SetEntProp(newtankbot, Prop_Send, "deadflag", 0);
					SetEntProp(newtankbot, Prop_Send, "m_lifeState", 0);
					SetEntProp(newtankbot, Prop_Send, "m_iObserverMode", 0);
					SetEntProp(newtankbot, Prop_Send, "m_iPlayerState", 0);
					SetEntProp(newtankbot, Prop_Send, "m_zombieState", 0);
					DispatchSpawn(newtankbot);
					ActivateEntity(newtankbot);
					TeleportEntity(newtankbot, Origin, Angles, NULL_VECTOR); //移動到相同位置
				}
			}
		}
		KickClient(tankbot);
	}
	else
	{
		for (int i = 0; i < iCount; i++)
		{
			FakeClientCommand(client, "%s %s", sCommand, sInfected);
		}
	}
	SetCommandFlags(sCommand, iFlags);
}

bool HasTwoCheckpointDoorMap()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "c10m2_drainage", false))
	{
		return true;
	}
	
	return false;
}

stock void SetPlayerGhostStatus(int client, bool ghost)
{
	if(ghost){	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	}else{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
	}
}
stock void SetPlayerIsAlive(int client, bool alive)
{
	int offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}
stock void SetPlayerLifeState(int client, bool ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}
stock bool IsPlayerGhost(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

stock void CheatCommand(int client,  char[] command, char[] arguments = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

bool RealFreePlayersOnInfected ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && (IsPlayerGhost(i) || !IsPlayerAlive(i)))
			return true;
	}
	return false;
}

bool IsPlayerTank (int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
		DoorPrint(event, true);
}

public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetBool("checkpoint") )
		DoorPrint(event, false);
}

void DoorPrint(Event event, bool open)
{
	if( bLDFinished && blsHint)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if(open) PrintToChatAll("\x05[\x03LS\x05]\x04 <\x05%N\x04>\x01 打開了 安全門!", client);
			else PrintToChatAll("\x05[\x03LS\x05]\x04 <\x05%N\x04>\x01 關閉了 安全門!", client);
		}
	}
}