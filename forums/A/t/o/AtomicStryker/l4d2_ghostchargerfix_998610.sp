#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "L4D2 Ghost Charger Fix",
	author = "AtomicStryker",
	description = "Fixes the occasional ghost Charger pounding a Survivor",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	HookEvent("player_hurt", PlayerHurt);
	CreateConVar("l4d2_ghostchargerfix_version", PLUGIN_VERSION, "L4D2 Ghost Charger Fix plugin version on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public Action:PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new charger = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:Weapon[256];
	GetEventString(event, "weapon", Weapon, sizeof(Weapon));
	
	if ( StrEqual(Weapon, "charger_claw") && GetEntProp(charger, Prop_Send, "m_isGhost", 1) )
	{
		ForcePlayerSuicide(charger);
		PrintToChatAll("%N was slayed for becoming a Ghost Charger bug annoyance", charger);
	}
}