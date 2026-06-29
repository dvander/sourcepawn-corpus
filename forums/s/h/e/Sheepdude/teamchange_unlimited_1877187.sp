#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION	"1.2.2"
#define UPDATE_URL "http://sheepdude.silksky.com/sourcemod-plugins/raw/default/teamchange_unlimited.txt"

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATE   1
#define TEAM_T          2
#define TEAM_CT         3

public Plugin:myinfo =
{
	name = "TeamChange Unlimited",
	author = "Sheepdude",
	description = "TeamChange Unlimited",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Updater handles
new Handle:h_cvarUpdater;

// Convar handles
new Handle:h_cvarLimitTeams;

// Plugin convar handles
new Handle:h_cvarVersion;
new Handle:h_cvarChat;
new Handle:h_cvarSuicide;
new Handle:h_cvarASuicide;
new Handle:h_cvarMapLimit;
new Handle:h_cvarRoundLimit;
new Handle:h_cvarRestrict[4];
new Handle:h_cvarPenalty;
new Handle:h_cvarImmunity;

// Convar variables
new g_cvarLimitTeams;

// Plugin convar variables
new bool:g_cvarChat;
new bool:g_cvarSuicide;
new bool:g_cvarASuicide;
new g_cvarMapLimit;
new g_cvarRoundLimit;
new bool:g_cvarRestrict[4];
new String:g_cvarPenalty[16];
new bool:g_cvarImmunity;

// Plugin variables
new g_MapCount[MAXPLAYERS+1];
new g_RoundCount[MAXPLAYERS+1];

/******
 *Load*
*******/

public OnPluginStart() 
{
	// Event hooks
	HookEventEx("round_start", OnRoundStart);
	HookEventEx("teamplay_round_start", OnRoundStart);
	
	// Commands
	AddCommandListener(JoinTeamCmd, "jointeam");
	
	// Updater convar
	h_cvarUpdater = CreateConVar("sm_teamchange_unlimited_auto_update", "1", "Update plugin automatically if Updater is installed (1 - auto update, 0 - don't update", 0, true, 0.0, true, 1.0);

	// Convars
	h_cvarVersion     = CreateConVar("sm_teamchange_unlimited_version", PLUGIN_VERSION, "Plugin version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	h_cvarChat        = CreateConVar("sm_teamchange_unlimited_chat", "1", "Give plugin feedback to players in chat (1 - verbose, 0 - silent)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarSuicide     = CreateConVar("sm_teamchange_unlimited_suicide", "1", "Force suicide on alive players who switch teams (1 - force suicide, 0 - no suicide)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarASuicide    = CreateConVar("sm_teamchange_unlimited_suicide_admin", "1", "Force suicide on alive admins who switch teams (admin override: teamchange_unlimited_suicide_admin)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarMapLimit    = CreateConVar("sm_teamchange_unlimited_maplimit", "0", "Number of times a client can change teams per map (0 - disable)", FCVAR_NOTIFY, true, 0.0);
	h_cvarRoundLimit  = CreateConVar("sm_teamchange_unlimited_roundlimit", "0", "Number of times a client can change teams per round (0 - disable)", FCVAR_NOTIFY, true, 0.0);
	h_cvarRestrict[0] = CreateConVar("sm_teamchange_unlimited_restrict_auto", "0", "Restrict players from auto-assigning (1 - restrict, 0 - allow)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarRestrict[1] = CreateConVar("sm_teamchange_unlimited_restrict_spec", "0", "Restrict players from joining spectate (1 - restrict, 0 - allow)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarRestrict[2] = CreateConVar("sm_teamchange_unlimited_restrict_t", "0", "Restrict players from joining terrorists (1 - restrict, 0 - allow)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarRestrict[3] = CreateConVar("sm_teamchange_unlimited_restrict_ct", "0", "Restrict players from joining counter-terrorists (1 - restrict, 0 - allow)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarPenalty     = CreateConVar("sm_teamchange_unlimited_penalty", "011111101101", "Count auto-assign team change");
	h_cvarImmunity    = CreateConVar("sm_teamchange_unlimited_immunity", "0", "Admins receive team change count immunity (admin override: teamchange_unlimited_immunity)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarLimitTeams  = FindConVar("mp_limitteams");
	
	// Convar hooks
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	HookConVarChange(h_cvarLimitTeams, OnConvarChanged);
	HookConVarChange(h_cvarChat, OnConvarChanged);
	HookConVarChange(h_cvarSuicide, OnConvarChanged);
	HookConVarChange(h_cvarASuicide, OnConvarChanged);
	HookConVarChange(h_cvarMapLimit, OnConvarChanged);
	HookConVarChange(h_cvarRoundLimit, OnConvarChanged);
	HookConVarChange(h_cvarImmunity, OnConvarChanged);
	HookConVarChange(h_cvarPenalty, OnConvarChanged);
	for(new i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
		HookConVarChange(h_cvarRestrict[i], OnConvarChanged);
	
	AutoExecConfig(true, "teamchange_unlimited");
	UpdateAllConvars();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Updater_AddPlugin");
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	if(LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}

/*********
 *Updater*
**********/

public Action:Updater_OnPluginDownloading()
{
	if(!GetConVarBool(h_cvarUpdater))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

/*********
 *Globals*
**********/

public OnMapStart()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_MapCount[i] = 0;
		g_RoundCount[i] = 0;
	}
}

public OnConfigsExecuted()
{
	UpdateAllConvars();
}

/********
 *Events*
*********/

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
		g_RoundCount[i] = 0;
}

/**********
 *Commands*
***********/

public Action:JoinTeamCmd(client, const String:command[], argc)
{ 
	if(!IsValidClient(client) || argc < 1)
		return Plugin_Handled;
		
	decl String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	new toteam = StringToInt(arg);
	
	if(toteam < TEAM_UNASSIGNED || toteam > TEAM_CT || g_cvarRestrict[toteam])
	{
		if(g_cvarChat)
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Joining that team is not allowed.");
		return Plugin_Handled;
	}
	
	new interaction = GetInteraction(GetClientTeam(client), toteam);	
	new String:char[2] =  "1";
	if(interaction != -1)
		Format(char, 2, "%c", g_cvarPenalty[interaction]);
	if(StringToInt(char) > 0)
	{
		g_MapCount[client]++;
		g_RoundCount[client]++;
	}
	
	new bool:Access = StringToInt(char) == 0 || (g_cvarImmunity && CheckCommandAccess(client, "teamchange_unlimited_immunity", ADMFLAG_GENERIC, true));
	if(g_RoundCount[client] <= g_cvarRoundLimit || g_cvarRoundLimit == 0 || Access)
	{
		if(g_MapCount[client] <= g_cvarMapLimit || g_cvarMapLimit == 0 || Access)
			TeamChangeActual(client, toteam);
		else
		{
			if(g_cvarChat)
				PrintToChat(client, "\x01\x0B\x04[SM]\x01 Only %i team changes allowed per map.", g_cvarMapLimit);
			return Plugin_Handled;
		}
	}
	else
	{
		if(g_cvarChat)
			PrintToChat(client, "\x01\x0B\x04[SM]\x01 Only %i team changes allowed per round.", g_cvarRoundLimit);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

/*********
 *Helpers*
**********/

GetInteraction(fromteam, toteam)
{
	switch(fromteam)
	{
		case 0:
		{
			switch(toteam)
			{
				case 1: return 0;
				case 2: return 1;
				case 3: return 2;
			}
		}
		case 1:
		{
			switch(toteam)
			{
				case 0: return 3;
				case 2: return 4;
				case 3: return 5;
			}
		}
		case 2:
		{
			switch(toteam)
			{
				case 0: return 6;
				case 1: return 7;
				case 3: return 8;
			}
		}
		case 3:
		{
			switch(toteam)
			{
				case 0: return 9;
				case 1: return 10;
				case 2: return 11;
			}
		}
	}
	return -1;
}

TeamChangeActual(client, toteam)
{
	// Client is auto-assigning
	if(toteam == TEAM_UNASSIGNED)
		toteam = GetRandomInt(TEAM_T, TEAM_CT);
	
	// Proceed with the team change only if client is switching to a team that they are not already on
	new fromteam = GetClientTeam(client);
	if(fromteam == TEAM_UNASSIGNED || fromteam != toteam)
	{
		// Check that the team change doesn't violate mp_limitteams
		new imbalance = GetTeamClientCount(TEAM_CT) - GetTeamClientCount(TEAM_T);
		if(fromteam == TEAM_UNASSIGNED || fromteam == TEAM_SPECTATE)
			imbalance += toteam == TEAM_CT ? 2 : -2;
		else
			imbalance += toteam == TEAM_CT ? 1 : -1;
		if(g_cvarLimitTeams != 0 && imbalance > 0 && toteam == TEAM_CT && imbalance > g_cvarLimitTeams)
		{
			if(g_cvarChat)
				PrintToChat(client, "\x01\x0B\x04[SM]\x01 That team is full.");
			return;
		}
		else if(g_cvarLimitTeams != 0 && imbalance < 0 && toteam == TEAM_T && -imbalance > g_cvarLimitTeams)
		{
			if(g_cvarChat)
				PrintToChat(client, "\x01\x0B\x04[SM]\x01 That team is full.");
			return;
		}

		// Check if suicide is not an issue
		if(toteam == TEAM_SPECTATE || fromteam <= TEAM_SPECTATE || !IsPlayerAlive(client))
		{
			ChangeClientTeam(client, toteam);
			return;
		}
		// Check admin suicide conditions
		if(CheckCommandAccess(client, "teamchange_unlimited_suicide_admin", ADMFLAG_GENERIC, true))
		{
			if(g_cvarASuicide)
			{
				ChangeClientTeam(client, toteam);
				return;
			}
		}
		// Check non-admin suicide conditions
		else if(g_cvarSuicide)
		{
			ChangeClientTeam(client, toteam);
			return;
		}
		
		// Otherwise move client to spectate first to avoid killing them
		new Handle:data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, toteam);
		ChangeClientTeam(client, TEAM_SPECTATE);
		CreateTimer(1.0, TeamChangeActualTimer, data);
	}
}

/********
 *Timers*
*********/

public Action:TeamChangeActualTimer(Handle:timer, any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new toteam = ReadPackCell(data);
	CloseHandle(data);
	
	if(IsClientInGame(client))
		ChangeClientTeam(client, toteam);
	return Plugin_Handled;
}

/*********
 *Convars*
**********/

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarVersion)
		ResetConVar(h_cvarVersion);
	else if(cvar == h_cvarLimitTeams)
		g_cvarLimitTeams = GetConVarInt(h_cvarLimitTeams);
	else if(cvar == h_cvarChat)
		g_cvarChat       = GetConVarBool(h_cvarChat);
	else if(cvar == h_cvarSuicide)
		g_cvarSuicide    = GetConVarBool(h_cvarSuicide);
	else if(cvar == h_cvarASuicide)
		g_cvarASuicide   = GetConVarBool(h_cvarASuicide);
	else if(cvar == h_cvarMapLimit)
		g_cvarMapLimit   = GetConVarInt(h_cvarMapLimit);
	else if(cvar == h_cvarRoundLimit)
		g_cvarRoundLimit = GetConVarInt(h_cvarRoundLimit);
	else if(cvar == h_cvarImmunity)
		g_cvarImmunity   = GetConVarBool(h_cvarImmunity);
	else if(cvar == h_cvarPenalty)
		GetConVarString(h_cvarPenalty, g_cvarPenalty, sizeof(g_cvarPenalty));
	else
	{
		for(new i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
			if(cvar == h_cvarRestrict[i])
				g_cvarRestrict[i] = GetConVarBool(h_cvarRestrict[i]);
	}
}

UpdateAllConvars()
{
	g_cvarLimitTeams = GetConVarInt(h_cvarLimitTeams);
	g_cvarChat       = GetConVarBool(h_cvarChat);
	g_cvarSuicide    = GetConVarBool(h_cvarSuicide);
	g_cvarASuicide   = GetConVarBool(h_cvarASuicide);
	g_cvarMapLimit   = GetConVarInt(h_cvarMapLimit);
	g_cvarRoundLimit = GetConVarInt(h_cvarRoundLimit);
	g_cvarImmunity   = GetConVarBool(h_cvarImmunity);
	GetConVarString(h_cvarPenalty, g_cvarPenalty, sizeof(g_cvarPenalty));
	for(new i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
		g_cvarRestrict[i] = GetConVarBool(h_cvarRestrict[i]);
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}