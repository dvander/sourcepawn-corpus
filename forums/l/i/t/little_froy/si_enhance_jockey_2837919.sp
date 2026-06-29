#define PLUGIN_VERSION  "1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "SI Enhance Jockey",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351214"
};

ConVar C_jump_force_z;
float O_jump_force_z;
ConVar C_interval;
float O_interval;

Handle H_jump_interval[MAXPLAYERS+1];
bool Can_jump[MAXPLAYERS+1];

public void OnClientDisconnect_Post(int client)
{
	reset_player(client);
}

public void OnGameFrame()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 5)
		{
			int victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
			if(victim < 1 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || GetEntPropEnt(victim, Prop_Send, "m_hGroundEntity") == -1)
			{
				continue;
			}
			if(!Can_jump[client])
			{
				if(!H_jump_interval[client])
				{
					H_jump_interval[client] = CreateTimer(O_interval, timer_jump_interval, client);
				}
			}
			else
			{
				Can_jump[client] = false;
				float vel[3];
				GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", vel);
				vel[2] = O_jump_force_z;
				TeleportEntity(victim, .velocity = vel);
			}
		}
	}
}

void timer_jump_interval(Handle timer, int client)
{
	H_jump_interval[client] = null;
	Can_jump[client] = true;
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

void reset_player(int client)
{
    delete H_jump_interval[client];
	Can_jump[client] = false;
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	reset_all();
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

void event_jockey_ride(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_jockey_ride_end(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void get_all_cvars()
{
	O_jump_force_z = C_jump_force_z.FloatValue;
    O_interval = C_interval.FloatValue;
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_jump_force_z)
	{
		O_jump_force_z = C_jump_force_z.FloatValue;
	}
    else if(convar == C_interval)
    {
        O_interval = C_interval.FloatValue;
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
	HookEvent("round_start", event_round_start);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
	HookEvent("jockey_ride", event_jockey_ride);
	HookEvent("jockey_ride_end", event_jockey_ride_end);

    C_jump_force_z = CreateConVar("si_enhance_jockey_jump_force_z", "650.0", "force to jump z axis", _, true, 0.0);
    C_jump_force_z.AddChangeHook(convar_changed);
    C_interval = CreateConVar("si_enhance_jockey_interval", "4.0", "interval to jump", _, true, 0.0);
    C_interval.AddChangeHook(convar_changed);
	CreateConVar("si_enhance_jockey_version", PLUGIN_VERSION, "version of SI Enhance Jockey", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "si_enhance_jockey");
	get_all_cvars();
}
