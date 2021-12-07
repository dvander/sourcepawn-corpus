// Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

Handle g_aBadTags;

// Bools
bool g_bIsLateLoad = false;

// Info
public Plugin myinfo = {
	name = "Ban Bad Steam Groups", 
	author = "shanapu", 
	description = "Ban player who member of bad steam groups", 
	version = "1.0.0",
	url = "https://github.com/shanapu/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bIsLateLoad = late;

	return APLRes_Success;
}

// Start
public void OnPluginStart()
{
	// Late loading
	if (g_bIsLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}

		g_bIsLateLoad = false;
	}

}

public void OnConfigsExecuted()
{
	GetBadTags();
}

public void OnClientPostAdminCheck(int client)
{
	for (int i = 0; i < GetArraySize(g_aBadTags); i++)
	{
		char sBadTag[255];
		GetArrayString(g_aBadTags, i, sBadTag, sizeof(sBadTag));

		SteamWorks_GetUserGroupStatus(client, StringToInt(sBadTag));
	}
	
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = GetUserAuthID(authid);
	if (client == -1)
		return;

	if (isMember)
	{
		for (int i = 0; i < GetArraySize(g_aBadTags); i++)
		{
			char sBadTag[255];
			GetArrayString(g_aBadTags, i, sBadTag, sizeof(sBadTag));

			if (groupAccountID == StringToInt(sBadTag))
			{
				BanClient(client, 0, BANFLAG_AUTO, "Bad Steam Group");

				break;
			}
		}
	}
}

void GetBadTags()
{
	char g_filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, g_filename, sizeof(g_filename), "configs/badsteamgroups.ini");

	Handle file = OpenFile(g_filename, "rt");

	if (file == INVALID_HANDLE)
	{
		LogMessage("Could not open file!");
		return;
	}

	g_aBadTags = CreateArray(255);

	while (!IsEndOfFile(file))
	{
		char line[255];

		if(!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}

		TrimString(line);

		if (!line[0])
			continue;

		PushArrayString(g_aBadTags, line);
	}

	CloseHandle(file);
}

int GetUserAuthID(int authid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) return -1;
		
		char[] charauth = new char[64];
		char[] authchar = new char[64];
		GetClientAuthId(i, AuthId_Steam3, charauth, 64);
		IntToString(authid, authchar, 64);
		if (StrContains(charauth, authchar) != -1) return i;
	}

	return -1;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}