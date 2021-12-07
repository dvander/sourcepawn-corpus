#include <sourcemod>
 
public Plugin myinfo =
{
	name = "RoundCommand",
	author = "Potatoz",
	description = "Runs a server command every round-start",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

ConVar sm_roundcommand_exec = null;

public OnPluginStart() 
{ 
	// Hook round start
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy); 
	
	// Create Convar and Config for easy Customization
	sm_roundcommand_exec = CreateConVar("sm_roundcommand_exec", "sm_commandhere", "Command to run each round");
	AutoExecConfig(true, "plugin_roundcommand");
} 

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	// Get the value from the Convar above
	new String:command[128];
	GetConVarString(sm_roundcommand_exec, command, sizeof(command));
	
	// Execute the command and send message to console to confirm execution
	ServerCommand(command);
	PrintToServer("[ROUND-COMMAND] executed command %s", command);
}  