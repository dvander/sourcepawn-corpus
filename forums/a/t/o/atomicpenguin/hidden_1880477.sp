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
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#include <smlib>

#define PLUGIN_AUTHOR "atomic-penguin, daniel-murray"
#define PLUGIN_VERSION "2.11.6"
#define PLUGIN_NAME "TF2 Hidden"
#define PLUGIN_DESCRIPTION "Hidden:Source-like mod for TF2"
#define PLUGIN_URL "https://github.com/atomic-penguin/sm-hidden"

#define TICK_INTERVAL 0.1

#define HIDDEN_HP 500
#define HIDDEN_HP_PER_PLAYER 50
#define HIDDEN_HP_PER_KILL 75
#define HIDDEN_INVISIBILITY_TIME 100.0
#define HIDDEN_STAMINA_TIME 10.0 
#define HIDDEN_JUMP_TIME 0.5
#define HIDDEN_AWAY_TIME 15.0
#define HIDDEN_BOO
#define HIDDEN_BOO_TIME 20.0
#define HIDDEN_BOO_DURATION 3.5
#define HIDDEN_BOO_VISIBLE 1.5
#define HIDDEN_BOO_FILE "vo/taunts/spy_taunts06.wav"
#define HIDDEN_OVERLAY "effects/combine_binocoverlay"
#define HIDDEN_COLOR {0, 0, 0, 3}

#define PLAYER_FIRSTBLOOD (1 << 11)

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

enum HTeam {
    HTeam_Unassigned = TFTeam_Unassigned,
    HTeam_Spectator = TFTeam_Spectator,
    HTeam_Hidden = TFTeam_Blue,
    HTeam_Iris = TFTeam_Red
}

new hidden=0;
new hiddenHp;
new hiddenHpMax;
new bool:hiddenStick;
new Float:hiddenStamina;
new Float:hiddenInvisibility;
new Float:hiddenVisible;
new Float:hiddenJump;
new bool:hiddenAway;
new Float:hiddenAwayTime;
new TFClassType:g_hiddenSavedClass=TFClass_Unknown;
new TFClassType:g_lastHiddenSavedClass=TFClass_Unknown;
new g_lastHidden=0;
#if defined HIDDEN_BOO
    new Float:hiddenBoo;
#endif
new bool:newHidden;
new bool:playing = false; 
new bool:activated = false; // whether plugin is activated
new forceNextHidden = 0;
new Handle:t_disableCps;
new Handle:t_tick;
new Handle:cv_enabled; // Internal for sm_hidden_enabled
new Handle:cv_hidden_alltalk; // Internal for sm_hidden_alltalk
new Handle:cv_hidden_visible_damage; //Internal for sm_hidden_visible_damage
new Handle:cv_hidden_visible_jarate; //Internal for sm_hidden_visible_jarate
new Handle:cv_hidden_visible_pounce; //Internal for sm_hidden_visible_pounce
new Handle:cv_allowpyro;
new Handle:cv_allowengineer;

#if defined _steamtools_included
new bool:steamtools = false;
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
#if defined _steamtools_included
    MarkNativeAsOptional("Steam_SetGameDescription");
#endif
    return APLRes_Success;
}

public OnPluginStart() {
    LoadTranslations("common.phrases");
    new Handle:cv_version = CreateConVar("sm_tf2hidden_version", PLUGIN_VERSION, "SM TF2 Hidden version", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY); 
    cv_enabled = CreateConVar("sm_hidden_enabled", "1", "Enables/disables the plugin.", 0, true, 0.0, true, 1.0);
    cv_hidden_alltalk = CreateConVar("sm_hidden_alltalk", "1", "Turn alltalk on and voice icons off.", 0, true, 0.0, true, 1.0);
    cv_allowpyro = CreateConVar("sm_hidden_allowpyro", "1", "Set whether pyro is allowed on team IRIS", 0, true, 0.0, true, 1.0);
    cv_allowengineer = CreateConVar("sm_hidden_allowengineer", "1", "Set whether engineer is allowed on team IRIS", 0, true, 0.0, true, 1.0);
    cv_hidden_visible_damage = CreateConVar("sm_hidden_visible_damage", "0.5", "Amount of time (seconds) Hidden is visible when taking weapon damage.", 0, true, 0.0, true, 3.0);
    cv_hidden_visible_jarate = CreateConVar("sm_hidden_visible_jarate", "1.0", "Amount of time (seconds) Hidden is visible when splashed with jarate, mad milk, or bonked.", 0, true, 0.0, true, 3.0);
    cv_hidden_visible_pounce = CreateConVar("sm_hidden_visible_pounce", "0.25", "Amount of time (seconds) Hidden is visible when pouncing.", 0, true, 0.0, true, 3.0);

    // Auto-create the config file
    AutoExecConfig(true, "plugin.hidden");

    HookConVarChange(cv_enabled, cvhook_enabled);
    HookConVarChange(cv_hidden_alltalk, cvhook_hidden_alltalk);
    HookConVarChange(cv_allowpyro, cvhook_allowpyro);
    HookConVarChange(cv_allowengineer, cvhook_allowengineer);
   
    RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces the next hidden to be certain player");
    RegAdminCmd("sm_hidden_enable", Command_EnableHidden, ADMFLAG_CONVARS, "Changes the sm_hidden_enabled cvar to 1");
    RegAdminCmd("sm_hidden_disable", Command_DisableHidden, ADMFLAG_CONVARS, "Changes the sm_hidden_enabled cvar to 0");

#if defined _steamtools_included
    steamtools = LibraryExists("SteamTools");
#endif

    SetConVarString(cv_version, PLUGIN_VERSION);
}

public OnPluginEnd() {
    if (!activated) return;
    LOOP_CLIENTS(client, CLIENTFILTER_INGAME) {
        RemoveHiddenVision(client);
    }
}

public OnLibraryAdded(const String:name[]) {
#if defined _steamtools_included
    if (strcmp(name, "SteamTools", false) == 0) {
        steamtools = true;
    }
#endif
}

public OnLibraryRemoved(const String:name[]) {
#if defined _steamtools_included
    if (strcmp(name, "SteamTools", false) == 0) {
         steamtools = false;
    }
#endif
}

public OnConfigsExecuted() {
    new bool:cvar_enabled=GetConVarBool(cv_enabled);
    if (cvar_enabled && IsArenaMap()) {
        ActivatePlugin();
    } else if (!cvar_enabled || !IsArenaMap()) {
        DeactivatePlugin();
    }
    if (steamtools) SetGameDescription(); 
}

public OnMapStart() {
    //playing=true;
    PrecacheSound(HIDDEN_BOO_FILE, true);
    new bool:cvar_enabled=GetConVarBool(cv_enabled);
    if (cvar_enabled && IsArenaMap()) {
        ActivatePlugin();
    } else if (!cvar_enabled || !IsArenaMap()) {
        DeactivatePlugin();
    }
    if (steamtools) SetGameDescription();
}

public OnMapEnd() {
    new bool:cvar_enabled=GetConVarBool(cv_enabled);
    if (cvar_enabled && activated) {
        DeactivatePlugin();
    }
    if (steamtools) SetGameDescription();
}

stock ActivatePlugin() {
    new bool:cvar_enabled=GetConVarBool(cv_enabled);
    if (cvar_enabled && activated) return;
    activated=true;
    
    t_tick = CreateTimer(TICK_INTERVAL, Timer_Tick, _, TIMER_REPEAT);
    t_disableCps = CreateTimer(5.0, Timer_DisableCps, _, TIMER_REPEAT);
    
    HookEvent("teamplay_round_start", teamplay_round_start);
    HookEvent("teamplay_round_win", teamplay_round_win);
    HookEvent("teamplay_round_active", teamplay_round_active);
    HookEvent("arena_round_start", teamplay_round_active);
    
    HookEvent("player_team", player_team);
    HookEvent("player_spawn", player_spawn);
    HookEvent("player_hurt", player_hurt);
    HookEvent("player_death", player_death);

    AddCommandListener(Cmd_build, "build");
    SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
    SetConVarInt(FindConVar("tf_arena_override_team_size"), 17);
    SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
    SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
    SetConVarInt(FindConVar("mp_forcecamera"), 0);
}

stock DeactivatePlugin() {
    new bool:cvar_enabled=GetConVarBool(cv_enabled);
    if (!cvar_enabled || !activated) return;
    activated=false;
    
    KillTimer(t_tick);
    KillTimer(t_disableCps);
    
    UnhookEvent("teamplay_round_start", teamplay_round_start);
    UnhookEvent("teamplay_round_win", teamplay_round_win);
    UnhookEvent("teamplay_round_active", teamplay_round_active);
    UnhookEvent("arena_round_start", teamplay_round_active);
    
    UnhookEvent("player_team", player_team);
    UnhookEvent("player_spawn", player_spawn);
    UnhookEvent("player_hurt", player_hurt);
    UnhookEvent("player_death", player_death);

    RemoveCommandListener(Cmd_build, "build");
    SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
    SetConVarInt(FindConVar("tf_arena_override_team_size"), 0);
    SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
    SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
    SetConVarInt(FindConVar("mp_forcecamera"), 1);
}

public cvhook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (IsArenaMap() && GetConVarBool(cvar)) {
        ActivatePlugin();
    } else {
        DeactivatePlugin();
    }
}

public cvhook_hidden_alltalk(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (!activated) return;
    if (GetConVarBool(cvar)) {
        ServerCommand("sv_alltalk 1");
        ServerCommand("mp_show_voice_icons 0");
    } else {
        ServerCommand("sv_alltalk 0");
        ServerCommand("mp_show_voice_icons 1");
    }
}

public cvhook_allowpyro(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (!activated) return;
    new bool:cvar_allowpyro = GetConVarBool(cvar);
    if (cvar_allowpyro) {
        PrintToChatAll("\x04[%s]\x01 Class: \x03Pyro\x01 is now allowed on team IRIS", PLUGIN_NAME);
    } else {
        PrintToChatAll("\x04[%s]\x01 Class: \x03Pyro\x01 is no longer allowed on team IRIS", PLUGIN_NAME);
    }
}

public cvhook_allowengineer(Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (!activated) return;
    new bool:cvar_allowengineer = GetConVarBool(cvar);
    if (cvar_allowengineer) {
        PrintToChatAll("\x04[%s]\x01 Class: \x03Engineer\x01 is now allowed on team IRIS", PLUGIN_NAME);
    } else {
        PrintToChatAll("\x04[%s]\x01 Class: \x03Engineer\x01 is no longer allowed on team IRIS", PLUGIN_NAME);
    }
}

public OnGameFrame() {
    if (!activated) return;
    if (!CanPlay()) return;
    
    new Float:tickInterval = GetTickInterval();
    new Float:f_hiddenVisibleDamage = GetConVarFloat(cv_hidden_visible_damage);
    new Float:f_hiddenVisibleJarate = GetConVarFloat(cv_hidden_visible_jarate);

    LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS|CLIENTFILTER_NOSPECTATORS) {
        if (client==hidden) {
            if (GetClientHealth(client)>0) {
                if (hiddenHp>HIDDEN_HP) {
                    SetEntityHealth(client, HIDDEN_HP);
                } else {
                    SetEntityHealth(client, hiddenHp);
                }
            }

            SetEntDataFloat(hidden, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0, true);

            if (newHidden) {
                newHidden=false;
                CreateTimer(0.5, Timer_GiveHiddenPowers, GetClientUserId(client));
            }

            if (hiddenAway) {
                hiddenAwayTime+=tickInterval;
                if (hiddenAwayTime>HIDDEN_AWAY_TIME) {
                    ForcePlayerSuicide(client);
                    PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 was killed because he was away", PLUGIN_NAME);
                    continue;
                }
            }

            new eflags=GetEntityFlags(client);

            // Save checking for these conditions, always do them.
            TF2_RemovePlayerDisguise(client);
            TF2_RemoveCondition(client, TFCond_DeadRingered);
            TF2_RemoveCondition(client, TFCond_Kritzkrieged);
            TF2_RemoveCondition(client, TFCond_MarkedForDeath);

            if (hiddenInvisibility>0.0) {
                hiddenInvisibility-=tickInterval;
                if (hiddenInvisibility<0.0) {
                    hiddenInvisibility=0.0;
                    ForcePlayerSuicide(client);
                    PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 lost his powers!", PLUGIN_NAME);
                    continue;
                }
            }

            #if defined HIDDEN_BOO
                if (hiddenBoo>0.0) {
                    hiddenBoo-=tickInterval;
                    if (hiddenBoo<0.0) {
                        hiddenBoo=0.0;
                    }
                }
            #endif

            if (!hiddenStick) {
                HiddenUnstick();
                if (hiddenStamina<HIDDEN_STAMINA_TIME) {
                    hiddenStamina+=tickInterval/2;
                    if (hiddenStamina>HIDDEN_STAMINA_TIME) {
                        hiddenStamina=HIDDEN_STAMINA_TIME;
                    }
                }
            } else {
                hiddenStamina-=tickInterval;
                if (hiddenStamina<=0.0) {
                    hiddenStamina=0.0;
                    hiddenStick=false;
                    HiddenUnstick();
                } else if (GetEntityMoveType(client)==MOVETYPE_WALK) {
                    SetEntityMoveType(client, MOVETYPE_NONE);
                }
            }

            if (eflags & FL_ONGROUND || hiddenStick) {
                if (hiddenJump>0.0) {
                    hiddenJump-=tickInterval;
                    if (hiddenJump<0.0) {
                        hiddenJump=0.0;
                    }
                }
            }

            if (hiddenVisible>0.0) {
                hiddenVisible-=tickInterval;
                if (hiddenVisible<0.0) {
                    hiddenVisible=0.0;
                }
            }

            if (hiddenInvisibility>0.0) {
                if (hiddenVisible<=0.0) {
                    if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked)) {
                        TF2_AddCondition(client, TFCond_Cloaked, -1.0);
                    }
                } else {
                    TF2_RemoveCondition(client, TFCond_Cloaked);
                }
            } else {
                TF2_RemoveCondition(client, TFCond_Cloaked);
            }

            if (TF2_IsPlayerInCondition(client, TFCond_OnFire)) {
                AddHiddenVisible(f_hiddenVisibleDamage);
                TF2_RemoveCondition(client, TFCond_OnFire);
                GiveHiddenVision(client);
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) {
                TF2_RemoveCondition(client, TFCond_Ubercharged);
                GiveHiddenVision(client);
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Jarated)) {
                AddHiddenVisible(f_hiddenVisibleJarate);
                TF2_RemoveCondition(client, TFCond_Jarated);
                GiveHiddenVision(client);
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Milked)) {
                AddHiddenVisible(f_hiddenVisibleJarate);
                TF2_RemoveCondition(client, TFCond_Milked);
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Bonked)) {
                AddHiddenVisible(f_hiddenVisibleJarate);
                TF2_RemoveCondition(client, TFCond_Bonked);
            }
            
            if (TF2_IsPlayerInCondition(client, TFCond_Bleeding)) {
                AddHiddenVisible(f_hiddenVisibleDamage);
                TF2_RemoveCondition(client, TFCond_Bleeding);
                GiveHiddenVision(client);
            }

            SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", hiddenInvisibility/HIDDEN_INVISIBILITY_TIME*100.0);
            
            if (GetEntProp(client, Prop_Send, "m_bGlowEnabled")) {
                SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
            }
        } else if (client != hidden) {
            if (HTeam:GetClientTeam(client) == HTeam_Hidden) {
                ChangeClientTeam(client, _:HTeam_Iris);
            }

            if (!GetEntProp(client, Prop_Send, "m_bGlowEnabled")) {
                SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
            }
        }
    }
}

public Action:teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=true;
    CreateTimer(0.5, Timer_ResetHidden);
}

public Action:teamplay_round_active(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=true;
}

public Action:teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
    playing=false;
    CreateTimer(0.1, Timer_NewGame);
}

public Action:Timer_DisableCps(Handle:timer) {
    DisableCps();
}

public Action:Timer_NewGame(Handle:timer) {
    NewGame();
}

public Action:player_team(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !Client_IsIngame(client)) return;
    if (IsFakeClient(client)) return;

    new HTeam:team = HTeam:GetEventInt(event, "team");

    if (client != hidden && team==HTeam_Hidden) {
        ChangeClientTeam(client, _:HTeam_Iris);
    } else if (client == hidden && team==HTeam_Iris) {
        ChangeClientTeam(client, _:HTeam_Hidden);
    }
}

public Action:player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new TFClassType:class = TF2_GetPlayerClass(client);
    new bool:cvar_allowpyro = GetConVarBool(cv_allowpyro);
    new bool:cvar_allowengineer = GetConVarBool(cv_allowengineer);
    
    if ((client==hidden) && (class!=TFClass_Spy)) {
        ChangeClientTeam(client, _:HTeam_Hidden);
        TF2_SetPlayerClass(client, TFClass_Spy, false, true);
        newHidden=true;
        CreateTimer(0.1, Timer_Respawn, client);
    } else if (client!=hidden) {
        if ((client==g_lastHidden) && (g_lastHiddenSavedClass!=TFClass_Unknown)) { //if we haven't set them to their pre-hidden class choice
            ChangeClientTeam(client, _:HTeam_Iris);
            TF2_SetPlayerClass(client, g_lastHiddenSavedClass, false, true);
            g_lastHiddenSavedClass=TFClass_Unknown;
            g_lastHidden=0;
            CreateTimer(0.1, Timer_Respawn, client);
        } else if (class==TFClass_Unknown || class==TFClass_Spy || ((class==TFClass_Engineer) && (!cvar_allowengineer)) || ((class==TFClass_Pyro) && (!cvar_allowpyro))) {
            ChangeClientTeam(client, _:HTeam_Iris);
            TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
            PrintToChat(client, "\x04[%s]\x01 You cannot use this class on team IRIS", PLUGIN_NAME);
            CreateTimer(0.1, Timer_Respawn, client);
        }
    }
}

public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast) {
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    if (victim!=hidden) return;
    
    new damage = GetEventInt(event, "damageamount");
    hiddenHp-=damage;

    if (hiddenHp<0) hiddenHp=0;
   
    if (hiddenHp>500) {
        SetEntityHealth(hidden, 500);
    } else if (hiddenHp>0) {
        SetEntityHealth(hidden, hiddenHp);
    }
}

public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast) {
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (!playing) return;
 
    if (victim==hidden) {
        hiddenHp=0;
        RemoveHiddenPowers(victim);
        if (Client_IsIngame(attacker) && attacker!=hidden) {
            forceNextHidden = GetClientUserId(attacker);
            PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 was killed by \x03%N\x01!", PLUGIN_NAME, attacker); 
        }
    } else {
        if (Client_IsIngame(hidden) && attacker==hidden) {

            // Remove firstblood crit
            new attacker_cond = GetEntProp(attacker, Prop_Send, "m_nPlayerCond");
            SetEntProp(attacker, Prop_Send, "m_nPlayerCond", attacker_cond & ~PLAYER_FIRSTBLOOD);
                
            hiddenInvisibility+=HIDDEN_INVISIBILITY_TIME*0.35;
            if (hiddenInvisibility>HIDDEN_INVISIBILITY_TIME) {
                hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
            }
            hiddenHp+=HIDDEN_HP_PER_KILL;
            if (hiddenHp>hiddenHpMax) {
                hiddenHp=hiddenHpMax;
            }
            PrintToChatAll("\x04[%s]\x01 \x03The Hidden\x01 killed \x03%N\x01 and ate his body", PLUGIN_NAME, victim);
            CreateTimer(0.1, Timer_Dissolve, victim);
        }
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    if (!activated) return Plugin_Continue;
    if (!CanPlay()) return Plugin_Continue;
    if (client==hidden) {
        new bool:changed=false;
        
        if (hiddenStick && hiddenStamina<HIDDEN_STAMINA_TIME-0.5) {
            if (buttons & IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_JUMP > 0)
            {
                HiddenUnstick();
            }
        }
        
        if (hiddenAway && (buttons & IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_JUMP) > 0) {
            hiddenAway=false;
        }
        
        if (buttons&IN_ATTACK) {
            changed=true;
            TF2_RemoveCondition(client, TFCond_Cloaked);
            AddHiddenVisible(0.75);
        }
        
        if (buttons&IN_ATTACK2) {
            buttons&=~IN_ATTACK2;
            changed=true;
            HiddenSpecial();
        }
        
        if (buttons&IN_RELOAD) {
            #if defined HIDDEN_BOO
                HiddenBoo();
            #endif
        }
        
        if (changed) {
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

public Action:Cmd_build(client, String:cmd[], args)
{
    if (args < 1) return Plugin_Continue;
    if (TF2_GetPlayerClass(client) != TFClass_Engineer) return Plugin_Continue;
    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    new building = StringToInt(arg1);
    if (building == _:TFObject_Sentry) {
        PrintToChat(client, "\x04[%s]\x01 You cannot build sentries in this game mode.", PLUGIN_NAME);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Timer_ResetHidden(Handle:timer) {
    ResetHidden();
}

public Action:Timer_Respawn(Handle:timer, any:data) {
    TF2_RespawnPlayer(data);
}

public Action:Timer_Dissolve(Handle:timer, any:data) {
    Dissolve(data, 3);
}

public Action:Timer_GiveHiddenPowers(Handle:timer, any:data) {
    GiveHiddenPowers(GetClientOfUserId(data));
}

public Action:Timer_Tick(Handle:timer) {
    ShowHiddenHP(TICK_INTERVAL);
}

public AddHiddenVisible(Float:value) {
    if (hiddenVisible<value) hiddenVisible=value;
}

public Action:Cmd_NextHidden(client, args) {
    if (!activated) return Plugin_Continue;
    if (IsFakeClient(client)) return Plugin_Continue;
    if (args<1) {
        if (GetCmdReplySource()==SM_REPLY_TO_CHAT) {
            ReplyToCommand(client, "\x04[%s]\x01 Usage: /nexthidden <player>", PLUGIN_NAME);
        } else {
            ReplyToCommand(client, "\x04[%s]\x01 Usage: sm_nexthidden <player>", PLUGIN_NAME);
        }
        return Plugin_Handled;
    }
    
    decl String:tmp[128];
    GetCmdArg(1, tmp, sizeof(tmp));
    
    new target = FindTarget(client, tmp, false, false);
    if (target==-1) return Plugin_Handled;
    
    forceNextHidden = GetClientUserId(target);
    
    PrintToChat(client, "\x04[%s]\x01 The next hidden will be \x03%N\x01", PLUGIN_NAME, target);
    
    return Plugin_Handled;
}

public Action:Command_EnableHidden(client, args) {
    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (cvar_enabled) return Plugin_Handled;
    ServerCommand("sm_hidden_enabled 1");
    ReplyToCommand(client, "[%s] Enabled.", PLUGIN_NAME);
    return Plugin_Handled;
}

public Action:Command_DisableHidden(client, args) {
    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    if (!cvar_enabled) return Plugin_Handled;
    ServerCommand("sm_hidden_enabled 0");
    ReplyToCommand(client, "[%s] Disabled.", PLUGIN_NAME);
    return Plugin_Handled;
}

stock NewGame() {
    if (!CanPlay()) return;
    if (hidden!=0) return;
    //playing=true;
    SelectHidden();
    Client_RespawnAll();
    newHidden=true;
}

stock DisableCps() {
    new i = -1;
    new CP = 0;

    for (new n = 0; n <= 16; n++) {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP)) {
            AcceptEntityInput(CP, "Disable");
            i = CP;
        } else {
            break;
        }
    } 
}

stock bool:IsArenaMap() {
    decl String:curMap[32];
    GetCurrentMap(curMap, sizeof(curMap));
    return strncmp("arena_", curMap, 6, false)==0;
}

public OnClientDisconnect(client) {
    if (client==hidden) ResetHidden();
}

stock Dissolve(client, type) {
    if (!Client_IsIngame(client)) return;

    new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll<0) return;

    decl String:dname[32], String:dtype[32];
    Format(dname, sizeof(dname), "dis_%d", client);
    Format(dtype, sizeof(dtype), "%d", type);
    
    new ent = CreateEntityByName("env_entity_dissolver");
    if (ent>0) {
        DispatchKeyValue(ragdoll, "targetname", dname);
        DispatchKeyValue(ent, "dissolvetype", dtype);
        DispatchKeyValue(ent, "target", dname);
        DispatchKeyValue(ent, "magnitude", "10");
        AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
        AcceptEntityInput(ent, "Kill");
    }
}

stock bool:CanPlay() {
    // Requires 2 or more players, excluding bots in the server.
    if (Client_GetCount(true, false) >= 2) {
        return true;
    } else {
        return false;
    }
}

stock MakeTeamWin(team) {
    new ent = FindEntityByClassname(-1, "team_control_point_master");
    if (ent == -1) {
        ent = CreateEntityByName("team_control_point_master");
        DispatchSpawn(ent);
        AcceptEntityInput(ent, "Enable");
    }
    
    SetVariantInt(team);
    AcceptEntityInput(ent, "SetWinner");
}

stock SelectHidden() {
    g_lastHidden=hidden; //Save this to restore class in player spawn
    g_lastHiddenSavedClass=g_hiddenSavedClass;  //Save this to restore class in player_spawn
    hidden=0;
    g_hiddenSavedClass=TFClass_Unknown;
    hiddenHpMax=HIDDEN_HP+((Client_GetCount(true, false)-1)*HIDDEN_HP_PER_PLAYER);
    hiddenHp=hiddenHpMax;
    hiddenVisible=0.0;
    hiddenStamina=HIDDEN_STAMINA_TIME;
    hiddenStick=false;
    hiddenAway=true;
    hiddenAwayTime=0.0;
    hiddenJump=0.0;
    hiddenInvisibility=HIDDEN_INVISIBILITY_TIME;
    
    #if defined HIDDEN_BOO
        hiddenBoo=0.0;
    #endif
    
    new forced=GetClientOfUserId(forceNextHidden);
    
    if (forced) {
        hidden=forced;
        forceNextHidden=0;
    } else {
        hidden = Client_GetRandom(CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_NOSPECTATORS);
    }
   
    g_hiddenSavedClass = TF2_GetPlayerClass(hidden); //grab player class *before* it is set to spy
    ChangeClientTeam(hidden, _:HTeam_Hidden); 
    TF2_SetPlayerClass(hidden, TFClass_Spy, false, true);
    
    if (!IsPlayerAlive(hidden)) {
        TF2_RespawnPlayer(hidden);
    }
    
    PrintToChat(hidden, "\x04[%s]\x01 You are \x03The Hidden\x01! Kill the IRIS Team!", PLUGIN_NAME);
    PrintToChat(hidden, "\x04[%s]\x01 Press \x04attack2\x01 to use super jump or stick to walls; \x04reload\x01 to use your stun attack.", PLUGIN_NAME);

    return hidden;
}

public bool:TraceRay_HitWorld(entityhit, mask) {
    return entityhit==0;
}

stock bool:HiddenSuperJump() {
    if (hidden==0) return false;
    if (hiddenJump>0.0) return false;
    hiddenJump = HIDDEN_JUMP_TIME;
    new Float:f_hiddenVisiblePounce = GetConVarFloat(cv_hidden_visible_pounce);
    
    HiddenUnstick();
    
    decl Float:ang[3];
    decl Float:vel[3];
    GetClientEyeAngles(hidden, ang);
    GetEntPropVector(hidden, Prop_Data, "m_vecAbsVelocity", vel);
    
    decl Float:tmp[3];
    
    GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
    
    vel[0] += tmp[0]*900.0;
    vel[1] += tmp[1]*900.0;
    vel[2] += tmp[2]*900.0;
    
    new flags=GetEntityFlags(hidden);
    if (flags & FL_ONGROUND)
        flags &= ~FL_ONGROUND;

    SetEntityFlags(hidden, flags);
    TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
    AddHiddenVisible(f_hiddenVisiblePounce);
    
    return true;
}

stock bool:HiddenSpecial() {
    if (hidden==0) return;
    if (HiddenStick()==-1) {
        HiddenSuperJump();
    }
}

stock HiddenStick() {
    if (hidden==0) return 0;
    
    decl Float:pos[3];
    decl Float:ang[3];
    
    GetClientEyeAngles(hidden, ang);
    GetClientEyePosition(hidden, pos);
    
    new Handle:ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
    if (TR_DidHit(ray)) {
        decl Float:pos2[3];
        TR_GetEndPosition(pos2, ray);
        if (GetVectorDistance(pos, pos2)<64.0) {
            if (hiddenStick || hiddenStamina<HIDDEN_STAMINA_TIME*0.7) {
                CloseHandle(ray);
                return 0;
            }
            
            hiddenStick=true;
            if (GetEntityMoveType(hidden)!=MOVETYPE_NONE) {
                SetEntityMoveType(hidden, MOVETYPE_NONE);
            }
            CloseHandle(ray);
            return 1;
        } else {
            CloseHandle(ray);
            return -1;
        }
    } else {
        CloseHandle(ray);
        return -1;
    }
}

public HiddenUnstick() {
    hiddenStick=false;
    if (GetEntityMoveType(hidden)==MOVETYPE_NONE) {
        SetEntityMoveType(hidden, MOVETYPE_WALK);
        new Float:vel[3];
        TeleportEntity(hidden, NULL_VECTOR, NULL_VECTOR, vel);
    }
}

stock GiveHiddenVision(i) {
    OverlayCommand(i, HIDDEN_OVERLAY);
}

stock RemoveHiddenVision(i) {
    OverlayCommand(i, "\"\"");
}

stock ShowHiddenHP(Float:duration) {
    if (hidden==0) return;
    duration+=0.1;
    
    new Float:perc=float(hiddenHp)/float(hiddenHpMax)*100.0;
    SetHudTextParams(-1.0, 0.3, duration, 255, 255, 255, 255);

    LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_NOBOTS) {
        if (client==hidden) continue;
        ShowHudText(client, 0, "Hidden Health: %.1f%%", perc);
    } 
    
    if (perc>60.0) {
        SetHudTextParams(-1.0, 0.3, duration, 0, 255, 0, 255);
    } else if (perc>30.0) {
        SetHudTextParams(-1.0, 0.3, duration, 128, 128, 0, 255);
    } else {
        SetHudTextParams(-1.0, 0.3, duration, 255, 0, 0, 255);
    }

    if (Client_IsIngame(hidden)) {    
        ShowHudText(hidden, 0, "Hidden Health: %.1f%%", perc);
    
        SetHudTextParams(-1.0, 0.325, duration, 255, 255, 255, 255);
        ShowHudText(hidden, 1, "Stamina: %.0f%%", hiddenStamina/HIDDEN_STAMINA_TIME*100.0);
    
        #if defined HIDDEN_BOO
            SetHudTextParams(-1.0, 0.35, duration, 255, 255, 255, 255);
            ShowHudText(hidden, 2, "Boo: %.0f%%", 100.0-hiddenBoo/HIDDEN_BOO_TIME*100.0);
        #endif
    }
}

stock GiveHiddenPowers(i) {
    if (!i) return;

    TF2_RemoveWeaponSlot(i, 0); // Revolver
    //TF2_RemoveWeaponSlot(i, 1); // Sapper
    TF2_RemoveWeaponSlot(i, 2); // Knife
    TF2_RemoveWeaponSlot(i, 3); // Disguise Kit
    TF2_RemoveWeaponSlot(i, 4); // Invisibility Watch
    TF2_RemoveWeaponSlot(i, 5); // Golden Machine Gun
                                        
    // This will add the knife to the spy, even if he has another unlock
    new knife=GivePlayerItem(i, "tf_weapon_knife");
    SetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex", 4);
    SetEntProp(knife, Prop_Send, "m_iEntityLevel", 100);
    SetEntProp(knife, Prop_Send, "m_iEntityQuality", 10);
    SetEntProp(knife, Prop_Send, "m_bInitialized", 1);

    // Also, I hate extensions :p
    EquipPlayerWeapon(i, knife);
    GiveHiddenVision(i);
    Client_SetHideHud(i, HIDEHUD_HEALTH);
}

stock RemoveHiddenPowers(i) {
    RemoveHiddenVision(i);
    Client_SetHideHud(i, 0);
}

stock ResetHidden() {
    if (hidden!=0 && Client_IsIngame(hidden)) {
        RemoveHiddenPowers(hidden);
    }
    hidden=0;
}

stock OverlayCommand(client, String:overlay[]) {    
    if (client && Client_IsIngame(client) && !IsClientInKickQueue(client)) {
        SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
        ClientCommand(client, "r_screenoverlay %s", overlay);
    }
}

stock Client_RespawnAll() {
    LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_NOBOTS|CLIENTFILTER_NOSPECTATORS) {
        CreateTimer(0.1, Timer_Respawn, client);
    }
}

#if defined HIDDEN_BOO
stock bool:HiddenBoo() {
    if (hidden==0) return false;
    if (hiddenBoo>0.0) return false;
    hiddenBoo = HIDDEN_BOO_TIME;
    
    decl Float:pos[3];
    decl Float:eye[3];
    decl Float:pos2[3];
    GetClientAbsOrigin(hidden, pos);
    GetClientEyePosition(hidden, eye);
    
    AddHiddenVisible(HIDDEN_BOO_VISIBLE);
    
    new targets[MaxClients];
    new targetsCount;
    LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_ALIVE|CLIENTFILTER_NOBOTS|CLIENTFILTER_NOSPECTATORS) {
        if (client==hidden) continue;
        GetClientAbsOrigin(client, pos2);
        if (GetVectorDistance(pos, pos2, true)>196.0*196.0) {
            continue;
        }

        TF2_StunPlayer(client, HIDDEN_BOO_DURATION, _, TF_STUNFLAG_GHOSTEFFECT|TF_STUNFLAG_THIRDPERSON, hidden);
    }
    targets[targetsCount++] = hidden;
    
    EmitSound(targets, targetsCount, HIDDEN_BOO_FILE, SOUND_FROM_PLAYER, _, _, _, _, _, hidden, eye);
    
    return true;
}
#endif

stock SetGameDescription() {
    new bool:cvar_enabled = GetConVarBool(cv_enabled);
    decl String:gameDesc[64];
    if (cvar_enabled && activated) {
        Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
    } else {
        gameDesc = "Team Fortress";
    }
    Steam_SetGameDescription(gameDesc);
}
