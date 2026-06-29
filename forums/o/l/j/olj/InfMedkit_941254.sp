#define PLUGIN_VERSION "0.1"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

//#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

public Plugin:myinfo = 

{
	name = "Infinite Medkits",
	author = "Olj",
	description = "Infinite Medkits",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("heal_success", HealEvent);
	CreateConVar("l4d_infmed_version", PLUGIN_VERSION, "Version of Infinite medkits", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public HealEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
new Healer = GetClientOfUserId(GetEventInt(event, "userid"));
CreateTimer(0.1, RegivingMeds, any:Healer);
}

public Action:RegivingMeds(Handle:timer, any:Healer)
{
ExecuteCommand(Healer, "give", "first_aid_kit");
}


ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
    if (Client==0) return;
    new Flags = GetCommandFlags(strCommand);
    SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", strCommand, strParam1);
    CreateTimer(0.1, RevertingFlags, any:Flags);
}

public Action:RevertingFlags(Handle:timer, any:Flags)
{
SetCommandFlags("give", Flags);
}