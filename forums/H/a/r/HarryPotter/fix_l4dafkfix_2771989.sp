#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.5"
#define TEAM_SURVIVORS 2
#define TEAM_SPECTATOR 1

//=================
#define debug 0

#define LOG		"logs\\crash_log.log"

#if debug
static	char DEBUG[256];
#endif
//===============

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] 4+ Survivor Afk Fix",
	author = "MI 5, SwiftReal, raziEiL [disawar1], Electr0 [m_iMeow], HarryPotter",
	description = "Fixes issue where player does not go IDLE on a bot in 4+ survivors games",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public void OnPluginStart()
{
	#if debug
		BuildPath(Path_SM, DEBUG, sizeof(DEBUG), LOG);
	#endif

	// Hook the player_bot_replace event and player_afk event
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnded, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnded, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", Event_RoundEnded, EventHookMode_PostNoCopy); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnded, EventHookMode_PostNoCopy); //救援載具離開之時  (之後沒有觸發round_end)
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player dies
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client) return;
	if(!IsClientInGame(client)) return;

	// If the client is a bot and has a player idle on it, force the player to take over the bot
	if(IsFakeClient(client) && GetClientTeam(client)==TEAM_SURVIVORS)
	{
		int idleplayer = FindidOfIdlePlayer(client);
		if(idleplayer != 0) TakeOverBot(idleplayer, client);
	}
}

void TakeOverBot(int client, int bot)
{
	if (client > 0)
	{
		//PrintToChatAll("TakeOverBot %N %N", client, bot);

		#if debug
			LogToFile(DEBUG, "TakeOverBot(%N, %N) -> SDKCall SetHumanSpec", client, bot);
		#endif

		L4D_SetHumanSpec(bot, client);

		#if debug
			LogToFile(DEBUG, "TakeOverBot(%N, %N) -> SDKCall TakeOverBot", client, bot);
		#endif

		L4D_TakeOverBot(client);
		return;
	}
}

public Action Event_RoundEnded(Event event, const char[] name, bool dontBroadcast)
{
	int idleplayer;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && IsPlayerAlive(i))
		{
			idleplayer = FindidOfIdlePlayer(i);
			if(idleplayer != 0) TakeOverBot(idleplayer, i);
		}
	}
}

int FindidOfIdlePlayer(int bot)
{
	char sNetClass[12];
	GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

	if( strcmp(sNetClass, "SurvivorBot") == 0 )
	{
		if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
			return 0;

		int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
		if(client)
		{
			// Do not count bots
			// Do not count 3rd person view players
			if(IsClientInGame(client) && !IsFakeClient(client) && (GetClientTeam(client) == TEAM_SPECTATOR))
				return client;
		}
	}

	return 0;
}