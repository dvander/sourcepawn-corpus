#include <sourcemod>
#include "system2"

#pragma semicolon 1
#pragma newdecls required


public void OnPluginStart()
{
	RegConsoleCmd("sm_cpu", Command_CPU);
}


public Action Command_CPU(int client, int args)
{
	char output[10000] = "Unknown";
	OS os = System2_GetOS();
	
	if (os == OS_WINDOWS)
	{
		System2_Execute(output, sizeof(output), "wmic cpu get name | findstr /v Name");
	} else if (os == OS_UNIX || os == OS_MAC)
	{
		System2_Execute(output, sizeof(output), "grep -m1 -i 'model name' '/proc/cpuinfo' | awk -F': ' {'print $2'}");
	}
	
	ReplyToCommand(client, "Your model is: %s", output);

	return Plugin_Handled;
}
