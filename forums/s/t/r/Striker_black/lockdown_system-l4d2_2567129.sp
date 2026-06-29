#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <glow>

#define PLUGIN_VERSION "2.6"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY
#define MAXLENGTH 128

#define SURVIVOR 2
#define TANK 8

#define UNLOCK 0
#define LOCK 1

ConVar hLSAnnounce, hLS_AFDuration, hLSDuration, hLSMobs, hLSMenu;
int SafetyLock, idGoal;
char nmKeyman[MAXLENGTH], SoundNotice[MAXLENGTH] = "doors/latchlocked2.wav", SoundDoorOpen[MAXLENGTH] = "doors/door_squeek1.wav",
	SoundLockdown[MAXLENGTH] = "ambient/alarms/klaxon1.wav";

bool TanksPresent, IsSystemApplied, IsLockdown, LockdownEnds, menuStarted;
bool bLSAnnounce, bLSMenu;
int tankCount, afTime, lTime, iLSMobs;
int votedNo, votedYes, votedUnknown;
Handle AntiFarmTimer = INVALID_HANDLE, LockdownTimer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "[L4D2] Lockdown System",
	author = "ztar, NiCo-op, cravenge",
	description = "Locks Saferoom Door Until Chosen Keyman Opens It.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
};

public void OnPluginStart()
{
	CreateConVar("ls-l4d2_version", PLUGIN_VERSION, "Lockdown System Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	hLSAnnounce = CreateConVar("ls-l4d2_announce", "1", "Enable/Disable Announcements", CVAR_FLAGS);
	hLS_AFDuration = CreateConVar("ls-l4d2_anti-farm_duration", "150", "Duration Of Ant Farm", CVAR_FLAGS);
	hLSDuration = CreateConVar("ls-l4d2_duration", "60", "Duration Of Lockdown", CVAR_FLAGS);
	hLSMobs = CreateConVar("ls-l4d2_mobs", "5", "Number Of Mobs To Spawn", CVAR_FLAGS);
	hLSMenu = CreateConVar("ls-l4d2_menu", "0", "Enable/Disable Menu", CVAR_FLAGS);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Pre);
	HookEvent("tank_spawn", OnTankSpawn);
	
	AutoExecConfig(true, "l4d2_lockdown");
	
	afTime = hLS_AFDuration.IntValue;
	lTime = hLSDuration.IntValue;
	iLSMobs = hLSMobs.IntValue;
	
	bLSAnnounce = hLSAnnounce.BoolValue;
	bLSMenu = hLSMenu.BoolValue;
	
	HookConVarChange(hLSAnnounce, PlCVarsChanged);
	HookConVarChange(hLS_AFDuration, PlCVarsChanged);
	HookConVarChange(hLSDuration, PlCVarsChanged);
	HookConVarChange(hLSMobs, PlCVarsChanged);
	HookConVarChange(hLSMenu, PlCVarsChanged);
}

public void PlCVarsChanged(Handle cvar, const char[] oV, const char[] nV)
{
	afTime = hLS_AFDuration.IntValue;
	lTime = hLSDuration.IntValue;
	iLSMobs = hLSMobs.IntValue;
	
	bLSAnnounce = hLSAnnounce.BoolValue;
	bLSMenu = hLSMenu.BoolValue;
}

public void OnMapStart()
{
	if (isSystemApplied() || isFirstSet() || isSecondSet())
	{
		PrecacheSound(SoundNotice, true);
		PrecacheSound(SoundDoorOpen, true);
		PrecacheSound(SoundLockdown, true);
		
		PrecacheModel("models/props_doors/checkpoint_door_02.mdl", true);
		/*
		PrecacheModel("models/props_doors/checkpoint_door_-01.mdl", true);
		PrecacheModel("models/props_doors/checkpoint_door_01.mdl", true);
		*/
	}
}

public void OnMapEnd()
{
	if (isSystemApplied() || isFirstSet() || isSecondSet())
	{
		TanksPresent = false;
		IsSystemApplied = false;
		IsLockdown = false;
		LockdownEnds = false;
		tankCount = 0;
		
		ResetTimers();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	CreateTimer(20.0, TimerAnnounce, client);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!isSystemApplied() && !isFirstSet() && !isSecondSet())
	{
		return;
	}
	
	InitDoor();
	
	TanksPresent = false;
	IsSystemApplied = false;
	IsLockdown = false;
	LockdownEnds = false;
	tankCount = 0;
	
	ResetTimers();
	
	if (bLSMenu)
	{
		menuStarted = false;
		
		votedNo = 0;
		votedYes = 0;
		votedUnknown = 0;
	}
}

public Action TimerAnnounce(Handle timer, any client)
{
	if (!bLSAnnounce)
	{
		return Plugin_Stop;
	}
	
	PrintToChat(client, "\x04[LS]\x03 Engaged!");
	return Plugin_Stop;
}

void ResetTimers()
{
	afTime = hLS_AFDuration.IntValue;
	lTime = hLSDuration.IntValue;
	if (AntiFarmTimer != INVALID_HANDLE)
	{
		KillTimer(AntiFarmTimer);
		AntiFarmTimer = INVALID_HANDLE;
	}
	
	CreateTimer(2.0, LockdownFix);
}

public Action LockdownFix(Handle timer)
{
	if (LockdownTimer == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	KillTimer(LockdownTimer);
	LockdownTimer = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank <= 0 || !IsClientInGame(tank) || GetClientTeam(tank) != 3 || GetEntProp(tank, Prop_Send, "m_zombieClass") != 8)
	{
		return;
	}
	
	tankCount -= 1;
	if (tankCount <= 0)
	{
		TanksPresent = false;
		if (AntiFarmTimer != INVALID_HANDLE)
		{
			KillTimer(AntiFarmTimer);
			AntiFarmTimer = INVALID_HANDLE;
		}
	}
}

public Action OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank <= 0 || !IsClientInGame(tank) || GetClientTeam(tank) != 3 || GetEntProp(tank, Prop_Send, "m_zombieClass") != 8)
	{
		return;
	}
	
	tankCount += 1;
	TanksPresent = true;
}

public Action OnPlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (isSystemApplied() || isFirstSet() || isSecondSet())
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		{
			return Plugin_Continue;
		}
		
		int Entity = event.GetInt("targetid");
		if (Entity <= 0 || !IsValidEntity(Entity) || !IsValidEdict(Entity))
		{
			return Plugin_Continue;
		}
		
		if (SafetyLock == LOCK && Entity == idGoal)
		{
			char entname[MAXLENGTH];
			GetEdictClassname(Entity, entname, sizeof(entname));
			if (StrEqual(entname, "prop_door_rotating_checkpoint"))
			{
				AcceptEntityInput(Entity, "Lock");
				SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
				
				GetClientName(client, nmKeyman, sizeof(nmKeyman));
				
				if (bLSMenu)
				{
					if (!menuStarted)
					{
						menuStarted = true;
						
						char cmEntry[8];
						
						Menu chooseMenu = CreateMenu(chooseMenuHandler);
						SetVoteResultCallback(chooseMenu, chooseMenuResults);
						chooseMenu.SetTitle("Want To Do Anti-Farm?");
						
						IntToString(0, cmEntry, sizeof(cmEntry));
						chooseMenu.AddItem(cmEntry, "Yes");
						IntToString(1, cmEntry, sizeof(cmEntry));
						chooseMenu.AddItem(cmEntry, "No");
						
						SetMenuPagination(chooseMenu, MENU_NO_PAGINATION);
						
						int totalHumans, humanPlayers[MAXPLAYERS+1];
						
						for (int i = 1; i <= MaxClients; i++)
						{
							if (!IsClientInGame(i) || GetClientTeam(i) != SURVIVOR || IsFakeClient(i))
							{
								continue;
							}
							
							humanPlayers[totalHumans++] = i;
						}
						
						VoteMenu(chooseMenu, humanPlayers, totalHumans, 30);
					}
				}
				else
				{
					if (TanksPresent)
					{
						KeepItLocked(Entity);
						PrintHintText(client, "Tanks Are Still Alive! Kill Them First!");
						
						if (!IsSystemApplied)
						{
							IsSystemApplied = true;
							
							SpawnMobs(client, iLSMobs);
							
							CreateTimer(1.0, TimerAntiFarm, Entity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
							if (AntiFarmTimer == INVALID_HANDLE)
							{
								AntiFarmTimer = CreateTimer(hLS_AFDuration.FloatValue + 1.0, TimerEndAntiFarm, _, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
					else
					{
						if (!IsLockdown)
						{
							IsLockdown = true;
							
							SpawnMobs(client, iLSMobs);
							
							CreateTimer(1.0, TimerLockdown, Entity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
							if (LockdownTimer == INVALID_HANDLE)
							{
								LockdownTimer = CreateTimer(hLSDuration.FloatValue + 1.0, TimerEndLockdown, _, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public int chooseMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char chosen[8];
			GetMenuItem(menu, param2, chosen, sizeof(chosen));
			switch (StringToInt(chosen))
			{
				case 0: votedYes += 1;
				case 1: votedNo += 1;
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

void KeepItLocked(int entity)
{
	SafetyLock = LOCK;
	ControlDoor(entity, LOCK);
	EmitSoundToAll(SoundNotice, entity);
}

public void chooseMenuResults(Handle menu,
			int num_votes,
			int num_clients,
			const int[][] client_info,
			int num_items,
			const int[][] item_info)
{
	num_votes = votedYes + votedNo;
	if (num_votes < GetHumanCount(SURVIVOR))
	{
		votedUnknown = GetHumanCount(SURVIVOR) - num_votes;
	}
	
	if (votedUnknown > num_votes)
	{
		PrintToChatAll("\x04[LS]\x03 %d\x01 Voted \x05None\x01! Lockdown Ongoing..", votedUnknown);
		if (!IsLockdown)
		{
			IsLockdown = true;
			
			int randClient = GetRandomSpawner();
			SpawnMobs(randClient, iLSMobs);
			
			CreateTimer(1.0, TimerLockdown, idGoal, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			if (LockdownTimer == INVALID_HANDLE)
			{
				LockdownTimer = CreateTimer(hLSDuration.FloatValue + 1.0, TimerEndLockdown, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
	{
		if (votedYes > votedNo)
		{
			PrintToChatAll("\x04[LS]\x03 %d\x01 Out Of \x03%d \x01Voted\x05 Yes\x01! Anti-Farming..", votedYes, GetHumanCount(SURVIVOR));
			
			KeepItLocked(idGoal);
			if (!IsSystemApplied)
			{
				IsSystemApplied = true;
				
				int randCommander = GetRandomSpawner();
				SpawnMobs(randCommander, iLSMobs);
				
				CreateTimer(1.0, TimerAntiFarm, idGoal, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				if (AntiFarmTimer == INVALID_HANDLE)
				{
					AntiFarmTimer = CreateTimer(hLS_AFDuration.FloatValue + 1.0, TimerEndAntiFarm, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			PrintToChatAll("\x04[LS] \x03%d \x01Out Of\x03 %d\x01 Voted \x05No\x01! Initiating Lockdown..", votedNo, GetHumanCount(SURVIVOR));
			if (!IsLockdown)
			{
				IsLockdown = true;
				
				int randExecuter = GetRandomSpawner();
				SpawnMobs(randExecuter, iLSMobs);
				
				CreateTimer(1.0, TimerLockdown, idGoal, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				if (LockdownTimer == INVALID_HANDLE)
				{
					LockdownTimer = CreateTimer(hLSDuration.FloatValue + 1.0, TimerEndLockdown, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action TimerAntiFarm(Handle timer, any entity)
{
	if (AntiFarmTimer == INVALID_HANDLE)
	{
		if (!IsLockdown)
		{
			IsLockdown = true;
			
			int uSpawner = GetRandomSpawner();
			SpawnMobs(uSpawner, hLSMobs.IntValue);
			
			CreateTimer(1.0, TimerLockdown, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			if (LockdownTimer == INVALID_HANDLE)
			{
				LockdownTimer = CreateTimer(hLSDuration.FloatValue + 1.0, TimerEndLockdown, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Stop;
	}
	
	afTime--;
	PrintCenterTextAll("[ANTFARM] %d Seconds!", afTime);
	
	return Plugin_Continue;
}

public Action TimerEndAntiFarm(Handle timer)
{
	if (AntiFarmTimer == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	KillTimer(AntiFarmTimer);
	AntiFarmTimer = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action TimerLockdown(Handle timer, any entity)
{
	if (LockdownTimer == INVALID_HANDLE)
	{
		if (LockdownEnds)
		{
			EmitSoundToAll(SoundDoorOpen, entity);
			SafetyLock = UNLOCK;
			ControlDoor(entity, UNLOCK);
			for (int i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
				{
					PrintHintText(i, "DOOR OPENED!");
				}
			}
			if (hLSAnnounce.BoolValue)
			{
				PrintToChatAll("\x04[LS] \x01<%s>\x03 Opened Safe Room!", nmKeyman);
			}
		}
		return Plugin_Stop;
	}
	
	EmitSoundToAll(SoundLockdown, entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	lTime--;
	PrintCenterTextAll("[DOOR OPENS IN] %d!", lTime);
	
	return Plugin_Continue;
}

public Action TimerEndLockdown(Handle timer)
{
	if (LockdownTimer == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	LockdownEnds = true;
	
	KillTimer(LockdownTimer);
	LockdownTimer = INVALID_HANDLE;
	
	return Plugin_Stop;
}

void SpawnMobs(int spawner, int count)
{
	int flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	for (int i=0; i<count; i++)
	{
		if (spawner == 0)
		{
			ServerCommand("z_spawn mob auto");
			ServerExecute();
		}
		else
		{
			FakeClientCommand(spawner, "z_spawn mob auto");
		}
	}
	SetCommandFlags("z_spawn", flags);
}

void InitDoor()
{
	int Entity = -1;
	while ((Entity = FindEntityByClassname(Entity, "prop_door_rotating_checkpoint")) != -1)
	{
		if (GetEntProp(Entity, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
		{
			idGoal = Entity;
			ControlDoor(Entity, LOCK);
			
			HookSingleEntityOutput(Entity, "OnFullyOpen", StartAntiSpamProcedure);
			HookSingleEntityOutput(Entity, "OnFullyClose", StartAntiSpamProcedure);
		}
	}
	SafetyLock = LOCK;
}

public void StartAntiSpamProcedure(const char[] output, int caller, int activator, float delay)
{
	AcceptEntityInput(caller, "Lock");
	SetEntProp(caller, Prop_Data, "m_hasUnlockSequence", LOCK);
	L4D2_SetEntGlow(caller, L4D2Glow_Constant, 550, 0, {0, 0, 255}, false);
	
	CreateTimer(3.0, StopAntiSpamProcedure, EntIndexToEntRef(caller), TIMER_FLAG_NO_MAPCHANGE);
}

public Action StopAntiSpamProcedure(Handle timer, any doorEnt)
{
	if ((doorEnt = EntRefToEntIndex(doorEnt)) == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}
	
	L4D2_SetEntGlow(doorEnt, L4D2Glow_Constant, 550, 0, {255, 255, 0}, false);
	SetEntProp(doorEnt, Prop_Data, "m_hasUnlockSequence", UNLOCK);
	AcceptEntityInput(doorEnt, "Unlock");
	
	return Plugin_Stop;
}

void ControlDoor(int Entity, int Operation)
{
	if (Operation == LOCK)
	{
		L4D2_SetEntGlow(Entity, L4D2Glow_Constant, 550, 0, {0, 0, 255}, false);
		
		AcceptEntityInput(Entity, "Close");
		AcceptEntityInput(Entity, "Lock");
		AcceptEntityInput(Entity, "ForceClosed");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if (Operation == UNLOCK)
	{
		L4D2_SetEntGlow(Entity, L4D2Glow_Constant, 550, 0, {255, 255, 0}, false);
		
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(Entity, "Unlock");
		AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Open");
	}
}

int GetRandomSpawner()
{
	int igClientsCount, igClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			igClients[igClientsCount++] = i;
		}
	}
	return (igClientsCount == 0) ? 0 : igClients[GetRandomInt(0, igClientsCount - 1)];
}

bool isSystemApplied()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if ((StrEqual(mapname, "c1m1_hotel", false)) 			||	//Dead Center 1
		(StrEqual(mapname, "c2m1_highway", false)) 		|| 	//Dark Carnival 1
		(StrEqual(mapname, "c3m1_plankcountry", false)) 	|| 	//Swamp Fever 1	
		(StrEqual(mapname, "c4m1_milltown_a", false)) 		|| 	//Hard Rain 1
		(StrEqual(mapname, "c5m1_waterfront", false)) 		|| 	//The Paris 1
		(StrEqual(mapname, "c6m1_riverbank", false)) 		|| 	//The Passing 1	
		(StrEqual(mapname, "c7m1_docks", false)) 			|| 	//The Sacrifice 1
		(StrEqual(mapname, "c8m1_apartment", false)) 		||	//No Mercy 1
		(StrEqual(mapname, "c9m1_alleys", false)) 			||	//Crash Course 1
		(StrEqual(mapname, "c10m1_caves", false)) 			||	//Death Troll 1
		(StrEqual(mapname, "c11m1_greenhouse", false)) 	|| 	//Dead Air 1
		(StrEqual(mapname, "c12m1_hilltop", false)) 		|| 	//Blood Harvest 1
		(StrEqual(mapname, "c13m1_alpinecreek", false))) 		//Cold Stream 1
	{
		return true;
	}
	return false;
}

bool isFirstSet()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if ((StrEqual(mapname, "c1m2_streets", false)) 		|| 	//Dead Center 2
		(StrEqual(mapname, "c2m2_fairgrounds", false)) 	|| 	//Dark Carnival 2
		(StrEqual(mapname, "c3m2_swamp", false)) 			|| 	//Swamp Fever 2	
		(StrEqual(mapname, "c4m2_sugarmill_a", false)) 	||	//Hard Rain 2
		(StrEqual(mapname, "c5m2_park", false)) 			||	//The Paris 2
		(StrEqual(mapname, "c6m2_bedlam", false)) 			|| 	//The Passing 2
		//(StrEqual(mapname, "c7m2_barge", false)) 			||	//The Sacrifice
		(StrEqual(mapname, "c8m2_subway", false)) 			|| 	//No Mercy 2
		//Crash Course 											//Crash Course 2
		(StrEqual(mapname, "c10m2_drainage", false)) 		||	//Death Troll 2
		(StrEqual(mapname, "c11m2_offices", false)) 		||	//Dead Air 2
		(StrEqual(mapname, "c12m2_traintunnel", false)) 	|| 	//Blood Harvest 2
		(StrEqual(mapname, "c13m2_southpinestream", false))) 	//Cold Stream 2
	{
		return true;
	}
	return false;
}

bool isSecondSet()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if ((StrEqual(mapname, "c1m3_mall", false)) 			||	//Dead Center 3
		(StrEqual(mapname, "c2m3_coaster", false)) 		|| 	/*Dark Carnival 3*/ (StrEqual(mapname, "c2m4_barns", false)) 		||	//Dark Carnival 4
		(StrEqual(mapname, "c3m3_shantytown", false)) 		|| 	//Swamp Fever 3
		(StrEqual(mapname, "c4m3_sugarmill_b", false)) 	|| 	/*Hard Rain 3*/ 	(StrEqual(mapname, "c4m4_milltown_b", false)) 	||	//Hard Rain 4
		(StrEqual(mapname, "c5m3_cemetery", false)) 		|| 	/*The Paris 3*/ 	(StrEqual(mapname, "c5m4_quarter", false)) 	||	//The Paris 4
		//The Passing											//The Passing	
		(StrEqual(mapname, "c7m2_barge", false)) 			||	//The Sacrifice 2
		(StrEqual(mapname, "c8m3_sewers", false)) 			|| 	/*No Mercy 3*/		(StrEqual(mapname, "c8m4_interior", false)) 	||	//No Mercy 4
		//Crash Course											//Crash Course
		(StrEqual(mapname, "c10m3_ranchhouse", false)) 	||	/*Death Troll 3*/ 	(StrEqual(mapname, "c10m4_mainstreet", false))	||	//Death Troll 4
		(StrEqual(mapname, "c11m3_garage", false)) 		||	/*Dead Air 3*/		(StrEqual(mapname, "c11m4_terminal", false)) 	||	//Dead Air 4
		(StrEqual(mapname, "c12m3_bridge", false)) 		||	/*Blood Harvest 3*/ (StrEqual(mapname, "c12m4_barn", false)) 		||	//Blood Harvest 4
		(StrEqual(mapname, "c13m3_memorialbridge", false)))	//Cold Stream 3
	{
		return true;
	}
	return false;
}

int GetHumanCount(any team)
{
	int totalCounts;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i))
		{
			totalCounts += 1;
		}
	}
	return totalCounts;
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
    {
        return false; 
    }
    return true;
}

