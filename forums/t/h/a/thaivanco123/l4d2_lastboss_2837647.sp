#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0.2"
#define DEBUG 0

#define TEAM_SURVIVOR 2
#define ZC_TANK 8
#define MOLOTOV 0
#define EXPLODE 1

#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"
#define SOUND_EXPLODE "animation/bombing_run_01.wav"
#define SOUND_SPAWN "music/pzattack/contusion.wav"
#define SOUND_BCLAW "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_GCLAW "plats/churchbell_end.wav"
#define SOUND_DCLAW "ambient/random_amb_sounds/randbridgegroan_03.wav"
#define SOUND_QUAKE "player/charger/hit/charger_smash_02.wav"
#define SOUND_STEEL "physics/metal/metal_solid_impact_hard5.wav"
#define SOUND_CHANGE "items/suitchargeok1.wav"
#define SOUND_HOWL "player/tank/voice/pain/tank_fire_08.wav"
#define SOUND_WARP "ambient/energy/zap9.wav"
#define PARTICLE_SPAWN "electrical_arc_01_system"
#define PARTICLE_DEATH "gas_explosion_main"
#define PARTICLE_THIRD "apc_wheel_smoke1"
#define PARTICLE_FORTH "aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP "water_splash"

#define MSG_SPAWN "\x05Prepare for the final battle! \x04Type-UNKNOWN\x01[FINAL BOSS]"
#define MSG_SECOND "\x05Form changed -> \x01[STEEL OVERLOAD]"
#define MSG_THIRD "\x05Form changed -> \x01[NIGHT HUNTER]"
#define MSG_FORTH "\x05Form changed -> \x01[FIRE SPIRIT]"

enum Form {
    FORM_ONE = 1,
    FORM_TWO,
    FORM_THREE,
    FORM_FOUR,
    FORM_DEAD = -1
}

enum struct TankData {
    int bossId;
    Form formPrev;
    bool bossActive;
    bool lastWave;
    int waveCount;
    int alphaRate;
    int visibility;
    float lastPos[3];
    int velocityOffset;
    Handle timerUpdate;
}

ArrayList g_Tanks;
ConVar g_hCvarEnable, g_hCvarAnnounce, g_hCvarSteel, g_hCvarStealth, g_hCvarGravity,
       g_hCvarBurn, g_hCvarQuake, g_hCvarJump, g_hCvarComet, g_hCvarDread,
       g_hCvarGush, g_hCvarAbyss, g_hCvarWarp, g_hCvarHealthMax, g_hCvarHealthSecond,
       g_hCvarHealthThird, g_hCvarHealthForth, g_hCvarColorFirst, g_hCvarColorSecond,
       g_hCvarColorThird, g_hCvarColorForth, g_hCvarForceFirst, g_hCvarForceSecond,
       g_hCvarForceThird, g_hCvarForceForth, g_hCvarSpeedFirst, g_hCvarSpeedSecond,
       g_hCvarSpeedThird, g_hCvarSpeedForth, g_hCvarWeightSecond, g_hCvarStealthThird,
       g_hCvarJumpIntervalForth, g_hCvarJumpHeightForth, g_hCvarGravityInterval,
       g_hCvarQuakeRadius, g_hCvarQuakeForce, g_hCvarDreadInterval, g_hCvarDreadRate,
       g_hCvarForthC5M5Bridge, g_hCvarWarpInterval, g_hCvarModes, g_hCvarModesOff,
       g_hCvarModesTog, g_hCvarMPGameMode;
bool g_bCvarAllow, g_bMapStarted;
int g_iDefaultForce, g_iCurrentMode, g_iPlayerSpawn, g_iRoundStart;
int g_iHealthMax, g_iHealthSecond, g_iHealthThird, g_iHealthForth, g_iForceFirst,
    g_iForceSecond, g_iForceThird, g_iForceForth, g_iDreadRate;
float g_fSpeedFirst, g_fSpeedSecond, g_fSpeedThird, g_fSpeedForth, g_fWeightSecond,
      g_fStealthThird, g_fJumpIntervalForth, g_fJumpHeightForth, g_fGravityInterval,
      g_fQuakeRadius, g_fQuakeForce, g_fDreadInterval, g_fWarpInterval;
char g_sColorFirst[32], g_sColorSecond[32], g_sColorThird[32], g_sColorForth[32];

public Plugin myinfo = {
    name = "[L4D2] Last Boss Reworked",
    author = "ztar (original), JustMe (reworked)",
    description = "Enhanced special Tank spawns with multiple boss tanks",
    version = PLUGIN_VERSION,
    url = "http://ztar.blog7.fc2.com/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    char game[32];
    GetGameFolderName(game, sizeof(game));
    if (!StrEqual(game, "left4dead2")) {
        strcopy(error, err_max, "This plugin is for Left 4 Dead 2 only.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart() {
    g_Tanks = new ArrayList(sizeof(TankData));
    g_iDefaultForce = GetConVarInt(FindConVar("z_tank_throw_force"));

    CreateConVar("sm_lastboss_reworked_version", PLUGIN_VERSION, "Plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    g_hCvarEnable = CreateConVar("sm_lastboss_reworked_enable", "2", "Enable plugin (0:OFF 1:Finale Only 2:Always 3:Second Tank)", FCVAR_NOTIFY);
    g_hCvarAnnounce = CreateConVar("sm_lastboss_reworked_enable_announce", "1", "Enable announcements (0:OFF 1:ON)", FCVAR_NOTIFY);
    
    g_hCvarSteel = CreateConVar("sm_lastboss_reworked_enable_steel", "1", "Enable SteelSkin (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarStealth = CreateConVar("sm_lastboss_reworked_enable_stealth", "1", "Enable StealthSkin (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarGravity = CreateConVar("sm_lastboss_reworked_enable_gravity", "1", "Enable GravityClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarBurn = CreateConVar("sm_lastboss_reworked_enable_burn", "1", "Enable BurnClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarQuake = CreateConVar("sm_lastboss_reworked_enablesony", "1", "Enable EarthQuake (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarJump = CreateConVar("sm_lastboss_reworked_enable_jump", "1", "Enable MadSpring (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarComet = CreateConVar("sm_lastboss_reworked_enable_comet", "1", "Enable BlastRock/CometStrike (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarDread = CreateConVar("sm_lastboss_reworked_enable_dread", "1", "Enable DreadClaw (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarGush = CreateConVar("sm_lastboss_reworked_enable_gush", "1", "Enable FlameGush (0:OFF 1:ON)", FCVAR_NOTIFY);
    g_hCvarAbyss = CreateConVar("sm_lastboss_reworked_enable_abyss", "1", "Enable CallOfAbyss (0:OFF 1:Forth Form 2:All Forms)", FCVAR_NOTIFY);
    g_hCvarWarp = CreateConVar("sm_lastboss_reworked_enable_warp", "1", "Enable FatalMirror (0:OFF 1:ON)", FCVAR_NOTIFY);
    
    g_hCvarHealthMax = CreateConVar("sm_lastboss_reworked_health_max", "80000", "Max Health", FCVAR_NOTIFY);
    g_hCvarHealthSecond = CreateConVar("sm_lastboss_reworked_health_second", "60000", "Health (second form)", FCVAR_NOTIFY);
    g_hCvarHealthThird = CreateConVar("sm_lastboss_reworked_health_third", "40000", "Health (third form)", FCVAR_NOTIFY);
    g_hCvarHealthForth = CreateConVar("sm_lastboss_reworked_health_forth", "20000", "Health (fourth form)", FCVAR_NOTIFY);
    
    g_hCvarColorFirst = CreateConVar("sm_lastboss_reworked_color_first", "255 255 80", "RGB for First form", FCVAR_NOTIFY);
    g_hCvarColorSecond = CreateConVar("sm_lastboss_reworked_color_second", "80 255 80", "RGB for Second form", FCVAR_NOTIFY);
    g_hCvarColorThird = CreateConVar("sm_lastboss_reworked_color_third", "80 80 255", "RGB for Third form", FCVAR_NOTIFY);
    g_hCvarColorForth = CreateConVar("sm_lastboss_reworked_color_forth", "255 80 80", "RGB for Fourth form", FCVAR_NOTIFY);
    
    g_hCvarForceFirst = CreateConVar("sm_lastboss_reworked_force_first", "800", "Force (first form)", FCVAR_NOTIFY);
    g_hCvarForceSecond = CreateConVar("sm_lastboss_reworked_force_second", "825", "Force (second form)", FCVAR_NOTIFY);
    g_hCvarForceThird = CreateConVar("sm_lastboss_reworked_force_third", "835", "Force (third form)", FCVAR_NOTIFY);
    g_hCvarForceForth = CreateConVar("sm_lastboss_reworked_force_forth", "850", "Force (fourth form)", FCVAR_NOTIFY);
    
    g_hCvarSpeedFirst = CreateConVar("sm_lastboss_reworked_speed_first", "0.9", "Speed (first form)", FCVAR_NOTIFY);
    g_hCvarSpeedSecond = CreateConVar("sm_lastboss_reworked_speed_second", "1.0", "Speed (second form)", FCVAR_NOTIFY);
    g_hCvarSpeedThird = CreateConVar("sm_lastboss_reworked_speed_third", "1.1", "Speed (third form)", FCVAR_NOTIFY);
    g_hCvarSpeedForth = CreateConVar("sm_lastboss_reworked_speed_forth", "1.2", "Speed (fourth form)", FCVAR_NOTIFY);
    
    g_hCvarWeightSecond = CreateConVar("sm_lastboss_reworked_weight_second", "8.0", "Weight (second form)", FCVAR_NOTIFY);
    g_hCvarStealthThird = CreateConVar("sm_lastboss_reworked_stealth_third", "10.0", "Stealth interval (third form)", FCVAR_NOTIFY);
    g_hCvarJumpIntervalForth = CreateConVar("sm_lastboss_reworked_jumpinterval_forth", "1.0", "Jump interval (fourth form)", FCVAR_NOTIFY);
    g_hCvarJumpHeightForth = CreateConVar("sm_lastboss_reworked_jumpheight_forth", "300.0", "Jump height (fourth form)", FCVAR_NOTIFY);
    g_hCvarGravityInterval = CreateConVar("sm_lastboss_reworked_gravityinterval", "6.0", "Gravity claw interval", FCVAR_NOTIFY);
    g_hCvarQuakeRadius = CreateConVar("sm_lastboss_reworked_quake_radius", "600.0", "Earth Quake radius", FCVAR_NOTIFY);
    g_hCvarQuakeForce = CreateConVar("sm_lastboss_reworked_quake_force", "350.0", "Earth Quake force", FCVAR_NOTIFY);
    g_hCvarDreadInterval = CreateConVar("sm_lastboss_reworked_dreadinterval", "8.0", "Dread Claw interval", FCVAR_NOTIFY);
    g_hCvarDreadRate = CreateConVar("sm_lastboss_reworked_dreadrate", "235", "Dread Claw blind rate", FCVAR_NOTIFY);
    g_hCvarForthC5M5Bridge = CreateConVar("sm_lastboss_reworked_forth_c5m5_bridge", "0", "Start at fourth form in c5m5_bridge", FCVAR_NOTIFY);
    g_hCvarWarpInterval = CreateConVar("sm_lastboss_reworked_warp_interval", "35.0", "Fatal Mirror interval", FCVAR_NOTIFY);
    
    g_hCvarModes = CreateConVar("sm_lastboss_reworked_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all)", FCVAR_NOTIFY);
    g_hCvarModesOff = CreateConVar("sm_lastboss_reworked_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none)", FCVAR_NOTIFY);
    g_hCvarModesTog = CreateConVar("sm_lastboss_reworked_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", FCVAR_NOTIFY);

    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    g_hCvarEnable.AddChangeHook(OnConVarChanged_Allow);
    g_hCvarModes.AddChangeHook(OnConVarChanged_Allow);
    g_hCvarModesOff.AddChangeHook(OnConVarChanged_Allow);
    g_hCvarModesTog.AddChangeHook(OnConVarChanged_Allow);
    g_hCvarHealthMax.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarHealthSecond.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarHealthThird.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarHealthForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarColorFirst.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarColorSecond.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarColorThird.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarColorForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarForceFirst.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarForceSecond.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarForceThird.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarForceForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarSpeedFirst.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarSpeedSecond.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarSpeedThird.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarSpeedForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarWeightSecond.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarStealthThird.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarJumpIntervalForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarJumpHeightForth.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarGravityInterval.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarQuakeRadius.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarQuakeForce.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarDreadInterval.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarDreadRate.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarForthC5M5Bridge.AddChangeHook(OnConVarChanged_Cvars);
    g_hCvarWarpInterval.AddChangeHook(OnConVarChanged_Cvars);

    AutoExecConfig(true, "l4d2_lastboss_reworked");
}

public void OnConfigsExecuted() {
    IsAllowed();
}

public void OnMapStart() {
    g_bMapStarted = true;
    PrecacheAssets();
    ResetTankData();
}

public void OnMapEnd() {
    g_bMapStarted = false;
    ResetTankData();
}

void OnConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue) {
    IsAllowed();
}

void OnConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue) {
    GetCvars();
}

void GetCvars() {
    g_iHealthMax = g_hCvarHealthMax.IntValue;
    g_iHealthSecond = g_hCvarHealthSecond.IntValue;
    g_iHealthThird = g_hCvarHealthThird.IntValue;
    g_iHealthForth = g_hCvarHealthForth.IntValue;
    g_hCvarColorFirst.GetString(g_sColorFirst, sizeof(g_sColorFirst));
    g_hCvarColorSecond.GetString(g_sColorSecond, sizeof(g_sColorSecond));
    g_hCvarColorThird.GetString(g_sColorThird, sizeof(g_sColorThird));
    g_hCvarColorForth.GetString(g_sColorForth, sizeof(g_sColorForth));
    g_iForceFirst = g_hCvarForceFirst.IntValue;
    g_iForceSecond = g_hCvarForceSecond.IntValue;
    g_iForceThird = g_hCvarForceThird.IntValue;
    g_iForceForth = g_hCvarForceForth.IntValue;
    g_fSpeedFirst = g_hCvarSpeedFirst.FloatValue;
    g_fSpeedSecond = g_hCvarSpeedSecond.FloatValue;
    g_fSpeedThird = g_hCvarSpeedThird.FloatValue;
    g_fSpeedForth = g_hCvarSpeedForth.FloatValue;
    g_fWeightSecond = g_hCvarWeightSecond.FloatValue;
    g_fStealthThird = g_hCvarStealthThird.FloatValue;
    g_fJumpIntervalForth = g_hCvarJumpIntervalForth.FloatValue;
    g_fJumpHeightForth = g_hCvarJumpHeightForth.FloatValue;
    g_fGravityInterval = g_hCvarGravityInterval.FloatValue;
    g_fQuakeRadius = g_hCvarQuakeRadius.FloatValue;
    g_fQuakeForce = g_hCvarQuakeForce.FloatValue;
    g_fDreadInterval = g_hCvarDreadInterval.FloatValue;
    g_iDreadRate = g_hCvarDreadRate.IntValue;
    g_fWarpInterval = g_hCvarWarpInterval.FloatValue;
}

void IsAllowed() {
    bool bCvarAllow = g_hCvarEnable.IntValue > 0;
    bool bAllowMode = IsAllowedGameMode();
    GetCvars();

    if (!g_bCvarAllow && bCvarAllow && bAllowMode) {
        g_bCvarAllow = true;
        HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
        HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
        HookEvent("finale_vehicle_incoming", Event_FinaleLast, EventHookMode_PostNoCopy);
        HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
        HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
        HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
        HookEvent("player_incapacitated", Event_PlayerHurt, EventHookMode_Post);
        HookEvent("finale_bridge_lowering", Event_FinaleStart, EventHookMode_PostNoCopy);
        HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
    } else if (g_bCvarAllow && (!bCvarAllow || !bAllowMode)) {
        g_bCvarAllow = false;
        UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
        UnhookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
        UnhookEvent("finale_vehicle_incoming", Event_FinaleLast, EventHookMode_PostNoCopy);
        UnhookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
        UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
        UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
        UnhookEvent("player_incapacitated", Event_PlayerHurt, EventHookMode_Post);
        UnhookEvent("finale_bridge_lowering", Event_FinaleStart, EventHookMode_PostNoCopy);
        UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
        ResetTankData();
    }
}

bool IsAllowedGameMode() {
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog != 0) {
        if (!g_bMapStarted)
            return false;

        g_iCurrentMode = 0;

        int entity = CreateEntityByName("info_gamemode");
        if (IsValidEntity(entity)) {
            DispatchSpawn(entity);
            HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "PostSpawnActivate");
            if (IsValidEntity(entity))
                RemoveEdict(entity);
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0]) {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if (sGameModes[0]) {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay) {
    if (strcmp(output, "OnCoop") == 0)
        g_iCurrentMode = 1;
    else if (strcmp(output, "OnSurvival") == 0)
        g_iCurrentMode = 2;
    else if (strcmp(output, "OnVersus") == 0)
        g_iCurrentMode = 4;
    else if (strcmp(output, "OnScavenge") == 0)
        g_iCurrentMode = 8;
}

void ResetTankData() {
    for (int i = 0; i < g_Tanks.Length; i++) {
        TankData tank;
        g_Tanks.GetArray(i, tank);
        if (tank.timerUpdate != null) {
            delete tank.timerUpdate;
        }
    }
    g_Tanks.Clear();
    SetConVarInt(FindConVar("z_tank_throw_force"), g_iDefaultForce, true, true);
}

void PrecacheAssets() {
    PrecacheModel(MODEL_PROPANE, true);
    PrecacheModel(MODEL_GASCAN, true);
    PrecacheSound(SOUND_EXPLODE, true);
    PrecacheSound(SOUND_SPAWN, true);
    PrecacheSound(SOUND_BCLAW, true);
    PrecacheSound(SOUND_GCLAW, true);
    PrecacheSound(SOUND_DCLAW, true);
    PrecacheSound(SOUND_QUAKE, true);
    PrecacheSound(SOUND_STEEL, true);
    PrecacheSound(SOUND_CHANGE, true);
    PrecacheSound(SOUND_HOWL, true);
    PrecacheSound(SOUND_WARP, true);
    PrecacheParticle(PARTICLE_SPAWN);
    PrecacheParticle(PARTICLE_DEATH);
    PrecacheParticle(PARTICLE_THIRD);
    PrecacheParticle(PARTICLE_FORTH);
    PrecacheParticle(PARTICLE_WARP);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if (g_iPlayerSpawn == 1 && g_iRoundStart == 0)
        CreateTimer(2.0, TimerLoad, _, TIMER_FLAG_NO_MAPCHANGE);
    g_iRoundStart = 1;
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 0; i < g_Tanks.Length; i++) {
        TankData tank;
        g_Tanks.GetArray(i, tank);
        tank.bossActive = true;
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));
        tank.waveCount = (StrEqual(currentMap, "c1m4_atrium") || StrEqual(currentMap, "c5m5_bridge")) ? 2 : 1;
        g_Tanks.SetArray(i, tank);
    }
}

void Event_FinaleLast(Event event, const char[] name, bool dontBroadcast) {
    for (int i = 0; i < g_Tanks.Length; i++) {
        TankData tank;
        g_Tanks.GetArray(i, tank);
        tank.lastWave = true;
        g_Tanks.SetArray(i, tank);
    }
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    int index = FindTankIndex(client);
    if (index != -1 && IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK) {
        TankData tank;
        g_Tanks.GetArray(index, tank);
        if (tank.timerUpdate != null) {
            delete tank.timerUpdate;
        }
        g_Tanks.Erase(index);
    }
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast) {
    if (!g_bCvarAllow) return;

    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client)) return;

    TankData tank;
    tank.bossId = client;
    tank.velocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
    if (tank.velocityOffset == -1) {
        LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
    }
    tank.formPrev = FORM_DEAD;
    tank.bossActive = (StrEqual(currentMap, "c1m4_atrium") || StrEqual(currentMap, "c5m5_bridge"));
    tank.lastWave = false;
    tank.waveCount = (StrEqual(currentMap, "c1m4_atrium") || StrEqual(currentMap, "c5m5_bridge")) ? 2 : 1;
    tank.alphaRate = 255;
    tank.visibility = 0;
    tank.lastPos = {0.0, 0.0, 0.0};
    tank.timerUpdate = null;

    if ((tank.bossActive && g_hCvarEnable.IntValue == 1) || g_hCvarEnable.IntValue == 2 || (tank.bossActive && g_hCvarEnable.IntValue == 3 && tank.waveCount >= 2)) {
        g_Tanks.PushArray(tank);
        CreateTimer(0.3, Timer_SetTankHealth, client);
        tank.timerUpdate = CreateTimer(1.0, Timer_TankUpdate, client, TIMER_REPEAT);

        if (g_hCvarAnnounce.BoolValue) {
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && !IsFakeClient(i)) {
                    EmitSoundToClient(i, SOUND_SPAWN);
                    PrintToChat(i, MSG_SPAWN);
                    int finalHealth = (tank.lastWave || (StrEqual(currentMap, "c5m5_bridge") && g_hCvarForthC5M5Bridge.BoolValue)) ? g_iHealthForth : g_iHealthMax;
                    PrintToChatAll("\x05Tank %d Health: \x04%d \x05Speed: \x04%.1f", client, finalHealth, (finalHealth == g_iHealthForth) ? g_fSpeedForth : g_fSpeedFirst);
                }
            }
        }
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    if (!g_bCvarAllow) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK) return;

    int index = FindTankIndex(client);
    if (index == -1) return;

    TankData tank;
    g_Tanks.GetArray(index, tank);

    if (tank.waveCount < 2 && g_hCvarEnable.IntValue == 3) {
        tank.waveCount++;
        g_Tanks.SetArray(index, tank);
        return;
    }

    if ((tank.bossActive && g_hCvarEnable.IntValue == 1) || g_hCvarEnable.IntValue == 2 || (tank.bossActive && g_hCvarEnable.IntValue == 3)) {
        float pos[3];
        GetClientAbsOrigin(tank.bossId, pos);
        EmitSoundToAll(SOUND_EXPLODE, tank.bossId);
        ShowParticle(pos, PARTICLE_DEATH, 5.0);
        LittleFlower(pos, MOLOTOV);
        LittleFlower(pos, EXPLODE);
        if (tank.timerUpdate != null) {
            delete tank.timerUpdate;
        }
        g_Tanks.Erase(index);
    }
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
    if (!g_bCvarAllow) return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int target = GetClientOfUserId(event.GetInt("userid"));
    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));

    int index = FindTankIndex(attacker);
    if (index != -1) {
        TankData tank;
        g_Tanks.GetArray(index, tank);
        if (tank.waveCount < 2 && g_hCvarEnable.IntValue == 3) return;

        if ((tank.bossActive && g_hCvarEnable.IntValue == 1) || g_hCvarEnable.IntValue == 2 || (tank.bossActive && g_hCvarEnable.IntValue == 3)) {
            if (StrEqual(weapon, "tank_claw") && attacker == tank.bossId) {
                if (g_hCvarQuake.BoolValue && IsPlayerIncapped(target)) {
                    SkillEarthQuake(tank, target);
                }
                if (g_hCvarGravity.BoolValue && tank.formPrev == FORM_TWO) {
                    SkillGravityClaw(target);
                }
                if (g_hCvarDread.BoolValue && tank.formPrev == FORM_THREE) {
                    SkillDreadClaw(tank, target);
                }
                if (g_hCvarBurn.BoolValue && tank.formPrev == FORM_FOUR) {
                    SkillBurnClaw(target);
                }
            }
            if (StrEqual(weapon, "tank_rock") && attacker == tank.bossId && g_hCvarComet.BoolValue) {
                SkillCometStrike(target, tank.formPrev == FORM_FOUR ? MOLOTOV : EXPLODE);
            }
        }
    }

    index = FindTankIndex(target);
    if (index != -1) {
        TankData tank;
        g_Tanks.GetArray(index, tank);
        if (tank.waveCount < 2 && g_hCvarEnable.IntValue == 3) return;

        if ((tank.bossActive && g_hCvarEnable.IntValue == 1) || g_hCvarEnable.IntValue == 2 || (tank.bossActive && g_hCvarEnable.IntValue == 3)) {
            if (StrEqual(weapon, "melee") && target == tank.bossId) {
                if (g_hCvarSteel.BoolValue && tank.formPrev == FORM_TWO) {
                    EmitSoundToClient(attacker, SOUND_STEEL);
                    SetEntityHealth(tank.bossId, GetEventInt(event, "dmg_health") + GetEventInt(event, "health"));
                }
                if (g_hCvarGush.BoolValue && tank.formPrev == FORM_FOUR) {
                    SkillFlameGush(tank, attacker);
                }
            }
        }
    }
}

Action TimerLoad(Handle timer) {
    IsAllowed();
    return Plugin_Continue;
}

Action Timer_SetTankHealth(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));

    if (IsValidClient(tank.bossId)) {
        int finalHealth = (tank.lastWave || (StrEqual(currentMap, "c5m5_bridge") && g_hCvarForthC5M5Bridge.BoolValue)) ? g_iHealthForth : g_iHealthMax;
        SetEntProp(tank.bossId, Prop_Data, "m_iHealth", finalHealth);
        SetEntProp(tank.bossId, Prop_Data, "m_iMaxHealth", finalHealth);
    }
    return Plugin_Stop;
}

void SkillEarthQuake(TankData tank, int target) {
    if (!IsValidClient(target) || !IsPlayerIncapped(target)) return;

    float pos[3], tPos[3];
    GetClientAbsOrigin(tank.bossId, pos);
    for (int i = 1; i <= MaxClients; i++) {
        if (i == tank.bossId || !IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
        GetClientAbsOrigin(i, tPos);
        if (GetVectorDistance(tPos, pos) < g_fQuakeRadius) {
            EmitSoundToClient(i, SOUND_QUAKE);
            ScreenShake(i, 60.0);
            Smash(tank.bossId, i, g_fQuakeForce, 1.0, 1.5);
        }
    }
}

void SkillDreadClaw(TankData tank, int target) {
    tank.visibility = g_iDreadRate;
    CreateTimer(g_fDreadInterval, Timer_Dread, GetClientUserId(target));
    EmitSoundToAll(SOUND_DCLAW, target);
    ScreenFade(target, 0, 0, 0, tank.visibility, 0, 0);
    g_Tanks.SetArray(FindTankIndex(tank.bossId), tank);
}

void SkillGravityClaw(int target) {
    SetEntityGravity(target, 0.3);
    CreateTimer(g_fGravityInterval, Timer_Gravity, GetClientUserId(target));
    EmitSoundToAll(SOUND_GCLAW, target);
    ScreenFade(target, 0, 0, 100, 80, 4000, 1);
    ScreenShake(target, 30.0);
}

void SkillBurnClaw(int target) {
    int health = GetClientHealth(target);
    if (health > 0 && !IsPlayerIncapped(target)) {
        SetEntityHealth(target, 1);
        SetEntPropFloat(target, Prop_Send, "m_healthBuffer", float(health));
    }
    EmitSoundToAll(SOUND_BCLAW, target);
    ScreenFade(target, 200, 0, 0, 150, 80, 1);
    ScreenShake(target, 50.0);
}

void SkillCometStrike(int target, int type) {
    float pos[3];
    GetClientAbsOrigin(target, pos);
    if (type == MOLOTOV) {
        LittleFlower(pos, EXPLODE);
        LittleFlower(pos, MOLOTOV);
    } else {
        LittleFlower(pos, EXPLODE);
    }
}

void SkillFlameGush(TankData tank, int target) {
    SkillBurnClaw(target);
    float pos[3];
    GetClientAbsOrigin(tank.bossId, pos);
    LittleFlower(pos, MOLOTOV);
}

void SkillCallOfAbyss(TankData tank) {
    SetEntityMoveType(tank.bossId, MOVETYPE_NONE);
    SetEntProp(tank.bossId, Prop_Data, "m_takedamage", 0, 1);
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
        EmitSoundToClient(i, SOUND_HOWL);
        ScreenShake(i, 20.0);
    }
    if ((tank.formPrev == FORM_FOUR && g_hCvarAbyss.IntValue == 1) || g_hCvarAbyss.IntValue == 2) {
        TriggerPanicEvent();
    }
    CreateTimer(5.0, Timer_Howl, tank.bossId);
}

Action Timer_TankUpdate(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1 || !IsValidClient(client)) {
        return Plugin_Stop;
    }

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.waveCount < 2 && g_hCvarEnable.IntValue == 3) {
        return Plugin_Continue;
    }

    int health = GetClientHealth(tank.bossId);
    if (health > g_iHealthSecond) {
        if (tank.formPrev != FORM_ONE) SetParameters(tank, FORM_ONE);
    } else if (health > g_iHealthThird) {
        if (tank.formPrev != FORM_TWO) SetParameters(tank, FORM_TWO);
    } else if (health > g_iHealthForth) {
        ExtinguishEntity(tank.bossId);
        if (tank.formPrev != FORM_THREE) SetParameters(tank, FORM_THREE);
    } else if (health > 0) {
        if (tank.formPrev != FORM_FOUR) SetParameters(tank, FORM_FOUR);
    }
    g_Tanks.SetArray(index, tank);
    return Plugin_Continue;
}

void SetParameters(TankData tank, Form formNext) {
    tank.formPrev = formNext;
    int force;
    float speed;
    char color[32];

    if (formNext != FORM_ONE) {
        if (g_hCvarAbyss.BoolValue) SkillCallOfAbyss(tank);
        ExtinguishEntity(tank.bossId);
        AttachParticle(tank.bossId, PARTICLE_SPAWN);
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
            EmitSoundToClient(i, SOUND_CHANGE);
            ScreenFade(i, 200, 200, 255, 255, 100, 1);
        }
    }

    switch (formNext) {
        case FORM_ONE: {
            force = g_iForceFirst;
            speed = g_fSpeedFirst;
            strcopy(color, sizeof(color), g_sColorFirst);
            if (g_hCvarWarp.BoolValue) {
                CreateTimer(3.0, Timer_GetSurvivorPosition, tank.bossId, TIMER_REPEAT);
                CreateTimer(g_fWarpInterval, Timer_FatalMirror, tank.bossId, TIMER_REPEAT);
            }
        }
        case FORM_TWO: {
            if (g_hCvarAnnounce.BoolValue) PrintToChatAll(MSG_SECOND);
            force = g_iForceSecond;
            speed = g_fSpeedSecond;
            strcopy(color, sizeof(color), g_sColorSecond);
            SetEntityGravity(tank.bossId, g_fWeightSecond);
        }
        case FORM_THREE: {
            if (g_hCvarAnnounce.BoolValue) PrintToChatAll(MSG_THIRD);
            force = g_iForceThird;
            speed = g_fSpeedThird;
            strcopy(color, sizeof(color), g_sColorThird);
            SetEntityGravity(tank.bossId, 1.0);
            CreateTimer(0.8, Timer_Particle, tank.bossId, TIMER_REPEAT);
            if (g_hCvarStealth.BoolValue) CreateTimer(g_fStealthThird, Timer_Stealth, tank.bossId);
        }
        case FORM_FOUR: {
            if (g_hCvarAnnounce.BoolValue) PrintToChatAll(MSG_FORTH);
            force = g_iForceForth;
            speed = g_fSpeedForth;
            strcopy(color, sizeof(color), g_sColorForth);
            SetEntityGravity(tank.bossId, 1.0);
            IgniteEntity(tank.bossId, 9999.9);
            if (g_hCvarJump.BoolValue) CreateTimer(g_fJumpIntervalForth, Timer_Jumping, tank.bossId, TIMER_REPEAT);
        }
    }

    SetConVarInt(FindConVar("z_tank_throw_force"), force, true, true);
    SetEntPropFloat(tank.bossId, Prop_Send, "m_flLaggedMovementValue", speed);
    SetEntityRenderMode(tank.bossId, RENDER_NORMAL);
    DispatchKeyValue(tank.bossId, "rendercolor", color);
    g_Tanks.SetArray(FindTankIndex(tank.bossId), tank);
}

Action Timer_Particle(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.formPrev == FORM_THREE) {
        AttachParticle(tank.bossId, PARTICLE_THIRD);
    } else if (tank.formPrev == FORM_FOUR) {
        AttachParticle(tank.bossId, PARTICLE_FORTH);
    } else {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

Action Timer_Gravity(Handle timer, int userid) {
    int target = GetClientOfUserId(userid);
    if (IsValidClient(target)) SetEntityGravity(target, 1.0);
    return Plugin_Stop;
}

Action Timer_Jumping(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.formPrev == FORM_FOUR && IsValidClient(tank.bossId)) {
        AddVelocity(tank.bossId, g_fJumpHeightForth);
    } else {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

Action Timer_Stealth(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.formPrev == FORM_THREE && IsValidClient(tank.bossId)) {
        tank.alphaRate = 255;
        Remove(tank.bossId);
        g_Tanks.SetArray(index, tank);
    }
    return Plugin_Stop;
}

Action Timer_Dread(Handle timer, int userid) {
    int target = GetClientOfUserId(userid);
    if (!IsValidClient(target)) return Plugin_Stop;

    int index = FindTankIndex(target);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    tank.visibility -= 8;
    if (tank.visibility < 0) tank.visibility = 0;
    ScreenFade(target, 0, 0, 0, tank.visibility, 0, 1);
    g_Tanks.SetArray(index, tank);
    if (tank.visibility <= 0) return Plugin_Stop;
    return Plugin_Continue;
}

Action Timer_Howl(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (IsValidClient(tank.bossId)) {
        SetEntityMoveType(tank.bossId, MOVETYPE_WALK);
        SetEntProp(tank.bossId, Prop_Data, "m_takedamage", 2, 1);
    }
    return Plugin_Stop;
}

Action Timer_Warp(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (IsValidClient(tank.bossId)) {
        float pos[3];
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
            EmitSoundToClient(i, SOUND_WARP);
        }
        GetClientAbsOrigin(tank.bossId, pos);
        ShowParticle(pos, PARTICLE_WARP, 2.0);
        TeleportEntity(tank.bossId, tank.lastPos, NULL_VECTOR, NULL_VECTOR);
        ShowParticle(tank.lastPos, PARTICLE_WARP, 2.0);
        SetEntityMoveType(tank.bossId, MOVETYPE_WALK);
        SetEntProp(tank.bossId, Prop_Data, "m_takedamage", 2, 1);
    }
    return Plugin_Stop;
}

Action Timer_GetSurvivorPosition(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    int count = 0;
    int idAlive[MAXPLAYERS + 1];
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
        idAlive[count] = i;
        count++;
    }
    if (count == 0) return Plugin_Continue;
    int clientNum = GetRandomInt(0, count - 1);
    GetClientAbsOrigin(idAlive[clientNum], tank.lastPos);
    g_Tanks.SetArray(index, tank);
    return Plugin_Continue;
}

Action Timer_FatalMirror(Handle timer, int client) {
    int index = FindTankIndex(client);
    if (index == -1) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (IsValidClient(tank.bossId)) {
        SetEntityMoveType(tank.bossId, MOVETYPE_NONE);
        SetEntProp(tank.bossId, Prop_Data, "m_takedamage", 0, 1);
        CreateTimer(1.5, Timer_Warp, tank.bossId);
    } else {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

void Remove(int ent) {
    if (IsValidEntity(ent)) {
        int index = FindTankIndex(ent);
        if (index == -1) return;
        TankData tank;
        g_Tanks.GetArray(index, tank);
        CreateTimer(0.1, Timer_FadeOut, ent, TIMER_REPEAT);
        SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
    }
}

Action Timer_FadeOut(Handle timer, int ent) {
    int index = FindTankIndex(ent);
    if (index == -1 || !IsValidEntity(ent)) return Plugin_Stop;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.formPrev != FORM_THREE) return Plugin_Stop;
    tank.alphaRate -= 2;
    if (tank.alphaRate < 0) tank.alphaRate = 0;
    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
    SetEntityRenderColor(ent, 80, 80, 255, tank.alphaRate);
    g_Tanks.SetArray(index, tank);
    if (tank.alphaRate <= 0) return Plugin_Stop;
    return Plugin_Continue;
}

void AddVelocity(int client, float zSpeed) {
    int index = FindTankIndex(client);
    if (index == -1) return;

    TankData tank;
    g_Tanks.GetArray(index, tank);
    if (tank.velocityOffset == -1) return;

    float vecVelocity[3];
    GetEntDataVector(client, tank.velocityOffset, vecVelocity);
    vecVelocity[2] += zSpeed;
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

void LittleFlower(float pos[3], int type) {
    int entity = CreateEntityByName("prop_physics");
    if (IsValidEntity(entity)) {
        pos[2] += 10.0;
        DispatchKeyValue(entity, "model", type == MOLOTOV ? MODEL_GASCAN : MODEL_PROPANE);
        DispatchSpawn(entity);
        SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
        TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(entity, "break");
    }
}

void Smash(int client, int target, float power, float powHor, float powVec) {
    float headingVector[3], aimVector[3];
    GetClientEyeAngles(client, headingVector);
    aimVector[0] = Cosine(DegToRad(headingVector[1])) * power * powHor;
    aimVector[1] = Sine(DegToRad(headingVector[1])) * power * powHor;

    float current[3];
    GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

    float resulting[3];
    resulting[0] = current[0] + aimVector[0];
    resulting[1] = current[1] + aimVector[1];
    resulting[2] = power * powVec;
    TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type) {
    Handle msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    BfWriteShort(msg, type == 0 ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}

void ScreenShake(int target, float intensity) {
    Handle msg = StartMessageOne("Shake", target);
    BfWriteByte(msg, 0);
    BfWriteFloat(msg, intensity);
    BfWriteFloat(msg, 10.0);
    BfWriteFloat(msg, 3.0);
    EndMessage();
}

void TriggerPanicEvent() {
    int flager = GetAnyClient();
    if (flager == -1) return;
    int flag = GetCommandFlags("director_force_panic_event");
    SetCommandFlags("director_force_panic_event", flag & ~FCVAR_CHEAT);
    FakeClientCommand(flager, "director_force_panic_event");
}

void ShowParticle(float pos[3], char[] particleName, float time) {
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particleName);
        DispatchKeyValue(particle, "targetname", "particle");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, Timer_DeleteParticles, particle);
    }
}

void AttachParticle(int ent, char[] particleType) {
    char tName[64];
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        float pos[3];
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
        DispatchKeyValue(particle, "targetname", "tf2particle");
        DispatchKeyValue(particle, "parentname", tName);
        DispatchKeyValue(particle, "effect_name", particleType);
        DispatchSpawn(particle);
        SetVariantString(tName);
        AcceptEntityInput(particle, "SetParent", particle, particle, 0);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
    }
}

Action Timer_DeleteParticles(Handle timer, int particle) {
    if (IsValidEntity(particle)) {
        char classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) {
            RemoveEdict(particle);
        }
    }
    return Plugin_Stop;
}

void PrecacheParticle(char[] particleName) {
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        DispatchKeyValue(particle, "effect_name", particleName);
        DispatchKeyValue(particle, "targetname", "particle");
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(0.01, Timer_DeleteParticles, particle);
    }
}

bool IsPlayerIncapped(int client) {
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 0;
}

int GetAnyClient() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) return i;
    }
    return -1;
}

bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsValidEntity(client);
}

int FindTankIndex(int client) {
    for (int i = 0; i < g_Tanks.Length; i++) {
        TankData tank;
        g_Tanks.GetArray(i, tank);
        if (tank.bossId == client) return i;
    }
    return -1;
}