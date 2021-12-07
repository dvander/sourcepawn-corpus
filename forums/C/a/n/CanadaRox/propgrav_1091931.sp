#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

public Plugin:myinfo =
{
	name = "Low Gravity Props",
	author = "CanadaRox",
	description = "Props have low gravity!",
	version = "1.0",
	url = "..."
};

new Handle:cvar_enable;

new Float:default_grav;

//new bool:finale;

new round_num;

public OnPluginStart()
{
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("This is a L4D1/2 plugin you nub!");
	
	cvar_enable = CreateConVar("l4d2_PropGrav_Enable", "1", "Enable Low Gravity Props Plugin", CVAR_FLAGS);
	HookConVarChange(cvar_enable, Hook_enable);
		
	default_grav = GetConVarFloat(FindConVar("sv_gravity"));
}

public OnPluginEnd()
{
	SetConVarFloat(FindConVar("sv_gravity"), default_grav, false, false);
}

public Hook_enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(GetConVarBool(cvar_enable) == false){
		UnhookEvents();
		SetConVarFloat(FindConVar("sv_gravity"), default_grav, false, false);
	} else {
		HookEvents();
	}
}

HookEvents()
{
	HookEvent("map_transition", Event_map_transition);
	HookEvent("finale_vehicle_leaving", Event_finale_vehicle_leaving);
	HookEvent("round_start", Event_round_start);
	HookEvent("round_end", Event_round_end);
}

UnhookEvents()
{
	UnhookEvent("map_transition", Event_map_transition);
	UnhookEvent("finale_vehicle_leaving", Event_finale_vehicle_leaving);
	UnhookEvent("round_start", Event_round_start);
	UnhookEvent("round_end", Event_round_end);
}

public OnMapStart()
{
	round_num = 0;
	if (GetConVarFloat(cvar_enable) == 0)
	{
		UnhookEvents();
		return;
	} else {
		HookEvents();
	}
	
	SetConVarFloat(FindConVar("sv_gravity"), default_grav, false, false);
}

public Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_num++;
	
}

public Event_map_transition(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarFloat(FindConVar("sv_gravity"), 0.1, false, false);
}
public Event_finale_vehicle_leaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:mode[16];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));
	
	if (!(StrContains(mode, "versus") > -1)) SetConVarFloat(FindConVar("sv_gravity"), 0.1, false, false);
}

public Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:mode[16];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));
	
	if (((StrContains(mode, "versus") > -1) || (StrContains(mode, "scav") > -1)) && (round_num > 0)) SetConVarFloat(FindConVar("sv_gravity"), 0.1, false, false);
}

