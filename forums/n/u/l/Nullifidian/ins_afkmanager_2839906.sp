#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PL_VERSION		"1.6"

#define TEAM_SPECTATOR	1
#define TEAM_SECURITY	2
#define TEAM_INSURGENT	3

static const float gc_fTimeBeforeMoveToSpec 		= 240.0;	// def = 240.0
static const float gc_fTimeBeforeKick				= 600.0;	// def = 600.0
static const float gc_fTimeBeforeActionWarn			= 60.0;		// def = 60.0
static const float gc_fTimerInterval				= 0.25;		// def = 0.25

static const int gc_iMinPlayersInGameBeforeMove		= 2;		// def = 2
static const int gc_iMinPlayersInGameBeforeKick		= 10;		// def = 10
static const int gc_iNumberOfDaysToKeepLogs			= 7;		// def = 7

static const bool gc_bIsDeadPlayersExcluded			= true;		// def = true
static const bool gc_bIsAdminsImmuneToKick			= true;		// def = true
static const bool gc_bIsActionsAnnouncedToAll		= true;		// def = true

stock const char COL_RESET[]	= "\x01";
stock const char COL_RED[]		= "\x07FF0000";
stock const char COL_ORANGE[]	= "\x07FFA500";
stock const char COL_GOLD[]		= "\x07FFD700";

int g_iNumberHumanPlayersInGame					= 0;
int ga_iPlayerLastButtons[MAXPLAYERS + 1]		= {0, ...};
int ga_iPlayerTeam[MAXPLAYERS + 1]				= {0, ...};

float g_fTimeNow;
float ga_fPlayerNextAfkScanAt[MAXPLAYERS + 1]	= {0.0, ...};
float ga_fTimePlayerLastActive[MAXPLAYERS + 1]	= {0.0, ...};
float ga_fTimeToNextWarning[MAXPLAYERS + 1]		= {0.0, ...};

bool ga_bIsPlayerPickedSquad[MAXPLAYERS + 1]	= {false, ...};
bool g_bIsLateLoad;
bool g_bIsMapChanging							= false;
bool g_bIsGameEnd								= false;
bool g_bRecountQueued							= false;
bool g_bNowTimerRunning							= false;

char g_sLogDir[PLATFORM_MAX_PATH];
char g_sLogFile[PLATFORM_MAX_PATH];
char g_sLogDate[16];
bool g_bLogDedicatedDir = false;

public Plugin myinfo = {
	name		= "ins_afkmanager",
	author		= "Nullifidian",
	description	= "AFK move/kick",
	version		= PL_VERSION
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bIsLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("common.phrases");

	HookEvent("player_team",		Event_PlayerTeam);
	HookEvent("player_pick_squad",	Event_PlayerPickSquad);
	HookEvent("game_end",			Event_GameEnd, EventHookMode_PostNoCopy);

	BuildLogFilePath();
	PurgeOldLogs();

	AddCommandListener(ChangeLevelListener, "changelevel");
	AddCommandListener(ChangeLevelListener, "map");
	AddCommandListener(ChangeLevelListener, "sm_map");

	if (g_bIsLateLoad) {
		int pr = GetPlayerResourceEntity();
		bool hasSquadProp = (pr != -1) && HasEntProp(pr, Prop_Send, "m_iSquad");
		float now = AFK_Now();
		for (int i = 1; i <= MaxClients; i++) {
			if (IsHumanClientInGame(i))
				ResetPlayerGlobalsLate(i, pr, hasSquadProp, now);
		}
		
		g_iNumberHumanPlayersInGame = HumanCountInGame();
		if (g_iNumberHumanPlayersInGame > 0)
			AFK_StartNowTimer();
	}

	RegAdminCmd("sm_spec", cmd_spec, ADMFLAG_KICK, "sm_spec <#userid|name|@all> - Move target(s) to spectator");
}

public Action ChangeLevelListener(int client, const char[] command, int argc) {
	if (StrEqual(command, "sm_map", false)) {
		if (client > 0 && !CheckCommandAccess(client, "sm_map", ADMFLAG_CHANGEMAP, true))
			return Plugin_Continue;
	}
	else if (StrEqual(command, "map", false) || StrEqual(command, "changelevel", false)) {
		if (client > 0)
			return Plugin_Continue;
	}
	else
		return Plugin_Continue;

	if (argc > 0) {
		char nextMap[PLATFORM_MAX_PATH];
		GetCmdArg(1, nextMap, sizeof(nextMap));
		if (IsMapValid(nextMap))
			g_bIsMapChanging = true;
	}
	return Plugin_Continue;
}

public void OnMapStart() {
	g_bRecountQueued = false;
	g_bIsMapChanging = false;
	g_bIsGameEnd = false;
	BuildLogFilePath();
	PurgeOldLogs();
}

public void OnClientPostAdminCheck(int client) {
	if (!IsHumanClientInGame(client))
		return;

	ResetPlayerGlobals(client);
	g_iNumberHumanPlayersInGame = HumanCountInGame();

	if (g_iNumberHumanPlayersInGame > 0)
		AFK_StartNowTimer();
}

public void OnClientDisconnect(int client) {
	if (g_bIsGameEnd || g_bIsMapChanging)
		return;
	
	ResetPlayerGlobals(client);
	if (!g_bRecountQueued) {
		g_bRecountQueued = true;
		RequestFrame(Frame_OnClientDisconnect);
	}
}

void Frame_OnClientDisconnect(any data) {
	g_bRecountQueued = false;
	if (g_bIsGameEnd || g_bIsMapChanging)
		return;

	g_iNumberHumanPlayersInGame = HumanCountInGame();
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsHumanClientInGame(client))
		return Plugin_Continue;

	ga_iPlayerTeam[client] = event.GetInt("team");
	ga_fTimePlayerLastActive[client] = AFK_Now();
	ga_fTimeToNextWarning[client] = 0.0;
	ga_bIsPlayerPickedSquad[client] = false;
	return Plugin_Continue;
}

public Action Event_PlayerPickSquad(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsHumanClientInGame(client))
		return Plugin_Continue;

	ga_bIsPlayerPickedSquad[client] = true;
	ga_fTimePlayerLastActive[client] = AFK_Now();
	ga_fTimeToNextWarning[client] = 0.0;
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!IsHumanClientInGame(client))
		return Plugin_Continue;

	ga_fTimePlayerLastActive[client] = AFK_Now();
	ga_fTimeToNextWarning[client] = 0.0;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	if (cmdnum <= 0 || !IsHumanClientInGame(client))
		return Plugin_Continue;
	
	float now = AFK_Now();
	if (now < ga_fPlayerNextAfkScanAt[client])
		return Plugin_Continue;

	ga_fPlayerNextAfkScanAt[client] = now + gc_fTimerInterval;

	int team = ga_iPlayerTeam[client];

	if (gc_bIsDeadPlayersExcluded && (team == TEAM_SECURITY || team == TEAM_INSURGENT) && !IsPlayerAlive(client) && ga_bIsPlayerPickedSquad[client]) {
		ga_fTimePlayerLastActive[client] = now;
		return Plugin_Continue;
	}

	if (mouse[0] != 0 || mouse[1] != 0 || buttons != ga_iPlayerLastButtons[client]) {
		ga_fTimePlayerLastActive[client] = now;
		ga_iPlayerLastButtons[client] = buttons;
		ga_fTimeToNextWarning[client] = 0.0;
		return Plugin_Continue;
	}

	float idle = now - ga_fTimePlayerLastActive[client];

	if (gc_fTimeBeforeMoveToSpec > 0.0 && (team == TEAM_SECURITY || team == TEAM_INSURGENT) && g_iNumberHumanPlayersInGame >= gc_iMinPlayersInGameBeforeMove && idle >= gc_fTimeBeforeMoveToSpec && !g_bIsGameEnd) {
		MovePlayerToSpectator(client, idle);
		return Plugin_Continue;
	}

	if (gc_fTimeBeforeKick > 0.0 && g_iNumberHumanPlayersInGame >= gc_iMinPlayersInGameBeforeKick && idle >= gc_fTimeBeforeKick && !g_bIsGameEnd) {
		if (gc_bIsAdminsImmuneToKick && IsAfkClientAdmin(client))
			return Plugin_Continue;

		KickForAFK(client, idle);
		return Plugin_Continue;
	}

	if (gc_fTimeBeforeActionWarn == 0.0)
		return Plugin_Continue;

	const float BIG = 999999.0;
	float moveLeft = BIG, kickLeft = BIG;

	if (gc_fTimeBeforeMoveToSpec > 0.0 && (team == TEAM_SECURITY || team == TEAM_INSURGENT) && g_iNumberHumanPlayersInGame >= gc_iMinPlayersInGameBeforeMove) {
		float t = gc_fTimeBeforeMoveToSpec - idle;
		if (t > 0.0)
			moveLeft = t;
	}

	if (gc_fTimeBeforeKick > 0.0) {
		float t = gc_fTimeBeforeKick - idle;
		if (t > 0.0)
			kickLeft = t;
	}

	if (gc_bIsAdminsImmuneToKick && IsAfkClientAdmin(client))
		kickLeft = BIG;

	bool warnKick = (kickLeft <= moveLeft);
	float nextAction = warnKick ? kickLeft : moveLeft;

	if (nextAction <= gc_fTimeBeforeActionWarn && now >= ga_fTimeToNextWarning[client]) {
		int secs = (nextAction > 0.0) ? RoundToCeil(nextAction) : 0;
		if (warnKick)
			PrintToChat(client, "%s[AFK] %sYou will be kicked in %s%d%s seconds.", COL_ORANGE, COL_RED, COL_GOLD, secs, COL_RED);
		else
			PrintToChat(client, "%s[AFK] %sYou will be moved to spectator in %s%d%s seconds.", COL_ORANGE, COL_RED, COL_GOLD, secs, COL_RED);

		ga_fTimeToNextWarning[client] = now + (secs >= 20 ? 10.0 : 1.0);
	}
	return Plugin_Continue;
}

void MovePlayerToSpectator(int client, float idle) {
	if (!IsHumanClientInGame(client))
		return;

	ChangeClientTeam(client, TEAM_SPECTATOR);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	if (gc_bIsActionsAnnouncedToAll) PrintToChatAll("%s[AFK] %s%s%s was moved to spectator (idle %.0fs).", COL_ORANGE, COL_GOLD, name, COL_RESET, idle);
	else
		PrintToChat(client, "%s[AFK] %sYou were moved to spectator (idle %.0fs).", COL_ORANGE, COL_RED, idle);

	char auth[32];
	if (!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
		strcopy(auth, sizeof(auth), "UNKNOWN");

	LogAFK("MOVE: \"%s\" %s idle=%.1fs", name, auth, idle);
	ResetPlayerGlobals(client);
	ga_iPlayerTeam[client] = TEAM_SPECTATOR;
}

void KickForAFK(int client, float idle) {
	if (!IsHumanClientInGame(client))
		return;

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	if (gc_bIsActionsAnnouncedToAll)
		PrintToChatAll("%s[AFK] %s%s%s was kicked for being AFK (idle %.0fs).", COL_ORANGE, COL_GOLD, name, COL_RESET, idle);
	else
		PrintToChat(client, "%s[AFK] %sYou were kicked for being AFK (idle %.0fs).", COL_ORANGE, COL_RED, idle);

	char auth[32];
	if (!GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
		strcopy(auth, sizeof(auth), "UNKNOWN");

	LogAFK("KICK: \"%s\" %s idle=%.1fs", name, auth, idle);
	KickClient(client, "[AFK] You were kicked for being AFK.");
}

bool IsAfkClientAdmin(int client) {
	int flags = GetUserFlagBits(client);
	return ((flags & ADMFLAG_ROOT) != 0) || ((flags & ADMFLAG_KICK) != 0) || ((flags & ADMFLAG_GENERIC) != 0);
}

bool IsHumanClientInGame(int client) {
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
}

int HumanCountInGame() {
	int n = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsHumanClientInGame(i))
			n++;
	return n;
}

void ResetPlayerGlobals(int client) {
	float now = AFK_Now();

	ga_fTimePlayerLastActive[client] = now;
	ga_iPlayerLastButtons[client] = 0;
	ga_fTimeToNextWarning[client] = 0.0;
	ga_iPlayerTeam[client] = 0;
	ga_bIsPlayerPickedSquad[client] = false;
	ga_fPlayerNextAfkScanAt[client]  = 0.0;
}

void ResetPlayerGlobalsLate(int client, int pr, bool hasSquadProp, float now) {
	ga_iPlayerTeam[client] = GetClientTeam(client);

	if (pr != -1 && hasSquadProp) {
		int squad = GetEntProp(pr, Prop_Send, "m_iSquad", _, client);
		ga_bIsPlayerPickedSquad[client] = (squad > -1);
	} else
		ga_bIsPlayerPickedSquad[client] = false;

	ga_fTimePlayerLastActive[client] = now;
	ga_iPlayerLastButtons[client] = 0;
	ga_fTimeToNextWarning[client] = 0.0;
	ga_fPlayerNextAfkScanAt[client] = 0.0;
}

void BuildLogFilePath() {
	FormatTime(g_sLogDate, sizeof(g_sLogDate), "%Y-%m-%d", GetTime());

	BuildPath(Path_SM, g_sLogDir, sizeof(g_sLogDir), "logs/ins_afkmanager");
	g_bLogDedicatedDir = DirExists(g_sLogDir) || CreateDirectory(g_sLogDir, 448);

	if (g_bLogDedicatedDir)
		BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/ins_afkmanager/%s.log", g_sLogDate);
	else {
		BuildPath(Path_SM, g_sLogDir, sizeof(g_sLogDir), "logs");
		BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/ins_afkmanager_%s.log", g_sLogDate);
	}
}

void PurgeOldLogs() {
	if (gc_iNumberOfDaysToKeepLogs < 1)
		return;

	if (g_sLogDir[0] == '\0')
		BuildLogFilePath();

	if (!DirExists(g_sLogDir))
		return;

	Handle dir = OpenDirectory(g_sLogDir);
	if (dir == null)
		return;

	int cutoff = GetTime() - (gc_iNumberOfDaysToKeepLogs * 86400);
	char name[PLATFORM_MAX_PATH];
	FileType type;

	while (ReadDirEntry(dir, name, sizeof(name), type)) {
		if (type != FileType_File)
			continue;

		int slen = strlen(name);
		if (slen < 4 || StrContains(name, ".log", false) != slen - 4)
			continue;

		if (!g_bLogDedicatedDir && StrContains(name, "ins_afkmanager_", false) != 0)
			continue;

		char full[PLATFORM_MAX_PATH];
		if (g_bLogDedicatedDir)
			BuildPath(Path_SM, full, sizeof(full), "logs/ins_afkmanager/%s", name);
		else
			BuildPath(Path_SM, full, sizeof(full), "logs/%s", name);

		if (GetFileTime(full, FileTime_LastChange) < cutoff)
			DeleteFile(full);
	}

	CloseHandle(dir);
}

void LogAFK(const char[] fmt, any ...) {
	char date[16];
	FormatTime(date, sizeof(date), "%Y-%m-%d", GetTime());
	if (g_sLogFile[0] == '\0' || !StrEqual(date, g_sLogDate, false)) {
		BuildLogFilePath();
		PurgeOldLogs();
	}

	char buf[512];
	VFormat(buf, sizeof(buf), fmt, 2);
	LogToFileEx(g_sLogFile, "%s", buf);
}

public Action cmd_spec(int client, int args) {
	if (args < 1) {
		ReplyToCommand(client, "Usage: sm_spec <#userid|name|@all>");
		return Plugin_Handled;
	}

	char pattern[64];
	GetCmdArg(1, pattern, sizeof(pattern));

	int targets[MAXPLAYERS], count;
	char targetName[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	count = ProcessTargetString(pattern, client, targets, sizeof(targets),
								COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS,
								targetName, sizeof(targetName), tn_is_ml);

	if (count <= 0) {
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	int moved = 0, already = 0;

	for (int i = 0; i < count; i++) {
		int t = targets[i];

		if (!IsClientInGame(t) || IsClientSourceTV(t) || IsFakeClient(t))
			continue;

		if (GetClientTeam(t) == TEAM_SPECTATOR) {
			already++;
			continue;
		}

		ChangeClientTeam(t, TEAM_SPECTATOR);
		ga_iPlayerTeam[t] = TEAM_SPECTATOR;
		moved++;
	}

	ReplyToCommand(client, "[SM] %s - moved: %d, already spectator: %d.", targetName, moved, already);
	return Plugin_Handled;
}

public Action TimerR_GetGameTime(Handle timer) {
	if (g_bIsMapChanging || g_bIsGameEnd || g_iNumberHumanPlayersInGame == 0) {
		g_bNowTimerRunning = false;
		return Plugin_Stop;
	}

	g_fTimeNow = GetGameTime();
	return Plugin_Continue;
}

float AFK_Now() {
	return g_bNowTimerRunning ? g_fTimeNow : GetGameTime();
}

void AFK_StartNowTimer() {
	if (g_bNowTimerRunning)
		return;

	g_bNowTimerRunning = true;
	g_fTimeNow = GetGameTime();
	CreateTimer(gc_fTimerInterval, TimerR_GetGameTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_GameEnd(Event event, const char[] name, bool dontBroadcast) {
	g_bIsGameEnd = true;
}

public void OnMapEnd() {
	g_bIsMapChanging = true;
	g_bNowTimerRunning = false;
}

public void OnPluginEnd() {
	g_bNowTimerRunning = false;
}