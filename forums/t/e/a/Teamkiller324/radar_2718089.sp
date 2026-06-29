public	Plugin	myinfo	=	{
	name		=	"[CSGO] Hide Radar",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Hides the radar for the client upon dying or spectating",
	version		=	"1.0",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

#pragma		semicolon	1
#pragma		newdecls	required

int	Radar[MAXPLAYERS+1];

public void OnPluginStart()	{	
	HookEvent("player_spawn",	Radar_Hook,	EventHookMode_Pre);
	HookEvent("player_death",	Radar_Hook,	EventHookMode_Pre);
	HookEvent("player_team",	Radar_Hook,	EventHookMode_Pre);
}

Action Radar_Hook(Event event, const char[] name, bool dontBroadcast)	{
	int		client	=	GetClientOfUserId(event.GetInt("userid"));
	ConVar	cvar	=	FindConVar("sv_disable_radar");
	char	value[1];
	
	if(!IsValidClient(client))
	
	if(StrEqual(name,	"player_spawn"))	{
		Radar[client]	=	1;
	}
	else if(StrEqual(name,	"player_team"))		{
		if(event.GetInt("team") < 2)	{
			Radar[client]	=	0;
		}
		else	{
			Radar[client]	=	1;
		}
	}
	else if(StrEqual(name,	"player_death"))	{
		Radar[client]		=	0;
	}
	
	if(Radar[client] == 1)	{
		value	=	"0";
	}
	else if(Radar[client] == 0)	{
		value	=	"1";
	}
	cvar.ReplicateToClient(client,	value);
}

stock bool IsValidClient(int client)	{
	if(client < MaxClients) 		return false;
	if(client > MaxClients) 		return false;
	if(client == 0)					return false;
	if(IsFakeClient(client))		return false;
	if(IsClientObserver(client))	return false;
	if(IsClientSourceTV(client))	return false;
	if(!IsClientInGame(client))		return false;
	return true;
}