#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Suit & Deagle",
	author = "JaZz",
	description = "This plugin gives all players on spawn an assault suit (kevlar + helmet) and dessert eagle. This is especially useful for fy and aim maps.",
	version = "1.0.0.0",
	url = "http://www.andreas-glaser.com"
};

public OnPluginStart()
{
   HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new weaponEntity = GetPlayerWeaponSlot(client, 1);
    if (IsValidEntity(weaponEntity))
    {
        RemovePlayerItem(client, weaponEntity);
        RemoveEdict(weaponEntity);
    }
    GivePlayerItem(client, "weapon_deagle", 0);
    GivePlayerItem(client, "item_assaultsuit", 0);
    return;
}

