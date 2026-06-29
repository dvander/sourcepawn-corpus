#include <sourcemod>

public Plugin:myinfo = 
{
	name = "God mode to everyone",
	author = "Bacardi",
	description = "Automatically god mode to everyone",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

new Handle:enabled = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_player_spawn);

	enabled = CreateConVar("sm_godall", "1", "Everyone have godmode automatically", _, true, 0.0, true, 1.0);
}

public Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(enabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
		PrintToChat(client, "\x01[SM] \x04God Mode on");
	}
}