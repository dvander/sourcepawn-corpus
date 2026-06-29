#define PLUGIN_VERSION	"1.6"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Revive Health Buffer",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342905"
};

GlobalForward Forward_OnSetReviveHealth;

ConVar C_value;
float O_value;

bool is_player_alright(int client)
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
    if(event.GetBool("ledge_hang"))
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
    {
        set_temp_health(client, O_value);
        Call_StartForward(Forward_OnSetReviveHealth);
        Call_PushCell(client);
        Call_Finish();
    }
}

void get_all_cvars()
{
    O_value = C_value.FloatValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_value)
    {
        O_value = C_value.FloatValue;
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
	Forward_OnSetReviveHealth = new GlobalForward("ReviveHealthBuffer_OnSetReviveHealth", ET_Ignore, Param_Cell);
	RegPluginLibrary("revive_health_buffer");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("revive_success", event_revive_success);

    C_value = CreateConVar("revive_health_buffer_value", "29.3", "how many health buffer will get after revived from down?", _, true, 0.0);
    C_value.AddChangeHook(convar_changed);
    CreateConVar("revive_health_buffer_version", PLUGIN_VERSION, "version of Revive Health Buffer", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "revive_health_buffer");
    get_all_cvars();
}
