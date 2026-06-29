#include <cstrike>
#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
    HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Pre);
    HookEvent("cs_match_end_restart", Event_OnMatchRestart, EventHookMode_Pre);
    HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
    AddCommandListener(Command_Join, "jointeam");
}

public Action:Event_OnFullConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!client || !IsClientInGame(client))
        return Plugin_Continue;

    new iRed, iBlue;
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;

        new iTeam = GetClientTeam(i);
        if(iTeam == CS_TEAM_T)
            iRed++;
        else if(iTeam == CS_TEAM_CT)
            iBlue++;
    }

    if(iRed < iBlue)
        SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
    else
        SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);

    ForcePlayerSuicide(client);
    CS_RespawnPlayer(client);
    return Plugin_Continue;
}

public Action:Event_OnMatchRestart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iRed, iBlue, iJoin;
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;

        switch(GetClientTeam(i))
        {
            case CS_TEAM_T:
                iRed++;
            case CS_TEAM_CT:
                iBlue++;
        }
    }

    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;

        if(iRed < iBlue)
            iJoin = CS_TEAM_T;
        else if(iBlue < iRed)
            iJoin = CS_TEAM_CT;
        else
            iJoin = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);

        switch(iJoin)
        {
            case CS_TEAM_T:
                iRed++;
            case CS_TEAM_CT:
                iBlue++;
        }

        ChangeClientTeam(i, iJoin);
    }
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!client || !IsClientInGame(client))
        return Plugin_Continue;

    if(!IsPlayerAlive(client))
        CreateTimer(0.1, Timer_Respawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(!client)
        return Plugin_Continue;

    new iTeam = GetClientTeam(client);
    if(iTeam <= CS_TEAM_SPECTATOR)
        return Plugin_Continue;

    if(IsPlayerAlive(client))
        return Plugin_Continue;

    CS_RespawnPlayer(client);

    return Plugin_Continue;
}

public Action:Command_Join(client, const String:command[], argc)
{
    decl String:sJoining[8];
    GetCmdArg(1, sJoining, sizeof(sJoining));
    new iJoining = StringToInt(sJoining);
    if(iJoining == CS_TEAM_SPECTATOR)
        return Plugin_Continue;

    new iTeam = GetClientTeam(client);
    if(iJoining == iTeam)
        return Plugin_Handled;
    else
    {
        SetEntProp(client, Prop_Send, "m_iTeamNum", iJoining);
        ForcePlayerSuicide(client);
        CS_RespawnPlayer(client);
    }

    return Plugin_Continue;
}


public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!client || !IsClientInGame(client))
        return Plugin_Continue;

    CreateTimer(0.1, Timer_Respawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}  