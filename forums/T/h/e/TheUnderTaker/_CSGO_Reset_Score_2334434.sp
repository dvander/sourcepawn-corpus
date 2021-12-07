#include <sourcemod>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name        = "[CS:GO] Reset Score",
	author      = "TheUnderTaker",
	description = "Reset Score.",
	version     = "1.0",
	url         = "http://steamcommunity.com/profiles/76561198090124061/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_resetscore", ResetScore);
	RegConsoleCmd("sm_rs", ResetScore);
}

public Action:ResetScore(client, args)
{
	if(client == 0)
	{
	PrintToServer("Command In-game only!");
	return Plugin_Handled;
	}
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	SetEntProp(client, Prop_Data, "m_iDeaths", 0);
	CS_SetClientAssists(client, 0);
	CS_SetMVPCount(client, 0);
	CS_SetClientContributionScore(client, 0);
	PrintToChatAll("\x04%N\x01: Reseted his score.", client);
	
	return Plugin_Handled;
}