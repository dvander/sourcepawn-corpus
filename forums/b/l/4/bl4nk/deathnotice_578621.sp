#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.3"

public Plugin:myinfo = {
	name = "Death Notice",
	author = "bl4nk",
	description = "Tells the admins who killed who.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	HookEvent("player_death", hooplah);
}

public Action:hooplah(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (attacker == victim)
	{
		return Plugin_Handled;
	}

	new String:victimName[32];
	GetClientName(victim, victimName, sizeof(victimName));

	new String:attackerName[32];
	GetClientName(attacker,attackerName,sizeof(attackerName));

	MessageToAdmins(victimName, attackerName);

	return Plugin_Handled;
}

MessageToAdmins(String:victim[], String:attacker[])
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (!IsClientInGame(i))
			return;

		new clientFlags = GetUserFlagBits(i);
		if ((clientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC || (clientFlags & ADMFLAG_ROOT) == ADMFLAG_ROOT)
			PrintToChat(i, "%s killed %s", attacker, victim);
	}
}