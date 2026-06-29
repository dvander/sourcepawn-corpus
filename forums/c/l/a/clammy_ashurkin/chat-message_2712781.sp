#include <sourcemod>

public void OnPluginStart()
{
	CreateTimer(10.0, Timer_Callback, _, TIMER_REPEAT);
}

public Action Timer_Callback(Handle hTimer, any mData)
{
	if (GetClientCount() > 0)
	{
		PrintToChatAll("[SM] BIG CHUNGUS");

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				FakeClientCommand(i, "kill");
			}
		}
	}

	return Plugin_Continue;
}