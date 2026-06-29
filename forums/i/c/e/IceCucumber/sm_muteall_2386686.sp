#pragma semicolon 1

#include <sourcemod>
#include <basecomm>

#define PLUGIN_VERSION "0.1.1"

public Plugin myinfo = {
	name			= "Mute all",
	description	= "Mute/unmute everyone",
	version		= PLUGIN_VERSION
};

public void OnPluginStart()
{
	RegAdminCmd("sm_muteall",	Command_MuteAll, ADMFLAG_GENERIC, "Mute everyone except server admins.");
	RegAdminCmd("sm_unmuteall",	Command_UnMuteAll, ADMFLAG_GENERIC, "Unmute everyone.");
}

public Action Command_MuteAll(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i))
			continue;
		
		AdminId id = GetUserAdmin(i);
		if (id != INVALID_ADMIN_ID)
			continue;
		
		BaseComm_SetClientMute(i, true);
	}
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	PrintToChatAll("Admin %s muted everyone.", clientName);
	
	return Plugin_Handled;
}

public Action Command_UnMuteAll(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i))
			continue;
		
		BaseComm_SetClientMute(i, false);
	}
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	PrintToChatAll("Admin %s unmuted everyone.", clientName);
	
	return Plugin_Handled;
}