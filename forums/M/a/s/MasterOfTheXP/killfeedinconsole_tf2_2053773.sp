#include <tf2_stocks>
#include <sdkhooks>

public OnPluginStart()
	HookEvent("player_death", Event_Death);

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[64];
	GetEventString(event, "weapon_logclassname", weapon, sizeof(weapon));
	if (attacker > 0 && attacker <= MaxClients && attacker != victim)
		PrintToServer("%N killed %N with %s.%s%s", attacker, victim, weapon, (GetEventInt(event, "damagebits") & DMG_CRIT) ? " (crit)" : "", (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) ? " (feign death)" : "");
	if (attacker == victim)
		PrintToServer("%N died.%s%s", victim, (GetEventInt(event, "damagebits") & DMG_CRIT) ? " (crit)" : "", (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) ? " (feign death)" : "");
	if (!attacker || attacker > MaxClients)
		PrintToServer("%N suicided.%s%s", victim, (GetEventInt(event, "damagebits") & DMG_CRIT) ? " (crit)" : "", (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) ? " (feign death)" : "");
	return Plugin_Continue;	
}