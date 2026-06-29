#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

new Handle:h_ShowHealth,
	bool:b_late;

new i_health[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[ZR] Health Fix",
	author = "FrozDark (HlModders.ru LLC)",
	description = "It will fix the bug with Health",
	version = "1.1",
	url = "http:/www.hlmod.ru"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	b_late = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("zr_healthfix_version", "1.1", "The plugin's version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	h_ShowHealth	=	CreateConVar("zr_healthfix_showhealth", "1", "Enables showing the health in hud.", 0, true, 0.0, true, 1.0);
	
	if (b_late)
	{
		b_late = false;
		OnMapStart();
	}
}

public OnMapStart()
{
	CreateTimer(1.0, ShowHealth, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ShowHealth(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (GetConVarBool(h_ShowHealth) && IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientZombie(i))
		{
			PrintHintText(i, "%d HP", i_health[i]);
		}
	}
}

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientFrame(i);
}

OnClientFrame(client)
{
	if (!IsPlayerAlive(client))
		return;
	
	new health = GetClientHealth(client);
	
	if (health > 500)
	{
		i_health[client] = health;
		SetEntityHealth(client, 500);
	}
	
	if (health < 500)
	{
		if (i_health[client] > 500)
		{
			i_health[client] = i_health[client] - (500 - health);
			
			if (i_health[client] > 500)
				SetEntityHealth(client, 500);
			else
				SetEntityHealth(client, i_health[client]);
		}
		else
			i_health[client] = health;
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (client > 0)
		i_health[client] = GetClientHealth(client);
		
	if (attacker > 0)
		i_health[attacker] = GetClientHealth(attacker);
}

public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	if (client > 0)
		i_health[client] = GetClientHealth(client);
}