#define PLUGIN_VERSION	"1.4"
#define PLUGIN_NAME		"Medicine Health Buffer"
#define PLUGIN_PREFIX	"medicine_health_buffer"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define MEDICINE_PILLS		(1 << 0)
#define MEDICINE_ADRENALINE	(1 << 1)
#define MEDICINE_MEDKIT		(1 << 2)

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342781"
};

ConVar C_enable;
int O_enable;
ConVar C_buffer_decay_rate;
float O_buffer_decay_rate;
ConVar C_max_health_pills;
float O_max_health_pills;
ConVar C_max_health_adrenaline;
float O_max_health_adrenaline;
ConVar C_max_health_medkit;
float O_max_health_medkit;

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

void extra_heal(int client, float max)
{
	float health = float(GetClientHealth(client));
	if(health + get_temp_health(client) < max)
	{
		set_temp_health(client, max - health);
	}
}

void event_pills_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_enable & MEDICINE_PILLS))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		extra_heal(client, O_max_health_pills);
    }
}

void event_adrenaline_used(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_enable & MEDICINE_ADRENALINE))
	{
		return;
	}
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		extra_heal(client, O_max_health_adrenaline);
    }
}

void event_heal_success(Event event, const char[] name, bool dontBroadcast)
{
	if(!(O_enable & MEDICINE_MEDKIT))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("subject"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
    {
		extra_heal(client, O_max_health_medkit);
    }
}

void get_cvars()
{
	O_buffer_decay_rate = C_buffer_decay_rate.FloatValue;
	O_max_health_pills = C_max_health_pills.FloatValue;
	O_max_health_adrenaline = C_max_health_adrenaline.FloatValue;
	O_max_health_medkit = C_max_health_medkit.FloatValue;
	O_enable = C_enable.IntValue;
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
    HookEvent("pills_used", event_pills_used);
    HookEvent("adrenaline_used", event_adrenaline_used);
	HookEvent("heal_success", event_heal_success);

	C_buffer_decay_rate = FindConVar("pain_pills_decay_rate");
	C_buffer_decay_rate.AddChangeHook(convar_changed);
	C_max_health_pills = CreateConVar(PLUGIN_PREFIX ... "_max_health_pills", "80.2", "if pain pills used health lower than this value, add health buffer to it", _, true, 1.0);
	C_max_health_pills.AddChangeHook(convar_changed);
	C_max_health_adrenaline = CreateConVar(PLUGIN_PREFIX ... "_max_health_adrenaline", "55.2", "if adrenaline used health lower than this value, add health buffer to it", _, true, 1.0);
	C_max_health_adrenaline.AddChangeHook(convar_changed);
	C_max_health_medkit = CreateConVar(PLUGIN_PREFIX ... "_max_health_medkit", "100.2", "if first aid kit used health lower than this value, add health buffer to it", _, true, 1.0);
	C_max_health_medkit.AddChangeHook(convar_changed);
	C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "3", "0 = disable, 1 = enable pain pills, 2 = enable adrenaline, 4 = enable first aid kit. add numbers together", _, true, 0.0, true, 7.0);
	C_enable.AddChangeHook(convar_changed);	
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_cvars();
}