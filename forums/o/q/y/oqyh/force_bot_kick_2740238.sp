#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
    name = "[CS:GO] Bot Quota fix",
    author = "TheWho",
    description = "Bot Quota fix",
    version = "FINAL",
    url = "http://forums.alliedmods.net/"
}

new Handle:g_hBotQuota;
 
public OnPluginStart()
{
    g_hBotQuota = FindConVar("bot_quota");
    if (g_hBotQuota != INVALID_HANDLE)
    {
        HookConVarChange(g_hBotQuota, OnBotQuotaChange);
    }
}
 
public OnBotQuotaChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    if (StringToInt(newVal) > 0)
    {
        SetConVarInt(cvar, 0);
        //return Plugin_Handled;
    }
} 