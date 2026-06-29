#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <colors>
#include <updater>

#define		MAX_WEAPON_STRING		80

new Handle:ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

public Plugin:myinfo = 
{
	name = "Zeus Refill",
	author = "TnTSCS aka ClarkKent (Simplified by VJScope)",
	description = "If you kill with taser, you get another one",
	version = "",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:weapon[MAX_WEAPON_STRING];
	weapon[0] = '\0';
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (StrEqual(weapon, "taser", false) || StrEqual(weapon, "knife", false))
	{
		ClientTimer[killer] = CreateTimer(0.5, Timer_GiveZeus, killer);
	}
}

public Action:Timer_GiveZeus(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	GivePlayerItem(client, "weapon_taser");
}