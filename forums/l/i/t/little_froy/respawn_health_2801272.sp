#define PLUGIN_VERSION	"2.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

#define ENABLE_HEALTH_DEFIB     (1 << 0)
#define ENABLE_HEALTH_RESCUE    (1 << 1)

public Plugin myinfo =
{
	name = "Respawn Health of Defibrillator/Rescue",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342192"
};

GlobalForward Forward_OnSetRescueHealth;
GlobalForward Forward_OnSetDefibrillatorHealth;

ConVar C_enable;
int O_enable;

ConVar C_defib_health_true;
int O_defib_health_true;
ConVar C_defib_health_buffer;
float O_defib_health_buffer;
ConVar C_defib_dying;
bool O_defib_dying;
ConVar C_defib_revive_count;
int O_defib_revive_count;

ConVar C_rescue_health_true;
int O_rescue_health_true;
ConVar C_rescue_health_buffer;
float O_rescue_health_buffer;
ConVar C_rescue_dying;
bool O_rescue_dying;
ConVar C_rescue_revive_count;
int O_rescue_revive_count;

bool Lib_l4d_heartbeat;

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

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

void event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)
{
    if(!(O_enable & ENABLE_HEALTH_DEFIB))
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
    {
        SetEntityHealth(client, O_defib_health_true);
        set_temp_health(client, O_defib_health_buffer);
        if(O_defib_dying)
        {
            SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
        }
        if(Lib_l4d_heartbeat)
        {
            Heartbeat_SetRevives(client, O_defib_revive_count);
        }
        else
        {
            SetEntProp(client, Prop_Send, "m_currentReviveCount", O_defib_revive_count);
        }
        Call_StartForward(Forward_OnSetDefibrillatorHealth);
        Call_PushCell(client);
        Call_Finish();
    }
}

void event_survivor_rescued(Event event, const char[] name, bool dontBroadcast)
{
    if(!(O_enable & ENABLE_HEALTH_RESCUE))
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("victim"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client))
    {
        SetEntityHealth(client, O_rescue_health_true);
        set_temp_health(client, O_rescue_health_buffer);
        if(O_rescue_dying)
        {
            SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
        }
        if(Lib_l4d_heartbeat)
        {
            Heartbeat_SetRevives(client, O_rescue_revive_count);
        }
        else
        {
            SetEntProp(client, Prop_Send, "m_currentReviveCount", O_rescue_revive_count);
        }
        Call_StartForward(Forward_OnSetRescueHealth);
        Call_PushCell(client);
        Call_Finish();
    }
}

void get_all_cvars()
{
    O_enable = C_enable.IntValue;

    O_defib_health_true = C_defib_health_true.IntValue;
    O_defib_health_buffer = C_defib_health_buffer.FloatValue;
    O_defib_dying = C_defib_dying.BoolValue;
    O_defib_revive_count = C_defib_revive_count.IntValue;

    O_rescue_health_true = C_rescue_health_true.IntValue;
    O_rescue_health_buffer = C_rescue_health_buffer.FloatValue;
    O_rescue_dying = C_rescue_dying.BoolValue;
    O_rescue_revive_count = C_rescue_revive_count.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_enable)
    {
        O_enable = C_enable.IntValue;
    }
    else if(convar == C_defib_health_true)
    {
        O_defib_health_true = C_defib_health_true.IntValue;
    }
    else if(convar == C_defib_health_buffer)
    {
        O_defib_health_buffer = C_defib_health_buffer.FloatValue;
    }
    else if(convar == C_defib_dying)
    {
        O_defib_dying = C_defib_dying.BoolValue;
    }
    else if(convar == C_defib_revive_count)
    {
        O_defib_revive_count = C_defib_revive_count.IntValue;
    }
    else if(convar == C_rescue_health_true)
    {
        O_rescue_health_true = C_rescue_health_true.IntValue;
    }
    else if(convar == C_rescue_health_buffer)
    {
        O_rescue_health_buffer = C_rescue_health_buffer.FloatValue;
    }
    else if(convar == C_rescue_dying)
    {
        O_rescue_dying = C_rescue_dying.BoolValue;
    }
    else if(convar == C_rescue_revive_count)
    {
        O_rescue_revive_count = C_rescue_revive_count.IntValue;
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
    Forward_OnSetRescueHealth = new GlobalForward("RespawnHealth_OnSetRescueHealth", ET_Ignore, Param_Cell);
    Forward_OnSetDefibrillatorHealth = new GlobalForward("RespawnHealth_OnSetDefibrillatorHealth", ET_Ignore, Param_Cell);
    RegPluginLibrary("respawn_health");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("defibrillator_used", event_defibrillator_used);
    HookEvent("survivor_rescued", event_survivor_rescued);

    C_enable = CreateConVar("respawn_health_enable", "3", "1 = enable defib health settings, 2 = enable rescue health settings. add numbers together");
    C_enable.AddChangeHook(convar_changed);

    C_defib_health_true = CreateConVar("respawn_health_defib_health_true", "30", "how many main health will get after defibrillator used", _, true, 1.0);
    C_defib_health_true.AddChangeHook(convar_changed);
    C_defib_health_buffer = CreateConVar("respawn_health_defib_health_buffer", "0.0", "how many health buffer will get after defibrillator used", _, true, 0.0);
    C_defib_health_buffer.AddChangeHook(convar_changed);
    C_defib_dying = CreateConVar("respawn_health_defib_dying", "0", "1 = enable, 0 = disable. set \"m_isGoingToDie\" prop after defibrillator used?");
    C_defib_dying.AddChangeHook(convar_changed);
    C_defib_revive_count = CreateConVar("respawn_health_defib_revive_count", "0", "how many revive count will be set after defibrillator used?", _, true, 0.0);
    C_defib_revive_count.AddChangeHook(convar_changed);

    C_rescue_health_true = CreateConVar("respawn_health_rescue_health_true", "30", "how many main health will get after rescued", _, true, 1.0);
    C_rescue_health_true.AddChangeHook(convar_changed);
    C_rescue_health_buffer = CreateConVar("respawn_health_rescue_health_buffer", "0.0", "how many health buffer will get after rescued", _, true, 0.0);
    C_rescue_health_buffer.AddChangeHook(convar_changed);
    C_rescue_dying = CreateConVar("respawn_health_rescue_dying", "0", "1 = enable, 0 = disable. set \"m_isGoingToDie\" prop after rescued?");
    C_rescue_dying.AddChangeHook(convar_changed);
    C_rescue_revive_count = CreateConVar("respawn_health_rescue_revive_count", "0", "how many revive count will be set after rescued?", _, true, 0.0);
    C_rescue_revive_count.AddChangeHook(convar_changed);

    CreateConVar("respawn_health_version", PLUGIN_VERSION, "version of Respawn Health of Defibrillator/Rescue", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "respawn_health");
    get_all_cvars();
}
