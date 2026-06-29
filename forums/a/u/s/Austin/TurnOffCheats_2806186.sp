#include <sourcemod>

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	PrintToServer("TurnOffCheats Loaded");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, TimerTurnOffCheats);
	return Plugin_Continue;
}

public Action TimerTurnOffCheats(Handle timer)
{
	ServerCommand("sv_cheats 0");
	return Plugin_Continue;
}
