
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

static bool:b_HasRoundStarted; // Used to state if the round started or not
static bool:b_HasRoundEnded; // States if the round has ended or not
static bool:AfterInitialRound;
static bool:PlayerHasEnteredStart[MAXPLAYERS+1];
static bool:g_bIsL4D2;
static PlayersInServer;

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] All Bot Teams",
	author = "MI 5",
	description = "This plugin allows survivor players to face all infected bot teams, or vice versa",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=140347"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel.
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	if (StrEqual(GameName, "left4dead2", false))
		g_bIsL4D2 = true;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("l4d_abt_version", PLUGIN_VERSION, "Version of L4D All Bot Teams", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_bot_replace", Event_CheckForPlayers, EventHookMode_Post);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawned);
	HookEvent("player_entered_start_area", Event_PlayerFirstSpawned);
	HookEvent("player_entered_checkpoint", Event_PlayerFirstSpawned);
	HookEvent("player_transitioned", Event_PlayerFirstSpawned);
	HookEvent("player_left_start_area", Event_PlayerFirstSpawned);
	HookEvent("player_left_checkpoint", Event_PlayerFirstSpawned);
	HookEvent("map_transition", Event_GameEnded);
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
		return;
	
	PlayersInServer++;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has started ...
	if (b_HasRoundStarted)
		return;
	
	b_HasRoundStarted = true;
	b_HasRoundEnded = false;
	
	// When the game starts, stop the bots till a player joins
	SetConVarInt(FindConVar("sb_stop"), 1);
	
	if (AfterInitialRound)
		SetConVarInt(FindConVar("sb_stop"), 0);
}

public Action:Event_CheckForPlayers(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!RealPlayersInServer())
	{
		if (g_bIsL4D2)
		{
			SetConVarInt(FindConVar("sb_all_bot_game"), 0);
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
		}
		else
		SetConVarInt(FindConVar("sb_all_bot_team"), 0);
	}
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	PlayerHasEnteredStart[client] = false;
	PlayersInServer--;
	
	if (PlayersInServer == 0)
	{
		if (g_bIsL4D2)
		{
			SetConVarInt(FindConVar("sb_all_bot_game"), 0);
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
		}
		else
		SetConVarInt(FindConVar("sb_all_bot_team"), 0);
	}
}

public Action:Event_GameEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has not been reported as ended ..
	if (!b_HasRoundEnded)
	{
		// we mark the round as ended
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		AfterInitialRound = true;
		
		for (new i = 1; i <= MaxClients; i++)
			PlayerHasEnteredStart[i] = false;
	}
}

public Action:Event_PlayerFirstSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_HasRoundEnded)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (IsFakeClient(client))
		return;
	
	// If player has already entered the start area, don't go into this
	if (PlayerHasEnteredStart[client])
		return;
	
	PlayerHasEnteredStart[client] = true;
	
	SetConVarInt(FindConVar("sb_stop"), 0);
	
	if (g_bIsL4D2)
	{
		SetConVarInt(FindConVar("sb_all_bot_game"), 1);
		SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	}
	else
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
}

public OnMapEnd()
{
	b_HasRoundEnded = true;
	b_HasRoundStarted = false;
	AfterInitialRound = false;
	
	for (new i = 1; i <= MaxClients; i++)
		PlayerHasEnteredStart[i] = false;
}

bool:RealPlayersInServer ()
{
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return true;
	}
	return false;
}

public OnPluginEnd()
{
	if (g_bIsL4D2)
	{
		ResetConVar(FindConVar("sb_all_bot_game"), true, true);
		ResetConVar(FindConVar("allow_all_bot_survivor_team"), true, true);
	}
	else
	ResetConVar(FindConVar("sb_all_bot_team"), true, true);
	
	ResetConVar(FindConVar("sb_stop"), true, true);
}


//////////////////////////