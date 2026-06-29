/*///////////////////////////////////////////////////////////////////////////////////////

	A SourceMod plugin for Left 4 Dead and Left 4 Dead 2

*/
#define PLUGIN_NAME		   "Survivor Bot Takeover"
#define PLUGIN_VERSION	   "0.8"
#define PLUGIN_DESCRIPTION "Allows dead survivors to take over a living bot survivor."
/*

	Programmer: Mikko Andersson (muukis)
	URL: http://forums.alliedmods.net/showthread.php?t=127987
	Date: 27.05.2010

*/
///////////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define TEAM_UNDEFINED	0
#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS	2
#define TEAM_INFECTED	3

#define VOTE_UNDEFINED	0
#define VOTE_YES		1
#define VOTE_NO			2
#define CVAR_FLAGS		FCVAR_NOTIFY

#define SOUND_TAKEOVER	"items/suitchargeok1.wav"
#define TAG				"TAKEOVER"

#pragma newdecls required

// new String:TAKEOVERVOTE_QUESTION[256] = "Allow %s to takeover a bot controlled living survivor?";
// new String:TAKEOVERCHOICE_QUESTION[256] = "Do you want to takeover a bot controlled living survivor?";

bool			 EnableSounds_Takeover	= true;
bool			 TakeoversEnabled		= false;
bool			 TakeoversEnabledFinale = false;
int				 PlayerTakeoverTarget	= 0;
int				 PlayerTakeoverVote[MAXPLAYERS + 1];
bool			 PlayerChoseNo[MAXPLAYERS + 1];
bool			 PlayerDisplayingChoosingPanel[MAXPLAYERS + 1];

Handle			 cvar_ManualTO				= INVALID_HANDLE;
Handle			 cvar_ManualTOIncap			= INVALID_HANDLE;
Handle			 cvar_AutoTOIncap			= INVALID_HANDLE;
Handle			 cvar_AutoTODeath			= INVALID_HANDLE;
Handle			 cvar_RequestTOConfirmation = INVALID_HANDLE;
Handle			 cvar_EnableTOVoting		= INVALID_HANDLE;
Handle			 cvar_TOVotingTime			= INVALID_HANDLE;
Handle			 cvar_TOChoosingTime		= INVALID_HANDLE;
Handle			 cvar_TODelay				= INVALID_HANDLE;
Handle			 cvar_SurvivorLimit			= INVALID_HANDLE;
Handle			 cvar_FinaleOnly			= INVALID_HANDLE;
Handle			 cvar_DisplayBotName		= INVALID_HANDLE;
Handle			 L4DTakeoverConf			= INVALID_HANDLE;
Handle			 L4DTakeoverSHS				= INVALID_HANDLE;
Handle			 L4DTakeoverTOB				= INVALID_HANDLE;
Handle			 TakeoverVoteTimer			= INVALID_HANDLE;
Handle			 PlayerDelayedChoosingPanel[MAXPLAYERS + 1];
Handle			 PeriodicTakeoverCheckTimer = INVALID_HANDLE;

// Plugin Info
public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Mikko Andersson (muukis) & Natán",
	description = PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= "http://www.sourcemod.com/"
};

// Here we go!
public void OnPluginStart()
{
	// Require Left 4 Dead (2)
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}
	LoadTranslations("takeover.phrases");

	// Plugin version public Cvar
	CreateConVar("l4d_takeover_version", PLUGIN_VERSION, "Survivor Bot Takeover Version", CVAR_FLAGS | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	if (FileExists("addons/sourcemod/gamedata/left4dhooks.l4d2.txt"))
	{
		// SDK handles for survivor bot takeover
		L4DTakeoverConf = LoadGameConfigFile("left4dhooks.l4d2");

		if (L4DTakeoverConf == INVALID_HANDLE)
		{
			SetFailState("Survivor Bot Takeover is disabled because could not load gamedata/left4dhooks.l4d2.txt");
			return;
		}
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DTakeoverConf, SDKConf_Signature, "SurvivorBot::SetHumanSpectator");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DTakeoverSHS = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DTakeoverConf, SDKConf_Signature, "CTerrorPlayer::TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DTakeoverTOB = EndPrepSDKCall();
		}
	}
	else
	{
		SetFailState("Survivor Bot Takeover is disabled because could not load gamedata/left4dhooks.txt");
		return;
	}

	EngineVersion ServerVersion = GetEngineVersion();

	cvar_ManualTO				= CreateConVar("l4d_takeover_manual", "1", "Allow dead survivor players to execute console command \"sm_takeover\" to takeover a survivor bot.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_ManualTOIncap			= CreateConVar("l4d_takeover_manualincap", "0", "Allow incapped survivor players to execute console command \"sm_takeover\" to takeover a survivor bot.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_AutoTOIncap			= CreateConVar("l4d_takeover_autoincap", "0", "Execute a takeover automatically when a player incaps.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_AutoTODeath			= CreateConVar("l4d_takeover_autodeath", "1", "Execute a takeover automatically when a player dies. Enabling this will disable the takeover voting.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_RequestTOConfirmation	= CreateConVar("l4d_takeover_requestconf", "1", "Request confirmation from the player before executing a takeover.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_EnableTOVoting			= CreateConVar("l4d_takeover_votingenabled", "0", "Initiate a vote for a takeover when a player dies.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_TOVotingTime			= CreateConVar("l4d_takeover_votingtime", "20", "Time to cast a takeover vote.", CVAR_FLAGS, true, 10.0, true, 60.0);
	cvar_TOChoosingTime			= CreateConVar("l4d_takeover_choosingtime", "20", "Time to cast a takeover choice.", CVAR_FLAGS, true, 10.0, true, 60.0);
	cvar_TODelay				= CreateConVar("l4d_takeover_delay", "5", "Delay after a possible takeover is found and before showing any panels to anyone.", CVAR_FLAGS, true, 0.0);
	cvar_FinaleOnly				= CreateConVar("l4d_takeover_finaleonly", "0", "Allow takeovers only in finale maps.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_DisplayBotName			= CreateConVar("l4d_takeover_displaybotname", "1", "Display the bot name when a takeover executes.", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_takeover");

	cvar_SurvivorLimit = FindConVar("survivor_limit");

	// Sounds
	if (!EnableSounds_Takeover)
		EnableSounds_Takeover = PrecacheSound(SOUND_TAKEOVER);	  // Sound from bot takeover

	RegConsoleCmd("sm_takeover", cmd_Takeover, "Takeover a survivor bot.");
	RegAdminCmd("sm_admintakeover", cmd_TakeoverAdmin, ADMFLAG_GENERIC, "Takeover a survivor bot.");

	HookEvent("player_incapacitated", event_PlayerIncap);
	HookEvent("player_death", event_PlayerDeath, EventHookMode_Pre);
	HookEvent("revive_success", event_PlayerRevive);
	HookEvent("round_start", event_RoundStart);
	HookEvent("finale_start", event_RoundStart);
	HookEvent("mission_lost", event_RoundStop);
	HookEvent("finale_vehicle_leaving", event_RoundStop);
	HookEvent("survivor_rescued", event_PlayerRescued);
	// HookEvent("door_open", event_DoorOpened, EventHookMode_Post); // When the saferoom door opens...
	// HookEvent("player_left_start_area", event_RoundStart, EventHookMode_Post); // When a survivor leaves the start area...
	HookEvent("map_transition", event_RoundStop);
	HookEvent("player_ledge_grab", event_PlayerIncap);
	if (ServerVersion == Engine_Left4Dead2)
	{
		HookEvent("survival_round_start", event_RoundStart);	// Timed Maps event
		HookEvent("scavenge_round_halftime", event_RoundStop);
		HookEvent("scavenge_round_start", event_RoundStart);
		HookEvent("defibrillator_used", event_PlayerRevive);
	}

	PeriodicTakeoverCheckTimer = CreateTimer(10.0, timer_TakeoverCheck, INVALID_HANDLE, TIMER_REPEAT);

	ResetPluginVariables();
}

public void OnPluginEnd()
{
	DisableTakeovers();

	if (PeriodicTakeoverCheckTimer != INVALID_HANDLE)
	{
		CloseHandle(PeriodicTakeoverCheckTimer);
		PeriodicTakeoverCheckTimer = INVALID_HANDLE;
	}
}

// Initializes the plugin onload also
public void OnMapStart()
{
	if (GetConVarBool(cvar_FinaleOnly))
		return;

	Initialize();
}

public void Initialize()
{
	ResetPluginVariables();

	TakeoversEnabled = true;
}

void ResetPluginVariables()
{
	for (int i = 0; i <= MaxClients; i++)
		ResetClientVariables(i);
}

void ResetClientVariables(int client)
{
	ResetPlayerWaitingForTakeover(client);
	PlayerTakeoverVote[client] = VOTE_UNDEFINED;
	PlayerChoseNo[client]	   = false;
}

void ResetPlayerDelayedChoosingPanel(int client)
{
	if (PlayerDelayedChoosingPanel[client] != INVALID_HANDLE)
	{
		CloseHandle(PlayerDelayedChoosingPanel[client]);
		PlayerDelayedChoosingPanel[client] = INVALID_HANDLE;
	}
}

void ResetPlayerWaitingForTakeover(int client)
{
	ResetPlayerDelayedChoosingPanel(client);
	PlayerDisplayingChoosingPanel[client] = false;
}

Action cmd_TakeoverAdmin(int client, int args)
{
	if (client <= 0)
		return Plugin_Continue;

	PlayerChoseNo[client] = false;

	if (!ExecuteTakeover(client, true))
		TOPrintToChatPreFormatted(client, "Takeover \x05FAILED\x01.");

	return Plugin_Handled;
}

Action cmd_Takeover(int client, int args)
{
	if (client <= 0)
		return Plugin_Handled;

	PlayerChoseNo[client] = false;

	if (!TOIsClientInGameHuman(client))
		return Plugin_Handled;

	if (!IsTakeoverEnabled())
	{
		TOPrintToChatPreFormatted(client, "Takeover is \x05CURRENTLY DISABLED\x01.");
		return Plugin_Handled;
	}

	if (!GetConVarBool(cvar_ManualTO))
	{
		TOPrintToChatPreFormatted(client, "Manual takeover by console command is \x05DISABLED\x01.");
		return Plugin_Handled;
	}

	if (IsPlayerAlive(client))
	{
		bool ManualTOIncap = GetConVarBool(cvar_ManualTOIncap);

		if (ManualTOIncap && !TOIsClientIncapacitated(client))
		{
			TOPrintToChatPreFormatted(client, "You cannot execute a takeover before you're incapacitated or dead.");
			return Plugin_Handled;
		}

		if (!ManualTOIncap)
		{
			TOPrintToChatPreFormatted(client, "You cannot execute a takeover before you're dead.");
			return Plugin_Handled;
		}
	}

	if (!ExecuteTakeover(client))
		TOPrintToChatPreFormatted(client, "Takeover \x05FAILED\x01.");

	return Plugin_Handled;
}

Action event_PlayerIncap(Handle event, const char[] name, bool dontBroadcast)
{
	CheckSurvivorsAllDown();

	if (!IsTakeoverEnabled())
		return Plugin_Stop;

	int Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (PlayerChoseNo[Victim] || !GetConVarBool(cvar_AutoTOIncap) && TOGetTeamHumanCount(TEAM_SURVIVORS, Victim))
		return Plugin_Stop;

	ExecuteTakeoverCheck(Victim);
	return Plugin_Handled;
}

Action event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Victim <= 0 || !TOIsClientInTeam(Victim, TEAM_SURVIVORS))
		return Plugin_Stop;

	CheckSurvivorsAllDown();

	if (!IsTakeoverEnabled() || GetEventBool(event, "victimisbot"))
		return Plugin_Stop;

	if (PlayerChoseNo[Victim] || !TOIsClientInGameHuman(Victim))
		return Plugin_Handled;

	if (!GetConVarBool(cvar_AutoTODeath))
	{
		if (GetConVarBool(cvar_EnableTOVoting))
			ExecuteTakeoverVote(Victim);

		return Plugin_Handled;
	}

	ExecuteTakeoverCheck(Victim);
	return Plugin_Continue;
}

Action event_PlayerRevive(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsTakeoverEnabled())
		return Plugin_Stop;

	int Subject = GetClientOfUserId(GetEventInt(event, "subject"));

	if (!IsClientConnected(Subject) || !IsFakeClient(Subject))
		return Plugin_Handled;

	ExecuteTakeoverCheck();
	return Plugin_Handled;
}

Action event_PlayerRescued(Handle event, const char[] name, bool dontBroadcast)
{
	if (!IsTakeoverEnabled())
		return Plugin_Stop;

	int Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsClientConnected(Victim) || !IsFakeClient(Victim))
		return Plugin_Handled;

	ExecuteTakeoverCheck();
	return Plugin_Handled;
}

void event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bool IsFinaleRound = StrEqual(name, "finale_start");
	bool FinaleOnly	   = GetConVarBool(cvar_FinaleOnly);

	if (IsFinaleRound && !FinaleOnly || !IsFinaleRound && FinaleOnly)
		return;

	Initialize();
}

/* Action event_DoorOpened(Handle event, const char[] name, bool dontBroadcast)
{
	if (IsTakeoverEnabled() || GetConVarBool(cvar_FinaleOnly) || !GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed"))
		return;

	Initialize();
} */

void event_RoundStop(Handle event, const char[] name, bool dontBroadcast)
{
	DisableTakeovers();
}

Action timer_TakeoverCheck(Handle timer, Handle hndl)
{
	ExecuteTakeoverCheck();
	return Plugin_Continue;
}

Action timer_TakeoverVotingTimeout(Handle timer, int client)
{
	TakeoverVoteTimer = INVALID_HANDLE;
	CountTakeoverVotes(true);
	return Plugin_Continue;
}

Action timer_DelayedTakeoverChoice(Handle timer, int client)
{
	PlayerDelayedChoosingPanel[client] = INVALID_HANDLE;
	DisplayTakeoverChoice(client);
	return Plugin_Continue;
}

void CloseTakeoverVote()
{
	PlayerTakeoverTarget = 0;

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(TakeoverVoteTimer);
		TakeoverVoteTimer = INVALID_HANDLE;
	}

	// TODO: Look for other voting routes
}

void CalculateTakeoverVotes(int &validvoterscount, int &yes, int &no)
{
	validvoterscount = 0;
	yes				 = 0;
	no				 = 0;

	for (int i = 1; i <= MaxClients; i++)
		if (PlayerTakeoverTarget != i && TOIsClientInGameHuman(i))
		{
			validvoterscount++;

			if (PlayerTakeoverVote[i] != VOTE_UNDEFINED)
			{
				if (PlayerTakeoverVote[i] == VOTE_YES)
					yes++;
				else
					no++;
			}
		}
}

void CountTakeoverVotes(bool final = false)
{
	if (PlayerTakeoverTarget <= 0 || !TOIsClientInGameHuman(PlayerTakeoverTarget))
	{
		CloseTakeoverVote();
		return;
	}

	int ValidVotersCount = 0;
	int YesVotes		 = 0;
	int NoVotes			 = 0;
	int WinningVoteCount;

	CalculateTakeoverVotes(ValidVotersCount, YesVotes, NoVotes);

	WinningVoteCount = RoundToNearest(float(ValidVotersCount) / 2);

	if (final || YesVotes >= WinningVoteCount || NoVotes >= WinningVoteCount)
	{
		// TODO: Check the votes and execute ExecuteTakeoverCheck(votedclient)
		CloseTakeoverVote();
	}
}

stock bool IsTakeoverPossible(int human = 0)
{
	if (!IsTakeoverEnabled())
		return false;

	if (human <= 0)
		human = TOFindHuman();

	if (human <= 0 || !IsClientValidForTakeover(human))
		return false;

	// find a bot controlled living survivor
	int bot = TOFindBot();

	if (bot == 0)
		return false;

	return true;
}

void ExecuteTakeoverCheck(int human = 0)
{
	if (!IsTakeoverEnabled())
		return;

	if (human <= 0)
		human = TOFindHuman();

	if (human <= 0 || PlayerChoseNo[human] || !IsTakeoverPossible(human))
		return;

	DelayedTakeoverChoice(human);
}

public void OnClientPostAdminCheck(int client)
{
	ResetClientVariables(client);
}

public void OnClientDisconnect(int client)
{
	ResetClientVariables(client);

	ExecuteTakeoverCheck();
}

public void ExecuteTakeoverVote(int client)
{
	if (!IsTakeoverEnabled() || !TOIsClientInGameHuman(client))
		return;

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		// TODO: Add the player ID to an array, so we can initiate another vote after the previous vote is closed
		return;
	}

	PlayerTakeoverTarget = client;
	TakeoverVoteTimer	 = CreateTimer(GetConVarFloat(cvar_TOVotingTime), timer_TakeoverVotingTimeout, client);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (PlayerTakeoverTarget != i && TOIsClientInGameHuman(i))
		{
			// TODO: Display voting panel...
		}
	}
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool ExecuteTakeover(int client, bool force = false)
{
	if (!force && !IsTakeoverEnabled())
		return false;

	if (!TOIsClientInGameHuman(client))
		return false;

	if (TOGetTeamHumanCount() >= TOGetTeamMaxHumans())
		return false;

	// find a bot controlled living survivor
	int bot = TOFindBot();

	if (bot <= 0)
		return false;

	ResetPlayerWaitingForTakeover(client);

	char playername[64];
	char botname[64];

	GetClientName(client, playername, sizeof(playername));

	if (GetConVarBool(cvar_DisplayBotName))
	{
		GetClientName(bot, botname, sizeof(botname));
		Format(botname, sizeof(botname), " {orange}({olive}%s{orange})", botname);
	}
	else
		botname[0] = '\0';

	// change the team to spectators before the takeover
	ChangeClientTeam(client, TEAM_SPECTATORS);

	// have to do this to give control of a survivor bot
	SDKCall(L4DTakeoverSHS, bot, client);
	SDKCall(L4DTakeoverTOB, client, true);

	if (EnableSounds_Takeover)
		EmitSoundToAll(SOUND_TAKEOVER);
	TakeOverCPrintToChatAll("%t", "TAKEOVER_ANNOUNCE", playername, botname);

	return true;
}

stock int TOFindBot(int team = TEAM_SURVIVORS)
{
	for (int bot = 1; bot <= MaxClients; bot++)
	{
		if (!IsClientConnected(bot))
			continue;

		if (!IsFakeClient(bot))
			continue;

		if (GetClientTeam(bot) != team)
			continue;

		if (!IsClientAlive(bot))
			continue;

		if (TOIsClientIncapacitated(bot))
			continue;

		return bot;
	}

	return 0;
}

stock int TOFindHuman()
{
	for (int human = 1; human <= MaxClients; human++)
	{
		if (!IsClientWaitingForTakeover(human) && IsClientValidForTakeover(human))
			return human;
	}

	return 0;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool TOIsClientInGameHuman(int client, int team = TEAM_SURVIVORS)
{
	if (client > 0) return IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == team;
	else return false;
}

stock bool TOIsClientInGameBot(int client, int team = TEAM_SURVIVORS)
{
	if (client > 0) return IsClientConnected(client) && IsFakeClient(client) && GetClientTeam(client) == team;
	else return false;
}

stock bool IsClientValidForTakeover(int client)
{
	if (client <= 0 || PlayerChoseNo[client] || IsClientWaitingForTakeover(client))
		return false;

	if (!TOIsClientInGameHuman(client))
		return false;

	if (IsPlayerAlive(client))
	{
		bool IsClientIncapacitated = TOIsClientIncapacitated(client);

		if (!IsClientIncapacitated || IsClientIncapacitated && !GetConVarInt(cvar_AutoTOIncap))
			return false;
	}

	return true;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock int TOGetTeamHumanCount(int team = TEAM_SURVIVORS, int no_count_client = 0)
{
	int humans = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != no_count_client && TOIsClientInGameHuman(i, team))
			humans++;
	}

	return humans;
}

stock int TOGetTeamBotCount(int team = TEAM_SURVIVORS)
{
	int bots = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (TOIsClientInGameBot(i) && GetClientTeam(i) == team && GetClientHealth(i) > 0 && !TOIsClientIncapacitated(i))
			bots++;
	}
	return bots;
}

stock int TOGetTeamMaxHumans(int team = TEAM_SURVIVORS)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return -1;
		case TEAM_SPECTATORS:
			return MaxClients;
	}

	return -1;
}

void DisplayYesNoPanel(int client, MenuHandler handler, int delay = 30)
{
	if (!client || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client))
		return;
	char   title[MAX_MESSAGE_LENGTH];
	char   text[MAX_MESSAGE_LENGTH];
	Handle panel = CreatePanel();
	Format(title, sizeof(title), "%t.", "TAKEOVERCHOICE_QUESTION");
	SetPanelTitle(panel, title);
	Format(text, sizeof(text), "%t", "yes");
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "no");
	DrawPanelItem(panel, text);
	SendPanelToClient(panel, client, handler, delay);
	CloseHandle(panel);
}

public void DelayedTakeoverChoice(int client)
{
	if (!IsTakeoverEnabled() || IsClientWaitingForTakeover(client) || !IsTakeoverPossible(client))
		return;

	float Delay = GetConVarFloat(cvar_TODelay);

	if (Delay <= 0.0)
	{
		DisplayTakeoverChoice(client);
		return;
	}

	PlayerDelayedChoosingPanel[client] = CreateTimer(Delay, timer_DelayedTakeoverChoice, client);
}

public void DisplayTakeoverChoice(int client)
{
	if (!IsTakeoverEnabled() || IsClientWaitingForTakeover(client) || !IsTakeoverPossible(client))
		return;

	if (!GetConVarBool(cvar_RequestTOConfirmation))
	{
		ExecuteTakeover(client);
		return;
	}

	PlayerDisplayingChoosingPanel[client] = true;
	DisplayYesNoPanel(client, TakeoverChoicePanelHandler, RoundToNearest(GetConVarFloat(cvar_TOChoosingTime)));
}

public int TakeoverChoicePanelHandler(Handle menu, MenuAction action, int client, int selection)
{
	PlayerDisplayingChoosingPanel[client] = false;

	if (action != MenuAction_Select)
		return 0;

	if (selection == VOTE_NO){
		PlayerChoseNo[client] = true;
		return 2;
	}

	if (selection != VOTE_YES)
		return 0;

	if (!IsClientValidForTakeover(client) || !ExecuteTakeover(client))
		TOPrintToChatPreFormatted(client, "%t \x05%t\x01.", "titleLowerCase", "failed");
	return 0;
}

public void TOPrintToChatPreFormatted(int client, char[] message, any...)
{
	PrintToChat(client, "\x04[\x03%t\x04] \x01%s", "titleUpperCase", message);
}

stock void TakeOverCPrintToChatAll(const char[] TOMessage, any...)
// {blue}: azul
// {orange}: naranja
// {olive}: verde
// {default}: blanco

{
	char TOBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i])
		{
			SetGlobalTransTarget(i);
			VFormat(TOBuffer, sizeof(TOBuffer), TOMessage, 2);
			CPrintToChat(i, "{orange}[{blue}%s{orange}] {olive}%s", TAG, TOBuffer);
		}
	}
}

stock bool TOIsClientIncapacitated(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

stock bool IsClientAlive(int client)
{
	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return GetClientHealth(client) > 0 && GetEntProp(client, Prop_Send, "m_lifeState") == 0;
	else if (!IsClientInGame(client))
		return false;

	return IsPlayerAlive(client);
}

void CheckSurvivorsAllDown()
{
	if (!IsTakeoverEnabled())
		return;
	for (int i = 1; i <= MaxClients; i++)

	{
		if (IsClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVORS && !TOIsClientIncapacitated(i))
			return;
	}

	// If we ever get this far it means the surviviors are all down or dead!
	DisableTakeovers();
}

stock bool TOIsClientInTeam(int client, int team = TEAM_SURVIVORS)
{
	if (client <= 0 || !IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return (GetClientTeam(client) == team);
	else
		return (IsClientInGame(client) && GetClientTeam(client) == team);
}

void DisableTakeovers()
{
	TakeoversEnabled	   = false;
	TakeoversEnabledFinale = false;

	ResetPluginVariables();

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(TakeoverVoteTimer);
		TakeoverVoteTimer = INVALID_HANDLE;
	}
}

bool IsTakeoverEnabled()
{
	if (GetConVarBool(cvar_FinaleOnly))
		return TakeoversEnabledFinale;
	else
		return TakeoversEnabled;
}

stock bool IsClientWaitingForTakeover(int client)
{
	return (client > 0 && (PlayerDelayedChoosingPanel[client] != INVALID_HANDLE || PlayerDisplayingChoosingPanel[client]));
}
