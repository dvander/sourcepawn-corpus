#pragma semicolon 1
#include <sourcemod>
#include <devzones>
#include <tf2>
#incldue <tf2_stocks>

#define PLUGIN_VERSION "1.0"

new bool:IsInZone[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name        =    "Boxing Zone",
	author        =    "Pelipoika",
	description    =    "Only heavy with melee.",
	version        =    PLUGIN_VERSION,
	url            =    "http://www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	RegAdminCmd("sm_killboxers", Command_ZoneKill, ADMFLAG_ROOT);
}

public Action:Command_ZoneKill(client, args)
{
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsInZone[i]) continue;
		ForcePlayerSuicide(i);
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsInZone[client])
	{	
		IsInZone[client] = false;
	}
}

public Zone_OnClientEntry(client, String:zone[])
{
	if (StrContains(zone, "Boxing", false) == 0)
	{
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);  
		
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		
		TF2_RemoveCondition(client, TFCond_Slowed);
		TF2_RemoveCondition(client, TFCond_Zoomed);
		
		IsInZone[client] = true;
	}
}

public Zone_OnClientLeave(client, String:zone[])
{
	if (StrContains(zone, "Boxing", false) == 0)
	{
		//Uncomment this if you want the player to get his weapons back after he leaves the boxing zone
		//TF2_RegeneratePlayer(client);
		IsInZone[client] = false;
	}
}