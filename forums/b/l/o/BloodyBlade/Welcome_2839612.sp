#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0.0.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar sm_Join_Message_Enable, sm_Join_Message;
bool bHooked = false;
char cMessage[128];

public Plugin myinfo =
{
    name = "Welcome",
    author = "Hunter S. Thompson",
    description = "My First Plugin - Displays a welcome message when the user joins.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=187975"
};

public void OnPluginStart()
{
    CreateConVar("sm_join_message_version", PLUGIN_VERSION, "Welcome plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    sm_Join_Message_Enable = CreateConVar("sm_join_message_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
    sm_Join_Message = CreateConVar("sm_join_message", "Welcome %N, to Conflagration Deathrun!", "Default Join Message", CVAR_FLAGS);
    AutoExecConfig(true, "onJoin");
    sm_Join_Message_Enable.AddChangeHook(OnConVarEnableChanged);
    sm_Join_Message.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    sm_Join_Message.GetString(cMessage, sizeof(cMessage));
}

void IsAllowed()
{
    bool bPluginOn = sm_Join_Message_Enable.BoolValue;
    if(!bHooked && bPluginOn)
    {
        bHooked = true;
        OnConVarsChanged(null, "", "");
        HookEvent("player_activate", Player_Activated, EventHookMode_Post);
    }
    else if(bHooked && !bPluginOn)
    {
        bHooked = false;
        UnhookEvent("player_activate", Player_Activated, EventHookMode_Post);
    }
}

Action Player_Activated(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    CreateTimer(4.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

Action Timer_Welcome(Handle timer, int client)
{
    if (client > 0 && IsClientConnected(client) && IsClientInGame(client))
    {
        CPrintToChat(client, cMessage, client);
    }
    return Plugin_Stop;
}
