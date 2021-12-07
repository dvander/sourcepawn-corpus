#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0.1"

new Handle:gBuyRespawnEnabled = INVALID_HANDLE;
new Handle:gBuyRespawnCost = INVALID_HANDLE;
new Handle:gBuyRespawnMessage = INVALID_HANDLE;
new respawn_cost;

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
	gBuyRespawnMessage = CreateConVar("sm_buyrespawn_message", "1", "\"1\" = \"SM: Buy Respawn\" message is enabled, \"0\" = \"SM: Buy Respawn\" message is disabled");

	new size = sizeof(commands_respawn);
	for (new i = 0; i < size; i++)
	{
		RegConsoleCmd(commands_respawn[i], CallRespawn);
	}
}

public OnMapStart() 
{
	respawn_cost = GetConVarInt(gBuyRespawnCost);
}

public OnClientPutInServer(client) 
{
	if(GetConVarInt(gBuyRespawnMessage) == 1 && GetConVarInt(gBuyRespawnEnabled) == 1) 
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01To buy respawn use: !respawn, !revive, !buyr, !buyrevive or !buyrespawn");
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01A new life costs: %d$", respawn_cost);
	}
}

public Action:CallRespawn(client, args)
{
	if(client < 1 || GetConVarInt(gBuyRespawnEnabled) != 1)
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

	new money = GetEntProp(client, Prop_Send, "m_iAccount");

	if(money < respawn_cost) 
	{
		PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01Unfortunately you do not have money, the price of a new life is: %d$", respawn_cost);

		return Plugin_Continue;
	}

	SetEntProp(client, Prop_Send, "m_iAccount", money - respawn_cost);
	CS_RespawnPlayer(client);
	PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You bought a new life, be careful with it !");

	return Plugin_Continue;	
}

public IsValidClient(client) 
{ 
	if (!( 1 <= client <= MaxClients) || !IsClientInGame(client)) 
		return false; 

	return true; 
}