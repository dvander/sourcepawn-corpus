#pragma	semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

Config()
{
	//default value 5 - How long a SurvivorBot (sb_) waits once it reaches its debug move-to spot:
	SetConVarInt(FindConVar("sb_debug_apoproach_wait_time"), 0);
	//default value 0 - Allow a team of nothing but bots:
	SetConVarInt(FindConVar("sb_all_bot_team"), 1);
	//default value 1500 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_battlestation_give_up_range_from_human"), 100);
	//default value 4 - How long the nearest human must hold their place before SurvivorBots will re-evaluate their Battlestations
	SetConVarFloat(FindConVar("sb_battlestation_human_hold_time"), 0.25);
	//default value 2 - No other information on this from Valve:
	SetConVarFloat(FindConVar("sb_close_checkpoint_door_interval"), 0.15);
	//default value 1000 - No information on this from Valve:
	SetConVarInt(FindConVar("sb_combat_saccade_speed"), 9999);
	//default value 10 - No other information on this from Valve:
	SetConVarFloat(FindConVar("sb_enforce_proximity_lookat_timeout"), 0.0);
	//default value 1500 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_enforce_proximity_range"), 1000);
	//default value 0.5 - No other information on this from Valve:
	SetConVarFloat(FindConVar("sb_follow_stress_factor"), 1.0);
	//default value 0.5 - How quickly a SurvivorBot realizes a friend has been Pounced or Tongued
	SetConVarFloat(FindConVar("sb_friend_immobilized_reaction_time_expert"), 0);
	//default value 1.0 - How quickly a SurvivorBot realizes a friend has been Pounced or Tongued
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_hard"), 0);	
	//default value 2.0 - How quickly a SurvivorBot realizes a friend has been Pounced or Tongued
	SetConVarInt(FindConVar("sb_friend_immobilized_reaction_time_normal"), 0);
	//default value 0.5 - How quickly a SurvivorBot realizes a friend has been Pounced or Tongued in versus
	SetConVarFloat(FindConVar("sb_friend_immobilized_reaction_time_vs"), 0);
	//default value 0 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_reachable_cache_paranoia"), 0);
	//default value 10 - No other information on this from Valve:
	SetConVarFloat(FindConVar("sb_locomotion_wait_threshold"), 0.0);
	//default value 1000 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_use_button_range"), 1000);
	//default value 750 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_max_battlestation_range_from_human"), 300);
	//default value 750 - SurvivorBots won't scavenge items farther away from the group:
	SetConVarInt(FindConVar("sb_max_scavenge_separation"), 2000);
	//default 0.5 -  If someone looks at me longer than this, I'll notice:
	SetConVarFloat(FindConVar("sb_min_attention_notice_time"), 0.0);
	//default value 1 - No other information on this from Valve:
	SetConVarFloat(FindConVar("sb_min_orphan_time_to_cover"), 0.0);
	//default value 300 - How close a friend needs to be to feel safe:
	SetConVarInt(FindConVar("sb_neighbor_range"), 100);
	//default value 350 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_normal_saccade_speed"), 9999);
	//default value 300 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_path_lookahead_range"), 1000);
	//default value 1.0 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_pushscale"), 0);
	//default value 3 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_reachability_cache_lifetime"), 0);
	//default value 300 - How close to the arrival point of the rescue vehicle SurvivorBots try to get:
	SetConVarInt(FindConVar("sb_rescue_vehicle_loading_range"), 50);
	//default value 600 - A Survivor teammate this far away needs to be gathered back into the group:
	SetConVarInt(FindConVar("sb_separation_danger_max_range"), 700);
	//default value 500 - A Survivor teammate this far away is straying from the group:
	SetConVarInt(FindConVar("sb_separation_danger_min_range"), 85);
	//default value 200 - Desired distance between Survivors:
	SetConVarInt(FindConVar("sb_separation_range"), 650);
	//default value 0 - Allow sidestepping left/right to acquire common infected targets:
	SetConVarInt(FindConVar("sb_sidestep_for_horde"), 1);
	//default value 0.5 - Temporary health is multiplied by this when SurvivorBots consider who needs healing:
	SetConVarFloat(FindConVar("sb_temp_health_consider_factor"), 0.20);
	//default value 200000 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_threat_exposure_stop"), 2147483646);
	//default value 50000 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_threat_exposure_walk"), 2147483647);
	//default value 500 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_near_hearing_range"), 9999);
	//default value 1500 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_far_hearing_range"), 2147483647);
	//default value 150 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_threat_very_close_range"), 50);
	//default value 200 - No other information on this from Valve:
	SetConVarInt(FindConVar("sb_close_threat_range"), 75);
	//default value 150 - Very close range for threats:
	SetConVarInt(FindConVar("sb_threat_close_range"), 50);
	//default value 300 - Too close for comfort, even when neutral:
	SetConVarInt(FindConVar("sb_threat_medium_range"), 3000);
	//default value 600 - Close enough to be a threat if near several other threats:
	SetConVarInt(FindConVar("sb_threat_far_range"), 8000);
	//default value 1500 - Too far to be a threat, even for boss infected:
	SetConVarInt(FindConVar("sb_threat_very_far_range"), 2147483647);
	//default 15 - How much more SurvivorBots must be hurt to consider themselves equally valid as a healing target:
	SetConVarInt(FindConVar("sb_toughness_buffer"), 15);
	//default value 5 - How long Boomer vomit/explosion gore blinds bots:
	SetConVarFloat(FindConVar("sb_vomit_blind_time"), 0.0);
	//default value 750 - No other information on this from Valve:
	SetConVarInt(FindConVar("survivor_vision_range_obscured"), 1500);
	//default value 1500 - No other information on this from Valve:
	SetConVarInt(FindConVar("survivor_vision_range"), 3000);
	//Commands - Force intensity of selected SurvivorBot to maximum level.	
	int flags=GetCommandFlags("sb_force_max_intensity");
	SetCommandFlags("sb_force_max_intensity", flags & ~FCVAR_CHEAT);
	
	ServerCommand("sb_force_max_intensity Bill");
	ServerCommand("sb_force_max_intensity Louis");
	ServerCommand("sb_force_max_intensity Francis");
	ServerCommand("sb_force_max_intensity Zoey");
}

public OnPluginStart()
{
	HookEvent("round_start", Roundstart, EventHookMode_Post);
	Config();
}

public Roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Competitive, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnMapStart()
{
	Config();
}

public Action:Competitive(Handle:Timer)
{
	Config();
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