// 1 spec
// 2 Ts
// 3 Cts

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define FADE_IN 0x0001
#define SPEC 1
#define TS 2
#define CTS 3 

new Handle:g_Cvar_round_restart_delay;
new Handle:g_adtClientlist;
new Handle:g_adtPlayers;
new g_teamT;
new g_teamCT;
new g_diff;

public Plugin:myinfo =
{
	name = "Team-Balancer",
	author = "FreeZ",
	version = "1.1",
	description = "Simple Team-Balancer",
	url = "http://gts-fun.de"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd)
	g_Cvar_round_restart_delay = FindConVar("mp_round_restart_delay");
	PrintToChatAll("[TB] Team-Balancer is loaded")
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:restart_delay = GetConVarFloat(g_Cvar_round_restart_delay);
		
	CreateTimer((restart_delay-0.1), Balance);
}

public Action:Balance(Handle:timer)
{
	g_teamT = GetTeamClientCount(TS);
	g_teamCT = GetTeamClientCount(CTS);
	g_diff = g_teamT - g_teamCT;
	
	if (g_diff < 0)
	{
		g_diff = -g_diff;
	}
	
	g_diff = RoundToFloor(Float:(g_diff/2.0)+1);
	
	g_adtClientlist = CreateArray(3);
	g_adtPlayers = CreateArray(3);
	
	if (g_teamT > (g_teamCT + 1))
	{
		if (GetTeamClientCount(TS) > 0)
		{
			//Clientliste erstellen
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TS) && (GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					PushArrayCell(g_adtClientlist, i);
				}
			}
			clientuebergeber();
		}
		switcher(0, 0, 255, 255, FADE_IN, CTS);
	}
	
	if (g_teamCT > (g_teamT + 1))
	{
		if (GetTeamClientCount(CTS) > 0)
		{
			//Clientliste erstellen
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == CTS) && (GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					PushArrayCell(g_adtClientlist, i);
				}
			}
			clientuebergeber();
		}
		switcher(255, 0, 0, 255, FADE_IN, TS);
	}

}

public Action:clientuebergeber()
{
	new randomnumber;
	
	if (GetArraySize(g_adtClientlist)+1 < g_diff)
	{
		g_diff = GetArraySize(g_adtClientlist)+1;
	}

	//Switch-Clientliste erstellen
	for (new j=1; j<g_diff; j++)
	{
		randomnumber = GetRandomInt(0, GetArraySize(g_adtClientlist)-1);
		PushArrayCell(g_adtPlayers, GetArrayCell(g_adtClientlist, randomnumber));
		RemoveFromArray(g_adtClientlist, randomnumber);
	}

}

public Action:switcher(red, green, blue, alpha, type, newteam)
{
	new Handle:msg;
	new duration;
	
	duration = 0;
		
	for (new i=1; i<g_diff; i++)
	{
		CS_SwitchTeam(GetArrayCell(g_adtPlayers, i-1), newteam);
		PrintCenterText(GetArrayCell(g_adtPlayers, i-1), "ACHTUNG: Du bist nun im anderen Team!")
		
		msg = StartMessageOne("Fade", GetArrayCell(g_adtPlayers, i-1));
		BfWriteShort(msg, 500);
		BfWriteShort(msg, duration);
		BfWriteShort(msg, type);
		BfWriteByte(msg, red);
		BfWriteByte(msg, green);
		BfWriteByte(msg, blue);
		BfWriteByte(msg, alpha);
		EndMessage();
	}
	
	ClearArray(g_adtClientlist);
	ClearArray(g_adtPlayers);
	
}