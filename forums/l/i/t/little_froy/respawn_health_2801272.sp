#define PLUGIN_VERSION	"1.3"
#define PLUGIN_NAME		"Respawn Health of Defibrillator/Rescue"
#define PLUGIN_PREFIX   "respawn_health"

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
	url = "https://forums.alliedmods.net/showthread.php?t=342192"
};

ConVar C_health_defib;
int O_health_defib;
ConVar C_health_rescue;
int O_health_rescue;

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
        SetEntityHealth(client, O_health_defib);
    }
}

void event_survivor_rescued(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
        SetEntityHealth(client, O_health_rescue);
    }
}

void get_cvars()
{
	O_health_defib = C_health_defib.IntValue;
    O_health_rescue = C_health_rescue.IntValue;
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
    HookEvent("defibrillator_used", event_defibrillator_used);
    HookEvent("survivor_rescued", event_survivor_rescued);

    C_health_defib = CreateConVar(PLUGIN_PREFIX ... "_defib", "30", "how many health will get after defibrillator used", _, true, 1.0);
    C_health_defib.AddChangeHook(convar_changed);
    C_health_rescue = CreateConVar(PLUGIN_PREFIX ... "_rescue", "30", "how many health will get after rescued", _, true, 1.0);
    C_health_rescue.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_cvars();
}