#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new m_bHasDefuser;
new m_bHasHelmet;
new m_bHasNightVision;
new m_ArmorValue;
new m_flDeathTime;
new m_iAmmo;

#define ITEM_NAME_LEN 32
#define ITEMS_TYPES_NUM 10
#define CS_SLOT_KNIFE 2
#define CS_TEAMS_NUM 4

enum {
	Item_Primary = 0,
	Item_Secondary,
	Item_Noknife,
	Item_Hegrenade,
	Item_Flashbang,
	Item_Flashbang2,
	Item_Smokegrenade,
	Item_Armor,
	Item_Nvgs,
	Item_Defuser
};

new String:Items_Names[][ITEM_NAME_LEN] = {
	"m3",
	"xm1014",
	"mac10",
	"tmp",
	"mp5navy",
	"ump45",
	"p90",
	"galil",
	"famas",
	"ak47",
	"m4a1",
	"sg552",
	"aug",
	"m249",
	"scout",
	"sg550",
	"awp",
	"g3sg1",
	"glock",
	"p228",
	"usp",
	"deagle",
	"elite",
	"fiveseven",
	"noknife",
	"hegrenade",
	"flashbang",
	"flashbang",
	"smokegrenade",
	"kevlar",
	"assaultsuit",
	"nvgs",
	"defuser"
};

new Items_Types[] = {
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Primary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Secondary,
	Item_Noknife,
	Item_Hegrenade,
	Item_Flashbang,
	Item_Flashbang2,
	Item_Smokegrenade,
	Item_Armor,
	Item_Armor,
	Item_Nvgs,
	Item_Defuser
};

// Functions
public Plugin:myinfo =
{
    name = "Get All Weapon Slots",
    author = "LP",
    description = "",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}


public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponTest, EventHookMode_Post);
}

public WeaponTest(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get the client from the event
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new id      = GetClientOfUserId(GetEventInt(event, "userid"));
	new primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		new secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		new knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
		new hegrenade = GetEntData(client, m_iAmmo + (11 * 4));
		new flashbang = GetEntData(client, m_iAmmo + (12 * 4));
		new smokegrenade = GetEntData(client, m_iAmmo + (13 * 4));
    
    // Declare the weapon name buffer
    new String:sWeaponName[64];
    
    // Get the player's current weapon
    if (GetClientWeapon(client, sWeaponName, sizeof(sWeaponName)))
    {
        // Compare the weapon name and execute code based on the weapon
        if (strcmp(sWeaponName, "weaponname1", false) == 0)
        {
            // Code for weaponname1
        }
        else if (strcmp(sWeaponName, "weaponname 2", false) == 0)
        {
            // Code for weaponname2
        }
        else if (strcmp(sWeaponName, "weaponname 3", false) == 0)
        {
            // Code for weaponname3
        }
        else
        {
            //PrintToChat(client, "Dude, I have absolutely no idea what weapon you are using: %s", Slot_Primary);
			PrintToChat(client, "Bruh: %s", sWeaponName);
			PrintToChat(client, "Bruh: %s", primary);
			PrintToChat(client, "Bruh: %s", CS_SLOT_KNIFE);
			PrintToChat(client, "Bruh: %s", secondary);
			//PrintToChat(client, "Dude, I have absolutely no idea what weapon you are using: %s", Slot_Melee);
        }
    }
    else
    {
        PrintToChat(client, "Unable to retrieve weapon info.");
    }
}
