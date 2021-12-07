/*
Description:

Allows players to buy respawn to return to play again, it is possible to set the price.

This plugin has been rewritten from the original made ​​by member: Devzirom
Original thread: http://forums.alliedmods.net/showthread.php?t=141345

The cause of rewriting the plugin? It has not been approved.

I removed the cvar sm_buy_relive_buytime, because hardly anyone will die before the end buytime, however I am open to suggestions will.

Commands:

!buyr
!respawn
!revive
!buyrespawn
!buyrevive

CVARs:

sm_buyrespawn_enabled = 1/0 - plugin is enabled/disabled, (def. 1)
sm_buyrespawn_cost = 0-16000 - Set the price for the relive(respawn), (def. 5000)
sm_buyrespawn_message = 1/0 plugin message is enabled/disabled, (def. 1)
sm_buyrespawn_per_round = 0 No limit | 1/99 - Set the max respawns per round(def. 10)
sm_buyrespawn_version - current plugin version

Credits:

Devzirom

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
ConVar FIX
sm_ added in commands
Small optimizations

* Version 1.0.2 *

Added Cvar sm_buyrespawn_per_round
Added Automatic .cfg generator
Added HookConVarChange
Little optimization

* Version 1.0.3 *

Small fix in uses count
Release STORE version

* Version 1.0.4 *

Some bugs fixed, reported by relicek.
*/

#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0.2"

new Handle:gBuyRespawnEnabled = INVALID_HANDLE;
new Handle:gBuyRespawnCost = INVALID_HANDLE;
new Handle:gBuyRespawnMessage = INVALID_HANDLE;
new Handle:gBuyRespawnUses = INVALID_HANDLE;
new Handle:h_MP_RESTARTGAME = INVALID_HANDLE;
new respawn_enabled;
new respawn_cost;
new respawn_message;
new cRespawn_Uses;
new respawn_uses[MAXPLAYERS+1];

new String:commands_respawn[][] = { // List of CMDs
    "sm_respawn", 
    "sm_buyr",
    "sm_revive",
    "sm_buyrevive",
    "sm_buyrespawn"
};

public Plugin:myinfo = {
	name = "SM: Buy Respawn",
	author = "Rodrigo286",
	description = "Allows players to buy a respawn",
    version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart() 
{
	CreateConVar("sm_buyrespawn_version", PLUGIN_VERSION, "\"SM: Buy Respawn\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gBuyRespawnEnabled = CreateConVar("sm_buyrespawn_enabled", "1", "\"1\" = \"SM: Buy Respawn\" plugin is enabled, \"0\" = \"SM: Buy Respawn\" plugin is disabled");
	gBuyRespawnCost = CreateConVar("sm_buyrespawn_cost", "5000.0", "Set the price for the relive(respawn)", FCVAR_NONE, true, 0.0, true, 16000.0);
	gBuyRespawnUses = CreateConVar("sm_buyrespawn_per_round", "10", "Set the max respawns per round(respawn)", FCVAR_NONE, true, 0.0, true, 99.0);
	gBuyRespawnMessage = CreateConVar("sm_buyrespawn_message", "1", "\"1\" = \"SM: Buy Respawn\" message is enabled, \"0\" = \"SM: Buy Respawn\" message is disabled");
	AutoExecConfig(true, "sm_buy_respawn");
	HookEvent("round_end", Round_End); 

	new size = sizeof(commands_respawn);
	for (new i = 0; i < size; i++)
	{
		RegConsoleCmd(commands_respawn[i], CallRespawn);
	}

	h_MP_RESTARTGAME = FindConVar("mp_restartgame");
	if(h_MP_RESTARTGAME != INVALID_HANDLE)
		HookConVarChange(h_MP_RESTARTGAME, ConvarChanged)

	HookConVarChange(gBuyRespawnEnabled, ConVarChange);
	HookConVarChange(gBuyRespawnCost, ConVarChange);
	HookConVarChange(gBuyRespawnUses, ConVarChange);
	HookConVarChange(gBuyRespawnMessage, ConVarChange);

	respawn_enabled = GetConVarBool(gBuyRespawnEnabled);
	respawn_cost = GetConVarInt(gBuyRespawnCost);
	cRespawn_Uses = RoundToCeil(GetConVarFloat(gBuyRespawnUses));
	respawn_message = GetConVarInt(gBuyRespawnMessage);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	respawn_enabled = GetConVarBool(gBuyRespawnEnabled);
	respawn_cost = GetConVarInt(gBuyRespawnCost);
	cRespawn_Uses = RoundToCeil(GetConVarFloat(gBuyRespawnUses));
	respawn_message = GetConVarInt(gBuyRespawnMessage);
}

public Action:Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		respawn_uses[client] = 0;
	}
}

public ConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StrEqual(newVal, "1"))
	{
		for(new client = 1; client <= MaxClients; client++)
		{
			respawn_uses[client] = 0;
		}
	}
}

public OnClientPutInServer(client) 
{
	if(respawn_enabled != 1)
		return;
		
	if(respawn_message == 1) 
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01To buy respawn use: !respawn, !revive, !buyr, !buyrevive or !buyrespawn");
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01A new life costs: %d$", respawn_cost);
	}

	respawn_uses[client] = 0;
}

public OnClientDisconnect(client)
{
	respawn_uses[client] = 0;
}

public Action:CallRespawn(client, args)
{
	if(respawn_enabled != 1)
		return Plugin_Continue;

	if(!IsValidClient(client))
		return Plugin_Continue;

	if(GetClientTeam(client) <= 1)
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01This command is not available to spectators.");

		return Plugin_Continue;
	}

	if(IsPlayerAlive(client)) 
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You already have a life, do not need another !");

		return Plugin_Continue;
	}

	if(cRespawn_Uses != 0)
	{
		if(respawn_uses[client] >= cRespawn_Uses)
		{
			PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You can not buy more respawns in this round, the limit is %d !", cRespawn_Uses);

			return Plugin_Continue;
		}
	}

	new money = GetEntProp(client, Prop_Send, "m_iAccount");

	if(money < respawn_cost) 
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01Unfortunately you do not have money, the price of a new life is: %d$", respawn_cost);

		return Plugin_Continue;
	}

	SetEntProp(client, Prop_Send, "m_iAccount", money - respawn_cost);
	CS_RespawnPlayer(client);
	PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You bought a new life, be careful with it !");
	respawn_uses[client] += 1;

	return Plugin_Continue;	
}

public IsValidClient(client) 
{ 
	if (!( 1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 

	return true; 
}