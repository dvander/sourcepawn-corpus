#define PLUGIN_VERSION	"1.5"
#define PLUGIN_NAME		"Automatic Healing Real Health Edtion"
#define PLUGIN_PREFIX	"automatic_healingr"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344086"
};

ConVar C_buffer_decay_rate;
float O_buffer_decay_rate;
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

bool Started;

float Next_heal_time[MAXPLAYERS+1] = {-1.0, ...};

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

void reset_all()
{
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		end_heal(client);
	}
}

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

float get_temp_health(int client)
{
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * O_buffer_decay_rate;
	return buffer < 0.0 ? 0.0 : buffer;
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

void end_heal(int client)
{
	Next_heal_time[client] = -1.0;
}

bool lower_than_heal_max(int client)
{
	return GetClientHealth(client) < O_max;
}

void wait_to_heal(int client)
{
	Next_heal_time[client] = GetEngineTime() + O_wait_time;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if(!Started)
	{
		return;
	}
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
	{
		int health = GetClientHealth(client);
		if(health < O_max)
		{
			if(Next_heal_time[client] < 0.0)
			{
				wait_to_heal(client);
			}
			else if(GetEngineTime() >= Next_heal_time[client])
			{
				float buffer = get_temp_health(client);
				if(health + O_health < O_max)
				{
					SetEntityHealth(client, health + O_health);
					if(buffer > 0.0)
					{
						if(O_replace_health_buffer)
						{
							buffer -= O_health;
							set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
						}
						else
						{
							float max = float(GetEntProp(client, Prop_Data, "m_iMaxHealth"));
							float current_health = float(health + O_health);
							if(current_health + buffer > max)
							{
								buffer = max - current_health;
								set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
							}
						}
					}
					Next_heal_time[client] += O_repeat_interval;
				}
				else
				{
					SetEntityHealth(client, O_max);
					if(buffer > 0.0)
					{
						if(O_replace_health_buffer)
						{
							buffer -= O_max - health;
							set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
						}
						else
						{
							float max = float(GetEntProp(client, Prop_Data, "m_iMaxHealth"));
							float current_health = float(O_max);
							if(current_health + buffer > max)
							{
								buffer = max - current_health;
								set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
							}
						}
					}
					end_heal(client);
				}
				SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			}
		}
		else
		{
			end_heal(client);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
		}
	}
	else
	{
		end_heal(client);
	}
}

public void OnClientDisconnect_Post(int client)
{
	if(!Started)
	{
		return;
	}
	end_heal(client);
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		end_heal(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
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
	if(client != 0)
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
	if(client != 0)
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
	if(client != 0)
	{
		end_heal(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	Started = true;
	reset_all();
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

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started || !O_interrupt_on_hurt || event.GetInt("dmg_health") < 1)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client) && lower_than_heal_max(client))
	{
		wait_to_heal(client);
	}
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev != 0)
		{
			Next_heal_time[client] = Next_heal_time[prev];
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
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev != 0)
		{
			Next_heal_time[client] = Next_heal_time[prev];
		}
	}
}

void get_cvars()
{
	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
	O_interrupt_on_hurt = C_interrupt_on_hurt.BoolValue;
	O_wait_time = C_wait_time.FloatValue;
	O_health = C_health.IntValue;
	O_max = C_max.IntValue;
	O_repeat_interval = C_repeat_interval.FloatValue;
	O_replace_health_buffer = C_replace_health_buffer.BoolValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

any native_AutomaticHealingR_WaitToHeal(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "client index %d is out of bound", client);
	}
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "client index %d is not in game", client);
	}
	if(GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !is_survivor_alright(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "client index %d is not an alive and none-incapacitated survivor", client);
	}
	if(!Started)
	{
		return false;
	}
	if(lower_than_heal_max(client))
	{
		wait_to_heal(client);
		return true;
	}
	else
	{
		return false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    CreateNative("AutomaticHealingR_WaitToHeal", native_AutomaticHealingR_WaitToHeal);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", event_player_spawn);
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

	C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_buffer_decay_rate.AddChangeHook(convar_changed);
	C_interrupt_on_hurt = CreateConVar(PLUGIN_PREFIX ... "_interrupt_on_hurt", "1", "1 = enable, 0 = disable. interrupt healing on hurt?");
	C_interrupt_on_hurt.AddChangeHook(convar_changed);
	C_wait_time = CreateConVar(PLUGIN_PREFIX ... "_wait_time", "5.0", "how long time need to wait after the interruption to start healing", _, true, 0.0);
	C_wait_time.AddChangeHook(convar_changed);
	C_health = CreateConVar(PLUGIN_PREFIX ... "_health", "1", "how many health heal once", _, true, 1.0);
	C_health.AddChangeHook(convar_changed);
	C_repeat_interval = CreateConVar(PLUGIN_PREFIX ... "_repeat_interval", "1.0", "repeat interval after healing start", _, true, 0.0);
	C_repeat_interval.AddChangeHook(convar_changed);
	C_max = CreateConVar(PLUGIN_PREFIX ... "_max", "30", "max health of healing", _, true, 2.0);
	C_max.AddChangeHook(convar_changed);
	C_replace_health_buffer = CreateConVar(PLUGIN_PREFIX ... "_replace_health_buffer", "0", " 0 = disable, 1 = replace health buffer when healing");
	C_replace_health_buffer.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_cvars();
}