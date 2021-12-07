/**
 * HLstatsX - SourceMod plugin to display ingame messages
 * http://www.hlstatsx.com/
 * Copyright (C) 2007-2009 TTS Oetzel & Goerz GmbH
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

#define REQUIRE_EXTENSIONS 
#include <sourcemod>
#include <keyvalues>
#include <menus>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>

new String: game_mod[32];
new String: team_list[16][64];

new Handle: hlx_block_chat_commands;
new Handle: hlx_message_prefix;
new Handle: hlx_protect_address;
new String: blocked_commands[][] = { "rank", "skill", "points", "place", "session", "session_data", 
                                     "kpd", "kdratio", "kdeath", "next", "load", "status", "servers", 
                                     "top20", "top10", "top5", "clans", "cheaters", "statsme", "weapons", 
                                     "weapon", "action", "actions", "accuracy", "targets", "target", "kills", 
                                     "kill", "player_kills", "cmd", "cmds", "command", "hlx_display 0", 
                                     "hlx_display 1", "hlx_teams 0", "hlx_teams 1", "hlx_hideranking", 
                                     "hlx_chat 0", "hlx_chat 1", "hlx_menu", "servers 1", "servers 2", 
                                     "servers 3", "gstats", "global_stats", "hlx", "hlstatsx" };

new Handle:HLstatsXMenuMain;
new Handle:HLstatsXMenuAuto;
new Handle:HLstatsXMenuEvents;

new Handle: PlayerColorArray;

new ct_player_color   = -1;
new ts_player_color   = -1;
new blue_player_color = -1;
new red_player_color  = -1;

new String: message_cache[192];
new String: parsed_message_cache[192];
new cached_color_index;

new String: ct_models[4][] = {"models/player/ct_urban.mdl", 
                              "models/player/ct_gsg9.mdl", 
                              "models/player/ct_sas.mdl", 
                              "models/player/ct_gign.mdl"};
                                
new String: ts_models[4][] = {"models/player/t_phoenix.mdl", 
                              "models/player/t_leet.mdl", 
                              "models/player/t_arctic.mdl", 
                              "models/player/t_guerilla.mdl"};

new String: logmessage_ignore[512];
new String: message_prefix[64];

public Plugin:myinfo = {
	name = "HLstatsX Plugin",
	author = "TTS Oetzel & Goerz GmbH",
	description = "HLstatsX Ingame Plugin",
	version = "2.8",
	url = "http://www.hlstatsx.com"
};


public OnPluginStart() 
{
	get_server_mod();

	CreateHLstatsXMenuMain(HLstatsXMenuMain);
	CreateHLstatsXMenuAuto(HLstatsXMenuAuto);
	CreateHLstatsXMenuEvents(HLstatsXMenuEvents);

	clear_message_cache();

	RegServerCmd("hlx_sm_psay",          hlx_sm_psay);
	RegServerCmd("hlx_sm_psay2",         hlx_sm_psay2);
	RegServerCmd("hlx_sm_csay",          hlx_sm_csay);
	RegServerCmd("hlx_sm_msay",          hlx_sm_msay);
	RegServerCmd("hlx_sm_tsay",          hlx_sm_tsay);
	RegServerCmd("hlx_sm_hint",          hlx_sm_hint);
	RegServerCmd("hlx_sm_browse",        hlx_sm_browse);
	RegServerCmd("hlx_sm_swap",          hlx_sm_swap);
	RegServerCmd("hlx_sm_redirect",      hlx_sm_redirect);
	RegServerCmd("hlx_sm_player_action", hlx_sm_player_action);
	RegServerCmd("hlx_sm_team_action",   hlx_sm_team_action);
	RegServerCmd("hlx_sm_world_action",  hlx_sm_world_action);

	if (strcmp(game_mod, "INSMOD") == 0 || strcmp(game_mod, "ZPS") == 0) {
		RegConsoleCmd("say",                 hlx_block_commands);
		RegConsoleCmd("say2",                hlx_block_commands);
		RegConsoleCmd("say_team",            hlx_block_commands);
	} else {
		RegConsoleCmd("say",                 hlx_block_commands);
		RegConsoleCmd("say_team",            hlx_block_commands);
	}

	HookEvent("player_death", HLstatsX_Event_PlyDeath, EventHookMode_Pre);
	HookEvent("player_team",  HLstatsX_Event_PlyTeamChange, EventHookMode_Pre);
	
	CreateConVar("hlx_plugin_version", "2.8", "HLstatsX Ingame Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("hlx_webpage", "http://www.hlstatsx.com", "http://www.hlstatsx.com", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hlx_block_chat_commands = CreateConVar("hlx_block_commands", "1", "If activated HLstatsX commands are blocked from the chat area", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hlx_message_prefix = CreateConVar("hlx_message_prefix", "", "Define the prefix displayed on every HLstatsX ingame message");
	HookConVarChange(hlx_message_prefix, OnMessagePrefixChange);
	hlx_protect_address = CreateConVar("hlx_protect_address", "", "Address to be protected for logging/forwarding");
	HookConVarChange(hlx_protect_address, OnProtectAddressChange);
	
	RegServerCmd("log", ProtectLoggingChange);
	RegServerCmd("logaddress_del", ProtectForwardingChange);
	RegServerCmd("logaddress_delall", ProtectForwardingDelallChange);
	RegServerCmd("hlx_message_prefix_clear", MessagePrefixClear);

	PlayerColorArray = CreateArray();
}


public OnPluginEnd() 
{
	if (PlayerColorArray != INVALID_HANDLE) {
		CloseHandle(PlayerColorArray);
	}
}


public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("CS_SwitchTeam");
	MarkNativeAsOptional("CS_RespawnPlayer");
	
	return true;
}


public OnMapStart()
{
	get_server_mod();

	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0) || (strcmp(game_mod, "DODS") == 0) || (strcmp(game_mod, "HL2MP") == 0) || (strcmp(game_mod, "FF") == 0) || (strcmp(game_mod, "HIDDEN") == 0) || (strcmp(game_mod, "ZPS") == 0) || (strcmp(game_mod, "AOC") == 0)) {		
		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++) {
			decl String: team_name[64];
			GetTeamName(team_index, team_name, 64);
			if (strcmp(team_name, "") != 0) {
				team_list[team_index] = team_name;
			}
		}
	}
	
	clear_message_cache();

	if (strcmp(game_mod, "CSS") == 0) {
		ct_player_color = -1;
		ts_player_color = -1;
		find_player_team_slot("CT");
		find_player_team_slot("TERRORIST");
	} else if (strcmp(game_mod, "TF") == 0) {
		blue_player_color = -1;
		red_player_color = -1;
		find_player_team_slot("Blue");
		find_player_team_slot("Red");
	}
}


get_server_mod()
{
	if (strcmp(game_mod, "") == 0) {
		new String: game_description[64];
		GetGameDescription(game_description, 64, true);
	
		if (StrContains(game_description, "Counter-Strike", false) != -1) {
			game_mod = "CSS";
		}
		if (StrContains(game_description, "Day of Defeat", false) != -1) {
			game_mod = "DODS";
		}
		if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1) {
			game_mod = "HL2MP";
		}
		if (StrContains(game_description, "Team Fortress", false) != -1) {
			game_mod = "TF";
		}
		if (StrContains(game_description, "Insurgency", false) != -1) {
			game_mod = "INSMOD";
		}
		if (StrContains(game_description, "L4D", false) != -1) {
			game_mod = "L4D";
		}
		if (StrContains(game_description, "Fortress Forever", false) != -1) {
			game_mod = "FF";
		}
		if (StrContains(game_description, "Zombie Panic", false) != -1) {
			game_mod = "ZPS";
		}
		if (StrContains(game_description, "Age of Chivalry", false) != -1) {
			game_mod = "AOC";
		}
		
		// game mod could not detected, try further
		if (strcmp(game_mod, "") == 0) {
			new String: game_folder[64];
			GetGameFolderName(game_folder, 64);

			if (StrContains(game_folder, "cstrike", false) != -1) {
				game_mod = "CSS";
			}
			if (StrContains(game_folder, "dod", false) != -1) {
				game_mod = "DODS";
			}
			if (StrContains(game_folder, "hl2mp", false) != -1) {
				game_mod = "HL2MP";
			}
			if (StrContains(game_folder, "tf", false) != -1) {
				game_mod = "TF";
			}
			if (StrContains(game_folder, "insurgency", false) != -1) {
				game_mod = "INSMOD";
			}
			if (StrContains(game_folder, "left4dead", false) != -1) {
				game_mod = "L4D";
			}
			if (StrContains(game_folder, "FortressForever", false) != -1) {
				game_mod = "FF";
			}
			if (StrContains(game_folder, "Hidden", false) != -1) {
				game_mod = "HIDDEN";
			}
			if (StrContains(game_folder, "zps", false) != -1) {
				game_mod = "ZPS";
			}
			if (StrContains(game_folder, "ageofchivalry", false) != -1) {
				game_mod = "AOC";
			}			
			if (strcmp(game_mod, "") == 0) {
				LogToGame("Mod Detection (HLstatsX): Failed (%s, %s)", game_description, game_folder);
			}
		}

		if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "DODS") == 0)) {
			AddGameLogHook(HLstatsX_Event_GameLog);
		}

		if (strcmp(game_mod, "CSS") == 0) {
			HookEvent("bomb_dropped",    HLstatsX_Event_PlyBombDropped, EventHookMode_Pre);
			HookEvent("bomb_pickup",     HLstatsX_Event_PlyBombPickup,  EventHookMode_Pre);
			HookEvent("bomb_planted",    HLstatsX_Event_PlyBombPlanted, EventHookMode_Pre);
			HookEvent("bomb_defused",    HLstatsX_Event_PlyBombDefused, EventHookMode_Pre);
			HookEvent("hostage_killed",  HLstatsX_Event_PlyHostageKill, EventHookMode_Pre);
			HookEvent("hostage_rescued", HLstatsX_Event_PlyHostageResc, EventHookMode_Pre);
		}

		// added round tracking for Insurgency and Age of Chivalry		
		if (strcmp(game_mod, "AOC") == 0 || strcmp(game_mod, "INSMOD") == 0) {
			HookEvent("round_end", HLstatsX_Event_RoundEnd, EventHookMode_Pre);
		}

		LogToGame("Mod Detection (HLstatsX): %s [%s]", game_description, game_mod);
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


public Action:ProtectLoggingChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			if (args >= 1) {
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if ((strcmp(log_action, "off") == 0) || (strcmp(log_action, "0") == 0)) {
					LogToGame("HLstatsX address protection active, logging reenabled!");
					ServerCommand("log 1");
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:ProtectForwardingChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			if (args == 1) {
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if (strcmp(log_action, protect_address) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			} else if (args > 1) {
				new String: log_action[192];
				for(new i = 1; i <= args; i++) {
					decl String: temp_argument[192];
					GetCmdArg(i, temp_argument, 192);
					strcopy(log_action[strlen(log_action)], 192, temp_argument);
				}
				if (strcmp(log_action, protect_address) == 0) {
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			
			}
		}
	}
	return Plugin_Continue;
}


public Action:ProtectForwardingDelallChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE) {
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0) {
			decl String: log_command[192];
			Format(log_command, 192, "logaddress_add %s", protect_address);
			LogToGame("HLstatsX address protection active, logaddress readded!");
			ServerCommand(log_command);
		}
	}
	return Plugin_Continue;
}


public OnMessagePrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(message_prefix, 64, newVal);
}


public Action:MessagePrefixClear(args)
{
	message_prefix = "";
}


log_player_event(client, String: verb[32], String: player_event[192], display_location = 0)
{
	if (client > 0) {
		decl String: player_name[32];
		if (!GetClientName(client, player_name, 32)) {
			strcopy(player_name, 32, "UNKNOWN");
		}

		decl String: player_authid[32];
		if (!GetClientAuthString(client, player_authid, 32)) {
			strcopy(player_authid, 32, "UNKNOWN");
		}

		new player_team_index = GetClientTeam(client);
		decl String: player_team[64];
		player_team = team_list[player_team_index];

		// Workaround for wrong team logging within the game Insurgency
		if (strcmp(game_mod, "INSMOD") == 0) {
			switch(player_team_index) {
				case 1:		strcopy(player_team, 64, "U.S. Marines");
				case 2:		strcopy(player_team, 64, "Iraqi Insurgents");
				case 3:		strcopy(player_team, 64, "SPECTATOR");
				default:	strcopy(player_team, 64, "Unassigned");
			}
		}		

		new user_id = GetClientUserId(client);
		
		if (display_location > 0) {
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" %s \"%s\"", player_name, user_id, player_authid, player_team, verb, player_event); 
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\" (position \"%d %d %d\")", player_name, user_id, player_authid, player_team, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		} else {
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\"", player_name, user_id, player_authid, player_team, verb, player_event); 
		}
	}
}


// not used yet
stock log_admin_event(client, const String: admin_event[])
{
	if (client > 0) {
		decl String: player_name[32];
		if (!GetClientName(client, player_name, 32)) {
			strcopy(player_name, 32, "UNKNOWN");
		}

		decl String: player_authid[32];
		if (!GetClientAuthString(client, player_authid, 32)) {
			strcopy(player_authid, 32, "UNKNOWN");
		}

		new player_team_index = GetClientTeam(client);
		decl String: player_team[64];
		player_team = team_list[player_team_index];

		LogToGame("[SOURCEMOD]: \"%s<%s><%s>\" %s \"%s\"", player_name, player_authid, player_team, "executed", admin_event); 
	} else {
		LogToGame("[SOURCEMOD]: \"<SERVER>\" %s \"%s\"", "executed", admin_event); 
	}
}


find_player_team_slot(String: team[64]) 
{
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
		new team_index = get_team_index(team);
		if (team_index > -1) {
			if (strcmp(team, "CT") == 0) {
				ct_player_color = -1;
			} else if (strcmp(team, "TERRORIST") == 0) {
				ts_player_color = -1;
			} else if (strcmp(team, "Blue") == 0) {
				blue_player_color = -1;
			} else if (strcmp(team, "Red") == 0) {
				red_player_color = -1;
			}

			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new player_index = i;
				if ((IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
					new player_team_index = GetClientTeam(player_index);
					if (player_team_index == team_index) {
						if (strcmp(team, "CT") == 0) {
							ct_player_color = player_index;
							if (ts_player_color == ct_player_color) {
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						} else if (strcmp(team, "TERRORIST") == 0) {
							ts_player_color = player_index;
							if (ts_player_color == ct_player_color) {
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						} else if (strcmp(team, "Blue") == 0) {
							blue_player_color = player_index;
							if (red_player_color == blue_player_color) {
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						} else if (strcmp(team, "Red") == 0) {
							red_player_color = player_index;
							if (red_player_color == blue_player_color) {
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						}
					}
				}
			}
		}
	}
}


stock validate_team_colors() 
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (ct_player_color > -1) {
			if ((IsClientConnected(ct_player_color)) && (IsClientInGame(ct_player_color))) {
				new player_team_index = GetClientTeam(ct_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("CT", player_team) != 0) {
					ct_player_color = -1;
				}
			} else {
				ct_player_color = -1;
			}
		} else if (ts_player_color > -1) {
			if ((IsClientConnected(ts_player_color)) && (IsClientInGame(ts_player_color))) {
				new player_team_index = GetClientTeam(ts_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("TERRORIST", player_team) != 0) {
					ts_player_color = -1;
				}
			} else {
				ts_player_color = -1;
			}
		}
		if ((ct_player_color == -1) || (ts_player_color == -1)) {
			if (ct_player_color == -1) {
				find_player_team_slot("CT");
			}
			if (ts_player_color == -1) {
				find_player_team_slot("TERRORIST");
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		if (blue_player_color > -1) {
			if ((IsClientConnected(blue_player_color)) && (IsClientInGame(blue_player_color))) {
				new player_team_index = GetClientTeam(blue_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Blue", player_team) != 0) {
					blue_player_color = -1;
				}
			} else {
				blue_player_color = -1;
			}
		} else if (red_player_color > -1) {
			if ((IsClientConnected(red_player_color)) && (IsClientInGame(red_player_color))) {
				new player_team_index = GetClientTeam(red_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Red", player_team) != 0) {
					red_player_color = -1;
				}
			} else {
				red_player_color = -1;
			}
		}
		if ((blue_player_color == -1) || (red_player_color == -1)) {
			if (blue_player_color == -1) {
				find_player_team_slot("Blue");
			}
			if (red_player_color == -1) {
				find_player_team_slot("Red");
			}
		}
	}
}


add_message_cache(String: message[192], String: parsed_message[192], color_index) {
	message_cache = message;
	parsed_message_cache = parsed_message;
	cached_color_index = color_index;
}


is_message_cached(String: message[192]) {
	if (strcmp(message, message_cache) == 0) {
		return 1;
	}
	return 0;
}


clear_message_cache() {
	message_cache = "";
	parsed_message_cache = "";
	cached_color_index = -1;
}


public OnClientDisconnect(client)
{
	if (client > 0) {
		if (strcmp(game_mod, "CSS") == 0) {
			if ((ct_player_color == -1) || (client == ct_player_color)) {
				ct_player_color = -1;
				clear_message_cache();
			} else if ((ts_player_color == -1) || (client == ts_player_color)) {
				ts_player_color = -1;
				clear_message_cache();
			}
		} else if (strcmp(game_mod, "TF") == 0) {
			if ((blue_player_color == -1) || (client == blue_player_color)) {
				blue_player_color = -1;
				clear_message_cache();
			} else if ((red_player_color == -1) || (client == red_player_color)) {
				red_player_color = -1;
				clear_message_cache();
			}
		}
	}
}


color_player(color_type, player_index, String: client_message[192]) 
{
	new color_player_index = -1;
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
		decl String: client_name[192];
		GetClientName(player_index, client_name, 192);
		if (color_type == 1) {
			decl String: colored_player_name[192];
			Format(colored_player_name, 192, "\x03%s\x01", client_name);
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0) {
				return player_index;
			}
		} else {
			decl String: colored_player_name[192];
			Format(colored_player_name, 192, "\x04%s\x01", client_name);
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0) {
			}
		}
	}
	return color_player_index;
}


color_all_players(String: message[192]) 
{
	new color_index = -1;
	if (PlayerColorArray != INVALID_HANDLE) {
		ClearArray(PlayerColorArray);
		if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {

			new lowest_matching_pos = 192;
			new lowest_matching_pos_client = -1;

			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new client = i;
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					decl String: client_name[32];
					GetClientName(client, client_name, 32);
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


get_team_index(String: team_name[])
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
	ReplaceString(message, 192, "x04", "");
	ReplaceString(message, 192, "x03", "");
	ReplaceString(message, 192, "x01", "");
}


color_entities(String: message[192])
{
	ReplaceString(message, 192, "x04", "\x04");
	ReplaceString(message, 192, "x03", "\x03");
	ReplaceString(message, 192, "x01", "\x01");
}


color_team_entities(String: message[192])
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (ts_player_color > -1) {
			if (ReplaceString(message, 192, "TERRORIST", "\x03TERRORIST\x01") == 0) {
				if (ct_player_color > -1) {
					if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0) {
						return ct_player_color;
					}
				}
			} else {
				return ts_player_color;
			}
		} else {
			if (ct_player_color > -1) {
				if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0) {
					return ct_player_color;
				}
			}
		}
	} else if (strcmp(game_mod, "TF") == 0) {
		if (red_player_color > -1) {
			if (ReplaceString(message, 192, "Red", "\x03Red\x01") == 0) {
				if (blue_player_color > -1) {
					if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0) {
						return blue_player_color;
					}
				}
			} else {
				return red_player_color;
			}
		} else {
			if (blue_player_color > -1) {
				if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0) {
					return blue_player_color;
				}
			}
		}
	}
	
	return -1;
}


display_menu(player_index, time, String: full_message[1024], need_handler = 0)
{
	new String: display_message[1024];
	new offset = 0;
	new message_length = strlen(full_message); 
	for(new i = 0; i < message_length; i++) {
		if (i > 0) {
			if ((full_message[i-1] == 92) && (full_message[i] == 110)) {
				new String: buffer[1024];
				strcopy(buffer, (i - offset), full_message[offset]);
				if (strlen(display_message) == 0) {
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				} else {
					display_message[strlen(display_message)] = 10;
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				}
				i++;
				offset = i;
			}
		}
	}
	if (need_handler == 0) {
		InternalShowMenu(player_index, display_message, time);
	} else {
		InternalShowMenu(player_index, display_message, time, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), InternalMenuHandler);
	}
}


public InternalMenuHandler(Handle:menu, MenuAction:action, param1, param2)
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


public Action:hlx_sm_psay(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

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

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = (1 + ignore_param); i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > (1 + ignore_param)) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			new color_index = player_index;
			decl String: display_message[192];
			if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
				if (is_colored > 0) {
					if (is_message_cached(client_message) > 0) {
						client_message = parsed_message_cache;
						color_index = cached_color_index;
					} else {
						decl String: client_message_backup[192];
						strcopy(client_message_backup, 192, client_message);
					
						new player_color_index = color_all_players(client_message);
						if (player_color_index > -1) {
							color_index = player_color_index;
						} else {
							validate_team_colors();
							color_index = color_team_entities(client_message);
						}
						color_entities(client_message);
						add_message_cache(client_message_backup, client_message, color_index);
					}
				}
				
				if (strcmp(message_prefix, "") == 0) {
					Format(display_message, 192, "\x01%s", client_message);
				} else {
					Format(display_message, 192, "\x04%s\x01 %s", message_prefix, client_message);
				}

				new Handle:hBf;
				hBf = StartMessageOne("SayText2", player_index);
				if (hBf != INVALID_HANDLE) {
					BfWriteByte(hBf, color_index); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, display_message);
					EndMessage();
				}
			} else {
				if (strcmp(message_prefix, "") == 0) {
					Format(display_message, 192, "%s", client_message);
				} else {
					Format(display_message, 192, "%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			}
			
		}	
	}
	return Plugin_Handled;
}


public Action:hlx_sm_psay2(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_psay2 <userid><colored><message> - sends green colored private message");
		return Plugin_Handled;
	}
	
	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0) {
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0) {
		ignore_param = 1;
	}

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = (1 + ignore_param); i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > (1 + ignore_param)) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			decl String:display_message[192];
			if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "DODS") == 0) || (strcmp(game_mod, "TF") == 0)) {
				remove_color_entities(client_message);
				
				if (strcmp(message_prefix, "") == 0) {
					Format(display_message, 192, "\x04%s", client_message);
				} else {
					Format(display_message, 192, "\x04%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			} else {
				if (strcmp(message_prefix, "") == 0) {
					Format(display_message, 192, "%s", client_message);
				} else {
					Format(display_message, 192, "%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			}
		}	
	}
	return Plugin_Handled;
}


public Action:hlx_sm_csay(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_csay <message> - display center message");
		return Plugin_Handled;
	}

	new String: display_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i <= argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i, temp_argument, 192);
		if (i > 1) {
			if ((191 - strlen(display_message)) > strlen(temp_argument)) {
				display_message[strlen(display_message)] = 32;		
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		} else {
			if ((192 - strlen(display_message)) > strlen(temp_argument)) {
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		}
	}

	if (strcmp(display_message, "") != 0) {
		PrintCenterTextAll(display_message);
	}
		
	return Plugin_Handled;
}


public Action:hlx_sm_msay(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	if (strcmp(game_mod, "HL2MP") == 0) {
		return Plugin_Handled;
	}
	
	if (CheckVoteDelay() != 0) {
		return Plugin_Handled;
	}
	
	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);
	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);
	decl String: handler_param[32];
	GetCmdArg(3, handler_param, 32);
	new ignore_param = 0;
	new need_handler = 0;
	if (strcmp(handler_param, "1") == 0) {
		need_handler = 1;
		ignore_param = 1;
	}
	if (strcmp(handler_param, "0") == 0) {
		need_handler = 1;
		ignore_param = 1;
	}

	new String: client_message[1024];
	new argument_count = GetCmdArgs();
	for(new i = (3 + ignore_param); i <= argument_count; i++) {
		decl String: temp_argument[1024];
		GetCmdArg(i, temp_argument, 1024);
		if (i > (3 + ignore_param)) {
			if ((1023 - strlen(client_message)) > strlen(temp_argument)) {
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		} else {
			if ((1024 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		}
	}

	new time = StringToInt(display_time);
	if (time <= 0) {
		time = 10;
	}

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			decl String: display_message[1024];
			strcopy(display_message, 1024, client_message);
			if (strcmp(display_message, "") != 0) {
				display_menu(player_index, time, display_message, need_handler);			
			}
		}	
	}		
		
	return Plugin_Handled;
}


public Action:hlx_sm_tsay(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);
	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 2; i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > 2) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
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


public Action:hlx_sm_hint(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	if (strcmp(game_mod, "HL2MP") == 0) {
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > 1) {
			if ((191 - strlen(client_message)) > strlen(temp_argument)) {
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125)) {
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				} else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44)) {
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0)) {
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				} else {
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		} else {
			if ((192 - strlen(client_message)) > strlen(temp_argument)) {
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0)) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			PrintHintText(player_index, client_message);
		}	
	}		
			
	return Plugin_Handled;
}


public Action:hlx_sm_browse(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new String: client_url[192];

	decl String: argument_string[512];
	GetCmdArgString(argument_string, 512);

	new find_pos = StrContains(argument_string, "http://", true);
	if (find_pos == -1) {
		new argument_count = GetCmdArgs();
		for(new i = 1; i < argument_count; i++) {
			decl String: temp_argument[192];
			GetCmdArg(i+1, temp_argument, 192);
			if ((192 - strlen(client_url)) > strlen(temp_argument)) {
				strcopy(client_url[strlen(client_url)], 192, temp_argument);
			}
		}
	} else {
		strcopy(client_url, 192, argument_string[find_pos]);
		ReplaceString(client_url, 192, "\"", "");
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_url, "") != 0)) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			ShowMOTDPanel(player_index, "HLstatsX", client_url, MOTDPANEL_TYPE_URL);
		}	
	}		
			
	return Plugin_Handled;
}


public Action:hlx_sm_swap(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new client = StringToInt(client_id);
	if (client > 0) {
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (IsClientConnected(player_index)) && (IsClientInGame(player_index))) {
			swap_player(player_index)
		}
	}
	return Plugin_Handled;
}


public Action:hlx_sm_redirect(args)
{
	if (args < 3) {
		PrintToServer("Usage: hlx_sm_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	new String: server_address[192];

	new argument_count = GetCmdArgs();
	new break_address = argument_count;

	for(new i = 2; i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (strcmp(temp_argument, ":") == 0) {
			break_address = i + 1;
		} else if (i == 3) {
			break_address = i - 1;
		}
		if (i <= break_address) {
			if ((192 - strlen(server_address)) > strlen(temp_argument)) {
				strcopy(server_address[strlen(server_address)], 192, temp_argument);
			}
		}
	}	

	new String: redirect_reason[192];
	for(new i = break_address + 1; i < argument_count; i++) {
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if ((192 - strlen(redirect_reason)) > strlen(temp_argument)) {
			redirect_reason[strlen(redirect_reason)] = 32;		
			strcopy(redirect_reason[strlen(redirect_reason)], 192, temp_argument);
		}
	}	


	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(server_address, "") != 0)) {
		new player_index = GetClientOfUserId(client);
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
		
	return Plugin_Handled;
}


public Action:hlx_sm_player_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_player_action <userid><action> - trigger player action to be handled from HLstatsX");
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


public Action:hlx_sm_team_action(args)
{
	if (args < 2) {
		PrintToServer("Usage: hlx_sm_player_action <team_name><action> - trigger team action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	decl String: team_name[64];
	GetCmdArg(1, team_name, 64);

	decl String: team_action[64];
	GetCmdArg(2, team_action, 64);

	LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action); 

	return Plugin_Handled;
}


public Action:hlx_sm_world_action(args)
{
	if (args < 1) {
		PrintToServer("Usage: hlx_sm_world_action <action> - trigger world action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	decl String: world_action[64];
	GetCmdArg(1, world_action, 64);

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


public Action:hlx_block_commands(client, args)
{
	if (client) {
		if (client == 0) {
			return Plugin_Continue;
		}
		new block_chat_commands = GetConVarInt(hlx_block_chat_commands);

		decl String: user_command[192];
		GetCmdArgString(user_command, 192);

		decl String: origin_command[192];
		new start_index = 0
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
		if (strcmp(game_mod, "INSMOD") == 0 || strcmp(game_mod, "ZPS") == 0) {
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
				new command_blocked = is_command_blocked(user_command[start_index]);
				if (command_blocked > 0) {
					if ((IsClientConnected(client)) && (IsClientInGame(client))) {
						if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
							(strcmp("hlx", user_command[start_index]) == 0) ||
							(strcmp("hlstatsx", user_command[start_index]) == 0)) {
							DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
						}
						if (strcmp(game_mod, "INSMOD") == 0 || strcmp(game_mod, "ZPS") == 0) {
							log_player_event(client, command_type, user_command[start_index]);
						} else {
							log_player_event(client, command_type, origin_command);
						}
					}
					return Plugin_Handled;
				} else {
					if (strcmp(game_mod, "INSMOD") == 0 || strcmp(game_mod, "ZPS") == 0) {
						log_player_event(client, command_type, user_command[start_index]);
					}
				}
			} else {
				if ((IsClientConnected(client)) && (IsClientInGame(client))) {
					if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
						(strcmp("hlx", user_command[start_index]) == 0) ||
						(strcmp("hlstatsx", user_command[start_index]) == 0)) {
						DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
					}
				}
				if (strcmp(game_mod, "INSMOD") == 0 || strcmp(game_mod, "ZPS") == 0) {
					log_player_event(client, command_type, user_command[start_index]);
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


public Action:HLstatsX_Event_GameLog(const String: message[])
{
	if ((strcmp("", logmessage_ignore) != 0) && (StrContains(message, logmessage_ignore) != -1)) {
		if (StrContains(message, "position") == -1) {
			logmessage_ignore = "";
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}


public Action:HLstatsX_Event_PlyDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "DODS") == 0)) {
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		if ((attacker > 0) && (victim > 0)) {
			decl String: weapon[64];
			GetEventString(event, "weapon", weapon, 64);

			new suicide = 0;
			if (attacker == victim) {
				suicide = 1;
			}
			
			new player_team_index = GetClientTeam(attacker);
			decl String: player_team[64];
			player_team = team_list[player_team_index];

			decl String: player_name[32];
			if (!GetClientName(attacker, player_name, 32)) {
				strcopy(player_name, 32, "UNKNOWN");
			}

			decl String: player_authid[32];
			if (!GetClientAuthString(attacker, player_authid, 32)) {
				strcopy(player_authid, 32, "UNKNOWN");
			}

			new Float: player_origin[3];
			GetClientAbsOrigin(attacker, player_origin);

			new player_userid = GetClientUserId(attacker);

			if (suicide == 0) {

				new headshot = 0;
				new String: headshot_logentry[12] = "";
				new String: headshot_logentry_ignore[12] = "";
				if (strcmp(game_mod, "CSS") == 0) {
					headshot = GetEventBool(event, "headshot");
					if (headshot == 1) {
					 	headshot_logentry = "(headshot) ";
					 	headshot_logentry_ignore = " (headshot)";
					}
				}

				new victim_team_index = GetClientTeam(victim);
				decl String: victim_team[64];
				victim_team = team_list[victim_team_index];

				decl String: victim_name[32];
				if (!GetClientName(victim, victim_name, 32)) {
					strcopy(victim_name, 32, "UNKNOWN");
				}

				decl String: victim_authid[32];
				if (!GetClientAuthString(victim, victim_authid, 32)) {
					strcopy(victim_authid, 32, "UNKNOWN");
				}
			
				new Float: victim_origin[3];
				GetClientAbsOrigin(victim, victim_origin);

				new victim_userid = GetClientUserId(victim);
			
				Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"%s\"%s",
					player_name, player_userid, player_authid, player_team, 
					victim_name, victim_userid, victim_authid, victim_team,
					weapon, headshot_logentry_ignore);
					
				LogToGame("\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"%s\" %s(attacker_position \"%d %d %d\") (victim_position \"%d %d %d\")",
					player_name, player_userid, player_authid, player_team, 
					victim_name, victim_userid, victim_authid, victim_team,
					weapon, headshot_logentry, 
					RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), 
					RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2]));

				if (headshot == 1) {
					if (victim_team_index != player_team_index) {
						LogToGame("\"%s<%d><%s><%s>\" triggered \"headshot\"", player_name, player_userid, player_authid, player_team); 
					}
				}
			} else {
				Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" committed suicide with \"%s\"",
					player_name, player_userid, player_authid, player_team, weapon);				
				LogToGame("\"%s<%d><%s><%s>\" committed suicide with \"%s\" (attacker_position \"%d %d %d\")",
					player_name, player_userid, player_authid, player_team, weapon, 
					RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]));
			}
		}

	} else if (strcmp(game_mod, "TF") == 0) {
		new custom_kill = GetEventInt(event, "customkill");
		if (custom_kill > 0) {
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
			if ((attacker > 0) && (victim > 0)) {
				new victim_team_index = GetClientTeam(victim);
				new player_team_index = GetClientTeam(attacker);
				if (victim_team_index != player_team_index) {
					if (custom_kill == 1) {
						log_player_event(attacker, "triggered", "headshot");
					} else if (custom_kill == 2) {
						log_player_event(attacker, "triggered", "backstab");
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}


public Action: HLstatsX_Event_PlyTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((strcmp(game_mod, "CSS") == 0) || (strcmp(game_mod, "TF") == 0)) {
		new userid = GetEventInt(event, "userid");
		if (userid > 0) {
			new player_team_index = GetEventInt(event, "team");
			decl String: player_team[64];
			player_team = team_list[player_team_index];
			new player_index = GetClientOfUserId(userid);
			if (player_index > 0) {
				if (IsClientInGame(player_index)) {
					if (strcmp(game_mod, "CSS") == 0) {
						if (player_index == ct_player_color) { 
							ct_player_color = -1;
						}
						if (player_index == ts_player_color) { 
							ts_player_color = -1;
						}
					} else if (strcmp(game_mod, "TF") == 0) {
						if (player_index == blue_player_color) {
							blue_player_color = -1;
						}
						if (player_index == red_player_color) {
							red_player_color = -1;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:HLstatsX_Event_PlyBombDropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Dropped_The_Bomb", 1);
		}
	}
}


public Action:HLstatsX_Event_PlyBombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Got_The_Bomb", 1);
		}
	}
}


public Action:HLstatsX_Event_PlyBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Planted_The_Bomb", 1);
		}
	}
}


public Action:HLstatsX_Event_PlyBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Defused_The_Bomb", 1);
		}
	}
}


public Action:HLstatsX_Event_PlyHostageKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Killed_A_Hostage", 1);
		}
	}
}


public Action:HLstatsX_Event_PlyHostageResc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (strcmp(game_mod, "CSS") == 0) {
		new player   = GetClientOfUserId(GetEventInt(event, "userid"));
		if (player > 0) {
			log_player_event(player, "triggered", "Rescued_A_Hostage", 1);
		}
	}
}


public Action:HLstatsX_Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((strcmp(game_mod, "INSMOD") == 0) && (strcmp(game_mod, "AOC") == 0)) {
		new team_index = GetEventInt(event, "winner");
		decl String: winner_team[64];
		winner_team = team_list[team_index];

		// Workaround for wrong team logging within the game Insurgency
		if (strcmp(game_mod, "INSMOD") == 0) {
			switch(team_index) {
				case 1:		strcopy(winner_team, 64, "U.S. Marines");
				case 2:		strcopy(winner_team, 64, "Iraqi Insurgents");
				case 3:		strcopy(winner_team, 64, "SPECTATOR");
				default:	strcopy(winner_team, 64, "Unassigned");
			}
		}		
		new String:team_action[64] = "Round_Win";
		ServerCommand("hlx_sm_team_action %s %s", winner_team, team_action);	
	}
}


swap_player(player_index)
{
	if (strcmp(game_mod, "CSS") == 0) {
		if (IsClientConnected(player_index)) {
			new player_team_index = GetClientTeam(player_index);
			decl String: player_team[64];
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
						decl String: class_name[64];
						GetEdictClassname(weapon_entity, class_name, 64);
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
}


public CreateHLstatsXMenuMain(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXMainCommandHandler, MenuAction_Select|MenuAction_Cancel);

	if (strcmp(game_mod, "INSMOD") == 0) {
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Console Events");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
	} else {
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
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


public CreateHLstatsXMenuAuto(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXAutoCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Auto-Ranking");
	AddMenuItem(MenuHandle, "", "Enable on round-start");
	AddMenuItem(MenuHandle, "", "Enable on round-end");
	AddMenuItem(MenuHandle, "", "Enable on player death");
	AddMenuItem(MenuHandle, "", "Disable");

	SetMenuPagination(MenuHandle, 8);
}


public CreateHLstatsXMenuEvents(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXEventsCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Console Events");
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


public HLstatsXMainCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			if (strcmp(game_mod, "INSMOD") == 0) {
				switch (param2) {
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 4 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 5 : 
						make_player_command(param1, "/hlx_hideranking");
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
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 7 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 8 : 
						make_player_command(param1, "/weapons");
					case 9 : 
						make_player_command(param1, "/accuracy");
					case 10 : 
						make_player_command(param1, "/targets");
					case 11 : 
						make_player_command(param1, "/kills");
					case 12 : 
						make_player_command(param1, "/hlx_hideranking");
					case 13 : 
						make_player_command(param1, "/cheaters");
					case 14 : 
						make_player_command(param1, "/help");
				}
			}
		}
	}
}


public HLstatsXAutoCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/hlx_auto start rank");
				case 1 : 
					make_player_command(param1, "/hlx_auto end rank");
				case 2 : 
					make_player_command(param1, "/hlx_auto kill rank");
				case 3 : 
					make_player_command(param1, "/hlx_auto clear");
			}
		}
	}
}


public HLstatsXEventsCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		if (IsClientConnected(param1)) {
			switch (param2) {
				case 0 : 
					make_player_command(param1, "/hlx_display 1");
				case 1 : 
					make_player_command(param1, "/hlx_display 0");
				case 2 : 
					make_player_command(param1, "/hlx_chat 1");
				case 3 : 
					make_player_command(param1, "/hlx_chat 0");
			}
		}
	}
}
