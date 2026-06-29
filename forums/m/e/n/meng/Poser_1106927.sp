#include <sourcemod>
#include <sdktools>

new Handle:g_cvarEnabled;

public OnPluginStart()
{
	g_cvarEnabled = CreateConVar("sm_poser_enabled", "1", "Enable/Disable plugin.", _, true, 0.0, true, 1.0);

	HookEvent("player_death", EventPlayerDeath);
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!GetConVarBool(g_cvarEnabled))
	{
		return;
	}

	decl String:sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if (!StrEqual(sWeapon, "knife"))
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ((attacker == 0) || (GetClientTeam(attacker) == GetClientTeam(victim)))
	{
		return;
	}

	decl String:sVictimModel[64];
	GetClientModel(victim, sVictimModel, sizeof(sVictimModel));
	SetEntityModel(attacker, sVictimModel);
}