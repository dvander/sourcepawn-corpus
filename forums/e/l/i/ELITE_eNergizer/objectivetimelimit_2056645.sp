/**
 * =============================================================================
 * Objective Time bomb Plugin
 * This plugin adds a time limit functionality to objectives.
 * =============================================================================
 *
 */


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "[NMRiH] Objective Time Limit",
	author = "ELITE_eNergizer",
	description = "Kills the survivors if they don't finish an objective in time. (Only works on objective maps)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// Global variables, uh oh!
static timeLeft;
static Handle:sm_objectivetimelimit_time = INVALID_HANDLE;
static Handle:sm_objectivetimelimit_spam = INVALID_HANDLE;

public OnPluginStart()
{
	// 300 = 5 minutes
	// CVARs
	sm_objectivetimelimit_time = CreateConVar("sm_objectivetimelimit_time",  "300", "The objective time limit in seconds", FCVAR_NOTIFY, true, -1.0, false, 0.0);
	sm_objectivetimelimit_spam = CreateConVar("sm_objectivetimelimit_spam",  "1", "How obnoxious the messages are. 0 for 30 second countdown and round start info, 1 for previous and minute notifier",
										FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("sm_objectivetimelimit_version",  PLUGIN_VERSION, "Objective Time Limit Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	AutoExecConfig(true, "plugin_objectivetimelimit");
	
	// Start the timer up
	StartTimers();
	timeLeft = -1;
	
	// Hooks
	HookEvent("nmrih_round_begin", Event_RoundStart, EventHookMode_Pre);
	HookEvent("objective_complete", Event_ObjectiveComplete, EventHookMode_Pre);
	
	// Commands
	RegAdminCmd("sm_objectivetimelimit", Command_KillAll, ADMFLAG_SLAY, "sm_objectivetimelimit [#time] (-1 for disable) - For setting the timer on the current objective.");
	RegConsoleCmd("time", Command_TimeLeft, "Shows time left until survivors get killed if objective is not complete.");
}

/**
* This will reset and stop the timer
**/
public OnMapStart()
{
	timeLeft = -1;
}

/**
* Reset the timer when an objective is complete
**/
public Action:Event_ObjectiveComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsObjectiveMap())
		return Plugin_Continue;
	
	PrintToChatAll("Objective Complete!");
	timeLeft = GetConVarInt(sm_objectivetimelimit_time) + 5;
	return Plugin_Continue;
}

/**
* This will check if the map is an objective map or a survival map
**/
public bool:IsObjectiveMap()
{
	new String:buffer[64];
	GetCurrentMap(buffer, 64);
	buffer[4] = '\0';
	if (StrEqual(buffer, "nmo_"))
		return true;
	
	return false;
}

/**
* A hook onto an event where a round starts
**/
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsObjectiveMap())
		return Plugin_Continue;
	
	timeLeft = GetConVarInt(sm_objectivetimelimit_time) + 5;
	
	PrintToServer("Round Started");
	PrintToChatAll("[SM] Round Started");
	PrintToChatAll("You have a time limit for each objective. If you don't complete one in time, you will all die.");
	PrintToChatAll("You can type !time to see how much time is left.");
	PrintToChatAll("[SM] %d minutes and %d seconds until survivors get wiped out.", timeLeft/60, timeLeft%60);
	
	return Plugin_Continue;
}

/**
* This function kills all players
**/
public Action:KillPlayers()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		 if (IsValidEntity(i) && IsValidEdict(i) && IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
}

/**
* This will print to the center of the screen to everyone the timeLeft until 0
* Once the timer reaches 0, survivors will get killed
**/
public Action:ChatTimerTime(Handle:timer)
{
	if (timeLeft == 0)
	{
		timeLeft = -1;
		KillPlayers();
	}
	else if (timeLeft > 0)
	{
		if (timeLeft > 60 && (timeLeft % 60 == 0) && GetConVarInt(sm_objectivetimelimit_spam) )
		{
			PrintCenterTextAll("%d minutes left", timeLeft/60);
		}
		else if (timeLeft <= 30)
		{
			PrintCenterTextAll("%d seconds left", timeLeft);
		}
		timeLeft--;
	}
}

/**
* This will be called when the command time is called.
* It is supposed to print to the chat for everyone on how much time is left until survivors die.
**/
public Action:Command_TimeLeft(client, args)
{
	if (timeLeft > 0)
		PrintToChat(client, "[SM] %d minutes and %d seconds until survivors get wiped out.", timeLeft/60, timeLeft%60);
	else
		PrintToChat(client, "[SM] There is no time limit on the objective.");
	
	return Plugin_Handled;
}

/**
* This will manually set a timer on the survivors to kill them all
* You can also disable the timer by typing the command with no arguments
**/
public Action:Command_KillAll(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_objectivetimelimit [#time] (-1 for disable)");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	// Get the first argument
	GetCmdArg(1, arg1, sizeof(arg1));
	timeLeft = StringToInt(arg1);
	if (timeLeft > 0)
	{
		PrintToChatAll("[SM] Time limit changed!");
		PrintToChatAll("[SM] %d minutes and %d seconds until survivors get wiped out.", timeLeft/60, timeLeft%60);
	}
	else
		PrintToChatAll("[SM] Time limit disabled for current objective.");
	
	// TODO: finish this later
	// LogAction(client, target, "\"%L\" slapped \"%L\" (damage %d)", client, target, damage);
	
	return Plugin_Handled;
}

/**
* This is for starting up the timers
**/
public Action:StartTimers()
{
	CreateTimer( 1.0, ChatTimerTime, INVALID_HANDLE, TIMER_REPEAT);
}
