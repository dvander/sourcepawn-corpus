#include <sourcemod>
#include <morecolors>

public Plugin:myinfo =
{
	name = "Log kills - Console & Chat edition",
	author = "Arkarr",
	description	= "Display who get killed by who !",
	version	= "1.0",
	url	= "http://www.sourcemod.net"
};

public OnPluginStart()
{
	PrintToServer("---------- KILL LOGGER STARTED ----------");
	HookEvent("player_death", Event_PlayerDeath);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:killer_name[100];
	decl String:victim_name[100];
	
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	GetClientName(killer, killer_name, sizeof(killer_name));
	GetClientName(victim, victim_name, sizeof(victim_name));
	
	for(new i = 1; i < MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_admin", ADMFLAG_ROOT,true) && IsValidClient(i))
		{
			if(killer == victim)
			{
				CPrintToChat(i, "{fullred}[Kill Info]{default} %s suicided !", victim_name);
				PrintToConsole(i, "[Kill Info] %s suicide !", victim_name);
			}
			else
			{
				CPrintToChat(i, "{fullred}[Kill Info]{default} %s killed %s !", killer_name, victim_name);
				PrintToConsole(i, "[Kill Info] %s killed %s !", killer_name, victim_name);
			}
		}
	}
	
	return Plugin_Continue
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

