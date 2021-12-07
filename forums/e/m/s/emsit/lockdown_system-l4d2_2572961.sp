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

	AutoExecConfig(true, "lockdown_system-l4d2");

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
				ControlDoor(Entity, LOCK);

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
			if (GetEntProp(Entity, Prop_Send, "m_spawnflags") == 32768)
			{
				continue;
			}

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
	if ((StrEqual(mapname, "c1m1_hotel", false)) || (StrEqual(mapname, "c1m1d_hotel", false)) ||
		(StrEqual(mapname, "c2m1_highway", false)) ||
		(StrEqual(mapname, "c3m1_plankcountry", false)) ||
		(StrEqual(mapname, "c4m1_milltown_a", false)) ||
		(StrEqual(mapname, "c5m1_waterfront", false)) ||
		(StrEqual(mapname, "c6m1_riverbank", false)) ||
		(StrEqual(mapname, "c7m1_docks", false)) ||
		(StrEqual(mapname, "c8m1_apartment", false)) || (StrEqual(mapname, "l4d2_hospital01_apartment")) ||
		(StrEqual(mapname, "c9m1_alleys", false)) || (StrEqual(mapname, "l4d2_garage01_alleys_a")) || (StrEqual(mapname, "c9m1_alleys_daytime", false)) ||
		(StrEqual(mapname, "c10m1_caves", false)) || (StrEqual(mapname, "l4d2_smalltown01_caves", false)) ||
		(StrEqual(mapname, "c11m1_greenhouse", false)) ||
		(StrEqual(mapname, "c12m1_hilltop", false)) ||
		(StrEqual(mapname, "c13m1_alpinecreek", false)) || (StrEqual(mapname, "c13m1_alpinecreek_night")) ||
		(StrEqual(mapname, "cwm1_intro", false)) ||
		(StrEqual(mapname, "l4d2_city17_01", false)) ||
		(StrEqual(mapname, "c1_1_mall", false)) ||
		(StrEqual(mapname, "gasfever_1", false)) ||
		(StrEqual(mapname, "jsgone01_crash", false)) ||
		(StrEqual(mapname, "c1_mario1_1", false)) ||
		(StrEqual(mapname, "wth_1", false)) ||
		(StrEqual(mapname, "lost01_club", false)) ||
		(StrEqual(mapname, "l4d2_darkblood01_tanker", false)) ||
		(StrEqual(mapname, "left4cake201_start")) ||
		(StrEqual(mapname, "bwm1_climb")) ||
		(StrEqual(mapname, "l4d2_pasiri1")) ||
		(StrEqual(mapname, "l4d_draxmap0")) ||
		(StrEqual(mapname, "p84m1_crash")) ||
		(StrEqual(mapname, "l4d2_tunnel")) ||
		(StrEqual(mapname, "cbm1_lake")) ||
		(StrEqual(mapname, "l4d_coldfear01_smallforest")) ||
		(StrEqual(mapname, "apartment")) ||
		(StrEqual(mapname, "aircrash")) ||
		(StrEqual(mapname, "hellishjourney01")) || (StrEqual(mapname, "hellishjourney01_l4d2")) ||
		(StrEqual(mapname, "jsarena201_town")) ||
		(StrEqual(mapname, "uf1_boulevard")) ||
		(StrEqual(mapname, "ch_map1_city")) ||
		(StrEqual(mapname, "l4d2_orange01_city")) ||
		(StrEqual(mapname, "youcallthatalanding")) ||
		(StrEqual(mapname, "l4d2_scream01_yards")) ||
		(StrEqual(mapname, "l4d2_win1")) ||
		(StrEqual(mapname, "damshort170surv")) ||
		(StrEqual(mapname, "qe_1_cliche")) || (StrEqual(mapname, "QE_1_cliche")) ||
		(StrEqual(mapname, "qe2_ep1")) || (StrEqual(mapname, "QE2_ep1")) ||
		(StrEqual(mapname, "grmap1")) ||
		(StrEqual(mapname, "wfp1_track")) ||
		(StrEqual(mapname, "l4d2_pdmesa01_surface")) ||
		(StrEqual(mapname, "l4d2_diescraper1_apartment_35")) ||
		(StrEqual(mapname, "carnage_jail", false)) ||
		(StrEqual(mapname, "l4d_linz_kbh", false)) ||
		(StrEqual(mapname, "l4d_naniwa01_shoppingmall", false)) ||
		(StrEqual(mapname, "m1_beach", false)) ||
		(StrEqual(mapname, "dead_death_02", false)) ||
		(StrEqual(mapname, "hotel01_market_two", false)) ||
		(StrEqual(mapname, "village_beta408", false)) ||
		(StrEqual(mapname, "blood_hospital_01", false)) ||
		(StrEqual(mapname, "l4d2_ravenholmwar_1", false)) ||
		(StrEqual(mapname, "2019_M1b", false)) || (StrEqual(mapname, "2019_m1b", false)) ||
		(StrEqual(mapname, "c8m1_apartment_daytime", false)) ||
		(StrEqual(mapname, "l4d2_the_complex_final_01", false)) ||
		(StrEqual(mapname, "soi_m1_metrostation", false)) ||
		(StrEqual(mapname, "l4d_fallen01_approach", false)) ||
		(StrEqual(mapname, "symbyosys_intro", false)))
	{
		return true;
	}
	return false;
}

bool isFirstSet()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if ((StrEqual(mapname, "c1m2_streets", false)) || (StrEqual(mapname, "c1m2d_streets", false)) ||
		(StrEqual(mapname, "c2m2_fairgrounds", false)) || (StrEqual(mapname, "c2m4_barns", false)) ||
		(StrEqual(mapname, "c3m2_swamp", false)) ||
		(StrEqual(mapname, "c4m2_sugarmill_a", false)) || (StrEqual(mapname, "c4m4_milltown_b", false)) ||
		(StrEqual(mapname, "c5m2_park", false)) || (StrEqual(mapname, "c5m4_quarter", false)) ||
		(StrEqual(mapname, "c6m2_bedlam", false)) ||
		(StrEqual(mapname, "c8m3_sewers", false)) ||
		(StrEqual(mapname, "c10m4_mainstreet", false)) ||
		(StrEqual(mapname, "l4d2_smalltown04_mainstreet", false)) ||
		(StrEqual(mapname, "c11m2_offices", false)) || (StrEqual(mapname, "c11m2_offices_day", false)) || (StrEqual(mapname, "c11m4_terminal", false)) || (StrEqual(mapname, "c11m4_terminal_day", false)) ||
		(StrEqual(mapname, "c12m3_bridge", false)) ||
		(StrEqual(mapname, "c13m3_memorialbridge", false)) ||
		(StrEqual(mapname, "cwm3_drain", false)) ||
		(StrEqual(mapname, "l4d2_city17_02", false)) || (StrEqual(mapname, "l4d2_city17_04", false)) ||
		(StrEqual(mapname, "c1_2_jam", false)) ||
		(StrEqual(mapname, "c1_mario1_2", false)) ||
		(StrEqual(mapname, "wth_3", false)) ||
		(StrEqual(mapname, "lost02_", false)) || (StrEqual(mapname, "lost04", false)) ||
		(StrEqual(mapname, "l4d2_darkblood02_engine", false)) ||
		(StrEqual(mapname, "left4cake202_dos")) ||
		(StrEqual(mapname, "c13m2_southpinestream_night")) ||
		(StrEqual(mapname, "bwm3_forest")) ||
		(StrEqual(mapname, "l4d2_pasiri3")) ||
		(StrEqual(mapname, "l4d_draxmap2")) ||
		(StrEqual(mapname, "p84m2_train")) ||
		(StrEqual(mapname, "l4d2_tracks")) || (StrEqual(mapname, "l4d2_tracks_vs")) ||
		(StrEqual(mapname, "l4d_coldfear02_factory")) || (StrEqual(mapname, "l4d_coldfear04_roffs")) ||
		(StrEqual(mapname, "l4d2_garage02_lots_b")) ||
		(StrEqual(mapname, "station-a")) ||
		(StrEqual(mapname, "rivermotel")) || (StrEqual(mapname, "cityhall")) ||
		(StrEqual(mapname, "hellishjourney02_l4d2")) ||
		(StrEqual(mapname, "jsarena203_roof")) ||
		(StrEqual(mapname, "l4d2_hospital02_subway")) || (StrEqual(mapname, "l4d2_hospital04_interior")) ||
		(StrEqual(mapname, "uf3_harbor", false)) ||
		(StrEqual(mapname, "ch_map2_temple")) ||
		(StrEqual(mapname, "surface")) ||
		(StrEqual(mapname, "l4d2_scream02_goingup")) || (StrEqual(mapname, "l4d2_scream04_train")) ||
		(StrEqual(mapname, "l4d2_win3")) || (StrEqual(mapname, "l4d2_win5")) ||
		(StrEqual(mapname, "qe_2_remember_me")) || (StrEqual(mapname, "QE_2_remember_me")) ||
		(StrEqual(mapname, "gemarshy02fac")) ||
		(StrEqual(mapname, "wfp3_mill")) ||
		(StrEqual(mapname, "gridmap2")) ||
		(StrEqual(mapname, "l4d2_pdmesa03_office")) ||
		(StrEqual(mapname, "l4d2_diescraper2_streets_35")) ||
		(StrEqual(mapname, "carnage_basement", false)) ||
		(StrEqual(mapname, "busbahnhof1", false)) || (StrEqual(mapname, "l4d_linz_zurueck", false)) ||
		(StrEqual(mapname, "l4d_naniwa03_highway", false)) ||
		(StrEqual(mapname, "m2_burbs", false)) || (StrEqual(mapname, "m4_launchpad", false)) ||
		(StrEqual(mapname, "dead_death_01", false)) ||
		(StrEqual(mapname, "hotel02_sewer_two", false)) || (StrEqual(mapname, "hotel04_scaling_two", false)) ||
		(StrEqual(mapname, "urban_beta408", false)) ||
		(StrEqual(mapname, "blood_hospital_02", false)) ||
		(StrEqual(mapname, "l4d2_ravenholmwar_3", false)) ||
		(StrEqual(mapname, "2019_M2b", false)) || (StrEqual(mapname, "2019_m2b", false)) ||
		(StrEqual(mapname, "c8m3_sewers_daytime", false)) ||
		(StrEqual(mapname, "soi_m2_museum", false)) || (StrEqual(mapname, "soi_m3_biolab", false)) ||
		(StrEqual(mapname, "l4d_fallen03_tower", false)) ||
		(StrEqual(mapname, "symbyosys_02", false)) || (StrEqual(mapname, "symbyosys_04", false)))
	{
		return true;
	}
	return false;
}

bool isSecondSet()
{
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if ((StrEqual(mapname, "c1m3_mall", false)) || (StrEqual(mapname, "c1m3d_mall", false)) ||
		(StrEqual(mapname, "c2m3_coaster", false)) ||
		(StrEqual(mapname, "c3m3_shantytown", false)) ||
		(StrEqual(mapname, "c4m3_sugarmill_b", false)) ||
		(StrEqual(mapname, "c5m3_cemetery", false)) ||
		(StrEqual(mapname, "c7m2_barge", false)) ||
		(StrEqual(mapname, "c8m2_subway", false)) || (StrEqual(mapname, "c8m4_interior", false)) ||
		(StrEqual(mapname, "c10m2_drainage", false)) || (StrEqual(mapname, "l4d2_smalltown02_drainage", false)) ||
		(StrEqual(mapname, "c11m3_garage", false)) || (StrEqual(mapname, "c11m3_garage_day", false)) ||
		(StrEqual(mapname, "c12m2_traintunnel", false)) || (StrEqual(mapname, "c12m4_barn", false)) ||
		(StrEqual(mapname, "c13m2_southpinestream", false)) ||
		(StrEqual(mapname, "cwm2_warehouse", false)) ||
		(StrEqual(mapname, "l4d2_city17_03", false)) ||
		(StrEqual(mapname, "c1_3_school", false)) ||
		(StrEqual(mapname, "gasfever_2", false)) ||
		(StrEqual(mapname, "c1_mario1_3", false)) ||
		(StrEqual(mapname, "wth_2", false)) || (StrEqual(mapname, "wth_4", false)) ||
		(StrEqual(mapname, "lost03", false)) || (StrEqual(mapname, "lost02_1", false)) ||
		(StrEqual(mapname, "l4d2_darkblood03_platform", false)) ||
		(StrEqual(mapname, "c13m3_memorialbridge_night")) ||
		(StrEqual(mapname, "bwm2_city")) || (StrEqual(mapname, "bwm4_rooftops")) ||
		(StrEqual(mapname, "l4d2_pasiri2")) ||
		(StrEqual(mapname, "l4d_draxmap3")) ||
		(StrEqual(mapname, "p84m3_clubd")) ||
		(StrEqual(mapname, "l4d2_forest")) || (StrEqual(mapname, "l4d2_cave")) || (StrEqual(mapname, "l4d2_forest_vs")) || (StrEqual(mapname, "l4d2_cave_vs")) ||
		(StrEqual(mapname, "cbm2_town")) ||
		(StrEqual(mapname, "l4d_coldfear03_officebuilding")) ||
		(StrEqual(mapname, "l4d2_garage02_lots_a")) || (StrEqual(mapname, "l4d2_garage01_alleys_b")) ||
		(StrEqual(mapname, "hotel")) ||
		(StrEqual(mapname, "outskirts")) ||
		(StrEqual(mapname, "hellishjourney02")) ||
		(StrEqual(mapname, "jsarena202_alley")) ||
		(StrEqual(mapname, "l4d2_hospital03_sewers")) ||
		(StrEqual(mapname, "uf2_rooftops", false)) ||
		(StrEqual(mapname, "l4d2_orange02_mountain")) || (StrEqual(mapname, "l4d2_orange03_sky")) ||
		(StrEqual(mapname, "devilscorridor")) || (StrEqual(mapname, "ftlostonahill")) ||
		(StrEqual(mapname, "l4d2_scream03_rooftops")) ||
		(StrEqual(mapname, "l4d2_win2")) || (StrEqual(mapname, "l4d2_win4")) ||
		(StrEqual(mapname, "qe_3_unorthodox_paradox")) || (StrEqual(mapname, "QE_3_unorthodox_paradox")) ||
		(StrEqual(mapname, "qe2_ep2")) || (StrEqual(mapname, "QE2_ep2")) || (StrEqual(mapname, "qe2_ep3")) || (StrEqual(mapname, "QE2_ep3")) || (StrEqual(mapname, "qe2_ep4")) || (StrEqual(mapname, "QE2_ep4", false)) ||
		(StrEqual(mapname, "wfp2_horn")) ||
		(StrEqual(mapname, "gridmap3")) ||
		(StrEqual(mapname, "l4d2_pdmesa02_shafted")) || (StrEqual(mapname, "l4d2_pdmesa04_pointinsert")) ||
		(StrEqual(mapname, "l4d2_diescraper3_mid_35")) ||
		(StrEqual(mapname, "carnage_canyon", false)) ||
		(StrEqual(mapname, "l4d_linz_ok", false)) ||
		(StrEqual(mapname, "l4d_naniwa02_arcade", false)) || (StrEqual(mapname, "l4d_naniwa04_subway", false)) ||
		(StrEqual(mapname, "m3_crowd_control", false)) ||
		(StrEqual(mapname, "dead_death_03", false)) || (StrEqual(mapname, "reactor_1_canal", false)) ||
		(StrEqual(mapname, "hotel03_ramsey_two", false)) ||
		(StrEqual(mapname, "forest_beta407", false)) ||
		(StrEqual(mapname, "l4d2_ravenholmwar_2", false)) ||
		(StrEqual(mapname, "c8m2_subway_daytime", false)) || (StrEqual(mapname, "c8m4_interior_witchesday", false)) ||
		(StrEqual(mapname, "l4d2_the_complex_final_02", false)) ||
		(StrEqual(mapname, "l4d_fallen02_trenches", false)) || (StrEqual(mapname, "l4d_fallen04_cliff", false)) ||
		(StrEqual(mapname, "symbyosys_01", false)) || (StrEqual(mapname, "symbyosys_03_bridge", false)) || (StrEqual(mapname, "symbyosys_05_final", false)))
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

