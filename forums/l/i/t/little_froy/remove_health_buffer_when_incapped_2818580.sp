#define PLUGIN_VERSION	"1.5"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "Remove Health Buffer When Incapped",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346436"
};

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void set_temp_health(int client, float buffer)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

void remove_health_buffer(int client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !is_player_alright(client))
	{
		set_temp_health(client, 0.0);
	}
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0)
	{
		remove_health_buffer(client);
	}
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0)
	{
		remove_health_buffer(client);
	}
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
    HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);

	CreateConVar("remove_health_buffer_when_incapped_version", PLUGIN_VERSION, "version of Remove Health Buffer When Incapped", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	for(int client = 1; client <= MaxClients; client++)
	{
		remove_health_buffer(client);
	}
}
