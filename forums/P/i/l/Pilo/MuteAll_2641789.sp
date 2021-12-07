#define PLUGIN_AUTHOR "Pilo"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <basecomm>

#pragma newdecls required
#pragma semicolon 1

ConVar g_cvarPrefix;
char g_sPrefix[32];

public Plugin myinfo = 
{
    name = "Mute-All Players",
    author = PLUGIN_AUTHOR,
    description = "Mute-All",
    version = PLUGIN_VERSION,
    url = "https://forums.gamers-israel.co.il/"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_muteall", Command_MuteAll, ADMFLAG_GENERIC, "Mute-All");
    RegAdminCmd("sm_unmuteall", Command_UnMuteAll, ADMFLAG_GENERIC, "Un-Mute All");
    RegAdminCmd("sm_mutet", Command_MuteT, ADMFLAG_GENERIC, "Mute Terrorist");
    RegAdminCmd("sm_mutect", Command_MuteCT, ADMFLAG_GENERIC, "Mute Counter-Terrorist");

    g_cvarPrefix = CreateConVar("sm_muteall_prefix", "[SM] » ", "The tag applied before plugin messages. If you want no tag, you can set an empty string here.");
    g_cvarPrefix.AddChangeHook(cvarChange_Prefix);
    g_cvarPrefix.GetString(g_sPrefix, sizeof(g_sPrefix));

    AutoExecConfig(true, "muteall");
}

public void cvarChange_Prefix(ConVar convar, const char[] oldValue, const char[] newValue) {
    Format(g_sPrefix, sizeof(g_sPrefix), newValue);
}

public Action Command_MuteAll(int client, int args)
{
    PrintToChatAll("%s \x07%N\x01 has muted all \x06players\x01", g_sPrefix, client);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !BaseComm_IsClientMuted(i) && IsPlayerAlive(i))
        {
        	if (!CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true))
        	{
            SetClientListeningFlags(i, VOICE_MUTED);
           }
        }
    }
    return Plugin_Handled;
}

public Action Command_UnMuteAll(int client, int args)
{
    PrintToChatAll("%s \x07%N\x01 has un-muted all \x06players\x01", g_sPrefix, client);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !BaseComm_IsClientMuted(i))
        {
        	if (!CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true))
        	{
            SetClientListeningFlags(i, VOICE_NORMAL);
           }
        }
    }
    return Plugin_Handled;
}

public Action Command_MuteT(int client, int args)
{
    PrintToChatAll("%s \x07%N\x01 has muted all \x02Terrorist\x01", g_sPrefix, client);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !BaseComm_IsClientMuted(i) && GetClientTeam(i) == CS_TEAM_T)
        {
        	if (!CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true))
        	{
            SetClientListeningFlags(i, VOICE_MUTED);
           }
        }
    }
    return Plugin_Handled;
}

public Action Command_MuteCT(int client, int args)
{
    PrintToChatAll("%s \x07%N\x01 has muted all \x03Counter-Terrorist\x01", g_sPrefix, client);
    for (int i = 1; i <= MaxClients; i++)
    {
    	
        if (IsClientInGame(i) && !BaseComm_IsClientMuted(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
        	if (!CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC, true))
        	{
            SetClientListeningFlags(i, VOICE_MUTED);
        	}
       }
	}
    return Plugin_Handled;
}