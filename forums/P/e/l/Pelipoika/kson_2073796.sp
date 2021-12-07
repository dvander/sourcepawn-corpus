#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
    RegConsoleCmd( "sm_kson", Cmd_Enable );
}

public Action:Cmd_Enable( client, args )
{
    SetEntProp( client, Prop_Send, "m_iKillStreak", 100 );
    return Plugin_Handled;
}