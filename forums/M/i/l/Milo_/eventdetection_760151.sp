/**
 * Application:      eventdetection.smx
 * Author:           Milo <milo@corks.nl>
 * Target platform:  Sourcemod 1.1.0 + Metamod 1.7.0 + Team Fortress 2 (20090211)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION               "1.0"
#define FLOOD_DELAY           1.0
#define EVENTNAME_MAXLEN      64


// Remove or comment this line if you dont want this plugin
// to spam eventnames in the chatbox once they trigger.
#define PRINT_INFO_TO_CHAT


// Keep this value up to date with the amount of entries
// in the allEvents array below. Currently this is 274.
#define EVENT_MAXCOUNT        274

// All the eventnames which we should try to capture.
new String:allEvents[EVENT_MAXCOUNT][EVENTNAME_MAXLEN] = {
	"ability_use", "achievement_earned", "achievement_write_failed", "alarm_trigger", 
	"ambient_play", "ammo_pickup", "area_cleared", "award_earned", "block_frozen", 
	"block_unfrozen", "bomb_abortdefuse", "bomb_abortplant", "bomb_beep", "bomb_begindefuse", 
	"bomb_beginplant", "bomb_defused", "bomb_dropped", "bomb_exploded", "bomb_pickup", 
	"bomb_planted", "boomer_exploded", "boomer_near", "bot_player_replace", "break_breakable", 
	"break_prop", "bullet_impact", "choke_end", "choke_start", "choke_stopped", 
	"create_panic_event", "ctf_flag_assist", "ctf_flag_capture", "ctf_flag_defend", 
	"ctf_flag_dominate", "ctf_flag_return", "ctf_flag_stolen", "ctf_kill_carrier", 
	"ctf_map_end", "ctf_protect_carrier", "ctf_round_start", "cyber_frag", "difficulty_changed", 
	"dod_allies_ready", "dod_axis_ready", "dod_bomb_defused", "dod_bomb_exploded", 
	"dod_bomb_planted", "dod_broadcast_audio", "dod_capture_blocked", "dod_game_over", 
	"dod_hint", "dod_kill_defuser", "dod_kill_planter", "dod_map_time_remaining", 
	"dod_point_captured", "dod_ready_restart", "dod_restart_round", "dod_round_active", 
	"dod_round_restart_seconds", "dod_round_start", "dod_round_win", "dod_stats_player_damage", 
	"dod_stats_player_killed", "dod_stats_weapon_attack", "dod_team_scores", "dod_tick_points", 
	"dod_timer_flash", "dod_timer_time_added", "dod_tnt_pickup", "dod_warmup_begins", 
	"dod_warmup_ends", "dod_win_panel", "door_close", "door_moving", "door_open", 
	"door_unlocked", "drag_begin", "drag_end", "dys_changemap", "dys_implant_stats", 
	"dys_points", "dys_scoring_stats", "dys_weapon_stats", "entity_shoved", "entity_visible", 
	"explain_bridge", "explain_church_door", "explain_crane", "explain_disturbance", 
	"explain_elevator_button", "explain_emergency_door", "explain_gas_can_panic", 
	"explain_gas_truck", "explain_lift_button", "explain_mainstreet", "explain_panic_button", 
	"explain_pills", "explain_pre_radio", "explain_radio", "explain_train_lever", 
	"explain_van_panic", "explain_weapons", "extraction_start", "extraction_stop", 
	"fatal_vomit", "finale_escape_start", "finale_radio_damaged", "finale_radio_start", 
	"finale_reportscreen", "finale_rush", "finale_start", "finale_vehicle_leaving", 
	"finale_vehicle_ready", "finale_win", "flag_return", "flashbang_detonate", "friendly_fire", 
	"game_end", "game_message", "game_newmap", "game_round_end", "game_round_restart", 
	"game_round_start", "game_squadupdate", "game_start", "gameinstructor_draw", 
	"gameinstructor_nodraw", "ghost_spawn_time", "give_weapon", "gravity_change", 
	"grenade_bounce", "heal_begin", "heal_end", "heal_interrupted", "heal_success", 
	"hegrenade_detonate", "hostage_call_for_help", "hostage_follows", "hostage_hurt", 
	"hostage_killed", "hostage_rescued", "hostage_rescued_all", "hostage_stops_following", 
	"hostname_changed", "hunter_headshot", "hunter_punched", "infected_death", "infected_hurt", 
	"iris_radio", "item_pickup", "lobby_exit", "lunge_pounce", "lunge_shove", "map_transition", 
	"material_check", "melee_kill", "mission_lost", "nav_blocked", "nav_generate", 
	"non_pistol_fired", "objective", "phase_switch", "pills_used", "pills_used_fail", 
	"player_activate", "player_afk", "player_blind", "player_blocked", "player_bot_replace", 
	"player_changeclass", "player_changename", "player_chat", "player_class", "player_connect", 
	"player_death", "player_disconnect", "player_drop", "player_entered_checkpoint", 
	"player_entered_start_area", "player_falldamage", "player_first_spawn", "player_footstep", 
	"player_grab", "player_hurt", "player_hurt_concise", "player_incapacitated", 
	"player_incapacitated_start", "player_info", "player_jump", "player_jump_apex", 
	"player_ledgegrab", "player_ledgerelease", "player_left_checkpoint", 
	"player_left_start_area", "player_location", "player_no_longer_it", "player_now_it", 
	"player_radio", "player_say", "player_score", "player_shoot", "player_shoved", 
	"player_spawn", "player_squad", "player_talking_state", "player_team", 
	"player_transitioned", "player_use", "pounce_end", "pounce_stopped", "relocated", 
	"rescue_door_open", "respawning", "revive_begin", "revive_end", "revive_success", 
	"round_end", "round_end_message", "round_freeze_end", "round_restart", "round_start", 
	"round_start_post_nav", "round_start_pre_entity", "server_addban", "server_cvar", 
	"server_msg", "server_removeban", "server_shutdown", "server_spawn", 
	"smokegrenade_detonate", "spawner_give_item", "spec_target_updated", "squad_order", 
	"started_pre_radio", "success_checkpoint_button_used", "survivor_call_for_help", 
	"survivor_rescue_abandoned", "survivor_rescued", "tank_frustrated", "tank_killed", 
	"tank_spawn", "team_info", "team_score", "tongue_broke_bent", "tongue_broke_victim_died", 
	"tongue_grab", "tongue_pull_stopped", "tongue_release", "use_target", "vip_escaped", 
	"vip_killed", "vote_cast_no", "vote_cast_yes", "vote_changed", "vote_ended", "vote_failed", 
	"vote_passed", "vote_started", "waiting_checkpoint_button_used", 
	"waiting_checkpoint_door_used", "waiting_door_used_versus", "weapon_fire", 
	"weapon_fire_at_40", "weapon_fire_on_empty", "weapon_give_duplicate_fail", 
	"weapon_given", "weapon_pickup", "weapon_reload", "weapon_zoom", "witch_harasser_set", 
	"witch_killed", "witch_spawn", "zombie_death", "zombie_ignited"
	
};

new bool:hookResult[EVENT_MAXCOUNT];

/******************************************************************
  Plugin information
******************************************************************/

public Plugin:myinfo = {
	name        = "Event detection",
	author      = "Milo",
	description = "Tries to hook a large collection of known game events, and informs plugin developers of which ones are working.",
	version     = VERSION,
	url         = "http://sourcemod.corks.nl/"
};

/******************************************************************
  Register admincommands and hook all possible events
******************************************************************/

public OnPluginStart() {
	RegAdminCmd("eventdetect_showall", CMD_ShowAll,     ADMFLAG_GENERIC, "eventdetect_showall");
	RegAdminCmd("eventdetect_show",    CMD_ShowWorking, ADMFLAG_GENERIC, "eventdetect_show");
	CreateConVar("eventdetect_version", VERSION, "Current version of the eventdetect plugin", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	for (new i = 0; i < EVENT_MAXCOUNT; i++) {
		if (strlen(allEvents[i]) > 0 && HookEventEx(allEvents[i], EventTriggered)) {
			hookResult[i] = true;
		} else {
			hookResult[i] = false;
		}
	}
}

/******************************************************************
  Handle admincommands
******************************************************************/

public Action:CMD_ShowAll(client, args) {
  showList(client, true);
  return Plugin_Handled;
}

public Action:CMD_ShowWorking(client, args) {
  showList(client, false);
  return Plugin_Handled;
}

/******************************************************************
  Handle triggered event
******************************************************************/

public EventTriggered(Handle:event, const String:name[], bool:dontBroadcast) {
	PrintToServer( "[DEV-ED] Event <%s> triggered.", name);
#if defined PRINT_INFO_TO_CHAT
	PrintToChatAll("[DEV-ED] Event <%s> triggered.", name);
#endif
}

/******************************************************************
  Function to send results to clients' console
******************************************************************/

new ListTransmit[MAXPLAYERS+1][3]; // index 0=offset, 1=size, 2=showall

showList(client, bool:showall) {
	new String:eventState[16];
	new const transmSize = 10;
	new linesPrinted     =  0;
	new bool:timerStarted = false;
	if (ListTransmit[client][0] == 0) {
		if (showall) PrintToConsole(client, "[DEV-ED] Listing status for all known events:");
		else         PrintToConsole(client, "[DEV-ED] Listing status for all hooked events:");
		PrintToConsole(client, "[DEV-ED] -----------------------------------------------------------");
		ListTransmit[client][1] = EVENT_MAXCOUNT;
		ListTransmit[client][2] = (showall ? 1 : 0);
	}
	for (new i = ListTransmit[client][0]; i < ListTransmit[client][1]; i++) if (strlen(allEvents[i]) > 0) {
		if (showall && hookResult[i])       eventState = "Hooked";
		else if (showall && !hookResult[i]) eventState = "Failure";
		else                                eventState = "";
		if (showall || hookResult[i]) {
			PrintToConsole(client, "[DEV-ED] %3d. %-64s  %-16s", i+1, allEvents[i], eventState);
			linesPrinted++;
		}
		if (linesPrinted >= transmSize) {
			ListTransmit[client][0] = i+1;
			CreateTimer(FLOOD_DELAY, SendNextListSegment, client);
			timerStarted = true;
			break;
		}
	}
	if (!timerStarted) {
		PrintToConsole(client, "[DEV-ED] -----------------------------------------------------------");
		ListTransmit[client][0] = 0;
	}
}

public Action:SendNextListSegment(Handle:timer, any:client) {
  showList(client, (ListTransmit[client][2] > 0));
}