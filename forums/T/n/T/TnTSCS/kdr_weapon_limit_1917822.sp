/* REQUEST
* 	URL = http://forums.alliedmods.net/showthread.php?t=174230
* 	By Skalp (http://forums.alliedmods.net/member.php?u=164686)
*
* This plugin will restrict the AK47 and M4A1 for players when they reach/exceed a set KDR
* 
* CREDITS - ClearTimer from Antithasys - http://forums.alliedmods.net/showthread.php?t=167160
* 
* Version 0.0.1.0 - Initial posting
* 
* Version 0.0.1.1:
* As an enhancement request, this plugin has been expaneded to further restrict weapons when players reach 9 kills with a KDR of 3+ and 
* even further when they reach 20 kills with a KDR of 3+.
* 
* Version 0.0.1.2
* Adjusted login according to https://forums.alliedmods.net/showpost.php?p=1660819&postcount=25
* 
* Version 0.0.1.3
* 	*	Fixed the bug where Ts cannot use C4
* 
* Version 0.0.1.4
* 	*	Changed plugin around to be more customizable.
* 
*/
#pragma semicolon 1
// ==================== Includes ======================================================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
// ==================== Defines =======================================================================================================
#define 	PLUGIN_VERSION		"0.0.1.4"
#define 	MAX_WEAPON_NAME 	80
#define		MAX_FILE_LEN		256
#define 	SOUND_FILE 			"buttons/weapon_cant_buy.wav" // cstrike\sound\buttons
// ==================== Global Variables and Handles ===================================================================================
new Handle:h_Trie;

new DropMode;

new bool:Restricted[MAXPLAYERS+1] = {false, ...};
new bool:MaintainRestrictions;

new Float:RatioLimit1;
new Float:RatioLimit2;

new DefuseBombPoints[MAXPLAYERS+1] = 0;
new BombExplodePoints[MAXPLAYERS+1] = 0;

new bool:PlayerRestrictOne[MAXPLAYERS+1] = {false, ...};
new bool:PlayerRestrictTwo[MAXPLAYERS+1] = {false, ...};

new String:RestrictedWeapons1[MAX_FILE_LEN];
new String:RestrictedWeapons2[MAX_FILE_LEN];
new bool:RestrictPlayer1[MAXPLAYERS+1] = {false, ...};
new bool:RestrictPlayer2[MAXPLAYERS+1] = {false, ...};
new bool:NeedsToDropWeapons[MAXPLAYERS+1] = {false, ...};

// Enum for maintaining KDR restriction
enum RestrictedAttributes
{
RESTRICTION,
DEFUSE,
EXPLODE,
FRAGS,
DEATHS
};
// ==================== Plugin Info ====================================================================================================
public Plugin:myinfo = 
{
	name = "KDR Weapon Limit",
	author = "TnTSCS aka ClarkKent",
	description = "This plugin will limit a player from a list of weapons once they reach certain KDR",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

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
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_version", PLUGIN_VERSION, 
	"Version of 'KDR Weapon Limit'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio1", "3.0", 
	"KDR Ratio a player must meet before stage 1 weapon limit is enforced against them.")), OnKDR1Changed);
	RatioLimit1 = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_rw1", "awp, sg550, g3sg1", 
	"List the weapons a player cannot use once they've reached the ratio1 limit")), RestrictedWeaponsOneChanged);
	RestrictedWeapons1[0] = '\0';
	GetConVarString(hRandom, RestrictedWeapons1, sizeof(RestrictedWeapons1));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio2", "5.0", 
	"KDR Ratio a player must meet before stage 2 weapon limit is enforced against them.")), OnKDR2Changed);
	RatioLimit2 = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_rw1", "awp, sg550, g3sg1, m4a1, ak47, deagle", 
	"List the weapons a player cannot use once they've reached the ratio2 limit")), RestrictedWeaponsTwoChanged);
	RestrictedWeapons2[0] = '\0';
	GetConVarString(hRandom, RestrictedWeapons2, sizeof(RestrictedWeapons2));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_maintain", "1", 
	"Maintain restrictions until map changes?\nIf set to no (0) then players can just reconnect to be able to purchase restricted weapons again.", _, true, 0.0, true, 1.0)), MaintainRestrictionsChanged);
	MaintainRestrictions = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_drop", "1",
	"When should player be forced to drop restricted weapon?\n1 = Immediately\n2 = Beginning of next round")), OnDropModeChanged);
	DropMode = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	// Hook game events needed for this plugin
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("bomb_defused", 	Event_BombDefused);
	HookEvent("bomb_exploded", 	Event_BombExploded);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("round_start",	Event_RoundStart);
	
	// Create the trie to hold data for maintaining restrictions
	h_Trie = CreateTrie();
	
	// Load the translation file
	LoadTranslations("kdr_weapon_limit.phrases");
	
	// Execute the config file
	AutoExecConfig(true);
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
	SoundPrecache();
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
}

/**
 * Called when the map is loaded.
 *
 * @note This used to be OnServerLoad(), which is now deprecated.
 * Plugins still using the old forward will work.
 */
public OnMapStart()
{
	SoundPrecache();
	
	ResetEverything();
}

/**
 * Called right before a map ends.
 */
public OnMapEnd()
{
	ResetEverything();
}

SoundPrecache()
{
	decl String:buffer[MAX_FILE_LEN];
	buffer[0] = '\0';
	
	Format(buffer, sizeof(buffer), "sound/%s", SOUND_FILE);
	
	if (!PrecacheSound(SOUND_FILE, true))
	{
		LogError("Unable to precache sound file %s", SOUND_FILE);
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
	if (!IsClientInGame(client) || IsFakeClient(client) || CheckCommandAccess(client, "no_kdr_restrict", ADMFLAG_CUSTOM6))
	{
		return;
	}
	
	if (MaintainRestrictions)
	{
		// Get and store the client's SteamID
		decl String:authString[20];
		authString[0] = '\0';
		
		GetClientAuthString(client, authString, sizeof(authString));
		
		new GetRestrictedInfo[RestrictedAttributes];
		
		if (GetTrieArray(h_Trie, authString, GetRestrictedInfo[0], 5)) // We found the steam ID in the Trie
		{
			new pRestriction = GetRestrictedInfo[RESTRICTION];
			
			if (pRestriction == 1) // Maintain restrictions is enforced
			{
				Restricted[client] = true;
				
				BombExplodePoints[client] = GetRestrictedInfo[EXPLODE];
				DefuseBombPoints[client] = GetRestrictedInfo[DEFUSE];
				
				SetEntProp(client, Prop_Data, "m_iFrags", GetRestrictedInfo[FRAGS]);
				SetEntProp(client, Prop_Data, "m_iDeaths", GetRestrictedInfo[DEATHS]);
				
				RestrictWeapons(client, 1);
			}
		}
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
	if (IsClientInGame(client))
	{
		// Unhook player since they're leaving the server
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		// Maintain restrictions is on, let's store this players data in the Trie
		if (MaintainRestrictions)
		{
			// Get and store the client's SteamID
			decl String:authString[20];
			authString[0] = '\0';
			
			GetClientAuthString(client, authString, 20);
			
			new RestrictedInfo[RestrictedAttributes];
			
			RestrictedInfo[RESTRICTION] = Restricted[client];
			RestrictedInfo[DEFUSE] = DefuseBombPoints[client];
			RestrictedInfo[EXPLODE] = BombExplodePoints[client];
			
			RestrictedInfo[FRAGS] = GetClientFrags(client);
			RestrictedInfo[DEATHS] = GetClientDeaths(client);
			
			SetTrieArray(h_Trie, authString, RestrictedInfo[0], 5, true);
		}
		
		// Reset cliend_id variables and timer
		Restricted[client] = false;
		BombExplodePoints[client] = 0;
		DefuseBombPoints[client] = 0;
		NeedsToDropWeapons[client] = false;
	}
}

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	// If client has reached or exceeded allowed KDR
	if (IsClientInGame(client) && Restricted[client] && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		// Allow non-weapon items to be bought all of the time
		if (StrEqual(weapon, "vest", false) || StrEqual(weapon, "vesthelm", false) || StrEqual(weapon, "defuser", false) || 
			StrEqual(weapon, "secammo", false) || StrEqual(weapon, "primammo", false) || StrEqual(weapon, "nvgs", false) || StrEqual(weapon, "c4", false))
		{
			return Plugin_Continue; // Allow purchase
		}
		
		// Check for restricted weapons
		if ((PlayerRestrictTwo[client] && StrContains(RestrictedWeapons2, weapon, false) == -1) ||
			(PlayerRestrictOne[client] && StrContains(RestrictedWeapons1, weapon, false) == -1))
		{
			PrintToChat(client, "\x04[\x03SM\x04] %t", "Weapon", weapon);
			
			EmitSoundToClient(client, SOUND_FILE);
			
			return Plugin_Handled; // Don't allow purchase, play sound, and advise via chat
		}
	}
	
	return Plugin_Continue;
}

/**
 *	"bomb_defused"
 *	{
 *		"userid"	"short"		// player who defused the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DefuseBombPoints[client] += 3;
}

/**
 *	"bomb_exploded"
 *	{
 *		"userid"	"short"		// player who planted the bomb
 *		"site"		"short"		// bombsite index
 *	}
 */
public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	BombExplodePoints[client] += 3;
}

/**
 * 	"player_death"
 *	{
 *		// this extents the original player_death by a new fields
 *		"userid"	"short"   	// user ID who died				
 *		"attacker"	"short"	// user ID who killed
 *		"weapon"	"string" 	// weapon name killer used 
 *		"headshot"	"bool"		// singals a headshot
 *		"dominated"	"short"	// did killer dominate victim with this kill
 *		"revenge"	"short"	// did killer get revenge on victim with this kill
 * 	}
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.1, Timer_ProcessKDR, GetClientSerial(victim));
	
	if (killer > 0 && killer <= MaxClients)
	{
		CreateTimer(0.1, Timer_ProcessKDR, GetClientSerial(killer));
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (NeedsToDropWeapons[client])
	{
		CheckKDR(client);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			NeedsToDropWeapons[i] = false;
		}
	}
}

public Action:Timer_ProcessKDR(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}
	
	CheckKDR(client);
}

CheckKDR(client)
{
	new Float:KDR = 0.0;	
	new frags = GetClientFrags(client);
	new deaths = GetClientDeaths(client);	
	new bonus_points = (DefuseBombPoints[client] + BombExplodePoints[client]);	
	frags -= bonus_points;
	
	if (frags <= 0 && deaths <= 0)
	{
		return; // KDR is nothing
	}	
	else if (frags > 0 && deaths <= 0)
	{
		KDR = float(frags) - float(deaths);
	}
	else if (frags > 0 && deaths > 0)
	{
		KDR = float(frags) / float(deaths);
	}
	
	// KDR is above or equal to limit2
	if (KDR >= RatioLimit2)
	{
		// Since the player isn't restricted already, restrict the weapons
		if (!Restricted[client] || !RestrictPlayer2[client])
		{
			SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			Restricted[client] = true;
			RestrictPlayer2[client] = true;
			PrintToChat(client, "\x04[\x03SM\x04] %t", "On", KDR, RatioLimit2);
			
			if (DropMode == 1 || (DropMode == 2 && NeedsToDropWeapons[client]))
			{
				RestrictWeapons(client, 0);
			}
			else
			{
				NeedsToDropWeapons[client] = true;
			}
		}
	}
	else if (KDR >= RatioLimit1)
	{
		if (!Restricted[client] || !RestrictPlayer1[client])
		{
			SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			Restricted[client] = true;
			RestrictPlayer1[client] = true;
			PrintToChat(client, "\x04[\x03SM\x04] %t", "On", KDR, RatioLimit1);
			
			if (DropMode == 1 || (DropMode == 2 && NeedsToDropWeapons[client]))
			{
				RestrictWeapons(client, 0);
			}
			else
			{
				NeedsToDropWeapons[client] = true;
			}
		}
	}
	else
	{
		// Since the KDR is below the limit and the player is marked as restricted, unrestrict the player
		if (Restricted[client])
		{
			Restricted[client] = false;
			RestrictPlayer1[client] = false;
			RestrictPlayer2[client] = false;
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			PrintToChat(client, "\x04[\x03SM\x04] %t", "Off");
		}
	}
}

RestrictWeapons(client, msg)
{
	if (!IsClientInGame(client) && GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return;
	}
	
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (weapon != -1)
	{
		DropRestrictedWeapons(client, weapon);
	}
	
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (weapon != -1)
	{
		DropRestrictedWeapons(client, weapon);
	}
	
	switch (msg)
	{
		case 1: { PrintToChat(client, "\x04[\x03SM\x04] %t", "On2", RatioLimit1); }			
		case 2: { PrintToChat(client, "\x04[\x03SM\x04] %t", "On2", RatioLimit2); }			
		case 3: { PrintToChat(client, "\x04[\x03SM\x04] %t", "Pistols"); }			
		case 4: { PrintToChat(client, "\x04[\x03SM\x04] %t", "USP and Glock"); }
	}
}

DropRestrictedWeapons(client, weapon)
{
	decl String:WeaponName[MAX_WEAPON_NAME];
	WeaponName[0] = '\0';
	
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));	
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	if ((PlayerRestrictTwo[client] && StrContains(RestrictedWeapons2, WeaponName, false) == -1) ||
		(PlayerRestrictOne[client] && StrContains(RestrictedWeapons1, WeaponName, false) == -1))
	{
		CS_DropWeapon(client, weapon, true);
		
		EmitSoundToClient(client, SOUND_FILE);
	}
}

ResetEverything()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Restricted[i] = false;
			RestrictPlayer1[i] = false;
			RestrictPlayer2[i] = false;
			SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			BombExplodePoints[i] = 0;
			DefuseBombPoints[i] = 0;
		}
	}
}

/**
* SDKHooks Function SDKHook_WeaponCanUse
*
* @param client		Client index
* @param weapon	weapon entity index
* @return		Plugin_Continue to allow, else Handled to disallow
*/
public Action:OnWeaponCanUse(client, weapon)
{
	if (!Restricted[client])
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[MAX_WEAPON_NAME];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));	
	ReplaceString(sWeapon, sizeof(sWeapon), "weapon_", "", false);
	
	if (StrEqual(sWeapon, "vest", false) || StrEqual(sWeapon, "vesthelm", false) || StrEqual(sWeapon, "defuser", false) ||
		StrEqual(sWeapon, "secammo", false) || StrEqual(sWeapon, "primammo", false) || StrEqual(sWeapon, "nvgs", false) || 
		StrEqual(sWeapon, "c4"))
	{
		return Plugin_Continue;
	}
	
	if ((PlayerRestrictTwo[client] && StrContains(RestrictedWeapons2, sWeapon, false) == -1) ||
		(PlayerRestrictOne[client] && StrContains(RestrictedWeapons1, sWeapon, false) == -1))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnKDR1Changed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RatioLimit1 = GetConVarFloat(cvar);
}

public OnKDR2Changed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RatioLimit2 = GetConVarFloat(cvar);
}

public MaintainRestrictionsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaintainRestrictions = GetConVarBool(cvar);
}

public RestrictedWeaponsOneChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RestrictedWeapons1[0] = '\0';
	GetConVarString(cvar, RestrictedWeapons1, sizeof(RestrictedWeapons1));
}

public RestrictedWeaponsTwoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RestrictedWeapons2[0] = '\0';
	GetConVarString(cvar, RestrictedWeapons2, sizeof(RestrictedWeapons2));
}

public OnDropModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropMode = GetConVarInt(cvar);
}