#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Spectator List",
	author = "NinjaSK credits to GoD-Tony",
	description = "View who is spectating you in CS:S",
	version = 1.0,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_speclist", Command_SpecList);
}

public Action:Command_SpecList(client, args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[SpecList]\x03 You need to be alive to use this command.");
		return Plugin_Handled;
	}
	if(!IsClientInGame(client))
	{
		PrintToChat(client, "\x04[SpecList]\x03 You need to be alive to use this command.");
		return Plugin_Handled;
	}
	new player = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	decl String:spectatorBuffer[365];
	new observer;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i) == 1)
		{
			observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(player == observer)
				GetClientName(i, spectatorBuffer, sizeof(spectatorBuffer));
				//Format(spectatorBuffer, sizeof(buffer), "%s,", userName); Need to make a correct format of Player1, Player2, Player3...
		}
	}
	PrintToChat(client,"\x04[SpecList]\x03 Speclist:\x01 %s",spectatorBuffer);
	return Plugin_Handled;
}