#define PLUGIN_VERSION	"1.2"
#define PLUGIN_NAME		"Revive Health Buffer"
#define PLUGIN_PREFIX   "revive_health_buffer"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342905"
};

ConVar C_value;
float O_value;

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

void event_revive_success(Event event, const char[] name, bool dontBroadcast)
{
    if(event.GetInt("ledge_hang"))
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
        set_temp_health(client, O_value);
    }
}

void get_cvars()
{
    O_value = C_value.FloatValue;
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
    HookEvent("revive_success", event_revive_success);

    C_value = CreateConVar(PLUGIN_PREFIX ... "_value", "29.2", "how many health buffer will get after revived from down?", _, true, 0.0);
    C_value.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_cvars();
}