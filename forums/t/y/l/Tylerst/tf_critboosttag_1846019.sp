#pragma semicolon 1

#include <tf2>

#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 
{
	
	name = "Crit Boost Tag",
	
	author = "Tylerst",

	description = "Gives Criticals to a random player",

	version = PLUGIN_VERSION,
	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

#define MINPLAYERS 6

new g_PlayerCount = 0;
new bool:g_bEnabled = false;
new g_BoostedPlayer = 0;


public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}
public OnClientPutInServer(client)
{
	if(++g_PlayerCount >= MINPLAYERS)
	{
		if(!g_bEnabled)
		{
			g_bEnabled = true;
			ChooseBoostedPlayer();
		}
	} 
}

public OnClientDisconnect_Post(client)
{
	if(--g_PlayerCount < MINPLAYERS)
	{
		if(g_bEnabled)
		{
			g_bEnabled = false;
			g_BoostedPlayer = 0;
			UnBoostPlayer(g_BoostedPlayer);			
		}
	}
	else
	{
		if(client == g_BoostedPlayer) ChooseBoostedPlayer();
	}
}

public OnMapStart()
{
	g_PlayerCount = 0;
	g_bEnabled = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client == g_BoostedPlayer) BoostPlayer(client);
	}
}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if(victim == g_BoostedPlayer)
		{
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			if(victim == attacker) ChooseBoostedPlayer();
			else if(attacker > 0 && attacker <= MaxClients)
			{
				g_BoostedPlayer = attacker;
				if(IsPlayerAlive(attacker)) BoostPlayer(attacker);
			}
			else ChooseBoostedPlayer();
		}
	}
}

public ChooseBoostedPlayer()
{
	new PlayerArray[MaxClients+1], PlayerCounter;
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && client != g_BoostedPlayer) PlayerArray[PlayerCounter++] = client;
	}
	new BoostedPlayer = PlayerArray[GetRandomInt(0, PlayerCounter-1)];
	g_BoostedPlayer = BoostedPlayer;
	if(IsPlayerAlive(BoostedPlayer)) BoostPlayer(BoostedPlayer);

}

public BoostPlayer(client)
{	
	TF2_AddCondition(client, TFCond_CritOnKill, -1.0);
	TF2_AddCondition(client, TFCond_MarkedForDeath, -1.0);
	TF2_AddCondition(client, TFCond_Milked, -1.0);	
}

public UnBoostPlayer(client)
{	
	TF2_RemoveCondition(client, TFCond_CritOnKill);
	TF2_RemoveCondition(client, TFCond_MarkedForDeath);
	TF2_RemoveCondition(client, TFCond_Milked);	
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(g_bEnabled && g_BoostedPlayer == client)
	{
		if(condition == TFCond_CritOnKill || condition == TFCond_MarkedForDeath || condition == TFCond_Milked)
		{
			BoostPlayer(client);
		}
	}
}






