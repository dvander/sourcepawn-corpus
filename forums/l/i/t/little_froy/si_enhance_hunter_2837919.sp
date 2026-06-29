#define PLUGIN_VERSION  "1.7"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "SI Enhance Hunter",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_delay;
float O_delay;
ConVar C_interval;
float O_interval;
ConVar C_times;
int O_times;
ConVar C_damage;
int O_damage;

bool Started;

Handle H_bleed[MAXPLAYERS+1];
int Bleed_times[MAXPLAYERS+1];
ArrayList Used_timer;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnMapStart()
{
	Started = true;
    reset_all();
}

public void OnMapEnd()
{
	Started = false;
    reset_all();
}

public void OnClientDisconnect_Post(int client)
{
    if(!Started)
    {
        return;
    }
    reset_player(client);
}

void reset_player(int client)
{
    H_bleed[client] = null;
    Bleed_times[client] = 0;
}

void reset_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
		if(IsClientInGame(client))
		{
        	reset_player(client);
		}
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	Started = true;
    reset_all();
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
	Started = false;
    reset_all();
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
	Started = false;
    reset_all();
}

bool bleed(Handle timer, bool start)
{
	bool repeat = false;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(timer == H_bleed[client])
		{
			if(!Started || Bleed_times[client] < 1 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_player_alright(client))
			{
				reset_player(client);
				continue;
			}
			Bleed_times[client]--;
			float time_stamp = -1.0;
			CountdownTimer inv_timer = L4D2Direct_GetInvulnerabilityTimer(client);
			if(inv_timer)
			{
				time_stamp = CTimer_GetTimestamp(inv_timer);
				CTimer_SetTimestamp(inv_timer, -1.0);
			}
			SDKHooks_TakeDamage(client, client, client, float(O_damage));
			if(inv_timer)
			{
				CTimer_SetTimestamp(inv_timer, time_stamp);
			}
			if(Bleed_times[client] == 0)
			{
				H_bleed[client] = null;
				continue;
			}
			repeat = true;
			if(start)
			{
				H_bleed[client] = CreateTimer(O_interval, timer_repeat, _, TIMER_REPEAT);
				Used_timer.Push(H_bleed[client]);
			}
		}
	}
	return repeat;
}

Action timer_repeat(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
	if(bleed(timer, false))
	{
		Used_timer.Push(timer);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}

void timer_start(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
	bleed(timer, true);
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started || event.GetInt("dmg_health") < 1)
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
	{
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if(attacker > 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 3)
        {
			if(!H_bleed[client])
			{
				for(int i = 0; i < Used_timer.Length; i++)
				{
					Handle timer = Used_timer.Get(i);
					bool got = false;
					for(int j = 1; j <= MaxClients; j++)
					{
						if(timer == H_bleed[j])
						{
							got = true;
							break;
						}
					}
					if(!got)
					{
						Used_timer.Erase(i--);
						delete timer;
					}
				}
				H_bleed[client] = CreateTimer(O_delay, timer_start);
				Used_timer.Push(H_bleed[client]);
			}
            Bleed_times[client] = O_times;
        }
	}
}

void data_trans(int client, int prev)
{
    H_bleed[client] = H_bleed[prev];
    Bleed_times[client] = Bleed_times[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

void get_all_cvars()
{
	O_delay = C_delay.FloatValue;
    O_interval = C_interval.FloatValue;
    O_times = C_times.IntValue;
    O_damage = C_damage.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_delay)
	{
		O_delay = C_delay.FloatValue;
	}
	else if(convar == C_interval)
	{
        O_interval = C_interval.FloatValue;
	}
	else if(convar == C_times)
	{
		O_times = C_times.IntValue;
	}
    else if(convar == C_damage)
    {
        O_damage = C_damage.IntValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    Used_timer = new ArrayList();

    HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("player_hurt", event_player_hurt);
    HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);
	HookEvent("map_transition", event_map_transition);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_delay = CreateConVar("si_enhance_hunter_delay", "1.0", "delay to bleed", _, true, 0.1);
	C_delay.AddChangeHook(convar_changed);
    C_interval = CreateConVar("si_enhance_hunter_interval", "1.0", "interval of bleed", _, true, 0.1);
    C_interval.AddChangeHook(convar_changed);
    C_times = CreateConVar("si_enhance_hunter_times", "5", "times to bleed", _, true, 1.0);
    C_times.AddChangeHook(convar_changed);
    C_damage = CreateConVar("si_enhance_hunter_damage", "1", "damage of bleed per time", _, true, 1.0);
    C_damage.AddChangeHook(convar_changed);
	CreateConVar("si_enhance_hunter_version", PLUGIN_VERSION, "version of SI Enhance Hunter", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_hunter");
	get_all_cvars();
}
