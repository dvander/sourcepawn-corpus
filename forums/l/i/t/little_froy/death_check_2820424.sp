#define PLUGIN_VERSION	"2.3"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Death Check",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347073"
};

ConVar C_director_no_death_check;

bool Started;

void frame_check()
{
    if(!Started)
    {
        return;
    }
    bool got = false;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            if(IsPlayerAlive(client))
            {
                return;
            }
            got = true;
        }
    }
    if(got)
    {
        Started = false;
        restart_round();
    }
}

void restart_round()
{
	int flag = GetCommandFlags("scenario_end");
	SetCommandFlags("scenario_end", flag & ~(FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY));
	ServerCommand("scenario_end");
	ServerExecute();
	SetCommandFlags("scenario_end", flag);
}

public void OnMapStart()
{
	Started = true;
    C_director_no_death_check.BoolValue = true;
}

public void OnMapEnd()
{
    Started = false;
    C_director_no_death_check.BoolValue = true;
}

public void OnClientDisconnect_Post(int client)
{
    RequestFrame(frame_check);
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    Started = true;
    C_director_no_death_check.BoolValue = true;
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    C_director_no_death_check.BoolValue = true;
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    C_director_no_death_check.BoolValue = true;
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    C_director_no_death_check.BoolValue = true;
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    C_director_no_death_check.BoolValue = true;
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
    RequestFrame(frame_check);
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
    RequestFrame(frame_check);
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
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
    HookEvent("player_death", event_player_death);
    HookEvent("player_team", event_player_team);

    C_director_no_death_check = FindConVar("director_no_death_check");
    CreateConVar("death_check_version", PLUGIN_VERSION, "version of Death Check", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
