#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

enum {
	FlagEvent_PickedUp = 1,
	FlagEvent_Captured,
	FlagEvent_Defended,
	FlagEvent_Dropped
};

new Handle:g_PluginVersion;
new Handle:g_Enabled;

public Plugin:myinfo =
{
    name = "Intel Carrier Glow",
    author = "Munra",
    description = "Makes the player carrying with the intel glow",
    version = PLUGIN_VERSION,
    url = "http://anbservers.net"
}

public OnPluginStart()
{
   //Create Cvars
   g_PluginVersion = CreateConVar("intelglow_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
   g_Enabled = CreateConVar("intelglow_enable", "1", "Enable or disable the carrie glow", 0, true, 0.0, true, 1.0);
   
   //Hook the events
   HookEvent("teamplay_flag_event", Event_intelglow);
}

public OnMapStart()
{
	// hax against valvefail Thanks psychonic 
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_PluginVersion, PLUGIN_VERSION);	
}

public Event_intelglow(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Enabled))
		return;
		
	new client = GetEventInt(event, "player");
	switch(GetEventInt(event, "eventtype"))
	{
		case FlagEvent_PickedUp:
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);		
		}
		case FlagEvent_Captured, FlagEvent_Dropped:
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
		}
	}
}