#pragma semicolon 1
#include <sourcemod>
//#include <sdktools>
#include <sdkhooks>


public Action:eOnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamagetype)
{
	if(fDamage < 0.0)
		return Plugin_Continue;
	
	if(iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker) || GetClientTeam(iAttacker) != 2)
		return Plugin_Continue;
	
	if(iVictim < 1 || iVictim > MaxClients || !IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, eOnTakeDamage);
}

