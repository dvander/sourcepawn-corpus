
/*
	STATE_ACTIVE=0,
	STATE_WELCOME,
	STATE_PICKINGTEAM,
	STATE_PICKINGCLASS,
	STATE_DEATH_ANIM,
	STATE_DEATH_WAIT_FOR_KEY,
	STATE_OBSERVER_MODE,
	STATE_GUNGAME_RESPAWN,
	STATE_DORMANT,
	NUM_PLAYER_STATES
*/




#include <sdktools>


int halftimeroundsplayed = 0;
bool IsRoundStart_Post;	// check players respawn after round_start event (mp_join_grace_time)

ConVar mp_afterroundmoney;
ConVar mp_maxmoney;
ConVar mp_startmoney;

StringMap accounts;

enum
{
	GAMEPHASE_WARMUP_ROUND,
	GAMEPHASE_PLAYING_STANDARD,
	GAMEPHASE_PLAYING_FIRST_HALF,
	GAMEPHASE_PLAYING_SECOND_HALF,
	GAMEPHASE_HALFTIME,
	GAMEPHASE_MATCH_ENDED,
	GAMEPHASE_MAX
};

public void OnPluginStart()
{
	accounts = new StringMap();

	mp_afterroundmoney = FindConVar("mp_afterroundmoney");
	mp_maxmoney = FindConVar("mp_maxmoney");
	mp_startmoney = FindConVar("mp_startmoney");

	if(mp_afterroundmoney == null)
		SetFailState("Plugin not found ConVar mp_afterroundmoney");

	if(mp_maxmoney == null)
		SetFailState("Plugin not found ConVar mp_maxmoney");

	if(mp_startmoney == null)
		SetFailState("Plugin not found ConVar mp_startmoney");


	HookEvent("cs_pre_restart", events);		// reset round
	HookEvent("round_start", events);		// new round began
	HookEvent("begin_new_match", events);	// new match

	HookEvent("player_team", player_team);
	HookEvent("player_spawn", player_spawn);
}


public void events(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToServer("%s m_gamePhase %d", name, GameRules_GetProp("m_gamePhase"));

	if(GameRules_GetProp("m_bWarmupPeriod")
	|| GameRules_GetProp("m_bGameRestart")
	|| StrEqual(name, "begin_new_match", false))
	{
		halftimeroundsplayed = 0;
		return;
	}

	int m_totalRoundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");

	if(StrEqual(name, "cs_pre_restart", false))
	{
		IsRoundStart_Post = false;

		accounts.Clear();	// clear money on round reset

		if(GameRules_GetProp("m_gamePhase") == GAMEPHASE_HALFTIME) // It's half time
		{
			halftimeroundsplayed = m_totalRoundsPlayed;
		}
		
		return;
	}


	if(StrEqual(name, "round_start", false))
	{
		IsRoundStart_Post = true;

		m_totalRoundsPlayed -= halftimeroundsplayed;

		// This happens only on 2nd round
		if(m_totalRoundsPlayed != 1)
			return;

		int maxmoney = mp_maxmoney.IntValue;

		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_iPlayerState") != 0)
				continue;

			// Set max money, all those players who respawn at pre-round_start
			SetMoney(i, maxmoney);
			SetEntProp(i, Prop_Send, "m_iAccount", maxmoney);
		}
		
		PrintToChatAll(" \x01[SM]\x03 Boost $%i for everyone", maxmoney);
	}
}

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!IsRoundStart_Post
	|| GameRules_GetProp("m_bWarmupPeriod")
	|| GameRules_GetProp("m_bGameRestart"))
	{
		return;
	}

	int m_totalRoundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");

	m_totalRoundsPlayed -= halftimeroundsplayed;

	// This happens only on 2nd round
	if(m_totalRoundsPlayed != 1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(GetEntProp(client, Prop_Send, "m_iPlayerState") != 0)
		return;


	int maxmoney = mp_maxmoney.IntValue;

	GetMoney(client, maxmoney);
	PrintToChat(client, " \x01[SM]\x03 Boost $%i for your account", maxmoney);
	SetEntProp(client, Prop_Send, "m_iAccount", maxmoney);
}



public void player_team(Event event, const char[] name, bool dontBroadcast)
{
	if(!IsRoundStart_Post
	|| GameRules_GetProp("m_bWarmupPeriod")
	|| GameRules_GetProp("m_bGameRestart")
	|| GameRules_GetProp("m_gamePhase") == GAMEPHASE_HALFTIME
	|| GameRules_GetProp("m_gamePhase") == GAMEPHASE_MATCH_ENDED)
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client == 0)
		return;

	int m_totalRoundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");

	m_totalRoundsPlayed -= halftimeroundsplayed;

	int money;

	// pistol round
	if(m_totalRoundsPlayed == 0)
	{
		if(event.GetInt("oldteam") != 0)
			return;

		money = mp_startmoney.IntValue;

		if(GetEntProp(client, Prop_Send, "m_iAccount") != money)
		{
			SetEntProp(client, Prop_Send, "m_iAccount", money);
			PrintToChat(client, " \x01[SM]\x03 Money Bug fix $%i", money);
		}

		return;
	}

	// Second round only
	if(m_totalRoundsPlayed != 1)
		return;


	money = mp_maxmoney.IntValue;

	// player is joinning in team (first time)
	if(event.GetInt("oldteam") == 0)
	{
		UpdateMoney(client, money);
		SetEntProp(client, Prop_Send, "m_iAccount", money);
		PrintToChat(client, " \x01[SM]\x03 Boost $%i for your account", money);
		return;
	}

	// player is joinning spec, he will lose money afterwards
	if(event.GetInt("oldteam") > 1 && event.GetInt("team") == 1)
	{
		SetMoney(client, GetEntProp(client, Prop_Send, "m_iAccount"));
		return;
	}

	// player disconnect from server, but not as spectator
	if(event.GetInt("disconnect") && event.GetInt("oldteam") > 1)
	{
		SetMoney(client, GetEntProp(client, Prop_Send, "m_iAccount"));
		return;
	}

	// player is joinning in team from spec
	if(event.GetInt("oldteam") == 1)
	{
		UpdateMoney(client, money);
		SetEntProp(client, Prop_Send, "m_iAccount", money);
		PrintToChat(client, " \x01[SM]\x03 Boost $%i for your account", money);
		return;
	}
}


void UpdateMoney(int client, int &value)
{
	if(IsFakeClient(client))
		return;

	char auth[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));

	if(!accounts.ContainsKey(auth))
	{
		accounts.SetValue(auth, value, true);
		return;
	}

	accounts.GetValue(auth, value);
}

void GetMoney(int client, int &value)
{
	if(IsFakeClient(client))
		return;

	char auth[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));

	accounts.GetValue(auth, value);
}

void SetMoney(int client, int value)
{
	if(IsFakeClient(client))
		return;

	char auth[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth));

	accounts.SetValue(auth, value, true);
}
