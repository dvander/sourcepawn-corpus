#define COOPMAPNAME			"l4d_hospital01_apartment"
#define VERSUSMAPNAME		"l4d_vs_hospital01_apartment"
#define SURVIVALMAPNAME		"l4d_sv_lighthouse"

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Empty Server Restarter",
	author = "exvel",
	description = "Restarts servers when last player disconnected",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

new bool:g_isMapChange = false;
new String:m_mode[12];
new Handle:mp_gamemode = INVALID_HANDLE;

public OnPluginStart()
{
	mp_gamemode = FindConVar("mp_gamemode");
}

public OnClientDisconnect(client)
{
	// if map is changing do not do anything
	if (client == 0 || g_isMapChange || IsFakeClient(client))
		return;
	
	CreateTimer(1.0, Check);
}

public OnMapEnd()
{
	g_isMapChange = true;
}

public OnMapStart()
{
	g_isMapChange = false;
}

PlayerCounter()
{
	new counter = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			counter++;
		}
	}
	
	return counter;
}

public Action:Check(Handle:timer)
{
	if (g_isMapChange)
		return;
		
	if (PlayerCounter() == 0)
	{
		SetCurrentGameMode();
		
		if(StrEqual(m_mode, "coop", false))
			ServerCommand("changelevel %s", COOPMAPNAME);
		else if(StrEqual(m_mode, "versus", false))
			ServerCommand("changelevel %s", VERSUSMAPNAME);
		else
			ServerCommand("changelevel %s", SURVIVALMAPNAME);
	}
}

SetCurrentGameMode()
{
	GetCurrentGameMode(m_mode, sizeof(m_mode));
}

GetCurrentGameMode(String:mode[], maxlength)
{
	if(mp_gamemode != INVALID_HANDLE)
		GetConVarString(mp_gamemode, mode, maxlength);
	else
		Format(mode, maxlength, "");
}
