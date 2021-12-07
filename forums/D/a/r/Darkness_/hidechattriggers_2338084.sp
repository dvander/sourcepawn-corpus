#include <sourcemod>

public void OnPluginStart()
{
	AddCommandListener(HideChatTriggers, "say");
	AddCommandListener(HideChatTriggers, "say_team");
}

public Action HideChatTriggers(int client, const String:command[], int argc)
{
	if (IsChatTrigger())
		return Plugin_Handled;
		
	return Plugin_Continue;
}