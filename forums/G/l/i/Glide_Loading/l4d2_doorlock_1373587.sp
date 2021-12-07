#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define PLUGIN_VERSION "2.6a"

#define SAFEDOOR_MODEL_01 "models/props_doors/checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "models/props_doors/checkpoint_door_-01.mdl"
#define SAFEDOOR_CLASS "prop_door_rotating_checkpoint"

new spawnWaitTime, countDown, clientTimeout[MAXPLAYERS + 1];
new ent_safedoor;
new ent_safedoor_check;
new indexClientReady[MAXPLAYERS + 1];
// 0=spectator, 1 = unready, 2=ready

new bool:isFirstRound;
new bool:isFreezeAllowed;
new bool:isInvulnerable;
new bool:isTheDoorBreakeble;
new bool:isTheDoorOpened;
new bool:isReadyUpMode;
new bool:isClientLoading[MAXPLAYERS + 1];
new bool:isClientSpawning[MAXPLAYERS + 1];
new bool:isGameModeBool = false;

new Handle:cvarInvulnerable = INVALID_HANDLE; 
new Handle:cvarFreezeNodoor = INVALID_HANDLE;
new Handle:cvarDisplayMode = INVALID_HANDLE;
new Handle:cvarGameModeEnabled = INVALID_HANDLE;
new Handle:cvarReadyUpMode = INVALID_HANDLE;
new Handle:cvarMpGamemode = INVALID_HANDLE;
new Handle:cvarStartPrevent = INVALID_HANDLE;

new Handle:cvarBreakTheDoor = INVALID_HANDLE;
new Handle:cvarPrepareTime1r = INVALID_HANDLE;
new Handle:cvarPrepareTime2r = INVALID_HANDLE;
new Handle:cvarWaitForInfected = INVALID_HANDLE;
new Handle:cvarClientTimeOut = INVALID_HANDLE;
new Handle:cvarDisplayPanel = INVALID_HANDLE;

new Handle:statusPanel;

public Plugin:myinfo =
{
	name = "L4D2 Door Lock",
	author = "Glide Loading",
	//Original developer: lilDrowOuw
	//L4D2 Port and bugfixing: AtomicStryker
	
	description = "Saferoom Door locked until all players loaded and infected are ready to spawn",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showpost.php?p=1373587&postcount=136"
};

public OnPluginStart()
{
	HookEvent("round_start", DL_Event_RoundStart);
	HookEvent("player_hurt", DL_Event_PlayerHurt);
	HookEvent("player_left_start_area", DL_Event_PlayerLeftSstartArea);
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
	
	CreateConVar("l4d2_dlock_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);

	cvarInvulnerable = CreateConVar("l4d2_dlock_godmode", "1", "If enabled, survivors invulnerable while they are in saferoom.");
	cvarFreezeNodoor = CreateConVar("l4d2_dlock_freezenodoor", "1", "Freeze survivors if start saferoom door is absent");
	cvarPrepareTime1r = CreateConVar("l4d2_dlock_prepare1st", "20", "How many seconds plugin will wait after all clients have loaded before starting first round on a map");
	cvarPrepareTime2r = CreateConVar("l4d2_dlock_prepare2nd", "15", "How many seconds plugin will wait after all clients have loaded before starting second round on a map");
	cvarWaitForInfected = CreateConVar("l4d2_dlock_infectedspawn", "1", "Wait for infected to be ready to spawn before starting countdown");
	cvarClientTimeOut = CreateConVar("l4d2_dlock_timeout", "90", "How many seconds plugin will wait after a map starts before giving up on waiting for a client");
	cvarBreakTheDoor = CreateConVar("l4d2_dlock_weakdoor", "1", "Saferoom door will be breaked, once opened.");
	cvarStartPrevent = CreateConVar("l4d2_dlock_startprevent", "1", "If enabled, versus round will not start until safe-room door become opened.");
	cvarDisplayPanel = CreateConVar("l4d2_dlock_displaypanel", "2", "Display players state panel. 0-disabled, 1-hide failed, 2-full info");
	cvarDisplayMode = CreateConVar("l4d2_dlock_displaymode", "hint", "Set the display mode for the countdown. (hint, center, chat. any other value to hide countdown)");
	cvarReadyUpMode = CreateConVar("l4d2_dlock_readyupmode", "0", "NOT IMPLEMENTED. DO NOT ENABLE !!! 0 - timer, 1 - ready-up mode");
	cvarGameModeEnabled = CreateConVar("l4d2_dlock_gamemodeactive", "versus,teamversus,mutation13", "Set the game mode for which the plugin should be activated");

	cvarMpGamemode = FindConVar("mp_gamemode");
	
	LoadTranslations("doorlock.phrases");

	AutoExecConfig(true, "l4d2_doorlock");

	CheckGamemode()
}

public OnMapStart()
{
	isFirstRound = true;
}

public DL_Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isTheDoorBreakeble = false;
	isFreezeAllowed = false;
	isInvulnerable = false;
	isReadyUpMode = false;
	isTheDoorOpened = false;
	
	ent_safedoor = -1;
		
	CheckGamemode()
	CreateTimer(0.2, PluginStartSequence01)
}

public Action:PluginStartSequence01(Handle:timer)
{
	if (isGamemode())
	{
		if(GetConVarBool(cvarReadyUpMode))
		{
			isReadyUpMode = true;
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			isClientLoading[i] = true;
			clientTimeout[i] = 0;
			
			if (isReadyUpMode)
			{
				indexClientReady[i] = 0;
			}
		}

		CheckSafeRoomDoor()
		SurvivorsBotStop()
		CreateTimer(0.2, PluginStartSequence02)
	}
	else
	{
		SurvivorsBotStart()
	}
}

public Action:PluginStartSequence02(Handle:timer)
{
	countDown = -1;
	spawnWaitTime = 10;
	
	if(GetConVarBool(cvarBreakTheDoor) && (ent_safedoor > 0))
	{
		isTheDoorBreakeble = true;
	}
	
	if(GetConVarBool(cvarInvulnerable))
	{
		isInvulnerable = true;
	}

	if (ent_safedoor > 0)
	{
		LockTheDoor()
		CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else if (GetConVarBool(cvarFreezeNodoor))
	{
		isFreezeAllowed = true;
		CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else
	{
		SurvivorsBotStart()
		countDown = 0;
	}
}

public Action:DL_ClientReady(client, args)
{
	if (isReadyUpMode && (indexClientReady[client] = 1))
	{
		indexClientReady[client] = 2;
	
		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		PrintToChatAll("%t", "DL_Ready", name);
		
		ShowStatusPanel()
	}
}

public Action:DL_ClientUnready(client, args)
{
	if (isReadyUpMode && (indexClientReady[client] = 2))
	{
		indexClientReady[client] = 1;
	
		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
	
		PrintToChatAll("%t", "DL_Unready", name);
		
		ShowStatusPanel()
	}
}


/*public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && isCountDownStoppedOrRunning())
	{
		isClientLoading[client] = false;
		clientTimeout[client] = 0;
	}
}*/

public OnClientDisconnect(client)
{
	isClientLoading[client] = false;
	clientTimeout[client] = 0;
}

public DL_Event_Join_Team(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_team = GetEventInt(event, "team");
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

public DL_Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isGamemode())
	{
		if (isFirstRound)
		{
			isFirstRound = false;
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (isFreezeAllowed && (isCountDownStopped() || isCountDownStoppedOrRunning()))
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if (IsValidEntity(client))
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
		}
	}
}

public Action:DL_Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if (!isFreezeAllowed || (isFreezeAllowed && !isCountDownStoppedOrRunning()))
	{
		if (IsValidEntity(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:DL_Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	if (isCountDownStoppedOrRunning() || isCountDownStopped())
	{
		if (IsValidEntity(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		if (IsValidEntity(bot))
		{	
			SetEntityMoveType(bot, MOVETYPE_NONE);
		}
	}
}

public DL_Event_GhostSpawnTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarWaitForInfected))
	{
		new userid = GetEventInt(event, "userid");
		new time = GetEventInt(event, "spawntime");
		new client = GetClientOfUserId(userid);

		if (isCountDownStoppedOrRunning())
		{
			if (time > spawnWaitTime) spawnWaitTime = time;
			isClientSpawning[client] = (time > 0);
		}
	}
}

public DL_Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (!client) return;

	if (IsClientConnected(client))
	{
		if (isCountDownStoppedOrRunning() && isFreezeAllowed && GetClientTeam(client) == 2)
		{
			if (IsValidEntity(client))
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
		}
	}
}

public DL_Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarBool(cvarWaitForInfected))
	{
		if (isCountDownStoppedOrRunning() && GetClientTeam(client) == 3 && !IsFakeClient(client))
		{
			isClientSpawning[client] = false;
		}
	}
}

public Action:StartTimer(Handle:timer)
{
	if (isReadyUpMode)
	{
		PrintTextAll("Ready-up mode is not implemented. Disable it and restart round.");
	}
	else
	{
		if (countDown == -1)
		{
			SurvivorsBotStop()
			return Plugin_Stop;
		}
		else if (countDown++ >= GetConVarInt(isFirstRound ? cvarPrepareTime1r : cvarPrepareTime2r) - 1)
		{
			countDown = 0;
			PrintTextAll("%t", "DL_Moveout");
			SurvivorsBotStart()
			UnFreezePlayers()
		
			if (ent_safedoor > 0)
			{
				UnlockTheDoor()
			}

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

public Action:LoadingTimer(Handle:timer)
{
	if (isFinishedLoading())
	{
		if (!isFreezeAllowed)
		{
			UnFreezePlayers()
		}
		
		if (GetConVarBool(cvarWaitForInfected))
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
					SurvivorsBotStart()
					CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				}
			}
			return Plugin_Stop;
		}
	}
	else
	{
		countDown = -1;
	}

	return Plugin_Continue;
}

public Action:SpawningTimer(Handle:timer)
{
	if (isInfectedTeamReady())
	{
		if (!isCountDownRunning())
		{
			countDown = 0;
			CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			
			if (!isFreezeAllowed)
			{
				SurvivorsBotStart()
			}
		}

		return Plugin_Stop;
	}
	else
	{
		countDown = -1;
	}

	return Plugin_Continue;
}

SurvivorsBotStart()
{
	SetConVarInt(FindConVar("sb_stop"), 0);
}

SurvivorsBotStop()
{
	SetConVarInt(FindConVar("sb_stop"), 1);
}

ShowStatusPanel()
{
	if(((GetConVarInt(cvarDisplayPanel) > 0) && isFirstRound) || isReadyUpMode)
	{
		if (statusPanel != INVALID_HANDLE)
		{
			CloseHandle(statusPanel);
		}

		statusPanel = CreatePanel();
		
		decl String:readyPlayers[1024];
		
		new timelimit = GetConVarInt(cvarClientTimeOut);
		
		new connected;
		new loading;
		new failed;
		new ready;
		new unready;

		decl i;
		for (i = 1; i <= MaxClients; i++) 
		{
			if(IsClientConnected(i) && !IsFakeClient(i)) 
			{
				if (!isReadyUpMode)
				{
					if(isClientLoading[i]) 
						loading++;
					else if (clientTimeout[i] >= timelimit)
						failed++;
					else
						connected++;
				}
				else
				{
					if(isClientLoading[i]) 
						loading++;
					else if (clientTimeout[i] >= timelimit)
						failed++;
					else if (indexClientReady[i] == 2)
						ready++;
					else
						unready++;
				}
			}
		}
		
		decl String:DL_Menu_Header[128];
		Format(DL_Menu_Header, sizeof(DL_Menu_Header), "%t", "DL_Menu_Header");
		DrawPanelText(statusPanel, DL_Menu_Header);
		
		if(loading)
		{
			decl String:DL_Menu_Connecting[128];
			Format(DL_Menu_Connecting, sizeof(DL_Menu_Connecting), "%t", "DL_Menu_Connecting");
			DrawPanelText(statusPanel, DL_Menu_Connecting);
			loading = 0;
			
			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i])
					{
						loading++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", loading, i);
						DrawPanelText(statusPanel, readyPlayers);
					}
				}
			}
		}
		
		if(connected)
		{
			decl String:DL_Menu_Ingame[128];
			Format(DL_Menu_Ingame, sizeof(DL_Menu_Ingame), "%t", "DL_Menu_Ingame");
			DrawPanelText(statusPanel, DL_Menu_Ingame);
			connected = 0;
			
			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(!isClientLoading[i] && clientTimeout[i] < timelimit)
					{
						connected++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", connected, i);
						DrawPanelText(statusPanel, readyPlayers);
					}
				}
			}
		}
		
		if (GetConVarInt(cvarDisplayPanel) > 1)
		{
			if(failed)
			{
				decl String:DL_Menu_Fail[128];
				Format(DL_Menu_Fail, sizeof(DL_Menu_Fail), "%t", "DL_Menu_Fail");
				DrawPanelText(statusPanel, DL_Menu_Fail);
				failed = 0;
			
				for(i = 1; i <= MaxClients; i++) 
				{
					if(IsClientConnected(i) && !IsFakeClient(i))
					{
						if(!isClientLoading[i] && clientTimeout[i] < timelimit)
						{
							failed++;
							Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", failed, i);
							DrawPanelText(statusPanel, readyPlayers);
						}
					}
				}
			}
		}
		
		if(ready)
		{
			decl String:DL_Menu_Ready[128];
			Format(DL_Menu_Ready, sizeof(DL_Menu_Ready), "%t", "DL_Menu_Ready");
			DrawPanelText(statusPanel, DL_Menu_Ready);
			ready = 0;
			
			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i] && indexClientReady[i] == 2)
					{
						ready++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", ready, i);
						DrawPanelText(statusPanel, readyPlayers);
					}
				}
			}
		}
		
		if(unready)
		{
			decl String:DL_Menu_Unready[128];
			Format(DL_Menu_Unready, sizeof(DL_Menu_Unready), "%t", "DL_Menu_Unready");
			DrawPanelText(statusPanel, DL_Menu_Unready);
			unready = 0;
			
			for(i = 1; i <= MaxClients; i++) 
			{
				if(IsClientConnected(i) && !IsFakeClient(i))
				{
					if(isClientLoading[i] && indexClientReady[i] == 1)
					{
						unready++;
						Format(readyPlayers, sizeof(readyPlayers), "->%d. %N", unready, i);
						DrawPanelText(statusPanel, readyPlayers);
					}
				}
			}
		}
	
		for(i = 1; i <= MaxClients; i++) 
		{
			if(IsClientConnected(i) && !IsFakeClient(i))
			{
				SendPanelToClient(statusPanel, i, blankhandler, 5);
			}
		}
	}
}

public blankhandler(Handle:menu, MenuAction:action, param1, param2)
{
}

//======================================
//				Actions
//======================================
LockTheDoor()
{
	DispatchKeyValue(ent_safedoor, "spawnflags", "585728");
}

UnlockTheDoor()
{
	DispatchKeyValue(ent_safedoor, "spawnflags", "8192");
}

UnFreezePlayers()
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i)) 
		{
			if (IsValidEntity(i) && GetEntityMoveType(i) == MOVETYPE_NONE) 
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
	}
}

//======================================
//				Check
//======================================
bool:isGamemode()
{
	return isGameModeBool;
}

CheckGamemode()
{
	decl String:gamemode[64], String:gamemodeactive[64];
	GetConVarString(cvarMpGamemode, gamemode, sizeof(gamemode));
	GetConVarString(cvarGameModeEnabled, gamemodeactive, sizeof(gamemodeactive));
	
	isGameModeBool = StrContains(gamemodeactive, gamemode) != -1;
}

CheckSafeRoomDoor()
{
	ent_safedoor_check = -1;
	while ((ent_safedoor_check = FindEntityByClassname(ent_safedoor_check, SAFEDOOR_CLASS)) != -1)
	if (ent_safedoor_check > 0)
	{
		new spawn_flags;
		decl String:model[255];
		GetEntPropString(ent_safedoor_check, Prop_Data, "m_ModelName", model, sizeof(model));
		spawn_flags = GetEntProp(ent_safedoor_check, Prop_Data, "m_spawnflags");

		if (((strcmp(model, SAFEDOOR_MODEL_01) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))) || ((strcmp(model, SAFEDOOR_MODEL_02) == 0) && ((spawn_flags == 8192) || (spawn_flags == 0))))
		{
			ent_safedoor = ent_safedoor_check;
		}
	}
}

bool:isCountDownStoppedOrRunning()
{
	return countDown != 0;
}

bool:isCountDownStopped()
{
	return countDown == -1;
}

bool:isCountDownRunning()
{
	return countDown > 0;
}

bool:isInfectedTeamReady()
{
	if (GetConVarBool(cvarWaitForInfected))
	{
		new bool:spawning = false;
		spawnWaitTime--;
		if (spawnWaitTime <= 0) spawning = true;
		return spawning;
	}
	else return true;
}

bool:isAnyClientLoading()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (isClientLoading[i]) return true;
	}

	return false;
}

bool:isFinishedLoading()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (!IsClientInGame(i) && !IsFakeClient(i))
			{
				clientTimeout[i]++;
				if (isClientLoading[i])
				{
					if (clientTimeout[i] == 1)
					{
						isClientLoading[i] = true;
					}
				}
				
				if (clientTimeout[i] == GetConVarInt(cvarClientTimeOut))
				{
					isClientLoading[i] = false;
				}
			}
			else
			{
				isClientLoading[i] = false;
			}
		}
		
		else isClientLoading[i] = false;
	}
	
	ShowStatusPanel()
	
	return !isAnyClientLoading();
}

bool:isClientValid(client)
{ 	if (client <= 0) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}

//======================================
//				Other
//======================================

PrintTextAll(const String:format[], any:...)
{
	decl String:buffer[192], String:type[64];
	VFormat(buffer, sizeof(buffer), format, 2);
	GetConVarString(cvarDisplayMode, type, sizeof(type));

	if (strcmp(type, "center") == 0)
	{
		PrintCenterTextAll(buffer);
	}
	else if (strcmp(type, "hint") == 0)
	{
		PrintHintTextToAll(buffer);
	}
	else if (strcmp(type, "chat") == 0)
	{
		PrintToChatAll(buffer);
	}
	else
	{
		return;
	}
}

public DL_Event_PlayerLeftSstartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	isInvulnerable = false;
}

public DL_Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isInvulnerable)
	{
		new userid0 = GetEventInt(event, "userid");
		new health = GetEventInt(event, "health");
		new dmg_health = GetEventInt(event, "dmg_health");
		new victim = GetClientOfUserId(userid0);
		SetEntityHealth(victim, health + dmg_health);
	}
}

public Action: DL_Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (ent_safedoor > 0)
	{
		if (GetEventBool(event, "checkpoint"))
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			if (isTheDoorBreakeble)
			{
				ReplaceSafeDoor(client)
			}
			if (GetConVarBool(cvarStartPrevent))
			{
				isTheDoorOpened = true;
			}
		}
		
	}
}

ReplaceSafeDoor(client)
{
	new ent_brokendoor = CreateEntityByName("prop_physics");
	decl String:model[255];
	GetEntPropString(ent_safedoor, Prop_Data, "m_ModelName", model, sizeof(model));
	
	decl Float:pos[3], Float:ang[3];
	GetEntPropVector(ent_safedoor, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(ent_safedoor, Prop_Send, "m_angRotation", ang);

	AcceptEntityInput(ent_safedoor, "Kill");

	DispatchKeyValue(ent_brokendoor, "model", model);
	DispatchKeyValue(ent_brokendoor, "spawnflags", "4");

	DispatchSpawn(ent_brokendoor);
	
	decl Float:EyeAngles[3];
	decl Float:Push[3];
	decl Float:ang_fix[3];
			
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

public Action:FadeBrokenDoor(Handle:timer, any:ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		SetEntityRenderFx(ent_brokendoor, RENDERFX_FADE_FAST); //RENDERFX_FADE_SLOW 3.5
		CreateTimer(1.5, KillBrokenDoorEntity, ent_brokendoor);
	}
}

public Action:KillBrokenDoorEntity(Handle:timer, any:ent_brokendoor)
{
	if (IsValidEntity(ent_brokendoor))
	{
		AcceptEntityInput(ent_brokendoor, "Kill");
	}
}

//======================================
//				L4DT
//======================================

public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
	if ((ent_safedoor > 0) && !isTheDoorOpened)
	{
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}