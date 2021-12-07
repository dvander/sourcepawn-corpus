#include <sourcemod>
#include <sdktools>

    public Plugin:myinfo = {
    name = "-",
    author = "-",
    description = "-",
    version = "-",
    url = "-"
};

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:steamid[32];
	new client = GetClientAuthString(client, steamid, sizeof(steamid));
    
	if (StrEqual(steamid,"put sid in here"))
	{
		SetEntityHealth(client, and in here put amount of hp);
	}
}  