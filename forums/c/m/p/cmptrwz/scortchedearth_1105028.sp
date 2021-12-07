#pragma semicolon 1
#include <sourcemod>

#define VERSION "0.1_wz"
// Comment this out to only affect actual commands
#define AFFECT_CVARS

public Plugin:myinfo =
{
	name = "ScortchedEarth",
	author = "devicenull",
	description = "Removes all unused commands",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new String:prefixlist[][] = {
"sm_"
,"mani_"
,"ma_"
,"es_"
,"-"
,"+"
};


new String:whitelist[][] = {
"addip"
,"autobuy"
,"banid"
,"banip"
,"bind"
,"bot_add"
,"bot_add_ct"
,"bot_all_weapons"
,"bot_allow_grenades"
,"bot_allow_machine_guns"
,"bot_allow_pistols"
,"bot_allow_rifles"
,"bot_allow_rogues"
,"bot_allow_shotguns"
,"bot_allow_snipers"
,"bot_allow_sub_machine_guns"
,"bot_auto_follow"
,"bot_auto_vacate"
,"bot_chatter"
,"bot_crouch"
,"bot_debug"
,"bot_debug_target"
,"bot_defer_to_human"
,"bot_difficulty"
,"bot_dont_shoot"
,"bot_eco_limit"
,"bot_flipout"
,"bot_freeze"
,"bot_goto_mark"
,"bot_join_after_player"
,"bot_join_delay"
,"bot_join_team"
,"bot_kick"
,"bot_kill"
,"bot_knives_only"
,"bot_loadout"
,"bot_mimic"
,"bot_pistols_only"
,"bot_prefix"
,"bot_profile_db"
,"bot_quota"
,"bot_quota_mode"
,"bot_show_battlefront"
,"bot_show_nav"
,"bot_show_occupy_time"
,"bot_snipers_only"
,"bot_stop"
,"bot_traceview"
,"bot_walk"
,"bot_zombie"
,"cl_cmdrate"
,"cl_interp"
,"cl_updaterate"
,"cvarlist"
,"disconnect"
,"dod_bonusround"
,"dod_bonusroundtime"
,"dod_enableroundwaittime"
,"dod_flagrespawnbonus"
,"dod_freezecam"
,"dod_friendlyfiresafezone"
,"dropitem"
,"echo"
,"endround"
,"exec"
,"exit"
,"find"
,"findflags"
,"fps_max"
,"heartbeat"
,"help"
,"hostname"
,"incrementvar"
,"ip"
,"kick"
,"kickid"
,"listid"
,"listip"
,"listmaps"
,"log"
,"logaddress_add"
,"logaddress_del"
,"logaddress_delall"
,"logaddress_list"
,"map"
,"mapcyclefile"
,"maps"
,"maxplayers"
,"meta"
,"mp_allowrandomclass"
,"mp_allowspectators"
,"mp_autokick"
,"mp_autoteambalance"
,"mp_buytime"
,"mp_c4timer"
,"mp_cancelwarmup"
,"mp_chattime"
,"mp_clan_ready_signal"
,"mp_clan_readyrestart"
,"mp_clan_restartround"
,"mp_decals"
,"mp_defaultteam"
,"mp_disable_autokick"
,"mp_disable_respawn_times"
,"mp_dynamicpricing"
,"mp_enableroundwaittime"
,"mp_fadetoblack"
,"mp_falldamage"
,"mp_flashlight"
,"mp_footsteps"
,"mp_forcecamera"
,"mp_forcerespawn"
,"mp_forcerespawnplayers"
,"mp_fraglimit"
,"mp_freezetime"
,"mp_friendlyfire"
,"mp_hostagepenalty"
,"mp_humanteam"
,"mp_idledealmethod"
,"mp_idlemaxtime"
,"mp_limit_allies_assault"
,"mp_limit_allies_mg"
,"mp_limit_allies_rifleman"
,"mp_limit_allies_rocket"
,"mp_limit_allies_sniper"
,"mp_limit_allies_support"
,"mp_limit_axis_assault"
,"mp_limit_axis_mg"
,"mp_limit_axis_rifleman"
,"mp_limit_axis_rocket"
,"mp_limit_axis_sniper"
,"mp_limit_axis_support"
,"mp_limitteams"
,"mp_logdetail"
,"mp_match_end_at_timelimit"
,"mp_maxrounds"
,"mp_playerid"
,"mp_playerid_delay"
,"mp_playerid_hold"
,"mp_respawnwavetime"
,"mp_restartgame"
,"mp_restartround"
,"mp_restartwarmup"
,"mp_roundtime"
,"mp_scrambleteams"
,"mp_showrespawntimes"
,"mp_spawnprotectiontime"
,"mp_stalemate_enable"
,"mp_stalemate_timelimit"
,"mp_startmoney"
,"mp_switchteams"
,"mp_teams_unbalance_limit"
,"mp_time_between_capscoring"
,"mp_timelimit"
,"mp_tkpunish"
,"mp_tournament"
,"mp_tournament_allow_non_admin_restart"
,"mp_tournament_restart"
,"mp_tournament_stopwatch"
,"mp_waitingforplayers_cancel"
,"mp_waitingforplayers_restart"
,"mp_waitingforplayers_time"
,"mp_warmup_time"
,"mp_weaponstay"
,"mp_winlimit"
,"nextlevel"
,"nextmap"
,"ping"
,"plugin_load"
,"plugin_pause"
,"plugin_pause_all"
,"plugin_print"
,"plugin_unload"
,"plugin_unpause"
,"plugin_unpause_all"
,"rate"
,"rcon_password"
,"rebuy"
,"removeid"
,"removeip"
,"restartround"
,"say"
,"say_team"
,"setmaster"
,"stats"
,"status"
,"stuffcmds"
,"sm"
,"sv_accelerate"
,"sv_airaccelerate"
,"sv_allow_voice_from_file"
,"sv_allowdownload"
,"sv_allowupload"
,"sv_alltalk"
,"sv_consistency"
,"sv_contact"
,"sv_downloadurl"
,"sv_friction"
,"sv_gravity"
,"sv_logbans"
,"sv_maxcmdrate"
,"sv_maxrate"
,"sv_maxspeed"
,"sv_maxupdaterate"
,"sv_maxvelocity"
,"sv_mincmdrate"
,"sv_minrate"
,"sv_minupdaterate"
,"sv_password"
,"sv_pausable"
,"sv_pure"
,"sv_pure_kick_clients"
,"sv_pure_trace"
,"sv_rcon_banpenalty"
,"sv_rcon_log"
,"sv_rcon_maxfailures"
,"sv_rcon_minfailures"
,"sv_rcon_minfailuretime"
,"sv_region"
,"sv_tags"
,"sv_timeout"
,"sv_turbophysics"
,"sv_visiblemaxplayers"
,"sv_voicecodec"
,"sv_voiceenable"
,"teamswitch"
,"teamswitch_death"
,"teamswitch_roundend"
,"teamswitch_spec"
,"teamswitch_version"
,"tf_arena_max_streak"
,"tf_arena_override_cap_enable_time"
,"tf_arena_preround_time"
,"tf_arena_round_time"
,"tf_arena_use_queue"
,"tf_escort_recede_time"
,"tf_escort_recede_time_overtime"
,"tf_escort_score_rate"
,"tf_flag_caps_per_round"
,"tf_tournament_classlimit_demoman"
,"tf_tournament_classlimit_engineer"
,"tf_tournament_classlimit_heavy"
,"tf_tournament_classlimit_medic"
,"tf_tournament_classlimit_pyro"
,"tf_tournament_classlimit_scout"
,"tf_tournament_classlimit_sniper"
,"tf_tournament_classlimit_soldier"
,"tf_tournament_classlimit_spy"
,"tf_tournament_hide_domination_icons"
,"tf_weapon_criticals"
,"timeleft"
,"toggle"
,"tv_allow_camera_man"
,"tv_allow_static_shots"
,"tv_autoretry"
,"tv_chatgroupsize"
,"tv_chattimelimit"
,"tv_clients"
,"tv_delay"
,"tv_delaymapchange"
,"tv_deltacache"
,"tv_dispatchmode"
,"tv_enable"
,"tv_maxclients"
,"tv_maxrate"
,"tv_msg"
,"tv_name"
,"tv_overridemaster"
,"tv_password"
,"tv_port"
,"tv_record"
,"tv_relay"
,"tv_relaypassword"
,"tv_relayvoice"
,"tv_retry"
,"tv_snapshotrate"
,"tv_status"
,"tv_stop"
,"tv_stoprecord"
,"tv_timeout"
,"tv_title"
,"tv_transmitall"
,"use"
,"user"
,"users"
,"wait"
,"writeid"
,"writeip"};

public OnPluginStart()
{
	new Handle:allowedCmds = CreateTrie();
	for (new i=0;i<sizeof(whitelist);i++)
	{
		SetTrieValue(allowedCmds,whitelist[i],1);
	}
	
	decl String:curCmd[128], bool:isCmd, val;
#if defined AFFECT_CVARS
	new Handle:cvarHandle;
#endif
	new Handle:cmdIt = FindFirstConCommand(curCmd,sizeof(curCmd),isCmd);
	do
	{
		for (new i=0;i<sizeof(prefixlist);i++)
			if (StrContains(curCmd,prefixlist[i],false) == 0)
				continue;
				
		if (!GetTrieValue(allowedCmds,curCmd,val))
		{
			if(isCmd)
			{
				SetCommandFlags(curCmd,GetCommandFlags(curCmd)|FCVAR_CHEAT);
			}
#if defined AFFECT_CVARS
			else
			{
				cvarHandle = FindConVar(curCmd);
				SetConVarFlags(cvarHandle,GetConVarFlags(cvarHandle)|FCVAR_CHEAT);
			}
#endif
		}
	} while (FindNextConCommand(cmdIt,curCmd,sizeof(curCmd),isCmd));
	
	CreateConVar("sm_scortchedversion", VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
}
