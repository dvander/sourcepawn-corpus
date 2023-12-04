/**************************************************************************
 *                                                                        *
 *                L4D2 Statistaic and Ranking System (SRS) 		     	  *
 *                            Author: pan0s                               *
 *                          Version: v2.5(LTS)                            *
 *                                                                        *
 **************************************************************************/

/*
                                       Update LOG
====================================================================================================
v2.5 (17 March 2022)
   -Fixed page bugs.

v2.4 (17 March 2022)
   -Using [--] instead of N/A country name tag

v2.3 (15 March 2022)
   -Fixed SRS Panel pressing 0 can not close.

v2.2 (8 March 2022)
   -Fixed cheat command

v2.1 (23 June 2021)
   -Initial project
====================================================================================================
*/

#include <adminmenu>
#include <GeoResolver>
#include <hextags>
#include <pan0s>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <srs_cv>

#define PLUGIN_VERSION "v2.5(LTS)"
#define DATABASE       "l4d2_srs"    // SQLITE

// #define EFFECT_BALL				"electrical_arc_01_cp0" // Combo Level Up effect
// #define EFFECT_ELECTRON			"electrical_arc_01_system" // Combo Level Up effect
#define EFFECT_BALL       "mini_fireworks"             // Combo Level Up effect
#define EFFECT_ELECTRON   "achieved"                   // Combo Level Up effect
#define COMBO_LEVEL_SOUND "./level/bell_impact.wav"    // Combo Level Up Sound
#define JOIN_SOUND        "./ambient/tones/elev1.wav"

#define CVAR_FLAGS FCVAR_NOTIFY
#pragma tabsize 0
#pragma newdecls required

Handle g_hFowards[2];
Handle g_tUpdateInterval;

// SRS core entity
int    g_iSRSs[MAXPLAYERS + 1][SRS_TYPE_SIZE][SRS_CODE_SIZE];
Player g_players[MAXPLAYERS + 1];

int    g_iTop10SRSs[11][SRS_TYPE_SIZE][SRS_CODE_SIZE];
Player g_pTop10[11];

// Golbal MVP list
int   g_iClients[MAXPLAYERS + 1];
float g_fScores[MAXPLAYERS + 1];

// Panel
ConVar g_hCvar_panel_refresh_time;

ConVar g_hCvar_scores[SRS_CODE_SIZE];
// Combo
ConVar g_hCvar_combo_time, g_hCvar_combo_time_min, g_hCvar_combo_time_decrease, g_hCvar_combo_level, g_hCvar_combo_level_multiply_score;
ConVar g_hCvar_difficulties[sizeof(g_sDifficulties)];
ConVar g_hCvar_gamemodes[sizeof(g_sGamemodes)];
ConVar g_hCvar_combo_level_sound_on;
ConVar g_hCvar_combo_level_effect_on;

ConVar g_hCvar_infinite_ammo_on;
ConVar g_hCvar_extra_ci_spawn_time;

ConVar g_hCvar_sound_join;
ConVar g_hCvar_country_tag;
ConVar g_hCvar_rank_tag;

float g_iCISpawnTime;

bool g_bIsLate;
bool g_bReady;    // Check it is ready to spawn CI
bool g_bTag;      // used for handle printing change name message

// current game setting variables
ConVar      g_hCvar_refresh_game_settings_time;
ConVar      g_hCvar_frame_move_time;
float       g_iRefreshTime;    // To store next remaining refresh time.
GameSetting g_gameSetting;
ConVar      g_cvDifficulty;    // To store current difficulty ConVar
ConVar      g_cvGamemode;      // To store current gamemode ConVar

// Database variables
Database g_db;

ConVar g_hCvar_command_white_list;

float g_fTop10LoadTime;

int g_iHumanNo;

public Plugin Info = {
	name        = "L4D2 Statistaic And Ranking System",
	description = "Record almost all l4d2 game data, and use them to make a SRS.",
	author      = "pan0s",
	version     = PLUGIN_VERSION,
	url         = ""
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_srs.phrases");
	LoadTranslations("l4d2_weapons.phrases");
	LoadTranslations("l4d2_tags.phrases");

	RegAdminCmd("sm_score", HandleCmdScore, ADMFLAG_ROOT);
	RegAdminCmd("sm_rebuildsrs", HandleCmdRebuildSRS, ADMFLAG_ROOT);
	RegAdminCmd("sm_updatesrs", HandleCmdUpdateSRS, ADMFLAG_ROOT);
	RegAdminCmd("sm_t2", HandleCmdT2, ADMFLAG_ROOT);
	RegConsoleCmd("sm_rank", HandleCmdSRS);
	RegConsoleCmd("sm_status", HandleCmdSRS);
	RegConsoleCmd("sm_state", HandleCmdSRS);
	RegConsoleCmd("sm_rank_eff", HandleCmdEff);
	RegConsoleCmd("sm_rank_sound", HandleCmdSound);
	RegConsoleCmd("sm_rank_auto", HandleCmdAuto);
	RegConsoleCmd("sm_top10", HandleCmdTop10);
	RegConsoleCmd("sm_top", HandleCmdTop10);
	RegConsoleCmd("sm_mvp", HandleCmdMVP);

	// Command White list
	g_hCvar_command_white_list = CreateConVar("srs_command_white_list", "sm_top,sm_ji,sm_top10,sm_ivoteblock,sm_menu,sm_ivote,sm_ihud,sm_csm,sm_lightmenu,sm_hat,sm_hats,sm_shop,sm_admin,sm_team,sm_teams,sm_buy,sm_market,sm_item,sm_items,sm_usepoint,sm_usepoints,sm_buy_confirm,sm_kill,sm_suicide", "Add your server commands that open a menu/panel to here so that the panel will not block menu.\nUse ',' to split commands.", CVAR_FLAGS);

	// Combo ConVar
	g_hCvar_combo_level_sound_on       = CreateConVar("srs_combo_level_sound_on", "1", "Combo Level Up sound.\n0=OFF, 1=ON", CVAR_FLAGS);
	g_hCvar_combo_level_effect_on      = CreateConVar("srs_combo_level_effect_on", "1", "Combo Level Up effect.\n0=OFF, 1=ON", CVAR_FLAGS);
	g_hCvar_combo_time                 = CreateConVar("srs_combo_time", "10.0", "0=off\nCombo time", CVAR_FLAGS);
	g_hCvar_combo_time_min             = CreateConVar("srs_combo_time_min", "2.5", "Minimun combo time after decreasing by combo level", CVAR_FLAGS);
	g_hCvar_combo_time_decrease        = CreateConVar("srs_combo_time_decrease", "0.4", "How many seconds to decrease for each level?", CVAR_FLAGS);
	g_hCvar_combo_level                = CreateConVar("srs_combo_level", "5", "How many Combo for each level?", CVAR_FLAGS);
	g_hCvar_combo_level_multiply_score = CreateConVar("srs_combo_level_multiply_score", "1.05", "How many value for each level to multiply the score?", CVAR_FLAGS);

	g_hCvar_panel_refresh_time = CreateConVar("srs_combo_level_refresh_time", "0.1", "How many second for each refreshing the panel data??", CVAR_FLAGS);

	g_hCvar_sound_join  = CreateConVar("srs_sound_join", "1", "Join sound?\n0=Off, 1=On", CVAR_FLAGS);
	g_hCvar_country_tag = CreateConVar("srs_country_tag", "1", "Add [--] country tag before the name?\n0=Off, 1=On", CVAR_FLAGS);
	g_hCvar_rank_tag    = CreateConVar("srs_rank_tag", "1", "Add [Rank.X] tag before the name?\n0=Off, 1=On", CVAR_FLAGS);

	g_hCvar_difficulties[0] = CreateConVar("srs_difficulty_easy", "0.5", "How many score multiply/divide in easy difficulty?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_difficulties[1] = CreateConVar("srs_difficulty_normal", "1.0", "How many score multiply/divide in normal difficulty?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_difficulties[2] = CreateConVar("srs_difficulty_hard", "1.5", "How many score multiply/divide in hard difficulty?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_difficulties[3] = CreateConVar("srs_difficulty_impossible", "2.0", "How many score multiply/divide in impossible difficulty?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	g_hCvar_gamemodes[0] = CreateConVar("srs_gamemode_survival", "1.0", "How many score multiply/divide in survival gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[1] = CreateConVar("srs_gamemode_coop", "1.0", "How many score multiply/divide in coop gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[2] = CreateConVar("srs_gamemode_scavenge", "1.0", "How many score multiply/divide in scavenge gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[3] = CreateConVar("srs_gamemode_realism", "1.0", "How many score multiply/divide in realism gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[4] = CreateConVar("srs_gamemode_versus", "1.0", "How many score multiply/divide in versus gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[5] = CreateConVar("srs_gamemode_teamscavenge", "1.0", "How many score multiply/divide in teamscavenge gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_gamemodes[6] = CreateConVar("srs_gamemode_teamversus", "1.0", "How many score multiply/divide in teamversus gamemod?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	g_hCvar_refresh_game_settings_time = CreateConVar("srs_refresh_game_settings_time", "5.0", "How many seconds for refreshing game settings once?", CVAR_FLAGS);

	g_hCvar_frame_move_time = CreateConVar("srs_frame_move_time", "0.1", "How many seconds for frame move once? (Affect all timer)", CVAR_FLAGS);

	g_hCvar_infinite_ammo_on    = CreateConVar("srs_infinite_ammo_on", "0", "Infinite ammo?\n0=OFF, 1=ON but not M60/GL, 2=ON", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hCvar_extra_ci_spawn_time = CreateConVar("srs_extra_ci_spawn_time", "60.0", "Extra common intected spawn time.\n-1=OFF,0=Depends on amount of players (60 - (survivors*3), min=30.0)", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_CI] = CreateConVar("srs_s_k_ci_score", "1.2", "How many score for killing a common infected? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SK] = CreateConVar("srs_s_k_sk_score", "3.8", "How many score for killing a Smoker? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_B]  = CreateConVar("srs_s_k_b_score", "3.8", "How many score for killing a Boomer? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_H]  = CreateConVar("srs_s_k_h_score", "3.8", "How many score for killing a Hunter? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_ST] = CreateConVar("srs_s_k_st_score", "3.8", "How many score for killing a Spitter? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_J]  = CreateConVar("srs_s_k_j_score", "3.8", "How many score for killing a Jockey? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_C]  = CreateConVar("srs_s_k_c_score", "3.8", "How many score for killing a Changer? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_W]  = CreateConVar("srs_s_k_w_score", "10.0", "How many score for killing a Witch? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_T]  = CreateConVar("srs_s_k_t_score", "33.8", "How many score for killing a Tank? (Survivor)", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_CI_HS] = CreateConVar("srs_s_k_ci_hs_score", "3.8", "How many score for killing a common infected by headshot? (Survivor)", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SK_HS] = CreateConVar("srs_s_k_sk_hs_score", "8.88", "How many score for killing a Smoker? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_B_HS]  = CreateConVar("srs_s_k_b_hs_score", "8.88", "How many score for killing a Boomer? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_H_HS]  = CreateConVar("srs_s_k_h_hs_score", "8.88", "How many score for killing a Hunter? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_ST_HS] = CreateConVar("srs_s_k_st_hs_score", "8.88", "How many score for killing a Spitter? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_J_HS]  = CreateConVar("srs_s_k_j_hs_score", "8.88", "How many score for killing a Jockey? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_C_HS]  = CreateConVar("srs_s_k_c_hs_score", "8.88", "How many score for killing a Changer? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_W_HS]  = CreateConVar("srs_s_k_w_hs_score", "8.88", "How many score for killing a Witch? (Survivor) by headshot", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_T_HS]  = CreateConVar("srs_s_k_t_hs_score", "8.88", "How many score for killing a Tank? (Survivor) by headshot", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_W_OS] = CreateConVar("srs_s_k_w_os_score", "100.0", "How many score for killing a Witch in one shot? (Survivor)", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_SMG]      = CreateConVar("srs_s_k_smg", "1.5", "How many score multiply/divide for killing a ci/si by smg?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SILENCED] = CreateConVar("srs_s_k_silenced", "1.5", "How many score multiply/divide for killing a ci/si by SMG silenced?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_MP5]      = CreateConVar("srs_s_k_mp5", "1.5", "How many score multiply/divide for killing a ci/si by mp5?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_M16]      = CreateConVar("srs_s_k_m16", "1.2", "How many score multiply/divide for killing a ci/si by m16?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_DESERT]   = CreateConVar("srs_s_k_desert", "1.2", "How many score multiply/divide for killing a ci/si by Desert?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_AK47]     = CreateConVar("srs_s_k_ak47", "1.2", "How many score multiply/divide for killing a ci/si by ak47?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SG552]    = CreateConVar("srs_s_k_sg552", "1.2", "How many score multiply/divide for killing a ci/si by Sg552?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_M60]      = CreateConVar("srs_s_k_m60", "1.2", "How many score multiply/divide for killing a ci/si by m60?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_HUNTING]  = CreateConVar("srs_s_k_hunting", "1.2", "How many score multiply/divide for killing a ci/si by Hunting?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_MILITARY] = CreateConVar("srs_s_k_military", "1.2", "How many score multiply/divide for killing a ci/si by Military?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SCOUT]    = CreateConVar("srs_s_k_scout", "1.2", "How many score multiply/divide for killing a ci/si by Scout?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_AWP]      = CreateConVar("srs_s_k_awp", "2.0", "How many score multiply/divide for killing a ci/si by Awp?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_PUMP]     = CreateConVar("srs_s_k_pump", "1.5", "How many score multiply/divide for killing a ci/si by pump?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_CHROME]   = CreateConVar("srs_s_k_chrome", "1.5", "How many score multiply/divide for killing a ci/si by chrome?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_AUTO]     = CreateConVar("srs_s_k_auto", "1.2", "How many score multiply/divide for killing a ci/si by auto?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SPAS]     = CreateConVar("srs_s_k_spas", "1.2", "How many score multiply/divide for killing a ci/si by spas?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_PISTOL]   = CreateConVar("srs_s_k_pistol", "3.0", "How many score multiply/divide for killing a ci/si by pistol?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_MAGNUM]   = CreateConVar("srs_s_k_magnum", "2.0", "How many score multiply/divide for killing a ci/si by magnum?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_GL]       = CreateConVar("srs_s_k_gl", "0.5", "How many score multiply/divide for killing a ci/si by Grenade Launcher?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_KATANA]    = CreateConVar("srs_s_k_katana", "1.88", "How many score multiply/divide for killing a ci/si by katana?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_AXE]       = CreateConVar("srs_s_k_axe", "1.88", "How many score multiply/divide for killing a ci/si by AXE?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_MACHATE]   = CreateConVar("srs_s_k_machate", "1.88", "How many score multiply/divide for killing a ci/si by machate?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_KNIFE]     = CreateConVar("srs_s_k_knife", "1.88", "How many score multiply/divide for killing a ci/si by knife?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SAW]       = CreateConVar("srs_s_k_saw", "1.22", "How many score multiply/divide for killing a ci/si by saw?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_PITCHFORK] = CreateConVar("srs_s_k_pitchfork", "1.88", "How many score multiply/divide for killing a ci/si by pitchfork?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_SHOVEL]    = CreateConVar("srs_s_k_shovel", "1.88", "How many score multiply/divide for killing a ci/si by shovel?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_GOLF]      = CreateConVar("srs_s_k_golf", "1.88", "How many score multiply/divide for killing a ci/si by golf?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_GUITAR]    = CreateConVar("srs_s_k_guitar", "1.88", "How many score multiply/divide for killing a ci/si by guitar?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_TONFA]     = CreateConVar("srs_s_k_tonfa", "1.88", "How many score multiply/divide for killing a ci/si by tonfa?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_BASEBALL]  = CreateConVar("srs_s_k_tonfa", "1.88", "How many score multiply/divide for killing a ci/si by baseballc?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_CRICKET]   = CreateConVar("srs_s_k_cricket", "1.88", "How many score multiply/divide for killing a ci/si by cricket?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_PAN]       = CreateConVar("srs_s_k_pan", "1.88", "How many score multiply/divide for killing a ci/si by Pan?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_CROWBAR]   = CreateConVar("srs_s_k_crowbar", "1.88", "How many score multiply/divide for killing a ci/si by crowbar?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_K_MOLO] = CreateConVar("srs_s_k_molo", "0.1", "How many score multiply/divide for killing a ci/si by molotov?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_PIPE] = CreateConVar("srs_s_k_pipe", "0.1", "How many score multiply/divide for killing a ci/si by pipe bomb?\n1.0=No Multiply/Divide", CVAR_FLAGS);
	g_hCvar_scores[SRS_S_K_NONE] = CreateConVar("srs_s_k_none", "0.1", "How many score multiply/divide for killing a ci/si by none weapon?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	g_hCvar_scores[SRS_S_SHOT] = CreateConVar("srs_s_k_pipe", "0.1", "How many score multiply/divide for killing a ci/si by pipe bomb?\n1.0=No Multiply/Divide", CVAR_FLAGS);

	AutoExecConfig(true, "l4d2_srs", "sourcemod");

	// Survivor Hook
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("award_earned", Event_AwardEarned);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);

	// Special Infected Hook
	HookEvent("player_now_it", Event_BoomerVomit);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("charger_impact", Event_ChargerImpact);
	HookEvent("charger_pummel_start", Event_ChargerPummel);
	HookEvent("zombie_ignited", Event_SIBurned);

	// Survivor/Special Infected Hook
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);

	// Common Hook
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_PlayLeftCheckpoint);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("door_open", Event_PlayLeftCheckpoint);

	// Join Hook
	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);
	HookEvent("player_connect", Event_BlockBroadcast, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_BlockBroadcast, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);

	// Timers
	delete g_tUpdateInterval;
	g_tUpdateInterval = CreateTimer(g_hCvar_frame_move_time.FloatValue, FrameMove, _, TIMER_REPEAT);

	RefreshGameSetting();

	// Connect to database
	Database.Connect(OnConnectDB, DATABASE);

	if (g_bIsLate)
	{
		RefreshGameSetting();
		RegWhiteListCmd();
	}

	RegWhiteListCmd();

	// set nb_update_frequency
	int flag = GetCommandFlags("nb_update_frequency");
	SetCommandFlags("nb_update_frequency 0", flag & ~FCVAR_CHEAT);
}

public void RegWhiteListCmd()
{
	char cmds[512];
	g_hCvar_command_white_list.GetString(cmds, sizeof(cmds));
	int  index = 0;
	char cmd[32];
	for (int i = 0; i < sizeof(cmds); i++)
	{
		if (cmds[i] == '\0') break;

		if (cmds[i] == ',')
		{
			index = 0;
			RegConsoleCmd(cmd, HandleWhiteListCmd);
			for (int j = 0; j < sizeof(cmd); j++)
				cmd[j] = '\0';
		}
		else
			cmd[index++] = cmds[i];
	}
}

// ====================================================================================================
//					pan0s | Database functions (Async)
// ====================================================================================================
public void OnConnectDB(Database db, const char[] error, any data)
{
	if (db == null)
		LogError("[Error]: Failed to Connect Database \"%s\": \"%s\" ", DATABASE, error);
	else
	{
		g_db = db;
		CallDBAgent(DBA_CREATE, 0);
	}
}

public void CallDBAgent(SRS_DBA action, int client)
{
	if (g_db != null)
	{
		char steamId[32];
		char name[MAX_NAME_LENGTH];
		char query[1024];
		if (IsValidClient(client))
		{
			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			GetClientName(client, name, sizeof(name));
			Format(g_players[client].steamId, sizeof(steamId), steamId);
			Format(g_players[client].name, sizeof(name), name);

			ReplaceString(name, sizeof(name), "'", "''", false);
		}
		switch (action)
		{
			case DBA_CREATE:
			{
				char longQuery[8194];
				Format(longQuery, sizeof(longQuery),
				       "CREATE TABLE IF NOT EXISTS SRS( \
				CreatedDate DATETIME NOT NULL DEFAULT LOCALTIME, \
				LastUpdatedDate DATETIME NOT NULL DEFAULT LOCALTIME, \
				SteamId VARCHAR(255) NOT NULL, \
				Name VARCHAR(255) NOT NULL, \
				Score REAL DEFAULT 0.0, \
				MaxScore REAL DEFAULT 0.0, \
				PlayedTime REAL DEFAULT 0.0, \
				ComboSound INTEGER DEFAULT 1, \
				ComboEffect INTEGER DEFAULT 1");

				for (int i = 0; i < sizeof(g_sSRSCode); i++)
					Format(longQuery, sizeof(longQuery), "%s,%s INTEGER DEFAULT 0", longQuery, g_sSRSCode[i]);
				Format(longQuery, sizeof(longQuery), "%s,Auto_Open INTEGER DEFAULT 0", longQuery);
				Format(longQuery, sizeof(longQuery), "%s,PRIMARY KEY (steamId))", longQuery);
				g_db.Query(OnCreateTable, longQuery);
			}
			case DBA_DROP:
			{
				g_db.Query(OnUpdateRow, "DROP TABLE SRS");
				CallDBAgent(DBA_CREATE, 0);
				CPrintToChat(client, "SRS has been rebuilt successfully.")
			}
			case DBA_ALTER:
			{
				g_db.Query(OnUpdateRow, "ALTER TABLE SRS ADD COLUMN Auto_Open INTEGER DEFAULT 0");
				CPrintToChat(client, "[SRS] Updated.");
				// g_db.Query(OnCreateTable, "ALTER TABLE SRS ADD COLUMN MaxScore REAL DEFAULT 0.0");
			}
			case DBA_TOP10:
			{
				Format(query, sizeof(query), "SELECT ROW_NUMBER() OVER (ORDER BY score DESC) AS `Rank`, SRS.* FROM SRS LIMIT 0,10"); //"SELECT ROW_NUMBER () OVER (ORDER BY score  DESC) Rank , * FROM SRS LIMIT 0,10");
				g_db.Query(OnSelectTop10Row, query, client);
			}
			case DBA_LOAD:
			{
				Format(query, sizeof(query), "SELECT * FROM(SELECT RANK() OVER(ORDER BY t.Score DESC, t.CreatedDate DESC) globalRank, t.* FROM(SELECT * FROM SRS GROUP BY SteamId) t) rt WHERE rt.SteamId='%s'", steamId);
				g_db.Query(OnSelectRow, query, client);
			}

			case DBA_SAVE:
			{
				char longQuery[4096];
				Format(longQuery, sizeof(longQuery), "UPDATE SRS SET Name='%s',Score=%.3f,MaxScore=%.3f,PlayedTime=%.1f,LastUpdatedDate=LOCALTIME,ComboSound=%b,ComboEffect=%b,Auto_Open=%b", name, g_players[client].fScore[SRS_TYPE_DB], g_players[client].fMaxScore, g_players[client].fPlayedTime[SRS_TYPE_DB], g_players[client].combo.bSound, g_players[client].combo.bEff, g_players[client].bAutoOpen);
				// PrintToServer(longQuery);
				for (int i = 0; i < sizeof(g_sSRSCode); i++) Format(longQuery, sizeof(longQuery), "%s,%s=%d", longQuery, g_sSRSCode[i], g_iSRSs[client][SRS_TYPE_DB][i]);
				Format(longQuery, sizeof(longQuery), "%s WHERE steamId='%s'", longQuery, steamId, name);

				// DataPack pack = new DataPack();
				// g_db.Query(OnUpdateRow, longQuery, pack);
				g_db.Query(OnUpdateRow, longQuery, client);
				LogMessage("[UPDATE]: \"%L\" saved. Score: %.1f", client, g_players[client].fScore[SRS_TYPE_DB]);

				// pack.WriteFloat(g_players[client].fScore[SRS_TYPE_DB]);
				// pack.WriteString(name);
				// pack.WriteString(steamId);

				// DBResultSet rs = SQL_Query(g_db, longQuery, sizeof(longQuery));
				// if(rs.AffectedRows>0)
				// 	LogMessage("[UPDATE]: \"%L\" saved. Score: %.1f", client, g_players[client].fScore[SRS_TYPE_DB]);
				// else
				// 	LogError("[UPDATE]: Failed to save \"%L\"", client);
			}
			case DBA_INSERT:
			{
				// PrintToServer("[SRS] ==========DBA_INSERT(1) %s=======================", steamId)
				if (strcmp("STEAM_ID_STOP_IGNORING_RETVALS", steamId, false) == 0) return;
				Format(query, sizeof(query), "INSERT INTO SRS(steamId, name) VALUES('%s', '%s')", steamId, name);
				g_db.Query(OnInsertRow, query, client);
				// PrintToServer("[SRS] ==========DBA_INSERT(2)=======================")
			}
		}
	}
}

public void OnCreateTable(Database db, DBResultSet rs, const char[] error, int client)
{
	if (!rs) LogError("[CREATE]: Failed to Create SRS table: \"%s\"", error);
	else
	{
		if (rs.RowCount > 0) LogMessage("[CREATE]: Created SRS table successfully.");
		else PrintToServer("[CREATE]: DB function of SRS is running successfully.");
	}
}

public void OnUpdateRow(Database db, DBResultSet rs, const char[] error, int client)
{
	// pack.Reset();
	// float score = pack.ReadCell();
	// char name[64];
	// char steamId[32];
	// char logName[sizeof(name)+sizeof(steamId)];
	// pack.ReadString(steamId, sizeof(steamId));
	// pack.ReadString(name, sizeof(name));

	// Format(logName, sizeof(logName), "%s<%s><>", name, steamId);

	// PrintToServer("(2)============================");
	// if(!rs) LogError("[UPDATE]: Failed to update \"%\" Score %.1f: \"%s\"", logName, score, error);
	// else
	// {
	// 	LogMessage("[UPDATE]: \"%s\" saved. Score: %.1f", logName, score);
	// }
	// CloseHandle(pack)
}

public void OnInsertRow(Database db, DBResultSet rs, const char[] error, int client)
{
	if (!rs) LogError("[INSERT]: Failed to insert \"%L\": \"%s\"", client, error);
	else
	{
		LogMessage("[INSERT]: \"%L\" is a new user!!!", client);

		// Get & Set rank for the new user.
		char query[64];
		Format(query, sizeof(query), "SELECT COUNT(*) as Total FROM SRS");
		db.Query(OnSelectCount, query, client);
		OpenPanel(g_players[client]);
	}
}

public void OnSelectCount(Database db, DBResultSet rs, const char[] error, int client)
{
	if (!rs) LogError("[SELECT]: Failed to select count * for \"%L\": \"%s\"", client, error);
	else
	{
		if (rs.FetchRow())
		{
			g_players[client].rank[SRS_TYPE_DB] = rs.FetchInt(0);    // last rank
			CreateTimer(0.8, HandleShowJoinTimer, client);
			LogMessage("[LOAD]: New user \"%L\" loaded rank.", client, g_players[client].rank[SRS_TYPE_DB]);
		}
	}
}

public void SetPlayerinfo(DBResultSet rs, Player p, int[][][] srsEntity, bool isTop10)
{
	// 0=rank
	//  1,2=date
	//  3=steamid
	//  4=name
	//  5=score
	//  6=max score
	//  7=playedTimer
	//  8=sound
	//  9=eff
	//  10+ SRS entity
	//  n= aftger SRS entity
	int read            = 0;
	p.rank[SRS_TYPE_DB] = rs.FetchInt(read++);                               // 0
	rs.FetchString(read++, p.sCreatedDate, 64);                              // 1
	rs.FetchString(read++, p.sUpdatedDate, 64);                              // 2
	rs.FetchString(read++, p.steamId, 32);                                   // 3
	rs.FetchString(read++, p.name, MAX_NAME_LENGTH);                         // 4
	p.fScore[SRS_TYPE_DB]      = rs.FetchFloat(read++);                      // 5
	p.fMaxScore                = rs.FetchFloat(read++);                      // 6
	p.fPlayedTime[SRS_TYPE_DB] = rs.FetchFloat(read++);                      // 7
	p.combo.bSound             = rs.FetchInt(read++) == 1 ? true : false;    // 8
	p.combo.bEff               = rs.FetchInt(read++) == 1 ? true : false;    // 9

	for (int i = 0; i < SRS_CODE_SIZE; i++)
	{
		srsEntity[p.id][SRS_TYPE_DB][i] = rs.FetchInt(read++);
		// if(isTop10) LogAction(-1,-1,"[SRS] Loaded Top10- %s: %d: %d==============", p.name, read+i, srsEntity[p.id][SRS_TYPE_DB][i]);
	}

	p.bAutoOpen = rs.FetchInt(read++) == 1 ? true : false;    // n+0
															  // if(!isTop10) PrintToServer("%s: %b, %b, %b", p.name, p.combo.bSound , p.combo.bEff, p.bAutoOpen);
}

public void OnSelectTop10Row(Database db, DBResultSet rs, const char[] error, int client)
{
	if (!rs) LogError("[LOAD]: Failed to load TOP10: \"%s\"", error);
	else
	{
		int i = 1;
		while (rs.FetchRow() && i < sizeof(g_pTop10))
		{
			g_pTop10[i].id            = i;
			g_pTop10[i].iPanelSRSType = SRS_TYPE_DB;

			SetPlayerinfo(rs, g_pTop10[i++], g_iTop10SRSs, true);
		}
	}
}

public void OnSelectRow(Database db, DBResultSet rs, const char[] error, int client)
{
	if (!rs) LogError("[LOAD]: Failed to load \"%L\": \"%s\"", client, error);
	else
	{
		if (rs.FetchRow())
		{
			g_players[client].id = client;
			SetPlayerinfo(rs, g_players[client], g_iSRSs, false);

			LogMessage("[LOAD]: \"%L\" loaded. Score: %.1f, Rank: %d", client, g_players[client].fScore[SRS_TYPE_DB], g_players[client].rank[SRS_TYPE_DB]);

			char msg[255];
			Format(msg, sizeof(msg), "%T%T", "SYSTEM", client, "LOADED", client, g_players[client].fScore[SRS_TYPE_DB]);
			CreateTimer(0.8, HandleShowJoinTimer, client);
		}
		else CallDBAgent(DBA_INSERT, client);
	}
}

// Native
// Database ConnectDB()
// {
// 	char error[255];
// 	Database db = SQL_Connect(DATABASE, true, error, sizeof(error));

// 	if (db == null)
// 	{
// 	    LogError("[ERROR]: Could not connect: \"%s\"", error);
// 		return null;
// 	}
// 	else
// 	{
// 		return db;
// 	}
// }
public void LoadRank(const Player p)
{
	// Database db = ConnectDB();
	// if(db == null) return;

	char query[1024];
	Format(query, sizeof(query), "SELECT `globalRank`, score FROM (SELECT RANK() OVER(ORDER BY t.score DESC, t.CreatedDate DESC) AS globalRank, t.* FROM (SELECT * FROM SRS GROUP BY steamId) AS t) AS rt WHERE rt.steamId = '%s'", p.steamId);
	DBResultSet rs = SQL_Query(g_db, query, sizeof(query));
	if (rs.FetchRow())
	{
		int read              = 0;
		p.rank[SRS_TYPE_DB]   = rs.FetchInt(read++);      // 0
		p.fScore[SRS_TYPE_DB] = rs.FetchFloat(read++);    // 0
	}
	else
	{
		char query2[64];
		Format(query2, sizeof(query2), "SELECT COUNT(*) as Total FROM SRS");
		DBResultSet rs2 = SQL_Query(g_db, query2, sizeof(query2));
		if (rs2.FetchRow())
		{
			p.rank[SRS_TYPE_DB]   = rs2.FetchInt(0);    // last rank +1 because the client does not exist in the db right now.
			p.fScore[SRS_TYPE_DB] = 0.0;                // 0
		}
	}
	// delete db;
}

// Show loaded message
public Action HandleShowJoinTimer(Handle timer, int client)
{
	PrintJoinMsgToAll(g_players[client]);
	AddCountryTag(g_players[client]);

	if (g_players[client].bAutoOpen)
	{
		g_players[client].iPanelType = PT_ME;
		OpenPanel(g_players[client]);
	}

	char msg[255];
	Format(msg, sizeof(msg), "%T%T", "SYSTEM", client, "LOADED", client, g_players[client].fScore[SRS_TYPE_DB]);
	if (IsValidClient(client)) CPrintToChat(client, msg);
	return Plugin_Handled;
}

// ====================================================================================================
//					pan0s | Override functions
// ====================================================================================================
public void OnMapStart()
{
	PrecacheSound(COMBO_LEVEL_SOUND, false);

	PrecacheParticle(EFFECT_BALL);
	PrecacheParticle(EFFECT_ELECTRON);

	PrecacheSound(JOIN_SOUND, false);
}

public void PrecacheParticle(const char[] particlename)
{
	/* Precache particle */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

public void ShowParticle(const float pos[3], const char[] particlename, float time)
{
	/* Show particle effect you like */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			RemoveEdict(particle);
	}

	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	// forward
	Call_StartForward(g_hFowards[0]);
	Call_Finish();
}

public void OnPluginEnd()
{
	Action result;
	Call_StartForward(g_hFowards[1]);
	Call_Finish(view_as<int>(result));
}

public void OnClientConnected(int client)
{
	if (client && !IsFakeClient(client))
	{
		if (g_hCvar_sound_join.BoolValue) EmitSoundToAll(JOIN_SOUND, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i))
				CPrintToChat(i, "%T%T", "TAG_ANNOUNCE", i, "CONNECTING", i, client);
	}

	g_players[client].id = client;
	Reset(g_players[client], false);
}


public void OnClientDisconnect(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i))
				CPrintToChat(i, "%T%T", "TAG_ANNOUNCE", i, "LEFT", i, client);

		Save(client);
		Reset(g_players[client], false);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client))
	{
		g_players[client].combo.bEff    = true;
		g_players[client].combo.bSound  = true;
		g_players[client].bAutoOpen     = false;
		g_players[client].iPanelSRSType = SRS_TYPE_MVP;
		if (!IsFakeClient(client))
		{
			CallDBAgent(DBA_LOAD, client);
		}
	}
}

// ====================================================================================================
//					pan0s | Native registion
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool isLate, char[] error, int err_max)
{
	char game_name[128];
	GetGameFolderName(game_name, sizeof(game_name));
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("l4d2_srs.phrases");
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("%T", "Game Check Fail", LANG_SERVER);
	}
	// Native function
	CreateNative("SRS_GetVersion", SRS_GetVersion);
	CreateNative("SRS_GetMvp", SRS_GetMvp);
	CreateNative("SRS_GetScore", SRS_GetScore);
	CreateNative("SRS_GetScoreStatus", SRS_GetScoreStatus);
	CreateNative("SRS_GetRankAndScore", SRS_GetRankAndScore);
	CreateNative("SRS_GetOnlinePlayRankAndScore", SRS_GetOnlinePlayRankAndScore);

	g_hFowards[0] = CreateGlobalForward("OnSRSLoaded", ET_Ignore);
	g_hFowards[1] = CreateGlobalForward("OnSRSUnloaded", ET_Ignore);
	RegPluginLibrary("l4d2_srs");
	g_bIsLate = isLate;
	return APLRes_Success;
}

// ====================================================================================================
//					pan0s | Library functions override
// ====================================================================================================
public any SRS_GetVersion(Handle plugin, int numParams)
{
	SetNativeString(1, PLUGIN_VERSION, 10, false);
	return true;
}

public any SRS_GetMvp(Handle plugin, int numParams)
{
	SetNativeArray(1, g_iClients, 4);
	SetNativeArray(2, g_fScores, 4);
	return true;
}

public any SRS_GetScore(Handle plugin, int numParams)
{
	int client  = GetNativeCell(2);
	int srsType = GetNativeCell(2);
	return GetScore(g_players[client], srsType);
}

public any SRS_GetScoreStatus(Handle plugin, int numParams)
{
	int  size = GetNativeCell(2);
	char buffer[64];
	GetScoreStatus(buffer, size);
	SetNativeString(1, buffer, size);
	return true;
}

public any SRS_GetRankAndScore(Handle plugin, int numParams)
{
	Player p;
	GetNativeString(1, p.steamId, 32);

	LoadRank(p);

	SetNativeCellRef(2, p.rank[SRS_TYPE_DB]);
	SetNativeCellRef(3, p.fScore[SRS_TYPE_DB]);
	return true;
}

public any SRS_GetOnlinePlayRankAndScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	SetNativeCellRef(2, g_players[client].rank[SRS_TYPE_DB]);
	SetNativeCellRef(3, g_players[client].fScore[SRS_TYPE_DB]);
	return true;
}

// ====================================================================================================
//					pan0s | Helper functions
// ====================================================================================================
public void GetMvp(int[] buffer1, float[] buffer2, int size)
{
	int tempPlayers[MAXPLAYERS + 1];
	for (int i = 0; i < sizeof(tempPlayers); i++)
	{
		tempPlayers[i] = i;
	}

	SortCustom1D(tempPlayers, sizeof(tempPlayers), SortByScoreDesc);

	for (int i = 0; i < size; i++)
	{
		int client = tempPlayers[i];
		if (IsValidClient(client))
		{
			int srsType = IsFakeClient(client) ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP;
			buffer1[i]  = client;                                  // Client ID
			buffer2[i]  = GetScore(g_players[client], srsType);    // Score
		}
	}
}

public int SortByScoreDesc(const int client1, const int client2, const int[] array, Handle hndl)
{
	// Dont sort SI BOT
	if (!IsValidClient(client1) || (GetClientTeam(client1) == TEAM_INFECTED && IsFakeClient(client1))) return 1;
	if (!IsValidClient(client2) || (GetClientTeam(client2) == TEAM_INFECTED && IsFakeClient(client2))) return -1;

	int srsTypes[2];
	srsTypes[0] = IsFakeClient(client1) ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP;
	srsTypes[1] = IsFakeClient(client2) ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP;

	return CompareDesc(g_players[client1].fScore[srsTypes[0]], g_players[client2].fScore[srsTypes[1]]);
}

public void PrintJoinMsgToAll(Player p)
{
	if (IsValidClientAndHuman(p.id))
	{
		char ip[16];
		char city[32];
		char country[100];
		GetClientIPEx(p.id, ip, 16);
		GeoR_CityEx(ip, city, 32);
		if (GeoR_CountryEx(ip, country, 100))
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClientAndHuman(i))
					CPrintToChat(i, "%T", "JOIN_MESSAGE", i, p.id, country, city, p.rank[SRS_TYPE_DB], p.fScore[SRS_TYPE_DB]);
	}
}

public bool HasTag(char[] name, char[] tag)
{
	if (IndexOf(name, 6, tag, 6) == 0) return true;    // Find tag index to prevent adding tag twice.
	return false;
}

public bool AddCountryTag(Player p)
{
	if (!IsValidClientAndHuman(p.id)) return false;

	char tag[6];
	Format(tag, sizeof(tag), "%N", p.id);

	char ip[16];
	GetClientIPEx(p.id, ip, 16);
	if (g_hCvar_country_tag.BoolValue)
	{
		if (GeoR_CodeEx(ip, p.tag, 6)) Format(p.tag, 6, "[%2s]", p.tag);
		else
			Format(p.tag, 6, "[--]");
		if (HasTag(tag, p.tag)) return false;
		g_bTag = true;
		Format(p.name, MAX_NAME_LENGTH, "%s%N", p.tag, p.id);
		SetClientName(p.id, p.name);
	}
	return true;
}

bool GeoR_CityEx(const char[] ip, char[] buffer, int size)
{
	GeoR_City(ip, buffer, size);
	return IndexOf(buffer, size, "/", 1) == -1;
}

stock bool GeoR_CodeEx(char[] IP, char[] Code, int size)
{
	GeoR_Code(IP, Code, size);
	return IndexOf(Code, size, "/", 1) == -1;
}

stock bool GeoR_CountryEx(const char[] ip, char[] buffer, int size)
{
	GeoR_Country(ip, buffer, size);
	return IndexOf(buffer, size, "/", 1) == -1;
}

// ====================================================================================================
//					pan0s | Score + Combo System
// ====================================================================================================
public float GetScore(const Player p, const int srsType)
{
	return p.fScore[srsType];
}

public int GetComboLevel(const Player p)
{
	return p.combo.iCount / g_hCvar_combo_level.IntValue;
}

public float MultiplyComboScore(const Player p, float fScore)
{
	int   level      = GetComboLevel(p);
	float exBasic    = g_hCvar_combo_level_multiply_score.FloatValue;
	float percentage = 1.0;

	for (int i = 0; i < level; i++)
	{
		percentage *= exBasic;
		fScore *= exBasic;
	}
	p.combo.fPercentage = level > 0 ? percentage : 0.0;

	return fScore;
}

public float CountScore(const Player p, const int srsCode, const int srsWeapon)
{
	float score = g_hCvar_scores[srsCode].FloatValue;

	score = MultiplyComboScore(p, score);
	score *= g_hCvar_scores[srsWeapon].FloatValue;
	score *= g_cvGamemode.FloatValue;
	score *= g_cvDifficulty.FloatValue;
	return score;
}

public void PlayLevelEffect(const Player p)
{
	if (g_hCvar_combo_level_sound_on.BoolValue)
	{
		if (p.combo.bSound)
		{
			EmitSoundToClient(p.id, COMBO_LEVEL_SOUND, -2, 0, 100, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			EmitSoundToClient(p.id, COMBO_LEVEL_SOUND, -2, 0, 150, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}

	if (g_hCvar_combo_level_effect_on.BoolValue)
	{
		if (p.combo.bEff)
		{
			float pos[3];
			GetClientAbsOrigin(p.id, pos);
			pos[2] += 50.0;
			ShowParticle(pos, EFFECT_ELECTRON, 5.0);
			ShowParticle(pos, EFFECT_BALL, 5.0);
		}
	}
}

public void UpdateCombo(const Player p)
{
	int   level     = GetComboLevel(p);
	float decrease  = g_hCvar_combo_time_decrease.FloatValue;
	float basicTime = g_hCvar_combo_time.FloatValue - (level * decrease);
	float minTime   = g_hCvar_combo_time_min.FloatValue;
	minTime         = basicTime >= minTime ? basicTime : minTime

                                                     p.combo.fTime = minTime;
	p.combo.iCount++;

	if (p.combo.iCount % g_hCvar_combo_level.IntValue == 0) PlayLevelEffect(p);
	int srsType = IsFakeClient(p.id) ? SRS_TYPE_DB_BOT : SRS_TYPE_DB;
	if (p.combo.iCount > g_iSRSs[p.id][srsType][SRS_H_MX_CB])
	{
		CallUpdateAgent(p, SRS_H_MX_CB, p.combo.iCount, true);
	}
}

public void GetLevelSymbol(const Player p, char[] buffer, const int size)
{
	int level = GetComboLevel(p);
	for (int i = 0; i < level; i++) Format(buffer, size, "%s↑", buffer);
}

public void PrintCombo(const Player p, const char[] text, const float score)
{
	char symbol[128];
	GetLevelSymbol(p, symbol, sizeof(symbol));
	char s = p.combo.iCount > 1 ? 's' : ' ';
	PrintCenterText(p.id, "%T！ +%.2f (Combo%c %d)%s", text, p.id, score, s, p.combo.iCount, symbol);
}

public void UpdateScore(const Player p, const int srsCodeK, const int srsCodeHS, const bool bHeadshot)
{
	int srcCode = bHeadshot ? srsCodeHS : srsCodeK;

	UpdateCombo(p);
	int   srsWeapon = GetSRSWeaponId(p, false);
	float score     = CountScore(p, srcCode, srsWeapon);
	if (score > p.fMaxScore) p.fMaxScore = score;
	p.fLastScore = score;
	int start    = 0;
	int end      = 0;
	if (IsFakeClient(p.id))
	{
		start = SRS_TYPE_MVP_BOT;
		end   = SRS_TYPE_DB_BOT;
	}
	else
	{
		start = SRS_TYPE_MVP;
		end   = SRS_TYPE_DB;
	}
	for (int i = start; i <= end; i++)
	{
		if (i >= SRS_TYPE_MVP)    // if client is not fake
		{
			if (bHeadshot) PrintCombo(p, "HEADSHOT", score);
			else PrintCombo(p, "KILL", score);
		}
		if (bHeadshot) g_iSRSs[p.id][i][srsCodeHS]++;
		g_iSRSs[p.id][i][srsCodeK]++;
		g_iSRSs[p.id][i][srsWeapon]++;
		g_players[p.id].fScore[i] += score;
	}
}

// ====================================================================================================
//					pan0s | Useful Functions
// ====================================================================================================
public void CallUpdateAgent(const Player p, const int srsCode, const int value, const bool isSet)
{
	if (srsCode == SRS_S_HIT)
	{
		if (!p.bFired) return;    // Do nothing to prevent add hit twice times by one hit.
		p.bFired = false;
	}
	if (srsCode == SRS_S_SHOT) p.bFired = true;
	UpdateSRSData(p.id, srsCode, value, isSet);
}

public void UpdateSRSData(const int client, const int srsCode, const int value, const bool isSet)
{
	if (IsValidClient(client))
	{
		if (IsFakeClient(client))
		{
			for (int i = SRS_TYPE_MVP_BOT; i <= SRS_TYPE_DB_BOT; i++)
				if (isSet) g_iSRSs[client][i][srsCode] = value;
				else g_iSRSs[client][i][srsCode] += value;
		}
		else
		{
			for (int i = SRS_TYPE_MVP; i <= SRS_TYPE_DB; i++)
				if (isSet) g_iSRSs[client][i][srsCode] = value;
				else g_iSRSs[client][i][srsCode] += value;
		}
	}
}

public void SpawnCI()
{
	if (g_hCvar_extra_ci_spawn_time.FloatValue < 0.0) return;

	ArrayList list = new ArrayList();
	list.Clear();
	for (int i = 1; i <= MaxClients; i++)
		if (IsSurvivorAlive(i) && !IsFakeClient(i)) list.Push(i);

	if (list.Length > 0)
	{
		int rand = GetRandomInt(list.Get(0), list.Get(list.Length - 1));
		if (IsValidClient(rand))
		{
			PrintToServer("[SRS] ========== SpawnCI =============");
			CheatCommand(rand, "z_spawn", "mob");
		}
	}
	delete list;
}

public void GiveAmmoBack(const Player p)
{
	int slot = -1;
	int clips;

	GetSlotAndClips(p.id, p.weapon.name, slot, clips, g_hCvar_infinite_ammo_on.IntValue > 1);

	if (slot == 0 || slot == 1)
	{
		int weaponEnt = GetPlayerWeaponSlot(p.id, slot);
		if (weaponEnt > 0 && IsValidEntity(weaponEnt))
			SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clips + 1);
	}
}

public void PrintJoin(const int client, const char[] team)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClientAndHuman(i))
		{
			char translatedTeam[32];
			Format(translatedTeam, sizeof(translatedTeam), "%T", team, i);
			CPrintToChat(i, "%T%T", "TAG_ANNOUNCE", i, "JOIN", i, client, translatedTeam);
		}
}

// ====================================================================================================
//					pan0s | Hook event
// ====================================================================================================
public Action Hook_SayText2(UserMsg msg_id, any msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char[] sMessage = new char[24];

	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pbmsg = msg;
		pbmsg.ReadString("msg_name", sMessage, 24);
	}

	else
	{
		BfRead bfmsg = msg;
		bfmsg.ReadByte();
		bfmsg.ReadByte();
		bfmsg.ReadString(sMessage, 24, false);
	}

	if (StrEqual(sMessage, "#Cstrike_Name_Change") && playersNum >= 1 && g_bTag)
	{
		g_bTag = false;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Event_PlayerChangename(Event event, const char[] name, bool broadcast)
{
	int  client = GetEventClient(event, "userid");
	char newName[MAX_NAME_LENGTH];
	GetEventString(event, "newname", newName, MAX_NAME_LENGTH);
	Format(g_players[client].name, sizeof(newName), newName);
	bool bTag = HasTag(newName, g_players[client].tag);
	if (!bTag)
	{
		delete g_players[client].tTag;
		g_players[client].tTag = CreateTimer(0.01, HandleAddTagTimer, client);
	}

	return Plugin_Continue;
}

public Action HandleAddTagTimer(Handle timer, int client)
{
	AddCountryTag(g_players[client]);
	g_players[client].tTag = null;
	return Plugin_Handled;
}

public Action Event_BlockBroadcast(Event event, const char[] name, bool broadcast)
{
	if (!event.GetBool("silent"))
		event.BroadcastDisabled = true;
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		delete g_players[client].tJoin;
		g_players[client].tJoin = CreateTimer(0.3, HandleTeamTimer, client);
	}
	return Plugin_Handled;
}

public Action HandleTeamTimer(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		int team = GetClientTeam(client) 
		switch (team)
		{
			case 1: PrintJoin(client, "SPECTATE");
			case 2: PrintJoin(client, "SURVIVOR");
			case 3: PrintJoin(client, "INFECTED");
		}
	}

	g_players[client].tJoin = null;
	return Plugin_Handled;
}

// Survivor Hook ------------------------------------------------------------>
public Action Event_WeaponFire(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	event.GetString("weapon", g_players[client].weapon.name, 32);
	// PrintToChat(client, "%s", g_players[client].weapon.name);
	g_players[client].weapon.SetNameToPure();
	// PrintToChat(client, "%s", g_players[client].weapon.name);
	if (g_players[client].weapon.IsGunOrMelee()) CallUpdateAgent(g_players[client], SRS_S_SHOT, 1, false);
	else if (StrEqual(g_players[client].weapon.name, "molotov", false)) CallUpdateAgent(g_players[client], SRS_S_TH_MOLO, 1, false);
	else if (StrEqual(g_players[client].weapon.name, "pipe_bomb", false)) CallUpdateAgent(g_players[client], SRS_S_TH_PIPE, 1, false);
	else if (StrEqual(g_players[client].weapon.name, "vomitjar", false)) CallUpdateAgent(g_players[client], SRS_S_TH_VOMITJAR, 1, false);

	if (g_hCvar_infinite_ammo_on.IntValue > 0) GiveAmmoBack(g_players[client]);

	return Plugin_Handled;
}

public Action Event_InfectedHurt(Event event, char[] event_name, bool dontBroadcast)
{
	int attacker   = GetEventClient(event, "attacker");
	int damage     = event.GetInt("amount");
	int damageType = event.GetInt("type");

	// Add hit
	switch (damageType)
	{
		case DMG_CLUB, DMG_BURN, DMG_PREVENT_PHYSICS_FORCE + DMG_BURN, DMG_DIRECT + DMG_BURN, DMG_BLAST_SURFACE:
		{
		}    // Do nothing
		default: CallUpdateAgent(g_players[attacker], SRS_S_HIT, 1, false);
	}

	CallUpdateAgent(g_players[attacker], SRS_S_DMG, damage, false);

	return Plugin_Handled;
}

public Action Event_InfectedDeath(Event event, char[] event_name, bool dontBroadcast)
{
	int  killer    = GetEventClient(event, "attacker");
	int  weaponId  = event.GetInt("weapon_id");
	bool bHeadshot = event.GetBool("headshot");

	if (!IsSurvivor(killer)) return Plugin_Handled;

	g_players[killer].weapon.id = weaponId;
	g_players[killer].weapon.UpdateName();
	g_players[killer].weapon.SetNameToPure();

	UpdateScore(g_players[killer], SRS_S_K_CI, SRS_S_K_CI_HS, bHeadshot);

	return Plugin_Handled;
}

public Action Event_WitchKilled(Event event, char[] event_name, bool dontBroadcast)
{
	int  killer    = GetEventClient(event, "userid");
	bool bHeadshot = event.GetBool("oneshot");

	if (!IsSurvivor(killer)) return Plugin_Handled;

	Format(g_players[killer].weapon.name, 32, g_players[killer].weapon.activeName);

	UpdateScore(g_players[killer], SRS_S_K_W, SRS_S_K_W_HS, bHeadshot);

	return Plugin_Handled;
}

public Action Event_TankKilled(Event event, char[] event_name, bool dontBroadcast)
{
	// int attacker = GetEventClient(event, "attacker");
	// int client = GetEventClient(event, "userid");

	return Plugin_Handled;
}

public Action Event_PlayerIncapacitated(Event event, char[] event_name, bool dontBroadcast)
{
	int attacker = GetEventClient(event, "attacker");
	int client   = GetEventClient(event, "userid");

	if (IsInfected(attacker) && IsValidClient(attacker)) CallUpdateAgent(g_players[attacker], SRS_I_INCAPACITATE, 1, false);
	if (IsSurvivor(client) && IsValidClient(client)) CallUpdateAgent(g_players[client], SRS_S_INCAPACITATED, 1, false);

	return Plugin_Handled;
}

public Action Event_SurvivorRescued(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "rescuer");
	int target = GetEventClient(event, "victim");

	if (IsInfected(client) || IsInfected(target) || client == target) return Plugin_Handled;

	CallUpdateAgent(g_players[client], SRS_S_RESCUE, 1, false);
	CallUpdateAgent(g_players[target], SRS_S_RESCUED, 1, false);

	return Plugin_Handled;
}

public Action Event_ReviveSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	int target = GetEventClient(event, "subject");

	if (IsInfected(client) || IsInfected(target) || client == target) return Plugin_Handled;

	CallUpdateAgent(g_players[client], SRS_S_REVIVE, 1, false);
	CallUpdateAgent(g_players[target], SRS_S_REVIVED, 1, false);

	return Plugin_Handled;
}

public Action Event_DefibrillatorUsed(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	int target = GetEventClient(event, "subject");

	if (IsInfected(client) || IsInfected(target)) return Plugin_Handled;

	CallUpdateAgent(g_players[client], SRS_S_DEFIBRILLATE, 1, false);
	CallUpdateAgent(g_players[target], SRS_S_DEFIBRILLATED, 1, false);

	return Plugin_Handled;
}

public Action Event_AwardEarned(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	int award  = event.GetInt("award");
	if (IsSurvivor(client))
	{
		if (award == 67)    // Protect someone
		{
			CallUpdateAgent(g_players[client], SRS_S_PROTECT, 1, false);
		}
	}
	return Plugin_Handled;
}
// <------------------------------------------------------------ Survivor Hook
public Action Event_HealSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	int target = GetEventClient(event, "subject");

	CallUpdateAgent(g_players[client], SRS_S_MEDKIT, 1, false);

	if (client != target)
	{
		CallUpdateAgent(g_players[target], SRS_S_HEALED, 1, false);
		CallUpdateAgent(g_players[client], SRS_S_HEAL, 1, false);
	}

	if (client == target)
	{
		CallUpdateAgent(g_players[client], SRS_S_SELF_HEALED, 1, false);
	}

	return Plugin_Handled;
}

public Action Event_PillsUsed(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	CallUpdateAgent(g_players[client], SRS_S_PILLS, 1, false);

	return Plugin_Handled;
}

public Action Event_AdrenalineUsed(Event event, char[] event_name, bool dontBroadcast)
{
	int client = GetEventClient(event, "userid");
	CallUpdateAgent(g_players[client], SRS_S_ADRENALINE, 1, false);

	return Plugin_Handled;
}

// Special Infected Hook ------------------------------------------------------------>
public Action Event_BoomerVomit(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_LungePounce(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_TongueGrab(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_JockeyRide(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_ChargerImpact(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_ChargerPummel(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}

public Action Event_SIBurned(Event event, char[] event_name, bool dontBroadcast)
{
	// TODO: uipdate SRS data

	return Plugin_Handled;
}
// <------------------------------------------------------------ Special Infected Hook

// Survivor/Special Infected Hook ------------------------------------------------------------>
public Action Event_PlayerDeath(Event event, char[] event_name, bool dontBroadcast)
{
	int victim = GetEventClient(event, "userid");
	int killer = GetEventClient(event, "attacker");

	if (IsInfected(victim)) CallUpdateAgent(g_players[victim], SRS_I_DEATH, 1, false);
	else CallUpdateAgent(g_players[victim], SRS_S_DEATH, 1, false);

	if (IsSurvivor(victim) && IsSurvivor(killer)) CallUpdateAgent(g_players[victim], SRS_S_TEAMKILL, 1, false);

	if (IsSurvivor(killer) && IsInfected(victim))
	{
		bool bHeadshot = event.GetBool("headshot");

		event.GetString("weapon", g_players[killer].weapon.name, 32);
		g_players[killer].weapon.SetNameToPure();

		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");    // start from 1 (smoker);
		UpdateScore(g_players[killer], SRS_S_K_SK + zClass - 1, SRS_S_K_SK_HS + zClass - 1, bHeadshot);
	}
	else if (IsInfected(killer) && IsSurvivor(victim))
	{
		CallUpdateAgent(g_players[victim], SRS_I_KILL, 1, false);
	}
	return Plugin_Handled;
}

public Action Event_PlayerHurt(Event event, char[] event_name, bool dontBroadcast)
{
	int attacker = GetEventClient(event, "attacker");
	int victim   = GetEventClient(event, "userid");
	int damage   = event.GetInt("dmg_health");

	event.GetString("weapon", g_players[attacker].weapon.name, 32);
	g_players[attacker].weapon.SetNameToPure();

	// CPrintToChat(attacker, "%s", g_players[attacker].weapon.name);

	CallUpdateAgent(g_players[victim], SRS_S_HURT, damage, false);

	if (IsSurvivor(attacker) && IsInfected(victim))
	{
		if (g_players[attacker].weapon.IsGunOrMelee()) CallUpdateAgent(g_players[attacker], SRS_S_HIT, 1, false);
		CallUpdateAgent(g_players[attacker], SRS_S_DMG, damage, false);
	}
	return Plugin_Handled;
}
// <------------------------------------------------------------ Survivor/Special Infected Hook

// Common Hook ------------------------------------------------------------>
public Action Event_RoundEnd(Event event, char[] event_name, bool dontBroadcast)
{
	g_iCISpawnTime = 0.0;
	g_bReady       = false;
	
	//TODO::add more save to event to prevent rank reset, maybe every 30 seconds???
	SaveAll();
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, char[] event_name, bool dontBroadcast)
{
	ClearAll();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i)) CallDBAgent(DBA_LOAD, i);    // Refresh the ranking.
		if (g_players[i].bAutoOpen)
		{
			g_players[i].iPanelType = PT_ME;
			OpenPanel(g_players[i]);
		}
	}
	// LoadTop10
	CallDBAgent(DBA_TOP10, 0);
	return Plugin_Handled;
}

public Action Event_PlayLeftCheckpoint(Event event, char[] event_name, bool dontBroadcast)
{
	if (!g_bReady)
	{
		int client = GetEventClient(event, "userid");
		if (IsSurvivor(client))
		{
			g_bReady = true;
			SpawnCI();
		}
	}
	return Plugin_Handled;
}
// <------------------------------------------------------------ Common Hook
public void SaveAll()
{
	for (int i = 1; i <= MaxClients; i++)
		Save(i);
}

public void Save(int client)
{
	if (IsValidClientAndHuman(client)) CallDBAgent(DBA_SAVE, client);
}

public void ClearAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		Reset(g_players[i], true);
	}
}

public void Reset(Player p, bool bBot)
{
	if (!IsValidClientIndex(p.id)) return;
	p.iPanelSRSType = 0;
	p.iPanelTarget  = 0;
	p.iPanelSRSType = SRS_TYPE_MVP;

	p.iPanelType    = PT_ME;
	// p.bPanel = false;
	p.bFired        = false;
	p.bMVPSelecting = true;

	if (IsValidClient(p.id))
	{
		GetClientName(p.id, p.name, MAX_NAME_LENGTH);
		GetClientAuthId(p.id, AuthId_Steam2, p.steamId, 32);
	}
	else
	{
		Format(p.name, MAX_NAME_LENGTH, "");
		Format(p.steamId, 32, "");
	}

	p.sCreatedDate[0] = '\0';
	p.sUpdatedDate[0] = '\0';

	p.fPanelRefreshTime = 0.0;
	p.fLastScore        = 0.0;
	p.fExScore          = 0.0;
	p.fMaxScore         = 0.0;

	for (int i = 0; i < PG_SIZE; i++)
	{
		p.iPanelPage[i] = false;
	}

	for (int i = 0; i < ET_SIZE; i++)
	{
		p.bET[i] = false;
	}

	// SRS reset
	int start = bBot ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP;
	for (int i = start; i < SRS_TYPE_SIZE; i++)
	{
		p.fScore[i]      = 0.0;
		p.rank[i]        = 0;
		p.fPlayedTime[i] = 0.0;

		for (int j = 0; j < SRS_CODE_SIZE; j++) g_iSRSs[p.id][i][j] = 0;
	}
}

public void RefreshGameSetting()
{
	g_gameSetting.Refresh();

	for (int i = 0; i < sizeof(g_sGamemodes); i++)
		if (StrEqual(g_gameSetting.mode, g_sGamemodes[i], false))
			g_cvGamemode = g_hCvar_gamemodes[i];

	for (int i = 0; i < sizeof(g_sDifficulties); i++)
		if (StrEqual(g_gameSetting.difficulty, g_sDifficulties[i], false))
			g_cvDifficulty = g_hCvar_difficulties[i];
}

public void GetScoreStatus(char[] buffer, int size)
{
	Format(buffer, size, g_gameSetting.difficulty);
	buffer[0] = CharToUpper(g_gameSetting.difficulty[0]);
	Format(buffer, size, "%s: %.1fx Score", buffer, g_cvDifficulty.FloatValue * g_cvGamemode.FloatValue);
}

public int GetSRSWeaponId(const Player p, bool bActive)
{
	if (!IsSurvivor(p.id)) return SRS_S_K_NONE;

	if (bActive)
	{
		if (p.weapon.IsGunOrMelee(true))
		{
			for (int i = 0; i < sizeof(g_iSRSWeaponCodes); i++)
				if (StrEqual(p.weapon.activeName, g_sWeapons[i], false)) return g_iSRSWeaponCodes[i];

			LogError("Active Weapon \"%s\" not found. (Use none weapon to count score)", p.weapon.activeName);
		}
	}
	else if (p.weapon.IsGunOrMelee())
	{
		for (int i = 0; i < sizeof(g_iSRSWeaponCodes); i++)
			if (StrEqual(p.weapon.name, g_sWeapons[i], false)) return g_iSRSWeaponCodes[i];

		LogError("Weapon \"%s\" not found. (Use none weapon to count score)", p.weapon.name);
	}

	return SRS_S_K_NONE;
}

public void OpenPanel(Player p)
{
	p.fPanelRefreshTime = 1.0;
	OpenSRSPanel(p, p, g_iSRSs);
}

// ====================================================================================================
//					pan0s | Handle Cmd
// ====================================================================================================
public Action HandleCmdScore(int client, int args)
{
	char buffer[10];
	GetCmdArgString(buffer, sizeof(buffer));
	g_players[client].fScore[SRS_TYPE_MVP] = StringToFloat(buffer);
	g_players[client].fScore[SRS_TYPE_DB]  = StringToFloat(buffer);
	return Plugin_Handled;
}

public Action HandleCmdRebuildSRS(int client, int args)
{
	CallDBAgent(DBA_DROP, client);
	return Plugin_Handled;
}

public Action HandleCmdUpdateSRS(int client, int args)
{
	CallDBAgent(DBA_ALTER, client);
	return Plugin_Handled;
}

public Action HandleCmdT2(int client, int args)
{
	AddCountryTag(g_players[client]);
	if (IsValidClient(client))
	{
		if (!IsFakeClient(client))
		{
			if (g_hCvar_sound_join.BoolValue) EmitSoundToAll(JOIN_SOUND, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
					CPrintToChat(i, "%T%T", "TAG_ANNOUNCE", i, "CONNECTING", i, client);
		}
	}
	// int rand = GetRandomInt(0,99);
	// char name[32];
	PrintJoinMsgToAll(g_players[client]);
	// ClearAll();
	return Plugin_Handled;
}

public Action HandleCmdSRS(int client, int args)
{
	CloseSRSPanel(g_players[client]);
	g_players[client].iPanelType = PT_ME;
	OpenPanel(g_players[client]);
	return Plugin_Handled;
}

public Action HandleCmdAuto(int client, int args)
{
	g_players[client].bAutoOpen = !g_players[client].bAutoOpen;
	bool on                     = g_players[client].bAutoOpen;
	CPrintToChat(client, "%T%T: {%s}%T{DEFAULT}", "SYSTEM", client, "AUTO_OPEN", client, on ? "GREEN" : "ORANGE", on ? "ON" : "OFF", client);
	return Plugin_Handled;
}

public Action HandleCmdEff(int client, int args)
{
	g_players[client].combo.bEff = !g_players[client].combo.bEff;
	bool on                      = g_players[client].combo.bEff;
	CPrintToChat(client, "%T%T: {%s}%T{DEFAULT}", "SYSTEM", client, "COMBO_EFFECT", client, on ? "GREEN" : "ORANGE", on ? "ON" : "OFF", client);
	return Plugin_Handled;
}

public Action HandleCmdSound(int client, int args)
{
	g_players[client].combo.bSound = !g_players[client].combo.bSound;
	bool on                        = g_players[client].combo.bSound;
	CPrintToChat(client, "%T%T: {%s}%T{DEFAULT}", "SYSTEM", client, "COMBO_SOUND", client, on ? "GREEN" : "ORANGE", on ? "ON" : "OFF", client);
	return Plugin_Handled;
}

public Action HandleCmdTop10(int client, int args)
{
	g_players[client].iPanelPage[PG_TOP10] = 0;
	g_players[client].iPanelType           = PT_TOP10;
	OpenTop10ListPanel(g_players[client]);
	return Plugin_Handled;
}

public Action HandleCmdMVP(int client, int args)
{
	g_players[client].fPanelRefreshTime  = 1.0;
	g_players[client].iPanelPage[PG_MVP] = 0;
	g_players[client].iPanelType         = PT_MVP;
	g_players[client].bMVPSelecting      = true;
	OpenMVPListPanel(g_players[client]);
	return Plugin_Handled;
}

public Action HandleWhiteListCmd(int client, int args)
{
	if (args == 0) CloseSRSPanel(g_players[client])

		return Plugin_Handled;
}

// ====================================================================================================
//					pan0s | FrameMove Timer
// ====================================================================================================
public Action FrameMove(Handle timer)
{
	float frameMoveTime = g_hCvar_frame_move_time.FloatValue;

	// LoadTop10
	if (g_fTop10LoadTime == 0.0)
	{
		if (g_pTop10[0].fScore[SRS_TYPE_DB] == 0.0)
			CallDBAgent(DBA_TOP10, 0);
	}
	g_fTop10LoadTime += frameMoveTime;
	if (g_fTop10LoadTime >= 10.0) g_fTop10LoadTime = 0.0;

	// Refresh Game settings timer
	float defaultTime = g_hCvar_refresh_game_settings_time.FloatValue;
	if (defaultTime > 0.0)
	{
		if (g_iRefreshTime > 0.0) g_iRefreshTime -= frameMoveTime;
		else
		{
			g_iRefreshTime = defaultTime;
			RefreshGameSetting();
		}
	}

	int humanNum = 0;

	GetMvp(g_iClients, g_fScores, MaxClients + 1);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (!IsFakeClient(i)) humanNum++;

			for (int x = 0; x < MaxClients; x++)
				if (g_iClients[x] == i)
					if (IsFakeClient(i)) g_players[i].rank[SRS_TYPE_MVP_BOT] = x + 1;
					else g_players[i].rank[SRS_TYPE_MVP] = x + 1;

			if (GetClientTeam(i) != TEAM_SPECTATOR)
				for (int x = SRS_TYPE_MVP; x <= SRS_TYPE_DB; x++) g_players[i].fPlayedTime[x] += frameMoveTime;

			g_players[i].id            = i;
			g_players[i].weapon.client = i;
			g_players[i].weapon.UpdateActiveName();

			float fp              = g_players[i].combo.fPercentage > 0.0 ? g_players[i].combo.fPercentage : 1.0;
			int   srsWeapon       = GetSRSWeaponId(g_players[i], true);
			// int srsWeapon = SRS_S_K_NONE;
			float weaponScore     = IsSurvivor(i) ? g_hCvar_scores[srsWeapon].FloatValue : 1.0;
			g_players[i].fExScore = (fp * g_cvGamemode.FloatValue * g_cvDifficulty.FloatValue * weaponScore - 1) * 100.0;

			// Panel update
			// g_players[i].bPanel = true;
			if (g_players[i].bPanel && g_players[i].fPanelRefreshTime >= 1.0)
			{
				g_players[i].fPanelRefreshTime += frameMoveTime;
				if (g_players[i].fPanelRefreshTime > 1.0 + g_hCvar_panel_refresh_time.FloatValue)
				{
					if (g_players[i].iPanelType == PT_MVP)
					{
						if (g_players[i].bMVPSelecting) OpenMVPListPanel(g_players[i]);
						else OpenMVPSRSPanel(g_players[i]);
					}
					else OpenSRSPanel(g_players[i], g_players[i], g_iSRSs);
					g_players[i].fPanelRefreshTime = 1.0;
				}
			}

			// Combo timer
			if (g_players[i].combo.fTime > 0.0)
			{
				g_players[i].combo.fTime -= frameMoveTime;
			}
			else
			{
				g_players[i].combo.iCount      = 0;
				g_players[i].combo.fPercentage = 0.0;
			}
		}
	}

	if (g_bReady)
	{
		g_iCISpawnTime += frameMoveTime;

		if (g_hCvar_extra_ci_spawn_time.FloatValue == 0.0)
		{
			float time  = 60.0 - (humanNum * 3);
			float mTime = time <= 30.0 ? 10.0 : time;
			if (g_iCISpawnTime >= mTime)
			{
				g_iCISpawnTime = 0.0;
				SpawnCI();
			}
		}
		else
		{
			if (g_iCISpawnTime >= g_hCvar_extra_ci_spawn_time.FloatValue)
			{
				g_iCISpawnTime = 0.0;
				SpawnCI();
			}
		}
	}
	return Plugin_Handled;
}

//
// ====================================================================================================
//					pan0s | Panel UI
// ====================================================================================================
public void GetKillSI(const Player pMe, const Player p, int[][] killSI, int[] totalKSI, int[][][] srsEntity)
{
	for (int i = SRS_S_K_SK; i <= SRS_S_K_T; i++)
	{
		if (i == SRS_S_K_W_OS) continue;
		killSI[0][i] = srsEntity[p.id][pMe.iPanelSRSType][i];
		killSI[1][i] = srsEntity[p.id][pMe.iPanelSRSType][i + SRS_S_K_SK_HS - 1];
		totalKSI[0] += killSI[0][i];
		totalKSI[1] += killSI[1][i];
	}
}

public void ConvertSecondToTime(float fSeconds, char[] buffer, int size)
{
	int seconds = RoundToFloor(fSeconds);
	int hours = seconds / 3600;
	int mins  = seconds / 60 % 60;
	int secs  = seconds % 60;
	Format(buffer, size, "%02d:%02d:%02d", hours, mins, secs);
}

// public float GetAccuracy(const Player p, const int[][][] srsEntity)
// {
// 	int shot = srsEntity[p.id][p.iPanelSRSType][SRS_S_SHOT];
// 	int hit = srsEntity[p.id][p.iPanelSRSType][SRS_S_HIT];
// 	return shot > 0.0? 1.0 * (hit) / (shot) * 100: 0.0;
// }
public void ConvertTimeToSymbol(float time, char[] buffer, int size)
{
	while (time > 0.0)
	{
		Format(buffer, size, "%s|", buffer);
		time -= 0.4;
	}
}

public void DrawPrev(Panel panel, Player p, bool bBack)
{
	char line[32];
	panel.CurrentKey = 8;
	if (bBack) Format(line, sizeof(line), "%T", "BACK", p.id);
	else Format(line, sizeof(line), "%T", "PREV_PAGE", p.id);
	panel.DrawItem(line);
}

public void DrawNext(Panel panel, Player p)
{
	char line[32];
	panel.CurrentKey = 9;
	Format(line, sizeof(line), "%T", "NEXT_PAGE", p.id);
	panel.DrawItem(line);
}

public void DrawClose(Panel panel, Player p)
{
	char line[32];
	panel.CurrentKey = 10;
	Format(line, sizeof(line), "%T", "CLOSE", p.id);
	panel.DrawItem(line);
}

public void OpenSRSPanel(Player pMe, Player p, int[][][] srsEntity)
{
	if (!IsValidClient(pMe.id) || IsFakeClient(pMe.id)) return;
	pMe.bPanel = true;

	char line[512];
	int  lastPage = 2;

	Panel panel = new Panel();

	char targetName[MAX_NAME_LENGTH];
	char rank[10];
	if (pMe.iPanelType == PT_MVP && IsFakeClient(p.id))
	{
		if (pMe.iPanelSRSType == SRS_TYPE_DB_BOT) Format(rank, sizeof(rank), "BOT");
		else Format(rank, sizeof(rank), "%d", p.rank[pMe.iPanelSRSType]);
		Format(targetName, sizeof(targetName), "%N", p.id);
	}
	else
	{
		Format(rank, sizeof(rank), "%d", p.rank[pMe.iPanelSRSType]);
		Format(targetName, sizeof(targetName), "%s", p.name);
	}

	Format(line, sizeof(line), "      -= #%s %s %T =-      ", rank, targetName, "INFO", pMe.id);
	panel.SetTitle(line);

	if (pMe.iPanelType != PT_TOP10)
	{
		char view[32];
		switch (pMe.iPanelSRSType)
		{
			case SRS_TYPE_MVP_BOT, SRS_TYPE_MVP: Format(view, sizeof(view), "ROUND_STATUS");
			case SRS_TYPE_DB_BOT, SRS_TYPE_DB: Format(view, sizeof(view), "TOTAL_STATUS");
		}
		Format(line, sizeof(line), "%T: %T", "VIEWING", pMe.id, view, pMe.id);
		panel.DrawItem(line);
	}
	else panel.CurrentKey = 2;
	panel.DrawText(" ");

	if (pMe.iPanelPage[PG_PANEL] == 0)
	{
		int   shot     = srsEntity[p.id][pMe.iPanelSRSType][SRS_S_SHOT];
		int   hit      = srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HIT];
		float accuracy = shot > 0.0 ? 1.0 * (hit) / (shot)*100 : 0.0;

		float score = p.fScore[pMe.iPanelSRSType];

		int killCI    = srsEntity[p.id][pMe.iPanelSRSType][SRS_S_K_CI];
		int killCI_HS = srsEntity[p.id][pMe.iPanelSRSType][SRS_S_K_CI_HS];

		int KSI[2][SRS_S_K_T + 1];
		int totalKSI[2];
		GetKillSI(pMe, p, KSI, totalKSI, srsEntity);

		char timeSymbol[128];
		ConvertTimeToSymbol(p.combo.fTime, timeSymbol, 128);

		// float weaponExScore;
		// char wActiveName[32];
		// if(TranslationPhraseExists(p.weapon.activeName)) Format(wActiveName, sizeof(wActiveName), "%T", p.weapon.activeName, pMe.id);
		// else Format(wActiveName, sizeof(wActiveName), "-");

		char levelSymbol[127];
		GetLevelSymbol(p, levelSymbol, sizeof(levelSymbol));

		// if(weaponExScore>0.0) Format(line, sizeof(line), "☼ %T: %s (+%.2f%%)", "USING", pMe.id, wActiveName, pMe.id, weaponExScore);
		// else Format(line, sizeof(line), "☼ %T: %s (%.2f%%)", "USING", pMe.id, wActiveName, pMe.id, weaponExScore);
		// panel.DrawText(line);

		Format(line, sizeof(line), "☼ %T: %.2f", "SCORE", pMe.id, score);
		panel.DrawText(line);

		if (pMe.iPanelSRSType == SRS_TYPE_DB || pMe.iPanelSRSType == SRS_TYPE_DB_BOT)
		{
			Format(line, sizeof(line), "├ %T", "HIGHEST_SCORE_ADDED", pMe.id, p.fMaxScore);
			panel.DrawText(line);

			Format(line, sizeof(line), "└ %T", "HIGHEST_COMBO", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_H_MX_CB]);
			panel.DrawText(line);
		}
		else
		{
			Format(line, sizeof(line), "├ %s%.2f (%s%.2f%%) %s", p.fLastScore > 0.0 ? "+" : "", p.fLastScore, p.fExScore > 0.0 ? "+" : "", p.fExScore, levelSymbol);
			panel.DrawText(line);

			Format(line, sizeof(line), "└ %T", "COMBO", pMe.id, timeSymbol, p.combo.iCount, p.combo.iCount > 1 ? "s" : "");
			panel.DrawText(line);
		}

		panel.DrawText(" ");

		Format(line, sizeof(line), "%T", "FIRE_STATISTIC", pMe.id);
		panel.DrawItem(line, ITEMDRAW_DEFAULT);

		Format(line, sizeof(line), "%s %T: %.1f%%", !pMe.bET[ET_DMG] ? "└" : "├", "ACCURACY", pMe.id, accuracy);
		panel.DrawText(line);

		if (pMe.bET[ET_DMG])
		{
			Format(line, sizeof(line), "├ %T: %d  %T: %d", "SRS_S_SHOT", pMe.id, shot, "SRS_S_HIT", pMe.id, hit);
			panel.DrawText(line);
			Format(line, sizeof(line), "└ %T: %d", "SRS_S_DMG", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_DMG]);
			panel.DrawText(line);
		}

		panel.DrawText(" ");

		Format(line, sizeof(line), "%T:", "KILL_STATISTIC", pMe.id);
		panel.DrawItem(line, ITEMDRAW_DEFAULT);

		Format(line, sizeof(line), "%s %T: %d/%d  %T: %d/%d", !pMe.bET[ET_KILL] ? "└" : "├", "SPECIAL", pMe.id, totalKSI[0], totalKSI[1], "COMMON", pMe.id, killCI, killCI_HS);
		panel.DrawText(line);

		if (pMe.bET[ET_KILL])
		{
			int si         = 0;
			int count      = 0;
			int eachRowCol = 3;
			for (int i = SRS_S_K_SK; i <= SRS_S_K_T; i++)
			{
				if (count % eachRowCol == 0)
				{
					if (count >= SRS_S_K_T - SRS_S_K_SK + eachRowCol - 1) Format(line, sizeof(line), "└ ");
					else Format(line, sizeof(line), "├ ");
					count++;
				}
				Format(line, sizeof(line), "%s%s: %d/%d  ", line, g_sSRSSIName[si++], KSI[0][i], KSI[1][i]);
				count++;
				if (count % eachRowCol != 0)
					Format(line, sizeof(line), "%s  ", line);
				if (count % eachRowCol == 0)
					panel.DrawText(line);
			}
		}

		panel.DrawText(" ");

		if (pMe.iPanelType == PT_ME)
		{
			Format(line, sizeof(line), "%s%T", !pMe.bET[ET_OPTIONS] ? "─" : "┌", "OPTIONS", pMe.id);
			panel.DrawItem(line);
			if (pMe.bET[ET_OPTIONS])
			{
				// 5
				Format(line, sizeof(line), "├%T: %T", "AUTO_OPEN", pMe.id, p.bAutoOpen ? "ON" : "OFF", pMe.id);
				panel.DrawItem(line);
				// 6
				Format(line, sizeof(line), "├%T: %T", "COMBO_EFFECT", pMe.id, p.combo.bEff ? "ON" : "OFF", pMe.id);
				panel.DrawItem(line);
				// 7
				Format(line, sizeof(line), "└%T: %T", "COMBO_SOUND", pMe.id, p.combo.bSound ? "ON" : "OFF", pMe.id);
				panel.DrawItem(line);
			}
			panel.DrawText(" ");
		}
		if (pMe.iPanelType == PT_MVP || pMe.iPanelType == PT_TOP10) DrawPrev(panel, pMe, true);
		DrawNext(panel, pMe);
		DrawClose(panel, pMe);
	}
	else if (pMe.iPanelPage[PG_PANEL] == 1)
	{
		// 2
		Format(line, sizeof(line), "%T", "ITEMS_USED", pMe.id);
		panel.DrawItem(line);
		Format(line, sizeof(line), "%s %d %T %d %T", !pMe.bET[ET_USED] ? "└" : "├", srsEntity[p.id][pMe.iPanelSRSType][SRS_S_MEDKIT], "first_aid_kit", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_PILLS], "pain_pills", pMe.id);
		panel.DrawText(line);
		if (pMe.bET[ET_USED])
		{
			Format(line, sizeof(line), "├ %d %T %d %T", srsEntity[p.id][pMe.iPanelSRSType][SRS_S_ADRENALINE], "adrenaline", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_TH_PIPE], "pipe_bomb", pMe.id);
			panel.DrawText(line);
			Format(line, sizeof(line), "└ %d %T %d %T", srsEntity[p.id][pMe.iPanelSRSType][SRS_S_TH_MOLO], "molotov", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_TH_VOMITJAR], "vomitjar", pMe.id);
			panel.DrawText(line);
		}

		// 3
		panel.DrawText(" ");
		Format(line, sizeof(line), "%T", "HEALTH_INFO", pMe.id);
		panel.DrawItem(line);
		Format(line, sizeof(line), "%s %T: %d  %T: %d", !pMe.bET[ET_HEALTH] ? "└" : "├", "SRS_S_DEATH", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_DEATH], "SRS_S_INCAPACITATED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_INCAPACITATED]);
		panel.DrawText(line);
		if (pMe.bET[ET_HEALTH])
		{
			Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_REVIVED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_REVIVED], "SRS_S_RESCUED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_RESCUED]);
			panel.DrawText(line);
			Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_HEALED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HEALED], "SRS_S_SELF_HEALED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_SELF_HEALED]);
			panel.DrawText(line);
			Format(line, sizeof(line), "└ %T: %d %T: %d", "SRS_S_DEFIBRILLATED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_DEFIBRILLATED], "SRS_S_HURT", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HURT]);
			// Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_DEFIBRILLATED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_DEFIBRILLATED], "SRS_S_PROTECTED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_PROTECTED]);
			panel.DrawText(line);
			// Format(line, sizeof(line), "└ %T: %d", "SRS_S_HURT", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HURT]);
			// panel.DrawText(line);
		}

		// 4
		panel.DrawText(" ");
		Format(line, sizeof(line), "%T", "HELP_INFO", pMe.id);
		panel.DrawItem(line);
		Format(line, sizeof(line), "%s %T: %d %T: %d", !pMe.bET[ET_HELP] ? "└" : "├", "SRS_S_HEAL", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HEAL], "SRS_S_REVIVE", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_REVIVE]);
		panel.DrawText(line);
		if (pMe.bET[ET_HELP])
		{
			Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_DEFIBRILLATE", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_DEFIBRILLATE], "SRS_S_RESCUE", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_RESCUE]);
			panel.DrawText(line);
			Format(line, sizeof(line), "└ %T: %d", "SRS_S_PROTECT", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_PROTECT]);
			panel.DrawText(line);
		}

		panel.DrawText(" ");

		DrawPrev(panel, pMe, false);
		DrawNext(panel, pMe);
	}
	// else if(pMe.iPanelPage[PG_PANEL] == 2)
	// {
	// 	Format(line, sizeof(line), "%T", "HURT_STATISTIC", pMe.id);
	// 	panel.DrawItem(line);
	// 	Format(line, sizeof(line), "%s %T: %d", !pMe.bET[ET_HURT] ?"└": "├", "SRS_S_HURT", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_HURT]);
	// 	panel.DrawText(line);

	// 	// if(pMe.bET[ET_HURT])
	// 	{
	// 		int otherHurt = 0;
	// 		Format(line, sizeof(line), "├ %T: %d %T: %d", "OTHER_HURT", pMe.id, otherHurt, "SRS_S_J_RIDE", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_J_RIDE]);
	// 		panel.DrawText(line);
	// 		Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_C_CARRY", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_C_CARRY], "SRS_S_C_PUMMEL", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_C_PUMMEL]);
	// 		panel.DrawText(line);
	// 		Format(line, sizeof(line), "├ %T: %d %T: %d", "SRS_S_SK_POUNCE", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_SK_POUNCE], "SRS_S_H_PUNCHED", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_H_PUNCHED]);
	// 		panel.DrawText(line);
	// 		Format(line, sizeof(line), "└ %T: %d %T: %d", "SRS_S_ST_DMG", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_ST_DMG], "SRS_S_B_NOW_IT", pMe.id, srsEntity[p.id][pMe.iPanelSRSType][SRS_S_B_NOW_IT]);
	// 		panel.DrawText(line);
	// 	}

	// 	DrawPrev(panel, pMe, false);
	// 	DrawNext(panel, pMe);
	// }
	else if(pMe.iPanelPage[PG_PANEL] == lastPage)
	{
		// 2
		Format(line, sizeof(line), "%T", "DATETIME_INFO", pMe.id);
		panel.DrawItem(line);
		char playedTime[32];
		ConvertSecondToTime(p.fPlayedTime[pMe.iPanelSRSType], playedTime, sizeof(playedTime));

		Format(line, sizeof(line), "%s %T: %s", pMe.bET[ET_DATE] ?"└": "├", "PLAYED_TIME", pMe.id, playedTime);
		panel.DrawText(line);
		if(!pMe.bET[ET_DATE]) // default extend
		{
			Format(line, sizeof(line), "├ %T: %s", "JOIN_DATE", pMe.id, p.sCreatedDate[0]== '\0'? "-":p.sCreatedDate);
			panel.DrawText(line);
			Format(line, sizeof(line), "└ %T: %s", "UPDATE_DATE", pMe.id, p.sUpdatedDate[0]== '\0'? "-":p.sUpdatedDate);
			panel.DrawText(line);
		}

		panel.DrawText(" ");
		panel.DrawText("===========================");
		panel.DrawText(" ");
		panel.DrawText("          Statistic & Ranking System (SRS)          ");
		Format(line, sizeof(line), "                 Version: %s      ", PLUGIN_VERSION);
		panel.DrawText(line);
		panel.DrawText("          Author: pan0s#6098 (Discord)          ");
		panel.DrawText("          Modified by: ALICE#9896 (Discord)          ");
		panel.DrawText("      Official Server: 35.220.252.154:27015         ");
		panel.DrawText("        New functions are coming soon? :)       ");
		panel.DrawText(" ");
		DrawPrev(panel, pMe, false);
	}
	DrawClose(panel, pMe);

	panel.Send(pMe.id, HandlePanelSelected, MENU_TIME_FOREVER);
	delete panel;
}

public void ExtendSRS(Player p, int[] etCodes)
{
	int page = p.iPanelPage[PG_PANEL];
	if (etCodes[page] == -1) return;

	p.bET[etCodes[page]] = !p.bET[etCodes[page]];
	if (p.iPanelType == PT_TOP10) OpenTop10SRSPanel(p);
}

public void CloseSRSPanel(Player p)
{
	p.iPanelSRSType        = SRS_TYPE_MVP;
	p.iPanelPage[PG_PANEL] = 0;
	p.fPanelRefreshTime    = 0.0;
	p.bPanel               = false;
	for (int i = 0; i < ET_SIZE; i++) p.bET[i] = false;
}

public void SwitchSRSPanelType(Player p)
{
	if (p.iPanelType == PT_MVP && IsFakeClient(p.iPanelTarget)) p.iPanelSRSType = p.iPanelSRSType == SRS_TYPE_MVP_BOT ? SRS_TYPE_DB_BOT : SRS_TYPE_MVP_BOT;
	else p.iPanelSRSType = p.iPanelSRSType == SRS_TYPE_MVP ? SRS_TYPE_DB : SRS_TYPE_MVP;
}

/**
 * Menu Callback Handler for Show Player Rank panel
 */
public int HandlePanelSelected(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			switch (selectedIndex)
			{
				case 1:
				{
					SwitchSRSPanelType(g_players[client]);
				}
				case 2:
				{
					int etCodes[] = {
						ET_DMG,
						ET_USED,
						ET_DATE,
					};
					ExtendSRS(g_players[client], etCodes);
				}
				case 3:
				{
					int etCodes[] = { ET_KILL, ET_HEALTH, -1 };
					ExtendSRS(g_players[client], etCodes);
				}
				case 4:
				{
					int etCodes[] = { ET_OPTIONS, ET_HELP, -1 };
					ExtendSRS(g_players[client], etCodes);
				}
				case 5:
				{
					if (g_players[client].iPanelType == PT_ME && g_players[client].bET[ET_OPTIONS])
					{
						g_players[client].bAutoOpen = !g_players[client].bAutoOpen;
					}
					else
					{
					}
				}
				case 6:
				{
					if (g_players[client].iPanelType == PT_ME && g_players[client].bET[ET_OPTIONS])
					{
						g_players[client].combo.bEff = !g_players[client].combo.bEff;
					}
					else
					{
					}
				}
				case 7:
				{
					if (g_players[client].iPanelType == PT_ME && g_players[client].bET[ET_OPTIONS])
					{
						g_players[client].combo.bSound = !g_players[client].combo.bSound;
					}
					else
					{
					}
				}
				case 8:
				{
					if (g_players[client].iPanelPage[PG_PANEL] == 0)
					{
						if (g_players[client].iPanelType == PT_TOP10) OpenTop10ListPanel(g_players[client]);    // Back
						else if (g_players[client].iPanelType == PT_MVP)
						{
							g_players[client].bMVPSelecting = true;
							OpenMVPListPanel(g_players[client]);    // Back
						}
					}
					else
					{
						if (--g_players[client].iPanelPage[PG_PANEL] < 0)
						{
							g_players[client].iPanelPage[PG_PANEL] = 0;
						}
						if (g_players[client].iPanelType == PT_TOP10) OpenTop10SRSPanel(g_players[client]);
						else if (g_players[client].iPanelType == PT_MVP) OpenMVPSRSPanel(g_players[client]);
					}
				}
				case 9:
				{
					if (++g_players[client].iPanelPage[PG_PANEL] > 2)
					{
						g_players[client].iPanelPage[PG_PANEL] = 2;
						return 0;
					}
					if (g_players[client].iPanelType == PT_TOP10) OpenTop10SRSPanel(g_players[client]);
				}
				case 10:
				{
					CloseSRSPanel(g_players[client]);
				}
			}
		}
		case MenuAction_Cancel:
		{
			switch (selectedIndex)
			{
				case MenuCancel_Interrupted, MenuCancel_Exit, MenuCancel_NoDisplay, MenuCancel_Disconnected:
				{
					g_players[client].fPanelRefreshTime = 0.0;
					if (g_players[client].bPanel) g_players[client].fPanelRefreshTime = 1.0;
				}
			}
		}
	}
	return 0;
}

public void OpenMVPListPanel(Player p)
{
	if (!IsValidClient(p.id)) return;
	p.bPanel = true;
	char line[128];

	Panel panel = new Panel();
	Format(line, sizeof(line), "          -= Round MVP =-          ");
	panel.SetTitle(line);

	g_iHumanNo = 0;
	for (int i = 0; i <= MaxClients; i++)
	{
		int client = g_iClients[i];
		if (IsValidClient(client))
		{
			if (!IsFakeClient(client) || (IsFakeClient(client) && GetClientTeam(client) != TEAM_INFECTED)) g_iHumanNo++;
		}
	}

	char nameCheck[2][MAX_NAME_LENGTH];

	for (int i = p.iPanelPage[PG_MVP] * 5; i < p.iPanelPage[PG_MVP] * 5 + 5; i++)
	{
		int client = g_iClients[i];
		if (!IsValidClient(client)) continue;
		Format(nameCheck[0], sizeof(nameCheck[]), "%N", g_players[client].id);
		if (StrEqual(nameCheck[0], nameCheck[1])) continue;
		Format(nameCheck[1], sizeof(nameCheck[]), "%N", g_players[client].id);

		Format(line, sizeof(line), "%s", nameCheck[0]);
		panel.DrawItem(line);

		int srsType = IsFakeClient(client) ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP 
		Format(line, sizeof(line), "└ %T.%d  %T: %.1f", "RANK", p.id, g_players[client].rank[srsType], "SCORE", p.id, g_players[client].fScore[srsType]);
		panel.DrawText(line);
	}

	panel.DrawText(" ");

	if (p.iPanelPage[PG_MVP] != 0 && g_iHumanNo >= 5) DrawPrev(panel, p, false);
	float pageNo = (g_iHumanNo - 1) / (5.0 * (1 + p.iPanelPage[PG_MVP]));
	if (RoundToFloor(pageNo) > 0) DrawNext(panel, p);

	DrawClose(panel, p);

	panel.Send(p.id, HandlePanelMVPSelected, MENU_TIME_FOREVER);
	delete panel;
}

public void OpenMVPSRSPanel(Player p)
{
	OpenSRSPanel(p, g_players[p.iPanelTarget], g_iSRSs);
}

/**
 * Menu Callback Handler for Show Player Rank panel
 */
public int HandlePanelMVPSelected(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			int basic = g_players[client].iPanelPage[PG_MVP] * 5;
			if (selectedIndex < 6)
			{
				int target = g_iClients[selectedIndex - 1 + basic];
				if (IsValidClient(target))
				{
					g_players[client].iPanelSRSType = IsFakeClient(target) ? SRS_TYPE_MVP_BOT : SRS_TYPE_MVP;
					g_players[client].iPanelTarget  = target;
					g_players[client].iPanelType    = PT_MVP;
					g_players[client].bMVPSelecting = false;
				}
				else
				{
					CPrintToChat(client, "%T%T", "SYSTEM", client, "MVP_ERROR_1", client);
				}
			}
			switch (selectedIndex)
			{
				case 8:
				{
					if (--g_players[client].iPanelPage[PG_MVP] < 0) g_players[client].iPanelPage[PG_MVP] = 0;
				}
				case 9:
				{
					int max = RoundToCeil(g_iHumanNo / 5.0) - 1;
					if (++g_players[client].iPanelPage[PG_MVP] > max)
						g_players[client].iPanelPage[PG_MVP] = max;
				}
				case 10:
				{
					CloseSRSPanel(g_players[client]);
				}
			}
		}
		case MenuAction_Cancel:
		{
			switch (selectedIndex)
			{
				case MenuCancel_Interrupted, MenuCancel_Exit, MenuCancel_NoDisplay, MenuCancel_Disconnected:
				{
					g_players[client].fPanelRefreshTime = 0.0;
					if (g_players[client].bPanel) g_players[client].fPanelRefreshTime = 1.0;
				}
			}
		}
	}
	return 0;
}

public void OpenTop10ListPanel(Player p)
{
	if (!IsValidClient(p.id)) return;
	char line[128];

	Panel panel = new Panel();
	Format(line, sizeof(line), "             -= Top10 =-             ");
	panel.SetTitle(line);

	for (int i = p.iPanelPage[PG_TOP10] * 5 + 1; i <= p.iPanelPage[PG_TOP10] * 5 + 5; i++)
	{
		if (StrEqual(g_pTop10[i].name, "", false)) break;
		Format(line, sizeof(line), "%s", g_pTop10[i].name);
		panel.DrawItem(line);
		Format(line, sizeof(line), "└ %T.%d  %T: %.1f", "RANK", p.id, g_pTop10[i].rank[SRS_TYPE_DB], "SCORE", p.id, g_pTop10[i].fScore[SRS_TYPE_DB]);
		panel.DrawText(line);
	}

	panel.DrawText(" ");

	if (p.iPanelPage[PG_TOP10] == 0) DrawNext(panel, p);
	else if (p.iPanelPage[PG_TOP10] == 1)
	{
		DrawPrev(panel, p, false);
		panel.DrawText(" ");
	}

	DrawClose(panel, p);

	panel.Send(p.id, HandlePanelTop10Selected, MENU_TIME_FOREVER);
	delete panel;
}

public void OpenTop10SRSPanel(Player p)
{
	int target = p.iPanelTarget;
	OpenSRSPanel(p, g_pTop10[target], g_iTop10SRSs);
}

/**
 * Menu Callback Handler for Show Player Rank panel
 */
public int HandlePanelTop10Selected(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			int basic = g_players[client].iPanelPage[PG_TOP10] * 5;
			if (selectedIndex < 6)
			{
				g_players[client].iPanelSRSType = SRS_TYPE_DB;
				g_players[client].iPanelTarget  = selectedIndex + basic;
				OpenTop10SRSPanel(g_players[client]);
			}
			switch (selectedIndex)
			{
				case 8:
				{
					if (--g_players[client].iPanelPage[PG_TOP10] < 0)
					{
						g_players[client].iPanelPage[PG_TOP10] = 0;
						return 0;
					}
					OpenTop10ListPanel(g_players[client]);
				}
				case 9:
				{
					if (++g_players[client].iPanelPage[PG_TOP10] > 1)
					{
						g_players[client].iPanelPage[PG_TOP10] = 1;
						return 0;
					}
					OpenTop10ListPanel(g_players[client]);
				}
				default:
				{
				}
			}
		}
		case MenuAction_Cancel:
		{
			switch (selectedIndex)
			{
				case MenuCancel_ExitBack:
				{
				}
				case MenuCancel_Interrupted, MenuCancel_Exit, MenuCancel_NoDisplay, MenuCancel_Disconnected:
				{
				}
			}
		}
	}
	return 0;
}

// Rank chat
public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	char tag[64];
	if (g_hCvar_rank_tag.BoolValue) Format(tag, sizeof(tag), "{green}[{olive}Rank.%d{green}]", g_players[author].rank[SRS_TYPE_DB])
		Format(name, 128, "%s{teamcolor}%s", tag, name);
	Format(message, 128, "{default}%s", message);
	return Plugin_Changed;
}
