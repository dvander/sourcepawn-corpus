public Plugin:myinfo = 
{
	name = "[ANY] Block Death Event",
	author = "Oshizu / Sena™ ¦",
	description = "Blocks showing up death icon at right up corner",
	version = "1.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre)
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Handled;
}