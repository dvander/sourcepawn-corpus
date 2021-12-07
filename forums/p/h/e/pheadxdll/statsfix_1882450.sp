#include <sourcemod>

new bool:g_bBlockLog = false;

public OnPluginStart()
{
	HookEvent("player_builtobject", Event_PlayerBuiltObjectPre, EventHookMode_Pre);
	
	AddGameLogHook(OnGameLog);
}

public Action:Event_PlayerBuiltObjectPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients && IsClientInGame(client))
	{
		new iBuilding = GetEventInt(event, "index");
		if(iBuilding > MaxClients && IsValidEntity(iBuilding) && GetEntProp(iBuilding, Prop_Send, "m_bCarryDeploy"))
		{
			g_bBlockLog = true;
		}
	}
	
	return Plugin_Continue;
}

public Action:OnGameLog(const String:message[])
{
	if(g_bBlockLog)
	{
		g_bBlockLog = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}