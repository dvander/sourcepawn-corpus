#define PLUGIN_VERSION	"1.15"
#define PLUGIN_NAME		"SafeRoom Naps"
#define PLUGIN_PREFIX	"saferoom_naps"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "ConnerRia, little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2801063"
};

ConVar C_buffer_decay_rate;
float O_buffer_decay_rate;
ConVar C_health;
int O_health;

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
    float buffer = 0.0;
    bool set_health = false;
    if(!is_survivor_alright(client))
    {
        set_health = true;
        GivePlayerItem(client, "health");
    }
    else
    {
        int health = GetClientHealth(client);
        if(health < O_health)
        {
            set_health = true;
            buffer = get_temp_health(client) + float(health) - float(O_health);
        }
    }
    if(set_health)
    {
        SetEntityHealth(client, O_health);
        set_temp_health(client, buffer < 0.0 ? 0.0 : buffer);
    }
    SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
    SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);  
    SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
    StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            heal_player(client);
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
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("map_transition", event_map_transition);

    C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
    C_buffer_decay_rate.AddChangeHook(convar_changed);
    C_health = CreateConVar(PLUGIN_PREFIX ... "_health", "100", "heal to the value when map transition", _, true, 1.0);
    C_health.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_cvars();
}