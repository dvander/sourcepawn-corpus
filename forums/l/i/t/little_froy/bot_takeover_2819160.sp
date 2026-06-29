#define PLUGIN_VERSION	"4.7"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define TAKEOVER_REPRINT_TYPE_CENTER    1
#define TAKEOVER_REPRINT_TYPE_HINT      2

public Plugin myinfo =
{
	name = "Bot Takeover",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346637"
};

ConVar C_print_type;
int O_print_type;
ConVar C_print_interval;
float O_print_interval;
ConVar C_button;
int O_button;
ConVar C_skip;
bool O_skip;
ConVar C_pre_delay;
float O_pre_delay;

bool Started;

bool Delayed[MAXPLAYERS+1];
Handle H_delay[MAXPLAYERS+1];
bool Printed_can[MAXPLAYERS+1];
Handle H_can[MAXPLAYERS+1];
bool Printed_waiting[MAXPLAYERS+1];
Handle H_waiting[MAXPLAYERS+1];
int Last_buttons[MAXPLAYERS+1];

public void OnMapStart()
{
	Started = true;
    reset_all(false);
}

public void OnMapEnd()
{
    Started = false;
    reset_all(false);
}

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

bool any_free_bot()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && get_idled_of_bot(client) == 0)
        {
            return true;
        }
    }
    return false;
}

void reset_player(int client)
{
    delete H_delay[client];
    delete H_can[client];
    delete H_waiting[client];
    Delayed[client] = false;
    Printed_can[client] = false;
    Printed_waiting[client] = false;
}

void reset_all(bool end_msg)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            if(end_msg && (H_can[client] || H_waiting[client]) && !IsFakeClient(client) && GetClientTeam(client) == 2 && !IsPlayerAlive(client))
            {
                switch(O_print_type)
                {
                    case TAKEOVER_REPRINT_TYPE_CENTER:
                    {
                        PrintCenterText(client, "%T", "no_free_bot", client);
                    }
                    case TAKEOVER_REPRINT_TYPE_HINT:
                    {
                        PrintHintText(client, "%T", "no_free_bot", client);
                    }
                }
            }
            reset_player(client);
        }
    }
}

void show_takeover(int client, int bot)
{
    char buffer[2];
    IntToString(GetEntProp(bot, Prop_Send, "m_survivorCharacter"), buffer, sizeof(buffer));
    BfWrite msg = view_as<BfWrite>(StartMessageOne("VGUIMenu", client, USERMSG_RELIABLE));
    msg.WriteString("takeover_survivor_bar");
    msg.WriteByte(1);
    msg.WriteByte(1);
    msg.WriteString("character");
    msg.WriteString(buffer);
    EndMessage();
}

int get_takeover_target(int client)
{
    int obmode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if(!(obmode == 4 || obmode == 5))
    {
        return 0;
    }
    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if(target != client && target > 0 && target <= MaxClients && IsClientInGame(target) && IsFakeClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && get_idled_of_bot(target) == 0)
    {
        return target;
    }
    return 0;
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(!Started || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || IsPlayerAlive(client))
    {
        Last_buttons[client] = buttons;
        return;
    }
    if(!Delayed[client])
    {
        if(!H_delay[client])
        {
            H_delay[client] = CreateTimer(O_pre_delay, timer_pre_delay, client);
        }
        Last_buttons[client] = buttons;
        return;
    }
    if(any_free_bot())
    {
        int target = get_takeover_target(client);
        if(target == 0)
        {
            delete H_can[client];
            Printed_can[client] = false;
            if(!Printed_waiting[client])
            {
                Printed_waiting[client] = true;
                switch(O_print_type)
                {
                    case TAKEOVER_REPRINT_TYPE_CENTER:
                    {
                        PrintCenterText(client, "%T", "waiting", client);
                    }
                    case TAKEOVER_REPRINT_TYPE_HINT:
                    {
                        PrintHintText(client, "%T", "waiting", client);
                    }
                }
            }
            if(!H_waiting[client])
            {
                H_waiting[client] = CreateTimer(O_print_interval, timer_print_waiting, client, TIMER_REPEAT);
            }
        }
        else
        {      
            if(buttons & O_button == O_button && Last_buttons[client] & O_button != O_button)
            {
                reset_player(client);
                if(!O_skip)
                {
                    switch(O_print_type)
                    {
                        case TAKEOVER_REPRINT_TYPE_CENTER:
                        {
                            PrintCenterText(client, "%T", "done", client);
                        }
                        case TAKEOVER_REPRINT_TYPE_HINT:
                        {
                            PrintHintText(client, "%T", "done", client);
                        }
                    }
                }
                ChangeClientTeam(client, 1);
                L4D_SetHumanSpec(target, client);
                if(O_skip)
                {
                    L4D_TakeOverBot(client);
                }
                else
                {
                    show_takeover(client, target);
                }
            }
            else
            {
                delete H_waiting[client];
                Printed_waiting[client] = false;
                if(!Printed_can[client])
                {
                    Printed_can[client] = true;
                    switch(O_print_type)
                    {
                        case TAKEOVER_REPRINT_TYPE_CENTER:
                        {
                            PrintCenterText(client, "%T", "can_takeover", client);
                        }
                        case TAKEOVER_REPRINT_TYPE_HINT:
                        {
                            PrintHintText(client, "%T", "can_takeover", client);
                        }
                    }
                }
                if(!H_can[client])
                {
                    H_can[client] = CreateTimer(O_print_interval, timer_print_can, client, TIMER_REPEAT);
                }
            }
        }
    }
    else if(H_can[client] || H_waiting[client])
    {
        delete H_can[client];
        delete H_waiting[client];
        Printed_can[client] = false;
        Printed_waiting[client] = false;
        switch(O_print_type)
        {
            case TAKEOVER_REPRINT_TYPE_CENTER:
            {
                PrintCenterText(client, "%T", "no_free_bot", client);
            }
            case TAKEOVER_REPRINT_TYPE_HINT:
            {
                PrintHintText(client, "%T", "no_free_bot", client);
            }
        }
    }
    Last_buttons[client] = buttons;
}

void timer_pre_delay(Handle timer, int client)
{
    H_delay[client] = null;
    Delayed[client] = true;
}

Action timer_print_can(Handle timer, int client)
{
    Printed_can[client] = false;
    return Plugin_Continue;
}

Action timer_print_waiting(Handle timer, int client)
{
    Printed_waiting[client] = false;
    return Plugin_Continue;
}

public void OnClientDisconnect_Post(int client)
{
    Last_buttons[client] = 0;
    if(!Started)
    {
        return;
    }
    reset_player(client);
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
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
    reset_all(false);
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all(true);
}

void get_all_cvars()
{
    O_print_interval = C_print_interval.FloatValue;
    O_print_type = C_print_type.IntValue;
    O_button = C_button.IntValue;
    O_skip = C_skip.BoolValue;
    O_pre_delay = C_pre_delay.FloatValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_print_interval)
    {
        O_print_interval = C_print_interval.FloatValue;
    }
    else if(convar == C_print_type)
    {
        O_print_type = C_print_type.IntValue;
    }
    else if(convar == C_button)
    {
        O_button = C_button.IntValue;
    }
    else if(convar == C_skip)
    {
        O_skip = C_skip.BoolValue;
    }
    else if(convar == C_pre_delay)
    {
        O_pre_delay = C_pre_delay.FloatValue;
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
    LoadTranslations("bot_takeover.phrases");

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);

    C_print_type = CreateConVar("bot_takeover_print_type", "2", "print type. 1 = center text, 2 = hint text", _, true, 1.0, true, 2.0);
    C_print_type.AddChangeHook(convar_changed);
    C_print_interval = CreateConVar("bot_takeover_print_interval", "4.0", "interval to print the same text again", _, true, 0.1);
    C_print_interval.AddChangeHook(convar_changed);
    C_button = CreateConVar("bot_takeover_button", "32", "press the button to takeover bot. support combine buttons");
    C_button.AddChangeHook(convar_changed);
    C_skip = CreateConVar("bot_takeover_skip", "0", "1 = enable, 0 = disable. no longer required to manually takeover the bot after selected?");
    C_skip.AddChangeHook(convar_changed);
    C_pre_delay = CreateConVar("bot_takeover_pre_delay", "2.0", "pre delay before formal checks and messages", _, true, 0.1);
    C_pre_delay.AddChangeHook(convar_changed);
    CreateConVar("bot_takeover_version", PLUGIN_VERSION, "version of Bot Takeover", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "bot_takeover");
    get_all_cvars();
}
