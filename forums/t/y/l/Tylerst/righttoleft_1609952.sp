#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Right to Left",
	author = "Tylerst",
	description = "Reverses a given string.",
	version = "1.0.0",
	url = "none"
}

public OnPluginStart()
{	
	RegConsoleCmd("sm_rtl", Command_ReverseString);
	RegConsoleCmd("sm_rtl_team", Command_ReverseStringTeam);	
}

public Action:Command_ReverseString(client, args)
{
	new String:input[128], String:output[128];
	GetCmdArgString(input, sizeof(input));
	new length = strlen(input)-1;
	for(new i=0; i<=length; i++)
	{
		output[i] = input[length-i];
	}
	FakeClientCommand(client, "say %s", output);
	return Plugin_Handled;
}

public Action:Command_ReverseStringTeam(client, args)
{
	new String:input[128], String:output[128];
	GetCmdArgString(input, sizeof(input));
	new length = strlen(input)-1;
	for(new i=0; i<=length; i++)
	{
		output[i] = input[length-i];
	}
	FakeClientCommand(client, "say_team %s", output);
	return Plugin_Handled;
}