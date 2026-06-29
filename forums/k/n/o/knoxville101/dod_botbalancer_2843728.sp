//////////////////////////////////////////////
//
// SourceMod Script
//
// DoD:S Bot Balancer
//
// Description: Balances teams using only bots, never real players.
//              Works alongside RCBot2 for bot population management.
//
//////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

// Team definitions for DoD:S
#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATOR 1
#define TEAM_ALLIES 2
#define TEAM_AXIS 3

public Plugin myinfo = 
{
	name = "DoD:S Bot Balancer",
	author = "Knoxville",
	description = "Balances teams using only bots, never real players",
	version = PLUGIN_VERSION,
	url = ""
}

// ConVars
ConVar g_cvEnabled;
ConVar g_cvMaxTeamDiff;
ConVar g_cvDebug;

// Global variables
bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Create ConVars
	CreateConVar("dod_botbalancer_version", PLUGIN_VERSION, "Bot Balancer Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvEnabled = CreateConVar("dod_botbalancer_enabled", "1", "Enable/disable bot balancer (1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvMaxTeamDiff = CreateConVar("dod_botbalancer_maxdiff", "1", "Maximum allowed team difference before balancing", FCVAR_NOTIFY, true, 0.0);
	g_cvDebug = CreateConVar("dod_botbalancer_debug", "0", "Enable debug messages (1/0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// Hook events
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	// Hook team join attempts (before they happen)
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	// Register admin command for manual balancing
	RegAdminCmd("sm_balancebots", Command_BalanceBots, ADMFLAG_GENERIC, "Manually trigger bot team balance");
	
	// Auto-generate config file
	AutoExecConfig(true, "dod_botbalancer");
	
	// If plugin loaded late, check teams
	if (g_bLateLoad)
	{
		CreateTimer(1.0, Timer_CheckBalance);
	}
}

public void OnMapStart()
{
	// Check balance when map starts
	CreateTimer(2.0, Timer_CheckBalance);
	
	// Create a repeating timer to check balance every 10 seconds
	CreateTimer(10.0, Timer_CheckBalance, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// Event: Player changes team
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	int newteam = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	
	// Only care about players joining actual teams (not spec/unassigned)
	if (newteam != TEAM_ALLIES && newteam != TEAM_AXIS)
		return;
	
	// Ignore if player is just switching within the same team or from spec
	if (oldteam == newteam)
		return;
	
	// Debug message
	if (g_cvDebug.BoolValue && IsValidClient(client))
	{
		char playerName[64];
		GetClientName(client, playerName, sizeof(playerName));
		PrintToServer("[BotBalancer] %s (%s) joined team %d", 
			playerName, 
			IsFakeClient(client) ? "BOT" : "PLAYER", 
			newteam);
	}
	
	// Delay balance check slightly to let team change complete
	CreateTimer(0.5, Timer_CheckBalance);
}

// Event: Player spawns
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return;
	
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	// Only balance when bots spawn
	if (!IsValidClient(client) || !IsFakeClient(client))
		return;
	
	// Check balance after a bot spawns
	CreateTimer(0.5, Timer_CheckBalance);
}

// Command Listener: Intercept team join attempts
public Action Command_JoinTeam(int client, const char[] command, int argc)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	// Only handle real players
	if (!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if (argc < 1)
		return Plugin_Continue;
	
	// Get the team they want to join
	char teamStr[8];
	GetCmdArg(1, teamStr, sizeof(teamStr));
	int desiredTeam = StringToInt(teamStr);
	
	// Only care about joining actual teams
	if (desiredTeam != TEAM_ALLIES && desiredTeam != TEAM_AXIS)
		return Plugin_Continue;
	
	int currentTeam = GetClientTeam(client);
	
	// If already on that team, allow it
	if (currentTeam == desiredTeam)
		return Plugin_Continue;
	
	// Pre-emptively move a bot to make room if needed
	if (PreBalanceForPlayer(client, desiredTeam))
	{
		if (g_cvDebug.BoolValue)
		{
			char playerName[64];
			GetClientName(client, playerName, sizeof(playerName));
			PrintToServer("[BotBalancer] Pre-balanced for %s joining team %d", playerName, desiredTeam);
		}
	}
	
	return Plugin_Continue;
}

// Admin Command: Manually trigger balance
public Action Command_BalanceBots(int client, int args)
{
	if (!g_cvEnabled.BoolValue)
	{
		ReplyToCommand(client, "[BotBalancer] Plugin is disabled");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[BotBalancer] Triggering manual balance check...");
	BalanceTeams();
	
	return Plugin_Handled;
}

// Timer: Check and balance teams
public Action Timer_CheckBalance(Handle timer)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;
	
	BalanceTeams();
	return Plugin_Continue;
}

// Main balancing function
void BalanceTeams()
{
	int alliesReal = 0, axisReal = 0;
	int alliesBots = 0, axisBots = 0;
	
	// Count real players and bots on each team
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		
		int team = GetClientTeam(i);
		
		if (team == TEAM_ALLIES)
		{
			if (IsFakeClient(i))
				alliesBots++;
			else
				alliesReal++;
		}
		else if (team == TEAM_AXIS)
		{
			if (IsFakeClient(i))
				axisBots++;
			else
				axisReal++;
		}
	}
	
	// Calculate total players per team
	int alliesTotal = alliesReal + alliesBots;
	int axisTotal = axisReal + axisBots;
	int totalBots = alliesBots + axisBots;
	
	// Debug output
	if (g_cvDebug.BoolValue)
	{
		PrintToServer("[BotBalancer] Teams - Allies: %d real + %d bots = %d | Axis: %d real + %d bots = %d | Total bots: %d",
			alliesReal, alliesBots, alliesTotal, axisReal, axisBots, axisTotal, totalBots);
	}
	
	// If no bots exist, nothing to balance
	if (totalBots == 0)
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] No bots to balance");
		return;
	}
	
	// Calculate ideal distribution
	// Goal: Make total team sizes as equal as possible by moving only bots
	int maxDiff = g_cvMaxTeamDiff.IntValue;
	int difference = alliesTotal - axisTotal;
	
	// Teams are balanced
	if (difference >= -maxDiff && difference <= maxDiff)
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] Teams are balanced (diff: %d)", difference);
		return;
	}
	
	// Determine which team has more total players and needs to lose a bot
	int fromTeam, toTeam;
	int botsAvailable;
	
	if (difference > maxDiff) // Allies has more total players
	{
		fromTeam = TEAM_ALLIES;
		toTeam = TEAM_AXIS;
		botsAvailable = alliesBots;
	}
	else // Axis has more total players
	{
		fromTeam = TEAM_AXIS;
		toTeam = TEAM_ALLIES;
		botsAvailable = axisBots;
	}
	
	// Check if we have bots available to move
	if (botsAvailable <= 0)
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] Cannot balance - no bots available on team %d to move", fromTeam);
		return;
	}
	
	// Move a bot
	if (MoveBotBetweenTeams(fromTeam, toTeam))
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] Moved bot from team %d to team %d (diff was %d)", fromTeam, toTeam, difference);
		
		// Check if we need to move more bots (recursive balance)
		CreateTimer(0.5, Timer_CheckBalance);
	}
	else
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] Failed to move bot from team %d to team %d", fromTeam, toTeam);
	}
}

// Pre-balance teams before a player joins
bool PreBalanceForPlayer(int client, int desiredTeam)
{
	int alliesReal = 0, axisReal = 0;
	int alliesBots = 0, axisBots = 0;
	int currentTeam = GetClientTeam(client);
	
	// Count real players and bots on each team
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		
		// Skip the joining player when counting
		if (i == client)
			continue;
		
		int team = GetClientTeam(i);
		
		if (team == TEAM_ALLIES)
		{
			if (IsFakeClient(i))
				alliesBots++;
			else
				alliesReal++;
		}
		else if (team == TEAM_AXIS)
		{
			if (IsFakeClient(i))
				axisBots++;
			else
				axisReal++;
		}
	}
	
	// Simulate the player joining their desired team
	if (desiredTeam == TEAM_ALLIES)
		alliesReal++;
	else if (desiredTeam == TEAM_AXIS)
		axisReal++;
	
	// If player is switching teams (not joining from spec), subtract from old team
	if (currentTeam == TEAM_ALLIES)
		alliesReal--;
	else if (currentTeam == TEAM_AXIS)
		axisReal--;
	
	int alliesTotal = alliesReal + alliesBots;
	int axisTotal = axisReal + axisBots;
	
	if (g_cvDebug.BoolValue)
	{
		PrintToServer("[BotBalancer] PreBalance - After join would be: Allies %d (%d real + %d bots) | Axis %d (%d real + %d bots)",
			alliesTotal, alliesReal, alliesBots, axisTotal, axisReal, axisBots);
	}
	
	// Check if this would unbalance teams
	int maxDiff = g_cvMaxTeamDiff.IntValue;
	int difference = alliesTotal - axisTotal;
	
	// Teams would be balanced, allow join
	if (difference >= -maxDiff && difference <= maxDiff)
		return true;
	
	// Teams would be unbalanced - need to move a bot
	int fromTeam, toTeam;
	int botsAvailable;
	
	if (difference > maxDiff) // Allies would have more
	{
		fromTeam = TEAM_ALLIES;
		toTeam = TEAM_AXIS;
		botsAvailable = alliesBots;
	}
	else // Axis would have more
	{
		fromTeam = TEAM_AXIS;
		toTeam = TEAM_ALLIES;
		botsAvailable = axisBots;
	}
	
	// Check if we have bots available to move
	if (botsAvailable <= 0)
	{
		if (g_cvDebug.BoolValue)
			PrintToServer("[BotBalancer] Cannot pre-balance - no bots available on team %d", fromTeam);
		return false;
	}
	
	// Move a bot before the player joins
	return MoveBotBetweenTeams(fromTeam, toTeam);
}

// Move a bot from one team to another
bool MoveBotBetweenTeams(int fromTeam, int toTeam)
{
	// Find a bot on the source team
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
		
		if (!IsFakeClient(i))
			continue;
		
		if (GetClientTeam(i) != fromTeam)
			continue;
		
		// Found a bot, move it
		ChangeClientTeam(i, toTeam);
		
		if (g_cvDebug.BoolValue)
		{
			char botName[64];
			GetClientName(i, botName, sizeof(botName));
			PrintToServer("[BotBalancer] Moving bot '%s' from team %d to team %d", botName, fromTeam, toTeam);
		}
		
		return true;
	}
	
	return false;
}

// Check if client is valid
bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}
