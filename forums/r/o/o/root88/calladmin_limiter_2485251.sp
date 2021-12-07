#include <sourcemod>
#include <calladmin>
#pragma semicolon 1


new i_ReportCount[MAXPLAYERS+1] = 0;
new i_LastReportingClient = 0;

public OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnected);
}

public Action:CallAdmin_OnReportPre(client, target, const String:reason[])
{
	if(i_LastReportingClient == client)
	{
		PrintToChat(client, "\x04[CALLADMIN]\x03 You've already reported a player. STOP SPAMMING!");
		return Plugin_Stop;
	}
	if (i_ReportCount[target] < 2)
	{
		i_LastReportingClient = client;
		i_ReportCount[target]++;
		PrintToChat(client, "\x04[CALLADMIN]\x03 Your report is waiting for confirmation.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:PlayerDisconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	i_ReportCount[client] = 0;
}

public void CallAdmin_OnReportPost(client, target, const String:reason[])
{
	i_ReportCount[target] = 0;
}
