#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "2.0.2"
#define PLUGIN_PREFIX "\x04Skins: \x03"

#define NUM_TIERS 6
#define NUM_PATHS 8

#define ACCESS_NO_ACCESS -1
#define ACCESS_TIER_ONE 0
#define ACCESS_TIER_TWO 1
#define ACCESS_TIER_THREE 2
#define ACCESS_TIER_FOUR 3
#define ACCESS_TIER_FIVE 4
#define ACCESS_TIER_NONE 5

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hBots = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hCommands = INVALID_HANDLE;
new Handle:g_hAllowed = INVALID_HANDLE;
new Handle:g_hFlag[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hPathT[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hPathCT[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hForced[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hCookie = INVALID_HANDLE;
new Handle:g_hTrie = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new g_iTier[MAXPLAYERS + 1];
new bool:g_bAppear[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];

new bool:g_bLateLoad = true, bool:g_bEnabled = true, bool:g_bModel, bool:g_bDefault, bool:g_bForced[NUM_TIERS], bool:g_bRedAvailable[NUM_TIERS], bool:g_bBlueAvailable[NUM_TIERS], bool:g_bChangable = true;
new g_iBots, g_iAccess[NUM_TIERS], g_iRedTotal[NUM_TIERS], g_iBlueTotal[NUM_TIERS];
new Float:g_fDelay, Float:g_fAllowed;
new String:g_sRedPaths[NUM_TIERS][NUM_PATHS][256], String:g_sBluePaths[NUM_TIERS][NUM_PATHS][256], String:g_sCommands[8][32];

static const String:g_sBlueModels[4][] = 
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};

static const String:g_sRedModels[4][] = 
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};

public Plugin:myinfo =
{
	name = "Jail skins", 
	author = "KryptoNite", 
	description = "Provides simple functionality for applying skins to players automatically.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hands_f_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_holster.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_holster.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_pants.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_pants.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_pants_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/eyeball_l.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/eyeball_l.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/eyeball_r.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/eyeball_r.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/hair_brown.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/hair_brown.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_badge.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_badge.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_badge_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hand_f.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hand_f.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hand_f_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_shirt.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_shirt.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_shirt_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hands_m.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hands_m.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_hands_m_n.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_male_face.vmt");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_male_face.vtf");
    AddFileToDownloadsTable("materials/models/player/natalya/police/chp_male_face_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.mdl");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.phy");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p.vvd");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p.vtf");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.mdl");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.dx80.vtx");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.dx90.vtx");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.phy");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.sw.vtx");
    AddFileToDownloadsTable("models/player/ics/skull_admin_v2/skull.vvd");
    AddFileToDownloadsTable("materials/models/player/ics/skull_admin_v2/terrortemp.vmt");
    AddFileToDownloadsTable("materials/models/player/ics/skull_admin_v2/terrortemp.vtf");
    AddFileToDownloadsTable("materials/models/player/ics/skull_admin_v2/terrortemp_normal.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p2.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p2.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_p2_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.mdl");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.phy");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_p2.vvd");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_pc.vmt");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_pc.vtf");
    AddFileToDownloadsTable("materials/models/player/techknow/prison/leet_pc_n.vtf");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.dx80.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.dx90.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.mdl");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.phy");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.sw.vtx");
    AddFileToDownloadsTable("models/player/techknow/prison/leet_pc.vvd");
    return 0;
	}

public Action:PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsClientInGame(client))
 {
        if (IsPlayerAlive(client)) 
{
            decl String:HideAdminX[64];
            decl String:UseAdminCTSkin[64];
            decl String:UseAdminTSkin[64];
            decl String:PlayerUseCTSkin[64];
            decl String:PlayerUseTSkin[64];
            GetClientCookie(client, AdminVisibility, HideAdminX, 64);
            GetClientCookie(client, AdminUseCTSkin, UseAdminCTSkin, 64);
            GetClientCookie(client, AdminUseTSkin, UseAdminTSkin, 64);
            GetClientCookie(client, UseCTSkin, PlayerUseCTSkin, 64);
            GetClientCookie(client, UseTSkin, PlayerUseTSkin, 64);
            new AdminSkinEnabled = GetConVarInt(FindConVar("sm_jail_adminskin"));
            if (GetClientTeam(client) == 3) 
{
                if (GetUserAdmin(client) != -1)
 {
                    if (!StringToInt(HideAdminX, 10)) 
{
                        if (AdminSkinEnabled)
 {
                            if (!(StringToInt(UseAdminCTSkin, 10)))
 {
                                SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
}
                            if (StringToInt(UseAdminCTSkin, 10) == 1) 
{
                                SetEntityModel(client, "models/player/natalya/police/chp_female_jacket.mdl");
}
                            if (StringToInt(UseAdminCTSkin, 10) == 2)
 {
                                SetEntityModel(client, "models/player/natalya/police/chp_female_shirt.mdl");
}
                            if (StringToInt(UseAdminCTSkin, 10) == 1337) 
{
                                new RandomSkin = GetRandomInt(0, 1);
                                if (!RandomSkin)
{
                                    SetEntityModel(client, "models/player/natalya/police/chp_female_jacket.mdl");}
                                if (RandomSkin == 1)
 {
                                    SetEntityModel(client, "models/player/natalya/police/chp_female_shirt.mdl");
                                }
                            }
                        } 
else
{
                            if (StringToInt(PlayerUseCTSkin, 10)) 
{
                            } 
else 
{
                                SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
                            }
                        }
                    } 
else 
{
                        if (StringToInt(PlayerUseCTSkin, 10))
{
                        } 
else
{
                            SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
                        }
                    }
                }
                if (StringToInt(PlayerUseCTSkin, 10))
 {
                } 
else 
{
                    SetEntityModel(client, "models/player/natalya/police/chp_male_jacket.mdl");
                }
            }
            if (GetClientTeam(client) == 2) 
{
                if (GetUserAdmin(client) != -1)
{
                    if (!StringToInt(HideAdminX, 10)) 
{
                        if (AdminSkinEnabled)
{
                            if (StringToInt(UseAdminTSkin, 10) == 1337) 
{
                                new RandomSkin = GetRandomInt(0, 2);
                                if (!RandomSkin) 
{
                                    SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                                }
                                if (RandomSkin == 1) 
{
                                    SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                                }
                                if (RandomSkin == 2) {
                                    SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                                }
                            }
                            if (!(StringToInt(UseAdminTSkin, 10))) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                            }
                            if (StringToInt(UseAdminTSkin, 10) == 1) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                            }
                            if (StringToInt(UseAdminTSkin, 10) == 2) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                            }
                            if (StringToInt(UseAdminTSkin, 10) == 3) {
                                SetEntityModel(client, "models/player/ics/skull_admin_v2/skull.mdl");
                            }
                        } 
else
 {
                            if (StringToInt(PlayerUseTSkin, 10) == 1337) {
                                new RandomSkin = GetRandomInt(0, 2);
                                if (!RandomSkin) 
{
                                    SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                                }
                                if (RandomSkin == 1) 
{
                                    SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                                }
                                if (RandomSkin == 2) 
{
                                    SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                                }
                            }
                            if (!(StringToInt(PlayerUseTSkin, 10))) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                            }
                            if (StringToInt(PlayerUseTSkin, 10) == 1) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                            }
                            if (StringToInt(PlayerUseTSkin, 10) == 2) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                            }
                        }
                    } 
else 
{
                        if (StringToInt(PlayerUseTSkin, 10) == 1337) 
{
                            new RandomSkin = GetRandomInt(0, 2);
                            if (!RandomSkin) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                            }
                            if (RandomSkin == 1) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                            }
                            if (RandomSkin == 2) 
{
                                SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                            }
                        }
                        if (!(StringToInt(PlayerUseTSkin, 10))) 
{
                            SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                        }
                        if (StringToInt(PlayerUseTSkin, 10) == 1) 
{
                            SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                        }
                        if (StringToInt(PlayerUseTSkin, 10) == 2) 
{
                            SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                        }
                    }
                }
                if (StringToInt(PlayerUseTSkin, 10) == 1337) 
{
                    new RandomSkin = GetRandomInt(0, 2);
                    if (!RandomSkin) 
{
                        SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                    }
                    if (RandomSkin == 1) 
{
                        SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                    }
                    if (RandomSkin == 2) 
{
                        SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                    }
                }
                if (!(StringToInt(PlayerUseTSkin, 10))) 
{
                    SetEntityModel(client, "models/player/techknow/prison/leet_p.mdl");
                }
                if (StringToInt(PlayerUseTSkin, 10) == 1) 
{
                    SetEntityModel(client, "models/player/techknow/prison/leet_p2.mdl");
                }
                if (StringToInt(PlayerUseTSkin, 10) == 2) 
{
                    SetEntityModel(client, "models/player/techknow/prison/leet_pc.mdl");
                }
            }
        }
    }
    return Action:0;
	
}