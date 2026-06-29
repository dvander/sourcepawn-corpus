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
    name = "[TF2] heavy pootis",
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
    TF2Items_CreateWeapon( BATTLE_RIFLE_ID, "tf_weapon_fists", 656, 2, 9, 10, "31 ; 5 ; 24 ; 1 ; 369 ; 1 ; 180 ; 150 ; 140 ; 200 ; 358 ; 1 ; 235 ; 1", -1, _, true );
}

public OnPostInventoryApplicationAndPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
    new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
    if( iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) /*|| !IsPlayerAlive(iClient)*/ )
        return;
    
    for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
        TF2_RemoveWeaponSlot( iClient, iSlot );
    
    TF2_SetPlayerClass( iClient, TFClass_Heavy, _, true );
    
    TF2Items_GiveWeapon( iClient, BATTLE_RIFLE_ID );
}