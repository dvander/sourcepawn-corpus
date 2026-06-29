#define PLUGIN_VERSION	"1.12 Use env_instructor_hint"
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
	url = "https://forums.alliedmods.net/showpost.php?p=2820202"
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
int Hint[MAXPLAYERS+1] = {-1, ...};
float Hint_end_time[MAXPLAYERS+1] = {-1.0, ...};

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
ConVar C_hint_duration;
float O_hint_duration;
ConVar C_hint_color_used;
char O_hint_color_used[32];
ConVar C_hint_color_ready;
char O_hint_color_ready[32];
ConVar C_hint_color_query;
char O_hint_color_query[32];
ConVar C_hint_icon_used;
char O_hint_icon_used[32];
ConVar C_hint_icon_ready;
char O_hint_icon_ready[32];
ConVar C_hint_icon_query;
char O_hint_icon_query[32];

int G_vomit_id = -1;
int G_charge_id = -1;
bool Started;
bool Map_started;

int Offset_QueuedPummelVictim;

public void OnMapStart()
{
    Map_started = true;
    Started = true;
    reset_all();
    hints_create();
}

public void OnMapEnd()
{
    Map_started = false;
    Started = false;
    reset_all();
}

void hints_create()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        int entity = create_hint();
        if(entity != -1)
        {
            Hint[i] = EntIndexToEntRef(entity);
        }
    }
}

void remove_ref(int& ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEdict(entity);
    }
    ref = -1;
}

void reset_player(int client, bool extra = false, bool remove_hint_ent = false)
{
    Enabled[client] = true;
    Next_enable_time[client] = -1.0;
    Block_fire_time[client] = -1.0;
    Vomited_id[client].Clear();
    Charged_id[client].Clear();
    if(remove_hint_ent)
    {
        remove_ref(Hint[client]);
    }
    else
    {
        if(Hint[client] != -1)
        {
            int entity = EntRefToEntIndex(Hint[client]);
            if(entity != -1)
            {
                AcceptEntityInput(entity, "EndHint");
            }
        }
    }
    Hint_end_time[client] = -1.0;
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
        reset_player(client, true, true);
    }
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

int create_hint()
{
    int entity = CreateEntityByName("env_instructor_hint");
    if(entity != -1)
    {
        DispatchKeyValue(entity, "hint_static", "1");
        DispatchKeyValue(entity, "hint_timeout", "0");
        DispatchKeyValue(entity, "hint_range", "0.0");
        DispatchKeyValue(entity, "hint_display_limit", "0");
        DispatchKeyValue(entity, "hint_instance_type", "0");
        DispatchSpawn(entity);
    }
    return entity;
}

void set_hint(int entity, int client, const char[] icon, const char[] color, const char[] caption)
{
    DispatchKeyValue(entity, "hint_caption", caption);
    DispatchKeyValue(entity, "hint_color", color);
    DispatchKeyValue(entity, "hint_icon_onscreen", icon);
    AcceptEntityInput(entity, "ShowHint", client);
    Hint_end_time[client] = GetGameTime() + O_hint_duration;
}

void hint_text(int client, const char[] icon, const char[] color, const char[] format, any ...)
{
    if(Hint[client] == -1)
    {
        int entity = create_hint();
        if(entity != -1)
        {
            Hint[client] = EntIndexToEntRef(entity);
            char buffer[256];
            VFormat(buffer, sizeof(buffer), format, 5);
            set_hint(entity, client, icon, color, buffer);
        }
    }
    else
    {
        int entity = EntRefToEntIndex(Hint[client]);
        if(entity != -1)
        {
            AcceptEntityInput(entity, "EndHint");
            char buffer[256];
            VFormat(buffer, sizeof(buffer), format, 5);
            set_hint(entity, client, icon, color, buffer);
        }
        else
        {
            entity = create_hint();
            if(entity != -1)
            {
                Hint[client] = EntIndexToEntRef(entity);
                char buffer[256];
                VFormat(buffer, sizeof(buffer), format, 5);
                set_hint(entity, client, icon, color, buffer);
            }
            else
            {
                Hint[client] = -1;
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
        if(Hint[client] != -1 && Hint_end_time[client] >= 0.0 && time >= Hint_end_time[client])
        {
            Hint_end_time[client] = -1.0;
            int entity = EntRefToEntIndex(Hint[client]);
            if(entity != -1)
            {
                AcceptEntityInput(entity, "EndHint");
            }
        }
        if(!Enabled[client] && Next_enable_time[client] >= 0.0 && time >= Next_enable_time[client])
        {
            Enabled[client] = true;
            Next_enable_time[client] = -1.0;
            if(!IsFakeClient(client))
            {
                hint_text(client, O_hint_icon_ready, O_hint_color_ready, "%T", "escape_enabled", client);
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
                    hint_text(client, O_hint_icon_ready, O_hint_color_ready, "%T", "escape_enabled", client);
                }
                else
                {
                    float left = Next_enable_time[client] - time;
                    hint_text(client,O_hint_icon_query,  O_hint_color_query, "%T", "escape_query", client, left);
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
        if(!IsFakeClient(victim))
        {
            hint_text(victim, O_hint_icon_used, O_hint_color_used, "%T", "escape_used", victim, source, O_time);
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
    if(!IsFakeClient(client))
    {
        float left = Next_enable_time[client] - GetGameTime();
        hint_text(client, O_hint_icon_query, O_hint_color_query, "%T", "escape_query", client, left);
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
    if(Map_started)
    {
        hints_create();
    }
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
    O_hint_duration = C_hint_duration.FloatValue;
    C_hint_color_used.GetString(O_hint_color_used, sizeof(O_hint_color_used));
    C_hint_color_ready.GetString(O_hint_color_ready, sizeof(O_hint_color_ready));
    C_hint_color_query.GetString(O_hint_color_query, sizeof(O_hint_color_query));
    C_hint_icon_used.GetString(O_hint_icon_used, sizeof(O_hint_icon_used));
    C_hint_icon_ready.GetString(O_hint_icon_ready, sizeof(O_hint_icon_ready));
    C_hint_icon_query.GetString(O_hint_icon_query, sizeof(O_hint_icon_query));
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
    else if(convar == C_hint_duration)
    {
        O_hint_duration = C_hint_duration.FloatValue;
    }
    else if(convar == C_hint_color_used)
    {
        C_hint_color_used.GetString(O_hint_color_used, sizeof(O_hint_color_used));
    }
    else if(convar == C_hint_color_ready)
    {
        C_hint_color_ready.GetString(O_hint_color_ready, sizeof(O_hint_color_ready));
    }
    else if(convar == C_hint_color_query)
    {
        C_hint_color_query.GetString(O_hint_color_query, sizeof(O_hint_color_query));
    }
    else if(convar == C_hint_icon_used)
    {
        C_hint_icon_used.GetString(O_hint_icon_used, sizeof(O_hint_icon_used));
    }
    else if(convar == C_hint_icon_ready)
    {
        C_hint_icon_ready.GetString(O_hint_icon_ready, sizeof(O_hint_icon_ready));
    }
    else if(convar == C_hint_icon_query)
    {
        C_hint_icon_query.GetString(O_hint_icon_query, sizeof(O_hint_icon_query));
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
    C_hint_duration = CreateConVar(PLUGIN_PREFIX ... "_hint_duration", "3.0", "hint duration", _, true, 0.1);
    C_hint_duration.AddChangeHook(convar_changed);
    C_hint_color_used = CreateConVar(PLUGIN_PREFIX ... "_hint_color_used", "255 255 255", "color of hint when escaped");
    C_hint_color_used.AddChangeHook(convar_changed);
    C_hint_color_ready = CreateConVar(PLUGIN_PREFIX ... "_hint_color_ready", "255 255 255", "color of hint when escape is ready");
    C_hint_color_ready.AddChangeHook(convar_changed);
    C_hint_color_query = CreateConVar(PLUGIN_PREFIX ... "_hint_color_query", "255 255 255", "color of hint when show remainder");
    C_hint_color_query.AddChangeHook(convar_changed);
    C_hint_icon_used = CreateConVar(PLUGIN_PREFIX ... "_hint_icon_used", "icon_shield", "icon of hint when escaped");
    C_hint_icon_used.AddChangeHook(convar_changed);
    C_hint_icon_ready = CreateConVar(PLUGIN_PREFIX ... "_hint_icon_ready", "icon_alert", "icon of hint when escape is ready");
    C_hint_icon_ready.AddChangeHook(convar_changed);
    C_hint_icon_query = CreateConVar(PLUGIN_PREFIX ... "_hint_icon_query", "icon_no", "icon of hint when show remainder");
    C_hint_icon_query.AddChangeHook(convar_changed);
	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true, PLUGIN_PREFIX);
	get_all_cvars();
}

public void OnPluginEnd()
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        remove_ref(Hint[i]);
    }
}