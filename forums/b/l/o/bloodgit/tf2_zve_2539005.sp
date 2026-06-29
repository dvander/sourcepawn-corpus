///////////////////////////////////////////////// DEFINES /////////////////////////////////////////////////

#define LoopAlivePlayers(%1) for (int %1 = 1; %1 <= MaxClients; ++%1) if (IsClientInGame(%1) && IsPlayerAlive(%1))
#define TF2_NOTEAM 0
#define TF2_TEAMSPEC 1
#define TF2_TEAMRED 2
#define TF2_TEAMBLUE 3

#define PLUGIN_AUTHOR "#pragma / BloodTiger"
#define PLUGIN_VERSION "1.00"
#define DEBUG

///////////////////////////////////////////////// INCLUDES /////////////////////////////////////////////////

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <smlib>

///////////////////////////////////////////////// PRAGMAS /////////////////////////////////////////////////

#pragma semicolon 1
#pragma newdecls required

///////////////////////////////////////////////// GAMEPLAY /////////////////////////////////////////////////

bool g_bHasRoundStarted = false;
ConVar g_hSetupTime;
ConVar g_hRoundTime;
Handle g_tOpenDoors;
Handle g_tRoundTime;
Handle g_tHalfRoundTime;

//// DOUBLE JUMP ////

// Note : Anything labled Double Jump is from paegus's double jump plugin
Handle g_cvJumpBoost = INVALID_HANDLE;
Handle g_cvJumpEnable = INVALID_HANDLE;
Handle g_cvJumpMax = INVALID_HANDLE;
float g_flBoost = 250.0;
bool g_bDoubleJump = true;
int g_fLastButtons[MAXPLAYERS + 1];
int g_fLastFlags[MAXPLAYERS + 1];
int g_iJumps[MAXPLAYERS + 1];
int g_iJumpMax;

///////////////////////////////////////////////// PLUGIN INFO /////////////////////////////////////////////////

public Plugin myinfo = 
{
	name = "[TF2] Zombie Survival",
	author = PLUGIN_AUTHOR,
	description = "Muselks gamemode of Zombie Survival",
	version = PLUGIN_VERSION,
	url = ""
};

///////////////////////////////////////////////// ON PLUGIN START /////////////////////////////////////////////////

public void OnPluginStart()
{
	//// SERVER COMMANDS ////
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_scrambleteams_auto 0");
	ServerCommand("mp_disable_respawn_times 1");
	ServerCommand("tf_arena_use_queue 0");
	
	//// HOOKS EVENTS ////
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("teamplay_round_active", RoundActive);
	HookEvent("teamplay_round_win", RoundEnd);
	HookEvent("teamplay_waiting_ends", WaitingEnds);
	HookEvent("player_death", PlayerDeath);
	HookEvent("post_inventory_application", Resupply);
	HookEvent("player_team", ChatSpam, EventHookMode_Pre);
	HookEvent("server_cvar", ChatSpam, EventHookMode_Pre);
	
	//// CONVARS ////
	CreateConVar("tf_zve_version", "1", "dont touch", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hSetupTime = CreateConVar("tf_zve_setuptime", "60", "How long before setup time ends?");
	g_hRoundTime = CreateConVar("tf_zve_roundtime", "340", "How long before the round ends (This is the time after setup time ends)");
	
	//// COMMAND LISTENERS ////
	AddCommandListener(CL_Build, "build");
	AddCommandListener(CL_ChangeClass, "joinclass");
	AddCommandListener(CL_ChangeTeam, "jointeam");
	AddCommandListener(CL_Spectate, "spectate");
	
	//// DOUBLE JUMP ////
	g_cvJumpEnable = CreateConVar("tf_zve_dj_enabled", "1", "Enable double jumping for blues?", FCVAR_NOTIFY);
	g_cvJumpBoost = CreateConVar("tf_zve_dj_boost", "250.0", "The amount of vertical boost to apply to double jumps.", FCVAR_NOTIFY);
	g_cvJumpMax = CreateConVar("tf_zve_dj_max", "1", "The maximum number of re-jumps allowed while already jumping.", FCVAR_NOTIFY);
	
	HookConVarChange(g_cvJumpBoost, convar_ChangeBoost);
	HookConVarChange(g_cvJumpEnable, convar_ChangeEnable);
	HookConVarChange(g_cvJumpMax, convar_ChangeMax);
	
	g_bDoubleJump = GetConVarBool(g_cvJumpEnable);
	g_flBoost = GetConVarFloat(g_cvJumpBoost);
	g_iJumpMax = GetConVarInt(g_cvJumpMax);
}

///////////////////////////////////////////////// GAME ENGINE CHECK /////////////////////////////////////////////////

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));

	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta"))
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

///////////////////////////////////////////////// EVENTS /////////////////////////////////////////////////

public Action RoundActive(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int randomclient = Client_GetRandom(CLIENTFILTER_INGAME && CLIENTFILTER_TEAMTWO);
	
	if (IsClientInGame(randomclient))
	{
		FUNCTION_MakeFirstZombie(randomclient);
	}
	
	FUNCTION_DeleteRoundTimer();
	FUNCTION_DisableCapturing();
}

public Action RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			FUNCTION_MakeHuman(i);
		}
	}
}

public Action RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_bHasRoundStarted = false;
	CloseHandle(g_tRoundTime);
	CloseHandle(g_tHalfRoundTime);
	CloseHandle(g_tOpenDoors);
}

public Action WaitingEnds(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_bHasRoundStarted = false;
	CloseHandle(g_tRoundTime);
	CloseHandle(g_tHalfRoundTime);
	CloseHandle(g_tOpenDoors);
}

public Action Resupply(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	
	if(g_bHasRoundStarted)
	{
		if(IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			ClientCommand(client, "slot03");
			CreateTimer(1.0, TIMER_CheckWeapons, client);
		}
	}
	
	if(!g_bHasRoundStarted)
	{
		if(IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			ClientCommand(client, "slot03");
			CreateTimer(1.0, TIMER_CheckWeapons, client);
		}
	}
}

public Action PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (g_bHasRoundStarted)
	{
		if (IsClientInGame(client))
		{
			FUNCTION_MakeZombie(client);
		}
	}
	
	if(!g_bHasRoundStarted)
	{
		if(IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			FUNCTION_MakeZombie(client);
		}
	}
	
	FUNCTION_CheckPlayerCount(client);
}

public Action ChatSpam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	hEvent.BroadcastDisabled = true;
	return Plugin_Continue;
}

///////////////////////////////////////////////// SOURCEMOD EVENTS /////////////////////////////////////////////////

public void OnPostAdminCheck(int client)
{
	if (g_bHasRoundStarted)
	{
		FUNCTION_MakeZombie(client);
	}
	else
	{
		FUNCTION_MakeHuman(client);
	}
}

///////////////////////////////////////////////// COMMAND LISTENERS /////////////////////////////////////////////////

/*
 * This code is from Tsunami's TF2 build restrictions. It prevents engineers
 * from even placing a sentry.
 * Credit : shewokees
 */

public Action CL_Build(int client, const char[] command, int argc)
{
	//initializing the array that will contain all user collision information
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);

	//Feeding an array because i can only give one custom variable to the timer
	CreateTimer(3.0, Recollide, client);

	// Get arguments
	char sObjectType[256];
	GetCmdArg(1, sObjectType, sizeof(sObjectType));

	// Get object mode, type and client's team
	int iObjectType = StringToInt(sObjectType),
	iTeam = GetClientTeam(client);

	// If invalid object type passed, or client is not on Blu or Red
	if(iObjectType < view_as<int>(TFObject_Dispenser) || iObjectType > view_as<int>(TFObject_Sentry) || iTeam < view_as<int>(TFTeam_Red) )
	{
		return Plugin_Continue;
	}
	//Blocks sentry building
	else if(iObjectType==view_as<int>(TFObject_Sentry) )
	{
		PrintToChat(client, "You cannot do that");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action CL_ChangeTeam(int client, const char[] command, int argc)
{
	if(TF2_GetClientTeam(client) == TFTeam_Unassigned || TF2_GetClientTeam(client) == TFTeam_Spectator)
	{
		return Plugin_Continue;
	}
	
	PrintToChat(client, "You cannot do that");
	return Plugin_Handled;
}

public Action CL_ChangeClass(int client, const char[] command, int argc)
{
	char arg1[256];
	GetCmdArg(1, arg1, sizeof(arg1));

	if(strcmp(arg1,"medic",false)==0 && TF2_GetClientTeam(client)==TFTeam_Blue)
	{
		return Plugin_Continue;
	}
	else if(TF2_GetClientTeam(client)==TFTeam_Blue)
	{
		ClientCommand(client,"joinclass medic");
	}

	if(strcmp(arg1,"engineer",false)==0 && TF2_GetClientTeam(client)==TFTeam_Red )
	{
		return Plugin_Continue;
	}
	else if(TF2_GetClientTeam(client)==TFTeam_Red )
	{
		ClientCommand(client,"joinclass engineer");
	}


	PrintToChat(client, "You cannot do that");
	return Plugin_Handled;
}

public Action CL_Spectate(int client, const char[] command, int argc)
{
	PrintToChat(client, "You cannot do that.");
	return Plugin_Handled;
}

///////////////////////////////////////////////// TIMERS /////////////////////////////////////////////////

public Action Recollide(Handle timer, any client)
{
	if(IsClientInGame(client))
	{
		if(TF2_GetClientTeam(client) == TFTeam_Red)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 3);
		}
		else if(TF2_GetClientTeam(client) == TFTeam_Blue)
		{	
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
		}
	}
}

public Action TIMER_OpenDoors(Handle timer)
{
	FUNCTION_DeleteEntities();
	g_bHasRoundStarted = true;
	PrintToChatAll("The zombies have been released!");
	g_tRoundTime = CreateTimer(g_hRoundTime.FloatValue, TIMER_RoundTime);
	g_tHalfRoundTime = CreateTimer(g_hRoundTime.FloatValue/2.0, TIMER_HalfRoundTime);
	ServerCommand("tf_zve_dj_boost 250");
	PrintToChatAll("This round will last for %i seconds.", g_hRoundTime.IntValue);
}


public Action TIMER_RoundTime(Handle timer)
{
	ServerCommand("sm_slay @red");
}

public Action TIMER_HalfRoundTime(Handle timer)
{
	if(GetConVarBool(g_cvJumpEnable))
	{
		PrintToChatAll("Half Time, the zombies are getting a higher jump boost!");	
		ServerCommand("tf_zve_dj_boost 300");
	}
}

public Action TIMER_CheckWeapons(Handle timer, any client)
{
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	ClientCommand(client, "slot03");
}

///////////////////////////////////////////////// ON GAME FRAME /////////////////////////////////////////////////

public void OnGameFrame() 
{
	if (g_bDoubleJump) // double jump active
	{
		for (int i = 1; i <= MaxClients; i++) // cycle through players
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) 
			{
				FUNCTION_DoubleJump(i); // Check for double jumping
			}
		}
	}
}


///////////////////////////////////////////////// HOOKED CONVAR CHANGES /////////////////////////////////////////////////

//// DOUBLE JUMP ////

public void convar_ChangeBoost(Handle convar, const char[] oldVal, const char[] newVal) 
{
	g_flBoost = StringToFloat(newVal);
}

public void convar_ChangeEnable(Handle convar, const char[] oldVal, const char[] newVal) 
{
	if (StringToInt(newVal) >= 1) 
	{
		g_bDoubleJump = true;
	} 
	else 
	{
		g_bDoubleJump = false;
	}
}

public void convar_ChangeMax(Handle convar, const char[] oldVal, const char[] newVal) 
{
	g_iJumpMax = StringToInt(newVal);
}


///////////////////////////////////////////////// FUNCTIONS /////////////////////////////////////////////////

void FUNCTION_DeleteEntities()
{
	int iEnt = -1;
	
	while((iEnt = FindEntityByClassname(iEnt, "func_door")) != -1)
	{
		AcceptEntityInput(iEnt, "Open");
		AcceptEntityInput(iEnt, "Kill");
	}
	
	while((iEnt = FindEntityByClassname(iEnt, "func_respawnroomvisualizer")) != -1)
	{
		AcceptEntityInput(iEnt, "Kill");
	}
	
	while((iEnt = FindEntityByClassname(iEnt, "func_regenerate")) != -1)
	{
		AcceptEntityInput(iEnt, "Kill");
	}
}

void FUNCTION_DeleteRoundTimer()
{
	int iEnt = -1;
	
	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (strncmp(mapname, "koth_", 6) == 0)
	{
		while((iEnt = FindEntityByClassname(iEnt, "tf_logic_koth")) != -1)
		{
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	else
	{
		while((iEnt = FindEntityByClassname(iEnt, "team_round_timer")) != -1)
		{
			AcceptEntityInput(iEnt, "Kill");
			PrintToChatAll("This gamemode may not work on the arena maps.");
		}
	}
	
	if (strncmp(mapname, "arena_", 6) == 0)
	{
		while((iEnt = FindEntityByClassname(iEnt, "tf_logic_arena")) != -1)
		{
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	else
	{
		while((iEnt = FindEntityByClassname(iEnt, "team_round_timer")) != -1)
		{
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}

void FUNCTION_MakeHuman(int client)
{
	RequestFrame(InstantHuman, GetClientSerial(client));
}

void FUNCTION_MakeZombie(int client)
{
	RequestFrame(InstantZombie, GetClientSerial(client));
}

void FUNCTION_MakeFirstZombie(int client)
{
	RequestFrame(FirstZombie, GetClientSerial(client));
}

void FUNCTION_CheckPlayerCount(int client)
{
	RequestFrame(CheckPlayerCount, GetClientSerial(client));
}

int FUNCTION_GetTeamPlayersAlive(int iTeam) 
{
	int iCount;
	
	LoopAlivePlayers(i) 
	{
		if (GetClientTeam(i) == iTeam)
		{
			iCount++;
		}
	}
	
	return iCount;
}


// Tooken from Swixel's capture toggle

void FUNCTION_DisableCapturing()
{
  /* Things to enable or disable */
  char targets[5][25] = {"team_control_point_master","team_control_point","trigger_capture_area","item_teamflag","func_capturezone"};
  char input[7] = "Disable";

  /* Loop through things that should be enabled/disabled, and push it as an input */
  int ent = 0;
  for (int i = 0; i < 5; i++)
  {
    ent = MaxClients+1;
    while((ent = FindEntityByClassname(ent, targets[i]))!=-1)
    {
      AcceptEntityInput(ent, input);
    }
  }
}

///////////////////////////////////////////////// ENTITY STUFF /////////////////////////////////////////////////

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "obj_sentrygun", false) && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

///////////////////////////////////////////////// SERIAL FUNCTIONS /////////////////////////////////////////////////

public void InstantZombie(any serial)
{
	int client = GetClientFromSerial(serial);
	int melee = GetPlayerWeaponSlot(client, 2);
	
	if(client != 0)
	{
		int team = GetClientTeam(client);
		if(IsPlayerAlive(client) && team != 1 || !IsPlayerAlive(client) && team != 1)
		{
			TF2_ChangeClientTeam(client, TFTeam_Blue);
			TF2_SetPlayerClass(client, TFClass_Medic);
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
			ClientCommand(client, "slot3");
		}
	}
}

public void FirstZombie(any serial)
{
	int client = GetClientFromSerial(serial);
	int melee = GetPlayerWeaponSlot(client, 2);
	
	if(client != 0)
	{
		int team = GetClientTeam(client);
		if(IsPlayerAlive(client) && team != 1 || !IsPlayerAlive(client) && team != 1)
		{
			TF2_ChangeClientTeam(client, TFTeam_Blue);
			TF2_SetPlayerClass(client, TFClass_Medic);
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 1);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
			ClientCommand(client, "slot3");
			TF2_StunPlayer(client, GetConVarFloat(g_hSetupTime), 1.00, TF_STUNFLAG_SLOWDOWN);
			g_tOpenDoors = CreateTimer(GetConVarFloat(g_hSetupTime), TIMER_OpenDoors);
			PrintToChatAll("%N was chosen to be the first zombie.", client);
		}
	}
}

public void InstantHuman(any serial)
{
	int client = GetClientFromSerial(serial);
	if(client != 0)
	{
		int team = GetClientTeam(client);
		if(IsPlayerAlive(client) && team != 1 || !IsPlayerAlive(client) && team != 1)
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
			TF2_SetPlayerClass(client, TFClass_Engineer);
			TF2_RespawnPlayer(client);
			TF2_RegeneratePlayer(client);
		}
	}
}

void CheckPlayerCount(any serial) 
{
	int client = GetClientFromSerial(serial);
	
	if (FUNCTION_GetTeamPlayersAlive(TF2_TEAMRED) == 0) 
	{
		FUNCTION_ForceEndRound();
	}
	
	if (FUNCTION_GetTeamPlayersAlive(TF2_TEAMRED) == 1)
	{
		if(client != 0)
		{
			int team = GetClientTeam(client);
			if(IsPlayerAlive(client) && team != 3 || IsPlayerAlive(client) && team != 1)
			{
				TF2_AddCondition(client, TFCond_Kritzkrieged, TFCondDuration_Infinite);
			}
		}
	}
}

int FUNCTION_DoubleJump(const any client) 
{
	int fCurFlags = GetEntityFlags(client); // current flags
	int fCurButtons = GetClientButtons(client); // current buttons
	
	if (g_fLastFlags[client] & FL_ONGROUND) // was grounded last frame
	{
		if (!(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP) 
		{
			FUNCTION_OriginalJump(client); // process jump from the ground
		}
	} 
	else if (fCurFlags & FL_ONGROUND) 
	{
		FUNCTION_Landed(client); // process landing on the ground
	} 
	else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP) 
	{
		FUNCTION_ReJump(client); // process attempt to double-jump
	}
	
	g_fLastFlags[client] = fCurFlags; // update flag state for next frame
	g_fLastButtons[client] = fCurButtons; // update button state for next frame
}

int FUNCTION_OriginalJump(const any client) 
{
	g_iJumps[client]++; // increment jump count
}

int FUNCTION_Landed(const any client) 
{
	g_iJumps[client] = 0; // reset jumps count
}

int FUNCTION_ReJump(const any client) 
{
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) 
	{
		g_iJumps[client]++;
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		vVel[2] = g_flBoost;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}

int FUNCTION_ForceEndRound()
{
	int iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");

	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
		{
			DispatchSpawn(iEnt);
		}
	}
	
	int iWinningTeam = 0;

	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
}	


