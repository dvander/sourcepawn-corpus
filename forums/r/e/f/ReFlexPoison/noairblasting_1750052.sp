#pragma semicolon 1

#include <sourcemod>

public OnPluginStart()
{
	AddCommandListener("attack", Attack);
	AddCommandListener("+attack", Attack);
}

public Action:Attack(client, const String:command[], argc)
{
	return Plugin_Handled;
}