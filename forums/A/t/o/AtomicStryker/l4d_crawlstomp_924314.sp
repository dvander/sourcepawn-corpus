#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_NAME "L4D Crawl Stomp"


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Suffering damage while on the ground immobilizes you ",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action:Event_PlayerHurt (Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	new victim=GetClientOfUserId(GetEventInt(event,"userid"));

	if (victim == 0 || attacker == 0) return Plugin_Continue;
	if (GetClientTeam(victim) != 2) return Plugin_Continue;
	if (!IsPlayerIncapped(victim)) return Plugin_Continue;
	
	SetEntityMoveType(victim, MOVETYPE_NONE);
	CreateTimer(1.5, ResetMove, victim);
}

public Action:ResetMove(Handle:timer, any:victim)
{
	SetEntityMoveType(victim, MOVETYPE_WALK);
}

bool:IsPlayerIncapped(client)
{
	new propincapped = FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated");
	new isincapped = GetEntData(client, propincapped, 1);
	if (isincapped == 1) return true;
	else return false;
}