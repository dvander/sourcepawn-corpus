#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "0.9"
public Plugin:myinfo =
{
	name = "Weapon Remover Lite",
	author = "Gdk",
	version = PLUGIN_VERSION,
	description = "Removes players weapons",
	url = "https://topsecretgaming.net"
};

new Handle:PluginEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	PluginEnabled = CreateConVar("sm_weapon_remover_lite_enabled", "1", "Whether the plugin is enabled");

	/** Create/Execute cvars **/
	AutoExecConfig(true, "weapon_remover_lite");
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Event_HandleSpawn, GetEventInt(event, "userid"));
}

public Action Event_HandleSpawn(Handle timer, any user_index)
{
	int client = GetClientOfUserId(user_index);
	
	if (GetConVarBool(PluginEnabled))
	{
		for(int j = 0; j < 4; j++)
		{
			int weapon = GetPlayerWeaponSlot(client, j);
			if(weapon != -1)
			{
				RemovePlayerItem(client, weapon);
				RemoveEdict(weapon);						
			}
		}
	}
}