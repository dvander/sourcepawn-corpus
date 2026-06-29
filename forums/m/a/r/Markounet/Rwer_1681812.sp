#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
name = "RWER",
author = "Markounet",
description = "Disarm all weapons at us and gives us a knife",
version = "1.0",
url = ""
}

public OnPluginStart()
{
HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
new client = GetClientOfUserId(GetEventInt(event, "userid"));

if (IsPlayerAlive(client))
{
disarm(client);
GivePlayerItem(client, "weapon_knife");
}
}

public disarm(id)
{
new disarme;

for (new i = 0; i < 6; i++)
{
if (i < 6 && (disarme = GetPlayerWeaponSlot(id, i)) != -1) 
{
RemovePlayerItem(id, disarme);
}
}
}
