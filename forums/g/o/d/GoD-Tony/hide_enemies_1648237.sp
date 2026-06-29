#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sendproxy>

public OnMapStart()
{
	new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
	}
	
	//SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
}

public Action:Hook_PlayerManager(entity, const String:propname[], &iValue, element)
{
	iValue = 0;
	return Plugin_Changed;
}
