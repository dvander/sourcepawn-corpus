#define PLUGIN_VERSION  "4.8"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Thirdstrike Glow",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/Should_add_glowthread.php?t=340159"
};

ConVar C_color;
int O_color[3];
ConVar C_range;
int O_range;
ConVar C_range_min;
int O_range_min;
ConVar C_through_wall;
bool O_through_wall;
ConVar C_flash;
bool O_flash;
ConVar C_pulse_duration;
float O_pulse_duration;
ConVar C_pulse_interval;
float O_pulse_interval;
ConVar C_revive_keep_duration;
float O_revive_keep_duration;
ConVar C_auto_through_wall;
bool O_auto_through_wall;
ConVar C_sv_disable_glow_survivors;
bool O_sv_disable_glow_survivors;

bool Added[MAXPLAYERS+1];
Handle H_keep[MAXPLAYERS+1];
ArrayList Used_timer;

Handle H_set_true;
Handle H_set_false;
bool Should_add_glow = true;
int Glow_type;

bool is_player_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

void set_glow(int entity, int type = 0, const int color[3] = {0, 0, 0}, int range = 0, int range_min = 0, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range_min);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

void update_glow_type()
{
    if(O_auto_through_wall)
    {
        if(O_sv_disable_glow_survivors)
        {
            Glow_type = 2;
        }
        else
        {
            Glow_type = 3;
        }
    }
    else
    {
        if(O_through_wall)
        {
            Glow_type = 3;
        }
        else
        {
            Glow_type = 2;
        }
    }
}

void add_glow(int client)
{
    if(!Added[client])
    {
        Added[client] = true;
        set_glow(client, Glow_type, O_color, O_range, O_range_min, O_flash);
    }
}

void reset_glow(int client)
{
    if(Added[client])
    {
        Added[client] = false;
        set_glow(client);
    }
}

void reset_player(int client)
{
    H_keep[client] = null;
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            if((Should_add_glow || H_keep[client]) && is_player_on_thirdstrike(client))
            {
                add_glow(client);
            }
            else
            {
                reset_glow(client);
            }
        }
    }
}

public void OnClientDisconnect_Post(int client)
{
	Added[client] = false;
    reset_player(client);
}

void reset_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            reset_glow(client);
            reset_player(client);
        }
    }
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_glow(client);
        reset_player(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
		reset_glow(client);
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
		reset_glow(client);
        reset_player(client);
	}
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void event_revive_success(Event event, const char[] name, bool dontBroadcast)
{
    if(O_revive_keep_duration < 0.1 || event.GetBool("ledge_hang"))
    {
        return;
    }
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_player_on_thirdstrike(client))
	{
        for(int i = 0; i < Used_timer.Length; i++)
        {
            Handle timer = Used_timer.Get(i);
            bool got = false;
            for(int j = 1; j <= MaxClients; j++)
            {
                if(timer == H_keep[j])
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
        H_keep[client] = CreateTimer(O_revive_keep_duration, timer_keep);
        Used_timer.Push(H_keep[client]);
	}
}

void timer_keep(Handle timer)
{
    int idx = Used_timer.FindValue(timer);
    if(idx != -1)
    {
        Used_timer.Erase(idx);
    }
    for(int client = 1; client <= MaxClients; client++)
    {
        if(timer == H_keep[client])
        {
            reset_player(client);
        }
    }
}

void data_trans(int client, int prev)
{
    H_keep[client] = H_keep[prev];
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

void timer_set_false(Handle timer)
{
    H_set_false = null;
    Should_add_glow = false;
    H_set_true = CreateTimer(O_pulse_interval, timer_set_true);
}

void timer_set_true(Handle timer)
{
    H_set_true = null;
    Should_add_glow = true;
    H_set_false = CreateTimer(O_pulse_duration, timer_set_false);
}

void data_reset()
{
    delete H_set_true;
    delete H_set_false;
    Should_add_glow = true;
    if(O_pulse_duration >= 0.1 && O_pulse_interval >= 0.1)
    {
        H_set_false = CreateTimer(O_pulse_duration, timer_set_false);
    }
}

void get_all_cvars()
{
    char cvar_colors[12];
    C_color.GetString(cvar_colors, sizeof(cvar_colors));
    explode_string_to_cell_array(cvar_colors, " ", O_color, sizeof(O_color), 4, StringExplodeType_Int);
    O_range = C_range.IntValue;
    O_range_min = C_range_min.IntValue;
    O_through_wall = C_through_wall.BoolValue;
    O_flash = C_flash.BoolValue;
    O_pulse_duration = C_pulse_duration.FloatValue;
    O_pulse_interval = C_pulse_interval.FloatValue;
    O_revive_keep_duration = C_revive_keep_duration.FloatValue;
    O_auto_through_wall = C_auto_through_wall.BoolValue;
    O_sv_disable_glow_survivors = C_sv_disable_glow_survivors.BoolValue;

    data_reset();
    update_glow_type();
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_color)
    {
        char cvar_colors[12];
        C_color.GetString(cvar_colors, sizeof(cvar_colors));
        explode_string_to_cell_array(cvar_colors, " ", O_color, sizeof(O_color), 4, StringExplodeType_Int);
    }
    else if(convar == C_range)
    {
        O_range = C_range.IntValue;
    }
    else if(convar == C_range_min)
    {
        O_range_min = C_range_min.IntValue;
    }
    else if(convar == C_through_wall)
    {   
        O_through_wall = C_through_wall.BoolValue;
        update_glow_type();
    }
    else if(convar == C_flash)
    {
        O_flash = C_flash.BoolValue;
    }
    else if(convar == C_pulse_duration)
    {
        O_pulse_duration = C_pulse_duration.FloatValue;
    }
    else if(convar == C_pulse_interval)
    {
        O_pulse_interval = C_pulse_interval.FloatValue;
    }
    else if(convar == C_revive_keep_duration)
    {
        O_revive_keep_duration = C_revive_keep_duration.FloatValue;
    }
    else if(convar == C_auto_through_wall)
    {
        O_auto_through_wall = C_auto_through_wall.BoolValue;
        update_glow_type();
    }
    else if(convar == C_sv_disable_glow_survivors)
    {
        O_sv_disable_glow_survivors = C_sv_disable_glow_survivors.BoolValue;
        update_glow_type();
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);

    reset_all();
    data_reset();
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
	Used_timer = new ArrayList();

    HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("revive_success", event_revive_success);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

    C_color = CreateConVar("thirdstrike_glow_color", "255 255 255", "color of glow, split up with space");
    C_color.AddChangeHook(convar_changed);
    C_range = CreateConVar("thirdstrike_glow_range", "0", "max visible range of glow. 0 = infinite", _, true, 0.0);
    C_range.AddChangeHook(convar_changed);
    C_range_min = CreateConVar("thirdstrike_glow_range_min", "0", "min range far away to visible the glow, 0 = no limit", _, true, 0.0);
    C_range_min.AddChangeHook(convar_changed);
    C_through_wall = CreateConVar("thirdstrike_glow_through_wall", "1", "1 = enable, 0 = disable. can the glow be seen through wall?");
    C_through_wall.AddChangeHook(convar_changed);
    C_flash = CreateConVar("thirdstrike_glow_flash", "1", "1 = enable, 0 = disable. will the glow flash?");
    C_flash.AddChangeHook(convar_changed);
    C_pulse_duration = CreateConVar("thirdstrike_glow_pulse_duration", "1.0", "duration of pulse to add glow. lower than 0.1 = disable");
    C_pulse_duration.AddChangeHook(convar_changed);
    C_pulse_interval = CreateConVar("thirdstrike_glow_pulse_interval", "0.5", "interval of pulse to add glow. lower than 0.1 = disable");
    C_pulse_interval.AddChangeHook(convar_changed);
    C_revive_keep_duration = CreateConVar("thirdstrike_glow_revive_keep_duration", "1.5", "after revived from down, always add glow for this duration even in the pulse interval. lower than 0.1 = disable");
    C_revive_keep_duration.AddChangeHook(convar_changed);
    C_auto_through_wall = CreateConVar("thirdstrike_glow_auto_through_wall", "0", "1 = enable, 0 = disable. ignore \"thirdstrike_glow_through_wall\", and only let glow pass through wall when \"sv_disable_glow_survivors\" disabled(for realism modes)");
    C_auto_through_wall.AddChangeHook(convar_changed);
    C_sv_disable_glow_survivors = FindConVar("sv_disable_glow_survivors");
    C_sv_disable_glow_survivors.AddChangeHook(convar_changed);
    CreateConVar("thirdstrike_glow_version", PLUGIN_VERSION, "version of Thirdstrike Glow", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "thirdstrike_glow");
    get_all_cvars();
}

public void OnPluginEnd()
{
    reset_all();
}
