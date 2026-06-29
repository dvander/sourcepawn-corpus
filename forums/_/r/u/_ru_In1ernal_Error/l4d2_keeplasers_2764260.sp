#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.3"
#define L4D2_WEPUPGFLAG_LASER  (1 << 2)

public Plugin myinfo =
{
	name = "L4D2 Keep Lasers",
	author = "dcx2 (assist: Mr. Zero) - 2020 by SilverShot",
	description = "Keep existing laser sights when picking up a new gun",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

ConVar g_cvarEnable;
bool g_bEnable;
ConVar g_cvarDebug;
bool g_bDebug;
ConVar g_cvarMode;
int g_iMode;
ConVar g_cvarNoHint;
bool g_bNoHint;

bool g_hasHadLasers[MAXPLAYERS+1];
int g_droppedWeapons[MAXPLAYERS+1];

public void OnPluginStart()
{
	g_cvarEnable = CreateConVar("sm_keeplasers_enable", "1", "Enables this plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarDebug = CreateConVar("sm_keeplasers_debug", "0", "Enable debugging output", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarNoHint = CreateConVar("sm_keeplasers_nohint", "1", "Disable laser sight upgrade hint", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarMode = CreateConVar("sm_keeplasers_mode", "2", "0: Swap laser sights if you drop a gun which had them while picking up a int one\n1: Keep laser sights if you ever had them\n2: Always have laser sights.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	CreateConVar("sm_keeplasers_version", PLUGIN_VERSION, "L4D2 Keep Lasers", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		g_hasHadLasers[i] = false;
		g_droppedWeapons[i] = -1;
	}

	AutoExecConfig(true, "L4D2_KeepLasers");

	g_cvarEnable.AddChangeHook(OnEnableChanged);
	g_cvarDebug.AddChangeHook(OnDebugChanged);
	g_cvarMode.AddChangeHook(OnModeChanged);
	g_cvarNoHint.AddChangeHook(OnNoHintChanged);

	g_bEnable = g_cvarEnable.BoolValue;
	g_bDebug = g_cvarDebug.BoolValue;
	g_iMode = g_cvarMode.IntValue;
	g_bNoHint = g_cvarNoHint.BoolValue;

	HookEvent("receive_upgrade", Event_ReceiveUpgrade);
	HookEvent("weapon_drop", Event_WeaponDrop);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("player_use", Event_PlayerUse);
}

public void OnEnableChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_bEnable = StringToInt(newVal) == 1;
}

public void OnDebugChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_bDebug = StringToInt(newVal) == 1;
}

public void OnModeChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_iMode = StringToInt(newVal);
	// if mode was changed to Always, give everyone lasersights immediately
	if (g_iMode == 2)
	{
		for (int i=1; i<MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue; // Invalid survivor, continue
			if (g_bDebug) PrintToChatAll("Mode changed to 2 (Always), giving client %N laser sights", i);
			GiveClientLaser(i);
		}
	}
	// if mode was changed to Keep, give everyone lasersights if they previously had them
	else if (g_iMode == 1)
	{
		for (int i=1; i<MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || !g_hasHadLasers[i]) continue; // Invalid survivor, continue
			if (g_bDebug) PrintToChatAll("Mode changed to 1 (Keep), giving client %N laser sights", i);
			GiveClientLaser(i);
		}
	}
}

public void OnNoHintChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	g_bNoHint = StringToInt(newVal) == 1;
}

public Action Event_ReceiveUpgrade(Event event, const char[] name, bool dontBroadcast)
{
	char Upgrade[32];
	event.GetString("upgrade", Upgrade, sizeof(Upgrade));
	if (StrEqual(Upgrade, "laser_sight", false))
	{
		// Remember that this client has had laser sights
		int targetClient = GetClientOfUserId(event.GetInt("userid"));
		if (g_bDebug) PrintToChatAll("%N received laser sights", targetClient);
		g_hasHadLasers[targetClient] = true;
	}
}

public Action Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnable) 	return Plugin_Continue;		// Not enabled?  Do nothing

	int targetClient = GetClientOfUserId(event.GetInt("userid"));

	// client 0, or not connected, or not in game, or not survivor?  Done
	if (targetClient == 0 || !IsClientConnected(targetClient) || !IsClientInGame(targetClient) || GetClientTeam(targetClient)!= 2) return Plugin_Continue;

	int droppedEnt = event.GetInt("propid");					// Grab the dropped weapon

	// WeaponDrop is called for all kinds of stuff (pills, melee, etc)
	// Can this dropped weapon have a laser sight?
	// If it can have a laser sight, does it have one?
	if ( IsValidWeapon(droppedEnt) && L4D2_CanWeaponUpgrades(droppedEnt) )
	{
		int droppedUpgrades = L4D2_GetWeaponUpgrades(droppedEnt);

		if (droppedUpgrades & L4D2_WEPUPGFLAG_LASER)
		{
			// Remember the dropped weapon, in case we need to restore laser sights
			g_droppedWeapons[targetClient] = EntIndexToEntRef(droppedEnt);

			// If the client dies, don't remove laser sights or the gun could disappear
			if (GetClientHealth(targetClient) > 0)
			{
				L4D2_SetWeaponUpgrades(droppedEnt, droppedUpgrades & ~L4D2_WEPUPGFLAG_LASER);
				CreateTimer(0.2, LaserDroppedDelay, GetClientUserId(targetClient)); //add a delay
			}
		}
	}

	return Plugin_Continue;
}

// We can't give the upgrade immediately because you don't quite have the new weapon yet
// So we use a small delay to make sure that UpgradeLaserSight is called after you have your new weapon
// This will also put the laser sight back on the dropped gun if the client still has a laser
public Action LaserDroppedDelay(Handle timer, any targetClient)
{
	targetClient = GetClientOfUserId(targetClient);
	if( !targetClient ) return;

	bool oldGun = false;
	int CurrentWeapon = -1;

	if (!IsClientInGame(targetClient) || !IsPlayerAlive(targetClient))
	{
		oldGun = true;	// Not in game or alive?  Do nothing
	}

	if (!oldGun)
	{
		CurrentWeapon = GetPlayerWeaponSlot(targetClient, 0);
		if (CurrentWeapon <= 0 || !IsValidEntity(CurrentWeapon))
		{
			oldGun = true;			// No gun?  Put laser sights back on the old one
		}
	}

	if (oldGun)
	{
		CurrentWeapon = g_droppedWeapons[targetClient];
		CurrentWeapon = EntRefToEntIndex(CurrentWeapon);
	}

	// TODO: how to spawn a gun with laser sights?
	// can we just give and force drop?
	if (CurrentWeapon <= 0 || !IsValidEntity(CurrentWeapon)) return;

	int CurrentUpgrades = L4D2_GetWeaponUpgrades(CurrentWeapon);
	if (!oldGun && (CurrentUpgrades & L4D2_WEPUPGFLAG_LASER))		// Already have laser sight on new gun?  Give it back to the old gun
	{
		oldGun = true;
		CurrentWeapon = g_droppedWeapons[targetClient];
		CurrentWeapon = EntRefToEntIndex(CurrentWeapon);
		if (CurrentWeapon <= 0 || !IsValidEntity(CurrentWeapon)) return;

		CurrentUpgrades = L4D2_GetWeaponUpgrades(CurrentWeapon);
	}

	// If drop-only mode and not oldGun, then they have no weapon and we are done, ItemPickup will activate laser sights for us
	if (!oldGun && g_iMode != 0)
	{
		return;
	}

	if (!oldGun && g_bDebug) PrintToChatAll("Swapped %N's laser sights", targetClient);
	if (oldGun && g_bDebug) PrintToChatAll("Restored laser sight on %N's old gun", targetClient);

	// Give new laser sight
	if (oldGun || g_bNoHint)
	{
		// No hint *enabled*, or old gun, set the upgrade quietly
		L4D2_SetWeaponUpgrades(CurrentWeapon, CurrentUpgrades | L4D2_WEPUPGFLAG_LASER);
	}
	else
	{
		// No hint *disabled*, or not old gun?  Then show hint with upgrade_add
		CheatCommand(targetClient, "upgrade_add", "LASER_SIGHT");
	}
}

// ItemPickup is called when a gun is picked up from a gun spawn,
// or when the give command gives a gun
// but NOT when you pick a dropped gun off the ground
public Action Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{

	if (!g_bEnable) 	return Plugin_Continue;		// Not enabled?  Do nothing

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return Plugin_Continue; // Invalid survivor, return

	// if mode 0, do nothing
	// if mode 1 and has not had lasers, do nothing
	// if mode 2, always give lasers
	if (g_iMode == 0 || (g_iMode == 1 && !g_hasHadLasers[client]))
	{
		return Plugin_Continue;
	}

	char Item[64];
	event.GetString("item", Item, sizeof(Item));
	
	if (g_bDebug) PrintToChatAll("Event_ItemPickup %s", Item);
	
	if (isLaserWeapon(Item, sizeof(Item), "Event_ItemPickup"))
	{
		if (g_bDebug) PrintToChatAll("Giving %N laser sights from item_pickup", client);
		GiveClientLaser(client);
	}
	return Plugin_Continue;
}

// Unfortunately, the only way to catch picking up weapons off the ground (without SDKHooks) is to hook player_use
public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnable) 	return Plugin_Continue;		// Not enabled?  Do nothing

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client)) return Plugin_Continue; // Invalid survivor, return

	// if mode 0, do nothing
	// if mode 1 and has not had lasers, do nothing
	// if mode 2, always give lasers
	if (g_iMode == 0 || (g_iMode == 1 && !g_hasHadLasers[client]))
	{
		return Plugin_Continue;
	}

	int entIndex = event.GetInt("targetid");
	if (entIndex <= 0 || !IsValidEntity(entIndex)) return Plugin_Continue; // Invalid weapon, return

	char Item[64];
	GetEdictClassname(entIndex, Item, sizeof(Item));

	// player can use all sorts of stuff, so before checking whether it's a laser weapon
	// let's make sure it's a weapon at all, because isLaserWeapon is one big mess of StrEqual
	
	if (g_bDebug) PrintToChatAll("Event_PlayerUse %s", Item);
	
	if (strncmp(Item, "weapon", 6) == 0 && isLaserWeapon(Item, sizeof(Item), "Event_PlayerUse"))
	{
		if (g_bDebug) PrintToChatAll("Giving %N laser sights from player_use", client);
		GiveClientLaser(client);
	}
	return Plugin_Continue;
}

// NOTE: destructively removes all weapon_, but this should make the million StrEqual's a little faster
bool isLaserWeapon(char[] Weapon, int weaponSize, char[] caller)
{
	if (g_bDebug) PrintToChatAll("isLaserWeapon %s caller %s", Weapon, caller);

	// ReplaceString(Weapon, weaponSize, "weapon_", ""); // Just [7] - Silvers.
	// return
		// StrEqual(Weapon[7], "rifle", false) ||
		// StrEqual(Weapon[7], "rifle_ak47", false) ||
		// StrEqual(Weapon[7], "rifle_desert", false) ||
		// StrEqual(Weapon[7], "rifle_sg552", false) ||
		// StrEqual(Weapon[7], "smg", false) ||
		// StrEqual(Weapon[7], "smg_silenced", false) ||
		// StrEqual(Weapon[7], "smg_mp5", false) ||
		// StrEqual(Weapon[7], "pumpshotgun", false) ||
		// StrEqual(Weapon[7], "shotgun_chrome", false) ||
		// StrEqual(Weapon[7], "autoshotgun", false) ||
		// StrEqual(Weapon[7], "shotgun_spas", false) ||
		// StrEqual(Weapon[7], "hunting_rifle", false) ||
		// StrEqual(Weapon[7], "sniper_military", false) ||
		// StrEqual(Weapon[7], "sniper_awp", false) ||
		// StrEqual(Weapon[7], "sniper_scout", false) ||
		// StrEqual(Weapon[7], "grenade_launcher", false) ||
		// StrEqual(Weapon[7], "rifle_m60", false);
		
		
		
	// there may be weapon_ or may be not, depends on caller ;)	
	ReplaceString(Weapon, weaponSize, "weapon_", "");
	
	return StrEqual(Weapon, "rifle", false) || StrEqual(Weapon, "rifle_ak47", false) || StrEqual(Weapon, "rifle_desert", false) || StrEqual(Weapon, "rifle_sg552", false) || 
		StrEqual(Weapon, "smg", false) || StrEqual(Weapon, "smg_silenced", false) || StrEqual(Weapon, "smg_mp5", false) || StrEqual(Weapon, "pumpshotgun", false) ||
		StrEqual(Weapon, "shotgun_chrome", false) || StrEqual(Weapon, "autoshotgun", false) || StrEqual(Weapon, "shotgun_spas", false) ||
		StrEqual(Weapon, "hunting_rifle", false) || StrEqual(Weapon, "sniper_military", false) || StrEqual(Weapon, "sniper_awp", false) ||
		StrEqual(Weapon, "sniper_scout", false) || StrEqual(Weapon, "grenade_launcher", false) || StrEqual(Weapon, "rifle_m60", false);
}

// This only gives the laser to the client's equipped weapon, it can't do anything to a dropped gun
stock void GiveClientLaser(any client)
{
//		PrintToChatAll("Giving %N laser sights on %s", client, Weapon);
	int priWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
	if (priWeapon <= 0 || !IsValidEntity(priWeapon)) return; // Invalid weapon, return

	if (!L4D2_CanWeaponUpgrades(priWeapon)) return; // This weapon does not support upgrades

	int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of primary weapon
	if (upgrades & L4D2_WEPUPGFLAG_LASER) return; // Primary weapon already has laser sight, return

	// Give new laser sight
	if (g_bNoHint)
	{
		// No hint *enabled*, or ground gun, set the upgrade quietly
		L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER);
	}
	else
	{
		// No hint *disabled*?  Then show hint with upgrade_add, unless it's a gun on the ground
		CheatCommand(client, "upgrade_add", "LASER_SIGHT");
	}
}

// Made this myself, based on the two codes below
bool L4D2_CanWeaponUpgrades(int weapon)
{
	return (GetEntSendPropOffs(weapon, "m_upgradeBitVec") > -1);
}

// Thanks Mr. Zero!
int L4D2_GetWeaponUpgrades(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

// Thanks Mr. Zero!
void L4D2_SetWeaponUpgrades(int weapon, int upgrades)
{
	if (weapon < 0) return;
	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
}

// Not sure where I grabbed this, it's pretty common
void CheatCommand(int client, const char[] command, const char[] arguments)
{
    int flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
}

/*
 * Checks whether the entity is a valid weapon or not.
 *
 * @param weapon                Weapon Entity.
 * @return                              True if the entity is a valid weapon, false otherwise.
 */
stock bool IsValidWeapon(int weapon)
{
	char name[32];
	if (IsValidEdict(weapon))
	{
		if(GetEdictClassname(weapon, name, sizeof(name)))
		{
			if( strncmp(name, "weapon_", 7) == 0 && StrContains(name[7], "spawn") == -1)
				return true;
		}
	}

	return false;
}