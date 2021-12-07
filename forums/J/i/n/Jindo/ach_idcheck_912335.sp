/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <customachievements>

public Plugin:myinfo = 
{
	name = "Achievement by Steam ID",
	author = "Jindo",
	description = "Track deaths by Steam ID and award achievements",
	version = "0.1",
	url = "http://www.topaz-games.com"
}

public OnPluginStart()
{
	HookEvent("player_death", eCheckID);
}

public Action:eCheckID(Handle:event, const String:name[], bool:noBroadcast)
{
	new victim = GetEventInt(event, "userid");
	new rvictim = GetClientOfUserId(victim);
	new attacker = GetEventInt(event, "attacker");
	new rattacker = GetClientOfUserId(attacker);
	decl String:victimID[256];
	GetClientAuthString(rvictim, victimID, sizeof(victimID));
	decl String:attackerID[256];
	GetClientAuthString(rattacker, attackerID, sizeof(attackerID));
	if (StrEqual(victimID, "STEAM_0:1:14783567", true)) // check if the victim's steam id matches the id in the condition
	{
		ProcessAchievement(1, rattacker); // give the killer achievement #1
	}
	if (StrEqual(attackerID, "STEAM_0:1:14783567", true)) // check if the killer's steam id matches the id in the condition
	{
		ProcessAchievement(2, rvictim); // give the killer achievement #2
	}
}