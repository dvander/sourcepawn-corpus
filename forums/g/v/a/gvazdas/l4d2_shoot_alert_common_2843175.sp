// Thanks to testers: Hatsune Miku Fan, Krufftys Killers
// Thanks to Silvers for code cleanup and serious optimizations.

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d2_shoot_alert_common"
#define PLUGIN_VERSION 			"1.5 2026-03-12"
#define GAMEDATA_FILE           PLUGIN_NAME
#define CONFIG_FILENAME         PLUGIN_NAME

// When a gun is fired, the position of fire is recorded immediately.

public Plugin myinfo =
{
	name = "[L4D2] Weapon Fire Alert Common",
	author = "gvazdas,Silvers",
	description = "Survivor weapon fire and speech alerts Common Infected (except road workers).",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352360,https://github.com/gvazdas/l4d2_zombie_master"
}

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAXENTITIES         2048
#define MODEL_ROAD          "models/infected/common_male_roadcrew.mdl"
#define DEBUG               0

#if DEBUG
int g_iLaser;
#endif

// Optimizations
Handle timer_hook; // reduce weapon_fire hook/unhook spam
Handle timers[MAXPLAYERS+1]; // reduce weapon_fire and NormalSoundHook spam
bool ignore[MAXENTITIES] = {true,...}; // ignore non-infected, and rushing or road worker infected
float multipliers[MAXPLAYERS+1] = {1.0,...}; // track range multipliers for silent smg, survivor speech
bool weapon_fire_hooked = false; // track weapon_fire hook
bool speech_hooked = false; // track NormalSoundHook
bool finale_active = false; // do nothing during survival and finales
int commons = 0; // track only non-rushing commons
float pos_arr[MAXPLAYERS+1][3]; // calculate position of survivor only once before callback
int alerts[MAXENTITIES]; // force infected rush if alerted too many times
Handle timer_calm; // periodically calm down non-rushing infected

// Inputs
ConVar g_hCvarEnable, g_hCvarAlertRange, g_hCvarAlertProbability, g_hCvarRushRange, g_hCvarLOS, g_hCvarAlertMax, g_hCvarAlertMemory, g_hCvarVoice, g_hCvarMPGameMode;
bool enabled, speech = false;
float alert_range, rush_range, alert_probability, alert_memory, LOS_multiplier, voice_multiplier;
int alert_max;

public void OnPluginStart()
{
    AutoExecConfig(true, CONFIG_FILENAME);
    
    g_hCvarEnable = CreateConVar("l4d2_shoot_alert_common_enable", "1", "0=Plugin off, 1=Plugin on.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);   
    
    g_hCvarAlertRange = CreateConVar("l4d2_shoot_alert_common_range", "2500.0", "Alert range in line of sight.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarAlertRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertProbability = CreateConVar("l4d2_shoot_alert_common_probability", "0.5", "Alert probability.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAlertProbability.AddChangeHook(ConVarChanged_Cvars);  
    
    g_hCvarRushRange = CreateConVar("l4d2_shoot_alert_common_range_rush", "800.0", "Rush range in line of sight. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarRushRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarLOS = CreateConVar("l4d2_shoot_alert_common_los", "2.5", "No-line-of-sight range multiplier.",FCVAR_NOTIFY, true, 1.0, true, 10000.0);
    g_hCvarLOS.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertMax = CreateConVar("l4d2_shoot_alert_common_max", "12", "Number of alerts to rush. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMax.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertMemory = CreateConVar("l4d2_shoot_alert_common_memory", "4.0", "How many seconds to forget 1 alert. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMemory.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarVoice = CreateConVar("l4d2_shoot_alert_common_voice", "0.0", "Survivor voice range multiplier (scales with volume), 0 to disable. 2 is a good value.",FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    g_hCvarVoice.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Gamemode);
    
  	HookEvent("finale_start", 			evtFinaleStart,    EventHookMode_PostNoCopy);
  	HookEvent("finale_radio_start", 	evtFinaleStart,    EventHookMode_PostNoCopy);
  	HookEvent("gauntlet_finale_start", 	evtFinaleStart,    EventHookMode_PostNoCopy);
  	HookEvent("survival_round_start",   evtFinaleStart,    EventHookMode_PostNoCopy);
  	HookEvent("round_start",            evtRound,          EventHookMode_PostNoCopy);
    HookEvent("round_end",              evtRound,          EventHookMode_PostNoCopy);
    GetCvars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue) { GetCvars(); }
void ConVarChanged_Gamemode(ConVar convar, const char[] oldValue, const char[] newValue) { RequestFrame(check_hooks); }

void GetCvars()
{
    alert_range = g_hCvarAlertRange.FloatValue;
    rush_range = g_hCvarRushRange.FloatValue;
    alert_probability = g_hCvarAlertProbability.FloatValue;
    LOS_multiplier = g_hCvarLOS.FloatValue;
    if (g_hCvarVoice.FloatValue != voice_multiplier)
    {
        voice_multiplier = g_hCvarVoice.FloatValue;
        speech = voice_multiplier>0.0;
        if (speech_hooked!=speech) RequestFrame(check_hooks);
    }
    if (alert_max!=g_hCvarAlertMax.IntValue || g_hCvarAlertMemory.FloatValue != alert_memory)
    {
        alert_max = g_hCvarAlertMax.IntValue;
        alert_memory = g_hCvarAlertMemory.FloatValue;
        if (weapon_fire_hooked) // Repeating timer needs to be restarted with new period
        {
            timer_calm = null;
            if (alert_memory>=0.1 && alert_max>0) perform_calm(null,true);
        }
    }
    IsAllowed();
}

void IsAllowed()
{
    if (g_hCvarEnable.BoolValue==enabled) return;
    enabled = g_hCvarEnable.BoolValue;
    if (enabled)
    {
        HookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_spawn", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_activate", evtPlayerTeam, EventHookMode_Post);
        HookEvent("player_bot_replace", EvtBotReplace, EventHookMode_Post);
        HookEvent("bot_player_replace", EvtBotReplace, EventHookMode_Post);
        late_enable();
    }
    else
    {
        UnhookEvent("player_team", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_spawn", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_activate", evtPlayerTeam, EventHookMode_Post);
        UnhookEvent("player_bot_replace", EvtBotReplace, EventHookMode_Post);
        UnhookEvent("bot_player_replace", EvtBotReplace, EventHookMode_Post);
        check_hooks();
    }
}

void check_hooks() // Dynamically hook/unhook weapon_fire and NormalSoundHook for performance.
{
    timer_hook = null;
    bool should_hook = enabled && !finale_active && !L4D_IsSurvivalMode() && get_commons()>0;
    bool should_hook_speech = should_hook && speech;
    if (should_hook!=weapon_fire_hooked)
    {
        if (should_hook) HookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        else UnhookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        weapon_fire_hooked = should_hook;
        if (alert_memory>=0.1 && alert_max>0) perform_calm(null,true); // reset calm timer
        #if DEBUG 
        LogMessage("weapon_fire hook %d", weapon_fire_hooked);
        #endif
    }
    if (should_hook_speech!=speech_hooked)
    {
        if (should_hook_speech) AddNormalSoundHook(SurvivorSpeak);
        else RemoveNormalSoundHook(SurvivorSpeak);
        speech_hooked = should_hook_speech;
        #if DEBUG 
        LogMessage("NormalSoundHook %d", speech_hooked);
        #endif
    }
}

Action timer_check_hooks(Handle timer)
{
    check_hooks();
    return Plugin_Stop;
}

void late_enable() // If plugin just enabled, check if there are any infected entities to alarm.
{
    reset_timers();
    get_commons(false,true);
    if (!weapon_fire_hooked && commons>0) check_hooks();
}

public void OnEntityCreated(int entity, const char[] classname) // Check if this is an infected entity.
{
	if (!enabled || finale_active || L4D_IsSurvivalMode()) return; // always spawns with 0 HP
	if (strcmp(classname,"infected")==0 && GetEntProp(entity,Prop_Send,"m_mobRush")<=0 && infected_can_hear(entity))
	{
    	ignore[entity] = false; alerts[entity] = 0; commons += 1;
    	CreateTimer(1.0,check_aggro,EntIndexToEntRef(entity),TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action check_aggro(Handle timer, int entref) // Check again.
{
    if (!IsValidEntRef(entref))
    {
        commons -= 1;
        return Plugin_Stop;
    }
    int entity = EntRefToEntIndex(entref);
    if (ignore[entity]) return Plugin_Stop; // commons was subtracted somewhere else (hopefully)
    if (is_bad_infected(entity) || !infected_can_hear(entity))
    {
        ignore_infected(entity);
        return Plugin_Stop;
    }
    if (weapon_fire_hooked || timer_hook!=null) return Plugin_Stop; // if already hooked, do nothing
    timer_hook = CreateTimer(0.1,timer_check_hooks,TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

public void OnEntityDestroyed(int entity) // When infected is destroyed, check if hooks needs to be deactivated.
{
	if (!weapon_fire_hooked || !IsValidEntity(entity)) return;
    if (is_infected(entity))
    {
    	commons -= 1;
    	if (commons<=0 && timer_hook==null) timer_hook = CreateTimer(0.1,timer_check_hooks,TIMER_FLAG_NO_MAPCHANGE);
    }
}

void evtPlayerFired(Event event, const char[] name, bool dontBroadcast) // Survivor fired a gun.
{
    if (event.GetInt("count")<=0) return; // melee weapons give 0 count
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (timers[client]!=null || GetClientTeam(client)!=TEAM_SURVIVOR) return;
    static char weapon[128];
    event.GetString("weapon",weapon,sizeof(weapon),""); // 2.0 multiplier for silenced smg
    alert_constructor(client, (StrContains(weapon,"silen",false)>=0) ? 2.0 : 1.0 );
}

Action SurvivorSpeak(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
                     int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
                     char soundEntry[PLATFORM_MAX_PATH], int &seed) // Survivor said something.
{
    if (channel!=SNDCHAN_VOICE || volume<=0.1 || sample[0]!='p' || !IsValidClient(entity) || timers[entity]!=null) return Plugin_Continue;
    if (!IsPlayerAlive(entity) || GetClientTeam(entity)!=TEAM_SURVIVOR) return Plugin_Continue;
    if (strncmp(sample[16],"voice",5)!=0 || strncmp(sample[7],"survivor",8)!=0) return Plugin_Continue;
    #if DEBUG 
    LogMessage("%s %d %f -> %f", sample, level, volume, voice_multiplier/volume);
    #endif
    alert_constructor(entity,voice_multiplier/volume);
    return Plugin_Continue;
}

void alert_constructor(int client, float multiplier = 1.0)
{
    if (multiplier<=0.0) return;
    static float pos[3];
    L4D_GetEntityWorldSpaceCenter(client,pos);
    pos_arr[client][0] = pos[0]; pos_arr[client][1] = pos[1]; pos_arr[client][2] = pos[2];
    multipliers[client] = multiplier;
    timers[client] = CreateTimer(GetRandomFloat(0.5,1.5),alert_update,EntIndexToEntRef(client),TIMER_FLAG_NO_MAPCHANGE);
}

Action alert_update(Handle timer, int entref) // Alert nearby infected.
{
    if (!IsValidEntRef(entref)) return Plugin_Stop; // prevent carry-over to new round
    int client = EntRefToEntIndex(entref);
    if (!IsValidClient(client)) return Plugin_Stop;
    if (timers[client]==null) return Plugin_Stop; // prevent carry-over to new round
    timers[client] = null;
    if (!IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return Plugin_Stop;
    if (FindEntityByClassname(-1, "pipe_bomb_projectile")!=INVALID_ENT_REFERENCE) return Plugin_Stop;
    static float pos[3];
    pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2];
    TR_EnumerateEntitiesSphere(pos,alert_range/multipliers[client],PARTITION_NON_STATIC_EDICTS,AlertCallback,client);
    #if DEBUG
    if (g_iLaser>0 && !IsFakeClient(client))
    {
       	// WHITE - SPHERE, SPHERE/LOS_multiplier | BLUE - ALERT, ALERT/LOS_multiplier | RED - RUSH, RUSH/LOS_multiplier
       	TE_SetupBeamRingPoint(pos,alert_range/multipliers[client],alert_range/multipliers[client]-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,255,255,255},0,0);
        pos[2] += 2.0; TE_SendToClient(client); // draw enumerate sphere (LOS)
        TE_SetupBeamRingPoint(pos,alert_range/multipliers[client]/LOS_multiplier,alert_range/multipliers[client]/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,255,255,255},0,0);
        pos[2] += 2.0; TE_SendToClient(client); // draw enumerate sphere (no LOS)
        TE_SetupBeamRingPoint(pos,alert_range,alert_range-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
        pos[2] += 2.0; TE_SendToClient(client); // draw alert range (LOS)
        TE_SetupBeamRingPoint(pos,alert_range/LOS_multiplier,alert_range/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
        pos[2] += 2.0; TE_SendToClient(client); // draw alert range (no LOS)
        if (rush_range>1.0)
        {
            TE_SetupBeamRingPoint(pos,rush_range,rush_range-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            pos[2] += 2.0; TE_SendToClient(client); // draw rush range (LOS)
            TE_SetupBeamRingPoint(pos,rush_range/LOS_multiplier,rush_range/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            TE_SendToClient(client); // draw rush range (no LOS)
        }
    }
    #endif
    return Plugin_Stop;
}

bool AlertCallback(int entity, int client) // Return true to continue enumerating, false to stop
{
    if (entity<=MaxClients || !IsValidEntity(entity)) return true;
    if (ignore[entity]) return true;
    if (is_infected(entity))
    {
        if (is_bad_infected(entity)) // Ignore rushing and dead infected
        {
            ignore_infected(entity);
            return true;
        }
        
        if (!IsValidClient(client)) return false; // client might disconnect during callback
        
        static float pos[3], pos2[3];
        pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2];
        L4D_GetEntityWorldSpaceCenter(entity,pos2);
        float range = GetVectorDistance(pos,pos2);
        pos2[2] += 36.0; // for ray trace, check infected ear position
        bool LOS = L4D2_IsVisibleToPlayer(client,TEAM_SURVIVOR,3,0,pos2);
        if (!LOS) range *= LOS_multiplier;
        range *= multipliers[client];
        if (range>alert_range) return true;
        #if DEBUG
        LogMessage("AlertCallback client %d infected %d LOS %d multiplier %.2f final range %.1f",client,entity,LOS,multipliers[client],range);
        #endif
        if (rush_range>0.0 && range<=rush_range)
        {
            infected_rush_client(entity,client);
            return true;
        }
        if (alert_probability>=1.0 || GetRandomFloat(0.0,1.0)<alert_probability)
        {
            if (alert_max>0) // Aggro if disturbed too many times.
            {
                alerts[entity] += 1; 
                if (alerts[entity]>=alert_max)
                {
                    infected_rush_client(entity,client);
                    return true;
                }
            }
            int look = GetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget");
            if ( LOS && ( look==client || (IsValidClient(look) && IsPlayerAlive(look) && GetClientTeam(look)==TEAM_SURVIVOR) ) )
                infected_rush_client(entity,client); // Aggro if LOS and was previously looking at any alive survivor.
            else if (look<=0)
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

void infected_rush_client(const int infected, const int client)
{
    #if DEBUG
    LogMessage("infected %d rush %d", infected, client);
    #endif
    SetEntPropEnt(infected, Prop_Send, "m_clientLookatTarget", client); // this might do absolutely nothing.
    SetEntProp(infected, Prop_Send, "m_mobRush", 1);
    ignore_infected(infected);
}

void ignore_infected(const int infected)
{
    ignore[infected] = true;
    commons -= 1;
    if (commons<=0 && timer_hook==null) check_hooks();
}

Action undo_lookat(Handle timer, DataPack pack) // Must have been the wind...
{
    pack.Reset();
    int entref_zombie = pack.ReadCell();
    if (!IsValidEntRef(entref_zombie)) return Plugin_Stop;
    if (is_bad_infected(entref_zombie))
    {
        ignore_infected(EntRefToEntIndex(entref_zombie));
        return Plugin_Stop;
    }
    int entref_client = pack.ReadCell();
    if (!IsValidEntRef(entref_client)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref_client);
    if (GetEntPropEnt(entref_zombie,Prop_Send,"m_clientLookatTarget")==client) SetEntPropEnt(entref_zombie,Prop_Send,"m_clientLookatTarget",-1);
    return Plugin_Stop;
}

public void OnMapStart()
{
    #if DEBUG
    g_iLaser = PrecacheModel("sprites/laserbeam.vmt", true);
    #endif
    if (!enabled) return;
    reset_timers();
    RequestFrame(check_hooks);
}

void evtFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    finale_active = true;
    if (weapon_fire_hooked) RequestFrame(check_hooks);
}

void evtRound(Event event, const char[] name, bool dontBroadcast)
{
    finale_active = false;
    if (!enabled) return;
    reset_timers();
    RequestFrame(check_hooks);
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

int get_commons(bool calm=false, bool late=false) // Counting ONLY non-aggro infected
{
    int entity = -1;
    int count = 0;
   	while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
   	{
      	if (late)
      	{
            if (is_bad_infected(entity) || !infected_can_hear(entity)) { ignore[entity] = true; continue; }
            ignore[entity] = false; alerts[entity] = 0;
      	}
      	else
      	{
            if (ignore[entity]) continue;
            if (is_bad_infected(entity)) { ignore[entity] = true; continue; }
      		if (calm && alerts[entity]>0)
      		{
          		alerts[entity] -= 1;
              	#if DEBUG
                LogMessage("infected %d calmed -> %d", entity, alerts[entity]);
                #endif
          	}
      	}
       	count++;
   	}
   	commons = count;
    return commons;
}

Action perform_calm(Handle timer=null, bool reset = false)
{
    if (!weapon_fire_hooked)
    {
        timer_calm = null;
        return Plugin_Stop; // Plugin_Stop kills periodic timers like this one.
    }
    if ( (timer_calm==null || reset) && alert_memory>=0.1 )
    {
        timer_calm = CreateTimer(alert_memory,perform_calm,false,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Stop;
    }
    if (timer_calm==null || timer!=timer_calm) return Plugin_Stop;
    get_commons(true);
    return Plugin_Continue;
}

void reset_timers()
{
    for( int i = 1; i <= MAXPLAYERS; i++ )
    {
        timers[i] = null;
    }
    timer_hook = null;
    timer_calm = null;
}  

stock bool is_infected(int infected)
{
    static char class[16];
    GetEntityClassname(infected,class,sizeof(class));
    return strcmp(class,"infected")==0;
    //return HasEntProp(infected,Prop_Send,"m_mobRush"); // Silvers benchmarked - this is slower!
}

stock bool is_bad_infected(int infected) // both props change dynamically and need to be monitored.
{
    return GetEntProp(infected,Prop_Send,"m_mobRush")>0 || GetEntProp(infected,Prop_Data,"m_iHealth")<=0;
}

stock bool infected_can_hear(int infected) // prop is set once on entity create and never changed.
{
    static char sModelName[64]; // Road crew have headphones, ignore gunfire.
    GetEntPropString(infected,Prop_Data,"m_ModelName",sModelName,sizeof(sModelName));
    return strcmp(sModelName,MODEL_ROAD)!=0;
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