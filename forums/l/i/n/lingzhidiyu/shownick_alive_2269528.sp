#include <zombiereloaded>
#include <sdktools>
#include <cstrike>
#include <sourcemod>

#define PLUGIN_VERSION   "[ZR] 1.0"

new bool:g_bClientShowHUD[MAXPLAYERS + 1];
new Handle:g_hOnlyTeanmate;

public Plugin:myinfo =
{
	name = "[ZR] Show nickname on HUD",
	author = "Graffiti & Oshizu",
	description = "Show nickname on HUD for CSGO",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_show", Command_ShowHud);
	CreateConVar("sm_show_nickname_on_hud_version", PLUGIN_VERSION, "Show nickname on HUD", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_hOnlyTeanmate = CreateConVar("sm_show_only_teammate", "1");
	CreateTimer(0.1, Timer, _, TIMER_REPEAT);
}

public Action:Command_ShowHud(client, args)
{
	if (g_bClientShowHUD[client])
	{
		g_bClientShowHUD[client] = false;
	}
	else
	{
		g_bClientShowHUD[client] = true;
	}
}

public OnClientDisconnect(client)
{
	g_bClientShowHUD[client] = false;
}

public Action:Timer(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (g_bClientShowHUD[i] && IsClientInGame(i))
		{
			new target = GetClientAimTarget(i) 
			if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
			{
				if(GetConVarBool(g_hOnlyTeanmate))
				{
					if (!IsPlayerAlive(i) || ZR_IsClientHuman(i) == ZR_IsClientHuman(target) || ZR_IsClientZombie(i) == ZR_IsClientZombie(target))
					{
						PrintHintText(i, "Player: \"%N\"", target);
					}
				}
				else
				{
					if (!IsPlayerAlive(i))
					{
						PrintHintText(i, "Player: \"%N\"", target);
					}
				}
			}
		}
	}
	return Plugin_Continue; 
}