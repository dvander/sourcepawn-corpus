#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

ConVar Enable;
ConVar Chance;
ConVar RunTimes;

public Plugin myinfo = 
{
	name = "[L4D2] Coffee Ammo",
	author = "McFlurry",
	description = "Coffee ammo from L4D.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public void OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_coffee_version", PLUGIN_VERSION, "Version of Coffee ammo", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable = CreateConVar("l4d2_coffee_enable", "1", "Coffee ammo enable");
	Chance = CreateConVar("l4d2_coffee_chance", "2", "Coffee ammo chance");
	RunTimes = CreateConVar("l4d2_coffee_runtimes", "2", "How many ammo spawns to check for replacement?");
	
	HookEvent("round_start", Event_RoundStart);
	AutoExecConfig(true, "l4d2_coffee");
}	

public void OnMapStart()
{
	PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);
}	

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(8.0, CoffeeTime, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CoffeeTime(Handle Timer)
{
	int runtimes = 0,
	maxruntimes = GetConVarInt(RunTimes),
	ent = -1,
	prev = 0,
	chance = GetConVarInt(Chance);
	if(GetConVarInt(Enable) == 0) return;
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1 && runtimes < maxruntimes)
	{
		runtimes++;
		if(prev && GetRandomInt(1, chance) == 1)
		{
			SetEntityModel(prev, "models/props_unique/spawn_apartment/coffeeammo.mdl");
		}
		prev = ent;
	}
	if(prev && GetRandomInt(1, chance) == 1 && IsValidEdict(prev))
	{
		SetEntityModel(prev, "models/props_unique/spawn_apartment/coffeeammo.mdl");
	}
}