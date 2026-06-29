#include <sourcemod>
#include <SteamWorks>
#include <cstrike>
#pragma semicolon 1
#pragma newdecls required

bool g_bNoPrime[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "No Prime Clan Tag",
    author        = "OkyHp & Wend4r",
    description = "Setting clan tags for NO PRIME players.",
};

public void OnPluginStart()
{
    if(GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("This plugin works only on CS:GO");
    }
}

public void OnMapStart()
{
    CreateTimer(5.0, Timer_SetClanTags, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPostAdminCheck(int iClient)
{
    g_bNoPrime[iClient] = SteamWorks_HasLicenseForApp(iClient, 624820) ? true : false;
    SetClientClanTag(iClient);
}

public Action Timer_SetClanTags(Handle hTimer)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if (g_bNoPrime[i] && IsClientInGame(i) && !IsFakeClient(i))
        {
            SetClientClanTag(i);
        }
    }
    return Plugin_Continue;
}

public Action SetClientClanTag(int iClient)
{
    if (g_bNoPrime[iClient] && !IsFakeClient(iClient) && IsClientInGame(iClient))
    {
        CS_SetClientClanTag(iClient, "[NO PRIME]");
    }
}