// Thanks to testers: Hatsune Miku Fan
// Thanks Silvers for finding bugs and scripting help.

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d2_shoot_alert_common"
#define PLUGIN_VERSION 			"1.21 2026-03-09"
#define GAMEDATA_FILE           PLUGIN_NAME
#define CONFIG_FILENAME         PLUGIN_NAME

public Plugin myinfo =
{
	name = "[L4D2] Weapon Fire Alert Common",
	author = "gvazdas",
	description = "Weapon fire alerts Common Infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352360,https://github.com/gvazdas/l4d2_zombie_master"
}

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAXENTITIES         2048
#define MODEL_ROAD          "models/infected/common_male_roadcrew.mdl"

// Optimizations
Handle timer_death; // avoid infected death spam
Handle timers[MAXPLAYERS+1]; // prevent frequent sphere calculations
bool ignore[MAXENTITIES] = {true,...}; // ignore non-infected entities and already rushing infected
bool silent[MAXPLAYERS+1]; // 2x range reduction for silenced smg
bool weapon_fire_hooked = false; // dynamically unhook weapon_fire if there are no commons.
int commons = 0; // track commons to predict when unhook might need to be done
float pos_arr[MAXPLAYERS+1][3]; // calculate position of survivor once -- idk why sphere can't give us this info :/

// Inputs
ConVar g_hCvarEnable, g_hCvarAlertRange, g_hCvarAlertProbability, g_hCvarRushRange, g_hCvarLOS, g_hCvarMPGameMode;
bool enabled = false;
float alert_range = 3000.0;
float rush_range = 800.0;
float alert_probability = 0.5;
float LOS_multiplier = 2.0;

public void OnPluginStart()
{
    AutoExecConfig(true, CONFIG_FILENAME);
    
    g_hCvarEnable = CreateConVar("l4d2_shoot_alert_common_enable", "1", "0=Plugin off, 1=Plugin on.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);   
    
    g_hCvarAlertRange = CreateConVar("l4d2_shoot_alert_common_range", "3000.0", "Range to make commons look at shooter.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarAlertRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertProbability = CreateConVar("l4d2_shoot_alert_common_probability", "0.5", "Probability for gun fire to alert a particular common zombie.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAlertProbability.AddChangeHook(ConVarChanged_Cvars);  
    
    g_hCvarRushRange = CreateConVar("l4d2_shoot_alert_common_range_rush", "800.0", "Range to make commons rush shooter immediately.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarRushRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarLOS = CreateConVar("l4d2_shoot_alert_common_los", "2.0", "Range multiplier when there is no line-of-sight to survivor.",FCVAR_NOTIFY, true, 1.0, true, 10000.0);
    g_hCvarLOS.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Gamemode);
    
    GetCvars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void ConVarChanged_Gamemode(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RequestFrame(check_hook_weapon_fire);
}

void GetCvars()
{
    alert_range = g_hCvarAlertRange.FloatValue;
    rush_range = g_hCvarRushRange.FloatValue;
    alert_probability = g_hCvarAlertProbability.FloatValue;
    LOS_multiplier = g_hCvarLOS.FloatValue;
    IsAllowed();
}

void IsAllowed()
{
    if (g_hCvarEnable.BoolValue==enabled) return;
    enabled = g_hCvarEnable.BoolValue;
    RequestFrame(check_hook_weapon_fire);
    if (enabled)
    {
        HookEvent("round_start",   evtRound,  EventHookMode_PostNoCopy);
        HookEvent("round_end",   evtRound,  EventHookMode_PostNoCopy);
        HookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_spawn", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_activate", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_bot_replace", EvtBotReplace, EventHookMode_Post);
        HookEvent("bot_player_replace", EvtBotReplace, EventHookMode_Post);
  		HookEvent("finale_start", 			evtFinaleStart, EventHookMode_PostNoCopy); //final starts, some of final maps won't trigger
  		HookEvent("finale_radio_start", 	evtFinaleStart, EventHookMode_PostNoCopy); //final starts, all final maps trigger
  		HookEvent("gauntlet_finale_start", 	evtFinaleStart, EventHookMode_PostNoCopy); //final starts, only rushing maps trigger (C5M5, C13M4)
  		HookEvent("survival_round_start", Event_SurvivalRoundStart,EventHookMode_PostNoCopy);
        reset_timers();
    }
    else
    {
        UnhookEvent("round_start",   evtRound,	 EventHookMode_PostNoCopy);
        UnhookEvent("round_end",   evtRound,  EventHookMode_PostNoCopy);
        UnhookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_spawn", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_activate", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_bot_replace", EvtBotReplace, EventHookMode_Post);
        UnhookEvent("bot_player_replace", EvtBotReplace, EventHookMode_Post);
        UnhookEvent("finale_start", 		evtFinaleStart, EventHookMode_PostNoCopy); //final starts, some of final maps won't trigger
		UnhookEvent("finale_radio_start", 	evtFinaleStart, EventHookMode_PostNoCopy); //final starts, all final maps trigger
		UnhookEvent("gauntlet_finale_start",evtFinaleStart, EventHookMode_PostNoCopy); //final starts, only rushing maps trigger (C5M5, C13M4)
		UnhookEvent("survival_round_start", Event_SurvivalRoundStart,EventHookMode_PostNoCopy);
    }
}

void check_hook_weapon_fire()
{
    timer_death = null;
    bool should_hook = enabled && !L4D_IsSurvivalMode() && !L4D_IsFinaleActive() && get_commons()>0;
    if (should_hook==weapon_fire_hooked) return;
    if (should_hook)
    {
        HookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        LogMessage("hook weapon_fire");
    }
    else
    {
        UnhookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        LogMessage("unhook weapon_fire");
    }
    weapon_fire_hooked = should_hook;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname,"infected")==0)
	{
    	ignore[entity] = false;
    	commons += 1;
    	if (enabled && !weapon_fire_hooked && timer_death==null)
        	timer_death = CreateTimer(0.1,timer_check_hook_weapon_fire);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!weapon_fire_hooked) return;
	static char class[16];
    GetEntityClassname(entity, class, sizeof(class));
    if (strcmp(class,"infected")==0)
    {
    	commons -= 1;
    	if (commons<=1 && timer_death==null)
        	timer_death = CreateTimer(0.1,timer_check_hook_weapon_fire);
    }
}

Action timer_check_hook_weapon_fire(Handle timer)
{
    check_hook_weapon_fire();
    return Plugin_Stop;
}

void evtPlayerFired(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetInt("count")<=0) return; // melee weapons give 0 count
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GetClientTeam(client)!=TEAM_SURVIVOR) return;
    if (timers[client]==null)
    {
        static char weapon[128]; // weapon id would be more efficient i suppose
        event.GetString("weapon",weapon,sizeof(weapon),"");
        silent[client] = StrContains(weapon,"silen",false)>=0;
        timers[client] = CreateTimer(GetRandomFloat(0.5,1.0),alert_update,EntIndexToEntRef(client),TIMER_FLAG_NO_MAPCHANGE);
    }
}

// GUNFIRE!
Action alert_update(Handle timer, int entref)
{
    if (!IsValidEntRef(entref)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref);
    if (timers[client]==null) return Plugin_Stop; //prevent carry-over to new round
    timers[client] = null;
    if (!IsValidClient(client)) return Plugin_Stop;
    if (!IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return Plugin_Stop;
    if (FindEntityByClassname(-1,"info_goal_infected_chase")!=INVALID_ENT_REFERENCE) return Plugin_Stop;
    if (FindEntityByClassname(-1, "pipe_bomb_projectile")!=INVALID_ENT_REFERENCE) return Plugin_Stop;
    static float pos[3];
    L4D_GetEntityWorldSpaceCenter(client,pos);
    pos_arr[client][0] = pos[0]; pos_arr[client][1] = pos[1]; pos_arr[client][2] = pos[2];
    TR_EnumerateEntitiesSphere(pos,alert_range,PARTITION_NON_STATIC_EDICTS,AlertCallback,client);
    return Plugin_Stop;
}

bool AlertCallback(int entity, int client)
{
    // Return true to continue enumerating, false to stop
    if (entity<=MaxClients || !IsValidEntity(entity)) return true;
    if (ignore[entity]) return true;
    static char class[16];
    GetEntityClassname(entity, class, sizeof(class));
    if (strcmp(class,"infected")==0)
    {
        // If already rushing, do nothing.
        if (GetEntProp(entity,Prop_Send,"m_mobRush")>0)
        {
            ignore[entity] = true;
            return true;
        }
        
        // Road crew have headphones, ignore gunfire.
        static char sModelName[64];
        GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
        if (strcmp(sModelName,MODEL_ROAD)==0)
        {
            ignore[entity] = true;
            return true;
        }
        
        if (!IsValidClient(client)) return false; // just in case.
        
        static float pos[3], pos2[3];
        pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2];
        L4D_GetEntityWorldSpaceCenter(entity,pos2);
        float range = GetVectorDistance(pos,pos2);
        pos2[2] += 36.0;
        bool LOS = L4D2_IsVisibleToPlayer(client,TEAM_SURVIVOR,3,0,pos2);
        if (!LOS) range *= LOS_multiplier;
        if (silent[client]) range *= 2.0;
        
        if (range<=rush_range)
        {
            zombie_rush_client(entity,client);
            return true;
        }
        if (range>alert_range) return true;
        if (alert_probability>=1.0 || GetRandomFloat(0.0,1.0)<alert_probability)
        {
            int lookat = GetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget");
            if (lookat==client && LOS) zombie_rush_client(entity,client);
            else if (lookat<=0)
            {
                SetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget",client);
                DataPack pack;
                CreateDataTimer(GetRandomFloat(1.5,2.5),undo_lookat,pack,TIMER_FLAG_NO_MAPCHANGE);
                pack.WriteCell(EntIndexToEntRef(entity));
                pack.WriteCell(EntIndexToEntRef(client));
            }
        }
    }
    else ignore[entity] = true;
    return true;
}

void zombie_rush_client(int zombie, int client)
{
    SetEntPropEnt(zombie, Prop_Send, "m_clientLookatTarget",client); // this might do absolutely nothing.
    SetEntProp(zombie, Prop_Send, "m_mobRush", 1);
    ignore[zombie] = true;
}

// Must have been the wind.
Action undo_lookat(Handle timer, DataPack pack)
{
    pack.Reset();
    int entref_zombie = pack.ReadCell();
    if (!IsValidEntRef(entref_zombie)) return Plugin_Stop;
    if (GetEntProp(entref_zombie, Prop_Send, "m_mobRush")>0)
    {
        ignore[EntRefToEntIndex(entref_zombie)] = true;
        return Plugin_Stop;
    }
    int entref_client = pack.ReadCell();
    if (!IsValidEntRef(entref_client)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref_client);
    if (GetEntPropEnt(entref_zombie, Prop_Send, "m_clientLookatTarget")==client)
        SetEntPropEnt(entref_zombie, Prop_Send, "m_clientLookatTarget",-1);
    return Plugin_Stop;
}

public void OnMapStart()
{
    if (!enabled) return;
    reset_timers();
    RequestFrame(check_hook_weapon_fire);
}

void Event_SurvivalRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (weapon_fire_hooked) RequestFrame(check_hook_weapon_fire);
}

void evtFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    if (weapon_fire_hooked) RequestFrame(check_hook_weapon_fire);
}

void EvtBotReplace(Event event, const char[] name, bool dontBroadcast) 
{
    int bot = GetClientOfUserId(event.GetInt("bot"));
    int client = GetClientOfUserId(event.GetInt("player"));
    if (IsValidClient(client)) timers[client] = null;
    if (IsValidClient(bot)) timers[bot] = null;
}

void evtPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client)) timers[client] = null;
}

void evtRound(Event event, const char[] name, bool dontBroadcast)
{
    reset_timers();
    RequestFrame(check_hook_weapon_fire);
}

int get_commons()
{
    commons = L4D_GetCommonsCount();
    return commons;
}

void reset_timers()
{
    for( int i = 1; i <= MAXPLAYERS; i++ )
    {
        timers[i] = null;
    }
    timer_death = null;
}  

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client<1 || client>MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

stock bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;	
}