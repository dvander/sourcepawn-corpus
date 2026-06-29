#include <sourcemod>
#include "include/autoexecconfig"
#include "include/steamworks"

#pragma semicolon 1
#pragma newdecls required


#define PLUGIN_VERSION "0.1.6"

public Plugin myinfo = 
{
	name = "Steam Group Restrict",
	author = "Impact",
	description = "Kicks players based on whether they are a member of a group",
	version = PLUGIN_VERSION,
	url = "http://gugy.eu"
}


ConVar g_hGroupIds;
ConVar g_hNotify;
ConVar g_hKickReason;

int g_iGroupIds[100];
int g_iNumGroups;
char g_sKickReason[256];


public void OnPluginStart()
{
	AutoExecConfig_SetFile("plugin.steamgrouprestrict");
	
	AutoExecConfig_CreateConVar("sm_steamgrouprestrict_version", PLUGIN_VERSION, "Plugin version", FCVAR_PROTECTED|FCVAR_DONTRECORD);
	
	g_hGroupIds   = AutoExecConfig_CreateConVar("sm_steamgrouprestrict_groupids", "", "List of group ids separated by a comma. Use (groupd64 % 4294967296) to convert to expected input", FCVAR_PROTECTED);
	g_hNotify     = AutoExecConfig_CreateConVar("sm_steamgrouprestrict_notify", "1", "Whether or not admins should be notified about kicks", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hKickReason = AutoExecConfig_CreateConVar("sm_steamgrouprestrict_reason", "You are a member of a restricted group", "Kick reason displayed to client");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	g_hGroupIds.AddChangeHook(OnCvarChanged);
	g_hKickReason.AddChangeHook(OnCvarChanged);
}


public void OnCvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hGroupIds)
	{
		OnConfigsExecuted();
	}
	else if (cvar == g_hKickReason)
	{
		g_hKickReason.GetString(g_sKickReason, sizeof(g_sKickReason));
	}
}


public void OnConfigsExecuted()
{
	g_hKickReason.GetString(g_sKickReason, sizeof(g_sKickReason));
	RefreshGroupIds();
	CheckAll();
}


void CheckAll()
{
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			int accountId = GetSteamAccountID(i);
			SteamWorks_OnValidateClient(accountId, accountId);
		}
	}
}


void RefreshGroupIds()
{
	char sGroupIds[1024];
	g_hGroupIds.GetString(sGroupIds, sizeof(sGroupIds));
	
	char sGroupBuf[sizeof(g_iGroupIds)][12];
	int count = 0;
	int explodes = ExplodeString(sGroupIds, ",",  sGroupBuf, sizeof(sGroupBuf), sizeof(sGroupBuf[]));
	
	for (int i=0; i <= explodes; i++)
	{
		TrimString(sGroupBuf[i]);
		
		if (explodes >= sizeof(g_iGroupIds))
		{
			SetFailState("Group Limit of %d reached", sizeof(g_iGroupIds));
			break;
		}
		
		int tmp = StringToInt(sGroupBuf[i]);
		
		if (tmp > 0)
		{
			g_iGroupIds[count] = tmp;
			count++;
		}
	}

	g_iNumGroups = count;
}


public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
	for (int i=0; i < g_iNumGroups; i++)
	{
		SteamWorks_GetUserGroupStatusAuthID(authid, g_iGroupIds[i]);
	}
}


public void SteamWorks_OnClientGroupStatus(int accountId, int groupId, bool isMember, bool isOfficer)
{
	if (isMember)
	{
		int client = GetClientOfAccountId(accountId);
		if (client != -1)
		{
			if (g_hNotify.BoolValue)
			{
				PrintNotifyMessageToAdmins(client, groupId);
			}
			
			KickClient(client, g_sKickReason);
		}
	}
}


void PrintNotifyMessageToAdmins(int client, int groupId)
{
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckCommandAccess(i, "sm_steamgrouprestrict_admin", ADMFLAG_BAN)) 
		{
			PrintToChat(i, "\x04[SGR]\x01 %N was kicked for being a member of a restricted group: %d", client, groupId);
		}
	}	
}


int GetClientOfAccountId(int accountId)
{
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetSteamAccountID(i) == accountId)
		{
			return i;
		}
	}
	
	return -1;
}
