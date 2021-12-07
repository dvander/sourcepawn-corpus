#pragma semicolon 1

#define PLUGIN_VERSION "1.3.1"
#define PLUGIN_CHATTAG "[\x04SM\x01]"

#include <sourcemod>
#include <sdktools>

#define TEAM_UNASSIGNED     0
#define TEAM_SPECTATE 	    1
#define TEAM_T              2
#define TEAM_CT             3

public Plugin:myinfo =
{
	name = "TeamChange Unlimited",
	author = "Sheepdude, viderizer",
	description = "TeamChange Unlimited",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Convar handles
Handle h_cvarLimitTeams;

// Plugin convar handles
Handle h_cvarVersion;
Handle h_cvarChat;
Handle h_cvarSuicide;
Handle h_cvarASuicide;
Handle h_cvarMapLimit;
Handle h_cvarRoundLimit;
Handle h_cvarRestrict[4];
Handle h_cvarPenalty;
Handle h_cvarImmunity;

// Convar variables
int g_cvarLimitTeams;

// Plugin convar variables
bool g_cvarChat;
bool g_cvarSuicide;
bool g_cvarASuicide;
int g_cvarMapLimit;
int g_cvarRoundLimit;
bool g_cvarRestrict[4];
char g_cvarPenalty[16];
bool g_cvarImmunity;

// Plugin variables
int g_MapCount[MAXPLAYERS+1];
int g_RoundCount[MAXPLAYERS+1];

public OnPluginStart()
{
	// Event hooks
	HookEventEx("round_start", OnRoundStart);
	HookEventEx("teamplay_round_start", OnRoundStart);

	// Commands
	AddCommandListener(JoinTeamCmd, "jointeam");

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
	for (int i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
		HookConVarChange(h_cvarRestrict[i], OnConvarChanged);

	AutoExecConfig(true, "teamchange_unlimited");
	UpdateAllConvars();
}

public OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_MapCount[i] = 0;
		g_RoundCount[i] = 0;
	}
}

public OnConfigsExecuted()
{
	UpdateAllConvars();
}

public OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_RoundCount[i] = 0;
}

public Action JoinTeamCmd(int client, const char[] command, int argc)
{
	if (!IsValidClient(client) || argc < 1)
		return Plugin_Handled;

	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int toteam = StringToInt(arg);

	if (toteam == TEAM_UNASSIGNED) //auto-assign
		toteam = GetRandomInt(TEAM_T, TEAM_CT);

	if (toteam < 1 || toteam > 3 || g_cvarRestrict[toteam]) {
		if (g_cvarChat)
			PrintToChat(client, "%s Joining that team is not allowed.", PLUGIN_CHATTAG);
		return Plugin_Handled;
	}

	int interaction = GetInteraction(GetClientTeam(client), toteam);
	char str[2] =  "1";
	if (interaction != -1)
		Format(str, 2, "%c", g_cvarPenalty[interaction]);
	if (StringToInt(str) > 0) {
		g_MapCount[client]++;
		g_RoundCount[client]++;
	}

	bool Access = StringToInt(str) == 0 || (g_cvarImmunity && CheckCommandAccess(client, "teamchange_unlimited_immunity", ADMFLAG_GENERIC, true));
	if (g_RoundCount[client] <= g_cvarRoundLimit || g_cvarRoundLimit == 0 || Access) {
		if (g_MapCount[client] <= g_cvarMapLimit || g_cvarMapLimit == 0 || Access)
			TeamChangeActual(client, toteam);
		else {
			if (g_cvarChat)
				PrintToChat(client, "%s Only %i team changes allowed per map.", PLUGIN_CHATTAG, g_cvarMapLimit);
			return Plugin_Handled;
		}
	}
	else {
		if (g_cvarChat)
			PrintToChat(client, "%s Only %i team changes allowed per round.", PLUGIN_CHATTAG, g_cvarRoundLimit);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

GetInteraction(int fromteam, int toteam)
{
	switch (fromteam) {
		case 0: {
			switch (toteam) {
				case 1: return 0;
				case 2: return 1;
				case 3: return 2;
			}
		}
		case 1: {
			switch (toteam) {
				case 0: return 3;
				case 2: return 4;
				case 3: return 5;
			}
		}
		case 2: {
			switch (toteam) {
				case 0: return 6;
				case 1: return 7;
				case 3: return 8;
			}
		}
		case 3: {
			switch (toteam) {
				case 0: return 9;
				case 1: return 10;
				case 2: return 11;
			}
		}
	}
	return -1;
}

TeamChangeActual(int client, int toteam)
{
	// Proceed with the team change only if client is switching to a team that they are not already on
	int fromteam = GetClientTeam(client);
	if (fromteam == TEAM_UNASSIGNED || fromteam != toteam)
	{
		// Check that the team change doesn't violate mp_limitteams
		int imbalance = GetTeamClientCount(TEAM_CT) - GetTeamClientCount(TEAM_T);
		if (fromteam == TEAM_UNASSIGNED || fromteam == TEAM_SPECTATE)
			imbalance += toteam == TEAM_CT ? 1 : -1;
		else
			imbalance += toteam == TEAM_CT ? 2 : -2;

		if (g_cvarLimitTeams != 0 && imbalance > 0 && toteam == TEAM_CT && imbalance > g_cvarLimitTeams) {
			if (g_cvarChat)
				PrintToChat(client, "%s That team is full.", PLUGIN_CHATTAG);
			return;
		}
		else if (g_cvarLimitTeams != 0 && imbalance < 0 && toteam == TEAM_T && -imbalance > g_cvarLimitTeams) {
			if (g_cvarChat)
				PrintToChat(client, "%s That team is full.", PLUGIN_CHATTAG);
			return;
		}

		// Check if suicide is not an issue
		if (toteam == TEAM_SPECTATE || fromteam <= TEAM_SPECTATE || !IsPlayerAlive(client)) {
			ChangeClientTeam(client, toteam);
			return;
		}

		// Check admin suicide conditions
		if (CheckCommandAccess(client, "teamchange_unlimited_suicide_admin", ADMFLAG_GENERIC, true)) {
			if (g_cvarASuicide)
			{
				ChangeClientTeam(client, toteam);
				return;
			}
		} else if (g_cvarSuicide) {
			ChangeClientTeam(client, toteam);
			return;
		}

		// Otherwise move client to spectate first to avoid killing them
		Handle data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, toteam);
		ChangeClientTeam(client, TEAM_SPECTATE);
		CreateTimer(1.0, TeamChangeActualTimer, data);
	}
}

public Action TeamChangeActualTimer(Handle timer, any data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	int toteam = ReadPackCell(data);
	CloseHandle(data);

	if(IsClientInGame(client))
		ChangeClientTeam(client, toteam);
	return Plugin_Handled;
}

public void OnConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
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
	else {
		for (int i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
			if (cvar == h_cvarRestrict[i])
				g_cvarRestrict[i] = GetConVarBool(h_cvarRestrict[i]);
	}
}

void UpdateAllConvars()
{
	g_cvarLimitTeams = GetConVarInt(h_cvarLimitTeams);
	g_cvarChat       = GetConVarBool(h_cvarChat);
	g_cvarSuicide    = GetConVarBool(h_cvarSuicide);
	g_cvarASuicide   = GetConVarBool(h_cvarASuicide);
	g_cvarMapLimit   = GetConVarInt(h_cvarMapLimit);
	g_cvarRoundLimit = GetConVarInt(h_cvarRoundLimit);
	g_cvarImmunity   = GetConVarBool(h_cvarImmunity);
	GetConVarString(h_cvarPenalty, g_cvarPenalty, sizeof(g_cvarPenalty));
	for (int i = TEAM_UNASSIGNED; i <= TEAM_CT; i++)
		g_cvarRestrict[i] = GetConVarBool(h_cvarRestrict[i]);
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
