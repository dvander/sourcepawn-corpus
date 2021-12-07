#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


public OnMapStart()
{
	CreateTimer(5.0, Repetidor, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Repetidor(Handle:timer)
{
  	for (new i = 1; i < GetMaxClients(); i++)
  	{
		if (IsClientInGame(i))
		{
            		QueryClientConVar(i, "cam_idealyaw", CheckQuery, i);
		}
  	}
}

public CheckQuery(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "0") && IsClientInGame(client))
	{
		KickClient(client, "Incorrect value of cam_idealyaw");
	}
}