#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>

#define PLUGIN_VERSION "1.0.0"

bool b_Free2Play[MAXPLAYERS + 1];

public Plugin myinfo = {
    name        = "Free2BeKicked - CS:GO",
    author      = "Asher \"asherkin\" Baker, psychonic",
    description = "Automatically kicks non-premium players.",
    version     = PLUGIN_VERSION,
    url         = "http://limetech.org/"
};

public OnPluginStart()
{
	CreateConVar("anti_f2p_version", PLUGIN_VERSION, "Free2BeKicked", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	RegAdminCmd("sm_f2p_all", cmdFree2Play, ADMFLAG_GENERIC, "Print all f2p clients list to console.");
	for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client)
{
    if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
    {
        return;
    }
    
    if (k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820))
    {
        b_Free2Play[client] = true;
        return;
    }
    
    return;
}

public void OnClientDisconnect(int client)
{
	if(IsValidClient(client))
	{
		b_Free2Play[client] = false;
	}
}

public Action cmdFree2Play(int client, int args)
{

	char buffer[512];
	StrCat(buffer, sizeof(buffer), "\nGracze F2P:\n");
	for(int i = 0; i <= MaxClients; i++)
	{
		if(i > 0 && IsClientInGame(i) && b_Free2Play[i])
		{
			char sPlayerName[32];
			GetClientName(i, sPlayerName, sizeof(sPlayerName));
			StrCat(buffer, sizeof(buffer), sPlayerName);
			StrCat(buffer, sizeof(buffer), "\n");
		}
	}
	StrCat(buffer, sizeof(buffer), "\n");
	PrintToConsole(client, buffer);
	
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (IsFakeClient(client)) return false;
	return IsClientInGame(client);
}