#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Bullet Damage",
	author = "SAMURAI",
	description = "Display damage done",
	version = "0.1",
	url = "www.cs-utilz.net"
}

new Handle:p_cvar = INVALID_HANDLE;


public OnPluginStart()
{
	HookEvent("player_hurt",event_player_hurt);
	
	p_cvar = CreateConVar("bulletdamage_mode","1"); // 1 = health damage ;  2 = armor damage
}

public Action:event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	if(!IsPlayerAlive(attacker) && !IsClientInGame(attacker))
		return Plugin_Continue;
	
	if(GetConVarInt(p_cvar) == 1)
	{
		new dmg_health = GetEventInt(event,"dmg_health");
		
		if(dmg_health > 0)
			PrintCenterText(attacker,"%i",dmg_health);
	}
	
	else if(GetConVarInt(p_cvar) == 2)
	{
		new dmg_armor = GetEventInt(event,"dmg_armor");
		
		if(dmg_armor > 0)
			PrintCenterText(attacker,"%i",dmg_armor);
	}
	
	return Plugin_Continue;
}
		
	
	
