#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

new Handle:Enable = INVALID_HANDLE;
new Handle:Chance = INVALID_HANDLE;
new Handle:RunTimes = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Coffee Ammo",
	author = "McFlurry",
	description = "Coffee ammo from L4D.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_coffee_version", PLUGIN_VERSION, "Version of Coffee ammo", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable = CreateConVar("l4d2_coffee_enable", "1", "Coffee ammo enable", FCVAR_PLUGIN);
	Chance = CreateConVar("l4d2_coffee_chance", "2", "Coffee ammo chance", FCVAR_PLUGIN);
	RunTimes = CreateConVar("l4d2_coffee_runtimes", "2", "How many ammo spawns to check for replacement?", FCVAR_PLUGIN);
	
	HookEvent("round_start", Event_RoundStart);
	AutoExecConfig(true, "l4d2_coffee");
}	

public OnMapStart()
{
	PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);
}	

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(8.0, CoffeeTime, _, TIMER_FLAG_NO_MAPCHANGE);	
}	

public Action:CoffeeTime(Handle:Timer)
{
	new runtimes = 0,
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