#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.0.2"

public Plugin:myinfo = {
	name = "Point_viewcontrol Fix",
	author = "MasterOfTheXP",
	description = "Fix for viewcontrols not being reset upon death.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Death, EventHookMode_Pre);
	CreateConVar("sm_pointviewcontrolfix_version", PLUGIN_VERSION, "Plugin version.", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > MaxClients || client <= 0) return;
	if (GetEventInt(event, "death_flags") & 32) return; // Ignore fake deaths caused by the Dead Ringer in Team Fortress 2
	new ViewEnt = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
	
	if (ViewEnt > MaxClients)
	{
		new String:cls[25];
		GetEntityClassname(ViewEnt, cls, sizeof(cls));
		if (StrEqual(cls, "point_viewcontrol", false)) SetClientViewEntity(client, client);
	}
}