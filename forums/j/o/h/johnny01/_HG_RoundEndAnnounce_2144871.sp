#pragma semicolon 1
#include <sdktools>

public Plugin:myinfo =
{
    name = "[HG] RoundEndAnnounce",
    author = "Johnny [Method by TnTSCS]",
    description = "Checks players remaining",
    version = "1.0"
}

public OnPluginStart()
{
	HookEvent("round_end", EventRoundEnd);
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetPlayerCount() >= 2)
	{
		for (client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
	}
	else if (GetPlayerCount() == 1)
	{	
		for (client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				new rHealth = GetClientHealth(client);
				new rArmor = GetEntProp(client, Prop_Send, "m_ArmorValue");
				new String:player[32];
				GetClientName(client, player, sizeof(player));
				
				PrintToChatAll(" \x04%s \x05has won the round with [%d Health || %d Armor]", player, rHealth, rArmor);
			}
		}
	}
}


stock GetPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
		{
			players++;
		}
	}
	return players;
}