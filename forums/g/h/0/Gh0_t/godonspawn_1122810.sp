#include <sourcemod>

new Handle:GodModeEnabled;

public Plugin:myinfo =
{
    name = "Give Godmode",
    author = "Gh0$t",
    description = "Godmode on Spawn",
    version = "1.0",
    url = "http://www.HuGaminG.de/"
};

public OnPluginStart()
{
	GodModeEnabled	= CreateConVar("sm_godmode_start", "0", "enable and disable the godmode Plugin");
	
	HookEvent("player_spawn", PlayerSpawnEvent);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(GodModeEnabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		new String:clientname[32];
		GetClientName(client, clientname, 32);
		PrintToServer("[SM] Godmode enabled to: %s",clientname);
	}
}
