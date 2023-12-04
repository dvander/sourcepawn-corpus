#define PLUGIN_VERSION "1.4"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define SAY_EVENT_LOG	 "logs\\say_event.log"

#define CHAT 0

ConVar g_Event;
bool g_l4d1, block;
int g_iCvarEnable;
char logfilepath[PLATFORM_MAX_PATH], Map[64];

public Plugin myinfo = 
{
    name = "[L4D1 & L4D2] Say Event",
    author = "disawar1 [raziEiL] (fork by Dragokas)",
    description = "Displays triggered events.",
    version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	BuildPath(Path_SM, logfilepath, sizeof(logfilepath), SAY_EVENT_LOG);
	LogTo("+-------------------------------------------+");
	LogTo("|               PLUGIN START                |");
	LogTo("+-------------------------------------------+");
	
	CreateConVar("say_event_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_Event = CreateConVar("say_event_enable", "1", "Log Events: 0=Disable, 1=Enable", FCVAR_NOTIFY);
	AutoExecConfig(true, "say_event");
	
	g_Event.AddChangeHook(OnCVarChange);
	Init();
}

public void OnCVarChange(ConVar convar_hndl, const char[] oldValue, const char[] newValue)
{
	Init();
}

public void OnMapStart()
{
	LogTo("+-------------------------------------------+");
	LogTo("|                  MAP START                |");
	LogTo("+-------------------------------------------+");
	GetCurrentMap(Map, 64);
	LogTo("| \"%s\" |", Map);
}

public void OnMapEnd()
{
	GetCurrentMap(Map, 64);
	LogTo("| \"%s\" |", Map);
	LogTo("+-------------------------------------------+");
	LogTo("|                  MAP END                  |");
	LogTo("+-------------------------------------------+");
}

public void ClientEvents(Event event, const char[] name, bool dontBroadcast)
{
	int client, team;
	char sName[64];
	int UserId = event.GetInt("userid");
	if( UserId != 0 )
	{
		client = GetClientOfUserId(UserId);
		if( client && IsClientInGame(client) )
		{
			team = GetClientTeam(client);
			GetClientName(client, sName, sizeof(sName));
		}
		LogEvent("EVENT_HAPPENED ---> \"%s\". Client: %i (%s). Team: %i", name, client, sName, team);
	}
}

public void EventCallbackPost(Event event, const char[] name, bool dontBroadcast)
{
	LogEvent("EVENT_HAPPENED :: (POST) :: \"%s\"", name);
}

public void EventCallbackPre(Event event, const char[] name, bool dontBroadcast)
{
	LogEvent("EVENT_HAPPENED :: (Pre ) :: \"%s\"", name);
}

void ReportEntityTotal()
{
	LogTo("{Total entities}");
	int ent = -1, cnt = 0;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		cnt++;
	}
	LogTo("All: %i", cnt);
	LogTo("Networked: %i", GetEntityCount());
}

void ReportClientWeapon()
{
	LogTo("{Survivors}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
			if( IsPlayerAlive(i))
			{
				WeaponInfo(i);
			}
		}
	}
	LogTo("{Spectators}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 1 )
		{
			LogTo("%i. %N", i, i);
		}
	}
	LogTo("{Infected}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
		}
	}
}

public void Event_Round_End(Handle event, const char[] name, bool dontBroadcast)
{
	LogTo("[Entity report]");

	ReportEntityTotal();
	GetPrecacheInfo();
	ReportClientWeapon();
	ReportSafeRoomEntity();
}

void ReportSafeRoomEntity()
{
	LogTo("{Nearby entities} - within 300.0 units");
	
	//find mediane point
	float mediane[3], pos[3];
	char sClass[64];
	int cnt = 0;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			GetClientAbsOrigin(i, pos);
			mediane[0] += pos[0];
			mediane[1] += pos[1];
			mediane[2] += pos[2];
			cnt++;
		}
	}
	mediane[0] /= cnt;
	mediane[1] /= cnt;
	mediane[2] /= cnt;
	const float MAXDIST = 300.0;
	float dist;
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			if( HasEntProp(ent, Prop_Data, "m_vecOrigin"))
			{
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
				dist = GetVectorDistance(pos, mediane);
				if( dist <= MAXDIST )
				{
					GetEntityClassname(ent, sClass, sizeof(sClass));
					LogTo("%s. dist = %f%s", sClass, dist, IsInSafeRoom(ent) ? " (IN SAFEROOM)" : "");
				}
			}
		}
	}
}

void WeaponInfo(int client)
{
	int weapon;
	char sName[32];
	for( int i = 0; i < 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(client, i);
		
		if( weapon == -1 )
		{
			LogTo("Slot #%i: EMPTY", i);
		}
		else {
			GetEntityClassname(weapon, sName, sizeof(sName));
			LogTo("Slot #%i: %s", i, sName);
		}
	}
}

void HookEventAll(char[] name)
{
	HookEvent(name, EventCallbackPost, EventHookMode_PostNoCopy);
	HookEvent(name, EventCallbackPre, EventHookMode_Pre);
}

void HookCommon()
{
	HookEvent("map_transition", Event_Round_End, EventHookMode_Pre);
	HookEvent("player_disconnect", ClientEvents, EventHookMode_Pre);
	
	HookEventAll("round_end");
	HookEventAll("ability_use");
	HookEventAll("achievement_earned");
	HookEventAll("achievement_event");
	HookEventAll("achievement_write_failed");
	HookEventAll("ammo_pickup");
	HookEventAll("area_cleared");
	HookEventAll("award_earned");
	HookEventAll("bonus_updated");
	HookEventAll("boomer_exploded");
	HookEventAll("boomer_near");
	HookEventAll("bot_player_replace");
	HookEventAll("break_breakable");
	HookEventAll("break_prop");
	//HookEventAll("bullet_impact"); // because too often
	HookEventAll("choke_end");
	HookEventAll("choke_start");
	HookEventAll("choke_stopped");
	HookEventAll("create_panic_event");
	HookEventAll("difficulty_changed");
	HookEventAll("door_close");
	HookEventAll("door_moving");
	HookEventAll("door_open");
	HookEventAll("door_unlocked");
	HookEventAll("drag_begin");
	HookEventAll("drag_end");
	HookEventAll("entity_killed");
	HookEventAll("entity_shoved");
	HookEventAll("entity_visible");
	HookEventAll("explain_bridge");
	HookEventAll("explain_church_door");
	HookEventAll("explain_crane");
	HookEventAll("explain_disturbance");
	HookEventAll("explain_elevator_button");
	HookEventAll("explain_emergency_door");
	HookEventAll("explain_gas_can_panic");
	HookEventAll("explain_gas_truck");
	HookEventAll("explain_lift_button");
	HookEventAll("explain_mainstreet");
	HookEventAll("explain_panic_button");
	HookEventAll("explain_pills");
	HookEventAll("explain_pre_radio");
	HookEventAll("explain_radio");
	HookEventAll("explain_train_lever");
	HookEventAll("explain_van_panic");
	HookEventAll("explain_weapons");
	HookEventAll("fatal_vomit");
	HookEventAll("final_reportscreen");
	HookEventAll("finale_escape_start");
	HookEventAll("finale_radio_damaged");
	HookEventAll("finale_radio_start");
	HookEventAll("finale_rush");
	HookEventAll("finale_start");
	HookEventAll("finale_vehicle_leaving");
	HookEventAll("finale_vehicle_ready");
	HookEventAll("finale_win");
	HookEventAll("flare_ignite_npc");
	HookEventAll("friendly_fire");
	HookEventAll("game_end");
	HookEventAll("game_init");
	HookEventAll("game_message");
	HookEventAll("game_newmap");
	HookEventAll("game_start");
	HookEventAll("gameinstructor_draw");
	HookEventAll("gameinstructor_nodraw");
	HookEventAll("ghost_spawn_time");
	HookEventAll("give_weapon");
	HookEventAll("grenade_bounce");
	HookEventAll("heal_begin");
	HookEventAll("heal_end");
	HookEventAll("heal_interrupted");
	HookEventAll("heal_success");
	HookEventAll("hegrenade_detonate");
	HookEventAll("helicopter_grenade_punt_miss");
	HookEventAll("hostname_changed");
	HookEventAll("hunter_headshot");
	HookEventAll("hunter_punched");
	HookEventAll("infected_death");
	HookEventAll("infected_hurt");
	HookEventAll("item_pickup");
	HookEventAll("lunge_pounce");
	HookEventAll("lunge_shove");
	HookEventAll("map_transition");
	HookEventAll("melee_kill");
	HookEventAll("mission_lost");
	HookEventAll("nav_blocked");
	HookEventAll("nav_generate");
	HookEventAll("non_pistol_fired");
	HookEventAll("physgun_pickup");
	HookEventAll("pills_used");
	HookEventAll("pills_used_fail");
	HookEventAll("player_activate");
	HookEventAll("player_afk");
	HookEventAll("player_blind");
	HookEventAll("player_blocked");
	HookEventAll("player_bot_replace");
	HookEventAll("player_changename");
	HookEventAll("player_chat");
	HookEventAll("player_class");
	HookEventAll("player_connect");
	HookEventAll("player_death");
	HookEventAll("player_entered_checkpoint");
	HookEventAll("player_entered_start_area");
	HookEventAll("player_falldamage");
	HookEventAll("player_first_spawn");
	HookEventAll("player_footstep");
	HookEventAll("player_hurt");
	HookEventAll("player_hurt_concise");
	HookEventAll("player_incapacitated");
	HookEventAll("player_incapacitated_start");
	HookEventAll("player_info");
	HookEventAll("player_jump");
	HookEventAll("player_jump_apex");
	HookEventAll("player_ledge_grab");
	HookEventAll("player_ledge_release");
	HookEventAll("player_left_checkpoint");
	HookEventAll("player_left_start_area");
	HookEventAll("player_no_longer_it");
	HookEventAll("player_now_it");
	HookEventAll("player_say");
	HookEventAll("player_score");
	HookEventAll("player_shoot");
	HookEventAll("player_shoved");
	HookEventAll("player_spawn");
	HookEventAll("player_talking_state");
	HookEventAll("player_team");
	HookEventAll("player_transitioned");
	HookEventAll("player_use");
	HookEventAll("pounce_end");
	HookEventAll("pounce_stopped");
	HookEventAll("ragdoll_dissolved");
	HookEventAll("relocated");
	HookEventAll("rescue_door_open");
	HookEventAll("respawning");
	HookEventAll("revive_begin");
	HookEventAll("revive_end");
	HookEventAll("revive_success");
	HookEventAll("round_end_message");
	HookEventAll("round_freeze_end");
	HookEventAll("round_start");
	HookEventAll("round_start_post_nav");
	HookEventAll("round_start_pre_entity");
	HookEventAll("server_addban");
	HookEventAll("server_cvar");
	HookEventAll("server_removeban");
	HookEventAll("server_shutdown");
	HookEventAll("server_spawn");
	HookEventAll("spawner_give_item");
	HookEventAll("spec_target_updated");
	HookEventAll("started_pre_radio");
	HookEventAll("success_checkpoint_button_used");
	HookEventAll("survival_at_30min");
	HookEventAll("survivor_call_for_help");
	HookEventAll("survivor_rescue_abandoned");
	HookEventAll("survivor_rescued");
	HookEventAll("tank_frustrated");
	HookEventAll("tank_killed");
	HookEventAll("tank_spawn");
	HookEventAll("team_info");
	HookEventAll("team_score");
	HookEventAll("tongue_broke_bent");
	HookEventAll("tongue_grab");
	HookEventAll("tongue_pull_stopped");
	HookEventAll("tongue_release");
	HookEventAll("use_target");
	HookEventAll("user_data_downloaded");
	HookEventAll("vote_cast_no");
	HookEventAll("vote_cast_yes");
	HookEventAll("vote_changed");
	HookEventAll("vote_ended");
	HookEventAll("vote_failed");
	HookEventAll("vote_passed");
	HookEventAll("vote_started");
	HookEventAll("waiting_checkpoint_button_used");
	HookEventAll("waiting_checkpoint_door_used");
	HookEventAll("waiting_door_used_versus");
	//HookEventAll("weapon_fire"); // because too often
	HookEventAll("weapon_fire_at_40");
	HookEventAll("weapon_fire_on_empty");
	HookEventAll("weapon_given");
	HookEventAll("weapon_pickup");
	HookEventAll("weapon_reload");
	//HookEventAll("weapon_zoom"); // too many
	HookEventAll("witch_harasser_set");
	HookEventAll("witch_killed");
	HookEventAll("witch_spawn");
	HookEventAll("zombie_ignited");
	
	if (GetEngineVersion() == Engine_Left4Dead)
	{
		HookEventAll("tongue_broke_victim_died");
		HookEventAll("weapon_give_duplicate_fail");
	}
}


void HookL4D2()
{
	HookEventAll("ability_out_of_range");
	//HookEventAll("achievement_increment");
	HookEventAll("adrenaline_used");
	//HookEventAll("alarm_trigger");
	HookEventAll("ammo_pack_used");
	HookEventAll("ammo_pack_used_fail_doesnt_use_ammo");
	HookEventAll("ammo_pack_used_fail_full");
	HookEventAll("ammo_pack_used_fail_no_weapon");
	HookEventAll("ammo_pile_weapon_cant_use_ammo");
	HookEventAll("begin_scavenge_overtime");
	HookEventAll("c1m4_scavenge_instructions");
	HookEventAll("chair_charged");
	HookEventAll("charger_carry_end");
	HookEventAll("charger_carry_start");
	HookEventAll("charger_charge_end");
	HookEventAll("charger_charge_start");
	HookEventAll("charger_impact");
	HookEventAll("charger_killed");
	HookEventAll("charger_pummel_end");
	HookEventAll("charger_pummel_start");
	HookEventAll("dead_survivor_visible");
	HookEventAll("defibrillator_begin");
	HookEventAll("defibrillator_interrupted");
	HookEventAll("defibrillator_used");
	HookEventAll("defibrillator_used_fail");
	HookEventAll("entered_spit");
	HookEventAll("explain_bodyshots_reduced");
	HookEventAll("explain_burger_sign");
	HookEventAll("explain_c1m4_finale");
	HookEventAll("explain_c2m4_ticketbooth");
	HookEventAll("explain_c3m4_radio1");
	HookEventAll("explain_c3m4_radio2");
	HookEventAll("explain_c3m4_rescue");
	HookEventAll("explain_c6m3_finale");
	HookEventAll("explain_carousel_button");
	HookEventAll("explain_carousel_destination");
	HookEventAll("explain_coaster");
	HookEventAll("explain_coaster_stop");
	HookEventAll("explain_deactivate_alarm");
	HookEventAll("explain_decon");
	HookEventAll("explain_decon_wait");
	HookEventAll("explain_drawbridge");
	HookEventAll("explain_ferry_button");
	HookEventAll("explain_float");
	HookEventAll("explain_gates_are_open");
	HookEventAll("explain_gun_shop");
	HookEventAll("explain_gun_shop_tanker");
	HookEventAll("explain_hatch_button");
	HookEventAll("explain_hotel_elevator_doors");
	HookEventAll("explain_impound_lot");
	HookEventAll("explain_item_glows_disabled");
	HookEventAll("explain_mall_alarm");
	HookEventAll("explain_mall_window");
	HookEventAll("explain_need_gnome_to_continue");
	HookEventAll("explain_perimeter");
	HookEventAll("explain_pre_drawbridge");
	HookEventAll("explain_rescue_disabled");
	HookEventAll("explain_return_item");
	HookEventAll("explain_save_items");
	HookEventAll("explain_scavenge_goal");
	HookEventAll("explain_scavenge_leave_area");
	HookEventAll("explain_sewer_gate");
	HookEventAll("explain_sewer_run");
	HookEventAll("explain_shack_button");
	HookEventAll("explain_stage_finale_start");
	HookEventAll("explain_stage_lighting");
	HookEventAll("explain_stage_pyrotechnics");
	HookEventAll("explain_stage_survival_start");
	HookEventAll("explain_store_alarm");
	HookEventAll("explain_store_item");
	HookEventAll("explain_store_item_stop");
	HookEventAll("explain_survival_alarm");
	HookEventAll("explain_survival_carousel");
	HookEventAll("explain_survival_generic");
	HookEventAll("explain_survival_radio");
	HookEventAll("explain_survivor_glows_disabled");
	HookEventAll("explain_vehicle_arrival");
	HookEventAll("explain_witch_instant_kill");
	//HookEventAll("extraction_start");
	//HookEventAll("extraction_stop");
	HookEventAll("finale_bridge_lowering");
	HookEventAll("finale_vehicle_incoming");
	HookEventAll("foot_locker_opened");
	//HookEventAll("game_round_end");
	//HookEventAll("game_round_restart");
	//HookEventAll("game_round_start");
	HookEventAll("gas_can_forced_drop");
	HookEventAll("gascan_dropped");
	HookEventAll("gascan_pour_blocked");
	HookEventAll("gascan_pour_completed");
	HookEventAll("gascan_pour_interrupted");
	HookEventAll("gauntlet_finale_start");
	HookEventAll("infected_decapitated");
	//HookEventAll("iris_radio");
	HookEventAll("jockey_killed");
	HookEventAll("jockey_ride");
	HookEventAll("jockey_ride_end");
	HookEventAll("m60_streak_ended");
	//HookEventAll("material_check");
	HookEventAll("molotov_thrown");
	HookEventAll("mounted_gun_overheated");
	HookEventAll("mounted_gun_start");
	HookEventAll("non_melee_fired");
	HookEventAll("panic_event_finished");
	//HookEventAll("player_location");
	HookEventAll("punched_clown");
	HookEventAll("receive_upgrade");
	HookEventAll("request_weapon_stats");
	HookEventAll("scavenge_gas_can_destroyed");
	HookEventAll("scavenge_match_finished");
	HookEventAll("scavenge_round_finished");
	HookEventAll("scavenge_round_halftime");
	HookEventAll("scavenge_round_start");
	HookEventAll("scavenge_score_tied");
	//HookEventAll("server_msg");
	HookEventAll("set_instructor_group_enabled");
	HookEventAll("song_played");
	HookEventAll("spit_burst");
	HookEventAll("spitter_killed");
	HookEventAll("start_score_animation");
	HookEventAll("stashwhacker_game_won");
	HookEventAll("strongman_bell_knocked_off");
	HookEventAll("survival_round_start");
	HookEventAll("temp_c4m1_getgas");
	HookEventAll("temp_c4m3_return_to_boat");
	HookEventAll("total_ammo_below_40");
	HookEventAll("triggered_car_alarm");
	HookEventAll("upgrade_explosive_ammo");
	HookEventAll("upgrade_failed_no_primary");
	HookEventAll("upgrade_incendiary_ammo");
	HookEventAll("upgrade_item_already_used");
	HookEventAll("upgrade_pack_added");
	HookEventAll("upgrade_pack_begin");
	HookEventAll("upgrade_pack_used");
	HookEventAll("versus_marker_reached");
	HookEventAll("versus_match_finished");
	HookEventAll("versus_round_start");
	HookEventAll("vomit_bomb_tank");
	HookEventAll("weapon_drop");
	HookEventAll("weapon_spawn_visible");
}

public void Init()
{
	g_iCvarEnable = g_Event.IntValue;
	
	g_l4d1 = (GetEngineVersion() == Engine_Left4Dead);
	
	if (block == false && g_iCvarEnable == 1){
	
		block = true;
		
		if (g_l4d1)
		{
 			HookCommon();
		}
		else {
			HookCommon();
			HookL4D2();
		}
	}
}

void GetPrecacheInfo()
{
	int iTable = FindStringTable("modelprecache");
	if( iTable != INVALID_STRING_TABLE )
	{
		int iNum = GetStringTableNumStrings(iTable);
		LogTo("{Cached} model count: %i", iNum);
	}
}

public void OnAllPluginsLoaded()
{
	LogForward("{Forward} OnAllPluginsLoaded");
}

public void OnAutoConfigsBuffered()
{
	LogForward("{Forward} OnAutoConfigsBuffered");
}

public bool OnClientFloodCheck(int client)
{
	LogForward("{Forward} OnClientFloodCheck. Client: %i", client);
}

public void OnClientFloodResult(int client, bool blocked)
{
	LogForward("{Forward} OnClientFloodResult. Client: %i. Blocked: %b", client, blocked);
}

public void OnConfigsExecuted()
{
	LogForward("{Forward} OnConfigsExecuted");
}

public void OnClientAuthorized(int client, const char[] auth)
{
	LogForward("{Forward} OnClientAuthorized. Client: %i, %s", client, auth);
}

public Action OnClientCommand(int client, int args)
{
	LogForward("{Forward} OnClientCommand. Client: %i. Args: %i", client, args);
	return Plugin_Continue;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	LogForward("{Forward} OnClientCommandKeyValues. Client: %i", client);
	return Plugin_Continue;
}

public void OnClientCommandKeyValues_Post(int client, KeyValues kv)
{
	LogForward("{Forward} OnClientCommandKeyValues_Post. Client: %i", client);
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	LogForward("{Forward} OnClientConnect. Client: %i", client);
	return true;
}

public void OnClientConnected(int client)
{
	LogForward("{Forward} OnClientConnected. Client: %i", client);
}

public void OnClientDisconnect(int client)
{
	LogForward("{Forward} OnClientDisconnect. Client: %i. InGame? %b", client, client && IsClientInGame(client));
}

public void OnClientDisconnect_Post(int client)
{
	LogForward("{Forward} OnClientDisconnect_Post. Client: %i", client);
}

public void OnClientPostAdminCheck(int client)
{
	LogForward("{Forward} OnClientPostAdminCheck. Client: %i", client);
}

public void OnClientPostAdminFilter(int client)
{
	LogForward("{Forward} OnClientPostAdminFilter. Client: %i", client);
}

public Action OnClientPreAdminCheck(int client)
{
	LogForward("{Forward} OnClientPreAdminCheck. Client: %i", client);
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	LogForward("{Forward} OnClientPutInServer. Client: %i (%N), team: %i", client, client, GetClientTeam(client));
}

public void OnClientSettingsChanged(int client)
{
	LogForward("{Forward} OnClientSettingsChanged. Client: %i", client);
}

/*
public void OnGameFrame()
{
}*/

public void OnLibraryAdded(const char[] name)
{
	LogForward("{Forward} OnLibraryAdded. Name: %s", name);
}

public void OnLibraryRemoved(const char[] name)
{
	LogForward("{Forward} OnLibraryRemoved. Name: %s", name);
}

public void OnPluginEnd()
{
	LogForward("{Forward} OnPluginEnd");
}

public void OnPluginPauseChange(bool pause)
{
	LogForward("{Forward} OnPluginPauseChange. Pause: %b", pause);
}

/*
public void OnServerCfg() // replaced by => OnConfigsExecuted()
{
	LogForward("{Forward} OnServerCfg");
}*/

public void OnClientCookiesCached(int client)
{
	LogForward("{Forward} OnClientCookiesCached. Client: %i", client);
}

public void OnClientSpeaking(int client)
{
	LogForward("{Forward} OnClientSpeaking. Client: %i", client);
}

public void OnClientSpeakingEnd(int client)
{
	LogForward("{Forward} OnClientSpeakingEnd. Client: %i", client);
}

void LogEvent(const char[] format, any ...)
{
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogTo(buffer);
}

void LogForward(const char[] format, any ...)
{
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogTo(buffer);
}

void LogTo(const char[] format, any ...)
{
	if( g_iCvarEnable == 0 )
		return;
	
	static char buffer[192];
	VFormat(buffer, sizeof(buffer), format, 2);
	#if CHAT
		PrintToChatAll(buffer);
	#endif
	//PrintToServer(buffer);
	//static char sTime[64];
	//FormatTime(sTime, sizeof(sTime), "%F, %X", GetTime());
	//LogToFileEx(logfilepath, "%s - %s", sTime, buffer);
	
	Format(buffer, sizeof(buffer), "%.2f : %s", GetSysTickCount() / 1000.0, buffer);
	LogToFileEx(logfilepath, buffer);
}

bool IsInSafeRoom(int entity)
{
	int chl = -1;
	chl = FindEntityByClassname(-1, "info_changelevel");
	if (chl == -1)
	{
		chl = FindEntityByClassname(-1, "trigger_changelevel");
		if (chl == -1)
			return false;
	}
	
	float min[3], max[3], pos[3], me[3], maxme[3];

	GetEntPropVector(chl, Prop_Send, "m_vecMins", min);
	GetEntPropVector(chl, Prop_Send, "m_vecMaxs", max);
	
	// zone expanding by Y-axis
	min[2] -= 15.0;
	max[2] += 40.0;
	
	GetEntPropVector(chl, Prop_Send, "m_vecOrigin", pos);
	
	AddVectors(min, pos, min);
	AddVectors(max, pos, max);
	
	if( HasEntProp(entity, Prop_Send, "m_vecOrigin") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", me);
	}
	else {
		return false;
	}
	
	char g_sMap[64];
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	if (strcmp(g_sMap, "l4d_smalltown03_ranchhouse") == 0)
	{
		if (me[0] > -2442.0 && (175.0 < me[2] < 200.0) )
			return false;
	}
	else if (strcmp(g_sMap, "l4d_smalltown04_mainstreet") == 0)
	{
		max[2] += 20.0;
	}
	
	if( HasEntProp(entity, Prop_Send, "m_vecMaxs") )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxme);
	}
	else {
		return false;
	}
	
	AddVectors(maxme, me, maxme);
	
	return IsDotInside(me, min, max) && maxme[2] < max[2];
}

bool IsDotInside(float dot[3], float min[3], float max[3])
{
	if(	min[0] < dot[0] < max[0] &&
		min[1] < dot[1] < max[1] &&
		min[2] < dot[2] < max[2]) {
		return true;
	}
	return false;
}