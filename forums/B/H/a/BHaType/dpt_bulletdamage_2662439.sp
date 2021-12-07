#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "[CSGO] Simple Bullet Damage",
	author = "DPT",
	version = "1.0",
	description = "Shows amount of damage inflicted upon shooting the enemy",
	url = ""
};

public void OnPluginStart() 
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		int damagevalue = event.GetInt("dmg_health");
		
		SetHudTextParams(-1.0, -0.55, 0.5, 255, 255, 255, 1);	
		ShowHudText(attacker, -1, "%d", damagevalue);
	}
}
