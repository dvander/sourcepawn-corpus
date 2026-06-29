#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"SafeRoom Naps"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
native void L4D_ReviveSurvivor(int client);

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "ConnerRia, little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2800870&postcount=13"
};

ConVar C_buffer_decay_rate;
ConVar C_respawn_health;

float O_buffer_decay_rate;
int O_respawn_health;

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
    if(!is_survivor_alright(client))
    {
        L4D_ReviveSurvivor(client);
    }
    int health = GetClientHealth(client);
    if(health < O_respawn_health)
    {
        float buffer = get_temp_health(client) + float(health) - float(O_respawn_health);
        if(buffer < 0.0)
        {
			buffer = 0.0;
        }
		set_temp_health(client, buffer);
        SetEntityHealth(client, O_respawn_health);
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
    O_respawn_health = C_respawn_health.IntValue;
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

public void OnPluginStart()
{
    HookEvent("map_transition", event_map_transition);

    C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
    C_respawn_health = FindConVar("z_survivor_respawn_health");

    CreateConVar("saferoom_naps_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    C_buffer_decay_rate.AddChangeHook(convar_changed);
    C_respawn_health.AddChangeHook(convar_changed);
}