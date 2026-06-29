//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.5.1"

public Plugin:myinfo = 
{
	name = "L4D2 Hunter Training Map Multiplayer Enabler",
	author = "aionys",
	description = "Enables the cheats needed for Hunter Training Map to be run on a dedicated server.",
	version = PLUGIN_VERSION,
	url = "http://l4dmapdb.com/addon:hunter-training"
};

new Handle:enable_toggle;
new Handle:hRespawn = INVALID_HANDLE;
new training = 0;

public OnPluginStart()
{
	CreateConVar("l4d2_htm_mp_enabler", PLUGIN_VERSION, "L4D2 Hunter Training Map Multiplayer Enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	enable_toggle = CreateConVar("l4d2_htm_mp_enable","0","enable or disable needed cheat cvars to be altered for HTM (HTM will set this to true on map load.)", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(enable_toggle,Enable_HTM_MP);
	RegConsoleCmd("htm_training_start",start_training,"set Live Fire Course settings for training on any map.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("noclip",PerformNoClip);
	RegConsoleCmd("give",give_health);
	RegConsoleCmd("z_spawn",spawn_zombie);
	
//Load SDKCall for respawn command
	new Handle:hGameConf = LoadGameConfigFile("htm_mp_enabler.gamedata");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RoundRespawn");
	hRespawn = EndPrepSDKCall();

	if (hRespawn != INVALID_HANDLE) {
		RegConsoleCmd("respawn", Command_Respawn);
		RegConsoleCmd("respawn_all", Respawn_All);
	} else {
		PrintToServer("HTM MP enabler unable to enable respawn command");
	}

//Hook event to respawn survivor when survivor enters the end safe room area.
	HookEvent("player_entered_checkpoint", training_respawn);
}

public OnMapStart() {
	new String:map[30];
	GetCurrentMap(map, sizeof(map));
	training = 0;
	if(StrContains(map, "hunter_training", false)) //see if "hunter_training" is in the name of the map
	{
		ServerCommand("l4d2_htm_mp_enable 0");
	}
}	

public Action:start_training(client, args) { //manual start training
	ServerCommand("l4d2_htm_mp_enable 1;sm_cvar mp_gamemode versus;god 1;vs_max_team_switches 99;sb_all_bot_team 1;sb_all_bot_game 1;z_hunter_health 6000;director_no_death_check 1");
	training = 1;
}  
	
public Enable_HTM_MP(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(enable_toggle)) { //Turn off cheats if they are enabled.
		ServerCommand("sv_cheats 0");
		//Strip the CHEAT flag off of the needed cvars.
		SetCommandFlags("god", GetCommandFlags("god") & ~FCVAR_CHEAT);
		SetCommandFlags("nb_stop", GetCommandFlags("nb_stop") & ~FCVAR_CHEAT);
		SetCommandFlags("vs_max_team_switches", GetCommandFlags("vs_max_team_switches") & ~FCVAR_CHEAT);
		SetCommandFlags("warp_far_survivor_here", GetCommandFlags("warp_far_survivor_here") & ~FCVAR_CHEAT);
		SetCommandFlags("respawn", GetCommandFlags("respawn") & ~FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_team", GetCommandFlags("sb_all_bot_team") & ~FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_game", GetCommandFlags("sb_all_bot_game") & ~FCVAR_CHEAT);
		SetCommandFlags("z_spawn", GetCommandFlags("z_spawn") & ~FCVAR_CHEAT);
		SetCommandFlags("z_hunter_health", GetCommandFlags("z_hunter_health") & ~FCVAR_CHEAT);
		SetCommandFlags("director_no_death_check", GetCommandFlags("director_no_death_check") & ~FCVAR_CHEAT);
		SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
		SetCommandFlags("noclip", GetCommandFlags("noclip") & ~FCVAR_CHEAT);
		SetCommandFlags("kill", GetCommandFlags("kill") & ~FCVAR_CHEAT);
		SetCommandFlags("respawn", GetCommandFlags("respawn") & ~FCVAR_CHEAT);
	} else { //cycle flags back on.
		//Add the CHEAT flag back to needed cvars.
		SetCommandFlags("god", GetCommandFlags("god")|FCVAR_CHEAT);
		SetCommandFlags("nb_stop", GetCommandFlags("nb_stop")|FCVAR_CHEAT);
		SetCommandFlags("vs_max_team_switches", GetCommandFlags("vs_max_team_switches")|FCVAR_CHEAT);
		SetCommandFlags("warp_far_survivor_here", GetCommandFlags("warp_far_survivor_here")|FCVAR_CHEAT);
		SetCommandFlags("respawn", GetCommandFlags("respawn") & ~FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_team", GetCommandFlags("sb_all_bot_team")|FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_game", GetCommandFlags("sb_all_bot_game")|FCVAR_CHEAT);
		SetCommandFlags("z_spawn", GetCommandFlags("z_spawn")|FCVAR_CHEAT);
		SetCommandFlags("z_hunter_health", GetCommandFlags("z_hunter_health")|FCVAR_CHEAT);
		SetCommandFlags("director_no_death_check", GetCommandFlags("director_no_death_check")|FCVAR_CHEAT);
		SetCommandFlags("give", GetCommandFlags("give")|FCVAR_CHEAT);
		SetCommandFlags("noclip", GetCommandFlags("noclip")|FCVAR_CHEAT);
		SetCommandFlags("kill", GetCommandFlags("kill")|FCVAR_CHEAT);
		SetCommandFlags("respawn", GetCommandFlags("respawn")|FCVAR_CHEAT);
		ServerCommand("sv_cheats 1;wait 100;sv_cheats 0");
		training = 0;
	}
}
	
public Action:PerformNoClip(client, args) { //Allow noclip regardless of whether cheats are on.
	new MoveType:movetype = GetEntityMoveType(client);
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));

	if (((movetype != MOVETYPE_NOCLIP)&&!(StrEqual(arg, "0")))||(StrEqual(arg, "1"))) {
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	}
	if (((movetype == MOVETYPE_NOCLIP)&&!(StrEqual(arg, "1")))||(StrEqual(arg, "0"))) {
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	return Plugin_Handled;
}

public Action:give_health(client, args) { //allow everything if plugin is off.
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	if (StrEqual(arg, "health")||!GetConVarBool(enable_toggle)) { //Continue if (the argument is "health" or the plugin is turned off).
		return Plugin_Continue;
	} else {
		return Plugin_Handled;
	}
}

public Action:spawn_zombie(client, args) { //allow everything if plugin is off.
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	if ((StrEqual(arg, "witch")||StrEqual(arg, "tank"))&&(GetConVarBool(enable_toggle))) { //restrict iff ((the argument is "witch" or "tank") and the plugin is turned on).
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

//Respawn survivor in end safe room at start point if training is active.
public training_respawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event,"userid"))
	if (training) {
		Command_Respawn(client,0);
	}
}

//Manual respawn of all survivors
public Action:Respawn_All(client, args) {
	for (new i = 1; i <= MaxClients; i++) {
		Command_Respawn(i,0);
	}
}

//Respawn function
public Action:Command_Respawn(client, args) {
	if (GetConVarBool(enable_toggle) && IsClientInGame(client) && (GetClientTeam(client) != 3)) {
		SDKCall(hRespawn,client);
	}
	return Plugin_Continue;
}