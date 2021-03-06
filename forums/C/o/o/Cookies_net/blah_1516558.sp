/* Script generated by SourcePawn IDE */

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION "1.0.0.0"

public Plugin:myinfo = 
{
    name = "Blah",
    author = "Cookies",
    description = "Blah",
    version = PLUGIN_VERSION,
    url = "blah.blah/blaah.php"
}

public OnPluginStart()
{
    CreateConVar("Blah_version", PLUGIN_VERSION, "Current Blah version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
    HookEvent("post_inventory_application", post_inventory_application);
}

public post_inventory_application(Handle:event, const String:name[], bool:dontBroadast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    for (new i = 0; i < 2; i++)
    {
        new weapon = GetPlayerWeaponSlot(client, i);
        if (!IsValidEdict(weapon)) continue;
        new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
        switch (index)
        {
            case 441: // mangler, ze rocket lawnchair
            {
                TF2_RemoveWeaponSlot(client, i);
                new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
                TF2Items_SetClassname(hItem, "tf_weapon_rocketlauncher");
                TF2Items_SetItemIndex(hItem, 18);
                TF2Items_SetQuality(hItem, 0);
                TF2Items_SetLevel(hItem, 0);
                TF2Items_SetNumAttributes(hItem, 0);
                TF2Items_GiveNamedItem(client, hItem);
                new entWeapon = TF2Items_GiveNamedItem(client, hItem);
                CloseHandle(hItem);
                EquipPlayerWeapon(client, entWeapon);
            }
            case 442: // bison, ze shooooootgoooon
            {
                TF2_RemoveWeaponSlot(client, i);
                new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
                TF2Items_SetClassname(hItem, "tf_weapon_shotgun_soldier");
                TF2Items_SetItemIndex(hItem, 10);
                TF2Items_SetQuality(hItem, 0);
                TF2Items_SetLevel(hItem, 0);
                TF2Items_SetNumAttributes(hItem, 0);
                TF2Items_GiveNamedItem(client, hItem);
                new entWeapon = TF2Items_GiveNamedItem(client, hItem);
                CloseHandle(hItem);
                EquipPlayerWeapon(client, entWeapon);
            }
        }
    }
}



