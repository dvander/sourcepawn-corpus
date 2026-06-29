#define PLUGIN_VERSION	"1.24"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Automatic Healing Real Health Edition",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344086"
};

GlobalForward Forward_OnGameStart;
GlobalForward Forward_OnGameEnd;
GlobalForward Forward_OnHealed;

ConVar C_pain_pills_decay_rate;
float O_pain_pills_decay_rate;
ConVar C_interrupt_on_hurt;
bool O_interrupt_on_hurt;
ConVar C_wait_time;
float O_wait_time;
ConVar C_health;
int O_health;
ConVar C_max;
int O_max;
ConVar C_repeat_interval;
float O_repeat_interval;
ConVar C_replace_health_buffer;
bool O_replace_health_buffer;
ConVar C_min;
int O_min;

bool Started;

Handle H_heal[MAXPLAYERS+1];
ArrayList Used_timer;

void change_game_status(bool start)
{
	Started = start;
	reset_all();
	Call_StartForward(start ? Forward_OnGameStart : Forward_OnGameEnd);
	Call_Finish();
}

public void OnMapStart()
{
	change_game_status(true);
}

public void OnMapEnd()
{
	change_game_status(false);
}

void reset_all()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			end_heal(client);
		}
	}
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

float get_temp_health(int client)
{
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * O_pain_pills_decay_rate;
	return buffer < 0.0 ? 0.0 : buffer;
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

void end_heal(int client)
{
	H_heal[client] = null;
}

public void OnGameFrame()
{
	if(!Started)
	{
		return;
	}
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!H_heal[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
		{
			int health = GetClientHealth(client);
			if(health >= O_min && health < O_max)
			{
				for(int i = 0; i < Used_timer.Length; i++)
				{
					Handle timer = Used_timer.Get(i);
					bool got = false;
					for(int j = 1; j <= MaxClients; j++)
					{
						if(timer == H_heal[j])
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
				H_heal[client] = CreateTimer(O_wait_time, timer_start);
				Used_timer.Push(H_heal[client]);
			}
		}
	}
}

void remove_overflowed_health(int client, float health, float buffer)
{
	float max = float(GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	if(health + buffer > max)
	{
		buffer = max - health;
		set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
	}
}

bool heal(Handle timer, bool start)
{
	bool repeat = false;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(timer == H_heal[client])
		{
			if(!Started || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_player_alright(client))
			{
				end_heal(client);
				continue;
			}
			int health = GetClientHealth(client);
			if(health < O_min || health >= O_max)
			{
				end_heal(client);
				continue;
			}
			int amount = 0;
			float buffer = get_temp_health(client);
			if(health + O_health < O_max)
			{
				repeat = true;
				if(start)
				{
					H_heal[client] = CreateTimer(O_repeat_interval, timer_repeat, _, TIMER_REPEAT);
					Used_timer.Push(H_heal[client]);
				}
				amount = O_health;
				SetEntityHealth(client, health + O_health);
				if(buffer > 0.0)
				{
					if(O_replace_health_buffer)
					{
						buffer -= float(O_health);
						set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
					}
					else
					{
						remove_overflowed_health(client, float(health + O_health), buffer);
					}
				}
			}
			else
			{
				amount = O_max - health;
				end_heal(client);
				SetEntityHealth(client, O_max);
				if(buffer > 0.0)
				{
					if(O_replace_health_buffer)
					{
						buffer -= float(O_max) - float(health);
						set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
					}
					else
					{
						remove_overflowed_health(client, float(O_max), buffer);
					}
				}
			}
			if(GetEntProp(client, Prop_Send, "m_isGoingToDie"))
			{
				SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			}
			Call_StartForward(Forward_OnHealed);
			Call_PushCell(client);
			Call_PushCell(amount);
			Call_Finish();
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
	if(heal(timer, false))
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
	heal(timer, true);
}

public void OnClientDisconnect_Post(int client)
{
	if(!Started)
	{
		return;
	}
	end_heal(client);
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
		end_heal(client);
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
		end_heal(client);
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
		end_heal(client);
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
		end_heal(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	change_game_status(true);
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
	change_game_status(false);
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
	change_game_status(false);
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started || !O_interrupt_on_hurt || event.GetInt("dmg_health") < 1)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		end_heal(client);
	}
}

void data_trans(int client, int prev)
{
	H_heal[client] = H_heal[prev];
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
	O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
	O_interrupt_on_hurt = C_interrupt_on_hurt.BoolValue;
	O_wait_time = C_wait_time.FloatValue;
	O_health = C_health.IntValue;
	O_max = C_max.IntValue;
	O_repeat_interval = C_repeat_interval.FloatValue;
	O_replace_health_buffer = C_replace_health_buffer.BoolValue;
	O_min = C_min.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_pain_pills_decay_rate)
	{
		O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
	}
	else if(convar == C_interrupt_on_hurt)
	{
		O_interrupt_on_hurt = C_interrupt_on_hurt.BoolValue;
	}
	else if(convar == C_wait_time)
	{
		O_wait_time = C_wait_time.FloatValue;
	}
	else if(convar == C_health)
	{
		O_health = C_health.IntValue;
	}
	else if(convar == C_max)
	{
		O_max = C_max.IntValue;
	}
	else if(convar == C_repeat_interval)
	{
		O_repeat_interval = C_repeat_interval.FloatValue;
	}
	else if(convar == C_replace_health_buffer)
	{
		O_replace_health_buffer = C_replace_health_buffer.BoolValue;
	}
	else if(convar == C_min)
	{
		O_min = C_min.IntValue;
	}
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

any native_AutomaticHealingR_WaitToHeal(Handle plugin, int numParams)
{
	if(!Started)
	{
		return 0;
	}
	end_heal(GetNativeCell(1));
	return 0;
}

any native_AutomaticHealingR_HasGameStart(Handle plugin, int numParams)
{
	return Started;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
	Forward_OnGameStart = new GlobalForward("AutomaticHealingR_OnGameStart", ET_Ignore);
	Forward_OnGameEnd = new GlobalForward("AutomaticHealingR_OnGameEnd", ET_Ignore);
	Forward_OnHealed = new GlobalForward("AutomaticHealingR_OnHealed", ET_Ignore, Param_Cell, Param_Cell);
    CreateNative("AutomaticHealingR_WaitToHeal", native_AutomaticHealingR_WaitToHeal);
	CreateNative("AutomaticHealingR_HasGameStart", native_AutomaticHealingR_HasGameStart);
    RegPluginLibrary("automatic_healingr");
    return APLRes_Success;
}

public void OnPluginStart()
{
	Used_timer = new ArrayList();

	HookEvent("player_team", event_player_team);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);
	HookEvent("round_start", event_round_start);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("map_transition", event_map_transition);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	C_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	C_pain_pills_decay_rate.AddChangeHook(convar_changed);
	C_interrupt_on_hurt = CreateConVar("automatic_healingr_interrupt_on_hurt", "1", "1 = enable, 0 = disable. interrupt healing on hurt?");
	C_interrupt_on_hurt.AddChangeHook(convar_changed);
	C_wait_time = CreateConVar("automatic_healingr_wait_time", "5.0", "how long time need to wait after the interruption to start healing", _, true, 0.1);
	C_wait_time.AddChangeHook(convar_changed);
	C_health = CreateConVar("automatic_healingr_health", "1", "how many health heal once", _, true, 1.0);
	C_health.AddChangeHook(convar_changed);
	C_repeat_interval = CreateConVar("automatic_healingr_repeat_interval", "1.0", "repeat interval after healing start", _, true, 0.1);
	C_repeat_interval.AddChangeHook(convar_changed);
	C_max = CreateConVar("automatic_healingr_max", "30", "max health of healing");
	C_max.AddChangeHook(convar_changed);
	C_replace_health_buffer = CreateConVar("automatic_healingr_replace_health_buffer", "0", " 0 = disable, 1 = replace health buffer when healing");
	C_replace_health_buffer.AddChangeHook(convar_changed);
	C_min = CreateConVar("automatic_healingr_min", "1", "how many real health required to start automatic healing");
	C_min.AddChangeHook(convar_changed);
	CreateConVar("automatic_healingr_version", PLUGIN_VERSION, "version of Automatic Healing Real Health Edition", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "automatic_healingr");
	get_all_cvars();
}
