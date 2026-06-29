#define PLUGIN_VERSION	"2.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <survivor_auto_respawn>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Respawn As Incapacitated",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347163"
};

ConVar C_godframe_time;
float O_godframe_time;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_player_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

public void SurvivorAutoRespawn_OnRespawned(int client)
{
    if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_alright(client) && !is_player_on_thirdstrike(client))
    {
        SetEntityHealth(client, 1);
        set_temp_health(client, 0.0);
        CountdownTimer inv_timer = L4D2Direct_GetInvulnerabilityTimer(client);
        if(inv_timer)
        {
            CTimer_SetTimestamp(inv_timer, -1.0);
        }
        SDKHooks_TakeDamage(client, 0, 0, 5.0);
        if(inv_timer && O_godframe_time > 0.0)
        {
            CTimer_SetTimestamp(inv_timer, GetGameTime() + O_godframe_time);
        }
    }
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_godframe_time)
    {
        O_godframe_time = C_godframe_time.FloatValue;
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
    CreateConVar("respawn_as_incapacitated_version", PLUGIN_VERSION, "version of Respawn As Incapacitated", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public void OnAllPluginsLoaded()
{
    if(!C_godframe_time)
    {
        C_godframe_time = FindConVar("survivor_auto_respawn_godframe_time");
        if(C_godframe_time)
        {
            C_godframe_time.AddChangeHook(convar_changed);
            get_single_cvar(C_godframe_time);
        }
    }
}