#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools_functions>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Restore Grenade",
	author = PLUGIN_AUTHOR,
	description = "Restores attacker's grenade when kill someone with it.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298936"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	char sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "weapon_hegrenade", false))
	{
		GivePlayerItem(attacker, "weapon_hegrenade");
	}
}
