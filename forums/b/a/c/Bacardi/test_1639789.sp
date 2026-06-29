#include<sdktools>

public OnPluginStart()
{
	HookEventEx("teamplay_round_start", round_start, EventHookMode_PostNoCopy); // HookEvent
	HookEventEx("player_spawn", player);
}

new bool:lowgrav[MAXPLAYERS+1]; // Trace players gravity

public player(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(lowgrav[client]) // Player have visit inside trigger "map_test_trigger_123" before spawn
	{
		SetEntityGravity(client, 1.0); // Set normal gravity regardless server sv_gravity or other plugins
	}
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:buffer[60], ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1) // Find trigger_multiple
	{
		GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer)); // Get targetname

		if(StrEqual(buffer, "map_test_trigger_123", false)) // targetname match
		{
			HookSingleEntityOutput(ent, "OnEndTouch", callback, false); // Hook trigger output
			HookSingleEntityOutput(ent, "OnStartTouch", callback, false);
			break; // Stop loop
		}		
	}
}

public callback(const String:output[], caller, activator, Float:delay)
{
	// Here do anything what you want
	// Don't use player names to target!

	//PrintToServer("output %s, caller %i, activator %i, delay %0.1f", output, caller, activator, delay);

	if(activator > 0 && activator <= MaxClients)
	{
		if(StrEqual(output, "OnStartTouch"))
		{
			//ServerCommand("sm_gravity #%i 0.2", GetClientUserId(activator));
			lowgrav[activator] = true;	// Mark player
			SetEntityGravity(activator, 0.2);
			PrintHintText(activator, "Low gravity");
		}
		else if(StrEqual(output, "OnEndTouch"))
		{
			//ServerCommand("sm_gravity #%i 1.0", GetClientUserId(activator));
			lowgrav[activator] = false;	// Remove mark
			SetEntityGravity(activator, 1.0);
			PrintHintText(activator, "Normal gravity");
		}
	}
}