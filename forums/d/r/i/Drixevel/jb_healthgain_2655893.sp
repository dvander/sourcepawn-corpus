//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>

//ConVars
ConVar convar_Gain;
ConVar convar_Max;

public Plugin myinfo = 
{
	name = "[JB] Healthgain", 
	author = "Drixevel", 
	description = "Gives CTs health on T kills.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_Gain = CreateConVar("sm_healthgain_value", "10", "Health to gain on T kill for CTs.", _, true, 0.0);
	convar_Max = CreateConVar("sm_healthgain_max", "250", "Max health for CTs to have.", _, true, 1.0);
	AutoExecConfig();
	
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || victim == attacker)
		return;
	
	if (GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
	{
		int health = GetClientHealth(attacker) + convar_Gain.IntValue;
		
		if (health > convar_Max.IntValue)
			health = convar_Max.IntValue;
		
		SetEntityHealth(attacker, health);
	}
}