#pragma semicolon 1
#define DEBUG
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Bomb Csay",
	author = "SheriF",
	description = "Display Csays on bomb events",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("bomb_planted", OnBombPlant);
	HookEvent("bomb_defused", OnBombDefuse);
	HookEvent("bomb_dropped", OnBombDropped);
	HookEvent("bomb_pickup", OnBombPicked);
	HookEvent("bomb_abortplant", OnAbortPlant);
	HookEvent("bomb_abortdefuse", OnAbortDefuse);
}
public Action OnBombPlant(Event event, const char[] name, bool dontBroadcast)
{
	PrintCenterTextAll("The bomb has been planted!");
}
public Action OnBombDefuse(Event event, const char[] name, bool dontBroadcast)
{
	PrintCenterTextAll("The bomb has been defused!");
}
public Action OnBombDropped(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i)==2)
			PrintCenterText(i, "%N has dropped the bomb!",userid);
	}
}
public Action OnBombPicked(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i)==2)
			PrintCenterText(i, "%N has picked the bomb!",userid);
	}
}
public Action OnAbortPlant(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i)==2)
			PrintCenterText(i, "%N has been stopped planting the bomb!",userid);
	}
}
public Action OnAbortDefuse(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i)==3)
			PrintCenterText(i, "%N has been stopped defusing the bomb!",userid);
	}
}