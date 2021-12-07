#pragma semicolon 1

#include <sourcemod>

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source)
{
	CreateTimer(0.1, Timer_WriteID);
	return Plugin_Continue;
}

public Action:Timer_WriteID(Handle:timer)
{
	ServerCommand("writeid");	
	return Plugin_Stop;
}
