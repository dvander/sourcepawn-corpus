#define PLUGIN_VERSION  "1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "SI Enhance Boomer",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_force_scale;
float O_force_scale;
ConVar C_force_z;
float O_force_z;

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

public Action L4D2_OnStagger(int client, int source)
{
    if(IsClientInGame(client) && GetClientTeam(client) == 2 && source > 0 && source <= MaxClients && IsClientInGame(source) && GetClientTeam(source) == 3 && GetEntProp(source, Prop_Send, "m_zombieClass") == 2)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion)
{
    if(boomerExplosion && victim > 0 && victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim) && is_player_alright(victim) && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 2)
    {
        float survivor_pos[3];
        float boomer_pos[3];
        float force[3];
        GetClientAbsOrigin(victim, survivor_pos);
        GetClientAbsOrigin(attacker, boomer_pos);
        MakeVectorFromPoints(boomer_pos, survivor_pos, force);
        NormalizeVector(force, force);
        ScaleVector(force, O_force_scale);
        force[2] = O_force_z;
        SetEntPropFloat(victim, Prop_Send, "m_staggerTimer", -1.0, 1);
        L4D2_CTerrorPlayer_Fling(victim, attacker, force);
    }
}

void get_all_cvars()
{
    O_force_scale = C_force_scale.FloatValue;
    O_force_z = C_force_z.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_force_scale)
	{
		O_force_scale = C_force_scale.FloatValue;
	}
	else if(convar == C_force_z)
	{
		O_force_z = C_force_z.FloatValue;
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
    C_force_scale = CreateConVar("si_enhance_boomer_force_scale", "250.0", "force scale of fling", _, true, 0.0);
    C_force_scale.AddChangeHook(convar_changed);
    C_force_z = CreateConVar("si_enhance_boomer_force_z", "250.0", "force of fling to z axis", _, true, 0.0);
    C_force_z.AddChangeHook(convar_changed);
	CreateConVar("si_enhance_boomer_version", PLUGIN_VERSION, "version of SI Enhance Boomer", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_boomer");
	get_all_cvars();
}
