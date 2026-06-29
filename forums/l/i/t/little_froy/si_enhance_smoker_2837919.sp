#define PLUGIN_VERSION  "1.7"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "SI Enhance Smoker",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_delay;
float O_delay;
ConVar C_interval;
float O_interval;
ConVar C_damage_normal;
int O_damage_normal;
ConVar C_damage_down;
int O_damage_down;
ConVar C_damage_ledge;
int O_damage_ledge;

Handle H_drag[MAXPLAYERS+1];
ArrayList Used_timer;

bool is_player_hanging(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

bool drag_damage(Handle timer, bool start)
{
    bool repeat = false;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(timer == H_drag[client])
        {
			if(!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || GetEntPropEnt(client, Prop_Send, "m_tongueOwner") == -1 || GetEntProp(client, Prop_Send, "m_reachedTongueOwner"))
			{
				reset_player(client);
                continue;
			}
            repeat = true;
            if(start)
            {
                H_drag[client] = CreateTimer(O_interval, timer_repeat, _, TIMER_REPEAT);
                Used_timer.Push(H_drag[client]);
            }
            float damage = 0.0;
            if(is_player_alright(client))
            {
                damage = float(O_damage_normal);
            }
            else if(is_player_hanging(client))
            {
                damage = float(O_damage_ledge);
            }
            else
            {
                damage = float(O_damage_down);
            }
			float time_stamp = -1.0;
        	CountdownTimer inv_timer = L4D2Direct_GetInvulnerabilityTimer(client);
			if(inv_timer)
			{
				time_stamp = CTimer_GetTimestamp(inv_timer);
				CTimer_SetTimestamp(inv_timer, -1.0);
			}
            SDKHooks_TakeDamage(client, client, client, damage);
			if(inv_timer)
			{
				CTimer_SetTimestamp(inv_timer, time_stamp);
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
	if(drag_damage(timer, false))
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
    drag_damage(timer, true);
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

void reset_player(int client)
{
    H_drag[client] = null;
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
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
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_tongue_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
        for(int i = 0; i < Used_timer.Length; i++)
        {
            Handle timer = Used_timer.Get(i);
            bool got = false;
            for(int j = 1; j <= MaxClients; j++)
            {
                if(timer == H_drag[j])
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
        H_drag[client] = CreateTimer(O_delay, timer_start);
        Used_timer.Push(H_drag[client]);
	}
}

void event_tongue_release(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void data_trans(int client, int prev)
{
    H_drag[client] = H_drag[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
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
    O_damage_normal = C_damage_normal.IntValue;
    O_damage_down = C_damage_down.IntValue;
    O_damage_ledge = C_damage_ledge.IntValue;
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
    else if(convar == C_damage_normal)
    {
        O_damage_normal = C_damage_normal.IntValue;
    }
    else if(convar == C_damage_down)
    {
        O_damage_down = C_damage_down.IntValue;
    }
    else if(convar == C_damage_ledge)
    {
        O_damage_ledge = C_damage_ledge.IntValue;
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

	HookEvent("round_start", event_round_start);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
    HookEvent("tongue_grab", event_tongue_grab);
    HookEvent("tongue_release", event_tongue_release);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_delay = CreateConVar("si_enhance_smoker_delay", "0.6", "start wait of damage", _, true, 0.1);
    C_delay.AddChangeHook(convar_changed);
    C_interval = CreateConVar("si_enhance_smoker_interval", "0.6", "interval of damage", _, true, 0.1);
    C_interval.AddChangeHook(convar_changed);
    C_damage_normal = CreateConVar("si_enhance_smoker_damage_normal", "1", "damage per time to normal state", _, true, 1.0);
    C_damage_normal.AddChangeHook(convar_changed);
    C_damage_down = CreateConVar("si_enhance_smoker_damage_down", "3", "damage per time to down state", _, true, 1.0);
    C_damage_down.AddChangeHook(convar_changed);
    C_damage_ledge = CreateConVar("si_enhance_smoker_damage_ledge", "3", "damage per time to ledge state", _, true, 1.0);
    C_damage_ledge.AddChangeHook(convar_changed);
	CreateConVar("si_enhance_smoker_version", PLUGIN_VERSION, "version of SI Enhance Smoker", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_smoker");
	get_all_cvars();
}
