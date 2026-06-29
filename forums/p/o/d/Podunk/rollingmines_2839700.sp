#pragma semicolon 1
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION      "0.0.4"

#define DATABASE_NAME       "tf2_rollingmines_config"
#define TABLE_NAME_SETTINGS "rollingmines_settings"
#define TABLE_NAME_SPAWNPTS "rollingmines_spawnpts"
#define DEBUG               false

#define TICKS_ROLLDELAY     0.10
#define TICKS_JUMPDELAY     0.50
#define TICKS_DIEDELAY      1.0
#define TICKRATE_THINK      0.01
#define TICKRATE_TARGETING  0.5
#define TICKRATE_SPAWNER    1.0
#define ZAPRATE_MIN         0.1
#define ZAPRATE_MAX         3.0
#define MAXENTITIES         4096
#define STATUS_DISPOSE      Dispose

// settings for m_takedamage
#define DAMAGE_NO           0
#define DAMAGE_EVENTS_ONLY  1    // Call damage functions, but don't modify health
#define DAMAGE_YES          2
#define DAMAGE_AIM          3

#define Z_OFFSET_           100.0

enum Status
{
    Idle,
    Attack,
    Jump,
    Die,
    Dispose,
};
enum Spikes
{
    Spikes_Retracted,
    Spikes_Deployed
};
enum TargetAcquisitionMode
{
    Focused,
    AlwaysNearest
};

// VScript file name (save the Squirrel script as "rollingmines.nut" in the "scripts/vscripts" folder)
#define VSCRIPT_NAME                    "rollingmines"
#define VSCRIPT_FILENAME                "rollingmines.nut"

#define VS_ROLL                         "RollBallTowardsEntity(%d, %d, %f)"
#define VS_HALT                         "MomentumCancel(%d)"
#define VS_JUMP                         "SpinJump(%d)"

#define MDL_ROLLER                      "models/roller.mdl"
#define MDL_ROLLER_SPIKES               "models/roller_spikes.mdl"

#define SPR_BLUELIGHT1                  "sprites/bluelight1.vmt"
#define SPR_SHOK                        "sprites/rollermine_shock.vmt"

#define SOUND_COMBINE_MINE_ACTIVE_LOOP1 "npc/roller/mine/combine_mine_active_loop1.wav"
#define SOUND_COMBINE_MINE_DEACTIVATE1  "npc/roller/mine/combine_mine_deactivate1.wav"
#define SOUND_COMBINE_MINE_DEPLOY1      "npc/roller/mine/combine_mine_deploy1.wav"
#define SOUND_BLADES_IN1                "npc/roller/mine/rmine_blades_in1.wav"
#define SOUND_BLADES_IN2                "npc/roller/mine/rmine_blades_in2.wav"
#define SOUND_BLADES_IN3                "npc/roller/mine/rmine_blades_in3.wav"
#define SOUND_BLADES_OUT1               "npc/roller/mine/rmine_blades_out1.wav"
#define SOUND_BLADES_OUT2               "npc/roller/mine/rmine_blades_out2.wav"
#define SOUND_BLADES_OUT3               "npc/roller/mine/rmine_blades_out3.wav"
#define SOUND_BLIP1                     "npc/roller/mine/rmine_blip1.wav"
#define SOUND_BLIP3                     "npc/roller/mine/rmine_blip3.wav"
#define SOUND_CHIRP_ANSWER1             "npc/roller/mine/rmine_chirp_answer1.wav"
#define SOUND_CHIRP_QUEST1              "npc/roller/mine/rmine_chirp_quest1.wav"
#define SOUND_EXPLODE_SHOCK1            "npc/roller/mine/rmine_explode_shock1.wav"
#define SOUND_MOVEFAST_LOOP1            "npc/roller/mine/rmine_movefast_loop1.wav"
#define SOUND_MOVESLOW_LOOP1            "npc/roller/mine/rmine_moveslow_loop1.wav"
#define SOUND_PREDETONATE               "npc/roller/mine/rmine_predetonate.wav"
#define SOUND_SEEK_LOOP2                "npc/roller/mine/rmine_seek_loop2.wav"
#define SOUND_SHOCKVEHICLE1             "npc/roller/mine/rmine_shockvehicle1.wav"
#define SOUND_SHOCKVEHICLE2             "npc/roller/mine/rmine_shockvehicle2.wav"
#define SOUND_TAUNT1                    "npc/roller/mine/rmine_taunt1.wav"
#define SOUND_TAUNT2                    "npc/roller/mine/rmine_taunt2.wav"
#define SOUND_TOSSED1                   "npc/roller/mine/rmine_tossed1.wav"
#define SOUND_ZAP                       "npc/assassin/ball_zap1.wav"



new TargetAcquisitionMode:_tm = AlwaysNearest;

new g_iHP = 100;
new g_iAcquisitionDistance = 1000;
new g_iSpikeDeploymentDistance = 500;
new g_iSpawnRate = 0;

int g_shokDmg = 20;

int g_iBoomDmg = 150;
float g_boomDist = 100.0;

int CachedTgt = 0;// for debugging
bool neverDie = false;// for debugging

Status                _st          = Idle;
Spikes                _sp          = Spikes_Retracted;
float                 _st_ticks    = 0.0;
int                   tgt          = 0;
float                 tgtDist      = 0.0;
float                 roll_ticks   = 0.0;
float                 died_at      = 0.0;
bool                  soundPlaying = false;
float                 zapSndPlayedAt=0.0;

int                   spicyTargets[MAXPLAYERS + 1];            // Array to store client indices
float                 spicyTargetDistances[MAXPLAYERS + 1];    // Array to store distances
int                   spicyTargetCount = 0;                    // Track number of valid targets
float                 g_pos[3];
int                   iRlr_r;    // roller entity reference
float                 playbackRate = 1.0;
int                   currentHp    = 0;

int g_iShockIndex = -1;
int g_iShockHaloIndex = -1;


// Menu handler
new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;
new String:g_sConfigFile[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
    name        = "[TF2] RollingMines!",
    author      = "Podunk",
    description = "explosive rolling mines",
    version     = PLUGIN_VERSION,
    url         = "none",
};

public OnPluginStart()
{
    CreateConVar("sm_rm_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    RegAdminCmd("sm_rm", SpawnForClient, ADMFLAG_CONFIG, "Place an experimental rolling mine");

    BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/rollingmines.db");
    DatabaseConnect();
    
    // Register commands for custom values
    RegAdminCmd("sm_rm_set_targetmode", Command_SetTargetMode, ADMFLAG_ROOT, "Set target acquisition mode");
    RegAdminCmd("sm_rm_set_damage", Command_SetDamage, ADMFLAG_ROOT, "Set damage value");
    RegAdminCmd("sm_rm_set_hp", Command_SetHP, ADMFLAG_ROOT, "Set HP value");
    RegAdminCmd("sm_rm_set_acqdist", Command_SetAcqDist, ADMFLAG_ROOT, "Set acquisition distance");
    RegAdminCmd("sm_rm_set_spikedist", Command_SetSpikeDist, ADMFLAG_ROOT, "Set spike deployment distance");
    RegAdminCmd("sm_rm_set_spawnrate", Command_SetSpawnRate, ADMFLAG_ROOT, "Set spawn rate");
    
    // Register menu command
    RegAdminCmd("sm_rm_menu", Command_RollingMineMenu, ADMFLAG_ROOT, "Open RollingMines! config menu");


    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_setup_finished", Event_SetupFinished);
    HookEvent("teamplay_round_active", Event_RoundActive);

    initialize();
}
public OnPluginEnd()
{
    if (g_hDatabase != INVALID_HANDLE)
        CloseHandle(g_hDatabase);
    if (g_hMainMenu != INVALID_HANDLE)
        CloseHandle(g_hMainMenu);
}
public OnMapStart()
{
    //  Precache the new model if needed (recommended to avoid errors)
    PrecacheModel(MDL_ROLLER_SPIKES, true);
    PrecacheModel(MDL_ROLLER, true);

    g_iShockHaloIndex = PrecacheModel(SPR_BLUELIGHT1);
    g_iShockIndex = PrecacheModel(SPR_SHOK);

    PrecacheSound(SOUND_COMBINE_MINE_ACTIVE_LOOP1);
    PrecacheSound(SOUND_COMBINE_MINE_DEACTIVATE1);
    PrecacheSound(SOUND_COMBINE_MINE_DEPLOY1);
    PrecacheSound(SOUND_BLADES_IN1);
    PrecacheSound(SOUND_BLADES_IN2);
    PrecacheSound(SOUND_BLADES_IN3);
    PrecacheSound(SOUND_BLADES_OUT1);
    PrecacheSound(SOUND_BLADES_OUT2);
    PrecacheSound(SOUND_BLADES_OUT3);
    PrecacheSound(SOUND_BLIP1);
    PrecacheSound(SOUND_BLIP3);
    PrecacheSound(SOUND_CHIRP_ANSWER1);
    PrecacheSound(SOUND_CHIRP_QUEST1);
    PrecacheSound(SOUND_EXPLODE_SHOCK1);
    PrecacheSound(SOUND_MOVEFAST_LOOP1);
    PrecacheSound(SOUND_MOVESLOW_LOOP1);
    PrecacheSound(SOUND_PREDETONATE);
    PrecacheSound(SOUND_SEEK_LOOP2);
    PrecacheSound(SOUND_SHOCKVEHICLE1);
    PrecacheSound(SOUND_SHOCKVEHICLE2);
    PrecacheSound(SOUND_TAUNT1);
    PrecacheSound(SOUND_TAUNT2);
    PrecacheSound(SOUND_TOSSED1);
    PrecacheSound(SOUND_ZAP);
    

    CreateTimer(TICKRATE_TARGETING, Timer_CheckForSpicyTargets, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(ZAPRATE_MIN, Timer_Zapper, 0, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(TICKRATE_SPAWNER, Timer_Spawner, 0, TIMER_FLAG_NO_MAPCHANGE);

    initialize();
}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    initialize();
}
public void Event_SetupFinished(Event event, const char[] name, bool dontBroadcast)
{
    initialize();
}
public void Event_RoundActive(Event event, const char[] name, bool dontBroadcast)
{
    initialize();
}

initialize()
{
    SetStatus(Idle);
    ResetTiming();
    roll_ticks = _st_ticks;
    died_at = GetTickedTime();
    tgt          = 0;
    tgtDist      = 0.0;
    currentHp = 0;
    iRlr_r = 0;
}

public ResetTiming()
{
    _st_ticks = GetTickedTime();
}

public float GetTicks()
{
    return GetTickedTime() - _st_ticks;
}

public bool Delay(float interval)
{
    if (GetTicks() > interval)
    {
        ResetTiming();
        return true;
    }
    return false;
}

public Status SetStatus(Status status)
{
    if (status == _st)
        return status;
#if DEBUG
    int k = _st;
#endif
    _st = status;
#if DEBUG
    PrintToChatAll("_st: %i => %i", k, _st);
#endif
    ResetTiming();
    StatusSound(status);
    roll_ticks = _st_ticks;
    return status;
}

SpikeSound(int iRlr)
{
    if (_sp == Spikes_Retracted)
    {
        switch (GetRandomInt(1, 3))
        {
            case 1:
            {
                PlaySound(iRlr, true, SOUND_BLADES_IN1, 1.0);
            }
            case 2:
            {
                PlaySound(iRlr, true, SOUND_BLADES_IN2, 1.0);
            }
            case 3:
            {
                PlaySound(iRlr, true, SOUND_BLADES_IN3, 1.0);
            }
        }
    }
    else if (_sp == Spikes_Deployed)
    {
        switch (GetRandomInt(1, 3))
        {
            case 1:
            {
                PlaySound(iRlr, true, SOUND_BLADES_OUT1, 1.0);
            }
            case 2:
            {
                PlaySound(iRlr, true, SOUND_BLADES_OUT2, 1.0);
            }
            case 3:
            {
                PlaySound(iRlr, true, SOUND_BLADES_OUT3, 1.0);
            }
        }
    }
}

public ManageSpikes(int iRlr)
{
    // int entity = EntRefToEntIndex(iRlr_r);
    if (iRlr != 0 && IsValidEntity(iRlr))
    {
        if (_st == Idle)
        {
            if (_sp == Spikes_Deployed)
            {
                SetEntityModel(iRlr, MDL_ROLLER);

                _sp = Spikes_Retracted;
                SpikeSound(iRlr);
            }
        }
        else
        {
            if (tgtDist > g_iSpikeDeploymentDistance && _sp == Spikes_Deployed)
            {
                SetEntityModel(iRlr, MDL_ROLLER);
                _sp = Spikes_Retracted;
                SpikeSound(iRlr);
            }
            else if (tgtDist < g_iSpikeDeploymentDistance && _sp == Spikes_Retracted)
            {
                SetEntityModel(iRlr, MDL_ROLLER_SPIKES);
                _sp = Spikes_Deployed;
                SpikeSound(iRlr);
            }
        }
    }
}

StatusLoopSound(Status status)
{
    if (GetTickedTime() - zapSndPlayedAt < 1.0){
        return;
    }
    if (soundPlaying)
    {
        return;
    }
    if (iRlr_r == 0)
    {
        return;
    }
    int iRlr = EntRefToEntIndex(iRlr_r);
    if (iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr))
    {
        return;
    }

    switch (status)
    {
        case Attack:
        {
            if (_sp == Spikes_Retracted)
            {
                switch (GetRandomInt(1, 2))
                {
                    case 1:
                    {
                        PlaySound(iRlr, false, SOUND_MOVESLOW_LOOP1, 5.0);
                    }
                    case 2:
                    {
                        PlaySound(iRlr, false, SOUND_SEEK_LOOP2, 1.0);
                    }
                }
            }
            else if (_sp == Spikes_Deployed) {
                PlaySound(iRlr, false, SOUND_MOVEFAST_LOOP1, 0.10);
            }
        }
        case Idle:
        {
            if (GetRandomInt(1, 10) == 1)
            {
                switch (GetRandomInt(1, 2))
                {
                    case 1:
                    {
                        PlaySound(iRlr, false, SOUND_BLIP1, 1.0);
                    }
                    case 2:
                    {
                        PlaySound(iRlr, false, SOUND_BLIP3, 1.0);
                    }
                }
            }
        }
    }
}

StatusSound(Status status)
{
    if (iRlr_r == 0)
    {
        return;
    }
    int iRlr = EntRefToEntIndex(iRlr_r);
    if (iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr))
    {
        return;
    }

    switch (status)
    {
        case Attack:
        {
            PlaySound(iRlr, true, SOUND_CHIRP_QUEST1, 1.0);
        }
        case Idle:
        {
            PlaySound(iRlr, true, SOUND_COMBINE_MINE_DEACTIVATE1, 1.0);
            // PlaySound(iRlr, true, SOUND_COMBINE_MINE_DEPLOY1, 1.0);
        }
        case Jump:
        {
            PlaySound(iRlr, false, SOUND_PREDETONATE, 1.0);
        }
    }
}

PlaySound(int ent, bool loopAfter, const char[] snd, float duration)
{
    soundPlaying = true;
    EmitSoundToAll(snd, ent, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
    CreateTimer(duration, Sound_Done, loopAfter, TIMER_FLAG_NO_MAPCHANGE);
}
Sound_Done(loopAfter)
{
    soundPlaying = false;
    if (loopAfter)
        StatusLoopSound(_st);
}
public Action SpawnForClient(client, args)
{
    if (!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    g_pos[2] += Z_OFFSET_;
    new_roller_mine();
    return Plugin_Handled;
}
public bool get_random_spawnpt()
{
    g_pos[0] =  0.0;
    g_pos[1] =  0.0;
    g_pos[2] =  0.0;

    decl String:map[254];
    GetCurrentMap(map, sizeof(map));


    char query[256];
    Format(query, sizeof(query), "SELECT x,y,z FROM '%s' WHERE map = '%s'", TABLE_NAME_SPAWNPTS, map);
    DBResultSet results = SQL_Query(g_hDatabase, query);
    if (results == null) {
        char error[256];
        SQL_GetError(g_hDatabase, error, sizeof(error));
        PrintToServer("Query failed: %s", error);
        return false;
    }

    int rowCount = SQL_GetRowCount(results);
    int chosenPt = GetRandomInt(0,rowCount -1);

    int pt=0;
    bool success=false;
    DBResult status;  // For checking fetch status
    while (SQL_FetchRow(results)) {
        if (pt == chosenPt){
            g_pos[0] = SQL_FetchFloat(results, 0, status);
            if (status != DBVal_Data) {
                PrintToServer("Failed to fetch x (column 0) for row %d: Status %d", pt, status);
                delete results;
                return false;
            }

            g_pos[1] = SQL_FetchFloat(results, 1, status);
            if (status != DBVal_Data) {
                PrintToServer("Failed to fetch y (column 1) for row %d: Status %d", pt, status);
                delete results;
                return false;
            }

            g_pos[2] = SQL_FetchFloat(results, 2, status);
            if (status != DBVal_Data) {
                PrintToServer("Failed to fetch z (column 2) for row %d: Status %d", pt, status);
                delete results;
                return false;
            }

            g_pos[2] += Z_OFFSET_;
            success=true;
        }
        pt++;
    }
    delete results;
    return success;
}
public Action Timer_Spawner(int _any)
{
    if (g_iSpawnRate != -1 && !(iRlr_r != 0 && IsValidEntity(EntRefToEntIndex(iRlr_r)))){
         if (GetTickedTime() - died_at >= g_iSpawnRate){
            if (get_random_spawnpt())
                new_roller_mine();
        }
    }
    CreateTimer(TICKRATE_SPAWNER, Timer_Spawner, 0, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}
new_roller_mine()
{
    initialize();
    int iRlr = CreateEntityByName("prop_physics_override");
    if (!IsValidEntity(iRlr))
    {
        PrintToServer("Failed to create prop_physics_override");
        return;
    }
    iRlr_r   = EntIndexToEntRef(iRlr);
    DispatchKeyValue(iRlr, "model", MDL_ROLLER);
    DispatchKeyValue(iRlr, "targetname", "rollingmine");

    TeleportEntity(iRlr, g_pos, NULL_VECTOR, NULL_VECTOR);
    // char strName[64];
    // strName = "rollingmine";
    // SetEntProp(iRlr, Prop_Data, "m_iName", strName, sizeof(strName));
    SetEntProp(iRlr, Prop_Data, "m_nSolidType", 6);      // SOLID_VPHYSICS for full collision
    SetEntProp(iRlr, Prop_Send, "m_usSolidFlags", 0);    // Ensure no special flags disable collision
    DispatchKeyValue(iRlr, "physdamagescale", "1.0");
    DispatchSpawn(iRlr);
    SetEntProp(iRlr, Prop_Data, "m_nSequence", 0);
    SetEntPropFloat(iRlr, Prop_Data, "m_flPlaybackRate", playbackRate);
    currentHp = g_iHP;
    _sp                 = Spikes_Retracted;
    SetEntProp(iRlr, Prop_Data, "m_iHealth", g_iHP);
    SetEntProp(iRlr, Prop_Data, "m_takedamage", DAMAGE_YES);    // DAMAGETAKE_DEFAULT (allows all damage types)
    SDKHook(iRlr, SDKHook_OnTakeDamage, OnTakeDamage);          // Hook damage
    SetStatus(Idle);

    LoadVScript(VSCRIPT_NAME);
    // ExecVScript("Init();");
    SetVScript(iRlr, VSCRIPT_FILENAME);
    // RunVScriptCode(iRlr, "Init();");

    CreateTimer(TICKRATE_THINK, Timer_Think, iRlr_r, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    PrintToServer("Spawned rollingmine prop_physics_override with targetname 'rollingmine'");

    return;
}
roller_kill(int iRlr)
{
    if (iRlr != 0 && IsValidEntity(iRlr))
    {
        float clientPos[3];
        GetEntPropVector(iRlr, Prop_Data, "m_vecOrigin", clientPos);

        new explosion = CreateEntityByName("env_explosion");
        if (explosion)
        {
            DispatchSpawn(explosion);
            TeleportEntity(explosion, clientPos, NULL_VECTOR, NULL_VECTOR);
            AcceptEntityInput(explosion, "Explode", -1, -1, 0);
            RemoveEdict(explosion);
        }

        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsValidClient(i)) continue;
            if (!IsPlayerAlive(i)) continue;
            float zPos[3];
            GetClientAbsOrigin(i, zPos);
            float Dist = GetVectorDistance(clientPos, zPos);
            int   dmg  = GetDmg(Dist, g_iBoomDmg, g_boomDist*2);
            if (dmg > 0)
            {
                // EmitSoundToAll(SOUND_PAIN, i, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
                DoDamage(iRlr, i, dmg);
            }
        }
        for (new i = MaxClients + 1; i <= 2048; i++)
        {
            if (!IsValidEntity(i)) continue;
            char cls[20];
            GetEntityClassname(i, cls, sizeof(cls));
            if (!StrEqual(cls, "obj_sentrygun", false) && !StrEqual(cls, "obj_dispenser", false) && !StrEqual(cls, "obj_teleporter", false)) continue;
            float zPos[3];
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", zPos);
            float Dist = GetVectorDistance(clientPos, zPos);
            int   dmg  = GetDmg(Dist, g_iBoomDmg, g_boomDist*2);
            if (dmg > 0)
            {
                SetVariantInt(dmg);
                AcceptEntityInput(i, "RemoveHealth");
            }
        }
    }
    AcceptEntityInput(iRlr, "Break");
    RemoveEntity(iRlr);
    initialize();
}
public void OnEntityDestroyed(int entity)
{
    // copied from: https://github.com/Pelipoika/TF2-Rollermines/blob/master/rollermine.sp // THANK YOU!!!
	if(entity > MaxClients)
	{
		char strName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrContains(strName, "rollingmine") != -1)
		{
			StopSound(entity, SNDCHAN_AUTO, SOUND_SEEK_LOOP2);
			StopSound(entity, SNDCHAN_AUTO, SOUND_MOVESLOW_LOOP1);
			StopSound(entity, SNDCHAN_AUTO, SOUND_MOVEFAST_LOOP1);
		}
	}
}
int GetDmg(float dist, int baseDmg, float maxDist)
{
    if (dist > maxDist)
        return 0;
    // Linearly interpolate damage: full damage at dist=0, no damage at dist=300
    return RoundToFloor(baseDmg * (1 - dist / maxDist));
}
stock bool IsValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    return true;
}
stock void ShockTarget(int iRollermine, int iTarget)
{
    // copied from: https://github.com/Pelipoika/TF2-Rollermines/blob/master/rollermine.sp // THANK YOU!!!
    TE_SetupBeamLaser(iRollermine, iTarget, g_iShockIndex, g_iShockHaloIndex, 0, 1, 0.5, 16.0, 16.0, 300, 16.0, {255, 255, 255, 255}, 1);
    TE_SendToAll();
}

stock DoDamage(client, target, amount)    // from Goomba Stomp.
{
    if (target < 1 || !IsValidEntity(target))
        return;
    new pointHurt = CreateEntityByName("point_hurt");
    if (pointHurt)
    {
        DispatchKeyValue(target, "targetname", "explodeme");
        DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
        char dmg[15];
        Format(dmg, 15, "%i", amount);
        DispatchKeyValue(pointHurt, "Damage", dmg);
        DispatchKeyValue(pointHurt, "DamageType", "0");

        DispatchSpawn(pointHurt);
        AcceptEntityInput(pointHurt, "Hurt", client);
        DispatchKeyValue(pointHurt, "classname", "point_hurt");
        DispatchKeyValue(target, "targetname", "");
        RemoveEdict(pointHurt);
    }
}

public void CacheCurrentTarget()
{
    CachedTgt = tgt;
}
public int GetCachedTarget()
{
    return CachedTgt;
}
public bool ValidateOrAquireAnotherTarget()
{
    CacheCurrentTarget();
    bool r = ValidateOrAquireAnotherTarget2();
#if DEBUG
    if (GetCachedTarget() != tgt){
        if (tgt == -1){
            PrintToChatAll("no target");
        }else{
            char currentName[MAX_NAME_LENGTH];
            GetClientName(tgt, currentName, MAX_NAME_LENGTH);
            PrintToChatAll("target: %d, %s", tgt, currentName);
        }
    }
#endif
    return r;
}
public bool ValidateOrAquireAnotherTarget2()
{
    bool found = false;
    if (spicyTargetCount < 1)
    {
        tgt = -1;
        return false;
    }
    if (_tm == Focused)
    {
        for (int i = 0; i < spicyTargetCount; i++)
        {
            if (spicyTargets[i] == tgt)
            {
                tgtDist = spicyTargetDistances[i];
                found   = true;
                break;
            }
        }
    }
    if (_tm == AlwaysNearest || !found)
    {
        tgt = GetClosestTarget();
    }
    return true;
}

int GetClosestTarget()
{
    float closestDist  = 999999.0;
    int   closestIndex = -1;
    for (int i = 0; i < spicyTargetCount; i++)
    {
        if (spicyTargetDistances[i] < closestDist)
        {
            closestDist  = spicyTargetDistances[i];
            closestIndex = i;
        }
    }
    if (closestIndex > -1)
    {
        tgtDist = spicyTargetDistances[closestIndex];
        return spicyTargets[closestIndex];
    }
    return -1;
}

public Action Timer_Think(Handle timer, int entityRef)
{
    // stage 0
    if (entityRef != iRlr_r)
    {
        return Plugin_Stop;    // hack, doesn't cleanup
    }
    int iRlr = EntRefToEntIndex(entityRef);
    if (iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr))
    {
        return Plugin_Stop;
    }
    if (_st == STATUS_DISPOSE)
    {
        SDKUnhook(iRlr, SDKHook_OnTakeDamage, OnTakeDamage);
        return Plugin_Stop;
    }
    // stage 1
    if (!IsValidEntity(iRlr))
    {
        SetStatus(Dispose);
        return Plugin_Continue;
    }
    bool validTarget = ValidateOrAquireAnotherTarget();
    if (!validTarget && _st == Attack)
    {
        SetStatus(Idle);
    }
    else if (validTarget && _st == Idle)
    {
        SetStatus(Attack);
    }
    // else if (_st == Attack)
    // {
    //     SetStatus(Idle);
    // }
    ManageSpikes(iRlr);
    StatusLoopSound(_st);
    // stage 2
    if (_st == Attack && Delay(TICKS_ROLLDELAY))
    {
        float ballPos[3], playerPos[3];
        GetEntPropVector(iRlr, Prop_Data, "m_vecOrigin", ballPos);
        GetClientEyePosition(tgt, playerPos);

        // Calculate direction vector
        float direction[3];
        SubtractVectors(playerPos, ballPos, direction);
        float distance = GetVectorLength(direction);

        if (distance < g_boomDist && !neverDie)    // Avoid division by zero or tiny movements
        {
            // ExecVScript(VS_HALT, entity);
            RunVScriptCode(iRlr, VS_HALT, iRlr);
            SetStatus(Jump);
            return Plugin_Continue;
        }
        // ExecVScript(VS_ROLL, entity, tgt);
        float time = GetTickedTime() - roll_ticks;
        // PrintToChatAll("time %f", time);
        RunVScriptCode(iRlr, VS_ROLL, iRlr, tgt, time);
        roll_ticks = GetTickedTime();
        return Plugin_Continue;
    }
    else if (_st == Jump && Delay(TICKS_JUMPDELAY))
    {
        // ExecVScript(VS_JUMP, entity);
        RunVScriptCode(iRlr, VS_JUMP, iRlr);
        SetStatus(Die);
        return Plugin_Continue;
    }
    else if (_st == Die && Delay(TICKS_DIEDELAY))
    {
        roller_kill(iRlr);
        SetStatus(Dispose);
        return Plugin_Continue;
    }
    else
    {
        return Plugin_Continue;
    }
}
public Action Timer_Zapper(int _any)
{
    if (iRlr_r != 0)
    {
        int iRlr = EntRefToEntIndex(iRlr_r);
        if (!(iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr)))
        {
            for (int i = 0; i < spicyTargetCount; i++)
            {
                if (spicyTargetDistances[i] < g_iSpikeDeploymentDistance)
                {
                    zapSndPlayedAt = GetTickedTime();
                    EmitSoundToAll(SOUND_ZAP, iRlr, SNDCHAN_VOICE, SNDLEVEL_SCREAMING);
                    DoDamage(iRlr, spicyTargets[i], GetDmg(spicyTargetDistances[i], g_shokDmg, float(g_iSpikeDeploymentDistance) * 2));
                    ShockTarget(iRlr, spicyTargets[i]);
                }
            }
        }
    }
    float zr = GetRandomFloat(ZAPRATE_MIN, ZAPRATE_MAX);
    CreateTimer(zr, Timer_Zapper, 0, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}
public Action Timer_CheckForSpicyTargets(int _any)
{
    int iRlr = EntRefToEntIndex(iRlr_r);
    if (iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr))
    {
        return Plugin_Continue;
    }
    // Clear arrays before populating
    spicyTargetCount = 0;
    for (int i = 0; i <= MAXPLAYERS; i++)
    {
        spicyTargets[i]         = 0;
        spicyTargetDistances[i] = 0.0;
    }

    float minePos[3];
    GetEntPropVector(iRlr, Prop_Data, "m_vecOrigin", minePos);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        float targetPos[3];

        if(TF2_IsPlayerInCondition(i, TFCond_Disguised) || TF2_IsPlayerInCondition(i, TFCond_Cloaked)
            || TF2_IsPlayerInCondition(i, TFCond_Stealthed) || TF2_IsPlayerInCondition(i, TFCond_CloakFlicker)
            // || TF2_IsPlayerInCondition(i, TFCond_DeadRingered)
            || TF2_GetClientTeam(i) == TFTeam_Spectator
            )
		continue;

        // GetClientAbsOrigin(i, targetPos);

        GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetPos);

        // Calculate distance
        float distance = GetVectorDistance(minePos, targetPos);
        targetPos[2] += 55.0;    // Adjust z to target the center (e.g., chest height)

        // Check distance
        if (distance <= g_iAcquisitionDistance)
        {
            Handle trace = TR_TraceRayFilterEx(minePos, targetPos, MASK_VISIBLE, RayType_EndPoint, TraceFilter_ValidTarget, iRlr);
            if (TR_DidHit(trace))
            {
                int hitEntity = TR_GetEntityIndex(trace);
                if (hitEntity == i)
                {
                    // Store client index and distance
                    spicyTargets[spicyTargetCount]         = i;
                    spicyTargetDistances[spicyTargetCount] = distance;
                    spicyTargetCount++;
                }
            }
            CloseHandle(trace);
        }
    }
    return Plugin_Continue;
}

public bool TraceFilter_ValidTarget(int entity, int contentsMask, any data)
{
    return (entity > 0 && entity <= MaxClients);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsValidEntity(victim) || currentHp <= 0)
    {
        return Plugin_Continue;
    }
    int iRlr = EntRefToEntIndex(iRlr_r);
    if (iRlr == -1 || iRlr == 0 || !IsValidEntity(iRlr))
    {
        return Plugin_Handled;
    }
    if (iRlr != victim)
    {
        return Plugin_Handled;
    }
    // Reduce health
    currentHp -= RoundToFloor(damage);
#if DEBUG
    PrintToChatAll("Prop took %.0f damage! Remaining health: %d", damage, currentHp);
#endif
    if (currentHp <= 0 && !neverDie)
    {
        roller_kill(victim);
        currentHp = 0;
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public bool TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > MaxClients || !entity;
}
SetTeleportEndPoint(client)
{
    float vAngles[3];
    float vOrigin[3];
    float vBuffer[3];
    float vStart[3];
    float Distance;

    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);

    // get endpoint for teleport
    Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if (TR_DidHit(trace))
    {
        TR_GetEndPosition(vStart, trace);
        GetVectorDistance(vOrigin, vStart, false);
        Distance = -35.0;
        GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
        g_pos[0] = vStart[0] + (vBuffer[0] * Distance);
        g_pos[1] = vStart[1] + (vBuffer[1] * Distance);
        g_pos[2] = vStart[2] + (vBuffer[2] * Distance);
    }
    else
    {
        CloseHandle(trace);
        return false;
    }

    CloseHandle(trace);
    return true;
}

SetVScript(int entity, const char[] format, any...)
{
    char vscriptPath[128];
    VFormat(vscriptPath, sizeof(vscriptPath), format, 3);    // 3 is the 1-based index of the '...' in this function's parameters
#if DEBUG
    PrintToServer("vscriptPath: %s", vscriptPath);
#endif
    DispatchKeyValue(entity, "vscripts", vscriptPath);
}

LoadVScript(const char[] format, any...)
{
    char scriptNam[128];
    VFormat(scriptNam, sizeof(scriptNam), format, 2);    // 2 is the 1-based index of the '...' in this function's parameters
    char scriptCmd[128];
    Format(scriptCmd, sizeof(scriptCmd), "script_execute %s", scriptNam);
#if DEBUG
    PrintToServer("LoadVScript: %s", scriptCmd);
#endif
    ServerCommand(scriptCmd);
}

RunVScriptCode(int entity, const char[] format, any...)
{
    char scriptCmd[128];
    VFormat(scriptCmd, sizeof(scriptCmd), format, 3);    // 3 is the 1-based index of the '...' in this function's parameters
    SetVariantString(scriptCmd);
    AcceptEntityInput(entity, "RunScriptCode");
}






////////////////////////////////////////////////
/////////////
/////////////   MENU & CONFIG
/////////////
////////////////////////////////////////////////






DatabaseConnect()
{
    if (SQL_CheckConfig(DATABASE_NAME))
    {
        g_hDatabase = SQL_Connect(DATABASE_NAME, true, g_sConfigFile, sizeof(g_sConfigFile));
        if (g_hDatabase == INVALID_HANDLE)
        {
            LogError("Could not connect to database");
            return;
        }
        
        decl String:query[512];
        Format(query, sizeof(query), 
            "CREATE TABLE IF NOT EXISTS %s (\
            setting VARCHAR(32) PRIMARY KEY,\
            value INTEGER)", TABLE_NAME_SETTINGS);
        SQL_TQuery(g_hDatabase, SQLCallback_Void, query);

        decl String:query2[512];
        Format(query2, sizeof(query2), 
            "CREATE TABLE IF NOT EXISTS %s (\
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,\
            map VARCHAR(255),\
            x FLOAT,y FLOAT,z FLOAT)",
            TABLE_NAME_SPAWNPTS);
        SQL_TQuery(g_hDatabase, SQLCallback_Void, query2);
        
        LoadConfig();
    }
    else
    {
        LogError("Database config '%s' not found", DATABASE_NAME);
    }
}

public SQLCallback_Void(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Database error: %s", error);
    }
}

SaveConfig(const String:setting[], value)
{
    if (g_hDatabase == INVALID_HANDLE)
        return;
        
    decl String:query[256];
    Format(query, sizeof(query), 
        "INSERT OR REPLACE INTO %s (setting, value) VALUES ('%s', %d)",
        TABLE_NAME_SETTINGS, setting, value);
    SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
}

LoadConfig()
{
    if (g_hDatabase == INVALID_HANDLE)
        return;
        
    decl String:query[256];
    Format(query, sizeof(query), "SELECT setting, value FROM %s", TABLE_NAME_SETTINGS);
    SQL_TQuery(g_hDatabase, SQLCallback_LoadConfig, query);
}

public SQLCallback_LoadConfig(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Load config error: %s", error);
        return;
    }
    
    while (SQL_FetchRow(hndl))
    {
        decl String:setting[32];
        SQL_FetchString(hndl, 0, setting, sizeof(setting));
        new value = SQL_FetchInt(hndl, 1);
        
        if (StrEqual(setting, "target_mode"))
            _tm = TargetAcquisitionMode:value;
        else if (StrEqual(setting, "damage"))
            g_iBoomDmg = value;
        else if (StrEqual(setting, "hp"))
            g_iHP = value;
        else if (StrEqual(setting, "acq_distance"))
            g_iAcquisitionDistance = value;
        else if (StrEqual(setting, "spike_distance"))
            g_iSpikeDeploymentDistance = value;
        else if (StrEqual(setting, "spawn_rate"))
            g_iSpawnRate = value;
    }
}

CreateMainMenu()
{
    g_hMainMenu = CreateMenu(MenuHandler_Main);
    SetMenuTitle(g_hMainMenu, "RollingMines! Menu");
    AddMenuItem(g_hMainMenu, "spawnmine", "Spawn a mine");
    AddMenuItem(g_hMainMenu, "setspawn", "Place Spawnpoint");
    AddMenuItem(g_hMainMenu, "clearspawns", "Clear All Spawnpoints (for this map)");
    AddMenuItem(g_hMainMenu, "randomspawn", "Spawn via Random Spawnpoint");
    AddMenuItem(g_hMainMenu, "damage", "Damage");
    AddMenuItem(g_hMainMenu, "hp", "HP");
    AddMenuItem(g_hMainMenu, "spawnrate", "Spawn Rate");
    AddMenuItem(g_hMainMenu, "target", "Target Acquisition Mode");
    AddMenuItem(g_hMainMenu, "acqdist", "Acquisition Distance");
    AddMenuItem(g_hMainMenu, "spikedist", "Spike Deployment Distance");
}

public Action:Command_RollingMineMenu(client, args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "Menu is only available in-game");
        return Plugin_Handled;
    }
    
    if (g_hMainMenu == INVALID_HANDLE)
        CreateMainMenu();
        
    DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuHandler_Main(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        if (StrEqual(info, "target"))
            ShowTargetModeMenu(client);
        else if (StrEqual(info, "damage"))
            ShowDamageMenu(client);
        else if (StrEqual(info, "hp"))
            ShowHPMenu(client);
        else if (StrEqual(info, "acqdist"))
            ShowAcqDistMenu(client);
        else if (StrEqual(info, "spikedist"))
            ShowSpikeDistMenu(client);
        else if (StrEqual(info, "spawnrate"))
            ShowSpawnRateMenu(client);
        else if (StrEqual(info, "spawnmine"))
            SpawnRollingMine(client);
        else if (StrEqual(info, "setspawn"))
            PlaceSpawnPoint(client);
        else if (StrEqual(info, "clearspawns"))
            ClearAllSpawnPoints(client);
        else if (StrEqual(info, "randomspawn"))
            SpawnRandomRollingMine(client);
    }
}

ShowTargetModeMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_TargetMode);
    SetMenuTitle(menu, "Select Target Acquisition Mode");
    AddMenuItem(menu, "0", "Focused");
    AddMenuItem(menu, "1", "Always Nearest");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_TargetMode(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        _tm = TargetAcquisitionMode:StringToInt(info);
        SaveConfig("target_mode", _tm);
        PrintToChat(client, "Target Acquisition Mode set to %s", _tm == Focused ? "Focused" : "Always Nearest");
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowDamageMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_Damage);
    SetMenuTitle(menu, "Select Damage");
    AddMenuItem(menu, "1", "1");
    AddMenuItem(menu, "20", "20");
    AddMenuItem(menu, "50", "50");
    AddMenuItem(menu, "100", "100");
    AddMenuItem(menu, "150", "150");
    AddMenuItem(menu, "200", "200");
    AddMenuItem(menu, "2500", "2500");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Damage(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        g_iBoomDmg = StringToInt(info);
        SaveConfig("damage", g_iBoomDmg);
        PrintToChat(client, "Damage set to %d", g_iBoomDmg);
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowHPMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_HP);
    SetMenuTitle(menu, "Select HP");
    AddMenuItem(menu, "50", "50");
    AddMenuItem(menu, "100", "100");
    AddMenuItem(menu, "1000", "1000");
    AddMenuItem(menu, "10000", "10000");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_HP(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        g_iHP = StringToInt(info);
        SaveConfig("hp", g_iHP);
        PrintToChat(client, "HP set to %d", g_iHP);
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowAcqDistMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_AcqDist);
    SetMenuTitle(menu, "Select Acquisition Distance");
    AddMenuItem(menu, "100", "100");
    AddMenuItem(menu, "250", "250");
    AddMenuItem(menu, "300", "300");
    AddMenuItem(menu, "400", "400");
    AddMenuItem(menu, "500", "500");
    AddMenuItem(menu, "600", "600");
    AddMenuItem(menu, "700", "700");
    AddMenuItem(menu, "800", "800");
    AddMenuItem(menu, "900", "900");
    AddMenuItem(menu, "1000", "1000");
    AddMenuItem(menu, "1250", "1250");
    AddMenuItem(menu, "1500", "1500");
    AddMenuItem(menu, "2000", "2000");
    AddMenuItem(menu, "5000", "5000");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AcqDist(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        g_iAcquisitionDistance = StringToInt(info);
        SaveConfig("acq_distance", g_iAcquisitionDistance);
        PrintToChat(client, "Acquisition Distance set to %d", g_iAcquisitionDistance);
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowSpikeDistMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_SpikeDist);
    SetMenuTitle(menu, "Select Spike Deployment Distance");
    AddMenuItem(menu, "50", "50");
    AddMenuItem(menu, "250", "250");
    AddMenuItem(menu, "500", "500");
    AddMenuItem(menu, "750", "750");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SpikeDist(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        g_iSpikeDeploymentDistance = StringToInt(info);
        SaveConfig("spike_distance", g_iSpikeDeploymentDistance);
        PrintToChat(client, "Spike Deployment Distance set to %d", g_iSpikeDeploymentDistance);
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

ShowSpawnRateMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_SpawnRate);
    SetMenuTitle(menu, "Select Spawn Rate");
    AddMenuItem(menu, "-1", "-1 (Disabled)");
    AddMenuItem(menu, "0", "0 (Instant)");
    AddMenuItem(menu, "10", "10 seconds");
    AddMenuItem(menu, "20", "20 seconds");
    AddMenuItem(menu, "40", "40 seconds");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SpawnRate(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        g_iSpawnRate = StringToInt(info);
        SaveConfig("spawn_rate", g_iSpawnRate);
        PrintToChat(client, "Spawn Rate set to %d", g_iSpawnRate);
        DisplayMenu(g_hMainMenu, client, MENU_TIME_FOREVER);
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

public Action:Command_SetTargetMode(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_targetmode <0|1> (0=Focused, 1=AlwaysNearest)");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    new value = StringToInt(arg);
    
    if (value < 0 || value > 1)
    {
        ReplyToCommand(client, "Invalid value. Use 0 for Focused or 1 for AlwaysNearest");
        return Plugin_Handled;
    }
    
    _tm = TargetAcquisitionMode:value;
    SaveConfig("target_mode", _tm);
    ReplyToCommand(client, "Target Acquisition Mode set to %s", _tm == Focused ? "Focused" : "Always Nearest");
    return Plugin_Handled;
}

public Action:Command_SetDamage(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_damage <value>");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    g_iBoomDmg = StringToInt(arg);
    SaveConfig("damage", g_iBoomDmg);
    ReplyToCommand(client, "Damage set to %d", g_iBoomDmg);
    return Plugin_Handled;
}

public Action:Command_SetHP(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_hp <value>");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    g_iHP = StringToInt(arg);
    SaveConfig("hp", g_iHP);
    ReplyToCommand(client, "HP set to %d", g_iHP);
    return Plugin_Handled;
}

public Action:Command_SetAcqDist(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_acqdist <value>");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    g_iAcquisitionDistance = StringToInt(arg);
    SaveConfig("acq_distance", g_iAcquisitionDistance);
    ReplyToCommand(client, "Acquisition Distance set to %d", g_iAcquisitionDistance);
    return Plugin_Handled;
}

public Action:Command_SetSpikeDist(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_spikedist <value>");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    g_iSpikeDeploymentDistance = StringToInt(arg);
    SaveConfig("spike_distance", g_iSpikeDeploymentDistance);
    ReplyToCommand(client, "Spike Deployment Distance set to %d", g_iSpikeDeploymentDistance);
    return Plugin_Handled;
}

public Action:Command_SetSpawnRate(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_rm_set_spawnrate <value>");
        return Plugin_Handled;
    }
    
    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    g_iSpawnRate = StringToInt(arg);
    SaveConfig("spawn_rate", g_iSpawnRate);
    ReplyToCommand(client, "Spawn Rate set to %d", g_iSpawnRate);
    return Plugin_Handled;
}

SpawnRollingMine(client)
{
    SpawnForClient(client,0);
    PrintToChat(client, "Spawning rolling mine with current settings");
}

PlaceSpawnPoint(client)
{
    if (!SetTeleportEndPoint(client))
    {
        PrintToChat(client, "[SM] Could not find spawn point.");
        return Plugin_Handled;
    }
    g_pos[2] += Z_OFFSET_;

    if (g_hDatabase == INVALID_HANDLE)
        return;

    decl String:map[254];
    GetCurrentMap(map, sizeof(map));

    decl String:query[256];
    Format(query, sizeof(query), 
        "INSERT INTO %s (map, x, y, z) VALUES ('%s', %f, %f, %f)",
        TABLE_NAME_SPAWNPTS, map, g_pos[0], g_pos[1], g_pos[2]);
    SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
    
    PrintToChat(client, "Placed spawn point");
    Command_RollingMineMenu(client, 0);
}

ClearAllSpawnPoints(client)
{
    decl String:map[254];
    GetCurrentMap(map, sizeof(map));

    decl String:query[256];
    Format(query, sizeof(query), 
        "DELETE FROM %s WHERE map = '%s'",
        TABLE_NAME_SPAWNPTS, map, g_pos[0], g_pos[1], g_pos[2]);
    SQL_TQuery(g_hDatabase, SQLCallback_Void, query);
    PrintToChat(client, "Cleared all spawn points");
    Command_RollingMineMenu(client, 0);
}

SpawnRandomRollingMine(client)
{
    if (get_random_spawnpt())
    {
        new_roller_mine();
        PrintToChat(client, "Spawning rolling mine at random spawn point");
    }
    else
    {
        PrintToChat(client, "There are no spawn points for this map in the database.  Please set some up first!");
    }
}

