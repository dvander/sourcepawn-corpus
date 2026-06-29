// Thanks to testers: Hatsune Miku Fan, Krufftys Killers
// Thanks to SilverShot for code cleanup and serious optimizations.

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <files>
#include <left4dhooks>

#define PLUGIN_NAME			"l4d2_shoot_alert_common"
#define PLUGIN_VERSION 		"2.12 2026-04-29"
#define CONFIG_FILENAME      PLUGIN_NAME

public Plugin myinfo =
{
	name = "[L4D2] Weapon Fire Alert Common",
	author = "gvazdas, SilverShot",
	description = "Survivor gunfire and speech alerts Common Infected (except road workers).",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=352360, https://github.com/gvazdas/l4d2_zombie_master"
}

enum // ty Silvers
{
	TYPE_CEDA			= 11,
	TYPE_MUD_MEN		= 12,
	TYPE_ROAD_WORKER	= 13,
	TYPE_FALLEN		= 14,
	TYPE_RIOT			= 15,
	TYPE_CLOWN		= 16,
	TYPE_JIMMY_GIBBS	= 17
}

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define MAXENTITIES         2048
#define DEBUG               0 // 1 for basic debug, 2 for more spammy with details

#if DEBUG
int g_iLaser;
#endif

// Optimizations
Handle timer_hook; // weapon_fire hook/unhook
Handle timers[MAXPLAYERS+1]; // one pending alert for each client on a timer
bool ignore[MAXENTITIES+1] = {true,...}; // ignore non-infected entities, and mob rushing or road worker infected
float multipliers[MAXPLAYERS+1] = {1.0,...}; // client alert/rush range multipliers based on weapon type and speech volume
bool weapon_fire_hooked = false; // track weapon_fire hook
bool speech_hooked = false; // track NormalSoundHook
bool finale_active = false; // do nothing during survival and finales
int commons = 0; // take into account only non-rushing, non-road-worker commons
float pos_arr[MAXPLAYERS+1][3]; // position of alert. not centered on client for grenade explosions
int alerts[MAXENTITIES+1]; // track infected alerts in memory; force rush if alerted too many times
Handle timer_calm; // periodically calm down non-rushing infected
int shots[MAXPLAYERS+1]; // accumulate gunfire before callback, if accumulate cvar is 1.0
float weaponid_multipliers[L4D2WeaponId_MAX] = {-1.0,...}; // multipliers for each weaponID; -1.0 to use default value.
bool local[MAXPLAYERS+1]; // true if alert is localized at client position. false for grenade and pipe bomb detonation
int nearest[MAXPLAYERS+1]; // nearest client to alert center (for pipe bomb, grenade detonation)
int roundcount; // prevent alerts from firing next round
int roundcounts[MAXPLAYERS+1];

bool l4dhooks_updated; // check if l4dhooks is new enough
bool enumerate_new = true; // 2026-03-15 new enumeration method using L4D_FindEntityByClassnameWithin 

// Inputs
ConVar g_hCvarEnable, g_hCvarAlertRange, g_hCvarAlertProbability, g_hCvarRushRange, g_hCvarLOS, g_hCvarAlertMax,
g_hCvarAlertMemory, g_hCvarVoice, g_hCvarAccumulate, g_hCvarSaferoom, g_hCvarMPGameMode, g_hCvarBudget;
bool enabled, speech, accumulate, saferoom = false;
float alert_range, rush_range, alert_probability, alert_memory, LOS_multiplier, voice_multiplier;
int alert_max;

Action request_reset(int client, int args)
{
    char command[PLATFORM_MAX_PATH];
    Format(command, sizeof(command), "exec sourcemod/%s", CONFIG_FILENAME);
    ServerCommand(command);
    return Plugin_Stop;
}

public void OnPluginStart()
{   
    AutoExecConfig(true, CONFIG_FILENAME);
    RegAdminCmd("l4d2_shoot_alert_common_resetcvars", request_reset, ADMFLAG_ROOT, "Reload default cfg. Admins only.");
    
    l4dhooks_updated = GetFeatureStatus(FeatureType_Native,"L4D_FindEntityByClassnameNearest")==FeatureStatus_Available;
    if (!l4dhooks_updated) LogMessage("WARNING: update l4dhooks for better performance.");

    populate_multipliers(); // Populate table of weaponid range multipliers.
    
    g_hCvarEnable = CreateConVar("l4d2_shoot_alert_common_enable", "1", "0=OFF, 1=ON.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);   
    
    g_hCvarAlertRange = CreateConVar("l4d2_shoot_alert_common_range", "2500.0", "Alert range in line of sight for multiplier=1.0. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarAlertRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertProbability = CreateConVar("l4d2_shoot_alert_common_probability", "0.5", "Alert probability. (rush probability is always 1.0)",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAlertProbability.AddChangeHook(ConVarChanged_Cvars);  
    
    g_hCvarRushRange = CreateConVar("l4d2_shoot_alert_common_range_rush", "800.0", "Rush range in line of sight for multiplier=1.0. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 100000.0);
    g_hCvarRushRange.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarLOS = CreateConVar("l4d2_shoot_alert_common_los", "2.5", "No-line-of-sight range multiplier.",FCVAR_NOTIFY, true, 1.0, true, 10000.0);
    g_hCvarLOS.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertMax = CreateConVar("l4d2_shoot_alert_common_max", "12", "Number of alerts in zombie memory to rush. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMax.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertMemory = CreateConVar("l4d2_shoot_alert_common_memory", "4.0", "How many seconds to forget 1 alert. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMemory.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarVoice = CreateConVar("l4d2_shoot_alert_common_voice", "2.0", "Survivor voice range multiplier (scales with volume). 0 to disable. 2 is a good value. -1.0 for default.",FCVAR_NOTIFY, true, -1.0, true, 1000.0);
    g_hCvarVoice.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAccumulate = CreateConVar("l4d2_shoot_alert_common_accumulate", "0.0", "Set to 1 for hardcore realism. Any extra gunfire between shot and delayed response is accumulated for alert calculations.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAccumulate.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarSaferoom = CreateConVar("l4d2_shoot_alert_common_saferoom", "0.0", "Enable alert and rush when survivors are in start area.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarSaferoom.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarBudget = CreateConVar("l4d2_shoot_alert_common_budget_ms", "5.0", "CPU budget in ms for each alert. 0.0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    
    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Gamemode);
    
    HookEvent("finale_start", 		    evtFinaleStart,    EventHookMode_PostNoCopy);
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
    bool update = false; // should hooks be checked?
    alert_range = g_hCvarAlertRange.FloatValue;
    rush_range = g_hCvarRushRange.FloatValue;
    alert_probability = g_hCvarAlertProbability.FloatValue;
    LOS_multiplier = g_hCvarLOS.FloatValue;
    accumulate = g_hCvarAccumulate.BoolValue;
    if (g_hCvarVoice.FloatValue != voice_multiplier)
    {
        voice_multiplier = g_hCvarVoice.FloatValue;
        if (voice_multiplier<0.0) voice_multiplier = weaponid_multipliers[0]; // use default value
        speech = voice_multiplier>0.0;
        if (speech_hooked!=speech) update = true;
    }
    if (alert_max!=g_hCvarAlertMax.IntValue || g_hCvarAlertMemory.FloatValue != alert_memory)
    {
        alert_max = g_hCvarAlertMax.IntValue;
        alert_memory = g_hCvarAlertMemory.FloatValue;
        if (weapon_fire_hooked && alert_memory>=0.1 && alert_max>0) perform_calm(null,true);
    }
    if (saferoom!=g_hCvarSaferoom.BoolValue)
    {
        saferoom = g_hCvarSaferoom.BoolValue;
        update = true;
    }
    if ( (alert_range<=0.0 || alert_probability<=0.0) && rush_range<=0.0) SetConVarInt(g_hCvarEnable,0); // user error
    IsAllowed();
    if (update) RequestFrame(check_hooks);
}

void IsAllowed()
{
    if (g_hCvarEnable.BoolValue==enabled) return;
    enabled = g_hCvarEnable.BoolValue;
    if (enabled) late_enable();
    else check_hooks();
}

#define HOOKS_AUTO 0
#define HOOKS_FORCE_OFF 1
#define HOOKS_FORCE_ON 2

void check_hooks(int state = HOOKS_AUTO) // Dynamically hook/unhook weapon_fire and NormalSoundHook for performance.
{
    timer_hook = null;
    if (!finale_active && L4D_IsSurvivalMode()) finale_active = true;
    bool should_hook;
    switch (state)
    {
        case HOOKS_AUTO:
        {
            should_hook = enabled && !finale_active && L4D_IsInIntro()<=0 && (saferoom || L4D_HasAnySurvivorLeftSafeArea()) && get_commons()>0;
        }
        case HOOKS_FORCE_OFF: should_hook = false;
        case HOOKS_FORCE_ON: should_hook = enabled;
    }
    if (should_hook!=weapon_fire_hooked)
    {
        if (should_hook)
        {
            reset_timers();
            HookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        }
        else UnhookEvent("weapon_fire", evtPlayerFired, EventHookMode_Post);
        weapon_fire_hooked = should_hook;
        if (alert_memory>=0.1 && alert_max>0) perform_calm(null,true); // reset calm timer
        #if DEBUG
        LogMessage("commons %d finale/survival %d intro %d -> weapon_fire hook %d", commons, finale_active, L4D_IsInIntro(), weapon_fire_hooked);
        #endif
    }
    bool should_hook_speech = should_hook && speech;
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

Action timer_check_hooks(Handle timer, int state = HOOKS_AUTO)
{
    check_hooks(state);
    return Plugin_Stop;
}

public void L4D_OnFinishIntro()
{
    if (!enabled || weapon_fire_hooked || timer_hook!=null) return;
    timer_hook = CreateTimer(0.1,timer_check_hooks,_,TIMER_FLAG_NO_MAPCHANGE);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post()
{
    if (!enabled || weapon_fire_hooked || timer_hook!=null) return;
    timer_hook = CreateTimer(0.1,timer_check_hooks,_,TIMER_FLAG_NO_MAPCHANGE);
}

void late_enable() // If plugin just enabled, check if there are any infected entities to alarm.
{
    for(int entity = 0; entity<=MAXENTITIES; entity++) { ignore[entity] = true; }
    get_commons(false,true);
    if (!weapon_fire_hooked && commons>0) check_hooks();
    else reset_timers();
}


public void OnEntityCreated(int entity, const char[] classname) // Check if this is an infected entity.
{
	if (!enabled || !IsValidEdict(entity)) return;
	ignore[entity] = true; // ignore alerts from before zombie spawned
    if (!finale_active && L4D_IsSurvivalMode()) finale_active = true;
	if (finale_active) return;
	if (strncmp(classname,"infected",8,false)==0 && GetEntProp(entity,Prop_Send,"m_mobRush")<=0)
	{
       	CreateTimer(1.51,check_aggro,EntIndexToEntRef(entity),TIMER_FLAG_NO_MAPCHANGE); // prevent zombie from alerting retroactively
	}
}

Action check_aggro(Handle timer, int entref) // Check again.
{
    if (!IsValidEntRef(entref)) return Plugin_Stop;
    int entity = EntRefToEntIndex(entref);
    if (is_bad_infected(entity) || !infected_can_hear(entity))
    {
        ignore_infected(entity);
        return Plugin_Stop;
    }
    else if (ignore[entity]) // may have been already fixed by count commons
    {
        ignore[entity] = false; alerts[entity] = 0; commons += 1;
    }
    if (weapon_fire_hooked || timer_hook!=null) return Plugin_Stop; // if already hooked, do nothing
    timer_hook = CreateTimer(0.1,timer_check_hooks,_,TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

public void OnEntityDestroyed(int entity) // When infected is destroyed, check if hooks need to be deactivated.
{
    if (!weapon_fire_hooked || !IsValidEntity(entity)) return;
    if (is_infected(entity))
    {
        commons -= 1;
        if (commons<=0 && timer_hook==null) timer_hook = CreateTimer(2.0,timer_check_hooks,_,TIMER_FLAG_NO_MAPCHANGE);
    }
}


void evtPlayerFired(Event event, const char[] name, bool dontBroadcast) // Survivor fired a gun.
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidAliveSurvivor(client)) return;
    int weaponid = event.GetInt("weaponid");
    int count = event.GetInt("count");
    if (count<=0) // 0 count is returned by melee weapons and mounted weapons (minigun, 50 cal)
    {
        if (view_as<L4D2WeaponId>(weaponid)!=L4D2WeaponId_Ammo) return;
    }
    else if (view_as<L4D2WeaponId>(weaponid)==L4D2WeaponId_GrenadeLauncher) return; // grenade detonation event will alert instead.
    float multiplier = get_weaponid_multiplier(weaponid);
    #if DEBUG>1
        LogMessage("%d fired %d, %d bullets -> %f", client, weaponid, count, multiplier);
    #endif
    if (multiplier<=0.0) return; // 0.0 multiplier weapons are silent
    if (timers[client]!=null) // check if there is a pending alert
    {
        #if DEBUG>1
            LogMessage("%d timer already exists %d, valid %d", client, timers[client], timers[client]!=null);
        #endif
        if (multipliers[client]>multiplier) multipliers[client] = multiplier; // elevate to louder alert source
        if (accumulate) shots[client] += 1;
        return;
    }
    alert_constructor(client,client,multiplier);
}

// This fires many times for the same voice line depending on number of clients!!!!!
Action SurvivorSpeak(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
                     int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
                     char soundEntry[PLATFORM_MAX_PATH], int &seed) // Survivor said something.
{
    if (channel!=SNDCHAN_VOICE || volume<=0.1 || sample[0]!='p' || !IsValidAliveSurvivor(entity)) return Plugin_Continue;
    if (strncmp(sample[16],"voice",5)!=0 || strncmp(sample[7],"survivor",8)!=0) return Plugin_Continue;
    float multiplier = voice_multiplier/volume;
    if (timers[entity]!=null)
    {
        if (multipliers[entity]>multiplier) multipliers[entity] = multiplier; // elevate to louder alert source
        return Plugin_Continue;
    }
    #if DEBUG>1 
    LogMessage("%d %s %d %f -> %f", entity, sample, level, volume, voice_multiplier/volume);
    #endif
    alert_constructor(entity,entity,multiplier);
    return Plugin_Continue;
}

public void L4D2_GrenadeLauncher_Detonate_Post(int entity, int client)
{
    if (!weapon_fire_hooked) return;
    float multiplier = get_weaponid_multiplier(L4D2WeaponId_GrenadeLauncher);
    #if DEBUG 
    LogMessage("%d detonated grenade %d -> %f", client,entity,multiplier);
    #endif
    reset_timers(false,true); // louder than guns and voices
    alert_constructor(entity,client,multiplier,true);
}

public void L4D_PipeBombProjectile_Post(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
    if (!weapon_fire_hooked || !IsValidAliveSurvivor(client)) return;
    #if DEBUG 
    LogMessage("%d threw pipebomb %d", client, projectile);
    #endif
    reset_timers(false,true); // louder than guns and voices
}

public void L4D_PipeBomb_Detonate_Post(int entity, int client)
{
    if (!weapon_fire_hooked) return;
    static char class[32];
    GetEntityClassname(entity,class,sizeof(class)); 
    if (strncmp(class,"pipe_bomb_projectile",20,false)!=0) return; // bug noted in l4dhooks documentation
    #if DEBUG 
    LogMessage("%d detonated %s %d", client, class, entity);
    #endif
    reset_timers(false,true); // louder than guns and voices
    float multiplier = get_weaponid_multiplier(L4D2WeaponId_GrenadeLauncher);
    alert_constructor(entity,client,multiplier,true);
}

// entity where center should be, client is owner. force to ignore pipebomb
void alert_constructor(int entity, int client, float multiplier = 1.0, bool force = false)
{
    if (multiplier<=0.0) return; // 0.0 multipliers mean silence.
    if (IsValidClient(client) && entity==client && timers[client]!=null) return; // if local and alert already pending, skip
    if (!force && pipe_bomb_active()) return; // pipe bombs are louder than any gun or voice.
    static float pos[3];
    if (entity==client) GetClientEyePosition(client,pos); // if local, use client eye position
    else GetEntPropVector(entity,Prop_Send,"m_vecOrigin",pos); // otherwise use explosion origin
    if (!IsValidAliveSurvivor(client)) // if owner is not a valid survivor, assign nearest survivor as owner.
    {
        #if DEBUG
        int client_old = client;
        #endif
        client = NearestAliveSurvivor(pos,_,client==entity); // find nearest alive survivor without pending alert; if alert is explosion, any survivor
        if (client<=0) return;
        #if DEBUG
        LogMessage("alert_constructor: %d hotswapped to %d", client_old, client);
        #endif
    }
    pos_arr[client][0] = pos[0]; pos_arr[client][1] = pos[1]; pos_arr[client][2] = pos[2];
    shots[client] = 1;
    multipliers[client] = multiplier;
    local[client] = client==entity;
    roundcounts[client] = roundcount;
    timers[client] = CreateTimer(GetRandomFloat(0.5,1.5),alert_update,client,TIMER_FLAG_NO_MAPCHANGE);
}

#if DEBUG
int g_iEnumerated, g_iAlert, g_iRush; // how many entities were enumerated
#endif
float g_fTimeAlertStart; // track CPU budget

Action alert_update(Handle timer, int client) // Delayed alert nearby infected.
{
    if (!weapon_fire_hooked || roundcounts[client]!=roundcount || (timer!=timers[client] && local[client]) ) // alert was cancelled.
    {
        timers[client] = null;
        return Plugin_Stop;
    }
    timers[client] = null;
    
    #if DEBUG
    g_iEnumerated = 0;
    g_iAlert = 0;
    g_iRush = 0;
    #endif
    g_fTimeAlertStart = GetEngineTime();
    
    float max_range = get_max_range(multipliers[client]);
    if (max_range<=32.0) return Plugin_Stop; // range too small to catch anything.
    //if (local[client] && pipe_bomb_active()) return Plugin_Stop; // unless we are a grenade, pipe bombs are louder
    static float pos[3];
    pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2];
    if (l4dhooks_updated && L4D_FindEntityByClassnameNearest("infected",pos,max_range)==INVALID_ENT_REFERENCE) return Plugin_Stop;
    //if (local[client] && rush_range>0.0 && l4dhooks_updated) L4D2_RushVictim(client,range_rush_effective/LOS_multiplier);
    
    int client_final = client; // final client for alerting.
    bool undo_hotswap = false; // track if hotswap should be reversed
    int result_nearest = -1; // cache NearestAliveSurvivor(pos,max_range) result which may be reused later
    if (!IsValidAliveSurvivor(client_final)) // If old client disconnected, died, swapped teams, went AFK, etc. -> swap to nearest alive survivor
    {
        client_final = NearestAliveSurvivor(pos,max_range,true); // try nearest alive survivor without pending alert
        if (client_final<=0)
        {
            client_final = NearestAliveSurvivor(pos,max_range); // try nearest alive survivor
            undo_hotswap = true; // there is a pending alert, need to restore old parameters
            result_nearest = client_final;
        }
        if (client_final<=0) return Plugin_Stop; // no alive survivors within range
        #if DEBUG
        LogMessage("%d hotswapped to %d", client, client_final);
        #endif
        client_hotswap(client_final,client);
    }
    
    if (local[client_final]) nearest[client_final] = client_final;
    else nearest[client_final] = (result_nearest>=0) ? result_nearest : NearestAliveSurvivor(pos,max_range);
    
    if (enumerate_new && l4dhooks_updated) EnumerateInfectedWithin(pos,max_range,client_final);
    else TR_EnumerateEntitiesSphere(pos,max_range,PARTITION_NON_STATIC_EDICTS,AlertCallback_Sphere,client_final);
    
    #if DEBUG
    float t_elapsed_ms = (GetEngineTime()-g_fTimeAlertStart)*1000.0;
    if (g_iLaser>0 && !IsFakeClient(client_final))
    {
        float range_alert_effective = alert_range/multipliers[client_final];
        if (range_alert_effective>1.0) // BLUE:ALERT,ALERT/LOS
        {
            TE_SetupBeamRingPoint(pos,range_alert_effective,range_alert_effective-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
            pos[2] += 3.0; TE_SendToClient(client_final); // LOS
            TE_SetupBeamRingPoint(pos,range_alert_effective/LOS_multiplier,range_alert_effective/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
            pos[2] += 3.0; TE_SendToClient(client_final); // no LOS
        }
        float range_rush_effective = rush_range/multipliers[client_final];
        if (range_rush_effective>1.0) // RED:RUSH,RUSH/LOS
        {
            TE_SetupBeamRingPoint(pos,range_rush_effective,range_rush_effective-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            pos[2] += 3.0; TE_SendToClient(client_final); // LOS
            TE_SetupBeamRingPoint(pos,range_rush_effective/LOS_multiplier,range_rush_effective/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            TE_SendToClient(client_final); // no LOS
        }
    }
    if (g_iEnumerated<=0) g_iEnumerated = 1; // prevent division by 0
    LogMessage("%d %f -> %d entities (%d alert %d rush) %f ms (%f avg)",
    client_final, multipliers[client_final], g_iEnumerated, g_iAlert, g_iRush, t_elapsed_ms, t_elapsed_ms/g_iEnumerated);
    #endif
    if (undo_hotswap) client_hotswap(client_final); // restore pending alert
    return Plugin_Stop;
}

float hotswap_pos[3];
float hotswap_multiplier;
bool hotswap_local;
// Send client_old params to client_new. Store client_new values for later restore
// if client_old<0, restore cached values into client_new position
void client_hotswap(int client_new, int client_old = -1)
{
    if (client_old>=0) // Cache
    {
        hotswap_pos[0] = pos_arr[client_new][0];
        hotswap_pos[1] = pos_arr[client_new][1];
        hotswap_pos[2] = pos_arr[client_new][2];
        hotswap_local = local[client_new];
        hotswap_multiplier = multipliers[client_new];
    }
    pos_arr[client_new][0] = (client_old>=0) ? pos_arr[client_old][0] : hotswap_pos[0];
    pos_arr[client_new][1] = (client_old>=0) ? pos_arr[client_old][1] : hotswap_pos[1];
    pos_arr[client_new][2] = (client_old>=0) ? pos_arr[client_old][2] : hotswap_pos[2];
    local[client_new] = (client_old>=0) ? local[client_old] : hotswap_local;
    multipliers[client_new] = (client_old>=0) ? multipliers[client_old] : hotswap_multiplier;
}

void EnumerateInfectedWithin(float pos[3], float range, int client)
{
    int entity = INVALID_ENT_REFERENCE;
    while( (entity = L4D_FindEntityByClassnameWithin(entity,"infected",pos,range)) != INVALID_ENT_REFERENCE )
    {
        if (!AlertCallback(entity,client)) break;
    }
}

bool AlertCallback_Sphere(int entity, int client) // For legacy function where we need to verify entity index.
{
    if (entity<=MaxClients || !IsValidEdict(entity)) return true;
    return AlertCallback(entity,client);
}

bool AlertCallback(int entity, int client) // Return true to continue enumerating, false to stop
{
    if (!weapon_fire_hooked) return false;
    if (ignore[entity]) return true;
    if (g_hCvarBudget.FloatValue>0.0)
    {
        if ( (GetEngineTime()-g_fTimeAlertStart)*1000.0 >= g_hCvarBudget.FloatValue )
        {
            #if DEBUG
            LogMessage("WARNING: CPU budget (%f ms) exceeded", g_hCvarBudget.FloatValue);
            #endif
            return false;
        }
    }
    #if DEBUG
    g_iEnumerated += 1;
    #endif
    if (is_bad_infected(entity)) // Ignore rushing and dead infected
    {
        ignore_infected(entity);
        return true;
    }
    static float pos[3], pos2[3]; // alert position and infected position
    pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2]; // alert position
    GetEntPropVector(entity,Prop_Send,"m_vecOrigin",pos2); // infected position
    pos2[2] += 60.0; // move to infected ear position
    float range = GetVectorDistance(pos,pos2) * multipliers[client];
    //bool LOS = L4D2_IsVisibleToPlayer(client,TEAM_SURVIVOR,3,0,pos2);
    bool LOS = !los_blocked(pos2,pos,entity);
    if (!LOS) range *= LOS_multiplier;
    #if DEBUG>1
    LogMessage("cb %d shots %d zombie %d LOS %d x%.2f range_eff %.1f",client,shots[client],entity,LOS,multipliers[client],range);
    #endif
    if (rush_range>0.0 && range<=rush_range)
    {
        infected_rush_client(entity,client,nearest[client]);
        return true;
    }
    if (range>alert_range || alert_range<=0.0 || alert_probability<=0.0) return true;
    if (alert_probability>=1.0 || GetRandomFloat(0.0,1.0)<alert_probability)
    {
        if (alert_max>0) // Aggro if disturbed too many times.
        {
            alerts[entity] += shots[client];
            if (alerts[entity]>=alert_max)
            {
                infected_rush_client(entity,client,nearest[client]);
                return true;
            }
        }
        int look = GetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget");
        if ( LOS && ( look==client || IsValidAliveSurvivor(look) ) )
        {
            infected_rush_client(entity,client,nearest[client]); // Aggro if LOS and was previously looking at any alive survivor.
            return true;
        }
        else if (look<=0)
        {
            SetEntPropEnt(entity, Prop_Send, "m_clientLookatTarget",client);
            DataPack pack;
            CreateDataTimer(GetRandomFloat(1.75,3.5),undo_lookat,pack,TIMER_FLAG_NO_MAPCHANGE);
            pack.WriteCell(EntIndexToEntRef(entity));
            pack.WriteCell(EntIndexToEntRef(client));
        }
        #if DEBUG
        g_iAlert += 1;
        #endif
    }
    return true;
}

// infected: rush client, or if alert is not local, rush client nearest to alert.
void infected_rush_client(const int infected, const int client, int client_nearest = -1)
{
    int client_rush = -1;
    if (local[client] || GetEntPropEnt(infected, Prop_Send, "m_clientLookatTarget")==client) client_rush = client;
    else if (!local[client] && client_nearest>0) client_rush = client_nearest;
    #if DEBUG>1
    LogMessage("infected %d rush %d", infected, client_rush);
    #endif
    SetEntProp(infected,Prop_Send,"m_mobRush",1);
    if (client_rush>0) command_infected_attack(infected,client_rush);
    ignore_infected(infected);
    #if DEBUG
    g_iRush += 1;
    #endif
}

void command_infected_attack(const int infected, const int client)
{
    L4D2_CommandABot(infected,client,BOT_CMD_ATTACK);
    SetEntPropEnt(infected, Prop_Send, "m_clientLookatTarget", client); // probably useless
    DataPack pack;
    CreateDataTimer(0.1,refresh_rush_client,pack,TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(EntIndexToEntRef(infected));
    pack.WriteCell(EntIndexToEntRef(client));
    pack.WriteCell(0);
}

// CommandABot command may get overwritten, spam it a couple times to be safe.
Action refresh_rush_client(Handle timer, DataPack pack)
{
    pack.Reset();
    int entref_zombie = pack.ReadCell();
    if (!IsValidEntRef(entref_zombie)) return Plugin_Stop;
    int entref_client = pack.ReadCell();
    if (!IsValidEntRef(entref_client)) return Plugin_Stop;
    int client = EntRefToEntIndex(entref_client);
    if (!IsValidAliveSurvivor(client)) return Plugin_Stop;
    int infected = EntRefToEntIndex(entref_zombie);
    L4D2_CommandABot(infected,client,BOT_CMD_ATTACK);
    #if DEBUG>1
    LogMessage("L4D2_CommandABot %d %d BOT_CMD_ATTACK", infected, client);
    #endif
    SetEntPropEnt(infected, Prop_Send, "m_clientLookatTarget", client); // probably useless
    int repeats = pack.ReadCell();
    repeats += 1;
    if (repeats<5)
    {
        DataPack pack2;
        CreateDataTimer(0.5,refresh_rush_client,pack2,TIMER_FLAG_NO_MAPCHANGE);
        pack2.WriteCell(entref_zombie);
        pack2.WriteCell(entref_client);
        pack2.WriteCell(repeats);
    }
    return Plugin_Stop;
}

void ignore_infected(const int infected)
{
    if (ignore[infected]) return;
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
    finale_active = false;
    roundcount += 1;
    if (!enabled) return;
    reset_timers();
    check_hooks(HOOKS_FORCE_OFF);
}

public void OnMapEnd()
{
    finale_active = false;
    roundcount += 1;
    if (!enabled) return;
    check_hooks(HOOKS_FORCE_OFF);
}

void evtFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    finale_active = true;
    commons = 0; // all rushing survivors
    if (!enabled) return;
    reset_timers();
    check_hooks(HOOKS_FORCE_OFF);
}

void evtRound(Event event, const char[] name, bool dontBroadcast)
{
    roundcount += 1;
    finale_active = false;
    if (!enabled) return;
    reset_timers();
    check_hooks(HOOKS_FORCE_OFF);
}

public void OnClientPutInServer(int client)
{
    if (!enabled || !IsValidClient(client)) return;
    timers[client] = null;
}

// Loop over all common infected.
// calm: reduce alert count by 1 for each common.
// late: reset all common infected information
int get_commons(bool calm=false, bool late=false) // Counting ONLY non-aggro infected
{
    int entity = INVALID_ENT_REFERENCE;
    int count = 0;
    while( (entity = FindEntityByClassname(entity,"infected")) != INVALID_ENT_REFERENCE )
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
                #if DEBUG>1
                LogMessage("infected %d calmed -> %d", entity, alerts[entity]);
                #endif
            }
        }
        count++;
    }
    commons = count;
    return commons;
}

// Periodic timer for calming commons.
Action perform_calm(Handle timer=null, bool reset = false)
{
    #if DEBUG
    float t = GetEngineTime(); // profiling
    #endif
    if (!weapon_fire_hooked)
    {
        timer_calm = null;
        return Plugin_Stop; // Plugin_Stop kills periodic timers like this one.
    }
    if ( (timer_calm==null || reset) && alert_memory>=0.1 && alert_max>1 )
    {
        timer_calm = CreateTimer(alert_memory,perform_calm,false,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Stop;
    }
    if (timer_calm==null || timer!=timer_calm) return Plugin_Stop;
    if (pipe_bomb_active()) return Plugin_Continue; // do not calm if pipe bomb is active
    get_commons(true);
    #if DEBUG
    float t_ms = (GetEngineTime()-t)*1000.0;
    if (t_ms>0.0) LogMessage("perform_calm %f ms", t_ms);
    #endif
    return Plugin_Continue;
}

// force: cancel all alerts, including grenade (non-local)
// alerts_only: cancel only alerts, do not touch other timers.
void reset_timers(bool force = true, bool alerts_only = false)
{
    #if DEBUG
    int num_reset = 0;
    #endif
    if (force) roundcount += 1; // all alerts will cancel
    for( int i = 1; i <= MAXPLAYERS; i++ )
    {
        if (!force && !local[i]) continue; // skip for grenades
        shots[i] = 0;
        #if DEBUG
        if (timers[i]==null) continue;
        num_reset += 1;
        #endif
        timers[i] = null;
    }
    #if DEBUG
    LogMessage("reset %d alert timers", num_reset);
    #endif
    if (alerts_only) return;
    timer_hook = null;
    perform_calm(null,true);
}  

float get_weaponid_multiplier(int weaponid)
{
    if (weaponid<0 || view_as<L4D2WeaponId>(weaponid)>=L4D2WeaponId_MAX || weaponid_multipliers[weaponid]<0.0) return weaponid_multipliers[0];
    return weaponid_multipliers[weaponid];
}

void populate_multipliers() // load .txt file containing weapon multipiers
{
    weaponid_multipliers[0] = 1.0; // Default value
    weaponid_multipliers[L4D2WeaponId_SmgSilenced] = 2.0;
    weaponid_multipliers[L4D2WeaponId_GrenadeLauncher] = 0.5;
    weaponid_multipliers[L4D2WeaponId_SniperAWP] = 0.75;
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"data/l4d2_shoot_alert_common.txt");
    File fileHandle = OpenFile(path, "r");
    if (fileHandle!=null)
    {
        char line[128];
        char buffer[64];
        while (!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle,line,sizeof(line)))
        {
            TrimString(line);
            if (line[0]==0 || line[0]=='/') continue;
            int next = BreakString(line,buffer,sizeof(buffer));
            if (next==-1) continue;
            TrimString(buffer);
            int index = StringToInt(buffer);
            if (index<0 || view_as<L4D2WeaponId>(index)>=L4D2WeaponId_MAX) continue;
            next = BreakString(line[next],buffer,sizeof(buffer));
            TrimString(buffer);
            if (buffer[0]==0 || buffer[0]=='/') continue;
            float multiplier = StringToFloat(buffer);
            if (multiplier<(-1.0)) continue;
            if (multiplier>100.0) multiplier = 0.0; // makes completely silent. that's probably what they wanted.
            #if DEBUG
            LogMessage("weaponid_multipliers entry: %d %f", index, multiplier);
            #endif
            weaponid_multipliers[index] = multiplier;
        }
        CloseHandle(fileHandle);
    }
    else LogMessage("Could not read sourcemod/data/l4d2_shoot_alert_common.txt. Using default weapon multipliers.");
}

stock bool pipe_bomb_active()
{
    return FindEntityByClassname(-1,"pipe_bomb_projectile")!=INVALID_ENT_REFERENCE;
}

// Find nearest alive survivor to vector position
// max_dist>0.0 to ignore survivors outside of sphere
// check_alert -> skip survivors with an already pending alert
stock int NearestAliveSurvivor(float pos[3], float max_dist = -1.0, bool check_alert = false)
{
    int client = -1;
    float min_dist = -1.0;
    float dist;
    static float pos2[3];
    float max_dist_sq = max_dist*max_dist;
    for( int i = 1; i <= MAXPLAYERS; i++ )
    {
        if (!IsValidAliveSurvivor(i)) continue; // bad survivor
        if (check_alert && timers[i]!=null) continue; // alert pending
        GetClientAbsOrigin(i,pos2);
        dist = GetVectorDistance(pos,pos2,true);
        if (max_dist>0.0 && dist>max_dist_sq) continue; // outside range
        if (min_dist>=0.0 && dist>min_dist) continue; // closer survivor already found
        client = i;
        min_dist = dist;
    }
    return client;
}

stock bool IsValidAliveSurvivor(int client)
{
    return IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)==TEAM_SURVIVOR;
}

stock bool is_infected(int infected)
{
    static char class[16];
    GetEntityClassname(infected,class,sizeof(class));
    return strncmp(class,"infected",8,false)==0;
}

stock bool is_bad_infected(int infected) // both props change dynamically and need to be monitored.
{
    return GetEntProp(infected,Prop_Send,"m_mobRush")>0 || GetEntProp(infected,Prop_Data,"m_iHealth")<=0;
}

stock bool infected_can_hear(int infected) // prop is set once on entity create and never changed.
{
    return GetEntProp(infected,Prop_Send,"m_Gender")!=TYPE_ROAD_WORKER;
}

stock float get_max_range(float multiplier = 1.0) // Find max of alert range and rush range.
{
    float max = (alert_range>=rush_range) ? alert_range : rush_range;
    return max/multiplier;
}

const int TR_MASK_LOS = MASK_VISIBLE;

// Check if line-of-sight is blocked. ignore self entity index
stock bool los_blocked(const float eyePos[3], const float testPoint[3], int self = -1)
{
    TR_TraceRayFilter(eyePos, testPoint, TR_MASK_LOS, RayType_EndPoint, FilterLOS, self);
    return TR_DidHit(INVALID_HANDLE);
}

// Entity filter for LOS checks. Ignore self, players, infected, witches, and everything else that is see-through (transparent).
stock bool FilterLOS(int entity, int mask, int self = -1)
{
	if (entity==self) return false;
	if (entity==0) return true;
	if (IsValidClient(entity)) return false;
	static char class[16];
	GetEntityClassname(entity,class,sizeof(class));
	switch (class[0])
	{
    	case 'i':
    	{
        	if (strncmp(class,"infected",8,false)==0) return false;
    	}
    	case 'w':
    	{
        	if (strncmp(class,"witch",5,false)==0) return false;
    	}
    	case 'e':
    	{
        	if (strncmp(class,"env_",4,false)==0) return false;
        	if (strncmp(class,"entity_blocker",14,false)==0) return false;
    	}
    	case 'f':
    	{
        	if (strncmp(class,"func",4,false)==0) return false;
    	}
    	case 's':
    	{
        	if (strncmp(class,"script_clip",11,false)==0) return false;
    	}
    	case 'p':
    	{
        	if (strncmp(class,"prop_physics",12,false)==0) return false;
    	}
	}
	return true;
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