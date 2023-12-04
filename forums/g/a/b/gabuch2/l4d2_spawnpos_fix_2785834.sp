#pragma semicolon 1

#define PLUGIN_NAME 		"Survivor Spawn Position Fix (Gabu's Version)"
#define PLUGIN_AUTHOR 		"gabuch2"
#define PLUGIN_DESCRIPTION 	"Fixes survivor spawns on some maps where other survivors might spawn in a non-intended area."
#define PLUGIN_VERSION 		"2.1"  
#define PLUGIN_URL			"https://github.com/gabuch2/l4d2_spawnpos_fix"

#define DEBUG false

// BASE CHARACTER IDs
#define     NICK     		0
#define     ROCHELLE    	1
#define     COACH     		2
#define     ELLIS     		3

// L4D1 CHARACTER IDs
#define     BILL     		4
#define     ZOEY     		5
#define     FRANCIS     	6
#define     LOUIS     		7

#include <sourcemod>  
#include <sdktools>  
#include <left4dhooks>  

#pragma newdecls required

ConVar	g_cvarEnabled;
int 	g_iSurvivorCharacter[MAXPLAYERS+1];
bool 	g_bIsL4D1 = false;
bool	g_bShouldIgnoreTP[MAXPLAYERS+1] = { false, ... };
bool	g_bFinaleWon = false;
bool	g_bShouldLockPlayers = false;
float	g_fDesiredPos[3] = {0.0, 0.0, 0.0};

public Plugin myinfo =  
{  
	name = PLUGIN_NAME,  
	author = PLUGIN_AUTHOR,  
	description = PLUGIN_DESCRIPTION,  
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}  

public void OnPluginStart()  
{  
	g_cvarEnabled = CreateConVar("sm_l4d2_spawnpos_enabled", "1", "Enables Survivor Spawn Position Fix (Gabu's Version)", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	CreateConVar("sm_l4d2_spawnpos_version", PLUGIN_VERSION, "Version of Survivor Spawn Position Fix (Gabu's Version)", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	if(GetConVarBool(g_cvarEnabled))
	{
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerIgnoreTP, EventHookMode_Post);
		HookEvent("finale_win", Event_RoundEnd, EventHookMode_Pre);
		
		HookEvent("survivor_call_for_help", Event_PlayerIgnoreTP, EventHookMode_Post);

		RegConsoleCmd("sm_resetpos", Cmd_ResetPos, "Resets your position to a desired spawnpoint, if available."); 
	}
}

public void Event_FinaleWin(Handle event, const char[] name, bool dontBroadcast)
{
	g_bFinaleWon = true;
}

public Action Cmd_ResetPos(int iClient, int iArgs)  
{  
	if((g_fDesiredPos[0] != 0.0 || g_fDesiredPos[1] != 0.0 || g_fDesiredPos[2] != 0.0))
	{
		//Don't know if this will work on non-coop and non-versus gamemodes
		//please test and let me know
		if(L4D_HasAnySurvivorLeftSafeArea())
		{
			PrintToChat(iClient, "* Round has started, you can't use this command now.");
			return Plugin_Continue;
		}

		TeleportEntity(iClient, g_fDesiredPos, NULL_VECTOR, {1.0, 1.0, 0.0});
		return Plugin_Continue;
	}
	else
	{
		PrintToChat(iClient, "* You can't use this command at this moment.");
		return Plugin_Continue;
	}
}

public void L4D_OnForceSurvivorPositions_Pre()
{
	#if DEBUG
	PrintToServer("ONFORCE_PRE CALLED");
	#endif
	turn_survivors_into_original();
	LockAllPlayerMovement();
	g_bShouldLockPlayers = true;
}

public void L4D_OnForceSurvivorPositions()
{
	#if DEBUG
	PrintToServer("ONFORCE_POST CALLED");
	#endif
	restore_survivors();
}

public void L4D_OnReleaseSurvivorPositions()
{
	#if DEBUG
	PrintToServer("ONRELEASE CALLED");
	#endif
	g_bShouldLockPlayers = false;
	AllowAllPlayerMovement();

	//this fixes campaigns that change the original survivor position after the initial cutscene
	FixSpawns();
}

public void OnMapStart() 
{
	g_bIsL4D1 = L4D2_GetSurvivorSetMap() == 2 ? false : true;
	#if DEBUG
	PrintToServer("OnMapStart CALLED");
	#endif
	g_fDesiredPos = {0.0, 0.0, 0.0};
	CreateTimer(10.0, Timer_MapStart);
	g_bShouldLockPlayers = false;
	g_bFinaleWon = false;
}

public Action Timer_MapStart(Handle timer)
{
	//sometimes round_start doesn't trigger for the first time
	#if DEBUG
	PrintToServer("OnMapStart TIMER CALLED");
	#endif
	FixSpawns();
	EnsureSpawns();

	return Plugin_Continue;
}

public void Event_PlayerIgnoreTP(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bShouldIgnoreTP[iClient] = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	EnsureSpawns();
	g_bFinaleWon = false;
}

public Action Timer_EnsureSpawns(Handle timer)
{
	EnsureSpawns();

	return Plugin_Continue;
}

public void EnsureSpawns()
{
	if(!g_bFinaleWon)
	{
		if(g_fDesiredPos[0] != 0.0 || g_fDesiredPos[1] != 0.0 || g_fDesiredPos[2] != 0.0)
		{
			for(int iClient=1; iClient <= MaxClients; iClient++)
			{
				if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
				{
					//TeleportEntity(iClient, g_fDesiredPos, NULL_VECTOR, {1.0, 1.0, 0.0});
					AllowSinglePlayerMovement(iClient);
					TeleportEntity(iClient, g_fDesiredPos, NULL_VECTOR, {1.0, 1.0, 0.0});
					if(g_bShouldLockPlayers)
						LockSinglePlayerMovement(iClient);
					//char sTimer[5];
					//Format(sTimer, sizeof(sTimer), "0.%d", iClient);
					//CreateTimer(StringToFloat(sTimer), Timer_TeleportSinglePlayer, iClient);
				}
			}
		}
	}
}

public Action Timer_TeleportSinglePlayer(Handle timer, int iClient)
{
	//testing revealed that the game will refuse to teleport players if another player 
	//is in exactly the same position but with a small delay between teleports and velocity 
	//we can work around this
	
	TeleportEntity(iClient, g_fDesiredPos, NULL_VECTOR, {1.0, 1.0, 0.0});
	if(g_bShouldLockPlayers)
		LockSinglePlayerMovement(iClient);
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
		g_bShouldIgnoreTP[iClient] = false;

	//g_fDesiredPos = {0.0, 0.0, 0.0};
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	//SendProxy_HookPropChangeSafe(const int iEntity, const char[] cPropName, const SendPropType stType, const PropChangedCallback pCallback);
	if(GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
	{
		if((g_fDesiredPos[0] != 0.0 || g_fDesiredPos[1] != 0.0 || g_fDesiredPos[2] != 0.0) && !g_bShouldIgnoreTP[iClient] && !L4D_HasAnySurvivorLeftSafeArea())
		{
			//this is only possible on spawns after round_start, on round start we need to TP everyone again
			#if DEBUG
			PrintToServer("Debug: A player spawned! Conditions met so we're TPing him");
			#endif
			AllowSinglePlayerMovement(iClient);
			TeleportEntity(iClient, g_fDesiredPos, NULL_VECTOR, {1.0, 1.0, 0.0});
			if(g_bShouldLockPlayers)
				LockSinglePlayerMovement(iClient);
			//CreateTimer(0.1, Timer_TeleportSinglePlayer, iClient);
		}
	}
}

void FixSpawns()
{
	#if DEBUG
	PrintToServer("Debug: Calling FixSpawns()");
	#endif
	if(GetConVarBool(g_cvarEnabled))
	{
		// Determine if the spawns are standarized
		// This is quite complex by the way because we need to check both the gamemode
		// and their proper spawns and all the possible ways a survivor can spawn
		ConVar cvarGameMode = FindConVar("mp_gamemode");
		char sGameMode[32];
		GetConVarString(cvarGameMode, sGameMode, sizeof(sGameMode));

		bool bFoundNamedSpawnPoint = false;

		if(L4D_IsFirstMapInScenario())
		{
			#if DEBUG
			PrintToServer("Debug: Is the first map in the scenario");
			#endif
			//first map in scenario
			int iEnt = -1;
			while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
			{
				#if DEBUG
				PrintToServer("Debug: %d spawnpoint", iEnt);
				#endif
				char sSpawnGameMode[32], sSurvivorName[32];
				GetEntPropString(iEnt, Prop_Data, "m_iszGameMode", sSpawnGameMode, sizeof(sSpawnGameMode));
				GetEntPropString(iEnt, Prop_Data, "m_iszSurvivorName", sSurvivorName, sizeof(sSurvivorName));
				#if DEBUG
				PrintToServer("Debug: %d spawnpoint gamemode: %s", iEnt, sSpawnGameMode);
				PrintToServer("Debug: %d spawnpoint survivor: %s", iEnt, sSurvivorName);
				#endif
				if(((StrEqual(sGameMode, "coop") && (strlen(sSpawnGameMode) == 0 || StrContains(sSpawnGameMode, sGameMode) >= 0)) || StrContains(sSpawnGameMode, sGameMode) >= 0))
				{
					if(StrEqual(sSurvivorName, g_bIsL4D1 ? "Bill" : "Nick", false) || 
						StrEqual(sSurvivorName, g_bIsL4D1 ? "Louis" : "Coach", false) ||
						StrEqual(sSurvivorName, g_bIsL4D1 ? "Francis" : "Ellis", false) ||
						StrEqual(sSurvivorName, g_bIsL4D1 ? "Zoey" : "Rochelle", false))
					{
						bFoundNamedSpawnPoint = true;
						GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", g_fDesiredPos);
					}
				}
			}

			#if DEBUG
			PrintToServer("Debug: Checking bFoundNamedSpawnPoint");
			#endif
			if(bFoundNamedSpawnPoint)
			{
				//we found named spawnpoint
				//now we need to create the new logic

				//cleanup
				iEnt = -1;
				while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
				{
					char sSpawnGameMode[32], sSurvivorName[32];
					GetEntPropString(iEnt, Prop_Data, "m_iszGameMode", sSpawnGameMode, sizeof(sSpawnGameMode));
					GetEntPropString(iEnt, Prop_Data, "m_iszSurvivorName", sSurvivorName, sizeof(sSurvivorName));
					if((StrEqual(sGameMode, "coop") && ((strlen(sSpawnGameMode) > 0 && StrContains(sSpawnGameMode, sGameMode) == -1) ||(strlen(sSpawnGameMode) == 0 && strlen(sSurvivorName) == 0))) || (!StrEqual(sGameMode, "coop") && StrContains(sSpawnGameMode, sGameMode) == -1))
					{
						#if DEBUG
						PrintToServer("Debug: Removing info_survivor_position %d", iEnt);
						#endif
						RemoveEntity(iEnt);
					}
				}

				iEnt = -1;
				while ((iEnt = FindEntityByClassname(iEnt, "info_player_start")) != -1)
				{
					#if DEBUG
					PrintToServer("Debug: Removing info_player_start %d", iEnt);
					#endif
					RemoveEntity(iEnt);
				}
			}
			else
			{
				// We didn't find a named spawn point
				// We need to try with Ordered spawn points now
				iEnt = -1;
				bool bFoundOrderedSpawnPoint = false;
				while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
				{
					if(GetEntProp(iEnt, Prop_Data, "m_order") > 0)
					{
						GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", g_fDesiredPos);
						break;
					}
				}

				if(bFoundOrderedSpawnPoint)
				{
					//cleanup
					iEnt = -1;
					while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
					{
						if(GetEntProp(iEnt, Prop_Data, "m_order") == 0)
							RemoveEntity(iEnt);
					}

					iEnt = -1;
					while ((iEnt = FindEntityByClassname(iEnt, "info_player_start")) != -1)
						RemoveEntity(iEnt);
				}
				else
				{
					// We didn't find an Ordered spawn point
					// We need to try with info_player_spawn points now
					while ((iEnt = FindEntityByClassname(iEnt, "info_player_spawn")) != -1)
					{
						GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", g_fDesiredPos);
						break;
					}
				}
			}
		}
		else if(StrEqual("coop", sGameMode) || StrEqual("versus", sGameMode))
		{
			// not first map, so we need to check if a player spawned first
			// check his position and spawn users there
			// there's no really other way to do it
			// some people put info_player_spawn way ahead of the initial safehouse so checking it
			// is notsecure

			// we need a timer becase at this moment they will still have the origins from the
			// previous map
			LockAllPlayerMovement();
			CreateTimer(7.5, Timer_FindFirstSpawned);
		}

		// If everything above failed to trigger, the mapper decided to just use info_player_start for player spawns.
		// In that case we don't need to do anything because AFAIK you can't set individual spawns with those.
	}
}

public Action Timer_FindFirstSpawned(Handle timer)
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
		{
			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", g_fDesiredPos);
			break;
		}
	}
	EnsureSpawns();
	AllowAllPlayerMovement();

	return Plugin_Continue;
}

void LockAllPlayerMovement()
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
		{
			int pFlags = GetEntityFlags(iClient);
			SetEntityFlags(iClient, (pFlags | FL_FROZEN));
		}
	}
}

void LockSinglePlayerMovement(int iClient)
{
	if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
	{
		int pFlags = GetEntityFlags(iClient);
		SetEntityFlags(iClient, (pFlags | FL_FROZEN));
	}
}

void AllowSinglePlayerMovement(int iClient)
{
	if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
	{
		int pFlags = GetEntityFlags(iClient);
		SetEntityFlags(iClient, (pFlags & ~FL_FROZEN));
	}
}

void AllowAllPlayerMovement()
{
	for(int iClient=1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
		{
			int pFlags = GetEntityFlags(iClient);
			SetEntityFlags(iClient, (pFlags & ~FL_FROZEN));
		}
	}
}

void turn_survivors_into_original()
{
    for(int iClient=1; iClient <= MaxClients; iClient++)
    {
        if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
        {
			int iSurvivorChar = GetEntProp(iClient, Prop_Send, "m_survivorCharacter");
			g_iSurvivorCharacter[iClient] = iSurvivorChar;

			switch(iSurvivorChar)
			{
				case COACH, LOUIS:
				{
					SetEntProp(iClient, Prop_Send, "m_survivorCharacter", g_bIsL4D1 ? LOUIS : COACH);
				}
				case ROCHELLE, ZOEY:
				{
					SetEntProp(iClient, Prop_Send, "m_survivorCharacter", g_bIsL4D1 ? ZOEY : ROCHELLE);
				}
				case ELLIS, FRANCIS:
				{
					SetEntProp(iClient, Prop_Send, "m_survivorCharacter", g_bIsL4D1 ? FRANCIS : ELLIS);
				}
				default:
				{
					//incl custom survivor
					SetEntProp(iClient, Prop_Send, "m_survivorCharacter", g_bIsL4D1 ? BILL : NICK);
				}
			}
        }
    }
}

void restore_survivors()
{
    for(int iClient=1; iClient <= MaxClients; iClient++)
    {
        if(IsClientInGame(iClient) && GetClientTeam(iClient) == L4D_TEAM_SURVIVOR)
			SetEntProp(iClient, Prop_Send, "m_survivorCharacter", g_iSurvivorCharacter[iClient]);
    }
}