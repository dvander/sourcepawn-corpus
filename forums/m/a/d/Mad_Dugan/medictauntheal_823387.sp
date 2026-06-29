#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new isHeaaling[33];
new isHealingCount[33];

public Plugin:myinfo = 
{
	name = "Medic Taunt Health",
	author = "Mad_Dugan",
	description = "Medic receives health bonus when taunting with medigun",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.com"
};

public OnPluginStart()
{
	CreateConVar("sm_mediheal_version", PLUGIN_VERSION, "TMedic Taunt Health Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	for (new i = 0; i < 33; i++)
	{
		isHeaaling[i] = 0;
		isHealingCount[i] = 0;
	}
}

public OnClientDisconnected(client)
{
	isHeaaling[client] = 0;
	isHealingCount[client] = 0;
}

public Action:OnClientCommand(client, args)
{
	new String:cmd0[91];
	//new String:cmd1[91];
	//new String:cmd2[91]
	GetCmdArg(0, cmd0, sizeof(cmd0));
	//GetCmdArg(1, cmd1, sizeof(cmd1));
	//GetCmdArg(2, cmd2, sizeof(cmd2));
	
	if (StrEqual(cmd0, "taunt"))
	{
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			new String:weapon[34];
			GetClientWeapon(client, weapon, 34); 
			if ((strcmp(weapon, "tf_weapon_medigun", false)) == 0)
			{
				if (isHeaaling[client] == 0)
				{
					FakeClientCommand(client, "voicemenu 2 2");
					isHeaaling[client] = 1;
					isHealingCount[client] = 30;
					CreateTimer(1.0, timer_SlowHeal, client);
					CreateTimer(60.0, timer_FinishedHealing, client);
				}
			}
		}
	}
}

public Action:timer_FinishedHealing(Handle:timer, any:client)
{
	isHeaaling[client] = 0;
	isHealingCount[client] = 0;

	return Plugin_Continue;
}

public Action:timer_SlowHeal(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			isHealingCount[client] -= 1;
			
			new health = GetClientHealth(client);
			
			if (health < 146)
			{
				SetEntityHealth(client, health + 1);
			}
			else
			{
				isHealingCount[client] = 0;
			}
			
			if(isHealingCount[client] > 0)
			{
				CreateTimer(0.1, timer_SlowHeal, client);
			}
		}
	}

	return Plugin_Continue;
}