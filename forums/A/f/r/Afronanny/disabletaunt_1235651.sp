#include <sourcemod>

public OnPluginStart()
{
	RegConsoleCmd("taunt", Command_Taunt);

}

public Action:Command_Taunt(client, args)
{
	return Plugin_Handled;
}