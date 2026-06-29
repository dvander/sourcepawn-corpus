/**
 * gameME Plugin
 * http://www.gameme.com
 * Copyright (C) 2007-2011 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

 
#pragma semicolon 1

#define REQUIRE_EXTENSIONS 
#include <sourcemod>
#include <keyvalues>
#include <menus>
#include <sdktools>
#include <gameme>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <tf2_stocks>


// plugin information
#define GAMEME_PLUGIN_VERSION "3.8"
public Plugin:myinfo = {
	name = "gameME Plugin",
	author = "TTS Oetzel & Goerz GmbH",
	description = "gameME Plugin",
	version = GAMEME_PLUGIN_VERSION,
	url = "http://www.gameme.com"
};

// mod information
#define MOD_CSS 1
#define MOD_DODS 2
#define MOD_HL2MP 3
#define MOD_TF2 4
#define MOD_L4D 5
#define MOD_L4DII 6
#define MOD_INSMOD 7
#define MOD_FF 8
#define MOD_CSP 9
#define MOD_ZPS 10

new String: team_list[16][32];
// gameME Stats
#define GAMEME_TAG "gameME"
enum gameme_plugin_data {
  mod_id,
  String: game_mod[32],
  bool: sdkhook_available,
  sdk_version,
  bool: ignore_next_tag_change,
  Handle: custom_tags,
  Handle: sv_tags
}
new gameme_plugin[gameme_plugin_data];

#define SPECTATOR_TIMER_INTERVAL 	0.5
#define SPECTATOR_NONE 				0
#define SPECTATOR_FIRSTPERSON 		4
#define SPECTATOR_3RDPERSON 		5
#define SPECTATOR_FREELOOK	 		6
#define QUERY_TYPE_UNKNOWN			0
#define QUERY_TYPE_SPECTATOR		1001

enum player_display_messages {
	String: smessage[255],
	supdated
}

new player_messages[MAXPLAYERS + 1][MAXPLAYERS + 1][player_display_messages];

enum spectator_data {
	Handle: stimer,
	Float: srequested,
	starget
}

enum gameme_data {
	parmor, phealth, ploc1, ploc2, ploc3, pangle, pmoney, palive,
	pspectator[spectator_data]
}

new gameme_players[MAXPLAYERS + 1][gameme_data];


// hit location tracking

#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define MAX_LOG_WEAPONS    28
#define LOG_HIT_OFFSET     8

enum weapon_data {wshots, whits, wkills, wheadshots, wteamkills, wdamage, wdeaths, whealth, wgeneric, whead, wchest, wstomach, wleftarm, wrightarm, wleftleg, wrightleg}
	
new player_weapons[MAXPLAYERS + 1][MAX_LOG_WEAPONS][weapon_data];


new Handle: gameme_block_chat_commands;
new Handle: gameme_message_prefix;
new Handle: gameme_protect_address;
new Handle: gameme_display_spectatorinfo;
new const String: blocked_commands[][] = { "rank", "skill", "points", "place", "session", "session_data", 
                             	       	   "kpd", "kdratio", "kdeath", "next", "load", "status", "servers", 
                                	       "top20", "top10", "top5", "clans", "cheaters", "statsme", "weapons", 
                                    	   "weapon", "action", "actions", "accuracy", "targets", "target",
	                                       "kills", "kill", "player_kills", "cmd", "cmds", "command",
    	                                   "hlx_display 0", "hlx_display 1", "hlx_teams 0", "hlx_teams 1",
        	                               "hlx_hideranking",  "hlx_chat 0", "hlx_chat 1",
            	                           "gameme_display 0", "gameme_display 1", "gameme_teams 0", "gameme_teams 1",
                	                       "gameme_hideranking",  "gameme_chat 0", "gameme_chat 1",
                    	                   "servers 1", "servers 2", "servers 3", "gstats", "global_stats",
                        	               "hlx", "hlstatsx", "hlx_menu", "gameme", "gameme_menu" };

new Handle: gameMEMenuMain;
new Handle: gameMEMenuAuto;
new Handle: gameMEMenuEvents;

new Handle: PlayerColorArray;
new ColorSlotArray[] = { -1, -1, -1, -1, -1, -1 };

new const String: ct_models[4][] = {"models/player/ct_urban.mdl", 
          	            	        "models/player/ct_gsg9.mdl", 
            	            	    "models/player/ct_sas.mdl", 
                		            "models/player/ct_gign.mdl"};
                                
new const String: ts_models[4][] = {"models/player/t_phoenix.mdl", 
                              		"models/player/t_leet.mdl", 
                              		"models/player/t_arctic.mdl", 
                              		"models/player/t_guerilla.mdl"};

new String: message_prefix[32];
new Handle: message_recipients;
new Handle: gameme_enable_log_locations;

new gameme_log_location = 1;
new gameme_display_spectator = 0;


/**
 *  Counter-Strike: Source
 */

#define MAX_CSS_WEAPON_COUNT 28
new const String: css_weapon_list[][] = { "ak47", "m4a1", "awp", "deagle", "mp5navy", "aug", "p90",
										  "famas", "galil", "scout", "g3sg1", "hegrenade", "usp",
										  "glock", "m249", "m3", "elite", "fiveseven", "mac10",
										  "p228", "sg550", "sg552", "tmp", "ump45", "xm1014", "knife",
										  "smokegrenade", "flashbang" };


/**
 *  Day of Defeat: Source
 */

#define MAX_DODS_WEAPON_COUNT 26
new const String: dods_weapon_list[][] = {
									 "thompson",		// 11
									 "m1carbine",		// 7
									 "k98",				// 8
									 "k98_scoped",		// 10	// 34
									 "mp40",			// 12
									 "mg42",			// 16	// 36
									 "mp44",			// 13	// 38
									 "colt",			// 3
									 "garand",			// 31	// 6
									 "spring",			// 9	// 33
									 "c96",				// 5
									 "bar",				// 14
									 "30cal",			// 15	// 35
									 "bazooka",			// 17
									 "pschreck",		// 18
									 "p38",				// 4
									 "spade",			// 2
									 "frag_ger",		// 20
									 "punch",			// 30	// 29
									 "frag_us",			// 19
									 "amerknife",		// 1
									 "riflegren_ger",	// 26
									 "riflegren_us",	// 25
									 "smoke_ger",		// 24
									 "smoke_us",		// 23
									 "dod_bomb_target"
								};


/**
 *  Left4Dead 
 */
 
 #define MAX_L4D_WEAPON_COUNT 23
new const String: l4d_weapon_list[][] = { "rifle", "autoshotgun", "pumpshotgun", "smg", "dual_pistols",
										  "pipe_bomb", "hunting_rifle", "pistol", "prop_minigun",
										  "tank_claw", "hunter_claw", "smoker_claw", "boomer_claw",
										  "smg_silenced", "pistol_magnum", "rifle_ak47", "rifle_desert",
										  "shotgun_chrome", "shotgun_spas", "sniper_military", "jockey_claw",
										  "splitter_claw", "charger_claw"										  
										  };
 
enum l4dii_plugin_data {
	active_weapon_offset
}

new l4dii_data[l4dii_plugin_data];


/**
 *  Half-Life 2: Deathmatch
 */

#define MAX_HL2MP_WEAPON_COUNT 6
new const String: hl2mp_weapon_list[][] = { "crossbow_bolt", "smg1", "357", "shotgun", "ar2", "pistol" }; 

#define HL2MP_CROSSBOW 0

enum hl2mp_plugin_data {
	Handle: teamplay,
	bool: teamplay_enabled,
	Handle: boltchecks,
	crossbow_owner_offset
}

new hl2mp_data[hl2mp_plugin_data];

enum hl2mp_player {
	next_hitgroup,
	nextbow_hitgroup
}

new hl2mp_players[MAXPLAYERS + 1][hl2mp_player];


/**
 *  Zombie Panic! Source
 */

#define MAX_ZPS_WEAPON_COUNT 11
new const String: zps_weapon_list[][] = { "870", "revolver", "ak47", "usp", "glock18c", "glock", "mp5", "m4", "supershorty", "winchester", "ppk"};

enum zps_player {
	next_hitgroup
}

new zps_players[MAXPLAYERS + 1][zps_player];


/**
 *  Insurgency: Modern Infantry Comba
 */

#define MAX_INSMOD_WEAPON_COUNT 19
new const String: insmod_weapon_list[][] = { "makarov", "m9", "sks", "m1014", "toz", "svd", "rpk", "m249", "m16m203", "l42a1", "m4med", "m4", "m16a4", "m14", "fnfal", "aks74u", "ak47", "kabar", "bayonet"}; 

enum insmod_player {
	last_weapon
}

new insmod_players[MAXPLAYERS + 1][insmod_player];


/**
 *  Team Fortress 2
 */

#define TF2_UNLOCKABLE_BIT (1<<30)
#define TF2_WEAPON_PREFIX_LENGTH 10
#define TF2_MAX_LOADOUT_SLOTS 8
#define TF2_OBJ_DISPENSER 0
#define TF2_OBJ_TELEPORTER 1
#define TF2_OBJ_SENTRYGUN 2
#define TF2_OBJ_SENTRYGUN_MINI 20
#define TF2_ITEMINDEX_DEMOSHIELD 131
#define TF2_ITEMINDEX_GUNBOATS 133
#define TF2_JUMP_NONE 0
#define TF2_JUMP_ROCKET_START 1
#define TF2_JUMP_ROCKET 2
#define TF2_JUMP_STICKY 3
#define TF2_LUNCHBOX_CHOCOLATE 159
#define TF2_LUNCHBOX_STEAK 311

#define MAX_TF2_WEAPON_COUNT 28
new const String: tf2_weapon_list[MAX_TF2_WEAPON_COUNT][] = {
	"ball",
	"flaregun",
	"minigun",
	"natascha",
	"pistol",
	"pistol_scout",
	"revolver",
	"ambassador",
	"scattergun",
	"force_a_nature",
	"shotgun_hwg",
	"shotgun_primary",
	"shotgun_pyro",
	"shotgun_soldier",
	"smg",
	"sniperrifle",
	"syringegun_medic",
	"blutsauger",
	"tf_projectile_arrow",
	"tf_projectile_pipe",
	"tf_projectile_pipe_remote",
	"sticky_resistance",
	"tf_projectile_rocket",
	"rocketlauncher_directhit",
	"deflect_rocket",
	"deflect_promode",
	"deflect_flare",
	"deflect_arrow"
};


enum tf2_plugin_data {
	Handle: weapons_trie, 
	Handle: items_kv,
	Handle: slots_trie,
	stun_ball_id,
	Handle: stun_balls,
	Handle: wearables,
	carry_offset,
	Handle: critical_hits,
	critical_hits_enabled,
	bool: block_next_logging
}

new tf2_data[tf2_plugin_data];


enum tf2_player {
	player_loadout0[TF2_MAX_LOADOUT_SLOTS],
	player_loadout1[TF2_MAX_LOADOUT_SLOTS],
	bool: player_loadout_updated,
	Handle: object_list,
	Float: object_removed,
	jump_status,
	Float: dalokohs,
	TFClassType: player_class,
	bool: carry_object
}

new tf2_players[MAXPLAYERS + 1][tf2_player];


/**
 *  Raw Messages Interface
 */

#define RAW_MESSAGE_RANK				1
#define RAW_MESSAGE_PLACE				2
#define RAW_MESSAGE_KDEATH				3
#define RAW_MESSAGE_SESSION_DATA		4
#define RAW_MESSAGE_TOP10				5
#define RAW_MESSAGE_NEXT				6

// callbacks
#define RAW_MESSAGE_CALLBACK_PLAYER		101
#define RAW_MESSAGE_CALLBACK_TOP10		102
#define RAW_MESSAGE_CALLBACK_NEXT		103

// internal usage
#define RAW_MESSAGE_CALLBACK_INT_CLOSE		1000
#define RAW_MESSAGE_CALLBACK_INT_SPECTATOR	1001


new Handle: gameMEStatsRankForward;
new Handle: gameMEStatsPublicCommandForward;
new Handle: gameMEStatsTop10Forward;
new Handle: gameMEStatsNextForward;

new global_query_id = 0;
new Handle: QueryCallbackArray;

#define CALLBACK_DATA_SIZE 7
enum callback_data {callback_data_id, Float: callback_data_time, callback_data_client, Handle: callback_data_plugin, Function: callback_data_function, callback_data_payload, callback_data_limit};


public OnPluginStart() 
{
	LogToGame("gameME Plugin %s (http://www.gameme.com), copyright (c) 2007-2011 by TTS Oetzel & Goerz GmbH", GAMEME_PLUGIN_VERSION);

	CreateConVar("gameme_plugin_version", GAMEME_PLUGIN_VERSION, "gameME Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("gameme_webpage", "http://www.gameme.com", "http://www.gameme.com", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gameme_block_chat_commands = CreateConVar("gameme_block_commands", "1", "If activated gameME commands are blocked from the chat area", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gameme_message_prefix = CreateConVar("gameme_message_prefix", "", "Define the prefix displayed on every gameME ingame message");
	HookConVarChange(gameme_message_prefix, OnMessagePrefixChange);
	gameme_protect_address = CreateConVar("gameme_protect_address", "", "Address to be protected for logging/forwarding");
	HookConVarChange(gameme_protect_address, OnProtectAddressChange);
	gameme_enable_log_locations = CreateConVar("gameme_log_locations", "1", "If activated the gameserver logs players locations", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(gameme_enable_log_locations, OnLogLocationsChange);
	gameme_display_spectatorinfo = CreateConVar("gameme_display_spectatorinfo", "0", "If activated gameME Stats data are displayed while spectating a player", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(gameme_display_spectatorinfo, OnDisplaySpectatorinfoChange);

	get_server_mod();

	CreateGameMEMenuMain(gameMEMenuMain);
	CreateGameMEMenuAuto(gameMEMenuAuto);
	CreateGameMEMenuEvents(gameMEMenuEvents);

	RegServerCmd("gameme_raw_message",   gameme_raw_message);
	RegServerCmd("gameme_psay",          gameme_psay);
	RegServerCmd("gameme_psay2",         gameme_psay2);
	RegServerCmd("gameme_csay",          gameme_csay);
	RegServerCmd("gameme_msay",          gameme_msay);
	RegServerCmd("gameme_tsay",          gameme_tsay);
	RegServerCmd("gameme_hint",          gameme_hint);
	RegServerCmd("gameme_khint",         gameme_khint);
	RegServerCmd("gameme_browse",        gameme_browse);
	RegServerCmd("gameme_swap",          gameme_swap);
	RegServerCmd("gameme_redirect",      gameme_redirect);
	RegServerCmd("gameme_player_action", gameme_player_action);
	RegServerCmd("gameme_team_action",   gameme_team_action);
	RegServerCmd("gameme_world_action",  gameme_world_action);

	RegConsoleCmd("say",                 gameme_block_commands);
	RegConsoleCmd("say_team",            gameme_block_commands);

	if (gameme_plugin[mod_id] == MOD_INSMOD) {
		RegConsoleCmd("say2",            gameme_block_commands);
	}

	RegServerCmd("log", ProtectLoggingChange);
	RegServerCmd("logaddress_del", ProtectForwardingChange);
	RegServerCmd("logaddress_delall", ProtectForwardingDelallChange);
	RegServerCmd("gameme_message_prefix_clear", MessagePrefixClear);

	gameme_plugin[custom_tags] = CreateArray(128);
	gameme_plugin[sv_tags] = FindConVar("sv_tags");
	gameme_plugin[sdk_version] = GuessSDKVersion();
	if (gameme_plugin[sv_tags] != INVALID_HANDLE) {
		AddPluginServerTag(GAMEME_TAG);
		HookConVarChange(gameme_plugin[sv_tags], OnTagsChange);
	}

	
	if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
		HookEvent("player_team", gameME_Event_PlyTeamChange, EventHookMode_Pre);
	}
	
	switch (gameme_plugin[mod_id]) {
		case MOD_L4DII: {
			l4dii_data[active_weapon_offset] = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		}
		case MOD_HL2MP: {
			hl2mp_data[crossbow_owner_offset] = FindSendPropInfo("CCrossbowBolt", "m_hOwnerEntity");
			hl2mp_data[teamplay] = FindConVar("mp_teamplay");
			if (hl2mp_data[teamplay] != INVALID_HANDLE) {
				hl2mp_data[teamplay_enabled] = GetConVarBool(hl2mp_data[teamplay]);
				HookConVarChange(hl2mp_data[teamplay], OnTeamPlayChange);
			}
			hl2mp_data[boltchecks] = CreateStack();
		}
		case MOD_TF2: {
			tf2_data[critical_hits] = FindConVar("tf_weapon_criticals");
			HookConVarChange(tf2_data[critical_hits], OnTF2CriticalHitsChange);
		
			tf2_data[stun_balls] = CreateStack();
			tf2_data[wearables] = CreateStack();
			tf2_data[items_kv] = CreateKeyValues("items_game");
			if (FileToKeyValues(tf2_data[items_kv], "scripts/items/items_game.txt")) {
				KvJumpToKey(tf2_data[items_kv], "items");
			}
			tf2_data[slots_trie] = CreateTrie();
			SetTrieValue(tf2_data[slots_trie], "primary", 0);
			SetTrieValue(tf2_data[slots_trie], "secondary", 1);
			SetTrieValue(tf2_data[slots_trie], "melee", 2);
			SetTrieValue(tf2_data[slots_trie], "pda", 3);
			SetTrieValue(tf2_data[slots_trie], "pda2", 4);
			SetTrieValue(tf2_data[slots_trie], "building", 5);
			SetTrieValue(tf2_data[slots_trie], "head", 6);
			SetTrieValue(tf2_data[slots_trie], "misc", 7);

			for (new i = 0; (i <= MAXPLAYERS); i++) {
				tf2_players[i][object_list]  = CreateStack(); 
				tf2_players[i][carry_object] = false; 
				tf2_players[i][jump_status]  = 0;
			}
			
			init_tf2_weapon_trie();
			AddGameLogHook(OnTF2GameLog);
		}
	}


	GetConVarString(gameme_message_prefix, message_prefix, 32);

	PlayerColorArray = CreateArray();
	message_recipients = CreateStack();
	QueryCallbackArray = CreateArray(CALLBACK_DATA_SIZE);

	gameMEStatsRankForward = CreateGlobalForward("onGameMEStatsRank", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_Array, Param_Array, Param_String, Param_Array, Param_Array, Param_String);
	gameMEStatsPublicCommandForward = CreateGlobalForward("onGameMEStatsPublicCommand", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_Array, Param_Array, Param_String, Param_Array, Param_Array, Param_String);
	gameMEStatsTop10Forward = CreateGlobalForward("onGameMEStatsTop10", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String);
	gameMEStatsNextForward = CreateGlobalForward("onGameMEStatsNext", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String, Param_String);
}


public OnPluginEnd() 
{
	if (PlayerColorArray != INVALID_HANDLE) {
		CloseHandle(PlayerColorArray);
	}
	if (message_recipients != INVALID_HANDLE) {
		CloseHandle(message_recipients);
	}
	if (QueryCallbackArray != INVALID_HANDLE) {
		CloseHandle(QueryCallbackArray);
	}
	
	if (gameme_plugin[mod_id] == MOD_CSS) {
		for (new i = 1; (i <= MaxClients); i++) {
			if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[i][pspectator][stimer]);
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
			}
		}
	}
}


#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("gameme");

	CreateNative("DisplayGameMEStatsMenu", native_display_menu);
	CreateNative("gameMEStatsColorAllPlayers", native_color_all_players);
	CreateNative("QueryGameMEStats", native_query_gameme_stats);
	CreateNative("QueryGameMEStatsTop10", native_query_gameme_stats);
	CreateNative("QueryGameMEStatsNext", native_query_gameme_stats);
	CreateNative("QueryIntGameMEStats", native_query_gameme_stats);

	MarkNativeAsOptional("CS_SwitchTeam");
	MarkNativeAsOptional("CS_RespawnPlayer");
	MarkNativeAsOptional("SetCookieMenuItem");
	MarkNativeAsOptional("SDKHook");
	
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
#else 	
	return true;
#endif
}


public OnAllPluginsLoaded()
{
	if (GetExtensionFileStatus("clientprefs.ext") == 1) {
		SetCookieMenuItem(gameMESettingsMenu, 0, "gameME Settings");
	}

	if (GetExtensionFileStatus("sdkhooks.ext") == 1) {
		LogToGame("Extension SDK Hooks is available");
		gameme_plugin[sdkhook_available] = true;
	}
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (gameme_plugin[sdkhook_available]) {
				switch (gameme_plugin[mod_id]) {
					case MOD_HL2MP: {
						SDKHook(i, SDKHook_FireBulletsPost,  OnHL2MPFireBullets);
						SDKHook(i, SDKHook_TraceAttackPost,  OnHL2MPTraceAttack);
						SDKHook(i, SDKHook_OnTakeDamagePost, OnHL2MPTakeDamage);
					}
					case MOD_ZPS: {
						SDKHook(i, SDKHook_FireBulletsPost,  OnZPSFireBullets);
						SDKHook(i, SDKHook_TraceAttackPost,  OnZPSTraceAttack);
						SDKHook(i, SDKHook_OnTakeDamagePost, OnZPSTakeDamage);
					}
					case MOD_TF2: {
						SDKHook(i, SDKHook_OnTakeDamagePost, OnTF2TakeDamage_Post);
						SDKHook(i, SDKHook_OnTakeDamage, 	 OnTF2TakeDamage);

						tf2_players[i][player_loadout_updated] = true;
						tf2_players[i][carry_object] = false;
						tf2_players[i][object_removed] = 0.0;
						tf2_players[i][player_class] = TFClass_Unknown;

						for (new j = 0; j < TF2_MAX_LOADOUT_SLOTS; j++) {
							tf2_players[i][player_loadout0][j] = -1;
							tf2_players[i][player_loadout1][j] = -1;
						}

					}
				}
			}

			if (!IsFakeClient(i)) {
				QueryClientConVar(i, "cl_language", ConVarQueryFinished: ClientConVar, i);
			}
			
			if (gameme_plugin[mod_id] == MOD_CSS) {
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
				for (new j = 0; (j <= MAXPLAYERS); j++) {
					player_messages[j][i][supdated] = 1;
					strcopy(player_messages[j][i][smessage], 255, "");
				}
			}
		}
	}
}


public gameMESettingsMenu(client, CookieMenuAction: action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption) {
		DisplayMenu(gameMEMenuMain, client, MENU_TIME_FOREVER);
	}
}


public OnMapStart()
{
	get_server_mod();

	for (new i = 0; (i <= MAXPLAYERS); i++) {
		reset_player_data(i);
	}
	
	if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_HL2MP) ||
	    (gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_FF) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) ||
	    (gameme_plugin[mod_id] == MOD_CSP)) {		

		decl String: map_name[64];
		GetCurrentMap(map_name, 64);

		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++) {
			decl String: team_name[32];
			if (gameme_plugin[mod_id] == MOD_INSMOD) {
				if ((strcmp(map_name, "ins_baghdad") == 0) || (strcmp(map_name, "ins_karam") == 0)) {
					switch (team_index) {
						case 1:
							strcopy(team_name, 32, "Iraqi Insurgents");
						case 2:
							strcopy(team_name, 32, "U.S. Marines");
						case 3:
							strcopy(team_name, 32, "SPECTATOR");
						default:
							strcopy(team_name, 32, "Unassigned");
					}
				} else {
					switch (team_index) {
						case 1:
							strcopy(team_name, 32, "U.S. Marines");
						case 2:
							strcopy(team_name, 32, "Iraqi Insurgents");
						case 3:
							strcopy(team_name, 32, "SPECTATOR");
						default:
							strcopy(team_name, 32, "Unassigned");
					}
				}
			} else {
				GetTeamName(team_index, team_name, 32);
			}

			if (strcmp(team_name, "") != 0) {
				team_list[team_index] = team_name;
			}
		}
	}
	
	if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
		find_player_team_slot(2);
		find_player_team_slot(3);
	}
	
	ClearArray(QueryCallbackArray);
}


get_server_mod()
{
	if (strcmp(gameme_plugin[game_mod], "") == 0) {
		new String: game_description[64];
		GetGameDescription(game_description, 64, true);
	
		if (StrContains(game_description, "Counter-Strike", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "CSS");
			gameme_plugin[mod_id] = MOD_CSS;
		}
		if (StrContains(game_description, "Day of Defeat", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "DODS");
			gameme_plugin[mod_id] = MOD_DODS;
		}
		if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "HL2MP");
			gameme_plugin[mod_id] = MOD_HL2MP;
		}
		if (StrContains(game_description, "Team Fortress", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "TF2");
			gameme_plugin[mod_id] = MOD_TF2;
		}
		if (StrContains(game_description, "Insurgency", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "INSMOD");
			gameme_plugin[mod_id] = MOD_INSMOD;
		}
		if (StrContains(game_description, "L4D", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "L4D");
			gameme_plugin[mod_id] = MOD_L4D;
		}
		if (StrContains(game_description, "Left 4 Dead 2", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "L4DII");
			gameme_plugin[mod_id] = MOD_L4DII;
		}
		if (StrContains(game_description, "Fortress Forever", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "FF");
			gameme_plugin[mod_id] = MOD_FF;
		}
		if (StrContains(game_description, "CSPromod", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "CSP");
			gameme_plugin[mod_id] = MOD_CSP;
		}
		if (StrContains(game_description, "ZPS", false) != -1) {
			strcopy(gameme_plugin[game_mod], 32, "ZPS");
			gameme_plugin[mod_id] = MOD_ZPS;
		}
		
		// game mod could not detected, try further
		if (strcmp(gameme_plugin[game_mod], "") == 0) {
			new String: game_folder[64];
			GetGameFolderName(game_folder, 64);

			if (StrContains(game_folder, "cstrike", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "CSS");
				gameme_plugin[mod_id] = MOD_CSS;
			}
			if (StrContains(game_folder, "dod", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "DODS");
				gameme_plugin[mod_id] = MOD_DODS;
			}
			if (StrContains(game_folder, "hl2mp", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "HL2MP");
				gameme_plugin[mod_id] = MOD_HL2MP;
			}
			if (StrContains(game_folder, "tf", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "TF2");
				gameme_plugin[mod_id] = MOD_TF2;
			}
			if (StrContains(game_folder, "insurgency", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "INSMOD");
				gameme_plugin[mod_id] = MOD_INSMOD;
			}
			if (StrContains(game_folder, "left4dead", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "L4D");
				gameme_plugin[mod_id] = MOD_L4D;
			}
			if (StrContains(game_folder, "left4dead2", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "L4DII");
				gameme_plugin[mod_id] = MOD_L4DII;
			}
			if (StrContains(game_folder, "FortressForever", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "FF");
				gameme_plugin[mod_id] = MOD_FF;
			}
			if (StrContains(game_folder, "cspromod", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "CSP");
				gameme_plugin[mod_id] = MOD_CSP;
			}
			if (StrContains(game_folder, "zps", false) != -1) {
				strcopy(gameme_plugin[game_mod], 32, "ZPS");
				gameme_plugin[mod_id] = MOD_ZPS;
			}
			if (strcmp(gameme_plugin[game_mod], "") == 0) {
				LogToGame("gameME - Game Detection: Failed (%s, %s)", game_description, game_folder);
			}
		}

		// setup hooks
		switch (gameme_plugin[mod_id]) {
			case MOD_CSS: {
				HookEvent("weapon_fire",  			 Event_CSSPlayerFire);
				HookEvent("player_hurt",  			 Event_CSSPlayerHurt);
				HookEvent("player_death", 			 Event_CSSPlayerDeath);
				HookEvent("player_spawn",			 Event_CSSPlayerSpawn);
				HookEvent("round_start",   			 Event_CSSRoundStart);
				HookEvent("round_end",    			 Event_CSSRoundEnd);
				HookEvent("round_mvp",               Event_CSSRoundMVP);

				HookEvent("bomb_dropped",			gameME_Event_PlyBombDropped, EventHookMode_Pre);
				HookEvent("bomb_pickup",     		gameME_Event_PlyBombPickup,  EventHookMode_Pre);
				HookEvent("bomb_planted",    		gameME_Event_PlyBombPlanted, EventHookMode_Pre);
				HookEvent("bomb_defused",    		gameME_Event_PlyBombDefused, EventHookMode_Pre);
				HookEvent("hostage_killed",  		gameME_Event_PlyHostageKill, EventHookMode_Pre);
				HookEvent("hostage_rescued", 		gameME_Event_PlyHostageResc, EventHookMode_Pre);
			}
			case MOD_DODS: {
				HookEvent("dod_stats_weapon_attack", Event_DODSWeaponAttack);
				HookEvent("player_hurt",  			 Event_DODSPlayerHurt);
				HookEvent("player_death", 			 Event_DODSPlayerDeath);
				HookEvent("player_spawn", 			 Event_DODSRoundEnd);
			}
			case MOD_TF2: {
				HookEvent("player_death", 			 	Event_TF2PlayerDeath);

				HookEvent("object_destroyed", 			Event_TF2ObjectDestroyedPre, EventHookMode_Pre);
				HookEvent("player_builtobject", 	 	Event_TF2PlayerBuiltObjectPre, EventHookMode_Pre);
				HookEvent("player_spawn", 			 	Event_TF2PlayerSpawn);
				HookEvent("object_removed", 			Event_TF2ObjectRemoved);
				HookEvent("post_inventory_application", Event_TF2PostInvApp);
				HookEvent("teamplay_win_panel",     	Event_TF2WinPanel);
				HookEvent("arena_win_panel",         	Event_TF2WinPanel);
				HookEvent("player_teleported",       	Event_TF2PlayerTeleported);

				HookEvent("rocket_jump", 				Event_TF2RocketJump);
				HookEvent("rocket_jump_landed", 	 	Event_TF2JumpLanded);
				HookEvent("sticky_jump", 				Event_TF2StickyJump);
				HookEvent("sticky_jump_landed", 	 	Event_TF2JumpLanded);
				HookEvent("object_deflected", 			Event_TF2ObjectDeflected);

				HookEvent("player_stealsandvich",    	Event_TF2StealSandvich);
				HookEvent("player_stunned",          	Event_TF2Stunned);
				HookEvent("player_escort_score",     	Event_TF2EscortScore);
				HookEvent("deploy_buff_banner",      	Event_TF2DeployBuffBanner);
				HookEvent("medic_defended",          	Event_TF2MedicDefended);
				
				HookUserMessage(GetUserMessageId("PlayerJarated"),       Event_TF2Jarated);
				HookUserMessage(GetUserMessageId("PlayerShieldBlocked"), Event_TF2ShieldBlocked);
				
				AddNormalSoundHook(NormalSHook: Event_TF2SoundHook);
				
				tf2_data[carry_offset] = FindSendPropInfo("CTFPlayer", "m_bCarryingObject");
			}
			case MOD_L4D, MOD_L4DII: {
				HookEvent("weapon_fire",  			 Event_L4DPlayerFire);
				HookEvent("weapon_fire_on_empty",  	 Event_L4DPlayerFire);
				HookEvent("player_hurt",  			 Event_L4DPlayerHurt);
				HookEvent("infected_hurt",  		 Event_L4DInfectedHurt);
				HookEvent("player_death", 			 Event_L4DPlayerDeath);
				HookEvent("player_spawn", 			 Event_L4DPlayerSpawn);
				HookEvent("round_end_message",		 Event_L4DRoundEnd, EventHookMode_PostNoCopy);
		
				HookEvent("survivor_rescued",		 Event_L4DRescueSurvivor);
				HookEvent("heal_success", 			 Event_L4DHeal);
				HookEvent("revive_success", 		 Event_L4DRevive);
				HookEvent("witch_harasser_set", 	 Event_L4DStartleWitch);
				HookEvent("lunge_pounce", 			 Event_L4DPounce);
				HookEvent("player_now_it", 			 Event_L4DBoomered);
				HookEvent("friendly_fire", 			 Event_L4DFF);
				HookEvent("witch_killed", 			 Event_L4DWitchKilled);
				HookEvent("award_earned", 			 Event_L4DAward);

				if (gameme_plugin[mod_id] == MOD_L4DII) {
					HookEvent("defibrillator_used", 	 Event_L4DDefib);
					HookEvent("adrenaline_used", 	     Event_L4DAdrenaline);
					HookEvent("jockey_ride", 		     Event_L4DJockeyRide);
					HookEvent("charger_pummel_start",    Event_L4DChargerPummelStart);
					HookEvent("vomit_bomb_tank",         Event_L4DVomitBombTank);
					HookEvent("scavenge_match_finished", Event_L4DScavengeEnd);
					HookEvent("versus_match_finished",   Event_L4DVersusEnd);
					HookEvent("charger_killed",          Event_L4dChargerKilled);
				}
			
			}
			case MOD_INSMOD: {
				HookEvent("player_hurt",  			 Event_INSMODPlayerHurt); 
				HookEvent("player_death", 			 Event_INSMODPlayerDeath);
				HookEvent("player_spawn", 			 Event_INSMODPlayerSpawn);
				HookEvent("round_end",    			 Event_INSMODRoundEnd);
				
				HookUserMessage(GetUserMessageId("ObjMsg"), Event_INSMODObjMsg);
			}	
			case MOD_HL2MP: {
				HookEvent("player_death",            Event_HL2MPPlayerDeath);
				HookEvent("player_spawn",            Event_HL2MPPlayerSpawn);
				HookEvent("round_end",               Event_HL2MPRoundEnd, EventHookMode_PostNoCopy);
			}
			case MOD_ZPS: {
				HookEvent("player_death",            Event_ZPSPlayerDeath);
				HookEvent("player_spawn",            Event_ZPSPlayerSpawn);
				HookEvent("round_end",               Event_ZPSRoundEnd, EventHookMode_PostNoCopy);
			}
			case MOD_CSP: {
				HookEvent("round_start",   			 Event_CSPRoundStart);
				HookEvent("round_end",    			 Event_CSPRoundEnd);
			}
		} // end switch 
		
		// player death event
		HookEvent("player_death", gameME_Event_PlyDeath, EventHookMode_Pre);

		if ((gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) || (gameme_plugin[mod_id] == MOD_INSMOD)) {
			// since almost no deaths occurs force the data to be logged at least every 180 seconds
			CreateTimer(180.0, flush_weapon_logs, 0, TIMER_REPEAT);
		}

		// player location logging
		if (gameme_enable_log_locations != INVALID_HANDLE) {
			new enable_log_locations = GetConVarInt(gameme_enable_log_locations);
			if (enable_log_locations == 1) {
				gameme_log_location = 1;
				LogToGame("gameME location logging activated");
			} else if (enable_log_locations == 0) {
				gameme_log_location = 0;
				LogToGame("gameME location logging deactivated");
			}
		} else {
			gameme_log_location = 0;
		}

		LogToGame("gameME - Game Detection: %s [%s]", game_description, gameme_plugin[game_mod]);

	}
}


public OnClientPutInServer(client)
{
	if (client > 0) {
		if (gameme_plugin[sdkhook_available]) {
			switch (gameme_plugin[mod_id]) {
				case MOD_HL2MP: {
					SDKHook(client, SDKHook_FireBulletsPost,  OnHL2MPFireBullets);
					SDKHook(client, SDKHook_TraceAttackPost,  OnHL2MPTraceAttack);
					SDKHook(client, SDKHook_OnTakeDamagePost, OnHL2MPTakeDamage);
				}
				case MOD_ZPS: {
					SDKHook(client, SDKHook_FireBulletsPost,  OnZPSFireBullets);
					SDKHook(client, SDKHook_TraceAttackPost,  OnZPSTraceAttack);
					SDKHook(client, SDKHook_OnTakeDamagePost, OnZPSTakeDamage);
				}
				case MOD_TF2: {
					SDKHook(client, SDKHook_OnTakeDamagePost, OnTF2TakeDamage_Post);
					SDKHook(client, SDKHook_OnTakeDamage, 	  OnTF2TakeDamage);
			
					tf2_players[client][player_loadout_updated] = true;
					tf2_players[client][carry_object] = false;
					tf2_players[client][object_removed] = 0.0;
					tf2_players[client][player_class] = TFClass_Unknown;

					for (new i = 0; (i < TF2_MAX_LOADOUT_SLOTS); i++) {
						tf2_players[client][player_loadout0][i] = -1;
						tf2_players[client][player_loadout1][i] = -1;
					}
				}
			}
		}

		reset_player_data(client);
		if (!IsFakeClient(client)) {
			QueryClientConVar(client, "cl_language", ConVarQueryFinished:ClientConVar, client);
		}
		
		if (gameme_plugin[mod_id] == MOD_CSS) {
			if (gameme_display_spectator == 1) {
				gameme_players[client][pspectator][stimer] = INVALID_HANDLE;
				for (new j = 0; (j <= MAXPLAYERS); j++) {
					player_messages[j][client][supdated] = 1;
					strcopy(player_messages[j][client][smessage], 255, "");
				}
				if (!IsClientObserver(client)) {
					gameme_players[client][palive] = 0;
					gameme_players[client][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}


public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	if (IsClientConnected(client)) {
		log_player_settings(client, "setup", cvarName, cvarValue);
	}
}


get_weapon_index(const String: weapon_list[][], weapon_list_count, const String: weapon_name[])
{
	new loop_break = 0;
	new index = 0;
	
	while ((loop_break == 0) && (index < weapon_list_count)) {
   	    if (strcmp(weapon_name, weapon_list[index], true) == 0) {
       		loop_break++;
		} else {
			index++;
		}
	}

	if (loop_break == 0) {
		return -1;
	} else {
		return index;
	}
}


init_tf2_weapon_trie()
{

	tf2_data[weapons_trie] = CreateTrie();
	for (new i = 0; i < MAX_TF2_WEAPON_COUNT; i++) {
		SetTrieValue(tf2_data[weapons_trie], tf2_weapon_list[i], i);
	}
	
	new index;
	if(GetTrieValue(tf2_data[weapons_trie], "ball", index)) {
		SetTrieValue(tf2_data[weapons_trie], "tf_projectile_stun_ball", index);
		tf2_data[stun_ball_id] = index;
	}
}


get_tf2_weapon_index(const String: weapon_name[], client = 0, weapon = -1)
{
	new weapon_index = -1;
	new bool: unlockable_weapon;
	new reflect_index = -1;
	
	if(GetTrieValue(tf2_data[weapons_trie], weapon_name, weapon_index)) {
		if (weapon_index & TF2_UNLOCKABLE_BIT) {
			weapon_index &= ~TF2_UNLOCKABLE_BIT;
			unlockable_weapon = true;
		}
		
		if ((weapon_name[3] == 'p') && (weapon > -1)) {
			if (client == GetEntProp(weapon, Prop_Send, "m_iDeflected")) {
				switch(weapon_name[14]) {
					case 'a':
						reflect_index = get_tf2_weapon_index("deflect_arrow");
					case 'f':
						reflect_index = get_tf2_weapon_index("deflect_flare");
					case 'p': {
						if (weapon_name[19] == 0) {
							reflect_index = get_tf2_weapon_index("deflect_promode");
						}
					}
					case 'r':
						reflect_index = get_tf2_weapon_index("deflect_rocket");
				}
			}
		}

		if (reflect_index > -1) {
			return reflect_index;
		}

		if ((unlockable_weapon) && (client > 0)) {
			new slot = 0;
			if (tf2_players[client][player_class] == TFClass_DemoMan) {
				slot = 1;
			}
			new item_index = tf2_players[client][player_loadout0][slot];
			switch (item_index) {
				case 36, 41, 45, 61, 127, 130:
					weapon_index++;
			}
		}
	}
	return weapon_index;
}



reset_player_data(player_index) 
{
	for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
		player_weapons[player_index][i][wshots]     = 0;
		player_weapons[player_index][i][whits]      = 0;
		player_weapons[player_index][i][wkills]     = 0;
		player_weapons[player_index][i][wheadshots] = 0;
		player_weapons[player_index][i][wteamkills] = 0;
		player_weapons[player_index][i][wdamage]    = 0;
		player_weapons[player_index][i][wdeaths]    = 0;
		player_weapons[player_index][i][wgeneric]   = 0;
		player_weapons[player_index][i][whead]      = 0;
		player_weapons[player_index][i][wchest]     = 0;
		player_weapons[player_index][i][wstomach]   = 0;
		player_weapons[player_index][i][wleftarm]   = 0;
		player_weapons[player_index][i][wrightarm]  = 0;
		player_weapons[player_index][i][wleftleg]   = 0;
		player_weapons[player_index][i][wrightleg]  = 0;
	}
}


dump_player_data(player_index)
{
	if ((IsClientConnected(player_index)) && (IsClientInGame(player_index)))  {
		new is_logged = 0;
		for (new i = 0; (i < MAX_LOG_WEAPONS); i++) {
			if (player_weapons[player_index][i][wshots] > 0) {
				switch (gameme_plugin[mod_id]) {
					case MOD_CSS: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, css_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, css_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_DODS: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, dods_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, dods_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_L4D, MOD_L4DII: {
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, l4d_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, l4d_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_INSMOD: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, insmod_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, insmod_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_HL2MP: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, hl2mp_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, hl2mp_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_ZPS: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, zps_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
						if (player_weapons[player_index][i][whits] > 0) {
							LogToGame("\"%L\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", player_index, zps_weapon_list[i], player_weapons[player_index][i][whead], player_weapons[player_index][i][wchest], player_weapons[player_index][i][wstomach], player_weapons[player_index][i][wleftarm], player_weapons[player_index][i][wrightarm], player_weapons[player_index][i][wleftleg], player_weapons[player_index][i][wrightleg]); 
						}
					}
					case MOD_TF2: {								
						LogToGame("\"%L\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", player_index, tf2_weapon_list[i], player_weapons[player_index][i][wshots], player_weapons[player_index][i][whits], player_weapons[player_index][i][wkills], player_weapons[player_index][i][wheadshots], player_weapons[player_index][i][wteamkills], player_weapons[player_index][i][wdamage], player_weapons[player_index][i][wdeaths]); 
					}
				} // switch
				is_logged++;
			}
		}
		if (is_logged > 0) {
			reset_player_data(player_index);
		}
	}
	
}


public Action: flush_weapon_logs(Handle:timer, any:index) 
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
}


public Action: spectator_player_timer(Handle:timer, any: caller) 
{
	if ((gameme_plugin[mod_id] == MOD_CSS) && (IsValidEntity(caller))) {
		new observer_mode = GetEntProp(caller, Prop_Send, "m_iObserverMode");
		if ((!IsFakeClient(caller)) && (observer_mode == SPECTATOR_FIRSTPERSON) || (observer_mode == SPECTATOR_3RDPERSON)) {
			new target = GetEntPropEnt(caller, Prop_Send, "m_hObserverTarget");
			if ((target > 0) && (target <= MAXPLAYERS) && (IsClientConnected(target)) && (IsClientInGame(target))) {
				if (player_messages[caller][target][supdated] == 1) {
					for (new i = 0; (i <= MAXPLAYERS); i++) {
						player_messages[i][target][supdated] = 0;
					}
					QueryIntGameMEStats("spectatorinfo", target, QuerygameMEStatsIntCallback, QUERY_TYPE_SPECTATOR);
				}
			
				if (target != gameme_players[caller][pspectator][starget]) {
					gameme_players[caller][pspectator][srequested] = 0.0;
				}

				if (strcmp(player_messages[caller][target][smessage], "") != 0) {
					if ((caller > 0) && (!IsFakeClient(caller)) && (IsClientConnected(caller)) && (IsClientInGame(caller))) {
						if ((GetGameTime() - gameme_players[caller][pspectator][srequested]) > 5) {
							new Handle: hBf;
							hBf = StartMessageOne("KeyHintText", caller);
							if (hBf != INVALID_HANDLE) {
								BfWriteByte(hBf, 1); 
								BfWriteString(hBf, player_messages[caller][target][smessage]);
								EndMessage();
							}
							gameme_players[caller][pspectator][srequested] = GetGameTime();
						}
					}
				} else {
					if (target != gameme_players[caller][pspectator][starget]) {
						new Handle: hBf;
						hBf = StartMessageOne("KeyHintText", caller);
						if (hBf != INVALID_HANDLE) {
							BfWriteByte(hBf, 1); 
							BfWriteString(hBf, "");
							EndMessage();
						}
						gameme_players[caller][pspectator][srequested] = GetGameTime();
					}
				}
				gameme_players[caller][pspectator][starget] = target;
			}
		}
	}
}


public QuerygameMEStatsIntCallback(query_command, query_payload, query_caller[MAXPLAYERS + 1], query_target[MAXPLAYERS + 1], const String: query_message_prefix[], const String: query_message[])
{
	if ((query_caller[0] > 0) && (query_command == RAW_MESSAGE_CALLBACK_INT_SPECTATOR)) {
		if ((query_payload == QUERY_TYPE_SPECTATOR) && (query_target[0] > 0)) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				if (query_caller[i] > -1) {
					strcopy(player_messages[query_caller[i]][query_target[0]][smessage], 255, query_message);
					ReplaceString(player_messages[query_caller[i]][query_target[0]][smessage], 255, "\\n", "\10");
					gameme_players[query_caller[i]][pspectator][srequested] = 0.0;
				}
			}
		}
	}
}


public Action: Event_CSSPlayerFire(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"
	// "weapon"        "string"        // weapon name used

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			
			if ((weapon_index != 27) && // flashbang
			    (weapon_index != 11) && // hegrenade
			    (weapon_index != 26)) { // smokegrenade
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}
}


public Action: Event_DODSWeaponAttack(Handle: event, const String: name[], bool:dontBroadcast)
{
    // "attacker"      "short"
    // "weapon"        "byte"

	new userid   = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (userid > 0) {
		new log_weapon_index  = GetEventInt(event, "weapon");

		new weapon_index = -1;
		switch (log_weapon_index) {
			case 1 :
				weapon_index = 20;
			case 2 :
				weapon_index = 16;
			case 3 :
				weapon_index = 7;
			case 4 :
				weapon_index = 15;
			case 5 :
				weapon_index = 10;
			case 6 :
				weapon_index = 8;
			case 7 :
				weapon_index = 1;
			case 8 :
				weapon_index = 2;
			case 9 :
				weapon_index = 9;
			case 10 :
				weapon_index = 3;
			case 11 :
				weapon_index = 0;
			case 12 :
				weapon_index = 4;
			case 13 :
				weapon_index = 6;
			case 14 :
				weapon_index = 11;
			case 15 :
				weapon_index = 12;
			case 16 :
				weapon_index = 5;
			case 17 :
				weapon_index = 13;
			case 18 :
				weapon_index = 14;
			case 19 :
				weapon_index = 19;
			case 20 :
				weapon_index = 17;
			case 23 :
				weapon_index = 24;
			case 24 :
				weapon_index = 23;
			case 25 :
				weapon_index = 22;
			case 26 :
				weapon_index = 21;
			case 31 :
				weapon_index = 8;
			case 33 :
				weapon_index = 9;
			case 34 :
				weapon_index = 3;
			case 35 :
				weapon_index = 12;
			case 36 :
				weapon_index = 5;
			case 38 :
				weapon_index = 6;
		}
		
		if (weapon_index > -1) {
			if ((weapon_index != 25) && // dod_bomb_target
			    (weapon_index != 21) && // riflegren_ger
			    (weapon_index != 22) && // riflegren_us
			    (weapon_index != 23) && // smoke_ger
			    (weapon_index != 24)) { // smoke_us
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}

}


public Action: Event_L4DPlayerFire(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "userid"        "short"
	// "weapon"        "string"        // used weapon name  
	// "weaponid"      "short"         // used weapon ID
	// "count"         "short"         // number of bullets

	new userid   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if ((weapon_index != 12) && // entityflame
			    (weapon_index != 6)) { // inferno
				player_weapons[userid][weapon_index][wshots]++;
			}
		}
	}
}


public Action: Event_CSSPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // player index who was hurt
	//	"attacker"      "short"         // player index who attacked
	//	"health"        "byte"          // remaining health points
	//	"armor"         "byte"          // remaining armor points
	//	"weapon"        "string"        // weapon name attacker used, if not the world
	//	"dmg_health"    "byte"  		// damage done to health
	//	"dmg_armor"     "byte"          // damage done to armor
	//	"hitgroup"      "byte"          // hitgroup that was damaged

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
	}

	return Plugin_Continue;
}


public Action: Event_DODSPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user ID who attacked
	// "weapon"        "string"        // weapon name attacker used
	// "health"        "byte"          // health remaining
	// "damage"        "byte"          // how much damage in this attack
	// "hitgroup"      "byte"          // what hitgroup was hit

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(dods_weapon_list, MAX_DODS_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
	}

	return Plugin_Continue;
}


public Action: Event_L4DPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // Not networked
	// "userid"        "short"         // user ID who was hurt
	// "attacker"      "short"         // user id who attacked
	// "attackerentid" "long"          // entity id who attacked, if attacker not a player, and userid therefore invalid
	// "health"        "short"         // remaining health points
	// "armor"         "byte"          // remaining armor points
	// "weapon"        "string"        // weapon name attacker used, if not the world
	// "dmg_health"    "short"         // damage done to health
	// "dmg_armor"     "byte"          // damage done to armor
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "type"          "long"          // damage type

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		} else if (!strcmp(weapon_str, "insect_swarm")) {
			if ((victim > 0) && (IsClientInGame(victim)) && (GetClientTeam(victim) == 2) &&  (!GetEntProp(victim, Prop_Send, "m_isIncapacitated"))) {
				log_player_player_event(attacker, victim, "triggered", "spit_hurt");
			}
		} 

	}

	return Plugin_Continue;
}


public Action: Event_L4DInfectedHurt(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "local"         "1"             // don't network this, its way too spammy
	// "attacker"      "short"         // player userid who attacked
	// "entityid"      "long"          // entity id of infected
	// "hitgroup"      "byte"          // hitgroup that was damaged
	// "amount"        "short"         // how much damage was done                  
	// "type"          "long"          // damage type     

	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attacker > 0) {
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str[7]);
		if (weapon_index > -1) {
			if (player_weapons[attacker][weapon_index][wshots] == 0) {
				player_weapons[attacker][weapon_index][wshots]++;
			}
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += GetEventInt(event, "amount");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			}
		}
	}

	return Plugin_Continue;
}


public Action: Event_INSMODPlayerHurt(Handle: event, const String: name[], bool:dontBroadcast)
{ 	
	//  "userid"		"short"			// user ID on server 	
	//  "attacker"		"short"			// user ID on server of the attacker 	
	//  "dmg_health"	"short"			// lost health points 	
	//  "hitgroup"		"short"			// Hit groups 
	//  "weapon"		"string"		// Weapon name, like WEAPON_AK47
	
	new attacker  = GetEventInt(event, "attacker");
	new victim = GetEventInt(event, "userid");

	if ((attacker > 0) && (attacker != victim)) {
		decl String: weapon_str[32];
		GetEventString(event, "weapon", weapon_str, 32);
		new weapon_index = get_weapon_index(insmod_weapon_list, MAX_INSMOD_WEAPON_COUNT, weapon_str[7]);
		if (weapon_index > -1) {
			
			// we cannot track the shots
			//if (player_weapons[attacker][weapon_index][wshots] == 0) {
			//	player_weapons[attacker][weapon_index][wshots]++;
			//}
			
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage]  += GetEventInt(event, "dmg_health");
			new hitgroup  = GetEventInt(event, "hitgroup");
			if (hitgroup < 8) {
				player_weapons[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
			} else {
				player_weapons[attacker][weapon_index][hitgroup]++;
			} 
			if (hitgroup == HITGROUP_HEAD) {
				player_weapons[attacker][weapon_index][wheadshots]++;
				log_player_event(attacker, "triggered", "headshot");
			}
			insmod_players[attacker][last_weapon] = weapon_index;
		}
	}
	
	return Plugin_Continue;
} 

 
public Action: Event_CSSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	// "headshot"      "bool"          // signals a headshot
	// "dominated" 	   "short"		   // did killer dominate victim with this kill
	// "revenge" 	   "short" 		   // did killer get revenge on victim with this kill 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(css_weapon_list, MAX_CSS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				new headshot = GetEventBool(event, "headshot");
				if (headshot == 1) {
					player_weapons[attacker][weapon_index][wheadshots]++;
				}
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
				if (GetEventInt(event, "dominated")) {
					log_player_player_event(attacker, victim, "triggered", "domination");
				} else if (GetEventInt(event, "revenge")) {
					log_player_player_event(attacker, victim, "triggered", "revenge");
				}
			}
		}
		dump_player_data(victim);
		
		gameme_players[victim][palive] = 0;
		if ((gameme_display_spectator == 1) && (!IsFakeClient(victim))) {
			gameme_players[victim][pspectator][stimer] = CreateTimer(SPECTATOR_TIMER_INTERVAL, spectator_player_timer, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[j][attacker][supdated] = 1;
				player_messages[j][victim][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action: Event_DODSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death
	// "userid"        "short"         // user ID who died
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killed used

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(dods_weapon_list, MAX_DODS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}

	return Plugin_Continue;
}


public Action: Event_L4DPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID who died
	// "entityid"      "long"          // entity ID who died, userid should be used first, to get the dead Player.  Otherwise, it is not a player, so use this.         $
	// "attacker"      "short"         // user ID who killed   
	// "attackername"  "string"        // What type of zombie, so we don't have zombie names
	// "attackerentid" "long"          // if killer not a player, the entindex of who killed.  Again, use attacker first
	// "weapon"        "string"        // weapon name killer used
	// "headshot"      "bool"          // signals a headshot
	// "attackerisbot" "bool"          // is the attacker a bot
	// "victimname"    "string"        // What type of zombie, so we don't have zombie names
	// "victimisbot"   "bool"          // is the victim a bot     
	// "abort"         "bool"          // did the victim abort        
	// "type"          "long"          // damage type      
	// "victim_x"      "float"
	// "victim_y"      "float"
	// "victim_z"      "float"

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(l4d_weapon_list, MAX_L4D_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				new headshot = GetEventBool(event, "headshot");
				if (headshot == 1) {
					player_weapons[attacker][weapon_index][wheadshots]++;
				}
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}

	return Plugin_Continue;
}


public Action: Event_INSMODPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	//  "userid"	"short"   	// user ID who died				
	//  "attacker"	"short"	 	// user ID who killed
	//  "type"		"byte"		// type of death
	//  "nodeath"	"bool"		// true if death messages were off when player died

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			new weapon_index = insmod_players[attacker][last_weapon];
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}
	return Plugin_Continue;
}


public Event_HL2MPPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;		
				player_weapons[victim][weapon_index][wdeaths]++;
				if ((hl2mp_data[teamplay_enabled]) && (GetClientTeam(attacker) == GetClientTeam(victim))) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}	
			}
		}
		dump_player_data(victim);
	}
}


public Event_ZPSPlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// this extents the original player_death by a new fields
	// "userid"        "short"         // user ID who died                             
	// "attacker"      "short"         // user ID who killed
	// "weapon"        "string"        // weapon name killer used 
	
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if ((victim > 0) && (attacker > 0)) {
		if (attacker != victim) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_str);
			if (weapon_index > -1) {
				player_weapons[attacker][weapon_index][wkills]++;		
				player_weapons[victim][weapon_index][wdeaths]++;
				if (GetClientTeam(attacker) == GetClientTeam(victim)) {
					player_weapons[attacker][weapon_index][wteamkills]++;
				}
			}
		}
		dump_player_data(victim);
	}
}


public Action: Event_CSSPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
		if (gameme_display_spectator == 1) {
			if (gameme_players[userid][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[userid][pspectator][stimer]);
				gameme_players[userid][pspectator][stimer] = INVALID_HANDLE;
			}
		}
	}
	return Plugin_Continue;
}


public Action: Event_L4DPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
	return Plugin_Continue;
}


public Action: Event_INSMODPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
	return Plugin_Continue;
}


public Action: Event_HL2MPPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
	return Plugin_Continue;
}


public Action: Event_ZPSPlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	if (userid > 0) {
		reset_player_data(userid);
	}
	return Plugin_Continue;
}


public Action: Event_CSPRoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	LogToGame("World triggered \"Round_Start\"");
}


public Action: Event_CSSRoundStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (gameme_display_spectator == 1) {
		for (new i = 0; (i <= MAXPLAYERS); i++) {
			gameme_players[i][palive] = 1;
			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[i][j][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


public Action: Event_CSSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
		
		if (gameme_display_spectator == 1) {
			if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[i][pspectator][stimer]);
				gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
			}
		}
	}
	return Plugin_Continue;
}


public Action: Event_DODSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
	return Plugin_Continue;
}


public Action: Event_L4DRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
	return Plugin_Continue;
}


public Action: Event_INSMODRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}

	new team_index = GetEventInt(event, "winner");
	if (team_index > 0) {
		log_team_event(team_list[team_index], "Round_Win");
	}

	return Plugin_Continue;
}


public Action: Event_HL2MPRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
	return Plugin_Continue;
}


public Action: Event_ZPSRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	for (new i = 1; (i <= MaxClients); i++) {
		dump_player_data(i);
	}
	return Plugin_Continue;
}


public Action: Event_CSPRoundEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "Round_Win");
	}
	LogToGame("World triggered \"Round_End\"");
	return Plugin_Continue;
}


public Action: Event_CSSRoundMVP(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "mvp");
	}
}


public Action: Event_TF2PlayerDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"		"short"   	// user ID who died				
	// "attacker"	"short"	 	// user ID who killed
	// "weapon"	"string" 	// weapon name killer used 
	// "weaponid"	"short"		// ID of weapon killed used
	// "damagebits"	"long"		// bits of type of damage
	// "customkill"	"short"		// type of custom kill
	// "assister"	"short"		// user ID of assister
	// "weapon_logclassname"	"string" 	// weapon name that should be printed on the log
	// "stun_flags"	"short"	// victim's stun flags at the moment of death
	// "death_flags"	"short" //death flags.

	new death_flags = GetEventInt(event, "death_flags");
	if ((death_flags & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER) {
		return Plugin_Continue;
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((attacker > 0) && (victim > 0) && (attacker <= MaxClients)) {

		tf2_players[victim][jump_status] = TF2_JUMP_NONE;
		tf2_players[victim][carry_object] = false;

		new custom_kill = GetEventInt(event, "customkill");
		if (custom_kill > 0) {
			new victim_team_index = GetClientTeam(victim);
			new player_team_index = GetClientTeam(attacker);
				
			if (victim_team_index == player_team_index) {
				if (custom_kill == TF_CUSTOM_SUICIDE) {
					log_player_event(attacker, "triggered", "force_suicide");
				}
			} else {
				if (custom_kill == TF_CUSTOM_HEADSHOT) {
					log_player_event(attacker, "triggered", "headshot");
				} else if (custom_kill == TF_CUSTOM_BACKSTAB) {
					log_player_player_event(attacker, victim, "triggered", "backstab");
				}
			}
		}

		if (attacker != victim) {
			switch(tf2_players[attacker][jump_status]) {
				case 2:
					log_player_event(attacker, "triggered", "rocket_jump_kill");
				case 3:
					log_player_event(attacker, "triggered", "sticky_jump_kill");
			}

			new bits = GetEventInt(event, "damagebits");
			if ((bits & DMG_ACID) && (attacker > 0) && (custom_kill != TF_CUSTOM_HEADSHOT)) {
				log_player_event(attacker, "triggered", "crit_kill");
			} else if (bits & DMG_DROWN) {
				log_player_event(attacker, "triggered", "drowned");
			}
			if ((death_flags & TF_DEATHFLAG_FIRSTBLOOD) == TF_DEATHFLAG_FIRSTBLOOD) {
				log_player_event(attacker, "triggered", "first_blood");
			}
			if ((custom_kill == TF_CUSTOM_HEADSHOT) && (victim <= MaxClients) && (IsClientInGame(victim)) && ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0)) {
				log_player_event(attacker, "triggered", "airshot_headshot");
			}
		}

		decl String: weapon_log_name[64];
		GetEventString(event, "weapon_logclassname", weapon_log_name, 64);
		new weapon_index = get_tf2_weapon_index(weapon_log_name, attacker);
		if (weapon_index != -1) {
			player_weapons[attacker][weapon_index][wkills]++;
			if (custom_kill == TF_CUSTOM_HEADSHOT) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
			player_weapons[victim][weapon_index][wdeaths]++;
			if (GetClientTeam(victim) == GetClientTeam(attacker)) {
				player_weapons[attacker][weapon_index][wteamkills]++;
			}
		}
		dump_player_data(victim);
	}
	return Plugin_Continue;
}


public Action: Event_TF2PlayerTeleported(Handle: event, const String: name[], bool:dontBroadcast)
{
	//	"userid"        "short"         // userid of the player
	//	"builderid"     "short"         // userid of the player who built the teleporter

	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new builder = GetClientOfUserId(GetEventInt(event, "builderid"));
	if (((player > 0) && (builder > 0)) && (player != builder)) {
		log_player_player_event(builder, player, "triggered", "player_teleported", 1);
	}
}


public OnGameFrame()
{
	switch (gameme_plugin[mod_id]) {
		case MOD_HL2MP: {
			new bow_entity;
			while (PopStackCell(hl2mp_data[boltchecks], bow_entity))	{
				if (!IsValidEntity(bow_entity)) {
					continue;
				}
				new owner = GetEntDataEnt2(bow_entity, hl2mp_data[crossbow_owner_offset]);
				if ((owner < 0) || (owner > MaxClients)) {
					continue;
				}
				player_weapons[owner][HL2MP_CROSSBOW][wshots]++;
			}
		}
		case MOD_TF2: {
			new entity;
			if ((gameme_plugin[sdkhook_available]) && (tf2_data[stun_ball_id] > -1)) {
				while (PopStackCell(tf2_data[stun_balls], entity)) {
					if (IsValidEntity(entity)) {
						new owner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
						if ((owner > 0) && (owner <= MaxClients)) {
							player_weapons[owner][tf2_data[stun_ball_id]][wshots]++;
						}
					}
				}
			}

			while (PopStackCell(tf2_data[wearables], entity)) {
				if (IsValidEntity(entity)) {
					new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
					if ((owner > 0) && (owner <= MaxClients)) {

						new item_index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
						decl String: tmp_str[16];
						Format(tmp_str, 16, "%d", item_index);

						if (KvJumpToKey(tf2_data[items_kv], tmp_str)) {
							KvGetString(tf2_data[items_kv], "item_slot", tmp_str, 16);
							new slot;
							if (GetTrieValue(tf2_data[slots_trie], tmp_str, slot)) {
								if ((slot == 0) && (tf2_players[owner][player_class] == TFClass_DemoMan)) {
									slot++;
								}
								if (tf2_players[owner][player_loadout0][slot] != item_index) {
									tf2_players[owner][player_loadout0][slot] = item_index;
									tf2_players[owner][player_loadout_updated] = true;
								}
								tf2_players[owner][player_loadout1][slot] = entity;
							}
							KvGoBack(tf2_data[items_kv]);
						}
					}
				}
			}
	
			new client_count = GetClientCount();
			for (new i = 1; i <= client_count; i++) {
				if ((IsClientInGame(i)) && (GetEntData(i, tf2_data[carry_offset], 1))) {
					tf2_players[i][carry_object] = true;
				}
			}

		}
	
	}
}


public OnEntityCreated(entity, const String: classname[]) {
	switch (gameme_plugin[mod_id]) {
		case MOD_HL2MP: {
			if (strcmp(classname, "crossbow_bolt") == 0) {
				PushStackCell(hl2mp_data[boltchecks], entity);
			}
		}
		case MOD_TF2: {
			if(StrEqual(classname, "tf_projectile_stun_ball")) {
				PushStackCell(tf2_data[stun_balls], EntIndexToEntRef(entity));
			} else if(StrEqual(classname, "tf_wearable_item_demoshield") || StrEqual(classname, "tf_wearable_item")) {
				PushStackCell(tf2_data[wearables], EntIndexToEntRef(entity));
			}
		}
	}
}


public Action:OnTF2GameLog(const String: message[])
{
	if (tf2_data[block_next_logging]) {
		tf2_data[block_next_logging] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public OnLogLocationsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0)) {
			if (((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			   ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_enable_log_locations != INVALID_HANDLE) {
					new enable_log_locations = GetConVarInt(gameme_enable_log_locations);
					if (enable_log_locations == 1) {
						gameme_log_location = 1;
						LogToGame("gameME location logging activated");
					} else if (enable_log_locations == 0) {
						gameme_log_location = 0;
						LogToGame("gameME location logging deactivated");
					}
				} else {
					gameme_log_location = 0;
				}

			}
		}
	}
}


public OnDisplaySpectatorinfoChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		if ((strcmp(newVal, "0") == 0) || (strcmp(newVal, "1") == 0)) {
			if (((strcmp(newVal, "1") == 0) && (strcmp(oldVal, "1") != 0)) ||
			   ((strcmp(newVal, "0") == 0) && (strcmp(oldVal, "0") != 0))) {

				if (gameme_display_spectatorinfo != INVALID_HANDLE) {
					new display_info = GetConVarInt(gameme_display_spectatorinfo);
					if (display_info == 1) {
						gameme_display_spectator = 1;
						LogToGame("gameME spectator displaying activated");
					} else if (display_info == 0) {
						gameme_display_spectator = 0;
						for (new i = 0; (i <= MAXPLAYERS); i++) {
							if (gameme_players[i][pspectator][stimer] != INVALID_HANDLE) {
								KillTimer(gameme_players[i][pspectator][stimer]);
								gameme_players[i][pspectator][stimer] = INVALID_HANDLE;
							}
						}
						LogToGame("gameME spectator displaying deactivated");
					}
				} else {
					gameme_display_spectator = 0;
				}
			}
		}
	}
}


public OnTagsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (gameme_plugin[ignore_next_tag_change]){
		return;
	}
	
	new count = GetArraySize(gameme_plugin[custom_tags]);
	for (new i = 0; (i < count); i++) {
		decl String: tag[128];
		GetArrayString(gameme_plugin[custom_tags], i, tag, 128);
		AddPluginServerTag(tag);
	}
}

public OnProtectAddressChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0) {
		decl String: log_command[192];
		Format(log_command, 192, "logaddress_add %s", newVal);
		LogToGame("Command: %s", log_command);
		ServerCommand(log_command);
	}
}


public Action: ProtectLoggingChange(args)
{
	if (gameme_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(gameme_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			if (args >= 1) {
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if ((strcmp(log_action, "off") == 0) || (strcmp(log_action, "0") == 0)) {
					LogToGame("gameME address protection active, logging reenabled!");
					ServerCommand("log 1");
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action: ProtectForwardingChange(args)
{
	if (gameme_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(gameme_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			if (args == 1) {
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if (strcmp(log_action, protect_address) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("gameME address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			} else if (args > 1) {
				new String: log_action[192];
				for (new i = 1; i <= args; i++) {
					decl String: temp_argument[192];
					GetCmdArg(i, temp_argument, 192);
					strcopy(log_action[strlen(log_action)], 192, temp_argument);
				}
				if (strcmp(log_action, protect_address) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("gameME address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			
			}
		}
	}
	return Plugin_Continue;
}


public Action: ProtectForwardingDelallChange(args)
{
	if (gameme_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(gameme_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			decl String: log_command[192];
			Format(log_command, 192, "logaddress_add %s", protect_address);
			LogToGame("gameME address protection active, logaddress readded!");
			ServerCommand(log_command);
		}
	}
	return Plugin_Continue;
}


public OnMessagePrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(message_prefix, 32, newVal);
}


public Action: MessagePrefixClear(args)
{
	message_prefix = "";
}


public OnTeamPlayChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		hl2mp_data[teamplay_enabled] = GetConVarBool(hl2mp_data[teamplay]);
	}
}


public OnTF2CriticalHitsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	tf2_data[critical_hits_enabled] = GetConVarBool(tf2_data[critical_hits]);
	if(!tf2_data[critical_hits_enabled]) {
		for(new i = 1; i <= MaxClients; i++) {
			dump_player_data(i);
		}
	}
}


public Action: TF2_CalcIsAttackCritical(attacker, weapon, String: weaponname[], &bool: result)
{
	if ((gameme_plugin[sdkhook_available]) && (attacker > 0)) {
		new weapon_index = get_tf2_weapon_index(weaponname[TF2_WEAPON_PREFIX_LENGTH], attacker);
		if (weapon_index != -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
	return Plugin_Continue;
}


log_player_settings(client, String: verb[32], const String: settings_name[], const String: settings_value[])
{
	if (client > 0) {
		LogToGame("\"%L\" %s \"%s\" (value \"%s\")", client, verb, settings_name, settings_value); 
	} else {
		LogToGame("\"%s\" %s \"%s\" (value \"%s\")", "Server", verb, settings_name, settings_value); 
	}
}


log_player_event(client, String: verb[32], String: player_event[192], additional_player = 0, display_location = 0)
{
	if (client > 0) {
		if (display_location > 0) {
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			if ((additional_player > 0) && (client != additional_player)) {
				LogToGame("\"%L\" %s \"%s\" (position \"%d %d %d\") (player \"%L\")", client, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), additional_player); 
			} else {
				LogToGame("\"%L\" %s \"%s\" (position \"%d %d %d\")", client, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
			}
		} else {
			if ((additional_player > 0) && (client != additional_player)) {
				LogToGame("\"%L\" %s \"%s\" (player \"%L\")", client, verb, player_event, additional_player); 
			} else {
				LogToGame("\"%L\" %s \"%s\"", client, verb, player_event); 
			}
		}
	}
}


log_player_player_event(client, victim, String: verb[32], String: player_event[192],  display_location = 0)
{
	if ((client > 0) && (victim > 0)) {
		if (display_location > 0) {
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);

			new Float: victim_origin[3];
			GetClientAbsOrigin(victim, victim_origin);
			
			LogToGame("\"%L\" %s \"%s\" against \"%L\" (position \"%d %d %d\") (victim_position \"%d %d %d\")", client, verb, player_event, victim, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2])); 
		} else {
			LogToGame("\"%L\" %s \"%s\" against \"%L\"", client, verb, player_event, victim); 
		}
	}
}


log_team_event(String: team_name[32], String: team_action[192],  String: team_objective[192] = "")
{
	if (strcmp(team_name, "") != 0) {
		if (strcmp(team_objective, "") != 0) {
			LogToGame("Team \"%s\" triggered \"%s\" (object \"%s\")", team_name, team_action, team_objective);
		} else {
			LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action);
		}
	}
}


log_player_location(String: event[32], client, additional_player = 0)
{
	if (client > 0) {
		new Float: player_origin[3];
		GetClientAbsOrigin(client, player_origin);
		if ((additional_player > 0) && (client != additional_player)) {
			new Float: additional_player_origin[3];
			GetClientAbsOrigin(additional_player, additional_player_origin);
			LogToGame("\"%L\" located on \"%s\" (position \"%d %d %d\") against \"%L\" (victim_position \"%d %d %d\")", client, event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), additional_player, RoundFloat(additional_player_origin[0]), RoundFloat(additional_player_origin[1]), RoundFloat(additional_player_origin[2])); 
		} else {
			LogToGame("\"%L\" located on \"%s\" (position \"%d %d %d\")", client, event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
	}
}


find_player_team_slot(team_index) 
{
	if (team_index > -1) {
		ColorSlotArray[team_index] = -1;
		for (new i = 1; i <= MaxClients; i++) {
			new player_index = i;
			if ((IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
				new player_team_index = GetClientTeam(player_index);
				if (player_team_index == team_index) {
					ColorSlotArray[team_index] = player_index;
					break;
				}
			}
		}
	}
}


stock validate_team_colors() 
{
	for (new i = 0; (i < sizeof(ColorSlotArray)); i++) {
		new color_client = ColorSlotArray[i];
		if (color_client > 0) {
			if ((IsClientConnected(color_client)) && (IsClientInGame(color_client))) {
				new player_team_index = GetClientTeam(color_client);
				if (player_team_index != color_client) {
					find_player_team_slot(i);
				}
			}
		} else {
			if ((i == 2) || (i == 3)) {
				find_player_team_slot(i);
			}
		}
	}
}


public OnClientDisconnect(client)
{
	if (client > 0) {
		if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_DODS) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII) || (gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_ZPS)) {
			dump_player_data(client);
			reset_player_data(client);
		}
		if ((IsClientConnected(client)) && (IsClientInGame(client))) {
			if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
				new team_index = GetClientTeam(client);
				if (client == ColorSlotArray[team_index]) {
					ColorSlotArray[team_index] = -1;
				}
			}
		}
		
		if (gameme_plugin[mod_id] == MOD_CSS) {
			if (gameme_players[client][pspectator][stimer] != INVALID_HANDLE) {
				KillTimer(gameme_players[client][pspectator][stimer]);
				gameme_players[client][pspectator][stimer] = INVALID_HANDLE;
			}
			for (new j = 0; (j <= MAXPLAYERS); j++) {
				player_messages[j][client][supdated] = 1;
				strcopy(player_messages[j][client][smessage], 255, "");
			}
		}
	}
}


color_player(color_type, player_index, String: client_message[]) 
{
	new color_player_index = -1;
	decl String: client_name[192];
	GetClientName(player_index, client_name, 192);

	if ((strcmp(client_message, "") != 0) && (strcmp(client_name, "") != 0)) {
		if (color_type == 1) {
			decl String: search_client_name[192];
			Format(search_client_name, 192, "%s ", client_name);
			decl String: colored_player_name[192];
			if (gameme_plugin[mod_id] != MOD_HL2MP) {
				Format(colored_player_name, 192, "\x03%s\x01 ", client_name);
			} else {
				if (hl2mp_data[teamplay_enabled]) {
					Format(colored_player_name, 192, "\x03%s\x01 ", client_name);
				} else {
					Format(colored_player_name, 192, "\x04%s\x01 ", client_name);
				}
			}
			if (ReplaceString(client_message, 192, search_client_name, colored_player_name) > 0) {
				return player_index;
			}
		} else {
			decl String: search_client_name[192];
			Format(search_client_name, 192, " %s ", client_name);
			decl String: colored_player_name[192];
			Format(colored_player_name, 192, " \x04%s\x01 ", client_name);
			ReplaceString(client_message, 192, search_client_name, colored_player_name);
		}
	}
	return color_player_index;
}


public native_color_all_players(Handle: plugin, numParams)
{
	new color_index = -1;

	if (numParams < 1) {
		return color_index;
	}

	new message_length;
	GetNativeStringLength(1, message_length);
	if (message_length <= 0) {
		return color_index;
	}
 
	new String: message[message_length + 1];
	GetNativeString(1, message, message_length + 1);
   
	color_index = color_all_players(message);
	SetNativeString(1, message, strlen(message) + 1);

	return color_index;
}


color_all_players(String: message[]) 
{
	new color_index = -1;
	if (PlayerColorArray != INVALID_HANDLE) {
		if (strcmp(message, "") != 0) {
			ClearArray(PlayerColorArray);

			new lowest_matching_pos = 192;
			new lowest_matching_pos_client = -1;

			for (new i = 1; i <= MaxClients; i++) {
				new client = i;
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					decl String: client_name[32];
					GetClientName(client, client_name, 32);

					if (strcmp(client_name, "") != 0) {
						new message_pos = StrContains(message, client_name);
						if (message_pos > -1) {
							if (lowest_matching_pos > message_pos) {
								lowest_matching_pos = message_pos;
								lowest_matching_pos_client = client;
							}
							new TempPlayerColorArray[1];
							TempPlayerColorArray[0] = client;
							PushArrayArray(PlayerColorArray, TempPlayerColorArray);
						}
					}
				}
			}
			new size = GetArraySize(PlayerColorArray);
			for (new i = 0; i < size; i++) {
				new temp_player_array[1];
				GetArrayArray(PlayerColorArray, i, temp_player_array);
				new temp_client = temp_player_array[0];
				if (temp_client == lowest_matching_pos_client) {
					new temp_color_index = color_player(1, temp_client, message);
					color_index = temp_color_index;
				} else {
					color_player(0, temp_client, message);
				}
			}
			ClearArray(PlayerColorArray);
		}
	}
	
	return color_index;
}


stock get_team_index(String: team_name[])
{
	new loop_break = 0;
	new index = 0;
	while ((loop_break == 0) && (index < sizeof(team_list))) {
   	    if (strcmp(team_name, team_list[index], true) == 0) {
       		loop_break++;
        }
   	    index++;
	}
	if (loop_break == 0) {
		return -1;
	} else {
		return index - 1;
	}
}


remove_color_entities(String: message[192])
{
	ReplaceString(message, 192, "x05", "");
	ReplaceString(message, 192, "x04", "");
	ReplaceString(message, 192, "x01", "");
}


color_entities(String: message[192])
{
	ReplaceString(message, 192, "x05", "\x05");
	ReplaceString(message, 192, "x04", "\x04");
	ReplaceString(message, 192, "x01", "\x01");
}


color_team_entities(String: message[192])
{
	if (gameme_plugin[mod_id] == MOD_CSS) {
		if (strcmp(message, "") != 0) {
			if (ColorSlotArray[2] > -1) {
				if (ReplaceString(message, 192, "TERRORIST", "\x03TERRORIST\x01") > 0) {
					return ColorSlotArray[2];
				}
			}
			if (ColorSlotArray[3] > -1) {
				if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0) {
					return ColorSlotArray[3];
				}
			}
		}
	} else if (gameme_plugin[mod_id] == MOD_HL2MP) {
		if ((hl2mp_data[teamplay_enabled]) && (strcmp(message, "") != 0)) {
			if (ColorSlotArray[2] > -1) {
				if (ReplaceString(message, 192, "Rebels", "\x03Rebels\x01") > 0) {
					return ColorSlotArray[2];
				}
			}
			if (ColorSlotArray[3] > -1) {
				if (ReplaceString(message, 192, "Combine", "\x03Combine\x01") > 0) {
					return ColorSlotArray[3];
				}
			}
		}
	} else if (gameme_plugin[mod_id] == MOD_TF2) {
		if (strcmp(message, "") != 0) {
			if (ColorSlotArray[2] > -1) {
				if (ReplaceString(message, 192, "Red", "\x03Red\x01") > 0) {
					return ColorSlotArray[2];
				}
			}
			if (ColorSlotArray[3] > -1) {
				if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0) {
					return ColorSlotArray[3];
				}
			}
		}
	} else if ((gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
		if (strcmp(message, "") != 0) {
			if (ColorSlotArray[2] > -1) {
				if (ReplaceString(message, 192, "Survivors", "\x03Survivors\x01") > 0) {
					return ColorSlotArray[2];
				}
			}
			if (ColorSlotArray[3] > -1) {
				if (ReplaceString(message, 192, "Infected", "\x03Infected\x01") > 0) {
					return ColorSlotArray[3];
				}
			}
		}
	}

	return -1;
}


public native_display_menu(Handle: plugin, numParams)
{
	if (numParams < 4) {
		return;
	}

	new client = GetNativeCell(1);
	new time = GetNativeCell(2);

	new message_length;
	GetNativeStringLength(3, message_length);
	if (message_length <= 0) {
		return;
	}
	new String: message[message_length + 1];
	GetNativeString(3, message, message_length + 1);

	new handler = GetNativeCell(4);
	display_menu(client, time, message, handler);

	return;
}


display_menu(player_index, time, String: full_message[], need_handler = 0)
{
	ReplaceString(full_message, 1024, "\\n", "\10");
	if (need_handler == 0) {
		InternalShowMenu(player_index, full_message, time);
	} else {
		InternalShowMenu(player_index, full_message, time, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), InternalMenuHandler);
	}
}


public InternalMenuHandler(Handle:menu, MenuAction: action, param1, param2)
{
	new client = param1;
	if ((IsClientConnected(client)) && (IsClientInGame(client))) {
		if (action == MenuAction_Select) {
			decl String: player_event[192];
			IntToString(param2, player_event, 192);
			log_player_event(client, "selected", player_event);
		} else if (action == MenuAction_Cancel) {
			new String: player_event[192] = "cancel";
			log_player_event(client, "selected", player_event);
		}
	}
}


get_param(index, argument_count) 
{
	decl String: param[128];
	if (index <= argument_count) {
		GetCmdArg(index, param, 128);
		return StringToInt(param);
	}
	return -1;
}


get_query_id()
{
	global_query_id++;
	if (global_query_id > 65535) {
		global_query_id = 1;
	}
	return global_query_id;
}


find_callback(query_id)
{
	new index = -1;
	new size = GetArraySize(QueryCallbackArray);
	
	for (new i = 0; i < size; i++) {
		decl data[callback_data];
		GetArrayArray(QueryCallbackArray, i, data, sizeof(data));
		if ((data[callback_data_id] == query_id) && (data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
			index = i;
			break;
		}
	}
	return index;
}


public native_query_gameme_stats(Handle: plugin, numParams)
{
	if (numParams < 4) {
		return;
	}
	decl String: cb_type[255];
	GetNativeString(1, cb_type, 255);
	new cb_client = GetNativeCell(2);
	new Function: cb_function = GetNativeCell(3);
	new cb_payload = GetNativeCell(4);
	
	new cb_limit = 1;
	if (numParams >= 5) {
		cb_limit = GetNativeCell(5);
	}
	
	if (cb_client < 1) {
		new queryid = get_query_id();

		decl data[callback_data];
		data[callback_data_id] = queryid;
		data[callback_data_time] = GetGameTime();
		data[callback_data_client] = cb_client;
		data[callback_data_plugin] = plugin;
		data[callback_data_function] = cb_function;
		data[callback_data_payload] = cb_payload;
		data[callback_data_limit] = cb_limit;
		if (QueryCallbackArray != INVALID_HANDLE) {
			PushArrayArray(QueryCallbackArray, data);
		}
			
		new String: query_payload[32];
		IntToString(queryid, query_payload, 32);
		log_player_settings(cb_client, "requested", cb_type, query_payload);
	} else {
		if (IsClientConnected(cb_client)) {
			new userid = GetClientUserId(cb_client);
			if (userid > 0) {
				new queryid = get_query_id();

				decl data[callback_data];
				data[callback_data_id] = queryid;
				data[callback_data_time] = GetGameTime();
				data[callback_data_client] = cb_client;
				data[callback_data_plugin] = plugin;
				data[callback_data_function] = cb_function;
				data[callback_data_payload] = cb_payload;
				data[callback_data_limit] = cb_limit;

				if (QueryCallbackArray != INVALID_HANDLE) {
					PushArrayArray(QueryCallbackArray, data);
			
					new String: query_payload[32];
					IntToString(queryid, query_payload, 32);
					log_player_settings(cb_client, "requested", cb_type, query_payload);
				}
			}
		}
	}
}


public Action: gameme_raw_message(args)
{

	if (args < 1) {
		PrintToServer("Usage: gameme_raw_message <type><array> - retrieve internal gameME Stats data");
		return Plugin_Handled;
	}
	
	new argument_count = GetCmdArgs();
	new type = get_param(1, argument_count);
	switch (type) {

		case RAW_MESSAGE_CALLBACK_PLAYER, RAW_MESSAGE_RANK, RAW_MESSAGE_PLACE, RAW_MESSAGE_KDEATH, RAW_MESSAGE_SESSION_DATA: {
			if (argument_count >= 42) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);		
				new client = GetClientOfUserId(userid);		
				if (client > 0) {

					// total values
					new rank                    = get_param(4, argument_count);		
					new players                 = get_param(5, argument_count);		
					new skill                   = get_param(6, argument_count);		
					new kills                   = get_param(7, argument_count);		
					new deaths                  = get_param(8, argument_count);		

					decl String: kpd_param[16];
					GetCmdArg(9, kpd_param, 16);					
					new Float: kpd = StringToFloat(kpd_param);

					new suicides                = get_param(10, argument_count);		
					new headshots               = get_param(11, argument_count);		

					decl String: hpk_param[16];
					GetCmdArg(12, hpk_param, 16);					
					new Float: hpk = StringToFloat(hpk_param);

					decl String: acc_param[16];
					GetCmdArg(13, acc_param, 16);					
					new Float: accuracy = StringToFloat(acc_param);

					new connection_time         = get_param(14, argument_count);		
					new kill_assists            = get_param(15, argument_count);		
					new kills_assisted          = get_param(16, argument_count);		
					new points_healed           = get_param(17, argument_count);		
					new flags_captured          = get_param(18, argument_count);

					// session values
					new session_pos_change      = get_param(19, argument_count);
					new session_skill_change    = get_param(20, argument_count);
					new session_kills           = get_param(21, argument_count);
					new session_deaths          = get_param(22, argument_count);

					decl String: session_kpd_param[16];
					GetCmdArg(23, session_kpd_param, 16);					
					new Float: session_kpd = StringToFloat(session_kpd_param);

					new session_suicides        = get_param(24, argument_count);
					new session_headshots       = get_param(25, argument_count);

					decl String: session_hpk_param[16];
					GetCmdArg(26, session_hpk_param, 16);					
					new Float: session_hpk = StringToFloat(session_hpk_param);

					decl String: session_acc_param[16];
					GetCmdArg(27, session_acc_param, 16);					
					new Float: session_accuracy = StringToFloat(session_acc_param);

					new session_time            = get_param(28, argument_count);
					new session_kill_assists    = get_param(29, argument_count);		
					new session_kills_assisted  = get_param(30, argument_count);		
					new session_points_healed   = get_param(31, argument_count);		
					new session_flags_captured  = get_param(32, argument_count);

					decl String: session_fav_weapon[32];
					GetCmdArg(33, session_fav_weapon, 32);					
					if (StrEqual(session_fav_weapon, "-")) {
						session_fav_weapon = "No Fav Weapon";
					}

					// global values
					new global_rank             = get_param(34, argument_count);
					new global_players          = get_param(35, argument_count);
					new global_kills            = get_param(36, argument_count);
					new global_deaths           = get_param(37, argument_count);

					decl String: global_kpd_param[16];
					GetCmdArg(38, global_kpd_param, 16);					
					new Float: global_kpd = StringToFloat(global_kpd_param);

					new global_headshots        = get_param(39, argument_count);

					decl String: global_hpk_param[16];
					GetCmdArg(40, global_hpk_param, 16);					
					new Float: global_hpk = StringToFloat(global_hpk_param);

					// country
					decl String: country_code[16];
					GetCmdArg(41, country_code, 16);					

					
					new total_cell_values[12];
					total_cell_values[0]  = rank;
					total_cell_values[1]  = players;
					total_cell_values[2]  = skill;
					total_cell_values[3]  = kills;
					total_cell_values[4]  = deaths;
					total_cell_values[5]  = suicides;
					total_cell_values[6]  = headshots;
					total_cell_values[7]  = connection_time;
					total_cell_values[8]  = kill_assists;
					total_cell_values[9]  = kills_assisted;
					total_cell_values[10] = points_healed;
					total_cell_values[11] = flags_captured;

					new Float: total_float_values[3];
					total_float_values[0] = kpd;
					total_float_values[1] = hpk;
					total_float_values[2] = accuracy;


					new session_cell_values[11];
					session_cell_values[0]  = session_pos_change;
					session_cell_values[1]  = session_skill_change;
					session_cell_values[2]  = session_kills;
					session_cell_values[3]  = session_deaths;
					session_cell_values[4]  = session_suicides;
					session_cell_values[5]  = session_headshots;
					session_cell_values[6]  = session_time;
					session_cell_values[7]  = session_kill_assists;
					session_cell_values[8]  = session_kills_assisted;
					session_cell_values[9]  = session_points_healed;
					session_cell_values[10] = session_flags_captured;

					new Float: session_float_values[3];
					session_float_values[0] = session_kpd;
					session_float_values[1] = session_hpk;
					session_float_values[2] = session_accuracy;


					new global_cell_values[5];
					global_cell_values[0] = global_rank;
					global_cell_values[1] = global_players;
					global_cell_values[2] = global_kills;
					global_cell_values[3] = global_deaths;
					global_cell_values[4] = global_headshots;

					new Float: global_float_values[2];
					global_float_values[0] = global_kpd;
					global_float_values[1] = global_hpk;
					
					
					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_PLAYER) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_PLAYER);
									
									Call_PushCell(data[callback_data_payload]);
									Call_PushCell(client);

									Call_PushArray(total_cell_values, 12);
									Call_PushArray(total_float_values, 3);
	
									Call_PushArray(session_cell_values, 11);
									Call_PushArray(session_float_values, 3);
									Call_PushString(session_fav_weapon);

									Call_PushArray(global_cell_values, 5);
									Call_PushArray(global_float_values, 2);
						
									Call_PushString(country_code);
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {
						switch (type) {
							case RAW_MESSAGE_RANK: {
								Call_StartForward(gameMEStatsRankForward);
								Call_PushCell(RAW_MESSAGE_RANK);
							}
							case RAW_MESSAGE_PLACE: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_PLACE);
							}
							case RAW_MESSAGE_KDEATH: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_KDEATH);
							}
							case RAW_MESSAGE_SESSION_DATA: {
								Call_StartForward(gameMEStatsPublicCommandForward);
								Call_PushCell(RAW_MESSAGE_SESSION_DATA);
							}
						}
						Call_PushCell(client);
						Call_PushString(message_prefix);

						Call_PushArray(total_cell_values, 12);
						Call_PushArray(total_float_values, 3);

						Call_PushArray(session_cell_values, 11);
						Call_PushArray(session_float_values, 3);
						Call_PushString(session_fav_weapon);

						Call_PushArray(global_cell_values, 5);
						Call_PushArray(global_float_values, 2);

						Call_PushString(country_code);
						Call_Finish(_: result);
					}
				}
				
			}
		}
		case RAW_MESSAGE_CALLBACK_TOP10, RAW_MESSAGE_TOP10: {
			if (argument_count >= 4) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);	
				if (((userid > 0) && (type == RAW_MESSAGE_TOP10)) ||
   					((userid == -1) && (type == RAW_MESSAGE_CALLBACK_TOP10))) {

   					new client = GetClientOfUserId(userid);		
   					if ((client < 1) && (type == RAW_MESSAGE_TOP10)) {
						return Plugin_Handled;
   					}

					new top10_cell_values[20];
					new Float: top10_float_values[20];

					new String: player1[32];					
					new String: player2[32];					
					new String: player3[32];					
					new String: player4[32];					
					new String: player5[32];					
					new String: player6[32];					
					new String: player7[32];					
					new String: player8[32];					
					new String: player9[32];					
					new String: player10[32];					
					
					if (argument_count == 4) {
						top10_cell_values[0] = -1;
					} else {
						new count = 0;
						new array_cell_pos = 0;
						new array_float_pos = 0;
						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 3) <= argument_count)) {
								count++;
								new rank = count;
								new skill = get_param(i, argument_count);

								decl String: name[32];
								GetCmdArg((i + 1), name, 32);

								decl String: kpd_param[16];
								GetCmdArg((i + 2), kpd_param, 16);					
								new Float: kpd = StringToFloat(kpd_param);

								decl String: hpk_param[16];
								GetCmdArg((i + 3), hpk_param, 16);					
								new Float: hpk = StringToFloat(hpk_param);
								
								top10_cell_values[array_cell_pos] = rank;
								array_cell_pos++;
								top10_cell_values[array_cell_pos] = skill;
								array_cell_pos++;

								top10_float_values[array_float_pos] = kpd;
								array_float_pos++;
								top10_float_values[array_float_pos] = hpk;
								array_float_pos++;
								
								switch (count) {
									case 1:
										strcopy(player1, 32, name);
									case 2:
										strcopy(player2, 32, name);
									case 3:
										strcopy(player3, 32, name);
									case 4:
										strcopy(player4, 32, name);
									case 5:
										strcopy(player5, 32, name);
									case 6:
										strcopy(player6, 32, name);
									case 7:
										strcopy(player7, 32, name);
									case 8:
										strcopy(player8, 32, name);
									case 9: 
										strcopy(player9, 32, name);
									case 10:
										strcopy(player10, 32, name);
								}
								i = i + 3;
							}
						}
					}

					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_TOP10) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_TOP10);
									Call_PushCell(data[callback_data_payload]);

									Call_PushArray(top10_cell_values, 20);
									Call_PushArray(top10_float_values, 20);

									Call_PushString(player1);
									Call_PushString(player2);
									Call_PushString(player3);
									Call_PushString(player4);
									Call_PushString(player5);
									Call_PushString(player6);
									Call_PushString(player7);
									Call_PushString(player8);
									Call_PushString(player9);
									Call_PushString(player10);
									
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {

						Call_StartForward(gameMEStatsTop10Forward);
						Call_PushCell(RAW_MESSAGE_TOP10);
						Call_PushCell(client);
						Call_PushString(message_prefix);

						Call_PushArray(top10_cell_values, 20);
						Call_PushArray(top10_float_values, 20);

						Call_PushString(player1);
						Call_PushString(player2);
						Call_PushString(player3);
						Call_PushString(player4);
						Call_PushString(player5);
						Call_PushString(player6);
						Call_PushString(player7);
						Call_PushString(player8);
						Call_PushString(player9);
						Call_PushString(player10);

						Call_Finish(_:result);
					}
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_NEXT, RAW_MESSAGE_NEXT: {
			if (argument_count >= 4) {
				new query_id = get_param(2, argument_count);		
				new userid = get_param(3, argument_count);	
				new client = GetClientOfUserId(userid);		
				if (client > 0) {
					new next_cell_values[20];
					new Float: next_float_values[20];

					new String: player1[32];					
					new String: player2[32];					
					new String: player3[32];					
					new String: player4[32];					
					new String: player5[32];					
					new String: player6[32];					
					new String: player7[32];					
					new String: player8[32];					
					new String: player9[32];					
					new String: player10[32];					
					
					if (argument_count == 4) {
						next_cell_values[0] = -1;
					} else {
						new count = 0;
						new array_cell_pos = 0;
						new array_float_pos = 0;
						for (new i = 4; (i <= argument_count); i++) {
							if (((i + 4) <= argument_count)) {
								count++;
								
								new rank   = get_param(i, argument_count);
								new skill = get_param((i + 1), argument_count);

								decl String: name[32];
								GetCmdArg((i + 2), name, 32);

								decl String: kpd_param[16];
								GetCmdArg((i + 3), kpd_param, 16);					
								new Float: kpd = StringToFloat(kpd_param);

								decl String: hpk_param[16];
								GetCmdArg((i + 4), hpk_param, 16);					
								new Float: hpk = StringToFloat(hpk_param);
								
								next_cell_values[array_cell_pos] = rank;
								array_cell_pos++;
								next_cell_values[array_cell_pos] = skill;
								array_cell_pos++;

								next_float_values[array_float_pos] = kpd;
								array_float_pos++;
								next_float_values[array_float_pos] = hpk;
								array_float_pos++;
								
								switch (count) {
									case 1:
										strcopy(player1, 32, name);
									case 2:
										strcopy(player2, 32, name);
									case 3:
										strcopy(player3, 32, name);
									case 4:
										strcopy(player4, 32, name);
									case 5:
										strcopy(player5, 32, name);
									case 6:
										strcopy(player6, 32, name);
									case 7:
										strcopy(player7, 32, name);
									case 8:
										strcopy(player8, 32, name);
									case 9: 
										strcopy(player9, 32, name);
									case 10:
										strcopy(player10, 32, name);
								}
								i = i + 4;
							}
						}
					}

					decl Action: result;
					if (type == RAW_MESSAGE_CALLBACK_NEXT) {
						if (query_id > 0) {
							new cb_array_index = find_callback(query_id);
							if (cb_array_index >= 0) {
								decl data[callback_data];
								GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
								if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
									Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
									Call_PushCell(RAW_MESSAGE_CALLBACK_NEXT);
									Call_PushCell(data[callback_data_payload]);
									Call_PushCell(client);

									Call_PushArray(next_cell_values, 20);
									Call_PushArray(next_float_values, 20);

									Call_PushString(player1);
									Call_PushString(player2);
									Call_PushString(player3);
									Call_PushString(player4);
									Call_PushString(player5);
									Call_PushString(player6);
									Call_PushString(player7);
									Call_PushString(player8);
									Call_PushString(player9);
									Call_PushString(player10);
									
									Call_Finish(_:result);
									
									if (data[callback_data_limit] == 1) {
										RemoveFromArray(QueryCallbackArray, cb_array_index); 
									}
								}
							}
						}
					} else {

						Call_StartForward(gameMEStatsNextForward);
						Call_PushCell(RAW_MESSAGE_NEXT);
						Call_PushCell(client);
						Call_PushString(message_prefix);

						Call_PushArray(next_cell_values, 20);
						Call_PushArray(next_float_values, 20);

						Call_PushString(player1);
						Call_PushString(player2);
						Call_PushString(player3);
						Call_PushString(player4);
						Call_PushString(player5);
						Call_PushString(player6);
						Call_PushString(player7);
						Call_PushString(player8);
						Call_PushString(player9);
						Call_PushString(player10);

						Call_Finish(_:result);
					}
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_INT_CLOSE: {
			if (argument_count >= 2) {
				new query_id = get_param(2, argument_count);
				new cb_array_index = find_callback(query_id);
				if (cb_array_index >= 0) {
					RemoveFromArray(QueryCallbackArray, cb_array_index); 
				}
			}
		}
		case RAW_MESSAGE_CALLBACK_INT_SPECTATOR: {
			if (argument_count >= 5) {
				new query_id = get_param(2, argument_count);		

				new caller[MAXPLAYERS + 1] = {-1, ...};
				decl String: caller_id[512];
				GetCmdArg(3, caller_id, 512);
				if (StrContains(caller_id, ",") > -1) {
					decl String: CallerRecipients[MaxClients][16];
					new recipient_count = ExplodeString(caller_id, ",", CallerRecipients, MaxClients, 16);
					for (new i = 0; (i < recipient_count); i++) {
						caller[i] = GetClientOfUserId(StringToInt(CallerRecipients[i]));
					}
				} else {
					caller[0] = GetClientOfUserId(StringToInt(caller_id));
				}

				new target[MAXPLAYERS + 1] = {-1, ...};
				decl String: target_id[512];
				GetCmdArg(4, target_id, 512);
				if (StrContains(target_id, ",") > -1) {
					decl String: TargetRecipients[MaxClients][16];
					new recipient_count = ExplodeString(target_id, ",", TargetRecipients, MaxClients, 16);
					for (new i = 0; (i < recipient_count); i++) {
						target[i] = GetClientOfUserId(StringToInt(TargetRecipients[i]));
					}
				} else {
					target[0] = GetClientOfUserId(StringToInt(target_id));
				}


				if ((caller[0] > -1) && (target[0] > -1) && (query_id > 0)) {
					decl String: message[1024];
					GetCmdArg(5, message, 1024);	
					
					new cb_array_index = find_callback(query_id);
					if (cb_array_index >= 0) {
						decl data[callback_data];
						GetArrayArray(QueryCallbackArray, cb_array_index, data, sizeof(data));
						if ((data[callback_data_plugin] != INVALID_HANDLE) && (data[callback_data_function] != INVALID_FUNCTION)) {
							decl Action: result;
							Call_StartFunction(data[callback_data_plugin], data[callback_data_function]);
							Call_PushCell(RAW_MESSAGE_CALLBACK_INT_SPECTATOR);
							Call_PushCell(data[callback_data_payload]);
							Call_PushArray(caller, MAXPLAYERS + 1);
							Call_PushArray(target, MAXPLAYERS + 1);
							Call_PushString(message_prefix);
							Call_PushString(message);
							Call_Finish(_:result);

							if (data[callback_data_limit] == 1) {
								RemoveFromArray(QueryCallbackArray, cb_array_index); 
							}
						}
					}

				}
			}
		}

	}

	return Plugin_Handled;
}


public Action: gameme_psay(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new is_colored = 0;
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		is_colored = 1;
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	if (ignore_param == 1) {
 		copy_start_length += strlen(colored_param) + 1;
 	}
	copy_start_length += 1;

	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}
	
	if (IsStackEmpty(message_recipients) == false) {
		new color_index = -1;
		decl String: display_message[192];
		if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
			if (is_colored > 0) {
				new player_color_index = color_all_players(client_message);
				if (player_color_index > -1) {
					color_index = player_color_index;
				} else {
					validate_team_colors();
					color_index = color_team_entities(client_message);
				}
				color_entities(client_message);
			}
				
			if (strcmp(message_prefix, "") == 0) {
				Format(display_message, 192, "\x01%s", client_message);
			} else {
				Format(display_message, 192, "\x04%s\x01 %s", message_prefix, client_message);
			}
			
			new bool: setupColorForRecipients = false;
			if (color_index == -1) {
				setupColorForRecipients = true;
			}
			
			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					if (setupColorForRecipients == true) {
						color_index = player_index;
					}
					new Handle:hBf;
					hBf = StartMessageOne("SayText2", player_index);
					if (hBf != INVALID_HANDLE) {
						BfWriteByte(hBf, color_index); 
						BfWriteByte(hBf, 0); 
						BfWriteString(hBf, display_message);
						EndMessage();
					}
				}
			}
		} else {
			if (strcmp(message_prefix, "") == 0) {
				Format(display_message, 192, "%s", client_message);
			} else {
				Format(display_message, 192, "%s %s", message_prefix, client_message);
			}
				
			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					PrintToChat(player_index, display_message);
				}
			}
		}
	}
	return Plugin_Handled;
}


public Action: gameme_psay2(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_psay2 <userid><colored><message> - sends green colored private message");
		return Plugin_Handled;
	}
	
	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	if (ignore_param == 1) {
 		copy_start_length += strlen(colored_param) + 1;
 	}
	copy_start_length += 1;

	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}

	if (IsStackEmpty(message_recipients) == false) {
		decl String:display_message[192];
		if ((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_TF2) || (gameme_plugin[mod_id] == MOD_L4D) || (gameme_plugin[mod_id] == MOD_L4DII)) {
			remove_color_entities(client_message);
				
			if (strcmp(message_prefix, "") == 0) {
				Format(display_message, 192, "\x04%s", client_message);
			} else {
				Format(display_message, 192, "\x04%s %s", message_prefix, client_message);
			}

			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					PrintToChat(player_index, display_message);
				}
			}
		} else {
			if (strcmp(message_prefix, "") == 0) {
				Format(display_message, 192, "%s", client_message);
			} else {
				Format(display_message, 192, "%s %s", message_prefix, client_message);
			}

			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					PrintToChat(player_index, display_message);
				}
			}
		}	
	}
	return Plugin_Handled;
}


public Action: gameme_csay(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_csay <message> - display center message");
		return Plugin_Handled;
	}

	new String: display_message[192];
	GetCmdArg(1, display_message, 192);

	if (strcmp(display_message, "") != 0) {
		PrintCenterTextAll(display_message);
	}
		
	return Plugin_Handled;
}


public Action: gameme_msay(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		return Plugin_Handled;
	}
	
	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	decl String: handler_param[32];
	GetCmdArg(3, handler_param, 32);

	new need_handler = 0;
	if ((strcmp(handler_param, "1") == 0) || (strcmp(handler_param, "0") == 0)) {
		need_handler = 1;
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3;
	if (need_handler == 1) {
		copy_start_length += 2;
	}
	copy_start_length += 1;

	new String: client_message[1024];
	strcopy(client_message, 1024, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}

	new time = StringToInt(display_time);
	if (time <= 0) {
		time = 10;
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			if (strcmp(client_message, "") != 0) {
				display_menu(player_index, time, client_message, need_handler);			
			}
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_tsay(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3;
	copy_start_length += 1;

	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0)) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			new Handle:values = CreateKeyValues("msg");
			KvSetString(values, "title", client_message);
			KvSetNum(values, "level", 1); 
			KvSetString(values, "time", display_time); 
			CreateDialog(player_index, values, DialogType_Msg);
			CloseHandle(values);
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_hint(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] == MOD_HL2MP) {
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	copy_start_length++;
	
	new String: client_message[192];
	strcopy(client_message, 192, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}

	if (IsStackEmpty(message_recipients) == false) {
		if (strcmp(client_message, "") != 0) {
			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					PrintHintText(player_index, client_message);
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_khint(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_khint <userid><message> - send khint message");
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(client_id) + 3;
	copy_start_length++;
	
	new String: client_message[255];
	strcopy(client_message, 255, argument_string[copy_start_length]);
	while (client_message[strlen(client_message)-1] == 34) {
		client_message[strlen(client_message)-1] = 0;
	}
	ReplaceString(client_message, 255, "\\n", "\10");

	if (IsStackEmpty(message_recipients) == false) {
		if (strcmp(client_message, "") != 0) {
			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					new Handle: hBf;
					hBf = StartMessageOne("KeyHintText", player_index);
					if (hBf != INVALID_HANDLE) {
						BfWriteByte(hBf, 1); 
						BfWriteString(hBf, client_message);
						EndMessage();
					}
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_browse(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	decl String: client_id[512];
	GetCmdArg(1, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	new String: client_url[192];
	GetCmdArg(2, client_url, 192);

	if (IsStackEmpty(message_recipients) == false) {
		if (strcmp(client_url, "") != 0) {
			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					ShowMOTDPanel(player_index, "gameME", client_url, MOTDPANEL_TYPE_URL);
				}
			}
		}
	}		
			
	return Plugin_Handled;
}


public Action: gameme_swap(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	if (gameme_plugin[mod_id] != MOD_CSS) {
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			swap_player(player_index);
		}
	}
	return Plugin_Handled;
}


public Action: gameme_redirect(args)
{
	if (args < 3) {
		PrintToServer("Usage: gameme_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[512];
	GetCmdArg(2, client_id, 512);
	if (StrContains(client_id, ",") > -1) {
		decl String: MessageRecipients[MaxClients][16];
		new recipient_count = ExplodeString(client_id, ",", MessageRecipients, MaxClients, 16);
		for (new i = 0; (i < recipient_count); i++) {
			PushStackCell(message_recipients, StringToInt(MessageRecipients[i]));
		}
	} else {
		PushStackCell(message_recipients, StringToInt(client_id));
	}

	new String: server_address[192];
	GetCmdArg(3, server_address, 192);

	decl String: argument_string[1024];
	GetCmdArgString(argument_string, 1024);
	new copy_start_length = strlen(display_time) + 3 + strlen(client_id) + 3 + strlen(server_address) + 3;
	copy_start_length++;

	new String: redirect_reason[192];
	strcopy(redirect_reason, 192, argument_string[copy_start_length]);
	while (redirect_reason[strlen(redirect_reason)-1] == 34) {
		redirect_reason[strlen(redirect_reason)-1] = 0;
	}

	if (IsStackEmpty(message_recipients) == false) {
		if (strcmp(server_address, "") != 0) {

			while (IsStackEmpty(message_recipients) == false) {
				new recipient_client = -1;
				PopStackCell(message_recipients, recipient_client);

				new player_index = GetClientOfUserId(recipient_client);
				if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					new Handle:top_values = CreateKeyValues("msg");
					KvSetString(top_values, "title", redirect_reason);
					KvSetNum(top_values, "level", 1); 
					KvSetString(top_values, "time", display_time); 
					CreateDialog(player_index, top_values, DialogType_Msg);
					CloseHandle(top_values);
			
					new Float: display_time_float;
					display_time_float = StringToFloat(display_time);
					DisplayAskConnectBox(player_index, display_time_float, server_address);
				}
			}
		}	
	}		
		
	return Plugin_Handled;
}


public Action: gameme_player_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_player_action <client><action> - trigger player action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: player_action[192];
	GetCmdArg(2, player_action, 192);

	new client = StringToInt(client_id);
	if (client > 0) {
		log_player_event(client, "triggered", player_action);
	}

	return Plugin_Handled;
}


public Action: gameme_team_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: gameme_team_action <team_name><action>(objective) - trigger team action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: team_name[32];
	GetCmdArg(1, team_name, 32);

	decl String: team_action[192];
	GetCmdArg(2, team_action, 192);
	
	if (args > 2) {
		decl String: team_objective[192];
		GetCmdArg(3, team_objective, 192);
		log_team_event(team_name, team_action, team_objective);
	} else {
		log_team_event(team_name, team_action);
	}

	return Plugin_Handled;
}


public Action: gameme_world_action(args)
{
	if (args < 1) {
		PrintToServer("Usage: gameme_world_action <action> - trigger world action to be handled from gameME");
		return Plugin_Handled;
	}

	decl String: world_action[192];
	GetCmdArg(1, world_action, 192);

	LogToGame("World triggered \"%s\"", world_action); 

	return Plugin_Handled;
}


is_command_blocked(String: command[])
{
	new command_blocked = 0;
	new command_index = 0;
	while ((command_blocked == 0) && (command_index < sizeof(blocked_commands))) {
		if (strcmp(command, blocked_commands[command_index]) == 0) {
			command_blocked++;
		}
		command_index++;
	}
	if (command_blocked > 0) {
		return 1;
	}
	return 0;
}


public Action: gameme_block_commands(client, args)
{
	if (client) {
		if (client == 0) {
			return Plugin_Continue;
		}
		new block_chat_commands = GetConVarInt(gameme_block_chat_commands);
		
		decl String: user_command[192];
		GetCmdArgString(user_command, 192);

		decl String: origin_command[192];
		new start_index = 0;
		new command_length = strlen(user_command);
		if (command_length > 0) {
			if (user_command[0] == 34)	{
				start_index = 1;
				if (user_command[command_length - 1] == 34)	{
					user_command[command_length - 1] = 0;
				}
			}
			strcopy(origin_command, 192, user_command[start_index]);
			
			if (user_command[start_index] == 47)	{
				start_index++;
			}
		}

		new String: command_type[32] = "say";
		if (gameme_plugin[mod_id] == MOD_INSMOD) {
			decl String: say_type[1];
			strcopy(say_type, 2, user_command[start_index]);
			if (strcmp(say_type, "1") == 0) {
				command_type = "say";
			} else if (strcmp(say_type, "2") == 0) {
				command_type = "say_team";
			}
			start_index += 4;
		}

		if (command_length > 0) {
			if (block_chat_commands > 0) {
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
				
					if (gameme_plugin[mod_id] == MOD_INSMOD) {
						log_player_event(client, command_type, user_command[start_index]);
					}

					new command_blocked = is_command_blocked(user_command[start_index]);
					if (command_blocked > 0) {
						if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
							(strcmp("hlx", user_command[start_index]) == 0) ||
							(strcmp("hlstatsx", user_command[start_index]) == 0)) {
							DisplayMenu(gameMEMenuMain, client, MENU_TIME_FOREVER);
						}
						if ((strcmp("gameme_menu", user_command[start_index]) == 0) ||
							(strcmp("gameme", user_command[start_index]) == 0)) {
							DisplayMenu(gameMEMenuMain, client, MENU_TIME_FOREVER);
						}
						if (gameme_plugin[mod_id] != MOD_INSMOD) {
							log_player_event(client, command_type, origin_command);
						}
						return Plugin_Stop;
					}
				}
			} else {
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
						(strcmp("hlx", user_command[start_index]) == 0) ||
						(strcmp("hlstatsx", user_command[start_index]) == 0)) {
						DisplayMenu(gameMEMenuMain, client, MENU_TIME_FOREVER);
					}
					if ((strcmp("gameme_menu", user_command[start_index]) == 0) ||
						(strcmp("gameme", user_command[start_index]) == 0)) {
						DisplayMenu(gameMEMenuMain, client, MENU_TIME_FOREVER);
					}
					
					if (gameme_plugin[mod_id] == MOD_INSMOD) {
						log_player_event(client, command_type, user_command[start_index]);
					}
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyDeath(Handle: event, const String: name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));

	if (attacker > 0) {
		new headshot = 0;
		headshot = GetEventBool(event, "headshot");

		if (((gameme_plugin[mod_id] == MOD_CSS) || (gameme_plugin[mod_id] == MOD_CSP)) && (victim > 0)) {
			if (headshot == 1) {
				new player_team_index = GetClientTeam(attacker);
				new victim_team_index = GetClientTeam(victim);
				if (victim_team_index != player_team_index) {
					log_player_event(attacker, "triggered", "headshot");
				}
			}
			if ((gameme_log_location == 1) && ((gameme_plugin[mod_id] != MOD_CSP))) {
				if (attacker != victim) {
					log_player_location("kill", attacker, victim);
				} else {
					log_player_location("suicide", attacker);
				}
			}
		}

		if ((gameme_plugin[mod_id] == MOD_L4DII) || (gameme_plugin[mod_id] == MOD_L4DII)) {
			if (headshot == 1) {
				log_player_event(attacker, "triggered", "headshot");
			}
			if (gameme_plugin[mod_id] == MOD_L4DII) {
				decl String: weapon[32];
				GetEventString(event, "weapon", weapon, 32);
				if (strncmp(weapon, "melee", 5) == 0) {
					new new_weapon_index = GetEntDataEnt2(attacker, l4dii_data[active_weapon_offset]);
					if (IsValidEdict(new_weapon_index)) {
						GetEdictClassname(new_weapon_index, weapon, 32);
						if (strncmp(weapon[7], "melee", 5) == 0) { 
							GetEntPropString(new_weapon_index, Prop_Data, "m_strMapSetScriptName", weapon, 32);
							SetEventString(event, "weapon", weapon);
						}
					}
				}
			}
		}
		
		if (gameme_plugin[mod_id] == MOD_HL2MP) {
			decl String: weapon[32];
			GetEventString(event, "weapon", weapon, 32);
			if (strcmp(weapon, "crossbow_bolt") == 0) {
				if (hl2mp_players[victim][nextbow_hitgroup] == HITGROUP_HEAD) {
					log_player_event(attacker, "triggered", "headshot");
				}
			} else {
				if (hl2mp_players[victim][next_hitgroup] == HITGROUP_HEAD) {
					log_player_event(attacker, "triggered", "headshot");
				}		
			}
		}

		if (gameme_plugin[mod_id] == MOD_ZPS) {
			if (zps_players[victim][next_hitgroup] == HITGROUP_HEAD) {
				log_player_event(attacker, "triggered", "headshot");
			}		
		}

		if (gameme_plugin[mod_id] == MOD_TF2) {
			new customkill = GetEventInt(event, "customkill");
			new weapon = GetEventInt(event, "weaponid");
			switch (customkill) {
				case TF_CUSTOM_BURNING_ARROW, TF_CUSTOM_FLYINGBURN: {
					decl String: log_weapon[64];
					GetEventString(event, "weapon_logclassname", log_weapon, 64);
					if (log_weapon[0] != 'd') {
						SetEventString(event, "weapon_logclassname", "tf_projectile_arrow_fire");
					}
				}
				case TF_CUSTOM_TAUNT_UBERSLICE: {
					if (weapon == TF_WEAPON_BONESAW) {
						SetEventString(event, "weapon_logclassname", "taunt_medic");
						SetEventString(event, "weapon", "taunt_medic");
					}
				}
				case TF_CUSTOM_DECAPITATION_BOSS: {
					log_player_event(attacker, "triggered", "killed_by_horseman");
				}
			}
		}

		if (gameme_log_location == 1) {
			if (((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP) || (gameme_plugin[mod_id] == MOD_DODS)) && (victim > 0)) {
				if (attacker != victim) {
					log_player_location("kill", attacker, victim);
				}
			}
		}

	}

	return Plugin_Continue;
}


public Action: gameME_Event_PlyTeamChange(Handle: event, const String: name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	if (userid > 0) {
		new player_index = GetClientOfUserId(userid);
		if (player_index > 0) {
			for (new i = 0; (i < sizeof(ColorSlotArray)); i++) {
				new color_client = ColorSlotArray[i];
				if (color_client > -1) {
					if (color_client == player_index) {
						ColorSlotArray[i] = -1;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action: gameME_Event_PlyBombDropped(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Dropped_The_Bomb", player);
		}

		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action:gameME_Event_PlyBombPickup(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Got_The_Bomb", player);
		}
		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action:gameME_Event_PlyBombPlanted(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Planted_The_Bomb", player);
		}
		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}

	return Plugin_Continue;
}


public Action:gameME_Event_PlyBombDefused(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Defused_The_Bomb", player);
		}

		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


public Action:gameME_Event_PlyHostageKill(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Killed_A_Hostage", player);
		}

		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


public Action:gameME_Event_PlyHostageResc(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player   = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		if (gameme_log_location == 1) {
			log_player_location("Rescued_A_Hostage", player);
		}

		if (gameme_display_spectator == 1) {
			for (new i = 0; (i <= MAXPLAYERS); i++) {
				player_messages[i][player][supdated] = 1;
			}
		}
	}
	return Plugin_Continue;
}


swap_player(player_index)
{
	if (IsClientConnected(player_index)) {
		new player_team_index = GetClientTeam(player_index);
		decl String: player_team[32];
		player_team = team_list[player_team_index];			

		if (strcmp(player_team, "CT") == 0) {
			if (IsPlayerAlive(player_index)) {
				CS_SwitchTeam(player_index, CS_TEAM_T);
				CS_RespawnPlayer(player_index);
				new new_model = GetRandomInt(0, 3);
				SetEntityModel(player_index, ts_models[new_model]);
			} else {
				CS_SwitchTeam(player_index, CS_TEAM_T);
			}
		} else if (strcmp(player_team, "TERRORIST") == 0) {
			if (IsPlayerAlive(player_index)) {
				CS_SwitchTeam(player_index, CS_TEAM_CT);
				CS_RespawnPlayer(player_index);
				new new_model = GetRandomInt(0, 3);
				SetEntityModel(player_index, ct_models[new_model]);
				new weapon_entity = GetPlayerWeaponSlot(player_index, 4);
				if (weapon_entity > 0) {
					decl String: class_name[32];
					GetEdictClassname(weapon_entity, class_name, 32);
					if (strcmp(class_name, "weapon_c4") == 0) {
						RemovePlayerItem(player_index, weapon_entity);
					}
				}
			} else {
				CS_SwitchTeam(player_index, CS_TEAM_CT);
			}
		}
	}
}


public CreateGameMEMenuMain(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEMainCommandHandler, MenuAction_Select|MenuAction_Cancel);

	if ((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP)) {
		SetMenuTitle(MenuHandle, "gameME - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Console Events");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
	} else {
		SetMenuTitle(MenuHandle, "gameME - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Clans Ranking");
		AddMenuItem(MenuHandle, "", "Server Status");
		AddMenuItem(MenuHandle, "", "Statsme");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Console Events");
		AddMenuItem(MenuHandle, "", "Weapon Usage");
		AddMenuItem(MenuHandle, "", "Weapons Accuracy");
		AddMenuItem(MenuHandle, "", "Weapons Targets");
		AddMenuItem(MenuHandle, "", "Player Kills");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
		AddMenuItem(MenuHandle, "", "VAC Cheaterlist");
		AddMenuItem(MenuHandle, "", "Display Help");
	}

	SetMenuPagination(MenuHandle, 8);
}


public CreateGameMEMenuAuto(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEAutoCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "gameME - Auto-Ranking");
	AddMenuItem(MenuHandle, "", "Enable on round-start");
	AddMenuItem(MenuHandle, "", "Enable on round-end");
	AddMenuItem(MenuHandle, "", "Enable on player death");
	AddMenuItem(MenuHandle, "", "Disable");

	SetMenuPagination(MenuHandle, 8);
}


public CreateGameMEMenuEvents(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(gameMEEventsCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "gameME - Console Events");
	AddMenuItem(MenuHandle, "", "Enable Events");
	AddMenuItem(MenuHandle, "", "Disable Events");
	AddMenuItem(MenuHandle, "", "Enable Global Chat");
	AddMenuItem(MenuHandle, "", "Disable Global Chat");

	SetMenuPagination(MenuHandle, 8);
}


make_player_command(client, String: player_command[192]) 
{
	if (client > 0) {
		log_player_event(client, "say", player_command);
	}
}


public gameMEMainCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			if ((gameme_plugin[mod_id] == MOD_INSMOD) || (gameme_plugin[mod_id] == MOD_HL2MP)) {
				switch (param2) {
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						DisplayMenu(gameMEMenuAuto, param1, MENU_TIME_FOREVER);
					case 4 : 
						DisplayMenu(gameMEMenuEvents, param1, MENU_TIME_FOREVER);
					case 5 : 
						make_player_command(param1, "/gameme_hideranking");
				}
			} else {
				switch (param2) {
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						make_player_command(param1, "/clans");
					case 4 : 
						make_player_command(param1, "/status");
					case 5 : 
						make_player_command(param1, "/statsme");
					case 6 : 
						DisplayMenu(gameMEMenuAuto, param1, MENU_TIME_FOREVER);
					case 7 : 
						DisplayMenu(gameMEMenuEvents, param1, MENU_TIME_FOREVER);
					case 8 : 
						make_player_command(param1, "/weapons");
					case 9 : 
						make_player_command(param1, "/accuracy");
					case 10 : 
						make_player_command(param1, "/targets");
					case 11 : 
						make_player_command(param1, "/kills");
					case 12 : 
						make_player_command(param1, "/gameme_hideranking");
					case 13 : 
						make_player_command(param1, "/cheaters");
					case 14 : 
						make_player_command(param1, "/help");
				}
			}
		}
	}
}


public gameMEAutoCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/gameme_auto start rank");
				case 1 : 
					make_player_command(param1, "/gameme_auto end rank");
				case 2 : 
					make_player_command(param1, "/gameme_auto kill rank");
				case 3 : 
					make_player_command(param1, "/gameme_auto clear");
			}
		}
	}
}


public gameMEEventsCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/gameme_display 1");
				case 1 : 
					make_player_command(param1, "/gameme_display 0");
				case 2 : 
					make_player_command(param1, "/gameme_chat 1");
				case 3 : 
					make_player_command(param1, "/gameme_chat 0");
			}
		}
	}
}


//
//
// Third Party Addons
//
//


/*
 *
 * Advanced Logging for
 *   Left 4 Dead,
 *   Left 4 Dead 2,
 *   Team Fortress 2,
 *   Insurgency,
 *   Half-Life 2: Deathmatch
 * Copyright (C) 2011 Nicholas Hastings (psychonic)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/


public Event_L4DRescueSurvivor(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "rescuer"));
	if (player > 0) {
		log_player_event(player, "triggered", "rescued_survivor");
	}
}


public Event_L4DHeal(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && (player != GetClientOfUserId(GetEventInt(event, "subject")))) {
		log_player_event(player, "triggered", "healed_teammate");
	}
}


public Event_L4DRevive(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "revived_teammate");
	}
}


public Event_L4DStartleWitch(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && ((gameme_plugin[mod_id] != MOD_L4DII) || (GetEventBool(event, "first")))) {
		log_player_event(player, "triggered", "startled_witch");
	}
}


public Event_L4DPounce(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (victim > 0) {
		log_player_player_event(player, victim, "triggered", "pounce");
	} else {
		log_player_event(player, "triggered", "pounce");
	}
}


public Event_L4DBoomered(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((player > 0) && ((gameme_plugin[mod_id] != MOD_L4DII) || (GetEventBool(event, "by_boomer")))) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "vomit");
		} else {
			log_player_event(player, "triggered", "vomit");
		}
	}
}


public Event_L4DFF(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if ((player > 0) && (player == GetClientOfUserId(GetEventInt(event, "guilty")))) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "friendly_fire");
		} else {
			log_player_event(player, "triggered", "friendly_fire");
		}
	}
}


public Event_L4DWitchKilled(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((player > 0) && (GetEventBool(event, "oneshot"))) {
		log_player_event(player, "triggered", "cr0wned");
	}
}


public Event_L4DDefib(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "defibrillated_teammate");
	}
}


public Event_L4DAdrenaline(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "used_adrenaline");
	}
}


public Event_L4DJockeyRide(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (player > 0) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "jockey_ride");
		} else {
			log_player_event(player, "triggered", "jockey_ride");
		}
	}
}


public Event_L4DChargerPummelStart(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (player > 0) {
		if (victim > 0) {
			log_player_player_event(player, victim, "triggered", "charger_pummel");
		} else {
			log_player_event(player, "triggered", "charger_pummel");
		}
	}
}


public Event_L4DVomitBombTank(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		log_player_event(player, "triggered", "bilebomb_tank");
	}
}


public Event_L4DScavengeEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "scavenge_win");
	}
}


public Event_L4DVersusEnd(Handle: event, const String: name[], bool:dontBroadcast)
{
	new team_index = GetEventInt(event, "winners");
	if (strcmp(team_list[team_index], "") != 0) {
		log_team_event(team_list[team_index], "versus_win");
	}
}


public Event_L4dChargerKilled(Handle: event, const String: name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "charger"));
	if ((attacker > 0) && (IsClientInGame(attacker))) {
		if (GetEventBool(event, "melee") && GetEventBool(event, "charging")) {
			if ((victim > 0) && (IsClientInGame(victim))) {
				log_player_player_event(attacker, victim, "triggered", "level_a_charge");
			} else {
				log_player_event(attacker, "triggered", "level_a_charge");
			}
		}
	}
}


public Action: Event_L4DAward(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "userid"	"short"				// player who earned the award
	// "entityid"	"long"			// client likes ent id
	// "subjectentid"	"long"		// entity id of other party in the award, if any
	// "award"		"short"			// id of award earned

	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player >  0) {
		switch (GetEventInt(event, "award")) {
			case 21: 
				log_player_event(player, "triggered", "hunter_punter");
			case 27:
				log_player_event(player, "triggered", "tounge_twister");
			case 67:
				log_player_event(player, "triggered", "protect_teammate");
			case 80:
				log_player_event(player, "triggered", "no_death_on_tank");
			case 136:
				log_player_event(player, "triggered", "killed_all_survivors");
		}
	}
}


public Action:Event_INSMODObjMsg(UserMsg: msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{ 
	new objective_point = BfReadByte(bf); // Objective Point: 1 = point A, 2 = point B, 3 = point C, etc.
	new cap_status = BfReadByte(bf); // Capture Status: 1 on starting capture, 2 on finished capture
	new team_index = BfReadByte(bf); // Team Index: 1 = Marines, 2 = Insurgents
	
	if ((cap_status == 2) && (strcmp(team_list[team_index], "") != 0)) {
		switch (objective_point) {
			case 1:
				log_team_event(team_list[team_index], "point_captured", "point_a");
			case 2:
				log_team_event(team_list[team_index], "point_captured", "point_b");
			case 3:
				log_team_event(team_list[team_index], "point_captured", "point_c");
			case 4:
				log_team_event(team_list[team_index], "point_captured", "point_d");
			case 5:
				log_team_event(team_list[team_index], "point_captured", "point_e");
		}
	}

	return Plugin_Continue;
} 


public Event_TF2StealSandvich(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "owner"		"short"
	// "target"		"short"
		
	new owner = GetClientOfUserId(GetEventInt(event, "owner"));
	new target = GetClientOfUserId(GetEventInt(event, "target"));

	if ((owner > 0) && (target > 0)) {
		log_player_player_event(target, owner, "triggered", "steal_sandvich");
	}
}


public Event_TF2Stunned(Handle: event, const String: name[], bool:dontBroadcast)
{
	// "stunner"	"short"
	// "victim"	"short"
	// "victim_capping"	"bool"
	// "big_stun"	"bool"

	new stunner = GetClientOfUserId(GetEventInt(event, "stunner"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if ((stunner > 0) && (victim > 0)) {

		log_player_player_event(stunner, victim, "triggered", "stun");
		if ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0) {
			log_player_event(stunner, "triggered", "airshot_stun");
		}
	}
}


public Action: Event_TF2Jarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);

	if ((client > 0) && (victim > 0) && (IsClientInGame(client)) && (IsClientInGame(victim))) {
		new victim_condition = TF2_GetPlayerConditionFlags(victim);	
		if ((victim_condition & TF_CONDFLAG_JARATED) == TF_CONDFLAG_JARATED) {
			log_player_player_event(client, victim, "triggered", "jarate");
		} else if ((victim_condition & TF_CONDFLAG_MILKED) == TF_CONDFLAG_MILKED) {
			log_player_player_event(client, victim, "triggered", "madmilk");
		}
	}
	return Plugin_Continue;
}


public Action: Event_TF2ShieldBlocked(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new victim = BfReadByte(bf);
	new client = BfReadByte(bf);
		
	if ((client > 0) && (victim > 0)) {
		log_player_player_event(client, victim, "triggered", "shield_blocked");
	}
	return Plugin_Continue;
}


public Action: Event_TF2SoundHook(clients[64], &numClients, String: sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if ((entity <= MaxClients) &&(clients[0] == entity) && (tf2_players[entity][player_class] == TFClass_Heavy) && (StrEqual(sample, "vo/SandwichEat09.wav"))) {
		
		switch (tf2_players[entity][player_loadout0][1]) {
			case TF2_LUNCHBOX_CHOCOLATE: {
				log_player_event(entity, "triggered", "dalokohs");
				new Float: time = GetGameTime();
				if ((time - tf2_players[entity][dalokohs]) > 30) {
					log_player_event(entity, "triggered", "dalokohs_healthboost");
				}
				tf2_players[entity][dalokohs] = time;
				if (GetClientHealth(entity) < 350) {
					log_player_event(entity, "triggered", "dalokohs_healself");
				}
			}
			case TF2_LUNCHBOX_STEAK: {
				log_player_event(entity, "triggered", "steak");
			}
			default: {
				log_player_event(entity, "triggered", "sandvich");
				if (GetClientHealth(entity) < 300) {
					log_player_event(entity, "triggered", "sandvich_healself");
				}
			}
		}

		
	} 
	return Plugin_Continue;
} 


public Event_TF2WinPanel(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player1 = GetEventInt(event, "player_1");
	new player2 = GetEventInt(event, "player_2");
	new player3 = GetEventInt(event, "player_3");
	
	if (player1 > 0) {
		log_player_event(player1, "triggered", "mvp1");
	}
	if (player2 > 0) {
		log_player_event(player2, "triggered", "mvp2");
	}
	if (player3 > 0) {
		log_player_event(player3, "triggered", "mvp3");
	}
} 


public Event_TF2EscortScore(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetEventInt(event, "player");
	if (player > 0) {
		log_player_event(player, "triggered", "escort_score");
	}
}


public Event_TF2DeployBuffBanner(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "buff_owner"));
	if (player > 0) {
		log_player_event(player, "triggered", "buff_deployed");
	}

}


public Event_TF2MedicDefended(Handle: event, const String: name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player > 0) {
		log_player_event(player, "triggered", "defended_medic");
	}
}


public Action: Event_TF2ObjectDestroyedPre(Handle: event, const String: name[], bool:dontBroadcast)
{
	if (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1)) {
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new userid = GetEventInt(event, "userid");
		new victim = GetClientOfUserId(userid);
		
		if ((attacker > 0) && (victim > 0) && (attacker <= MAXPLAYERS) && (victim <= MAXPLAYERS) && (IsClientInGame(victim)) && (IsClientInGame(attacker))) {
			decl String: weapon_str[32];
			GetEventString(event, "weapon", weapon_str, 32);
			new Float: player_origin[3];
			GetClientAbsOrigin(attacker, player_origin);
			LogToGame("\"%L\" %s \"%s\" (object \"%s\") (weapon \"%s\") (objectowner \"%L\") (attacker_position \"%d %d %d\")", attacker, "triggered", "killedobject", "OBJ_SENTRYGUN_MINI", weapon_str, victim, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
		tf2_data[block_next_logging] = true;
	}
	return Plugin_Continue;
}


public Action: Event_TF2PlayerBuiltObjectPre(Handle: event, const String: name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		if (tf2_players[client][carry_object]) {
			tf2_players[client][carry_object] = false;
			tf2_data[block_next_logging] = true;
		} else {
			if (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1)) {
				if ((client > 0) && (client <= MAXPLAYERS) && (IsClientInGame(client))) {
					new Float: player_origin[3];
					GetClientAbsOrigin(client, player_origin);
					LogToGame("\"%L\" %s \"%s\" (object \"%s\") (position \"%d %d %d\")", client, "triggered", "builtobject", "OBJ_SENTRYGUN_MINI", RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
				}
				tf2_data[block_next_logging] = true;
			}
		}
	}
	return Plugin_Continue;
}


public Event_TF2PlayerSpawn(Handle: event, const String: name[], bool:dontBroadcast)
{
	new Float: time = GetGameTime();
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new TFClassType: spawn_class = TFClassType: GetEventInt(event, "class");

	tf2_players[client][jump_status] = TF2_JUMP_NONE;
	dump_player_data(client);

	if (time == tf2_players[client][object_removed]) {
		new obj_type;
		decl String: obj_name[24];
		while (PopStackCell(tf2_players[client][object_list], obj_type)) {
			switch (obj_type) {
				case TF2_OBJ_DISPENSER:
					obj_name = "OBJ_DISPENSER";
				case TF2_OBJ_TELEPORTER:
					obj_name = "OBJ_TELEPORTER";
				case TF2_OBJ_SENTRYGUN:
					obj_name = "OBJ_SENTRYGUN";
				case TF2_OBJ_SENTRYGUN_MINI:
					obj_name = "OBJ_SENTRYGUN_MINI";
				default:
					continue;
			}
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			LogToGame("\"%L\" %s \"%s\" (object \"%s\") (weapon \"%s\") (objectowner \"%L\") (attacker_position \"%d %d %d\")", client, "triggered", "killedobject", obj_name, "pda_engineer", client, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
	}
	
	tf2_players[client][player_class] = spawn_class;
	tf2_players[client][dalokohs] = -30.0;
}


public Event_TF2ObjectRemoved(Handle: event, const String: name[], bool:dontBroadcast)
{
	new Float: time = GetGameTime();
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if (time != tf2_players[client][object_removed]) {
		tf2_players[client][object_removed] = time;
		while (PopStack(tf2_players[client][object_list])) {
			continue;
		}
	}
	new obj_type = GetEventInt(event, "objecttype");
	new obj_index = GetEventInt(event, "index");
	if ((IsValidEdict(obj_index)) && (GetEntProp(GetEventInt(event, "index"), Prop_Send, "m_bMiniBuilding", 1))) {
		obj_type = TF2_OBJ_SENTRYGUN_MINI;
	}
	PushStackCell(tf2_players[client][object_list], obj_type);
}


public Event_TF2PostInvApp(Handle: event, const String: name[], bool:dontBroadcast)
{
	CreateTimer(0.2, check_player_loadout, GetEventInt(event, "userid"));
}


public Action: check_player_loadout(Handle: timer, any: userid)
{
	new client = GetClientOfUserId(userid);
	if ((client == 0) || (!IsClientInGame(client))) {
		return Plugin_Stop;
	}
	
	new bool: is_new_loadout = false;
	for (new check_slot = 0; check_slot <= 5; check_slot++) {
		if ((tf2_players[client][player_loadout1][check_slot] != 0) && (IsValidEntity(tf2_players[client][player_loadout1][check_slot]))) {
			continue;
		}
		new entity = GetPlayerWeaponSlot(client, check_slot);
		if (entity == -1) {
			if ((gameme_plugin[sdkhook_available]) && (check_slot < 3) && ((tf2_players[client][player_class] == TFClass_Soldier) || (tf2_players[client][player_class] == TFClass_DemoMan))) {
				tf2_players[client][player_loadout1][check_slot] = -1;
				continue;
			}
			if (tf2_players[client][player_loadout0][check_slot] == -1) {
				continue;
			}
			tf2_players[client][player_loadout0][check_slot] = -1;
			tf2_players[client][player_loadout1][check_slot] = -1;
			is_new_loadout = true;
		} else {
			new item_index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if (tf2_players[client][player_loadout0][check_slot] != item_index) {
				tf2_players[client][player_loadout0][check_slot] = item_index;
				is_new_loadout = true;
			}
			tf2_players[client][player_loadout1][check_slot] = EntIndexToEntRef(entity);
		}
	}
	
	if (gameme_plugin[sdkhook_available]) {
		if (is_new_loadout) {
			tf2_players[client][player_loadout_updated] = true;
		}
		CreateTimer(0.2, log_weapon_loadout, userid);
	} else {
		if (is_new_loadout) {
			log_weapon_loadout(INVALID_HANDLE, userid);
		}
	}
	return Plugin_Stop;
}


public Action: log_weapon_loadout(Handle: timer, any: userid)
{
	new client = GetClientOfUserId(userid);
	if ((client > 0) && (IsClientInGame(client))) {
		for (new i = 0; i < TF2_MAX_LOADOUT_SLOTS; i++) {
			if ((tf2_players[client][player_loadout0][i] != -1) && (!IsValidEntity(tf2_players[client][player_loadout1][i])) || (tf2_players[client][player_loadout1][i] == 0)) {
				tf2_players[client][player_loadout0][i] = -1;
				tf2_players[client][player_loadout1][i] = -1;
				tf2_players[client][player_loadout_updated] = true;
			}
		}
		if (tf2_players[client][player_loadout_updated] == false) {
			return Plugin_Stop;
		}
		tf2_players[client][player_loadout_updated] = false;
		LogToGame("\"%L\" %s \"%s\" (primary \"%d\") (secondary \"%d\") (melee \"%d\") (pda \"%d\") (pda2 \"%d\") (building \"%d\") (head \"%d\") (misc \"%d\")", client, "triggered", "player_loadout", tf2_players[client][player_loadout0][0], tf2_players[client][player_loadout0][1], tf2_players[client][player_loadout0][2], tf2_players[client][player_loadout0][3], tf2_players[client][player_loadout0][4], tf2_players[client][player_loadout0][5], tf2_players[client][player_loadout0][6], tf2_players[client][player_loadout0][7]); 
	}
	return Plugin_Stop;
}


public Action: OnTF2TakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ((attacker > 0) && (attacker != victim) && (inflictor > MaxClients) && (damage > 0.0) && (IsValidEntity(inflictor)) && ((GetEntityFlags(victim) & (FL_ONGROUND | FL_INWATER)) == 0)) {
		decl String: weapon_str[64];
		GetEdictClassname(inflictor, weapon_str, 64);
		if ((weapon_str[3] == 'p') && (weapon_str[4] == 'r')) {
			switch(weapon_str[14]) {
				case 'r': {
					log_player_event(attacker, "triggered", "airshot_rocket");
					if (tf2_players[attacker][jump_status] == TF2_JUMP_ROCKET) {
						log_player_event(attacker, "triggered", "air2airshot_rocket");
					}
				}
				case 'p': {
					if (weapon_str[18] != 0) {
						log_player_event(attacker, "triggered", "airshot_sticky");
						if (tf2_players[attacker][jump_status] == TF2_JUMP_STICKY) {
							log_player_event(attacker, "triggered", "air2airshot_sticky");
						}
					} else {
						log_player_event(attacker, "triggered", "airshot_pipebomb");
						if (tf2_players[attacker][jump_status] == TF2_JUMP_STICKY) {
							log_player_event(attacker, "triggered", "air2airshot_pipebomb");
						}
					}
				}
				case 'a': {
					log_player_event(attacker, "triggered", "airshot_arrow");
				}
				case 'f': {
					if (damage > 10.0) {
						log_player_event(attacker, "triggered", "airshot_flare");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public OnTF2TakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (attacker > 0) {
		new weapon_index = -1;
		new idamage = RoundFloat(damage);
		decl String: weapon_str[64];

		if (inflictor <= MaxClients) {
			if (damagetype & DMG_BURN) {
				return;
			}
			if ((inflictor == attacker) && (damagetype & 1) && (damage == 1000.0)) {
				return;
			}
			GetClientWeapon(attacker, weapon_str, 64);
			weapon_index = get_tf2_weapon_index(weapon_str[TF2_WEAPON_PREFIX_LENGTH], attacker);
		} else if (IsValidEdict(inflictor)) {
			GetEdictClassname(inflictor, weapon_str, 64);
			if (weapon_str[TF2_WEAPON_PREFIX_LENGTH] == 'g') {
				return;
			} else if (weapon_str[3] == 'p') {
				weapon_index = get_tf2_weapon_index(weapon_str, attacker, inflictor);
			} else {
				if ((!(damagetype & DMG_CRUSH)) && (damagetype & DMG_CLUB) && (StrEqual(weapon_str, "tf_weapon_bat_wood"))) {
					weapon_index = get_tf2_weapon_index("ball", attacker);
				} else {
					weapon_index = get_tf2_weapon_index(weapon_str[TF2_WEAPON_PREFIX_LENGTH], attacker);
				}
			}
		}

		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wdamage] += idamage;
			player_weapons[attacker][weapon_index][whits]++;
		}
	}
}


public Event_TF2RocketJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		new status = tf2_players[client][jump_status];
		if (status == TF2_JUMP_ROCKET_START) {
			tf2_players[client][jump_status] = TF2_JUMP_ROCKET;
			log_player_event(client, "triggered", "rocket_jump");
		} else if (status != TF2_JUMP_ROCKET) {
			tf2_players[client][jump_status] = TF2_JUMP_ROCKET_START;
		}
	}
}


public Event_TF2StickyJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		if (tf2_players[client][jump_status] != TF2_JUMP_STICKY) {
			tf2_players[client][jump_status] = TF2_JUMP_STICKY;
			log_player_event(client, "triggered", "sticky_jump");
		}
	}
}


public Event_TF2JumpLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0) {
		tf2_players[client][jump_status] = TF2_JUMP_NONE;
		
	}
}


public Event_TF2ObjectDeflected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
	
	if ((client > 0) && (owner > 0)) {
		new weapon_id = GetEventInt(event, "weaponid");
	
		switch (weapon_id)	{
			case TF_WEAPON_NONE: {
				log_player_player_event(client, owner, "triggered", "airblast_player", 1);
			}
			case TF_WEAPON_COMPOUND_BOW: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_arrow");
					if (weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_FLAREGUN: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_flare");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_ROCKETLAUNCHER: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_rocket");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_DIRECTHIT: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_rocket");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
			case TF_WEAPON_GRENADE_DEMOMAN: {
				if (gameme_plugin[sdkhook_available]) {
					new weapon_index = get_tf2_weapon_index("deflect_promode");
					if(weapon_index > -1) {
						player_weapons[client][weapon_index][wshots]++;
					}
				}
			}
		}
		
	}
}


public OnHL2MPFireBullets(attacker, shots, String: weapon_str[])
{
	if ((attacker > 0) && (attacker <= MaxClients)) {
		decl String: weapon_name[32];
		GetClientWeapon(attacker, weapon_name, 32);
		new weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_name[7]);
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
}


public OnHL2MPTraceAttack(victim, attacker, inflictor, Float: damage, damagetype, ammotype, hitbox, hitgroup)
{
	if ((hitgroup > 0) && (attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		if (IsValidEntity(inflictor)) {
			decl String: inflictorclsname[64];
			if ((GetEntityNetClass(inflictor, inflictorclsname, sizeof(inflictorclsname)) && (strcmp(inflictorclsname, "CCrossbowBolt") == 0))) {
				hl2mp_players[victim][nextbow_hitgroup] = hitgroup;
				return;
			}
		}
		hl2mp_players[victim][next_hitgroup] = hitgroup;
	}
}


public OnHL2MPTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{	
	if ((attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = -1;

		if (IsValidEntity(inflictor)) {
			decl String: inflictorclsname[64];
			if (GetEntityNetClass(inflictor, inflictorclsname, sizeof(inflictorclsname)) && strcmp(inflictorclsname, "CCrossbowBolt") == 0) {
				weapon_index = HL2MP_CROSSBOW;
			}
		}
		if (weapon_index == -1) {
			weapon_index = get_weapon_index(hl2mp_weapon_list, MAX_HL2MP_WEAPON_COUNT, weapon_str[7]);
		}

		new hitgroup = ((weapon_index == HL2MP_CROSSBOW) ? hl2mp_players[victim][nextbow_hitgroup] : hl2mp_players[victim][next_hitgroup]);
		if (hitgroup < 8) {
			hitgroup += LOG_HIT_OFFSET;
		}

		new bool: headshot = ((GetClientHealth(victim) <= 0) && (hitgroup == HITGROUP_HEAD));
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += RoundToNearest(damage);
			player_weapons[attacker][weapon_index][hitgroup]++;
			if (headshot) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
		}
		
		if (weapon_index == HL2MP_CROSSBOW) {
			hl2mp_players[victim][nextbow_hitgroup] = 0;
		} else {
			hl2mp_players[victim][next_hitgroup] = 0;
		}
		
	}
}


public OnZPSFireBullets(attacker, shots, String: weapon[])
{
	if ((attacker > 0) && (attacker <= MaxClients)) {
		decl String: weapon_name[32];
		GetClientWeapon(attacker, weapon_name, 32);
		new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_name);
		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][wshots]++;
		}
	}
}


public OnZPSTraceAttack(victim, attacker, inflictor, Float:damage, damagetype, ammotype, hitbox, hitgroup)
{
	if ((hitgroup > 0) && (attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		zps_players[victim][next_hitgroup] = hitgroup;
	}
}


public OnZPSTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{	
	if ((attacker > 0) && (attacker <= MaxClients) && (victim > 0) && (victim <= MaxClients)) {
		new hitgroup = zps_players[victim][next_hitgroup];
		if (hitgroup < 8) {
			hitgroup += LOG_HIT_OFFSET;
		}
		new bool: headshot = ((GetClientHealth(victim) <= 0) && (hitgroup == HITGROUP_HEAD));
		
		decl String: weapon_str[32];
		GetClientWeapon(attacker, weapon_str, 32);
		new weapon_index = get_weapon_index(zps_weapon_list, MAX_ZPS_WEAPON_COUNT, weapon_str);

		if (weapon_index > -1) {
			player_weapons[attacker][weapon_index][whits]++;
			player_weapons[attacker][weapon_index][wdamage] += RoundToNearest(damage);
			if (headshot) {
				player_weapons[attacker][weapon_index][wheadshots]++;
			}
		}
		zps_players[victim][next_hitgroup] = 0;
	}
}


stock AddPluginServerTag(const String:tag[]) 
{
	if ((gameme_plugin[sv_tags] == INVALID_HANDLE) || ((gameme_plugin[sdk_version] != SOURCE_SDK_EPISODE2) && (gameme_plugin[sdk_version] != SOURCE_SDK_EPISODE2VALVE))) {
		return;
	}
	
	if (FindStringInArray(gameme_plugin[custom_tags], tag) == -1) {
		PushArrayString(gameme_plugin[custom_tags], tag);
	}
	
	decl String: current_tags[128];
	GetConVarString(gameme_plugin[sv_tags], current_tags, 128);
	if (StrContains(current_tags, tag) > -1) {
		return;
	}
	
	decl String: new_tags[128];
	Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0] != 0) ? "," : "", tag);
	
	new flags = GetConVarFlags(gameme_plugin[sv_tags]);
	SetConVarFlags(gameme_plugin[sv_tags], flags & ~FCVAR_NOTIFY);
	gameme_plugin[ignore_next_tag_change] = true;
	SetConVarString(gameme_plugin[sv_tags], new_tags);
	gameme_plugin[ignore_next_tag_change] = false;
	SetConVarFlags(gameme_plugin[sv_tags], flags);
}
