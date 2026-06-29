#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "1"

new bool:sd;

new Handle:plugin_enable;
new Handle:cvheal = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Drunken Heal",
	author = "Dragonshadow - A.K.A - Fire",
	description = "Demoman Bottle Taunt Now Heals",
	version = PLUGIN_VERSION,
	url = "http://www.snigsclan.com"
}

new drinking[33];

public OnPluginStart()
{
	CreateConVar("sm_drunkenheal_version", PLUGIN_VERSION, "Drunken Heal Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvheal = CreateConVar("sm_drunkenheal_amount", "15", "Amount Healed By Bottle (Default 15)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	plugin_enable = CreateConVar("sm_drunkenheal_enable", "1", "Enable/Disable Drunken Heal", FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);

}

public OnEventShutdown()
{
	UnhookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	UnhookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	UnhookEvent("teamplay_round_win", Event_SuddenDeathEnd);
}

public OnMapStart()
{
	sd = false;
}

public Action:OnClientCommand(client, args)
{	
	if (GetConVarInt(plugin_enable) != 0)
	{
		new String:cmd0[91];
		GetCmdArg(0, cmd0, sizeof(cmd0));
		if (StrEqual(cmd0, "taunt"))
		{
			if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
			{
				new String:weapon[34];
				GetClientWeapon(client, weapon, 34); 
				if ((strcmp(weapon, "tf_weapon_bottle", false)) == 0)
				{
					if (sd != true)
					{ 
						if (drinking[client] == 0)
						{
							drinking[client] = 1;
							CreateTimer(2.2, startdrinkin, client);
							CreateTimer(4.5, donedrinkin, client);
						}
					}
					else
					{
						PrintHintText(client, "Drunken Heal Disabled In Sudden Death!");
					}
					
				}
			}
		}
	}
	return Plugin_Continue;
}



public Action:donedrinkin(Handle:timer, any:client)
{
	{
		drinking[client] = 0;
	}
	return Plugin_Continue;
}

public Action:startdrinkin(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			new hp = GetConVarInt(cvheal);
			new health = GetClientHealth(client);
			if (health + hp >= 175)
			{
				SetEntityHealth(client, 175);
			}
			else if (health + hp < 175)
			{
				SetEntityHealth(client, health + hp);
			}

		}
	}
	return Plugin_Continue;
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	sd = true;
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	sd = false;
}