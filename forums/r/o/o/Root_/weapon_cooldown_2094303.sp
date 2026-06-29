/**
* Weapon Cooldown by Root
*
* Description:
*   Creates a defined delay between shots for specified weapons.
*
* Version 2.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#include <sdkhooks>

// ====[ CONSTANTS ]================================================
#define PLUGIN_NAME    "Weapon Cooldown"
#define PLUGIN_VERSION "2.0"
#define INVALID_OFFSET -1

enum // values in trie array
{
	maxshots,      // max. shots before cooldown
	Float:fldelay, // delay between shots
	array_size     // size of trie array
};

// ====[ VARIABLES ]================================================
new	Handle:WeaponsTrie,
	Handle:WC_Enabled,
	m_hActiveWeapon,
	m_flNextAttack,
	m_flNextPrimaryAttack,
	m_flNextSecondaryAttack;

// ====[ PLUGIN ]===================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Creates a defined delay between shots for specified weapons",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/",
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ------------------------------------------------------------------ */
public OnPluginStart()
{
	// Find send property offsets that required for this plugin
	m_hActiveWeapon         = FindSendPropOffsEx("CBasePlayer",       "m_hActiveWeapon");
	m_flNextAttack          = FindSendPropOffsEx("CBasePlayer",       "m_flNextAttack");
	m_flNextPrimaryAttack   = FindSendPropOffsEx("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	m_flNextSecondaryAttack = FindSendPropOffsEx("CBaseCombatWeapon", "m_flNextSecondaryAttack");

	// Create plugin ConVars
	CreateConVar("sm_weapon_cooldown_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	WC_Enabled = CreateConVar("sm_weapon_cooldown_enable", "1", "Whether or not enable Weapon Cooldown", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// I have to hook weapon_fire event because 'CStrike have a custom CCSFireBullets or something like that' (c) psychonic
	HookEventEx("weapon_fire", OnWeaponFire);

	// Hook changes only for main variable
	HookConVarChange(WC_Enabled, OnPluginToggle);

	// Simulates late load for a plugin
	OnPluginToggle(WC_Enabled, "0", "1");

	// Create trie with cooldown settings
	WeaponsTrie = CreateTrie();
}

/* OnPluginToggle()
 *
 * Called when plugin is enabled or disabled by ConVar.
 * ------------------------------------------------------------------ */
public OnPluginToggle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Loop through all clients
	for (new client = 1; client <= MaxClients; client++)
	{
		// Ignore all not ingame players
		if (!IsClientInGame(client)) continue;

		// Get the new changed value
		switch (StringToInt(newValue))
		{
			// Hook or unhook callback appropriately
			case false: SDKUnhook(client, SDKHook_FireBulletsPost, OnFireBullets);
			case true:  SDKHookEx(client, SDKHook_FireBulletsPost, OnFireBullets);
		}
	}
}

/* OnMapStart()
 *
 * When the map starts.
 * ------------------------------------------------------------------ */
public OnMapStart()
{
	// Get the config and set weapons trie values eventually
	decl String:filepath[PLATFORM_MAX_PATH], Handle:file, cooldown[array_size];
	BuildPath(Path_SM, filepath, sizeof(filepath), "configs/weapon_cooldown.txt");

	// Check whether or not plugin config is exists
	if ((file = OpenFile(filepath, "r")) != INVALID_HANDLE)
	{
		ClearTrie(WeaponsTrie);

		decl String:fileline[PLATFORM_MAX_PATH];
		decl String:datas[3][PLATFORM_MAX_PATH];

		// Read every line in config and get rid of pieces
		while (ReadFileLine(file, fileline, sizeof(fileline)))
		{
			if (ExplodeString(fileline, ";", datas, sizeof(datas), sizeof(datas[])) == 3)
			{
				// Retrieve all required values to write in trie array
				cooldown[maxshots] = StringToInt(datas[1]);
				cooldown[fldelay]  = StringToFloat(datas[2]);
				SetTrieArray(WeaponsTrie, datas[0], cooldown, array_size);
			}
		}
	}
	else SetFailState("Unable to load plugin configuration file \"%s\"!", file);

	// Close config handle
	CloseHandle(file);
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * ------------------------------------------------------------------ */
public OnClientPutInServer(client)
{
	if (GetConVarBool(WC_Enabled))
	{
		// Hook every connected player if plugin enabled
		SDKHookEx(client, SDKHook_FireBulletsPost, OnFireBullets);
	}
}

/* OnWeaponFire()
 *
 * Called when a client is firing a weapon for both CS:S and CS:GO.
 * ------------------------------------------------------------------ */
public OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if plugin is enabled
	if (GetConVarBool(WC_Enabled))
	{
		// Retrieve the weapon string from event key
		decl String:weapon[16]; // max string length
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		// Make FireBullets callback from event
		OnFireBullets(GetClientOfUserId(GetEventInt(event, "userid")), 0, weapon);
	}
}

/* OnFireBullets()
 *
 * Called when a client is firing a weapon.
 * ------------------------------------------------------------------ */
public OnFireBullets(client, dummy, const String:weaponname[])
{
	decl cooldown[array_size], weapon, Float:time;
	if (GetTrieArray(WeaponsTrie, weaponname, cooldown, array_size) && (weapon = GetEntDataEnt2(client, m_hActiveWeapon)) != INVALID_OFFSET)
	{
		/**
		* For some reason second param (dummy) in FireBulletsPost callback is not static
		* So it means that shots aren't calculated when weapon fires, but it works fine for shotguns probably
		* I have to use static here to properly calculate shots when callback is fired due to plugin features.
		*/
		static shots;

		// If player has made more shots than max shots value in trie array
		if (++shots >= cooldown[maxshots])
		{
			// Reset all made shots
			shots = 0;

			// Declare the defined cooldown
			time  = GetGameTime() + cooldown[fldelay];

			// Prevnet player and its weapon from firing during the cooldown
			SetEntDataFloat(client, m_flNextAttack,          time);
			SetEntDataFloat(weapon, m_flNextPrimaryAttack,   time);
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, time);
		}
	}
}

/* FindSendPropOffsEx()
 *
 * Returns the offset of the specified network property.
 * --------------------------------------------------------------------------- */
FindSendPropOffsEx(const String:serverClass[64], const String:propName[64])
{
	new offset = FindSendPropOffs(serverClass, propName);

	// Disable plugin if a networkable send property offset was not found
	if (offset <= 0)
	{
		SetFailState("Unable to find offset: \"%s::%s\"!", serverClass, propName);
	}

	return offset;
}