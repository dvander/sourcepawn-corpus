#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "Host Time Scale",
	author = "Axel Juan Nieves",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar host_timescale, sv_cheats;

public void OnPluginStart()
{
	host_timescale = FindConVar("host_timescale");
	sv_cheats = FindConVar("sv_cheats");
	HookConVarChange(host_timescale, TimescaleChange);
}

public void OnClientPutInServer(int client)
{
	if ( IsFakeClient(client) )
		return;
	if ( GetConVarFloat(host_timescale)!=1.0 )
		SendConVarValue(client, sv_cheats, "1");
	else
		SendConVarValue(client, sv_cheats, "0");
}

public void OnClientDisconnect(int client)
{
	if ( IsFakeClient(client) )
		return;
	SendConVarValue(client, sv_cheats, "0");
}

public void TimescaleChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	for (int client=1; client<=MaxClients; client++)
	{
		if ( IsFakeClient(client) )
			continue;
		if ( GetConVarFloat(host_timescale)!=1.0 )
			SendConVarValue(client, sv_cheats, "1");
		else
			SendConVarValue(client, sv_cheats, "0");
	}
}