#pragma semicolon 1
#include <sourcemod>

#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

static bool g_bL4D2Version;

static int hp, client;
bool i_client[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[L4D] Punishments for Hide Seek",
	author = "AlexMy",
	description = "<- Description ->",
	version = "1.0",
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }
    
    g_bL4D2Version = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_jump",      eventPlayerJump, EventHookMode_Post);
	//HookEvent("player_jump_apex", eventPlayerJump, EventHookMode_Post);
}
	
public void eventPlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	if((client = GetClientOfUserId(event.GetInt("userid"))) && client && GetClientTeam(client) == 2 && !IsFakeClient(client) && IsTankAlive())
	{
		if(!i_client[client])
			CreateTimer(2.0, AlexMy_OmSk, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action AlexMy_OmSk(Handle timer, any player)
{
	if(player && IsValidEntity(player) && IsClientInGame(player))
	{
		if((i_GameDuck(player) == 0) && (i_GameFrags(player) == 129))
		{
			return Plugin_Stop;
		}
		if((i_GameDuck(player) == 1000) && (i_GameFrags(player) == 131))
		{
			i_client[player] = true;
			PrintHintText(player, "Будешь %N Гасится от Танка, Будешь Наказан!", player);
			CreateTimer(3.0, minus_health, player, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Stop;
}

public Action minus_health(Handle timer, any player)
{
	if(player && IsValidEntity(player) && IsClientInGame(player)) 
	{
		if((i_GameDuck(player) == 0) && (i_GameFrags(player) == 129))
		{
			i_client[player] = false;
			PrintHintText(player, "Ну Всё, Наказание Отменено!!!");
			return Plugin_Stop;
		}
		
		if ((hp = GetClientHealth(player)))
		{
			SetEntityHealth(player, hp - 2);
			PrintHintText(player, "Ну Удачи Тебе :D  %i - HP.", hp);
		}
	}
	return Plugin_Continue;
}

bool IsTankAlive()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == (g_bL4D2Version ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK))
			return true;
	}
	return false;
}


int i_GameDuck(int player)
{
	return(GetEntProp(player, Prop_Send, "m_nDuckTimeMsecs"));
}

int i_GameFrags(int player)
{
	return(GetEntProp(player, Prop_Send, "m_fFlags"));
}