#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Bebop Defib Fix"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("heal_success", Event_MedkitUsed);
}

public OnPluginEnd()
{
}

public Action:Event_MedkitUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
//	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(target, "give health 100");
	SetCommandFlags("give", flags|FCVAR_CHEAT);

	return Plugin_Continue;
}