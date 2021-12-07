/*
 * ===========================================================================================================
 * This plugin is based on greyscales original grenadepack plugin
 * Since steam finally fixed the ammo_<weapon>_max variables for nade types, I thought others would find this plugin
 * useful and fun.
 *
 * This plugin is VIP equiped.  VIP players can potentially be able to hold more of each type of nade than regular players
 * can.  If a player has the admin flag custom1 "o" they will be marked as VIP for this plugin.  You can override the flag 
 * needed for VIP by utilizing admin_overrides.cfg and assigning whatever flag you want to "grenadepack2_vip"
 *
 *
 * I like how he codes, giving all of the @param information, so I copied his style :)  It helps others out too
 *
 *  Grenade Pack 2
 *
 *  File:		  grenadepack2.sp
 *
 *  Description:   Allows and/or restricts players to a given number of he grenades, smoke grenades, and flashbangs
 *
 *  Copyright (C) 2009-2010  Greyscale
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ===========================================================================================================
 * 
 * Change Log:
 * 
 * Version 1.0.0
 * 	-	Initial release
 * 
 * Version 1.0.1
 * 	*	Fixed the check to prevent non-vip players from being able to carry more than they're allowed
 * 
 * Version 1.0.2
 * 	+	Added CVar to restrict players (VIP and non-VIP) from buying more than they're allowed to buy - by request.
 * 
 * Version 1.0.3
 * 	*	Some code clean up
 * 
 * Version 1.0.4
 * 	*	Changed code for better checking if player has certain type of nade
 * 	-	Got rid of unneeded code as suggested by Asherkin
 * 
 * Version 1.0.5
 * 	*	Fixed error with invalid handles
 * 	*	Fixed Disconnect code to unhook the correct players
 * 
 * Version 1.0.6
 * 	*	Fixed plugin so it will retain the CVar settings when the plugin is reloaded.
 * 	+	Added code to reset ammo cvars to original values when plugin is not enabled.
 * 	+	Enhanced plugin to identify VIP players when plugin is reloaded.
 * 
 * Version 1.0.7
 * 	*	Fixed plugin for CSS Update on 2/15/13 - sorry it took so long
 * 
 * Version 1.0.8
 * 	*	Fixed version number
 * 
 */

// Comment out to not require semicolons at the end of each line of code.
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

#define 	UPDATE_URL 				"http://dl.dropbox.com/u/3266762/GrenadePack2.txt"

#define 	PLUGIN_VERSION 			"1.0.8"
#define 	MAX_WEAPON_NAME 		80

#define 	PLUGIN_PREFIX 			"{green}[{lightgreen}Grenade Pack 2{green}]"

#define 	HEGrenadeOffset 		11	// (11 * 4)
#define 	FlashbangOffset 		12	// (12 * 4)
#define 	SmokegrenadeOffset		13	// (13 * 4)

/**
 * Array to track how many times a client has spawned so the plugin isn't announced every spawn.
 */
new SpawnCount[MAXPLAYERS+1] = {0, ...};

/**
 * Variables.
 */
new bool:Plugin_Enabled;
new bool:PlayerIsVIP[MAXPLAYERS+1] = {false, ...};

new announce, heMax, heMaxVip, smokeMax, smokeMaxVip, flashMax, flashMaxVip;

new BoughtHE[MAXPLAYERS+1] = {0, ...};
new BoughtFB[MAXPLAYERS+1] = {0, ...};
new BoughtSG[MAXPLAYERS+1] = {0, ...};

new bool:UseUpdater;
new bool:EnforceBuyLimit;

new orgHEGrenadeAmmo, orgSmokeGrenadeAmmo, orgFlashbangAmmo;

/**
 * Cvar handles.
 */
new Handle:HEGrenadeAmmo = INVALID_HANDLE;
new Handle:SmokeGrenadeAmmo = INVALID_HANDLE;
new Handle:FlashbangAmmo = INVALID_HANDLE;

/**
 * Record plugin info.
 */
public Plugin:myinfo = 
{
	name = "Grenade Pack 2",
	author = "TnTSCS",
	description = "Allows and/or restricts players to a given number of he grenades, smoke grenades, and flashbangs",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

/**
 * Plugin has started.
 */
public OnPluginStart()
{
	CreateConVar("sm_grenadepack2_version_build", SOURCEMOD_VERSION, "The version of SourceMod that 'Grenade Pack 2' was compiled with.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	CreateConVar("sm_grenadepack2_version", PLUGIN_VERSION, "The version of 'Grenade Pack 2'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	new Handle:hRandom; // KyleS HATES Handles
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_enabled", "1", 
	"Enable or disable the plugin ['0' = Disable]", _, true, 0.0, true, 1.0)), Enabled_Changed);
	Plugin_Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_announce", "5", 
	"Every X rounds the player is reminded of the plugin ['0' = Disable]", _, true, 0.0, true, 30.0)), Announce_Changed);
	announce = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_hegrenade", "1", 
	"Maximum number of HE Grenades regular players are allowed to carry.", _, true, 0.0, true, 100.0)), HE_Changed);
	heMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_hegrenade_vip", "3", 
	"Maximum number of HE Grenades VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), HE_VIP_Changed);
	heMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_smokegrenade", "1", 
	"Maximum number of Smoke Grenades regular players are allowed to carry.", _, true, 0.0, true, 100.0)), SMOKE_Changed);
	smokeMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_smokegrenade_vip", "2", 
	"Maximum number of Smoke Grenades VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), SMOKE_VIP_Changed);
	smokeMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_flashbang", "2", 
	"Maximum number of Flashbang's regular players are allowed to carry.", _, true, 0.0, true, 100.0)), FLASH_Changed);
	flashMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_flashbang_vip", "4", 
	"Maximum number of Flashbang's VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), FLASH_VIP_Changed);
	flashMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_enforce", "0", 
	"Enforce the limit so that players can't buy their max, use some, then buy more (they can still pick up more if they aren't carrying their max).", _, true, 0.0, true, 1.0)), EnforceChanged);
	EnforceBuyLimit = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_grenadepack2_update", "0", 
	"Use Updater plugin to auto-update GrenadePack2 when updates are available?", _, true, 0.0, true, 1.0)), UseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	// ======================================================================
	if ((HEGrenadeAmmo = FindConVar("ammo_hegrenade_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_hegrenade_max");
	}
	orgHEGrenadeAmmo = GetConVarInt(HEGrenadeAmmo);
	SetConVarInt(HEGrenadeAmmo, heMaxVip);
	
	if ((SmokeGrenadeAmmo = FindConVar("ammo_smokegrenade_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_smokegrenade_max");
	}
	orgSmokeGrenadeAmmo = GetConVarInt(SmokeGrenadeAmmo);
	SetConVarInt(SmokeGrenadeAmmo, smokeMaxVip);
	
	if ((FlashbangAmmo = FindConVar("ammo_flashbang_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_flashbang_max");
	}
	orgFlashbangAmmo = GetConVarInt(FlashbangAmmo);
	SetConVarInt(FlashbangAmmo, flashMaxVip);
	// ======================================================================
	
	LoadTranslations("grenadepack2.phrases");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	// Execute the config file
	AutoExecConfig(true);
	
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called after a library is added that the current plugin references 
 * optionally. A library is either a plugin name or extension name, as 
 * exposed via its include file.
 *
 * @param name			Library name.
 */
public OnLibraryAdded(const String:name[])
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been 
 * executed, and all plugin configs are done executing.  This is the best
 * place to initialize plugin functions which are based on cvar data.  
 *
 * @note This will always be called once and only once per map.  It will be 
 * called after OnMapStart().
 *
 * @noreturn
 */
public OnConfigsExecuted()
{
	// Check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPostAdminCheck(client)
{
	CheckIsPlayerVIP(client);
}

CheckIsPlayerVIP(client)
{
	// Check all clients connecting
	if (!IsFakeClient(client) && CheckCommandAccess(client, "grenadepack2_vip", ADMFLAG_CUSTOM1))
	{
		/**
		* Mark player as VIP.  VIP players are not hooked with Hook_Touch
		* and instead are allowed to purchase the maximum number of grenades, smoke grenades, and flashbangs
		* as set with ammo_hegrenade_max, ammo_smokegrenade_max, and ammo_flashbang_max cvars
		* which are all hooked with their corresponding sm_grenadepack2_<nade type>_vip
		*/
		PlayerIsVIP[client] = true;
		SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	}
	else
	{
		PlayerIsVIP[client] = false;
		
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	}
	
	// Set all client variables to 0
	ResetVariables(client, true, false);
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 * @note	Must use IsClientInGame(client) if you want to do client specific things
 */
public OnClientDisconnect(client)
{
	// ===================================================================================================================================
	// Reset client specific variables
	// ===================================================================================================================================
	if (IsClientInGame(client))
	{
		if (!PlayerIsVIP[client])
		{
			SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
		}
		
		ResetVariables(client, true, true);
	}
}

public ResetVariables(client, bool:Spawn, bool:VIP)
{
	BoughtFB[client] = 0;
	BoughtHE[client] = 0;
	BoughtSG[client] = 0;
	
	if (Spawn)
	{
		SpawnCount[client] = 0;
	}
	
	if (VIP)
	{
		PlayerIsVIP[client] = false;
	}
}

/**
 * Client has spawned.
 * 
 * @param event				The event handle.
 * @param name				The name of the event.
 * @param dontBroadcast 		Don't tell clients the event has fired.
 */
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Do not advertise to bots and only advertise if 'announce' > 0
	if (!IsFakeClient(client) && announce > 0)
	{
		// Announce on first spawn and every [n]th spawn ([n] = announce int)
		if (SpawnCount[client] == 0 || SpawnCount[client] == announce)
		{
			SpawnCount[client] = 0;
			
			if (PlayerIsVIP[client])
			{
				CPrintToChat(client, "%t", "VIP Announcement", PLUGIN_PREFIX, heMaxVip, flashMaxVip, smokeMaxVip);
			}
			else
			{
				CPrintToChat(client, "%t", "Announcement", PLUGIN_PREFIX, heMax, flashMax, smokeMax);
			}
		}
	}
	
	// Increment spawn count.
	SpawnCount[client]++;
	
	ResetVariables(client, false, false);
}


/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name (shortname like hegrenade, knife, or awp)
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	// If the plugin is disabled or the player is a VIP and we're not enforcing buy limits
	if (!Plugin_Enabled || (PlayerIsVIP[client] && !EnforceBuyLimit))
	{
		return Plugin_Continue;
	}
	
	/* Check if client is buying nade type and if it's allowed or not
	* Purchase allowed with Plugin_Continue
	* Purchase prohibited with Plugin_Handled
	*/
	if (StrEqual(weapon, "hegrenade", false))
	{
		if (!HEGrenadesOk(client)) // Player already has the maximum allowed equiped
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			return Plugin_Handled;
		}
		else
		{
			if (EnforceBuyLimit)
			{
				if ((PlayerIsVIP[client] && BoughtHE[client] >= heMaxVip) || (!PlayerIsVIP[client] && BoughtHE[client] >= heMax))
				{
					PrintCenterText(client, "%t", "Cannot Carry");
					CPrintToChat(client, "%t", "Purchased Max HE", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				else
				{
					BoughtHE[client]++;
				}
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "flashbang", false))
	{
		if (!FlashbangsOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			return Plugin_Handled;
		}
		else
		{
			if (EnforceBuyLimit)
			{
				if ((PlayerIsVIP[client] && BoughtFB[client] >= flashMaxVip) || (!PlayerIsVIP[client] && BoughtFB[client] >= flashMax))
				{
					PrintCenterText(client, "%t", "Cannot Carry");
					CPrintToChat(client, "%t", "Purchased Max FB", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				else
				{
					BoughtFB[client]++;
				}
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "smokegrenade", false))
	{
		if (!SmokeGrenadesOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			return Plugin_Handled;
		}
		else
		{
			if (EnforceBuyLimit)
			{
				if ((PlayerIsVIP[client] && BoughtSG[client] >= smokeMaxVip) || (!PlayerIsVIP[client] && BoughtSG[client] >= smokeMax))
				{
					PrintCenterText(client, "%t", "Cannot Carry");
					CPrintToChat(client, "%t", "Purchased Max SG", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				else
				{
					BoughtSG[client]++;
				}
			}
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

/**
* SDKHooks Function SDKHook_WeaponCanUse
*  - can player pick up nades
*
* @param client		Client index
* @param weapon	weapon entity index
* @return		Plugin_Continue to allow, else Handled to disallow
*/
public Action:WeaponCanUse(client, weapon)
{
	// Get and store the classname of the entity index the client is touching
	decl String:classname[MAX_WEAPON_NAME];
	classname[0] = '\0';
	
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	// Check if player is allowed to pick up nade type
	if (StrEqual(classname, "weapon_hegrenade", false))
	{
		if (!HEGrenadesOk(client))
		{
			return Plugin_Handled;
		}
	}
	else if (StrEqual(classname, "weapon_flashbang", false))
	{
		if (!FlashbangsOk(client))
		{
			return Plugin_Handled;
		}
	}
	else if (StrEqual(classname, "weapon_smokegrenade", false))
	{
		if (!SmokeGrenadesOk(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

HEGrenadesOk(client)
{
	if ((!PlayerIsVIP[client] && GetClientHEGrenades(client) >= heMax) || 
		(PlayerIsVIP[client] && GetClientHEGrenades(client) >= heMaxVip))
	{
		return false;
	}
	
	return true;
}

FlashbangsOk(client)
{
	if ((!PlayerIsVIP[client] && GetClientFlashbangs(client) >= flashMax) || 
		(PlayerIsVIP[client] && GetClientFlashbangs(client) >= flashMaxVip))
	{
		return false;
	}
		
	return true;
}

SmokeGrenadesOk(client)
{
	if ((!PlayerIsVIP[client] && GetClientSmokeGrenades(client) >= smokeMax) || 
		(PlayerIsVIP[client] && GetClientSmokeGrenades(client) >= smokeMaxVip))
	{
		return false;
	}
		
	return true;
}

GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

GetClientSmokeGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

GetClientFlashbangs(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

HookPlayers(bool:Enabled)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (Enabled)
			{
				CheckIsPlayerVIP(i);
			}
			else
			{
				ResetVariables(i, true, false);
				SDKUnhook(i, SDKHook_WeaponCanUse, WeaponCanUse);
			}
		}
	}
}

SetAmmoLimits(HEGrenade, SmokeGrenade, Flashbang)
{
	SetConVarInt(HEGrenadeAmmo, HEGrenade);
	SetConVarInt(SmokeGrenadeAmmo, SmokeGrenade);
	SetConVarInt(FlashbangAmmo, Flashbang);
}

/**
 * Cvar change callback for sm_grenadepack2_enabled.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public Enabled_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		UnhookEvent("player_spawn", Event_OnPlayerSpawn);
		CPrintToChatAll("%t", "Plugin Disabled", PLUGIN_PREFIX);
		SetAmmoLimits(orgHEGrenadeAmmo, orgSmokeGrenadeAmmo, orgFlashbangAmmo);
	}
	else
	{
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		CPrintToChatAll("%t", "Plugin Enabled", PLUGIN_PREFIX);
		SetAmmoLimits(heMaxVip, smokeMaxVip, flashMaxVip);
	}
		
	Plugin_Enabled = GetConVarBool(cvar);
	
	HookPlayers(Plugin_Enabled);
}

/**
 * Cvar change callback for sm_grenadepack2_announce.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public Announce_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	announce = GetConVarInt(cvar);
}

/**
 * Cvar change callback for sm_grenadepack2_hegrenade.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public HE_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited he", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed he", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	heMax = GetConVarInt(cvar);
	
	if (heMax > heMaxVip && heMaxVip != 0)
	{
		heMaxVip = heMax;
	}
}

/**
 * Cvar change callback for sm_grenadepack2_hegrenade_vip.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public HE_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited he vip", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed he vip", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	heMaxVip = GetConVarInt(cvar);
	
	if (heMax > heMaxVip && heMaxVip != 0)
	{
		heMax = heMaxVip;
	}
	
	SetConVarInt(HEGrenadeAmmo, heMaxVip);
}

/**
 * Cvar change callback for sm_grenadepack2_smokegrenade.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public SMOKE_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited smoke", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed smoke", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	smokeMax = GetConVarInt(cvar);
	
	if (smokeMax > smokeMaxVip && smokeMaxVip != 0)
	{
		smokeMaxVip = smokeMax;
	}
}

/**
 * Cvar change callback for sm_grenadepack2_smokegrenade_vip.
 * Announce to the server that the cvar has changed.
 * 
 * @param convar	The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public SMOKE_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited smoke vip", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed smoke vip", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	smokeMaxVip = GetConVarInt(cvar);
	
	if (smokeMax > smokeMaxVip && smokeMaxVip != 0)
	{
		smokeMax = smokeMaxVip;
	}
	
	SetConVarInt(SmokeGrenadeAmmo, smokeMaxVip);
}

/**
 * Cvar change callback for sm_grenadepack2_flashbang.
 * Announce to the server that the cvar has changed.
 * 
 * @param cvar		The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public FLASH_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited flash", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed flash", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	flashMax = GetConVarInt(cvar);
	
	if (flashMax > flashMaxVip && flashMaxVip != 0)
	{
		flashMaxVip = flashMax;
	}
}

/**
 * Cvar change callback for sm_grenadepack2_flashbang_vip.
 * Announce to the server that the cvar has changed.
 * 
 * @param cvar		The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public FLASH_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		CPrintToChatAll("%t", "Limit changed unlimited flash vip", PLUGIN_PREFIX);
	}
	else
	{
		CPrintToChatAll("%t", "Limit changed flash vip", PLUGIN_PREFIX, StringToInt(newValue));
	}
		
	flashMaxVip = GetConVarInt(cvar);
	
	if (flashMax > flashMaxVip && flashMaxVip != 0)
	{
		flashMax = flashMaxVip;
	}
	
	SetConVarInt(FlashbangAmmo, flashMaxVip);
}

/**
 * Cvar change callback for sm_grenadepack2_enforce.
 * 
 * @param cvar		The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public EnforceChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	EnforceBuyLimit = GetConVarBool(cvar);
}

/**
 * Cvar change callback for sm_grenadepack2_update.
 * 
 * @param cvar		The handle of the cvar being changed.
 * @param oldValue  	The value before it was changed.
 * @param newValue  	The value after it was changed.
 */
public UseUpdaterChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UseUpdater = GetConVarBool(cvar);
}