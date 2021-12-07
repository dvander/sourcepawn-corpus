#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
public Plugin myinfo =
{
	name = "L4D1 Human Game",
	author = "Axel Juan Nieves",
	description = "L4D1 Only Humans",
	version = PLUGIN_VERSION,
	url = ""
};

#define TEAM_SPEC		1
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

#define FLAGS_SURVIVOR	1
#define FLAGS_INFECTED	2
#define FLAGS_ALIVE		4
#define FLAGS_DEAD		8
#define FLAGS_BOT		16
#define FLAGS_HUMAN		32
#define FLAGS_OBSERVER	64
#define FLAGS_SPEC		128

g_iBots[MAXPLAYERS+1];

public void OnPluginStart()
{
	CreateConVar("l4d1_human_game_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d1_human_game");
	//LoadTranslations("l4d1_human_game.phrases");
	
	HookEvent("player_spawn", event_player_spawn, EventHookMode_PostNoCopy);
	HookEvent("player_team", event_player_team, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", event_player_bot_replace, EventHookMode_Post); //bot replaced a player
	HookEvent("bot_player_replace", event_bot_player_replace, EventHookMode_Post); //bot replaced a player
	//HookEvent ("weapon_fire", event_weapon_fire)
	//HookEvent("player_spawn", event_player_spawn_pre, EventHookMode_Pre);
}


public Action event_player_bot_replace(Handle event, const char[] name, bool dontBroadcast) //bot replaced a player
{
	//Let's allow a human player become a bot while he is connected, but remember his ID. We will kick that bot when his client disconnects.
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	g_iBots[client] = bot;
	
	//PrintToChatAll("%N is repalcing %N", GetClientOfUserId(GetEventInt(event, "bot")), GetClientOfUserId(GetEventInt(event, "player")));
	//PrintToServer("%N is repalcing %N", GetClientOfUserId(GetEventInt(event, "bot")), GetClientOfUserId(GetEventInt(event, "player")));
	return Plugin_Continue;
}

public Action event_bot_player_replace(Handle event, const char[] name, bool dontBroadcast) //player replaced a bot
{
	//Let's allow a human player become a bot while he is connected, but remember his ID. We will kick that bot when his client disconnects.
	g_iBots[GetClientOfUserId(GetEventInt(event, "player"))] = 0;
	//g_iHumans[GetClientOfUserId(GetEventInt(event, "bot"))] = 0;
	//PrintToChatAll("%N is repalcing %N", GetClientOfUserId(GetEventInt(event, "bot")), GetClientOfUserId(GetEventInt(event, "player")));
	//PrintToServer("%N is repalcing %N", GetClientOfUserId(GetEventInt(event, "bot")), GetClientOfUserId(GetEventInt(event, "player")));
	return Plugin_Continue;
}

public void event_player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsFakeClient(client) )
		return;
	
	if ( GetPlayersCount(FLAGS_SURVIVOR|FLAGS_BOT) > GetPlayersCount(FLAGS_SURVIVOR|FLAGS_HUMAN|FLAGS_OBSERVER|FLAGS_SPEC) )
	{
		PrintToChatAll("Humans afk:%i, bots:%i. Kicking %N", GetPlayersCount(FLAGS_SURVIVOR|FLAGS_HUMAN|FLAGS_OBSERVER|FLAGS_SPEC), GetPlayersCount(FLAGS_SURVIVOR|FLAGS_BOT), client);
		KickClient(client);
	}
	else
	{
		PrintToChatAll("Humans afk:%i, bots:%i. DO NOT KICK %N", GetPlayersCount(FLAGS_SURVIVOR|FLAGS_HUMAN|FLAGS_OBSERVER|FLAGS_SPEC), GetPlayersCount(FLAGS_SURVIVOR|FLAGS_BOT), client);
	}
}

//when a player leaves the server, this kicks its bot...
public void event_player_team(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int bot = g_iBots[client];
	if ( GetEventBool(event, "disconnect") )
	{
		if ( IsValidClientInGame(bot) )
		{
			if ( IsFakeClient(bot) && !IsClientObserver(bot) )
			{
				//PrintToChatAll("Kicking bot %N", bot);
				PrintToServer("Kicking bot %N", bot);
				KickClient(bot);
			}
		}
	}
	
	PrintToServer(" - - - - - - -%N isbot(%i) disconnect(%i)", client, GetEventBool(event, "isbot"), GetEventBool(event, "disconnect"));
}

stock int GetPlayersCount(int flags=0)
{
	int count, success;
	//if both FLAGS_INFECTED and FLAGS_SURVIVOR are omited, both will be enabled.
	if (flags & (FLAGS_INFECTED | FLAGS_SURVIVOR) == 0)
		flags |= (FLAGS_INFECTED | FLAGS_SURVIVOR);
	
	if (flags & (FLAGS_BOT | FLAGS_HUMAN) == 0)
		flags |= (FLAGS_BOT | FLAGS_HUMAN);
	
	//if both FLAGS_ALIVE and FLAGS_DEAD are omited, both will be enabled.
	if (flags & (FLAGS_ALIVE | FLAGS_DEAD) == 0)
		flags |= (FLAGS_ALIVE | FLAGS_DEAD);
	
	//if both FLAGS_BOT and FLAGS_HUMAN are omited, both will be enabled.
	if (flags & (FLAGS_BOT | FLAGS_HUMAN) == 0)
		flags |= (FLAGS_ALIVE | FLAGS_DEAD);
	
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		success = 0;
		if (!IsValidClientInGame(i))
			continue;
		
		//check alive status...
		if ( IsPlayerAlive(i) && flags&FLAGS_ALIVE)
			success++;
		else if ( !IsPlayerAlive(i) && flags&FLAGS_DEAD)
			success++;
		
		//check team...
		if (GetClientTeam(i)==TEAM_INFECTED && flags&FLAGS_INFECTED)
			success++;
		else if (GetClientTeam(i)!=TEAM_INFECTED && flags&FLAGS_SURVIVOR)
			success++;
		else if (GetClientTeam(i)!=TEAM_SPEC && flags&FLAGS_SPEC)
			success++;
		
		//check bot...
		if ( IsFakeClient(i) && flags&FLAGS_BOT )
			success++;
		else if ( !IsFakeClient(i) && flags&FLAGS_HUMAN )
		{
			//check idle humans...
			if ( IsClientObserver(i) && flags&FLAGS_OBSERVER )
			{
				success++;
			}
			else if ( !IsClientObserver(i) && (flags&FLAGS_OBSERVER==0) )
			{
				success++;
			}
		}
		
		//check above conditions...
		if (success==3)
			count++;
	}
	return count;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}