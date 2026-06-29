#include <sourcemod>
#include <sdktools>
#pragma semicolon 1



new Handle:g_hTvName;
new String:g_sTvName[MAX_NAME_LENGTH];


public Plugin:myinfo = 
{
	name = "tv_name fixer",
	author = "Impact",
	description = "Workaround for the tv_name bug",
	version = "0.1.0",
	url = "http://gugyclan.eu"
}




public OnPluginStart()
{
	if((g_hTvName = FindConVar("tv_name")) == INVALID_HANDLE)
	{
		SetFailState("Couldn't find cvar 'tv_name'");
	}
	
	GetConVarString(g_hTvName, g_sTvName, sizeof(g_sTvName));
	HookConVarChange(g_hTvName, OnCvarChanged);
	
	SetTvName(FindSourceTv());
}




public OnCvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(g_hTvName, g_sTvName, sizeof(g_sTvName));
	SetTvName(FindSourceTv());
}




public OnClientPostAdminCheck(client)
{
	if(IsClientSourceTV(client))
	{
		SetTvName(client);
	}
}




SetTvName(client)
{
	if(IsClientValid(client))
	{
		SetClientInfo(client, "name", g_sTvName);
	}
}




stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}




stock FindSourceTv()
{
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientSourceTV(i))
		{
			return i;
		}
	}
	
	return -1;
}




