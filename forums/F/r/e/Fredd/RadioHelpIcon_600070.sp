#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define VERSION "0.1"

public Plugin:myinfo = 
{
	name = "Radio Help Icon",
	author = "Fredd",
	description = "Shows a radio icon on player when they are getting hurt..",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("rhi_version", VERSION, "Radio Help Icon Version");
	HookEvent("player_hurt", OnPlayerHurt);
}
public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	TE_Start("RadioIcon");
	TE_WriteNum("m_iAttachToClient", client);
	TE_SendToAll();	
}