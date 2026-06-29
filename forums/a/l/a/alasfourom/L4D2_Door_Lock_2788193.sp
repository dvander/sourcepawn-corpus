/*=========================================================================================================

	Plugin Info:

*	Name	:	L4D2 Saferoom Locker
*	Author	:	alasfourom
*	Descp	:	Lock Saferoom Door Until All Players Are Ready
*	Link	:	https://forums.alliedmods.net

===========================================================================================================

03-09-2022 > Version 1.0: Initial release

===========================================================================================================

	To Do List:

*	Nothing ATM

 *================================================================================================================ *
 *												Includes, Pragmas and Define			   						   *
 *================================================================================================================ */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

/* =============================================================================================================== *
 *                     		 				 Bools, Floats, Handles and ConVars									   *
 *================================================================================================================ */

bool g_bLeft4Dead2;
bool g_bLockSafeAreas;
bool g_bWarmingUpTime;
bool g_bIgnoreLoaders;
bool g_bLeftSafeAreas;
bool g_bRoundHasEnded;

Handle g_hWarmingUp;

float g_fUnlockTime;

ConVar Cvar_DoorLock_AllowLock;
ConVar Cvar_DoorLock_GameModes;
ConVar Cvar_DoorLock_Countdown;
ConVar Cvar_DoorLock_LoaderMax;
ConVar Cvar_DoorLock_AllowGlow;
ConVar Cvar_DoorLock_GlowRange;
ConVar Cvar_DoorLock_LockColor;
ConVar Cvar_DoorLock_OpenColor;

/* =============================================================================================================== *
 *                     		 						 Plugin Info												   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D2 Saferoom Locker",
	author = "alasfourom",
	description = "Lock Saferoom Door Until All Players Are Ready",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
};

/* =============================================================================================================== *
 *                     		 				 Plugin Supports Left 4 Dead: 2 Only								   *
 *================================================================================================================ */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead: 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

/* =============================================================================================================== *
 *                     		 				 		OnPluginStart												   *
 *================================================================================================================ */

public void OnPluginStart()
{
	CreateConVar ("l4d2_door_lock_version", PLUGIN_VERSION, "L4D2 Door Lock", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	Cvar_DoorLock_AllowLock = CreateConVar("l4d2_doorlock_plugin_enable", "1", "Enable L4D2 Door Lock Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_GameModes = CreateConVar("l4d2_doorlock_game_mode", "versus,coop", "Add The Modes You Want To Enable This Plugin In It", FCVAR_NOTIFY);
	Cvar_DoorLock_Countdown = CreateConVar("l4d2_doorlock_countdown", "12", "How Long You Want To Lock The Safe Area (In Seconds)", FCVAR_NOTIFY);
	Cvar_DoorLock_LoaderMax = CreateConVar("l4d2_doorlock_loaders_time", "30", "How Long Plugin Waits For Loaders Before Giving Up On Them (In Seconds)", FCVAR_NOTIFY);
	Cvar_DoorLock_AllowGlow = CreateConVar("l4d2_doorlock_glow_enable", "1", "Set A Glow For The Saferoom Doors", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Cvar_DoorLock_GlowRange = CreateConVar("l4d2_doorlock_glow_range", "500", "Set The Glow Range For Saferoom Doors", FCVAR_NOTIFY);
	Cvar_DoorLock_LockColor = CreateConVar("l4d2_doorlock_lock_glow_color",	"255 0 0", "Set Saferoom Lock Glow Color, (0-255) Separated By Spaces.", FCVAR_NOTIFY);
	Cvar_DoorLock_OpenColor = CreateConVar("l4d2_doorlock_unlock_glow_color", "0 255 0", "Set Saferoom Unlock Glow Color, (0-255) Separated By Spaces.", FCVAR_NOTIFY);
	AutoExecConfig(true, "L4D2_Door_Lock");
	
	RegAdminCmd("sm_lock", Command_Lock, ADMFLAG_UNBAN);
	RegAdminCmd("sm_unlock", Command_Unlock, ADMFLAG_UNBAN);
	
	HookEvent("round_freeze_end", EVENT_OnRoundFreezeEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_left_start_area", Event_LeftStartArea);
	HookEvent("player_left_safe_area", Event_LeftStartArea);
}

/* =============================================================================================================== *
 *												EVENT_OnRoundFreezeEnd  										   *
 *================================================================================================================ */

void EVENT_OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bLeft4Dead2 && Cvar_DoorLock_AllowLock.BoolValue)
	{
		char GameMode[64];
		char GameInfo[64];
		FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
		Cvar_DoorLock_GameModes.GetString(GameInfo, sizeof(GameInfo));
		
		if (StrContains(GameInfo, GameMode) != -1)
		{
			g_bLockSafeAreas = false;
			g_bWarmingUpTime = true;
			g_bIgnoreLoaders = false;
			g_bLeftSafeAreas = false;
			g_bRoundHasEnded = false;
			
			FreezePlayersInFirstChapters();
			LockAllRotatingSaferoomDoors();
			
			g_hWarmingUp = CreateTimer(Cvar_DoorLock_LoaderMax.FloatValue, Timer_DisregardLoaders, _, TIMER_FLAG_NO_MAPCHANGE);
			g_hWarmingUp = CreateTimer(1.0, Timer_PendingLoaders, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

/* =============================================================================================================== *
 *													Event_OnPlayerSpawn  										   *
 *================================================================================================================ */

void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2) return;
	
	CreateTimer(0.5, Timer_FreezeSpawnedSurvivorsWhileLocked, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_FreezeSpawnedSurvivorsWhileLocked(Handle timer, int client)
{
	if (g_bLockSafeAreas)
		FreezePlayersInFirstChapters();
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *													 Event_OnRoundEnd  											   *
 *================================================================================================================ */

void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundHasEnded = true;
	g_bLeftSafeAreas = false;
	
	if (g_bWarmingUpTime)
	{
		delete g_hWarmingUp;
		g_bWarmingUpTime = false;
	}
}

/* =============================================================================================================== *
 *													 Event_LeftStartArea  										   *
 *================================================================================================================ */

public void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bLockSafeAreas)
	{
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		PrintToChatAll("\x04[LOCK] \x01Safe area was forced to \x03unlock\x01.");
	}
	g_bLeftSafeAreas = true;
}

/* =============================================================================================================== *
 *                     		 				 Waiting For Loaders Mechanism										   *
 *================================================================================================================ */

Action Timer_DisregardLoaders(Handle timer)
{
	g_bIgnoreLoaders = true;
	return Plugin_Handled;
}

Action Timer_PendingLoaders(Handle timer)
{
	if (!g_bRoundHasEnded)
	{
		int Loaders = IsClientLoading();
		int Human = IsClientRealPlayer();
		
		if (Human < 1) return Plugin_Continue;
		
		else if (Loaders > 0 && !g_bIgnoreLoaders) return Plugin_Continue;

		else g_hWarmingUp = CreateTimer(5.0, Timer_WarmingUpBeforeStartingCountdown, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

Action Timer_WarmingUpBeforeStartingCountdown(Handle timer)
{
	if (!g_bRoundHasEnded)
	{
		g_bWarmingUpTime = false;
		g_fUnlockTime = Cvar_DoorLock_Countdown.FloatValue;
		CreateTimer(1.0, Timer_StartCountdownToUnlock, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 		 				Timer: Countdown											   *
 *================================================================================================================ */

Action Timer_StartCountdownToUnlock(Handle timer)
{
	if (!g_bRoundHasEnded)
	{
		int timeleft = RoundToNearest(g_fUnlockTime--);
		if (timeleft >= 0 && g_bLockSafeAreas)
		{
			PrintHintTextToAll("Please Wait: %d", timeleft);
			return Plugin_Continue;
		}
		else
		{
			UnFreezePlayersInFirstChapters();
			UnLockAllRotatingSaferoomDoors();
			PrintHintTextToAll("Move Out!");
		}
	}
	return Plugin_Stop;
}

/* =============================================================================================================== *
 *                     		 		 				Command_Lock												   *
 *================================================================================================================ */

public Action Command_Lock(int client, int args)
{
	if (g_bLeftSafeAreas) PrintToChat(client, "\x04[LOCK] \x03Error: \x01players already left the safe area.");
	
	else if(g_bLockSafeAreas) PrintToChat(client, "\x04[LOCK] \x01The safe area is \x05already locked\x01.");
		
	else
	{
		FreezePlayersInFirstChapters();
		LockAllRotatingSaferoomDoors();
		PrintToChatAll("\x04[LOCK] \x01Admin \x03%N \x01has \x05locked \x01the safe area", client);
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 		 				Command_Unlock												   *
 *================================================================================================================ */

public Action Command_Unlock(int client, int args)
{
	if (g_bLeftSafeAreas) PrintToChat(client, "\x04[LOCK] \x03Error: \x01players already left the safe area.");
	
	else if(!g_bLockSafeAreas) PrintToChat(client, "\x04[LOCK] \x01The safe area is \x05already unlocked\x01.");
	
	else
	{
		UnFreezePlayersInFirstChapters();
		UnLockAllRotatingSaferoomDoors();
		PrintToChatAll("\x04[LOCK] \x01Admin \x03%N \x01has \x05unlocked \x01the safe area", client);
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     		 		 		First Chapters: Freeze and Unfreeze									   *
 *================================================================================================================ */

void FreezePlayersInFirstChapters()
{
	if(L4D_IsFirstMapInScenario())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i))
			{
				SetEntProp (i, Prop_Data, "m_takedamage", 0);
				
				if (GetClientTeam(i) == 2)
					SetEntityMoveType(i, MOVETYPE_NONE);
			}
		}
		SetConVarInt(FindConVar("nb_player_stop"), 1);
		g_bLockSafeAreas = true;
	}
}

void UnFreezePlayersInFirstChapters()
{
	if(L4D_IsFirstMapInScenario())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i))
			{
				SetEntProp (i, Prop_Data, "m_takedamage", 2);
				
				if (GetClientTeam(i) == 2)
					SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
		SetConVarInt(FindConVar("nb_player_stop"), 0);
		g_bLockSafeAreas = false;
	}
}

/* =============================================================================================================== *
 *                     		 	Chapters With Roatating Saferoom Doors: Lock and Unlock							   *
 *================================================================================================================ */

void LockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (g_bLockSafeAreas || !IsValidEnt(iCheckPointDoor)) return;
	
	AcceptEntityInput(iCheckPointDoor, "Close");
	AcceptEntityInput(iCheckPointDoor, "Lock");
	SetVariantString("spawnflags 40960");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");

	int g_iDoorLockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_LockColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorLockColors, sColor);

	if (Cvar_DoorLock_AllowGlow.BoolValue)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, g_iDoorLockColors, false);
		
	SetConVarInt(FindConVar("nb_player_stop"), 1);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			SetEntProp (i, Prop_Data, "m_takedamage", 0);
	
	g_bLockSafeAreas = true;
}

void UnLockAllRotatingSaferoomDoors()
{
	int iCheckPointDoor = L4D_GetCheckpointFirst();
	if (!g_bLockSafeAreas || !IsValidEnt(iCheckPointDoor)) return;
	
	SetVariantString("spawnflags 8192");
	AcceptEntityInput(iCheckPointDoor, "AddOutput");
	AcceptEntityInput(iCheckPointDoor, "Unlock");
	AcceptEntityInput(iCheckPointDoor, "StartGlowing");
	
	int g_iDoorUnlockColors[3];
	char sColor[16];
	
	Cvar_DoorLock_OpenColor.GetString(sColor, sizeof(sColor));
	GetColor(g_iDoorUnlockColors, sColor);
	
	if (Cvar_DoorLock_AllowGlow.BoolValue)
		L4D2_SetEntityGlow(iCheckPointDoor, L4D2Glow_Constant, Cvar_DoorLock_GlowRange.IntValue, 0, g_iDoorUnlockColors, false);
	
	SetConVarInt(FindConVar("nb_player_stop"), 0);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			SetEntProp (i, Prop_Data, "m_takedamage", 2);
	
	g_bLockSafeAreas = false;
}

/* =============================================================================================================== *
 *                     		 		 		GetColor For Door RGB Glow Cvar										   *
 *================================================================================================================ */

void GetColor(int[] array, char[] sTemp)
{
	if(StrEqual(sTemp, ""))
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
	{
		array[0] = array[1] = array[2] = 0;
		return;
	}

	array[0] = StringToInt(sColors[0]);
	array[1] = StringToInt(sColors[1]);
	array[2] = StringToInt(sColors[2]);
}

/* =============================================================================================================== *
 *                     		 		 				Other Stuff													   *
 *================================================================================================================ */

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

int IsClientLoading()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			number++;
	}
	return number;
}

int IsClientRealPlayer()
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			number++;
	}
	return number;
}