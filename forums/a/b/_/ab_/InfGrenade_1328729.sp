#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define AUTHOR "Metropolitaner"

public Plugin:myinfo = 
{
	name = "Unendlich Granaten",
	author = AUTHOR,
	description = "Immer Unendlich Granaten im Sack",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("weapon_fire", WeaponFire);
}

public GiveGrenade(client, const String:Name[])
{
	GivePlayerItem(client, Name);
}

public WeaponFire(Handle:event, String:name[], bool:dontBroadcast)
{
	decl String:Weapon[32];
	GetEventString(event, "weapon", Weapon, sizeof(Weapon));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (StrEqual(Weapon, "flashbang")) GiveGrenade(client, "weapon_flashbang");
	if (StrEqual(Weapon, "smokegrenade")) GiveGrenade(client, "weapon_smokegrenade");
	if (StrEqual(Weapon, "hegrenade")) GiveGrenade(client, "weapon_hegrenade");
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
	{
		GiveGrenade(client, "weapon_hegrenade");
		GiveGrenade(client, "weapon_smokegrenade");
		GiveGrenade(client, "weapon_flashbang");
		GiveGrenade(client, "weapon_flashbang");
	}
}