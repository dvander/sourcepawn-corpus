//Sourcemod Includes
#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

//Globals
new bool:IsWarmUp=true;
new bool:WarmupCFGExecuted=false;
new bool:live=false;

public Plugin myinfo = 
{
	name = "Competitive", 
	author = "Armin", 
	description = "Very simple pug plugin.", 
	version = "PLUGIN_VERSION", 
	url = "https://nerp.cf/"
};


public OnPluginStart()
{
	//EVENTS
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnMapStart()
{	
	WarmupCFGExecuted=false;
	
	IsWarmUp=true;
	
	live=false;
	
	CreateTimer(10.0, Timer_CfgExecute)
}

public Action Timer_CfgExecute(Handle timer)
{
	if (WarmupCFGExecuted=false)
	{
		ServerCommand("mp_warmup_start");
		ServerCommand("mp_warmuptime 3600");
		ServerCommand("bot_kick");
		ServerCommand("sv_alltalk 1");
		ServerCommand("mp_warmup_pausetimer 1");
		
		WarmupCFGExecuted=true;
		
		IsWarmUp=true;
		
		live=false;
	}
}

public Action Event_OnPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!(client > 0 && IsClientInGame(client)))
	{
		return Plugin_Continue;
	}
 
    if (GetAlivePlayersTeamCount(CS_TEAM_T) == 5 && GetAlivePlayersTeamCount(CS_TEAM_CT) == 5)
	{
		if(IsWarmUp)
		{
			if(GameRules_GetProp("m_bWarmupPeriod")==0)
			{
				IsWarmUp=false;
				CreateTimer(0.2, Timer_Scramble);
				CreateTimer(3.0, Timer_Message);
		
				live=true;
			}
		}
		
		ServerCommand("bot_kick");
		ServerCommand("mp_warmup_end");
	}
}

int GetAlivePlayersTeamCount(int team)
{
    int iCount = 0;
 
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
 
        if (!IsPlayerAlive(i))
            continue;
 
        if (GetClientTeam(i) != team)
            continue;
 
        iCount++;
    }
 
    return iCount;
}

public Action Timer_Scramble(Handle timer)
{
	ServerCommand("mp_scrambleteams");
	ServerCommand("mp_restartgame 1");
	ServerCommand("exec gamemode_casual.cfg");
}

public Action Timer_Message(Handle timer)
{
	PrintToChatAll(" ");
    PrintToChatAll(" Teams are \x06set\x01, let's get this party started!");
    PrintToChatAll(" ");
    
    for (int i = 0; i < 3; i++)
    {
        PrintToChatAll(" Hey Ho, Let's Go! Match Is \x06Live");
    }
    
    PrintToChatAll(" ");
    PrintToChatAll(" Good Luck & Have Fun!");
	PrintToChatAll(" ");
}