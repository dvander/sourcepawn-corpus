#define PLUGIN_VERSION	"2.4"
#define PLUGIN_NAME		"Bot Takeover 4v4 Arena Edition"
#define PLUGIN_PREFIX   "bot_takeover"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <4v4_arena>

#define TAKEOVER_REPRINT_TIME 1.0

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2819162"
};

ConVar C_alright;
bool O_alright;

bool Started;

float reprint_time_waiting[MAXPLAYERS+1] = {-1.0, ...};
float reprint_time_can[MAXPLAYERS+1] = {-1.0, ...};
float reprint_time_not[MAXPLAYERS+1] = {-1.0, ...};
int Last_buttons[MAXPLAYERS+1];
bool Taking[MAXPLAYERS+1];

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

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

bool is_survivor_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_someone_alright()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_alright(client))
        {
            return true;
        }
    }
    return false;
}

void reset_player(int client)
{
    reprint_time_can[client] = -1.0;
    reprint_time_not[client] = -1.0;
    reprint_time_waiting[client] = -1.0;
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_player(client);
    }
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(Started && IsClientInGame(client))
    {
        if(!IsFakeClient(client) && !IsPlayerAlive(client) && GetClientTeam(client) == 2)
        {
            if(!O_alright || is_someone_alright())
            {
                float time = GetGameTime();
                int obmode = GetEntProp(client, Prop_Send, "m_iObserverMode");
                if(obmode != 4 && obmode != 5)
                {
                    reprint_time_can[client] = -1.0;
                    reprint_time_not[client] = -1.0;
                    if(reprint_time_waiting[client] < 0.0 || time >= reprint_time_waiting[client])
                    {
                        reprint_time_waiting[client] = time + TAKEOVER_REPRINT_TIME;
                        PrintCenterText(client, "%T", "waiting", client);
                    }
                }
                else
                {
                    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                    if(target != client && target > 0 && target <= MaxClients && SurvivorArena_GetTeam(client) == SurvivorArena_GetTeam(target) && IsClientInGame(target) && GetClientTeam(target) == 2 && IsFakeClient(target) && IsPlayerAlive(target) && get_idled_of_bot(target) == 0)
                    {
                        reprint_time_not[client] = -1.0;
                        reprint_time_waiting[client] = -1.0;
                        if(reprint_time_can[client] < 0.0 || time >= reprint_time_can[client])
                        {
                            reprint_time_can[client] = time + TAKEOVER_REPRINT_TIME;
                            PrintCenterText(client, "%T", "can_takeover", client);
                        }
                        if(buttons & IN_SPEED == IN_SPEED && Last_buttons[client] & IN_SPEED != IN_SPEED)
                        {
                            reset_player(client);
                            Taking[client] = true;
                            ChangeClientTeam(client, 0);
                            L4D_SetHumanSpec(target, client);
                            L4D_TakeOverBot(client);
                            Taking[client] = false;
                        }
                    }
                    else
                    {
                        reprint_time_can[client] = -1.0;
                        reprint_time_waiting[client] = -1.0;
                        if(reprint_time_not[client] < 0.0 || time >= reprint_time_not[client])
                        {
                            reprint_time_not[client] = time + TAKEOVER_REPRINT_TIME;
                            PrintCenterText(client, "%T", "can_not_takeover", client);
                        }
                    }
                }
            }
            else
            {
                reset_player(client);
            }
        }
    }
    Last_buttons[client] = buttons;
}

public void OnClientDisconnect_Post(int client)
{
    Taking[client] = false;
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
	if(client != 0)
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
	if(client != 0)
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
	if(!Started)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client != 0)
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

void get_all_cvars()
{
    O_alright = C_alright.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_alright)
    {
        O_alright = C_alright.BoolValue;
    }
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
}

any native_BotTakeOver_IsInTaking(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return Taking[client];
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    CreateNative("BotTakeOver_IsInTaking", native_BotTakeOver_IsInTaking);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations(PLUGIN_PREFIX ... ".phrases");

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);
    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);

    C_alright = CreateConVar(PLUGIN_PREFIX ... "_alright", "1", "1 = enable, 0 = disable. required at least 1 survivor still not incapacitated to try to takeover bot?");
    C_alright.AddChangeHook(convar_changed);
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, PLUGIN_PREFIX);
    get_all_cvars();
}