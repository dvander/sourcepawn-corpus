#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

// Made By Phoenix.
// Website: http://ultimatumcss.tk

public OnPluginStart()
{
	RegConsoleCmd("sm_lastct", Command_LastCT)
}

public Action:Command_LastCT(client, args)
{
	if (GetClientTeam(client) == 3)
	{
		SayLastCT();
	}
	else
	{
		PrintToChat(client, "You are not a CT!");
	}
}

public SayLastCT()
{
	PrintHintTextToAll("If only One CT, LastCT");
	PrintCenterTextAll("If only One CT, LastCT");
}