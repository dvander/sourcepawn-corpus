#include <sourcemod>
#include <basecomm>

#pragma semicolon 1

#define VERSION "1.0"

new Handle:g_hMutedClients = INVALID_HANDLE;
new g_muteInitiator = -1;

public Plugin:myinfo = 
{
	name = "AdminVoice",
	author = "Powerlord",
	description = "Mutes all other non-muted players while an admin uses the +adminvoice keybind.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183541"
}

public OnPluginStart()
{
	// Add your own code here...
	CreateConVar("adminvoice_version", VERSION, "AdminVoice version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	RegAdminCmd("+adminvoice", MuteOn, ADMFLAG_GENERIC, "Mute all players when an admin is speaking");
	RegAdminCmd("-adminvoice", MuteOff, ADMFLAG_GENERIC, "Unmute people muted with adminvoice");
}

public Action:MuteOn(client, args)
{
	if (g_hMutedClients == INVALID_HANDLE)
	{
		g_muteInitiator = client;
		g_hMutedClients = CreateArray();
		
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (i != client && IsClientInGame(i) && !IsFakeClient(i) && BaseComm_SetClientMute(i, true))
			{
				PushArrayCell(g_hMutedClients, i);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:MuteOff(client, args)
{
	RemoveMute();
	return Plugin_Handled;
}

public OnMapEnd()
{
	RemoveMute();
}

public OnClientPutInServer(client)
{
	if (g_hMutedClients != INVALID_HANDLE && BaseComm_SetClientMute(client, true))
	{
		PushArrayCell(g_hMutedClients, client);
	}
}

// This must be Disconnect not Disconnect_Post due to the BaseComm call below
public OnClientDisconnect(client)
{
	if (client == g_muteInitiator)
	{
		RemoveMute();
	}
	else
	{
		new position = FindValueInArray(g_hMutedClients, client);
		if (position != -1)
		{
			// Not strictly necessary, but in case some other plugin is persisting mutes...
			BaseComm_SetClientMute(client, false);
			RemoveFromArray(g_hMutedClients, position);
		}
	}
}

stock RemoveMute()
{
	if (g_hMutedClients != INVALID_HANDLE)
	{
		g_muteInitiator = -1;
		new size = GetArraySize(g_hMutedClients);
		for (new i = 0; i < size; ++i)
		{
			BaseComm_SetClientMute(GetArrayCell(g_hMutedClients, i), false);
		}
		CloseHandle(g_hMutedClients);
		g_hMutedClients = INVALID_HANDLE;
	}
}