#include <sourcemod>
#include <sdktools>
#include <sdkhooks> 
#pragma semicolon 1


public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action:Hook_SetTransmit(client, entity)
{
	if( client == entity || GetClientTeam(client) != GetClientTeam(entity))
		return Plugin_Continue;
	return Plugin_Handled;
}
 