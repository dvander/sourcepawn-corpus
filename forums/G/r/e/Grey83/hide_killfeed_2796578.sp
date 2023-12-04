#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
}

public Action Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Changed;
}