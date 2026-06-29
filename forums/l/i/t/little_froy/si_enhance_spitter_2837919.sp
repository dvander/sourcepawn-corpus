#define PLUGIN_VERSION  "1.7"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#if !defined DMG_RADIATION
	#define DMG_RADIATION               (1 << 18)
#endif

#define _QueuedPummel_Attacker	8

public Plugin myinfo =
{
	name = "SI Enhance Spitter",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_speed_run;
float O_speed_run;
ConVar C_speed_walk;
float O_speed_walk;
ConVar C_speed_crouch;
float O_speed_crouch;
ConVar C_duration;
float O_duration;

Handle H_slow[MAXPLAYERS+1];
ArrayList Used_timer;

int Offset_QueuedPummelVictim;

int get_special_infected_attacker(int client)
{
    int attacker = -1;
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
    attacker = GetEntDataEnt2(client, Offset_QueuedPummelVictim + _QueuedPummel_Attacker);
    if(attacker > 0)
    {
        return attacker;
    }
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	return -1;
}

void reset_player(int client)
{
	H_slow[client] = null;
}

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

Action speed_scale(int target, float& retVal, float scale)
{
    if(target > 0 && target <= MaxClients && H_slow[target] && IsClientInGame(target) && GetClientTeam(target) == 2 && GetEntPropEnt(target, Prop_Send, "m_hGroundEntity") != -1 && get_special_infected_attacker(target) == -1)
    {
        retVal *= scale;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
	return speed_scale(target, retVal, O_speed_crouch);
}

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
    return speed_scale(target, retVal, O_speed_run);
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
    return speed_scale(target, retVal, O_speed_walk);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
}

void timer_end_slow(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
	for(int client = 1; client <= MaxClients; client++)
	{
		if(timer == H_slow[client])
		{
			reset_player(client);
		}
	}
}

void check_damage(Event event)
{
	if(!(event.GetInt("type") & DMG_RADIATION))
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(attacker > 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 4)
		{
			for(int i = 0; i < Used_timer.Length; i++)
			{
				Handle timer = Used_timer.Get(i);
				bool got = false;
				for(int j = 1; j <= MaxClients; j++)
				{
					if(timer == H_slow[j])
					{
						got = true;
						break;
					}
				}
				if(!got)
				{
					Used_timer.Erase(i--);
					delete timer;
				}
			}
			H_slow[client] = CreateTimer(O_duration, timer_end_slow);
			Used_timer.Push(H_slow[client]);
		}
	}
}

void event_player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("dmg_health") < 1)
	{
		return;
	}
	check_damage(event);
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	check_damage(event);
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		if(IsFakeClient(client) && event.GetInt("team") == 1 && event.GetInt("oldteam") == 2)
		{
			return;
		}
		reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void data_trans(int client, int prev)
{
	H_slow[client] = H_slow[prev];
}

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client > 0 && IsClientInGame(client))
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev > 0 && IsClientInGame(prev))
		{
			data_trans(client, prev);
		}
	}
}

void reset_all()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			reset_player(client);
		}
	}
}

void get_all_cvars()
{
	O_speed_run = C_speed_run.FloatValue;
	O_speed_walk = C_speed_walk.FloatValue;
	O_speed_crouch = C_speed_crouch.FloatValue;
	O_duration = C_duration.FloatValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_speed_run)
    {
        O_speed_run = C_speed_run.FloatValue;
    }
	else if(convar == C_speed_walk)
	{
		O_speed_walk = C_speed_walk.FloatValue;
	}
	else if(convar == C_speed_crouch)
	{
		O_speed_crouch = C_speed_crouch.FloatValue;
	}
	else if(convar == C_duration)
	{
        O_duration = C_duration.FloatValue;
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
	MarkNativeAsOptional("L4D_LaggedMovement");
    return APLRes_Success;
}

public void OnPluginStart()
{
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

	Used_timer = new ArrayList();

	HookEvent("round_start", event_round_start);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
    HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_speed_run = CreateConVar("si_enhance_spitter_speed_run", "0.7", "run speed on acid damage", _, true, 0.001);
    C_speed_run.AddChangeHook(convar_changed);
    C_speed_walk = CreateConVar("si_enhance_spitter_speed_walk", "0.8", "walk speed on acid damage", _, true, 0.010);
    C_speed_walk.AddChangeHook(convar_changed);
    C_speed_crouch = CreateConVar("si_enhance_spitter_speed_crouch", "0.8", "crouch speed on acid damage", _, true, 0.010);
    C_speed_crouch.AddChangeHook(convar_changed);
    C_duration = CreateConVar("si_enhance_spitter_duration", "0.5", "duration of speed scale", _, true, 0.1);
    C_duration.AddChangeHook(convar_changed);
	CreateConVar("si_enhance_spitter_version", PLUGIN_VERSION, "version of SI Enhance Spitter", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_spitter");
	get_all_cvars();
}
