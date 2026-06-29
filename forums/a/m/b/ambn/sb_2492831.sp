#pragma semicolon 1
#include <PTaH>

public Plugin myinfo =
{
	name = "Server Auto-Update Detector",
	author = "noBrain",
	version = "1.2",
};

public void OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	PTaH(PTaH_ServerConsolePrint, Hook, ServerConsolePrint);
} 
public Action ServerConsolePrint(const char[] sMessage)
{
	int Players = GetClientCount(false);
    if (StrContains(sMessage, "MasterRequestRestart") != -1 && Players == 0)
	{
		PrintToServer("[SM] An Update Detected ! Restarting Server In 5 Seconds!");
		PrintToChatAll("[SM] An Update Detected ! Restarting Server In 5 Seconds!");
		ServerCommand("quit");
	}
    return Plugin_Continue;
}
public Action Command_Say(int client, int args)
{
	char Message[512];
	GetCmdArgString(Message, sizeof(Message));
	if(StrContains(Message, "MasterRequestRestart") != -1)
	{
		PrintToChat(client, "[SM] Blocked Expression.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}