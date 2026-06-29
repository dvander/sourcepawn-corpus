#include <sourcemod>
#include <steamtools>
#define PLUGIN_VERSION "1.1"
#pragma semicolon 1
new Handle:g_hDo;


// Plugin Info
public Plugin:myinfo =
{
    name = "Outdated do?",
    author = "KK",
    description = "When Steam master servers report that your server is outdated, do?",
    version = PLUGIN_VERSION,
    url = "http://attack2.co.cc"
};


public OnPluginStart()
{
	DeleteFile("need.update");
	CreateConVar("sm_outdated_version", PLUGIN_VERSION, "Outdated do? version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT);
	g_hDo = CreateConVar("sm_outdated_do", "2", "Specific what to do when 'your server is reported outdated' \n0 = Disabled \n1 = Create need.update \n2 = Create need.update if no players or only bots \n3 = same as 1 but also shutdown the server \n4 = same as 2 but also shutdown the server", _, true, 0.0, true, 4.0);
	//RegConsoleCmd("sm_restartrequested", Steam_RestartRequested); // debug
}


public Action:Steam_RestartRequested()
{
	new value = GetConVarInt(g_hDo);
	if (value == 0)
	{
		return Plugin_Continue;
	}
	else if (value == 2 || value == 4)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if(IsClientConnected(client) && !IsFakeClient(client))
			{
				LogMessage("Could not made need.update, some still play :)");
				return Plugin_Continue;
			}
		}
	}

	if (FileExists("outdated.cfg"))
	{
		ServerCommand("exec outdated.cfg");
	}
	new Handle:hFile = OpenFile("need.update","w");	
	if(hFile != INVALID_HANDLE) 
	{
		CloseHandle(hFile);
	}

	LogMessage("need.update are now made");

	if(value == 3 || value == 4)
	{
		ServerCommand("quit");
	}
	return Plugin_Continue;
}
