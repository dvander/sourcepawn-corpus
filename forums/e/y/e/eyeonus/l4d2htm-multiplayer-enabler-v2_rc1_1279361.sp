//Includes:
#include <sourcemod>

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "L4D2 Hunter Training Map Multiplayer Enabler",
	author = "aionys",
	description = "Enables the cheats needed for Hunter Training Map to be run on a dedicated server.",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};

new Handle:enable_toggle;

public OnPluginStart()
{
	CreateConVar("l4d2_htm_mp_enabler", PLUGIN_VERSION, "L4D2 Hunter Training Map Multiplayer Enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	enable_toggle = CreateConVar("l4d2_htm_mp_enable","0","enable or disable needed cheat cvars to be altered for HTM (HTM will set this to true on map load.)");
	training_toggle = CreateConVar("htm_training_start","0","enable to begin Live Fire Course training on any map.");
	HookConVarChange(enable_toggle,Enable_HTM_MP);
	HookConVarChange(training_toggle,start_training);
	RegConsoleCmd("noclip",PerformNoClip);
	RegConsoleCmd("give",give_health);
	RegConsoleCmd("z_spawn",spawn_zombie);
}

public OnMapStart()
new String:map[30];
GetCurrentMap(map, sizeof(map));
if(!StrContains("hunter_training")) //see if "hunter_training" is in the name of the map
{
   ServerCommand("l4d2_htm_mp_enable 0");
}  

public start_training(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (GetConVarBool(training_toggle)) {
        ServerCommand("l4d2_htm_mp_enable 1;god 1;vs_max_team_switches 99;sb_all_bot_team 1")
    } else {
        ServerCommand("l4d2_htm_mp_enable 0")
    }  
	
public Enable_HTM_MP(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarBool(enable_toggle)) {
		SetConVarBool(FindConVar("sv_cheats"),false);
		//Strip the CHEAT flag off of the needed cvars.
		SetCommandFlags("god", GetCommandFlags("god") & ~FCVAR_CHEAT);
		SetCommandFlags("nb_stop", GetCommandFlags("nb_stop") & ~FCVAR_CHEAT);
		SetCommandFlags("vs_max_team_switches", GetCommandFlags("vs_max_team_switches") & ~FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_team", GetCommandFlags("sb_all_bot_team") & ~FCVAR_CHEAT);
		SetCommandFlags("z_spawn", GetCommandFlags("z_spawn") & ~FCVAR_CHEAT);
		SetCommandFlags("z_hunter_health", GetCommandFlags("z_hunter_health") & ~FCVAR_CHEAT);
		SetCommandFlags("director_no_death_check", GetCommandFlags("director_no_death_check") & ~FCVAR_CHEAT);
		SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
		SetCommandFlags("noclip", GetCommandFlags("noclip") & ~FCVAR_CHEAT);
		SetCommandFlags("kill", GetCommandFlags("kill") & ~FCVAR_CHEAT);
	} else {
		//Add the CHEAT flag back to needed cvars.
		SetCommandFlags("god", GetCommandFlags("god")|FCVAR_CHEAT);
		SetCommandFlags("nb_stop", GetCommandFlags("nb_stop")|FCVAR_CHEAT);
		SetCommandFlags("vs_max_team_switches", GetCommandFlags("vs_max_team_switches")|FCVAR_CHEAT);
		SetCommandFlags("sb_all_bot_team", GetCommandFlags("sb_all_bot_team")|FCVAR_CHEAT);
		SetCommandFlags("z_spawn", GetCommandFlags("z_spawn")|FCVAR_CHEAT);
		SetCommandFlags("z_hunter_health", GetCommandFlags("z_hunter_health")|FCVAR_CHEAT);
		SetCommandFlags("director_no_death_check", GetCommandFlags("director_no_death_check")|FCVAR_CHEAT);
		SetCommandFlags("give", GetCommandFlags("give")|FCVAR_CHEAT);
		SetCommandFlags("noclip", GetCommandFlags("noclip")|FCVAR_CHEAT);
		SetCommandFlags("kill", GetCommandFlags("kill")|FCVAR_CHEAT);
		ServerCommand("sv_cheats 1");
	}
}
	
public Action:PerformNoClip(client, args) {
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

public Action:give_health(client, args) {
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	if (StrEqual(arg, "health")||!GetConVarBool(enable_toggle)) {
		return Plugin_Continue;
	} else {
		return Plugin_Handled;
	}
}

public Action:spawn_zombie(client, args) {
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	if ((StrEqual(arg, "witch")||StrEqual(arg, "tank"))&&(GetConVarBool(enable_toggle))) {
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}
