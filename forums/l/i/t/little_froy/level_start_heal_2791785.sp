#define PLUGIN_VERSION	"3.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

#define LITTLE_FROY_INTEGER_MAX	0x7FFFFFFF

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = "Level Start Heal",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340158"
};

GlobalForward Forward_OnHealed;

ConVar C_pain_pills_decay_rate;
float O_pain_pills_decay_rate;
ConVar C_health;
int O_health;

bool Lib_l4d_heartbeat;

int G_heal_id = -1;
int Heal_id[MAXPLAYERS+1] = {-1, ...};
bool First_time[MAXPLAYERS+1];

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

public void OnMapStart()
{
    PrecacheSound(SOUND_HEARTBEAT, true);
}

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
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
	if(Lib_l4d_heartbeat)
	{
		Heartbeat_SetRevives(client, 0, false);
	}
	else
	{
    	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	}
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	Call_StartForward(Forward_OnHealed);
	Call_PushCell(client);
	Call_Finish();
}

void reset_player(int client, bool first_time)
{
	First_time[client] = first_time;
	Heal_id[client] = -1;
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client, true);
}

void next_frame(int id)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(id == Heal_id[client])
		{
			Heal_id[client] = -1;
			if(First_time[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
			{
				First_time[client] = false;
				heal_player(client);
			}
		}
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		G_heal_id++;
		if(G_heal_id == LITTLE_FROY_INTEGER_MAX)
		{
			G_heal_id = 0;
		}
		Heal_id[client] = G_heal_id;
		RequestFrame(next_frame, G_heal_id);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client, false);
		int idled = get_idled_of_bot(client);
		if(idled > 0 && IsClientInGame(idled))
		{
			reset_player(idled, false);
		}
	}
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client, false);
	}
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client, false);
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
	Heal_id[client] = Heal_id[prev];
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
	O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
    O_health = C_health.IntValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_pain_pills_decay_rate)
	{
		O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
	}
	else if(convar == C_health)
	{
		O_health = C_health.IntValue;
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
	MarkNativeAsOptional("Heartbeat_SetRevives"); 
	Forward_OnHealed = new GlobalForward("LevelStartHeal_OnHealed", ET_Ignore, Param_Cell);
	RegPluginLibrary("level_start_heal");
    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);
    HookEvent("round_start", event_round_start);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	C_pain_pills_decay_rate.AddChangeHook(convar_changed);
    C_health = CreateConVar("level_start_heal_health", "100", "how many health to heal on level start", _, true, 1.0);
	C_health.AddChangeHook(convar_changed);
	CreateConVar("level_start_heal_version", PLUGIN_VERSION, "version of Level Start Heal", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, "level_start_heal");
	get_all_cvars();

	for(int client = 1; client <= MAXPLAYERS; client++)
	{
		if(client > MaxClients || !IsClientInGame(client))
		{
			First_time[client] = true;
		}
	}
}
