#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#include <sourcemod>

ConVar sv_downloadurl, sm_fakedownloadurl, sm_fakedownloadurl_enabled;
bool fakeURL_enabled;
char fakeURL[100];

public Plugin myinfo =
{
	name 		= "Fake sv_downloadurl to players",
	author 		= "Bacardi (Updated to the new syntax by Sgt. Gremulock)",
	description = "Send fake sv_downloadurl \"URL\" to all players, they still download missing content from your real URL",
	url 		= "sourcemod.net",
	version 	= PLUGIN_VERSION
};

public void OnPluginStart()
{
	sv_downloadurl = FindConVar("sv_downloadurl");

	if (sv_downloadurl == null)
	{
		SetFailState("ConVar sv_downloadurl not found! Plugin stopped.");
	}

	sm_fakedownloadurl = CreateConVar("sm_fakedownloadurl", "", "Fake download URL to players, text max 99 length");
	sm_fakedownloadurl.GetString(fakeURL, sizeof(fakeURL));
	sm_fakedownloadurl.AddChangeHook(ConVarChange);

	sm_fakedownloadurl_enabled = CreateConVar("sm_fakedownloadurl_enabled", "1", "Enable/Disable Fake download URL to players", _, true, 0.0, true, 1.0);
	fakeURL_enabled = sm_fakedownloadurl_enabled.BoolValue;
	sm_fakedownloadurl_enabled.AddChangeHook(ConVarChange);

	CreateConVar("sm_fakedownloadurl_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY);

	AutoExecConfig();
}

public void ConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	sm_fakedownloadurl.GetString(fakeURL, sizeof(fakeURL));

	if (cvar == sm_fakedownloadurl_enabled && StringToInt(oldValue) != StringToInt(newValue))
	{
		fakeURL_enabled = sm_fakedownloadurl_enabled.BoolValue;

		if (fakeURL_enabled)
		{
			for (int i = 1; i <= MAXPLAYERS; i++)
			{
				if (IsValidClient(i))
				{
					OnClientPutInServer(i);
				}
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (fakeURL_enabled && IsValidClient(client))
	{
		sv_downloadurl.ReplicateToClient(client, fakeURL);
	}
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
	{
		return false; 
	}
	
	return IsClientInGame(client); 
}