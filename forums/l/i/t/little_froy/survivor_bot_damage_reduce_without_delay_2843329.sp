#define PLUGIN_VERSION  "1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Survivor Bot Damage Reduce Without Delay",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352419"
};

ConVar C_percent;
float O_percent;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage_client);
    }
}

Action OnTakeDamage_client(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(damage >= 1.0 && GetClientTeam(victim) == 2 && IsPlayerAlive(victim) && is_player_alright(victim))
    {
        damage *= O_percent;
        if(damage < 1.0)
        {
            damage = 1.0;
        }
        return Plugin_Changed;
    }
	return Plugin_Continue;
}

void get_all_cvars()
{
	O_percent = C_percent.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_percent)
	{
		O_percent = C_percent.FloatValue;
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
    C_percent = CreateConVar("survivor_bot_damage_reduce_without_delay_percent", "0.5", "damage percent to survivor bots. at least keep 1.0 damage", _, true, 0.0, true, 1.0);
    C_percent.AddChangeHook(convar_changed);
    CreateConVar("survivor_bot_damage_reduce_without_delay_version", PLUGIN_VERSION, "version of Survivor Bot Damage Reduce Without Delay", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "survivor_bot_damage_reduce_without_delay");
	get_all_cvars();

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
}