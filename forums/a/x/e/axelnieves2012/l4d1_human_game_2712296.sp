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

#define DELAY_KICK_FAKECLIENT 		0.1
#define DELAY_KICK_NONEEDBOT 		5.0
#define DELAY_KICK_NONEEDBOT_SAFE   30.0
#define DELAY_CHANGETEAM_NEWPLAYER 	1.5

bool g_bLeftSafeRoom;
Handle g_hPlayerLeftStartTimer = null;
Handle g_hTimer_SpecCheck = null;
int g_iTime;
int g_iCountDownTime;
int g_iRoundStart = 0;
int g_iPlayerSpawn = 0;

public void OnPluginStart()
{
	CreateConVar("l4d1_human_game_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d1_human_game");
	//LoadTranslations("l4d1_human_game.phrases");
	
	//HookEvent("player_first_spawn", event_player_first_spawn, EventHookMode_PostNoCopy);
	HookEvent("round_start", event_round_start, EventHookMode_Post);
	HookEvent("player_team", event_player_team, EventHookMode_Post);
	HookEvent("player_spawn", event_player_spawn, EventHookMode_Post);
	HookEvent("player_death", event_player_death, EventHookMode_Post);
	HookEvent("player_bot_replace", event_player_bot_replace, EventHookMode_Post); //bot replaced a player
	//HookEvent("bot_player_replace", event_bot_player_replace, EventHookMode_Post); //player replaced a bot
}

public void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	if ( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, PluginStart);
	g_iRoundStart = 1;
}

public Action PluginStart(Handle timer)
{
	ClearDefault();
	g_iCountDownTime = g_iTime;
	if (g_iCountDownTime > 0)
		CreateTimer(1.0, CountDown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if (g_hPlayerLeftStartTimer == null) 
		g_hPlayerLeftStartTimer = CreateTimer(1.0, PlayerLeftStart, _, TIMER_REPEAT);
	if (g_hTimer_SpecCheck == null) 
		g_hTimer_SpecCheck = CreateTimer(1.0, Timer_SpecCheck, _, TIMER_REPEAT)	;
}

public void event_player_bot_replace(Handle event, const char[] name, bool dontBroadcast) //bot replaced a player
{
	int fakebot = GetClientOfUserId(GetEventInt(event, "bot"));
	if ( fakebot && GetClientTeam(fakebot) == TEAM_SURVIVOR && IsFakeClient(fakebot) )
	{
		if (!g_bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, fakebot);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, fakebot);
	}
}

public void event_player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( client && GetClientTeam(client) == TEAM_SURVIVOR && IsFakeClient(client) )
	{
		if (!g_bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, client);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, client);
	}
	
	if ( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, PluginStart);
	g_iPlayerSpawn = 1;
}

public void event_player_death(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if ( client && GetClientTeam(client) == TEAM_SURVIVOR && IsFakeClient(client) )
	{
		if (!g_bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, client);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, client);
	}
} 

//when a player leaves the server, this kicks its bot...
public void event_player_team(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int oldteam = GetEventInt(event, "oldteam");

	if( oldteam == TEAM_SURVIVOR || GetEventBool(event, "disconnect") )
	{
		if ( IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR )
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if ( IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsValidClientAlive(i) )
				{
					if( HasEntProp(i, Prop_Send, "m_humanSpectatorUserID") )
					{
						if ( GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client )
						{
							//LogMessage("afk player %N changes team or leaves the game, his bot is %N",client,i);
							if (!g_bLeftSafeRoom)
								CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, i);
							else
								CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, i);
						}
					}
				}
			}
		}
	}
}

public Action Timer_KickNoNeededBot(Handle timer, int bot)
{
	if ( IsClientConnected(bot) && IsClientInGame(bot) && IsFakeClient(bot) )
	{
		if ( GetClientTeam(bot) != TEAM_SURVIVOR )
			return Plugin_Handled;
		
		if (!HasIdlePlayer(bot)) //no one afk this bot
		{
			KickClient(bot, "Kicking No Needed Bot");
		}
	}    
	return Plugin_Handled;
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

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}

public Action PlayerLeftStart(Handle Timer)
{
	if (LeftStartArea() || g_bLeftSafeRoom)
	{	
		g_bLeftSafeRoom = true;
		g_hPlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if ( IsValidEntity(i) )
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}

	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	//bKill = false;
	g_bLeftSafeRoom = false;
}

public Action CountDown(Handle timer)
{
	if(g_iCountDownTime <= 0) 
	{
		//bKill = true;
		return Plugin_Stop;
	}
	g_iCountDownTime--;
	return Plugin_Continue;
}

public Action Timer_SpecCheck(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if((GetClientTeam(i) == TEAM_SPEC) && !IsFakeClient(i))
			{
				if(!IsClientIdle(i))
				{
					char PlayerName[100];
					GetClientName(i, PlayerName, sizeof(PlayerName))		;
					PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, 聊天視窗輸入 \x03!join\x01 來加入倖存者隊伍", PlayerName);
				}
			}
		}
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))		
		{
			if((GetClientTeam(i) == TEAM_SURVIVOR) && !IsFakeClient(i) && !IsAlive(i))
			{
				char PlayerName[100];
				GetClientName(i, PlayerName, sizeof(PlayerName));
				PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, 請等待救援或復活", PlayerName);
			}
		}
	}	
	return Plugin_Continue;
}

bool HasIdlePlayer(int bot)
{
	if(IsClientConnected(bot) && IsClientInGame(bot) && IsFakeClient(bot) && GetClientTeam(bot) == 2 && IsAlive(bot))
	{
		if(HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))	;		
			if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsClientObserver(client))
			{
				return true;
			}
		}
	}
	return false;
}

bool IsClientIdle(int client)
{
	if(GetClientTeam(client) != 1)
		return false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsAlive(i))
		{
			if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
			{
				if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
					return true;
			}
		}
	}
	return false;
}

bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState"))
		return true;
	
	return false;
}
