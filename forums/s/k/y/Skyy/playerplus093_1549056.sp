#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3); }
#define PLAYERPLUS_VERSION			"0.93"

#define CVAR_SHOW FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <adminmenu>
#include "left4downtown.inc"
#include "left4loading.inc"

new Handle:g_SpawnNewClientLiveRound;
new Handle:g_SurvivorCountEqualsInfected;
new Handle:g_SurvivorMaximumPlayers;
new Handle:g_InfectedMaximumPlayers;
new Handle:g_SurvivorBotsEnabled;
new Handle:g_TeleportOnSpawn;
new Handle:g_SurvivorBotRemoval;
new Handle:g_TakeControlBot;
new bool:bRoundReset;

new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;
new Handle:hRoundRespawn = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Playerplus",
	author = "Sky",
	description = "A Management Plugin",
	version = PLAYERPLUS_VERSION,
	url = "mikel.toth@gmail.com"
}

public OnPluginStart()
{
	CreateConVar("playerplus_version", PLAYERPLUS_VERSION, "version of playerplus", CVAR_SHOW);

	g_SpawnNewClientLiveRound		= CreateConVar("playerplus_live_round_spawn","0","If disabled, players will spawn dead if the ready up period has ended for the current round.", CVAR_SHOW);
	g_SurvivorCountEqualsInfected	= CreateConVar("playerplus_equal_team_count","1","If enabled, survivor total count = total humans on infected team IF less humans on survivor.", CVAR_SHOW);
	g_SurvivorMaximumPlayers		= CreateConVar("playerplus_survivor_limit","10","The maximum amount of survivor players, including bots.", CVAR_SHOW);
	g_InfectedMaximumPlayers		= CreateConVar("playerplus_infected_limit","10","The maximum amount of infected players.", CVAR_SHOW);
	g_SurvivorBotsEnabled			= CreateConVar("playerplus_survivor_bots_allowed","1","If disabled, there will be no survivor bots.", CVAR_SHOW);
	g_TeleportOnSpawn				= CreateConVar("playerplus_teleport_on_spawn","1","If enabled, when a player is spawned, they will be teleported to a random survivor.", CVAR_SHOW);
	g_SurvivorBotRemoval			= CreateConVar("playerplus_survivor_allowed_nobots","4","Survivor bots are allowed until this amount of human survivors is reached. 0 disables.", CVAR_SHOW);
	g_TakeControlBot				= CreateConVar("playerplus_take_control_bot","1","If a survivor player dies and a bot is available, whether to allow them to take control of that bot.", CVAR_SHOW);

	SetConVarInt(FindConVar("survivor_limit"), GetConVarInt(g_SurvivorMaximumPlayers));
	SetConVarInt(FindConVar("z_max_player_zombies"), GetConVarInt(g_InfectedMaximumPlayers));

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_end", Event_RoundEnd);

	RegConsoleCmd("teams", Open_TeamsMenu);
	RegConsoleCmd("jointeam", BlockTeam);
	RegConsoleCmd("infected", BlockTeam);
	RegConsoleCmd("survivor", BlockTeam);

	gConf = LoadGameConfigFile("left4downtown.l4d2");

	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/left4downtown.l4d2.txt");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_GameRules);
	
	gConf = LoadGameConfigFile("l4drespawn");
	if (gConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
	}

	AutoExecConfig(true, "playerplus093");
}

public OnConfigsExecuted() { AutoExecConfig(true, "playerplus092"); }

//FORCE_INT_CHANGE(FSL, FindConVar("survivor_limit"), GetConVarInt(g_SurvivorMaximumPlayers));
//FORCE_INT_CHANGE(FIL, FindConVar("z_max_player_zombies"), GetConVarInt(g_InfectedMaximumPlayers));

public OnAllClientsLoaded() { bRoundReset = true; }
public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast) { bRoundReset = true; }
public OnReadyUpEnd() { bRoundReset = false; }


public Action:BlockTeam(client, args)
{
	PrintToChat(client, "\x01Use !teams instead.");
	return Plugin_Handled;
}

public VerifyPlayerCount()
{
	new survCount = 0;
	new infCount = 0;
	new survBotCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsFakeClient(i) && GetClientTeam(i) == 2) survCount++;
		if (IsFakeClient(i) && GetClientTeam(i) == 2) survBotCount++;
		if (!IsFakeClient(i) && GetClientTeam(i) == 3) infCount++;
	}
	if (survCount >= GetConVarInt(g_SurvivorBotRemoval) && GetConVarInt(g_SurvivorBotRemoval) >= 1 && 
		GetConVarInt(g_SurvivorCountEqualsInfected) == 0)
	{
		// Remember this can only be called if the Survivor == Infected is DISABLED.
		if (survBotCount > 0)
		{
			// 1. Required number of human survivors are in-game, that the server doesn't want bot survivors.
			// 2. Bot removal count is greater than 0 (0 disables).
			// 3. There is at least 1 bot survivor in the server.

			// We kick the bots and then return so bots don't get remade.
			FindAndKickSurvivorBots(survBotCount);
		}

		// Since we don't want the last statement at the bottom to run after these bots are kicked,
		// as long as the survCount >= Bot Removal setting, just return.
		return;
	}
	if (survBotCount > 0 && GetConVarInt(g_SurvivorBotsEnabled) == 0)
	{
		FindAndKickSurvivorBots(survBotCount);
	}
	else if (GetConVarInt(g_SurvivorCountEqualsInfected) == 1 && (survCount + survBotCount) > infCount)
	{
		FindAndKickSurvivorBots((survCount + survBotCount) - infCount);
	}
	else if (GetConVarInt(g_SurvivorCountEqualsInfected) == 1 && (survCount + survBotCount) < infCount)
	{
		_PP_CreateBots(infCount - (survCount + survBotCount));
	}
	else if (GetConVarInt(g_SurvivorCountEqualsInfected) == 0 && 
			 (survCount + survBotCount) > GetConVarInt(g_SurvivorMaximumPlayers))
	{
		FindAndKickSurvivorBots((survCount + survBotCount) - GetConVarInt(g_SurvivorMaximumPlayers));
	}
	else if ((survCount + survBotCount) < GetConVarInt(g_SurvivorMaximumPlayers) && 
			 GetConVarInt(g_SurvivorBotsEnabled) == 1)
	{
		_PP_CreateBots(GetConVarInt(g_SurvivorMaximumPlayers) - (survCount + survBotCount));
	}
}

stock FindAndKickSurvivorBots(count)
{
	// Until I rewrite the code above, we need to check survivor bots, so that the server
	// doesn't crash if count > 0 and there are no survivor bots remaining
	// (crash = never-ending loop)

	new survBot = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2) continue;
		survBot++;
	}
	for (new i = 1; i <= MaxClients && count > 0 && survBot > 0; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2) continue;
		KickClient(i, "Removing Bots to balance teams.");
		count--;
		survBot--;
	}
}

_PP_CreateBots(count)
{
	for (new i = 1; i < count; i++)
	{
		CreateTimer(0.5, Timer_CreateBots, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_CreateBots(Handle:timer)
{
	CreateSurvivor(-1);
	return Plugin_Stop;
}

stock bool:SurvivorBotsAvailable()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			// Survivor Bot Found.
			return true;
		}
	}
	return false;
}

public CreateSurvivor(client)
{
	new bot = CreateFakeClient("SurvivorBot");
	if (bot == 0) return;
	ChangeClientTeam(bot, 2);
	DispatchKeyValue(bot, "classname", "SurvivorBot");

	if (IsClientConnected(bot) && IsFakeClient(bot)) CreateTimer(0.5, Timer_KickFakeClient, bot, TIMER_FLAG_NO_MAPCHANGE);

	if (client != -1) PlaceOnSurvivorTeam(client);
}

public Action:Timer_KickFakeClient(Handle:timer, any:fakeclient)
{
	if (IsClientConnected(fakeclient) && IsFakeClient(fakeclient))
	{
		KickClient(fakeclient, "Created and removed bot.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public PlaceOnSurvivorTeam(client)
{
	if (!IsClientConnected(client)) return;
	if (IsClientInGame(client) && GetClientTeam(client) == 2) return;
	else if (IsClientInGame(client)) CreateTimer(0.5, Timer_PlaceOnSurvivorTeamDelay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_PlaceOnSurvivorTeamDelay(Handle:timer, any:client)
{
	new bot = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2) continue;
		bot = i;
		break;
	}
	if (bot == 0) CreateSurvivor(client);
	else
	{
		SDKCall(fSHS, bot, client);
		SDKCall(fTOB, client, Listen_Yes);

		if ((!IsPlayerAlive(client) && bRoundReset) || 
			(!IsPlayerAlive(client) && GetConVarInt(g_SpawnNewClientLiveRound) == 1))
		{
			RespawnClient(client);
		}
	}
}

public RespawnClient(client)
{
	SDKCall(hRoundRespawn, client);
	if (GetConVarInt(g_TeleportOnSpawn) == 1)
	{
		new surv = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || i == client) continue;
			surv = i;
			break;
		}
		if (surv != 0)
		{
			new Float:pos[3];
			GetClientAbsOrigin(surv, pos);
			TeleportEntity(client, Float:pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:Timer_PostActionDelay(Handle:timer, any:client)
{
	if (!IsHuman(client)) return Plugin_Stop;
	if (GetClientTeam(client) == 2)
	{
		if (!SurvivorBotsAvailable()) CreateSurvivor(client);
		else PlaceOnSurvivorTeam(client);
	}

	return Plugin_Stop;
}

public Action:Timer_VerifyPlayerCountDelay(Handle:timer)
{
	VerifyPlayerCount();
	return Plugin_Stop;
}

public TeamSelectSurvivorTeam(client)
{
	if (!SurvivorBotsAvailable()) CreateSurvivor(client);
	else PlaceOnSurvivorTeam(client);
}

public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientIndexOutOfRange(client) || !IsClientInGame(client) || IsFakeClient(client)) return;
	if (GetClientTeam(client) == 2 && GetConVarInt(g_TakeControlBot) == 1 && AnySurvivorBotsAlive()) SendPanelToClient(Menu_TakeControl(client), client, Menu_TakeControl_Init, MENU_TIME_FOREVER);
}

stock bool:AnySurvivorBotsAlive()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
		return true;
	}
	return false;
}

stock bool:IsClientIndexOutOfRange(client)
{
	if (client <= 0 || client > MaxClients) return true;
	else return false;
}

public Handle:Menu_TakeControl (client)
{
	new Handle:menu = CreatePanel();

	new String:text[512];
	Format(text, sizeof(text), "Would you like to take control of a bot?");
	DrawPanelText(menu, text);
	DrawPanelItem(menu, "Yes");
	DrawPanelItem(menu, "No");

	return menu;
}

public Menu_TakeControl_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				FindAndReplaceBot(client);
			}
			case 2:
			{
				return;
			}
		}
	}
}

public FindAndReplaceBot(client)
{
	new bot = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
		bot = i;
		break;
	}
	if (bot == 0) PrintToChat(client, "[PlayerPlus] If there was an available bot, it isn't anymore.");
	else
	{
		SDKCall(fSHS, bot, client);
		SDKCall(fTOB, client, Listen_Yes);
		PrintToChatAll("[PlayerPlus] %N Took control of bot %N", client, bot);
	}
}

public Action:Event_PlayerTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(1.0, Timer_VerifyPlayerCountDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Open_TeamsMenu(client, args)
{
	SendPanelToClient(Menu_TeamsInitial(client), client, Menu_TeamsChooseInit, MENU_TIME_FOREVER);
}

public Handle:Menu_TeamsInitial (client)
{
	new Handle:menu = CreatePanel();
	
	SetPanelTitle(menu, "Team Menu");
	new String:text[128];
	Format(text, sizeof(text), "Spectator Team");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "Survivor Team");
	DrawPanelItem(menu, text);
	Format(text, sizeof(text), "Infected Team");
	DrawPanelItem(menu, text);
	return menu;
}

public Menu_TeamsChooseInit (Handle:topmenu, MenuAction:action, client, param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				if (GetClientTeam(client) == 1) return;
				PrintToChatAll("\x04%N has joined the \x05Spectator Team", client);
				ChangeClientTeam(client, 1);
			}
			case 2:
			{
				if (GetClientTeam(client) == 2) return;
				PrintToChatAll("\x04%N has joined the \x05Survivor Team", client);
				TeamSelectSurvivorTeam(client);
			}
			case 3:
			{
				if (GetClientTeam(client) == 3) return;
				PrintToChatAll("\x04%N has joined the \x05Infected Team", client);
				ChangeClientTeam(client, 3);
			}
			default:
			{
				SendPanelToClient(Menu_TeamsInitial(client), client, Menu_TeamsChooseInit, MENU_TIME_FOREVER);
			}
		}
	}
}

stock bool:IsHuman(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client) || IsFakeClient(client)) return false;
	return true;
}

public OnClientPostAdminCheck(client)
{
	if (IsClientConnected(client) && client != 0 && !IsFakeClient(client)) CreateTimer(0.5, Timer_PostActionDelay, client, TIMER_FLAG_NO_MAPCHANGE);
}