#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "Left 4 Dead Teamkill disable",
	author = "Joshua Coffey",
	description = "Kills TKers",
	version = "2.0.0.0",
	url = "http://www.sourcemod.net/"
};


public OnPluginStart()
{
   HookEvent("player_incapacitated", Event_PlayerIncapacitated)

}
 
public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
   new victim_id = GetEventInt(event, "userid")
   new attacker_id = GetEventInt(event, "attacker")
 
   new victim = GetClientOfUserId(victim_id)
   new attacker = GetClientOfUserId(attacker_id)
   


if (GetClientTeam(victim) == GetClientTeam(attacker)){
	ForcePlayerSuicide(attacker);
	PrintToChatAll ("Teamkiller was killed.");
}

}