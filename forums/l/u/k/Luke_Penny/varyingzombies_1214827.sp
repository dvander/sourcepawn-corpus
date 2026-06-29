/*
Varying Zombie Population

ChangeLog:
1.0.0 - Initial Release
1.0.5 - Fixed some bugs that caused server to lag
1.1.0 - Special thanks to Die Teetasse for sdkhooks method of changing infected health
1.2.0 - Added zombie acquire time, fixed some stuff, released both L4D1 and L4D2 versions
1.3.0 - Cvar fixes, L4D1 and 2 both in 1 version
1.4.0 - Added specials, new cvar names, and fixed some bugs

*/

#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.4.0"

public Plugin:myinfo = 
{
	name = "Varying Zombie Population",
	author = "Luke Penny",
	description = "Common infected spawns with random health and random speed.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116515"
}
//Create Handles
new Handle:CvarHealth;
new Handle:CvarSpeed;
new Handle:CvarRange;
new Handle:CvarTime;
new Handle:CvarHunterHealth;
new Handle:CvarSmokerHealth;
new Handle:CvarBoomerHealth;
new Handle:CvarChargerHealth;
new Handle:CvarJockeyHealth;
new Handle:CvarSpitterHealth;


new Handle:MinHealth;
new Handle:MaxHealth;
new Handle:MinSpeed;
new Handle:MaxSpeed;
new Handle:MinRange;
new Handle:MaxRange;
new Handle:MinTime;
new Handle:MaxTime;

new Handle:MinHunterHealth;
new Handle:MaxHunterHealth;
new Handle:MinSmokerHealth;
new Handle:MaxSmokerHealth;
new Handle:MinBoomerHealth;
new Handle:MaxBoomerHealth;
new Handle:MinChargerHealth;
new Handle:MaxChargerHealth;
new Handle:MinJockeyHealth;
new Handle:MaxJockeyHealth;
new Handle:MinSpitterHealth;
new Handle:MaxSpitterHealth;
//Create and set ConVars
public OnPluginStart()
{
	CreateConVar("l4d_vzp_version", PLUGIN_VERSION, "Varying Zombie Population version", CVAR_FLAGS|FCVAR_DONTRECORD);
	//Common Infected
	MinHealth = CreateConVar("vz_health_min", "25", "Common min health - minimum health value zombies can have (default 50)", CVAR_FLAGS);
	MaxHealth = CreateConVar("vz_health_max", "100", "Common max health - maximum health value zombies can have (default 50)", CVAR_FLAGS);
	MinSpeed = CreateConVar("vz_speed_min", "200", "Common min speed - minimum speed value zombies can have (default 250", CVAR_FLAGS);
	MaxSpeed = CreateConVar("vz_speed_max", "300", "Common max speed - maximum speed value zombies can have (default 250)", CVAR_FLAGS);
	MinRange = CreateConVar("vz_range_min", "2000", "Common minimum sight - minimum range zombies will acquire targets", CVAR_FLAGS);
	MaxRange = CreateConVar("vz_range_max", "3000", "Common max sight - maximum range zombies will acquire targets", CVAR_FLAGS);
	MinTime = CreateConVar("vz_time_min", "2", "Common min acquire time - minimum time it takes zombies to acquire targets", CVAR_FLAGS);
	MaxTime = CreateConVar("vz_time_max", "8", "Common max acquire time - maximum time it takes zombies to acquire targets", CVAR_FLAGS);
	//Specials
	MinHunterHealth = CreateConVar("vz_hunter_min_health", "200", "Minimum Hunter Health (Default 250)", CVAR_FLAGS);
	MaxHunterHealth = CreateConVar("vz_hunter_max_health", "300", "Maximum Hunter Health (Default 250)", CVAR_FLAGS);
	MinSmokerHealth = CreateConVar("vz_smoker_min_health", "200", "Minimum Smoker Health (Default 250)", CVAR_FLAGS);
	MaxSmokerHealth = CreateConVar("vz_smoker_max_health", "300", "Minimum Smoker Health (Default 250)", CVAR_FLAGS);
	MinBoomerHealth = CreateConVar("vz_boomer_min_health", "25", "Minimum Boomer Health (Default 50)", CVAR_FLAGS);
	MaxBoomerHealth = CreateConVar("vz_boomer_max_health", "75", "Minimum Boomer Health (Default 50)", CVAR_FLAGS);
	MinChargerHealth = CreateConVar("vz_charger_min_health", "500", "Minimum Charger Health (Default 600)", CVAR_FLAGS);
	MaxChargerHealth = CreateConVar("vz_charger_max_health", "700", "Minimum Charger Health (Default 600)", CVAR_FLAGS);
	MinJockeyHealth = CreateConVar("vz_jockey_min_health", "275", "Minimum Jockey Health (Default 325)", CVAR_FLAGS);
	MaxJockeyHealth = CreateConVar("vz_jockey_max_health", "375", "Minimum Jockey Health (Default 325)", CVAR_FLAGS);
	MinSpitterHealth = CreateConVar("vz_spitter_min_health", "75", "Minimum Spitter Health (Default 100)", CVAR_FLAGS);
	MaxSpitterHealth = CreateConVar("vz_spitter_max_health", "125", "Minimum Spitter Health (Default 100)", CVAR_FLAGS);
	//Cvars
	CvarHealth = FindConVar("z_health");
	CvarSpeed = FindConVar("z_speed");
	CvarRange = FindConVar("z_acquire_far_range");
	CvarTime = FindConVar("z_acquire_far_time");
	//
	CvarHunterHealth = FindConVar("z_hunter_health");
	CvarSmokerHealth = FindConVar("z_gas_health");
	CvarBoomerHealth = FindConVar("z_exploding_health");
	CvarChargerHealth = FindConVar("z_charger_health");
	CvarJockeyHealth = FindConVar("z_jockey_health");
	CvarSpitterHealth = FindConVar("z_spitter_health");
	AutoExecConfig(true, "varyingzombies");
	CreateTimer(20, SpecialTimer, _, TIMER_REPEAT);
}
//This will change the values that zombies are spawned with after every individual zombie is spawned, so the next zombie spawned will have a different value
public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected"))
	{
		new RandomHealth = GetRandomInt(GetConVarInt(MinHealth), GetConVarInt(MaxHealth));
		new RandomSpeed = GetRandomInt(GetConVarInt(MinSpeed), GetConVarInt(MaxSpeed));
		new RandomRange = GetRandomInt(GetConVarInt(MinRange), GetConVarInt(MaxRange));
		new RandomTime = GetRandomInt(GetConVarInt(MinTime), GetConVarInt(MaxTime));
		//Set the zombie attributes to the new randomized values
		SetConVarInt(CvarHealth, RandomHealth);
		SetConVarInt(CvarSpeed, RandomSpeed);
		SetConVarInt(CvarRange, RandomRange);
		SetConVarInt(CvarTime, RandomTime);
	}
}

public Action:SpecialTimer(Handle:timer)
{	
	new RandomHunterHealth = GetRandomInt(GetConVarInt(MinHunterHealth), GetConVarInt(MaxHunterHealth));
	new RandomSmokerHealth = GetRandomInt(GetConVarInt(MinSmokerHealth), GetConVarInt(MaxSmokerHealth));
	new RandomBoomerHealth = GetRandomInt(GetConVarInt(MinBoomerHealth), GetConVarInt(MaxBoomerHealth));
	new RandomChargerHealth = GetRandomInt(GetConVarInt(MinChargerHealth), GetConVarInt(MaxChargerHealth));
	new RandomJockeyHealth = GetRandomInt(GetConVarInt(MinJockeyHealth), GetConVarInt(MaxJockeyHealth));
	new RandomSpitterHealth = GetRandomInt(GetConVarInt(MinSpitterHealth), GetConVarInt(MaxSpitterHealth));
	
	SetConVarInt(CvarHunterHealth, RandomHunterHealth);
	SetConVarInt(CvarSmokerHealth, RandomSmokerHealth);
	SetConVarInt(CvarBoomerHealth, RandomBoomerHealth);
	SetConVarInt(CvarChargerHealth, RandomChargerHealth);
	SetConVarInt(CvarJockeyHealth, RandomJockeyHealth);
	SetConVarInt(CvarSpitterHealth, RandomSpitterHealth);
}