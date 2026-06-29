#define PLUGIN_VERSION	"1.2"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <little_froy_utils>

public Plugin myinfo =
{
	name = "Finale Scavenge Point Ex",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352234"
};

enum struct Gascan_wave_t
{
    float pos[3];
    float ang[3];
    float interval;
    float drop_restore_delay;
}

Gascan_wave_t Gascan_spawn_info;
int Wave_gascan = -1;
Handle H_spawn_gascan;
Handle H_restore_gascan;

StringMap Maps;
char Data_path[PLATFORM_MAX_PATH];
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];
char Current_pos_string[54];
char Current_ang_string[54];
float Current_interval;
float Current_drop_restore_delay;

bool Enabled;

public Action L4D2_CGasCan_EventKilled(int gascan, int &inflictor, int &attacker)
{
    if(Wave_gascan == -1)
    {
        return Plugin_Continue;
    }
    if(EntIndexToEntRef(gascan) == Wave_gascan)
    {
        delete H_restore_gascan;
        restore_gascan(gascan);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void restore_gascan(int gascan)
{
    remove_owner(gascan);
    TeleportEntity(gascan, Gascan_spawn_info.pos, Gascan_spawn_info.ang);
    SetEntityMoveType(gascan, MOVETYPE_NONE);
}

void hook_equip_all(bool hook)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            if(hook)
            {
                SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
            }
            else
            {
                SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
            }
        }
    }
}

public void OnMapStart()
{
    char now_map[64];
    GetCurrentMap(now_map, sizeof(now_map));
    if(Maps.GetArray(now_map, Gascan_spawn_info, sizeof(Gascan_spawn_info)))
    {
        Enabled = true;
        hook_equip_all(true);
    }
}

public void OnMapEnd()
{
    if(!Enabled)
    {
        return;
    }
    Enabled = false;
    reset_timers();
    hook_equip_all(false);
    remove_gascan();
}

void set_glow(int entity, int type = 0, const int color[3] = {0, 0, 0}, int range = 0, int range_min = 0, bool flash = false)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", type);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + color[1] * 256 + color[2] * 65536);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", range_min);
    SetEntProp(entity, Prop_Send, "m_bFlashing", flash ? 1 : 0);
}

void remove_owner(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if(owner > 0 && owner <= MaxClients && IsClientInGame(owner))
    {
        RemovePlayerItem(owner, entity);
    }
}

void remove_gascan()
{
    if(Wave_gascan != -1)
    {
        int entity = EntRefToEntIndex(Wave_gascan);
        Wave_gascan = -1;
        if(entity != -1)
        {
            remove_owner(entity);
            RemoveEntity(entity);
        }
    }
}

void create_gascan()
{
    int gascan = CreateEntityByName("weapon_gascan");
    if(gascan == -1)
    {
        return;
    }
    Wave_gascan = EntIndexToEntRef(gascan);
    SetEntProp(gascan, Prop_Send, "m_nSkin", 1);
    TeleportEntity(gascan, Gascan_spawn_info.pos, Gascan_spawn_info.ang);
    DispatchSpawn(gascan);
    SetEntityMoveType(gascan, MOVETYPE_NONE);
    set_glow(gascan, 3, {255, 255, 255});
}

public void L4D2_CGasCan_ActionComplete_Post(int client, int gascan, int nozzle)
{
    if(!Enabled)
    {
        return;
    }
    if(GameRules_GetProp("m_iScavengeTeamScore", _, GameRules_GetProp("m_bAreTeamsFlipped")) < GameRules_GetProp("m_nScavengeItemsGoal"))
    {
        if(Wave_gascan != -1 && EntIndexToEntRef(gascan) == Wave_gascan)
        {
            Wave_gascan = -1;
            reset_timers();
            H_spawn_gascan = CreateTimer(Gascan_spawn_info.interval, timer_spawn);
        }
    }
    else
    {
        reset_timers();
        remove_gascan();
    }
}

void timer_spawn(Handle timer)
{
    H_spawn_gascan = null;
    create_gascan();
}

public void OnClientPutInServer(int client)
{
    if(Enabled)
    {
        SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
    }
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1)
    {
        return;
    }
    if(Wave_gascan != -1 && EntIndexToEntRef(weapon) == Wave_gascan)
    {
        delete H_restore_gascan;
    }
}

void reset_timers()
{
    delete H_spawn_gascan;
    delete H_restore_gascan;
}

void timer_restore(Handle timer)
{
    H_restore_gascan = null;
    if(Wave_gascan != -1)
    {
        int entity = EntRefToEntIndex(Wave_gascan);
        if(entity != -1)
        {
            restore_gascan(entity);
        }
    }
}

void event_weapon_drop(Event event, const char[] name, bool dontBroadcast)
{
    if(Wave_gascan == -1)
    {
        return;
    }
    int weapon = event.GetInt("propid");
    if(weapon > 0 && IsValidEntity(weapon) && EntIndexToEntRef(weapon) == Wave_gascan)
    {
        delete H_restore_gascan;
        H_restore_gascan = CreateTimer(Gascan_spawn_info.drop_restore_delay, timer_restore);
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Enabled)
    {
        return;
    }
    reset_timers();
    remove_gascan();
}

void event_finale_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Enabled)
    {
        return;
    }
    create_gascan();
}

void event_gauntlet_finale_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Enabled)
    {
        return;
    }
    create_gascan();
}

void reset_pre_load_data()
{
    Current_pos_string[0] = '\0';
    Current_ang_string[0] = '\0';
    Current_interval = 0.0;
    Current_drop_restore_delay = 0.0;
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	Current_section_level++;
	if(Current_section_level == 2)
	{
        strcopy(Current_section_name, sizeof(Current_section_name), name);
	}
    return SMCParse_Continue;
}

SMCResult OnLeaveSection(SMCParser smc)
{
    Current_section_level--;
    if(Current_section_level == 1)
    {
        if(Current_interval >= 0.1 && Current_drop_restore_delay >= 0.1)
        {
            Gascan_wave_t st;
            explode_string_to_cell_array(Current_pos_string, " ", st.pos, sizeof(st.pos), 18, StringExplodeType_Float);
            explode_string_to_cell_array(Current_ang_string, " ", st.ang, sizeof(st.ang), 18, StringExplodeType_Float);
            st.interval = Current_interval;
            st.drop_restore_delay = Current_drop_restore_delay;
            Maps.SetArray(Current_section_name, st, sizeof(st));
        }
        reset_pre_load_data();
    }
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(Current_section_level == 2)
	{
        if(strcmp(key, "pos") == 0)
        {
            strcopy(Current_pos_string, sizeof(Current_pos_string), value);
        }
        else if(strcmp(key, "ang") == 0)
        {
            strcopy(Current_ang_string, sizeof(Current_ang_string), value);
        }
        else if(strcmp(key, "interval") == 0)
        {
            Current_interval = StringToFloat(value);
        }
        else if(strcmp(key, "drop_restore_delay") == 0)
        {
            Current_drop_restore_delay = StringToFloat(value);
        }
	}
    return SMCParse_Continue;
}

void check_configs()
{
    Maps.Clear();
    reset_pre_load_data();
    Current_section_level = 0;
    Current_section_name[0] = '\0';
    SMCParser parser = new SMCParser();
    parser.OnEnterSection = OnEnterSection;
    parser.OnLeaveSection = OnLeaveSection;
    parser.OnKeyValue = OnKeyValue;
    parser.ParseFile(Data_path);
    delete parser;
}

Action cmd_reload(int client, int args)
{
    check_configs();
    return Plugin_Handled;
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
    Maps = new StringMap();

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/finale_scavenge_point_ex.cfg");

    HookEvent("weapon_drop", event_weapon_drop);
    HookEvent("round_start", event_round_start);
	HookEvent("finale_start", event_finale_start);
	HookEvent("gauntlet_finale_start", event_gauntlet_finale_start);

    CreateConVar("finale_scavenge_point_ex_version", PLUGIN_VERSION, "version of Finale Scavenge Point Ex", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_finale_scavenge_point_ex_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}

public void OnPluginEnd()
{
    remove_gascan();
}
