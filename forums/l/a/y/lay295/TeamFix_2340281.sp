#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
    AddCommandListener(JoinTeam, "jointeam");
    HookEvent("teamchange_pending", TeamChangePending, EventHookMode_Pre);
}

public Action:TeamChangePending(Handle:event, const String:name[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetEventInt(event, "toteam");
    SetEntProp(client, Prop_Send, "m_iTeam", team);
}

public Action:JoinTeam(client, const String:command[], args)
{
    ClientCommand(client, "joinclass");
}