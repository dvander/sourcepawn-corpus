new Handle:cvarHalftimeDuration;

public OnPluginStart()
{
	HookEvent("announce_phase_event", Event_HalfTime);
}

public OnConfigsExecuted()
{
	cvarHalftimeDuration = FindConVar("mp_halftime_duration");
}

public Action:Event_HalfTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("It's halftime. Teams will swap in %i seconds!", GetConVarInt(cvarHalftimeDuration));
}