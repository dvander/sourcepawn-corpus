#define PLUGIN_VERSION	"2.9"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Rescue Glow",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=348762"
};

ConVar C_color;
int O_color[3];
ConVar C_flash;
bool O_flash;

bool Added[MAXPLAYERS+1];

void set_glow(int entity, int type = 0, const int color[3] = {0, 0, 0}, int range = 0, int range_min = 0, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range_min);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

void add_glow(int client)
{
    Added[client] = true;
    set_glow(client, 3, O_color, .flash = O_flash);
}

void remove_glow(int client)
{
    Added[client] = false;
    set_glow(client);
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!Added[client] && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsPlayerAlive(client))
        {
            int rescue = -1;
            while((rescue = FindEntityByClassname(rescue, "info_survivor_rescue")) != -1)
            {
                if(GetEntPropEnt(rescue, Prop_Send, "m_survivor") == client)
                {
                    add_glow(client);
                    break;
                }
            }
        }
    }
}

void reset_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(Added[client] && IsClientInGame(client))
        {
            remove_glow(client);
        }
    }
}

public void OnClientDisconnect_Post(int client)
{
    Added[client] = false;
}

void event_survivor_rescue_abandoned(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && Added[client] && IsClientInGame(client))
	{
		remove_glow(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && Added[client] && IsClientInGame(client))
	{
		remove_glow(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && Added[client] && IsClientInGame(client))
	{
		remove_glow(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void get_all_cvars()
{
    char buffer[12];
    C_color.GetString(buffer, sizeof(buffer));
    explode_string_to_cell_array(buffer, " ", O_color, sizeof(O_color), 4, StringExplodeType_Int);
    O_flash = C_flash.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_color)
    {
        char buffer[12];
        C_color.GetString(buffer, sizeof(buffer));
        explode_string_to_cell_array(buffer, " ", O_color, sizeof(O_color), 4, StringExplodeType_Int);
    }
    else if(convar == C_flash)
    {
        O_flash = C_flash.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
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
    HookEvent("survivor_rescue_abandoned", event_survivor_rescue_abandoned);
    HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);

    C_color = CreateConVar("rescue_glow_color", "255 102 0", "color of glow, split up with space");
    C_color.AddChangeHook(convar_changed);
    C_flash = CreateConVar("rescue_glow_flash", "1", "1 = enable, 0 = disable. will the glow flash?");
    C_flash.AddChangeHook(convar_changed);
    CreateConVar("rescue_glow_version", PLUGIN_VERSION, "version of Rescue Glow", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "rescue_glow");
    get_all_cvars();
}

public void OnPluginEnd()
{
    reset_all();
}
