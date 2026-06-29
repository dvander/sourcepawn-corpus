#pragma semicolon 1
#include <sourcemod>
#include <basecomm>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "CT Comms",
	author = "Potatoz",
	description = "Blocks entry in to CT if you have an active Sourcecomms mute/gag",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{	
	AddCommandListener(OnJoinTeam, "jointeam");
}

public Action OnJoinTeam(int client, char[] commands, int args)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if(BaseComm_IsClientGagged(client) || BaseComm_IsClientMuted(client))
	{
		PrintToChat(client, "[SM] You can't join CT with an active communication block!");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}