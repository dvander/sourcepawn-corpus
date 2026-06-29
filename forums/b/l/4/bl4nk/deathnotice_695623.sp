#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.6"

new Handle:cvarMode;

public Plugin:myinfo = {
	name = "Death Notice",
	author = "bl4nk",
	description = "Tells the admins who killed who.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_deathnotice_version", PLUGIN_VERSION, "Death Notice Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarMode = CreateConVar("sm_deathnotice_mode", "1", "1 = Message admins, 2 = Message victim, 3 = Message everyone", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	HookEvent("player_death", event_PlayerDeath);
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (victim == attacker)
		return Plugin_Handled;

	switch(GetConVarInt(cvarMode))
	{
		case 1:
		{
			new maxclients = GetMaxClients();
			for (new i = 1; i <= maxclients; i++)
			{
				if (!IsClientConnected(i) || !IsClientInGame(i))
					continue;

				new clientFlags = GetUserFlagBits(i);
				if ((clientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC || (clientFlags & ADMFLAG_ROOT) == ADMFLAG_ROOT)
					PrintToChat(i, "%N killed %N", attacker, victim);
			}
		}
		case 2:
			PrintToChat(victim, "%N killed you", attacker);
		case 3:
			PrintToChatAll("%N killed %N", attacker, victim);
	}

	return Plugin_Handled;
}