#pragma semicolon 1                 // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>

#pragma newdecls required;			// Force new style syntax.

// l4dt native (for lobby unreserve)
native bool L4D_LobbyUnreserve();

// l4dt forward (to add more SI bots)
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define PLUGIN_VERSION		"1.8.10"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define TEAM_NEUTRAL	4

#define ZOMBIE_SMOKER	1
#define ZOMBIE_BOOMER	2
#define ZOMBIE_HUNTER	3
#define ZOMBIE_SPITTER	4
#define ZOMBIE_JOCKEY	5
#define ZOMBIE_CHARGER	6

char gameMode[16];
char gameName[16];
bool L4D1;

ConVar SurvivorLimit;
ConVar InfectedLimit;
ConVar L4DInfectedLimit;
ConVar ExtraFirstAid;
ConVar KillRes;
ConVar RespawnJoin;
ConVar MoreSiBotsVersus;

ConVar AutoDifficulty;
ConVar TankHpMulti;
ConVar SiHpMulti;
ConVar CiSpMulti;
ConVar SiSpMore;

Handle MedkitTimer    				= null;
Handle TeamPanelTimer[MAXPLAYERS+1]	= null;
Handle SubDirector					= null;
Handle BotsUpdateTimer    			= null;
Handle DifficultyTimer              = null;

bool MedkitsGiven = false;
bool RoundStarted = false;
int MaxSpecials = 2;

char SteamIDs[100][64];
int SteamPos = 0;

public Plugin myinfo =
{
	name        = "Super Versus Reloaded",
	author      = "DDRKhat, Marcus101RR, and Merudo",
	description = "Allows up to 32 players on Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=2398283#post2398283"
}

// *********************************************************************************
// METHODS FOR GAME START & END
// *********************************************************************************
public void OnPluginStart()
{
	FindConVar("mp_gamemode").GetString(gameMode, sizeof(gameMode));
	GetGameFolderName(gameName, sizeof(gameName));
	L4D1 = StrEqual(gameName, "left4dead", false);

	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", CVAR_FLAGS);
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS,true, 1.00, true, 24.00);
	InfectedLimit = CreateConVar("l4d_infected_limit", "4", "Max amount of infected (will not affect bots)", CVAR_FLAGS, true, 4.00, true, 24.00);
	KillRes = CreateConVar("l4d_killreservation","1","Should we clear Lobby reservation? (For use with Left4DownTown extension ONLY)", CVAR_FLAGS,true,0.0,true,1.0);
	ExtraFirstAid = CreateConVar("l4d_extra_first_aid", "1" , "Allow extra first aid kits for extra players. 0: No extra kits. 1: one extra kit per player above four", CVAR_FLAGS, true, 0.0, true, 1.0);
	RespawnJoin = CreateConVar("l4d_respawn_on_join", "1" , "Respawn alive when joining as an extra survivor? 0: No, 1: Yes (first time only)", CVAR_FLAGS, true, 0.0, true, 1.0);
	MoreSiBotsVersus =  CreateConVar("l4d_versus_si_more", "0" , "If less infected players than l4d_infected_limit in versus/scavenge, spawn SI bots?", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	AutoDifficulty = CreateConVar("director_auto_difficulty", "0", "Change Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	TankHpMulti    = CreateConVar("director_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	SiHpMulti      = CreateConVar("director_si_hpmulti","0.00","SI HP Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	CiSpMulti      = CreateConVar("director_ci_multi","0.25","Infected spawning rate Multiplier (multi*(survivors-4)). Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.00,true,1.00);
	SiSpMore       = CreateConVar("director_si_more","1","In coop, spawn 1 more SI per extra player? Requires director_auto_difficulty 1", CVAR_FLAGS,true,0.0,true,1.0);

	SetConVarBounds(L4DInfectedLimit, ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);

	RegConsoleCmd("sm_join", Join_Game, "Join Survivor Team (If dead, takeover bot)");	
	RegConsoleCmd("sm_survivor", Join_Survivor, "Join Survivor Team (If Bot Available)");	
	RegConsoleCmd("sm_infected", Join_Infected, "Join Infected Team");
	RegConsoleCmd("sm_spectate", Join_Spectator, "Join Spectator Team");
	RegConsoleCmd("sm_afk", Join_Spectator, "Join Spectator Team");	
	RegConsoleCmd("sm_teams", TeamMenu, "Opens Team Panel with Selection");
	RegConsoleCmd("sm_changeteam", TeamMenu, "Opens Team Panel with Selection");
	RegAdminCmd("sm_createplayer", Create_Player, ADMFLAG_CONVARS, "Create Survivor Bot");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_left_checkpoint", Event_PlayerLeftStartArea, EventHookMode_Post);

	AddCommandListener(Cmd_spec_next, "spec_next");

	AutoExecConfig(true, "l4d_superversus");	
}


public void FIL (Handle c, const char[] o, const char[] n) { L4DInfectedLimit.IntValue = InfectedLimit.IntValue; } 

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){MarkNativeAsOptional("L4D_LobbyUnreserve"); return APLRes_Success;}

// ------------------------------------------------------------------------
// Return true if lobby unreserve is supported
// ------------------------------------------------------------------------
bool l4dt() { if(FindConVar("left4downtown_version").FloatValue> 0.00) return true; else return false;}  // Is Left 4 Downtown 1/2 loaded?

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public void OnMapEnd()
{
	OnGameEnd();
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundStarted = false;
	OnGameEnd();
}

// ------------------------------------------------------------------------
//  Clean up the timers at the game end
// ------------------------------------------------------------------------
void OnGameEnd()
{
	delete SubDirector;
	delete MedkitTimer;
	delete BotsUpdateTimer;
	delete DifficultyTimer;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		delete TeamPanelTimer[i];
	}
	
	// Reset array SteamIDs, so previous players who join next round can respawn alive
	for (int i = 0; i < sizeof(SteamIDs); i++){SteamIDs[i] = "None";}
}

// ------------------------------------------------------------------------
// Event_RoundStart()
// ------------------------------------------------------------------------
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	MedkitsGiven = false;
	RoundStarted = true;
}

// ------------------------------------------------------------------------
//  MedKit timer. Used to spawn extra medkits in safehouse
// ------------------------------------------------------------------------
public Action timer_SpawnExtraMedKit(Handle hTimer)
{
	MedkitTimer = null;

	int client = GetAnyAliveSurvivor();
	int amount = GetSurvivorTeam() - 4;
	
	if(amount > 0 && client > 0)
	{
		for(int i = 1; i <= amount; i++)
		{
			CheatCommand(client, "give", "first_aid_kit", "");
		}
	}
}

// ------------------------------------------------------------------------
// FinaleEnd() Thanks to Damizean for smarter method of detecting safe survivors.
// ------------------------------------------------------------------------
public void Event_FinaleVehicleLeaving(Handle event, const char[] name, bool dontBroadcast)
{
	int edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		float pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		for(int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1) continue;
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

// *********************************************************************************
// METHODS RELATED TO PLAYER/BOT SPAWN AND KICK
// *********************************************************************************

// ------------------------------------------------------------------------
//  Each time a survivor spawns, setup timer to kick / spawn bots a bit later
// ------------------------------------------------------------------------
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Each time a new survivor spawns, check difficulty & record steam id (to prevent free respawning)
	if (GetClientTeam(client) == TEAM_SURVIVOR)
	{
		// Reset the bot check timer, if one exists	
		delete BotsUpdateTimer;
		BotsUpdateTimer = CreateTimer(2.0, timer_BotsUpdate);
		
		if (!IsFakeClient(client) && !AreInfectedAllowed() && IsFirstTime(client))
			RecordSteamID(client); // Record SteamID of player. 
	}
}

// ------------------------------------------------------------------------
// If player disconnect, set timer to spawn/kick bots as needed
// ------------------------------------------------------------------------
public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client) || RoundStarted != true)        // if bot or during transition
		return;

	delete TeamPanelTimer[client];           // Clean up Panel timer

	// Reset the timer, if one exists
	delete BotsUpdateTimer;
	BotsUpdateTimer = CreateTimer(1.0, timer_BotsUpdate); // re-update the bots
}

// ------------------------------------------------------------------------
// Bots are kicked/spawned after every survivor spawned and every player joined
// ------------------------------------------------------------------------
public Action timer_BotsUpdate(Handle hTimer)
{
	BotsUpdateTimer = null;

	if (AreAllInGame() == true)
	{
		// Update the bots
		SpawnCheck();
		
		// Give medkit (start of round)
		if(MedkitTimer == null && !MedkitsGiven && ExtraFirstAid.BoolValue)
		{
			MedkitsGiven = true;
			MedkitTimer = CreateTimer(2.0, timer_SpawnExtraMedKit);
		}
		
		// Update the difficulty
		delete DifficultyTimer;
		if(AutoDifficulty.BoolValue) DifficultyTimer = CreateTimer(5.0, timer_Difficulty);
	}
	else
	{
		BotsUpdateTimer = CreateTimer(1.0, timer_BotsUpdate);  // if not everyone joined, delay update
	}
}

// ------------------------------------------------------------------------
// Check the # of survivors, and kick/spawn bots as needed
// ------------------------------------------------------------------------
void SpawnCheck()
{
	if(RoundStarted != true)  return;      // if during transition, don't do anything
	
	int iSurvivor       = GetSurvivorTeam();
	int iHumanSurvivor  = AreInfectedAllowed() ? GetTeamPlayers(TEAM_SURVIVOR, false) : GetHumanCount();  // survivors excluding bots but including idles. If coop, counts spectators too (may be idles)
	int iSurvivorLim    = SurvivorLimit.IntValue;
	int iSurvivorMax    = iHumanSurvivor  >  iSurvivorLim ? iHumanSurvivor  : iSurvivorLim ;
	
	// iSurvivorMax is the maximum # of survivor we allow - we never kick human survivors
	
	if (iSurvivor > iSurvivorMax) PrintToConsoleAll("SuperVersus - Kicking %d bot(s)", iSurvivor - iSurvivorMax);
	if (iSurvivor < iSurvivorLim) PrintToConsoleAll("SuperVersus - Spawning %d bot(s)", iSurvivorLim - iSurvivor);

	for(; iSurvivorMax < iSurvivor; iSurvivorMax++)
	{
		KickUnusedSurvivorBot();
	}
	
	for(; iSurvivor < iSurvivorLim; iSurvivor++)
	{
		SpawnFakeSurvivorClient();  // This triggers Event_PlayerSpawn and create new timer, be careful about infinite loops
	}
}

// ------------------------------------------------------------------------
// Kick an unused survivor bot
// ------------------------------------------------------------------------
void KickUnusedSurvivorBot()
{
	int Bot = GetAnyValidSurvivorBot();
	if(Bot > 0 && IsBotValid(Bot))
		KickClient(Bot, "Kicking Useless Client.");
}

// ------------------------------------------------------------------------
// Spawn a survivor bot
// ------------------------------------------------------------------------
void SpawnFakeSurvivorClient()
{
	// Spawn bot survivor.
	int Bot = CreateFakeClient("SurvivorBot");
	if(Bot == 0)
		return;

	ChangeClientTeam(Bot, TEAM_SURVIVOR);
	if(DispatchKeyValue(Bot, "classname", "SurvivorBot") == false)
	{
		return;
	}
	DispatchSpawn(Bot);
	if(DispatchSpawn(Bot) == false)
	{
		return;
	}

	// Kick the "SurvivorBot" so it becomes a regular bot
	if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
		KickClient(Bot, "Kicking Fake Client.");
}


// ------------------------------------------------------------------------
// If lobby full, unreserve it. Autojoin survivors if coop & spectator
// ------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client)
{
	// If lobby is full, KillRes is true and l4dt is present, unreserve lobby
	if(KillRes.BoolValue && IsServerLobbyFull() && l4dt())
	{
		L4D_LobbyUnreserve();
	}
	
	if (IsFakeClient(client)) return;
	
	if (GetClientTeam(client) <= TEAM_SPECTATOR) // non-bot spectator or not in a team
	{
		CreateTimer(5.0, Timer_AutoJoinTeam, client);  //  Autojoin
	}
}

// ------------------------------------------------------------------------
// If connect as spectator, either auto-join survivor or show team menu
// ------------------------------------------------------------------------
public Action Timer_AutoJoinTeam(Handle timer, int client)
{
	// If joined the game already or not valid, don't do anything
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) > TEAM_SPECTATOR || IsClientIdle(client)) return;
	
	if (BotsUpdateTimer != null || !RoundStarted || !AreAllInGame() || GetClientTeam(client) == 0)
	{
		CreateTimer(1.0, Timer_AutoJoinTeam, client); // if during transition, delay autojoin
	}
	else
	{
		if (!AreInfectedAllowed()) FakeClientCommand(client, "sm_join");  // Autojoin survivors
		else FakeClientCommand(client, "sm_teams"); // Show team selection menu if infected are available
	}
}
// ------------------------------------------------------------------------
// Stores the Steam ID, so if reconnect we don't allow free respawn
// ------------------------------------------------------------------------
void RecordSteamID(int client)
{
	// Stores the Steam ID, so if reconnect we don't allow free respawn
	char SteamID[64];
	bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	if (valid)
	{
		SteamIDs[SteamPos] = SteamID;
		SteamPos = SteamPos + 1;
		if (SteamPos == 100) SteamPos = 0;
	}
}
// *********************************************************************************
// COMMANDS FOR JOINING TEAMS
// *********************************************************************************

// ------------------------------------------------------------------------
// If press left mouse button as spectator, join the game. Useful in case of idle bug
// ------------------------------------------------------------------------
public Action Cmd_spec_next(int client, char[] command, int argc)
{
	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR && !IsClientIdle(client))
	{
		if (AreInfectedAllowed()) FakeClientCommand(client, "sm_teams");
		else FakeClientCommand(client, "sm_join");	
	}
	return Plugin_Continue;	
}

// ------------------------------------------------------------------------
// If press any button as spectator, join the game. Useful in case of idle bug
// ------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR && !IsClientIdle(client))
	{
		if (AreInfectedAllowed()) FakeClientCommand(client, "sm_teams");
		else FakeClientCommand(client, "sm_join");	
	}
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// Join survivor, but may create a bot / take over a bot
// ------------------------------------------------------------------------
public Action Join_Game(int client, int args)
{
	if(!IsClientInGame(client)) return Plugin_Handled;
	
	if(GetClientTeam(client) != TEAM_SURVIVOR && !IsClientIdle(client))
	{
		if(CountAvailableBots(TEAM_SURVIVOR) == 0 && !AreInfectedAllowed())
		{
			bool canRespawn = (RespawnJoin.BoolValue && IsFirstTime(client)) ;
			
			ChangeClientTeam(client, TEAM_SURVIVOR);  // Add extra survivor. Triggers player_spawn, which makes IsFirstTime false
			
			if (!IsPlayerAlive(client) && !IsClientIdle(client) && canRespawn)
			{
				Respawn(client);
				TeleportToSurvivor(client);
				
				GiveAverageWeapon(client);				
				if(ExtraFirstAid.BoolValue && MedkitsGiven && MedkitTimer == null) // if medkits already given				
					CheatCommand(client, "give", "first_aid_kit", "");
			} else if (!IsPlayerAlive(client) && !IsClientIdle(client) && RespawnJoin.BoolValue)
			{
				PrintToChat(client, "\x01You already played on the \x04Survivor Team\x01 this round. You will spawn dead.");
			}
		}
		else
		{
			FakeClientCommand(client,"jointeam 2");
		}
	}
	if(GetClientTeam(client) == TEAM_SURVIVOR)
	{		
		if(IsPlayerAlive(client) == true)
		{
			PrintToChat(client, "\x01You are on the \x04Survivor Team\x01.");
		}
		else if(IsPlayerAlive(client) == false && CountAvailableBots(TEAM_SURVIVOR) != 0)  // Takeover a bot
		{
			ChangeClientTeam(client, TEAM_SPECTATOR);
			FakeClientCommand(client,"jointeam 2");
		}
		else if(IsPlayerAlive(client) == false && CountAvailableBots(TEAM_SURVIVOR) == 0)
		{
			PrintToChat(client, "\x01You are \x04Dead\x01. No \x05Bot(s) \x01Available.");
		}
	}
	return Plugin_Handled;
}

public Action Join_Spectator(int client, int args)
{
	ChangeClientTeam(client,TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action Join_Survivor(int client, int args)
{
	FakeClientCommand(client,"jointeam 2");
	return Plugin_Handled;
}

public Action Join_Infected(int client, int args)
{
	if( !AreInfectedAllowed() && !CheckCommandAccess( client, "", ADMFLAG_CHEATS, true ) )   
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is not available in %s.", gameMode);
	}
	else if(InfectedLimit.IntValue <= GetTeamPlayers(TEAM_INFECTED, false))
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is Full.");
	}	
	else
	{
		ChangeClientTeam(client,TEAM_INFECTED);
	}
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Create a bot. Useful if less bots than SurvivorLimit because the later got increased
// ------------------------------------------------------------------------
public Action Create_Player(int client, int args)
{
	char arg[MAX_NAME_LENGTH];
	if (args > 0)
	{
		GetCmdArg(1, arg, sizeof(arg));	
		PrintToChatAll("Player %s has joined the game", arg);	
		CreateFakeClient(arg);
	}
	else
	{
		int Bot = CreateFakeClient("SurvivorBot");
		if(Bot == 0)
			return Plugin_Handled;

		ChangeClientTeam(Bot, TEAM_SURVIVOR);
		if (!DispatchKeyValue(Bot, "classname", "survivorbot"))
			return Plugin_Handled;
			
		if (!DispatchSpawn(Bot))
			return Plugin_Handled; // if dispatch failed		

		if(!IsPlayerAlive(Bot))
			Respawn(Bot);

		TeleportToSurvivor(Bot);
		GiveAverageWeapon(Bot);
		
		if(ExtraFirstAid.BoolValue)				
			CheatCommand(Bot, "give", "first_aid_kit", "");
					
		if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
			KickClient(Bot, "Kicking Fake Client.");

	}
	return Plugin_Handled;
}

// *********************************************************************************
// RETURN PROPERTIES OF INFECTED/SURVIVOR TEAMS, BOTS, & PLAYERS
// *********************************************************************************

char survivor_only_modes[23][] =
{
	"coop", "realism", "survival",
	"m60s", "hardcore", "l4d1coop",
	"mutation1",	"mutation2",	"mutation3",	"mutation4",
	"mutation5",	"mutation6",	"mutation7",	"mutation8",
	"mutation9",	"mutation10",	"mutation16",	"mutation17", "mutation20",
	"community1",	"community2",	"community4",	"community5"
};

// ------------------------------------------------------------------------
// Returns true if players in team infected are allowed
// ------------------------------------------------------------------------
bool AreInfectedAllowed()
{	
	for (int i = 0; i < sizeof(survivor_only_modes); i++)
	{
		if (StrEqual(gameMode, survivor_only_modes[i], false))
		{
			return false;
		}
	}
	return true;   // includes versus, realism versus, scavenge, & some mutations
}

// ------------------------------------------------------------------------
// Returns true if all connected players are in the game
// ------------------------------------------------------------------------
bool AreAllInGame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			if (!IsClientInGame(i)) return false;
		}
	}
	return true;
}

// ------------------------------------------------------------------------
// Returns true if lobby full. Used to unreserve the lobby
// ------------------------------------------------------------------------
bool IsServerLobbyFull()
{
	int humans = GetHumanCount();

	if (humans >= 8) return true;
	if( !AreInfectedAllowed() && humans >= 4) return true;
	return false;
}

// ------------------------------------------------------------------------
// Returns true if client never connected this game. Used to allow 1 free spawn
// ------------------------------------------------------------------------
bool IsFirstTime(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) return false;
		
	char SteamID[64];
	bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));		
	
	if (valid == false) return false;

	for (int i = 0; i < sizeof(SteamIDs); i++)
	{
		if (StrEqual(SteamID, SteamIDs[i], false))
		{
			return false;
		}
	}
	return true;
}

// ------------------------------------------------------------------------
// Returns true if survivor bot has idle player
// ------------------------------------------------------------------------
bool HasIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(IsFakeClient(bot) && strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
					return true;
			}
		}
	}
	return false;
}

// ------------------------------------------------------------------------
// Returns true if survivor player is idle.
// ------------------------------------------------------------------------
bool IsClientIdle(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
        		int spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
        		int spectator_client = GetClientOfUserId(spectator_userid);
        
			if(spectator_client == client)
				return true;
		}
	}
	return false;
}

// ------------------------------------------------------------------------
// Get the number of players on the team (includes idles)
// includeBots == true : counts bots
// ------------------------------------------------------------------------
int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if(IsFakeClient(i) && !includeBots && !HasIdlePlayer(i))
				continue;
			players++;
		}
	}
	return players;
}

// ------------------------------------------------------------------------
// Get the number of survivors on the team, including bots
// ------------------------------------------------------------------------
int GetSurvivorTeam()
{
	return GetTeamPlayers(TEAM_SURVIVOR, true);
}

int GetHumanCount()
{
	int humans = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
			humans++;
	}
	return humans;
}

// ------------------------------------------------------------------------
// Is the bot valid? (either survivor or infected)
// ------------------------------------------------------------------------
bool IsBotValid(int client)
{
	if(IsClientInGame(client) && IsFakeClient(client) && !HasIdlePlayer(client) && !IsClientInKickQueue(client))
		return true;
	return false;
}

// ------------------------------------------------------------------------
// Get any valid survivor bot (may be dead). Last bot created is found first
// ------------------------------------------------------------------------
int GetAnyValidSurvivorBot()
{
	for(int i = MaxClients ; i >= 1; i--)  // kick bots in reverse order they have been spawned
	{
		if (IsBotValid(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			return i;
	}
	return -1;
}

// ------------------------------------------------------------------------
// Check if how many alive bots without an idle are available in a team
// ------------------------------------------------------------------------
int CountAvailableBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
					num++;
	}
	return num;
}

// ------------------------------------------------------------------------
// Check if how many bots are in a team without idle. Can be dead
// ------------------------------------------------------------------------
stock int CountBots(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && GetClientTeam(i) == team)
					num++;
	}
	return num;
}

int GetAnyValidClient()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) )
			return i;
	} 
	return -1;
}

int GetAnyAliveSurvivor()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientInKickQueue(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return -1;
}

// *********************************************************************************
// TEAM MENU
// *********************************************************************************

public Action TeamMenu(int client, int args)
{
	if(TeamPanelTimer[client] == null)
	{
		DisplayTeamMenu(client);
	}
	return Plugin_Handled;
}

void DisplayTeamMenu(int client)
{
	Handle TeamPanel = CreatePanel();

	SetPanelTitle(TeamPanel, "SuperVersus Team Panel");

	char title_spectator[32];
	Format(title_spectator, sizeof(title_spectator), "Spectator (%d)", GetTeamPlayers(TEAM_SPECTATOR, false));
	DrawPanelItem(TeamPanel, title_spectator);
		
	// Draw Spectator Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATOR)
		{
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			Format(text_client, sizeof(text_client), "%s", ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	char title_survivor[32];
	Format(title_survivor, sizeof(title_survivor), "Survivors (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_SURVIVOR, false), SurvivorLimit.IntValue, CountAvailableBots(TEAM_SURVIVOR));
	DrawPanelItem(TeamPanel, title_survivor);
	
	// Draw Survivor Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];

			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			char m_iHealth[MAX_TARGET_LENGTH];
			if(IsPlayerAlive(i))
			{
				if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				{
					Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
				}
				else if(GetEntProp(i, Prop_Send, "m_currentReviveCount") == FindConVar("survivor_max_incapacitated_count").IntValue)
				{
					Format(m_iHealth, sizeof(m_iHealth), "BLWH - ");
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetClientRealHealth(i));
				}
	
			}
			else
			{
				Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
			}

			Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			DrawPanelText(TeamPanel, text_client);
		}
	}

	char title_infected[32];
	if (GetClientTeam(client) != TEAM_INFECTED && !AreInfectedAllowed())
	{
		if (SiSpMore.BoolValue && AutoDifficulty.BoolValue && l4dt())
			Format(title_infected, sizeof(title_infected), "Infected - Max %d Bot(s)", MaxSpecials);  // doesn't show how many bots are alive, but show max bots
		else Format(title_infected, sizeof(title_infected), "Infected");  // don't show max bots if not known
	}
	else if (GetClientTeam(client) != TEAM_INFECTED && AreInfectedAllowed())
		Format(title_infected, sizeof(title_infected), "Infected (%d/%d)", GetTeamPlayers(TEAM_INFECTED, false), InfectedLimit.IntValue);  // doesn't show how many bots are alive
	else
		Format(title_infected, sizeof(title_infected), "Infected (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_INFECTED, false), InfectedLimit.IntValue, CountAvailableBots(TEAM_INFECTED));
	
	DrawPanelItem(TeamPanel, title_infected);
		
	// Draw Infected Group
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if (GetClientTeam(client) != TEAM_INFECTED && IsFakeClient(i)) continue ;    // Don't show anything about infected bots to survivors
		
			char text_client[32];
			char ClientUserName[MAX_TARGET_LENGTH];
			
			GetClientName(i, ClientUserName, sizeof(ClientUserName));
			ReplaceString(ClientUserName, sizeof(ClientUserName), "[", "");

			if (GetClientTeam(client) == TEAM_INFECTED) // Only show HP of infected to infected
			{
				char m_iHealth[MAX_TARGET_LENGTH];
				if(IsPlayerAlive(i))
				{
					if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
					{
						Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
					}
					if(GetEntProp(i, Prop_Send, "m_isGhost"))
					{
						Format(m_iHealth, sizeof(m_iHealth), "GHOST - ");
					}
					else
					{
						Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetEntData(i, FindDataMapOffs(i, "m_iHealth"), 4));
					}
				}
				else
				{
					Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
				}
				Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
			}
			else Format(text_client, sizeof(text_client), "%s", ClientUserName);
			
			DrawPanelText(TeamPanel, text_client);
		}
	}

	DrawPanelItem(TeamPanel, "Close");
		
	SendPanelToClient(TeamPanel, client, TeamMenuHandler, 30);
	CloseHandle(TeamPanel);
	TeamPanelTimer[client] = CreateTimer(1.0, timer_TeamMenuHandler, client);
}

public int TeamMenuHandler(Handle UpgradePanel, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			FakeClientCommand(client, "sm_spectate");
		}
		else if(param2 == 2)
		{
			FakeClientCommand(client, "sm_join");
		}
		else if(param2 == 3)
		{
			FakeClientCommand(client, "sm_infected");
		}
		else if(param2 == 4)
		{
			delete TeamPanelTimer[client];
		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public Action timer_TeamMenuHandler(Handle hTimer, int client)
{
	DisplayTeamMenu(client);
}

int GetClientRealHealth(int client)
{
	if(!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}
	if(GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return GetClientHealth(client);
	}
  
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float TempHealth;
	int PermHealth = GetClientHealth(client);
	if(buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float decay = FindConVar("pain_pills_decay_rate").FloatValue;
		float constant = 1.0/decay;	TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	return RoundToFloor(PermHealth + TempHealth);
}

// *********************************************************************************
// DIRECTOR DIFFICULTY METHODS
// *********************************************************************************

// ------------------------------------------------------------------------
//  Change the director variable MaxSpecials. Won't do anything unless l4dt present
// ------------------------------------------------------------------------
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if (!AreInfectedAllowed() && StrEqual(key, "MaxSpecials") && SiSpMore.BoolValue && AutoDifficulty.BoolValue)
	{
		retVal = MaxSpecials;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
//  Difficulty timer. Triggered by timer_BotsUpdate
// ------------------------------------------------------------------------
public Action timer_Difficulty(Handle hTimer)
{
	DifficultyTimer = null;
	AutoDifficultyCheck();
}

void AutoDifficultyCheck()
{
	int extrasurvivors = GetSurvivorTeam() - 4;
	extrasurvivors = (extrasurvivors > 0) ? extrasurvivors : 0;  // Don't make game easier if less than 4 survivors 

	float TankHp_Multi = 1 + TankHpMulti.FloatValue*extrasurvivors;
	if (TankHpMulti.BoolValue){   // if not 0
			int TankHP = RoundFloat(4000.0*TankHp_Multi);
			FindConVar("z_tank_health").IntValue = TankHP;
	}
	
	// Spawn more zombie the more survivors there are 
	float spawn_multi = 1 + CiSpMulti.FloatValue * extrasurvivors ;	
	if (CiSpMulti.BoolValue){	 
		FindConVar("z_mob_spawn_finale_size").IntValue	= RoundToNearest(20 * spawn_multi);
		FindConVar("z_mob_spawn_max_size").IntValue 	= RoundToNearest(30 * spawn_multi);
		FindConVar("z_mob_spawn_min_size").IntValue		= RoundToNearest(10 * spawn_multi);
		FindConVar("z_mob_spawn_finale_size").IntValue	= RoundToNearest(20 * spawn_multi);
		FindConVar("z_mega_mob_size").IntValue			= RoundToNearest(50 * spawn_multi);
		FindConVar("z_common_limit").IntValue			= RoundToNearest(30 * spawn_multi);
	  //FindConVar("z_health").IntValue					= RoundToNearest(50 * spawn_multi);
	
		FindConVar("z_mob_spawn_max_interval_easy").IntValue	= RoundToFloor(240.0 / spawn_multi);
		FindConVar("z_mob_spawn_max_interval_normal").IntValue	= RoundToFloor(180.0 / spawn_multi);
		FindConVar("z_mob_spawn_max_interval_hard").IntValue	= RoundToFloor(180.0 / spawn_multi);
		FindConVar("z_mob_spawn_max_interval_expert").IntValue	= RoundToFloor(180.0 / spawn_multi);
		FindConVar("z_mob_spawn_min_interval_easy").IntValue	= RoundToFloor(120.0 / spawn_multi);
		FindConVar("z_mob_spawn_min_interval_normal").IntValue	= RoundToFloor( 90.0 / spawn_multi);		
		FindConVar("z_mob_spawn_min_interval_hard").IntValue	= RoundToFloor( 90.0 / spawn_multi);
		FindConVar("z_mob_spawn_min_interval_expert").IntValue	= RoundToFloor( 90.0 / spawn_multi);
		
		FindConVar("z_mega_mob_spawn_max_interval").IntValue					= RoundToFloor(900.0 / spawn_multi);
		FindConVar("z_mega_mob_spawn_min_interval").IntValue					= RoundToFloor(420.0 / spawn_multi);
		FindConVar("director_special_respawn_interval").IntValue				= RoundToFloor( 45.0 / spawn_multi);
		FindConVar("director_special_battlefield_respawn_interval").IntValue	= RoundToFloor( 10.0 / spawn_multi);
		FindConVar("director_special_finale_offer_length").IntValue				= RoundToFloor( 10.0 / spawn_multi);
		FindConVar("director_special_initial_spawn_delay_max").IntValue			= RoundToFloor( 60.0 / spawn_multi);
		FindConVar("director_special_initial_spawn_delay_max_extra").IntValue	= RoundToFloor(180.0 / spawn_multi);
		FindConVar("director_special_initial_spawn_delay_min").IntValue			= RoundToFloor( 30.0 / spawn_multi);
		FindConVar("director_special_original_offer_length").IntValue			= RoundToFloor( 30.0 / spawn_multi);
	}

	// More survivors = more SI health
	float sihp_Multi = 1 + GetConVarFloat(SiHpMulti)*extrasurvivors;
	if (SiHpMulti.BoolValue){		
		FindConVar("z_gas_health").IntValue			= RoundToCeil(   250.0 * sihp_Multi);
		FindConVar("z_hunter_health").IntValue		= RoundToNearest(250.0 * sihp_Multi);
		FindConVar("z_exploding_health").IntValue	= RoundToNearest( 50.0 * sihp_Multi);
		FindConVar("z_spitter_health").IntValue		= RoundToCeil(   100.0 * sihp_Multi);
		FindConVar("z_charger_health").IntValue		= RoundToNearest(600.0 * sihp_Multi);
		FindConVar("z_jockey_health").IntValue		= RoundToNearest(325.0 * sihp_Multi);
	}

	// Increase limit of special infected as bots. 
	if(!AreInfectedAllowed() && SiSpMore.BoolValue && l4dt() && !StrEqual(gameMode, "survival"))    // Not in survival, versus, scavenge or realism versus, l4dt required
	{
		// Increase overall infected limit
		MaxSpecials = 2 + RoundToNearest(extrasurvivors * SiSpMore.FloatValue);
		FindConVar("z_minion_limit").IntValue = MaxSpecials; 	// For L4D1?
		
		// Increase limits of infected classes
		char iType[6][24] = {"z_smoker_limit", "z_boomer_limit", "z_hunter_limit", "z_spitter_limit", "z_charger_limit", "z_jockey_limit"};
		int maxTypes = L4D1 ? 3 : 6;
		if(L4D1)
		{
			ReplaceString(iType[0], sizeof(iType[]), "smoker", "gas", false);
			ReplaceString(iType[1], sizeof(iType[]), "boomer", "exploding", false);		
		}

		int SIperclass = RoundToCeil(MaxSpecials/3.0);  // 0 to 3 SI: 1 per class, 4 to 6 SI: 2 per class, 7 to 9 SI: 3 per class, etc

		for(int i = 0; i < maxTypes; i++)
		{
			FindConVar(iType[i]).IntValue = SIperclass;  // Increase each SI class limit
		}
	}
	PrintToConsoleAll("SuperVersus - Tank HP: %.0f%%\tSI HP: %.0f%%\tCI spawn rate: %.0f%%\tMaxSpecials: %d", 100.0*TankHp_Multi, 100.0*sihp_Multi, 100.0*spawn_multi, MaxSpecials);
}

// *********************************************************************************
// INFECTED COUNTER, for Versus / Scavenge
// *********************************************************************************

char SiNames[7][] = {"none", "smoker", "boomer", "hunter", "spitter", "jockey", "charger"};

// ------------------------------------------------------------------------
//  Start counter when a survivor leaves safe area. Delay equals to respawn of ghost
// ------------------------------------------------------------------------
public void Event_PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{ 
	if(SubDirector == null && AreInfectedAllowed() && AnySurvivorLeftSafeArea())
	{
		SubDirector = CreateTimer(FindConVar("z_ghost_delay_max").FloatValue, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void SetGhostStatus(int client, bool ghost) { SetEntProp(client, Prop_Send, "m_isGhost",   ghost); }
void SetLifeState  (int client, bool ready) { SetEntProp(client, Prop_Send, "m_lifeState", ready); }
bool IsPlayerGhost (int client) 			{ return GetEntProp(client, Prop_Send, "m_isGhost") ? true : false;}

bool AnySurvivorLeftSafeArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource", false))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if(GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

// ------------------------------------------------------------------------
//  If infected team not full, spawn infected to fill it up
// ------------------------------------------------------------------------
public Action BotInfectedCounter(Handle timer, int value)
{
	SubDirector = null;

	if (!MoreSiBotsVersus.BoolValue || GetTeamPlayers(TEAM_INFECTED, false) >= InfectedLimit.IntValue) // if not extra bots wanted
	{
		SubDirector = CreateTimer(30.0, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE); // check back in 30 secs to see if setting changed
		return ;
	}
	
	// first element is nothing, to simplify since enum starts at 1
	//////////////////////////////////////////////////////////////
	char iType[7][24] = {"none", "z_smoker_limit", "z_boomer_limit", "z_hunter_limit", "z_spitter_limit", "z_charger_limit", "z_jockey_limit"};	
	int SIleft[7] = {-1,  0,0,0, 0,0,0};
	
	// Rename / exclude for L4D1
	////////////////////////////
	int maxTypes = L4D1 ? 3 : 6;
	if(L4D1)
	{
		ReplaceString(iType[1], sizeof(iType[]), "smoker", "gas", false);
		ReplaceString(iType[2], sizeof(iType[]), "boomer", "exploding", false);		
	}
	
	// Record SI type limits
	////////////////////////
	int SIfromTypes = 0; // 
	for (int type = 1; type <= maxTypes; type++)
	{
		SIleft[type] = FindConVar(iType[type]).IntValue;
		SIfromTypes  = SIfromTypes + SIleft[type] ;
	}
	
	int iInfected = InfectedLimit.IntValue;
	
	// Check if SI from types are enough
	///////////////////////////////////////
	if (SIfromTypes < iInfected)   // if not enough 
	{
		int extraSiPerType =  RoundToCeil((iInfected - SIfromTypes)/3.0);
		
		for(int i = 1; i <= maxTypes; i++)
		{
			SIleft[i] = SIleft[i] + extraSiPerType;
			FindConVar(iType[i]).IntValue = SIleft[i];  // Increase each SI class limit
		}
	}
	
	// counts infected left that can be spawned.
	//////////////////////////////////////////
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			iInfected--;
			
			char modelName[32];
			GetClientModel(i, modelName, sizeof(modelName));
			
			for (int type = 1; type <= 6; type++)
			{
				if (StrEqual(modelName, SiNames[type])) SIleft[type]--;
			}
		}
	}
	
	// Stores Ghost / Life. Otherwise players may autospawn
	/////////////////////////////////////////////////////
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			if(IsPlayerGhost(i))
			{
				resetGhost[i] = true;
				SetGhostStatus(i, false);
			}
			else if(!IsPlayerAlive(i))
			{
				resetLife[i] = true;
				SetLifeState(i, false);
			}
		}
	}

	// Pick an available infected to spawn ;
	////////////////////////////////////////
	for(int limit = 0;limit < iInfected; limit++)
	{
		int nmax = 0;
		int SIfree[7];
		int pick;
		
		// Pick available types;
		for (int type = 1; type <= 6; type++)
		{
			if (SIleft[type] > 0)
			{
				nmax++;
				SIfree[nmax] = type;
			}
		}
		
		if (nmax != 0)   // if at least one type available
		{
			pick = SIfree[GetRandomInt(1, nmax)];
			SIleft[pick]--;
	
			SiSpawn(pick); // spawn bot
		}
	}

	// We restore the player's status
	/////////////////////////////////
	for(int i = 1; i <= MaxClients; i++)
	{
		if(resetGhost[i] == true)
			SetGhostStatus(i, true);
		if(resetLife[i] == true)
			SetLifeState(i, true);
	}
	
	
	// Update intensity
	////////////////////
	int m_iIntensity = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			m_iIntensity += GetEntProp(i, Prop_Send, "m_clientIntensity");
		}
	}
	float m_iAverageIntensity = 5.0 + (float(m_iIntensity) / (float( GetSurvivorTeam() ) * 100.0) * FindConVar("z_ghost_delay_max").FloatValue);

	SubDirector = CreateTimer(15.0 + m_iAverageIntensity, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
}

// ------------------------------------------------------------------------
//  Spawn a Special Infected bot
// ------------------------------------------------------------------------
void SiSpawn(int type)
{
	int client = GetAnyValidClient();

	int Bot = CreateFakeClient("InfectedBot");
	if(Bot != 0)
	{
			ChangeClientTeam(Bot, TEAM_INFECTED);
			DispatchKeyValue(Bot, "classname", "InfectedBot");
			CheatCommand(client, "z_spawn_old", SiNames[type], "auto"); // z_spawn_old required or they spawn in front of survivors
			KickClient(Bot, "Kicked Fake Bot");
	}
}

// *********************************************************************************
// RESPAWN AND CHEAT METHODS
// *********************************************************************************

void Respawn(int client)
{
	static Handle hRoundRespawn = INVALID_HANDLE;
	if (hRoundRespawn == INVALID_HANDLE)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if(hRoundRespawn == INVALID_HANDLE)
		{
			PrintToChatAll("SuperVersus: RoundRespawn Signature broken. Make sure l4d_superversus.txt is in /gamedata/");
		}
  	}
	SDKCall(hRoundRespawn, client);
}

void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

void PrintToConsoleAll(const char[] format, any ...) 
{ 
	char text[192];
	VFormat(text, sizeof(text), format, 2);
	
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			PrintToConsole(i, "%s", text);
		}
	}
}

// ------------------------------------------------------------------------
// Teleport client to survivor
// ------------------------------------------------------------------------
void TeleportToSurvivor(int client) 
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsClientIdle(client))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && client != i)
			{
				float pos[3] = 0.0;
				GetClientAbsOrigin(i, pos);
				TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
				return;
			}
		}
	}
}

// ------------------------------------------------------------------------
// Get the average weapon tier of survivors, and give a weapon of that tier to client
// ------------------------------------------------------------------------
char tier1_weapons[5][] =
{
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_smg_silenced",		// L4D2 only
	"weapon_shotgun_chrome",	// L4D2 only
	"weapon_smg_mp5"			// International only
};
bool IsWeaponTier1(int iWeapon)
{
	char sWeapon[128];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
	for (int i = 0; i < sizeof(tier1_weapons); i++)
	{
		if (StrEqual(sWeapon, tier1_weapons[i], false)) return true;
	}
	return false;
}
void GiveAverageWeapon(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client)) return;

	int iWeapon;
	int wtotal=0; int total=0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && client != i)
		{
			total = total+1;	
			iWeapon = GetPlayerWeaponSlot(i, 0);
			if (iWeapon < 0 || !IsValidEntity(iWeapon) || !IsValidEdict(iWeapon)) continue; // no primary weapon

			if (IsWeaponTier1(iWeapon)) wtotal = wtotal + 1;  // tier 1
			else wtotal = wtotal + 2; // tier 2 or more
		}
	}
	int average = total > 0 ? RoundToNearest(1.0 * wtotal/total) : 0;
	switch(average)
	{
		case 0: CheatCommand(client, "give", "pistol", "");	
		case 1: CheatCommand(client, "give", "smg", "");
		case 2: CheatCommand(client, "give", "weapon_rifle", "");
	}
}
