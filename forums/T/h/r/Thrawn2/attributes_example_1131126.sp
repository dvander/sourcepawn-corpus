#include <sourcemod>
#include <attributes>
#include <colors>

#pragma semicolon 1
#define PLUGIN_VERSION "0.1.0"

new g_Example[MAXPLAYERS+1];
new g_iExampleID;

public Plugin:myinfo =
{
	name = "tAttributes Mod, Example",
	author = "Thrawn",
	description = "A plugin for tAttributes Mod, Example, prints how many points you spend on this attribute.",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

public OnPluginStart()
{
	g_iExampleID = att_RegisterAttribute("Example", "Prints how many points you spend on this attribute.", att_OnExampleChange);

	HookEvent("player_spawn", Event_Player_Spawn);
}

public OnPluginEnd()
{
	att_UnregisterAttribute(g_iExampleID);
}

public att_OnExampleChange(iClient, iValue, iAmount) {
	g_Example[iClient] = iValue;

	if(iAmount != -1 && IsClientInGame(iClient))
	{
		CPrintToChat(iClient, "You are have decided to waste another {green}%i{default} attribute points, which is a total of %i.", iAmount, iValue);
	}
}

public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(att_IsEnabled())
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
		CPrintToChat(iClient, "You have wasted {green}%i{default} attribute points.", g_Example[iClient]);
	}
}
