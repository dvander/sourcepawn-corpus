/* sm_replen.sp
Name: Ammo Replenishment Lite
Author: LumiStance
Date: 2012 - 11/25

Description:
	Provides automatic ammo refill and restock to Counter Strike: Source and Counter Strike: Global Offensive
	Refill, when enabled, will fill the magazine clip when you get a kill.
	Refill can be limited to headshots only.
	Restock, when enabled, will give a box of ammo when you run out.

	The weapon lookup for refill uses integer instead of string comparison to reduce CPU usage,
	and only when the weapon is first picked up.
	The ammo lookup for restock uses the weapon's ammo type as an array index to get the box size.

	Servers using this mod: www.gametracker.com/search/?search_by=server_variable&search_by2=sm_replenlite_version&searchipp=50

Installation:
	Place compiled plugin (sm_replen.smx) into your plugins folder.
	The configuration file (replen.cfg) is generated automatically.
	Changes to replen.cfg are read at map/plugin load time.
	Changes to cvars made in console take effect immediately.

Complimentary Plugins:
	Deathmatch Lite Respawn - http://forums.alliedmods.net/showthread.php?t=130853

Upgrade Notes:
	Added sm_replenlite_headshot as of v1.3; add this to replen.cfg if you wish to use it.

Problems, Bug Reports, Feature Requests, and Compliments:
	Please send me a private message at http://forums.alliedmods.net/private.php?do=newpm&u=46596
	Include a detailed description of how to reproduce the problem. Information about your server,
	such as dedicate/listen, platform (win32/linux), game, and ip address may be useful.

	I prefer to keep the plugin thread cleared so people don't have to wade through pages of fodder.
	The community will be given a chance to address any bug reports that are posted in the plugin thread.
	If you want a direct response from me, send a private message.

	Compliments are always welcomed in the thread.

Background:
	I developed this plugin as part of my SM Gun Menu Lite project.

	Reload Implementation
		Hooks from CSS:DM basics by Bailopan
		m_iAmmo http://forums.alliedmods.net/showthread.php?t=81546

Files:
	cstrike/addons/sourcemod/plugins/sm_replen.smx
	cstrike/cfg/sourcemod/replen.cfg

Configuration Variables (Change in replen.cfg):
	sm_replenlite_refill - Enable/Disable Clip Refill. (Default: "1")
	sm_replenlite_headshot - Enable/Disable Clip Refill only on headshot. (Default: "0")
	sm_replenlite_restock - Enable/Disable Ammo Restock. (Default: "1")

Changelog:
	1.5 <-> 2012 - 11/25 LumiStance
		Added guns for CS:GO
		Bulk of CacheClipSize() now from code generator
	1.4 <-> 2011 - 06/29 LumiStance (946 downloads)
		Remove code to log unknown ammo_type
	1.3 <-> 2011 - 06/28 LumiStance (2 downloads)
		Add code to allow refills only on headshot
		Improved refill to prevent unneeded reload
	1.2 <-> 2011 - 06/28 LumiStance (2 downloads)
		Refactored code to SetFailState if FindSendPropOffs fails
		Improved client_index validation in Event_HandleReserveAmmo() and Event_HandleAutoReload
		Add code to log unknown ammo_type for player name and weapon
		Add code to validate ammo_type
	1.1 <-> 2011 - 06/05 LumiStance (83 downloads)
		Add code to automatically create configuration file
	1.0 <-> 2011 - 06/04 LumiStance (8 downloads)
		Initial released
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "1.5-lm"
#define PLUGIN_ANNOUNCE "\x04[Replen Lite]\x01 v1.5-lm by LumiStance"
public Plugin:myinfo =
{
	name = "Replen Lite",
	author = "LumiStance",
	description = "Provides automatic ammo refill and restock to Counter Strike: Source",
	version = PLUGIN_VERSION,
	url = "http://srcds.lumistance.com/"
};

// Constants
enum Slots
{
	Slot_Primary,
	Slot_Secondary,
	Slot_Knife,
	Slot_Grenade,
	Slot_C4,
	Slot_None
};

// Console Variables
new Handle:g_ConVar_Version;
new Handle:g_ConVar_Refill;
new Handle:g_ConVar_Headshot;
new Handle:g_ConVar_Restock;
// Configuration
new g_RefillAmmo = false;
new g_Headshot = false;
new g_RestockAmmo = false;
// Weapon Entity Members and Data
new g_iAmmo = -1;
new g_hActiveWeapon = -1;
new g_iPrimaryAmmoType = -1;
new g_iClip1 = -1;
// Ammo Types: xxx, .50cal, 7.62mm, 5.56mm, 5.56mm, .338cal, 9mm, 12G, .45cal, .357cal, 5.7mm
// knife == -1, c4 == -1, hegrenade == 11, flashbang == 12, smokegrenade == 13
new const g_AmmoBoxQty[] = {0, 35, 90, 90, 200, 30, 120, 32, 100, 52, 100};
// Player Settings
new g_PlayerPrimaryAmmo[MAXPLAYERS+1] = {0, ...};
new g_PlayerSecondaryAmmo[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{
	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file
	g_ConVar_Version = CreateConVar("sm_replenlite_version", PLUGIN_VERSION, "[SM] Replen Lite Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Specify console variables used to configure plugin
	g_ConVar_Refill = CreateConVar("sm_replenlite_refill", "1", "Enable/Disable Clip Refill.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Headshot = CreateConVar("sm_replenlite_headshot", "0", "Enable/Disable Clip Refill only on headshot.", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_ConVar_Restock = CreateConVar("sm_replenlite_restock", "1", "Enable/Disable Ammo Restock.", FCVAR_PLUGIN|FCVAR_SPONLY);
	AutoExecConfig(true, "replen");

	// Cache Send Property Offsets
	g_iAmmo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	g_hActiveWeapon = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
	g_iPrimaryAmmoType = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	g_iClip1 = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	if (g_hActiveWeapon == -1 || g_iPrimaryAmmoType == -1 || g_iAmmo == -1 || g_iClip1 == -1)
		SetFailState("Failed to retrieve entity member offsets");

	// Event Hooks
	HookConVarChange(g_ConVar_Refill, Event_CvarChange);
	HookConVarChange(g_ConVar_Headshot, Event_CvarChange);
	HookConVarChange(g_ConVar_Restock, Event_CvarChange);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("weapon_fire_on_empty", Event_Reload);
}

// Occurs after round_start
public OnConfigsExecuted()
{
	// Synchronize Cvar Cache after configuration loaded
	RefreshCvarCache();
	// Work around A2S_RULES bug in linux orange box
	SetConVarString(g_ConVar_Version, PLUGIN_VERSION);
}

// Synchronize Cvar Cache when change made
public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshCvarCache();
}

stock RefreshCvarCache()
{
	g_RefillAmmo = GetConVarBool(g_ConVar_Refill);
	g_Headshot = GetConVarBool(g_ConVar_Headshot);
	g_RestockAmmo = GetConVarBool(g_ConVar_Restock);
}

public OnClientPutInServer(client_index)
{
	PrintToChat(client_index, PLUGIN_ANNOUNCE);
}

// Spawn weapons don't fire item_pickup
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_index = GetClientOfUserId(GetEventInt(event, "userid"));

	new String:sz_classname[32];
	new entity_index = GetPlayerWeaponSlot(client_index, _:Slot_Primary);
	if (IsValidEdict(entity_index))
	{
		GetEdictClassname(entity_index, sz_classname, sizeof(sz_classname));
		CacheClipSize(client_index, sz_classname[7]);
	}
	entity_index = GetPlayerWeaponSlot(client_index, _:Slot_Secondary);
	if (IsValidEdict(entity_index))
	{
		GetEdictClassname(entity_index, sz_classname, sizeof(sz_classname));
		CacheClipSize(client_index, sz_classname[7]);
	}
}

public Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:sz_item[32];
	GetEventString(event, "item", sz_item, sizeof(sz_item));
	CacheClipSize(GetClientOfUserId(GetEventInt(event, "userid")), sz_item);
}

stock CacheClipSize(client_index, const String:sz_item[])
{
	// Convert first 4 characters of item into an integer for fast comparison (big endian byte ordering)
	// sizeof(sz_item) must be >= 4
	new gun = (sz_item[0] << 24) + (sz_item[1] << 16) + (sz_item[2] << 8) + (sz_item[3]);

	if  (gun==0x6D616737)													// mag7
		g_PlayerPrimaryAmmo[client_index]=5;
	else if  (gun==0x786D3130 || gun==0x73617765)							// xm1014,  sawedoff
		g_PlayerPrimaryAmmo[client_index]=7;
	else if  (gun==0x6D330000 || gun==0x6E6F7661)							// m3,  nova
		g_PlayerPrimaryAmmo[client_index]=8;
	else if  (gun==0x73636F75 || gun==0x61777000 || gun==0x73736730)		// scout,  awp,  ssg08
		g_PlayerPrimaryAmmo[client_index]=10;
	else if  (gun==0x67337367 || gun==0x73636172)							// g3sg1,  scar20
		g_PlayerPrimaryAmmo[client_index]=20;
	else if  (gun==0x66616D61 || gun==0x756D7034)							// famas,  ump45
		g_PlayerPrimaryAmmo[client_index]=25;
	// ak47,  aug,  m4a1,  sg550,  mp5navy,  tmp,  mac10,  mp7,  mp9
	else if  (gun==0x616B3437 || gun==0x61756700 || gun==0x6D346131 || gun==0x73673535
		|| gun==0x6D70356E || gun==0x746D7000 || gun==0x6D616331 || gun==0x6D703700 || gun==0x6D703900)
		g_PlayerPrimaryAmmo[client_index]=30;
	else if  (gun==0x67616C69)												// galil
		g_PlayerPrimaryAmmo[client_index]=35;
	else if  (gun==0x70393000)												// p90
		g_PlayerPrimaryAmmo[client_index]=50;
	else if  (gun==0x62697A6F)												// bizon
		g_PlayerPrimaryAmmo[client_index]=64;
	else if  (gun==0x6D323439)												// m249
		g_PlayerPrimaryAmmo[client_index]=100;
	else if  (gun==0x6E656765)												// negev
		g_PlayerPrimaryAmmo[client_index]=150;
	else if  (gun==0x64656167)												// deagle
		g_PlayerSecondaryAmmo[client_index]=7;
	else if  (gun==0x75737000)												// usp
		g_PlayerSecondaryAmmo[client_index]=12;
	else if  (gun==0x70323238 || gun==0x686B7032 || gun==0x70323530)		// p228,  hkp2000,  p250
		g_PlayerSecondaryAmmo[client_index]=13;
	else if  (gun==0x676C6F63 || gun==0x66697665)							// glock,  fiveseven
		g_PlayerSecondaryAmmo[client_index]=20;
	else if  (gun==0x656C6974)												// elite
		g_PlayerSecondaryAmmo[client_index]=30;
	else if  (gun==0x74656339)												// tec9
		g_PlayerSecondaryAmmo[client_index]=32;
}

// Did a player get a kill?
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_RefillAmmo)
	{
		new victim_index = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker_index = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (0 < attacker_index && attacker_index <= MaxClients && attacker_index != victim_index && (!g_Headshot || GetEventBool(event, "headshot")))
			RefillAmmo(attacker_index);
	}
}

public Event_Reload(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_RestockAmmo)
		CreateTimer(0.1, Event_HandleReserveAmmo, GetEventInt(event, "userid"));
}

public Action:Event_HandleReserveAmmo(Handle:timer, any:user_index)
{
	new client_index = GetClientOfUserId(user_index);

	// This event implies IsClientInGame() while GetClientOfUserId() checks IsClientConnected()
	if (client_index && GetClientTeam(client_index) >= 2)
	{
		new entity_index = GetEntDataEnt2(client_index, g_hActiveWeapon);
		if (IsValidEdict(entity_index))
		{
			new ammo_type = GetEntData(entity_index, g_iPrimaryAmmoType);
			// Replenish Ammo Stock (not active clip) if empty
			if (ammo_type > 0 && ammo_type < sizeof(g_AmmoBoxQty)
			 && GetEntData(client_index, g_iAmmo+(ammo_type<<2)) == 0)
				SetEntData(client_index, g_iAmmo+(ammo_type<<2), g_AmmoBoxQty[ammo_type], 4, true);
		}
	}
}

stock RefillAmmo(client_index)
{
	new clip;
	new entity_index = GetEntDataEnt2(client_index, g_hActiveWeapon);
	if (IsValidEdict(entity_index))
	{
		if (entity_index == GetPlayerWeaponSlot(client_index, _:Slot_Primary))
			clip = g_PlayerPrimaryAmmo[client_index];
		else if (entity_index == GetPlayerWeaponSlot(client_index, _:Slot_Secondary))
			clip = g_PlayerSecondaryAmmo[client_index];

		if (clip)
			SetEntData(entity_index, g_iClip1, clip, 4, true);
	}
}
