#include <sourcemod>

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (StrContains(command, "_", false) != -1)
	{
		FakeClientCommand(client, "say %s", sArgs);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}