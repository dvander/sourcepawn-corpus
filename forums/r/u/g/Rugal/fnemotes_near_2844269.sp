#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <autoexecconfig>
#include <liquidHelpers>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_BONEMERGE_FASTCULL       (1 << 7)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
#define HIDEHUD_ALL                 (1 << 2)
#define HIDEHUD_CROSSHAIR           (1 << 8)
#define CVAR_FLAGS                  FCVAR_PROTECTED

#define SOUND_BASE_PATH "kodua/fortnite_emotes/"
#define SOUND_BASE_FULL "sound/kodua/fortnite_emotes/"

enum struct EmoteData
{
    char name[64];
    char intro[64];
    char loop[64];
    char sound[64];
}

static const EmoteData g_Emotes[] =
{
    { "Emote_Fonzie_Pistol",            "Emote_Fonzie_Pistol",              "none",                    "",                              },
    { "Emote_Bring_It_On",              "Emote_Bring_It_On",                "none",                    "",                              },
    { "Emote_ThumbsDown",               "Emote_ThumbsDown",                 "none",                    "",                              },
    { "Emote_ThumbsUp",                 "Emote_ThumbsUp",                   "none",                    "",                              },
    { "Emote_Celebration_Loop",         "Emote_Celebration_Loop",           "",                        "jubilation",                    },
    { "Emote_BlowKiss",                 "Emote_BlowKiss",                   "none",                    "blowkiss"                       },
    { "Emote_Calculated",               "Emote_Calculated",                 "none",                    "",                              },
    { "Emote_Confused",                 "Emote_Confused",                   "none",                    "",                              },
    { "Emote_Chug",                     "Emote_Chug",                       "none",                    "gogogo"                         },
    { "Emote_Cry",                      "Emote_Cry",                        "none",                    "bananacry"                      },
    { "Emote_DustingOffHands",          "Emote_DustingOffHands",            "none",                    "",                              },
    { "Emote_DustOffShoulders",         "Emote_DustOffShoulders",           "none",                    "athena_emote_hot_music"         },
    { "Emote_Facepalm",                 "Emote_Facepalm",                   "none",                    "athena_emote_facepalm_foley_01" },
    { "Emote_Fishing",                  "Emote_Fishing",                    "none",                    "fishing"                        },
    { "Emote_Flex",                     "Emote_Flex",                       "none",                    "flexing"                        },
    { "Emote_golfclap",                 "Emote_golfclap",                   "none",                    "clapping"                       },
    { "Emote_HandSignals",              "Emote_HandSignals",                "none",                    "",                              },
    { "Emote_HeelClick",                "Emote_HeelClick",                  "none",                    "emote_heelclick"                },
    { "Emote_Hotstuff",                 "Emote_Hotstuff",                   "none",                    "emote_hotstuff"                 },
    { "Emote_IBreakYou",                "Emote_IBreakYou",                  "none",                    "",                              },
    { "Emote_IHeartYou",                "Emote_IHeartYou",                  "none",                    "iheartyou"                      },
    { "Emote_Kung-Fu_Salute",           "Emote_Kung-Fu_Salute",             "none",                    "",                              },
    { "Emote_Laugh",                    "Emote_Laugh",                      "Emote_Laugh_CT",          "emote_laugh_01"                 },
    { "Emote_Luchador",                 "Emote_Luchador",                   "none",                    "emote_luchador"                 },
    { "Emote_Make_It_Rain",             "Emote_Make_It_Rain",               "none",                    "athena_emote_makeitrain_music"  },
    { "Emote_NotToday",                 "Emote_NotToday",                   "none",                    "",                              },
    { "Emote_RockPaperScissor_Paper",   "Emote_RockPaperScissor_Paper",     "none",                    "",                              },
    { "Emote_RockPaperScissor_Rock",    "Emote_RockPaperScissor_Rock",      "none",                    "",                              },
    { "Emote_RockPaperScissor_Scissor", "Emote_RockPaperScissor_Scissor",  "none",                    "",                               },
    { "Emote_Salt",                     "Emote_Salt",                       "none",                    "",                              },
    { "Emote_Salute",                   "Emote_Salute",                     "none",                    "athena_emote_salute_foley_01"   },
    { "Emote_Snap",                     "Emote_Snap",                       "none",                    "emote_snap1"                    },
    { "Emote_StageBow",                 "Emote_StageBow",                   "none",                    "emote_stagebow"                 },
    { "Emote_Wave2",                    "Emote_Wave2",                      "none",                    "",                              },
    { "Emote_Yeet",                     "Emote_Yeet",                       "none",                    "emote_yeet"                     },
    { "Emote_Cena",                     "Emote_Cena",                       "none",                    "cant_c_me"                      },
    { "Emote_Lebron",                   "Emote_Lebron",                     "none",                    "lebronjame"                     },
};

static const EmoteData g_Dances[] =
{
    { "DanceMoves",                     "DanceMoves",                       "none",                    "ninja_dance_01,dance_soldier_03"    },
    { "Emote_Mask_Off_Intro",           "Emote_Mask_Off_Intro",             "Emote_Mask_Off_Loop",     "hip_hop_good_vibes_mix_01_loop"     },
    { "Emote_Zippy_Dance",              "Emote_Zippy_Dance",                "none",                    "emote_zippy_a"                      },
    { "ElectroShuffle",                 "ElectroShuffle",                   "none",                    "athena_emote_electroshuffle_music"  },
    { "Emote_AerobicChamp",             "Emote_AerobicChamp",               "none",                    "emote_aerobics_01"                  },
    { "Emote_Bendy",                    "Emote_Bendy",                      "none",                    "athena_music_emotes_bendy"          },
    { "Emote_BandOfTheFort",            "Emote_BandOfTheFort",              "none",                    "athena_emote_bandofthefort_music"   },
    { "Emote_Boogie_Down_Intro",        "Emote_Boogie_Down_Intro",          "Emote_Boogie_Down",       "emote_boogiedown"                   },
    { "Emote_Capoeira",                 "Emote_Capoeira",                   "none",                    "emote_capoeira"                     },
    { "Emote_Charleston",               "Emote_Charleston",                 "none",                    "athena_emote_flapper_music"         },
    { "Emote_Chicken",                  "Emote_Chicken",                    "none",                    "athena_emote_chicken_foley_01"      },
    { "Emote_Dance_NoBones",            "Emote_Dance_NoBones",              "none",                    "athena_emote_music_boneless"        },
    { "Emote_Dance_Shoot",              "Emote_Dance_Shoot",                "none",                    "athena_emotes_music_shoot_v7"       },
    { "Emote_Dance_SwipeIt",            "Emote_Dance_SwipeIt",              "none",                    "athena_emotes_music_swipeit"        },
    { "Emote_Dance_Disco_T3",           "Emote_Dance_Disco_T3",             "none",                    "athena_emote_disco"                 },
    { "Emote_DG_Disco",                 "Emote_DG_Disco",                   "none",                    "athena_emote_disco"                 },
    { "Emote_Dance_Worm",               "Emote_Dance_Worm",                 "none",                    "athena_emote_worm_music"            },
    { "Emote_Dance_Loser",              "Emote_Dance_Loser",                "Emote_Dance_Loser_CT",    "athena_music_emotes_takethel"       },
    { "Emote_Dance_Breakdance",         "Emote_Dance_Breakdance",           "none",                    "athena_emote_breakdance_music"      },
    { "Emote_Dance_Pump",               "Emote_Dance_Pump",                 "none",                    "emote_groove_jam_a"                 },
    { "Emote_Dance_RideThePony",        "Emote_Dance_RideThePony",          "none",                    "athena_emote_ridethepony_music_01"  },
    { "Emote_Dab",                      "Emote_Dab",                        "none",                    "",                                  },
    { "Emote_EasternBloc_Start",        "Emote_EasternBloc_Start",          "Emote_EasternBloc",       "eastern_bloc_musc_setup_d"          },
    { "Emote_FancyFeet",                "Emote_FancyFeet",                  "Emote_FancyFeet_CT",      "athena_emotes_lankylegs_loop_02"    },
    { "Emote_FlossDance",               "Emote_FlossDance",                 "none",                    "athena_emote_floss_music"           },
    { "Emote_FlippnSexy",               "Emote_FlippnSexy",                 "none",                    "emote_flippnsexy"                   },
    { "Emote_Fresh",                    "Emote_Fresh",                      "none",                    "athena_emote_fresh_music"           },
    { "Emote_GrooveJam",                "Emote_GrooveJam",                  "none",                    "emote_groove_jam_a"                 },
    { "Emote_guitar",                   "Emote_guitar",                     "none",                    "br_emote_shred_guitar_mix_03_loop"  },
    { "Emote_Hillbilly_Shuffle_Intro",  "Emote_Hillbilly_Shuffle_Intro",    "Emote_Hillbilly_Shuffle", "emote_hillbilly_shuffle"            },
    { "Emote_Hiphop_01",                "Emote_Hiphop_01",                  "Emote_Hip_Hop",           "s5_hiphop_breakin_132bmp_loop"      },
    { "Emote_Hula_Start",               "Emote_Hula_Start",                 "Emote_Hula",              "emote_hula_01"                      },
    { "Emote_InfiniDab_Intro",          "Emote_InfiniDab_Intro",            "Emote_InfiniDab_Loop",    "athena_emote_infinidab"             },
    { "Emote_Intensity_Start",          "Emote_Intensity_Start",            "Emote_Intensity_Loop",    "emote_intensity"                    },
    { "Emote_IrishJig_Start",           "Emote_IrishJig_Start",             "Emote_IrishJig",          "emote_irish_jig_foley_music_loop"   },
    { "Emote_KoreanEagle",              "Emote_KoreanEagle",                "none",                    "athena_music_emotes_koreaneagle"    },
    { "Emote_Kpop_02",                  "Emote_Kpop_02",                    "none",                    "emote_kpop_01"                      },
    { "Emote_LivingLarge",              "Emote_LivingLarge",                "none",                    "emote_livinglarge_a"                },
    { "Emote_Maracas",                  "Emote_Maracas",                    "none",                    "emote_samba_new_b"                  },
    { "Emote_PopLock",                  "Emote_PopLock",                    "none",                    "athena_emote_poplock"               },
    { "Emote_PopRock",                  "Emote_PopRock",                    "none",                    "emote_poprock_01"                   },
    { "Emote_RobotDance",               "Emote_RobotDance",                 "none",                    "athena_emote_robot_music"           },
    { "Emote_T-Rex",                    "Emote_T-Rex",                      "none",                    "emote_dino_complete"                },
    { "Emote_TechnoZombie",             "Emote_TechnoZombie",               "none",                    "athena_emote_founders_music"        },
    { "Emote_Twist",                    "Emote_Twist",                      "none",                    "athena_emotes_music_twist"          },
    { "Emote_WarehouseDance_Start",     "Emote_WarehouseDance_Start",       "Emote_WarehouseDance_Loop","emote_warehouse",                  },
    { "Emote_Wiggle",                   "Emote_Wiggle",                     "none",                    "wiggle_music_loop"                  },
    { "Emote_Youre_Awesome",            "Emote_Youre_Awesome",              "none",                    "youre_awesome_emote_music"          },
    { "Emote_Smooth_Moves",             "Emote_Smooth_Moves",               "none",                    "smooth_moves"                       },
    { "Emote_Friday13",                 "Emote_Friday13",                   "none",                    "california_girls"                   },
    { "Emote_Friday13_ES",              "Emote_Friday13",                   "none",                    "california_girls_es"                },
    { "Emote_Thanos_Twerk",             "Emote_Thanos_Twerk",               "none",                    "thanos_twerk"                       },
    { "Emote_Gangnam_Style",            "Emote_Gangnam_Style",              "none",                    "psychic"                            },
    { "Emote_InDaGhetto",               "Emote_InDaGhetto",                 "none",                    "emote_vivid"                        },
    { "Emote_BlindingLights",           "Emote_BlindingLights",             "none",                    "emote_autumn_tea"                   },
    { "Emote_Griddy",                   "Emote_Griddy",                     "none",                    "emote_griddles_music"               },
    { "Emote_ILikeToMoveIt",            "Emote_ILikeToMoveIt",              "none",                    "emote_jumpingjoy"                   },
    { "Emote_Macarena",                 "Emote_Macarena",                   "none",                    "emote_macaroon_music"               },
    { "Emote_NeverGonna",               "Emote_NeverGonna",                 "none",                    "emote_nevergonna"                   },
    { "Emote_NinjaStyle",               "Emote_NinjaStyle",                 "none",                    "emote_tour_bus"                     },
    { "Emote_PumpkinDance",             "Emote_PumpkinDance",               "none",                    "pumpkin_dance"                      },
    { "Emote_PumpUpTheJam",             "Emote_PumpUpTheJam",               "none",                    "deflated_emote_music"               },
    { "Emote_Renegade",                 "Emote_Renegade",                   "none",                    "emote_just_home_music"              },
    { "Emote_RushinAround",             "Emote_RushinAround",               "none",                    "emote_comrade"                      },
    { "Emote_SaySo",                    "Emote_SaySo",                      "none",                    "emote_hotpink"                      },
    { "Emote_Stuck",                    "Emote_Stuck",                      "none",                    "emote_downward"                     },
    { "Emote_ToosieSlide",              "Emote_ToosieSlide",                "none",                    "emote_art_giant"                    },
    { "Emote_AirShredder",              "Emote_AirShredder",                "none",                    "air_guitar_emote"                   },
    { "Emote_Crossbounce",              "Emote_Crossbounce",                "none",                    "emote_blaster"                      },
    { "Emote_DistractionDance",         "Emote_DistractionDance",           "none",                    "distraction"                        },
    { "Emote_Headbanger",               "Emote_Headbanger",                 "none",                    "headbanger_music"                   },
    { "Emote_HitchHiker",               "Emote_HitchHiker",                 "none",                    "hitchhiker_music"                   },
    { "Emote_ItsGoTime",                "Emote_ItsGoTime",                  "none",                    "itsgotime_music"                    },
    { "Emote_KneeSlapper",              "Emote_KneeSlapper",                "none",                    "kneeslapper_music"                  },
    { "Emote_Showstopper",              "Emote_Showstopper",                "none",                    "showstopper_music"                  },
    { "Emote_Sprinkler",                "Emote_Sprinkler",                  "none",                    "sprinkler_music"                    },
    { "Emote_Gmod",                     "Emote_Gmod",                       "none",                    "gmod_select"                        },
    { "Emote_ChickenDance",             "Emote_ChickenDance",               "none",                    "pollo_dance"                        },
    { "Emote_Ghostbusters",             "Emote_Ghostbusters",               "none",                    "toastbust"                          },
    { "Emote_Martian",                  "Emote_Martian",                    "none",                    "leave_the_door"                     },
    { "Emote_RememberMe_Intro",         "Emote_RememberMe_Intro",           "Emote_RememberMe_Loop",   "unforgettable"                      },
    { "Emote_Rollie",                   "Emote_Rollie",                     "none",                    "rollie_rollie"                      },
    { "Emote_Scenario",                 "Emote_Scenario",                   "none",                    "scenariooo"                         },
    { "Emote_Tpose",                    "Emote_Tpose",                      "none",                    ""                                   },
    { "Emote_SmoothDrive",              "Emote_SmoothDrive",                "none",                    "dropit"                             },
};

// ============================================================
// Sets the total number of emotes and dances.
// Setting any of these incorrectly will cause the server to crash.
#define EMOTES_COUNT 37
#define DANCES_COUNT 85

// ============================================================
// Globals
// ============================================================

ConVar g_cvHidePlayers;

TopMenu hTopMenu;

ConVar g_cvFlagEmotesMenu;
ConVar g_cvFlagDancesMenu;
ConVar g_cvCooldown;
ConVar g_cvSpeed;
ConVar g_cvEmotesSounds;
ConVar g_cvHideWeapons;
ConVar g_cvTeleportBack;

int g_iEmoteEnt[MAXPLAYERS+1];
int g_iEmoteSoundEnt[MAXPLAYERS+1];

int g_EmotesTarget[MAXPLAYERS+1];

char g_sEmoteSound[MAXPLAYERS+1][PLATFORM_MAX_PATH];

bool g_bClientDancing[MAXPLAYERS+1];

Handle CooldownTimers[MAXPLAYERS+1];
bool g_bEmoteCooldown[MAXPLAYERS+1];

int g_iWeaponHandEnt[MAXPLAYERS+1];

Handle g_EmoteForward;
Handle g_EmoteForward_Pre;
bool g_bHooked[MAXPLAYERS + 1];

float g_fLastAngles[MAXPLAYERS+1][3];
float g_fLastPosition[MAXPLAYERS+1][3];

public Plugin myinfo =
{
    name = "[L4D2] Fortnite Emotes & Dances",
    author = "Kodua, Franc1sco franug, TheBO$$, Aleexxx, Foxhound, nearly civilized, Ferks-FK",
    description = "Animations from Fortnite in CS:GO/L4D2. New emotes ported by nearly civilized",
    version = "1.9.0",
    url = "https://forums.alliedmods.net/showthread.php?t=318981"
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("fnemotes_near.phrases");

    RegConsoleCmd("sm_rdance",    Command_Random_Emote, "[SM] Emote aleatório");
    RegConsoleCmd("sm_emotes",    Command_Menu);
    RegConsoleCmd("sm_emote",     Command_Menu);
    RegConsoleCmd("sm_dances",    Command_Menu);
    RegConsoleCmd("sm_dance",     Command_Menu);
    RegAdminCmd("sm_setemotes",   Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
    RegAdminCmd("sm_setemote",    Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
    RegAdminCmd("sm_setdances",   Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
    RegAdminCmd("sm_setdance",    Command_Admin_Emotes, ADMFLAG_GENERIC, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
    RegConsoleCmd("sm_doemote",   Command_Do_Emotes,   "[SM] Usage: sm_doemote [Emote ID]");
    RegConsoleCmd("sm_dodance",   Command_Do_Emotes,   "[SM] Usage: sm_dodance [Emote ID]");
    RegAdminCmd("sm_danceall",    Command_Force_Emote, ADMFLAG_GENERIC, "Forces all players to dance");

    HookEvent("player_death",       Event_PlayerDeath,      EventHookMode_Pre);
    HookEvent("player_hurt",        Event_PlayerHurt,       EventHookMode_Pre);
    HookEvent("player_bot_replace", Event_BotReplacePlayer, EventHookMode_Pre);
    HookEvent("player_team",        Event_PlayerTeam,       EventHookMode_Pre);
    HookEvent("round_start",        Event_Start);
    HookEvent("round_end",          Event_RoundEnd);

    AutoExecConfig_SetFile("fortnite_emotes_nearlycivilized");

    g_cvEmotesSounds  = AutoExecConfig_CreateConVar("sm_emotes_sounds",           "1",     "Enable/Disable sounds for emotes.", _, true, 0.0, true, 1.0);
    g_cvCooldown      = AutoExecConfig_CreateConVar("sm_emotes_cooldown",          "1.0",  "Cooldown for emotes in seconds. -1 or 0 = no cooldown.");
    g_cvFlagEmotesMenu= AutoExecConfig_CreateConVar("sm_emotes_admin_flag_menu",   "",     "admin flag for emotes (empty for all players)");
    g_cvFlagDancesMenu= AutoExecConfig_CreateConVar("sm_dances_admin_flag_menu",   "",     "admin flag for dances (empty for all players)");
    g_cvHideWeapons   = AutoExecConfig_CreateConVar("sm_emotes_hide_weapons",      "1",    "Hide weapons when dancing", _, true, 0.0, true, 1.0);
    g_cvHidePlayers   = AutoExecConfig_CreateConVar("sm_emotes_hide_enemies",      "0",    "Hide enemy players when dancing", _, true, 0.0, true, 1.0);
    g_cvTeleportBack  = AutoExecConfig_CreateConVar("sm_emotes_teleportonend",     "1",    "Teleport back to the exact position when he started to dance.", _, true, 0.0, true, 1.0);
    g_cvSpeed         = CreateConVar(               "sm_emotes_speed",             "0.84", "Sets the playback speed of the animation.", CVAR_FLAGS);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    TopMenu topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
        OnAdminMenuReady(topmenu);

    g_EmoteForward     = CreateGlobalForward("fnemotes_OnEmote",     ET_Ignore, Param_Cell);
    g_EmoteForward_Pre = CreateGlobalForward("fnemotes_OnEmote_Pre", ET_Event,  Param_Cell);
}

public void OnPluginEnd()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && g_bClientDancing[i])
            StopEmote(i);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("fnemotes");
    CreateNative("fnemotes_IsClientEmoting", Native_IsClientEmoting);
    return APLRes_Success;
}

int Native_IsClientEmoting(Handle plugin, int numParams)
{
    return g_bClientDancing[GetNativeCell(1)];
}

public void OnMapStart()
{
    AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.mdl");
    AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.vvd");
    AddFileToDownloadsTable("models/player/kodua/fnemotes_nearlycivilized.dx90.vtx");

    PrecacheModel("models/player/kodua/fnemotes_nearlycivilized.mdl", true);

    char sound[64];
    for (int i = 0; i < EMOTES_COUNT; i++)
    {
        strcopy(sound, sizeof(sound), g_Emotes[i].sound);
        if (!StrEqual(sound, ""))
        {
            if (StrContains(sound, ",") != -1)
            {
                char sounds[8][64];
                int count = ExplodeString(sound, ",", sounds, sizeof(sounds), sizeof(sounds[]));
                for (int j = 0; j < count; j++)
                    PrecacheEmoteSound(sounds[j]);
            }
            else
                PrecacheEmoteSound(sound);
        }
    }
    for (int i = 0; i < DANCES_COUNT; i++)
    {
        strcopy(sound, sizeof(sound), g_Dances[i].sound);
        if (!StrEqual(sound, ""))
        {
            if (StrContains(sound, ",") != -1)
            {
                char sounds[8][64];
                int count = ExplodeString(sound, ",", sounds, sizeof(sounds), sizeof(sounds[]));
                for (int j = 0; j < count; j++)
                    PrecacheEmoteSound(sounds[j]);
            }
            else
                PrecacheEmoteSound(sound);
        }
    }
}

void PrecacheEmoteSound(const char[] soundName)
{
    char fullPath[PLATFORM_MAX_PATH];
    FormatEx(fullPath, sizeof(fullPath), "%s%s.mp3", SOUND_BASE_FULL, soundName);
    AddFileToDownloadsTable(fullPath);

    char precachePath[PLATFORM_MAX_PATH];
    FormatEx(precachePath, sizeof(precachePath), "%s%s.mp3", SOUND_BASE_PATH, soundName);
    PrecacheSound(precachePath);
}

public void OnClientPutInServer(int client)
{
    if (IsValidClient(client))
    {
        ResetCam(client);
        TerminateEmote(client);
        g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;

        if (CooldownTimers[client] != null)
            KillTimer(CooldownTimers[client]);
    }
}

public void OnClientDisconnect(int client)
{
    if (IsValidClient(client))
    {
        ResetCam(client);
        TerminateEmote(client);

        if (CooldownTimers[client] != null)
        {
            KillTimer(CooldownTimers[client]);
            CooldownTimers[client] = null;
            g_bEmoteCooldown[client] = false;
        }
    }
    g_bHooked[client] = false;
}

// ============================================================
// Events
// ============================================================

void Event_BotReplacePlayer(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot    = GetClientOfUserId(event.GetInt("bot"));
    StopEmote(player);
    StopEmote(bot);

    SetEntityMoveType(player, MOVETYPE_WALK);

    bool isHanging = GetEntProp(bot, Prop_Send, "m_isHangingFromLedge") == 1;
    if (!isHanging)
        SetEntityMoveType(bot, MOVETYPE_WALK);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(victim) && L4D_GetClientTeam(victim) == L4DTeam_Survivor)
        StopEmote(victim);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client))
    {
        ResetCam(client);
        StopEmote(client);
    }
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    StopEmote(client);
}

void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i, false) && g_bClientDancing[i])
        {
            ResetCam(i);
            StopEmote(i);
            WeaponUnblock(i);
            g_bClientDancing[i] = false;
        }
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 0; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        if (IsFakeClient(i) && OnInfectedTeam(i))
            CreateTimer(1.0, BotTaunt, i, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action BotTaunt(Handle timer, int client)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    RandomDance(client);
    return Plugin_Continue;
}

// ============================================================
// Commands
// ============================================================

public Action Command_Menu(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;
    Menu_Dance(client);
    return Plugin_Handled;
}

public Action Command_Force_Emote(int client, int args)
{
    for (int i = 0; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
            continue;
        RandomDance(i);
    }
    return Plugin_Handled;
}

public Action Command_Do_Emotes(int client, int args)
{
    if (args < 1)
    {
        CReplyToCommand(client, "[SM] Usage: sm_dodance [Emote ID]");
        CReplyToCommand(client, "[SM] Usage: sm_doemote [Emote ID]");
        return Plugin_Handled;
    }

    int amount = 1;
    char arg1[4];
    GetCmdArg(1, arg1, sizeof(arg1));
    int totalEmotes = EMOTES_COUNT + DANCES_COUNT;
    if (StringToIntEx(arg1, amount) < 1 || amount < 1 || amount > totalEmotes)
    {
        CReplyToCommand(client, "%t", "INVALID_EMOTE_ID", 1, totalEmotes);
        return Plugin_Handled;
    }

    PerformEmote(client, client, amount - 1);  // convert 1-based user ID to 0-based index
    return Plugin_Handled;
}

public Action Command_Random_Emote(int client, int args)
{
    int total = EMOTES_COUNT + DANCES_COUNT;
    PerformEmote(client, client, GetRandomInt(0, total - 1));
    return Plugin_Handled;
}

public Action Command_Admin_Emotes(int client, int args)
{
    if (args < 1)
    {
        CReplyToCommand(client, "[SM] Usage: sm_setemotes <#userid|name> [Emote ID]");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    int amount = 0;  // default: first emote (0-based index)
    if (args > 1)
    {
        char arg2[4];
        GetCmdArg(2, arg2, sizeof(arg2));
        int totalEmotes = EMOTES_COUNT + DANCES_COUNT;
        if (StringToIntEx(arg2, amount) < 1 || amount < 1 || amount > totalEmotes)
        {
            CReplyToCommand(client, "%t", "INVALID_EMOTE_ID", 1, totalEmotes);
            return Plugin_Handled;
        }
        amount--;  // convert 1-based user ID to 0-based index
    }

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
        arg, client, target_list, MAXPLAYERS,
        COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (int i = 0; i < target_count; i++)
        PerformEmote(client, target_list[i], amount);

    return Plugin_Handled;
}

// ============================================================
// Core: PerformEmote — single dispatch point
// ============================================================

void PerformEmote(int client, int target, int amount)
{
    if (amount < 0 || amount >= EMOTES_COUNT + DANCES_COUNT)
    {
        CPrintToChat(client, "%t", "INVALID_EMOTE_ID", 1, EMOTES_COUNT + DANCES_COUNT);
        return;
    }

    char intro[64], loop[64], sound[64];

    if (amount < EMOTES_COUNT)
    {
        strcopy(intro,  sizeof(intro),  g_Emotes[amount].intro);
        strcopy(loop,   sizeof(loop),   g_Emotes[amount].loop);
        strcopy(sound,  sizeof(sound),  g_Emotes[amount].sound);
    }
    else
    {
        int idx = amount - EMOTES_COUNT;
        strcopy(intro,  sizeof(intro),  g_Dances[idx].intro);
        strcopy(loop,   sizeof(loop),   g_Dances[idx].loop);
        strcopy(sound,  sizeof(sound),  g_Dances[idx].sound);
    }

    CreateEmote(target, intro, loop, sound);
}

// ============================================================
// Helpers
// ============================================================

void RandomEmote(int client)
{
    char sBuffer[32];
    g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));
    if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
    {
        CPrintToChat(client, "%t", "NO_EMOTES_ACCESS_FLAG");
        return;
    }
    PerformEmote(client, client, GetRandomInt(0, EMOTES_COUNT - 1));
}

void RandomDance(int client)
{
    char sBuffer[32];
    g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));
    if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
    {
        CPrintToChat(client, "%t", "NO_DANCES_ACCESS_FLAG");
        return;
    }
    PerformEmote(client, client, EMOTES_COUNT + GetRandomInt(0, DANCES_COUNT - 1));
}

void PopulateEmotesMenu(Menu menu, int client)
{
    char info[8];
    for (int i = 0; i < EMOTES_COUNT; i++)
    {
        IntToString(i, info, sizeof(info));
        char name[64], label[128];
        strcopy(name, sizeof(name), g_Emotes[i].name);
        if (TranslationPhraseExists(name))
            Format(label, sizeof(label), "[%d] %T", i + 1, name, client);
        else
            Format(label, sizeof(label), "[%d] %s", i + 1, name);
        menu.AddItem(info, label);
    }
}

void PopulateDancesMenu(Menu menu, int client, int infoOffset = 0, int idOffset = 1)
{
    char info[8];
    for (int i = 0; i < DANCES_COUNT; i++)
    {
        IntToString(infoOffset + i, info, sizeof(info));
        char name[64], label[128];
        strcopy(name, sizeof(name), g_Dances[i].name);
        if (TranslationPhraseExists(name))
            Format(label, sizeof(label), "[%d] %T", idOffset + i, name, client);
        else
            Format(label, sizeof(label), "[%d] %s", idOffset + i, name);
        menu.AddItem(info, label);
    }
}

// Called from MenuAction_Select for both Emotes and Dances menus.
// baseOffset: 0 for emotes, EMOTES_COUNT for dances (so PerformEmote gets the right index).
void HandleEmoteMenuSelect(Menu menu, int client, int param2, int baseOffset)
{
    char info[8];
    if (menu.GetItem(param2, info, sizeof(info)))
    {
        int idx = StringToInt(info);
        PerformEmote(client, client, baseOffset + idx);
    }
    menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
}

// ============================================================
// Main menu
// ============================================================

Action Menu_Dance(int client)
{
    Menu menu = new Menu(MenuHandler1);

    char title[65];
    Format(title, sizeof(title), "%T:", "TITLE_MAIM_MENU", client);
    menu.SetTitle(title);

    AddTranslatedMenuItem(menu, "", "RANDOM_EMOTE",  client);
    AddTranslatedMenuItem(menu, "", "RANDOM_DANCE",  client);
    AddTranslatedMenuItem(menu, "", "EMOTES_LIST",   client);
    AddTranslatedMenuItem(menu, "", "DANCES_LIST",   client);

    menu.ExitButton     = true;
    menu.ExitBackButton = false;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;
            switch (param2)
            {
                case 0: { RandomEmote(client); Menu_Dance(client); }
                case 1: { RandomDance(client); Menu_Dance(client); }
                case 2: EmotesMenu(client);
                case 3: DancesMenu(client);
            }
        }
        case MenuAction_End: delete menu;
    }

    return 0;
}

// ============================================================
// Emotes menu
// ============================================================

Action EmotesMenu(int client)
{
    char sBuffer[32];
    g_cvFlagEmotesMenu.GetString(sBuffer, sizeof(sBuffer));
    if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
    {
        CPrintToChat(client, "%t", "NO_EMOTES_ACCESS_FLAG");
        return Plugin_Handled;
    }

    Menu menu = new Menu(MenuHandlerEmotes);

    char title[65];
    Format(title, sizeof(title), "%T:", "TITLE_EMOTES_MENU", client);
    menu.SetTitle(title);

    PopulateEmotesMenu(menu, client);

    menu.ExitButton     = true;
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

int MenuHandlerEmotes(Menu menu, MenuAction action, int client, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
            HandleEmoteMenuSelect(menu, client, param2, 0);
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) Menu_Dance(client);
        }
    }

    return 0;
}

// ============================================================
// Dances menu
// ============================================================

Action DancesMenu(int client)
{
    char sBuffer[32];
    g_cvFlagDancesMenu.GetString(sBuffer, sizeof(sBuffer));
    if (!CheckAdminFlags(client, ReadFlagString(sBuffer)))
    {
        CPrintToChat(client, "%t", "NO_DANCES_ACCESS_FLAG");
        return Plugin_Handled;
    }

    Menu menu = new Menu(MenuHandlerDances);

    char title[65];
    Format(title, sizeof(title), "%T:", "TITLE_DANCES_MENU", client);
    menu.SetTitle(title);

    PopulateDancesMenu(menu, client, 0, EMOTES_COUNT + 1);

    menu.ExitButton     = true;
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

int MenuHandlerDances(Menu menu, MenuAction action, int client, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
            HandleEmoteMenuSelect(menu, client, param2, EMOTES_COUNT);
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack) Menu_Dance(client);
        }
    }

    return 0;
}

Action CreateEmote(int client, const char[] anim1, const char[] anim2, const char[] soundName)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (g_EmoteForward_Pre != null)
    {
        Action res = Plugin_Continue;
        Call_StartForward(g_EmoteForward_Pre);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Continue)
            return Plugin_Handled;
    }

    if (!IsPlayerAlive(client) || bIsPlayerIncapped(client))
    {
        CReplyToCommand(client, "%t", "MUST_BE_ALIVE");
        return Plugin_Handled;
    }

    if (!(GetEntityFlags(client) & FL_ONGROUND))
    {
        CReplyToCommand(client, "%t", "STAY_ON_GROUND");
        return Plugin_Handled;
    }

    if (CooldownTimers[client])
    {
        CReplyToCommand(client, "%t", "COOLDOWN_EMOTES");
        return Plugin_Handled;
    }

    if (StrEqual(anim1, ""))
    {
        CReplyToCommand(client, "%t", "AMIN_1_INVALID");
        return Plugin_Handled;
    }

    if (g_iEmoteEnt[client])
        StopEmote(client);

    if (GetEntityMoveType(client) == MOVETYPE_NONE)
    {
        CReplyToCommand(client, "%t", "CANNOT_USE_NOW");
        return Plugin_Handled;
    }

    int EmoteEnt = CreateEntityByName("prop_dynamic");
    if (IsValidEntity(EmoteEnt))
    {
        SetEntityMoveType(client, MOVETYPE_NONE);
        WeaponBlock(client);

        float vec[3], ang[3];
        GetClientAbsOrigin(client, vec);
        GetClientAbsAngles(client, ang);

        g_fLastPosition[client] = vec;
        g_fLastAngles[client]   = ang;

        char emoteEntName[16];
        FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));

        DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
        DispatchKeyValue(EmoteEnt, "model",      "models/player/kodua/fnemotes_nearlycivilized.mdl");
        DispatchKeyValue(EmoteEnt, "solid",      "0");
        DispatchKeyValue(EmoteEnt, "rendermode", "10");

        ActivateEntity(EmoteEnt);
        DispatchSpawn(EmoteEnt);

        TeleportEntity(EmoteEnt, vec, ang, NULL_VECTOR);

        SetVariantString(emoteEntName);
        AcceptEntityInput(client, "SetParent", client, client, 0);

        g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);

        SetEntProp(client, Prop_Send, "m_fEffects",
            EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW | EF_BONEMERGE_FASTCULL | EF_PARENT_ANIMATES);

        // Sound
        if (g_cvEmotesSounds.BoolValue && !StrEqual(soundName, ""))
        {
            int EmoteSoundEnt = CreateEntityByName("info_target");
            if (IsValidEntity(EmoteSoundEnt))
            {
                char soundEntName[16];
                FormatEx(soundEntName, sizeof(soundEntName), "soundEnt%i", GetRandomInt(1000000, 9999999));

                DispatchKeyValue(EmoteSoundEnt, "targetname", soundEntName);
                DispatchSpawn(EmoteSoundEnt);

                vec[2] += 72.0;
                TeleportEntity(EmoteSoundEnt, vec, NULL_VECTOR, NULL_VECTOR);

                SetVariantString(emoteEntName);
                AcceptEntityInput(EmoteSoundEnt, "SetParent");

                g_iEmoteSoundEnt[client] = EntIndexToEntRef(EmoteSoundEnt);

                char soundNameBuffer[64];

                if (StrContains(soundName, ",") != -1)
                {
                    char sounds[8][64];
                    int count = ExplodeString(soundName, ",", sounds, sizeof(sounds), sizeof(sounds[]));
                    strcopy(soundNameBuffer, sizeof(soundNameBuffer), sounds[GetRandomInt(0, count - 1)]);
                }
                else
                    strcopy(soundNameBuffer, sizeof(soundNameBuffer), soundName);

                FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH,
                    "%s%s.mp3", SOUND_BASE_PATH, soundNameBuffer);

                EmitSoundToAll(g_sEmoteSound[client], client, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
            }
        }
        else
        {
            g_sEmoteSound[client] = "";
        }

        if (StrEqual(anim2, "none", false))
            HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
        else
        {
            SetVariantString(anim2);
            AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
        }

        SetVariantString(anim1);
        AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);

        SetCam(client);

        if (g_cvSpeed.FloatValue != 1.0)
            SetEntPropFloat(EmoteEnt, Prop_Send, "m_flPlaybackRate", g_cvSpeed.FloatValue);

        g_bClientDancing[client] = true;

        if (g_cvHidePlayers.BoolValue)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsPlayerAlive(i)
                    && GetClientTeam(i) != GetClientTeam(client)
                    && !g_bHooked[i])
                {
                    SDKHook(i, SDKHook_SetTransmit, SetTransmit);
                    g_bHooked[i] = true;
                }
            }
        }

        if (g_cvCooldown.FloatValue > 0.0)
            CooldownTimers[client] = CreateTimer(g_cvCooldown.FloatValue, ResetCooldown, client);

        if (g_EmoteForward != null)
        {
            Call_StartForward(g_EmoteForward);
            Call_PushCell(client);
            Call_Finish();
        }
    }

    return Plugin_Handled;
}

// ============================================================
// RunCmd / animation end
// ============================================================

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
    if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
        StopEmote(client);

    static int iAllowedButtons = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;

    if (iButtons == 0)         return Plugin_Continue;
    if (g_iEmoteEnt[client] == 0) return Plugin_Continue;

    if ((iButtons & iAllowedButtons) && !(iButtons &~ iAllowedButtons))
        return Plugin_Continue;

    StopEmote(client);
    return Plugin_Continue;
}

void EndAnimation(const char[] output, int caller, int activator, float delay)
{
    if (caller > 0)
    {
        activator = GetEmoteActivator(EntIndexToEntRef(caller));
        StopEmote(activator);
    }
}

int GetEmoteActivator(int iEntRefDancer)
{
    if (iEntRefDancer == INVALID_ENT_REFERENCE)
        return 0;
    for (int i = 1; i <= MaxClients; i++)
        if (g_iEmoteEnt[i] == iEntRefDancer)
            return i;
    return 0;
}

// ============================================================
// Stop / Terminate emote
// ============================================================

void StopEmote(int client)
{
    if (!g_iEmoteEnt[client])
        return;

    int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
    if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
    {
        char emoteEntName[50];
        GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
        SetVariantString(emoteEntName);
        AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
        DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
        AcceptEntityInput(iEmoteEnt, "FireUser1");

        if (g_cvTeleportBack.BoolValue)
            TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);

        ResetCam(client);
        WeaponUnblock(client);
        SetEntityMoveType(client, MOVETYPE_WALK);
        g_iEmoteEnt[client]   = 0;
        g_bClientDancing[client] = false;
    }
    else
    {
        g_iEmoteEnt[client]   = 0;
        g_bClientDancing[client] = false;
    }

    if (g_iEmoteSoundEnt[client])
    {
        int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);
        if (!StrEqual(g_sEmoteSound[client], "")
            && iEmoteSoundEnt
            && iEmoteSoundEnt != INVALID_ENT_REFERENCE
            && IsValidEntity(iEmoteSoundEnt))
        {
            StopSound(client, SNDCHAN_AUTO, g_sEmoteSound[client]);
            AcceptEntityInput(iEmoteSoundEnt, "Kill");
            g_iEmoteSoundEnt[client] = 0;
        }
        else
        {
            g_iEmoteSoundEnt[client] = 0;
        }
    }
}

void TerminateEmote(int client)
{
    if (!g_iEmoteEnt[client])
        return;

    int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
    if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
    {
        char emoteEntName[50];
        GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
        SetVariantString(emoteEntName);
        AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
        DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
        AcceptEntityInput(iEmoteEnt, "FireUser1");

        g_iEmoteEnt[client]   = 0;
        g_bClientDancing[client] = false;
    }
    else
    {
        g_iEmoteEnt[client]   = 0;
        g_bClientDancing[client] = false;
    }

    if (g_iEmoteSoundEnt[client])
    {
        int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);
        if (!StrEqual(g_sEmoteSound[client], "")
            && iEmoteSoundEnt
            && iEmoteSoundEnt != INVALID_ENT_REFERENCE
            && IsValidEntity(iEmoteSoundEnt))
        {
            StopSound(client, SNDCHAN_AUTO, g_sEmoteSound[client]);
            AcceptEntityInput(iEmoteSoundEnt, "Kill");
            g_iEmoteSoundEnt[client] = 0;
        }
        else
        {
            g_iEmoteSoundEnt[client] = 0;
        }
    }
}

// ============================================================
// Weapon block / unblock
// ============================================================

void WeaponBlock(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse,  WeaponCanUseSwitch);
    SDKHook(client, SDKHook_WeaponSwitch,  WeaponCanUseSwitch);

    if (g_cvHideWeapons.BoolValue)
        SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);

    int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (iEnt != -1)
    {
        g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
    }
}

void WeaponUnblock(int client)
{
    SDKUnhook(client, SDKHook_WeaponCanUse,  WeaponCanUseSwitch);
    SDKUnhook(client, SDKHook_WeaponSwitch,  WeaponCanUseSwitch);
    SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);

    if (GetEmotePeople() == 0)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && g_bHooked[i])
            {
                SDKUnhook(i, SDKHook_SetTransmit, SetTransmit);
                g_bHooked[i] = false;
            }
        }
    }

    if (IsPlayerAlive(client) && g_iWeaponHandEnt[client] != INVALID_ENT_REFERENCE)
    {
        int iEnt = EntRefToEntIndex(g_iWeaponHandEnt[client]);
        if (iEnt != INVALID_ENT_REFERENCE)
            SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iEnt);
    }

    g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
    return Plugin_Stop;
}

void OnPostThinkPost(int client)
{
    SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public Action SetTransmit(int entity, int client)
{
    if (g_bClientDancing[client] && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(entity))
        return Plugin_Handled;
    return Plugin_Continue;
}

// ============================================================
// Camera
// ============================================================

void SetCam(int client)
{
    SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
    SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_CROSSHAIR);
}

void ResetCam(int client)
{
    SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
    SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDEHUD_CROSSHAIR);
}

Action ResetCooldown(Handle timer, any client)
{
    CooldownTimers[client] = null;
    return Plugin_Continue;
}

// ============================================================
// Admin top menu
// ============================================================

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
    if (topmenu == hTopMenu)
        return;
    hTopMenu = topmenu;

    TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
    if (player_commands != INVALID_TOPMENUOBJECT)
        hTopMenu.AddItem("sm_setemotes", AdminMenu_Emotes, player_commands, "sm_setemotes", ADMFLAG_SLAY);
}

void AdminMenu_Emotes(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "%T", "EMOTE_PLAYER", param);
    else if (action == TopMenuAction_SelectOption)
        DisplayEmotePlayersMenu(param);
}

void DisplayEmotePlayersMenu(int client)
{
    Menu menu = new Menu(MenuHandler_EmotePlayers);

    char title[65];
    Format(title, sizeof(title), "%T:", "EMOTE_PLAYER", client);
    menu.SetTitle(title);
    menu.ExitBackButton = true;

    AddTargetsToMenu(menu, client, true, true);
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotePlayers(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hTopMenu)
            hTopMenu.Display(param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        int userid, target;

        menu.GetItem(param2, info, sizeof(info));
        userid = StringToInt(info);

        if ((target = GetClientOfUserId(userid)) == 0)
            CPrintToChat(param1, "[SM] %t", "Player no longer available");
        else if (!CanUserTarget(param1, target))
            CPrintToChat(param1, "[SM] %t", "Unable to target");
        else
        {
            g_EmotesTarget[param1] = userid;
            DisplayEmotesAmountMenu(param1);
            return 0;
        }

        if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
            DisplayEmotePlayersMenu(param1);
    }

    return 0;
}

void DisplayEmotesAmountMenu(int client)
{
    Menu menu = new Menu(MenuHandler_EmotesAmount);

    char title[65];
    Format(title, sizeof(title), "%T: %N", "SELECT_EMOTE", client, GetClientOfUserId(g_EmotesTarget[client]));
    menu.SetTitle(title);
    menu.ExitBackButton = true;

    // Emotes (IDs 1..N) then dances (IDs N+1..N+M)
    // Info value encodes the global PerformEmote index (0-based)
    PopulateEmotesMenu(menu, client);

    // Dances: info encodes global PerformEmote index (EMOTES_COUNT+i), IDs start at EMOTES_COUNT+1
    PopulateDancesMenu(menu, client, EMOTES_COUNT, EMOTES_COUNT + 1);

    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_EmotesAmount(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && hTopMenu)
            hTopMenu.Display(param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        int amount, target;

        menu.GetItem(param2, info, sizeof(info));
        amount = StringToInt(info);

        if ((target = GetClientOfUserId(g_EmotesTarget[param1])) == 0)
            CPrintToChat(param1, "[SM] %t", "Player no longer available");
        else if (!CanUserTarget(param1, target))
            CPrintToChat(param1, "[SM] %t", "Unable to target");
        else
            PerformEmote(param1, target, amount);

        if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
            DisplayEmotePlayersMenu(param1);
    }

    return 0;
}

// ============================================================
// Triggers
// ============================================================

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "trigger_multiple")
        || StrEqual(classname, "trigger_hurt")
        || StrEqual(classname, "trigger_push"))
    {
        SDKHook(entity, SDKHook_StartTouch, OnTrigger);
        SDKHook(entity, SDKHook_EndTouch,   OnTrigger);
        SDKHook(entity, SDKHook_Touch,      OnTrigger);
    }
}

public Action OnTrigger(int entity, int other)
{
    if (0 < other <= MaxClients)
        StopEmote(other);
    return Plugin_Continue;
}

// ============================================================
// Utilities
// ============================================================

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
    char buffer[128];
    Format(buffer, sizeof(buffer), "%T", phrase, client);
    menu.AddItem(opt, buffer);
}

bool CheckAdminFlags(int client, int iFlag)
{
    int iUserFlags = GetUserFlagBits(client);
    return (iUserFlags & ADMFLAG_ROOT || (iUserFlags & iFlag) == iFlag);
}

int GetEmotePeople()
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && g_bClientDancing[i])
            count++;
    return count;
}

stock bool bIsPlayerIncapped(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}
