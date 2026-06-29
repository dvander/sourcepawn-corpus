// bebop.sp

// 
// CHANGELOG
// 0.1 beta
//     initial release
// 
// 0.2 beta
//     FIXED BUG: where bebop unnhooks events twice when changing
//                from non coop gamemode to another non coop gamemode
//     FIXED BUG: in l4d1 mp_gamemode cvar flag got set to protected
//                because it is not protected by default like in l4d1
// 
// 0.3 beta
//     FIXED BUG: Fixed a major bug in which this plugin would crash the entire server
// 

#include <sourcemod>
#include <sdktools>

#define BEBOP_VERSION				"0.3 beta"
#define BEBOP_LOG_PATH				"logs\\bebop.log"
#define DELAY_KICK_BEBOP_FAKE_CLIENT		1.0
#define DELAY_KICK_NO_MORE_NEEDED_BOTS		0.125
#define DELAY_AFK_PUT_CLIENT_SURVIVOR_TEAM	1.0
#define DELAY_NEW_PUT_CLIENT_SURVIVOR_TEAM	10.0
#define ID_TEAM_SURVIVOR			2

public char logfilepath[256];
public char clientname[256];
public char gameDir[64];
public char currentGameMode[64];
public int newMapActivatedPlayers;
public int convarFlags;
public int count;
public int tclient;
public int bclient;
public bool coopEnabled;
public bool isL4D2 = false;
Handle g_Cvar_GameMode;
Handle g_Cvar_BebopLogging;

public Plugin:MyInfo = 
{
	name = "bebop",
	author = "frool",
	description = "allows \"unlimited\" additional players playing in coop mode",
	version = BEBOP_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=110210"
};

public OnPluginStart()
{
	CreateConVar("bebop_version", BEBOP_VERSION, "tells the running version number of bebop", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("bebop_logging", "1", "toggle logging for bebop", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_Cvar_BebopLogging = FindConVar("bebop_logging");
	g_Cvar_GameMode = FindConVar("mp_gamemode");
	
	if (GetConVarBool(g_Cvar_BebopLogging))
	{
		BuildPath(Path_SM, logfilepath, sizeof(logfilepath), BEBOP_LOG_PATH);
		LogToFile(logfilepath, "+-------------------------------------------+");
		LogToFile(logfilepath, "|               PLUGIN START                |");
		LogToFile(logfilepath, "+-------------------------------------------+");
		LogToFile(logfilepath, "|               Version: %s           |", BEBOP_VERSION);
		LogToFile(logfilepath, "+-------------------------------------------+");
	}
	
	
	//// 
	//// hook stuff
	//// 
	
	
	// 
	// detect if l4d1 or l4d2 is running
	// 
	GetGameFolderName(gameDir, sizeof(gameDir));
	
	if (StrEqual(gameDir, "left4dead2"))
	{
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLUGIN_LOAD -> NOTICE: gamedir is \\left4dead2. setting mp_gamemode convar flags to unprotected");
		}
		isL4D2 = true;
		
		// 
		// set gamemode flags to non protected to gain access
		// 
		convarFlags = GetConVarFlags(g_Cvar_GameMode);
		SetConVarFlags(g_Cvar_GameMode, convarFlags & ~FCVAR_PROTECTED);
	}
	
	GetConVarString(g_Cvar_GameMode, currentGameMode, sizeof(currentGameMode));
	
	if (StrEqual(currentGameMode, "coop"))
	{
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLUGIN_LOAD -> NOTICE: gamemode is COOP. hooking events...");
		}
		coopEnabled = true;
		HookUnhookEvents(true);
	}
	
	HookConVarChange(g_Cvar_GameMode, Event_GameModeChanges);
	
	if (isL4D2)
	{
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLUGIN_LOAD -> NOTICE: gamedir is \\left4dead2. restoring original mp_gamemode convar flags");
		}
		SetConVarFlags(g_Cvar_GameMode, convarFlags);
	}
}

public Event_GameModeChanges(Handle:convar, const String:oldGameMode[], const String:newGameMode[])
{
	if (StrEqual(newGameMode, "coop"))
	{
		coopEnabled = true;
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "GAMEMODE_CHANGE -> NOTICE: gamemode changed to COOP NOW");
		}
		
		HookUnhookEvents(true);
	}
	else if (StrEqual(oldGameMode, "coop") == true || StrEqual(newGameMode, "coop") == false)
	{
		coopEnabled = false;
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "GAMEMODE_CHANGE -> NOTICE: gamemode changed to NON COOP");
		}
		
		HookUnhookEvents(false);
	}
}

public void HookUnhookEvents(bool:HookUnhook)
{
	if (HookUnhook)
	{
		HookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
		HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "HOOKED_EVENTS -> NOTICE: hooked events");
		}
	}
	else
	{
		UnhookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
		UnhookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "UNHOOKED_EVENTS -> NOTICE: unhooked events");
		}
	}
}

public void OnMapEnd()
{
	if (GetConVarBool(g_Cvar_BebopLogging))
	{
		LogToFile(logfilepath, "+-------------------------------------------+");
		LogToFile(logfilepath, "|                  MAP END                  |");
		LogToFile(logfilepath, "+-------------------------------------------+");
	}
	
	newMapActivatedPlayers = 0;
}

public void OnClientDisconnect(client)
{
	if (coopEnabled == false) return;
	if (newMapActivatedPlayers <= 4) return;
	
	if (!IsFakeClient(client))
	{
		clientname = "GetClientName() Failed";
		GetClientName(client, clientname, sizeof(clientname));
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "DISCONNECT:	--> %s <-- just disconnected from the server", clientname);
		}
		
		// 
		// -1 cuz the disconnected player does not count
		// 
		count = 0;
		count = GetHumanInGamePlayerCount() - 1;
		
		if (count >= 4)
		{
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "DISCONNECT -> KICK_BOT: HumamInGamePlayerCount is bigger or equals 4 --> Reported: %d <-- ", count);
			}
			
			// 
			// Generate Timer to Kick the Bot that takes over the disconnected client
			// 
			CreateTimer(DELAY_KICK_NO_MORE_NEEDED_BOTS, Timer_KickNoMoreNeededBot, 0, TIMER_REPEAT);
		}
	}
}

public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	tclient = 0;
	tclient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (tclient != 0)
	{
		if (!IsFakeClient(tclient) && GetClientTeam(tclient) == ID_TEAM_SURVIVOR)
		{
			clientname = "GetClientName() Failed";
			GetClientName(tclient, clientname, sizeof(clientname));
			
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "PLAYER_CHANGE_TEAM:	--> %s <-- may pressed the afk button", clientname);
			}
			
			CreateTimer(DELAY_AFK_PUT_CLIENT_SURVIVOR_TEAM, Timer_PutClientToSurvivorTeam, tclient, TIMER_REPEAT);
		}
	}
}

public Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	tclient = 0;
	tclient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsFakeClient(tclient))
	{
		clientname = "GetClientName() Failed";
		GetClientName(tclient, clientname, sizeof(clientname));
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLAYER_ACTIVATE: --> %s <-- just activated in the game", clientname);
		}
		
		newMapActivatedPlayers++;
		
		count = 0;
		count = GetHumanInGamePlayerCount();
		
		// 
		// clientteam is fix for spawning too many bouts after map_transition
		// 
		if (count > 4 && newMapActivatedPlayers > 4 && (GetClientTeam(tclient) != 2 || GetClientTeam(tclient) == 1))
		{
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "PLAYER_ACTIVATE: HumamInGamePlayerCount is bigger than 4 --> Reported: %d <--  TEAMID: %d", count, GetClientTeam(tclient));
			}
			
			SpawnBebopFakeClient();
			CreateTimer(DELAY_NEW_PUT_CLIENT_SURVIVOR_TEAM, Timer_PutClientToSurvivorTeam, tclient, TIMER_REPEAT);
		}
		// 
		// This fixes the major bug where the server will crash when a person tries to join with no bots
		// and minimum of 1 human player.
		// 
		else if (count < 4 && newMapActivatedPlayers < 4 && (GetClientTeam(tclient) != 2 || GetClientTeam(tclient) == 1))
		{
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "PLAYER_ACTIVATE: HumamInGamePlayerCount is less than 4 --> Reported: %d <--  TEAMID: %d", count, GetClientTeam(tclient));
			}
			
			SpawnBebopFakeClient();
			CreateTimer(DELAY_NEW_PUT_CLIENT_SURVIVOR_TEAM, Timer_PutClientToSurvivorTeam, tclient, TIMER_REPEAT);
		}
	}
}

public Action:Timer_PutClientToSurvivorTeam(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLAYER_ACTIVATE -> PUT_CLIENT_SURVIVORTEAM: --> %s <-- has been put into the survivor team", clientname);
		}
		
		FakeClientCommand(client, "jointeam %d", ID_TEAM_SURVIVOR);
	}
	
	return Plugin_Stop;
}

public Action:Timer_KickNoMoreNeededBot(Handle:timer, any:data)
{
	if (GetConVarBool(g_Cvar_BebopLogging))
	{
		LogToFile(logfilepath, "DISCONNECT -> KICK_BOT -> TIMER: searching for a bot to kick now");
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsFakeClient(i) && (GetClientTeam(i) == ID_TEAM_SURVIVOR))
		{
			clientname = "GetClientName() failed";
			GetClientName(i, clientname, sizeof(clientname));
			
			if (StrEqual(clientname, "bebop_bot_fakeclient", true))
			{
				continue;
			}
			
			KickClient(i, "client_is_bebop_fakeclient");
			
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "DISCONNECT -> KICK_BOT -> TIMER: --> %s <-- has been kicked ", clientname);
			}
			
			break;
		}
	}
	
	return Plugin_Stop;
}

public Action:Timer_KickBebopFakeClient(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		KickClient(client, "client_is_bebop_fakeclient");
		
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "PLAYER_ACTIVATE -> ADD_BOT -> KICK_BEBOP_FAKE_CLIENT_TIMER: kicked the bebop_fake_client from the server. bot should take over now");
		}
	}
	
	return Plugin_Stop;
}

public int GetHumanInGamePlayerCount()
{
	count = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			count++;
		}
	}
	
	return count;
}

public bool SpawnBebopFakeClient()
{
	// 
	// init ret value
	// 
	bool ret = false;
	
	// 
	// create fake client
	// 
	bclient = 0;
	bclient = CreateFakeClient("bebop_bot_fakeclient");
	
	// 
	// if entity is valid
	// 
	if (bclient != 0)
	{
		// 
		// move into survivor team
		// 
		ChangeClientTeam(bclient, ID_TEAM_SURVIVOR);
		//FakeClientCommand(bclient, "jointeam %d", ID_TEAM_SURVIVOR);
		
		// 
		// set entity classname to survivorbot
		// 
		if (DispatchKeyValue(bclient, "classname", "survivorbot"))
		{
			// 
			// spawn the client
			// 
			if (DispatchSpawn(bclient))
			{
				// 
				// kick the fake client to make the bot take over
				// 
				if (GetConVarBool(g_Cvar_BebopLogging))
				{
					LogToFile(logfilepath, "PLAYER_ACTIVATE -> ADD_BOT: bebop_fake_client created. kicking bebop_fake client now to make bot take over");
				}
				
				CreateTimer(DELAY_KICK_BEBOP_FAKE_CLIENT, Timer_KickBebopFakeClient, bclient, TIMER_REPEAT);
				ret = true;
			}
			else
			{
				if (GetConVarBool(g_Cvar_BebopLogging))
				{
					LogToFile(logfilepath, "ERROR: DispatchSpawn() in SpawnBebopFakeClient() failed");
				}
			}
		}
		else
		{
			if (GetConVarBool(g_Cvar_BebopLogging))
			{
				LogToFile(logfilepath, "ERROR: DispatchKeyValue() in SpawnBebopFakeClient() failed");
			}
		}
		
		//
		// if something went wrong kick the created fake client
		// 
		if (ret == false)
		{
			KickClient(bclient, "");
		}
	}
	else
	{
		if (GetConVarBool(g_Cvar_BebopLogging))
		{
			LogToFile(logfilepath, "ERROR: CreateFakeClient() in SpawnBebopFakeClient() failed");
		}
	}
	
	return ret;
}
