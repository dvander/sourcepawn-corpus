#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <tf2items>

#undef REQUIRE_PLUGIN
#tryinclude <tf2itemsinfo>

#define REQUIRE_PLUGIN
#include <tf2items_giveweapon>

#define BATTLE_RIFLE_ID 9090

#if !defined _tf2itemsinfo_included
new TF2ItemSlot = 8;
#endif

public Plugin:myinfo =
{
    name = "[TF2] stickbombt mod",
    author = "Bitl",
    description = "A gamemode where pyros fight each others.",
    version = "1.1",
    url = "https://forums.alliedmods.net/showthread.php?t=287521"
};

public OnPluginStart()
{
    HookEvent( "post_inventory_application", OnPostInventoryApplicationAndPlayerSpawn );
    HookEvent( "player_spawn", OnPostInventoryApplicationAndPlayerSpawn );
}

public OnAllPluginsLoaded()
{
    TF2Items_CreateWeapon( BATTLE_RIFLE_ID, "tf_weapon_stickbomb", 307, 2, 9, 10, "134 ; 2 ; 521 ; 1 ; 2 ; 1000 ; 59 ; 100 ; 99 ; 1000 ; 107 ; 2 ; 140 ; 2325 ; 68 ; 5", -1, _, true );
}

public OnPostInventoryApplicationAndPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
    new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
    if( iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) /*|| !IsPlayerAlive(iClient)*/ )
        return;
    
    for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
        TF2_RemoveWeaponSlot( iClient, iSlot );
    
    TF2_SetPlayerClass( iClient, TFClass_Pyro, _, true );
    
    TF2Items_GiveWeapon( iClient, BATTLE_RIFLE_ID );
}