#include <sdktools>

public void OnPluginStart()
{
	HookEvent("bomb_begindefuse", Event_Defuse);
}

public void Event_Defuse(Event event, char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Defuse);
}

public Action Timer_Defuse(Handle timer)
{
	int bomb = FindEntityByClassname(-1, "planted_c4");
	if (!bomb)
		return Plugin_Handled;

	SetEntPropFloat(bomb, Prop_Send, "m_flDefuseCountDown", GetGameTime());

	return Plugin_Handled;
}