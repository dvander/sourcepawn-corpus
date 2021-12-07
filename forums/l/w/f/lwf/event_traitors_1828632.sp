#include <sourcemod>
#include <tf2_stocks>

#define VERSION "0.0.1"

public Plugin:myinfo = {
	name = "Event traitors",
	author = "lwf",
	description = "Mark disruptors so that players can do with them as they please",
	version = VERSION,
	url = "http://tf2.rocketblast.com/"
}

#define POINTSTHRESHOLD 5
#define ADDKILLPOINTS 3
#define SUBPOINTSREVENGE 2
#define SUBPOINTSMARKEDKILL 1
#define SUBPOINTSNEWBOSS 2

#define SPAWNDELAY 3.0
#define WINDELAY 5.0
#define LOSSDELAY 1.0

new g_points[MAXPLAYERS+1]
new g_glowing[MAXPLAYERS+1]
new g_lasthurtby[MAXPLAYERS+1]
new bool:g_bossActive

public OnPluginStart()
{
	CreateConVar("event_traitors_version", VERSION, "Event traitors version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD)

	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("player_spawn", Event_PlayerSpawn)
	HookEvent("player_hurt", Event_PlayerHurt)

	HookEvent("merasmus_summoned", Event_BossSpawned)
	HookEvent("merasmus_killed", Event_BossWin)
	HookEvent("merasmus_escaped", Event_BossLoss)

	RegConsoleCmd("sm_traitors", Command_ConsoleOutput)
}

public Action:Command_ConsoleOutput(client, args)
{
	decl String:name[MAX_NAME_LENGTH]

	PrintToConsole(client, "List of traitors:")
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || g_points[i] < 1)
			continue
		
		GetClientName(i, name, sizeof(name))
		PrintToConsole(client, "Marked: %d Points: %d Name: %s", g_glowing[i], g_points[i], name)
	}
}

public OnClientConnected(client)
{
	g_points[client] = 0
	g_glowing[client] = 0
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl victim, killer

	victim = GetClientOfUserId(GetEventInt(event, "userid"))
	killer = GetClientOfUserId(GetEventInt(event, "attacker"))

	if (!g_bossActive || !killer || !victim || killer == victim)
		return

	if (g_lasthurtby[killer] == victim)
	{
		g_lasthurtby[killer] = 0
		return
	}

	if (g_points[victim] > 0)
	{
		if (g_lasthurtby[killer] != victim)
		{
			g_points[victim] = g_points[victim] - SUBPOINTSREVENGE
		}
		if (g_points[killer] > 0)
		{
			g_points[killer] = g_points[killer] - SUBPOINTSMARKEDKILL
		}
		if (g_points[victim] < 0)
		{
			g_points[victim] = 0
		}
	}
	else if (TF2_GetPlayerClass(victim) != TFClass_Spy)
	{
		g_points[killer] = g_points[killer] + ADDKILLPOINTS
	}

	decideGlow(killer)

	if (g_glowing[killer])
		PrintToChat(victim, "You were killed by a marked traitor. All marked traitors can be killed without being marked yourself.")
}

decideGlow(client)
{
	if (g_points[client] > POINTSTHRESHOLD && g_glowing[client] < 1)
	{
		setGlow(client, 1)
		
		decl String:clientname[MAX_NAME_LENGTH]
		GetClientName(client, clientname, sizeof(clientname))
		PrintToChatAll("%s is a traitor and has been marked! Killing a marked traitor is always allowed.", clientname)
	}
	else if (g_points[client] < POINTSTHRESHOLD && g_glowing[client] == 1)
	{
		setGlow(client, 0)
	}
}

setGlow(client, status)
{
	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", status, 1)
		g_glowing[client] = status
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bossActive)
		return

	decl victim, attacker

	victim = GetClientOfUserId(GetEventInt(event, "userid"))
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"))

	if (!(0 < victim < MaxClients) || !(0 < attacker < MaxClients))
		return

	if (!IsClientConnected(victim) || !IsClientConnected(attacker))
		return

	if (g_lasthurtby[attacker] == victim)
		return
	
	g_lasthurtby[victim] = attacker
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bossActive)
		return

	decl client
	
	client = GetClientOfUserId(GetEventInt(event, "userid"))
	decideGlow(client)
	if (g_glowing[client] == 1)
	{
		setGlow(client, 1)
	}

	g_lasthurtby[client] = 0
}

public Event_BossSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(SPAWNDELAY, Timer_ActiveBoss)

	for (new i = 1; i <= MaxClients; i++)
	{
		g_lasthurtby[i] = 0
		
		if (g_points[i] > 0)
		{
			g_points[i] = g_points[i] - SUBPOINTSNEWBOSS
			if (g_points[i] < 0)
			{
				g_points[i] = 0
			}
			decideGlow(i)
		}
		
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_glowing[i])
		{
			setGlow(i, 1)
		}
	}
}

public Event_BossWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(WINDELAY, Timer_InactiveBoss)
}

public Event_BossLoss(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(LOSSDELAY, Timer_InactiveBoss)
}

public Action:Timer_ActiveBoss(Handle:timer)
{
	g_bossActive = true
}

public Action:Timer_InactiveBoss(Handle:timer)
{
	g_bossActive = false
}
