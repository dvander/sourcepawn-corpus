#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Constants
#define PLUGIN_VERSION	 "1.20"

#define MESS			 "\x03[SM_Scout] \x01%t"
//#define DEBUG_MESS	 "\x04[SM_Scout] \x01"

// Handles
new Handle:sm_scout_mode				 = INVALID_HANDLE;
new Handle:sm_scout_number_per_round	 = INVALID_HANDLE;
new Handle:sm_scout_version				 = INVALID_HANDLE;

new playerSpawnedScouts[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM_Scout",
	author = "dataviruset",
	description = "Scout spawner (simple, silent version)",
	version = "1.20ssv",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Perform one-time startup tasks ...

	// Load translations
	//LoadTranslations("scout.phrases");

	// Console commands
	RegConsoleCmd("sm_scout", Command_GiveScout);

	// Hook events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_disconnect", Event_PlayerDisconnect);

	// Create ConVars
	sm_scout_mode = CreateConVar("sm_scout_mode", "0", "Ammo mode; 0 - ammo of spawned scout gets set to zero, 1 - full ammo, 10+90");
	sm_scout_number_per_round = CreateConVar("sm_scout_number_per_round", "3", "Number of scout spawns allowed every round (reset on round start); 0 - unlimited, >0 - number of scouts");
	sm_scout_version = CreateConVar("sm_scout_version", PLUGIN_VERSION, "SM_Scout plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "sm_scout");

	// Hook ConVar-changes
	HookConVarChange(sm_scout_version, VersionChange);
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

// a tiny function to set ammo IN CLIP for a weapon
stock SetWeaponClipAmmo(client, slot, ammo)
{
	new ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	return SetEntData(client, ammoOffset+(slot*4), ammo);
}

stock SetWeaponAmmo(client, ammo)
{
	new iWeapon = GetEntDataEnt2(client, FindSendPropInfo("CCSPlayer", "m_hActiveWeapon"));
	SetEntData(iWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), ammo);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Reset the number of scout spawns players have made
	if (GetConVarInt(sm_scout_number_per_round) != 0)
	{
		for(new i = 0; i < MaxClients; i++)
		{
			playerSpawnedScouts[i] = 0;
		}
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Reset the number of scout spawns THIS player has made
	if (GetConVarInt(sm_scout_number_per_round) != 0)
	{
		new ev_client = GetEventInt(event, "userid");
		new client = GetClientOfUserId(ev_client);

		playerSpawnedScouts[client] = 0;
	}
}

public Action:Command_GiveScout(client, args)
{
	if (IsPlayerAlive(client))
	{
		if ( (GetConVarInt(sm_scout_number_per_round) == 0) || (playerSpawnedScouts[client] < GetConVarInt(sm_scout_number_per_round)) )
		{
			if (GetPlayerWeaponSlot(client, 0) == -1)
			{
				// Give scout
				GivePlayerItem(client, "weapon_scout");

				// Add to the player array (contains number of scouts each player has spawned) if number of scout spawns should be limited...
				if (GetConVarInt(sm_scout_number_per_round) != 0)
					playerSpawnedScouts[client]++;

				// Destroy ammo if ammo mode == 0
				if (GetConVarInt(sm_scout_mode) == 0)
				{
					SetWeaponAmmo(client, 0);
					SetWeaponClipAmmo(client, 2, 0);
				}
			}
		}
	}

	return Plugin_Handled;
}