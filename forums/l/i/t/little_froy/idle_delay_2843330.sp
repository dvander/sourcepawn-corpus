#define PLUGIN_VERSION	"1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <little_froy_utils_colors>

public Plugin myinfo =
{
	name = "Idle Delay",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352420"
};

ConVar C_value;
char O_value[18];
float O_value_float;

Handle H_idle[MAXPLAYERS+1];

bool Started;

public void OnMapStart()
{
	Started = true;
    reset_all();
}

public void OnMapEnd()
{
    Started = false;
    reset_all();
}

void reset_player(int client)
{
	delete H_idle[client];
}

public void OnClientDisconnect_Post(int client)
{
	if(!Started)
	{
		return;
	}
	reset_player(client);
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

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_player(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    Started = true;
    reset_all();
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

bool other_real_player(int exclude)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client != exclude && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			return true;
		}
	}
	return false;
}

void timer_idle(Handle timer, int client)
{
	H_idle[client] = null;
	if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if(!Started)
		{
			colors_print_to_chat(client, "%T", "idle_failed_round_not_started", client);
		}
		else if(!other_real_player(client))
		{
			colors_print_to_chat(client, "%T", "idle_failed", client);
		}
		else
		{
			L4D_GoAwayFromKeyboard(client);
		}
	}
}

Action on_cmd_idle(int client, const char[] command, int argc)
{
	if(client > 0 && client <= MaxClients && !H_idle[client] && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if(!Started)
		{
			colors_print_to_chat(client, "%T", "idle_failed_round_not_started", client);
		}
		else if(!other_real_player(client))
		{
			colors_print_to_chat(client, "%T", "idle_failed", client);
		}
		else
		{
			colors_print_to_chat(client, "%T", "will_idle", client, O_value);
			H_idle[client] = CreateTimer(O_value_float, timer_idle, client);
		}
	}
	return Plugin_Handled;
}

void get_all_cvars()
{
    C_value.GetString(O_value, sizeof(O_value));
	O_value_float = StringToFloat(O_value);
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_value)
    {
		C_value.GetString(O_value, sizeof(O_value));
		O_value_float = StringToFloat(O_value);
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public void OnPluginStart()
{
    LoadTranslations("idle_delay.phrases");

	AddCommandListener(on_cmd_idle, "go_away_from_keyboard");

	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
	HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);

	C_value = CreateConVar("idle_delay_value", "2.5", "idle delay", _, true, 0.1);
	C_value.AddChangeHook(convar_changed);
    CreateConVar("idle_delay_version", PLUGIN_VERSION, "version of Idle Delay", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "idle_delay");
    get_all_cvars();
}