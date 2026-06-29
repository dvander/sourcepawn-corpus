#define PLUGIN_VERSION	"3.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

#define _QueuedPummel_Attacker	8

#define RESPAWN_SURVIVOR_STATUS_PINNED      (1 << 0)
#define RESPAWN_SURVIVOR_STATUS_DOWN        (1 << 1)
#define RESPAWN_SURVIVOR_STATUS_IN_AIR      (1 << 2)
#define RESPAWN_SURVIVOR_STATUS_DANGER_ZONE (1 << 3)

#define RESPAWN_REPRINT_TYPE_CENTER    1
#define RESPAWN_REPRINT_TYPE_HINT      2

public Plugin myinfo =
{
	name = "Survivor Auto Respawn",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347163"
};

enum struct Respawn_target_t
{
    int client;
    int status;
}

GlobalForward Forward_OnRespanwed;

ConVar C_time;
int O_time;
ConVar C_time_pre_delay;
float O_time_pre_delay;
ConVar C_godframe_time;
float O_godframe_time;
ConVar C_health;
int O_health;
ConVar C_print_type;
int O_print_type;
ConVar C_health_buffer;
float O_health_buffer;
ConVar C_health_revive_count;
int O_health_revive_count;
ConVar C_health_going_to_die;
bool O_health_going_to_die;
ConVar C_idle_time;
float O_idle_time;
ConVar C_penalty_per_respawn;
int O_penalty_per_respawn;
ConVar C_penalty_max;
int O_penalty_max;

bool Lib_l4d_heartbeat;

int Offset_QueuedPummelVictim;

bool Started;

bool Got_config;

Handle H_respawn[MAXPLAYERS+1];
int Respawn_time[MAXPLAYERS+1];
int Respawn_count[MAXPLAYERS+1];
Handle H_idle[MAXPLAYERS+1];
ArrayList Used_timer;

public void OnLibraryAdded(const char[] name)
{
    if(strcmp(name, "l4d_heartbeat") == 0)
    {
        Lib_l4d_heartbeat = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if(strcmp(name, "l4d_heartbeat") == 0)
    {
        Lib_l4d_heartbeat = false;
    }
} 

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

int get_special_infected_attacker(int client)
{
    int attacker = -1;
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
    attacker = GetEntDataEnt2(client, Offset_QueuedPummelVictim + _QueuedPummel_Attacker);
    if(attacker > 0)
    {
        return attacker;
    }
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	return -1;
}

bool is_player_falling(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

public void OnMapStart()
{
	Started = true;
    reset_all(false);
}

public void OnMapEnd()
{
    Started = false;
    reset_all(false);
}

void reset_player(int client, bool count)
{
	Respawn_time[client] = 0;
    if(count)
    {
        Respawn_count[client] = 0;
    }
}

void reset_idle(int client)
{
    delete H_idle[client];
}

void reset_all(bool end_msg)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            if(end_msg && Respawn_time[client] > 0 && !IsFakeClient(client) && GetClientTeam(client) == 2 && !IsPlayerAlive(client))
            {
                switch(O_print_type)
                {
                    case RESPAWN_REPRINT_TYPE_CENTER:
                    {
                        PrintCenterText(client, "%T", "respawn_gameover", client);
                    }
                    case RESPAWN_REPRINT_TYPE_HINT:
                    {
                        PrintHintText(client, "%T", "respawn_gameover", client);
                    }
                }
            }
            reset_player(client, true);
            reset_idle(client);
        }
    }
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

bool is_player_hanging(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_in_trigger_hurt(int client)
{
    int trigger = -1;
    while((trigger = FindEntityByClassname(trigger, "trigger_hurt")) != -1)
    {
        if(L4D_IsTouchingTrigger(trigger, client))
        {
            return true;
        }
    }
    return false;
}

int get_random_survivor(int client, bool& in_danger_zone)
{
    Respawn_target_t[] data = new Respawn_target_t[MaxClients];
    int total = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            data[total].client = i;
            data[total].status = 0;

            if(is_player_falling(i) || is_in_trigger_hurt(i))
            {
                data[total].status |= RESPAWN_SURVIVOR_STATUS_DANGER_ZONE;
            }
            if(get_special_infected_attacker(i) != -1)
            {
                data[total].status |= RESPAWN_SURVIVOR_STATUS_PINNED;
            }
            if(GetEntPropEnt(i, Prop_Send, "m_hGroundEntity") == -1)
            {
                data[total].status |= RESPAWN_SURVIVOR_STATUS_IN_AIR;
            }

            if(!is_player_alright(i))
            {
                if(is_player_hanging(i))
                {
                    data[total].status |= RESPAWN_SURVIVOR_STATUS_DANGER_ZONE;
                }
                else
                {
                    data[total].status |= RESPAWN_SURVIVOR_STATUS_DOWN;
                }
            }
            total++;
        }
    }
    for(int i = 0; i < total - 1; i++)
    {
        bool swaped = false;
        for(int j = 0; j < total - 1 - i; j++)
        {
            if(data[j].status > data[j + 1].status)
            {
                swaped = true;
                Respawn_target_t temp;
                temp = data[j];
                data[j] = data[j + 1];
                data[j + 1] = temp;
            }
        }
        if(!swaped)
        {
            break;
        }
    }
    int count = 0;
    for(int i = 0; i < total; i++)
    {
        if(count == 0)
        {
            count++;
        }
        else
        {
            if(data[i].status != data[0].status)
            {
                break;
            }
            else
            {
                count++;
            }
        }
    }
    if(count > 0)
    {
        int index = GetRandomInt(0, count - 1);
        in_danger_zone = !!(data[index].status & RESPAWN_SURVIVOR_STATUS_DANGER_ZONE);
        return data[index].client;
    }
    return 0;
}

public void OnClientDisconnect_Post(int client)
{
    H_respawn[client] = null;
    reset_idle(client);
    if(!Started)
    {
        return;
    }
    reset_player(client, true);
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(H_idle[client] && (buttons != 0 || impulse != 0 || weapon != 0) && IsClientInGame(client))
    {
        reset_idle(client);
    }
}

void timer_idle(Handle timer, int client)
{
    H_idle[client] = null;
    if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(i != client && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                L4D_GoAwayFromKeyboard(client);
                return;
            }
        }
    }
}

void respawn_survivor(int client, int rescuer)
{
    int entity = CreateEntityByName("info_survivor_rescue");
    if(entity == -1)
    {
        return;
    }
    float pos[3];
    float ang[3];
    GetClientEyeAngles(rescuer, ang);
    ang[0] = 0.0;
    ang[2] = 0.0;
    GetClientAbsOrigin(rescuer, pos);
    TeleportEntity(entity, pos, ang);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Send, "m_survivor", client);
	AcceptEntityInput(entity, "Rescue", rescuer);
    RemoveEntity(entity);
}

Action timer_respawn(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
    bool repeat = false;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(timer == H_respawn[client])
        {
            if(!Started || !IsClientInGame(client) || GetClientTeam(client) != 2 || IsPlayerAlive(client))
            {
                H_respawn[client] = null;
                continue;
            }
            bool in_danger_zone = false;
            int target = get_random_survivor(client, in_danger_zone);
            if(target == 0)
            {
                H_respawn[client] = null;
                continue;
            }
            if(in_danger_zone)
            {
                repeat = true;
                if(!IsFakeClient(client))
                {
                    switch(O_print_type)
                    {
                        case RESPAWN_REPRINT_TYPE_CENTER:
                        {
                            PrintCenterText(client, "%T", "respawn_waiting_danger_zone", client, Respawn_time[client]);
                        }
                        case RESPAWN_REPRINT_TYPE_HINT:
                        {
                            PrintHintText(client, "%T", "respawn_waiting_danger_zone", client, Respawn_time[client]);
                        }
                    }
                }
                continue;
            }
            Respawn_time[client]--;
            if(Respawn_time[client] > 0)
            {
                repeat = true;
                if(!IsFakeClient(client))
                {
                    switch(O_print_type)
                    {
                        case RESPAWN_REPRINT_TYPE_CENTER:
                        {
                            PrintCenterText(client, "%T", "respawn_waiting", client, Respawn_time[client]);
                        }
                        case RESPAWN_REPRINT_TYPE_HINT:
                        {
                            PrintHintText(client, "%T", "respawn_waiting", client, Respawn_time[client]);
                        }
                    }
                }
            }
            else
            {
                H_respawn[client] = null;
                Respawn_count[client]++;
                respawn_survivor(client, target);
                
                SetEntProp(client, Prop_Send, "m_bDucked", 1);
                SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);

                SetEntityHealth(client, O_health);
                set_temp_health(client, O_health_buffer);
                SetEntProp(client, Prop_Send, "m_isGoingToDie", O_health_going_to_die ? 1 : 0);
                if(Lib_l4d_heartbeat)
                {
                    Heartbeat_SetRevives(client, O_health_revive_count);
                }
                else
                {
                    SetEntProp(client, Prop_Send, "m_currentReviveCount", O_health_revive_count);
                }

                L4D_StopMusic(client, "Event.SurvivorDeath");

                CountdownTimer inv_timer = L4D2Direct_GetInvulnerabilityTimer(client);
                if(inv_timer)
                {
                    CTimer_SetTimestamp(inv_timer, O_godframe_time > 0.0 ? GetGameTime() + O_godframe_time : -1.0);
                }

                if(O_idle_time >= 0.1 && !IsFakeClient(client))
                {
                    reset_idle(client);
                    H_idle[client] = CreateTimer(O_idle_time, timer_idle, client);
                }
                
                Call_StartForward(Forward_OnRespanwed);
                Call_PushCell(client);
                Call_Finish();
            }
        }
    }
    if(repeat)
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
    for(int client = 1; client <= MaxClients; client++)
    {
        if(timer == H_respawn[client])
        {    
            if(!Started || !IsClientInGame(client) || GetClientTeam(client) != 2 || IsPlayerAlive(client))
            {
                H_respawn[client] = null;
                continue;
            }
            bool in_danger_zone = false;
            int target = get_random_survivor(client, in_danger_zone);
            if(target == 0)
            {
                H_respawn[client] = null;
                continue;
            }
            H_respawn[client] = CreateTimer(1.0, timer_respawn, _, TIMER_REPEAT);
            Used_timer.Push(H_respawn[client]);
            Respawn_time[client] = O_time + Respawn_count[client] * O_penalty_per_respawn;
            if(O_penalty_max > 0 && Respawn_time[client] > O_penalty_max)
            {
                Respawn_time[client] = O_penalty_max;
            }
            if(!IsFakeClient(client))
            {
                switch(O_print_type)
                {
                    case RESPAWN_REPRINT_TYPE_CENTER:
                    {
                        PrintCenterText(client, "%T", in_danger_zone ? "respawn_waiting_danger_zone" : "respawn_waiting", client, Respawn_time[client]);
                    }
                    case RESPAWN_REPRINT_TYPE_HINT:
                    {
                        PrintHintText(client, "%T", in_danger_zone ? "respawn_waiting_danger_zone" : "respawn_waiting", client, Respawn_time[client]);
                    }
                }
            }
        }
    }
}

void start_wait(int client)
{
    for(int i = 0; i < Used_timer.Length; i++)
    {
        Handle timer = Used_timer.Get(i);
        bool got = false;
        for(int j = 1; j <= MaxClients; j++)
        {
            if(timer == H_respawn[j])
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
    H_respawn[client] = CreateTimer(O_time_pre_delay, timer_start);
    Used_timer.Push(H_respawn[client]);
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
    {
        reset_idle(client);
        start_wait(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_idle(client);
        if(!Started)
        {
            return;
        }
        if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
        {
            return;
        }
        reset_player(client, true);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_idle(client);
        start_wait(client);
        int idled = get_idled_of_bot(client);
        if(idled > 0 && IsClientInGame(idled))
        {
            Respawn_count[idled] = Respawn_count[client];
            start_wait(idled);
        }
        if(!Started)
        {
            return;
        }
        reset_player(client, false);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    Started = true;
    reset_all(false);
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void data_trans(int client, int prev)
{
    H_respawn[client] = H_respawn[prev];
    Respawn_time[client] = Respawn_time[prev];
    Respawn_count[client] = Respawn_count[prev];
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
    O_time = C_time.IntValue;
    O_time_pre_delay = C_time_pre_delay.FloatValue;
    O_godframe_time = C_godframe_time.FloatValue;
    O_health = C_health.IntValue;
    O_print_type = C_print_type.IntValue;
    O_health_buffer = C_health_buffer.FloatValue;
    O_health_revive_count = C_health_revive_count.IntValue;
    O_health_going_to_die = C_health_going_to_die.BoolValue;
    O_idle_time = C_idle_time.FloatValue;
    O_penalty_per_respawn = C_penalty_per_respawn.IntValue;
    O_penalty_max = C_penalty_max.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_time)
    {
        O_time = C_time.IntValue;
    }
    else if(convar == C_time_pre_delay)
    {
        O_time_pre_delay = C_time_pre_delay.FloatValue;
    }
    else if(convar == C_godframe_time)
    {
        O_godframe_time = C_godframe_time.FloatValue;
    }
    else if(convar == C_health)
    {
        O_health = C_health.IntValue;
    }
    else if(convar == C_print_type)
    {
        O_print_type = C_print_type.IntValue;
    }
    else if(convar == C_health_buffer)
    {
        O_health_buffer = C_health_buffer.FloatValue;
    }
    else if(convar == C_health_revive_count)
    {
        O_health_revive_count = C_health_revive_count.IntValue;
    }
    else if(convar == C_health_going_to_die)
    {
        O_health_going_to_die = C_health_going_to_die.BoolValue;
    }
    else if(convar == C_idle_time)
    {
        O_idle_time = C_idle_time.FloatValue;
    }
    else if(convar == C_penalty_per_respawn)
    {
        O_penalty_per_respawn = C_penalty_per_respawn.IntValue;
    }
    else if(convar == C_penalty_max)
    {
        O_penalty_max = C_penalty_max.IntValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public void OnConfigsExecuted()
{
    if(Got_config)
    {
        return;
    }
    Got_config = true;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!H_respawn[client] && IsClientInGame(client))
        {
            start_wait(client);
        }
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    MarkNativeAsOptional("Heartbeat_SetRevives");
    Forward_OnRespanwed = new GlobalForward("SurvivorAutoRespawn_OnRespawned", ET_Ignore, Param_Cell);
    RegPluginLibrary("survivor_auto_respawn");
    return APLRes_Success;
}

public void OnPluginStart()
{
    Used_timer = new ArrayList();
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    LoadTranslations("survivor_auto_respawn.phrases");

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_time = CreateConVar("survivor_auto_respawn_time", "20", "how long time need to respawn", _, true, 1.0);
    C_time.AddChangeHook(convar_changed);
    C_time_pre_delay = CreateConVar("survivor_auto_respawn_time_pre_delay", "2.0", "pre delay before formal check and message", _, true, 0.1);
    C_time_pre_delay.AddChangeHook(convar_changed);
    C_godframe_time = CreateConVar("survivor_auto_respawn_godframe_time", "2.0", "godframe time after respawn. 0.0 or lower = remove godframe");
    C_godframe_time.AddChangeHook(convar_changed);
    C_health = CreateConVar("survivor_auto_respawn_health", "30", "how many health will get after respawn", _, true, 1.0);
    C_health.AddChangeHook(convar_changed);
    C_print_type = CreateConVar("survivor_auto_respawn_print_type", "2", "print type. 1 = center text, 2 = hint text", _, true, 1.0, true, 2.0);
    C_print_type.AddChangeHook(convar_changed);
    C_health_buffer = CreateConVar("survivor_auto_respawn_health_buffer", "0.0", "how many health buffer will get", _, true, 0.0);
    C_health_buffer.AddChangeHook(convar_changed);
    C_health_revive_count = CreateConVar("survivor_auto_respawn_health_revive_count", "0", "how many revived count will get");
    C_health_revive_count.AddChangeHook(convar_changed);
    C_health_going_to_die = CreateConVar("survivor_auto_respawn_health_going_to_die", "0", "\"m_isGoingToDie\", 1 = set, 0 = remove");
    C_health_going_to_die.AddChangeHook(convar_changed);
    C_idle_time = CreateConVar("survivor_auto_respawn_idle_time", "4.0", "how long time the player will idle if no action after respawn. lower than 0.1 = disable");
    C_idle_time.AddChangeHook(convar_changed);
    C_penalty_per_respawn = CreateConVar("survivor_auto_respawn_penalty_per_respawn", "0", "how many respawn time cost will increase after respawned, reset on new round start. 0 = disable", _, true, 0.0);
    C_penalty_per_respawn.AddChangeHook(convar_changed);
    C_penalty_max = CreateConVar("survivor_auto_respawn_penalty_max", "0", "max respawn time. 0 = no limit", _, true, 0.0);
    C_penalty_max.AddChangeHook(convar_changed);
    CreateConVar("survivor_auto_respawn_version", PLUGIN_VERSION, "version of Survivor Auto Respawn", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "survivor_auto_respawn");
    get_all_cvars();
}
