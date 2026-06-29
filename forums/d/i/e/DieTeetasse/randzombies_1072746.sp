#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Varying Zombie Population",
	author = "Die Teetasse (Idea: Luke Penny)",
	description = "Common infected spawns with random health and maxspeed.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=116515"
}

new Handle:hCvarHealth;
new Handle:hCvarSpeed;

new Handle:hMinHealth;
new Handle:hMaxHealth;
new Handle:hMinSpeed;
new Handle:hMaxSpeed;

public OnPluginStart()
{
	CreateConVar("l4d2_vzp_version", PLUGIN_VERSION, "Varying Zombie Population version", CVAR_FLAGS|FCVAR_DONTRECORD);

	hMinHealth = CreateConVar("l4d2_vzp_min_health", "50", "Common min health", CVAR_FLAGS);
	hMaxHealth = CreateConVar("l4d2_vzp_max_health", "100", "Common max health", CVAR_FLAGS);
	hMinSpeed = CreateConVar("l4d2_vzp_min_speed", "200", "Common min speed", CVAR_FLAGS);
	hMaxSpeed = CreateConVar("l4d2_vzp_max_speed", "300", "Common max speed", CVAR_FLAGS);
	
	hCvarHealth = FindConVar("z_health");
	hCvarSpeed = FindConVar("z_speed");
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected"))
	{
		new RandomHealth = GetRandomInt(GetConVarInt(hMinHealth), GetConVarInt(hMaxHealth));
		new RandomSpeed = GetRandomInt(GetConVarInt(hMinSpeed), GetConVarInt(hMaxSpeed));
		
		SetConVarInt(hCvarHealth, RandomHealth);
		SetConVarInt(hCvarSpeed, RandomSpeed);
	}
}