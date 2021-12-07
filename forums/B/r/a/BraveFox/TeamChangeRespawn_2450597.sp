#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "[Noy]TeamChange Respawn",
	author = "ItsNoy - BraveFox",
	description = "Auto Respawn After team change",
	version = "1.0"
}

public OnPluginStart()
{
	HookEvent("player_team", Hook);
}
public Action:Hook(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CS_RespawnPlayer(client);
}

