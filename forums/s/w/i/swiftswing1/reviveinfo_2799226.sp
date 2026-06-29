#include <sourcemod>

#define PLUGIN_VERSION 	"1.0"

public Plugin:myinfo =
{
	name = "Survivor Revive Info",
	author = "sw",
	description = "Prints message to notify whenever you are being/have stopped being revived and by whom.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("revive_begin", ReviveBegin);
	HookEvent("revive_end", ReviveEnd);
}

public ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
    new reviver = GetClientOfUserId(GetEventInt(event, "userid"));
    new revivee = GetClientOfUserId(GetEventInt(event, "subject")); 
	
    if (IsClientInGame(reviver) && IsClientInGame(revivee))
	{
        PrintHintText(revivee, "You are being revived by %N!", reviver);
	}
} 

public ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new reviver = GetClientOfUserId(GetEventInt(event, "userid"));
    new revivee = GetClientOfUserId(GetEventInt(event, "subject")); 
	
    if (IsClientInGame(reviver) && IsClientInGame(revivee))
	{
        PrintHintText(revivee, "%N has stopped reviving you!", reviver);
	}
}