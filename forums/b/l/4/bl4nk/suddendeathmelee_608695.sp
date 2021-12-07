#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new bool:isActive = false;

new Handle:cvarEnable;
new Handle:cvarClass;

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
	cvarClass = CreateConVar("sm_suddendeathmelee_class", "scout", "Class for people to spawn as");

	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("teamplay_suddendeath_begin", event_SuddenDeathStart);
	HookEvent("teamplay_suddendeath_end", event_SuddenDeathEnd);
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvarEnable) || !isActive)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:classString[32];
	GetConVarString(cvarClass, classString, sizeof(classString));

	new TFClassType:class = TF2_GetClass(classString);
	switch (class)
	{
		case TFClass_Unknown:
		{
			if (strcmp(classString, "random") == 0)
			{
				new TFClassType:random = TFClassType:GetRandomInt(1, 9);
				TF2_SetPlayerClass(client, random, false);
			}
		}
		default:
			TF2_SetPlayerClass(client, class, false);
	}

	CreateTimer(0.1, timer_Melee, client);

}

public Action:event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
	isActive = true;

public Action:event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
	isActive = false;

public Action:timer_Melee(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 0; i <= 5; i++)
		{
			if (i == 2)
				continue;

			TF2_RemoveWeaponSlot(client, i);
		}
	}
}