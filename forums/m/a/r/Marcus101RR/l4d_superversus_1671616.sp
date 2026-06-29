#pragma semicolon 1                 // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

native bool L4D_LobbyUnreserve();

// l4dt forward (to add more SI bots)
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	5.0
#define PLUGIN_VERSION		"1.8.8"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define TEAM_NEUTRAL	4

#define ZOMBIE_SMOKER	1
#define ZOMBIE_BOOMER	2
#define ZOMBIE_HUNTER	3

Handle MedkitTimer    				= null;
Handle TeamPanelTimer[MAXPLAYERS+1]	= null;
Handle SubDirector					= null;
Handle BotsUpdateTimer    			= null;

Handle SurvivorLimit 				= null;
Handle InfectedLimit 				= null;
Handle L4DInfectedLimit 			= null;
Handle KillRes						= null;
Handle AutoDifficulty				= null;
Handle extraFirstAid				= null;
Handle hpMulti    					= null;
Handle g_VarInfected[6] 			= { null, ...};

bool MedkitsGiven = false;
bool RoundStarted = false;
int specialKills = 0;
char gameMode[16];
char gameName[16];


public Plugin:myinfo =
{
	name        = "Super Versus Reloaded",
	author      = "DDRKhat, Marcus101RR, and Merudo",
	description = "Allows up to 32 players on Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?p=2393931#post2393931"
}

// *********************************************************************************
// METHODS FOR GAME START & END
// *********************************************************************************
public void OnPluginStart()
{
	GetConVarString(FindConVar("mp_gamemode"), gameMode, sizeof(gameMode));
	GetGameFolderName(gameName, sizeof(gameName));
	
	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", CVAR_FLAGS);
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS,true, 1.00, true, 24.00);
	InfectedLimit = CreateConVar("l4d_infected_limit", "4", "Max amount of infected (will not affect bots)", CVAR_FLAGS, true, 4.00, true, 24.00);
	AutoDifficulty = CreateConVar("director_auto_difficulty", "0", "Change Difficulty", CVAR_FLAGS, true, 0.0, true, 1.0);
	extraFirstAid = CreateConVar("l4d_extra_first_aid", "1" , "Allow extra first aid kits for extra players. 0: No extra kits. 1: one extra kit per player above four", CVAR_FLAGS, true, 0.0, true, 1.0);
	hpMulti = CreateConVar("l4d_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4)). Only active if director_auto_difficulty is 1", CVAR_FLAGS,true,0.01,true,1.00);
	KillRes = CreateConVar("l4d_killreservation","1","Should we clear Lobby reservaton? (For use with Left4DownTown extension ONLY)", CVAR_FLAGS,true,0.0,true,1.0);

	g_VarInfected[0] = CreateConVar("z_smoker_allow", "1", "Allow smoker in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	g_VarInfected[1] = CreateConVar("z_boomer_allow", "1", "Allow boomer in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	g_VarInfected[2] = CreateConVar("z_hunter_allow", "1", "Allow hunter in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	g_VarInfected[3] = CreateConVar("z_spitter_allow", "1", "Allow spitter in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	g_VarInfected[4] = CreateConVar("z_charger_allow", "1", "Allow charger in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	g_VarInfected[5] = CreateConVar("z_jockey_allow", "1", "Allow jockey in Auto Difficulty.", CVAR_FLAGS, true, 0.00, true, 1.00);
	
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
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_left_checkpoint", Event_PlayerLeftStartArea, EventHookMode_Post);
	AutoExecConfig(true, "l4d_superversus");
}

#define FORCE_INT_CHANGE(%1,%2,%3) public void %1 (Handle c, const char[] o, const char[] n) { SetConVarInt(%2,%3); }
FORCE_INT_CHANGE(FIL,L4DInfectedLimit,GetConVarInt(InfectedLimit))

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){MarkNativeAsOptional("L4D_LobbyUnreserve"); return APLRes_Success;}

// ------------------------------------------------------------------------
// Return true if lobby unreserve is supported
// ------------------------------------------------------------------------
bool l4dt() { if(GetConVarFloat(FindConVar("left4downtown_version"))> 0.00) return true; else return false;}  // Is Left 4 Downtown 1/2 loaded?

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
	
	int iMaxClients = MaxClients; 
	for(int i = 1; i <= iMaxClients; i++)
	{
		delete TeamPanelTimer[i];
	}
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
	int client = GetAnyValidSurvivor();
	int amount = GetTeamPlayers(TEAM_SURVIVOR, true) - 4;
	
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

	if (GetClientTeam(client) != TEAM_SURVIVOR)
		return ;
	
	// Reset the timer, if one exists
	delete BotsUpdateTimer;
	BotsUpdateTimer = CreateTimer(2.0, timer_BotsUpdate);
}

// ------------------------------------------------------------------------
// If player disconnect, set timer to spawn/kick bots as needed
// ------------------------------------------------------------------------
public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client) || RoundStarted != true)        // if bot or during transition
		return;

	delete TeamPanelTimer[client];

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
		SpawnCheck();
		if(MedkitTimer == null && !MedkitsGiven && GetConVarInt(extraFirstAid))
		{
			MedkitsGiven = true;
			MedkitTimer = CreateTimer(2.0, timer_SpawnExtraMedKit);
		}
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
	if(RoundStarted != true)
		return;
	
	int iSurvivor    = GetTeamPlayers(TEAM_SURVIVOR, true);
	int iSurvivorMax = GetConVarInt(SurvivorLimit);
	
	if (iSurvivor > iSurvivorMax) PrintToConsoleAll("SuperVersus - Kicking %d bot(s)", iSurvivor - iSurvivorMax);
	if (iSurvivor < iSurvivorMax) PrintToConsoleAll("SuperVersus - Spawning %d bot(s)", iSurvivorMax - iSurvivor);

	for(; iSurvivorMax < iSurvivor; iSurvivorMax++)
	{
		KickUnusedBot();
	}
	
	for(; iSurvivor < iSurvivorMax; iSurvivor++)
	{
		SpawnFakeClient();  // This triggers Event_PlayerSpawn and create new timer, be careful about infinite loops
	}
}

// ------------------------------------------------------------------------
// Kick an unused survivor bot
// ------------------------------------------------------------------------
void KickUnusedBot()
{
	int Bot = GetAnyValidBot();
	if(Bot > 0 && IsBotValid(Bot))
		KickClient(Bot, "Kicking Useless Client.");
}

// ------------------------------------------------------------------------
// Spawn a survivor bot
// ------------------------------------------------------------------------
void SpawnFakeClient()
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

// *********************************************************************************
// COMMANDS FOR JOINING TEAMS
// *********************************************************************************

public Action Join_Game(int client, int args)
{
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) != TEAM_SURVIVOR)
		{
			if(CheckAvailableBot(TEAM_SURVIVOR) == 0 && !IsClientIdle(client) && !AreInfectedAllowed())
			{
				ChangeClientTeam(client, TEAM_SURVIVOR);
			}
			else
			{
				if(!IsClientIdle(client))
					FakeClientCommand(client,"jointeam 2");
			}
		}
		if(GetClientTeam(client) == TEAM_SURVIVOR)
		{	
			if(IsPlayerAlive(client) == true)
			{
				PrintToChat(client, "\x01You are on the \x04Survivor Team\x01.");
			}
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(TEAM_SURVIVOR) != 0)  // Takeover a bot
			{
				ChangeClientTeam(client, TEAM_SPECTATOR);
				FakeClientCommand(client,"jointeam 2");
			}
			else if(IsPlayerAlive(client) == false && CheckAvailableBot(TEAM_SURVIVOR) == 0)
			{
				PrintToChat(client, "\x01You are \x04Dead\x01. No \x05Bot(s) \x01Available.");
			}
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
	else if(GetConVarInt(InfectedLimit) <= GetTeamPlayers(TEAM_INFECTED, false))
	{
		PrintToChat(client, "\x01[\x04ERROR\x01] The \x05Infected Team\x01 is Full.");
	}	
	else
	{
		ChangeClientTeam(client,TEAM_INFECTED);
	}
	return Plugin_Handled;
}

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
		int i = GetAnyValidSurvivor();
		int Bot = CreateFakeClient("SurvivorBot");
		if(Bot == 0)
			return Plugin_Handled;

		ChangeClientTeam(Bot, TEAM_SURVIVOR);
		if (DispatchKeyValue(Bot, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(Bot))
			{
				if(!IsPlayerAlive(Bot))
				{
					Respawn(Bot);
				}	
				if(i > 0)
				{
					float teleportOrigin[3];
					GetClientAbsOrigin(i, teleportOrigin);
					TeleportEntity(Bot, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
				}
				if((GetConVarInt(extraFirstAid)))				
					CheatCommand(Bot, "give", "first_aid_kit", "");
					
				GiveAverageWeapon(Bot);

				if(IsClientInGame(Bot) && IsFakeClient(Bot) && !HasIdlePlayer(Bot))
					KickClient(Bot, "Kicking Fake Client.");
			}
		}
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
	return true;
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
// Get the number of players on the team
// includeBots == true : counts bots
// ------------------------------------------------------------------------
int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if(IsFakeClient(i) && !includeBots)
				continue;
			players++;
		}
	}
	return players;
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
// Get any valid survivor bot. Last bot created first
// ------------------------------------------------------------------------
int GetAnyValidBot()
{
	for(int i = MaxClients ; i >= 1; i--)
	{
		if (IsBotValid(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			return i;
	}
	return -1;
}

// ------------------------------------------------------------------------
// Check if how many alive bots are available in a team
// ------------------------------------------------------------------------
int CheckAvailableBot(int team)
{
	int num = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsBotValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
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

int GetAnyValidSurvivor()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsClientInKickQueue(i))
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
	int iMaxClients = MaxClients; 
	for(int i = 1; i <= iMaxClients; i++)
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
	Format(title_survivor, sizeof(title_survivor), "Survivors (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_SURVIVOR, false), GetConVarInt(SurvivorLimit), CheckAvailableBot(TEAM_SURVIVOR));
	DrawPanelItem(TeamPanel, title_survivor);
	
	// Draw Survivor Group
	for(int i = 1; i <= iMaxClients; i++)
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
				else if(GetEntProp(i, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
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
	Format(title_infected, sizeof(title_infected), "Infected (%d/%d) - %d Bot(s)", GetTeamPlayers(TEAM_INFECTED, false), GetConVarInt(InfectedLimit), CheckAvailableBot(TEAM_INFECTED));
	DrawPanelItem(TeamPanel, title_infected);
		
	// Draw Infected Group
	for(int i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
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
				Format(m_iHealth, sizeof(m_iHealth), "DEAD - ");
			Format(text_client, sizeof(text_client), "%s%s", m_iHealth, ClientUserName);
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
			if(StrEqual(gameName, "left4dead2", false))
			{
				FakeClientCommand(client, "jointeam 2");
			}
			else
			{
				FakeClientCommand(client, "sm_join");
			}

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
		float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
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

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if (!AreInfectedAllowed() && StrEqual(key, "MaxSpecials") && GetConVarInt(AutoDifficulty))
	{
		retVal = 18;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	// If lobby is full, KillRes is true and l4dt is present, unreserve lobby
	if(GetConVarInt(KillRes) && l4dt())
	{
		L4D_LobbyUnreserve();
	}

	// Auto-Difficulty (Tanks, Specials, Etc)
	if(GetConVarInt(AutoDifficulty) == 1 && !IsFakeClient(client))
		AutoDifficultyCheck();
}

// ------------------------------------------------------------------------
// After every InfectedLimit * 3 SI kills, readjust difficulty
// ------------------------------------------------------------------------
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userId"));
	if(client < 1)
		return;

	if(GetClientTeam(client) == TEAM_INFECTED && GetConVarInt(AutoDifficulty) == 1)
	{
		specialKills++;
		if(specialKills > GetConVarInt(InfectedLimit) * 3)
		{
			specialKills = 0;
			AutoDifficultyCheck();	
		}
	}
}

void AutoDifficultyCheck()
{
	if(GetTeamPlayers(2, true) >= 4 && !StrEqual(gameMode, "versus", false))
	{
		int iMultiplier = GetTeamPlayers(TEAM_SURVIVOR, true);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(20)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30+RoundToNearest(float(30)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10+RoundToNearest(float(10)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20+RoundToNearest(float(10)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_mega_mob_size"), 50+RoundToNearest(float(50)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_common_limit"), 30+RoundToNearest(float(30)*((float(iMultiplier)/4.0)-1.0)/6.0));
		
		//SetConVarInt(FindConVar("z_health"), 50+RoundToNearest(float(50)*((float(iMultiplier)/4.0)-1.0)/1.6));
		SetConVarInt(FindConVar("z_gas_health"), RoundToNearest(float(250)*float(iMultiplier)/4.0));
		SetConVarInt(FindConVar("z_hunter_health"), RoundToNearest(float(250)*float(iMultiplier)/4.0));
		SetConVarInt(FindConVar("z_exploding_health"), RoundToNearest(float(50)*float(iMultiplier)/4.0));
		if(StrEqual(gameName, "left4dead2", false))
		{
			SetConVarInt(FindConVar("z_spitter_health"), RoundToNearest(float(100)*float(iMultiplier)/4.0));
			SetConVarInt(FindConVar("z_charger_health"), RoundToNearest(float(600)*float(iMultiplier)/4.0));
			SetConVarInt(FindConVar("z_jockey_health"), RoundToNearest(float(325)*float(iMultiplier)/4.0));			
		}
		SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), RoundToFloor(900.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), RoundToFloor(420.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_easy"), RoundToFloor(240.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_max_interval_normal"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_easy"), RoundToFloor(120.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("z_mob_spawn_min_interval_normal"), RoundToFloor(90.0 * (4.0/float(iMultiplier))));

		SetConVarInt(FindConVar("director_special_respawn_interval"), RoundToFloor(45.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_battlefield_respawn_interval"), RoundToFloor(10.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_finale_offer_length"), RoundToFloor(10.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max"), RoundToFloor(60.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_max_extra"), RoundToFloor(180.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_initial_spawn_delay_min"), RoundToFloor(30.0 * (4.0/float(iMultiplier))));
		SetConVarInt(FindConVar("director_special_original_offer_length"), RoundToFloor(30.0 * (4.0/float(iMultiplier))));

		if(!AreInfectedAllowed())
		{
			int totalAmount = 0;
			int iAmount = 0;
			int iLastType = 0;
			int maxTypes = StrEqual(gameName, "left4dead", false) ? 3 : 6;
			
			if(GetTeamPlayers(2, true) > GetConVarInt(SurvivorLimit))
				totalAmount = GetTeamPlayers(2, true);
			else if (GetTeamPlayers(2, true) < GetConVarInt(FindConVar("z_minion_limit")))
				totalAmount = GetConVarInt(FindConVar("z_minion_limit"));
			else
				totalAmount = GetConVarInt(SurvivorLimit);

			char iType[6][24] = {"z_smoker_limit", "z_boomer_limit", "z_hunter_limit", "z_spitter_limit", "z_charger_limit", "z_jockey_limit"};
			char iName[6][8] = {"Smoker", "Boomer", "Hunter", "Spitter", "Charger", "Jockey"};
			int iMin[6] = {1, 1, 1, 0, 0, 0};

			if(StrEqual(gameName, "left4dead", false))
			{
				ReplaceString(iType[0], sizeof(iType[]), "smoker", "gas", false);
				ReplaceString(iType[1], sizeof(iType[]), "boomer", "exploding", false);		
			}
			
			for(int i = 0; i < maxTypes; i++)
				if(GetConVarInt(g_VarInfected[i]) > 0)
					iLastType = i;
			
			PrintToConsoleAll("---------------------------------------------------");
			PrintToConsoleAll("ID\tTOTAL:\t%d\t%d/%d\tMax\tReserved", totalAmount, iLastType, maxTypes);
			PrintToConsoleAll("---------------------------------------------------");
			
			for(int i = 0; i < maxTypes; i++)
			{
				if(GetConVarInt(g_VarInfected[i]) > 0)
				{
					int lessMax = 0;
					for(int j = i + 1; j < maxTypes; j++)
							lessMax += iMin[j];
					
					iAmount = GetRandomInt(totalAmount == 0 ? 0 : i == iLastType ? totalAmount-lessMax : iMin[i], totalAmount-lessMax);
					SetConVarInt(FindConVar(iType[i]), iAmount);
					PrintToConsoleAll("%s\t\t%d\t%d\t%d\t%d", iName[i], iAmount, totalAmount, totalAmount-lessMax, lessMax);
					totalAmount -= iAmount;
				}
			}
		}

		float extrasurvivors = (float(GetTeamPlayers(2, true))-4.0);
		if(RoundFloat(extrasurvivors) > 0)
		{
			int TankHP = RoundFloat((4000*(1.0+(GetConVarFloat(hpMulti)*extrasurvivors))));
			SetConVarInt(FindConVar("z_tank_health"), TankHP);
			PrintToConsoleAll("Tank HP: %d", TankHP);
		}
	}
}

// *********************************************************************************
// INFECTED COUNTER, for L4D1 Versus
// *********************************************************************************

public void Event_PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{ 
	if(SubDirector == null && StrEqual(gameMode, "versus", false) && !StrEqual(gameName, "left4dead2", false) && AnySurvivorLeftSafeArea())
	{
		SubDirector = CreateTimer(float(GetConVarInt(FindConVar("z_ghost_delay_max"))), BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void SetGhostStatus(int client, bool ghost)
{
	if (ghost)	SetEntProp(client, Prop_Send, "m_isGhost", 1);
	else		SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

void SetLifeState(int client, bool ready)
{
	if(ready)	SetEntProp(client, Prop_Send, "m_lifeState", 1);
	else		SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost")) return true;
	return false;
}

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

public Action BotInfectedCounter(Handle timer, int value)
{
	int smoker = GetConVarInt(FindConVar("z_versus_smoker_limit"));
	int boomer = GetConVarInt(FindConVar("z_versus_boomer_limit"));
	int hunter = GetConVarInt(FindConVar("z_hunter_limit"));

	int iInfected = GetConVarInt(InfectedLimit);

	int iMaxClients = MaxClients; 
	for(int i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			iInfected--;

			if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_HUNTER) hunter--;
			else if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_SMOKER) smoker--;
			else if(GetEntProp(i, Prop_Send, "m_zombieClass") == ZOMBIE_BOOMER) boomer--;
		}
	}

	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	
	for(int i = 1; i <= iMaxClients; i++)
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

	int client = GetAnyValidClient();

	for(int limit = 0;limit < iInfected; limit++)
	{
		int Bot = CreateFakeClient("InfectedBot");
		if(Bot != 0)
		{
			ChangeClientTeam(Bot, TEAM_INFECTED);
			DispatchKeyValue(Bot, "classname", "InfectedBot");
			int type = GetRandomInt(1, 3);

			if(type == 1 && smoker-- > 0){ CheatCommand(client, "z_spawn", "smoker", "auto"); }
			else if(type == 2 && boomer-- > 0){ CheatCommand(client, "z_spawn", "boomer", "auto"); }
			else if(type == 3 && hunter-- > 0){ CheatCommand(client, "z_spawn", "hunter", "auto"); }

			KickClient(Bot, "Kicked Fake Bot");
		}
	}

	// We restore the player's status
	for(int i = 1; i <= iMaxClients; i++)
	{
		if(resetGhost[i] == true)
			SetGhostStatus(i, true);
		if(resetLife[i] == true)
			SetLifeState(i, true);
	}

	int m_iIntensity = 0;
	for(int i = 1; i <= iMaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			m_iIntensity += GetEntProp(i, Prop_Send, "m_clientIntensity");
		}
	}
	float m_iAverageIntensity = 5.0 + (float(m_iIntensity) / (float( GetTeamPlayers(TEAM_SURVIVOR, true) ) * 100.0) * float(GetConVarInt(FindConVar("z_ghost_delay_max"))));

	SubDirector = null;
	SubDirector = CreateTimer(15.0 + m_iAverageIntensity, BotInfectedCounter, _, TIMER_FLAG_NO_MAPCHANGE);
}


// *********************************************************************************
// RESPAWN AND CHEAT METHODS
// *********************************************************************************

void Respawn(int client)
{
	static Handle hRoundRespawn = null;
	if (hRoundRespawn == null)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_superversus");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if(hRoundRespawn == null)
		{
			PrintToChatAll("L4D_SM_Respawn: RoundRespawn Signature broken");
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
// Get the average weapon tier of survivors, and give a weapon of that tier to client
// ------------------------------------------------------------------------
char tier1_weapons[4][] =
{
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun"
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
