#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"
#define TEAM_SURVIVORS 2

//=================
#define debug 0

#define LOG		"logs\\crash_log.log"

#if debug
static	char DEBUG[256];
#endif
//===============

static	bool PlayerWentAFK[MAXPLAYERS+1];
Handle hSpec;
Handle hSwitch;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if(StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] 4+ Survivor Afk Fix",
	author = "MI 5, SwiftReal, raziEiL [disawar1], Electr0 [m_iMeow]",
	description = "Fixes issue where player does not go IDLE on a bot in 4+ survivors games",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public void OnPluginStart()
{
	#if debug
		BuildPath(Path_SM, DEBUG, sizeof(DEBUG), LOG);
	#endif

	CreateConVar("l4dafkfix_version", PLUGIN_VERSION, "Version of L4D 4+ Survivor AFK Fix", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(FindConVar("l4dafkfix_version"), PLUGIN_VERSION);

	// Read file handle
	Handle temp = LoadGameConfigFile("l4dafkfix");
	if (temp != INVALID_HANDLE)
	{
		// USED SetHumanIdle
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(temp, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
		if (hSpec == INVALID_HANDLE) SetFailState("Survivor Afk Fix: SetHumanSpec Signature broken");

		// USED TakeOverBot
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(temp, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
		if (hSwitch == INVALID_HANDLE) SetFailState("Survivor Afk Fix: TakeOverBot Signature broken");
		CloseHandle(temp);
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4dafkfix.txt , you FAILED AT INSTALLING");
	}

	// Hook the player_bot_replace event and player_afk event
	HookEvent("player_afk", Event_PlayerWentAFK, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnded, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnded, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_takeoverme", TakeOverMe);
	RegConsoleCmd("sm_join", TakeOverMe);

	RegConsoleCmd("sm_afk", GoAwayFromKeyboard);
	RegConsoleCmd("sm_idle", GoAwayFromKeyboard);
	RegConsoleCmd("sm_spec", GoAwayFromKeyboard);
	RegConsoleCmd("sm_spectate", GoAwayFromKeyboard);
}

public Action TakeOverMe(int client, int agrs)
{
	if (!client) return Plugin_Handled;

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && IsAlive(i)){

			int me = FindidOfIdlePlayer(i);
			if (client == me)
			{
				TakeOverBot(me, i);
				PrintToChat(client, "TakeOverBot");
			}
		}
	}
	return Plugin_Handled;
}

public Action GoAwayFromKeyboard(int client, int args)
{
	if (!client || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return Plugin_Handled;

	FakeClientCommand(client, "go_away_from_keyboard");

	if (GetClientTeam(client) == 1)
		PrintToChatAll("%N has become a spectator.", client);

	return Plugin_Handled;
}

public Action Event_PlayerWentAFK(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player goes AFK
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	PlayerWentAFK[client] = true;
}

public Action Event_BotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a bot takes over a player
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));

	// Create a datapack as we are moving 2+ pieces of data through a timer
	if(GetClientTeam(bot)==TEAM_SURVIVORS)
	{
		if(client)
		{
			if(IsClientConnected(client) && IsClientInGame(client))
			{
				Handle datapack;
				CreateDataTimer(0.5, Timer_ActivateFix, datapack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(datapack, client);
				WritePackCell(datapack, bot);
			}
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player dies
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client) return;
	if(!IsClientInGame(client)) return;

	// If the client is a bot and has a player idle on it, force the player to take over the bot
	if(IsFakeClient(client) && GetClientTeam(client)==TEAM_SURVIVORS && HasIdlePlayer(client))
	{
		int idleplayer = FindidOfIdlePlayer(client);
		if(idleplayer != 0)
			TakeOverBot(idleplayer, client);
	}
}

public Action Timer_ActivateFix(Handle Timer, any datapack)
{
	// Reset the data pack
	ResetPack(datapack);

	// Retrieve values from datapack
	int client = ReadPackCell(datapack);
	int bot = ReadPackCell(datapack);

	// Check to see if the player successfully went AFK, and if the player did, forget this plugin
	if(IsClientIdle(client, bot))
	{
		PlayerWentAFK[client] = false;
		return;
	}

	// If the player went AFK and failed, continue on
	if(PlayerWentAFK[client])
	{
		PlayerWentAFK[client] = false;
		SetHumanIdle(client, bot);
	}
}

stock void SetHumanIdle(int client, int bot)
{
	if (IsClientInGame(bot) && GetClientTeam(bot)==TEAM_SURVIVORS && IsClientInGame(client))
	{
		#if debug
			LogToFile(DEBUG, "SetHumanIdle(%N, %N) -> SDKCall SetHumanSpec", client, bot);
		#endif

		SDKCall(hSpec, bot, client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
		return;
	}
}

stock void TakeOverBot(int client, int bot)
{
	if (client > 0)
	{
		//PrintToChatAll("TakeOverBot %N %N", client, bot);

		#if debug
			LogToFile(DEBUG, "TakeOverBot(%N, %N) -> SDKCall SetHumanSpec", client, bot);
		#endif

		SDKCall(hSpec, bot, client);

		#if debug
			LogToFile(DEBUG, "TakeOverBot(%N, %N) -> SDKCall TakeOverBot", client, bot);
		#endif

		SDKCall(hSwitch, client, true);
		return;
	}
}

public Action Event_RoundEnded(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && IsAlive(i) && HasIdlePlayer(i))
			TakeOverBot(FindidOfIdlePlayer(i), i);
	}
}

public void OnClientDisconnect(int client)
{
	// Reset the arrays on the client when the client disconnects
	PlayerWentAFK[client] = false;
}

stock bool IsClientIdle(int client, int bot)
{
	if(IsValidEntity(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if( strcmp(sNetClass, "SurvivorBot") == 0 )
		{
			if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
				return false;

			if(GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID")) == client)
				return true;
		}
		else return false;
	}
	return false;
}

stock bool HasIdlePlayer(int bot)
{
	if(IsValidEntity(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if( strcmp(sNetClass, "SurvivorBot") == 0 )
		{
			if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
				return false;

			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
			if(client)
			{
				// Do not count bots
				// Do not count 3rd person view players
				if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVORS))
					return true;
			}
			else return false;
		}
	}
	return false;
}

stock bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState"))
		return true;
	return false;
}

stock int FindidOfIdlePlayer(int bot)
{
	if(IsValidEntity(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if( strcmp(sNetClass, "SurvivorBot") == 0 )
		{
			if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
				return false;

			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
			if(client)
			{
				// Do not count bots
				// Do not count 3rd person view players
				if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) != TEAM_SURVIVORS))
					return client;
			}
			else
				return 0;
		}
	}
	return 0;
}