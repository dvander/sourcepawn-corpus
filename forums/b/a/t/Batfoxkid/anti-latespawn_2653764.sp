#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required

#define MapConfig "configs/arenamaps.cfg"

ConVar cvarEnable;
ConVar cvarSCommand;
ConVar cvarPCommand;
ConVar cvarRCommand;
ConVar cvarFailCheck;
ConVar cvarFailDelay;
ConVar cvarTeam;

bool ClassChange[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "TF2: Anti-Arena Latespawn",
	description = "Stops players from spawning during in Arena mode",
	author = "Batfoxkid",
	version = "1.1"
}

public void OnPluginStart()
{
	cvarEnable = CreateConVar("latespawn_enable", "1", "0: Disable Plugin, 1: Enable Plugin", _, true, 0.0, true, 1.0);
	cvarSCommand = CreateConVar("latespawn_servercommand", "sm_slay #", "Command for the server to run once this happens (# is the user).");
	cvarPCommand = CreateConVar("latespawn_playercommand", "kill", "Command for the player to run once this happens.");
	cvarRCommand = CreateConVar("latespawn_runcommand", "1", "0: Server Command, 1: Player Command", _, true, 0.0, true, 1.0);
	cvarFailCheck = CreateConVar("latespawn_failcheck", "1", "0: latespawn_runcommand only, 1: If the player is still alive, 2: Always run next", _, true, 0.0, true, 2.0);
	cvarFailDelay = CreateConVar("latespawn_faildelay", "5.0", "Delay between commands, if latespawn_faildelay is above zero.", _, true, 0.0);
	cvarTeam = CreateConVar("latespawn_team", "1", "2: Ignore RED, 3: Ignore BLU", _, true, 1.0, true, 3.0);
	AutoExecConfig(true, "anti-latespawn");

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	AddCommandListener(OnChangeClass, "joinclass");
	AddCommandListener(OnChangeClass, "join_class");
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(CheckRoundState()!=1 || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client)==cvarTeam.IntValue)
		return Plugin_Continue;

	if(ClassChange[client])
		CreateTimer(0.1, ItsTimeToGoHumiliateThisPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(!ClassChange[client])
		CreateTimer(0.5, ResetClassChange, client, TIMER_FLAG_NO_MAPCHANGE);

	ClassChange[client] = true;
	return Plugin_Continue;
}

public Action ResetClassChange(Handle timer, int client)
{
	ClassChange[client] = false;
	return Plugin_Continue;
}

public Action ItsTimeToGoHumiliateThisPlayer(Handle timer, any userid)
{
	if(CheckRoundState()!=1 || !GetConVarBool(cvarEnable) || !IsArenaMap())
		return Plugin_Continue;

	char command[128];

	if(GetConVarBool(cvarRCommand))
	{
		GetConVarString(cvarPCommand, command, sizeof(command));
		FakeClientCommand(GetClientOfUserId(userid), command);
	}
	else
	{
		char userString[128];

		GetConVarString(cvarSCommand, command, sizeof(command));
		Format(userString, sizeof(userString), "#%i", userid);
		ReplaceString(command, sizeof(command), "#", userString, false);

		ServerCommand(command);
	}

	if(GetConVarInt(cvarFailCheck) > 0)
		CreateTimer(GetConVarFloat(cvarFailDelay), ItsTimeToGoHumiliateThisPlayerPartTwo, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action ItsTimeToGoHumiliateThisPlayerPartTwo(Handle timer, any userid)
{
	if(CheckRoundState()!=1 || !GetConVarBool(cvarEnable))
		return Plugin_Continue;

	int client = GetClientOfUserId(userid);

	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if(GetConVarInt(cvarFailCheck)<2 && !IsPlayerAlive(client))
		return Plugin_Continue;

	/*
		Here we go again
	*/

	char command[128];

	if(GetConVarBool(cvarRCommand))
	{
		char userString[128];

		GetConVarString(cvarSCommand, command, sizeof(command));
		Format(userString, sizeof(userString), "#%i", userid);
		ReplaceString(command, sizeof(command), "#", userString, false);

		ServerCommand(command);
	}
	else
	{
		GetConVarString(cvarPCommand, command, sizeof(command));
		FakeClientCommand(client, command);
	}

	return Plugin_Continue;
}

/*
	Below is directly from Freak Fortress 2
*/

public int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9	// Ugly compatability
	return 2;
	#endif
}

stock bool IsArenaMap()
{
	char config[PLATFORM_MAX_PATH], currentmap[99];
	GetCurrentMap(currentmap, sizeof(currentmap));

	BuildPath(Path_SM, config, sizeof(config), MapConfig);
	if(!FileExists(config))
	{
		LogError("Unable to find '%s'!", MapConfig);
		SetConVarInt(cvarEnable, 0);
		return false;
	}

	Handle file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogError("Unable to read '%s'!", MapConfig);
		SetConVarInt(cvarEnable, 0);
		return false;
	}

	int tries;
	while(ReadFileLine(file, config, sizeof(config)))
	{
		tries++;
		if(tries > 99)
		{
			LogError("Breaking infinite loop when trying to check '%s'!", MapConfig);
			SetConVarInt(cvarEnable, 0);
			return false;
		}

		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(!StrContains(currentmap, config, false) || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			return true;
		}
	}
	CloseHandle(file);
	return false;
}

#file "TF2: Anti-Arena Latespawn"