#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "punish instant bomb plant/defuse",
	author = "domino_",
	description = "ban players who make the bomb explode, or defuse instantly",
	version = "0.2.0",
	url = "www.google.co.uk"
};

int g_iPlantFirstEventTime;
int g_iDefuseFirstEventTime;

public void OnPluginStart()
{
	HookEvent("bomb_planted", PlantFirstEvent);
	HookEvent("bomb_exploded", PlantSecondEvent);
	
	HookEvent("bomb_begindefuse", DefuseFirstEvent);
	HookEvent("bomb_defused", DefuseSecondEvent);
}

public Action PlantFirstEvent(Event event, const char[] eventname, bool dontBroadcast)
{
	g_iPlantFirstEventTime = GetTime();
}

public Action PlantSecondEvent(Event event, const char[] eventname, bool dontBroadcast)
{
	if((GetTime() - g_iPlantFirstEventTime) <= 1)
		BanClientOnEvent(GetClientOfUserId(event.GetInt("userid")), eventname);
}

public Action DefuseFirstEvent(Event event, const char[] eventname, bool dontBroadcast)
{
	g_iDefuseFirstEventTime = GetTime();
}

public Action DefuseSecondEvent(Event event, const char[] eventname, bool dontBroadcast)
{
	if((GetTime() - g_iDefuseFirstEventTime) <= 1)
		BanClientOnEvent(GetClientOfUserId(event.GetInt("userid")), eventname);
}

public void BanClientOnEvent(int iClient, const char[] eventname)
{
	ServerCommand("sm_ban #%i 0 banned for making the bomb explode, or defusing instantly [event:%s]", GetClientUserId(iClient), eventname);
	if(IsClientInGame(iClient))
		KickClient(iClient, "You have been banned from this server.");
	
	PrintToChatAll(" \x02%L was banned for making the bomb explode, or defusing instantly [event:%s]", eventname);
}