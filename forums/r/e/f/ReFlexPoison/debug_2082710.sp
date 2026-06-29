#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	RegAdminCmd("sm_debug", Command_Debug, ADMFLAG_ROOT, "Debug");
}

// ====[ COMMANDS ]============================================================
public Action:Command_Debug(iClient, iArgs)
{
	if(!IsValidClient(iClient))
		return Plugin_Continue;

	PrintToChat(iClient, "m_CollisionGroup: %i", GetEntProp(iClient, Prop_Send, "m_CollisionGroup"));
	PrintToChat(iClient, "m_usSolidFlags: %i", GetEntProp(iClient, Prop_Send, "m_usSolidFlags"));
	return Plugin_Handled;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}