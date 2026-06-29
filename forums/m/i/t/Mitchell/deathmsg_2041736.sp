
#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = {
	name = "Console Death Messages",
	author = "Mitch",
	description = "Shows who killed who in client's console.",
	version = "0.2",
	url = "SnBx.info"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
}
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	new String:DeathMessage[256];
	if(attacker > 0)
		if(!StrEqual(weapon, "", false))
			Format(DeathMessage, sizeof(DeathMessage), "%N killed %N with %s.", attacker, client, weapon);
		else
			Format(DeathMessage, sizeof(DeathMessage), "%N killed %N.", attacker, client);
	else
		Format(DeathMessage, sizeof(DeathMessage), "%N committed suicide.", client);
	
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			PrintToConsole(i, DeathMessage);
}