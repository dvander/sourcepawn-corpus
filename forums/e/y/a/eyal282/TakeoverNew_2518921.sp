/*///////////////////////////////////////////////////////////////////////////////////////

	A SourceMod plugin for Left 4 Dead and Left 4 Dead 2

*/
#define PLUGIN_NAME					"Survivor Bot Takeover"
#define PLUGIN_VERSION			"0.8"
#define PLUGIN_DESCRIPTION	"Allows dead survivors to take over a living bot survivor."
/*

	Programmer: Mikko Andersson (muukis)
	URL: http://forums.alliedmods.net/showthread.php?t=127987
	Date: 27.05.2010

*////////////////////////////////////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#define TEAM_UNDEFINED 0
#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define SERVER_VERSION_L4D1 40
#define SERVER_VERSION_L4D2 50

#define VOTE_UNDEFINED 0
#define VOTE_YES 1
#define VOTE_NO 2

#define IsPlayer(%1) (1 <= %1 <= MAXPLAYERS)

#define SOUND_TAKEOVER "items/suitchargeok1.wav"

new String:TAKEOVERVOTE_QUESTION[256] = "Allow %s to takeover a bot controlled living survivor?";
new String:TAKEOVERCHOICE_QUESTION[256] = "Do you want to takeover a bot controlled living survivor?";

new ServerVersion = SERVER_VERSION_L4D1;
new bool:EnableSounds_Takeover = true;
new bool:TakeoversEnabled = false;
new bool:TakeoversEnabledFinale = false;
new PlayerTakeoverTarget = 0;
new PlayerTakeoverVote[MAXPLAYERS+1];
new bool:PlayerChoseNo[MAXPLAYERS+1];
new bool:PlayerDisplayingChoosingPanel[MAXPLAYERS+1];

new Handle:cvar_ManualTO = INVALID_HANDLE;
new Handle:cvar_ManualTOIncap = INVALID_HANDLE;
new Handle:cvar_AutoTOIncap = INVALID_HANDLE;
new Handle:cvar_AutoTODeath = INVALID_HANDLE;
new Handle:cvar_RequestTOConfirmation = INVALID_HANDLE;
new Handle:cvar_EnableTOVoting = INVALID_HANDLE;
new Handle:cvar_TOVotingTime = INVALID_HANDLE;
new Handle:cvar_TOChoosingTime = INVALID_HANDLE;
new Handle:cvar_TODelay = INVALID_HANDLE;
new Handle:cvar_SurvivorLimit = INVALID_HANDLE;
new Handle:cvar_FinaleOnly = INVALID_HANDLE;
new Handle:cvar_DisplayBotName = INVALID_HANDLE;
new Handle:L4DTakeoverConf = INVALID_HANDLE;
new Handle:L4DTakeoverSHS = INVALID_HANDLE;
new Handle:L4DTakeoverTOB = INVALID_HANDLE;
new Handle:TakeoverVoteTimer = INVALID_HANDLE;
new Handle:PlayerDelayedChoosingPanel[MAXPLAYERS+1];
new Handle:PeriodicTakeoverCheckTimer = INVALID_HANDLE;

// Plugin Info
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Mikko Andersson (muukis)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/"
};

// Here we go!
public OnPluginStart()
{
	// Require Left 4 Dead (2)
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead", false) &&
			!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}

	// Plugin version public Cvar
	CreateConVar("l4d_takeover_version", PLUGIN_VERSION, "Survivor Bot Takeover Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if (FileExists("addons/sourcemod/gamedata/l4d_takeover.txt"))
	{
		// SDK handles for survivor bot takeover
		L4DTakeoverConf = LoadGameConfigFile("l4d_takeover");

		if (L4DTakeoverConf == INVALID_HANDLE)
		{
			SetFailState("Survivor Bot Takeover is disabled because could not load gamedata/l4d_takeover.txt");
			return;
		}
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DTakeoverConf, SDKConf_Signature, "SetHumanSpec");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DTakeoverSHS = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DTakeoverConf, SDKConf_Signature, "TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DTakeoverTOB = EndPrepSDKCall();
		}
	}
	else
	{
		SetFailState("Survivor Bot Takeover is disabled because could not load gamedata/l4d_takeover.txt");
		return;
	}

	ServerVersion = GuessSDKVersion();

	cvar_ManualTO = CreateConVar("l4d_takeover_manual", "1", "Allow dead survivor players to execute console command \"sm_takeover\" to takeover a survivor bot.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ManualTOIncap = CreateConVar("l4d_takeover_manualincap", "1", "Allow incapped survivor players to execute console command \"sm_takeover\" to takeover a survivor bot.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoTOIncap = CreateConVar("l4d_takeover_autoincap", "0", "Execute a takeover automatically when a player incaps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoTODeath = CreateConVar("l4d_takeover_autodeath", "0", "Execute a takeover automatically when a player dies. Enabling this will disable the takeover voting.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RequestTOConfirmation = CreateConVar("l4d_takeover_requestconf", "1", "Request confirmation from the player before executing a takeover.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTOVoting = CreateConVar("l4d_takeover_votingenabled", "0", "Initiate a vote for a takeover when a player dies.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_TOVotingTime = CreateConVar("l4d_takeover_votingtime", "20", "Time to cast a takeover vote.", FCVAR_PLUGIN, true, 10.0, true, 60.0);
	cvar_TOChoosingTime = CreateConVar("l4d_takeover_choosingtime", "20", "Time to cast a takeover choice.", FCVAR_PLUGIN, true, 10.0, true, 60.0);
	cvar_TODelay = CreateConVar("l4d_takeover_delay", "5", "Delay after a possible takeover is found and before showing any panels to anyone.", FCVAR_PLUGIN, true, 0.0);
	cvar_FinaleOnly = CreateConVar("l4d_takeover_finaleonly", "0", "Allow takeovers only in finale maps.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_DisplayBotName = CreateConVar("l4d_takeover_displaybotname", "1", "Display the bot name when a takeover executes.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_takeover");

	cvar_SurvivorLimit = FindConVar("survivor_limit");

	// Sounds
	EnableSounds_Takeover = IsSoundPrecached(SOUND_TAKEOVER);

	if (!EnableSounds_Takeover)
		EnableSounds_Takeover = PrecacheSound(SOUND_TAKEOVER); // Sound from bot takeover

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
	//HookEvent("door_open", event_DoorOpened, EventHookMode_Post); // When the saferoom door opens...
	//HookEvent("player_left_start_area", event_RoundStart, EventHookMode_Post); // When a survivor leaves the start area...
	HookEvent("map_transition", event_RoundStop);
	HookEvent("player_ledge_grab", event_PlayerIncap);
	if (ServerVersion == SERVER_VERSION_L4D2)
	{
		HookEvent("survival_round_start", event_RoundStart); // Timed Maps event
		HookEvent("scavenge_round_halftime", event_RoundStop);
		HookEvent("scavenge_round_start", event_RoundStart);
		HookEvent("defibrillator_used", event_PlayerRevive);
	}

	PeriodicTakeoverCheckTimer = CreateTimer(10.0, timer_TakeoverCheck, INVALID_HANDLE, TIMER_REPEAT);

	ResetPluginVariables();
}

public OnPluginEnd()
{
	DisableTakeovers();

	if (PeriodicTakeoverCheckTimer != INVALID_HANDLE)
	{
		CloseHandle(PeriodicTakeoverCheckTimer);
		PeriodicTakeoverCheckTimer = INVALID_HANDLE;
	}
}

// Initializes the plugin onload also
public OnMapStart()
{
	if (GetConVarBool(cvar_FinaleOnly))
		return;

	Initialize();
}

public Initialize()
{
	ResetPluginVariables();

	TakeoversEnabled = true;
}

ResetPluginVariables()
{
	for (new i = 0; i <= MAXPLAYERS; i++)
		ResetClientVariables(i);
}

ResetClientVariables(client)
{
	ResetPlayerWaitingForTakeover(client);
	PlayerTakeoverVote[client] = VOTE_UNDEFINED;
	PlayerChoseNo[client] = false;
}

ResetPlayerDelayedChoosingPanel(client)
{
	if (PlayerDelayedChoosingPanel[client] != INVALID_HANDLE)
	{
		CloseHandle(PlayerDelayedChoosingPanel[client]);
		PlayerDelayedChoosingPanel[client] = INVALID_HANDLE;
	}
}

ResetPlayerWaitingForTakeover(client)
{
	ResetPlayerDelayedChoosingPanel(client);
	PlayerDisplayingChoosingPanel[client] = false;
}

public Action:cmd_TakeoverAdmin(client, args)
{
	if (client <= 0)
		return Plugin_Continue;

	PlayerChoseNo[client] = false;

	if (!ExecuteTakeover(client, true))
		TOPrintToChatPreFormatted(client, "Takeover \x05FAILED\x01.");

	return Plugin_Handled;
}

public Action:cmd_Takeover(client, args)
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
		new bool:ManualTOIncap = GetConVarBool(cvar_ManualTOIncap);

		if (ManualTOIncap && !TOIsClientIncapacitated(client) && !IsClientTrapped(client))
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

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckSurvivorsAllDown();

	if (!IsTakeoverEnabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (PlayerChoseNo[Victim] || !GetConVarBool(cvar_AutoTOIncap) && TOGetTeamHumanCount(TEAM_SURVIVORS, Victim))
		return;

	ExecuteTakeoverCheck(Victim);
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Victim <= 0 || !TOIsClientInTeam(Victim, TEAM_SURVIVORS))
		return;

	CheckSurvivorsAllDown();

	if (!IsTakeoverEnabled() || GetEventBool(event, "victimisbot"))
		return;

	if (PlayerChoseNo[Victim] || !TOIsClientInGameHuman(Victim))
		return;

	if (!GetConVarBool(cvar_AutoTODeath))
	{
		if (GetConVarBool(cvar_EnableTOVoting))
			ExecuteTakeoverVote(Victim);

		return;
	}

	ExecuteTakeoverCheck(Victim);
}

public Action:event_PlayerRevive(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsTakeoverEnabled())
		return;

	new Subject = GetClientOfUserId(GetEventInt(event, "subject"));

	if (!IsClientConnected(Subject) || !IsFakeClient(Subject))
		return;

	ExecuteTakeoverCheck();
}

public Action:event_PlayerRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsTakeoverEnabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsClientConnected(Victim) || !IsFakeClient(Victim))
		return;

	ExecuteTakeoverCheck();
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:IsFinaleRound = StrEqual(name, "finale_start");
	new bool:FinaleOnly = GetConVarBool(cvar_FinaleOnly);

	if (IsFinaleRound && !FinaleOnly || !IsFinaleRound && FinaleOnly)
		return;

	Initialize();
}

public Action:event_DoorOpened(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsTakeoverEnabled() || GetConVarBool(cvar_FinaleOnly) || !GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed"))
		return;

	Initialize();
}

public Action:event_RoundStop(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisableTakeovers();
}

public Action:timer_TakeoverCheck(Handle:timer, Handle:hndl)
{
	ExecuteTakeoverCheck();
}

public Action:timer_TakeoverVotingTimeout(Handle:timer, any:client)
{
	TakeoverVoteTimer = INVALID_HANDLE;
	CountTakeoverVotes(true);
}

public Action:timer_DelayedTakeoverChoice(Handle:timer, any:client)
{
	PlayerDelayedChoosingPanel[client] = INVALID_HANDLE;
	DisplayTakeoverChoice(client);
}

CloseTakeoverVote()
{
	PlayerTakeoverTarget = 0;

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(TakeoverVoteTimer);
		TakeoverVoteTimer = INVALID_HANDLE;
	}

	//TODO: Look for other voting routes
}

CalculateTakeoverVotes(&validvoterscount, &yes, &no)
{
	validvoterscount = 0;
	yes = 0;
	no = 0;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
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

CountTakeoverVotes(bool:final=false)
{
	if (PlayerTakeoverTarget <= 0 || !TOIsClientInGameHuman(PlayerTakeoverTarget))
	{
		CloseTakeoverVote();
		return;
	}

	new ValidVotersCount = 0, YesVotes = 0, NoVotes = 0;
	new WinningVoteCount;

	CalculateTakeoverVotes(ValidVotersCount, YesVotes, NoVotes);

	WinningVoteCount = RoundToNearest(float(ValidVotersCount) / 2);

	if (final || YesVotes >= WinningVoteCount || NoVotes >= WinningVoteCount)
	{
		//TODO: Check the votes and execute ExecuteTakeoverCheck(votedclient)
		CloseTakeoverVote();
	}
}

stock bool:IsTakeoverPossible(human=0)
{
	if (!IsTakeoverEnabled())
		return false;

	if (human <= 0)
		human = TOFindHuman();

	if (human <= 0 || !IsClientValidForTakeover(human))
		return false;

	//find a bot controlled living survivor
	new bot = TOFindBot();

	if (bot == 0)
		return false;

	return true;
}

ExecuteTakeoverCheck(human=0)
{
	if (!IsTakeoverEnabled())
		return;

	if (human <= 0)
		human = TOFindHuman();

	if (human <= 0 || PlayerChoseNo[human] || !IsTakeoverPossible(human))
		return;

	DelayedTakeoverChoice(human);
}

public OnClientPostAdminCheck(client)
{
	ResetClientVariables(client);
}

public OnClientDisconnect(client)
{
	ResetClientVariables(client);

	ExecuteTakeoverCheck();
}

public ExecuteTakeoverVote(client)
{
	if (!IsTakeoverEnabled() || !TOIsClientInGameHuman(client))
		return;

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		//TODO: Add the player ID to an array, so we can initiate another vote after the previous vote is closed
		return;
	}

	PlayerTakeoverTarget = client;
	TakeoverVoteTimer = CreateTimer(GetConVarFloat(cvar_TOVotingTime), timer_TakeoverVotingTimeout, client);

	new maxplayers = GetMaxClients();

	for(new i = 1; i < maxplayers + 1; i++)
	{
		if(PlayerTakeoverTarget != i && TOIsClientInGameHuman(i))
		{
			//TODO: Display voting panel...
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

stock bool:ExecuteTakeover(client, bool:force=false)
{
	if (!force && !IsTakeoverEnabled())
		return false;

	if (!TOIsClientInGameHuman(client))
		return false;

	if(TOGetTeamHumanCount() >= TOGetTeamMaxHumans())
		return false;

	ResetPlayerWaitingForTakeover(client);

	new maxplayers = GetMaxClients();
	new Tiers[6][maxplayers];
	
	if(!FormatTiers(Tiers))
		return false;
	
	
	new Handle:menu = CreateMenu(TakeOverMenuSelected);
	SetMenuTitle(menu, "Bots to take over:");
	
	for(new i;i < 6;i++)
	{
		for(new bot;bot < maxplayers;bot++) // The Tiers[0-6] start from 0, not 1 unlike client indexes.
		{
			new Target = Tiers[i][bot];
			new String:BotID[4], String:BotInfo[100], String:BotName[32], String:BotStatus[32];
			
			if(!IsPlayer(Target))
				continue;
				
			GetClientName(Target, BotName, sizeof(BotName));
			
			IntToString(Target, BotID, sizeof(BotID));
			
			if(i == 0)
				Format(BotStatus, sizeof(BotStatus), "Standing");
			
			else if(i == 1)
				Format(BotStatus, sizeof(BotStatus), "Incap");
			
			else if(i == 2)
				Format(BotStatus, sizeof(BotStatus), "Jockeyed");
			
			else if(i == 3)
				Format(BotStatus, sizeof(BotStatus), "Hanging");
			
			else if(i == 4)
				Format(BotStatus, sizeof(BotStatus), "Pinned");
			
			else if(i == 5)
				Format(BotStatus, sizeof(BotStatus), "Incap & Pinned");
			
			Format(BotInfo, sizeof(BotInfo), "%s ( %i HP ) ( %s )", BotName, GetEntProp(Target, Prop_Send, "m_iHealth"), BotStatus);
			AddMenuItem(menu, BotID, BotInfo);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return true;
}

public TakeOverMenuSelected(Handle:menu, MenuAction:action, client, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			new bot = StringToInt(item);

			if (IsClientConnected(bot))
			{
				if(IsFakeClient(bot) && GetClientTeam(bot) == 2 && IsClientAlive(bot))
				TakeOverBetween(client, bot);
			}		
		}
	}
}
			
stock TakeOverBetween(client, bot)
{
	//change the team to spectators before the takeover
	ChangeClientTeam(client, TEAM_SPECTATORS);


	decl String:playername[64], String:botname[64];

	GetClientName(client, playername, sizeof(playername));

	if (GetConVarBool(cvar_DisplayBotName))
	{
		GetClientName(bot, botname, sizeof(botname));
		Format(botname, sizeof(botname), " (\x03%s\x01)", botname);
	}
	else
		botname[0] = '\0';
		
	//have to do this to give control of a survivor bot
	SDKCall(L4DTakeoverSHS, bot, client);
	SDKCall(L4DTakeoverTOB, client, true);

	if (EnableSounds_Takeover)
		EmitSoundToAll(SOUND_TAKEOVER);	
	
	TOPrintToChatAll("Player \x05%s \x01was put in control of a survivor bot%s.", playername, botname);
}

stock TOFindBot()
{
	new Tiers[6][MAXPLAYERS];
	if(!FormatTiers(Tiers))
		return false;
	
	return true;
}
stock bool:FormatTiers(Tiers[][])
{
	new maxplayers = GetMaxClients();
	new CurrentCell[6];
	new bool:Hope = false;
	for(new i;i < 6;i++)
	{
			for(new num;num < maxplayers;num++)
			{
				Tiers[i][num] = -1;
			}
	}
	for (new bot = 1; bot <= maxplayers; bot++)
	{
		if (!IsClientConnected(bot))
			continue;

		if (!IsFakeClient(bot))
			continue;

		if (GetClientTeam(bot) != TEAM_SURVIVORS)
			continue;

		if (!IsClientAlive(bot))
			continue;
		
		Hope = true;
		new Health = GetEntProp(bot, Prop_Send, "m_iHealth");
		
		if(!IsClientTrapped(bot) && !TOIsClientIncapacitated(bot)) // Tier 0: Client is up and not trapped.
		{
			Tiers[0][CurrentCell[0]] = bot;
			CurrentCell[0]++;
		}
		
		else if(!IsClientTrapped(bot) && IsClientIncap(bot)) // Tier 4: Client is incapacitated but not trapped ( can shoot and stuff and most servers that use this have rushers haha ).
		{
			Tiers[1][CurrentCell[1]] = bot;
			CurrentCell[1]++;
		}
		
		else if(IsClientTrapped(bot) && GetEntProp(bot, Prop_Send, "m_jockeyAttacker") > 0 && !IsClientIncap(bot)) // Tier 4: Client is incapacitated but not trapped ( can shoot and stuff and most servers that use this have rushers haha ).
		{
			Tiers[2][CurrentCell[2]] = bot;
			CurrentCell[2]++;
		}
		
		else if(IsClientHanging(bot))
		{
			Tiers[3][CurrentCell[3]] = bot;
			CurrentCell[3]++;
		}
		
		else if(IsClientTrapped(bot) && !TOIsClientIncapacitated(bot)) // Tier 5: Client is trapped but not incapacitated.
		{
			Tiers[4][CurrentCell[4]] = bot;
			CurrentCell[4]++;
		}
		
		else if(IsClientTrapped(bot) && TOIsClientIncapacitated(bot)) // Tier 6: Client is trapped and incapacitated. Ouch...
		{
			Tiers[5][CurrentCell[5]] = bot;
			CurrentCell[5]++;
		}
	}
	
	for(new i;i < 6;i++)
		SortCustom1D(Tiers[i], CurrentCell[i], SortTiersHealth);
	
	return Hope;
}

public SortTiersHealth(First, Second, const Array[], Handle:hndl) 
{ 
	
    if (GetClientHealth(First) == GetClientHealth(Second)) 
    { 
        return 0; 
    } 
    else if(GetClientHealth(First) < GetClientHealth(Second)) 
    { 
        return 1; 
    } 
    else 
    { 
        return -1; 
    } 
} 
stock bool IsClientTrapped(client) // Not incap by a Special Infected
{
	if(GetClientTeam(client) != TEAM_SURVIVORS)
		return false;
	
	//new String:Name[32];
	//GetClientName(client, Name, sizeof(Name));
	//PrintToChatAll("Test %s", Name);
	// Jockey excluded because he doesn't get you until you die.
	
	return ( ( GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 ) || ( GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 ) || ( GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 ) || ( GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0 ) ) ? true : false;
}
stock TOFindHuman()
{
	new maxplayers = GetMaxClients();

	for (new human = 1; human <= maxplayers; human++)
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

stock bool:TOIsClientInGameHuman(client, team=TEAM_SURVIVORS)
{
	if (client > 0) return IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && GetClientTeam(client) == team;
	else return false;
}

stock bool:TOIsClientInGameBot(client, team=TEAM_SURVIVORS)
{
	if (client > 0) return IsClientConnected(client) && IsFakeClient(client) && GetClientTeam(client) == team;
	else return false;
}

stock bool:IsClientValidForTakeover(client)
{
	if (client <= 0 || PlayerChoseNo[client] || IsClientWaitingForTakeover(client))
		return false;

	if (!TOIsClientInGameHuman(client))
		return false;

	if (IsPlayerAlive(client))
	{
		new bool:IsClientIncapacitated = TOIsClientIncapacitated(client);

		if (!IsClientIncapacitated || IsClientIncapacitated && !GetConVarInt(cvar_AutoTOIncap))
			if(!IsClientTrapped(client))
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

stock TOGetTeamHumanCount(team=TEAM_SURVIVORS, no_count_client=0)
{
	new humans = 0, maxplayers = GetMaxClients();
	
	for(new i = 1; i < maxplayers + 1; i++)
	{
		if(i != no_count_client && TOIsClientInGameHuman(i, team))
			humans++;
	}
	
	return humans;
}

stock TOGetTeamBotCount(team=TEAM_SURVIVORS)
{
	new bots = 0, maxplayers = GetMaxClients();
	
	for(new i = 1; i < maxplayers + 1; i++)
	{
		if(TOIsClientInGameBot(i) && GetClientTeam(i) == team && GetClientHealth(i) > 0 && !TOIsClientIncapacitated(i))
			bots++;
	}
	
	return bots;
}

stock TOGetTeamMaxHumans(team=TEAM_SURVIVORS)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return -1;
		case TEAM_SPECTATORS:
			return GetMaxClients();
	}
	
	return -1;
}

DisplayYesNoPanel(client, const String:title[], MenuHandler:handler, delay=30)
{
	if (!client || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client))
		return;

	new Handle:panel = CreatePanel();

	SetPanelTitle(panel, title);

	DrawPanelItem(panel, "Yes");
	DrawPanelItem(panel, "No");

	SendPanelToClient(panel, client, handler, delay);
	CloseHandle(panel);
}

public DisplayTakeoverVote(client)
{
	DisplayYesNoPanel(client, TAKEOVERVOTE_QUESTION, TakeoverVotePanelHandler, RoundToNearest(GetConVarFloat(cvar_TOVotingTime)));
}

public TakeoverVotePanelHandler(Handle:menu, MenuAction:action, client, selection)
{
	if (action != MenuAction_Select || !TOIsClientInGameHuman(client))
		return;

	if (selection == VOTE_YES || selection == VOTE_NO)
	{
		//TODO: Store client vote and calculate if requirements are met for closing the vote
	}
}

public DelayedTakeoverChoice(client)
{
	if (!IsTakeoverEnabled() || IsClientWaitingForTakeover(client) || !IsTakeoverPossible(client))
		return;

	new Float:Delay = GetConVarFloat(cvar_TODelay);

	if (Delay <= 0.0)
	{
		DisplayTakeoverChoice(client);
		return;
	}

	PlayerDelayedChoosingPanel[client] = CreateTimer(Delay, timer_DelayedTakeoverChoice, client);
}

public DisplayTakeoverChoice(client)
{
	if (!IsTakeoverEnabled() || IsClientWaitingForTakeover(client) || !IsTakeoverPossible(client))
		return;

	if (!GetConVarBool(cvar_RequestTOConfirmation))
	{
		ExecuteTakeover(client);
		return;
	}

	PlayerDisplayingChoosingPanel[client] = true;
	DisplayYesNoPanel(client, TAKEOVERCHOICE_QUESTION, TakeoverChoicePanelHandler, RoundToNearest(GetConVarFloat(cvar_TOChoosingTime)));
}

public TakeoverChoicePanelHandler(Handle:menu, MenuAction:action, client, selection)
{
	PlayerDisplayingChoosingPanel[client] = false;

	if (action != MenuAction_Select)
		return;

	if (selection == VOTE_NO)
		PlayerChoseNo[client] = true;

	if (selection != VOTE_YES)
		return;

	if (!IsClientValidForTakeover(client) || !ExecuteTakeover(client))
		TOPrintToChatPreFormatted(client, "Takeover \x05FAILED\x01.");
}

public TOPrintToChat(client, const String:message[], any:...)
{
	new String:FormattedMessage[128];
	VFormat(FormattedMessage, sizeof(FormattedMessage), message, 3);

	TOPrintToChatPreFormatted(client, FormattedMessage);
}

public TOPrintToChatPreFormatted(client, const String:message[])
{
	PrintToChat(client, "\x04[\x03TAKEOVER\x04] \x01%s", message);
}

public TOPrintToChatAll(const String:message[], any:...)
{
	new String:FormattedMessage[128];
	VFormat(FormattedMessage, sizeof(FormattedMessage), message, 2);

	TOPrintToChatAllPreFormatted(FormattedMessage);
}

public TOPrintToChatAllPreFormatted(const String:message[])
{
	PrintToChatAll("\x04[\x03TAKEOVER\x04] \x01%s", message);
}

stock bool:TOIsClientIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 ||
				 GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || 
				 GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

stock bool:IsClientIncap(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0 && GetEntProp(client, Prop_Send, "m_isFallingFromLedge") == 0;
}

stock bool:IsClientHanging(client)
{

	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || 
		   GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}
stock bool:IsClientAlive(client)
{
	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return GetClientHealth(client) > 0 && GetEntProp(client, Prop_Send, "m_lifeState") == 0;
	else if (!IsClientInGame(client))
			return false;

	return IsPlayerAlive(client);
}

CheckSurvivorsAllDown()
{
	if (!IsTakeoverEnabled())
		return;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVORS && !TOIsClientIncapacitated(i))
			return;
	}

	//If we ever get this far it means the surviviors are all down or dead!
	if(GetConVarInt(FindConVar("director_no_death_check")) == 0) // Some servers are modded.
		DisableTakeovers();
}

stock bool:TOIsClientInTeam(client, team=TEAM_SURVIVORS)
{
	if (client <= 0 || !IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return (GetClientTeam(client) == team);
	else
		return (IsClientInGame(client) && GetClientTeam(client) == team);
}

DisableTakeovers()
{
	TakeoversEnabled = false;
	TakeoversEnabledFinale = false;

	ResetPluginVariables();

	if (TakeoverVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(TakeoverVoteTimer);
		TakeoverVoteTimer = INVALID_HANDLE;
	}
}

bool:IsTakeoverEnabled()
{
	if (GetConVarBool(cvar_FinaleOnly))
		return TakeoversEnabledFinale;
	else
		return TakeoversEnabled;
}

stock bool:IsClientWaitingForTakeover(client)
{
	return (client > 0 && (PlayerDelayedChoosingPanel[client] != INVALID_HANDLE || PlayerDisplayingChoosingPanel[client]));
}
