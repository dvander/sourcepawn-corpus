#include <sourcemod>
#pragma semicolon 1
new Handle:CvarEnabled;

public Plugin:myinfo =
{
	name = "Dxlevel Restrict",
	author = "KK",
	description = "Simple kick players if there's dxlevel not are 80 or 81",
	version = "1.0",
	url = "http://www.attack2.co.cc/"
};

public OnPluginStart() 
{
	CvarEnabled = CreateConVar("sm_dxlevel_restrict_enabled", "1", "Sets whether Dxlevel Restrict is enabled");
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(CvarEnabled))
	{	
		QueryClientConVar(client, "mat_dxlevel", ConVarQueryFinished:QueryCallback);
	}
}

public QueryCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (StrEqual(cvarName, "mat_dxlevel") && IsClientConnected(client) && IsClientInGame(client))
	{
		new cvarValue2 = StringToInt(cvarValue);

		if (cvarValue2 != 80 && cvarValue2 != 81)
		{
			KickClient(client, "You need to set mat_dxlevel to 80 or 81..");
		}
	}
}
