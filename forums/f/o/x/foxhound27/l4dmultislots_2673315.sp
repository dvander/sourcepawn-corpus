//#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#if SOURCEMOD_V_MINOR < 7
 #error Old version sourcemod!
#endif
#pragma newdecls required

#define PLUGIN_VERSION 				"2.1"
#define CVAR_FLAGS					FCVAR_NONE|FCVAR_NOTIFY
#define DELAY_KICK_FAKECLIENT 		0.1
#define DELAY_KICK_NONEEDBOT 		0.7
#define TEAM_SPECTATORS 			1
#define TEAM_SURVIVORS 				2
#define TEAM_INFECTED				3
#define DAMAGE_EVENTS_ONLY			1
#define	DAMAGE_YES					2

ConVar hMaxSurvivors;
ConVar hMinSurvivors;
Handle timer_SpecCheck = null;
bool gbVehicleLeaving;
bool gbPlayedAsSurvivorBefore[MAXPLAYERS+1];
bool gbFirstItemPickedUp;
bool gbPlayerPickedUpFirstItem[MAXPLAYERS+1];
char gMapName[128];
int giIdleTicks[MAXPLAYERS+1];
Handle hRoundRespawn = null;
Handle gGameConf = null;
bool Played[MAXPLAYERS + 1];
Handle Join_Timer[MAXPLAYERS+1];
Handle g_kvDB = null;

//CVars' handles
ConVar cvar_ar_time = null;
ConVar cvar_ar_admin_immunity = null;
ConVar cvar_ar_disconnect_by_user_only = null;
ConVar cvar_lan = null;

//Cvars' varibles
bool isLAN = false;
int ar_time = 300;
int ar_disconnect_by_user_only = true;
int ar_admin_immunity = false;

bool map_start;
bool IsTimeTeleport;

public Plugin myinfo = 
{
	name = "[L4D(2)] MultiSlots",
	author = "SwiftReal, MI 5",
	description = "Allows additional survivor/infected players in coop, versus, and survival",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// This plugin will only work on L4D 1/2
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1) return APLRes_Failure; 
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("l4dmultislots.phrases");
	
	// Anti reconnect part
	g_kvDB = CreateKeyValues("antireconnect_multislot");
	
	cvar_ar_time = CreateConVar("l4d_multislots_anti_reconnect_time", "90", "Time in seconds players must to wait before connect to the server again after disconnecting, 0 = disabled", FCVAR_NONE, true, 0.0);
	cvar_ar_disconnect_by_user_only = CreateConVar("l4d_multislots_anti_reconnect_disconnect_by_user_only", "1", "\n0 = always block players from reconnecting\n1 = block player from reconnecting only if a client \"disconnected by user\"", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_ar_admin_immunity = CreateConVar("l4d_multislots_anti_reconnect_admin_immunity", "0", "0 = disabled, 1 = protect admins from Anti-Reconnect functionality", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");
	
	HookConVarChange(cvar_ar_time, OnCVarChange);
	HookConVarChange(cvar_ar_disconnect_by_user_only, OnCVarChange);
	HookConVarChange(cvar_ar_admin_immunity, OnCVarChange);
	HookConVarChange(cvar_lan, OnCVarChange);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_start", Check_Bots, EventHookMode_Post);
	
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Post);
	
	// Create plugin version cvar and set it
	CreateConVar("l4d_multislots_version", PLUGIN_VERSION, "L4D(2) MultiSlots version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetConVarString(FindConVar("l4d_multislots_version"), PLUGIN_VERSION);
	
	// Register commands
	RegAdminCmd("sm_addbot", AddBot, ADMFLAG_KICK, "Attempt to add and teleport a survivor bot");
	RegAdminCmd("sm_spec", Spec, ADMFLAG_ROOT, "");
	RegAdminCmd("sm_surv", Surv, ADMFLAG_ROOT, "");
	RegAdminCmd("sm_tweak", Tweak, ADMFLAG_ROOT, "Tweak some settings");
	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join Survivors");
	
	// Register cvars
	hMaxSurvivors	= CreateConVar("l4d_multislots_max_survivors", "17", "How many survivors allowed?", CVAR_FLAGS, true, 4.0, true, 32.0);
	hMinSurvivors	= CreateConVar("l4d_multislots_min_survivors", "4", "", CVAR_FLAGS, true, 4.0, true, 32.0);
	// Hook events
	HookEvent("item_pickup", evtRoundStartAndItemPickup);
	HookEvent("player_left_start_area", evtPlayerLeftStart);
	HookEvent("survivor_rescued", evtSurvivorRescued);
	HookEvent("finale_vehicle_leaving", evtFinaleVehicleLeaving);
	HookEvent("mission_lost", evtMissionLost);
	HookEvent("player_activate", evtPlayerActivate, EventHookMode_Post);
	HookEvent("bot_player_replace", evtPlayerReplacedBot);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_team", evtPlayerTeam);
	
	// Create or execute plugin configuration file
	AutoExecConfig(true, "l4dmultislots");
	
	gGameConf = LoadGameConfigFile("l4drevive");
	if (gGameConf != null)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == null) 
		{
			SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
  	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drevive.txt , you FAILED AT INSTALLING");
	}
}

public void OnMapStart()
{
	GetCurrentMap(gMapName, sizeof(gMapName));
	gbFirstItemPickedUp = false;
	map_start = false;
	
	// Anti reconnect part
	CloseHandle(g_kvDB);
	g_kvDB = CreateKeyValues("antireconnect_multislot");
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (client)
	{
		gbPlayedAsSurvivorBefore[client] = false;
		gbPlayerPickedUpFirstItem[client] = false;
		giIdleTicks[client] = 0;
	}
	return true;
}

public void OnClientDisconnect(int client)
{
	gbPlayedAsSurvivorBefore[client] = false;
	gbPlayerPickedUpFirstItem[client] = false;
	
	if (Join_Timer[client] != null)
	{ 
		KillTimer(Join_Timer[client]); 
		Join_Timer[client] = null; 
	}
}

public void OnMapEnd()
{
	StopTimers();
	gbVehicleLeaving = false;
	gbFirstItemPickedUp = false;
}

public Action AddBot(int client, int args)
{
	if (SpawnFakeClientAndTeleport()) PrintToChatAll("Survivor bot spawned and teleported.");
	return Plugin_Handled;
}

public Action Spec(int client, int args)
{
	if (client) ChangeClientTeam(client, 1);
	return Plugin_Handled;
}

public Action Surv(int client, int args)
{
	if (client) ChangeClientTeam(client, 2);
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	Played[client] = false;
	
	if (isLAN || ar_time == 0 || IsFakeClient(client) || !IsClientConnected(client)) return;
	
	char steamId[30];	
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
	int disconnect_time = KvGetNum(g_kvDB, steamId, -1);
	if (disconnect_time == -1) return;

	int wait_time = disconnect_time + ar_time - GetTime();
	if (wait_time <= 0)
	{
		KvDeleteKey(g_kvDB, steamId);
	}
	else
	{
		Played[client] = true;
		Join_Timer[client] = CreateTimer(6.0, PlayerJoin, client);
	}
	
	if (!IsTimeTeleport)
	{
		return;
	}
	
	CreateTimer(1.5, TimerTeleport, client);
}

public Action TimerTeleport(Handle timer, any client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client)) return;
	if (GetClientTeam(client) != TEAM_SURVIVORS || !IsPlayerAlive(client))
	{
		CreateTimer(3.5, TimerTeleport, client);
		return;
	}
	TeleportClientTo(client);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(5.1, Mortal, client);
	PrintToChat(client, "%t", "You are temporarily invulnerable!");
}

public Action Mortal(Handle timer, any client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client, "%t", "You are no longer invulnerable!");
	}
}

int TeleportClientTo(int client)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i) && IsNotFalling(i))
		{
			float pos[3];
			GetClientAbsOrigin(i, pos);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

bool IsNotFalling(int i)
{
	return GetEntProp(i, Prop_Send, "m_isHangingFromLedge") == 0 && GetEntProp(i, Prop_Send, "m_isFallingFromLedge") == 0 && (GetEntPropFloat(i, Prop_Send, "m_flFallVelocity") == 0 || GetEntPropFloat(i, Prop_Send, "m_flFallVelocity") < -100);
}

public Action PlayerJoin(Handle timer, any client) 
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != TEAM_SPECTATORS)
	{
		if (Played[client])
		{
			ChangeClientTeam(client, 1);
		}
		Join_Timer[client] = null; 
	}
	else
	{
		Join_Timer[client] = null;
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Played[i] = false;
	}
	
	IsTimeTeleport = false;
	CreateTimer(0.2, TimerTweak2);
	CreateTimer(90.5, TimeToTeleportNewClients);
}

public void Check_Bots(Handle event, const char[] name, bool dontBroadcast) {
    CreateTimer(35.0, BotsFix);
}


public Action BotsFix(Handle timer) {

if(SpawnFakeClientAndTeleport()) CreateTimer(3.0, BotsFix);//new
    
}

public Action TimerTweak2(Handle timer, any client)
{
	if (!map_start)
	{
		map_start = true;
		TweakSettings1();
	}
	return Plugin_Stop;
}

public Action TimeToTeleportNewClients(Handle timer, any client)
{
	IsTimeTeleport = true;
	ServerCommand("sm_cvar director_no_survivor_bots 0");

	return Plugin_Stop;
}

public Action Tweak(int client, int args)
{
	TweakSettings1();
}

stock int TweakSettings1()
{
	ConVar hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 25.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, GetConVarInt(hMaxSurvivors));
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000); // allow spawning bots at any time
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, true, 6.0);
}

stock int TweakSettings2()
{
	ConVar hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 4.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, GetConVarInt(hMinSurvivors));
}

//************************************************//

public Action JoinTeam(int client, int args)
{
//	if (!IsClientConnected(client)) return Plugin_Handled
	if (!IsClientInGame(client)) return Plugin_Handled;
	
	// Anti reconnect part
	if (Played[client])
	{
		char steamId[30];	
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	
		int disconnect_time = KvGetNum(g_kvDB, steamId, -1);
		if (disconnect_time == -1) Played[client] = false;
		
		int wait_time = disconnect_time + ar_time - GetTime();
		if (wait_time <= 0)
		{
			KvDeleteKey(g_kvDB, steamId);
			Played[client] = false;
		}
		else
		{
			Played[client] = true;
			Join_Timer[client] = CreateTimer(7.0, PlayerJoin, client);
			PrintHintText(client, "%t", "You are not allowed to reconnect for %d seconds", wait_time);
		}
		
		//PrintHintText(client, "%t", "Rejoin message")
		return Plugin_Handled;
	}
	else
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{	
				if (DispatchKeyValue(client, "classname", "player") == true)
				{
					PrintHintText(client, "%t", "You are allready joined the Survivor team");
				}
				else if ((DispatchKeyValue(client, "classname", "info_survivor_position") == true) && !IsAlive(client))
				{
					PrintHintText(client, "%t", "Please wait to be revived or rescued");
				}
			}
			else if (IsClientIdle(client))
			{
				PrintHintText(client, "%t", "You are now idle. Press mouse to play as survivor");
			}
			else
			{			
				if (TotalFreeBots() == 0)
				{	
					ChangeClientTeam(client, 2);
					CreateTimer(1.0, Timer_AutoJoinTeam, client);	
				}
				else TakeOverBot(client, false);
			}
		}
	}
	return Plugin_Handled;
}
////////////////////////////////////
// Events
////////////////////////////////////
public Action evtRoundStartAndItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	if (!gbFirstItemPickedUp)
	{
		// alternative to round start...
		if (timer_SpecCheck == null) timer_SpecCheck = CreateTimer(15.0, Timer_SpecCheck, _, TIMER_REPEAT);
		
		gbFirstItemPickedUp = true;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	//if (!gbPlayerPickedUpFirstItem[client] && !IsFakeClient(client))
	//if (IsClientInGame(client))
	if (client)
	{
		if (IsPlayerAlive(client))
		{
			if (!gbPlayerPickedUpFirstItem[client] && !IsFakeClient(client))
			{
				// force setting client cvars here...
				//ForceClientCvars(client)
				gbPlayerPickedUpFirstItem[client] = true;
				gbPlayedAsSurvivorBefore[client] = true;
			}
		}
	}
}

public Action evtPlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	/*if (!IsFakeClient(client) && !IsClientIdle(client))
	{	
		newMapActivatedPlayers++;
		
		int count;
		count = GetHumanInGamePlayerCount();
		
		if (count > 4 && newMapActivatedPlayers > 4 && (GetClientTeam(client) != TEAM_INFECTED || GetClientTeam(client) != TEAM_SURVIVORS || GetClientTeam(client) == TEAM_SPECTATORS)) // clientteam is fix for spawning too many bouts after map_transition
		{	
			if (!IsClientIdle(client))
			{
				CreateTimer(1.0 * GetRandomFloat(5.5, 10.5), Timer_AutoJoinTeam, client);
			}
		}
	}*/
	
	if (client)
	{
		if ((GetClientTeam(client) != TEAM_INFECTED) && (GetClientTeam(client) != TEAM_SURVIVORS) && !IsFakeClient(client) && !IsClientIdle(client))
			//CreateTimer(DELAY_CHANGETEAM_NEWPLAYER, Timer_AutoJoinTeam, client)
			CreateTimer(1.0 * GetRandomFloat(5.5, 10.5), Timer_AutoJoinTeam, client);
	}
}

/*GetHumanInGamePlayerCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (!IsFakeClient(i))
			{
				if (IsClientInGame(i))
				{
					count++;
				}
			}
		}
	}
	return count;
}*/

public Action evtPlayerLeftStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS) gbPlayedAsSurvivorBefore[client] = true;
		}
	}
}

public Action evtPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(0.5, ClientInServer, client);
		Join_Timer[client] = CreateTimer(5.0, PlayerJoin, client);
	}
	
	if (Played[client])
	{
		char steamId[30];	
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));		
		
		int disconnect_time = KvGetNum(g_kvDB, steamId, -1);
		if (disconnect_time == -1) Played[client] = false;
		
		int wait_time = disconnect_time + ar_time - GetTime();
		if (wait_time <= 0)
		{
			KvDeleteKey(g_kvDB, steamId);
			Played[client] = false;
		}
		else
		{
			Played[client] = true;
			PrintHintText(client, "%t", "You are not allowed to reconnect for %d seconds", wait_time);
		}
	}
	
	/*int newteam = event.GetInt("team")
	
	if (client)
	{
		if (!IsClientConnected(client)) return;
		if (!IsClientInGame(client) || IsFakeClient(client) || !IsAlive(client)) return;
		if (newteam == TEAM_INFECTED)
		{
			char PlayerName[100];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			PrintToChatAll("%t", "[MultiSlots] %s joined the Infected Team", PlayerName);
			giIdleTicks[client] = 0;
		}
	}*/
}

public Action ClientInServer(Handle timer, any client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{			
			if (!IsPlayerAlive(client))
			{
				SDKCall(hRoundRespawn, client);
			}	
			//BypassAndExecuteCommand(client, "give", "health");
		
			char GameMode[30];
			GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));		
			if (StrEqual(GameMode, "mutation3", false))
			{
				//SetEntityHealth(client, 1);
				//SetEntityTempHealth(client, 99);
			}
			else
			{
				//SetEntityHealth(client, 100);
				//SetEntityTempHealth(client, 0);			
			}	
			if (IsTimeTeleport) //PerformTeleport(client, target);
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				CreateTimer(5.1, Mortal, client);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i) && IsAlive(i) && i != client)
					{						
						// get the position coordinates of any active alive player
						float teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin);			
						TeleportEntity(client, teleportOrigin, NULL_VECTOR, NULL_VECTOR);					
						break;
					}
				}
			}
		}
	}
}

public Action evtPlayerReplacedBot(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if (!client) return;
	if (GetClientTeam(client) != TEAM_SURVIVORS || IsFakeClient(client)) return;
	if (!gbPlayedAsSurvivorBefore[client])
	{
		//ForceClientCvars(client)
		gbPlayedAsSurvivorBefore[client] = true;
		giIdleTicks[client] = 0;
		
		/*BypassAndExecuteCommand(client, "give", "health");
		
		char GameMode[30];
		GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));		
		if (StrEqual(GameMode, "mutation3", false))
		{
			//SetEntityHealth(client, 1);
			//SetEntityTempHealth(client, 99);
		}
		else
		{
			//SetEntityHealth(client, 100);
			//SetEntityTempHealth(client, 0);			
		}*/
		
		char PlayerName[100];
		GetClientName(client, PlayerName, sizeof(PlayerName));
//		PrintToChatAll("\x01[\x04MultiSlots\x01] %s присоединился к выжившим", PlayerName);
	}
}

public Action evtSurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{	
		StripWeapons(client);
		BypassAndExecuteCommand(client, "give", "pistol");
	}
}

public Action evtFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if ((GetClientTeam(i) == TEAM_SURVIVORS) && IsAlive(i))
			{
				SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY, 1);
				float newOrigin[3] = { 0.0, 0.0, 0.0 };
				TeleportEntity(i, newOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_YES, 1);
			}
		}
	}	
	StopTimers();
	gbVehicleLeaving = true;
}

public Action evtMissionLost(Event event, const char[] name, bool dontBroadcast)
{
	gbFirstItemPickedUp = false;
}

public Action evtBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (GetClientTeam(bot) == TEAM_SURVIVORS) CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, bot);
}
////////////////////////////////////
// timers
////////////////////////////////////
public Action Timer_SpawnTick(Handle timer)
{
	int iTotalSurvivors = TotalSurvivors();
	if (iTotalSurvivors >= 4)
	{
		timer = null;	
		return Plugin_Stop;
	}
	for(; iTotalSurvivors < 4; iTotalSurvivors++) SpawnFakeClient();
	return Plugin_Continue;
}

public Action Timer_SpecCheck(Handle timer)
{
	if (gbVehicleLeaving) return Plugin_Stop;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if ((GetClientTeam(i) == TEAM_SPECTATORS) && !IsFakeClient(i))
			{
				if (!IsClientIdle(i))
				{
					char PlayerName[100];
					GetClientName(i, PlayerName, sizeof(PlayerName));	
					//PrintToChat(i, "%t", "[MultiSlots] %s, type to !join the Survivor Team", PlayerName);
					PrintHintText(i, "%t", "%s, press USE (E) to join the Survivor Team", PlayerName);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_AutoJoinTeam(Handle timer, any client)
{
//	if (!IsClientConnected(client)) return Plugin_Stop
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	else
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS) return Plugin_Stop;
		if (IsClientIdle(client)) return Plugin_Stop;
		
		JoinTeam(client, 0);
	}
	return Plugin_Continue;
}

public Action Timer_KickNoNeededBot(Handle timer, any bot)
{
	if ((TotalSurvivors() <= 4)) return Plugin_Handled;
	if (IsClientConnected(bot) && IsClientInGame(bot))
	{
		if (GetClientTeam(bot) == TEAM_INFECTED) return Plugin_Handled;
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));				
		if (StrEqual(BotName, "FakeClient", true)) return Plugin_Handled;
		if (!HasIdlePlayer(bot))
		{
			StripWeapons(bot);
			KickClient(bot, "Kicking No Needed Bot");
		}
	}
	
	//ServerCommand("sm_kickextrabots");
	
	return Plugin_Handled;
}

public Action Timer_KickFakeBot(Handle timer, any fakeclient)
{
	if (IsClientConnected(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");		
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}
////////////////////////////////////
// stocks
////////////////////////////////////
stock int TakeOverBot(int client, bool completely)
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) == TEAM_SURVIVORS) return;
	if (IsFakeClient(client)) return;
	
	int bot = FindBotToTakeOver();
	if (bot==0)
	{
		PrintHintText(client, "No survivor bots to take over.");
		return;
	}
	
	static Handle hSetHumanSpec;
	if (hSetHumanSpec == null)
	{
		Handle hGameConf;		
		hGameConf = LoadGameConfigFile("l4dmultislots");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	}
	
	static Handle hTakeOverBot;
	if (hTakeOverBot == null)
	{
		Handle hGameConf;		
		hGameConf = LoadGameConfigFile("l4dmultislots");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
	}
	
	if (completely)
	{
		SDKCall(hSetHumanSpec, bot, client);
		SDKCall(hTakeOverBot, client, true);
	}
	else
	{
		SDKCall(hSetHumanSpec, bot, client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	}
	return;
}

stock int FindBotToTakeOver()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i))
			{
				if (IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsAlive(i) && !HasIdlePlayer(i)) return i;
			}
		}
	}
	return 0;
}

stock int SetEntityTempHealth(int client, int hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	int float newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock int BypassAndExecuteCommand(int client, char[] strCommand, char[] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

stock int StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 3; x++)
	{
		if ((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			RemoveEdict(itemIdx);
		}
	}
}

/*
stock int ForceClientCvars(int client)
{
ClientCommand(client, "cl_glow_item_far_r 0.0")
ClientCommand(client, "cl_glow_item_far_g 0.7")
ClientCommand(client, "cl_glow_item_far_b 0.2")
}*/

stock int TotalSurvivors() // total bots, including players
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS)) l++;
		}
	}
	return l;
}

stock int TotalRealPlayers()
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i))
			{
				if (!IsFakeClient(i)) l++;
			}
		}
	}
	return l;
}

stock int HumanConnected()
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(bot))
		{
			if (!IsFakeClient(i)) l++;
		}
	}
	return l;
}

stock int TotalFreeBots() // total bots (excl. IDLE players)
{
	int l = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				if (!HasIdlePlayer(i)) l++;
			}
		}
	}
	return l;
}

stock bool HasIdlePlayer(int bot)
{
	if (IsValidEntity(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if (strcmp(sNetClass, "SurvivorBot") == 0)
		{
			if (!GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
				return false;

			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
			if (client)
			{
				// Do not count bots
				// Do not count 3rd person view players
				if (IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVORS)) return true;
			}
			else return false;
		}
	}
	return false;
}

stock int StopTimers()
{
	/*if (timer_SpawnTick != null)
	{
		KillTimer(timer_SpawnTick);
		timer_SpawnTick = null;
	}*/
	if (timer_SpecCheck != null)
	{
		KillTimer(timer_SpecCheck);
		timer_SpecCheck = null;
	}	
}

bool SpawnFakeClient()
{
	int ClientsCount = GetClientCount(false);
	
	bool fakeclientKicked = false;
	
	// create fakeclient
	int fakeclient = 0;
	if (ClientsCount < 31)
	{
		fakeclient = CreateFakeClient("FakeClient");
	}
	
	// if entity is valid
	if (fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		// check if entity classname is survivorbot
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(fakeclient) == true)
			{	
				// kick the fake client to make the bot take over
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}			
		// if something went wrong, kick the created FakeClient
		if (fakeclientKicked == false) KickClient(fakeclient, "Kicking FakeClient");
	}	
	return fakeclientKicked;
}

bool SpawnFakeClientAndTeleport()
{
	int ClientsCount = GetClientCount(false);
	int bots = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsValidSurvivorBot(i))
		{
			bots ++;
		}
	}
	
	bool fakeclientKicked = false;
	
	// create fakeclient
	int fakeclient = 0;
	
	if (ClientsCount < 31 && bots < 3)
	{
		fakeclient = CreateFakeClient("FakeClient");
	}
	
	// if entity is valid
	if (fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		// check if entity classname is survivorbot
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(fakeclient) == true)
			{
				// teleport client to the position of any active alive player
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i) && IsAlive(i) && i != fakeclient)
					{						
						// get the position coordinates of any active alive player
						float teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin);			
						TeleportEntity(fakeclient, teleportOrigin, NULL_VECTOR, NULL_VECTOR);					
						break;
					}
				}
				
				StripWeapons(fakeclient);
				BypassAndExecuteCommand(fakeclient, "give", "pistol");
				
				// kick the fake client to make the bot take over
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}			
		// if something went wrong, kick the created FakeClient
		if (fakeclientKicked == false) KickClient(fakeclient, "Kicking FakeClient");
	}	
	return fakeclientKicked;
}

bool IsClientIdle(int client)
{
	char sNetClass[12];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if ((GetClientTeam(i) == TEAM_SURVIVORS) && IsPlayerAlive(i))
			{
				if (IsFakeClient(i))
				{
					GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
					if (strcmp(sNetClass, "SurvivorBot") == 0)
					{
						if (GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client) return true;
					}
				}
			}
		}
	}
	return false;
}

bool IsAlive(int client)
{
	if (!GetEntProp(client, Prop_Send, "m_lifeState")) return true;
	return false;
}

stock bool IsValidSurvivorBot(int client)
{
	if (!client) return false;
	if (!IsClientInGame(client)) return false;
	if (!IsFakeClient(client)) return false;
	if (GetClientTeam(client) != TEAM_SURVIVORS) return false;
	return true;
}

/*
bool IsNobodyAtStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if ((GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i) && IsAlive(i))
			{
				decl Float:vecLocationPlayer[3]
				GetClientAbsOrigin(i, vecLocationPlayer)
				if (GetVectorDistance(vecLocationStart, vecLocationPlayer, false) < 750) return false
			}
		}
	}
	return true
}*/

//************************************************//
//********     ANTI RECONNECT PART    ************//
//************************************************//

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	char reason[128];
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client) return;
	Played[client] = false;
	GetEventString(event, "reason", reason, 128);
	if (StrEqual(reason, "Disconnect by user.") || !ar_disconnect_by_user_only)
	{
		if (isLAN || ar_time == 0 || IsFakeClient(client)) return;
		if (GetUserFlagBits(client) && ar_admin_immunity) return;
		
		char steamId[30];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));	
		KvSetNum(g_kvDB, steamId, GetTime());
	}
}

public void OnCVarChange(Handle convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

public void OnConfigsExecuted()
{
	GetCVars();
}

public Action GetCVars()
{
	isLAN = GetConVarBool(cvar_lan);
	ar_time = GetConVarInt(cvar_ar_time);
	ar_disconnect_by_user_only = GetConVarBool(cvar_ar_disconnect_by_user_only);
	ar_admin_immunity = GetConVarBool(cvar_ar_admin_immunity);
}

stock int GetRandomClientLive(bool bot = false, bool alive = false, int team = 0) 
{ 
	int count = 0, players[MaxClients]; 
	for (int i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && bot == IsFakeClient(i) && alive == IsPlayerAlive(i) && !(team > 0 && team != GetClientTeam(i))) 
		{ 
			players[count++] = i; 
		} 
	} 
	return count > 0 ? players[GetRandomInt(0, count - 1)] : -1; 
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	if ((TotalRealPlayers() <= 10)) return Plugin_Handled;
	ServerCommand("sm_cvar director_no_survivor_bots 1");
	//SetConVarInt(FindConVar("director_no_survivor_bots"), 1, false, false);
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsValidPlayer(client)) return;
	if (buttons & IN_USE)
	{
		JoinTeam(client, 0);
	}  
}

int IsValidPlayer(int client)
{
	if (client == 0) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client) != TEAM_SPECTATORS) return false;
	return true;
}