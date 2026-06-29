/*
*	L4D2 Rescue Teleport
*	Copyright (C) 2025 JustMe
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define PLUGIN_VERSION		"1.0.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Rescue Teleport
*	Author	:	JustMe
*	Descrp	:	Allows stuck players to teleport to teammates
*	Link	:	

========================================================================================
	Change Log:
	
1.0.2 (17-May-2026)
	- Replaced crash-prone info_gamemode entity with L4D_GetGameModeType native.

1.0.1 (10-Jan-2025)
	- Added support for ledge hanging players

1.0.0 (01-Jan-2025)
	- Initial release

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <multicolors>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"{green}[Rescue]{default} "

#define L4D_TEAM_SURVIVOR	2
#define L4D_TEAM_INFECTED	3



// ====================================================================================================
//					PLUGIN VARS
// ====================================================================================================
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarCooldown, g_hCvarMaxUses, g_hCvarGodMode, g_hCvarAllowInfected, g_hCvarAllowIncapped;
ConVar g_hCvarRequirePermission, g_hCvarRequestTimeout, g_hCvarDebug;

bool g_bCvarAllow, g_bAllowInfected, g_bAllowIncapped, g_bRequirePermission, g_bDebugMode;
float g_fCvarCooldown, g_fCvarGodMode, g_fCvarRequestTimeout;
int g_iCvarMaxUses, g_iCurrentMode;

float g_fLastTeleportTime[MAXPLAYERS+1];
int g_iUsesThisRound[MAXPLAYERS+1];
int g_iPendingRequest[MAXPLAYERS+1];
int g_iPendingTarget[MAXPLAYERS+1];
bool g_bGodModeActive[MAXPLAYERS+1];
Handle g_hRequestTimer[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Rescue Teleport",
	author = "JustMe",
	description = "Allows players to teleport to teammates",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_rescue_teleport.phrases");

	g_hCvarAllow =				CreateConVar("sm_rescue_tp_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =				CreateConVar("sm_rescue_tp_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =			CreateConVar("sm_rescue_tp_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog =			CreateConVar("sm_rescue_tp_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	g_hCvarCooldown =			CreateConVar("sm_rescue_tp_cooldown",			"5.0",			"Cooldown time (seconds) between teleports for each player.", CVAR_FLAGS, true, 0.0);
	g_hCvarMaxUses =			CreateConVar("sm_rescue_tp_max_uses",			"-1",			"Max uses per round per player. -1 = Unlimited.", CVAR_FLAGS, true, -1.0);
	g_hCvarGodMode =			CreateConVar("sm_rescue_tp_god_mode",			"2.0",			"God mode duration (seconds) after teleport. 0 = Disable.", CVAR_FLAGS, true, 0.0);
	g_hCvarAllowInfected =		CreateConVar("sm_rescue_tp_allow_infected",		"0",			"Allow infected team to use this command.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarAllowIncapped =		CreateConVar("sm_rescue_tp_allow_incapped",		"1",			"Allow incapped/ledge hanging players to use this command.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarRequirePermission =	CreateConVar("sm_rescue_tp_require_permission",	"0",			"Require target player's permission to teleport. 0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarRequestTimeout =		CreateConVar("sm_rescue_tp_request_timeout",	"15.0",			"Time (seconds) before a teleport request expires.", CVAR_FLAGS, true, 5.0);
	g_hCvarDebug =				CreateConVar("sm_rescue_tp_debug",				"0",			"Enable debug logging.", CVAR_FLAGS, true, 0.0, true, 1.0);
	CreateConVar("sm_rescue_tp_version", PLUGIN_VERSION, "Rescue Teleport plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d2_rescue_teleport");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarCooldown.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxUses.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGodMode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllowIncapped.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRequirePermission.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRequestTimeout.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDebug.AddChangeHook(ConVarChanged_Cvars);

	RegConsoleCmd("sm_help", Command_RescueTeleport, "Teleport to a teammate. Usage: !help <playername>");
	RegConsoleCmd("sm_rescue", Command_RescueTeleport, "Teleport to a teammate. Usage: !rescue <playername>");
	RegConsoleCmd("sm_stuck", Command_RescueTeleport, "Teleport to a teammate. Usage: !stuck <playername>");

	IsAllowed();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarCooldown =		g_hCvarCooldown.FloatValue;
	g_iCvarMaxUses =		g_hCvarMaxUses.IntValue;
	g_fCvarGodMode =		g_hCvarGodMode.FloatValue;
	g_bAllowInfected =		g_hCvarAllowInfected.BoolValue;
	g_bAllowIncapped =		g_hCvarAllowIncapped.BoolValue;
	g_bRequirePermission =	g_hCvarRequirePermission.BoolValue;
	g_fCvarRequestTimeout =	g_hCvarRequestTimeout.FloatValue;
	g_bDebugMode =			g_hCvarDebug.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("player_spawn", Event_PlayerSpawn);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn", Event_PlayerSpawn);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
			ResetClientData(i);
		}
	}
}

bool IsAllowedGameMode()
{
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog != 0)
    {
        if (g_iCurrentMode == 0)
        {
            if (!L4D_HasMapStarted())
                return false;
            g_iCurrentMode = L4D_GetGameModeType();
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnMapStart()
{
	
}

public void OnMapEnd()
{
	ResetAllClients();
}

public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	ResetClientData(client);
}

public void OnClientDisconnect(int client)
{
	CancelPendingRequest(client);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_iPendingTarget[i] == client )
		{
			if( IsClientInGame(i) )
				CPrintToChat(i, "%s%t", CHAT_TAG, "Target Left Game");
			CancelPendingRequest(i);
		}
	}

	ResetClientData(client);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllClients();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllClients();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
	{
		g_fLastTeleportTime[client] = 0.0;
		g_bGodModeActive[client] = false;
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( g_bGodModeActive[victim] )
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}



// ====================================================================================================
//					COMMAND
// ====================================================================================================
Action Command_RescueTeleport(int client, int args)
{
	if( !g_bCvarAllow )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Plugin Disabled");
		return Plugin_Handled;
	}

	if( !client || !IsClientInGame(client) )
		return Plugin_Handled;

	int team = GetClientTeam(client);

	if( team == L4D_TEAM_INFECTED && !g_bAllowInfected )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Infected Not Allowed");
		return Plugin_Handled;
	}

	if( team != L4D_TEAM_SURVIVOR && team != L4D_TEAM_INFECTED )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Must Be In Game");
		return Plugin_Handled;
	}

	if( !IsPlayerAlive(client) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Must Be Alive");
		return Plugin_Handled;
	}

	if( team == L4D_TEAM_SURVIVOR && !g_bAllowIncapped && GetEntProp(client, Prop_Send, "m_isIncapacitated") )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Cannot Use Incapped");
		return Plugin_Handled;
	}

	if( team == L4D_TEAM_INFECTED && GetEntProp(client, Prop_Send, "m_isGhost") )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Cannot Use Ghost");
		return Plugin_Handled;
	}

	if( team == L4D_TEAM_INFECTED && L4D_GetPinnedSurvivor(client) != 0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Cannot Use Attacking");
		return Plugin_Handled;
	}

	if( team == L4D_TEAM_SURVIVOR && GetPinningSurvivor(client) != 0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Cannot Use Pinned");
		return Plugin_Handled;
	}

	float currentTime = GetEngineTime();
	if( currentTime - g_fLastTeleportTime[client] < g_fCvarCooldown )
	{
		float timeLeft = g_fCvarCooldown - (currentTime - g_fLastTeleportTime[client]);
		CPrintToChat(client, "%s%t", CHAT_TAG, "Cooldown Wait", timeLeft);
		return Plugin_Handled;
	}

	if( g_iCvarMaxUses > -1 && g_iUsesThisRound[client] >= g_iCvarMaxUses )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Max Uses Reached", g_iCvarMaxUses);
		return Plugin_Handled;
	}

	if( g_iPendingTarget[client] != 0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Request Pending");
		return Plugin_Handled;
	}

	if( args < 1 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Usage");
		return Plugin_Handled;
	}

	char targetName[MAX_NAME_LENGTH];
	GetCmdArgString(targetName, sizeof(targetName));
	StripQuotes(targetName);
	TrimString(targetName);

	int target = FindTargetByName(client, targetName, team);
	if( target == 0 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Player Not Found", targetName);
		return Plugin_Handled;
	}

	if( !IsValidTeleportTarget(target, team) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Target Invalid", target);
		return Plugin_Handled;
	}

	if( g_bRequirePermission && !IsFakeClient(target) )
		SendTeleportRequest(client, target);
	else
		ExecuteTeleport(client, target);

	return Plugin_Handled;
}



// ====================================================================================================
//					PERMISSION REQUEST
// ====================================================================================================
void SendTeleportRequest(int requester, int target)
{
	g_iPendingRequest[target] = requester;
	g_iPendingTarget[requester] = target;

	Menu menu = new Menu(MenuHandler_Permission);

	char title[128];
	Format(title, sizeof(title), "%T", "Menu Title", target, requester);
	menu.SetTitle(title);

	char info[16], menuItemAllow[64], menuItemDeny[64];
	IntToString(GetClientUserId(requester), info, sizeof(info));
	
	Format(menuItemAllow, sizeof(menuItemAllow), "%T", "Menu Allow", target);
	Format(menuItemDeny, sizeof(menuItemDeny), "%T", "Menu Deny", target);
	
	menu.AddItem(info, menuItemAllow);
	menu.AddItem(info, menuItemDeny);

	menu.ExitButton = false;
	menu.Display(target, RoundToNearest(g_fCvarRequestTimeout));

	CPrintToChat(requester, "%s%t", CHAT_TAG, "Request Sent", target);

	delete g_hRequestTimer[requester];

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(requester));
	pack.WriteCell(GetClientUserId(target));
	g_hRequestTimer[requester] = CreateTimer(g_fCvarRequestTimeout, Timer_RequestTimeout, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);

	if( g_bDebugMode )
		PrintToServer("[Rescue] %N sent teleport request to %N", requester, target);
}

int MenuHandler_Permission(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_Select:
		{
			int target = param1;

			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int requester = GetClientOfUserId(StringToInt(info));
			if( !requester || !IsClientInGame(requester) || g_iPendingTarget[requester] != target )
			{
				CPrintToChat(target, "%s%t", CHAT_TAG, "Request Expired Invalid");
				return 0;
			}

			if( param2 == 0 )
			{
				CPrintToChat(target, "%s%t", CHAT_TAG, "You Allowed", requester);
				ExecuteTeleport(requester, target);
			}
			else
			{
				CPrintToChat(target, "%s%t", CHAT_TAG, "You Denied", requester);
				CPrintToChat(requester, "%s%t", CHAT_TAG, "Request Denied", target);
				CancelPendingRequest(requester);
			}
		}
		case MenuAction_Cancel:
		{
			int target = param1;
			if( param2 != MenuCancel_Timeout )
			{
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( g_iPendingTarget[i] == target )
					{
						if( IsClientInGame(i) )
							CPrintToChat(i, "%s%t", CHAT_TAG, "Menu Closed", target);
						CancelPendingRequest(i);
						break;
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return 0;
}

Action Timer_RequestTimeout(Handle timer, DataPack pack)
{
	pack.Reset();
	int requester = GetClientOfUserId(pack.ReadCell());
	int target = GetClientOfUserId(pack.ReadCell());

	if( requester && IsClientInGame(requester) )
	{
		g_hRequestTimer[requester] = null;

		if( g_iPendingTarget[requester] != 0 )
		{
			CPrintToChat(requester, "%s%t", CHAT_TAG, "Request Timeout");

			if( target && IsClientInGame(target) )
				CPrintToChat(target, "%s%t", CHAT_TAG, "Request From Timeout", requester);

			CancelPendingRequest(requester);
		}
	}

	return Plugin_Stop;
}



// ====================================================================================================
//					TELEPORT
// ====================================================================================================
void ExecuteTeleport(int client, int target)
{
	CancelPendingRequest(client);

	if( !IsClientInGame(client) || !IsPlayerAlive(client) )
		return;

	if( !IsClientInGame(target) || !IsPlayerAlive(target) )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Target No Longer Valid");
		return;
	}

	bool bWasIncapped = false;
	bool bWasLedge = false;
	int iHealth = 0;
	int iReviveCount = 0;
	bool bWasThirdStrike = false;

	if( GetClientTeam(client) == L4D_TEAM_SURVIVOR )
	{
		bWasLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 1;
		bWasIncapped = GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1;

		if( bWasIncapped || bWasLedge )
		{
			iHealth = GetClientHealth(client);
			iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
			bWasThirdStrike = GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike") == 1;

			L4D_ReviveSurvivor(client);

			if( g_bDebugMode )
				PrintToServer("[Rescue] %N was %s - health: %d, revive count: %d, third strike: %s", 
					client, bWasLedge ? "ledge hanging" : "incapped", iHealth, iReviveCount, bWasThirdStrike ? "yes" : "no");
		}
	}

	float targetPos[3], safePos[3];
	GetClientAbsOrigin(target, targetPos);

	if( !FindSafePosition(targetPos, safePos) )
		safePos = targetPos;

	TeleportEntity(client, safePos, NULL_VECTOR, NULL_VECTOR);

	if( GetClientTeam(client) == L4D_TEAM_SURVIVOR && (bWasIncapped || bWasLedge) )
	{
		DataPack pack;
		CreateDataTimer(0.1, Timer_RestoreIncapState, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(iHealth);
		pack.WriteCell(iReviveCount);
		pack.WriteCell(bWasThirdStrike ? 1 : 0);
	}

	CreateTimer(0.2, Timer_CheckStuck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	if( g_fCvarGodMode > 0.0 )
	{
		g_bGodModeActive[client] = true;
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 150);
		CreateTimer(g_fCvarGodMode, Timer_RemoveGodMode, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	g_fLastTeleportTime[client] = GetEngineTime();
	g_iUsesThisRound[client]++;

	CPrintToChat(client, "%s%t", CHAT_TAG, "Teleported To", target);

	if( g_bDebugMode )
		PrintToServer("[Rescue] %N teleported to %N (uses: %d/%d)", client, target, g_iUsesThisRound[client], g_iCvarMaxUses);
}

bool FindSafePosition(float targetPos[3], float result[3])
{
	static const float offsets[8][2] =
	{
		{50.0, 0.0}, {-50.0, 0.0}, {0.0, 50.0}, {0.0, -50.0},
		{35.0, 35.0}, {-35.0, 35.0}, {35.0, -35.0}, {-35.0, -35.0}
	};

	float testPos[3], hitPos[3];

	for( int i = 0; i < sizeof(offsets); i++ )
	{
		testPos[0] = targetPos[0] + offsets[i][0];
		testPos[1] = targetPos[1] + offsets[i][1];
		testPos[2] = targetPos[2] + 10.0;

		Handle trace = TR_TraceRayFilterEx(testPos, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_NoPlayers);
		if( TR_DidHit(trace) )
		{
			TR_GetEndPosition(hitPos, trace);
			hitPos[2] += 5.0;

			if( !IsPositionStuck(hitPos) )
			{
				result = hitPos;
				delete trace;
				return true;
			}
		}
		delete trace;
	}

	return false;
}

bool IsPositionStuck(float position[3])
{
	Handle trace = TR_TraceHullFilterEx(position, position, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID, TraceFilter_NoPlayers);
	bool stuck = TR_DidHit(trace);
	delete trace;
	return stuck;
}

bool TraceFilter_NoPlayers(int entity, int contentsMask)
{
	return entity > MaxClients;
}



// ====================================================================================================
//					TIMERS
// ====================================================================================================
Action Timer_RestoreIncapState(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int iHealth = pack.ReadCell();
	int iReviveCount = pack.ReadCell();
	bool bWasThirdStrike = pack.ReadCell() == 1;

	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return Plugin_Stop;

	if( GetClientTeam(client) != L4D_TEAM_SURVIVOR )
		return Plugin_Stop;

	L4D_SetPlayerIncapped(client, true);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);

	ConVar hMaxIncap = FindConVar("survivor_max_incapacitated_count");
	int iMaxIncap = hMaxIncap != null ? hMaxIncap.IntValue : 2;

	if( bWasThirdStrike || iReviveCount >= iMaxIncap )
	{
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}

	SetEntityHealth(client, iHealth);

	if( g_bDebugMode )
		PrintToServer("[Rescue] Restored %N incap state - health: %d, revive count: %d/%d, third strike: %s", 
			client, iHealth, iReviveCount, iMaxIncap, (bWasThirdStrike || iReviveCount >= iMaxIncap) ? "yes" : "no");

	return Plugin_Stop;
}

Action Timer_CheckStuck(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) && IsPlayerAlive(client) )
		L4D_WarpToValidPositionIfStuck(client);

	return Plugin_Continue;
}

Action Timer_RemoveGodMode(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		g_bGodModeActive[client] = false;
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					HELPERS
// ====================================================================================================
int FindTargetByName(int client, const char[] name, int team)
{
	int target = 0, matchCount = 0;
	char playerName[MAX_NAME_LENGTH];

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i == client || !IsClientInGame(i) || GetClientTeam(i) != team || !IsPlayerAlive(i) )
			continue;

		GetClientName(i, playerName, sizeof(playerName));
		if( StrContains(playerName, name, false) != -1 )
		{
			target = i;
			matchCount++;
		}
	}

	if( matchCount > 1 )
	{
		CPrintToChat(client, "%s%t", CHAT_TAG, "Multiple Players Found");
		return 0;
	}

	return matchCount == 1 ? target : 0;
}

bool IsValidTeleportTarget(int target, int team)
{
	if( !IsClientInGame(target) || GetClientTeam(target) != team || !IsPlayerAlive(target) )
		return false;

	if( team == L4D_TEAM_SURVIVOR && GetEntProp(target, Prop_Send, "m_isIncapacitated") )
		return false;

	if( team == L4D_TEAM_INFECTED && GetEntProp(target, Prop_Send, "m_isGhost") )
		return false;

	return true;
}

int GetPinningSurvivor(int client)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == L4D_TEAM_INFECTED && IsPlayerAlive(i) )
		{
			if( L4D_GetPinnedSurvivor(i) == client )
				return i;
		}
	}
	return 0;
}

void CancelPendingRequest(int requester)
{
	int target = g_iPendingTarget[requester];
	if( target > 0 && target <= MaxClients )
		g_iPendingRequest[target] = 0;

	g_iPendingTarget[requester] = 0;
	delete g_hRequestTimer[requester];
}

void ResetClientData(int client)
{
	g_fLastTeleportTime[client] = 0.0;
	g_iUsesThisRound[client] = 0;
	g_bGodModeActive[client] = false;
	g_iPendingRequest[client] = 0;
	g_iPendingTarget[client] = 0;
	delete g_hRequestTimer[client];
}

void ResetAllClients()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		CancelPendingRequest(i);
		ResetClientData(i);
	}
}
