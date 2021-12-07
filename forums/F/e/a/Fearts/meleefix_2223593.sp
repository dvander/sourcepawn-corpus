#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>

public Plugin:myinfo =
{
    name        = "Melee exploit fix",
    author      = "Friagram",
    description = "Derp",
    version     = "1.0",
    url         = "http://steamcommunity.com/groups/poniponiponi"
};

public OnPluginStart()
{
    HookEvent("post_inventory_application", post_inventory_application,  EventHookMode_Post);
}

public post_inventory_application(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    static String:weaponclass[][] = {
        "tf_weapon_bat",
        "tf_weapon_bat",    // scout
        "tf_weapon_club", // sniper
        "tf_weapon_shovel", // soldier
        "tf_weapon_bottle", // demoman
        "tf_weapon_bonesaw", // medic
        "tf_weapon_fists", // heavy
        "tf_weapon_fireaxe", // pyro
        "tf_weapon_knife", // spy
        "tf_weapon_wrench" // engineer
    };
    
    static weapondef[] = {
        0,
        0, // scout
        3, // sniper
        6, // soldier
        1, // demoman
        8, // medic
        5, // heavy
        2, // pyro
        4, // spy
        7 // engineer
    };

    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new weapon = GetPlayerWeaponSlot(client, 2);
    if(weapon == -1)
    {
        new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
        if (hWeapon != INVALID_HANDLE)
        {
            new playerclass = _:TF2_GetPlayerClass(client);
            TF2Items_SetClassname(hWeapon, weaponclass[playerclass]);
            TF2Items_SetItemIndex(hWeapon, weapondef[playerclass]);			

            TF2Items_SetLevel(hWeapon, 1);
            TF2Items_SetQuality(hWeapon, 1);
            TF2Items_SetNumAttributes(hWeapon, 0);

            weapon = TF2Items_GiveNamedItem(client, hWeapon);

            if(IsValidEntity(weapon))
            {
                EquipPlayerWeapon(client, weapon);

                SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
            }

            CloseHandle(hWeapon);
        }
    }
}