#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

new Float:g_lastTimeUsed[MAXPLAYERS+1];

public Plugin:myinfo=
{
	name="resetscore",
	author="SynysteR",
	description="Resets your score with command sm_resetscore or sm_rs",
	version="1.0",
	url="http://offensive.co.il"
}
public OnPluginStart()
{
	RegConsoleCmd("sm_rs", Command_ResetScore, "The command to reset your score");
	RegConsoleCmd("sm_resetscore", Command_ResetScore, "The second command to reset your score");
	CreateTimer(420.0, resetscore, _, TIMER_REPEAT);
}

public OnMapStart()
{
	for (new i=0;i<sizeof(g_lastTimeUsed);i++)
		g_lastTimeUsed[i]=-1.0;
}

public OnClientConnected(client)
{
	g_lastTimeUsed[client]=-1.0;
}
public Action:Command_ResetScore(client, args)
{
	new Team = GetClientTeam(client);
	if (g_lastTimeUsed[client]!=-1.0 && GetGameTime() - g_lastTimeUsed[client] < 300.0) 
	{
		PrintToChat(client, "\x04[SM] \x03You may only use this command once every 5 minutes.");
		return Plugin_Handled;
	}

	if(Team == 1)
	{
		PrintToChat(client, "\x04[SM] \x03You can't use this command in Spectators.");
		return Plugin_Handled;
	}

	g_lastTimeUsed[client] = GetGameTime();

	SetClientFrags(client, 0);
	SetClientDeaths(client, 0);
	
	PrintToChat(client, "\x04[SM] \x03Your score has reset succsesfully.");
	return Plugin_Handled;
}

stock SetClientFrags(index, frags)
{
	SetEntProp(index, Prop_Data, "m_iFrags", frags);
	return 1;
}
stock SetClientDeaths( index, deaths )
{
	SetEntProp(index, Prop_Data, "m_iDeaths", deaths);
	return 1;
}
public Action:resetscore(Handle:timer)
{
	PrintToChatAll("\x03 Type in chat !rs or !resetscore to reset you score.");
	return Plugin_Handled;
}