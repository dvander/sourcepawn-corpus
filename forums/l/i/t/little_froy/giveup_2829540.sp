#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <little_froy_utils_colors>

public Plugin myinfo =
{
	name = "Giveup",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349486"
};

ConVar C_pain_pills_decay_rate;
float O_pain_pills_decay_rate;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

float get_temp_health(int client)
{
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * O_pain_pills_decay_rate;
	return buffer < 0.0 ? 0.0 : buffer;
}

Action cmd_giveup(int client, int args)
{
    if(client < 1 || client > MaxClients || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    if(GetClientTeam(client) != 2 || !IsPlayerAlive(client) || is_player_alright(client))
    {
        colors_print_to_chat(client, "%T", "not_valid", client);
        return Plugin_Handled;
    }
    CountdownTimer inv_timer = L4D2Direct_GetInvulnerabilityTimer(client);
    if(inv_timer)
    {
        CTimer_SetTimestamp(inv_timer, -1.0);
    }
    SDKHooks_TakeDamage(client, 0, 0, float(GetClientHealth(client)) + get_temp_health(client) + 1.0, DMG_POISON);
    return Plugin_Handled;
}

void get_all_cvars()
{
	O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_pain_pills_decay_rate)
	{
		O_pain_pills_decay_rate = C_pain_pills_decay_rate.FloatValue;
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
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("giveup.phrases");

	C_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	C_pain_pills_decay_rate.AddChangeHook(convar_changed);
    CreateConVar("giveup_version", PLUGIN_VERSION, "version of Giveup", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "giveup");
	get_all_cvars();

    RegConsoleCmd("sm_giveup", cmd_giveup);
}
