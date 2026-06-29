#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"Airborne"

new Handle:gPluginEnabled;
new kills[33] = {0,...};
new deaths[33] = {0,...};

new LEVELS = 6;
new levels[6] = {2, 5, 6, 7, 8, 10};
new String:sounds[6][] = {"misc/doublekill.wav", "misc/killingspree.wav", "misc/rampage.wav", "misc/dominating.wav", "misc/unstoppable.wav", "misc/godlike.wav"};
new String:messages[6][] = {"%s: DOUBLE-KILL!!!", "%s IS ON A KILLING SPREE!!!", "%s IS ON A RAMPAGE!!!", "%s IS DOMINATING!!!", "%s IS UNSTOPPABLE!!!", "%s IS GODLIKE!!!"};

public Plugin:myinfo = 
{
	name = "UT Killing Spree",
	author = PLUGIN_AUTHOR,
	description = "Killing Spree Notifications and Sounds",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	CreateConVar("ut_killing_spree_version", PLUGIN_VERSION, "UT Killing Spree Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	gPluginEnabled = CreateConVar("ut_killing_spree", "1");
}

public OnMapStart()
{
	for(new i = 0; i < LEVELS; i++)
	{
		decl String:buffer[64];
		PrecacheSound(sounds[i],true);
		Format(buffer, sizeof(buffer), "sound/%s", sounds[i]);
		AddFileToDownloadsTable(buffer);
	}
}

public OnClientConnected(client)
{
	kills[client] = 0;
	deaths[client] = 0;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gPluginEnabled) <= 0)
	{
		return Plugin_Handled;
	}
	new playersConnected = GetMaxClients();
	for (new playerClient = 1; playerClient <= playersConnected; playerClient++)
	{
		new playerInGameStatus = IsClientInGame(playerClient);
		if (playerInGameStatus == 1)
		{
			if (kills[playerClient] > levels[0])
			{
				PrintToChat(playerClient, "* You are on a killstreak with %d kills.", kills[playerClient]);
			}
			else if (deaths[playerClient] > 1)
			{
				PrintToChat(playerClient, "* Take care, you are on a deathstreak with %d deaths in a row.", deaths[playerClient]);
			}
			else if (kills[playerClient] <= 1)
			{
				PrintToChat(playerClient, "* You are not on a killstreak or a deathstreak.");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gPluginEnabled) <= 0)
	{
		return Plugin_Handled;
	}
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	kills[attacker] += 1;
	kills[victim] = 0;
	deaths[attacker] = 0;
	deaths[victim] += 1;

	for (new i = 0; i < LEVELS; i++)
	{
		if (kills[attacker] == levels[i])
		{
			announce(attacker, i);
		}
	}
	return Plugin_Continue;
}

public announce(attacker, level)
{
	new String:name[33];

	GetClientName(attacker, name, 32);

	new playersConnected = GetMaxClients();
	for (new playerClient = 1; playerClient <= playersConnected; playerClient++)
	{
		PrintHintTextToAll(messages[level], name);
		new playerInGameStatus = IsClientInGame(playerClient);
		if (playerInGameStatus == 1)
		{
        		ClientCommand(playerClient, "playgamesound %s", sounds[level]);
		}
	}
}