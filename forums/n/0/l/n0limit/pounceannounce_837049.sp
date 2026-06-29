
#include <sourcemod>

//globals
new Handle:maxPounceDistance;
new Handle:minPounceDistance;
new Handle:maxPounceDamage;
public Plugin:myinfo = 
{
	name = "PounceAnnounce",
	author = "n0limit",
	description = "Announces hunter pounces to entire server",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	maxPounceDistance = FindConVar("z_pounce_damage_range_max");
	minPounceDistance = FindConVar("z_pounce_damage_range_min");
	maxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	
	HookEvent("lunge_pounce",Event_PlayerPounced);
}

public Event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "userid");
	new victimId = GetEventInt(event, "victim");
	new distance = GetEventInt(event, "distance");
	new max = GetConVarInt(maxPounceDistance);
	new min = GetConVarInt(minPounceDistance);
	new maxDmg = GetConVarInt(maxPounceDamage);
	new Float:dmg = ((float(distance - min) / float(max - min)) * float(maxDmg)) + 1;
	
	decl String:attackerName[64];
	decl String:victimName[64];
	
	if(distance > min)
	{
		new attackerClient = GetClientOfUserId(attackerId);
		new victimClient = GetClientOfUserId(victimId);
		GetClientName(attackerClient,attackerName,sizeof(attackerName));
		GetClientName(victimClient,victimName,sizeof(victimName));
		PrintToServer("Pounce: max: %d min: %d dmg: %d dist: %d dmg: %f",max,min,maxDmg,distance, dmg);
		PrintHintTextToAll("%s pounced %s for %01f damage over a distance of %d",attackerName,victimName,dmg,distance);
	}
	
}