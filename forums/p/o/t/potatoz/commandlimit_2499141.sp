#include <sourcemod>

int CommandUsed = 0;
ConVar sm_commandlimit_cmd = null;

public Plugin myinfo =
{
name = "CommandLimit",
author = "Potatoz",
description = "Limits command usage to once per round",
version = "1.0",
url = "http://www.sourcemod.net/"
};

public OnPluginStart() 
{ 
// Hook round start
HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

// Create Convar and Config for easy Customization
sm_commandlimit_cmd = CreateConVar("sm_commandlimit_cmd", "sm_commandhere", "Command to limit (This is currently limited to one command)");
AutoExecConfig(true, "plugin_commandlimit");

// Add listener for specified command
new String:command[100];
GetConVarString(sm_commandlimit_cmd, command, sizeof(command));

AddCommandListener(Command_Limit, command);
} 

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
CommandUsed = 0;
}

public Action:Command_Limit(client, const String:command[], argc)
{    
	if(CommandUsed == 1)
		return Plugin_Handled;
    
	CommandUsed = 1;
    return Plugin_Continue;
}