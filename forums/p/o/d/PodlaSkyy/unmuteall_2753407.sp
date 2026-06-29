#pragma semicolon 1
#pragma tabsize 0
#define DEBUG
#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION ""

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <basecomm>

#pragma newdecls required
public Plugin myinfo = 
{
	name = "Mute-ALL",
	author = "faruki",
	description = "simple muteall everyone in server",
	version = "1.0.0",
	url = "forums.gamers-israel.co.il"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_unmuteall", Cmd_muteall, ADMFLAG_GENERIC, "muteall");
}

public Action Cmd_unmuteall(int client, int args)
{
    PrintToChatAll("[SM] ADMIN has unmuted all players",client);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !BaseComm_IsClientMuted(i) && IsPlayerAlive(i))
        {
        	if (!CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true))
        	{
            SetClientListeningFlags(i, VOICE_NORMAL);
           }
        }
    }
return Plugin_Handled;
}