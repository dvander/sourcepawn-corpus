#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "2.6a"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"
#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"

int spawnWaitTime, countDown, clientTimeout[MAXPLAYERS + 1] = {0, ...};
int ent_safedoor = 0;
int ent_safedoor_check = 0;
int indexClientReady[MAXPLAYERS + 1] = {0, ...};
// 0=spectator, 1 = unready, 2=ready

bool isFirstRound = false;
bool isFreezeAllowed = false;
bool isInvulnerable = false;
bool isTheDoorBreakeble = false;
bool isTheDoorOpened = false;
bool isReadyUpMode = false;
bool isClientLoading[MAXPLAYERS + 1] = {false, ...};
bool isClientSpawning[MAXPLAYERS + 1] = {false, ...};
bool isGameModeBool = false;

ConVar cvarInvulnerable; 
ConVar cvarFreezeNodoor;
ConVar cvarDisplayMode;
ConVar cvarGameModeEnabled;
ConVar cvarReadyUpMode;
ConVar cvarMpGamemode;
ConVar cvarStartPrevent;

ConVar cvarBreakTheDoor;
ConVar cvarPrepareTime1r;
ConVar cvarPrepareTime2r;
ConVar cvarWaitForInfected;
ConVar cvarClientTimeOut;
ConVar cvarDisplayPanel;

Panel statusPanel;

public Plugin myinfo =
{
	name = "L4D2 Door Lock",
	author = "Glide Loading",
	//Original developer: lilDrowOuw
	//L4D2 Port and bugfixing: AtomicStryker
	
	description = "Saferoom Door locked until all players loaded and infected are ready to spawn",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showpost.php?p=1373587&postcount=136"
};

public void OnPluginStart()
{
	HookEvent("round_start", DL_Event_RoundStart);
	HookEvent("player_hurt", DL_Event_PlayerHurt);
	HookEvent("player_left_start_area", DL_Event_PlayerLeftSstartArea);
	HookEvent("player_left_checkpoint", DL_Event_PlayerLeftSstartArea);
	HookEvent("door_open", DL_Event_DoorOpen);
	HookEvent("player_team", DL_Event_Join_Team);
	HookEvent("round_end", DL_Event_RoundEnd);
	HookEvent("player_bot_replace", DL_Event_PlayerBotReplace);
	HookEvent("bot_player_replace", DL_Event_BotPlayerReplace);
	HookEvent("ghost_spawn_time", DL_Event_GhostSpawnTime);
	HookEvent("player_first_spawn", DL_Event_PlayerFirstSpawn);
	HookEvent("player_spawn", DL_Event_PlayerSpawn);

	RegConsoleCmd("sm_ready", DL_ClientReady);
	RegConsoleCmd("sm_unready", DL_ClientUnready);
	
	CreateConVar("l4d2_dlock_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS|FCVAR_REPLICATED);

	cvarInvulnerable = CreateConVar("l4d2_dlock_godmode", "0", "If enabled, survivors invulnerable while they are in saferoom.", CVAR_FLAGS);
	cvarFreezeNodoor = CreateConVar("l4d2_dlock_freezenodoor", "1", "Freeze survivors if start saferoom door is absent", CVAR_FLAGS);
	cvarPrepareTime1r = CreateConVar("l4d2_dlock_prepare1st", "20", "How many seconds plugin will wait after all clients have loaded before starting first round on a map", CVAR_FLAGS);
	cvarPrepareTime2r = CreateConVar("l4d2_dlock_prepare2nd", "20", "How many seconds plugin will wait after all clients have loaded before starting second round on a map", CVAR_FLAGS);
	cvarWaitForInfected = CreateConVar("l4d2_dlock_infectedspawn", "1", "Wait for infected to be ready to spawn before starting countdown", CVAR_FLAGS);
	cvarClientTimeOut = CreateConVar("l4d2_dlock_timeout", "45", "How many seconds plugin will wait after a map starts before giving up on waiting for a client", CVAR_FLAGS);
	cvarBreakTheDoor = CreateConVar("l4d2_dlock_weakdoor", "1", "Saferoom door will be breaked, once opened.", CVAR_FLAGS);
	cvarStartPrevent = CreateConVar("l4d2_dlock_startprevent", "1", "If enabled, versus round will not start until safe-room door become opened.", CVAR_FLAGS);
	cvarDisplayPanel = CreateConVar("l4d2_dlock_displaypanel", "2", "Display players state panel. 0-disabled, 1-hide failed, 2-full info", CVAR_FLAGS);
	cvarDisplayMode = CreateConVar("l4d2_dlock_displaymode", "hint", "Set the display mode for the countdown. (hint, center, chat. any other value to hide countdown)", CVAR_FLAGS);
	cvarReadyUpMode = CreateConVar("l4d2_dlock_readyupmode", "0", "NOT IMPLEMENTED. DO NOT ENABLE !!! 0 - timer, 1 - ready-up mode", CVAR_FLAGS);
	cvarGameModeEnabled = CreateConVar("l4d2_dlock_gamemodeactive", "coop,versus,teamversus,mutation13", "Set the game mode for which the plugin should be activated", CVAR_FLAGS);

	cvarMpGamemode = FindConVar("mp_gamemode");

	LoadTranslations("doorlock.phrases");

	AutoExecConfig(true, "l4d2_doorlock");

	CheckGamemode();
}

public void OnMapStart()
{
	isFirstRound = true;
}

void DL_Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	isTheDoorBreakeble = false;
	isFreezeAllowed = false;
	isInvulnerable = false;
	isReadyUpMode = false;
	isTheDoorOpened = false;
	
	ent_safedoor = -1;

	CheckGamemode();
	CreateTimer(0.2, PluginStartSequence01);
}

Action PluginStartSequence01(Handle timer)
{
	if (isGamemode())
	{
		if(cvarReadyUpMode.BoolValue) isReadyUpMode = true;

		for (int i = 1; i <= MaxClients; i++)
		{
			isClientLoading[i] = true;
			clientTimeout[i] = 0;

			if (isReadyUpMode) indexClientReady[i] = 0;
		}

		CheckSafeRoomDoor();
		SurvivorsBotStop();
		CreateTimer(0.2, PluginStartSequence02);
	}
	else SurvivorsBotStart();
	return Plugin_Stop;
}

Action PluginStartSequence02(Handle timer)
{
	countDown = -1;
	spawnWaitTime = 10;

	if(cvarBreakTheDoor.BoolValue && (ent_safedoor > 0)) isTheDoorBreakeble = true;

	if(cvarInvulnerable.BoolValue) isInvulnerable = true;

	if (ent_safedoor > 0)
	{
		LockTheDoor();
		CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else if (GetConVarBool(cvarFreezeNodoor))
	{
		isFreezeAllowed = true;
		CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else
	{
		SurvivorsBotStart();
		countDown = 0;
	}
	return Plugin_Stop;
}

Action DL_ClientReady(int client, int args)
{
	if (isReadyUpMode && (indexClientReady[client] = 1))
	{
		indexClientReady[client] = 2;

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%t", "DL_Ready", name);
		ShowStatusPanel();
	}
	return Plugin_Handled;
}

Action DL_ClientUnready(int client, int args)
{
	if (isReadyUpMode && (indexClientReady[client] = 2))
	{
		indexClientReady[client] = 1;

		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%t", "DL_Unready", name);
		ShowStatusPanel();
	}
	return Plugin_Handled;
}


/*public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client) && isCountDownStoppedOrRunning())
	{
		isClientLoading[client] = false;
		clientTimeout[client] = 0;
	}
}*/

public void OnClientDisconnect(int client)
{
	isClientLoading[client] = false;
	clientTimeout[client] = 0;
}

void DL_Event_Join_Team(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int client_team = event.GetInt("team");
	if (isClientValid(client) && isCountDownStoppedOrRunning())
	{
		isClientLoading[client] = false;
		clientTimeout[client] = 0;
	}

	if (isReadyUpMode)
	{
		switch (client_team)
		{
			case 1:
			{
				indexClientReady[client] = 0;
			}
			case 2:
			{	
				indexClientReady[client] = 2;
			}
			case 3:
			{
				indexClientReady[client] = 3;
			}
		}
	}
}

void DL_Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (isGamemode())
	{
		if (isFirstRound) isFirstRound = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (isFreezeAllowed && (isCountDownStopped() || isCountDownStoppedOrRunning()))
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
	return Plugin_Continue;
}

Action DL_Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if (!isFreezeAllowed || (isFreezeAllowed && !isCountDownStoppedOrRunning()))
	{
		if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Continue;
}

Action DL_Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (isCountDownStoppedOrRunning() || isCountDownStopped())
	{
		if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_WALK);
		if (IsValidEntity(bot)) SetEntityMoveType(bot, MOVETYPE_NONE);
	}
	return Plugin_Continue;
}

void DL_Event_GhostSpawnTime(Event event, const char[] name, bool dontBroadcast)
{
	if (cvarWaitForInfected.BoolValue)
	{
		int time = event.GetInt("spawntime");
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (isCountDownStoppedOrRunning())
		{
			if (time > spawnWaitTime) spawnWaitTime = time;
			isClientSpawning[client] = (time > 0);
		}
	}
}

void DL_Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client) return;

	if (IsClientConnected(client))
	{
		if (isCountDownStoppedOrRunning() && isFreezeAllowed && GetClientTeam(client) == 2)
		{
			if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
}

void DL_Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (cvarWaitForInfected.BoolValue)
	{
		if (isCountDownStoppedOrRunning() && GetClientTeam(client) == 3 && !IsFakeClient(client))
		{
			isClientSpawning[client] = false;
		}
	}
}

Action StartTimer(Handle timer)
{
	if (isReadyUpMode) PrintTextAll("Ready-up mode is not implemented. Disable it and restart round.");
	else
	{
		if (countDown == -1)
		{
			SurvivorsBotStop();
			return Plugin_Stop;
		}
		else if (countDown++ >= (isFirstRound ? cvarPrepareTime1r.IntValue : cvarPrepareTime2r.IntValue) - 1)
		{
			countDown = 0;
			PrintTextAll("%t", "DL_Moveout");
			SurvivorsBotStart();
			UnFreezePlayers();

			if (ent_safedoor > 0) UnlockTheDoor();

			isFirstRound = false;
			return Plugin_Stop;
		}
		else
		{
			if (!isFreezeAllowed)
			{
				PrintTextAll("%t", "DL_Locked", GetConVarInt(isFirstRound ? cvarPrepareTime1r : cvarPrepareTime2r) - countDown);
			}
			else
			{
				PrintTextAll("%t", "DL_Frozen", GetConVarInt(isFirstRound ? cvarPrepareTime1r : cvarPrepareTime2r) - countDown);
			}
		}
	}
	return Plugin_Continue;
}

Action LoadingTimer(Handle timer)
{
	if (isFinishedLoading())
	{
		if (!isFreezeAllowed) UnFreezePlayers();

		if (cvarWaitForInfected.BoolValue)
		{
			CreateTimer(1.0, SpawningTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			return Plugin_Stop;
		}
		else
		{
			if (!isCountDownRunning())
			{
				countDown = 0;

				if (!isFreezeAllowed)
				{
					SurvivorsBotStart();
					CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				}
			}
			return Plugin_Stop;
		}
	}
	else countDown = -1;

	return Plugin_Continue;
}

Action SpawningTimer(Handle timer)
{
	if (isInfectedTeamReady())
	{
		if (!isCountDownRunning())
		{
			countDown = 0;
			CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			if (!isFreezeAllowed) SurvivorsBotStart();
		}
		return Plugin_Stop;
	}
	else countDown = -1;

	return Plugin_Continue;
}

void SurvivorsBotStart()
{
	FindConVar("sb_stop").SetInt(0);
}

void SurvivorsBotStop()
{
	FindConVar("sb_stop").SetInt(1);
}

void ShowStatusPanel()
{
	if((cvarDisplayPanel.IntValue > 0 && isFirstRound) || isReadyUpMode)
	{
		if (statusPanel != null) delete statusPanel;

		statusPanel = new Panel();

		char readyPlayers[1024];

		int timelimit = cvarClientTimeOut.IntValue;

		int connected;
		int loading;
		int failed;
		int ready;
		int unready;

		int i;
		for (i = 1; i <= MaxClients; i++) 
		{
			if(IsClientConnected(i) && !IsFakeClient(i)) 
			{
				if (!isReadyUpMode)
				{
					if(isClientLoading[i]) loading++;
					else if (clientTimeout[i] >= timelimit) failed++;
					else connected++;
				}
				else
				{
					if(isClientLoading[i]) loading++;
					else if (clientTimeout[i] >= timelimit) failed++;
					else if (indexClientReady[i] == 2) ready++;
					else unready++;
				}
			}
		}

		char DL_Menu_Header[128];
		Format(DL_Menu_Header, sizeof(DL_Menu_Header), "%t", "DL_Menu_Header");
		statusPanel.DrawText(DL_Menu_Header);

		if(loading)
		{
			char DL_Menu_Connecting[128];
			Format(DL_Menu_Connecting, sizeof(DL_Menu_Connecting), "%t", "DL_Menu_Connecting");
			statusPanel.DrawText(DL_Menu_Connecting);
			loading = 0;

			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i])
					{
						loading++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", loading, i);
						statusPanel.DrawText(readyPlayers);
					}
				}
			}
		}

		if(connected)
		{
			char DL_Menu_Ingame[128];
			Format(DL_Menu_Ingame, sizeof(DL_Menu_Ingame), "%t", "DL_Menu_Ingame");
			statusPanel.DrawText(DL_Menu_Ingame);
			connected = 0;

			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(!isClientLoading[i] && clientTimeout[i] < timelimit)
					{
						connected++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", connected, i);
						statusPanel.DrawText(readyPlayers);
					}
				}
			}
		}

		if (cvarDisplayPanel.IntValue > 1)
		{
			if(failed)
			{
				char DL_Menu_Fail[128];
				Format(DL_Menu_Fail, sizeof(DL_Menu_Fail), "%t", "DL_Menu_Fail");
				statusPanel.DrawText(DL_Menu_Fail);
				failed = 0;

				for(i = 1; i <= MaxClients; i++) 
				{
					if(IsClientConnected(i) && !IsFakeClient(i))
					{
						if(!isClientLoading[i] && clientTimeout[i] < timelimit)
						{
							failed++;
							Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", failed, i);
							statusPanel.DrawText(readyPlayers);
						}
					}
				}
			}
		}

		if(ready)
		{
			char DL_Menu_Ready[128];
			Format(DL_Menu_Ready, sizeof(DL_Menu_Ready), "%t", "DL_Menu_Ready");
			statusPanel.DrawText(DL_Menu_Ready);
			ready = 0;

			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i] && indexClientReady[i] == 2)
					{
						ready++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", ready, i);
						statusPanel.DrawText(readyPlayers);
					}
				}
			}
		}

		if(unready)
		{
			char DL_Menu_Unready[128];
			Format(DL_Menu_Unready, sizeof(DL_Menu_Unready), "%t", "DL_Menu_Unready");
			statusPanel.DrawText(DL_Menu_Unready);
			unready = 0;

			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i] && indexClientReady[i] == 1)
					{
						unready++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", unready, i);
						statusPanel.DrawText(readyPlayers);
					}
				}
			}
		}

		for(i = 1; i <= MaxClients; i++) 
		{
			if(IsClientConnected(i) && !IsFakeClient(i)) statusPanel.Send(i, blankhandler, 5);
		}
	}
}

int blankhandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

//======================================
//				Actions
//======================================
void LockTheDoor()
{
	DispatchKeyValue(ent_safedoor, "spawnflags", "585728");
}

void UnlockTheDoor()
{
	DispatchKeyValue(ent_safedoor, "spawnflags", "8192");
}

void UnFreezePlayers()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i)) 
		{
			if (IsValidEntity(i) && GetEntityMoveType(i) == MOVETYPE_NONE) SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
}

//======================================
//				Check
//======================================
bool isGamemode()
{
	return isGameModeBool;
}

void CheckGamemode()
{
	char gamemode[64], gamemodeactive[64];
	cvarMpGamemode.GetString(gamemode, sizeof(gamemode));
	cvarGameModeEnabled.GetString(gamemodeactive, sizeof(gamemodeactive));
	isGameModeBool = StrContains(gamemodeactive, gamemode) != -1;
}

void CheckSafeRoomDoor()
{
	ent_safedoor_check = -1;
	while ((ent_safedoor_check = FindEntityByClassname(ent_safedoor_check, SAFEDOOR_CLASS)) != -1)
	if (ent_safedoor_check > 0)
	{
		int spawn_flags;
		char model[255];
		GetEntPropString(ent_safedoor_check, Prop_Data, "m_ModelName", model, sizeof(model));
		spawn_flags = GetEntProp(ent_safedoor_check, Prop_Data, "m_spawnflags");

		if (((strcmp(model, SAFEDOOR_MODEL_01) == 0) && ((spawn_flags == 8192)
		|| (spawn_flags == 0)))
		|| ((strcmp(model, SAFEDOOR_MODEL_02) == 0) && ((spawn_flags == 8192)
		|| (spawn_flags == 0))))
			ent_safedoor = ent_safedoor_check;
	}
}

stock bool isCountDownStoppedOrRunning()
{
	return countDown != 0;
}

stock bool isCountDownStopped()
{
	return countDown == -1;
}

stock bool isCountDownRunning()
{
	return countDown > 0;
}

stock bool isInfectedTeamReady()
{
	if (cvarWaitForInfected.BoolValue)
	{
		bool spawning = false;
		spawnWaitTime--;
		if (spawnWaitTime <= 0) spawning = true;
		return spawning;
	}
	else return true;
}

stock bool isAnyClientLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (isClientLoading[i])
		{
			return true;
		}
	}
	return false;
}

stock bool isFinishedLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (!IsClientInGame(i) && !IsFakeClient(i))
			{
				clientTimeout[i]++;
				if (isClientLoading[i])
				{
					if (clientTimeout[i] == 1) isClientLoading[i] = true;
				}

				if (clientTimeout[i] == GetConVarInt(cvarClientTimeOut)) isClientLoading[i] = false;
			}
			else isClientLoading[i] = false;
		}
		else isClientLoading[i] = false;
	}

	ShowStatusPanel();

	return !isAnyClientLoading();
}

stock bool isClientValid(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}

//======================================
//				Other
//======================================
void PrintTextAll(const char[] format, any ...)
{
	char buffer[192], type[64];
	VFormat(buffer, sizeof(buffer), format, 2);
	cvarDisplayMode.GetString(type, sizeof(type));
	if (strcmp(type, "center") == 0) PrintCenterTextAll(buffer);
	else if (strcmp(type, "hint") == 0) PrintHintTextToAll(buffer);
	else if (strcmp(type, "chat") == 0) PrintToChatAll(buffer);
	else return;
}

void DL_Event_PlayerLeftSstartArea(Event event, const char[] name, bool dontBroadcast)
{
	isInvulnerable = false;
}

void DL_Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (isInvulnerable)
	{
		int health = event.GetInt("health");
		int dmg_health = event.GetInt("dmg_health");
		int victim = GetClientOfUserId(event.GetInt("userid"));
		SetEntityHealth(victim, health + dmg_health);
	}
}

Action DL_Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if (ent_safedoor > 0)
	{
		if (event.GetBool("checkpoint"))
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			if (isTheDoorBreakeble) ReplaceSafeDoor(client);
			if (cvarStartPrevent.BoolValue) isTheDoorOpened = true;
		}
	}
	return Plugin_Continue;
}

void ReplaceSafeDoor(int client)
{
	int ent_brokendoor = CreateEntityByName("prop_physics");
	char model[255];
	GetEntPropString(ent_safedoor, Prop_Data, "m_ModelName", model, sizeof(model));

	float pos[3], ang[3];
	GetEntPropVector(ent_safedoor, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(ent_safedoor, Prop_Send, "m_angRotation", ang);

	AcceptEntityInput(ent_safedoor, "Kill");

	DispatchKeyValue(ent_brokendoor, "model", model);
	DispatchKeyValue(ent_brokendoor, "spawnflags", "4");

	DispatchSpawn(ent_brokendoor);

	float EyeAngles[3];
	float Push[3];
	float ang_fix[3];

	ang_fix[0] = (ang[0] - 5.0);
	ang_fix[1] = (ang[1] + 5.0);
	ang_fix[2] = (ang[2]);

	GetClientEyeAngles(client, EyeAngles);
	Push[0] = (100.0 * Cosine(DegToRad(EyeAngles[1])));
	Push[1] = (100.0 * Sine(DegToRad(EyeAngles[1])));
	Push[2] = (15.0 * Sine(DegToRad(EyeAngles[0])));

	TeleportEntity(ent_brokendoor, pos, ang_fix, Push);
	CreateTimer(10.0, FadeBrokenDoor, ent_brokendoor);
}

Action FadeBrokenDoor(Handle timer, any ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		SetEntityRenderFx(ent_brokendoor, RENDERFX_FADE_FAST); //RENDERFX_FADE_SLOW 3.5
		CreateTimer(1.5, KillBrokenDoorEntity, ent_brokendoor);
	}
	return Plugin_Stop;
}

Action KillBrokenDoorEntity(Handle timer, any ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		AcceptEntityInput(ent_brokendoor, "Kill");
	}
	return Plugin_Stop;
}

//======================================
//				L4DT
//======================================

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (ent_safedoor > 0 && !isTheDoorOpened)
	{
		return Plugin_Handled;
	}
	else
	{
		isInvulnerable = false;
		return Plugin_Continue;
	}
}
