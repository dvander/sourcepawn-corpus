#define PLUGIN_VERSION	"1.12 Use Chat Text"
#define PLUGIN_NAME		"Escape Cooldown EX"
#define PLUGIN_PREFIX   "escape_cooldown_ex"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ESCAPE_HUNTER       (1 << 0)
#define ESCAPE_JOCKEY       (1 << 1)
#define ESCAPE_SMOKER       (1 << 2)
#define ESCAPE_BOOMER       (1 << 3)
#define ESCAPE_CHARGER      (1 << 4)

#define QueuedPummel_Victim		0
#define QueuedPummel_Attacker	8

#define MAX_CAHRGE_ID   65535
#define MAX_VOMIT_ID    65535
#define TIME_BLOCK_FIRE  0.1

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2820505"
};

GlobalForward Forward_OnClearedSpecialInfectedHealth;

bool Enabled[MAXPLAYERS+1];
float Next_enable_time[MAXPLAYERS+1] = {-1.0, ...};
int Vomit_id_send[MAXPLAYERS+1] = {-1, ...};
int Charge_id_send[MAXPLAYERS+1] = {-1, ...};
ArrayList Vomited_id[MAXPLAYERS+1];
ArrayList Charged_id[MAXPLAYERS+1];
int Last_buttons[MAXPLAYERS+1];
float Block_fire_time[MAXPLAYERS+1] = {-1.0, ...};
bool Boomer_killed_by_escape[MAXPLAYERS+1];

ConVar C_z_charge_interval;
float O_z_charge_interval;
ConVar C_time;
float O_time;
ConVar C_auto_print;
bool O_auto_print;
ConVar C_enable;
int O_enable;
ConVar C_ignite;
int O_ignite;

int G_vomit_id = -1;
int G_charge_id = -1;
bool Started;

int Offset_QueuedPummelVictim;

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

void colors_replace(char[] str, int max_len)
{
    static const char color_tag_and_codes[][2][32] = 
    {
        {
            "{default}",
            "\x01"
        },
        {
            "{lightgreen}",
            "\x03"
        },
        {
            "{olive}",
            "\x04"
        },
        {
            "{green}",
            "\x05"
        },
    };
    for(int i = 0; i < sizeof(color_tag_and_codes); i++)
    {
        ReplaceString(str, max_len, color_tag_and_codes[i][0], color_tag_and_codes[i][1]);
    }
}

void colors_print_to_chat(int client, const char[] format, any ...)
{
    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 3);
    colors_replace(buffer, sizeof(buffer));
    PrintToChat(client, "%s", buffer);
}

void reset_player(int client, bool extra = false)
{
    Enabled[client] = true;
    Next_enable_time[client] = -1.0;
    Block_fire_time[client] = -1.0;
    Vomited_id[client].Clear();
    Charged_id[client].Clear();
    if(extra)
    {
        Boomer_killed_by_escape[client] = false;
    }
}

void data_trans(int client, int prev)
{
    Enabled[client] = Enabled[prev];
    Next_enable_time[client] = Next_enable_time[prev];
    Vomited_id[client].Clear();
    for(int i = 0; i < Vomited_id[prev].Length; i++)
    {
        Vomited_id[client].Push(Vomited_id[prev].Get(i));
    }
    Charged_id[client].Clear();
    for(int i = 0; i < Charged_id[prev].Length; i++)
    {
        Charged_id[client].Push(Charged_id[prev].Get(i));
    }
}

void reset_all()
{
    for(int client = 1; client <= MAXPLAYERS; client++)
    {
        reset_player(client, true);
    }
}

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
	return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

int get_print_target(int client)
{
    int target = 0;
    if(!IsFakeClient(client))
    {
        target = client;
    }
    else
    {
        int human = get_idled_of_bot(client);
        if(human > 0 && IsClientInGame(human))
        {
            target = human;
        }
    }
    return target;
}

void kill_target(int target, int attacker)
{
    int health = GetClientHealth(target);
    SetEntityHealth(target, 1);
    Call_StartForward(Forward_OnClearedSpecialInfectedHealth);
    Call_PushCell(target);
    Call_PushCell(health);
    Call_PushCell(health - 1);
    Call_PushCell(attacker);
    Call_Finish();
    CTimer_SetTimestamp(L4D2Direct_GetInvulnerabilityTimer(target), 0.0);
    SDKHooks_TakeDamage(target, 0, attacker, 2.0);
}

int get_charger_victim(int client)
{
    int victim = -1;
	victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
	if(victim > 0)
	{
		return victim;
	}
	victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if(victim > 0)
	{
		return victim;
	}
    victim = GetEntDataEnt2(client, Offset_QueuedPummelVictim + QueuedPummel_Victim);
    if(victim > 0)
    {
        return victim;
    }
    return -1;
}

void stop_charge(int client)
{
    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if(ability != -1 && HasEntProp(ability, Prop_Send, "m_isCharging"))
    {
        SetEntProp(ability, Prop_Send, "m_isCharging", 0);
        SetEntityFlags(client, GetEntityFlags(client) & ~FL_FROZEN);
        SetEntPropFloat(ability, Prop_Send, "m_duration", O_z_charge_interval);
		SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + O_z_charge_interval);
    }
}

void clear_charger_attacker(int victim, int attacker)
{
    SetEntPropEnt(victim, Prop_Send, "m_pummelAttacker", -1);
    SetEntPropEnt(victim, Prop_Send, "m_carryAttacker", -1);
    SetEntDataEnt2(victim, Offset_QueuedPummelVictim + QueuedPummel_Attacker, -1);
    SetEntPropEnt(attacker, Prop_Send, "m_pummelVictim", -1);
    SetEntPropEnt(attacker, Prop_Send, "m_carryVictim", -1);
    SetEntDataEnt2(attacker, Offset_QueuedPummelVictim + QueuedPummel_Victim, -1);
}

void charger_escape(int client, float time)
{
    int[] chargers = new int[MaxClients];
    int count = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != client && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 6 && get_charger_victim(i) == client)
        {
            chargers[count++] = i;
        }
    }
    if(count > 0)
    {
        bool pushed = false;
        for(int i = 0; i < count; i++)
        {
            int id = Charge_id_send[chargers[i]];
            if(Charged_id[client].FindValue(id) == -1)
            {
                Charged_id[client].Push(id);
                pushed = true;
            }
        }
        if(pushed && count == 1)
        {
            if(check_escape(client, "charger"))
            { 
                int charger = chargers[0];
                stop_charge(charger);
                clear_charger_attacker(client, charger);
                if(O_ignite & ESCAPE_CHARGER)
                {
                    IgniteEntity(charger, 999.0);
                }
                kill_target(charger, client);
                L4D2Direct_DoAnimationEvent(client, PLAYERANIMEVENT_SPAWN);
                Block_fire_time[client] = time + TIME_BLOCK_FIRE;
            }
            else
            {
                auto_print(client);
            }
        }
    }
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(!Started || !IsClientInGame(client))
    {
        return;
    }
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        float time = GetGameTime();
        if(!Enabled[client] && Next_enable_time[client] >= 0.0 && time >= Next_enable_time[client])
        {
            Enabled[client] = true;
            Next_enable_time[client] = -1.0;
            int target = get_print_target(client);
            if(target != 0)
            {
                colors_print_to_chat(target, "%T", "escape_enabled", target);
            }
        }
        if(O_enable & ESCAPE_CHARGER)
        {
            charger_escape(client, time);
        }
        if(!IsFakeClient(client))
        {
            if(buttons & IN_SPEED == IN_SPEED && Last_buttons[client] & IN_SPEED != IN_SPEED)
            {
                if(Enabled[client])
                {
                    colors_print_to_chat(client, "%T", "escape_enabled", client);
                }
                else
                {
                    float left = Next_enable_time[client] - time;
                    colors_print_to_chat(client, "%T", "escape_query", client, left < 0.1 ? 0.1 : left);
                }
            }
        }
    }
    Last_buttons[client] = buttons;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(!Started)
    {
        return Plugin_Continue;
    }
    if(Block_fire_time[client] >= 0.0 && GetGameTime() >= Block_fire_time[client])
    {
        Block_fire_time[client] = -1.0;
        buttons &= ~(IN_ATTACK | IN_ATTACK2);
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

bool check_escape(int victim, const char[] source)
{
    if(Enabled[victim])
    {
        Enabled[victim] = false;
        Next_enable_time[victim] = GetGameTime() + O_time;
        int target = get_print_target(victim);
        if(target != 0)
        {
            colors_print_to_chat(target, "%T", "escape_used", target, source, O_time);
        }
        return true;
    }
    return false;
}

void auto_print(int client)
{
    if(!O_auto_print)
    {
        return;
    }
    int target = get_print_target(client);
    if(target != 0)
    {
        float left = Next_enable_time[client] - GetGameTime();
        colors_print_to_chat(target, "%T", "escape_query", target, left < 0.1 ? 0.1 : left);
    }
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

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    Started = true;
	reset_all();
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
		reset_player(client, true);
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

void event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started)
    {
        return;
    }
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("player"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started)
    {
        return;
    }
	int client = GetClientOfUserId(event.GetInt("player"));
	if(client != 0)
	{
		int prev = GetClientOfUserId(event.GetInt("bot"));
		if(prev != 0)
		{
			data_trans(client, prev);
		}
	}
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    Started = false;
    reset_all();
}

public Action L4D2_OnStagger(int client, int source)
{
    if(source > 0 && source <= MaxClients && Boomer_killed_by_escape[source] && GetClientTeam(client) == 2)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void frame_boomer(DataPack dp)
{
    dp.Reset();
    int target = GetClientOfUserId(dp.ReadCell());
    int client = GetClientOfUserId(dp.ReadCell());
    delete dp;
    if(target != 0 && IsClientInGame(target) && GetClientTeam(target) == 3 && IsPlayerAlive(target))
    {
        int owner = 0;
        if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
        {
            owner = client;
        }
        else
        {
            int[] survivors = new int[MaxClients];
            int count = 0;
            for(int i = 1; i <= MaxClients; i++)
            {
                if(i != target && IsClientInGame(i) && GetClientTeam(i) == 2)
                {
                    survivors[count++] = i;
                }
            }
            if(count > 0)
            {
                owner = survivors[GetRandomInt(0, count - 1)];
            }
        }
        if(O_ignite & ESCAPE_BOOMER)
        {
            IgniteEntity(target, 999.0);
        }
        kill_target(target, owner);
    }
}

void add_vomit_id_all(int id)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Vomited_id[i].FindValue(id) == -1 && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            Vomited_id[i].Push(id);
        }
    }
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
    if(!Started || !(O_enable & ESCAPE_BOOMER) || attacker == 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != 3 || !IsClientInGame(victim) || GetClientTeam(victim) != 2)
    {
        return Plugin_Continue;
    }
    if(!boomerExplosion)
    {
        if(Boomer_killed_by_escape[attacker])
        {
            add_vomit_id_all(Vomit_id_send[attacker]);
            return Plugin_Handled;
        }
        if(Vomited_id[victim].FindValue(Vomit_id_send[attacker]) == -1)
        {
            if(check_escape(victim, "boomer"))
            {
                add_vomit_id_all(Vomit_id_send[attacker]);
                Boomer_killed_by_escape[attacker] = true;
                if(IsPlayerAlive(attacker))
                {
                    DataPack dp = new DataPack();
                    dp.WriteCell(GetClientUserId(attacker));
                    dp.WriteCell(GetClientUserId(victim));
                    RequestFrame(frame_boomer, dp);
                }
                return Plugin_Handled;
            }
            else
            {
                Vomited_id[victim].Push(Vomit_id_send[attacker]);
                auto_print(victim);
                return Plugin_Continue;
            }
        }
        else
        {
            return Plugin_Continue;
        }
    }
    else
    {
        if(Boomer_killed_by_escape[attacker])
        {
            return Plugin_Handled;
        }
        else if(check_escape(victim, "boomer"))
        {
            return Plugin_Handled;
        }
        else
        {
            auto_print(victim);
            return Plugin_Continue;
        }
    }
}

void event_lunge_pounce(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started || !(O_enable & ESCAPE_HUNTER))
    {
        return;
    }
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if(attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 3)
    {
        int victim = GetClientOfUserId(event.GetInt("victim"));
        if(victim != 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
        {
            if(check_escape(victim, "hunter"))
            {
                L4D_Hunter_ReleaseVictim(victim, attacker);
                if(O_ignite & ESCAPE_HUNTER)
                {
                    IgniteEntity(attacker, 999.0);
                }
                kill_target(attacker, victim);
                L4D2Direct_DoAnimationEvent(victim, PLAYERANIMEVENT_SPAWN);
                Block_fire_time[victim] = GetGameTime() + TIME_BLOCK_FIRE;
            }
            else
            {
                auto_print(victim);
            }
        }
    }
}

void event_jockey_ride(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started || !(O_enable & ESCAPE_JOCKEY))
    {
        return;
    }
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if(attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 5)
    {
        int victim = GetClientOfUserId(event.GetInt("victim"));
        if(victim != 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
        {
            if(check_escape(victim, "jockey"))
            {
                L4D2_Jockey_EndRide(victim, attacker);
                if(O_ignite & ESCAPE_JOCKEY)
                {
                    IgniteEntity(attacker, 999.0);
                }
                kill_target(attacker, victim);
                Block_fire_time[victim] = GetGameTime() + TIME_BLOCK_FIRE;
            }
            else
            {
                auto_print(victim);
            }
        }
    }
}

void event_tongue_grab(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started || !(O_enable & ESCAPE_SMOKER))
    {
        return;
    }
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if(attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 1)
    {
        int victim = GetClientOfUserId(event.GetInt("victim"));
        if(victim != 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
        {
            if(check_escape(victim, "smoker"))
            {
                L4D_Smoker_ReleaseVictim(victim, attacker);
                if(O_ignite & ESCAPE_SMOKER)
                {
                    IgniteEntity(attacker, 999.0);
                }
                kill_target(attacker, victim);
            }
            else
            {
                auto_print(victim);
            }
        }
    }
}

void event_ability_use(Event event, const char[] name, bool dontBroadcast)
{
    if(!Started)
    {
        return;
    }
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if(attacker != 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker))
    {
        int class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
        char ability[64];
        event.GetString("ability", ability, sizeof(ability));
        if(class == 2 && strcmp(ability, "ability_vomit") == 0)
        {
            G_vomit_id++;
            if(G_vomit_id > MAX_VOMIT_ID)
            {
                G_vomit_id = 0;
            }
            for(int i = 1; i <= MaxClients; i++)
            {
                int index = Vomited_id[i].FindValue(G_vomit_id);
                if(index != -1)
                {
                    Vomited_id[i].Erase(index);
                }
            }
            Vomit_id_send[attacker] = G_vomit_id;
        }
        else if(class == 6 && strcmp(ability, "ability_charge") == 0)
        {
            G_charge_id++;
            if(G_charge_id > MAX_CAHRGE_ID)
            {
                G_charge_id = 0;
            }
            for(int i = 1; i <= MaxClients; i++)
            {
                int index = Charged_id[i].FindValue(G_charge_id);
                if(index != -1)
                {
                    Charged_id[i].Erase(index);
                }
            }
            Charge_id_send[attacker] = G_charge_id;
        }
    }
}

void get_all_cvars()
{
    O_z_charge_interval = C_z_charge_interval.FloatValue;
    O_time = C_time.FloatValue;
    O_auto_print = C_auto_print.BoolValue;
    O_enable = C_enable.IntValue;
    O_ignite = C_ignite.IntValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_time)
    {
        O_time = C_time.FloatValue;
        reset_all();
    }
    else if(convar == C_auto_print)
    {
        O_auto_print = C_auto_print.BoolValue;
    }
    else if(convar == C_enable)
    {
        O_enable = C_enable.IntValue;
    }
    else if(convar == C_ignite)
    {
        O_ignite = C_ignite.IntValue;
    }
    else if(convar == C_z_charge_interval)
    {
        O_z_charge_interval = C_z_charge_interval.FloatValue;
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
    Forward_OnClearedSpecialInfectedHealth = new GlobalForward("EscapeCooldownEX_OnClearedSpecialInfectedHealth", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    RegPluginLibrary(PLUGIN_PREFIX);
    return APLRes_Success;
}

public void OnPluginStart()
{
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        Vomited_id[i] = new ArrayList();
        Charged_id[i] = new ArrayList();
    }

    LoadTranslations(PLUGIN_PREFIX ... ".phrases");

	HookEvent("round_start", event_round_start);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
	HookEvent("player_death", event_player_death);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);
	HookEvent("map_transition", event_map_transition);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
    HookEvent("lunge_pounce", event_lunge_pounce);
    HookEvent("jockey_ride", event_jockey_ride);
    HookEvent("tongue_grab", event_tongue_grab);
    HookEvent("ability_use", event_ability_use);

    C_z_charge_interval = FindConVar("z_charge_interval");
    C_z_charge_interval.AddChangeHook(convar_changed);
	C_time = CreateConVar(PLUGIN_PREFIX ... "_time", "60.0", "escape cooldown", _, true, 0.1);
	C_time.AddChangeHook(convar_changed);
    C_auto_print = CreateConVar(PLUGIN_PREFIX ... "_auto_print", "1", "1 = enable, 0 = disable. when pinned by special infected, if self escape is not ready, auto print remainder?");
    C_auto_print.AddChangeHook(convar_changed);
    C_enable = CreateConVar(PLUGIN_PREFIX ... "_enable", "31", "which types of special infected can self escape from. 1 = hunter, 2 = jockey, 4 = smoker, 8 = target, 16 = charger. add numbers together", _, true, 0.0, true, 31.0);
    C_enable.AddChangeHook(convar_changed);
    C_ignite = CreateConVar(PLUGIN_PREFIX ... "_ignite", "31", "which types of special infected will be ignite before kill. 1 = hunter, 2 = jockey, 4 = smoker, 8 = target, 16 = charger. add numbers together", _, true, 0.0, true, 31.0);
    C_ignite.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_all_cvars();
}