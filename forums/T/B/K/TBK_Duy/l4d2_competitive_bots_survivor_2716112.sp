public OnPluginStart()
{
	CreateTimer(10.0, Competitive, _, TIMER_FLAG_NO_MAPCHANGE);
	RegConsoleCmd("sm_cb", ConfigBot, "Config the bot");
}

public OnMapStart()
{
	Config();
}

public Action:Competitive(Handle:Timer)
{
	Config();
}

public Action ConfigBot(client, args) 
{
	Config();
	return Plugin_Handled;
}
 
Config()
{
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	SetConVarInt(FindConVar("sb_debug_apoproach_wait_time"), 0);
	SetConVarInt(FindConVar("sb_allow_shoot_through_survivors"), 1);
	SetConVarInt(FindConVar("sb_escort"), 0); 
	SetConVarInt(FindConVar("sb_all_bot_game"), 1); 
	SetConVarInt(FindConVar("sb_battlestation_give_up_range_from_human"), 100);
	SetConVarInt(FindConVar("sb_max_battlestation_range_from_human"), 300);
	SetConVarInt(FindConVar("sb_battlestation_human_hold_time"), 0);
	SetConVarInt(FindConVar("sb_close_checkpoint_door_interval"), 1);
	SetConVarInt(FindConVar("sb_enforce_proximity_lookat_timeout"), 0);
	SetConVarInt(FindConVar("sb_follow_stress_factor"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_hard"), 0);
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_normal"), 0);
	SetConVarInt(FindConVar("sb_locomotion_wait_threshold"), 0);
	SetConVarInt(FindConVar("sb_max_scavenge_separation"), 1000);
	SetConVarInt(FindConVar("sb_min_orphan_time_to_cover"), 0);
	SetConVarInt(FindConVar("sb_neighbor_range"), 100);
	SetConVarInt(FindConVar("sb_normal_saccade_speed"), 9999);
	SetConVarInt(FindConVar("sb_combat_saccade_speed"), 9999);
	SetConVarInt(FindConVar("sb_path_lookahead_range"), 9999);
	SetConVarInt(FindConVar("sb_near_hearing_range"), 9999);
	SetConVarInt(FindConVar("sb_pushscale"), 0);
	SetConVarInt(FindConVar("sb_reachability_cache_lifetime"), 0);
	SetConVarInt(FindConVar("sb_rescue_vehicle_loading_range"), 50);
	SetConVarInt(FindConVar("sb_separation_danger_max_range"), 300);
	SetConVarInt(FindConVar("sb_separation_danger_min_range"), 100);
	SetConVarInt(FindConVar("sb_separation_range"), 150);
	SetConVarInt(FindConVar("sb_sidestep_for_horde"), 0);
	SetConVarInt(FindConVar("sb_threat_exposure_stop"), 2147483646);
	SetConVarInt(FindConVar("sb_threat_exposure_walk"), 2147483647);
	SetConVarInt(FindConVar("sb_far_hearing_range"), 2147483647);
	SetConVarInt(FindConVar("sb_threat_very_far_range"), 2147483647);
	SetConVarInt(FindConVar("sb_threat_very_close_range"), 1000);
	SetConVarInt(FindConVar("sb_close_threat_range"), 1000);
	SetConVarInt(FindConVar("sb_threat_close_range"), 1000);
	SetConVarInt(FindConVar("sb_threat_medium_range"), 5000);
	SetConVarInt(FindConVar("sb_threat_far_range"), 9999);
	SetConVarInt(FindConVar("sb_vomit_blind_time"), 0);
	new flags=GetCommandFlags("sb_force_max_intensity");
	SetCommandFlags("sb_force_max_intensity", flags & ~FCVAR_CHEAT);

	ServerCommand("sb_force_max_intensity Coach");
	ServerCommand("sb_force_max_intensity Ellis");
	ServerCommand("sb_force_max_intensity Rochelle");
	ServerCommand("sb_force_max_intensity Nick");
	ServerCommand("sb_force_max_intensity Bill");
	ServerCommand("sb_force_max_intensity Louis");
	ServerCommand("sb_force_max_intensity Francis");
	ServerCommand("sb_force_max_intensity Zoey");
} 
 
stock UnlockConsoleCommandAndConvar(const String:command[])
{
    new flags = GetCommandFlags(command);
    if (flags != INVALID_FCVAR_FLAGS)
    {
        SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    }
    
    new Handle:cvar = FindConVar(command);
    if (cvar != INVALID_HANDLE)
    {
        flags = GetConVarFlags(cvar);
        SetConVarFlags(cvar, flags & ~FCVAR_CHEAT);
    }
}