#define PLUGIN_VERSION	"2.1"
#define PLUGIN_NAME		"Level Start Heal"
#define PLUGIN_PREFIX	"level_start_heal"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340158"
};

ConVar C_buffer_decay_rate;
float O_buffer_decay_rate;
ConVar C_health;
int O_health;

bool Late_load;

bool First_time[MAXPLAYERS+1];

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

void heal_player(int client)
{
    int health = GetClientHealth(client);
    if(health < O_health)
    {
        float buffer = get_temp_health(client) + float(health) - float(O_health);
		set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
        SetEntityHealth(client, O_health);
    }
    SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
    SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);  
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
}

public void OnClientDisconnect_Post(int client)
{
	First_time[client] = true;
}

void next_frame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client != 0 && First_time[client] && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
	{
		First_time[client] = false;
		heal_player(client);
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(next_frame, event.GetInt("userid"));
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		First_time[client] = true;
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		First_time[client] = false;
	}
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		First_time[client] = false;
	}
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
	{
		First_time[client] = false;
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MAXPLAYERS; client++)
	{
        First_time[client] = true;
	}
}

void data_trans(int client, int prev)
{
	First_time[client] = First_time[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void get_cvars()
{
	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
    O_health = C_health.IntValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);
    HookEvent("round_start", event_round_start);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_buffer_decay_rate.AddChangeHook(convar_changed);
    C_health = CreateConVar("level_start_heal_health", "100", "how many health to heal on level start", _, true, 1.0);
	C_health.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_cvars();

	if(Late_load)
	{
		for(int client = 1; client <= MAXPLAYERS; client++)
		{
			if(client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
			{
				First_time[client] = true;
			}
		}
	}
}