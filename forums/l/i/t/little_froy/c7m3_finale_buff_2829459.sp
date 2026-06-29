#define PLUGIN_VERSION	"1.4"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define _QueuedPummel_Attacker	8

public Plugin myinfo =
{
	name = "c7m3 Finale Buff",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349473"
};

ConVar C_ignite;
bool O_ignite;

bool Valid_map;
bool Enabled;

int Bridge_trigger = -1;

int Offset_QueuedPummelVictim;

public void OnEntityCreated(int entity, const char[] classname)
{
    if(!Valid_map)
    {
        return;
    }
    if(entity < 1)
    {
        return;
    }
    if(strcmp(classname, "func_button_timed") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_func_button_timed);
    }
    else if(strcmp(classname, "func_button") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_func_button);
    }
    else if(strcmp(classname, "trigger_escape") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_trigger_escape);
    }
}

void OnSpawnPost_func_button_timed(int entity)
{
    char name[64];
    GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
    if(strcmp(name, "generator_button") == 0)
    {
        HookSingleEntityOutput(entity, "OnTimeUp", OnTimeUp);
    }
}

void OnSpawnPost_func_button(int entity)
{
    char name[64];
    GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
    if(strcmp(name, "bridge_start_button") == 0)
    {
        HookSingleEntityOutput(entity, "OnPressed", OnPressed);
    }
}

void OnSpawnPost_trigger_escape(int entity)
{
    char name[64];
    GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
    if(strcmp(name, "bridge_checker") == 0)
    {
        Bridge_trigger = EntIndexToEntRef(entity);
    }
}

public void OnMapInit(const char[] mapName)
{
    if(strcmp(mapName, "c7m3_port") == 0)
    {
        Valid_map = true;
    }
}

public void OnMapEnd()
{
    if(!Valid_map)
    {
        return;
    }
    Valid_map = false;
    Bridge_trigger = -1;
    reset_all();
}

void OnPressed(const char[] output, int caller, int activator, float delay)
{
    if(Enabled)
    {
        return;
    }
    Enabled = true;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
            {
                remove_si(client);
                if(!is_player_alright(client))
                {
                    L4D_ReviveSurvivor(client);
                }
            }
        }
    }
}

void OnTimeUp(const char[] output, int caller, int activator, float delay)
{
    reset_all();
}

void kill_si(int target, int attacker)
{
    CTimer_SetTimestamp(L4D2Direct_GetInvulnerabilityTimer(target), 0.0);
    if(O_ignite)
    {
        IgniteEntity(target, 999.0);
    }
    int health = GetClientHealth(target);
    if(health > 1)
    {
        SDKHooks_TakeDamage(target, attacker, attacker, float(health) - 1.0);
    } 
    SDKHooks_TakeDamage(target, attacker, attacker, 1.0);
}

void kill_horde(int target, int attacker)
{
    if(O_ignite)
    {
        IgniteEntity(target, 999.0);
    }
    int health = GetEntProp(target, Prop_Data, "m_iHealth");
    if(health > 1)
    {
        SDKHooks_TakeDamage(target, attacker, attacker, float(health) - 1.0);
    }
    SDKHooks_TakeDamage(target, attacker, attacker, 1.0);
}

void remove_si(int client)
{
    int attacker = get_special_infected_attacker(client);
    if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker))
    {
        kill_si(client, attacker);
    }
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

int get_special_infected_attacker(int client)
{
    int attacker = -1;
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
    attacker = GetEntDataEnt2(client, Offset_QueuedPummelVictim + _QueuedPummel_Attacker);
    if(attacker > 0)
    {
        return attacker;
    }
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if(attacker > 0)
	{
		return attacker;
	}
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if(attacker > 0)
	{
		return attacker;
	}
	return -1;
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(!Enabled)
    {
        return Plugin_Continue;
    }
    if(GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
    {
        if(attacker > 0)
        {
            if(attacker <= MaxClients)
            {
                if(IsClientInGame(attacker))
                if(GetClientTeam(attacker) == 3 && IsPlayerAlive(attacker))
                {
                    kill_si(attacker, victim);
                }
                damage = 0.0;
                return Plugin_Handled;
            }
            else
            {
                char class_name[64];
                GetEntityClassname(attacker, class_name, sizeof(class_name));
                if(strcmp(class_name, "infected") == 0 || strcmp(class_name, "witch") == 0)
                {
                    kill_horde(attacker, victim);
                    damage = 0.0;
                    return Plugin_Handled;
                }
            }
        }
    }
    return Plugin_Continue;
}

void reset_all()
{
    Enabled = false;
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if(Enabled)
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue; 
}

public Action L4D_OnGrabWithTongue(int victim, int attacker)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D2_OnPummelVictim(int attacker, int victim)
{
    if(Enabled)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    reset_all();
}

void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    reset_all();
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    reset_all();
}

void event_mission_lost(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    reset_all();
}

void event_finale_vehicle_leaving(Event event, const char[] name, bool dontBroadcast)
{
    if(!Valid_map)
    {
        return;
    }
    reset_all();
}

void frame_revive()
{
    if(!Enabled)
    {
        return;
    }
    int bridge = EntRefToEntIndex(Bridge_trigger);
    if(bridge == -1)
    {
        return;
    }
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !is_player_alright(i))
        {
            int[] others = new int[MaxClients];
            int count_others = 0;
            for(int j = 1; j <= MaxClients; j++)
            {
                if(j != i && IsClientInGame(j) && GetClientTeam(j) == 2 && IsPlayerAlive(j) && L4D_IsTouchingTrigger(bridge, j))
                {
                    others[count_others++] = j;
                }
            }
            if(count_others == 0)
            {
                return;
            }
            int target = others[GetRandomInt(0, count_others - 1)];
            float pos[3];
            GetClientAbsOrigin(target, pos);
            L4D_ReviveSurvivor(i);
            SetEntProp(i, Prop_Send, "m_bDucked", 1);
            SetEntityFlags(i, GetEntityFlags(i) | FL_DUCKING);
            TeleportEntity(i, pos);
        }
    }
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
	{
		return;
	}
    RequestFrame(frame_revive);
}

void event_player_ledge_grab(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
	{
		return;
	}
    RequestFrame(frame_revive);
}

void get_all_cvars()
{
    O_ignite = C_ignite.BoolValue;
}

void get_single_cvar(ConVar convar)
{
    if(convar == C_ignite)
    {
        O_ignite = C_ignite.BoolValue;
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
    return APLRes_Success;
}

public void OnPluginStart()
{
    Offset_QueuedPummelVictim = FindSendPropInfo("CTerrorPlayer", "m_pummelAttacker") + 4;

    HookEvent("round_start", event_round_start);
    HookEvent("round_end", event_round_end);
	HookEvent("map_transition", event_map_transition);
	HookEvent("mission_lost", event_mission_lost);
	HookEvent("finale_vehicle_leaving", event_finale_vehicle_leaving);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_ledge_grab", event_player_ledge_grab);

    C_ignite = CreateConVar("c7m3_finale_buff_ignite", "1", "1 = enable, 0 = disable. ignite infected before kill?");
    C_ignite.AddChangeHook(convar_changed);
    CreateConVar("c7m3_finale_buff_version", PLUGIN_VERSION, "version of c7m3 Finale Buff", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	//AutoExecConfig(true, "c7m3_finale_buff");
	get_all_cvars();
}
