#include <sourcemod>

#define PLUGIN_VERSION "1.2"

new Handle:gH_Version = INVALID_HANDLE;
new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Log = INVALID_HANDLE;
new bool:Enabled;
new bool:Logging;

public Plugin:myinfo = 
{
	name = "Anti Chatbug",
	author = "TimeBomb",
	description = "Fixes the color remove/2 lines chat bug, someone trys? log it :).",
	version = PLUGIN_VERSION,
	url = "http://vgames.co.il/"
}

public OnPluginStart()
{
	// Cvars
	gH_Version = CreateConVar("sm_antichatbug_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gH_Enabled = CreateConVar("sm_antichatbug_enabled", "1", "Is the plugin enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Log = CreateConVar("sm_antichatbug_logging", "1", "Should the the plugin log a bugging player?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	SetConVarString(gH_Version, PLUGIN_VERSION, _, true);
	
	// Booleans
	Enabled = true;
	Logging = true;
	
	// Hooks
	HookConVarChange(gH_Enabled, CVarChanged);
	HookConVarChange(gH_Log, CVarChanged);
	HookEvent("player_say", Player_Say, EventHookMode_Pre);
}

public CVarChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	Enabled = GetConVarBool(gH_Enabled);
	Logging = GetConVarBool(gH_Log);
}

public Action:Player_Say(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:Say[255];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "text", Say, 255);
	if(StrContains(Say, "     ", false) != -1 && Enabled)
	{
		PrintToChat(client, "[SM] This bug is blocked, don't try it.");
		if(Logging) LogMessage("[Anti-Chatbug] %N tried to use the bug.", client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}