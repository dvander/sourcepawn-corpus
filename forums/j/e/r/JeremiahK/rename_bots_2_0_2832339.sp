// vim: ts=8 syntax=cpp
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CFG_FILE	"configs/rename_bots.txt"
#define MAX_TEAMNUM	3
#define MAX_BOTNAME_LEN	32

public Plugin myinfo = {
	name =		"Rename Bots",
	version =	"1.12.2.0",
	description =	"Rename bots by TeamNum",
	author =	"JeremiahK (RedDeathOfMe)",
	url =		"https://forums.alliedmods.net/showthread.php?p=2840106"
}

ConVar gCvarEnabled;	// bool: plugin enabled?
ConVar gCvarPrefix;	// string: prefix for all bot names
ConVar gCvarSuffix;	// string: suffix for all bot names
ConVar gCvarShuffle;	// int: shuffle names? reshuffle once exhausted?

TeamBotNames gBotNames[MAX_TEAMNUM+1];

enum struct TeamBotNames {
	ArrayList Names;
	int Next;

	void _Init() {
		this.Names = CreateArray(MAX_BOTNAME_LEN);
		this.Next = 0;
	}

	void Add(const char[] name) {
		if (this.Names == INVALID_HANDLE) { this._Init(); }
		this.Names.PushString(name);
	}

	void Get(char[] name, int maxsize) {
		char buffer[MAX_BOTNAME_LEN];
		this.Names.GetString(this.Next, buffer, sizeof(buffer));
		strcopy(name, maxsize, buffer);
		if (++this.Next == this.Names.Length) {
			this.Next = 0;
			if (gCvarShuffle.IntValue == 2) {
				this.Shuffle();
			}
		}
	}

	void Shuffle() {
		for (int i = this.Names.Length - 1; i > 0; i--) {
			this.Names.SwapAt(i, GetURandomInt() % i);
		}
	}
}

public void OnPluginStart()
{
	gCvarEnabled = CreateConVar(
		"rename_bots_enabled",
		"1",
		"bool: rename_bots plugin enabled?",
		0, true, 0.0, true, 1.0
	);
	gCvarPrefix = CreateConVar(
		"rename_bots_prefix",
		"BOT ",
		"str: prefix for all bot names"
	);
	gCvarSuffix = CreateConVar(
		"rename_bots_suffix",
		"",
		"str: suffix for all bot names"
	);
	gCvarShuffle = CreateConVar(
		"rename_bots_shuffle",
		"1",
		"int: 0-no shuffle, 1-shuffle once, 2-reshuffle if exhausted",
		0, true, 0.0, true, 1.0
	);

	ProcessConfig();
}

public void OnClientPutInServer(int client)
{
	if (!gCvarEnabled.BoolValue) {
		return;
	}

	if (client > 0 && IsClientInGame(client) && IsFakeClient(client)) {
		CreateTimer(0.1, Timer_RenameOnValidTeamNum, client, TIMER_REPEAT);
	}
}

static Action Timer_RenameOnValidTeamNum(Handle timer, int client)
{
	int team = GetClientTeam(client);
	if (team) {
		RenameBot(client, team);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void RenameBot(const int client, const int team)
{
	char buffer[MAX_BOTNAME_LEN];
	char name[MAX_BOTNAME_LEN];

	gCvarPrefix.GetString(name, sizeof(name));

	gBotNames[team].Get(buffer, sizeof(buffer));
	StrCat(name, sizeof(name), buffer);

	gCvarSuffix.GetString(buffer, sizeof(buffer));
	StrCat(name, sizeof(name), buffer);

	SetClientInfo(client, "name", name);
}

void ProcessConfig()
{
	char configFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configFile, sizeof(configFile), CFG_FILE);
	if (!FileExists(configFile)) {
		PrintToServer("RENAME_BOTS: No config file found at `%s`.", configFile);
		return;
	}

	char buffer[256];
	char words[3][16];
	int team = -1;
	File file = OpenFile(configFile, "r");
	while (file.ReadLine(buffer, sizeof(buffer)))
	{
		TrimString(buffer);
		int numWords = ExplodeString(buffer, ":", words, sizeof(words), sizeof(words[0]), true);

		if (numWords == 3 && StrEqual(words[0], "RENAME_BOTS", false)) {
			if (StrEqual(words[1], "TEAMNUM", false)) {
				team = StringToInt(words[2]);
			}
		}

		else if (strlen(buffer)) {
			gBotNames[team].Add(buffer);
		}
	}
	file.Close();

	if (gCvarShuffle.IntValue > 0) {
		for (int i = 0; i <= MAX_TEAMNUM; i++)
		{
			if (gBotNames[i].Names != INVALID_HANDLE) {
				gBotNames[i].Shuffle();
			}
		}
	}
}
