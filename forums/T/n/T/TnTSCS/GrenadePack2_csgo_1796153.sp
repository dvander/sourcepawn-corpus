/*
 * ===========================================================================================================
 * This plugin is VIP equiped.  VIP players are able to hold more of each type of nade than regular players can.
 * If a player has the admin flag custom1 "a" (reservation) they will be marked as VIP for this plugin.  You can override 
 * the flag needed for VIP by utilizing admin_overrides.cfg and assigning whatever flag you want to "gp2_csgo_vip"
 *
 *
 *  Grenade Pack 2 for CS:GO
 *
 *  File:		  GrenadePack2_csgo.sp
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
 * 	Version 0.0.1.0
 * 		*	Initial release
 * 
 * 	Version 0.0.1.1
 * 		*	Cleaned up code a little
 * 
 * 	Version 0.0.1.2
 * 		*	01/23/13 CS:GO Update Fix
 * 
 * 	Version 0.0.1.3
 * 		+	Added ability to define a hard set limit for nades players can have, regardless of type
 * 		+	Added ability to define a hard set limit for types of nades a player can have
 * 
 * 	Version 0.0.1.4
 * 		*	Adjusted grenade offsets for 08/15/13 CS:GO update
 * 
 * 	Version 0.0.1.5
 * 		*	Adjusted grenade offsets
 * 		*	Fixed bug in CS_OnBuyCommand when using Total Nades option
 * 
 * 	Version 0.0.1.6
 * 		*	Fixed bug when players spawn with nades and using Total Nades option, they are allowed to buy beyond the max allowed.
 * 			-	Reported by parthi (https://forums.alliedmods.net/showpost.php?p=2277978&postcount=47)
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>

#define 	UPDATE_URL 				"http://dl.dropbox.com/u/3266762/GrenadePack2_csgo.txt"

#define 	PLUGIN_VERSION 			"0.0.1.6"
#define 	MAX_WEAPON_NAME 		80

#define 	PLUGIN_PREFIX 			"{default}[{green}CS:GO Grenade Pack 2{default}]"

#define 	HEGrenadeOffset 		14	// (14 * 4)
#define 	FlashbangOffset 		15	// (15 * 4)
#define 	SmokegrenadeOffset		16	// (16 * 4)
#define		IncenderyGrenadesOffset	17	// (17 * 4) Also Molotovs
#define		DecoyGrenadeOffset		18	// (18 * 4)

/**
 * Array to track how many times a client has spawned so the plugin isn't announced every spawn.
 */
new SpawnCount[MAXPLAYERS+1] = {0, ...};

/**
 * Variables.
 */
new bool:Plugin_Enabled = true;
new bool:PlayerIsVIP[MAXPLAYERS+1] = {false, ...};
new heMax ;
new smokeMax;
new flashMax;
new incenderyMax;
new decoyMax;

new heMaxVip;
new smokeMaxVip;
new flashMaxVip;
new incenderyMaxVip;
new decoyMaxVip;

new announce;


new bool:EnforceBuyLimit;
new BoughtHE[MAXPLAYERS+1] = {0, ...};
new BoughtFB[MAXPLAYERS+1] = {0, ...};
new BoughtSG[MAXPLAYERS+1] = {0, ...};
new BoughtINC[MAXPLAYERS+1] = {0, ...};
new BoughtDECOY[MAXPLAYERS+1] = {0, ...};
new TotalType[MAXPLAYERS+1] = {0, ...};

new bool:UseUpdater;
new bool:UseTotalNades;
new bool:UseRestrictType;
new bool:AdvertiseLimitChanges;

new OrgGrenadeAmmoTotal;
new OrgMaxDefault;
new OrgLimitFlashbang;

new TotalNades;
new TotalNadesVIP;
new RestrictType;
new RestrictTypeVIP;

/**
 * Cvar handles.
 */
new Handle:GrenadeAmmoTotal = INVALID_HANDLE;
new Handle:MaxDefault = INVALID_HANDLE;
new Handle:LimitFlashbang = INVALID_HANDLE;
new Handle:MaxNadeType = INVALID_HANDLE;
new Handle:MaxNadeTypeVIP = INVALID_HANDLE;
new Handle:MaxNades = INVALID_HANDLE;
new Handle:MaxNadesVIP = INVALID_HANDLE;

new UseDebug;
new String:dmsg[MAX_MESSAGE_LENGTH];

/**
 * Declare this as a struct in your plugin to expose its information.
 * Example:
 *
 * public Plugin:myinfo =
 * {
 *    name = "My Plugin",
 *    //etc
 * };
 */
public Plugin:myinfo = 
{
	name = "Grenade Pack 2 for CS:GO",
	author = "TnTSCS aka ClarkKent",
	description = "Allows and/or restricts players to a given number of HE Grenades, Incendery Grenades, Decoy Nades, Smokegrenades, and Flashbangs",
	version = PLUGIN_VERSION,
	url = "http://www.dhgamers.com"
}

/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	CreateConVar("sm_gp2_csgo_version_build", SOURCEMOD_VERSION, "The version of SourceMod that 'Grenade Pack 2 for CS:GO' was compiled with.", FCVAR_PLUGIN | FCVAR_DONTRECORD);
	CreateConVar("sm_gp2_csgo_version", PLUGIN_VERSION, "The version of 'Grenade Pack 2 for CS:GO'", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	
	new Handle:hRandom = INVALID_HANDLE; // KyleS HATES Handles
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_enabled", "1", 
	"Enable or disable the plugin ['0' = Disable]", _, true, 0.0, true, 1.0)), Enabled_Changed);
	Plugin_Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_announce", "5", 
	"Every X rounds the player is reminded of the plugin ['0' = Disable]", _, true, 0.0, true, 30.0)), Announce_Changed);
	announce = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_hegrenade", "1", 
	"Maximum number of HE Grenades regular players are allowed to carry.", _, true, 0.0, true, 100.0)), HE_Changed);
	heMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_hegrenade_vip", "3", 
	"Maximum number of HE Grenades VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), HE_VIP_Changed);
	heMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_incgrenade", "1", 
	"Maximum number of Incendery/Molotov regular players are allowed to carry.", _, true, 0.0, true, 100.0)), INC_Changed);
	incenderyMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_incgrenade_vip", "2", 
	"Maximum number of Incendery/Molotov VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), INC_VIP_Changed);
	incenderyMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_decoy", "1", 
	"Maximum number of Decoy Grenades regular players are allowed to carry.", _, true, 0.0, true, 100.0)), DECOY_Changed);
	decoyMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_decoy_vip", "2", 
	"Maximum number of Decoy Grenades VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), DECOY_VIP_Changed);
	decoyMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_smokegrenade", "1", 
	"Maximum number of Smoke Grenades regular players are allowed to carry.", _, true, 0.0, true, 100.0)), SMOKE_Changed);
	smokeMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_smokegrenade_vip", "2", 
	"Maximum number of Smoke Grenades VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), SMOKE_VIP_Changed);
	smokeMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_flashbang", "2", 
	"Maximum number of Flashbang's regular players are allowed to carry.", _, true, 0.0, true, 100.0)), FLASH_Changed);
	flashMax = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_flashbang_vip", "4", 
	"Maximum number of Flashbang's VIP players are allowed to carry.", _, true, 0.0, true, 100.0)), FLASH_VIP_Changed);
	flashMaxVip = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_enforce", "0", 
	"Enforce the limit so that players can't buy their max, use some, then buy more (they can still pick up more if they aren't carrying their max).", _, true, 0.0, true, 1.0)), EnforceChanged);
	EnforceBuyLimit = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_update", "0", 
	"Use Updater plugin to auto-update GrenadePack2 when updates are available?", _, true, 0.0, true, 1.0)), UseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_totalnades", "0", 
	"Use the total nades settings?", _, true, 0.0, true, 1.0)), UseTotalChanged);
	UseTotalNades = GetConVarBool(hRandom);
	
	HookConVarChange((MaxNades = CreateConVar("sm_gp2_csgo_total", "0", 
	"Maximum number of nades, regardless of type, regular players are allowed to carry.", _, true, 0.0, true, 99.0)), TotalChanged);
	TotalNades = GetConVarInt(MaxNades);
	
	HookConVarChange((MaxNadesVIP = CreateConVar("sm_gp2_csgo_total_vip", "0", 
	"Maximum number of nades, regardless of type, VIP players are allowed to carry.", _, true, 0.0, true, 99.0)), TotalVIPChanged);
	TotalNadesVIP = GetConVarInt(MaxNadesVIP);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_restricttype", "0", 
	"Use the nade type restriction settings?", _, true, 0.0, true, 1.0)), UseRestrictTypeChanged);
	UseRestrictType = GetConVarBool(hRandom);
	
	HookConVarChange((MaxNadeType = CreateConVar("sm_gp2_csgo_restrict", "0", 
	"Maximum number of different types of nades regular players are allowed to carry.", _, true, 0.0, true, 7.0)), RestrictTypeChanged);
	RestrictType = GetConVarInt(MaxNadeType);
	
	HookConVarChange((MaxNadeTypeVIP = CreateConVar("sm_gp2_csgo_restrict_vip", "0", 
	"Maximum number of different types of nades VIP players are allowed to carry.", _, true, 0.0, true, 7.0)), RestrictTypeVIPChanged);
	RestrictTypeVIP = GetConVarInt(MaxNadeTypeVIP);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_advertise", "0", 
	"Advertise when nade limits change?", _, true, 0.0, true, 1.0)), AdvertiseLimitChangesChanged);
	AdvertiseLimitChanges = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_gp2_csgo_debug", "0", 
	"Set the debug mode, add up the values to determine what you want.\n0 = No Debug\n1 = Log Debug information\n2 = Debug in-game msgs", _, true, 0.0, true, 3.0)), OnDebugChanged);
	UseDebug = GetConVarInt(hRandom);
	
	// ======================================================================
	if ((GrenadeAmmoTotal = FindConVar("ammo_grenade_limit_total")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_grenade_limit_total");
	}
	OrgGrenadeAmmoTotal = GetConVarInt(GrenadeAmmoTotal);
	
	if ((MaxDefault = FindConVar("ammo_grenade_limit_default")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_grenade_limit_default");
	}
	OrgMaxDefault = GetConVarInt(MaxDefault);
	
	if ((LimitFlashbang = FindConVar("ammo_grenade_limit_flashbang")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_grenade_limit_flashbang");
	}
	OrgLimitFlashbang = GetConVarInt(LimitFlashbang);
	// ======================================================================
	
	LoadTranslations("grenadepack2_csgo.phrases");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	AutoExecConfig(true);
}

AdjustMaxGrenadeAllowance()
{
	if (UseTotalNades)
	{
		SetConVarInt(MaxDefault, TotalNadesVIP);
		SetConVarInt(GrenadeAmmoTotal, TotalNadesVIP);
		SetConVarInt(LimitFlashbang, TotalNadesVIP);
		
		return;
	}
	
	new total = heMaxVip + smokeMaxVip + flashMaxVip + incenderyMaxVip + decoyMaxVip;
	
	SetConVarInt(MaxDefault, total);
	SetConVarInt(GrenadeAmmoTotal, total);
	
	SetConVarInt(LimitFlashbang, flashMaxVip);
}

ResetMaxGrenadeAllowance()
{
	SetConVarInt(MaxDefault, OrgMaxDefault);
	SetConVarInt(GrenadeAmmoTotal, OrgGrenadeAmmoTotal);	
	SetConVarInt(LimitFlashbang, OrgLimitFlashbang);
}

HookPlayers(bool:enabled)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (enabled)
			{
				SDKHook(i, SDKHook_WeaponCanUse, WeaponCanUse);
			}
			else
			{
				SDKUnhook(i, SDKHook_WeaponCanUse, WeaponCanUse);
			}
		}
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
	
	AdjustMaxGrenadeAllowance();
}

/**
 * Called when a client is entering the game.
 *
 * Whether a client has a steamid is undefined until OnClientAuthorized
 * is called, which may occur either before or after OnClientPutInServer.
 * Similarly, use OnClientPostAdminCheck() if you need to verify whether 
 * connecting players are admins.
 *
 * GetClientCount() will include clients as they are passed through this 
 * function, as clients are already in game at this point.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientPutInServer(client)
{
	if (Plugin_Enabled)
	{
		SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
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
	// Check all connecting clients and mark as VIP if they qualify
	if (!IsFakeClient(client))
	{
		PlayerIsVIP[client] = CheckCommandAccess(client, "gp2_csgo_vip", ADMFLAG_RESERVATION);
	}
	
	ResetVariables(client, true, false);
}

/**
 * Resets client variables
 *
 * @param client		Client index.
 * @param Spawn	true to reset spawn count
 * @param VIP		true to reset PlayerIsVIP
 * @noreturn
 */
ResetVariables(client, bool:Spawn, bool:VIP)
{
	BoughtFB[client] = 0;
	BoughtHE[client] = 0;
	BoughtSG[client] = 0;
	BoughtINC[client] = 0;
	TotalType[client] = 0;
	BoughtDECOY[client] = 0;
	
	if (Spawn)
	{
		SpawnCount[client] = 0;
	}
	
	if (VIP)
	{
		PlayerIsVIP[client] = false;
	}
	
	if (UseDebug > 0)
	{
		Format(dmsg, sizeof(dmsg), "Reset variables for \"%L\" [VIP=%s]", client, (PlayerIsVIP[client] ? "true" : "false"));
		DebugMessage(dmsg);
	}
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
	// Must check if client is in game first
	if (IsClientInGame(client))
	{
		ResetVariables(client, true, true);
		
		// Unhook client
		SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
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
	if (!IsFakeClient(client) && announce >= 1)
	{
		// Announce on first spawn and every [n]th spawn ([n] = announce int)
		if (SpawnCount[client] == 0 || SpawnCount[client] == announce)
		{
			SpawnCount[client] = 0;
			
			if (UseTotalNades)
			{
				if(PlayerIsVIP[client])
				{
					CPrintToChat(client, "%t", "VIP Announcement Total", PLUGIN_PREFIX, TotalNadesVIP);
				}
				else
				{
					CPrintToChat(client, "%t", "Announcement Total", PLUGIN_PREFIX, TotalNades);
				}
			}
			else
			{
				if(PlayerIsVIP[client])
				{
					CPrintToChat(client, "%t", "VIP Announcement", PLUGIN_PREFIX, heMaxVip, incenderyMaxVip, flashMaxVip, smokeMaxVip, decoyMaxVip);
					if (UseRestrictType)
						CPrintToChat(client, "%t", "VIP Announcement RestrictType", PLUGIN_PREFIX, RestrictTypeVIP);
				}
				else
				{
					CPrintToChat(client, "%t", "Announcement", PLUGIN_PREFIX, heMax, incenderyMax, flashMax, smokeMax, decoyMax);
					if (UseRestrictType)
						CPrintToChat(client, "%t", "Announcement RestrictType", PLUGIN_PREFIX, RestrictType);
				}
			}
		}
	}
	
	// Increment spawn count.
	SpawnCount[client]++;
	
	ResetVariables(client, false, false);
	
	UpdateBoughtNadeTypeCounts(client);
}

UpdateBoughtNadeTypeCounts(client)
{
	BoughtDECOY[client] = GetClientDecoyGrenades(client);
	BoughtFB[client] = GetClientFlashbangs(client);
	BoughtHE[client] = GetClientHEGrenades(client);
	BoughtINC[client] = GetClientIncendaryGrenades(client);
	BoughtSG[client] = GetClientSmokeGrenades(client);
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
	if (!Plugin_Enabled || !IsGrenadeType(weapon))// || IsFakeClient(client))// || (PlayerIsVIP[client] && !EnforceBuyLimit))
	{
		return Plugin_Continue;
	}
	
	if (UseTotalNades)
	{
		if (!PlayerIsVIP[client])
		{
			if ((BoughtDECOY[client] + BoughtFB[client] + BoughtHE[client] + BoughtINC[client] + BoughtSG[client]) >= TotalNades)
			{
				PrintCenterText(client, "%t", "Cannot Carry");
				CPrintToChat(client, "%t", "Purchased Max Nades", PLUGIN_PREFIX, TotalNades);
				
				if (UseDebug > 0)
				{
					Format(dmsg, sizeof(dmsg), "%L is not a VIP and is not allowed to buy %s because they've already purchased the maximum number of grenades [%i]", client, weapon, TotalNades);
					DebugMessage(dmsg);
					Format(dmsg, sizeof(dmsg), "%L has purchased the following: HE=%i, Smoke=%i, Flash=%i, Decoy=%i, INC=%i", client, BoughtHE[client], BoughtSG[client], BoughtFB[client], BoughtDECOY[client], BoughtINC[client]);
					DebugMessage(dmsg);
				}
				
				return Plugin_Handled;
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is not a VIP and is allowed to buy %s because they haven't reached the maximum number of grenades, yet", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
		else
		{
			if ((BoughtDECOY[client] + BoughtFB[client] + BoughtHE[client] + BoughtINC[client] + BoughtSG[client]) >= TotalNadesVIP)
			{
				PrintCenterText(client, "%t", "Cannot Carry");
				CPrintToChat(client, "%t", "Purchased Max Nades", PLUGIN_PREFIX, TotalNadesVIP);
				
				if (UseDebug > 0)
				{
					Format(dmsg, sizeof(dmsg), "%L is a VIP but is not allowed to buy %s because they've already purchased the maximum number of grenades [%i]", client, weapon, TotalNadesVIP);
					DebugMessage(dmsg);
					Format(dmsg, sizeof(dmsg), "%L has purchased the following: HE=%i, Smoke=%i, Flash=%i, Decoy=%i, INC=%i", client, BoughtHE[client], BoughtSG[client], BoughtFB[client], BoughtDECOY[client], BoughtINC[client]);
					DebugMessage(dmsg);
				}
				
				return Plugin_Handled;
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is a VIP and is allowed to buy %s because they haven't reached the maximum number of grenades, yet", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, weapon))
	{
		PrintCenterText(client, "%t", "Cannot Carry");
		
		if (PlayerIsVIP[client])
		{
			CPrintToChat(client, "%t", "Purchased Max Nade Type", PLUGIN_PREFIX, RestrictTypeVIP);
		}
		else
		{
			CPrintToChat(client, "%t", "Purchased Max Nade Type", PLUGIN_PREFIX, RestrictType);
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "%L %s a VIP, but is already carrying the maximum number of different types of nades, cannot buy %s", client, (PlayerIsVIP[client] ? "is" : "is not"), weapon);
			DebugMessage(dmsg);
			Format(dmsg, sizeof(dmsg), "%L is carrying following: HE=%i, Smoke=%i, Flash=%i, Decoy=%i, INC=%i", client, GetClientHEGrenades(client), GetClientSmokeGrenades(client), GetClientFlashbangs(client), GetClientDecoyGrenades(client), GetClientIncendaryGrenades(client));
			DebugMessage(dmsg);
		}
		
		return Plugin_Handled;
	}
	
	// Check what client is buying and either allow or disallow
	if (StrEqual(weapon, "hegrenade", false))
	{
		if (!HEGrenadesOk(client)) // Player already has the maximum allowed equipped
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already have the maximum allowed equiped.", client, weapon);
				DebugMessage(dmsg);
				Format(dmsg, sizeof(dmsg), "%L has [%i] of %s.", client, GetClientHEGrenades(client), weapon);
				DebugMessage(dmsg);
			}
			
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
					
					if (UseDebug > 0)
					{
						Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already bought the maximum allowed for this round.", client, weapon);
						DebugMessage(dmsg);
						Format(dmsg, sizeof(dmsg), "%L has already purchased [%i] of %s.", client, BoughtHE[client], weapon);
						DebugMessage(dmsg);
					}
					
					return Plugin_Handled;
				}
				else
				{
					BoughtHE[client]++;
				}
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is allowed to buy %s.", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "flashbang", false))
	{
		if (!FlashbangsOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already have the maximum allowed equiped.", client, weapon);
				DebugMessage(dmsg);
				Format(dmsg, sizeof(dmsg), "%L has [%i] of %s.", client, GetClientFlashbangs(client), weapon);
				DebugMessage(dmsg);
			}
			
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
					
					if (UseDebug > 0)
					{
						Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already bought the maximum allowed for this round.", client, weapon);
						DebugMessage(dmsg);
						Format(dmsg, sizeof(dmsg), "%L has already purchased [%i] of %s.", client, BoughtFB[client], weapon);
						DebugMessage(dmsg);
					}
					
					return Plugin_Handled;
				}
				else
				{
					BoughtFB[client]++;
				}
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is allowed to buy %s.", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "smokegrenade", false))
	{
		if (!SmokeGrenadesOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already have the maximum allowed equiped.", client, weapon);
				DebugMessage(dmsg);
				Format(dmsg, sizeof(dmsg), "%L has [%i] of %s.", client, GetClientSmokeGrenades(client), weapon);
				DebugMessage(dmsg);
			}
			
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
					
					if (UseDebug > 0)
					{
						Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already bought the maximum allowed for this round.", client, weapon);
						DebugMessage(dmsg);
						Format(dmsg, sizeof(dmsg), "%L has already purchased [%i] of %s.", client, BoughtSG[client], weapon);
						DebugMessage(dmsg);
					}
					
					return Plugin_Handled;
				}
				else
				{
					BoughtSG[client]++;
				}
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is allowed to buy %s.", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "incgrenade", false) || StrEqual(weapon, "molotov", false))
	{
		if (!IncenderyGrenadesOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already have the maximum allowed equiped.", client, weapon);
				DebugMessage(dmsg);
				Format(dmsg, sizeof(dmsg), "%L has [%i] of %s.", client, GetClientIncendaryGrenades(client), weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		else
		{
			if (EnforceBuyLimit)
			{
				if ((PlayerIsVIP[client] && BoughtINC[client] >= incenderyMaxVip) || (!PlayerIsVIP[client] && BoughtINC[client] >= incenderyMax))
				{
					PrintCenterText(client, "%t", "Cannot Carry");
					CPrintToChat(client, "%t", "Purchased Max INC", PLUGIN_PREFIX);
					
					if (UseDebug > 0)
					{
						Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already bought the maximum allowed for this round.", client, weapon);
						DebugMessage(dmsg);
						Format(dmsg, sizeof(dmsg), "%L has already purchased [%i] of %s.", client, BoughtINC[client], weapon);
						DebugMessage(dmsg);
					}
					
					return Plugin_Handled;
				}
				else
				{
					BoughtINC[client]++;
				}
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is allowed to buy %s.", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	else if (StrEqual(weapon, "decoy", false))
	{
		if (!DecoyGrenadesOk(client))
		{
			PrintCenterText(client, "%t", "Cannot Carry");
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already have the maximum allowed equiped.", client, weapon);
				DebugMessage(dmsg);
				Format(dmsg, sizeof(dmsg), "%L has [%i] of %s.", client, GetClientDecoyGrenades(client), weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		else
		{
			if (EnforceBuyLimit)
			{
				if ((PlayerIsVIP[client] && BoughtDECOY[client] >= decoyMaxVip) || (!PlayerIsVIP[client] && BoughtDECOY[client] >= decoyMax))
				{
					PrintCenterText(client, "%t", "Cannot Carry");
					CPrintToChat(client, "%t", "Purchased Max DECOY", PLUGIN_PREFIX);
					
					if (UseDebug > 0)
					{
						Format(dmsg, sizeof(dmsg), "%L cannot buy %s, they already bought the maximum allowed for this round.", client, weapon);
						DebugMessage(dmsg);
						Format(dmsg, sizeof(dmsg), "%L has already purchased [%i] of %s.", client, BoughtDECOY[client], weapon);
						DebugMessage(dmsg);
					}
					
					return Plugin_Handled;
				}
				else
				{
					BoughtDECOY[client]++;
				}
			}
			
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "%L is allowed to buy %s.", client, weapon);
				DebugMessage(dmsg);
			}
			
			return Plugin_Continue;
		}
	}
	
	// Player is not buying any type of nade, do not restrict
	return Plugin_Continue;
}

/**
* Return if weapon string is a grenade type
* 
* @param weapon	Weapon String
* @return	bool:true if weapon string is a grenade type
*/
bool:IsGrenadeType(const String:weapon[])
{
	if (StrContains(weapon, "grenade", false) != -1 || StrEqual(weapon, "flashbang", false) || StrEqual(weapon, "decoy", false))
	{
		return true;
	}
	
	return false;
}

/**
* SDKHooks Function SDKHook_WeaponCanUse
*
* @param client		Client index
* @param weapon	weapon entity index
* @return		Plugin_Continue to allow, else Handled to disallow
*/
public Action:WeaponCanUse(client, weapon)
{
	// Get and store the classname of the entity index the client is touching
	new String:classname[MAX_WEAPON_NAME];
	
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	// Check the weapon the player is picking up
	if (StrEqual(classname, "weapon_hegrenade", false))
	{
		if (!HEGrenadesOk(client))
		{
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for hegrenade, NOT allowed to use", client);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for hegrenade, allowed to use", client);
			DebugMessage(dmsg);
		}
	}
	else if (StrEqual(classname, "weapon_flashbang", false))
	{
		if (!FlashbangsOk(client))
		{
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for flashbang, NOT allowed to use", client);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for flashbang, allowed to use", client);
			DebugMessage(dmsg);
		}
	}
	else if (StrEqual(classname, "weapon_smokegrenade", false))
	{
		if (!SmokeGrenadesOk(client))
		{
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for smokegrenade, NOT allowed to use", client);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for smokegrenade, allowed to use", client);
			DebugMessage(dmsg);
		}
	}
	else if (StrEqual(classname, "weapon_incgrenade", false) || StrEqual(classname, "weapon_molotov", false))
	{
		if (!IncenderyGrenadesOk(client))
		{
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for incgrenade/molotov, NOT allowed to use", client);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for incgrenade/molotov, allowed to use", client);
			DebugMessage(dmsg);
		}
	}
	else if (StrEqual(classname, "weapon_decoy", false))
	{
		if (!DecoyGrenadesOk(client))
		{
			if (UseDebug > 0)
			{
				Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for decoy, NOT allowed to use", client);
				DebugMessage(dmsg);
			}
			
			return Plugin_Handled;
		}
		
		if (UseDebug > 0)
		{
			Format(dmsg, sizeof(dmsg), "WeaponCanUse on %N for decoy, allowed to use", client);
			DebugMessage(dmsg);
		}
	}
	
	// Player either allowed to pick up the nade or is picking up another weapon.
	return Plugin_Continue;
}

/**
* Return if player has maximum type and can't buy/use another one
* 
* @param client		ClientID
* @param nadeType	Weapon String
* @return	bool:true if player already is carrying max allowed types of nades
*/
bool:PlayerHasMaxType(client, const String:nadeType[])
{
	TotalType[client] = 0;
	
	if (GetClientHEGrenades(client) > 0)
	{
		if (StrEqual(nadeType, "hegrenade", false))
		{ // Already has hegrenade type, so allow them to purchase more
			return false;
		}
		
		TotalType[client]++;
	}
	
	if (GetClientFlashbangs(client) > 0)
	{
		if (StrEqual(nadeType, "flashbang", false))
		{ // Already has flashbang type, so allow them to purchase more
			return false;
		}
		
		TotalType[client]++;
	}
	
	if (GetClientSmokeGrenades(client) > 0)
	{
		if (StrEqual(nadeType, "smokegrenade", false))
		{ // Already has smokegrenade type, so allow them to purchase more
			return false;
		}
		
		TotalType[client]++;
	}
	
	if (GetClientDecoyGrenades(client) > 0)
	{
		if (StrEqual(nadeType, "decoy", false))
		{ // Already has decoy type, so allow them to purchase more
			return false;
		}
	
		TotalType[client]++;
	}
	
	if (GetClientIncendaryGrenades(client) > 0)
	{
		if (StrEqual(nadeType, "incgrenade", false) || StrEqual(nadeType, "molotov", false))
		{ // Already has incgrenade type, so allow them to purchase more
			return false;
		}
		
		TotalType[client]++;
	}
	
	if ((!PlayerIsVIP[client] && TotalType[client] >= RestrictType) || (PlayerIsVIP[client] && TotalType[client] >= RestrictTypeVIP))
	{
		return true;
	}
	
	return false;
}

/**
 * Checks if client already has reached the max allowed total nades
 * 
 * @param	client	Player's ClientID
 * @return bool:true if player already has reached max allowed total nades
 */
bool:PlayerHasTotalNades(client)
{
	new nadeTotal = GetClientHEGrenades(client) + GetClientFlashbangs(client) + GetClientSmokeGrenades(client) + GetClientDecoyGrenades(client) + GetClientIncendaryGrenades(client);
	
	if ((!PlayerIsVIP[client] && nadeTotal >= TotalNades) || (PlayerIsVIP[client] && nadeTotal >= TotalNadesVIP))
	{
		return true;
	}
	
	return false;
}

/**
 * Checks if client can buy/pickup/use HE grenades
 * 
 * @param	client	Player's ClientID
 * @return bool:true will allow, false will deny
 */
bool:HEGrenadesOk(client)
{
	if (UseTotalNades && PlayerHasTotalNades(client))
	{
		return false;
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, "hegrenade"))
	{
		return false;
	}
	
	if ((!PlayerIsVIP[client] && GetClientHEGrenades(client) >= heMax) || (PlayerIsVIP[client] && GetClientHEGrenades(client) >= heMaxVip))
	{
		return false;
	}
	
	return true;
}

/**
 * Checks if client can buy/pickup/use flashbang grenades
 * 
 * @param	client	Player's ClientID
 * @return bool:true will allow, false will deny
 */
bool:FlashbangsOk(client)
{
	if (UseTotalNades && PlayerHasTotalNades(client))
	{
		return false;
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, "flashbang"))
	{
		return false;
	}
	
	if ((!PlayerIsVIP[client] && GetClientFlashbangs(client) >= flashMax) || (PlayerIsVIP[client] && GetClientFlashbangs(client) >= flashMaxVip))
	{
		return false;
	}
	
	return true;
}

/**
 * Checks if client can buy/pickup/use smoke grenades
 * 
 * @param	client	Player's ClientID
 * @return bool:true will allow, false will deny
 */
bool:SmokeGrenadesOk(client)
{
	if (UseTotalNades && PlayerHasTotalNades(client))
	{
		return false;
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, "smokegrenade"))
	{
		return false;
	}
	
	if ((!PlayerIsVIP[client] && GetClientSmokeGrenades(client) >= smokeMax) || (PlayerIsVIP[client] && GetClientSmokeGrenades(client) >= smokeMaxVip))
	{
		return false;
	}
	
	return true;
}

/**
 * Checks if client can buy/pickup/use decoy grenades
 * 
 * @param	client	Player's ClientID
 * @return bool:true will allow, false will deny
 */
bool:DecoyGrenadesOk(client)
{
	if (UseTotalNades && PlayerHasTotalNades(client))
	{
		return false;
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, "decoy"))
	{
		return false;
	}
	
	if ((!PlayerIsVIP[client] && GetClientDecoyGrenades(client) >= decoyMax) || (PlayerIsVIP[client] && GetClientDecoyGrenades(client) >= decoyMaxVip))
	{
		return false;
	}
	
	return true;
}

/**
 * Checks if client can buy/pickup/use incendary grenades
 * 
 * @param	client	Player's ClientID
 * @return bool:true will allow, false will deny
 */
bool:IncenderyGrenadesOk(client)
{
	if (UseTotalNades && PlayerHasTotalNades(client))
	{
		return false;
	}
	
	if (UseRestrictType && PlayerHasMaxType(client, "incgrenade"))
	{
		return false;
	}
	
	if ((!PlayerIsVIP[client] && GetClientIncendaryGrenades(client) >= incenderyMax) || (PlayerIsVIP[client] && GetClientIncendaryGrenades(client) >= incenderyMaxVip))
	{
		return false;
	}
	
	return true;
}

/**
 * Retrieves player's total amount of HE grenades
 * 
 * @param	client	Player's ClientID
 * @return Total count of HE grenades in client's inventory
 */
GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

/**
 * Retrieves player's total amount of smoke grenades
 * 
 * @param	client	Player's ClientID
 * @return Total count of smoke grenades in client's inventory
 */
GetClientSmokeGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, SmokegrenadeOffset);
}

/**
 * Retrieves player's total amount of flashbang grenades
 * 
 * @param	client	Player's ClientID
 * @return Total count of flashbang grenades in client's inventory
 */
GetClientFlashbangs(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, FlashbangOffset);
}

/**
 * Retrieves player's total amount of decoy grenades
 * 
 * @param	client	Player's ClientID
 * @return Total count of decoy grenades in client's inventory
 */
GetClientDecoyGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, DecoyGrenadeOffset);
}

/**
 * Retrieves player's total amount of Incendary/molotov grenades
 * 
 * @param	client	Player's ClientID
 * @return Total count of incendary/molotov grenades in client's inventory
 */
GetClientIncendaryGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, IncenderyGrenadesOffset);
}

DebugMessage(const String:msg[], any:...)
{
	if (UseDebug & 1)
	{
		LogMessage("[DEBUG] %s", msg);
	}
	
	if (UseDebug & 2)
	{
		PrintToChatAll("[GrenadePack2 DEBUG] %s", msg);
	}
}

// ===========================================================
// Changed CVar Hook Callbacks
// ===========================================================
public Enabled_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(newValue, "0"))
	{
		UnhookEvent("player_spawn", Event_OnPlayerSpawn);
		CPrintToChatAll("%t", "Plugin Disabled", PLUGIN_PREFIX);
		
		ResetMaxGrenadeAllowance();
	}
	else
	{
		HookEvent("player_spawn", Event_OnPlayerSpawn);
		CPrintToChatAll("%t", "Plugin Enabled", PLUGIN_PREFIX);
		
		AdjustMaxGrenadeAllowance();
	}
		
	Plugin_Enabled = GetConVarBool(cvar);
	
	HookPlayers(Plugin_Enabled);
}

public Announce_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	announce = GetConVarInt(cvar);
}

public HE_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed he", PLUGIN_PREFIX, StringToInt(newValue));
	
	heMax = GetConVarInt(cvar);
	
	if (heMax > heMaxVip && heMaxVip != 0)
	{
		heMaxVip = heMax;
	}
}

public HE_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed he vip", PLUGIN_PREFIX, StringToInt(newValue));
	
	heMaxVip = GetConVarInt(cvar);
	
	if (heMax > heMaxVip && heMaxVip != 0)
	{
		heMax = heMaxVip;
	}
	
	AdjustMaxGrenadeAllowance();
}

public INC_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed inc", PLUGIN_PREFIX, StringToInt(newValue));
	
	incenderyMax = GetConVarInt(cvar);
	
	if (incenderyMax > incenderyMaxVip)
	{
		incenderyMaxVip = incenderyMax;
	}
}

public INC_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed inc vip", PLUGIN_PREFIX, StringToInt(newValue));
	
	incenderyMaxVip = GetConVarInt(cvar);
	
	if (incenderyMax > incenderyMaxVip)
	{
		incenderyMax = incenderyMaxVip;
	}
	
	AdjustMaxGrenadeAllowance();
}

public DECOY_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed decoy", PLUGIN_PREFIX, StringToInt(newValue));
	
	decoyMax = GetConVarInt(cvar);
	
	if (decoyMax > decoyMaxVip)
	{
		decoyMaxVip = decoyMax;
	}
}

public DECOY_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed decoy vip", PLUGIN_PREFIX, StringToInt(newValue));
	
	decoyMaxVip = GetConVarInt(cvar);
	
	if (decoyMax > decoyMaxVip)
	{
		decoyMax = decoyMaxVip;
	}
	
	AdjustMaxGrenadeAllowance();
}

public SMOKE_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed smoke", PLUGIN_PREFIX, StringToInt(newValue));
	
	smokeMax = GetConVarInt(cvar);
	
	if (smokeMax > smokeMaxVip && smokeMaxVip != 0)
	{
		smokeMaxVip = smokeMax;
	}
}

public SMOKE_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed smoke vip", PLUGIN_PREFIX, StringToInt(newValue));
	
	smokeMaxVip = GetConVarInt(cvar);
	
	if (smokeMax > smokeMaxVip && smokeMaxVip != 0)
	{
		smokeMax = smokeMaxVip;
	}
	
	AdjustMaxGrenadeAllowance();
}

public FLASH_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed flash", PLUGIN_PREFIX, StringToInt(newValue));
	
	flashMax = GetConVarInt(cvar);
	
	if (flashMax > flashMaxVip && flashMaxVip != 0)
	{
		flashMaxVip = flashMax;
	}
}

public FLASH_VIP_Changed(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (AdvertiseLimitChanges)
		CPrintToChatAll("%t", "Limit changed flash vip", PLUGIN_PREFIX, StringToInt(newValue));
	
	flashMaxVip = GetConVarInt(cvar);
	
	if (flashMax > flashMaxVip && flashMaxVip != 0)
	{
		flashMax = flashMaxVip;
	}
	
	SetConVarInt(LimitFlashbang, flashMaxVip);
}

public EnforceChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	EnforceBuyLimit = GetConVarBool(cvar);
}

public UseUpdaterChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UseUpdater = GetConVarBool(cvar);
}

public UseTotalChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UseTotalNades = GetConVarBool(cvar);
}

public TotalChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	TotalNades = GetConVarInt(cvar);
	
	if (TotalNadesVIP < TotalNades)
	{
		SetConVarInt(MaxNadesVIP, TotalNades);
	}
}

public TotalVIPChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	TotalNadesVIP = GetConVarInt(cvar);
	
	if (TotalNades > TotalNadesVIP)
	{
		SetConVarInt(MaxNades, TotalNadesVIP);
	}
}

public UseRestrictTypeChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UseRestrictType = GetConVarBool(cvar);
}

public RestrictTypeChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	RestrictType = GetConVarInt(cvar);
	
	if (RestrictTypeVIP < RestrictType)
	{
		SetConVarInt(MaxNadeTypeVIP, RestrictType);
	}
}

public RestrictTypeVIPChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	RestrictTypeVIP = GetConVarInt(cvar);
	
	if (RestrictType > RestrictTypeVIP)
	{
		SetConVarInt(MaxNadeType, RestrictTypeVIP);
	}
}

public AdvertiseLimitChangesChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	AdvertiseLimitChanges = GetConVarBool(cvar);
}

public OnDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseDebug = GetConVarInt(cvar);
}