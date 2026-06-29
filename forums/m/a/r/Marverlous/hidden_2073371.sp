/* [TF2] SM Hidden
 * Copyright (C) 2010, Matheus28, http://forums.alliedmods.net/showthread.php?t=143577
 * Copyright (C) 2013, Eric G. Wolfe and Daniel Murray
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <steamtools>
#include <sdkhooks>
#include <smlib>

#define PLUGIN_AUTHOR "atomic-penguin, daniel-murray"
#define PLUGIN_VERSION "3.0.0"
#define PLUGIN_NAME "TF2 Hidden"
#define PLUGIN_DESCRIPTION "Hidden:Source-like mod for TF2"
#define PLUGIN_URL "https://github.com/atomic-penguin/sm-hidden"

#define MAX_PLAYERS 32

#define DEBUG_LOGGING 0

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

enum HTeam
{
    HTeam_Unassigned = TFTeam_Unassigned,
    HTeam_Spectator = TFTeam_Spectator,
    HTeam_Iris = TFTeam_Red,
    HTeam_Hidden = TFTeam_Blue
}

new bool:activated = false;
new current_pool[MAX_PLAYERS + 1];
new bool:pool_lock = false;
new bool:round_init = false;

//cvars
new Handle:cv_enabled;
new Handle:cv_hidden_alltalk;

//class restrictions
new Handle:cv_allow_pyro;
new Handle:cv_allow_engy;
new Handle:cv_allow_sniper;

//timers
new Handle:t_tick;
#define TICK_INTERVAL 0.1
new Handle:t_disableCps;
new Handle:t_genericTips;
new Handle:t_genericStats;

// hidden player tracking related
new hidden = 0; // client index of the current hidden
new TFClassType:hidden_previous_class = TFClass_Soldier;
new next_hidden = 0; // client index of the hidden for next round
new previous_hidden = 0; // client index of the hidden from the last round
new current_hidden_kill_count = 0;

// hidden condition related
#define HIDDEN_ROUND_START_FILE_ONE "vo/taunts/spy_taunts04.wav"
#define HIDDEN_ROUND_START_FILE_TWO "vo/taunts/spy_taunts10.wav"
#define HIDDEN_ROUND_START_FILE_THREE "vo/taunts/spy_taunts11.wav"
#define HIDDEN_INVISIBILITY_TIME 100.0
new Float:hidden_visible;
new Float:hidden_invisibility;
new hidden_hp = 0; 
#define HIDDEN_MAX_HEALTH 500
new game_defined_hidden_max_health;
#define HIDDEN_HP_PER_PLAYER 50
#define HIDDEN_HP_PER_KILL 75
#define HIDDEN_HP_REGEN_TIME 10.0
new heal_per_second = 0;
new amount_yet_to_heal = 0;
#define HIDDEN_OVERLAY "effects/combine_binocoverlay"

// jumping related
#define HIDDEN_STAMINA_TIME 10.0
#define HIDDEN_JUMP_TIME 0.1
new bool:hidden_stuck = false;
new Float:hidden_stamina = 0.0;
new Float:hidden_jump = 0.0;
#define HIDDEN_JUMP_FILE "vo/taunts/spy_taunts05.wav"

// boo related
#define HIDDEN_BOO_STUN_DURATION 3.5
#define HIDDEN_BOO_FILE "vo/taunts/spy_taunts06.wav"
new Float:hidden_boo_charge = 0.0;

// generic tip system
new tip_counter = 0;
#define TOTAL_TIPS 9 

static const String:generic_tips[][] =
{
    "Kill \x03The Hidden\x01 to become him, have fun!",
    "\x03The Hidden \x01is immune to \
        milks, pisses, and afterburn.",
    "As the Hidden, you will starve if \
        you cloak metter ran out, kill to survive.",
    "Pyros, Heavies, and Razorback had been thoroughly nerfed, \
        with reduced primary ammunitions and health point.",
    "As \x03The Hidden \x01Right-click lets you pounce \
        and stick to surfaces.",
    "As \x03The Hidden \x01you can throw a deadly \
       Grenade by typing !cb",
    "As \x03The Hidden \x01pressing R activates boo.",
    "Pay attention to the sounds of footsteps.",
    "As \x03The Hidden \x01use Boo and Nades to clear \
        enemies out of corners and tight spaces."
};

// stats
new kills_as_hidden[MAX_PLAYERS + 1];
new kills_of_hidden[MAX_PLAYERS + 1];
new bool:last_shown_kills_as = false;

// weapon banning related
#define TOTAL_BANNED_ITEMS 9

static const banned_items[] =
{
    811,  // "The Huo Long Heater"
    42,   // "The Sandvich"
    1002, // "Festive Sandvich"
    863,  // "The Robo-Sandvich"
    433,  // "Fishcake"
    159,  // "The Dalokohs Bar"
    311,  // "The Buffalo Steak Sandvich"
    656,  // "The Holiday Punch"
    46    // "Bonk! Atomic Punch"
};

static const String:banned_items_names[][] =
{
    "The Huo Long Heater",        // 811
    "The Sandvich",               // 42
    "Festive Sandvich",           // 1002
    "The Robo-Sandvich",          // 863
    "Fishcake",                   // 433
    "The Dalokohs Bar",           // 159 
    "The Buffalo Steak Sandvich", // 311 
    "The Holiday Punch",          // 656
    "Bonk! Atomic Punch"          // 46
};

static const replacement_items_index[] =
{
    15, // "tf_weapon_minigun"
    11, // "tf_weapon_shotgun_hwg"
    11, // "tf_weapon_shotgun_hwg"
    11, // "tf_weapon_shotgun_hwg"
    11, // "tf_weapon_shotgun_hwg"
    11, // "tf_weapon_shotgun_hwg"
    11, // "tf_weapon_shotgun_hwg"
    5,  // "tf_weapon_fists"
    23  // "tf_weapon_pistol_scout"
};

static const String:replacement_items[][] =
{
    "tf_weapon_minigun",     // "The Huo Long Heater" -> "Minigun" 
    "tf_weapon_shotgun_hwg", // "The Sandvich" -> "Shotgun"
    "tf_weapon_shotgun_hwg", // "Festive Sandvich" -> "Shotgun"
    "tf_weapon_shotgun_hwg", // "The Robo-Sandvich" -> "Shotgun"
    "tf_weapon_shotgun_hwg", // "Fishcake" -> "Shotgun"
    "tf_weapon_shotgun_hwg", // "The Dalokohs Bar" -> "Shotgun"
    "tf_weapon_shotgun_hwg", // "The Buffalo Steak Sandvich" -> "Shotgun"
    "tf_weapon_fists",       // "The Holiday Punch" -> "Fists"
    "tf_weapon_pistol_scout" // "Bonk! Atomic Punch" -> "Scouts Pistol"
};

// other
new bool:InitialRoundInit = false;
new number_of_charging_dots = 0;
new hide_text_due_to_scores[MAX_PLAYERS + 1];
new display_hidden_hud_tip = false;
new bool:hidden_jump_blocker = false;
#define HIDDEN_GENERIC_FINAL_FILE "vo/taunts/spy_taunts09.wav"
#define HIDDEN_SCOUT_FINAL_FILE "vo/spy_dominationscout06.wav"
#define HIDDEN_SOLDIER_FINAL_FILE "vo/spy_dominationsoldier04.wav"
#define HIDDEN_PYRO_FINAL_FILE "vo/spy_dominationpyro04.wav"
#define HIDDEN_DEMO_FINAL_FILE "vo/spy_dominationdemoman04.wav"
#define HIDDEN_HEAVY_FINAL_FILE "vo/spy_dominationheavy02.wav"
#define HIDDEN_ENGY_FINAL_FILE "vo/taunts/spy_taunts08.wav"
#define HIDDEN_MEDIC_FINAL_FILE "vo/spy_dominationmedic04.wav"
#define HIDDEN_SNIPER_FINAL_FILE "vo/spy_dominationsniper06.wav"

public OnPluginStart()
{
    //LoadTranslations("common.phrases");
    cv_enabled = CreateConVar("sm_hidden_enabled", "1",
        "Enables/Disables the plugin.", 0, true, 0.0, true, 1.0);
    cv_allow_pyro = CreateConVar("sm_hidden_allow_pyro", "0",
        "Whether pyro is allowed.", 0, true, 0.0, true, 1.0);
    cv_allow_engy = CreateConVar("sm_hidden_allow_engy", "1",
        "Whether engy is allowed.", 0, true, 0.0, true, 1.0);
    cv_allow_sniper = CreateConVar("sm_hidden_allow_sniper", "0",
        "Whether sniper is allowed.", 0, true, 0.0, true, 1.0);

    cv_hidden_alltalk = CreateConVar("sm_hidden_alltalk", "1",
        "Turns alltalk on and voice icons off.", 0, true, 0.0, true, 1.0);

    HookConVarChange(cv_enabled, cvhook_enabled);
    HookConVarChange(cv_allow_pyro, cvhook_allow_pyro);
    HookConVarChange(cv_allow_engy, cvhook_allow_engy);
    HookConVarChange(cv_allow_sniper, cvhook_allow_sniper);
    HookConVarChange(cv_hidden_alltalk, cvhook_hidden_alltalk);

    RegAdminCmd("sm_hidden_enable", Command_HiddenEnable, ADMFLAG_CONVARS,
        "Enables the plugin.");
    RegAdminCmd("sm_hidden_disable", Command_HiddenDisable, ADMFLAG_CONVARS,
        "Disables the plugin.");

    PrecacheSound(HIDDEN_ROUND_START_FILE_ONE, true);
    PrecacheSound(HIDDEN_ROUND_START_FILE_TWO, true);
    PrecacheSound(HIDDEN_ROUND_START_FILE_THREE, true);
    PrecacheSound(HIDDEN_JUMP_FILE, true);
    PrecacheSound(HIDDEN_BOO_FILE, true);
    PrecacheSound(HIDDEN_GENERIC_FINAL_FILE, true);
    PrecacheSound(HIDDEN_SCOUT_FINAL_FILE, true);
    PrecacheSound(HIDDEN_SOLDIER_FINAL_FILE, true);
    PrecacheSound(HIDDEN_PYRO_FINAL_FILE, true);
    PrecacheSound(HIDDEN_DEMO_FINAL_FILE, true);
    PrecacheSound(HIDDEN_HEAVY_FINAL_FILE, true);
    PrecacheSound(HIDDEN_ENGY_FINAL_FILE, true);
    PrecacheSound(HIDDEN_MEDIC_FINAL_FILE, true);
    PrecacheSound(HIDDEN_SNIPER_FINAL_FILE, true);
}

public OnPluginEnd()
{
    UnhookConVarChange(cv_enabled, cvhook_enabled);
    UnhookConVarChange(cv_allow_pyro, cvhook_allow_pyro);
    UnhookConVarChange(cv_allow_engy, cvhook_allow_engy);
    UnhookConVarChange(cv_allow_sniper, cvhook_allow_sniper);
    UnhookConVarChange(cv_hidden_alltalk, cvhook_hidden_alltalk);
}

stock ActivatePlugin()
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @ActivatePlugin", PLUGIN_NAME);
#endif

    if (!(GetConVarBool(cv_enabled))) return;
    activated = true;

    for (new i = 1; i < MAX_PLAYERS + 1; ++i)
    {
        current_pool[i] = 0;
        kills_as_hidden[i] = 0;
        kills_of_hidden[i] = 0;
    }

    SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
    SetConVarInt(FindConVar("tf_arena_override_team_size"), MAX_PLAYERS);
    SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
    SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
    SetConVarInt(FindConVar("mp_waitingforplayers_restart"), 1);
    SetConVarInt(FindConVar("mp_waitingforplayers_cancel"), 1);
    SetConVarString(FindConVar("sv_tags"), "hidden ");

    t_tick = CreateTimer(TICK_INTERVAL, Timer_Tick, _, TIMER_REPEAT);
    t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
    t_genericTips = CreateTimer(130.0, Timer_GenericTip, _, TIMER_REPEAT);
    t_genericStats = CreateTimer(240.0, Timer_GenericStats, _, TIMER_REPEAT);

    HookEvent("teamplay_round_start", teamplay_round_start);
    HookEvent("teamplay_round_win", teamplay_round_win);
    HookEvent("teamplay_round_active", teamplay_round_active);
    HookEvent("arena_round_start", teamplay_round_active);
    HookEvent("player_spawn", player_spawn);
    HookEvent("player_changeclass", player_changeclass);
    HookEvent("player_hurt", player_hurt);
    HookEvent("player_death", player_death);

    AddCommandListener(Cmd_build, "build");

    round_init = false;

    SetGameDescription();
}

stock DeactivatePlugin()
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @DeactivatePlugin", PLUGIN_NAME);
#endif

    if (!activated) return;
    activated = false;

    for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        current_pool[i] = 0;

    SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
    SetConVarInt(FindConVar("tf_arena_override_team_size"), 0);
    SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
    SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
    SetConVarInt(FindConVar("mp_waitingforplayers_restart"), 0);
    SetConVarInt(FindConVar("mp_waitingforplayers_cancel"), 0);
    SetConVarString(FindConVar("sv_tags"), "");

    KillTimer(t_tick);
    KillTimer(t_disableCps);
    KillTimer(t_genericTips);
    KillTimer(t_genericStats);

    UnhookEvent("teamplay_round_start", teamplay_round_start);
    UnhookEvent("teamplay_round_win", teamplay_round_win);
    UnhookEvent("teamplay_round_active", teamplay_round_active);
    UnhookEvent("arena_round_start", teamplay_round_active);
    UnhookEvent("player_spawn", player_spawn);
    UnhookEvent("player_changeclass", player_changeclass);
    UnhookEvent("player_hurt", player_hurt);
    UnhookEvent("player_death", player_death);

    RemoveCommandListener(Cmd_build, "build");

    round_init = false;

    SetGameDescription();
}

public OnMapStart()
{
    InitialRoundInit = false;

    if (IsArenaMap() && GetConVarBool(cv_enabled))
    {
        ActivatePlugin();
    }
    SetGameDescription();
}

public OnMapEnd()
{
    if (IsArenaMap() && GetConVarBool(cv_enabled))
    {
        DeactivatePlugin();
    }
    SetGameDescription();
}

/************************************************************************/

public cvhook_enabled(
    Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @cvhook_enabled", PLUGIN_NAME);
#endif

    if (GetConVarBool(cvar) && IsArenaMap())
    {
        ActivatePlugin();
    }
    else
    {
        DeactivatePlugin();
    }
}

public cvhook_allow_pyro(
    Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @cvhook_allow_pyro", PLUGIN_NAME);
#endif

    if (GetConVarBool(cvar))
    {
        PrintToServer("[%s] Enabling the use of pyro", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Pyro \x01can now be played in \
            \x03The Hidden\x01!", PLUGIN_NAME);
    }
    else
    {
        PrintToServer("[%s] Disabling the use of pyro", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Pyro \x01is can no longer be played in \
            \x03The Hidden\x01.", PLUGIN_NAME);
    }
}

public cvhook_allow_engy(
    Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @cvhook_allow_engy", PLUGIN_NAME);
#endif

    if (GetConVarBool(cvar))
    {
        PrintToServer("[%s] Enabling the use of engineer", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Engineer \x01can now be played in \
            \x03The Hidden\x01!", PLUGIN_NAME);
    }
    else
    {
        PrintToServer("[%s] Disabling the use of engineer", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Engineer \x01is can no longer be played \
            in \x03The Hidden\x01.", PLUGIN_NAME);
    }
}

public cvhook_allow_sniper(
    Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @cvhook_allow_sniper", PLUGIN_NAME);
#endif

    if (GetConVarBool(cvar))
    {
        PrintToServer("[%s] Enabling the use of sniper", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Sniper \x01can now be played in \
            \x03The Hidden\x01!", PLUGIN_NAME);
    }
    else
    {
        PrintToServer("[%s] Disabling the use of sniper", PLUGIN_NAME);
        PrintToChatAll("\x04[%s] \x03Sniper \x01is can no longer be played \
            in \x03The Hidden\x01.", PLUGIN_NAME);
    }
}

public cvhook_hidden_alltalk(
    Handle:cvar, const String:oldVal[], const String:newVal[])
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @cvhook_hidden_alltalk", PLUGIN_NAME);
#endif

    if (GetConVarBool(cvar))
    {
        ServerCommand("sv_alltalk 1");
        ServerCommand("mp_show_voice_icons 0");
        ServerCommand("tf_teamtalk 0");
    }
    else
    {
        ServerCommand("sv_alltalk 0");
        ServerCommand("mp_show_voice_icons 1");
        ServerCommand("tf_teamtalk 1");
    }
}

public Action:Command_HiddenEnable(client, args)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @Command_HiddenEnable", PLUGIN_NAME);
#endif

    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (!cvar_enabled)
    {
        ServerCommand("sm_hidden_enabled 1");
        ReplyToCommand(client, "the plugin was enabled,");
        ReplyToCommand(client, "it is highly recommended to run changelevel \
            after enabling the plugin.");
    }
    return Plugin_Handled;
}

public Action:Command_HiddenDisable(client, args)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @Command_HiddenDisable", PLUGIN_NAME);
#endif

    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (cvar_enabled)
    {
        ServerCommand("sm_hidden_enabled 0");
        ReplyToCommand(client, "the plugin was disabled,");
        ReplyToCommand(client, "it is highly recommended to run changelevel \
            after disabling the plugin.");
    }
    return Plugin_Handled;
}

public Action:Cmd_build(client, String:cmd[], args)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @Cmd_build", PLUGIN_NAME);
#endif

    if (args < 1)
    {
        return Plugin_Continue;
    }

    if (TF2_GetPlayerClass(client) != TFClass_Engineer)
    {
        return Plugin_Continue;
    }

    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    new building = StringToInt(arg1);
    if (building == _:TFObject_Sentry)
    {
        PrintToChat(client, "\x04[%s] \x01 You cannot use sentries in \
            this game mode!", PLUGIN_NAME);
        Client_PrintToChat(client, true, "{G}[%s] {N}You cannot use sentries \
            in this game mode.", PLUGIN_NAME);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

/**************************************************************************/
public Action:teamplay_round_start(
    Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @teamplay_round_start", PLUGIN_NAME);
#endif

    if (PerformRoundInit())
    {
#if DEBUG_LOGGING
        PrintToServer("[%s] Sucessful PerformRoundInit() hidden: %d",
            PLUGIN_NAME, hidden);
#endif

        if (InitialRoundInit == false)
        {
            if (FindConVar("mp_roundrestart"))
            {
                SetConVarInt(FindConVar("mp_roundrestart"), 1);
            }
            InitialRoundInit = true;
        }
    }
    else
    {
#if DEBUG_LOGGING
    PrintToServer("[%s] Unsucessfull PerformRoundInit()", PLUGIN_NAME);
#endif
        InitialRoundInit = false;
    }

    return Plugin_Continue;
}

stock bool:PerformRoundInit()
{
    if (GetClientCount() < 2)
    {
        return false;
    }

    if (!round_init)
    {
        pool_lock = false;

        hidden_jump_blocker = true;

        for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        {
            current_pool[i] = 0;
        }
        
        LOOP_CLIENTS(client, CLIENTFILTER_INGAME)
        {
            current_pool[client] = 1;
        }

        // deteremine hidden
        new selected_player = 0;
        if (next_hidden != 0)
        {
            selected_player = next_hidden;
            next_hidden = 0;
        }
        else
        {
            new number_of_valid_players = 0;
            for (new i = 1; i < MAX_PLAYERS + 1; ++i)
            {
               if (current_pool[i] == 1)
               {
                    number_of_valid_players += 1;
               }
            }
            new random = GetRandomInt(1, number_of_valid_players);
            if (random == previous_hidden)
            {
                if (random == 1)
                {
                    random += 1;
                }
                else
                {
                    random -= 1;
                }
            }
            new count_so_far = 0;
            for (new i = 1; i < MAX_PLAYERS + 1; ++i)
            {
                if (current_pool[i] == 1)
                {
                    count_so_far += 1;
                    if (count_so_far == random)
                    {
                        selected_player = i;
                    }
                }
            }
        }

#if DEBUG_LOGGING
    PrintToServer("[%s] selected client:%N(%d) to be the hidden",
        PLUGIN_NAME, selected_player, selected_player);
#endif

        if (selected_player == 0)
        {
            return false;
        }

        hidden = selected_player;

        decl String:selected_player_name[64];
        if (GetClientName(selected_player, selected_player_name, 64))
        {
            PrintToChatAll("\x04[%s] \x03%s \x01was selected to be \
                \x03The Hidden\x01!", PLUGIN_NAME, selected_player_name);
        }

        current_hidden_kill_count = 0;

        for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        {
            if ((previous_hidden != 0) && (i == previous_hidden))
            {
#if DEBUG_LOGGING
    PrintToServer("[%s] found previous hidden as client:%N", PLUGIN_NAME, i);
#endif
                RemoveHiddenVision(i);
                if ((hidden_previous_class != TFClass_Spy) && (hidden_previous_class != TFClass_Unknown))
                {
                    TF2_SetPlayerClass(i, hidden_previous_class, false, true);
                    PrintToChat(i, "\x04[%s] \x01Restoring your \
                    previous class selection.", PLUGIN_NAME);
#if DEBUG_LOGGING
    PrintToServer("[%s] recorded hiddens previous class as:%d",
        PLUGIN_NAME, hidden_previous_class);
#endif
                }
                else
                {
                    TF2_SetPlayerClass(i, TFClass_Soldier, false, true);
                    Client_PrintToChat(i, true, "{G}[%s] {N}You \
                    cannot play {B}Spy {N}on the {R}Red {N}team \
                    in this game mode.", PLUGIN_NAME);
#if DEBUG_LOGGING
    PrintToServer("[%s] recorded hiddens previous class as:default_soldier",
        PLUGIN_NAME);
#endif

                }
            }
        }

        if ((hidden != 0) && (current_pool[hidden] == 1))
        {
            if (TF2_GetPlayerClass(hidden) != TFClass_Spy || TF2_GetPlayerClass(hidden) != TFClass_Unknown)
            {
                hidden_previous_class = TF2_GetPlayerClass(hidden);
            }
            else
            {
                hidden_previous_class = TFClass_Soldier;
            }
        }
#if DEBUG_LOGGING
    PrintToServer("[%s] recorded hiddens previous class as:%d",
        PLUGIN_NAME, hidden_previous_class);
#endif
        hidden_visible = 0.0;
        hidden_invisibility = HIDDEN_INVISIBILITY_TIME;
        previous_hidden = hidden;
        pool_lock = true;
        round_init = true;
        TF2_SetPlayerClass(hidden, TFClass_Spy);
        ChangeClientTeam(hidden, _:HTeam_Hidden);

        for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        {
            if (current_pool[i] == 1)
            {
                if (i == hidden)
                {
                    ChangeClientTeam(i, _:HTeam_Hidden);
                }
                else
                {
                    if (TF2_GetPlayerClass(i) == TFClass_Unknown)
                    {
                        TF2_SetPlayerClass(i, TFClass_Soldier);
                    }
                    ChangeClientTeam(i, _:HTeam_Iris);
                }
                TF2_RespawnPlayer(i);
            }
        }
    }
    return true;
}

public Action:teamplay_round_active(
    Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @teamplay_round_active", PLUGIN_NAME);
#endif

    hidden_jump_blocker = false;
    CreateTimer(3.0, Timer_Hidden_Round_Start_Speech, hidden);
}

public Action:teamplay_round_win(
    Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @teamplay_round_win", PLUGIN_NAME);
#endif

    pool_lock = false;
    round_init = false;
    MakeHiddenVisible(30.0);
}

public Action:OnPlayerRunCmd(
    client, &buttons, &impulse, Float:vec[3], Float:angles[3], &weapon)
{
    if (activated)
    {
        new bool:changed = false;

        if (client == hidden)
        {
            if (hidden_stuck && hidden_stamina < (HIDDEN_STAMINA_TIME - 0.5))
            {
                if (buttons & IN_ATTACK2)
                {
                    HiddenUnstick();
                }
            }
            if (buttons & IN_ATTACK)
            {
                changed = true;
                TF2_RemoveCondition(client, TFCond_Cloaked);
                MakeHiddenVisible(0.75);
            }

            if (buttons & IN_ATTACK2)
            {
                changed = true;
                buttons &= ~IN_ATTACK2;
                HiddenSuperJump();
            }

            if (buttons & IN_RELOAD)
            {
                HiddenBoo();
            }
        }
        else
        {
            if (buttons & IN_ATTACK)
            {
                if (TF2_IsPlayerInCondition(client, TFCond_Bonked))
                {
                    buttons &= ~IN_ATTACK;
                    changed = true;
                }
            }
        }

        if (buttons & IN_SCORE)
        {
            hide_text_due_to_scores[client] = 1;
        }
        else
        {
            hide_text_due_to_scores[client] = 0;
        }

        if (changed)
        {
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

/************************************************************************/

public Action:player_spawn(
    Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new HTeam:team = HTeam:GetEventInt(event, "team");

#if DEBUG_LOGGING
    PrintToServer("[%s] @player_spawn client:%N team:%d",
        PLUGIN_NAME, client, team);
#endif

    if (client != 0)
    {
        if (team == HTeam_Iris)
        {
            if (client == hidden)
            {
                ChangeClientTeam(client, _:HTeam_Hidden);
            }
        }
        else if (team == HTeam_Hidden)
        {
            if (client != hidden)
            {
                ChangeClientTeam(client, _:HTeam_Iris);
            }
        }
        else if (client && IsFakeClient(client))
        {
            ChangeClientTeam(client, _:HTeam_Spectator);
        }
        else
        {
            ChangeClientTeam(client, _:HTeam_Iris);
        }

    }
    else if (client != 0)
    {
        current_pool[client] = 0;
        RemoveHiddenVision(client); 
        ChangeClientTeam(client, _:HTeam_Spectator);
    }

    if (client == hidden)
    {
        game_defined_hidden_max_health = HIDDEN_MAX_HEALTH
            + ((Client_GetCount(true, true) - 1) * HIDDEN_HP_PER_PLAYER);
        hidden_hp = game_defined_hidden_max_health;
        heal_per_second = 0;
        amount_yet_to_heal = 0;
        hidden_boo_charge = 100.0;

        hidden_stamina = HIDDEN_STAMINA_TIME;
        hidden_stuck = false;
        hidden_jump = 0.0;

        display_hidden_hud_tip = true;

        TF2_RemoveWeaponSlot(client, 0); // Revolver
        TF2_RemoveWeaponSlot(client, 2); // Knife
        TF2_RemoveWeaponSlot(client, 3); // Disguise Kit
        TF2_RemoveWeaponSlot(client, 4); // Invisibility Watch
                                            
        new knife=GivePlayerItem(client, "tf_weapon_knife");
        SetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex", 4);
        new level = GetRandomInt(1, 100);
        SetEntProp(knife, Prop_Send, "m_iEntityLevel", level);
        SetEntProp(knife, Prop_Send, "m_iEntityQuality", 10);
        SetEntProp(knife, Prop_Send, "m_bInitialized", 1);
        EquipPlayerWeapon(client, knife);
        Client_SetHideHud(client, HIDEHUD_HEALTH);
        GiveHiddenVision(client);
    }
    else
    {
        if (TF2_GetPlayerClass(client) == TFClass_Spy)
        {
            TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
            Client_PrintToChat(client, true, "{G}[%s] {N}You \
                    cannot play {B}Spy {N}on the {R}Red {N}team \
                    in this game mode.", PLUGIN_NAME);
            TF2_RespawnPlayer(client);
        }
        if (((TF2_GetPlayerClass(client)) == TFClass_Pyro)
            && (!GetConVarBool(cv_allow_pyro)))
        {
            TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
            Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                spawned as a {R}Soldier {N}because {R}Pyro {N}is \
                currently {L}disabled{N}.", PLUGIN_NAME);
            TF2_RespawnPlayer(client);
        }
        if (((TF2_GetPlayerClass(client)) == TFClass_Engineer)
            && (!GetConVarBool(cv_allow_engy)))
        {
            TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
            Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                spawned as a {R}Soldier {N}because {R}Engineer \
                {N}is currently {L}disabled{N}.", PLUGIN_NAME);
            TF2_RespawnPlayer(client);
        }
        if (((TF2_GetPlayerClass(client)) == TFClass_Sniper)
            && (!GetConVarBool(cv_allow_sniper)))
        {
            TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
            Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                spawned as a {R}Soldier {N}because {R}Sniper \
                {N}is currently {L}disabled{N}.", PLUGIN_NAME);
            TF2_RespawnPlayer(client);
        }

        for (new i = 0; i < 3; ++i)
        {
            for (new j = 0; j < TOTAL_BANNED_ITEMS; ++j)
            {
                //Client_GetWeaponBySlot(client, banned_items[i]);
                new weapon = GetPlayerWeaponSlot(client, i);

                if (weapon != -1)
                {
                    new weapon_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
                    if (weapon_index == banned_items[j])
                    {
                        TF2_RemoveWeaponSlot(client, i);
                        new replacement = GivePlayerItem(client, replacement_items[j]);
                        SetEntProp(replacement, Prop_Send,
                            "m_iItemDefinitionIndex", replacement_items_index[j]);
                        SetEntProp(replacement, Prop_Send, "m_bInitialized", 1);
                        EquipPlayerWeapon(client, replacement);

                        new Handle:pack = CreateDataPack();
                        CreateTimer(float(i), Timer_InformPlayerAboutBan, pack);
                        WritePackCell(pack, client);
                        WritePackString(pack, banned_items_names[j]);
                    }
                }
            }
        }

        SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
        RemoveHiddenVision(client); 
    }

    return Plugin_Continue;
}

public Action:Timer_InformPlayerAboutBan(Handle:Timer, Handle:pack)
{
    decl String:item_name[128];
    new client;
    
    ResetPack(pack);
    client = ReadPackCell(pack);
    ReadPackString(pack, item_name, sizeof(item_name));

    if (client != hidden)
    {
        PrintToChat(client, "\x04[%s] \x01You cannot use \x03%s \
            \x01in this game mode.", PLUGIN_NAME, item_name);
    }
}

public Action:player_changeclass(
    Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @player_changeclass", PLUGIN_NAME);
#endif

    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (round_init)
    {
        if (client == hidden)
        {
            TF2_SetPlayerClass(client, TFClass_Spy, false, true);
        }
        else
        {
            if (GetEventInt(event, "class") == _:TFClass_Spy)
            {
                TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
                Client_PrintToChat(client, true, "{G}[%s] {N}You \
                    cannot play {B}Spy {N}on the {R}Red {N}team \
                    in this game mode.", PLUGIN_NAME);
            }
            if ((GetEventInt(event, "class") == _:TFClass_Pyro)
                && (!GetConVarBool(cv_allow_pyro)))
            {
                TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
                Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                    spawned as a {R}Soldier {N}because {R}Pyro {N}is \
                    currently {L}disabled{N}.", PLUGIN_NAME);
            }
            if ((GetEventInt(event, "class") == _:TFClass_Engineer)
                && (!GetConVarBool(cv_allow_engy)))
            {
                TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
                Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                    spawned as a {R}Soldier {N}because {R}Engineer \
                    {N}is currently {L}disabled{N}.", PLUGIN_NAME);
            }
            if ((GetEventInt(event, "class") == _:TFClass_Sniper)
                && (!GetConVarBool(cv_allow_sniper)))
            {
                TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
                Client_PrintToChat(client, true,  "{G}[%s] {N}You were \
                    spawned as a {R}Soldier {N}because {R}Sniper \
                    {N}is currently {L}disabled{N}.", PLUGIN_NAME);
            }

            if (!pool_lock)
            {
                current_pool[client] = 1;
                ChangeClientTeam(client, _:HTeam_Iris);
            }
            else
            {
                if (current_pool[client] == 1)
                {
                    ChangeClientTeam(client, _:HTeam_Iris);
                }
                else
                {
                    current_pool[client] = 0;
                    ChangeClientTeam(client, _:HTeam_Spectator);
                }
            }

            RemoveHiddenVision(client);
        }
    }

    return Plugin_Continue;
}

public Action:player_hurt(
    Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (victim == hidden)
    {
        if (activated)
        {
            new damage_amount = GetEventInt(event, "damageamount");
            hidden_hp -= damage_amount;
            if (hidden_hp < 0)
            {
                hidden_hp = 0;
            }
            else if (hidden_hp > HIDDEN_MAX_HEALTH)
            {
                SetEntityHealth(hidden, HIDDEN_MAX_HEALTH);
            }
            else if (hidden_hp > 0)
            {
                SetEntityHealth(hidden, hidden_hp);
            }
        }
    }
}

public Action:player_death(
    Handle:event, const String:name[], bool:dontBroadcast)
{
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

#if DEBUG_LOGGING
    PrintToServer("[%s] @player_death - victim:%N attacker:%N",
        PLUGIN_NAME, victim, attacker);
#endif


    current_pool[victim] = 0;

    if ((victim == hidden) && (attacker != 0))
    {
        if (attacker != hidden)
        {
            next_hidden = attacker;
            kills_of_hidden[attacker] += 1;
            PrintToChatAll("\x04[%s] \x01The Hidden was killed \
                by \x03%N\x01!", PLUGIN_NAME, attacker);
        }
        hidden_hp = 0;
        RemoveHiddenVision(victim);
    }
    else
    {
        if ((hidden != 0) && (attacker == hidden) && (victim != hidden))
        {
            amount_yet_to_heal += HIDDEN_HP_PER_KILL;
            CreateTimer(1.0, Timer_Heal_Hidden, hidden);

            hidden_invisibility += HIDDEN_INVISIBILITY_TIME * 0.35;
            if (hidden_invisibility > HIDDEN_INVISIBILITY_TIME)
            {
                hidden_invisibility = HIDDEN_INVISIBILITY_TIME;
            }

            PrintToChatAll("\x04[%s] \x01The Hidden killed \x03%N\x01!",
                PLUGIN_NAME, victim);
            CreateTimer(0.1, Timer_Dissolve, victim);
            next_hidden = 0;

            current_hidden_kill_count += 1;
            if (current_hidden_kill_count > kills_as_hidden[attacker])
            {
                kills_as_hidden[attacker] += 1;
            }

            if (activated && (hidden != 0))
            {
                // if the is the last member of iris alive play them a sound
                new number_of_alive_clients = -1;
                LOOP_CLIENTS(client, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE|CLIENTFILTER_NOSPECTATORS)
                {
                    number_of_alive_clients += 1;
                }

                if (number_of_alive_clients == 2)
                {
                    CreateTimer(3.0, Timer_Hidden_Final_Speech, hidden);
                }
            }
            RemoveHiddenVision(victim);
        }
    }

    return Plugin_Continue;
}

public OnClientPutInServer(client)
{
    RemoveHiddenVision(client);
}

public OnClientDisconnect(client)
{
#if DEBUG_LOGGING
    PrintToServer("[%s] @OnClientDisconnect", PLUGIN_NAME);
#endif

    if (next_hidden == client)
    {
        next_hidden = 0;
    }

    current_pool[client] = 0;
    RemoveHiddenVision(client);
    kills_as_hidden[client] = 0;
    kills_of_hidden[client] = 0;
    if (client == previous_hidden)
    {
        hidden_previous_class = TFClass_Soldier;
    }
}

public OnGameFrame()
{
    if (activated)
    {
        if (InitialRoundInit == false)
        {
            PerformRoundInit();
        }

        new Float:tick_interval = GetTickInterval();

        LOOP_CLIENTS(client, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE|CLIENTFILTER_NOSPECTATORS)
        {
            if (client == hidden)
            {
                if (GetClientHealth(client) > 0)
                {
                    if (hidden_hp > HIDDEN_MAX_HEALTH)
                    {
                        SetEntityHealth(client, HIDDEN_MAX_HEALTH);
                    }
                    else
                    {
                        SetEntityHealth(client, hidden_hp);
                    }
                }

                if (hidden_invisibility > 0.0)
                {
                    // using hidden_jump_blocker for now..
                    // this prevents cloak draining until the hidden can move
                    if (!hidden_jump_blocker)
                    {
                        hidden_invisibility -= tick_interval;
                        if (hidden_invisibility < 0.0)
                        {
                            hidden_invisibility = 0.0;
                            ForcePlayerSuicide(client);
                            PrintToChatAll("\x04[%s] \x01The Hidden starved \
                                and died violently!", PLUGIN_NAME);
                        }
                    }
                }

                if (hidden_visible > 0.0)
                {
                    hidden_visible -= tick_interval;
                    if (hidden_visible < 0.0)
                    {
                        hidden_visible = 0.0;
                    }
                }

                if (hidden_invisibility > 0.0)
                {
                    if (hidden_visible <= 0.0)
                    {
                        if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked))
                        {
                            if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
                            {
                                TF2_RemoveCondition(client, TFCond_Cloaked);
                            }
                            else
                            {
                                TF2_AddCondition(client, TFCond_Cloaked, -1.0);
                            }
                        }
                    }
                    else
                    {
                        TF2_RemoveCondition(client, TFCond_Cloaked);
                    }
                }
                else
                {
                    TF2_RemoveCondition(client, TFCond_Cloaked);
                }

                if (hidden_stuck)
                {
                    hidden_stamina -= tick_interval;
                    if (hidden_stamina <= 0.0)
                    {
                        hidden_stamina = 0.0;
                        hidden_stuck = false;
                        HiddenUnstick();
                    }
                    else if (GetEntityMoveType(client) == MOVETYPE_WALK)
                    {
                        SetEntityMoveType(client, MOVETYPE_NONE);
                    }
                }
                else
                {
                    HiddenUnstick();
                    if (hidden_stamina < HIDDEN_STAMINA_TIME)
                    {
                        hidden_stamina += tick_interval / 2;
                        if (hidden_stamina > HIDDEN_STAMINA_TIME)
                        {
                            hidden_stamina = HIDDEN_STAMINA_TIME;
                        }
                    }
                }

                new eflags = GetEntityFlags(client);
                if (eflags & FL_ONGROUND || hidden_stuck)
                {
                    if (hidden_jump > 0.0)
                    {
                        hidden_jump -= tick_interval;
                        if (hidden_jump < 0.0)
                        {
                            hidden_jump = 0.0;
                        }
                    }
                }

                if (hidden_boo_charge < 100.0)
                {
                    hidden_boo_charge += tick_interval * 4;
                    if (hidden_boo_charge > 100.0)
                    {
                        hidden_boo_charge = 100.0;
                    }
                }

                TF2_RemovePlayerDisguise(client);
                TF2_RemoveCondition(client, TFCond_DeadRingered);
                TF2_RemoveCondition(client, TFCond_Kritzkrieged);
                TF2_RemoveCondition(client, TFCond_MarkedForDeath);
                if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
                {
                    MakeHiddenVisible(0.5);
                    TF2_RemoveCondition(client, TFCond_OnFire);
                    GiveHiddenVision(client);
                }
                if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
                {
                    TF2_RemoveCondition(client, TFCond_Ubercharged);
                    GiveHiddenVision(client);
                }
                if (TF2_IsPlayerInCondition(client, TFCond_Jarated))
                {
                    MakeHiddenVisible(3.0);
                    TF2_RemoveCondition(client, TFCond_Jarated);
                    GiveHiddenVision(client);
                }
                if (TF2_IsPlayerInCondition(client, TFCond_Bleeding))
                {
                    MakeHiddenVisible(2.0);
                    TF2_RemoveCondition(client, TFCond_Bleeding);
                    GiveHiddenVision(client);
                }
                if (TF2_IsPlayerInCondition(client, TFCond_Milked))
                {
                    MakeHiddenVisible(3.0);
                    TF2_RemoveCondition(client, TFCond_Milked);
                }
                if (TF2_IsPlayerInCondition(client, TFCond_Bonked))
                {
                    MakeHiddenVisible(3.0);
                    TF2_RemoveCondition(client, TFCond_Bonked);
                }

                SetEntPropFloat(client, Prop_Send, "m_flCloakMeter",
                    hidden_invisibility / HIDDEN_INVISIBILITY_TIME * 100.0);

                SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
            }
            else // client != hidden
            {
                SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
            }
        }
    }
}

/*************************************************************************/

public Action:Timer_Tick(Handle:timer)
{
    DisplayHealthAndInfo(TICK_INTERVAL);
}

stock DisplayHealthAndInfo(Float:duration)
{
    if (activated && (hidden != 0))
    {
        duration += TICK_INTERVAL;

        new Float:percentage_remaining = ((float(hidden_hp))
            / (float(game_defined_hidden_max_health))) * 100.0;

        new Float:x_coord = -1.0;
        new Float:y_coord = 0.2;
        new Float:hold_time = duration;
        new red_amount;
        new green_amount;
        new blu_amount;
        new alpha_amount;

        LOOP_CLIENTS(client, CLIENTFILTER_INGAME)
        {
            red_amount = (RoundFloat((100 - percentage_remaining) * 2.25));
            green_amount = RoundFloat(percentage_remaining * 2.25);
            blu_amount = 0;
            alpha_amount = 255;

            if (client == hidden && (hide_text_due_to_scores[client] == 0))
            {
                SetHudTextParams(x_coord, y_coord, hold_time,
                    red_amount, green_amount, blu_amount, alpha_amount);
                if ((amount_yet_to_heal > 0) && (heal_per_second > 0))
                {
                    new Float:percentage_heal = ((float(heal_per_second))
                        / (float(game_defined_hidden_max_health))) * 100.0;

                    ShowHudText(client, 0, "Hidden Health: %.1f%% +%.1f%%/sec",
                        percentage_remaining, percentage_heal);
                }
                else
                {
                    ShowHudText(client, 0, "Hidden Health: %.1f%%",
                        percentage_remaining);
                }

                // show the hiddens other lines of text without colour
                red_amount = 255;
                green_amount = 255;
                blu_amount = 255;

                // stamina
                x_coord = -1.0;
                y_coord = 0.225;

                new Float:percentage_stamina = (hidden_stamina
                        / HIDDEN_STAMINA_TIME) * 100.0;

                if (percentage_stamina != 100.0)
                {
                    SetHudTextParams(x_coord, y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);
                    ShowHudText(client, 1, "Stamina: %.1f%%",
                        percentage_stamina);

                    y_coord += 0.025;
                }

                if (hidden_boo_charge != 100.0)
                {
                    new amount = RoundFloat(hidden_boo_charge * 1.5);
                    red_amount = amount;
                    green_amount = amount;
                    blu_amount = amount;
                    SetHudTextParams(x_coord, y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);
                    ShowHudText(client, 2, "Boo: Charging");

                    new Float:dots_x_coord = 0.555;
                    new Float:dots_y_coord = y_coord;

                    decl String:dots[32];
                    if (number_of_charging_dots == 3)
                    {
                        Format(dots, sizeof(dots), "...", client);
                    }
                    else if (number_of_charging_dots == 2)
                    {
                        Format(dots, sizeof(dots), "..", client);
                    }
                    else if (number_of_charging_dots == 1)
                    {
                        Format(dots, sizeof(dots), ".", client);
                    }
                    else
                    {
                        Format(dots, sizeof(dots), " ", client);
                    }
                    SetHudTextParams(dots_x_coord, dots_y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);

                    ShowHudText(client, 3, dots);
                    CreateTimer(5.0, Timer_Update_Dots, client);
                }
                else
                {
                    red_amount = 255;
                    green_amount = 255;
                    blu_amount = 255;
                    alpha_amount = 255;

                    SetHudTextParams(x_coord, y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);
                    ShowHudText(client, 4, "Boo: Charged");
                }

                if (display_hidden_hud_tip)
                {
                    x_coord = -1.0;
                    y_coord += 0.025;
                    red_amount = 255;
                    green_amount = 255;
                    blu_amount = 255;
                    alpha_amount = 255;

                    CreateTimer(0.1, Timer_Hidden_Hud_Tip, client);
                    SetHudTextParams(x_coord, y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);
                    PrintHintText(client,
                        "press R to use boo - Right-click to pounce - !cb for Nades");
                }
            }
            else if (hide_text_due_to_scores[client] == 0)
            {
                if (percentage_remaining != 100.0)
                {
                    SetHudTextParams(x_coord, y_coord, hold_time,
                        red_amount, green_amount, blu_amount, alpha_amount);
                    ShowHudText(client, 0, "Hidden Health: %.1f%%",
                        percentage_remaining);
                }
            }
        }
    }
}

public Action:Timer_Heal_Hidden(Handle:timer, any:data)
{
    HealHidden();
}

stock HealHidden()
{
    if (activated && (hidden != 0))
    {
        heal_per_second = RoundFloat(HIDDEN_HP_PER_KILL / HIDDEN_HP_REGEN_TIME);
        hidden_hp += heal_per_second;
        if (hidden_hp > game_defined_hidden_max_health)
        {
            hidden_hp = game_defined_hidden_max_health;
        }
        amount_yet_to_heal -= heal_per_second; 
        if (amount_yet_to_heal < 0)
        {
            amount_yet_to_heal = 0;
        }
        if (amount_yet_to_heal > 0)
        {
            CreateTimer(1.0, Timer_Heal_Hidden, hidden);
        }
    }
}

public Action:Timer_Dissolve(Handle:timer, any:data)
{
    Dissolve(data, 3);
}

stock Dissolve(client, type)
{
    new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll < 0)
    {
        return;
    }

    decl String:dname[32], String:dtype[32];
    Format(dname, sizeof(dname), "dis_%d", client);
    Format(dtype, sizeof(dtype), "%d", type);

    new ent = CreateEntityByName("env_entity_dissolver");
    if (ent > 0)
    {
        DispatchKeyValue(ragdoll, "targetname", dname);
        DispatchKeyValue(ent, "dissolvetype", dtype);
        DispatchKeyValue(ent, "target", dname);
        DispatchKeyValue(ent, "magnitude", "10");
        AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
        AcceptEntityInput(ent, "Kill");
    }
}

stock SetGameDescription()
{
    decl String:game_desc[64];

    if (activated)
    {
        Format(game_desc, sizeof(game_desc),
            "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
    }
    else
    {
        game_desc = "Team Fortress";
    }
    Steam_SetGameDescription(game_desc);
    PrintToServer("[%s] Set server description to: \"%s\"",
        PLUGIN_NAME, game_desc);
}

public Action:Timer_DisableCps(Handle:timer)
{
    DisableCps();
}

stock DisableCps()
{
    new i = -1;
    new CP = 0;
    for (new n = 0; n <=16; n++)
    {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP))
        {
            AcceptEntityInput(CP, "Disable");
            i = CP;
        }
        else
        {
            break;
        }
    }
}

stock bool:IsArenaMap()
{
    decl String:curMap[64];
    GetCurrentMap(curMap, sizeof(curMap));
    if (strncmp("arena_", curMap, 6, false) == 0)
        return true;
    else
    {
        PrintToServer("[%s] This map is not suitable. \
            The Plugin only supports Arena maps.", PLUGIN_NAME);
        PrintToServer("[%s] Most of the plugin has been disabled however \
            you should consider running !sm_hidden_disable", PLUGIN_NAME);
        return false;
    }
}

stock MakeHiddenVisible(Float:value)
{
    if (hidden_visible < value)
    {
        hidden_visible = value;
    }
}

stock GiveHiddenVision(client)
{
    OverlayCommand(client, HIDDEN_OVERLAY);
}

stock RemoveHiddenVision(client)
{
    OverlayCommand(client, "\"\"");
}

stock OverlayCommand(client, String:overlay[])
{
    SetCommandFlags("r_screenoverlay",
        GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
    ClientCommand(client, "r_screenoverlay %s", overlay);
}

stock HiddenBoo()
{
    if (activated && (hidden != 0))
    {
        if (hidden_boo_charge == 100.0)
        {
            decl Float:pos[3];
            decl Float:eye[3];
            decl Float:pos2[3];
            GetClientAbsOrigin(hidden, pos);
            GetClientEyePosition(hidden, eye);

            MakeHiddenVisible(1.5);
            LOOP_CLIENTS(client, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE|CLIENTFILTER_NOSPECTATORS)
            {
                if (client != hidden)
                {
                    GetClientAbsOrigin(client, pos2);
                    if (GetVectorDistance(pos, pos2, false) < 350)
                    {
                        TF2_MakeBleed(client, hidden, 1.0);

                        decl Float:angle[3];
                        decl Float:velocity[3];
                        GetClientEyeAngles(client, angle);
                        angle[0] = -45.0;

                        GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
                        decl Float:temp[3];
                        GetAngleVectors(angle, temp, NULL_VECTOR, NULL_VECTOR);
                        velocity[0] += temp[0] * 450.0;
                        velocity[1] += temp[1] * 450.0;
                        velocity[2] += temp[2] * 450.0;

                        new flags = GetEntityFlags(client);
                        if (flags & FL_ONGROUND)
                        {
                            flags &= ~FL_ONGROUND;
                        }
                        SetEntityFlags(client, flags);
                        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

                        TF2_StunPlayer(client, HIDDEN_BOO_STUN_DURATION,
                            _, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_THIRDPERSON, hidden);
                    }
                }
            }
            new targets[MAX_PLAYERS];
            targets[0] = hidden;
            EmitSound(targets, 1, HIDDEN_BOO_FILE, SOUND_FROM_PLAYER,
                _, _, _, _, _, hidden, eye);
            hidden_boo_charge = 0.0;
        }
    }
}

public bool:TraceRay_HitWorld(entityhit, mask)
{
    return entityhit == 0;
}

stock HiddenStick()
{
    if (activated && (hidden != 0))
    {
        decl Float:position[3];
        decl Float:angle[3];
        GetClientEyeAngles(hidden, angle);
        GetClientEyePosition(hidden, position);
        new Handle:ray = TR_TraceRayFilterEx(position, angle, MASK_ALL,
            RayType_Infinite, TraceRay_HitWorld);
        if (TR_DidHit(ray))
        {
            decl Float:position_two[3];
            TR_GetEndPosition(position_two, ray);
            if (GetVectorDistance(position, position_two) < 64.0)
            {
                if (hidden_stuck || hidden_stamina
                    < (HIDDEN_STAMINA_TIME * 0.7))
                {
                    CloseHandle(ray);
                    return 0;
                }

                hidden_stuck = true;
                if (GetEntityMoveType(hidden) != MOVETYPE_NONE)
                {
                    SetEntityMoveType(hidden, MOVETYPE_NONE);
                }
                CloseHandle(ray);
                return 1;
            }
            else
            {
                CloseHandle(ray);
                return -1;
            }
        }
        else
        {
            CloseHandle(ray);
            return -1;
        }
    }
    return 0;
}

public HiddenUnstick()
{
    hidden_stuck = false;
    if (GetEntityMoveType(hidden) == MOVETYPE_NONE)
    {
        SetEntityMoveType(hidden, MOVETYPE_WALK);
        new Float:velocity[3];
        TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, velocity);
    }
}

stock bool:HiddenSuperJump()
{
    if (activated && (hidden != 0) && (!hidden_jump_blocker))
    {
        if (HiddenStick() == -1)
        {
            if (hidden_jump == 0.0)
            {
                hidden_jump = HIDDEN_JUMP_TIME;
                HiddenUnstick();

                decl Float:angle[3];
                decl Float:velocity[3];
                GetClientEyeAngles(hidden, angle);
                GetEntPropVector(hidden, Prop_Data,
                    "m_vecAbsVelocity", velocity);
                decl Float:temp[3];
                GetAngleVectors(angle, temp, NULL_VECTOR, NULL_VECTOR);
                velocity[0] += temp[0] * 750.0;
                velocity[1] += temp[1] * 750.0;
                velocity[2] += temp[2] * 750.0;

                new flags = GetEntityFlags(hidden);
                if (flags & FL_ONGROUND)
                {
                    flags &= ~FL_ONGROUND;
                }
                SetEntityFlags(hidden, flags);

                TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, velocity);

                MakeHiddenVisible(0.5);

                new random = GetRandomInt(1,100);
                if (random == 1)
                {
                    decl Float:eye[3];
                    GetClientEyePosition(hidden, eye);
                    new targets[MAX_PLAYERS];
                    targets[0] = hidden;
                    EmitSound(targets, 1, HIDDEN_JUMP_FILE, SOUND_FROM_PLAYER,
                        _, _, _, _, _, hidden, eye);
                }

                return true;
            }
        }
    }
    return false;
}

public Action:Timer_Hidden_Hud_Tip(Handle:timer)
{
    display_hidden_hud_tip = false;
}

public Action:Timer_Update_Dots(Handle:timer)
{
    number_of_charging_dots += 1;
    if (number_of_charging_dots > 3)
    {
        number_of_charging_dots = 0;
    }
}

public Action:Timer_Hidden_Round_Start_Speech(Handle:timer)
{
    if (hidden != 0)
    {
        decl Float:eye[3];
        GetClientEyePosition(hidden, eye);
        new targets[MAX_PLAYERS];
        targets[0] = hidden;

        new random = GetRandomInt(1,3);
        switch (random)
        {
            case 1:
            {
                EmitSoundToAll(HIDDEN_ROUND_START_FILE_ONE, SOUND_FROM_PLAYER,
                    _, _, _, _, _, hidden, eye);
            }
            case 2:
            {
                EmitSoundToAll(HIDDEN_ROUND_START_FILE_TWO, SOUND_FROM_PLAYER,
                    _, _, _, _, _, hidden, eye);
            }
            case 3:
            {
                EmitSoundToAll(HIDDEN_ROUND_START_FILE_THREE, SOUND_FROM_PLAYER,
                    _, _, _, _, _, hidden, eye);
            }
        }
    }
}

public Action:Timer_Hidden_Final_Speech(Handle:timer)
{
    HiddenFinalSpeech();
}

stock HiddenFinalSpeech()
{
    decl Float:eye[3];
    GetClientEyePosition(hidden, eye);
    LOOP_CLIENTS(client, CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE|CLIENTFILTER_NOSPECTATORS)
    {
        if (client != hidden)
        {
            new TFClassType:class = TF2_GetPlayerClass(client);
            if (class == TFClass_Scout)
            {
                EmitSoundToAll(HIDDEN_SCOUT_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Soldier)
            {
                EmitSoundToAll(HIDDEN_SOLDIER_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Pyro)
            {
                EmitSoundToAll(HIDDEN_PYRO_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_DemoMan)
            {
                EmitSoundToAll(HIDDEN_DEMO_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Heavy)
            {
                EmitSoundToAll(HIDDEN_HEAVY_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Engineer)
            {
                EmitSoundToAll(HIDDEN_ENGY_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Medic)
            {
                EmitSoundToAll(HIDDEN_MEDIC_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
            else if (class == TFClass_Sniper)
            {
                EmitSoundToAll(HIDDEN_SNIPER_FINAL_FILE,
                SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
            }
        }
    }
}

public Action:Timer_GenericTip(Handle:Timer)
{
    PrintToChatAll("\x04[%s] \x01%s", PLUGIN_NAME, generic_tips[tip_counter]);
    tip_counter += 1;
    if (tip_counter >= TOTAL_TIPS)
    {
        tip_counter = 0;
    }
}

public Action:Timer_GenericStats(Handle:Timer)
{
    new client = 0;
    new highest_kills = 0;

    if (!last_shown_kills_as)
    {
        for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        {
            if (highest_kills == kills_as_hidden[i])
            {
                client = 0;
            }
            if (kills_as_hidden[i] > highest_kills) 
            {
                highest_kills = kills_as_hidden[i];
                client = i;
            }
        }
        
        if ((client != 0) && (highest_kills > 0))
        {
            // dont display this if they are currently playing the hidden
            if (client != hidden)
            {
                decl String:client_name[64];
                GetClientName(client, client_name, 64);
                PrintToChatAll("\x04[%s] \x03%s \x01currently holds the \
                    record for the most kills as \x03The Hidden\x01 \
                    in a single life with\x03 %d\x01!",
                    PLUGIN_NAME, client_name, highest_kills);
            }
        }

        last_shown_kills_as = true;
    }
    else
    {
        for (new i = 1; i < MAX_PLAYERS + 1; ++i)
        {
            if (highest_kills == kills_as_hidden[i])
            {
                client = 0;
            }
            if (kills_of_hidden[i] > highest_kills) 
            {
                highest_kills = kills_of_hidden[i];
                client = i;
            }
        }

        if ((client != 0) && (highest_kills > 0))
        {
            decl String:client_name[64];
            GetClientName(client, client_name, 64);
            PrintToChatAll("\x04[%s] \x03%s \x01hold the record \
                for killing \x03The Hidden \x01\x03%d\x01 times!",
                PLUGIN_NAME, client_name, highest_kills);
        }

        last_shown_kills_as = false;
    }
}


/******************************************************************/