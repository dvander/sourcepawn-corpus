#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Constants
#define PLUGIN_VERSION	 "1.0"

#define MESS			 "\x03.::[BB]::. \x01%t"
//#define DEBUG_MESS	 "\x04[.::[BB]::. \x01"

// Handles
new Handle:sm_awp_mode				 = INVALID_HANDLE;
new Handle:sm_awp_number_per_round	 = INVALID_HANDLE;
new Handle:sm_awp_version				 = INVALID_HANDLE;

new playerSpawnedawps[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "AWP Spawner",
	author = "Steve Merson",
	description = "awp_spawner",
	version = "1.0",
	url = "http://www.bb-clan.de"
};

public OnPluginStart()
{
	// Perform one-time startup tasks ...

	// Load translations
	LoadTranslations("awp.phrases");

	// Console commands
	RegConsoleCmd("sm_awp", Command_Giveawp);

	// Hook events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_disconnect", Event_PlayerDisconnect);

	// Create ConVars
	sm_awp_mode = CreateConVar("sm_awp_mode", "0", "Ammo mode; 0 - ammo of spawned awp gets set to zero, 1 - full ammo, 10+90");
	sm_awp_number_per_round = CreateConVar("sm_awp_number_per_round", "3", "Number of awp spawns allowed every round (reset on round start); 0 - unlimited, >0 - number of awps");
	sm_awp_version = CreateConVar("sm_awp_version", PLUGIN_VERSION, "awp_spawner plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "awp_spawner");

	// Hook ConVar-changes
	HookConVarChange(sm_awp_version, VersionChange);
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
	// Reset the number of awp spawns players have made
	if (GetConVarInt(sm_awp_number_per_round) != 0)
	{
		for(new i = 0; i < MaxClients; i++)
		{
			playerSpawnedawps[i] = 0;
		}
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Reset the number of awp spawns THIS player has made
	if (GetConVarInt(sm_awp_number_per_round) != 0)
	{
		new ev_client = GetEventInt(event, "userid");
		new client = GetClientOfUserId(ev_client);

		playerSpawnedawps[client] = 0;
	}
}

public Action:Command_Giveawp(client, args)
{
	if (IsPlayerAlive(client))
	{
		if ( (GetConVarInt(sm_awp_number_per_round) == 0) || (playerSpawnedawps[client] < GetConVarInt(sm_awp_number_per_round)) )
		{
			if (GetPlayerWeaponSlot(client, 0) == -1)
			{
				// Give awp
				GivePlayerItem(client, "weapon_awp");

				// Add to the player array (contains number of awps each player has spawned) if number of awp spawns should be limited...
				if (GetConVarInt(sm_awp_number_per_round) != 0)
					playerSpawnedawps[client]++;

				// Destroy ammo if ammo mode == 0
				if (GetConVarInt(sm_awp_mode) == 0)
				{
					SetWeaponAmmo(client, 0);
					SetWeaponClipAmmo(client, 2, 0);
				}
			}
			else
			{
				PrintToChat(client, MESS, "Primary Slot Contains Weapon");
				EmitSoundToClient(client, "buttons/button8.wav");
			}
		}
		else
		{
			PrintToChat(client, MESS, "Reached Maximum AWP Spawns Limit");
			EmitSoundToClient(client, "buttons/button8.wav");
		}
	}
	else
	{
		PrintToChat(client, MESS, "Must Be Alive");
	}

	return Plugin_Handled;
}