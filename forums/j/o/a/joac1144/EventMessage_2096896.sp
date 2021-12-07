#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "1.2"

new Handle:eventmsg_startmessage = INVALID_HANDLE
new Handle:eventmsg_endmessage = INVALID_HANDLE

public Plugin:myinfo =
{
	name = "Event Messages",
	author = "Born/Zyanthius/joac1144",
	description = "Sends messages when round events is fired",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("eventmsg_version", PLUGIN_VERSION, "Plugin version", FCVAR_SPONLY|FCVAR_NOTIFY);
	eventmsg_startmessage = CreateConVar("eventmsg_startmessage", "{lightgreen}The round has {green}started", "Default message to send when a round begins");
	eventmsg_endmessage = CreateConVar("eventmsg_endmessage", "{lightgreen}The round has {green}ended", "Default message to send when a round ends");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	AutoExecConfig(true, "eventmessage");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:msg[128];
	GetConVarString(eventmsg_startmessage, msg, sizeof(msg));
	
	CPrintToChatAll("%s", msg);
	
	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:msg[128];
	GetConVarString(eventmsg_endmessage, msg, sizeof(msg));
	
	CPrintToChatAll("%s", msg);

	return Plugin_Handled;
}






