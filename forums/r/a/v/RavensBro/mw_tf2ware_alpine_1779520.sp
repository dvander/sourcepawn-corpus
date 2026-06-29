#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <colors>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <geoip>

#define MAX_MINIGAMES 40

#define PLUGIN_VERSION "1.4"

#define MUSIC2_START "imgay/tf2ware/tf2ware_intro.mp3"
#define MUSIC2_START_LEN 2.18
#define MUSIC2_WIN "imgay/tf2ware/tf2ware_win.mp3"
#define MUSIC2_FAIL "imgay/tf2ware/tf2ware_fail.mp3"
#define MUSIC2_END_LEN 2.2
#define MUSIC2_SPEEDUP "imgay/tf2ware/tf2ware_speedup.mp3"
#define MUSIC2_SPEEDUP_LEN 3.29
#define MUSIC2_BOSS "imgay/tf2ware/boss.mp3"
#define MUSIC2_BOSS_LEN 3.9
#define MUSIC2_GAMEOVER "imgay/tf2ware/warioman_gameover.mp3"
#define MUSIC2_GAMEOVER_LEN 8.17

#define MUSIC_START "imgay/tf2ware/warioman_intro.mp3"
#define MUSIC_START_LEN 2.17
#define MUSIC_WIN "imgay/tf2ware/warioman_win.mp3"
#define MUSIC_FAIL "imgay/tf2ware/warioman_fail.mp3"
#define MUSIC_END_LEN 2.19
#define MUSIC_SPEEDUP "imgay/tf2ware/warioman_speedup.mp3"
#define MUSIC_SPEEDUP_LEN 3.9
#define MUSIC_BOSS "imgay/tf2ware/warioman_boss.mp3"
#define MUSIC_BOSS_LEN 4.2
#define MUSIC_GAMEOVER "imgay/tf2ware/warioman_gameover.mp3"
#define MUSIC_GAMEOVER_LEN 8.17

#define SOUND_COMPLETE "imgay/tf2ware/complete_me.mp3"
#define SOUND_COMPLETE_YOU "imgay/tf2ware/complete_you.mp3"
#define SOUND_MINISCORE "items/pumpkin_drop.wav"
#define SOUND_HEAVY_KISS "vo/heavy_generic01.wav"
#define MUSIC_WAITING "imgay/tf2ware/waitingforplayers.mp3"
#define MUSIC_SPECIAL "imgay/tf2ware/specialround.mp3"
#define MUSIC_SPECIAL_LEN 13.5
#define SOUND_SELECT "imgay/tf2ware/select.mp3"

#define SND_CHANNEL_SPECIFIC 32

#define PARTICLE_WIN_BLUE "teleportedin_blue"
#define PARTICLE_WIN_RED "teleportedin_red"

#define TF2_PLAYER_TAUNTING        (1 << 7)    // 128        Taunting

new String:g_name[MAX_MINIGAMES][24];
new Function:g_initFuncs[MAX_MINIGAMES];

// Language strings
new String:var_lang[][] = {"", "it/"};

// Handles
new Handle:ww_enable;
new Handle:ww_speed;
new Handle:ww_music;
new Handle:ww_force;
new Handle:ww_log;
new Handle:ww_special;
new Handle:ww_gamemode;
new Handle:ww_force_special;
new Handle:ww_allowedCommands;
new Handle:hudScore;
// REPLACE WEAPON
new Handle:GameConf = INVALID_HANDLE;
new Handle:hGiveNamedItem = INVALID_HANDLE;
new Handle:g_hSdkRemoveWearable = INVALID_HANDLE;
new Handle:microgametimer = INVALID_HANDLE;

// Keyvalues configuration handle
new Handle:MinigameConf = INVALID_HANDLE;

// Bools
new bool:g_Complete[MAXPLAYERS+1];
new bool:g_Spawned[MAXPLAYERS+1];
new bool:g_ModifiedOverlay[MAXPLAYERS+1];
new bool:g_attack = false;
new bool:g_enabled = false;
new bool:g_first = false;
new bool:g_waiting = true;

// Ints
new g_Mission[MAXPLAYERS+1];
new g_NeedleDelay[MAXPLAYERS+1];
new g_Points[MAXPLAYERS+1];
new g_Id[MAXPLAYERS+1];
new g_Winner[MAXPLAYERS+1];
new g_Minipoints[MAXPLAYERS+1];
new g_Country[MAXPLAYERS+1];
new Float:currentSpeed;
new iMinigame;
new status;
new randommini;
new g_offsCollisionGroup;
new timeleft = 8;
new white;
new g_HaloSprite;
new g_ExplosionSprite;
new g_result = 0;
new String:g_mathquestion[24];
new g_bomb = 0;
new Roundstarts = 0;
new g_lastminigame = 0;
new g_lastboss = 0;
new g_minigamestotal = 0;
new bossBattle = 0;
new SpecialRound = 0;
new bool:g_Participating[MAXPLAYERS+1] = false;
new g_Gamemode = 0;

// Strings
new String:materialpath[512] = "tf2ware/";
// Name of current minigame being played
new String:minigame[24];

// VALID iMinigame FORWARD HANDLERS //////////////
new Handle:g_OnMapStart;
new Handle:g_justEntered;
new Handle:g_OnAlmostEnd;
new Handle:g_OnTimerMinigame;
new Handle:g_OnEndMinigame;
new Handle:g_OnGameFrame_Minigames;
new Handle:g_PlayerDeath;
/////////////////////////////////////////

#define GAMEMODE_NORMAL         0
#define GAMEMODE_WIPEOUT        1
#define GAMEMODE_WIPEOUT_HEIGHT 1200.0

#include tf2ware\microgames\hitenemy.inc
#include tf2ware\microgames\spycrab.inc
#include tf2ware\microgames\kamikaze.inc
#include tf2ware\microgames\math.inc
#include tf2ware\microgames\sawrun.inc
#include tf2ware\microgames\barrel.inc
#include tf2ware\microgames\needlejump.inc
#include tf2ware\microgames\hopscotch.inc
#include tf2ware\microgames\airblast.inc
#include tf2ware\microgames\movement.inc
#include tf2ware\microgames\flood.inc
#include tf2ware\microgames\simonsays.inc
#include tf2ware\microgames\bball.inc
#include tf2ware\microgames\hugging.inc
#include tf2ware\microgames\redfloor.inc
#include tf2ware\microgames\batboy.inc
#include tf2ware\microgames\airraid.inc
#include tf2ware\microgames\jumprope.inc
#include tf2ware\microgames\colortext.inc
#include tf2ware\microgames\frogger.inc
#include tf2ware\microgames\goomba.inc
#include tf2ware\microgames\ghostbusters.inc
#include tf2ware\microgames\mandrill.inc

#include tf2ware\mw_tf2ware_features.inc
#include tf2ware\special.inc
#include tf2ware\vocalize.inc

public Plugin:myinfo = {
    name = "TF2 Ware",
    author = "Mecha the Slag, edit by RavensBro",
    description = "Wario Ware in Team Fortress 2!",
    version = PLUGIN_VERSION,
    url = "https://www.assembla.com/code/tf2ware/subversion/nodes"
};

public OnPluginStart() {
    // Check for SDKHooks
    if(GetExtensionFileStatus("sdkhooks.ext") < 1)
        SetFailState("SDK Hooks is not loaded.");
    
    // Find collision group offsets
    g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
    if (g_offsCollisionGroup == -1) {
        PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
    }
    
     // ConVars
    ww_enable = CreateConVar("ww_enable", "0", "Enables/Disables TF2 Ware.", FCVAR_PLUGIN);
    ww_force = CreateConVar("ww_force", "0", "Force a certain minigame (0 to not force).", FCVAR_PLUGIN);
    ww_speed = CreateConVar("ww_speed", "1.0", "Speed level.", FCVAR_PLUGIN);
    ww_music = CreateConVar("ww_music_fix", "0", "Apply music fix? Should only be on for localhosts during testing", FCVAR_PLUGIN);
    ww_log = CreateConVar("ww_log", "0", "Log server events?", FCVAR_PLUGIN);
    ww_special = CreateConVar("ww_special", "0", "Next round is Special Round?", FCVAR_PLUGIN);
    ww_gamemode = CreateConVar("ww_gamemode", "-1", "Gamemode", FCVAR_PLUGIN);
    ww_force_special = CreateConVar("ww_force_special", "0", "Forces a specific Special Round on Special Round", FCVAR_PLUGIN);
}

public OnMapStart() 
                {
            {
        {		
        g_enabled = true;
        
        // Add server tag
        AddServerTag("TF2Ware");
        
        // Load game config
        GameConf = LoadGameConfigFile("mechatheslag_global");
        
        // Load minigames
        decl String:imFile[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, imFile, sizeof(imFile), "configs/minigames.cfg");
        
        MinigameConf = CreateKeyValues("Minigames");
        if (FileToKeyValues(MinigameConf, imFile)) {
            PrintToServer("Loaded minigames from minigames.cfg");
            
            KvGotoFirstSubKey(MinigameConf);
            new i=0;
            do  {
                    KvGetSectionName(MinigameConf, g_name[KvGetNum(MinigameConf, "id")-1], 32);
                    i++;
                }
				while (KvGotoNextKey(MinigameConf)); 
            KvRewind(MinigameConf);
        }
        else {
            PrintToServer("Failed to load minigames.cfg!");
        }
        
        // SDK
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "GiveNamedItem");
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
        hGiveNamedItem = EndPrepSDKCall();
        
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkRemoveWearable = EndPrepSDKCall();
        
        // Add logging
        if (GetConVarBool(ww_log)) {
        LogMessage("//////////////////////////////////////////////////////");
        LogMessage("//                     TF2WARE LOG                  //");
        LogMessage("//////////////////////////////////////////////////////");
        }
        
        // Hooks
        HookConVarChange(ww_enable,StartMinigame_cvar);
        HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
        HookEvent("player_death", Player_Death, EventHookMode_Post);
        HookEvent("player_team", Player_Team, EventHookMode_Post);
        HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
        HookEvent("teamplay_game_over", Event_Roundend, EventHookMode_PostNoCopy);
        HookEvent("teamplay_round_stalemate", Event_Roundend, EventHookMode_PostNoCopy);
        HookEvent("teamplay_round_win", Event_Roundend, EventHookMode_PostNoCopy);
        //RegAdminCmd("ww_list", Command_list, ADMFLAG_GENERIC, "Lists all the registered, enabled plugins and their ids");
        //RegAdminCmd("ww_give", Command_points, ADMFLAG_GENERIC, "Gives you 20 points - You're a winner! (testing feature)");
        //RegAdminCmd("ww_event", Command_event, ADMFLAG_GENERIC, "Starts a debugging event");
        
        // Vars
        currentSpeed = GetConVarFloat(ww_speed);
        iMinigame = 1;
        status = 0;
        randommini = 0;
        Roundstarts = 0;
        SetStateAll(false);
        ResetWinners();
        SetMissionAll(0);
        
        // FORWARDS FOR MINIGAMES
        g_OnMapStart = CreateForward(ET_Ignore);
        g_justEntered = CreateForward(ET_Ignore, Param_Cell);
        g_OnAlmostEnd = CreateForward(ET_Ignore);
        g_OnTimerMinigame = CreateForward(ET_Ignore, Param_Cell);
        g_OnEndMinigame = CreateForward(ET_Ignore);
        g_OnGameFrame_Minigames = CreateForward(ET_Ignore);
        g_PlayerDeath = CreateForward(ET_Ignore, Param_Cell);
        
        // MINIGAME REGISTRATION
        RegMinigame("HitEnemy", HitEnemy_OnMinigame);
        RegMinigame("Spycrab", Spycrab_OnMinigame);
        RegMinigame("Kamikaze", Kamikaze_OnMinigame);
        RegMinigame("Math", Math_OnMinigame);
        RegMinigame("SawRun", SawRun_OnMinigame);
        RegMinigame("Barrel", Barrel_OnMinigame);
        RegMinigame("Needlejump", Needlejump_OnMinigame);
        RegMinigame("Hopscotch", Hopscotch_OnMinigame);
        RegMinigame("Airblast", Airblast_OnMinigame);
        RegMinigame("Movement", Movement_OnMinigame);
        RegMinigame("Flood", Flood_OnMinigame);
        RegMinigame("SimonSays", SimonSays_OnMinigame);
        RegMinigame("BBall", BBall_OnMinigame);
        RegMinigame("Hugging", Hugging_OnMinigame, Hugging_Init);
        RegMinigame("RedFloor", RedFloor_OnMinigame);
        RegMinigame("Batboy", Batboy_OnMinigame);
        RegMinigame("Airraid", Airraid_OnMinigame);
        RegMinigame("JumpRope", JumpRope_OnMinigame);
        RegMinigame("ColorText", ColorText_OnMinigame);
        RegMinigame("Frogger", Frogger_OnMinigame, Frogger_Init);
        RegMinigame("Goomba", Goomba_OnMinigame);
        RegMinigame("Ghostbusters", Ghostbusters_OnMinigame, Ghostbusters_Init);
        RegMinigame("Mandrill", Mandrill_OnMinigame);		

        // CHEATS
        HookConVarChange(FindConVar("sv_cheats"), OnConVarChanged_SvCheats);
        ww_allowedCommands = CreateArray(64);
        PushArrayString(ww_allowedCommands, "host_timescale");
        PushArrayString(ww_allowedCommands, "r_screenoverlay");
        PushArrayString(ww_allowedCommands, "thirdperson");
        PushArrayString(ww_allowedCommands, "firstperson");
        PushArrayString(ww_allowedCommands, "sv_cheats");
        UpdateClientCheatValue();
        HookAllCheatCommands();
        
        DestroyAllBarrels();
        
        // HUD
        hudScore = CreateHudSynchronizer();
        ResetScores();
        
        // Remove Notification Flags
        RemoveNotifyFlag("sv_tags");
        RemoveNotifyFlag("mp_respawnwavetime");
        RemoveNotifyFlag("mp_friendlyfire");
        RemoveNotifyFlag("tf_tournament_hide_domination_icons");
        SetConVarInt(FindConVar("tf_tournament_hide_domination_icons"), 0, true);
        SetConVarInt(FindConVar("mp_friendlyfire"), 1);
        
        if (GetConVarBool(ww_log)) LogMessage("Calling OnMapStart Forward");
            
        Call_StartForward(g_OnMapStart);
        Call_Finish();
        
        precacheSound(MUSIC_START);
        precacheSound(MUSIC_WIN);
        precacheSound(MUSIC_FAIL);
        precacheSound(MUSIC_SPEEDUP);
        precacheSound(MUSIC_BOSS);
        precacheSound(MUSIC_GAMEOVER);
        
        precacheSound(MUSIC2_START);
        precacheSound(MUSIC2_WIN);
        precacheSound(MUSIC2_FAIL);
        precacheSound(MUSIC2_SPEEDUP);
        precacheSound(MUSIC2_BOSS);
        precacheSound(MUSIC2_GAMEOVER);
        
        precacheSound(MUSIC_WAITING);
        precacheSound(MUSIC_SPECIAL);
        
        precacheSound(SOUND_COMPLETE);
        precacheSound(SOUND_COMPLETE_YOU);
        precacheSound(SOUND_MINISCORE);
        precacheSound(SOUND_SELECT);
		
        PrecacheSound("pl_hoodoo/alarm_clock_ticking_3.wav", true);

        PrecacheModel("models/props_farm/wooden_barrel.mdl", true);
        PrecacheModel("models/props_farm/gibs/wooden_barrel_break02.mdl", true);
        PrecacheModel("models/props_farm/gibs/wooden_barrel_chunk02.mdl", true);
        PrecacheModel("models/props_farm/gibs/wooden_barrel_chunk04.mdl", true);
        PrecacheModel("models/props_farm/gibs/wooden_barrel_chunk03.mdl", true);
        PrecacheModel("models/props_farm/gibs/wooden_barrel_chunk01.mdl", true);
        
        PrecacheModel( "models/weapons/w_models/w_bat.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_minigun.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_bonesaw.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_wrench.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_bottle.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_club.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_fireaxe.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_shovel.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_revolver.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_shotgun.mdl", true);
        PrecacheModel( "models/weapons/c_models/c_flamethrower/c_flamethrower.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_grenadelauncher.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_syringegun.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_rocketlauncher.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_stickybomb_launcher.mdl", true);
        PrecacheModel( "models/weapons/w_models/w_medigun.mdl", true);
		
        decl String:input[512];
        
        KvGotoFirstSubKey(MinigameConf);
        decl id;
        decl enable;
        new i=1;
        if (GetConVarBool(ww_log)) LogMessage("--Adding the following to downloads table from information in minigames.cfg:", input);
        do {
            id = KvGetNum(MinigameConf, "id");
            enable = KvGetNum(MinigameConf, "enable", 1);
            if (enable >= 1) {
                Format(input, sizeof(input), "imgay/tf2ware/minigame_%d.mp3", id);
                if (GetConVarBool(ww_log)) LogMessage("%s", input);
                precacheSound(input);
            }
            i++;
        }     
		while (KvGotoNextKey(MinigameConf)); 
        KvRewind(MinigameConf);
        
        white = PrecacheModel("materials/sprites/white.vmt");
        g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
        g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");

        PrecacheSound( "ambient/explosions/explode_8.wav", true);
        SetConVarFloat(ww_speed, 1.0);
        ResetScores();
        bossBattle = 0;
        Roundstarts = 0;
        
        SpecialPrecache();
        
        if (GetConVarBool(ww_log)) LogMessage("Map started");
        }
    }
}

public Action:OnGetGameDescription(String:gameDesc[64]) {
    if (g_enabled) {
        Format(gameDesc, sizeof(gameDesc), "TF2Ware %s", PLUGIN_VERSION);
    }
    else
    {
        Format(gameDesc, sizeof(gameDesc), "Team Fortress");
    }
    return Plugin_Changed;
}

public Action:Timer_DisplayVersion(Handle:timer, any:client)
{
    if (IsValidClient(client))
    {
        SetHudTextParams(0.63,0.73,25.0,255,255,255,255,1,3.0,0.0,3.0);
        ShowHudText(client,1,"v%s", PLUGIN_VERSION);
    }
    return Plugin_Handled;
}

public Action:Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast) {
    if (g_enabled && GetConVarBool(ww_enable)) {
        if ( Roundstarts == 0 ) {
            g_waiting = true;
            SetGameMode();
            RemoveAllParticipants();
        }

        if ( Roundstarts == 1 ) {
            g_waiting = false;
            SetGameMode();
            ResetScores();
            StartMinigame();
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && g_Spawned[i]) {
                    if (!IsFakeClient(i)) {
                        StopSound(i, SND_CHANNEL_SPECIFIC, MUSIC_WAITING);
                        SetOverlay(i, "");
                    }
                    if (g_Gamemode == GAMEMODE_WIPEOUT) SetWipeoutPosition(i, true);
                }
            }
            if (GetConVarBool(ww_log)) LogMessage("Waiting-for-players period has ended");
        }
    }
    Roundstarts++;
}

public Action:Event_Roundend(Handle:event,const String:name[],bool:dontBroadcast) {
    if (g_enabled && GetConVarBool(ww_enable)) {
        g_enabled = false;
        if (GetConVarBool(ww_log)) LogMessage("== ROUND ENDED SUCCESSFULLY == ");
    }
}

public OnClientPostAdminCheck(client) {
    if (!g_enabled) return;
    UpdateClientCheatValue();
    g_Points[client] = GetAverageScore();
    if (g_Gamemode == GAMEMODE_WIPEOUT) g_Points[client] = -1;
    
    // Country
    decl String:ip[32];
    GetClientIP(client, ip, sizeof(ip));
    decl String:country[3];
    GeoipCode2(ip, country);
    g_Country[client] = 0;
    
    //if (StrEqual(country, "IT")) g_Country[client] = 1;
    if (GetConVarBool(ww_log)) LogMessage("Client post admin check. Country: %d", g_Country[client]);
}

public OnClientPutInServer(client) {
    if (!g_enabled) return;
    if (GetConVarBool(ww_log)) LogMessage("Client put in server and hooked");
    SDKHook(client, SDKHook_PreThink, OnPreThink);
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageClient);
    SDKHook(client, SDKHook_Touch, Special_NoTouch);
    SDKHook(client, SDKHook_OnTakeDamage, Special_DamagePush);
}

public OnClientDisconnect(client) {
    if (GetConVarBool(ww_log)) LogMessage("Client disconnected");

    g_Spawned[client] = false;
}

public Action:OnTakeDamageClient(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
    
    if ((g_Winner[victim] >= 1) && (status != 2)) {
        damage = 0.0;
        return Plugin_Changed;
    }
    
    if (IsValidClient(attacker) && (g_Winner[attacker] == 1) && (g_Winner[victim] == 0) && IsValidClient(victim) && IsPlayerAlive(victim)) {
        damage = 450.0;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public OnPreThink(client) {
    new iButtons = GetClientButtons(client);
    if ((status != 2) && GetConVarBool(ww_enable) && g_enabled && (g_Winner[client] == 0) && !(SpecialRound == 6 && status != 5)) {
        if ((iButtons & IN_ATTACK2) || (iButtons & IN_ATTACK)) {
        iButtons &= ~IN_ATTACK;
        iButtons &= ~IN_ATTACK2;
        SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
        }
    }
    
    if ((status == 2) && (g_attack == false || !IsClientParticipating(client)) && GetConVarBool(ww_enable) && g_enabled) {
        if ((iButtons & IN_ATTACK2) || (iButtons & IN_ATTACK)) {
        iButtons &= ~IN_ATTACK;
        iButtons &= ~IN_ATTACK2;
        SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
        }
    }
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(ww_log)) LogMessage("Client post inventory");
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_Spawned[client] == false && g_waiting && GetConVarBool(ww_enable) && g_enabled && !IsFakeClient(client)) {
        EmitSoundToClient(client, MUSIC_WAITING, SOUND_FROM_PLAYER, SND_CHANNEL_SPECIFIC);
        SetOverlay(client, "tf2ware_welcome");
        CreateTimer(0.25, Timer_DisplayVersion, client);
    }

    g_Spawned[client] = true;
    if (GetConVarBool(ww_enable) && g_enabled) {
        SetEntityRenderMode(client, RENDER_NORMAL);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
    
        if ((status != 2) && (g_Winner[client] == 0)) {
            DisableClientWeapons(client);
        }
        if (status == 2 && IsClientParticipating(client)) {
            Call_StartForward(g_justEntered);
            Call_PushCell(client);
            Call_Finish();
        }
        if ((status == 2 && g_attack) || (g_Winner[client] > 0) || (SpecialRound == 6)) SetWeaponState(client, true);
        else SetWeaponState(client, false);
        
        HandlePlayerItems(client);
        
        if (SpecialRound == 4) {
            SetEntityRenderMode(client, RENDER_TRANSCOLOR);
            SetEntityRenderColor(client, 255, 255, 255, 0);
        }
        
        if (g_Gamemode == GAMEMODE_WIPEOUT && g_waiting == false) {
            if (status == 2 && IsClientParticipating(client)) {
                // do nothing
            }
            else {
                SetWipeoutPosition(client, true);
            }
            HandleWipeoutLives(client);
        }
    }
}

precacheSound(String:var[]) {
    new String:buffer[128];
    PrecacheSound(var, true);
    Format(buffer, sizeof(buffer), "sound/%s", var);
    AddFileToDownloadsTable(buffer);
}

public StartMinigame_cvar(Handle:cvar, const String:oldVal[], const String:newVal[]){
    if (GetConVarBool(ww_enable) && g_enabled) {
    StartMinigame();
    SetConVarInt(FindConVar("mp_respawnwavetime"), 999);
    SetConVarInt(FindConVar("mp_forcecamera"), 0);
    }
    else {
        ServerCommand("host_timescale %f", 1.0);
        ServerCommand("phys_timescale %f", 1.0);
        ResetConVar(FindConVar("mp_respawnwavetime")); 
        ResetConVar(FindConVar("mp_forcecamera")); 
        status = 0;
    }
}

public OnGameFrame() {
    if (GetConVarBool(ww_enable) && g_enabled && (status == 2) && (g_OnGameFrame_Minigames != INVALID_HANDLE)) {
        Call_StartForward(g_OnGameFrame_Minigames);
        Call_Finish();
        
        if (g_Gamemode == GAMEMODE_WIPEOUT && status == 1) {
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && IsPlayerAlive(i) && IsClientParticipating(i)) {
                    new Float:pos[3];
                    GetClientAbsOrigin(i, pos);
                    pos[2] -= 25.0;
                    if (pos[2] < GAMEMODE_WIPEOUT_HEIGHT) pos[2] = GAMEMODE_WIPEOUT_HEIGHT;
                    TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
                }
            }
        }
    }
}

public Action:StartMinigame_timer(Handle:hTimer) {
    if (status == 0) {
        StartMinigame();
    }
    return Plugin_Stop;
}

public Action:StartMinigame_timer2(Handle:hTimer) {
    if (status == 10) {
        status = 0;
        StartMinigame();
    }
    return Plugin_Stop;
}

RollMinigame() {
    if (GetConVarBool(ww_log) && bossBattle != 1) LogMessage("Rolling normal microgame...");
    if (GetConVarBool(ww_log) && bossBattle == 1) LogMessage("Rolling boss microgame...");
    new Handle:roll = CreateArray();
    new bool:accept = false;
    new out = 1;
    new iplayers = GetActivePlayers();
    for (new i = 1; i <= sizeof(g_name); i++) {
        if (StrEqual(g_name[i-1], "")) continue;
        accept = true;
        new gameisboss = GetMinigameConfNum(g_name[i-1], "boss", 0);
        if (iplayers < GetMinigameConfNum(g_name[i-1], "minplayers", 1)) accept = false;
        if ((bossBattle == 1) && (!gameisboss)) accept = false;
        if ((bossBattle != 1) && (gameisboss)) accept = false;
        if (i == g_lastminigame) accept = false;
        if (i == g_lastboss) accept = false;
        if (!GetMinigameConfNum(g_name[i-1], "enable", 1)) accept = false;
        for (new j=0; j<GetMinigameConfNum(g_name[i-1], "chance", 1); j++) {
            if (accept) PushArrayCell(roll, i);
        }
        if (GetConVarBool(ww_log) && (accept)) LogMessage("-- Microgame #%d allowed", i);
        if (GetConVarBool(ww_log) && (accept == false)) LogMessage("-- Microgame #%d NOT allowed", i);
    }
        
    if (GetArraySize(roll) > 0) out = GetArrayCell(roll, GetRandomInt(0, GetArraySize(roll)-1));
    CloseHandle(roll);
    
    new force = GetConVarInt(ww_force);
    if (force > 0) {
        if (force-1 < sizeof(g_name) && !StrEqual(g_name[force-1], "")) out = GetConVarInt(ww_force);
        else PrintToServer("Warning: Couldn't find a game with id %d, continuing with random roll.", GetConVarInt(ww_force));
    }
    
    if (GetConVarBool(ww_log)) LogMessage("Rolled microgame was: %s (id:%d)", g_name[out-1], out);
    
    if (GetConVarBool(ww_log)) LogMessage("Roll end");
    return out;
}

public Player_Team(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new oldteam = GetEventInt(event, "oldteam");
    new newteam = GetEventInt(event, "team");

    if (GetConVarBool(ww_log)) LogMessage("%N changed team", client);
    if (GetConVarBool(ww_enable) && g_enabled) {
        CreateTimer(0.1, StartMinigame_timer);
        if (oldteam < 2 && newteam >= 2) GiveSpecialRoundInfo();
    }
}

HandOutPoints() {
    if (GetConVarBool(ww_log)) LogMessage("Handing out points");
    for (new i = 1; i <= MaxClients; i++) {
        new points = 1;
        if (bossBattle == 1) points = 5;
        if ((IsValidClient(i)) && IsClientParticipating(i)) {
            if (g_Complete[i]) {
                if (g_Gamemode == GAMEMODE_NORMAL) g_Points[i] += points;
            }
            else {
                if (g_Gamemode == GAMEMODE_WIPEOUT && g_Points[i] > 0) {
                    g_Points[i] -= points;
                    if (g_Points[i] < 0) g_Points[i] = 0;
                    HandleWipeoutLives(i, true);
                }
            }
        }
        g_Complete[i] = false;
    }
}

StartMinigame() {
    if (GetConVarBool(ww_enable) && g_enabled && (status == 0) && g_waiting == false) {
        if (GetConVarBool(ww_log)) LogMessage("Starting microgame %s! Status = 0", minigame);
        SetConVarInt(FindConVar("mp_respawnwavetime"), 999);
        SetConVarInt(FindConVar("mp_friendlyfire"), 1);
        
        new Float:MUSIC_INFO_LEN = MUSIC_START_LEN;
        decl String:MUSIC_INFO[PLATFORM_MAX_PATH];
        Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC_START);
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            MUSIC_INFO_LEN = MUSIC2_START_LEN;
            Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC2_START);
        }
        
        RespawnAll();
        RemoveAllParticipants();
        UpdateHud(GetSpeedMultiplier(MUSIC_INFO_LEN));
        if (SpecialRound == 4) NoCollision(true);

        currentSpeed = GetConVarFloat(ww_speed);
        ServerCommand("host_timescale %f", GetHostMultiplier(1.0));
        ServerCommand("phys_timescale %f", GetHostMultiplier(1.0));
        
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            // Get two people to fight it off
            new personA = GetRandomWipeoutPlayer();
            if (IsValidClient(personA)) g_Participating[personA] = true;
            new personB = GetRandomWipeoutPlayer();
            if (IsValidClient(personB)) g_Participating[personB] = true;
            
            new personC = -1;
            if (GetLeftWipeoutPlayers() > 4) personC = GetRandomWipeoutPlayer();
            if (IsValidClient(personC)) g_Participating[personC] = true;
            
            if (IsValidClient(personA) == false || IsValidClient(personB) == false) {
                status = 4;
                bossBattle = 2;
                CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), Victory_timer);
                return;
            }
            decl String:strMessage[512];
            Format(strMessage, sizeof(strMessage), "%N\n%N", personA, personB);
            
            if (IsValidClient(personC)) Format(strMessage, sizeof(strMessage), "%s\n%N", strMessage, personC);
            PrintCenterTextAll(strMessage);
        }
        else {
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && GetClientTeam(i) >= 2 && g_Spawned[i] == true) g_Participating[i] = true;
            }
        }
        
        if (GetConVarBool(ww_music)) EmitSoundToClient(1, MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        else EmitSoundToAll(MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && (!(IsFakeClient(i)))) {
                SetOverlay(i,"");
                g_Minipoints[i] = 0;
            }
        }
        
        status = 1;
        iMinigame = RollMinigame();
        minigame = g_name[iMinigame-1];
        if (bossBattle == 1) g_lastboss = iMinigame;
        else g_lastminigame = iMinigame;
        CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), Game_Start);
        if (SpecialRound == 6) g_attack = true;
        else g_attack = false;
    }
}

public Action:Game_Start(Handle:hTimer) {
    if (status == 1) {
        if (GetConVarBool(ww_log)) LogMessage("Microgame %s started! Status = 1", minigame);
        
        // Spawn everyone so they can participate
        RespawnAll();
        if (SpecialRound == 4) NoCollision(true);
        if (SpecialRound == 7) {
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && !IsFakeClient(i)) ClientCommand(i, "wait; thirdperson");
            }
        }
        
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            for (new i2 = 1; i2 <= MaxClients; i2++) {
                if (IsValidClient(i2) && IsPlayerAlive(i2) && IsClientParticipating(i2)) {
                    SetEntityMoveType(i2, MoveType:MOVETYPE_WALK);
                    SetWipeoutPosition(i2, false);
                }
            }
        }
        
        // Play the microgame's music
        new String:sound[512];
        Format(sound, sizeof(sound), "imgay/tf2ware/minigame_%d.mp3", iMinigame);
        if (StrEqual(minigame, "Ghostbusters") && GetRandomInt(1,3) == 1) Format(sound, sizeof(sound), "imgay/tf2ware/minigame_%d_alt.mp3", iMinigame);
        new channel = SNDCHAN_AUTO;
        if (GetMinigameConfNum(minigame, "dynamic", 0)) channel = SND_CHANNEL_SPECIFIC;
        if (GetConVarBool(ww_music)) EmitSoundToClient(1, sound, SOUND_FROM_PLAYER, channel, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        else EmitSoundToAll(sound, SOUND_FROM_PLAYER, channel, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        
        // Set everyone's state to fail
        SetStateAll(false);
        
        // The 'x did y first' is untriggered
        g_first = false;
        
        // current proccess
        status = 2;
        
        // Reset everyone's mission
        SetMissionAll(0);
        
        // noone can attack
        if (SpecialRound == 6) g_attack = true;
        else g_attack = false;
        
        // initiate mission
        InitMinigame(iMinigame);
        
        // show the mission text
        PrintMissionText();
        
        // timeleft counter. Let it stay longer on boss battles.
        timeleft = 8;
        if (bossBattle == 1) CreateTimer(GetSpeedMultiplier(3.0), CountDown_Timer);
        else CreateTimer(GetSpeedMultiplier(1.0), CountDown_Timer);
        
        // get the lasting time from the cfg
        microgametimer = CreateTimer(GetSpeedMultiplier(GetMinigameConfFloat(minigame, "duration")), EndGame);
        
        // debug
        if (GetConVarBool(ww_log)) LogMessage("Microgame started post");
    }
    return Plugin_Stop;
}

PrintMissionText() {
    if (GetConVarBool(ww_log)) LogMessage("Printing mission text");
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            new String:input[512];
            Format(input, sizeof(input), "tf2ware_minigame_%d_%d", iMinigame, g_Mission[i]+1);
            SetOverlay(i,input);
            g_ModifiedOverlay[i] = false;
        }
    }
}

public Action:CountDown_Timer(Handle:hTimer) {
    if ((status == 2) && (timeleft > 0)) {
        timeleft = timeleft - 1;
        CreateTimer(GetSpeedMultiplier(0.4), CountDown_Timer);
        if (bossBattle != 1) {
            Call_StartForward(g_OnTimerMinigame);
            Call_PushCell(timeleft);
            Call_Finish();
        }
        if (timeleft == 2) {
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && (!(IsFakeClient(i))) && g_ModifiedOverlay[i] == false) {
                    SetOverlay(i, "");
                }
            }
        }
    }
}

public Action:EndGame(Handle:hTimer) {
    microgametimer = INVALID_HANDLE;
    if (status == 2) {
        if (GetConVarBool(ww_log)) LogMessage("Microgame %s, (id:%d) ended!", minigame, iMinigame);
        Call_StartForward(g_OnAlmostEnd);
        Call_Finish();
        
        status = 0;
        
        new Float:MUSIC_INFO_LEN = MUSIC_END_LEN;
        decl String:MUSIC_INFO_WIN[PLATFORM_MAX_PATH];
        decl String:MUSIC_INFO_FAIL[PLATFORM_MAX_PATH];
        Format(MUSIC_INFO_WIN, sizeof(MUSIC_INFO_WIN), MUSIC_WIN);
        Format(MUSIC_INFO_FAIL, sizeof(MUSIC_INFO_FAIL), MUSIC_FAIL);
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            MUSIC_INFO_LEN = MUSIC2_END_LEN;
            Format(MUSIC_INFO_WIN, sizeof(MUSIC_INFO_WIN), MUSIC2_WIN);
            Format(MUSIC_INFO_FAIL, sizeof(MUSIC_INFO_FAIL), MUSIC2_FAIL);
        }
        
        if (SpecialRound == 6) g_attack = true;
        else g_attack = false;
        
        Call_StartForward(g_OnEndMinigame);
        Call_Finish();
        
        CleanupAllVocalizations();
        
        currentSpeed = GetConVarFloat(ww_speed);
        ServerCommand("host_timescale %f", GetHostMultiplier(1.0));
        ServerCommand("phys_timescale %f", GetHostMultiplier(1.0));
        
        new String:sound[512];
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i)) {
                if (IsClientParticipating(i)) {
                    // heal everyone
                    //TF2_RegeneratePlayer(i);
                    
                    // Kill their weapons
                    DisableClientWeapons(i);
                    HealClient(i);
                    
                    // if client won
                    if (g_Complete[i]) {
                        Format(sound, sizeof(sound), MUSIC_INFO_WIN);
                    }
                    
                    // if client lost
                    if (g_Complete[i] == false) {
                        Format(sound, sizeof(sound), MUSIC_INFO_FAIL);
                    }
                }
                else {
                    Format(sound, sizeof(sound), MUSIC_INFO_WIN);
                }
                new String:oldsound[512];
                Format(oldsound, sizeof(oldsound), "imgay/tf2ware/minigame_%d.mp3", iMinigame);
                if (GetMinigameConfNum(minigame, "dynamic", 0)) StopSound(i, SND_CHANNEL_SPECIFIC, oldsound);
                EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
            }
        }
        
        // Clear all functions from forwards
        RemoveAllFromForward(g_justEntered, INVALID_HANDLE);
        RemoveAllFromForward(g_OnAlmostEnd, INVALID_HANDLE);
        RemoveAllFromForward(g_OnTimerMinigame, INVALID_HANDLE);
        RemoveAllFromForward(g_OnEndMinigame, INVALID_HANDLE);
        RemoveAllFromForward(g_OnGameFrame_Minigames, INVALID_HANDLE);
        RemoveAllFromForward(g_PlayerDeath, INVALID_HANDLE);
        
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && !IsFakeClient(i) && IsClientParticipating(i)) {
                if (g_Complete[i]) {
                    SetOverlay(i,"tf2ware_minigame_win");
                }
                if (g_Complete[i] == false) {
                    SetOverlay(i,"tf2ware_minigame_fail");

                }
            }
        }
        UpdateHud(GetSpeedMultiplier(MUSIC_INFO_LEN));
        
        new bool:bHandlePoints = true;
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            new bool:bSomeoneWon = false;
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && IsClientParticipating(i) && g_Complete[i] == true) bSomeoneWon = true;
            }
            if (bSomeoneWon == false && bossBattle == 1 && GetLeftWipeoutPlayers() == 2) {
                bHandlePoints = false;
                CPrintToChatAll("{red}DRAW{default}... playing new boss!");
            }
        }
        if (bHandlePoints) HandOutPoints();
        
        // RESPAWN START
        if (GetMinigameConfNum(minigame, "endrespawn", 0) > 0) RespawnAll(true, false);
        else RespawnAll();
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            for (new i2 = 1; i2 <= MaxClients; i2++) {
                if (IsValidClient(i2) && IsClientParticipating(i2)) {
                    SetWipeoutPosition(i2, true);
                }
            }
        }
        
        if (SpecialRound == 4) NoCollision(true);
        else NoCollision(false);
        
        if (SpecialRound == 7) {
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && !IsFakeClient(i)) ClientCommand(i, "wait; thirdperson");
            }
        }
        
        // RESPAWN END
        
        new bool:speedup = false;
        g_minigamestotal += 1;
        
        if (bossBattle == 1) bossBattle = 2;
        
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            if ((GetAverageScoreFloat() <= 2.80) && (bossBattle == 0) && currentSpeed <= 1.0) speedup = true;
            if ((GetAverageScoreFloat() <= 2.50) && (bossBattle == 0) && currentSpeed <= 2.0) speedup = true;
            if ((GetAverageScoreFloat() <= 2.20) && (bossBattle == 0) && currentSpeed <= 3.0) speedup = true;
            if ((GetAverageScoreFloat() <= 1.80) && (bossBattle == 0) && currentSpeed <= 4.0) speedup = true;
            if ((GetAverageScoreFloat() <= 1.40) && (bossBattle == 0) && currentSpeed <= 5.0) speedup = true;
            if ((GetAverageScoreFloat() <= 1.0) && (bossBattle == 0) && currentSpeed <= 6.0) speedup = true;
            if ((GetLeftWipeoutPlayers() == 2) && (bossBattle != 1)) {
                speedup = true;
                bossBattle = 1;
            }   
        }
        else {
            if ((g_minigamestotal == 4) && (bossBattle == 0)) speedup = true;
            if ((g_minigamestotal == 8) && (bossBattle == 0)) speedup = true;
            if ((g_minigamestotal == 12) && (bossBattle == 0)) speedup = true;
            if ((g_minigamestotal == 16) && (bossBattle == 0)) speedup = true;
            if ((g_minigamestotal == 19) && (bossBattle == 0)) {
                speedup = true;
                bossBattle = 1;
            }
            if ((g_minigamestotal >= 19) && bossBattle == 2 && SpecialRound == 3 && Special_TwoBosses == false) {
                speedup = true;
                bossBattle = 1;
                Special_TwoBosses = true;
            }
        }
        if (g_Gamemode == GAMEMODE_WIPEOUT && GetLeftWipeoutPlayers() <= 1) {
            status = 4;
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), Victory_timer);
        }
        if (speedup == false) {
            status = 10;
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), StartMinigame_timer2);
        }
        if (speedup == true) {
            status = 3;
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), Speedup_timer);
        }
        if (bossBattle == 2 && speedup == false) {
            status = 4;
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), Victory_timer);
        }
    }
    return Plugin_Stop;
}

public Action:Speedup_timer(Handle:hTimer) {
    if (status == 3) {
        RemoveAllParticipants();
        if (bossBattle == 1) {
            if (GetConVarBool(ww_log)) LogMessage("GETTING READY TO START SOME BOSS");
            new Float:MUSIC_INFO_LEN = MUSIC_BOSS_LEN;
            decl String:MUSIC_INFO[PLATFORM_MAX_PATH];
            Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC_BOSS);
            if (g_Gamemode == GAMEMODE_WIPEOUT) {
                MUSIC_INFO_LEN = MUSIC2_BOSS_LEN;
                Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC2_BOSS);
            }
            
            if (GetConVarBool(ww_log)) LogMessage("Boss part 2");
        
            // Set the Speed. If special round, we want it to be a tad faster ;)
            if (SpecialRound == 1) SetConVarFloat(ww_speed, 3.0);
            else SetConVarFloat(ww_speed, 1.0);
            
            if (GetConVarBool(ww_log)) LogMessage("Boss part 3");
            
            currentSpeed = GetConVarFloat(ww_speed);
            ServerCommand("host_timescale %f", GetHostMultiplier(1.0));
            ServerCommand("phys_timescale %f", GetHostMultiplier(1.0));
            
            if (GetConVarBool(ww_log)) LogMessage("Boss part 4");
            
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), StartMinigame_timer2);
            
            if (GetConVarBool(ww_log)) LogMessage("Boss part 5");
            
            if (GetConVarBool(ww_music)) EmitSoundToClient(1, MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
            else EmitSoundToAll(MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && (!(IsFakeClient(i)))) {
                    SetOverlay(i,"tf2ware_minigame_boss");
                }
            }     

            if (GetConVarBool(ww_log)) LogMessage("Boss part 6");
            
            UpdateHud(GetSpeedMultiplier(MUSIC_INFO_LEN));
        }
        
        if (GetConVarBool(ww_log)) LogMessage("Boss part 7");
    
        if (bossBattle != 1) {
            new Float:MUSIC_INFO_LEN = MUSIC_SPEEDUP_LEN;
            decl String:MUSIC_INFO[PLATFORM_MAX_PATH];
            Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC_SPEEDUP);
            if (g_Gamemode == GAMEMODE_WIPEOUT) {
                MUSIC_INFO_LEN = MUSIC2_SPEEDUP_LEN;
                Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC2_SPEEDUP);
            }
        
            if (GetConVarBool(ww_music)) EmitSoundToClient(1, MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
            else EmitSoundToAll(MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
            for (new i = 1; i <= MaxClients; i++) {
                if (IsValidClient(i) && (!(IsFakeClient(i)))) {
                    SetOverlay(i,"tf2ware_minigame_speed");
                }
            }
            UpdateHud(GetSpeedMultiplier(MUSIC_INFO_LEN));
            SetConVarFloat(ww_speed, GetConVarFloat(ww_speed) + 1.0);
            CreateTimer(GetSpeedMultiplier(MUSIC_INFO_LEN), StartMinigame_timer2);
        }
        
        if (GetConVarBool(ww_log)) LogMessage("Boss part 8");
        
        status = 10;
        
        if (GetConVarBool(ww_log)) LogMessage("Post boss");
    }
}

public Action:Victory_timer(Handle:hTimer) {
    if ((status == 4) && (bossBattle > 0)) {
        bossBattle = 0;
        SetConVarFloat(ww_speed, 1.0);
        currentSpeed = GetConVarFloat(ww_speed);
        
        CreateTimer(GetSpeedMultiplier(8.17), Restartall_timer);
        status = 5;
        
        new Float:MUSIC_INFO_LEN = MUSIC_GAMEOVER_LEN;
        decl String:MUSIC_INFO[PLATFORM_MAX_PATH];
        Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC_GAMEOVER);
        if (g_Gamemode == GAMEMODE_WIPEOUT) {
            MUSIC_INFO_LEN = MUSIC2_GAMEOVER_LEN;
            Format(MUSIC_INFO, sizeof(MUSIC_INFO), MUSIC2_GAMEOVER);
        }
        
        if (GetConVarBool(ww_music)) EmitSoundToClient(1, MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        else EmitSoundToAll(MUSIC_INFO, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,GetSoundMultiplier());
        
        ResetWinners();
        
        new targetscore = GetHighestScore();
        if (SpecialRound == 5) targetscore = GetLowestScore();
        new winnernumber = 0;
        new Handle:ArrayWinners = CreateArray();
        decl String:winnerstring_prefix[128];
        decl String:winnerstring_names[512];
        decl String:pointsname[512];
        Format(pointsname, sizeof(pointsname), "points");
        if (g_Gamemode == GAMEMODE_WIPEOUT) Format(pointsname, sizeof(pointsname), "lives");
        
        new bool:bAccepted = false;
        for (new i = 1; i <= MaxClients; i++) {
            SetOverlay(i, "");
            if (IsValidClient(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)) {
                bAccepted = false;
                if (g_Gamemode == GAMEMODE_WIPEOUT) {
                    if (g_Points[i] > 0) bAccepted = true;
                }
                else {
                    if (SpecialRound != 5 && g_Points[i] >= targetscore) bAccepted = true;
                    if (SpecialRound == 5 && g_Points[i] <= targetscore) bAccepted = true;
                }
                if (bAccepted) {
                    g_Winner[i] = 1;
                    RespawnClient(i, true, true);
                    SetWeaponState(i, true);
                    winnernumber += 1;
                    PushArrayCell(ArrayWinners, i);
                }
            }
        }
        for (new i = 0; i < GetArraySize(ArrayWinners); i++) {
            new client = GetArrayCell(ArrayWinners, i);
            if (winnernumber > 1) {
                if (i >= (GetArraySize(ArrayWinners)-1)) Format(winnerstring_names, sizeof(winnerstring_names), "%s and {olive}%N{green}", winnerstring_names, client);
                else Format(winnerstring_names, sizeof(winnerstring_names), "%s, {olive}%N{green}", winnerstring_names, client);
            }
            else Format(winnerstring_names, sizeof(winnerstring_names), "{olive}%N{green}", client);
        }
        if (winnernumber > 1) ReplaceStringEx(winnerstring_names, sizeof(winnerstring_names), ", ", "");
        
        if (winnernumber == 1) Format(winnerstring_prefix, sizeof(winnerstring_prefix), "{green}The winner is");
        else Format(winnerstring_prefix, sizeof(winnerstring_prefix), "{green}The winners are");
        
        CPrintToChatAll("%s %s (%i %s)!", winnerstring_prefix, winnerstring_names, targetscore, pointsname);
        CloseHandle(ArrayWinners);
        
        if (SpecialRound > 0) {
            CPrintToChatAll("The {lightgreen}Special Round{default} is over!");
            ResetSpecialRoundEffect();
            SpecialRound = 0;
            ShowGameText("Special Round is over!");
        }
        UpdateHud(GetSpeedMultiplier(MUSIC_INFO_LEN));    
    }
    return Plugin_Stop;
}

public Action:Restartall_timer(Handle:hTimer) {
    if (status == 5) {
        bossBattle = 0;
        
        // Set the game speed
        if (SpecialRound == 1) SetConVarFloat(ww_speed, 3.0);
        else SetConVarFloat(ww_speed, 1.0);
        
        if (SpecialRound > 0) AddSpecialRoundEffect();
        
        currentSpeed = GetConVarFloat(ww_speed);
        ResetScores();
        SetStateAll(false);
        ResetWinners();
        g_minigamestotal = 0;
        
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && IsPlayerAlive(i)) DisableClientWeapons(i);
        }
        
        // Roll special round
        if ((GetRandomInt(0,9) == 5 || GetConVarBool(ww_special)) && SpecialRound == 0) {
            status = 6;
            StartSpecialRound();
        }
        else {
            status = 0;
            SetGameMode();
            ResetScores();
            StartMinigame();
        }
    }
    return Plugin_Stop;
}

new var_SpecialRoundRoll = 0;
new var_SpecialRoundCount = 0;

public StartSpecialRound() {
    if (status == 6) {
        RespawnAll();
        SetConVarBool(ww_special, false);
        if (GetConVarInt(ww_force_special) <= 0) SpecialRound = GetRandomInt(1,SPECIAL_TOTAL);
        else SpecialRound = GetConVarInt(ww_force_special);
    
        if (GetConVarBool(ww_music)) EmitSoundToClient(1, MUSIC_SPECIAL);
        else EmitSoundToAll(MUSIC_SPECIAL);
        
        status = 5;
        CreateTimer(0.1, SpecialRound_timer);
        
        var_SpecialRoundCount = 130;
        
        CreateTimer(GetSpeedMultiplier(MUSIC_SPECIAL_LEN), Restartall_timer);
        
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && (!(IsFakeClient(i)))) {
                SetOverlay(i,"");
            }
        }
    }
}

public Action:SpecialRound_timer(Handle:hTimer) {
    if (status == 5 && var_SpecialRoundCount > 0) {
        CreateTimer(0.0, SpecialRound_timer);
        
        var_SpecialRoundCount -= 1;
        var_SpecialRoundRoll += 1;
        if (var_SpecialRoundRoll > sizeof(var_special_name)+1) var_SpecialRoundRoll = 0;
        decl String:Name[128];
        if (var_SpecialRoundRoll < sizeof(var_special_name)) Format(Name, sizeof(Name), var_special_name[var_SpecialRoundRoll]);
        else {
            decl String:var_funny_names[][] = {"FAT LARD RUN", "MOUSTACHIO", "LOVE STORY", "SIZE MATTERS", "ENGINERD", "IDLE FOR HATS", "TF2 BROS: BRAWL", "HOT SPY ON ICE"};
            Format(Name, sizeof(Name), var_funny_names[GetRandomInt(0, sizeof(var_funny_names)-1)]);
        }
        
        if (var_SpecialRoundCount > 0) {
            decl String:Text[128];
            Format(Text, sizeof(Text), "SPECIAL ROUND: %s?\nSpecial Round adds a new condition to the next round!", Name);
            ShowGameText(Text, "leaderboard_dominated", 1.0);
        }
        
        if (var_SpecialRoundCount == 0) {
            if (GetConVarBool(ww_music)) EmitSoundToClient(1, SOUND_SELECT);
            else EmitSoundToAll(SOUND_SELECT);
            GiveSpecialRoundInfo();
        }    
    }
}

GiveSpecialRoundInfo() {
    if (SpecialRound > 0) {
        decl String:Text[128];
        Format(Text, sizeof(Text), "SPECIAL ROUND: %s!\n%s", var_special_name[SpecialRound-1], var_special_desc[SpecialRound-1]);
        ShowGameText(Text, "leaderboard_dominated");
    }
}

public Action:Command_event(client, args) {
    status = 6;
    StartSpecialRound();
    SetConVarBool(ww_enable, true);
    
    return Plugin_Handled;
}

SetStateAll(bool:value) {
    for (new i = 1; i <= MaxClients; i++) {
        g_Complete[i] = value;
    }
}

SetMissionAll(value) {
    for (new i = 1; i <= MaxClients; i++) {
        g_Mission[i] = value;
    }
}

SetClientSlot(client, slot) {
    if (GetConVarBool(ww_log)) LogMessage("Setting client slot");
    new weapon = GetPlayerWeaponSlot(client, slot);
    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

RespawnAll(bool:force = false, bool:savepos = true) {
    if (GetConVarBool(ww_log)) LogMessage("Respawning everyone");
    for (new i = 1; i <= MaxClients; i++) {
        RespawnClient(i, force, savepos);
    }
}

RespawnClient(any:i, bool:force = false, bool:savepos = true) {
    decl Float:pos[3];
    decl Float:vel[3];
    decl Float:ang[3];
    new alive = false;
    if (IsValidClient(i) && IsValidTeam(i) && (g_Spawned[i] == true)) {
        new bool:force2 = false;
        if (!IsPlayerAlive(i)) force2 = true;
        if (force && IsClientParticipating(i)) force2 = true;
        if (g_Gamemode == GAMEMODE_WIPEOUT && g_Points[i] <= 0) force2 = false;
        if (force2) {
            alive = false;
            if (savepos) {
                GetClientAbsOrigin(i, pos);
                GetClientEyeAngles(i, ang);
                GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
                if (IsPlayerAlive(i)) alive = true;
            }
            
            TF2_RespawnPlayer(i);
            if ((savepos) && (alive)) TeleportEntity(i, pos, ang, vel);
        }
        TF2_RemovePlayerDisguise(i);
    }
}

SetStateClient(client, bool:value, bool:complete=false) {
    if (IsValidClient(client) && IsClientParticipating(client)) {
        if (complete && g_Complete[client] != value) {
            if (value) {
                EmitSoundToClient(client, SOUND_COMPLETE);
                for(new i = 1; i <= MaxClients; i++) {
                    if (IsValidClient(i) && !IsFakeClient(i)) {
                        EmitSoundToClient(i, SOUND_COMPLETE_YOU, client);
                        if (IsClientParticipating(i) && IsPlayerAlive(i) && g_Gamemode == GAMEMODE_WIPEOUT && i != client) {
                            SetStateClient(i, false, true);
                            ForcePlayerSuicide(i);
                            CPrintToChatEx(i, client, "{green}You were beaten by {teamcolor}%N{green}!", client);
                        }
                    }
                }
                new String:effect[128] = PARTICLE_WIN_BLUE;
                if (GetClientTeam(client) == 2) effect = PARTICLE_WIN_RED;
                ClientParticle(client, effect, 8.0);
            }
        }
        g_Complete[client] = value;
    }
}

stock Float:GetSpeedMultiplier(Float:count) {
    new Float:divide = ((currentSpeed-1.0)/7.5)+1.0;
    new Float:speed = count / divide;
    return speed;
}

stock Float:GetHostMultiplier(Float:count) {
    new Float:divide = ((currentSpeed-1.0)/7.5)+1.0;
    new Float:speed = count * divide;
    return speed;
}

GetSoundMultiplier() {
    new speed = SNDPITCH_NORMAL + RoundFloat((currentSpeed-1.0)*10.0);
    return speed;
}

HookAllCheatCommands() {
    decl String:name[64];
    new Handle:cvar;
    new bool:isCommand;
    new flags;
    
    cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags);
    if (cvar ==INVALID_HANDLE) {
        SetFailState("Could not load cvar list");
    }
    
    do {
        if (!isCommand || !(flags & FCVAR_CHEAT)) {
            continue;
        }
        RegConsoleCmd(name, OnCheatCommand);
        
    } 
	while (FindNextConCommand(cvar, name, sizeof(name), isCommand, flags));
    
    CloseHandle(cvar);
}

UpdateClientCheatValue() {
    if (GetConVarBool(ww_log)) LogMessage("Updating client cheat value");
    for(new i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i) && (!(IsFakeClient(i)))) {
            SendConVarValue(i, FindConVar("sv_cheats"), "1");
        }
    }
}

public OnConVarChanged_SvCheats(Handle:convar, const String:oldValue[], const String:newValue[]) {
    UpdateClientCheatValue();
}

public Action:OnCheatCommand(client, args) {
    if (GetConVarBool(ww_log)) LogMessage("on cheat command");
    if (GetConVarBool(ww_enable) && g_enabled) {
        decl String:command[32];
        GetCmdArg(0, command, sizeof(command));

        decl String:buf[64];
        new size = GetArraySize(ww_allowedCommands);
        for (new i=0; i<size; ++i) {
            GetArrayString(ww_allowedCommands,i, buf, sizeof(buf));
            
            if (StrEqual(buf, command, false) || GetConVarInt(FindConVar("sv_cheats")) == 1) {
                return Plugin_Continue;
            }
        }

        KickClient(client, "Attempted to use cheat command.");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

SetOverlay(i, String:overlay[512]) {
    if (IsValidClient(i) && (!(IsFakeClient(i)))) {
        new String:language[512];
        new String:input[512];
        // TRANSLATION
        Format(language, sizeof(language), "");
        
        if (g_Country[i] > 0) {
            Format(language, sizeof(language), "/%s",var_lang[g_Country[i]]);
        }
        
        if (StrEqual(overlay, "")) {
            Format(input, sizeof(input), "r_screenoverlay \"\"");
        }
        if (!(StrEqual(overlay, ""))) {
            Format(input, sizeof(input), "r_screenoverlay \"%s%s%s\"", materialpath,language,overlay);
        }
        ClientCommand(i,input);
        g_ModifiedOverlay[i] = true;
    }
}

UpdateHud(Float:time) {
    decl String:output[512];
    decl String:add[5];
    decl String:scorename[26];
    new colorR = 255;
    new colorG = 255;
    new colorB = 0;
    Format(scorename, sizeof(scorename), "Points:");
    if (g_Gamemode == GAMEMODE_WIPEOUT && SpecialRound != 7) {
        Format(scorename, sizeof(scorename), "Lives:");
    }
    for(new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            Format(add, sizeof(add), "");
            if (g_Gamemode == GAMEMODE_WIPEOUT) {
                if (!g_Complete[i] && IsClientParticipating(i) && bossBattle != 1 && SpecialRound != 7) Format(add, sizeof(add), "-1");
                if (!g_Complete[i] && IsClientParticipating(i) && bossBattle == 1 && SpecialRound != 7) Format(add, sizeof(add), "-5");
            }
            else {
                if (g_Complete[i] && IsClientParticipating(i) && bossBattle != 1 && SpecialRound != 7) Format(add, sizeof(add), "+1");
                if (g_Complete[i] && IsClientParticipating(i) && bossBattle == 1 && SpecialRound != 7) Format(add, sizeof(add), "+5");
            }
            Format(output, sizeof(output), "%s %i %s", scorename, g_Points[i], add);
            SetHudTextParams(0.3, 0.70, time, colorR, colorG, colorB, 0);
            ShowSyncHudText(i, hudScore, output);
        }
    }
}

public SortPlayerTimes(elem1[],elem2[],const array[][],Handle:hndl) {
    if(elem1[1] > elem2[1]) {
        return -1;
    }
    else if(elem1[1] < elem2[1]) {
        return 1;
    }
    return 0;
}  

ResetScores() {
    for(new i = 1; i <= MaxClients; i++) {
        if (g_Gamemode == GAMEMODE_WIPEOUT) g_Points[i] = 3;
        else g_Points[i] = 0;
    }
}

GetHighestScore() {
    new out = 0;
    
    for(new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && g_Points[i] > out) out = g_Points[i];
    }
    return out;
}

GetLowestScore() {
    new out = 99;
    
    for(new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && g_Points[i] < out) out = g_Points[i];
    }
    return out;
}

GetAverageScore() {
    new out = 0;
    new total = 0;
    
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && (g_Points[i] > 0)) {
            out += g_Points[i];
            total += 1;
        }
    }
    
    if ((total > 0) && (out > 0)) out = out / total;
    
    return out;
}

stock Float:GetAverageScoreFloat() {
    new out = 0;
    new Float:out2 = 0.0;
    new total = 0;
    
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && (g_Points[i] > 0)) {
            out += g_Points[i];
            total += 1;
        }
    }
    
    if ((total > 0) && (out > 0)) out2 = float(out) / float(total);
    
    return out2;
}

ResetWinners() {
    for (new i = 1; i <= MaxClients; i++) {
        g_Winner[i] = 0;
    }
}

public Action:Command_points(client, args) {
    PrintToChatAll("Gave %N 20 points", client);
    g_Points[client] += 20;
    g_Points[0] += 20;
    g_Points[1] += 20;
    return Plugin_Handled;
}

public Action:Command_list(client, args) {
    PrintToConsole(client, "Listing all registered minigames...");
    new String:output[128];
    for (new i=0; i<sizeof(g_name); i++) {
        if (StrEqual(g_name[i], "")) continue;
        if (GetMinigameConfNum(g_name[i], "enable", 1))
            Format(output, sizeof(output), " %2d - %s", GetMinigameConfNum(g_name[i], "id"), g_name[i]);
        else
            Format(output, sizeof(output), " %2d - %s (disabled)", GetMinigameConfNum(g_name[i], "id"), g_name[i]);
        PrintToConsole(client, output);
    }
}

RemoveNotifyFlag(String:name[128]) {
    new Handle:cv1 = FindConVar(name);
    new flags = GetConVarFlags(cv1);
    flags &= ~FCVAR_REPLICATED;
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(cv1, flags);
}

InitMinigame(id) {
    GiveId();
    Call_StartFunction(INVALID_HANDLE, g_initFuncs[id-1]);
    Call_Finish();
    
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsClientParticipating(i)) {
            Call_StartForward(g_justEntered);
            Call_PushCell(i);
            Call_Finish();
        }
    }
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (GetConVarBool(ww_enable) && (status == 2)) {
    
        if (g_PlayerDeath != INVALID_HANDLE && IsValidClient(client) && IsClientParticipating(client)) {
            Call_StartForward(g_PlayerDeath);
            Call_PushCell(client);
            Call_Finish();
        }
    }
    RemoveFakeWeapon(client);
}

// Some convenience functions for parsing the configuration file more simply.
GotoGameConf(String:game[]) {
    if (!KvJumpToKey(MinigameConf, game)) {
        PrintToServer("ERROR: Couldn't find requested iMinigame %s in configuration file!", game);
        KvRewind(MinigameConf);
    }
}

Float:GetMinigameConfFloat(String:game[], String:key[], Float:def=4.0) {
    GotoGameConf(game);
    new Float:value = KvGetFloat(MinigameConf, key, def);
    KvGoBack(MinigameConf);
    return value;
}

GetMinigameConfNum(String:game[], String:key[], def=0) {
    GotoGameConf(game);
    new value = KvGetNum(MinigameConf, key, def);
    KvGoBack(MinigameConf);
    return value;
}

GetRandomWipeoutPlayer() {
    new Handle:roll = CreateArray();
    new out = -1;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && IsClientParticipating(i) == false && g_Points[i] > 0) {
            PushArrayCell(roll, i);
        }
    }
        
    if (GetArraySize(roll) > 0) out = GetArrayCell(roll, GetRandomInt(0, GetArraySize(roll)-1));
    CloseHandle(roll);
    return out;
}

stock bool:IsClientParticipating(iClient) {
    if (g_Participating[iClient] == false) return false;
    return true;
}

SetGameMode() {
    new iOld = g_Gamemode;
    new iGamemode = GetConVarInt(ww_gamemode);
    if (iGamemode >= 0) g_Gamemode = iGamemode;
    else {
        g_Gamemode = GAMEMODE_NORMAL;
        new iRoll = GetRandomInt(0, 100);
        if (iRoll <= 5) g_Gamemode = GAMEMODE_WIPEOUT;
    }
    
    if (iOld == GAMEMODE_WIPEOUT && g_Gamemode != iOld) {
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && IsPlayerAlive(i)) SetWipeoutPosition(i, false);
        }
    }
    if (g_Gamemode == GAMEMODE_WIPEOUT && g_Gamemode != iOld) {
        for (new i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i) && IsPlayerAlive(i)) SetWipeoutPosition(i, true);
        }
    }
}

RemoveAllParticipants() {
    for (new i = 1; i <= MaxClients; i++) {
        g_Participating[i] = false;
    }
}

GetLeftWipeoutPlayers() {
    new out = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && GetClientTeam(i) >= 2 && g_Points[i] > 0) out ++;
    }
    return out;
}

SetWipeoutPosition(iClient, bool:bState = false) {
    new Float:fPos[3];
    GetClientAbsOrigin(iClient, fPos);
    if (bState) fPos[2] = GAMEMODE_WIPEOUT_HEIGHT;
    else fPos[2] = -70.0;
    TeleportEntity(iClient, fPos, NULL_VECTOR, NULL_VECTOR);
}

public Action:Timer_HandleWOLives(Handle:hTimer, any:iClient) {
    HandleWipeoutLives(iClient);
}

HandleWipeoutLives(iClient, bMessage = false) {
    if (g_Gamemode == GAMEMODE_WIPEOUT && IsValidClient(iClient) && IsPlayerAlive(iClient) && g_Points[iClient] <= 0) {
        if (bMessage) {
            if (g_Points[iClient] == 0) CPrintToChatAllEx(iClient, "{teamcolor}%N{olive} has been {green}wiped out!", iClient);
            if (g_Points[iClient] < 0) CPrintToChat(iClient, "{default}Please wait, the current {olive}Wipeout round{default} needs to finish before you can join.");
        }
        ForcePlayerSuicide(iClient);
        CreateTimer(0.2, Timer_HandleWOLives, iClient);
    }
}

public Action:TF2_CalcIsAttackCritical(iClient, iWeapon, String:StrWeapon[], &bool:bCrit) {
    if (g_enabled && GetConVarBool(ww_enable)) {
        bCrit = false;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

bool:IsValidTeam(iClient)
{
    new iTeam = GetClientTeam(iClient);
    if (iTeam == 2 || iTeam == 3) return true;
    return false;
}