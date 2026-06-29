#include <sourcemod>
#pragma semicolon 1

new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;
new bool:g_IsRestricted = false;
new bool:g_hasmani = false;

public Plugin:myinfo =
{
	name = "AWP To ClientCount Limit",
	author = "Shango",
	description = "This is a Plugin designed to restrict the AWP if there are less than 8 players (Observers do not count) in Game",
	version = "1.0.0.0",
	url = "http://www.stompfest.com/"
}

public OnPluginStart()
{
	new Handle:hnMani = INVALID_HANDLE;
	if ((hnMani = FindConVar("mani_admin_plugin_version")) == INVALID_HANDLE)
	{
		g_hasmani = false;
	}
	else
	{
		CloseHandle(hnMani);
		g_hasmani = true;
	}

	g_Cvar_MinPlayers = CreateConVar("awp_limit_minplayers", "8", "Min players required to unrestrict the AWP.");
}

public OnClientAuthorized(client, const String:auth[]) 
{
	new count = GetClientCount();

	if(GetConVarInt(g_Cvar_MinPlayers) >= count)
	{
		if(!g_IsRestricted)
		{
			g_IsRestricted = true;

			if(g_hasmani)
				ServerCommand("ma_restrict awp 0");
			else
				ServerCommand("sm_restrict awp 0");
		}
	}
	else
	{
		if(g_IsRestricted)
		{
			g_IsRestricted = false;

			if(g_hasmani)
				ServerCommand("ma_unrestrict awp");
			else
				ServerCommand("sm_unrestrict awp");
		}
	}
}

public OnClientDisconnect_Post(client)
{
	new count = GetClientCount( );

	if(GetConVarInt(g_Cvar_MinPlayers) <= count)
	{
		if(g_IsRestricted)
		{
			g_IsRestricted = false;

			if(g_hasmani)
    				ServerCommand("ma_unrestrict awp");
    			else
				ServerCommand("sm_unrestrict awp");
		}
	}
	else
	{
		if(!g_IsRestricted)
		{
			g_IsRestricted = true;

			if(g_hasmani)
				ServerCommand("ma_restrict awp 0");
			else
				ServerCommand("sm_restrict awp 0");
		}
	}
}