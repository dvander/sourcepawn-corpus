#include	<sourcemod>
#define		PLUGIN_VERSION "0.1"
ConVar		SuppressTeams;
ConVar		SuppressConnect;
ConVar		SuppressDisconnect;

public	Plugin:myinfo	=
{
	name		=	"Suppress Messages",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Suppress Messages.",
	version		=	PLUGIN_VERSION,
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public void OnPluginStart()
{
	CreateConVar("sm_suppress_version",	PLUGIN_VERSION,	"Suppress Version");
	SuppressTeams		=	CreateConVar("sm_suppress_teams",		"0",	"Block Player Joined Team Message?",	_, true, 0.0, true, 1.0);
	SuppressConnect		=	CreateConVar("sm_suppress_connect",		"0",	"Block Player Connected Message?",		_, true, 0.0, true, 1.0);
	SuppressDisconnect	=	CreateConVar("sm_suppress_disconnect",	"0",	"Block Player Disconnect Message?",		_, true, 0.0, true, 1.0);
	HookEvent("player_team",				suppress_Teams,			EventHookMode_Pre);
	HookEvent("player_disconnect",			suppress_Disconnect,	EventHookMode_Pre);
	HookEvent("player_connect_client",		suppress_Connect,		EventHookMode_Pre);
	AutoExecConfig(true, "sm_suppress");
}

public Action:suppress_Teams(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressTeams.IntValue == 1)
	{
		SetEventBroadcast(event, true);
	}
	return Plugin_Continue;
}
public Action:suppress_Connect(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressConnect.IntValue == 1)
	{
		SetEventBroadcast(event, true);
	}
	return Plugin_Continue;
}
public Action:suppress_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (SuppressDisconnect.IntValue == 1)
	{
		SetEventBroadcast(event, true);
	}
	return Plugin_Continue;
}