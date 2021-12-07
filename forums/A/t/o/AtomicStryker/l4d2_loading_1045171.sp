#include <sourcemod>

#undef REQUIRE_PLUGIN

#include <sdktools>
#include <adminmenu>

#define DEBUG_LOG 0
#define DEBUG_CHAT 0

#define PLUGIN_VERSION "1.0.1"
#define DEBUG_SCRIM 0
#define DEBUG_DOOR 0
#define DEBUG_CHMAP 0
#define DEBUG_PLAYERS 0
#define DEBUG_DIRECTOR 0
#define DEBUG_TYPE dbgtype:DEBUG_LOG
#define TAG "L4D2L"
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

public Plugin:myinfo =
{
	name = "L4D2 Loading Bug Removal",
	author = "lilDrowOuw & AtomicStryker",
	description = "Players cannot start the game as long players are still loading; when all players are ingame the safe room door is locked for a short time to let the infected team find a proper spot.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:menuScrim = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuSpawn = INVALID_TOPMENUOBJECT;

new Handle:freezeOn1st = INVALID_HANDLE;
new Handle:prepareTime1st = INVALID_HANDLE;
new Handle:prepareTime2nd = INVALID_HANDLE;
new Handle:prepareTimeScrim = INVALID_HANDLE;
new Handle:waitOnTimeOut = INVALID_HANDLE;
new Handle:playerAfk = INVALID_HANDLE;
new Handle:scrimMode = INVALID_HANDLE;
new Handle:scrimMasters = INVALID_HANDLE;
new Handle:scrimType = INVALID_HANDLE;
new Handle:awaitSpawn = INVALID_HANDLE;
new Handle:gameMode = INVALID_HANDLE;
new Handle:displayMode = INVALID_HANDLE;
new Handle:foundCampaigns = INVALID_HANDLE;
new Handle:g_l4dVoteMenu = INVALID_HANDLE;

new countDown;
new checkPointDoorEntityStart;
new String:checkPointDoorEntityStartAngles[255];
new checkPointDoorEntityIds[4];
new bool:isClientLoading[MAXPLAYERS + 1];
new bool:isClientSpawning[MAXPLAYERS + 1];
new clientTimeout[MAXPLAYERS + 1];
new scrimReady[MAXPLAYERS +1];
new bool:foundAnOrigin = false;
new bool:isFirstMap;
new bool:isFirstPlayer;
new bool:isFirstRound;
new spawnWaitTime;
new rdyCount[4];

new String:g_l4dVoteType[32];
new String:g_scrimVoteType[32];
new String:forceNext[128];
new foo;
new clientButtons[MAXPLAYERS + 1];
new Float:clientMouse[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	RegAdminCmd("sm_scrim", Command_ScrimMode, ADMFLAG_KICK, "Toggle scrim mode.");
	RegAdminCmd("sm_await_spawn", Command_AwaitSpawn, ADMFLAG_KICK, "Toggle await spawn.");
	RegAdminCmd("sm_cdstart", Command_Start, ADMFLAG_KICK, "Start countdown.");
	RegAdminCmd("sm_cdstop", Command_Stop, ADMFLAG_KICK, "Stop countdown.");
	RegAdminCmd("sm_force", Command_Force, ADMFLAG_KICK, "Force round start (cancel countdown/ waiting).");
	RegAdminCmd("setnext", Command_NextCampgain, ADMFLAG_KICK, "Set the next campaign.");

	// See if the menu plugin is already ready
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}

	#if DEBUG_DOOR
	RegConsoleCmd("dump_cpd", Command_DumpCPD);
	RegConsoleCmd("dump_players", Command_DumpPlayers);
	#endif

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("callvote", Command_Callvote);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("player_entered_start_area", Event_PlayerEnteredStartArea);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("revive_success", Event_ReviveEnd);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("ghost_spawn_time", Event_GhostSpawnTime);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("witch_spawn", Event_WitchSpawn);

	CreateConVar("l4d2_loadingVersion", PLUGIN_VERSION, "Version of the loading plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED);
	freezeOn1st = CreateConVar("l4d2_freezeOn1st", "0", "Freeze survivors on first chapter (0 = no, 1 = freeze survivors until all players have loaded; 2 = use countdown like on the other chapters)");
	prepareTime1st = CreateConVar("l4d2_prepare1st", "30", "Wait this many seconds after all clients have loaded before starting first round on a map");
	prepareTime2nd = CreateConVar("l4d2_prepare2nd", "30", "Wait this many seconds after all clients have loaded before starting second round on a map");
	prepareTimeScrim = CreateConVar("l4d2_prepareScrim", "5", "Wait this many seconds after all clients are ready until going live (first chapter)");
	playerAfk = CreateConVar("l4d2_afkTime", "25", "Wait this many seconds while countdown is stopped or running before moving a client to spectators");
	waitOnTimeOut = CreateConVar("l4d2_timeout", "70", "Wait this many seconds after a map starts before giving up on waiting for a client (timeout)");
	scrimMode = CreateConVar("l4d2_scrim", "0", "Activate scrim mode; players have to type !ready or !rdy in chat to unlock the door, use !urdy or !unready to reset ready state (new ready-up on next round)");
	scrimMasters = CreateConVar("l4d2_scrimMasters", "1", "How many players have to set ready state on each team to start a round in scrim mode");
	scrimType = CreateConVar("l4d2_scrimType", "round", "Set the type of scrim match (match = players ready-up on start of match, then each round is started by the default timer; map = players ready-up on each map, second round is started by a timer; round = players ready-up on each round)");
	awaitSpawn = CreateConVar("l4d2_infectedSpawn", "1", "Wait for infected to be ready to spawn before starting countdown");
	gameMode = CreateConVar("l4d2_gameModeActive", "coop,versus,teamversus", "Set the game mode for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma)");
	displayMode = CreateConVar("l4d2_displayMode", "center", "Set the display mode how the countdown will be displayed (hint = countdown is displayed in hint messages; center = countdown is displayed in the screen center; chat = countdown is displayed in the chat)");

	AutoExecConfig(true, "l4d2_loading");
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client) && IsCountDownStoppedOrRunning())
	{
		isClientLoading[client] = false;
		clientTimeout[client] = 0;
		scrimReady[client] = 0;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (i != client && IsClientConnected(i))
			{
				if (isClientLoading[i])
				{
					PrintToChat(client, "Waiting for player %N to join the game", i);
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	isClientLoading[client] = false;
	clientTimeout[client] = 0;
	scrimReady[client] = 0;
}

public OnMapStart()
{
	isFirstPlayer = true;
	isFirstRound = true;

	for (new i = 1; i <= MaxClients; i++)
	{
		ResetReadyState(i, "map");
	}
}

/*
 * Events
 */

new bool:isIncapacitated[MAXPLAYERS + 1];
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:gamemode[64], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(gameMode, gamemodeactive, sizeof(gamemodeactive));

	#if DEBUG_DOOR
	PrintDebugMessage("[DEBUG] Gamemode [ current = %s | desired = %s | contained = %i ]", gamemode, gamemodeactive, StrContains(gamemodeactive, gamemode));
	#endif

	if (StrContains(gamemodeactive, gamemode) != -1)
	{
		#if DEBUG_SCRIM
		PrintDebugMessage("[DEBUG] Starting new round");
		#endif
		decl String:map[255];

		GetCurrentMap(map, sizeof(map));

		countDown = -1;
		spawnWaitTime = 10;

		UpdateReadyCount();

		for (new i = 1; i <= MaxClients; i++)
		{
			isIncapacitated[i] = false;
			isClientLoading[i] = true;
			clientTimeout[i] = 0;
			clientButtons[i] = 0;
			clientMouse[i] = Float:{0,0,0};
			ResetReadyState(i, "round");
		}

		if (StrContains(map, "m1") == -1)
		{
			DirectorStop();
			isFirstMap = false;
			GetCheckPointDoorIds();
			CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else
		{
			isFirstMap = true;
			forceNext = "\0";

			DirectorStart();

			for (new i = 1; i <= MaxClients; i++)
			{
				ResetReadyState(i, "match");
			}

			if (!GetConVarBool(scrimMode) && GetConVarInt(freezeOn1st) == 0)
				countDown = 0;
			else
			{
				DirectorStop();
				CreateTimer(1.0, LoadingTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
		}

		foundAnOrigin = false;
		checkPointDoorEntityStart = 0;

		if (!isFirstRound && !isFirstMap)
		{
			CreateTimer(0.3, DelayedDoorSpawn);
			if (GetConVarInt(playerAfk) != 0) CreateTimer(0.1, AfkTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else if (GetConVarInt(freezeOn1st) > 0 && isFirstMap)
		{
			if (GetConVarInt(playerAfk) != 0) CreateTimer(0.1, AfkTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
	
	else countDown = 0;
}

public Action:DelayedDoorSpawn(Handle:timer)
{
	GetCheckPointDoorStart();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:map[128], String:gamemode[64];

	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));

	GetCurrentMap(map, sizeof(map));

	if (isFirstRound)
		isFirstRound = false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	isIncapacitated[client] = false;

	#if DEBUG_PLAYERS
	PrintDebugMessage("[DEBUG] Player %L is dead now", client);
	#endif
}

public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	isIncapacitated[client] = true;

	#if DEBUG_PLAYERS
	PrintDebugMessage("[DEBUG] Player %L is %s now", client, isIncapacitated[client] ? "down" : "on his feet");
	#endif
}

public Event_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	isIncapacitated[client] = true;

	#if DEBUG_PLAYERS
	PrintDebugMessage("[DEBUG] Player %L is %s now", client, isIncapacitated[client] ? "down" : "on his feet");
	#endif
}

public Event_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "subject");
	new client = GetClientOfUserId(userid);
	isIncapacitated[client] = false;

	#if DEBUG_PLAYERS
	PrintDebugMessage("[DEBUG] Player %L is %s now", client, isIncapacitated[client] ? "down" : "on his feet");
	#endif
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG_DOOR
	new ent = GetEventInt(event, "targetid");
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	PrintDebugMessage("Client %N used entity %i", client, ent);
	if (IsCountDownStoppedOrRunning()) PrintDebugMessage("Countdown running");
	if (IsCheckPointDoor(ent)) PrintDebugMessage("Found check point door: %i", ent);
	#endif
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsCountDownStoppedOrRunning())
	{
		new userid0 = GetEventInt(event, "userid");
		new userid1 = GetEventInt(event, "attacker");
		new health = GetEventInt(event, "health");
		new dmg_health = GetEventInt(event, "dmg_health");
		new victim = GetClientOfUserId(userid0);
		new attacker = GetClientOfUserId(userid1);

		#if DEBUG_SCRIM
		PrintDebugMessage("[DEBUG] Player %L hurt %L [health = %d | dmg_health = %d]", attacker, victim, health, dmg_health);
		#endif

		if ((attacker != 0 && victim != 0) && !GetConVarBool(scrimMode) && GetClientTeam(attacker) == GetClientTeam(victim))
		{
			PrintToChatAll("[%s] Player %N hurt %N [TA warning]", TAG, attacker, victim);
		}

		SetEntityHealth(victim, health + dmg_health);
	}
}

public Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG_DOOR
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	PrintDebugMessage("Player %L left start area [ countdown = %i | angles = %s | door = %i ]", client, countDown, checkPointDoorEntityStartAngles, checkPointDoorEntityStart);
	
	if (GetConVarBool(scrimMode) && IsCountDownStoppedOrRunning()) PrintDebugMessage( "Event_PlayerLeftStartArea(): failure on preventing to leave start area before countdown end");
	#endif
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if (GetConVarBool(scrimMode) && IsCountDownStoppedOrRunning()) {
		scrimReady[client] = 0;

		countDown = -1;

		#if DEBUG_SCRIM
		PrintDebugMessage("Player %L changed team during ready-up/ while countdown running - ready state reset, countdown stopped", client);
		#endif

		if (GetEventInt(event, "team") == 2) {
			#if DEBUG_SCRIM
			PrintDebugMessage("[DEBUG] Player %L saved on datapack for FreezingTimer()", client);
			#endif
			new Handle:dp = CreateDataPack();
			CreateDataTimer(1.0, FreezingTimer, dp, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(dp, client);
		}
	}

	clientButtons[client] = 0;
}

public Action:Event_PlayerEnteredStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	#if DEBUG_DOOR
	PrintDebugMessage("[DEBUG] Event_PlayerEnteredStartArea(): %L", client);
	#endif

	if (isFirstMap && GetConVarInt(freezeOn1st) > 0 && !GetConVarBool(scrimMode) && IsValidEntity(client))
	{
		new Handle:dp = CreateDataPack();
		CreateDataTimer(0.1, FreezingTimer, dp, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(dp, client);

		#if DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Event_PlayerEnteredStartArea(): Player %N saved on freezing timer", client);
		#endif
	}
}

/*
 * A player replaced a bot
 */
public Action:Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(GetConVarBool(scrimMode))
	{
		if(IsCountDownStoppedOrRunning())
		{
			#if DEBUG_SCRIM
			PrintDebugMessage("[DEBUG] Event_BotPlayerReplace(): Freezing %L", client);
			#endif
		
			if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
	else if (!isFirstMap || (isFirstMap && ((GetConVarInt(freezeOn1st) == 1 && !IsCountDownStopped()) || (GetConVarInt(freezeOn1st) == 2 && !IsCountDownStoppedOrRunning()))))
	{
		#if DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Event_BotPlayerReplace(): Unfreezing %L", client);
		#endif
		
		if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_WALK);
	}
	#if DEBUG_DOOR
	else PrintDebugMessage("[DEBUG] Event_BotPlayerReplace(): Doing nothing [ 1stmap = %i | countdown = %i | freezeOn1st = %i | scrim = %i ]", isFirstMap, countDown, GetConVarInt(freezeOn1st), GetConVarBool(scrimMode));
	#endif
}

/*
 * A bot replaced a player
 */
public Action:Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	if((GetConVarBool(scrimMode) && IsCountDownStoppedOrRunning()) || (!GetConVarBool(scrimMode) && IsCountDownStopped()))
	{
		#if DEBUG_SCRIM || DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Event_PlayerBotReplace(): Unfreezing %L", client);
		#endif

		if (IsValidEntity(client)) SetEntityMoveType(client, MOVETYPE_WALK);
		#if DEBUG_SCRIM || DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Event_PlayerBotReplace(): Freezing %L", bot);
		#endif

		if (IsValidEntity(bot)) SetEntityMoveType(bot, MOVETYPE_NONE);
	}
}

public Event_GhostSpawnTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(awaitSpawn))
	{
		new userid = GetEventInt(event, "userid");
		new time = GetEventInt(event, "spawntime");
		new client = GetClientOfUserId(userid);

		if (IsCountDownStoppedOrRunning())
		{
			if (time > spawnWaitTime) spawnWaitTime = time;
			isClientSpawning[client] = (time > 0);
			PrintToChatAll("Waiting for player %N to be ready to spawn", client);

			#if DEBUG_SCRIM
			PrintDebugMessage("%L :  %i (%i)", client, time, isClientSpawning[client]);
			#endif
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if (IsClientConnected(client))
	{
		if (IsCountDownStoppedOrRunning() && isFirstMap && GetClientTeam(client) == 3)
		{
			#if DEBUG_SCRIM
			PrintDebugMessage("[DEBUG] Player %L spawned during ready-up/ while countdown running", client);
			#endif

			if (IsClientConnected(client))
			{
				if (IsValidEntity(client))
				{
					SetEntityMoveType(client, MOVETYPE_NONE);
				#if DEBUG_SCRIM
				}
				else
				{
					PrintDebugMessage("[DEBUG] Event_PlayerSpawn(): Player %L returned invalid entity", client);

					if (IsValidEntity(client) && GetEntityMoveType(client) == MOVETYPE_NONE)
					{
						PrintToChatAll("[DEBUG] Froze player %L", client);
					}
				#endif
				}
			}
		}
	}
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarBool(awaitSpawn))
	{
		if (IsCountDownStoppedOrRunning() && GetClientTeam(client) == 3)
		{
			isClientSpawning[client] = false;
			PrintToChatAll("Player %N ready to spawn", client);
		}
	}
}

public Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!isFirstMap && IsCountDownStoppedOrRunning() && isFirstPlayer) {
		#if DEBUG_DOOR
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		PrintDebugMessage("[DEBUG] First player (%L) joined the game -> GetCheckPointDoorStart()", client);
		#endif
		if (checkPointDoorEntityStart == 0)
			GetCheckPointDoorStart();
	}

	isFirstPlayer = false;
}

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(scrimMode) && IsCountDownStoppedOrRunning())
	{
		#if DEBUG_SCRIM
		new tankid = GetEventInt(event, "tankid");
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
		PrintDebugMessage("[DEBUG] Early tank spawn detected [ player = %L | tankid = %i ]", client, tankid);
		#endif
	}
}

public Action:Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(scrimMode) && IsCountDownStoppedOrRunning())
	{
		#if DEBUG_SCRIM
		new witchid = GetEventInt(event, "witchid");
		new client = GetClientOfUserId(witchid);
	
		new Float:origin[3];
		GetEntPropVector(witchid, Prop_Send, "m_vecOrigin", origin);

		PrintDebugMessage("[DEBUG] Early witch spawn detected [ client = %L | origin = %f-%f-%f ]", client, witchid, origin[0], origin[1], origin[2]);
		#endif
	}
}

/*
 * Commands
 */

public Action:Command_Callvote(client, args)
{
	decl String:sType[32], String:votetype[32];

	if(GetConVarBool(scrimMode) && args == 1)
	{
		ReplyToCommand(client, "[%s] Scrim mode is activated - voting has been disabled", TAG);
		return Plugin_Handled;
	}

	GetCmdArg(1, votetype, 32);
	strcopy(g_l4dVoteType, sizeof(g_l4dVoteType), votetype);

	if (strcmp(votetype, "scrim", false) == 0)
	{
		if (args > 1)
		{
			GetCmdArg(2, sType, 32);

			if (strcmp(sType, "off") != 0 && strcmp(sType, "match") != 0 && strcmp(sType, "map") != 0 && strcmp(sType, "round") != 0 && strcmp(sType, "help") != 0)
			{
				ReplyToCommand(client, "[%s] Usage: callvote scrim <match|map|round|off|help>", TAG);

				return Plugin_Handled;
			}
			else if (strcmp(sType, "help") == 0)
			{
				ReplyToCommand(client, "[%s] Sending detailed command info to your console", TAG);

				PrintToConsole(client, "---Scrim vote commands---");
				PrintToConsole(client, "callvote Scrim none:    initiates a vote with the current setting of scrim type; only available if scrim mode is deactivated");
				PrintToConsole(client, "callvote Scrim off:     initiates a vote to disable scrim mode");
				PrintToConsole(client, "callvote Scrim match:   initiates a scrim type change vote; players ready-up on start of match, then each round is started by the default timer");
				PrintToConsole(client, "callvote Scrim map:     initiates a scrim type change vote; players ready-up on each map, second round is started by the default timer");
				PrintToConsole(client, "callvote Scrim round:   initiates a scrim type change vote; players ready-up on each round");
				PrintToConsole(client, "callvote Scrim help:    displays this command info");
				PrintToConsole(client, "---End scrim vote commands---");

				return Plugin_Handled;
			}
		}
		else
		{
			GetConVarString(scrimType, sType, sizeof(sType));
		}

		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[%s] There is a vote in progress currently", TAG);
			return Plugin_Handled;
		}

		DisplayScrimVote(sType);

		PrintToChatAll("[%s] %N initiated a scrim mode vote", TAG, client);
	}
	else if (strcmp(votetype, "campaign", false) == 0)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[%s] There is a vote in progress currently", TAG);
			return Plugin_Handled;
		}

		forceNext = "\0";
	}

	#if DEBUG_SCRIM
	PrintDebugMessage("[DEBUG] Player %L initiated a vote [ vote = %s | type = %s | scrim = %i ]", client, votetype, sType, GetConVarBool(scrimMode));
	#endif
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = 0
	if (text[0] == '"') {
		startidx = 1
		new len = strlen(text);
		if (text[len-1] == '"') {
			text[len-1] = '\0'
		}
	}
 
	if (StrEqual(text[startidx], "!rdy")) {
		SetReadyState(client, 1);

		return Plugin_Handled;
	} else if (StrEqual(text[startidx], "!ready")) {
		SetReadyState(client, 1);

		return Plugin_Handled;
	} else if (StrEqual(text[startidx], "!urdy")) {
		SetReadyState(client, 0);

		return Plugin_Handled;
	} else if (StrEqual(text[startidx], "!unready")) {
		SetReadyState(client, 0);

		return Plugin_Handled;
	} else if (StrEqual(text[startidx], "!scrim")) {
		if (IsAdmin(client)) {
			SetConVarBool(scrimMode, !GetConVarBool(scrimMode));
			PrintToChat(client, "Scrim mode %s", GetConVarBool(scrimMode) ? "activated" : "deactivated");
		} else {
			PrintToChat(client, "You don't have access to this command");
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:Command_ScrimMode(client, args)
{
	ToggleScrimMode(client);

	return Plugin_Handled;
}

public Action:Command_AwaitSpawn(client, args)
{
	ToggleAwaitSpawn(client);

	return Plugin_Handled;
}

public Action:Command_NextCampgain(client, args)
{
	decl String:forceNextArg[128], String:tmp[2][64];

	if (args == 0 || args > 1) {
		ReplyToCommand(client, "[%s] Usage: sm_setnext <name|(#id)> - accepts short forms (like dt, da) or parts of names (air, harvest, small, ..) as well, returns if the campaign could be found", TAG);
	} else if (args == 1) {
		new foundItems;
		if (foundCampaigns != INVALID_HANDLE && (foundItems = GetArraySize(foundCampaigns)) > 0) {
			GetCmdArg(1, forceNextArg, sizeof(forceNextArg));
			if (StrContains(forceNextArg, "#") != -1) ReplaceString(forceNextArg, sizeof(forceNextArg), "#", "");

			new campaignId = StringToInt(forceNextArg);

			campaignId--;
			if (campaignId >= foundItems || campaignId < 0) {
				ReplyToCommand(client, "[%s] Campaign id not found (available %i)", TAG, foundItems);
			} else {
				GetArrayString(foundCampaigns, campaignId, tmp[0], sizeof(tmp[]));

				if (strcmp("Dead Air", tmp[0]) != -1) {
					forceNext = "airport";
				} else if (strcmp("Death Toll", tmp[0]) != -1) {
					forceNext = "smalltown";
				} else if (strcmp("No Mercy", tmp[0]) != -1) {
					forceNext = "hospital";
				} else if (strcmp("Blood Harvest", tmp[0]) != -1) {
					forceNext = "farm";
				} else if (strcmp("Crash Course", tmp[0]) != -1) {
					forceNext = "garage";
				} else if (strcmp("Death Aboard", tmp[0]) != -1) {
					forceNext = "aboard";
				} else if (strcmp("Fly Gabe Newell", tmp[0]) != -1) {
					forceNext = "museum";
				} else if (strcmp("Coald Blood", tmp[0]) != -1) {
					forceNext = "coald";
				}

				#if DEBUG_CHMAP
				PrintDebugMessage(0, -1, "[DEBUG] Command_NextCampgain(): [ tmp[0] = %s | forceNext = %s ]", tmp[0], forceNext);
				#endif
				PrintToChat(client, "[%s] Next campaign set to '%s'", TAG, tmp[0]);

				ClearArray(foundCampaigns);
				foundCampaigns = INVALID_HANDLE;
			}
		} else {
			forceNext = "\0";
			foundCampaigns = CreateArray(64);

			GetCmdArg(1, forceNextArg, sizeof(forceNextArg));

			if (strcmp(forceNextArg, "da") == 0 || StrContains("Dead Air", forceNextArg, false) != -1 || StrContains("airport", forceNextArg, false) != -1) {
				forceNext = "airport";
				PushArrayString(foundCampaigns, "Dead Air");
			}
			if (strcmp(forceNextArg, "dt") == 0 || StrContains("Death Toll", forceNextArg, false) != -1 || StrContains("smalltown", forceNextArg, false) != -1) {
				forceNext = "smalltown";
				PushArrayString(foundCampaigns, "Death Toll");
			}
			if (strcmp(forceNextArg, "nm") == 0 || StrContains("No Mercy", forceNextArg, false) != -1 || StrContains("hospital", forceNextArg, false) != -1) {
				forceNext = "hospital";
				PushArrayString(foundCampaigns, "No Mercy");
			}
			if (strcmp(forceNextArg, "bh") == 0 || StrContains("Blood Harvest", forceNextArg, false) != -1 || StrContains("farm", forceNextArg, false) != -1) {
				forceNext = "farm";
				PushArrayString(foundCampaigns, "Blood Harvest");
			}
			if (strcmp(forceNextArg, "cc") == 0 || StrContains("Crash Course", forceNextArg, false) != -1 || StrContains("garage", forceNextArg, false) != -1) {
				forceNext = "garage";
				PushArrayString(foundCampaigns, "Crash Course");
			}
			if (strcmp(forceNextArg, "ab") == 0 || StrContains("Death Aboard", forceNextArg, false) != -1 || StrContains("aboard", forceNextArg, false) != -1) {
				forceNext = "aboard";
				PushArrayString(foundCampaigns, "Death Aboard");
			}
			if (strcmp(forceNextArg, "cb") == 0 || StrContains("Coald Blood", forceNextArg, false) != -1 || StrContains("coald", forceNextArg, false) != -1) {
				forceNext = "coald";
				PushArrayString(foundCampaigns, "Coald Blood");
			}
			if (strcmp(forceNextArg, "fg") == 0 || StrContains("Fly Gabe", forceNextArg, false) != -1 || StrContains("gabe", forceNextArg, false) != -1) {
				forceNext = "museum";
				PushArrayString(foundCampaigns, "Fly Gabe Newell");
			}
			
			if (strlen(forceNext) == 0) {
				PrintToChat(client, "[%s] No campaign found related to '%s'", TAG, forceNextArg);

				return Plugin_Handled;
			}

			if ((foundItems = GetArraySize(foundCampaigns)) == 1)
			{
				decl String:foundString[256];
				GetArrayString(foundCampaigns, 0, foundString, sizeof(foundString));
				#if DEBUG_CHMAP
				PrintToChat(client, "[%s] One campaign found related to '%s' :  %s", TAG, forceNextArg, foundString);
				#endif
				PrintToChat(client, "[%s] Next campaign set to '%s'", TAG, foundString);

				ClearArray(foundCampaigns);
				foundCampaigns = INVALID_HANDLE;
			}
			else if (foundItems > 1)
			{
				#if DEBUG_CHMAP
				PrintToChat(client, "[%s] More than one campaign found related to '%s' :  %i", TAG, forceNextArg, foundItems);
				#endif
				decl String:foundString[256] = "\0";
				for (new i = 1; i <= foundItems; i++)
				{
					#if DEBUG_CHMAP
					PrintToChat(client, "[%s] Generating found string - iteration #%i", TAG, i);
					#endif
					GetArrayString(foundCampaigns, i - 1, tmp[0], sizeof(tmp[]));
					Format(tmp[1], sizeof(tmp[]), "%s (#%i)", tmp[0], i);
					StrCat(foundString, sizeof(foundString), tmp[1]);
					if (i < foundItems) StrCat(foundString, sizeof(foundString), ", ");
				}
				PrintToChat(client, "[%s] More than one campaign found related to '%s': %s (you can use sm_setnext <#id> to set it to the one you want)", TAG, forceNextArg, foundString);
				forceNext = "\0";

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_DumpCPD(client, args)
{
	decl String:prop[128], String:type[16], String:ent[16], String:size[16];

	if (args < 2)
	{
		ReplyToCommand(client, "[%s] Usage: dumpcpd <entprop> <int|bool|float|vec|str> (<ent>) (<size>)", TAG);
	}
	else if (args == 2)
	{
		GetCmdArg(1, prop, sizeof(prop));
		GetCmdArg(2, type, sizeof(type));

		#if DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Command_DumpCPD(2): [ prop = %s | type = %s ]", prop, type);
		#endif

		DumpCPDEntity(prop, type);
	}
	else if (args == 3)
	{
		GetCmdArg(1, prop, sizeof(prop));
		GetCmdArg(2, type, sizeof(type));
		GetCmdArg(3, ent, 32);

		#if DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Command_DumpCPD(3): [ prop = %s | type = %s | ent = %i ]", prop, type, ent);
		#endif

		DumpCPDEntity(prop, type, StringToInt(ent));
	}
	else if (args == 4)
	{
		GetCmdArg(1, prop, sizeof(prop));
		GetCmdArg(2, type, sizeof(type));
		GetCmdArg(3, ent, 32);
		GetCmdArg(4, size, 32);

		#if DEBUG_DOOR
		PrintDebugMessage("[DEBUG] Command_DumpCPD(4): [ prop = %s | type = %s | ent = %i | size = %i ]", prop, type, ent, size);
		#endif

		DumpCPDEntity(prop, type, StringToInt(ent), StringToInt(size));
	}

	return Plugin_Handled;
}

public Action:Command_DumpPlayers(client, args)
{
	new Float:origin[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientAbsOrigin(i, origin);
			PrintToChatAll("[DEBUG] %L [ loading = %i | timeout = %i | origin = %f %f %f | ready = %i ]", i, isClientLoading[i], clientTimeout[i], origin[0], origin[1], origin[2], scrimReady[i]);
		}
		else PrintToChatAll("[DEBUG] #%i [ loading = %i | timeout = %i | ready = %i ]", i, isClientLoading[i], clientTimeout[i], scrimReady[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Stop(client, args)
{
	if (IsCountDownRunning())
	{
		PrintToChat(client, "[%s] Forced countdown stop.", TAG);
		SetConVarInt(FindConVar("versus_force_start_time"), 6000, false, false);

		countDown = -1;
	}

	return Plugin_Handled;
}

/* set versus_force_start_time to current time + countdown
 * common/ mob size not initialized properly
 */
public Action:Command_Start(client, args)
{
	if (IsCountDownStopped()) {
		PrintToChat(client, "[%s] Forced start of countdown.", TAG);

		if (GetConVarInt(FindConVar("versus_force_start_time")) != 90)
		{
			SetConVarInt(FindConVar("versus_force_start_time"), GetTime() + 90, false, false);
		}

		countDown = 0;
		DirectorStart();

		if (GetConVarBool(scrimMode) && isFirstMap)
		{
			PrintToChatAll("Admin forced countdown start, starting round in %i seconds", GetConVarInt(prepareTimeScrim));
			CreateTimer(1.0, LiveTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else
		{
			PrintToChatAll("Admin forced countdown start, starting round in %i seconds", GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd));
			CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Force(client, args)
{
	if (IsCountDownStoppedOrRunning())
	{
		ReplyToCommand(client, "[%s] Forced round start.", TAG);

		if (GetConVarInt(FindConVar("versus_force_start_time")) != 90) {
			SetConVarInt(FindConVar("versus_force_start_time"), 90, false, false);
		}

		if (IsCountDownStopped())
			countDown = 0;
		else countDown = GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd);
		DirectorStart();

		if (!isFirstMap && checkPointDoorEntityStart != 0) SpawnFakeDoor(checkPointDoorEntityStart, false);

		decl String:cmd[] = "director_force_versus_start";
		new flags = GetCommandFlags(cmd);
		SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
		ServerCommand(cmd);
		SetCommandFlags(cmd, flags);
	}

	return Plugin_Handled;
}

/*
 * Timers
 */

public Action:AfkTimer(Handle:timer)
{
	static display = 0;
	new Float:tmpAngles[3];

	if (IsCountDownStoppedOrRunning() && !GetConVarBool(scrimMode))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				GetClientEyeAngles(i, tmpAngles);
				#if DEBUG_PLAYERS
				//PrintDebugMessage("[DEBUG] AfkTimer(): %f %f %f - %f %f %f (%i)", tmpAngles[0],tmpAngles[1],tmpAngles[2],clientMouse[i][0],clientMouse[i][1],clientMouse[i][2],GetVectorDistance(tmpAngles, clientMouse[i]));
				PrintDebugMessage("[DEBUG] AfkTimer(): [ distance = %i | buttons = %i ]", GetVectorDistance(tmpAngles, clientMouse[i]), GetClientButtons(i));
				#endif
				if (GetClientButtons(i) == 0 && GetVectorDistance(tmpAngles, clientMouse[i]) == 0) clientButtons[i]++;
				else clientButtons[i] = 0;

				clientMouse[i][0] = tmpAngles[0];
				clientMouse[i][1] = tmpAngles[1];
				clientMouse[i][2] = tmpAngles[2];

				if (clientButtons[i] / 10 == GetConVarInt(playerAfk))
				{
					if (!IsSoleSurvivor())
					{
						ChangeClientTeam(i, 1);
						ClientCommand(i, "chooseteam");
						PrintToChatAll("Player %N is afk - switched to spectators", i);
						display = 0;
					}
					else if (IsSoleSurvivor() && display == 0)
					{
						PrintToChatAll("Player %N is afk but sole survivor", i);
						display++;
					}
				}
			}
		}
	}
	else
	{
		if (foo++ > 11)
		{
			foo = 0;

			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}


public Action:LiveTimer(Handle:timer)
{
	if (countDown == -1)
	{
		PrintTextAll("Countdown interupted - waiting for restart or ready-up");

		DirectorStop();
		
		return Plugin_Stop;
	}
	else if (countDown++ >= GetConVarInt(prepareTimeScrim) - 1)
	{
		countDown = 0;

		PrintTextAll("Round started - move out");

		if (!isFirstMap && checkPointDoorEntityStart != 0) SpawnFakeDoor(checkPointDoorEntityStart, false);
		UnFreezePlayers();

		isFirstRound = false;

		#if DEBUG_SCRIM
		PrintDebugMessage("Current settings :  1st = %i, 2nd = %i, timeout = %i, scrim = %i, masters = %i, spawn = %i", GetConVarInt(prepareTime1st), GetConVarInt(prepareTime2nd), GetConVarInt(waitOnTimeOut), GetConVarInt(scrimMode), GetConVarInt(scrimMasters), GetConVarInt(awaitSpawn));
		#endif

		return Plugin_Stop;
	}
	else
	{
		PrintTextAll("%i seconds remaining until starting round", GetConVarInt(prepareTimeScrim) - countDown);
	}

	return Plugin_Continue;
}

public Action:StartTimer(Handle:timer)
{
	if (countDown == -1)
	{
		PrintTextAll("Countdown interrupted - waiting for restart or ready-up");

		DirectorStop();
		
		return Plugin_Stop;
	}
	else if (countDown++ >= GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd) - 1)
	{
		if (GetConVarInt(FindConVar("versus_force_start_time")) != 90)
		{
			SetConVarInt(FindConVar("versus_force_start_time"), 90, false, false);
		}

		countDown = 0;

		PrintTextAll("Round started - move out");

		if (!isFirstMap)
		{
			if (checkPointDoorEntityStart != 0) SpawnFakeDoor(checkPointDoorEntityStart, false);
		}
		UnFreezePlayers();

		isFirstRound = false;

		#if DEBUG_DOOR
		PrintDebugMessage("Current settings :  1st = %i, 2nd = %i, timeout = %i, scrim = %i, masters = %i, spawn = %i", GetConVarInt(prepareTime1st), GetConVarInt(prepareTime2nd), GetConVarInt(waitOnTimeOut), GetConVarInt(scrimMode), GetConVarInt(scrimMasters), GetConVarInt(awaitSpawn));
		#endif

		return Plugin_Stop;
	}
	else
	{
		PrintTextAll("%i seconds remaining until starting round", GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd) - countDown);
	}

	return Plugin_Continue;
}

public Action:LoadingTimer(Handle:timer)
{
	if (IsFinishedLoading())
	{
		if (GetConVarBool(scrimMode) && !UseTimer())
		{
			PrintToChatAll("All players in-game, waiting for %i player(s) on each team to set ready state", GetConVarInt(scrimMasters));

			return Plugin_Stop;
		}
		else
		{
			if (CanUnfreeze()) UnFreezePlayers();

			if (GetConVarBool(awaitSpawn))
			{
				PrintToChatAll("All players ingame, waiting for infected players to be ready to spawn");

				CreateTimer(1.0, SpawningTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

				return Plugin_Stop;
			}
			else
			{
				if (!IsCountDownRunning())
				{
					countDown = 0;
					DirectorStart();

					if (isFirstMap && GetConVarInt(freezeOn1st) == 1)
						PrintToChatAll("All players in-game, starting round");
					else if (!isFirstMap || GetConVarInt(freezeOn1st) == 2)
					{
						PrintToChatAll("All players in-game, starting round in %i seconds", GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd));

						CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					}
				}

				return Plugin_Stop;
			}
		}
	}
	else
	{
		countDown = -1;
	}

	return Plugin_Continue;
}

public Action:FreezingTimer(Handle:timer, Handle:dp)
{
	if (dp == INVALID_HANDLE)
	{
		#if DEBUG_SCRIM || DEBUG_DOOR
		PrintDebugMessage("[DEBUG] FreezingTimer(): Invalid data handle");
		#endif
		return Plugin_Stop;
	}
	else
	{
		ResetPack(dp);
		new client = ReadPackCell(dp);

		if (IsClientConnected(client))
		{
			if (isFirstMap && ((GetConVarBool(scrimMode) && IsCountDownStopped()) || (GetConVarInt(freezeOn1st) == 1 && IsCountDownStopped()) || (GetConVarInt(freezeOn1st) == 2 && IsCountDownStoppedOrRunning())))
			{
				if (GetClientTeam(client) == 2)
				{
					if (IsValidEntity(client))
					{
						SetEntityMoveType(client, MOVETYPE_NONE);
						#if DEBUG_SCRIM || DEBUG_DOOR
						if (IsValidEntity(client) && GetEntityMoveType(client) == MOVETYPE_NONE)
						{
							PrintDebugMessage("[DEBUG] Froze player %L", client);
						}
						#endif
						return Plugin_Stop;
					}
					#if DEBUG_SCRIM || DEBUG_DOOR
					else PrintDebugMessage("[DEBUG] FreezingTimer(): Player %L returned invalid entity", client);
					#endif
				}
			}
			#if DEBUG_SCRIM || DEBUG_DOOR
			else PrintDebugMessage("[DEBUG] FreezingTimer(): Skipping freeze of %L [ countdown = %i ]", client, countDown);
			#endif
		}
	}
	return Plugin_Continue;
}

public Action:SpawningTimer(Handle:timer)
{
	if (IsInfectedTeamReady())
	{
		if (!IsCountDownRunning())
		{
			PrintToChatAll("All infected players ready to spawn, starting round in %i seconds", GetConVarInt(isFirstRound ? prepareTime1st : prepareTime2nd));

			countDown = 0;
			DirectorStart();

			CreateTimer(1.0, StartTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}

		return Plugin_Stop;
	} else {
		countDown = -1;
	}

	return Plugin_Continue;
}

new Handle:g_maparray = INVALID_HANDLE;
new g_mapserial = -1;
public Action:RestartCampaignTimer(Handle:timer)
{
	decl String:map[128], String:scenario[128];
	new Handle:maparray;

	GetCurrentMap(map, sizeof(map));

	SplitString(map, "0", scenario, sizeof(scenario));
#if DEBUG_SCRIM
	PrintDebugMessage("[DEBUG] Detected scenario: %s", scenario);
#endif
	
	if ((maparray = ReadMapList(g_maparray,
		g_mapserial,
		"sm_votemap menu",
		MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_MAPSFOLDER))
	!= INVALID_HANDLE) {
		g_maparray = maparray;
	}
	
	if (g_maparray == INVALID_HANDLE) {
		PrintToChatAll("[%s] Failed to retrieve map list", TAG);
		LogError("[%s] Could not retrieve map list", TAG);
		return;
	}
	
	decl String:mapname[128];
	new mapcount = GetArraySize(g_maparray);
	new bool:detected = false;
	
	for (new i = 0; i < mapcount; i++) {
		GetArrayString(maparray, i, mapname, sizeof(mapname));
		if (StrContains(mapname, scenario, false) != -1 && StrContains(mapname, "01", false) != -1) {
			detected = true;
#if DEBUG_SCRIM
			PrintDebugMessage("[DEBUG] Executing changelevel %s", mapname);
#endif
			ServerCommand("changelevel %s", mapname);
		}
	}

	if (!detected) {
		PrintToChatAll("[%s] Failed to restart campaign", TAG);
		LogError("[%s] Could not retrieve scenario from map '%s'", TAG, map);
	}
}

public Action:NewCampaignTimer(Handle:timer)
{
	decl String:map[128], String:mapname[128], String:nextmap[128] = "\0", String:firstmap[128] = "\0";
	new Handle:maparray;

	GetCurrentMap(map, sizeof(map));
	
	if ((maparray = ReadMapList(g_maparray,
		g_mapserial,
		"sm_votemap menu",
		MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_MAPSFOLDER))
	!= INVALID_HANDLE)
	{
		g_maparray = maparray;
	}
	
	if (g_maparray == INVALID_HANDLE)
	{
		PrintToChatAll("[%s] Failed to retrieve map list", TAG);
		LogError("[%s] Could not retrieve map list", TAG);
		return;
	}
	
	new mapcount = GetArraySize(g_maparray);
	new bool:detectedCur = false;
	new bool:detectedNxt = false;
	
	for (new i = 0; i < mapcount; i++)
	{
		GetArrayString(maparray, i, mapname, sizeof(mapname));
		if (StrContains(mapname, map, false) != -1) detectedCur = true;
		if (IsRightMapForGameMode(mapname) && StrContains(mapname, "01", false) != -1) {
			if (strlen(forceNext) > 0 && StrContains(mapname, forceNext, false) != -1) {
				strcopy(nextmap, sizeof(nextmap), mapname);
				detectedNxt = true;
				forceNext = "\0";
				break;
			} else {
				if (detectedCur && !detectedNxt)
				{
					strcopy(nextmap, sizeof(nextmap), mapname);
					#if DEBUG_CHMAP
					PrintDebugMessage("[DEBUG] Found next campaign '%s'", mapname);
					#endif
					detectedNxt = true;
				}
				if (strlen(firstmap) == 0) {
					strcopy(firstmap, sizeof(firstmap), mapname);
					#if DEBUG_CHMAP
					PrintDebugMessage("[DEBUG] Found first campaign '%s'", mapname);
					#endif
				}
			}
		}
	}

	if (!detectedNxt)
	{
		strcopy(nextmap, sizeof(nextmap), firstmap);
		#if DEBUG_CHMAP
		PrintDebugMessage("[DEBUG] Currently playing last campaign, using first map '%s'", nextmap);
		#endif
	}

	if (strlen(nextmap) > 0)
	{
		#if DEBUG_CHMAP
		PrintDebugMessage("[DEBUG] Forcing next campaign '%s'", nextmap);
		#endif
		ServerCommand("changelevel %s", nextmap);
	} else {
		PrintToChatAll("[%s] Failed to load next campaign", TAG);
		LogError("[%s] Could not load next scenario from map '%s'", TAG, map);
	}
}

bool:IsRightMapForGameMode(const String:map[])
{
	decl String:gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));

	if (StrContains(map, "l4d_garage", false) != -1 || StrContains(map, "l4d_coald", false) != -1 || StrContains(map, "l4d_deathaboard", false) != -1 || StrContains(map, "lc_museum", false) != -1) return true;
	else if (StrContains(gamemode, "versus", false) != -1) return StrContains(map, "l4d_vs_", false) != -1;
	else if (StrContains(gamemode, "coop", false) != -1) return StrContains(map, "l4d_vs_", false) == -1 && StrContains(map, "l4d_sv_", false) == -1;
	else return false;
}

/*
 * Methods
 */

bool:CanUnfreeze()
{
	return !(isFirstMap && GetConVarInt(freezeOn1st) == 2);
}

stock PrintDebugMessage(const String:format[], any:...)
{
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);

	#if (DEBUG_LOG == 1)
	LogAction(0, 0, buffer);
	#endif
	
	#if (DEBUG_CHAT == 1)
	PrintToChatAll(buffer);
	#endif
}

PrintTextAll(const String:format[], any:...)
{
	decl String:buffer[192], String:type[64];
	
	VFormat(buffer, sizeof(buffer), format, 2);

	GetConVarString(displayMode, type, sizeof(type));

	if (strcmp(type, "center") == 0) PrintCenterTextAll(buffer);
	else if (strcmp(type, "hint") == 0) PrintHintTextToAll(buffer);
	else if (strcmp(type, "chat") == 0) PrintToChatAll(buffer);
	else {
		PrintCenterTextAll(buffer);
		LogError("[%s] Invalid display type, using center", TAG);
	}
}

bool:IsSoleSurvivor()
{
	new count = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i)) {
			count++;
		}
	}

	return count == 1;
}

#if DEBUG_DOOR
bool:IsCheckPointDoor(ent)
{
	for (new i = 0; i < 4; i++) {
		if (checkPointDoorEntityIds[i] == ent) {
			return true;
		}
	}
	return false;
}
#endif

DumpCPDEntity(const String:prop[], const String:type[], ent = -1, size = 4)
{
	if (ent <= 0 && checkPointDoorEntityStart == 0) {
		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Invalid entity");
	} else if (ent == -1 && checkPointDoorEntityStart != 0) {
		ent = checkPointDoorEntityStart;
	}

	if (strcmp(type, "bool") == 0 || strcmp(type, "int") == 0) {
		new value;
		value = GetEntProp(ent, Prop_Data, prop, size);

		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Property %s has value %i", prop, value);
	} else if (strcmp(type, "vec") == 0) {
		new Float:value[3];
		GetEntPropVector(ent, Prop_Data, prop, value);

		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Property %s has value %f %f %f", prop, value[0], value[1], value[2]);
	} else if (strcmp(type, "float") == 0) {
		new Float:value;
		value = GetEntPropFloat(ent, Prop_Data, prop);

		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Property %s has value %f", prop, value);
	} else if (strcmp(type, "str") == 0) {
		decl String:value[128];
		GetEntPropString(ent, Prop_Data, prop, value, sizeof(value));

		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Property %s has value %s", prop, value);
	} else if (strcmp(type, "handle") == 0) {
		decl String:netclass[128];
		new value = GetEntPropEnt(ent, Prop_Data, prop);
		GetEntityNetClass(value, netclass, sizeof(netclass));

		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Property %s has value %i (%s)", prop, value, netclass);
	} else {
		LogAction(0, -1, "[DEBUG] DumpCPDEntity(): Invalid type (int|bool|float|vec|str|handle)");
	}
}

new cLimit, mSize;
DirectorStop()
{
	/* Remove spawning */
	SetConVarInt(FindConVar("director_no_bosses"), 1);
	SetConVarInt(FindConVar("director_no_specials"), 1);

	/* Remove mobs */
	SetConVarInt(FindConVar("director_no_mobs"), 1);
	if (GetConVarInt(FindConVar("z_common_limit")) != 0) {
		cLimit = GetConVarInt(FindConVar("z_common_limit"));
		SetConVarInt(FindConVar("z_common_limit"), 0);
	}
	if (GetConVarInt(FindConVar("z_mega_mob_size")) != 1) {
		mSize = GetConVarInt(FindConVar("z_mega_mob_size"));
		SetConVarInt(FindConVar("z_mega_mob_size"), 1);
	}

	#if DEBUG_DIRECTOR
	PrintDebugMessage("[DEBUG] DirectorStop(): [ common limit = %i | mob size = %i ]", cLimit, mSize);
	#endif
}

DirectorStart()
{
	new cLimitDef, mSizeDef;

	if (cLimit == 0) cLimit = GetConVarInt(FindConVar("z_common_limit"));
	if (mSize == 0) mSize = GetConVarInt(FindConVar("z_mega_mob_size"));

	/* Restore spawning */
	ResetConVar(FindConVar("director_no_bosses"));
	ResetConVar(FindConVar("director_no_specials"));

	/* Restore mobs */
	ResetConVar(FindConVar("director_no_mobs"));
	cLimitDef = GetConVarInt(FindConVar("z_common_limit"));
	mSizeDef = GetConVarInt(FindConVar("z_mega_mob_size"));
	SetConVarInt(FindConVar("z_common_limit"), cLimit != cLimitDef && cLimitDef != 0 ? cLimitDef : cLimit);
	SetConVarInt(FindConVar("z_mega_mob_size"), mSize != mSizeDef && mSizeDef != 1 ? mSizeDef : mSize);

	#if DEBUG_DIRECTOR
	PrintDebugMessage("[DEBUG] DirectorStart(): [ common limit = %s | mob size = %s ]", cLimit != cLimitDef && cLimitDef != 0 ? "cLimitDef" : "cLimit", mSize != mSizeDef && mSizeDef != 1 ? "mSizeDef" : "mSize");
	#endif

	/* Restart director (repopulate world) */
	decl String:cmd[] = "director_start";
	new flags = GetCommandFlags(cmd);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	ServerCommand(cmd);
	SetCommandFlags(cmd, flags);

	#if DEBUG_DIRECTOR
	PrintDebugMessage("[DEBUG] DirectorStart(): [ common limit = %i (def. %i) | mob size = %i (def. %i) ]", cLimit, cLimitDef, mSize, mSizeDef);
	#endif
}

ResetReadyState(client, String:cbipt[])
{
	decl String:sType[32];
	GetConVarString(scrimType, sType, sizeof(sType));

	if (strcmp(sType, cbipt) == 0) {
		scrimReady[client] = 0;
#if DEBUG_SCRIM
		if (IsClientConnected(client)) {
			PrintDebugMessage("[DEBUG] Reset ready state for player %L", client);
		}
#endif
	}
}

UpdateReadyCount()
{
	rdyCount = {0,0,0,0};
	for (new i = 1; i <= MaxClients; i++) {
		if (scrimReady[i] == 1) rdyCount[GetClientTeam(i)]++;
	}
}

SetReadyState(client, ready)
{
	if (GetConVarBool(scrimMode)) {
		if (IsTeamReady(client) && ready) PrintToChat(client, "Your team is ready");
		else {
			scrimReady[client] = ready;
			PrintToChatAll("Team %s got a player %s (%N)", GetClientTeam(client) == 2 ? "survivors" : "infected", ready ? "ready" : "unready", client);

			if (!ready) {
				/* Reset ready state for the whole team if we got 2 or 3 masters */
				if (GetConVarInt(scrimMasters) == 2 || GetConVarInt(scrimMasters) == 3) {
					for (new i = 1; i <= MaxClients; i++) {
						scrimReady[i] = 0;
					}
					PrintToChatAll("Team %s ready states reset", GetClientTeam(client) == 2 ? "survivors" : "infected");
				}

				if (IsCountDownRunning()) countDown = -1;
				else PrintToChatAll("Forcing new ready-up on next round", GetClientTeam(client) == 2 ? "survivors" : "infected");
			} else {
				UpdateReadyCount();
				PrintToChatAll("Team %s got %i of %i players ready", GetClientTeam(client) == 2 ? "survivors" : "infected", rdyCount[GetClientTeam(client)], GetConVarInt(scrimMasters));

				CheckSetLive();
			}
		}
	}
}

CheckSetLive()
{
	if(IsTeamsReady()) {
		PrintTextAll("Both teams are ready, starting round in %i seconds", GetConVarInt(prepareTimeScrim));

		countDown = 0;
		DirectorStart();

		isFirstRound = false;

		CreateTimer(1.0, LiveTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

bool:IsInfectedTeamReady()
{
	if (GetConVarBool(awaitSpawn)) {
		new bool:spawning = false;
		/*for (new i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
				if (GetClientTeam(i) == 3) {
					spawning = !isClientSpawning[i];
#if DEBUG_SCRIM
					PrintDebugMessage("%L :  %i", i, isClientSpawning[i]);
#endif
				}
			}
		}*/
		spawnWaitTime--;
		if (spawnWaitTime <= 0) spawning = true;
#if DEBUG_SCRIM
		PrintDebugMessage("[DEBUG] Infected ready :  %i", spawning);
#endif
		return spawning;
	} else return true;
}

bool:IsAnyClientLoading()
{
	for (new i = 1; i <= MaxClients; i++) {
		if (isClientLoading[i]) return true;
	}

	return false;
}

GetAnySurvivorPosition(String:vec[1024])
{
	new Float:origin[3];
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !foundAnOrigin)
		{
			decl String:clientname[256];
			GetClientName(i, clientname, sizeof(clientname));
			if (strlen(clientname) > 0)
			{
				GetClientAbsOrigin(i, origin);
				if ((RoundFloat(origin[0]) + RoundFloat(origin[1]) + RoundFloat(origin[2])) != 0) {
					foundAnOrigin = true;
					Format(vec, 1024, "%f %f %f ", origin[0], origin[1], origin[2]);
					#if DEBUG_DOOR
					PrintDebugMessage("[DEBUG] survivor [ player = %L | origin = %f %f %f | origin = %s ]", i, origin[0], origin[1], origin[2], vec);
					#endif
				}
				#if DEBUG_DOOR
				else PrintDebugMessage("[DEBUG] survivor [ player = %L ]", i);
				#endif
			}
		}
	}
}

GetCheckPointDoorStart()
{
	new flags[4], Float:survivorOrigin[3], Float:checkPointDoorEntityOrigin[4][3], Float:angles[4][3];
	for (new i = 0; i < 4; i++)
	{
		if (checkPointDoorEntityIds[i] != 0 && IsValidEntity(checkPointDoorEntityIds[i]))
		{
			GetEntPropVector(checkPointDoorEntityIds[i], Prop_Data,"m_vecAbsOrigin", checkPointDoorEntityOrigin[i]);
			flags[i] = GetEntProp(checkPointDoorEntityIds[i], Prop_Data,"m_spawnflags");
			GetEntPropVector(checkPointDoorEntityIds[i], Prop_Data, "m_angAbsRotation", angles[i]);

			#if DEBUG_DOOR
			PrintDebugMessage("[DEBUG] Found prop_door_rotating_checkpoint [ angles = %f %f %f | origin = %f %f %f | spawnflags = %i ]", angles[i][0], angles[i][1], angles[i][2], checkPointDoorEntityOrigin[i][0], checkPointDoorEntityOrigin[i][1], checkPointDoorEntityOrigin[i][2], flags[i]);
			DumpCPDEntity("m_angAbsRotation", "vec", checkPointDoorEntityIds[i]);
			#endif
		}
		#if DEBUG_DOOR
		else PrintDebugMessage("[DEBUG] Invalid entity id %i", checkPointDoorEntityIds[i]);
		#endif
	}

	decl String:buffers[4][128], String:survivorOriginStr[1024];
	GetAnySurvivorPosition(survivorOriginStr);

	if (foundAnOrigin)
	{
		ExplodeString(survivorOriginStr, " ", buffers, 4, sizeof(buffers[]));
		for (new i = 0; i < 2; i++) survivorOrigin[i] = StringToFloat(buffers[i]);

		#if DEBUG_DOOR
		decl String:svOrigin[256];
		Format(svOrigin, sizeof(svOrigin), "%f %f %f", survivorOrigin[0], survivorOrigin[1], survivorOrigin[2]);
		#endif

		checkPointDoorEntityStart = 0;

		new Float:dist[4], Float:smallest = 0.0;
		for (new i = 0; i < 4; i++)
		{
			if (checkPointDoorEntityIds[i] != 0 && (flags[i] == 8192 || flags[i] == 0))
			{
				dist[i] = GetVectorDistance(survivorOrigin, checkPointDoorEntityOrigin[i]);
				#if DEBUG_DOOR
				PrintDebugMessage("[DEBUG] survivor origin :  %s", svOrigin);
				PrintDebugMessage("[DEBUG] checkpoint entity :  %i", checkPointDoorEntityIds[i]);
				PrintDebugMessage("[DEBUG] checkpoint origin :  %f %f %f", checkPointDoorEntityOrigin[i][0], checkPointDoorEntityOrigin[i][1], checkPointDoorEntityOrigin[i][2]);
				PrintDebugMessage("[DEBUG] distance #%i :  %f", i, dist[i]);
				#endif
				if (IsValidEntity(checkPointDoorEntityIds[i]) && (i == 0 || RoundFloat(smallest) == 0 || FloatCompare(smallest, dist[i]) == 1)) {
					smallest = dist[i];
					checkPointDoorEntityStart = checkPointDoorEntityIds[i];
					Format(checkPointDoorEntityStartAngles, sizeof(checkPointDoorEntityStartAngles), "%f %f %f", angles[i][0], angles[i][1], angles[i][2]);
				}
				#if DEBUG_DOOR
				else LogError("[%s] Not first entity, smallest > 0 or distance not smaller [ id = %i | dist = %f | smallest = %f (%i) ]", TAG, i, dist[i], smallest, RoundFloat(smallest));
				#endif
			}
			#if DEBUG_DOOR
			else LogError("[%s] Invalid entity id or invalid spawnflags [ ent = %i | spawnflags = %i ]", TAG, checkPointDoorEntityIds[i], flags[i]);
			#endif
		}

		if (checkPointDoorEntityStart != 0)
		{
			#if DEBUG_DOOR
			PrintDebugMessage( "Determined starting safe room door entity :  %i [ angles = %s ]", checkPointDoorEntityStart, checkPointDoorEntityStartAngles);
			#endif

			SpawnFakeDoor(checkPointDoorEntityStart, true);
		}
		else LogError("[%s] Could not determine starting safe room door entity", TAG);
	}
	#if DEBUG_DOOR
	else LogError("[%s] Could not retrieve a valid survivor origin", TAG);
	#endif
}

bool:IsFinishedLoading()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsFakeClient(i))
			{
				/* Freeze the bots to prevent them moving out sometimes until all players have loaded */
				#if DEBUG_SCRIM
				PrintDebugMessage(0, -1, "[DEBUG] Bot %L saved on datapack for FreezingTimer()", i);
				#endif
				new Handle:dp = CreateDataPack();
				CreateDataTimer(0.1, FreezingTimer, dp, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(dp, i);
			}
			if (!IsClientInGame(i) && !IsFakeClient(i))
			{
				clientTimeout[i]++;
				if (isClientLoading[i] && clientTimeout[i] == 1)
				{
					PrintToChatAll("Waiting for player %N to join the game", i);
					isClientLoading[i] = true;
				}
				else if (clientTimeout[i] == GetConVarInt(waitOnTimeOut))
				{
					/* Handling clients timing out */
					PrintToChatAll("Stopping to wait for player %N (assumed timeout)", i);
					isClientLoading[i] = false;
				}
			}
			else
			{
				if (GetConVarBool(scrimMode) || GetConVarBool(freezeOn1st))
				{
					if (isFirstMap)
					{
						/* Use 1 sec timer to freeze players when starting a new campaign */
						if (isFirstRound)
						{
							#if DEBUG_SCRIM
							PrintDebugMessage("[DEBUG] Player %L saved on datapack for FreezingTimer()", i);
							#endif
							new Handle:dp = CreateDataPack();
							CreateDataTimer(1.0, FreezingTimer, dp, TIMER_FLAG_NO_MAPCHANGE);
							WritePackCell(dp, i);
						}
						else if (GetConVarBool(scrimMode))
						{
							if (IsValidEntity(i) && GetClientTeam(i) == 2) SetEntityMoveType(i, MOVETYPE_NONE);
							#if DEBUG_SCRIM
							else PrintDebugMessage("[DEBUG] IsFinishedLoading(): Player %L returned invalid entity", i);

							if (IsValidEntity(i) && GetEntityMoveType(i) == MOVETYPE_NONE)
							{
								PrintDebugMessage("[DEBUG] Froze player %L", i);
							}
							#endif
						}
					}
				}

				isClientLoading[i] = false;
			}
		}
		else isClientLoading[i] = false;
	}
	return !IsAnyClientLoading();
}

GetCheckPointDoorIds()
{
	new ent, count;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1) {
		checkPointDoorEntityIds[count] = ent;
		count++;
	}
}

bool:IsAdmin(client)
{
	return GetUserAdmin(client)!=INVALID_ADMIN_ID;
}

bool:IsCountDownStoppedOrRunning()
{
	return countDown != 0;
}

bool:IsCountDownStopped()
{
	return countDown == -1;
}

bool:IsCountDownRunning()
{
	return countDown > 0;
}

bool:IsTeamsReady()
{
	new teams[2];

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && scrimReady[i] == 1) {
			teams[GetClientTeam(i) - 2]++;
		}
	}

	#if DEBUG_SCRIM
	PrintDebugMessage("[DEBUG] Ready state [ teams = %i/ %i | masters = %i ]", teams[0], teams[1], GetConVarInt(scrimMasters));
	#endif

	if (teams[0] >= GetConVarInt(scrimMasters) && teams[1] >= GetConVarInt(scrimMasters)) {
		return true;
	} else return false;
}

bool:IsTeamReady(client)
{
	new team;

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && GetClientTeam(client) == GetClientTeam(i) && scrimReady[i] == 1) {
			team++;
		}
	}

	if (team >= GetConVarInt(scrimMasters)) {
		return true;
	} else return false;
}

SpawnFakeDoor(ent, bool:cantOpen)
{
	if (IsValidEntity(ent))
	{
		decl String:model[255], String:targetname[255], String:sorigin[255], String:renderFX[255], String:renderMode[255], String:spawnFlags[255];//, String:spawnPos[255];
		GetEntPropString(ent, Prop_Data,"m_ModelName",model,sizeof(model));
		GetEntPropString(ent, Prop_Data,"m_iName",targetname,sizeof(targetname));

		new renderfx = GetEntProp(ent, Prop_Data, "m_nRenderFX");
		new rendermode = GetEntProp(ent, Prop_Data, "m_nRenderMode");
		//new spawnpos = GetEntProp(ent, Prop_Data, "m_eSpawnPosition");

		decl Float:origin[3];
		GetEntPropVector(ent, Prop_Data,"m_vecAbsOrigin",origin);

		new fakedoor = CreateEntityByName("prop_door_rotating_checkpoint");

		if (cantOpen)
		{
			spawnFlags = "40960";
			checkPointDoorEntityStart = fakedoor;
			ReplaceIds(ent, fakedoor);
		}
		else
		{
			spawnFlags = "8192";
			checkPointDoorEntityStart = fakedoor;
			ReplaceIds(ent, fakedoor);
		}

		#if DEBUG_DOOR
		LogAction(0, -1, "Attempting to copy ent with id %i (angles: %s, flags: %s)",ent,checkPointDoorEntityStartAngles,spawnFlags);
		#endif

		Format(sorigin, sizeof(sorigin), "%f %f %f", origin[0], origin[1], origin[2]);
		IntToString(renderfx, renderFX, sizeof(renderFX));
		IntToString(rendermode, renderMode, sizeof(renderMode));
		//IntToString(spawnpos, spawnPos, sizeof(spawnPos));

		DispatchKeyValue(fakedoor,"renderfx",renderFX);
		DispatchKeyValue(fakedoor,"rendermode",renderMode);
		//DispatchKeyValue(fakedoor,"spawnpos",spawnPos);
		DispatchKeyValue(fakedoor,"spawnflags",spawnFlags);
		DispatchKeyValue(fakedoor,"angles",checkPointDoorEntityStartAngles);
		DispatchKeyValue(fakedoor,"speed","200");
		DispatchKeyValue(fakedoor,"returndelay","-1");
		DispatchKeyValue(fakedoor,"model",model);
		DispatchKeyValue(fakedoor,"origin",sorigin);
		DispatchKeyValue(fakedoor,"classname","prop_door_rotating_checkpoint");
		//DispatchKeyValue(fakedoor,"target",0);
		DispatchKeyValue(fakedoor,"targetname",targetname);

		DispatchSpawn(fakedoor);

		if (IsValidEntity(fakedoor))
			RemoveEdict(ent);

		#if DEBUG_DOOR
		if (!IsValidEntity(fakedoor)) PrintDebugMessage("[DEBUG] %s %s %s %s %s",renderFX,renderMode,spawnFlags,checkPointDoorEntityStartAngles,sorigin);
		if (IsValidEntity(fakedoor)) LogAction(0, -1, "Created fake door with ent id %i (%s)", fakedoor, cantOpen ? "cannot be opened" : "can be opened");
		else LogAction(0, -1, "Failed to create fake door");
		#endif
	}
	else
	{
		LogError("Entity id %i is invalid", ent);
	}
}

ReplaceIds(oldId, newId)
{
	for (new i = 0; i < 4; i++)
	{
		if (checkPointDoorEntityIds[i] == oldId)
		{
			checkPointDoorEntityIds[i] = newId;
		}
	}
}

bool:UseTimer()
{
	decl String:sType[32];
	GetConVarString(scrimType, sType, sizeof(sType));

	/* One team is no longer ready, force pause on this round */
	if (!IsTeamsReady()) return false;
	else if (strcmp(sType, "match") == 0 && isFirstMap && !isFirstRound) return true;
	else if (strcmp(sType, "match") == 0 && !isFirstMap) return true;
	else if (strcmp(sType, "map") == 0 && !isFirstRound) return true;
	else return false;
}

UnFreezePlayers()
{
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i)) {
			if (IsValidEntity(i) && GetEntityMoveType(i) == MOVETYPE_NONE) {
				SetEntityMoveType(i, MOVETYPE_WALK);
				#if DEBUG_SCRIM
				PrintDebugMessage("[DEBUG] UnFreezePlayers(): Unfroze player %L", i);
				#endif
			}
		}
	}
}

ToggleScrimMode(client)
{
	new bool:status = GetConVarBool(scrimMode);
	SetConVarBool(scrimMode, !status);

	LogAction(0, -1, "'%L' turned scrim mode %s.", client, (!status ? "on" : "off"));

	PrintToChat(client, "[%s] Turned scrim mode %s.", TAG, (!status ? "on" : "off"));
}

ToggleAwaitSpawn(client)
{
	new bool:status = GetConVarBool(awaitSpawn);
	SetConVarBool(awaitSpawn, !status);

	LogAction(0, -1, "'%L' turned await spawn %s.", client, (!status ? "on" : "off"));

	PrintToChat(client, "[%s] Turned await spawn %s.", TAG, (!status ? "on" : "off"));
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

/*
 * Menus
 */

public AdminMenuHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "Loading:", param);
	}
	else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Loading", param);
	}
}

public LoadingMenuHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		decl String:title[65];
		if (object_id == menuScrim) {
			Format(title, sizeof(title), "Toggle Scrim Mode (cur. %s)", (GetConVarBool(scrimMode) ? "on" : "off"));
			Format(buffer, maxlength, title, param);
		} else if (object_id == menuSpawn) {
			Format(title, sizeof(title), "Toggle Await Spawn (cur. %s)", (GetConVarBool(awaitSpawn) ? "on" : "off"));
			Format(buffer, maxlength, title, param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == menuScrim)
			ToggleScrimMode(param);
		else if (object_id == menuSpawn)
			ToggleAwaitSpawn(param);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Block us from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
	
	hTopMenu = topmenu;
	
	new TopMenuObject:objLoadingMenu = FindTopMenuCategory(hTopMenu, "Loading");
	if (objLoadingMenu == INVALID_TOPMENUOBJECT)
		objLoadingMenu = AddToTopMenu(
			hTopMenu,
			"Loading",
			TopMenuObject_Category,
			AdminMenuHandler,
			INVALID_TOPMENUOBJECT
		);

	menuScrim = AddToTopMenu(
		hTopMenu,
		"L4D_Scrim_Item",
		TopMenuObject_Item,
		LoadingMenuHandler,
		objLoadingMenu,
		"sm_activate",
		ADMFLAG_KICK
	);

	menuSpawn = AddToTopMenu(
		hTopMenu,
		"L4D_Spawn_Item",
		TopMenuObject_Item,
		LoadingMenuHandler,
		objLoadingMenu,
		"sm_awaitSpawn",
		ADMFLAG_KICK
	);
}

DisplayScrimVote(const String:sType[])
{
	strcopy(g_scrimVoteType, sizeof(g_scrimVoteType), sType);

	g_l4dVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	if (strcmp(sType, "off") == 0) {
		SetMenuTitle(g_l4dVoteMenu, "Disable scrim mode and restart campaign?");
	} else {
		SetMenuTitle(g_l4dVoteMenu, "Enable scrim mode (type %s) and restart campaign?", sType);
	}
	
	AddMenuItem(g_l4dVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_l4dVoteMenu, VOTE_NO, "No");
	
	SetMenuExitButton(g_l4dVoteMenu, false);
	VoteMenuToAll(g_l4dVoteMenu, 20);
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(g_l4dVoteMenu);
	}
	else if	(action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[%s] No votes detected on %s vote", TAG, g_l4dVoteType);
	}
	else if (action == MenuAction_VoteEnd)
	{
		decl String:item[64], String:display[64];
		new Float:percent, Float:limit, votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
		
		if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
		{
			votes = totalVotes - votes;
		}
		
		percent = GetVotePercent(votes, totalVotes);
		
		if (strcmp(g_l4dVoteType, "scrim") == 0 && (strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1)) {
			LogAction(-1, -1, "Scrim vote (%s) failed.", g_scrimVoteType);
			PrintToChatAll("[%s] %s scrim mode vote failed [ type = %s | limit = %i | percent = %i | votes = %i ]", TAG, strcmp(g_scrimVoteType, "off") == 0 ? "Disable" : "Enable", g_scrimVoteType, RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			if (strcmp(g_l4dVoteType, "scrim") == 0) {
				new Float:voteRestartCampaignTimer = 5.0;

				PrintToChatAll("[%s] %s scrim vote successful - restarting campaign in %i seconds", TAG, strcmp(g_scrimVoteType, "off") == 0 ? "Disable" : "Enable", RoundFloat(voteRestartCampaignTimer));
				#if DEBUG_SCRIM
				PrintDebugMessage("[DEBUG] Vote properties [ type = %s | limit = %i | percent = %i | votes = %i ]", g_scrimVoteType, RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
				#endif

				if (strcmp(g_scrimVoteType, "off") == 0)
				{
					SetConVarInt(scrimMode, 0);
					#if DEBUG_SCRIM
					PrintDebugMessage("[DEBUG] Scrim mode deactivated");
					#endif
				}
				else
				{
					SetConVarInt(scrimMode, 1);
					SetConVarString(scrimType, g_scrimVoteType);
					#if DEBUG_SCRIM
					PrintDebugMessage("[DEBUG] Scrim mode (type %s) activated", g_scrimVoteType);
					#endif
				}
			}
		}
	}
}