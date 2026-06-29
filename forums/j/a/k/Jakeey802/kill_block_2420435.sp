#include <sourcemod>
#pragma semicolon 1

public OnPluginStart()
{
    RegConsoleCmd("kill", Command_Disable);
}

public Action:Command_Disable(client, args)
{
    return Plugin_Handled;
}
