#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

new Handle:cvarEnable;

new Handle:redQueue = INVALID_HANDLE;
new Handle:blueQueue = INVALID_HANDLE;

new bool:soloMode[MAXPLAYERS+1] = {false, ...};
new bool:canSoloCmd[MAXPLAYERS+1] = {true, ...};
new bool:MapChanged;
new bool:soloRoundStart;

new deaths[MAXPLAYERS+1] = {0, ...};

public Plugin:myinfo = {
	name = "Arena Solo Mode (Dodgeball/Nanobot Addon)",
	author = "Nanochip",
	description = "Take on the other team solely (Intended for dodgeball).",
	version = PLUGIN_VERSION,
	url = "http://thecubeserver.org/"
};

public OnPluginStart()
{
	CreateConVar("sm_arenasolomode_version", PLUGIN_VERSION, "Arena Solo Mode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_arenasolomode_enable", "1", "Enable the plugin? 1 = Yes, 0 = No.", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_solo", Cmd_Solo, "Enable/disable solo mode.");
	
	redQueue = CreateArray();
	blueQueue = CreateArray();
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("arena_win_panel", Event_RoundEnd);
}

public Action:Cmd_Solo(client, args)
{
	//0 = Unassigned, 1 = Spec, 2 = Red, 3 = Blue.
	if (!IsClientInGame(client)) return Plugin_Handled;
	new team = GetClientTeam(client);
	if (team == 1 || team == 0)
	{
		ReplyToCommand(client, "[SOLO] You must join RED or BLU before you can use this command.");
		return Plugin_Handled;
	}
	if (!soloMode[client])
	{
		if (!canSoloCmd[client] || IsClientObserver(client))
		{
			ReplyToCommand(client, "[SOLO] Sorry, you may not use this command right now.");
			return Plugin_Handled;
		}
		
		// Check if all of the other players on the team have solo mode activated.
		if (team == 2 && GetTeamClientCount(2)-1 == GetArraySize(redQueue))
		{
			ReplyToCommand(client, "[SOLO] The rest of your team already has solo mode activated, therefore you may not activate it.");
			return Plugin_Handled;
		}
		if (team == 3 && GetTeamClientCount(3)-1 == GetArraySize(blueQueue))
		{
			ReplyToCommand(client, "[SOLO] The rest of your team already has solo mode activated, therefore you may not activate it.");
			return Plugin_Handled;
		}
		
		// Slay the client if they are alive.
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
			ReplyToCommand(client, "[SOLO] You have been slain and will be respawned when your team has no more players alive.");
			ReplyToCommand(client, "[SOLO] To disable this, type !solo again (you won't be respawned, however).");
		}
		
		// Add the client's USERID to the team queue
		if (team == 2) PushArrayCell(redQueue, GetClientUserId(client));
		if (team == 3) PushArrayCell(blueQueue, GetClientUserId(client));
		
		// Activated Solo Mode
		soloMode[client] = true;
		
		PrintToChatAll("[SOLO] Activated Solo Mode on %N.", client);
	}
	else
	{
		// Remove the client from the queue
		if (team == 2)
		{
			new index = FindValueInArray(redQueue, GetClientUserId(client));
			if (index != -1) RemoveFromArray(redQueue, index);
		}
		if (team == 3)
		{
			new index = FindValueInArray(blueQueue, GetClientUserId(client));
			if (index != -1) RemoveFromArray(blueQueue, index);
		}
		
		// Deactivated Solo Mode
		soloMode[client] = false;
		canSoloCmd[client] = false;
		
		PrintToChatAll("[SOLO] Deactivated Solo Mode on %N.", client);
	}
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (!GetConVarBool(cvarEnable)) return;
	if (IsClientConnected(client) && IsFakeClient(client)) return;
	if (!IsClientInGame(client)) return;
	
	// If the client was in RED or BLU queue, remove them from it.
	new team = GetClientTeam(client);
	if (team == 2)
	{
		new index = FindValueInArray(redQueue, GetClientUserId(client));
		if (index != -1) RemoveFromArray(redQueue, index);
	}
	if (team == 3)
	{
		new index = FindValueInArray(blueQueue, GetClientUserId(client));
		if (index != -1) RemoveFromArray(blueQueue, index);
	}
}

public OnMapEnd()
{
	if (!GetConVarBool(cvarEnable)) return;
	MapChanged = true;
}

public OnMapStart()
{
	if (!GetConVarBool(cvarEnable)) return;
	
	// Clear the queues OnMapStart
	ClearArray(redQueue);
	ClearArray(blueQueue);
	
	CreateTimer(10.0, Timer_MapStart);
	
	soloRoundStart = false;
}

public Action:Timer_MapStart(Handle:timer)
{
	MapChanged = false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnable)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client)) return;
	
	// Return 0 if there is no one in the queues.
	new team = GetClientTeam(client);
	if (team == 2 && GetArraySize(redQueue) == 0) return;
	if (team == 3 && GetArraySize(blueQueue) == 0) return;
	
	// When the last player alive dies on red, commence the red solo queue.
	if (team == 2 && GetRedAlivePlayerCount() == 1)
	{
		// If the last player who died was not in the queue then do:
		if (FindValueInArray(redQueue, GetClientUserId(client)) == -1)
		{
			new firstClient = GetClientOfUserId(GetArrayCell(redQueue, 0));
			// Respawn the first client.
			TF2_RespawnPlayer(firstClient);
			// Alert the client that it is their turn.
			ClientCommand(firstClient, "playgamesound \"%s\"", "ambient\\alarms\\doomsday_lift_alarm.wav");
		}
		// If the last player who died was in the queue, then do:
		else
		{
			new nextIndex = FindValueInArray(redQueue, GetClientUserId(client)) + 1;
			// If there are no more people in the queue, return 0.
			if (nextIndex >= GetArraySize(redQueue)) return;
			else
			{
				new nextClient = GetClientOfUserId(GetArrayCell(redQueue, nextIndex));
				// Respawn the next player in the queue
				TF2_RespawnPlayer(nextClient);
				// Alert the client who was just respawned
				ClientCommand(nextClient, "playgamesound \"%s\"", "ambient\\alarms\\doomsday_lift_alarm.wav");
			}
		}
	}
	// Same function as red queue above ^, except for blue queue.
	if (team == 3 && GetBlueAlivePlayerCount() == 1)
	{
		if (FindValueInArray(blueQueue, GetClientUserId(client)) == -1)
		{
			new firstClient = GetClientOfUserId(GetArrayCell(blueQueue, 0));
			TF2_RespawnPlayer(firstClient);
			ClientCommand(firstClient, "playgamesound \"%s\"", "ambient\\alarms\\doomsday_lift_alarm.wav");
		}
		else
		{
			new nextIndex = FindValueInArray(blueQueue, GetClientUserId(client)) + 1;
			if (nextIndex >= GetArraySize(blueQueue)) return;
			else
			{
				new nextClient = GetClientOfUserId(GetArrayCell(blueQueue, nextIndex));
				TF2_RespawnPlayer(nextClient);
				ClientCommand(nextClient, "playgamesound \"%s\"", "ambient\\alarms\\doomsday_lift_alarm.wav");
			}
		}
	}
	
	if (soloRoundStart)
	{
		if (team == 2)
		{
			for (new i = 0; i < GetArraySize(redQueue); i++)
			{
				new queuedClient = GetClientOfUserId(GetArrayCell(redQueue, i));
				if (deaths[queuedClient] > 0 && deaths[queuedClient] <= 5)
				{
					ClientCommand(queuedClient, "playgamesound \"vo\\announcer_begins_%dsec.mp3\"", deaths[queuedClient]);
					deaths[queuedClient]--;
				}
			}
		}
		
		if (team == 3)
		{
			for (new i = 0; i < GetArraySize(blueQueue); i++)
			{
				new queuedClient = GetClientOfUserId(GetArrayCell(blueQueue, i));
				if (deaths[queuedClient] > 0 && deaths[queuedClient] <= 5)
				{
					ClientCommand(queuedClient, "playgamesound \"vo\\announcer_begins_%dsec.mp3\"", deaths[queuedClient]);
					deaths[queuedClient]--;
				}
			}
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	soloRoundStart = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		canSoloCmd[i] = false;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3, T_RoundStart);
}

public Action:T_RoundStart(Handle:timer)
{
	if (!GetConVarBool(cvarEnable)) return;
	if (GetTeamClientCount(2) <= 1 && GetTeamClientCount(3) <= 1) return;
	// Activate the use of enabling solo when the round starts. This helps to prevent any exploits whenever a player is dead.
	bool hasNames = false;
	char names[1024];
	for (new i = 1; i < MaxClients; i++)
	{
		canSoloCmd[i] = true;
		char name[32];
		if (soloMode[i] && IsClientInGame(i))
		{
			ForcePlayerSuicide(i);
			PrintToChat(i, "[SOLO] You have been slain and will be respawned when your team has no more players alive.");
			PrintToChat(i, "[SOLO] To disable this, type !solo (you won't be respawned, however).");
			GetClientName(i, name, sizeof(name));
			Format(names, sizeof(names), "%s %s,", names, name);
			hasNames = true;
		}
	}
	if (hasNames)
	{
		PrintToChatAll("\x04SOLO Players: \x01%s", names);
	}
	
	soloRoundStart = true;
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (soloMode[i])
		{
			if (GetClientTeam(i) == 2)
			{
				deaths[i] = GetRedAlivePlayerCount() + FindValueInArray(redQueue, GetClientUserId(i))-1;
			}
			if (GetClientTeam(i) == 3)
			{
				deaths[i] = GetBlueAlivePlayerCount() + FindValueInArray(blueQueue, GetClientUserId(i))-1;
			}
		}
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnable)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsFakeClient(client)) return;
	if (soloMode[client])
	{
		new team = GetEventInt(event, "team");
		new oldTeam = GetEventInt(event, "oldteam");
		// If the player switched to spectator, remove them from the queue.
		if (team == 0)
		{
			if (oldTeam == 2)
			{
				new index = FindValueInArray(redQueue, GetClientUserId(client));
				if (index != -1) RemoveFromArray(redQueue, index);
			}
			if (oldTeam == 3)
			{
				new index = FindValueInArray(blueQueue, GetClientUserId(client));
				if (index != -1) RemoveFromArray(blueQueue, index);
			}
		}
		// If the player switched from BLU to RED, transfer their userid from blueQueue to redQueue.
		if (team == 2 && oldTeam == 3)
		{
			new index = FindValueInArray(blueQueue, GetClientUserId(client));
			if (index != -1) RemoveFromArray(blueQueue, index);
			
			PushArrayCell(redQueue, GetClientUserId(client));
		}
		// If the player switched from RED to BLUE, transfer their userid from redQueue to blueQueue.
		if (team == 3 && oldTeam == 2)
		{
			new index = FindValueInArray(redQueue, GetClientUserId(client));
			if (index != -1) RemoveFromArray(redQueue, index);
			
			PushArrayCell(blueQueue, GetClientUserId(client));
		}
	}
}

public OnGameFrame()
{
	if (!GetConVarBool(cvarEnable)) return;
	// If there are is less than or equal to one person on each team, clear the solo queues and disable solo command.
	if (!MapChanged && GetTeamClientCount(2) <= 1 && GetTeamClientCount(3) <= 1)
	{
		if (GetArraySize(redQueue) != 0) ClearArray(redQueue);
		if (GetArraySize(blueQueue) != 0) ClearArray(blueQueue);
		for (new i = 1; i < MaxClients; i++)
		{
			if (soloMode[i]) soloMode[i] = false;
			if (canSoloCmd[i]) canSoloCmd[i] = false;
		}
	}
	if (!MapChanged && GetTeamClientCount(2) > 0 && GetTeamClientCount(2) == GetArraySize(redQueue))
	{
		ClearArray(redQueue);
		PrintToChatAll("[SOLO] Cleared red team's solo queue because somehow everyone had solomode enabled.");
	}
	if (!MapChanged && GetTeamClientCount(3) > 0 && GetTeamClientCount(3) == GetArraySize(blueQueue))
	{
		ClearArray(blueQueue);
		PrintToChatAll("[SOLO] Cleared blue team's solo queue because somehow everyone had solomode enabled.");
	}
}

// Really basic stocks...
stock GetRedAlivePlayerCount()
{
	new alive = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) 
		{
			alive++;
		}
	}
	return alive;
}

stock GetBlueAlivePlayerCount()
{
	new alive = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) 
		{
			alive++;
		}
	}
	return alive;
}