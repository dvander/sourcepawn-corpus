public void OnPluginStart()
{
    HookEvent("infected_death", Event_InfectedDeath);
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	bool headshot = event.GetBool("headshot");	
	PrintToChatAll("headshot? %s", headshot ? "true" : "false");
}