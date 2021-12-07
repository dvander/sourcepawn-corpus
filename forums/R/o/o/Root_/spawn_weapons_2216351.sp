/**
* Spawn Weapons by Root
*
* Description:
*   Simply gives desired weapons on every player re/spawn.
*
* Version 1.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#include <sdktools>

// ====[ CONSTANTS ]=========================================================
#define PLUGIN_NAME    "Spawn Weapons"
#define PLUGIN_VERSION "1.0"
#define MAX_SLOTS      3 // 0 - primary, 1 - secondary, 2 - melee, 3 - grenades

// ====[ VARIABLES ]=========================================================
new	Handle:spawner_cleanup, Handle:spawner_weapons;

// ====[ PLUGIN ]===================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Simply gives desired weapons on every player spawn",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/",
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	spawner_cleanup = CreateConVar("sm_wspawner_cleanup", "1", "Whether or not clean up previous player ammunition before giving desired weapons", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	spawner_weapons = CreateConVar("sm_wspawner_weapons", "weapon_ar2 weapon_357 weapon_shotgun weapon_crowbar weapon_crossbow weapon_frag weapon_rpg weapon_smg1 weapon_stunstick weapon_slam weapon_pistol", "Put weapon names here", FCVAR_PLUGIN);

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

	// Create and exec config
	AutoExecConfig();
}

/* OnPlayerSpawn()
 *
 * When the player spawns.
 * -------------------------------------------------------------------------- */
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")), numWeapons;

	// No observers !
	if (IsPlayerAlive(client))
	{
		// Cleanup all player weapons if needed
		if (GetConVarBool(spawner_cleanup))
		{
			// Loop through all weapon slots
			for (new i; i <= MAX_SLOTS; i++)
			{
				new weaponIndex = -1;

				// Remove all player weapons if any in slot is valid
				while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, weaponIndex);
					AcceptEntityInput(weaponIndex, "Kill");
				}
			}
		}

		// Get the weapons list from convar string
		decl String:weapons[PLATFORM_MAX_PATH], String:pieces[64][sizeof(weapons)];
		GetConVarString(spawner_weapons, weapons, sizeof(weapons));

		// Remove all spaces from convar string and retrieve all 'pieces' between spaces (i.e. weapon class names)
		if ((numWeapons = ExplodeString(weapons, " ", pieces, sizeof(pieces), sizeof(pieces[]))))
		{
			// Loop through amount of 'pieces', which was assigned on ExplodeString native to numWeapons
			for (new i; i < numWeapons; i++)
			{
				// And give dem weapons to player
				GivePlayerItem(client, pieces[i]);
			}
		}
	}
}