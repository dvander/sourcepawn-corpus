#define PLUGIN_VERSION		"0.2"
#include <sourcemod>
#include "left4downtown.inc"

new Handle:g_TankPlayers;
new Handle:f_TimePeriod;
new Handle:b_SamePlayers;
new bool:bActiveRound;
new String:GameTypeCurrent[128];

public Plugin:myinfo = {
	name = "Some Tank Thingy",
	author = "Sky",
	description = "Spawns tanky things",
	version = PLUGIN_VERSION,
	url = "mikel.toth@gmail.com"
}

public OnPluginStart()
{
	g_TankPlayers		= CreateConVar("sm_tank_count","8","How many tanks you would like active at any point.");
	f_TimePeriod		= CreateConVar("sm_time_count","15.0","How long to wait after a player dies to check tank count.");
	b_SamePlayers		= CreateConVar("sm_same_count","0","If enabled, overrides sm_tank_count and maintains same-as-survivors.");
	HookEvent("round_end", Round_End);
	HookEvent("player_death", Player_Death);
	HookEvent("player_left_start_area", Player_Left_Start_Area);
	AutoExecConfig(true, "tankConfig_conf");
}

public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!bActiveRound) return;
	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3) CreateTimer(GetConVarFloat(f_TimePeriod), Timer_CheckPlayerCount);
}

public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast) { bActiveRound = false; }

// When a player leaves, we check to see if there are humans, because if there aren't,
// we need to tell it to create the bot tanks anyway.
public Action:Player_Left_Start_Area(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (!bActiveRound)
	{
		bActiveRound = true;
		CreateTimer(GetConVarFloat(f_TimePeriod), Timer_CheckActiveCount);
	}
}

// Check if it is only bots - and create the tanks if this is the case,
// as the other method requires there to be humans.
public Action:Timer_CheckActiveCount(Handle:timer)
{
	new survivorCount = 0;
	new infectedCount = 0;
	new spawnRemaining = 0;
	new client = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == 2) survivorCount++;
		else if (GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8) infectedCount++;
		if (GetClientTeam(i) == 3) client = i;
	}
	// if we have found a player, ignore.
	if (client != 0) return Plugin_Stop;
	client = CreateFakeClient("FakeClient");
	if (GetConVarInt(b_SamePlayers) == 1) spawnRemaining = survivorCount - infectedCount;
	else spawnRemaining = GetConVarInt(g_TankPlayers) - infectedCount;
	while (spawnRemaining > 0)
	{
		CreateTimer(0.1, spawnTank, client);
		spawnRemaining--;
	}
	CreateTimer(0.1, kickFakeClient, client);
	return Plugin_Stop;
}

public Action:kickFakeClient(Handle:timer, any:client) { KickClient(client, "FakeClient"); }

public Action:Timer_CheckPlayerCount(Handle:timer)
{
	if (!bActiveRound) return Plugin_Stop;
	new infectedCount = 0;
	new survivorCount = 0;
	new spawnRemaining = 0;
	new client = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == 2) survivorCount++;
		else if (GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == 8) infectedCount++;
		client = i;
	}
	if (GetConVarInt(b_SamePlayers) == 1) spawnRemaining = survivorCount - infectedCount;
	else spawnRemaining = 1;
	while (spawnRemaining > 0)
	{
		CreateTimer(0.1, spawnTank, client);
		spawnRemaining--;
	}
	return Plugin_Stop;
}

public Action:spawnTank(Handle:timer, any:client) { ExecCheatCommand(client, "z_spawn", "tank auto"); }

ExecCheatCommand(client = 0,const String:command[],const String:parameters[] = "")
{
	new iFlags = GetCommandFlags(command);
	SetCommandFlags(command,iFlags & ~FCVAR_CHEAT);

	FakeClientCommand(client,"%s %s",command,parameters);

	SetCommandFlags(command,iFlags);
	SetCommandFlags(command,iFlags|FCVAR_CHEAT);
}