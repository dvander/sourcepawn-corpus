#pragma semicolon 1
#include <sourcemod>

#define TEAM_BLUE 3
#define TEAM_RED 2

new Handle:g_hAdminFlag = INVALID_HANDLE;
new g_adminFlag;

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    g_hAdminFlag = CreateConVar("sm_adminred_flag", "b");
    HookConVarChange(g_hAdminFlag, OnConVarChange);
}


public OnConfigsExecuted()
{
    decl String:commandFlags[32];
    GetConVarString(g_hAdminFlag, commandFlags, sizeof(commandFlags));
    g_adminFlag = ReadFlagString(commandFlags);
}


public OnConVarChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{

    g_adminFlag = ReadFlagString(newValue);
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetClientTeam(client);
    if (CheckCommandAccess(client, "admin_red_override", g_adminFlag)) {
        if(team == TEAM_RED)
            ChangeClientTeam(client, TEAM_BLUE);
			PrintToChat(client, "Red Team is for Players Only, You have been moved to Blue");
        return Plugin_Changed;
    }

    if(GetClientTeam(client) == TEAM_BLUE) {
		ChangeClientTeam(client, TEAM_RED);
		PrintToChat(client, "Blue Team is for Admins Only, You have been moved to Red");
        return Plugin_Changed;
    }
    return Plugin_Continue;
}