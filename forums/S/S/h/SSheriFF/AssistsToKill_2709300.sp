#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma tabsize 0
int Assists[MAXPLAYERS + 1];
int KillsCounter[MAXPLAYERS + 1];
int AssistSaver;
ConVar g_cvAmountOfAssists;
public Plugin myinfo = 
{
	name = "AssistsToKill",
	author = "SheriF",
	description = "Converts an amount of assists into 1 kill",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_end", OnRoundEnd);
	HookEvent("round_start", OnRoundStart);
	g_cvAmountOfAssists = CreateConVar("sm_assists_to_convert", "2", "The amount of assists to convert into 1 kill.");
	AutoExecConfig(true, "Assists_To_Kill");
}
public void OnClientDisconnect(int client)
{
    Assists[client] = 0;
    KillsCounter[client] = 0;
}
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR)
            continue;
		SetEntProp(i, Prop_Data, "m_iFrags",GetEntProp(i, Prop_Data, "m_iFrags")+KillsCounter[i]);
		CS_SetClientAssists(i, Assists[i]);
		KillsCounter[i] = 0;
	}
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR)
            continue;
		Assists[i] = CS_GetClientAssists(i);
		AssistSaver = 0;
		while(Assists[i]>=g_cvAmountOfAssists.IntValue)
		{
			AssistSaver += g_cvAmountOfAssists.IntValue;
			Assists[i] -= g_cvAmountOfAssists.IntValue;
			KillsCounter[i]++;
		}
		if(KillsCounter[i]!=0)
		{
			CS_SetClientAssists(i, Assists[i]);
			SetEntProp(i, Prop_Data, "m_iFrags",GetEntProp(i, Prop_Data, "m_iFrags")+KillsCounter[i]);
			PrintToChat(i, "Your \x04%d\x01 assists were converted to \x10%d\x01 kill(s).", AssistSaver, KillsCounter[i]);
		}	
	}
}

