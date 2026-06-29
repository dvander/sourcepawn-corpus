#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define PLUGIN_VERSION		"0.8a"

#include <sourcemod>
#include <sdkhooks>
#include <l4d2_direct>

public Plugin:myinfo = {
	name = "Ready Up Lite",
	author = "Sky",
	description = "A lite ready up plugin",
	version = PLUGIN_VERSION,
	url = "vousdusky@gmail.com"
}

new Handle:g_FreezeEnabled;
new Handle:g_FreezeTime;
new Handle:g_SecondHalfReady;
new Handle:g_CompetitionMode;
new Handle:g_ConnectionTimeout;
new bool:bAllClientsLoaded;
new bool:bReadyUp;
new bool:bReady[MAXPLAYERS + 1];
new bool:bFirstClient;
new bool:bRoundEnd;
new bool:bTeamsFlipped;
new bool:bIntermission;
new bool:bFirstRound;
new bool:bInStartArea[MAXPLAYERS + 1];
new Float:timeCounter;
new Float:forceCounter;
new String:white[64];
new String:green[64];
new String:grenade[MAXPLAYERS + 1][64];

public OnPluginStart()
{
	CreateConVar("ruplite_version", PLUGIN_VERSION, "current installed version of this plugin.");

	g_CompetitionMode		= CreateConVar("ruplite_competition_mode","0","If set to 0, competition mode will not be turned on. If on, second half ready is forced.");
	g_SecondHalfReady		= CreateConVar("ruplite_ready_halftime","1","If set to 0, there will not be a ready up period before the second round begins.");

	g_ConnectionTimeout		= CreateConVar("ruplite_connect_timeout","60.0","If 0.0, all players must have loaded for ready up to start, otherwise forces ready up after this many seconds, even if all players are not fully loaded.");

	g_FreezeEnabled			= CreateConVar("ruplite_freeze_enabled","1","If set to 0, players are only frozen until all players load in.");
	g_FreezeTime			= CreateConVar("ruplite_freeze_time","60.0","If 0.0, all players MUST ready up to start, otherwise starts when all players have loaded, after this many seconds.");

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);

	// So colours not needed
	Format(white, sizeof(white), "\x01");
	Format(green, sizeof(green), "\x05");

	AutoExecConfig(true, "ruplite");

	LoadTranslations("common.phrases");
	LoadTranslations("ruplite.phrases");
}

public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (!bRoundEnd)
	{
		if (GetConVarInt(g_SecondHalfReady) == 1 || GetConVarInt(g_CompetitionMode) == 1) bIntermission = true;
		bRoundEnd = true;
		bTeamsFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped", 4, 0);
		CreateTimer(1.0, TimerCheckNewRound, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:Event_PlayerShoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new giver		= GetClientOfUserId(GetEventInt(event, "attacker"));
	new receiver	= GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(g_CompetitionMode) == 1 && 
		IsClientActual(giver) && IsClientActual(receiver) && 
		!IsFakeClient(receiver) && IsSameTeam(giver, receiver) && 
		GetPlayerWeaponSlot(giver, 2) != -1 && GetPlayerWeaponSlot(receiver, 2) == -1)
	{
		decl String:weapon[64];
		new weaponIndex = GetPlayerWeaponSlot(giver, 2);
		GetEdictClassname(weaponIndex, weapon, sizeof(weapon));
		RemovePlayerItem(giver, weaponIndex);
		ExecCheatCommand(receiver, "give", weapon);
	}
}

public Action:Event_PlayerLeftStartArea(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new survivor	= GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientActual(survivor)) bInStartArea[survivor] = false;
}

public Action:TimerCheckNewRound(Handle:timer)
{
	new bool:bTeamsFlipCheck = !!GameRules_GetProp("m_bAreTeamsFlipped", 4, 0);
	if (bTeamsFlipped == bTeamsFlipCheck) return Plugin_Continue;
	// Once teams have flipped...
	ReadyUpStart();
	return Plugin_Stop;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsClientActual(attacker) && IsClientActual(victim) && IsSameTeam(attacker, victim))
	{
		if (bReadyUp || bInStartArea[victim])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, "ruplite");
}

public bool:IsSameTeam(first, second)
{
	if (GetClientTeam(first) == GetClientTeam(second)) return true;
	return false;
}

public bool:IsClientActual(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return false;
	return true;
}

public OnMapStart()
{
	bFirstClient = false;
}

public ReadyUpStart()
{
	bAllClientsLoaded = true;
	bReadyUp = true;
	CreateTimer(1.0, TimerFreezePlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if (bIntermission || bFirstRound)
	{
		ForceSpectatorReady();
		// there's only a timer on the ready up period if it's set.
		if (GetConVarInt(g_FreezeEnabled) == 1 && GetConVarFloat(g_FreezeTime) > 0.0)
		{
			timeCounter = GetConVarFloat(g_FreezeTime);
			CreateTimer(1.0, TimerStartMatch, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		// Announce the game is in ready up mode.
		PrintToChatAll("%t", "Match Ready Up", white, green);
	}
	else
	{
		ReadyUpEnd();
	}
}

public bool:IsSpectators()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SPECTATOR) continue;
		return true;
	}
	return false;
}

public ForceSpectatorReady()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SPECTATOR) continue;
		bReady[i] = true;
	}
}

public ReadyUpEnd()
{
	PrintToChatAll("%t", "Match Is Live", white, green);
	if (GetConVarInt(g_SecondHalfReady) == 1 || GetConVarInt(g_CompetitionMode) == 1)
	{
		PrintToChatAll("%t", "Intermission Ready Up");
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientActual(i) || GetClientTeam(i) != TEAM_SURVIVORS) continue;
		bInStartArea[i] = true;
	}
	bFirstRound = false;
	bRoundEnd = false;
	bReadyUp = false;
	bIntermission = false;
	if (GetConVarInt(g_CompetitionMode) == 1 ) SetCompetitionMode();
}

public SetCompetitionMode()
{
	new EntCount = GetEntityCount();
	new String:EdictName[256];
	for (new i = 0; i <= EntCount; i++)
	{
		if (!IsValidEntity(i) || !IsValidEdict(i)) continue;
		GetEdictClassname(i, EdictName, sizeof(EdictName));
		if (StrContains(EdictName, "defib", false) != -1 || 
			StrContains(EdictName, "first_aid", false) != -1 || 
			StrContains(EdictName, "launcher", false) != -1)
		{
			if (!AcceptEntityInput(i, "Kill")) RemoveEdict(i);
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVORS) continue;
		ExecCheatCommand(i, "give", "pain_pills");
	}
	GiveSurvivorGrenades(2);
}

public HumanSurvivors()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVORS) continue;
		count++;
	}
	return count;
}

public GiveSurvivorGrenades(amount)
{
	new bool:bGrenadesFound = false;

	// Make sure same two people don't always get the grenades, but always two within succession of each other.
	new random = GetRandomInt(1, 3);
	if (HumanSurvivors() < 3) random = 1;
	new count = 1;
	new given = 0;
	for (new i = 1; i <= MaxClients && !bGrenadesFound; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVORS || StrEqual(grenade[i], "none")) continue;
		bGrenadesFound = true;
	}
	for (new i = 1; i <= MaxClients && given < amount; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVORS) continue;
		if (count != random) count++;
		else
		{
			if (!bGrenadesFound)
			{
				new type = GetRandomInt(1, 3);
				if (type == 1) grenade[i] = "molotov";
				else if (type == 2) grenade[i] = "pipe_bomb";
				else grenade[i] = "vomitjar";
				ExecCheatCommand(i, "give", grenade[i]);
			}
			else
			{
				for (new ii = 1; ii <= MaxClients; ii++)
				{
					if (!IsClientConnected(ii) || !IsClientInGame(ii) || GetClientTeam(ii) != TEAM_INFECTED || StrEqual(grenade[ii], "none")) continue;
					grenade[i] = grenade[ii];
					grenade[ii] = "none";
					ExecCheatCommand(i, "give", grenade[i]);
					break;
				}
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (IsHuman(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		bReady[client] = false;
		grenade[client] = "none";
		if (!bFirstClient)
		{
			bFirstClient = true;
			bReadyUp = true;
			bAllClientsLoaded = false;
			CreateTimer(1.0, TimerFreezePlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			if (GetConVarFloat(g_ConnectionTimeout) > 0.0)
			{
				forceCounter = 0.0;
				CreateTimer(1.0, TimerForceReadyUpStart, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if (!bClientsLoading() && !bAllClientsLoaded)
		{
			bIntermission = false;	// intermission does not occur in this state.
			bFirstRound = true;		// First round if bAllClientsLoaded is false.
			ReadyUpStart();
		}
	}
}

public Action:TimerForceReadyUpStart(Handle:timer)
{
	if (bAllClientsLoaded) return Plugin_Stop;
	if (forceCounter > 0.0)
	{
		forceCounter--;
		return Plugin_Continue;
	}
	else
	{
		bAllClientsLoaded = true;
		bIntermission = false;
		bFirstRound = true;			// First round if bAllClientsLoaded is false.
		ReadyUpStart();
	}
	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:TimerFreezePlayers(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) SendPanelToClient(ReadyUpMenu(i), i, ReadyUpMenu_Init, 1);
		if (!bReadyUp) SetEntityMoveType(i, MOVETYPE_WALK);
		else SetEntityMoveType(i, MOVETYPE_NONE);
	}
	if (!bReadyUp)
	{
		// Ready up period has ended, kill the timer.
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:TimerStartMatch(Handle:timer)
{
	if (timeCounter >= 0.0)
	{
		timeCounter--;
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
			{
				SendPanelToClient(ReadyUpMenu(client), client, ReadyUpMenu_Init, 1);
			}
		}
	}
	if (timeCounter < 0.0 || bPlayersReady())
	{
		ReadyUpEnd();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public bool:bClientsLoading()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i)) return true;
	}
	return false;
}

public bool:bPlayersReady()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !bReady[i]) return false;
	}
	return true;
}

public Handle:ReadyUpMenu (client)
{
	new Handle:menu = CreatePanel();
	new String:text[128];
	SetPanelTitle(menu, "Ready Up Lite");
	Format(text, sizeof(text), "ver. %s", PLUGIN_VERSION);
	DrawPanelText(menu, text);
	if (GetConVarInt(g_CompetitionMode) == 1) Format(text, sizeof(text), "%T", "Competition On", client);
	else Format(text, sizeof(text), "%T", "Competition Off", client);
	DrawPanelText(menu, text);

	if (GetConVarInt(g_FreezeEnabled) == 1)
	{
		if (bClientsLoading())
		{
			Format(text, sizeof(text), "%T", "Pregame", client);
			DrawPanelText(menu, text);
			if (GetConVarInt(g_ConnectionTimeout) == 1)
			{
				Format(text, sizeof(text), "%T", "Connection Timeout", client, RoundToFloor(forceCounter));
				DrawPanelText(menu, text);
			}
		}
		else if (timeCounter > 0.0)
		{
			Format(text, sizeof(text), "%T", "Time Remaining", client, RoundToFloor(timeCounter));
			DrawPanelText(menu, text);
		}
	}
	else
	{
		Format(text, sizeof(text), "%T", "Match Notice", client);
		DrawPanelText(menu, text);
	}
	if (bClientsLoading())
	{
		Format(text, sizeof(text), "%T", "Connection", client);
		DrawPanelItem(menu, text);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(text, sizeof(text), "%N", i);
				DrawPanelText(menu, text);
			}
		}
	}
	if (GetConVarInt(g_FreezeEnabled) == 1)
	{
		Format(text, sizeof(text), "%T", "Ready", client);
		DrawPanelItem(menu, text);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && bReady[i] && GetClientTeam(i) != TEAM_SPECTATOR)
			{
				Format(text, sizeof(text), "%N", i);
				DrawPanelText(menu, text);
			}
		}
		Format(text, sizeof(text), "%T", "Not Ready", client);
		DrawPanelItem(menu, text);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && !bReady[i] && GetClientTeam(i) != TEAM_SPECTATOR)
			{
				Format(text, sizeof(text), "%N", i);
				DrawPanelText(menu, text);
			}
		}
		if (bReady[client])
		{
			Format(text, sizeof(text), "%T", "Change To Not Ready", client);
			DrawPanelItem(menu, text);
		}
		else
		{
			Format(text, sizeof(text), "%T", "Change To Ready", client);
			DrawPanelItem(menu, text);
		}
		if (IsSpectators())
		{
			Format(text, sizeof(text), "%T", "Spectators", client);
			DrawPanelItem(menu, text);
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR)
				{
					Format(text, sizeof(text), "%N", i);
					DrawPanelText(menu, text);
				}
			}
		}
	}

	return menu;
}

public ReadyUpMenu_Init (Handle:topmenu, MenuAction:action, client, param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
			{
				SendPanelToClient(ReadyUpMenu(client), client, ReadyUpMenu_Init, 1);
			}
			case 2:
			{
				SendPanelToClient(ReadyUpMenu(client), client, ReadyUpMenu_Init, 1);
			}
			case 3:
			{
				if (!bAllClientsLoaded) SendPanelToClient(ReadyUpMenu(client), client, ReadyUpMenu_Init, 1);
				else
				{
					if (!bReadyUp || GetClientTeam(client) == TEAM_SPECTATOR) return;
					if (bReady[client]) bReady[client] = false;
					else bReady[client] = true;
				}
			}
			case 4:
			{
				if (!bReadyUp || GetClientTeam(client) == TEAM_SPECTATOR) return;
				if (bReady[client]) bReady[client] = false;
				else bReady[client] = true;
			}
			default:
			{
				SendPanelToClient(ReadyUpMenu(client), client, ReadyUpMenu_Init, 1);
			}
		}
	}
}

stock bool:IsHuman(client)
{
	if (!IsClientIndexOutOfRange(client) && IsClientInGame(client) && !IsFakeClient(client)) return true;
	else return false;
}

stock bool:IsClientIndexOutOfRange(client)
{
	if (client <= 0 || client > MaxClients) return true;
	else return false;
}

ExecCheatCommand(client = 0,const String:command[],const String:parameters[] = "")
{
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command,iFlags & ~FCVAR_CHEAT);

	if(IsClientIndexOutOfRange(client) || !IsClientInGame(client))
	{
		ServerCommand("%s %s",command,parameters);
	}
	else
	{
		FakeClientCommand(client,"%s %s",command,parameters);
	}

	SetCommandFlags(command,iFlags);
	SetCommandFlags(command,iFlags|FCVAR_CHEAT);
}