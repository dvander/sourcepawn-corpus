#include <sourcemod>
 
new Handle:g_hEnforceMOTD;
new g_iHTMLenabled = 0;

public Plugin:myinfo =
{
	name = "Enforce MOTD",
	description = "Enforce Player To Have cl_disablehtmlmotd Set To 0",
	author = "8GuaWong",
	version = "1.0",
	url = "http://www.blackmarke7.com"
};

public OnPluginStart()
{
	g_hEnforceMOTD = CreateConVar("sm_enforce_motd", "1");
	AddCommandListener(Check_Allowed, "jointeam");
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Pre);
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(g_hEnforceMOTD))
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action:Check_Allowed(client, const String:command[], argc)
{
	if (!GetConVarInt(g_hEnforceMOTD))
		return Plugin_Continue;

	decl String:m_szTeam[8];
	GetCmdArg(1, m_szTeam, sizeof(m_szTeam));
	new m_iTeam = StringToInt(m_szTeam);
	
	if (m_iTeam > 0)
	{
		QueryClientConVar(client, "cl_disablehtmlmotd", ConVar_QueryClient);
		if(g_iHTMLenabled)
			return Plugin_Continue;
		else
		{
			PrintCenterText(client, "You Need To Set cl_disablehtmlmotd To 0 In Order To Play");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public ConVar_QueryClient(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result == ConVarQuery_Okay)
		if (StringToInt(cvarValue))
			g_iHTMLenabled = 0;		
		else
			g_iHTMLenabled = 1;
}