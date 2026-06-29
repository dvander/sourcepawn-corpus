#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Give Nades",
	author = "Mr.Derp",
	description = "Give Decoy On Spawn",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_decoy");
	}
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}