#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Show last alive on HUD",
	author = "Sidezz",
	description = "",
	version = "1.0",
	url = "http://www.coldcommunity.com"
}

public OnClientPutInServer(client)
{
	CreateTimer(1.0, hudTick, client, TIMER_REPEAT);
}

public Action:hudTick(Handle:timer, any:client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}

	decl String:text[512], tAlive, ctAlive;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i))
		{
			continue;
		}
		if(IsPlayerAlive(i))
		{
			switch(GetClientTeam(i))
			{
				case CS_TEAM_CT: ctAlive++;
				case CS_TEAM_T: tAlive++;
			}
		}
	}

	if(tAlive > 1)
	{
		Format(text, sizeof(text), "Terrorists Alive: %i", tAlive);
	}
	else if(tAlive == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i))
			{
				continue;
			}

			if(IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				Format(text, sizeof(text), "Last Terrorist: %N", i);
			}
		}
	}

	if(ctAlive > 1)
	{
		Format(text, sizeof(text), "%s\nCounter-Terrorists Alive: %i", text, ctAlive);
	}
	else if(ctAlive == 1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i))
			{
				continue;
			}

			if(IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				Format(text, sizeof(text), "%s\nLast Counter-Terrorist: %N", text, i);
			}
		}
	}

	SetHudTextParams(-1.0, 0.865, 1.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
	ShowHudText(client, -1, text);
	PrintHintText(client, text);
	return Plugin_Handled;
}