#pragma semicolon 1
#include <sourcemod>
#include <sendproxy>

public Plugin:myinfo =
{
    name 		=		"Health Fix",			// http://www.youtube.com/watch?v=DbwmAxhRbIw&hd=1
    author		=		"Kyle Sanderson",
    description	=		"Work around for the Health fuckup.",
    version		=		"1.0",
    url			=		"http://SourceMod.net"
};

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	if (!SendProxy_IsHooked(client, "m_iHealth"))
	{
		SendProxy_Hook(client, "m_iHealth", Prop_Int, ProxyCallback);
	}
}

public Action:ProxyCallback(entity, const String:propname[], &iValue)
{
	if (!IsValidClient(entity))
	{
		return Plugin_Continue;
	}
	
	if (iValue > 500)
	{
		iValue = RoundToCeil(iValue / 10.0);
		
		if (iValue > 500)
		{
			iValue = 500;
		}
	
		ChangeEdictState(entity);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	return ((0 < client <= MaxClients) && IsClientInGame(client) && IsPlayerAlive(client));
}