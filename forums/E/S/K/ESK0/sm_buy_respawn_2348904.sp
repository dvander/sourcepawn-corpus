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

Handle gBuyRespawnEnabled = INVALID_HANDLE;
Handle gBuyRespawnCost = INVALID_HANDLE;
Handle gBuyRespawnMessage = INVALID_HANDLE;
Handle gBuyRespawnUses = INVALID_HANDLE;
Handle h_MP_RESTARTGAME = INVALID_HANDLE;
int respawn_enabled;
int respawn_cost;
int respawn_message;
int cRespawn_Uses;
int respawn_uses[MAXPLAYERS+1];

char commands_respawn[][] = {"sm_respawn", "sm_buyr","sm_revive","sm_buyrevive","sm_buyrespawn"};

public Plugin myinfo = {
	name = "SM: Buy Respawn",
	author = "Rodrigo286, Updated by ESK0",
	description = "Allows players to buy a respawn",
  version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

public void OnPluginStart()
{
	CreateConVar("sm_buyrespawn_version", PLUGIN_VERSION, "\"SM: Buy Respawn\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gBuyRespawnEnabled = CreateConVar("sm_buyrespawn_enabled", "1", "\"1\" = \"SM: Buy Respawn\" plugin is enabled, \"0\" = \"SM: Buy Respawn\" plugin is disabled");
	gBuyRespawnCost = CreateConVar("sm_buyrespawn_cost", "5000.0", "Set the price for the relive(respawn)", FCVAR_NONE, true, 0.0, true, 16000.0);
	gBuyRespawnUses = CreateConVar("sm_buyrespawn_per_round", "10", "Set the max respawns per round(respawn)", FCVAR_NONE, true, 0.0, true, 99.0);
	gBuyRespawnMessage = CreateConVar("sm_buyrespawn_message", "1", "\"1\" = \"SM: Buy Respawn\" message is enabled, \"0\" = \"SM: Buy Respawn\" message is disabled");
	AutoExecConfig(true, "sm_buy_respawn");
	HookEvent("round_end", Round_End);
	for (int i = 0; i < sizeof(commands_respawn); i++)
	{
		RegConsoleCmd(commands_respawn[i], CallRespawn);
	}
	h_MP_RESTARTGAME = FindConVar("mp_restartgame");

	if(h_MP_RESTARTGAME != INVALID_HANDLE) HookConVarChange(h_MP_RESTARTGAME, ConvarChanged)

	HookConVarChange(gBuyRespawnEnabled, ConVarChange);
	HookConVarChange(gBuyRespawnCost, ConVarChange);
	HookConVarChange(gBuyRespawnUses, ConVarChange);
	HookConVarChange(gBuyRespawnMessage, ConVarChange);

	respawn_enabled = GetConVarBool(gBuyRespawnEnabled);
	respawn_cost = GetConVarInt(gBuyRespawnCost);
	cRespawn_Uses = RoundToCeil(GetConVarFloat(gBuyRespawnUses));
	respawn_message = GetConVarInt(gBuyRespawnMessage);
}

public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	respawn_enabled = GetConVarBool(gBuyRespawnEnabled);
	respawn_cost = GetConVarInt(gBuyRespawnCost);
	cRespawn_Uses = RoundToCeil(GetConVarFloat(gBuyRespawnUses));
	respawn_message = GetConVarInt(gBuyRespawnMessage);
}

public Action Round_End(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		respawn_uses[client] = 0;
	}
}
public void ConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if(StrEqual(newVal, "1"))
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			respawn_uses[client] = 0;
		}
	}
}

public void OnClientPutInServer(client)
{
  if(IsValidClient(client))
  {
		if(respawn_message)
		{
			PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01To buy respawn use: !respawn, !revive, !buyr, !buyrevive or !buyrespawn");
			PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01A new life costs: %d$", respawn_cost);
		}
		respawn_uses[client] = 0;
  }
}

public void OnClientDisconnect(client)
{
	respawn_uses[client] = 0;
}

public Action CallRespawn(client, args)
{
	if(IsValidClient(client))
	{
		if(respawn_enabled)
		{
			if(GetClientTeam(client) > 1)
			{
				if(IsPlayerAlive(client))
				{
					if(cRespawn_Uses != 0)
					{
						if(respawn_uses[client] >= cRespawn_Uses)
						{
							PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You can not buy more respawns in this round, the limit is %d !", cRespawn_Uses);
						}
						else
						{
							int money = GetEntProp(client, Prop_Send, "m_iAccount");
							if(money < respawn_cost)
							{
								PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01Unfortunately you do not have money, the price of a new life is: %d$", respawn_cost);
							}
							else
							{
								SetEntProp(client, Prop_Send, "m_iAccount", money - respawn_cost);
								CS_RespawnPlayer(client);
								PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You bought a new life, be careful with it !");
								respawn_uses[client]++;
							}
						}
					}
				}
				else
				{
					PrintToChat(client, "\x03[\x04SM: Buy Respawn\x03] \x01You already have a life, do not need another !");
				}
			}
		}
	}
}
stock bool IsValidClient(client, bool alive = false)
{
  if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
  {
    return true;
  }
  return false;
}
