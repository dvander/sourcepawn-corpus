#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.7"

#define UNLOCK 0
#define LOCK 1

ConVar lsAnnounce, lsAntiFarmDuration, lsDuration, lsMobs, lsMenu, lsTankDemolition, lsType,
	cvarGameMode;

int iAntiFarmDuration, iDuration, iMobs, iType, iDoorStatus, iCheckpointDoor, iSystemTime;
float fDoorSpeed;
bool bAntiFarmInit, bLockdownInit, bLDFinished, bChoiceStarted, bAnnounce, bMenu, bTankDemolition;
char sGameMode[16], sKeyMan[128], sLastName[2048][128];
Handle hAntiFarmTime = null, hLockdownTime = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead)
	{
		strcopy(error, err_max, "[LS] Plugin Supports L4D Only");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D] Lockdown System",
	author = "cravenge",
	description = "Locks Saferoom Door Until Someone Opens It.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	cvarGameMode = FindConVar("mp_gamemode");
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	cvarGameMode.AddChangeHook(OnLSCVarsChanged);
	
	CreateConVar("lockdown_system-l4d_version", PLUGIN_VERSION, "Lockdown System Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	lsAnnounce = CreateConVar("lockdown_system-l4d_announce", "1", "Enable/Disable Announcements", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsAntiFarmDuration = CreateConVar("lockdown_system-l4d_anti-farm_duration", "150", "Duration Of Anti-Farm", FCVAR_SPONLY|FCVAR_NOTIFY);
	lsDuration = CreateConVar("lockdown_system-l4d_duration", "30", "Duration Of Lockdown", FCVAR_SPONLY|FCVAR_NOTIFY);
	lsMobs = CreateConVar("lockdown_system-l4d_mobs", "2", "Number Of Mobs To Spawn", FCVAR_SPONLY|FCVAR_NOTIFY, true, 1.0, true, 5.0);
	lsMenu = CreateConVar("lockdown_system-l4d_menu", "0", "Enable/Disable Menu", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsTankDemolition = CreateConVar("lockdown_system-l4d_tank_demolition", "1", "Enable/Disable Tank Demolition", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	lsType = CreateConVar("lockdown_system-l4d_type", "0", "Lockdown Type: 0=Random, 1=Improved, 2 & 3=Default", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	
	iAntiFarmDuration = lsAntiFarmDuration.IntValue;
	iDuration = lsDuration.IntValue;
	iMobs = lsMobs.IntValue;
	
	bAnnounce = lsAnnounce.BoolValue;
	bMenu = lsMenu.BoolValue;
	bTankDemolition = lsTankDemolition.BoolValue;
	
	lsAnnounce.AddChangeHook(OnLSCVarsChanged);
	lsAntiFarmDuration.AddChangeHook(OnLSCVarsChanged);
	lsDuration.AddChangeHook(OnLSCVarsChanged);
	lsMobs.AddChangeHook(OnLSCVarsChanged);
	lsMenu.AddChangeHook(OnLSCVarsChanged);
	lsTankDemolition.AddChangeHook(OnLSCVarsChanged);
	
	AutoExecConfig(true, "lockdown_system-l4d");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("tank_killed", OnTankKilled);
	
	HookEvent("round_end", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	
	HookEvent("player_use", OnPlayerUsePre, EventHookMode_Pre);
}

public void OnLSCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	iAntiFarmDuration = lsAntiFarmDuration.IntValue;
	iDuration = lsDuration.IntValue;
	iMobs = lsMobs.IntValue;
	
	bAnnounce = lsAnnounce.BoolValue;
	bMenu = lsMenu.BoolValue;
	bTankDemolition = lsTankDemolition.BoolValue;
	
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
			SetEntityRenderMode(iCheckpointDoor, RENDER_NORMAL);
			SetEntityRenderColor(iCheckpointDoor);
			
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
	if (bMenu)
	{
		bChoiceStarted = false;
	}
	
	InitDoor();
}

public void OnTankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (IsFinaleMap() || HasSaferoomBug() || !bTankDemolition || !bLDFinished)
	{
		return;
	}
	
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank)
	{
		ExecuteSpawn(tank, "tank auto", 1);
	}
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
		SetEntityRenderMode(iCheckpointDoor, RENDER_NORMAL);
		SetEntityRenderColor(iCheckpointDoor);
		
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
				if (bMenu)
				{
					if (bChoiceStarted)
					{
						return Plugin_Continue;
					}
					
					if (bAntiFarmInit || bLDFinished || bLockdownInit)
					{
						bChoiceStarted = true;
						return Plugin_Continue;
					}
					
					bChoiceStarted = true;
					GetClientName(user, sKeyMan, sizeof(sKeyMan));
					
					Menu mSystemChoice = new Menu(mSystemChoiceHandler, MENU_ACTIONS_DEFAULT|MenuAction_VoteEnd);
					mSystemChoice.SetTitle("Choose Desired System:");
					
					mSystemChoice.AddItem("", "Anti-Farm");
					mSystemChoice.AddItem("", "Lockdown");
					
					mSystemChoice.Pagination = MENU_NO_PAGINATION;
					
					int iPlayers, iHumans[MAXPLAYERS+1];
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != 2 || IsFakeClient(i))
						{
							continue;
						}
						
						iHumans[iPlayers++] = i;
					}
					
					mSystemChoice.DisplayVote(iHumans, iPlayers, 30);
				}
				else
				{
					if (GetTankCount() > 0)
					{
						if (bLDFinished || bLockdownInit)
						{
							bAntiFarmInit = true;
							return Plugin_Continue;
						}
						
						iSystemTime = iAntiFarmDuration;
						
						PrintHintText(user, "[LS] %s Still Alive! Kill %s First!", (GetTankCount() != 1) ? "Tanks Are" : "A Tank Is", (GetTankCount() == 1) ? "It" : "Them");
						EmitSoundToAll("doors/latchlocked2.wav", used, SNDCHAN_AUTO);
						
						if (!bAntiFarmInit)
						{
							bAntiFarmInit = true;
							GetClientName(user, sKeyMan, sizeof(sKeyMan));
							
							ExecuteSpawn(user, "mob auto", iMobs);
							
							if (hAntiFarmTime == null)
							{
								hAntiFarmTime = CreateTimer(float(iAntiFarmDuration) + 1.0, EndAntiFarm);
							}
							CreateTimer(1.0, CheckAntiFarm, used, TIMER_REPEAT);
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
							CreateTimer(1.0, CheckLockdown, used, TIMER_REPEAT);
						}
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
					
					iSystemTime = iAntiFarmDuration;
					
					PrintToChatAll("\x05[\x03LS\x05]\x04 Anti-Farm\x01 System Got Most Votes! \x03(\x05%d\x01 Out Of \x05\x03)", iVoteCount[0], iVoteCount[1]);
					EmitSoundToAll("doors/latchlocked2.wav", iCheckpointDoor, SNDCHAN_AUTO);
					
					if (!bAntiFarmInit)
					{
						bAntiFarmInit = true;
						ExecuteSpawn(GetRandomClient(), "mob auto", iMobs);
						
						if (hAntiFarmTime == null)
						{
							hAntiFarmTime = CreateTimer(float(iAntiFarmDuration) + 1.0, EndAntiFarm);
						}
						CreateTimer(1.0, CheckAntiFarm, iCheckpointDoor, TIMER_REPEAT);
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
						CreateTimer(1.0, CheckLockdown, iCheckpointDoor, TIMER_REPEAT);
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
			CreateTimer(1.0, CheckLockdown, entity, TIMER_REPEAT);
		}
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("[ANTI-FARM] %d Second%s!", iSystemTime, (iSystemTime == 1) ? "" : "s");
	iSystemTime -= 1;
	
	return Plugin_Continue;
}

public Action EndAntiFarm(Handle timer)
{
	if (hAntiFarmTime == null)
	{
		return Plugin_Stop;
	}
	
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
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
				{
					PrintHintText(i, "DOOR OPENED!");
				}
			}
			if (bAnnounce)
			{
				PrintToChatAll("\x05[\x03LS\x05]\x04 <\x05%s\x04>\x01 Opened Safe Room!", sKeyMan);
			}
			
			CreateTimer(5.0, LaunchTankDemolition);
		}
		return Plugin_Stop;
	}
	
	EmitSoundToAll("ambient/alarms/klaxon1.wav", entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	PrintCenterTextAll("[LOCKDOWN] %d Second%s!", iSystemTime, (iSystemTime != 1) ? "s" : "");
	
	iSystemTime -= 1;
	return Plugin_Continue;
}

public Action EndLockdown(Handle timer)
{
	if (hLockdownTime == null)
	{
		return Plugin_Stop;
	}
	
	hLockdownTime = null;
	return Plugin_Stop;
}

public Action LaunchTankDemolition(Handle timer)
{
	if (!bTankDemolition)
	{
		return Plugin_Stop;
	}
	
	ExecuteSpawn(GetRandomClient(), "tank auto", 3);
	if (bAnnounce)
	{
		PrintToChatAll("\x05[\x03LS\x05]\x01 Tank Demolition Underway!");
	}
	
	return Plugin_Stop;
}

public void OnMapEnd()
{
	if (!StrEqual(sGameMode, "coop", false))
	{
		return;
	}
	
	if (!IsFinaleMap() && !HasSaferoomBug())
	{
		bAntiFarmInit = false;
		bLockdownInit = false;
		bLDFinished = false;
		if (bMenu)
		{
			bChoiceStarted = false;
		}
		
		if (iCheckpointDoor != 0)
		{
			if (IsValidEntity(iCheckpointDoor) && IsValidEdict(iCheckpointDoor))
			{
				SetEntityRenderMode(iCheckpointDoor, RENDER_NORMAL);
				SetEntityRenderColor(iCheckpointDoor);
				
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
		else
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
	
	SetEntityRenderColor(caller, 0, 0);
	
	CreateTimer(3.0, PreventDoorSpam, EntIndexToEntRef(caller));
}

public Action PreventDoorSpam(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	SetEntityRenderColor(entity, _, _, 0);
	
	SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
	AcceptEntityInput(entity, "Unlock");
	
	return Plugin_Stop;
}

public void OnDoorBlocked(const char[] output, int caller, int activator, float delay)
{
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
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 0);
			
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
			SetEntityRenderMode(entity, RENDER_NORMAL);
			SetEntityRenderColor(entity, _, _, 0);
			
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

stock void ExecuteSpawn(int client, char[] sInfected, int iCount)
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
	for (int i = 0; i < iCount; i++)
	{
		FakeClientCommand(client, "%s %s", sCommand, sInfected);
	}
	SetCommandFlags(sCommand, iFlags);
}

