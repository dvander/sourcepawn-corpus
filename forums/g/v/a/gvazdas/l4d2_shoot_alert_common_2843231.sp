// Thanks to testers: Hatsune Miku Fan, Krufftys Killers
// Thanks to Silvers for code cleanup and serious optimizations.

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <files>
#include <left4dhooks>

#define PLUGIN_NAME			"l4d2_shoot_alert_common"
#define PLUGIN_VERSION 		"1.82 2026-03-14"
#define CONFIG_FILENAME         PLUGIN_NAME

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
#define MAXENTITIES        2048
#define MODEL_ROAD         "models/infected/common_male_roadcrew.mdl"
#define DEBUG              0

#if DEBUG
int g_iLaser;
#endif

// Optimizations
Handle timer_hook; // reduce weapon_fire hook/unhook spam
Handle timers[MAXPLAYERS+1]; // reduce weapon_fire and NormalSoundHook spam
bool ignore[MAXENTITIES+1] = {true,...}; // ignore non-infected, and rushing or road worker infected
float multipliers[MAXPLAYERS+1] = {1.0,...}; // client dynamic range multipliers based on weapon type and speech volume
bool weapon_fire_hooked = false; // track weapon_fire hook
bool speech_hooked = false; // track NormalSoundHook
bool finale_active = false; // do nothing during survival and finales
int commons = 0; // track only non-rushing commons
float pos_arr[MAXPLAYERS+1][3]; // calculate position of survivor only once before callback
int alerts[MAXENTITIES+1]; // track how many times infected alerted; force rush if alerted too many times
Handle timer_calm; // periodically calm down non-rushing infected
int shots[MAXPLAYERS+1]; // accumulate gunfire before callback
float weaponid_multipliers[L4D2WeaponId_MAX] = {-1.0,...}; // multipliers for each weaponID; -1.0 to use default value.

// Inputs
ConVar g_hCvarEnable, g_hCvarAlertRange, g_hCvarAlertProbability, g_hCvarRushRange, g_hCvarLOS, g_hCvarAlertMax,
g_hCvarAlertMemory, g_hCvarVoice, g_hCvarAccumulate, g_hCvarSaferoom, g_hCvarMPGameMode;
bool enabled, speech, accumulate, saferoom = false;
float alert_range, rush_range, alert_probability, alert_memory, LOS_multiplier, voice_multiplier;
int alert_max;

float get_weaponid_multiplier(int weaponid)
{
    if (weaponid<0 || view_as<L4D2WeaponId>(weaponid)>=L4D2WeaponId_MAX || weaponid_multipliers[weaponid]<0.0) return weaponid_multipliers[0];
    return weaponid_multipliers[weaponid];
}

Action request_reset(int client, int args)
{
    static char command[PLATFORM_MAX_PATH];
    Format(command, sizeof(command), "exec sourcemod/%s", CONFIG_FILENAME);
    ServerCommand(command);
    return Plugin_Stop;
}

public void OnPluginStart()
{   
    AutoExecConfig(true, CONFIG_FILENAME);
    RegAdminCmd("l4d2_shoot_alert_common_resetcvars", request_reset, ADMFLAG_ROOT, "Reload default cfg. Admins only.");
    
    // Populate table of weaponid range multipliers.
    weaponid_multipliers[0] = 1.0; // Default value
    weaponid_multipliers[L4D2WeaponId_SmgSilenced] = 2.0;
    weaponid_multipliers[L4D2WeaponId_GrenadeLauncher] = 0.5;
    weaponid_multipliers[L4D2WeaponId_SniperAWP] = 0.75;
    static char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"data/l4d2_shoot_alert_common.txt");
    File fileHandle = OpenFile(path, "r");
    if (fileHandle!=null)
    {
        static char line[128];
        static char buffer[64];
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
    else LogMessage("Could not read /data/l4d2_shoot_alert_common.txt. Using default values.");
    
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
    
    g_hCvarAlertMax = CreateConVar("l4d2_shoot_alert_common_max", "12", "Number of no-line-of-sight alerts to rush. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMax.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAlertMemory = CreateConVar("l4d2_shoot_alert_common_memory", "4.0", "How many seconds to forget 1 alert. 0 to disable.",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
    g_hCvarAlertMemory.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarVoice = CreateConVar("l4d2_shoot_alert_common_voice", "2.0", "Survivor voice range multiplier (scales with volume), 0 to disable. 2 is a good value. -1.0 to use default.",FCVAR_NOTIFY, true, -1.0, true, 1000.0);
    g_hCvarVoice.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarAccumulate = CreateConVar("l4d2_shoot_alert_common_accumulate", "0.0", "Set to 1 for hardcore realism. Any extra shots between shot and delayed response are accumulated.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarAccumulate.AddChangeHook(ConVarChanged_Cvars);
    
    g_hCvarSaferoom = CreateConVar("l4d2_shoot_alert_common_saferoom", "0.0", "Enable alerts when survivors are in start area.",FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvarSaferoom.AddChangeHook(ConVarChanged_Cvars);
    
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
    bool update = false;
    alert_range = g_hCvarAlertRange.FloatValue;
    rush_range = g_hCvarRushRange.FloatValue;
    alert_probability = g_hCvarAlertProbability.FloatValue;
    LOS_multiplier = g_hCvarLOS.FloatValue;
    accumulate = g_hCvarAccumulate.BoolValue;
    if (g_hCvarVoice.FloatValue != voice_multiplier)
    {
        voice_multiplier = g_hCvarVoice.FloatValue;
        if (voice_multiplier<0.0) voice_multiplier = weaponid_multipliers[0]; // use default value for -1.0
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
    IsAllowed();
    if (update) RequestFrame(check_hooks);
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
    bool should_hook = enabled && !finale_active && L4D_IsInIntro()<=0 && !L4D_IsSurvivalMode() && (saferoom || L4D_HasAnySurvivorLeftSafeArea()) && get_commons()>0;
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

public void L4D_OnFinishIntro()
{
    if (!enabled || weapon_fire_hooked || timer_hook!=null) return;
    timer_hook = CreateTimer(0.1,timer_check_hooks,TIMER_FLAG_NO_MAPCHANGE);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post()
{
    if (!enabled || weapon_fire_hooked || timer_hook!=null) return;
    timer_hook = CreateTimer(0.1,timer_check_hooks,TIMER_FLAG_NO_MAPCHANGE);
}

void late_enable() // If plugin just enabled, check if there are any infected entities to alarm.
{
    reset_timers();
    for(int entity = 1; entity<=MAXENTITIES; entity++) { ignore[entity] = true; }
    get_commons(false,true);
    if (!weapon_fire_hooked && commons>0) check_hooks();
}

public void OnEntityCreated(int entity, const char[] classname) // Check if this is an infected entity.
{
	if (!enabled || !IsValidEdict(entity)) return;
	if (finale_active || L4D_IsSurvivalMode())
	{
        	ignore[entity] = true;
        	return;
	}
	if (strcmp(classname,"infected")==0 && GetEntProp(entity,Prop_Send,"m_mobRush")<=0 && infected_can_hear(entity))
	{
        	ignore[entity] = false; alerts[entity] = 0; commons += 1;
        	CreateTimer(1.0,check_aggro,EntIndexToEntRef(entity),TIMER_FLAG_NO_MAPCHANGE);
	}
	else ignore[entity] = true;
}

Action check_aggro(Handle timer, int entref) // Check again.
{
    if (!IsValidEntRef(entref))
    {
        commons -= 1;
        return Plugin_Stop;
    }
    int entity = EntRefToEntIndex(entref);
    if (ignore[entity]) return Plugin_Stop; // commons was subtracted somewhere else
    if (is_bad_infected(entity) || !infected_can_hear(entity))
    {
        ignore_infected(entity);
        return Plugin_Stop;
    }
    if (weapon_fire_hooked || timer_hook!=null) return Plugin_Stop; // if already hooked, do nothing
    timer_hook = CreateTimer(0.1,timer_check_hooks,TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

public void OnEntityDestroyed(int entity) // When infected is destroyed, check if hooks need to be deactivated.
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
    //#if DEBUG 
    //    LogMessage("%d fired %d, %d bullets", GetClientOfUserId(event.GetInt("userid")), event.GetInt("weaponid"), event.GetInt("count"));
    //#endif
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (GetClientTeam(client)!=TEAM_SURVIVOR) return;
    int weaponid = event.GetInt("weaponid");
    if (event.GetInt("count")<=0) // 0 count is returned by melee weapons and mounted weapons (minigun, 50 cal)
    {
        if (view_as<L4D2WeaponId>(weaponid)!=L4D2WeaponId_Ammo) return;
    }
    else if (view_as<L4D2WeaponId>(weaponid)==L4D2WeaponId_GrenadeLauncher) return; // grenade detonation event will alert instead.
    float multiplier = get_weaponid_multiplier(weaponid);
    if (multiplier<=0.0) return; // 0.0 multiplier weapons are silent
    if (timers[client]!=null)
    {
        if (multipliers[client]>multiplier) multipliers[client] = multiplier; // prevent weapon swap exploit
        if (accumulate) shots[client] += 1;
        return;
    }
    alert_constructor(client,client,multiplier);
}

public void L4D2_GrenadeLauncher_Detonate_Post(int entity, int client)
{
    if (!weapon_fire_hooked) return;
    if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return;
    float multiplier = get_weaponid_multiplier(L4D2WeaponId_GrenadeLauncher);
    timers[client] = null; // cancel any pending alerts
    alert_constructor(entity,client,multiplier);
}

public void L4D_PipeBombProjectile_Post(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
    if (!weapon_fire_hooked) return;
    reset_timers(); // reset all timers, otherwise infected may enter rush state due to callback; typically they go back to calm state if no survivors are around
}

// This fires many times for the same file depending on number of clients!!!!!
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
    alert_constructor(entity,entity,voice_multiplier/volume);
    return Plugin_Continue;
}

// entity where center should be, client is owner
void alert_constructor(int entity, int client, float multiplier = 1.0)
{
    if (multiplier<=0.0) return; // 0.0 multipliers mean silence.
    static float pos[3];
    L4D_GetEntityWorldSpaceCenter(entity,pos);
    pos_arr[client][0] = pos[0]; pos_arr[client][1] = pos[1]; pos_arr[client][2] = pos[2];
    shots[client] = 1;
    multipliers[client] = multiplier;
    timers[client] = CreateTimer(GetRandomFloat(0.5,1.5),alert_update,EntIndexToEntRef(client),TIMER_FLAG_NO_MAPCHANGE);
}

Action alert_update(Handle timer, int entref) // Alert nearby infected.
{
    if (!IsValidEntRef(entref)) return Plugin_Stop; // prevent carry-over to new round
    int client = EntRefToEntIndex(entref);
    if (!IsValidClient(client)) return Plugin_Stop;
    if (timer!=timers[client]) return Plugin_Stop; // timer was cancelled
    timers[client] = null;
    if (!IsPlayerAlive(client) || GetClientTeam(client)!=TEAM_SURVIVOR) return Plugin_Stop;
    if (FindEntityByClassname(-1, "pipe_bomb_projectile")!=INVALID_ENT_REFERENCE) return Plugin_Stop;
    float range_alert_effective = alert_range/multipliers[client];
    if (range_alert_effective<=20.0) return Plugin_Stop; // range too small to catch anything.
    static float pos[3];
    pos[0] = pos_arr[client][0]; pos[1] = pos_arr[client][1]; pos[2] = pos_arr[client][2];
    TR_EnumerateEntitiesSphere(pos,range_alert_effective,PARTITION_NON_STATIC_EDICTS,AlertCallback,client);
    #if DEBUG
    if (range_alert_effective>1.0 && g_iLaser>0 && !IsFakeClient(client))
    {
        // BLUE - ALERT, ALERT/LOS | RED - RUSH, RUSH/LOS
        TE_SetupBeamRingPoint(pos,range_alert_effective,range_alert_effective-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
        pos[2] += 3.0; TE_SendToClient(client); // draw alert range (LOS)
        TE_SetupBeamRingPoint(pos,range_alert_effective/LOS_multiplier,range_alert_effective/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{0,0,255,255},0,0);
        pos[2] += 3.0; TE_SendToClient(client); // draw alert range (no LOS)
        float range_rush_effective = rush_range/multipliers[client];
        if (range_rush_effective>1.0)
        {
            TE_SetupBeamRingPoint(pos,range_rush_effective,range_rush_effective-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            pos[2] += 3.0; TE_SendToClient(client); // draw rush range (LOS)
            TE_SetupBeamRingPoint(pos,range_rush_effective/LOS_multiplier,range_rush_effective/LOS_multiplier-1.0,g_iLaser,0,0,0,3.0,1.5,0.0,{255,0,0,255},0,0);
            TE_SendToClient(client); // draw rush range (no LOS)
        }
    }
    #endif
    return Plugin_Stop;
}

bool AlertCallback(int entity, int client) // Return true to continue enumerating, false to stop
{
    if (entity<=MaxClients || !IsValidEdict(entity)) return true;
    if (ignore[entity]) return true;
    if (is_bad_infected(entity)) // Ignore rushing and dead infected
    {
        ignore_infected(entity);
        return true;
    }
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
    LogMessage("cb %d shots %d zombie %d LOS %d x%.2f range_eff %.1f",client,shots[client],entity,LOS,multipliers[client],range);
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
            alerts[entity] += shots[client];
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
            CreateDataTimer(GetRandomFloat(1.75,3.5),undo_lookat,pack,TIMER_FLAG_NO_MAPCHANGE);
            pack.WriteCell(EntIndexToEntRef(entity));
            pack.WriteCell(EntIndexToEntRef(client));
        }
    }
    return true;
}

void infected_rush_client(const int infected, const int client)
{
    #if DEBUG
    LogMessage("infected %d rush %d", infected, client);
    #endif
    SetEntPropEnt(infected, Prop_Send, "m_clientLookatTarget", client); // this probably does nothing useful
    SetEntProp(infected, Prop_Send, "m_mobRush", 1);
    ignore_infected(infected);
}

void ignore_infected(const int infected)
{
    ignore[infected] = true; alerts[infected] = 0;
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
    commons = 0; // all aggro
    reset_timers();
    check_hooks();
}

void evtRound(Event event, const char[] name, bool dontBroadcast)
{
    finale_active = false;
    if (!enabled) return;
    reset_timers();
    check_hooks();
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
        shots[i] = 0;
        timers[i] = null;
    }
    timer_hook = null;
    timer_calm = null; perform_calm(null,true);
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