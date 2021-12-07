#include<sdktools>

public OnPluginStart()
{
	HookEventEx("teamplay_round_start", round_start, EventHookMode_PostNoCopy); // HookEvent
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname
		if(StrEqual(buffer, "map_test_trigger_123", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnTrigger", callback, false); // Hook trigger output
			break; // Stop loop
		}		
	}
}

public callback(const String:output[], caller, activator, Float:delay)
{
	// Here do anything what you want
	// Don't use player names to target!

	PrintToServer("output %s, caller %i, activator %i, delay %0.1f", output, caller, activator, delay);

	if(activator > 0 && activator <= MaxClients)
	{
		ServerCommand("sm_slap #%i 1", GetClientUserId(activator));
	}
}