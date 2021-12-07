#pragma semicolon 1

#include <sourcemod>
#include <smlib>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVMin;
new Handle:g_hCVMax;

public Plugin:myinfo = 
{
	name = "[TF2] Advanced IdleDealMethod",
	author = "Newbie'",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_Newbie_"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_idledealmethod_version", PLUGIN_VERSION, "Idledealmethod Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
		HookConVarChange(hVersion, OnConVarVersionChange);
	}
	
	g_hCVMin = CreateConVar("sm_idledealmethod_min", "20", "Under that value -> mp_idledealmethod 0 over -> mp_idledealmethod 1 -> OK ???", FCVAR_PLUGIN);
	g_hCVMax = CreateConVar("sm_idledealmethod_max", "26", "Under that value -> mp_idledealmethod 1 over -> mp_idledealmethod 2 -> OK ???", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "plugin.IdleDealMethod");
}

public OnConVarVersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public OnClientConnected()
{
	ExecuteServerCommand();
}

public OnClientDisconnect()
{
	ExecuteServerCommand();
}

ExecuteServerCommand()
{
	new iTeamTotal;
	
	iTeamTotal = GetRealPlayerCount();
	
	if(iTeamTotal < GetConVarInt(g_hCVMin))
	{
		ServerCommand("mp_idledealmethod 0");
	}
	else if(iTeamTotal >= GetConVarInt(g_hCVMin) && iTeamTotal < GetConVarInt(g_hCVMax))
	{
		ServerCommand("mp_idledealmethod 1");
	}
	else if(iTeamTotal >= GetConVarInt(g_hCVMax))
	{
		ServerCommand("mp_idledealmethod 2");
	}
}

GetRealPlayerCount()
{
	new iTeamRed, iTeamBlue, iTeamTotal;
	
	Team_GetClientCounts(iTeamRed, iTeamBlue, CLIENTFILTER_ALL);
	iTeamTotal = iTeamRed + iTeamBlue;
	
	return iTeamTotal;
}