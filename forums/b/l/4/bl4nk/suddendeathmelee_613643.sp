#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.1b"

new bool:isActive = false;

new Handle:cvarEnable;
new Handle:cvarClass;
new Handle:cvarRandom;

new TFClassType:randomClass;

// Functions
public Plugin:myinfo =
{
	name = "Sudden Death Melee",
	author = "bl4nk",
	description = "Melee only mode during sudden death",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_suddendeathmelee_version", PLUGIN_VERSION, "Sudden Death Melee Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_suddendeathmelee_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarClass = CreateConVar("sm_suddendeathmelee_class", "scout", "Class for people to spawn as", FCVAR_PLUGIN);
	cvarRandom = CreateConVar("sm_suddendeathmelee_random", "1", "Which random mode to choose a class for someone to spawn as (1 = Per player spawn, 2 = Per stalemate", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("teamplay_round_stalemate", event_SuddenDeathStart);
	HookEvent("teamplay_round_start", event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", event_SuddenDeathEnd);
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvarEnable) || !isActive)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:classString[32];
	GetConVarString(cvarClass, classString, sizeof(classString));

	new TFClassType:class = TF2_GetClass(classString);
	if (class == TFClass_Unknown)
	{
		if (strcmp(classString, "random") == 0)
		{
			switch(GetConVarInt(cvarRandom))
			{
				case 1:
					class = TFClassType:GetRandomInt(1, 9);
				case 2:
					class = randomClass;
			}
		}
	}

	TF2_SetPlayerClass(client, class, false, false);
	CreateTimer(0.1, timer_Melee, client);
}

public Action:event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isActive = true;
	randomClass = TFClassType:GetRandomInt(1, 9);

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			TF2_RespawnPlayer(i);
		}
	}
}

public Action:event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
	isActive = false;

public Action:timer_Melee(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new weaponIndex = GetPlayerWeaponSlot(client, 2);
		for (new i = 0; i <= 5; i++)
		{
			if (i == 2)
			{
				RemovePlayerItem(client, weaponIndex);
				continue;
			}

			TF2_RemoveWeaponSlot(client, i);
		}

		EquipPlayerWeapon(client, weaponIndex);
	}

}