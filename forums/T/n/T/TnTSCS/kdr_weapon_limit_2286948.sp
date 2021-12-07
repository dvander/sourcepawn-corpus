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
* Version 0.0.1.5
* 	*	Further customization of plugin variables including custom sound file allowed.
* 	+	Added some DEBUG messaging capability
* 
* Version 0.0.1.6
* 	+	Added enabled CVar
* 	+	Added optional minimum kill limit a player must reach before checking KDR
* 	+	Added the option to ignore bot kills to count towards KDR
* 	+	Added replacement weapons, one for if a player reaches stage 1 and another for when player reaches stage 2
* 		*	Player MUST have restricted weapon to receive replacement
* 
* Version 0.0.1.7
* 	*	Changes according to post: https://forums.alliedmods.net/showpost.php?p=1928548&postcount=27
* 	*	Fixed MaintainRestrictions
* 
* Version 0.0.1.8
* 	*	Implemented some SMLIB functions to help with weapon giving and switching.
* 	*	Changed some translation phrases
* 	+	Added a CVar for controlling whether or not to auto switch new weapon given to client when they get restricted or not.
* 
* Version 0.0.1.9
* 	*	Fixed issues listed in post: https://forums.alliedmods.net/showpost.php?p=1929275&postcount=30
* 
* Version 1.0.0.0
* 	*	Initial public release
* 	+	Added Updater support
* 
* Version 1.0.0.1
* 	*	Fixed drop on spawn issues
* 
* Version 1.0.0.2
* 	*	Fixed version number in plugin
* 	+	Added HU translation file
* 
* Version 1.0.0.3
* 	*	Recompiled with latest Sourcemod due to reported crashes.
* 	+	Added a 3rd ratio with specific weapons for the 3rd weapon replacement (removed deagle from rw2 and moved it to the list for rw3)
* 
* Version 1.0.0.4
* 	*	Fixed Client index 0 is invalid error in t_HookPlayer as reported by pubhero
* 
* Version 1.0.0.5
* 	+	Added HP restrictions to ratio restricts - per request (https://forums.alliedmods.net/showpost.php?p=2273482&postcount=65)
* 
* Version 1.0.0.6
* 	*	Fixed HP restrict CVars 2 and 3
* 
* Version 1.0.0.7
* 	*	Added timer for HP modification
* 
*/

#pragma semicolon 1
// ==================== Includes ======================================================================================================
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>
// ==================== Defines =======================================================================================================
#define 	PLUGIN_VERSION		"1.0.0.7"
#define 	MAX_WEAPON_NAME 	80
#define		MAX_FILE_LEN		256
#define 	MAX_WEAPONS			48	// Max number of weapons available

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/KDR_Weapon_Limit.txt"

#define SECONDARY_WEAPONS "hkp2000 elite p250 fiveseven deagle glock tec9"
#define PRIMARY_WEAPONS "g3sg1 sg556 ak47 galilar mac10 sawedoff nova xm1014 mag7 m249 negev mp9 mp7 ump45 p90 bizon famas m4a1 m4a1_silencer ssg08 aug awp scar20"

#define _DEBUG 			1 		// Set to 1 for log debug spew
#define _DEBUG_ALL		0		// Set to 1 for in-game chat debug spew

#define RESTRICT1		1
#define RESTRICT2		2
#define RESTRICT3		3
// ==================== Global Variables and Handles ===================================================================================
new Handle:h_Trie;

new DropMode;
new DebugMode;
new MinRequiredKills;
new BotKills[MAXPLAYERS+1] = 0;
new DefuseBombPoints[MAXPLAYERS+1] = 0;
new BombExplodePoints[MAXPLAYERS+1] = 0;
new SavedFrags[MAXPLAYERS+1];
new SavedDeaths[MAXPLAYERS+1];
new ActiveWeapon[MAXPLAYERS+1];
new Ratio1HP;
new Ratio2HP;
new Ratio3HP;

new Float:RatioLimit1;
new Float:RatioLimit2;
new Float:RatioLimit3;
new Float:KDR[MAXPLAYERS+1];

new String:lastWeaponUsed[MAXPLAYERS+1][MAX_WEAPON_NAME];
new String:RestrictedWeapons1[MAX_FILE_LEN];
new String:RestrictedWeapons2[MAX_FILE_LEN];
new String:RestrictedWeapons3[MAX_FILE_LEN];
new String:Replacement1[MAX_WEAPON_NAME];
new String:Replacement1a[MAX_WEAPON_NAME];
new String:Replacement2[MAX_WEAPON_NAME];
new String:Replacement2a[MAX_WEAPON_NAME];
new String:Replacement3[MAX_WEAPON_NAME];
new String:Replacement3a[MAX_WEAPON_NAME];

new String:SOUND_FILE[MAX_FILE_LEN];

new String:dmsg[MAX_MESSAGE_LENGTH];

new bool:Enabled;
new bool:UseSound;
new bool:UseUpdater;
new bool:UseExempt;
new bool:IgnoreBotKills;
new bool:MaintainRestrictions;
new bool:Announce;
new bool:SwitchToNewWeapon;
new bool:Primary[MAXPLAYERS+1];
new bool:Secondary[MAXPLAYERS+1];
new bool:RestrictPlayer1[MAXPLAYERS+1] = {false, ...};
new bool:RestrictPlayer2[MAXPLAYERS+1] = {false, ...};
new bool:RestrictPlayer3[MAXPLAYERS+1] = {false, ...};
new bool:RestrictionExpempted[MAXPLAYERS+1] = {false, ...};
//new bool:DropOnSpawn[MAXPLAYERS+1] = {false, ...};
new bool:Restricted[MAXPLAYERS+1] = {false, ...};
new bool:ClientNeedsScoreUpdated[MAXPLAYERS+1] = {false, ...};
new bool:ClientNeedsRestricting[MAXPLAYERS+1] = {false, ...};
new bool:UseHPRestrict;

// Enum for maintaining KDR restriction
enum RestrictedAttributes
{
RESTRICTION,
DEFUSE,
EXPLODE,
FRAGS,
DEATHS,
BOT_KILLS
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
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_enabled", "1",
	"Is plugin enabled?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_usesound", "1",
	"Play sound to player when they reach KDR and are forced to drop their weapon?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0)), OnUseSoundChanged);
	UseSound = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_sound", "buttons/weapon_cant_buy.wav",
	"Path and file name of sound file to use for restriction sound relative to sound folder.")), OnSoundChanged);
	SOUND_FILE[0] = '\0';
	GetConVarString(hRandom, SOUND_FILE, sizeof(SOUND_FILE));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio1", "3.0", 
	"KDR Ratio a player must meet before stage 1 weapon limit is enforced against them.")), OnKDR1Changed);
	RatioLimit1 = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_rw1", "awp sg550 g3sg1", 
	"List the weapons a player cannot use once they've reached the ratio1 limit")), RestrictedWeaponsOneChanged);
	RestrictedWeapons1[0] = '\0';
	GetConVarString(hRandom, RestrictedWeapons1, sizeof(RestrictedWeapons1));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio2", "5.0", 
	"KDR Ratio a player must meet before stage 2 weapon limit is enforced against them.")), OnKDR2Changed);
	RatioLimit2 = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_rw2", "awp sg550 g3sg1 m4a1 ak47", 
	"List the weapons a player cannot use once they've reached the ratio2 limit")), RestrictedWeaponsTwoChanged);
	RestrictedWeapons2[0] = '\0';
	GetConVarString(hRandom, RestrictedWeapons2, sizeof(RestrictedWeapons2));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_ratio3", "7.0", 
	"KDR Ratio a player must meet before stage 3 weapon limit is enforced against them.")), OnKDR3Changed);
	RatioLimit3 = GetConVarFloat(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_rw3", "awp sg550 g3sg1 m4a1 ak47 deagle", 
	"List the weapons a player cannot use once they've reached the ratio3 limit")), RestrictedWeaponsThreeChanged);
	RestrictedWeapons3[0] = '\0';
	GetConVarString(hRandom, RestrictedWeapons3, sizeof(RestrictedWeapons3));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_maintain", "1", 
	"Maintain restrictions until map changes?\nIf set to no (0) then players can just reconnect to be able to purchase restricted weapons again.", _, true, 0.0, true, 1.0)), MaintainRestrictionsChanged);
	MaintainRestrictions = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_drop", "2",
	"When should player be forced to drop restricted weapon?\n1 = Immediately\n2 = Beginning of next round.")), OnDropModeChanged);
	DropMode = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_useexempt", "0",
	"Use the exemption system?.")), OnUseExemptChanged);
	UseExempt = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_botkills", "0",
	"Ignore bot kills towards players KDR?\n0 = No, count with KDR\n1 = Yes, do not count with KDR.")), OnIgnoreBotKillsChanged);
	IgnoreBotKills = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_minkills", "0",
	"Minimum number of kills required to start counting KDR.\n0 = disabled, count KDR right away\nN = Number of kills required before counting KDR")), OnMinimumKillsChanged);
	MinRequiredKills = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_pw1", "weapon_scout", 
	"List the primary weapon to give the player if the reach ratio1 and are forced to drop their weapon\nUse NONE for no replacement.\nFor CS:GO, the scout is ssg08")), PrimaryReplacementOneChanged);
	Replacement1[0] = '\0';
	GetConVarString(hRandom, Replacement1, sizeof(Replacement1));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_sw1", "weapon_p228", 
	"List the secondary weapon to give the player if the reach ratio1 and are forced to drop their pistol\nUse NONE for no replacement.\nFor CS:GO, the p228 is p250")), SecondaryReplacementOneChanged);
	Replacement1a[0] = '\0';
	GetConVarString(hRandom, Replacement1a, sizeof(Replacement1a));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_pw2", "weapon_scout", 
	"List the primary weapon to give the player if the reach ratio2 and are forced to drop their weapon\nUse NONE for no replacement.\nFor CS:GO, the scout is ssg08")), PrimaryReplacementTwoChanged);
	Replacement2[0] = '\0';
	GetConVarString(hRandom, Replacement2, sizeof(Replacement2));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_sw2", "weapon_p228", 
	"List the secondary weapon to give the player if the reach ratio2 and are forced to drop their pistol\nUse NONE for no replacement.\nFor CS:GO, the p228 is p250")), SecondaryReplacementTwoChanged);
	Replacement2a[0] = '\0';
	GetConVarString(hRandom, Replacement2a, sizeof(Replacement2a));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_pw3", "weapon_scout", 
	"List the primary weapon to give the player if the reach ratio3 and are forced to drop their weapon\nUse NONE for no replacement.\nFor CS:GO, the scout is ssg08")), PrimaryReplacementThreeChanged);
	Replacement3[0] = '\0';
	GetConVarString(hRandom, Replacement3, sizeof(Replacement3));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_sw3", "weapon_p228", 
	"List the secondary weapon to give the player if the reach ratio3 and are forced to drop their pistol\nUse NONE for no replacement.\nFor CS:GO, the p228 is p250")), SecondaryReplacementThreeChanged);
	Replacement3a[0] = '\0';
	GetConVarString(hRandom, Replacement3a, sizeof(Replacement3a));
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_announce", "0",
	"Announce to all players when a player gets restricted\n1 = Yes\n0 = No.")), OnAnnounceChanged);
	Announce = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_weaponswitch", "0",
	"Automatically have client switch to replacement weapon when given?\n1 = Yes\n0 = No.")), OnSwitchWeaponChanged);
	SwitchToNewWeapon = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update this plugin when updates are published?\n1 = Yes, 0 = No", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_debug", "0", 
	"Print DEBUG information?\n0 = No\n1 = Yes\n2 = Also to in-game chat", _, true, 0.0, true, 2.0)), OnDebugModeChanged);
	DebugMode = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_hprestrict", "0", 
	"Use HP Restrict feature?", _, true, 0.0, true, 1.0)), OnUseHPRestrictChanged);
	UseHPRestrict = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_restricthp1", "85", 
	"Value to set player's HP when they are at level 1 restriction", _, true, 0.0)), OnRatio1HPChanged);
	Ratio1HP = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_restricthp2", "70", 
	"Value to set player's HP when they are at level 2 restriction", _, true, 0.0)), OnRatio2HPChanged);
	Ratio2HP = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_kdrwl_restricthp3", "50", 
	"Value to set player's HP when they are at level 3 restriction", _, true, 0.0)), OnRatio3HPChanged);
	Ratio3HP = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	RegAdminCmd("sm_ratios", Cmd_ListRatios, ADMFLAG_GENERIC, "List all of the player's current ratios");
	
	// Hook game events needed for this plugin
	HookEvent("player_death", 	Event_PlayerDeath, EventHookMode_Post);
	HookEvent("bomb_defused", 	Event_BombDefused);
	HookEvent("bomb_exploded", 	Event_BombExploded);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	
	// Create the trie to hold data for maintaining restrictions
	h_Trie = CreateTrie();
	
	// Load the translation file
	LoadTranslations("kdr_weapon_limit.phrases");
	
	// Execute the config file
	AutoExecConfig(true);
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
	// If CVar to use Updater is true, add Chicken to Updater's list of plugins
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
	// If CVar to use Updater is true, check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
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
	new String:buffer[MAX_FILE_LEN];
	
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
	Format(dmsg, sizeof(dmsg), "OnClientPostAdminCheck fired for %N", client);
	DebugMessage(client, dmsg);
	
	if (!Enabled || IsFakeClient(client))
	{
		return;
	}
	
	if (UseExempt && CheckCommandAccess(client, "no_kdr_restrict", ADMFLAG_CUSTOM6))
	{
		RestrictionExpempted[client] = true;
	}
	else
	{
		RestrictionExpempted[client] = false;
	}
	
	if (MaintainRestrictions && !RestrictionExpempted[client])
	{
		Format(dmsg, sizeof(dmsg), "Checking Restrictions for %N after rejoining...", client);
		DebugMessage(client, dmsg);
		
		// Get and store the client's SteamID
		new String:authString[20];
		
		//GetClientAuthString(client, authString, sizeof(authString));
		GetClientAuthId(client, AuthId_Steam2, authString, sizeof(authString));
		
		new GetRestrictedInfo[RestrictedAttributes];
		
		if (GetTrieArray(h_Trie, authString, GetRestrictedInfo[0], 6)) // We found the steam ID in the Trie
		{
			new pRestriction = GetRestrictedInfo[RESTRICTION];
			BombExplodePoints[client] = GetRestrictedInfo[EXPLODE];
			DefuseBombPoints[client] = GetRestrictedInfo[DEFUSE];				
			SavedFrags[client] = GetRestrictedInfo[FRAGS];
			SavedDeaths[client] = GetRestrictedInfo[DEATHS];
			BotKills[client] = GetRestrictedInfo[BOT_KILLS];
			
			ClientNeedsScoreUpdated[client] = true;
			SetEntProp(client, Prop_Data, "m_iFrags", SavedFrags[client]);
			SetEntProp(client, Prop_Data, "m_iDeaths", SavedDeaths[client]);
			
			if (pRestriction == 1) // Client was restricted when they left.
			{
				Format(dmsg, sizeof(dmsg), "%N is restricted and should have - BombExplode:%i, BombDefuse:%i, Frags:%i, Deaths:%i, BotKills:%i", client, BombExplodePoints[client], DefuseBombPoints[client], SavedFrags[client], SavedDeaths[client], BotKills[client]);
				DebugMessage(client, dmsg);
				
				CheckKDR(client);
			}
		}
		else
		{
			Format(dmsg, sizeof(dmsg), "Did not find %s in Trie", authString);
			DebugMessage(client, dmsg);
		}
		
		RemoveFromTrie(h_Trie, authString);
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
	Format(dmsg, sizeof(dmsg), "OnClientDisconnect fired for %N", client);
	DebugMessage(client, dmsg);
	
	if (Enabled && IsClientInGame(client))
	{
		// Unhook player since they're leaving the server
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		
		// Maintain restrictions is on, let's store this players data in the Trie
		if (MaintainRestrictions)
		{
			// Get and store the client's SteamID
			new String:authString[20];
			
			//GetClientAuthString(client, authString, 20);
			GetClientAuthId(client, AuthId_Steam2, authString, sizeof(authString));
			
			new RestrictedInfo[RestrictedAttributes];
			
			RestrictedInfo[RESTRICTION] = Restricted[client];
			RestrictedInfo[DEFUSE] = DefuseBombPoints[client];
			RestrictedInfo[EXPLODE] = BombExplodePoints[client];
			
			RestrictedInfo[FRAGS] = GetClientFrags(client);
			RestrictedInfo[DEATHS] = GetClientDeaths(client);
			RestrictedInfo[BOT_KILLS] = BotKills[client];
			
			SetTrieArray(h_Trie, authString, RestrictedInfo[0], 6, true);
			
			Format(dmsg, sizeof(dmsg), "Set the following for %s - Defuse:%i, Explode:%i, Frags:%i, Deaths:%i, BotKills:%i", authString, DefuseBombPoints[client], BombExplodePoints[client], GetClientFrags(client), GetClientDeaths(client), BotKills[client]);
			DebugMessage(client, dmsg);
		}
		
		// Reset cliend_id variables and timer
		ActiveWeapon[client] = INVALID_ENT_REFERENCE;
		Restricted[client] = false;
		BombExplodePoints[client] = 0;
		DefuseBombPoints[client] = 0;
		//DropOnSpawn[client] = false;
		RestrictionExpempted[client] = false;
		BotKills[client] = 0;
		Primary[client] = false;
		Secondary[client] = false;
		RestrictPlayer1[client] = false;
		RestrictPlayer2[client] = false;
		RestrictPlayer3[client] = false;
		ClientNeedsScoreUpdated[client] = false;
		SavedDeaths[client] = 0;
		SavedFrags[client] = 0;
		lastWeaponUsed[client][0] = '\0';
		ClientNeedsRestricting[client] = false;
	}
}

public Action:Cmd_ListRatios(client, args)
{
	for (new i = 1; i <=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ReplyToCommand(client, "%N has a KDR of [%.2f]", i, KDR[i]);
		}
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
	if (!Enabled || !IsClientInGame(client) || RestrictionExpempted[client] ||
		!Restricted[client] || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
	{
		return Plugin_Continue;
	}

	// Check for restricted weapons
	if ((RestrictPlayer3[client] && StrContains(RestrictedWeapons3, weapon, false) != -1) ||
		(RestrictPlayer2[client] && StrContains(RestrictedWeapons2, weapon, false) != -1) ||
		(RestrictPlayer1[client] && StrContains(RestrictedWeapons1, weapon, false) != -1))
	{
		CPrintToChat(client, "%t", "Weapon", KDR[client], weapon);
		
		if (UseSound)
		{
			EmitSoundToClient(client, SOUND_FILE);
		}
		
		return Plugin_Handled;
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
	if (Enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		DefuseBombPoints[client] += 3;
	}
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
	if (Enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		BombExplodePoints[client] += 3;
	}
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
	if (!Enabled)
	{
		return;
	}
	
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim > 0 && victim <= MaxClients && !RestrictionExpempted[victim])
	{
		if (IgnoreBotKills && IsFakeClient(victim))
		{
			BotKills[killer]++;
		}
		
		if (DropMode == 1) // Drop Immediately
		{
			CreateTimer(0.1, Timer_ProcessKDR, GetClientSerial(victim));
		}
	}
	
	if (killer > 0 && killer <= MaxClients && !RestrictionExpempted[killer])
	{
		if (DropMode == 1) // Drop Immediately
		{
			GetEventString(event, "weapon", lastWeaponUsed[killer], sizeof(lastWeaponUsed[]));
			Format(dmsg, sizeof(dmsg), "lastWeaponUsed for %L was [%s]", killer, lastWeaponUsed[killer]);
			DebugMessage(killer, dmsg);
			//RequestFrame(RequestFrameCallback:ProcessKDR, GetClientSerial(killer));
			CreateTimer(0.1, Timer_ProcessKDR, GetClientSerial(killer));
		}
	}
}
#if 0
/**
 * The function that is called on the next frame of the event "player_team" to aid in handling the event for bots
 * 
 * @param	userid	Player's UserID
 * @noreturn	
 */
public HandlePlayerTeam(serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
	{
		return;
	}
}
#endif
/**
 *	"player_spawn"				// player spawned in game
 *	{
 *		"userid"	"short"		// user ID on server
 *	}
 */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!Enabled || !IsClientInGame(client))
	{
		return;
	}
	
	if (GetClientTeam(client) < CS_TEAM_SPECTATOR)
	{
		return;
	}
	
	Format(dmsg, sizeof(dmsg), "%L has spawned and ClientNeedsScoreUpdated value is %i", client, ClientNeedsScoreUpdated[client]);
	DebugMessage(client, dmsg);
	
	if (ClientNeedsScoreUpdated[client])
	{
		//ClientNeedsScoreUpdated[client] = false;
		
		CreateTimer(0.3, Timer_SetScore, GetClientSerial(client));
		
		Format(dmsg, sizeof(dmsg), "Setting %L's frags and deaths to %i and %i", client, SavedFrags[client], SavedDeaths[client]);
		DebugMessage(client, dmsg);
		
		return;
	}
	
	if (!RestrictionExpempted[client])
	{
		CheckKDR(client);
		
		if (UseHPRestrict)
		{
			CreateTimer(0.2, Timer_SetHealth, GetClientSerial(client));
		}
	}
}

public Action:Timer_SetHealth(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) <= 1)
	{
		return Plugin_Continue;
	}
	
	if (RestrictPlayer3[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", Ratio3HP, 1);
	}
	else if (RestrictPlayer2[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", Ratio2HP, 1);
	}
	else if (RestrictPlayer1[client])
	{
		SetEntProp(client, Prop_Send, "m_iHealth", Ratio1HP, 1);
	}
	
	return Plugin_Continue;
}	

public Action:Timer_SetScore(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	ClientNeedsScoreUpdated[client] = false;
	
	SetEntProp(client, Prop_Data, "m_iFrags", SavedFrags[client]);
	SetEntProp(client, Prop_Data, "m_iDeaths", SavedDeaths[client]);
	
	return Plugin_Continue;
}

public Action:Timer_ProcessKDR(Handle:timer, any:serial)
{ // Timer to allow score to update
	new client = GetClientFromSerial(serial);
	
	if (client == 0 || !IsClientInGame(client) || RestrictionExpempted[client])
	{
		return;
	}
	
	CheckKDR(client);
}

CheckKDR(client)
{
	Format(dmsg, sizeof(dmsg), "Checking KDR for %L", client);
	DebugMessage(client, dmsg);
	
	KDR[client] = 0.0;
	
	new Float:frags = float(GetClientFrags(client));
	new Float:deaths = float(GetClientDeaths(client));
	
	// Let's remove bomb/defuse points and any botkills, if there are any
	new Float:bonus_points = float((DefuseBombPoints[client] + BombExplodePoints[client] + BotKills[client]));
	frags -= bonus_points;
	
	if (MinRequiredKills >= 1 && frags < MinRequiredKills)
	{
		return; // Do not process since player hasn't reached minimum required kills
	}
	
	if (frags <= 0 && deaths <= 0)
	{
		Format(dmsg, sizeof(dmsg), "%L has a 0 KDR", client);
		DebugMessage(client, dmsg);
		
		return; // KDR is nothing
	}	
	else if (frags > 0 && deaths <= 0)
	{
		KDR[client] = frags - deaths;
	}
	else if (frags > 0 && deaths > 0)
	{
		KDR[client] = frags / deaths;
	}
	
	Format(dmsg, sizeof(dmsg), "%L has a %.2f KDR", client, KDR[client]);
	DebugMessage(client, dmsg);
	
	// KDR is above or equal to limit3
	if (KDR[client] > RatioLimit3)
	{
		if (!RestrictPlayer3[client])
		{
			Format(dmsg, sizeof(dmsg), "Restricting %L for being above RatioLimit3", client);
			DebugMessage(client, dmsg);
			
			RestrictPlayer1[client] = true;
			RestrictPlayer2[client] = true;
			RestrictPlayer3[client] = true;
			
			RestrictWeapons(client, RESTRICT3);
		}
	}
	else if (KDR[client] > RatioLimit2 && KDR[client] <= RatioLimit3)
	{
		if (RestrictPlayer3[client])
		{
			RestrictPlayer3[client] = false;
			CPrintToChat(client, "%t", "Off Some", KDR[client], RestrictedWeapons2);
		}
		
		if (!RestrictPlayer2[client])
		{
			Format(dmsg, sizeof(dmsg), "Restricting %L for being above RatioLimit2", client);
			DebugMessage(client, dmsg);
			
			RestrictPlayer1[client] = true;
			RestrictPlayer2[client] = true;
			
			RestrictWeapons(client, RESTRICT2);
		}
	}
	else if (KDR[client] > RatioLimit1 && KDR[client] <= RatioLimit2)
	{
		if (RestrictPlayer2[client])
		{
			RestrictPlayer2[client] = false;
			CPrintToChat(client, "%t", "Off Some", KDR[client], RestrictedWeapons1);
		}
		
		if (!RestrictPlayer1[client])
		{
			Format(dmsg, sizeof(dmsg), "Restricting %L for being above RatioLimit1", client);
			DebugMessage(client, dmsg);
			
			RestrictPlayer1[client] = true;
				
			RestrictWeapons(client, RESTRICT1);
		}
	}
	else
	{
		// Since the KDR is below the limit and the player is marked as restricted, unrestrict the player
		if (Restricted[client])
		{
			Format(dmsg, sizeof(dmsg), "UnRestricting %L since they are no longer at the KDR limit.", client);
			DebugMessage(client, dmsg);
			
			Restricted[client] = false;
			ClientNeedsRestricting[client] = false;
			RestrictPlayer1[client] = false;
			RestrictPlayer2[client] = false;
			RestrictPlayer3[client] = false;
			//DropOnSpawn[client] = false;
			SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			CPrintToChat(client, "%t", "Off All", KDR[client]);
			if (Announce)
			{
				new String:a_msg[MAX_MESSAGE_LENGTH];
				Format(a_msg, sizeof(a_msg), "%t", "Off Announce", client);
				AnnounceToPlayers(client, a_msg);
			}
		}
	}
}

RestrictWeapons(client, msg)
{
	if (!IsClientInGame(client) || RestrictionExpempted[client])
	{
		Format(dmsg, sizeof(dmsg), "Client [%L] is not in game or is exempt.", client);
		DebugMessage(client, dmsg);
		
		return;
	}
	
	if (Announce && !Restricted[client])
	{
		DebugMessage(client, "Creating timer for RestrictAnnounce.");
		
		CreateTimer(0.5, Timer_RestrictAnnounce, GetClientSerial(client));
	}
	
	Restricted[client] = true;
	
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (weapon != -1)
	{
		DebugMessage(client, "Will check secondary slot and drop, if needed.");
		
		DropRestrictedWeapons(client, weapon);
		Secondary[client] = true;
	}
	
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (weapon != -1)
	{
		DebugMessage(client, "Will check primary slot and drop, if needed.");
		
		DropRestrictedWeapons(client, weapon);
		Primary[client] = true;
	}
	
	switch (msg)
	{
		case 1:
		{
			CPrintToChat(client, "%t", "Restrict", KDR[client], RatioLimit1, RestrictedWeapons1);
		}
		case 2: 
		{
			CPrintToChat(client, "%t", "Restrict", KDR[client], RatioLimit2, RestrictedWeapons2);
		}
		case 3:
		{
			CPrintToChat(client, "%t", "Restrict", KDR[client], RatioLimit3, RestrictedWeapons3);
		}
	}
	
	CreateTimer(0.1, t_HookPlayer, GetClientSerial(client)); //Give the weapon time to drop
}

public Action:Timer_RestrictAnnounce(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	new String:a_msg[MAX_MESSAGE_LENGTH];
	Format(a_msg, sizeof(a_msg), "%t", "Restrict Announce", client);
	AnnounceToPlayers(client, a_msg);
	
	return Plugin_Continue;
}

AnnounceToPlayers(any:client, const String:msg[])
{
	if (DebugMode > 0)
	{
		CPrintToChatAll("Announce to players msg is: %s", msg);
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != client)
		{
			CPrintToChat(i, "%s", msg);
		}
	}
}

DropRestrictedWeapons(client, weapon)
{
	new String:WeaponName[MAX_WEAPON_NAME];
	
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));	
	ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
	
	if ((RestrictPlayer3[client] && StrContains(RestrictedWeapons3, WeaponName, false) != -1) ||
		(RestrictPlayer2[client] && StrContains(RestrictedWeapons2, WeaponName, false) != -1) ||
		(RestrictPlayer1[client] && StrContains(RestrictedWeapons1, WeaponName, false) != -1))
	{
		Format(dmsg, sizeof(dmsg), "[DropRestrictedWeapons] Restricting weapon_%s for %L and dropping it", WeaponName, client);
		DebugMessage(client, dmsg);
		
		CS_DropWeapon(client, weapon, true);
		DebugMessage(client, "Dropped weapon using CS_DropWeapon.");
		
		CreateTimer(0.2, t_GiveReplacementWeapon, GetClientSerial(client));
		
		if (UseSound)
		{
			EmitSoundToClient(client, SOUND_FILE);
		}
	}
}

public Action:t_GiveReplacementWeapon(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	Format(dmsg, sizeof(dmsg), "[t_GiveReplacementWeapon] Running timer to give replacement weapon for %L", client);
	DebugMessage(client, dmsg);
	
	new weapon;
	
	if (RestrictPlayer3[client])
	{
		if (Primary[client]) // Player needs a replacement for primary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement3);
				Primary[client] = false;
			}
		}
		
		if (Secondary[client]) // Player needs a replacement for secondary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement3a);
				Secondary[client] = false;
			}
		}
		
		return Plugin_Continue;
	}
	
	if (RestrictPlayer2[client])
	{
		if (Primary[client]) // Player needs a replacement for secondary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement2);
				Primary[client] = false;
			}
		}
		
		if (Secondary[client]) // Player needs a replacement for secondary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement2a);
				Secondary[client] = false;
			}
		}
		
		return Plugin_Continue;
	}
	
	if (RestrictPlayer1[client])
	{
		if (Primary[client]) // Player needs a replacement for secondary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement1);
				Primary[client] = false;
			}
		}
		
		if (Secondary[client]) // Player needs a replacement for secondary slot
		{
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weapon == -1) // no weapon exists, already dropped.
			{
				GiveReplacementWeapon(client, Replacement1a);
				Secondary[client] = false;
			}
		}
		
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

GiveReplacementWeapon(client, const String:weapon_name[])
{
	Format(dmsg, sizeof(dmsg), "[GiveReplacementWeapon] Running GiveReplacementWeapon [%s] for %L", weapon_name, client);
	DebugMessage(client, dmsg);
	
	if (StrEqual(weapon_name, "none", false)) // No replacement weapon, switch to next slot
	{
		SwitchToNextWeaponSlot(client);
	}
	else
	{
		if (SwitchToNewWeapon) // Give weapon and switch to it?
		{
			//GivePlayerItem(client, weapon_name);
			Client_GiveWeapon(client, weapon_name, true);
		}
		else
		{
			//ActiveWeapon[client] = GetActiveWeapon(client);
			//GivePlayerItem(client, weapon_name);
			//SetActiveWeapon(client, ActiveWeapon[client]);
			//PrintToChatAll("ActiveWeapon = %i", ActiveWeapon[client]);
			//if (ActiveWeapon[client] != -1)
			//{
			//	CreateTimer(0.1, Timer_SetActiveWeapon, GetClientSerial(client));
			//}
			Client_GiveWeapon(client, weapon_name, false);
		}
	}
}

public Action:Timer_SetActiveWeapon(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	SetActiveWeapon(client, ActiveWeapon[client]);
	
	return Plugin_Continue;
}

SwitchToNextWeaponSlot(client)
{
	new weapon;
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if (weapon == -1)
	{
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE); // knife is slot 2
	}
	
	if (weapon != -1)
	{
		EquipPlayerWeapon(client, weapon);
	}
}

public Action:t_HookPlayer(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client != 0 && IsClientInGame(client))
	{
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
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
	if (!Enabled || RestrictionExpempted[client] || !Restricted[client])
	{
		return Plugin_Continue;
	}
	
	new String:sWeapon[MAX_WEAPON_NAME];
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));	
	ReplaceString(sWeapon, sizeof(sWeapon), "weapon_", "", false);
	
	if ((RestrictPlayer3[client] && StrContains(RestrictedWeapons3, sWeapon, false) != -1) ||
		(RestrictPlayer2[client] && StrContains(RestrictedWeapons2, sWeapon, false) != -1) ||
		(RestrictPlayer1[client] && StrContains(RestrictedWeapons1, sWeapon, false) != -1))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

ResetEverything()
{
	DebugMessage(1, "Running ResetEverything()");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Restricted[i] = false;
			ActiveWeapon[i] = INVALID_ENT_REFERENCE;
			RestrictPlayer1[i] = false;
			RestrictPlayer2[i] = false;
			RestrictPlayer3[i] = false;
			SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			BombExplodePoints[i] = 0;
			DefuseBombPoints[i] = 0;
			KDR[i] = 0.0;
			//DropOnSpawn[i] = false;
			BotKills[i] = 0;
			Primary[i] = false;
			Secondary[i] = false;
			ClientNeedsScoreUpdated[i] = false;
			SavedDeaths[i] = 0;
			SavedFrags[i] = 0;
			lastWeaponUsed[i][0] = '\0';
			ClientNeedsRestricting[i] = false;
		}
	}
}

DebugMessage(client, const String:msg[], any:...)
{
	if (DebugMode <= 0 || client <= 0 || client > MaxClients || IsFakeClient(client))
	{
		return;
	}
	
	LogMessage("%s", msg);
	
	if (DebugMode == 2)
	{
		PrintToChatAll("[KDRWL DEBUG] %s", msg);
	}
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
SetActiveWeapon(client, weapon)
{
	//EquipPlayerWeapon(client, weapon);
	Format(dmsg, sizeof(dmsg), "Running SetActiveWeapon for %L [%i]", client, weapon);
	DebugMessage(client, dmsg);
	
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}
#if 0
/**
 * Grabs the player's active weapon
 *
 * @param client		Client Index.
 * @return	Weapon entity index or -1 on error
 */
GetActiveWeapon(client)
{
	new ent = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	Format(dmsg, sizeof(dmsg), "GetActiveWeapon for %L is [%i]", client, ent);
	DebugMessage(client, dmsg);
	
	return ent;
}
#endif

// ===================================
// SMLib Functions - Thanks berni
// ===================================
/**
 * Gives a client a weapon.
 *
 * @param client		Client Index.
 * @param className		Weapon Classname String.
 * @param switchTo		If set to true, the client will switch the active weapon to the new weapon.
 * @return				Entity Index of the given weapon on success, INVALID_ENT_REFERENCE on failure.
 */
Client_GiveWeapon(client, const String:className[], bool:switchTo=true)
{
	new weapon = Client_GetWeapon(client, className);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		weapon = Weapon_CreateForOwner(client, className);
		
		if (weapon == INVALID_ENT_REFERENCE) {
			return INVALID_ENT_REFERENCE;
		}
	}

	Client_EquipWeapon(client, weapon, switchTo);

	return weapon;
}

/**
 * Equips (attaches) a weapon to a client.
 *
 * @param client		Client Index.
 * @param weapon		Entity Index of the weapon.
 * @param switchTo		If true, the client will switch to that weapon (make it active).
 * @noreturn
 */
Client_EquipWeapon(client, weapon, bool:switchTo=false)
{
	EquipPlayerWeapon(client, weapon);
	
	if (switchTo) {
		Client_SetActiveWeapon(client, weapon);
	}
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
Client_SetActiveWeapon(client, weapon)
{
	//EquipPlayerWeapon(client, weapon);
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

/**
 * Create's a weapon and spawns it in the world at the specified location.
 * 
 * @param className		Classname String of the weapon to spawn
 * @param absOrigin		Absolute Origin Vector where to spawn the weapon.
 * @param absAngles		Absolute Angles Vector.
 * @return				Weapon Index of the created weapon or INVALID_ENT_REFERENCE on error.
 */
Weapon_CreateForOwner(client, const String:className[])
{
	new Float:absOrigin[3], Float:absAngles[3];
	Entity_GetAbsOrigin(client, absOrigin);
	Entity_GetAbsAngles(client, absAngles);
	
	new weapon = Weapon_Create(className, absOrigin, absAngles);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}
	
	Entity_SetOwner(weapon, client);
	
	return weapon;
}

/**
 * Create's a weapon and spawns it in the world at the specified location.
 * 
 * @param className		Classname String of the weapon to spawn
 * @param absOrigin		Absolute Origin Vector where to spawn the weapon.
 * @param absAngles		Absolute Angles Vector.
 * @return				Weapon Index of the created weapon or INVALID_ENT_REFERENCE on error.
 */
Weapon_Create(const String:className[], Float:absOrigin[3], Float:absAngles[3])
{
	new weapon = Entity_Create(className);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}
	
	Entity_SetAbsOrigin(weapon, absOrigin);
	Entity_SetAbsAngles(weapon, absAngles);
	
	DispatchSpawn(weapon);
	
	return weapon;
}

/**
 *  Creates an entity by classname.
 *
 * @param className			Classname String.
 * @param ForceEdictIndex	Edict Index to use.
 * @return 					Entity Index or INVALID_ENT_REFERENCE if the slot is already in use.
 */
Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}

	return CreateEntityByName(className, ForceEdictIndex);
}

/**
 * Checks if an entity is valid and exists.
 *
 * @param entity		Entity Index.
 * @return				True if the entity is valid, false otherwise.
 */
Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}

/**
 * Sets the Absolute Origin (position) of an entity.
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */
Entity_SetAbsOrigin(entity, Float:vec[3])
{
	// We use TeleportEntity to set the origin more safely
	// Todo: Replace this with a call to UTIL_SetOrigin() or CBaseEntity::SetLocalOrigin()
	TeleportEntity(entity, vec, NULL_VECTOR, NULL_VECTOR);
}

/**
 * Sets the Angles of an entity
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */ 
Entity_SetAbsAngles(entity, Float:vec[3])
{
	// We use TeleportEntity to set the angles more safely
	// Todo: Replace this with a call to CBaseEntity::SetLocalAngles()
	TeleportEntity(entity, NULL_VECTOR, vec, NULL_VECTOR);
}

/**
 * Gets the Absolute Origin (position) of an entity.
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */
Entity_GetAbsOrigin(entity, Float:vec[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec);
}

/**
 * Gets the Angles of an entity
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */ 
Entity_GetAbsAngles(entity, Float:vec[3])
{
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vec);
}

/**
 * Sets the owner of an entity.
 * For example the owner of a weapon entity.
 *
 * @param entity			Entity index.
 * @noreturn
 */
Entity_SetOwner(entity, newOwner)
{
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", newOwner);
}

/**
 * Gets the weapon of a client by the weapon's classname.
 *
 * @param client 		Client Index.
 * @param className		Classname of the weapon.
 * @return				Entity index on success or INVALID_ENT_REFERENCE.
 */
Client_GetWeapon(client, const String:className[])
{
	new offset = Client_GetWeaponsOffset(client) - 4;

	for (new i=0; i < MAX_WEAPONS; i++) {
		offset += 4;

		new weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) {
			continue;
		}
		
		if (Entity_ClassNameMatches(weapon, className)) {
			return weapon;
		}
	}
	
	return INVALID_ENT_REFERENCE;
}

/**
 * Checks if an entity matches a specific entity class.
 *
 * @param entity		Entity Index.
 * @param class			Classname String.
 * @return				True if the classname matches, false otherwise.
 */
bool:Entity_ClassNameMatches(entity, const String:className[], partialMatch=false)
{
	new String:entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));
	
	if (partialMatch) {
		return (StrContains(entity_className, className) != -1);
	}
	
	return StrEqual(entity_className, className);
}

/**
 * Gets the Classname of an entity.
 * This is like GetEdictClassname(), except it works for ALL
 * entities, not just edicts.
 *
 * @param entity			Entity index.
 * @param buffer			Return/Output buffer.
 * @param size				Max size of buffer.
 * @return					
 */
Entity_GetClassName(entity, String:buffer[], size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);
	
	if (buffer[0] == '\0') {
		return false;
	}
	
	return true;
}

/**
 * Checks whether the entity is a valid weapon or not.
 * 
 * @param weapon		Weapon Entity.
 * @return				True if the entity is a valid weapon, false otherwise.
 */
Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon)) {
		return false;
	}

	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/**
 * Gets the offset for a client's weapon list (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return				Weapon list offset or -1 on failure.
 */
Client_GetWeaponsOffset(client)
{
	static offset = -1;

	if (offset == -1) {
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
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

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
	
	if (!Enabled)
	{
		ResetEverything();
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

public OnKDR3Changed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RatioLimit3 = GetConVarFloat(cvar);
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

public RestrictedWeaponsThreeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RestrictedWeapons3[0] = '\0';
	GetConVarString(cvar, RestrictedWeapons3, sizeof(RestrictedWeapons3));
}

public OnDropModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropMode = GetConVarInt(cvar);
}

public OnUseSoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseSound = GetConVarBool(cvar);
}

public OnSoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SOUND_FILE[0] = '\0';
	GetConVarString(cvar, SOUND_FILE, sizeof(SOUND_FILE));
}

public OnUseExemptChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseExempt = GetConVarBool(cvar);
}

public OnIgnoreBotKillsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	IgnoreBotKills = GetConVarBool(cvar);
}

public OnMinimumKillsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MinRequiredKills = GetConVarInt(cvar);
}

public PrimaryReplacementOneChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement1[0] = '\0';
	GetConVarString(cvar, Replacement1, sizeof(Replacement1));
}

public SecondaryReplacementOneChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement1a[0] = '\0';
	GetConVarString(cvar, Replacement1a, sizeof(Replacement1a));
}

public PrimaryReplacementTwoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement2[0] = '\0';
	GetConVarString(cvar, Replacement2, sizeof(Replacement2));
}

public SecondaryReplacementTwoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement2a[0] = '\0';
	GetConVarString(cvar, Replacement2a, sizeof(Replacement2a));
}

public PrimaryReplacementThreeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement3[0] = '\0';
	GetConVarString(cvar, Replacement3, sizeof(Replacement3));
}

public SecondaryReplacementThreeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Replacement3a[0] = '\0';
	GetConVarString(cvar, Replacement3a, sizeof(Replacement3a));
}

public OnAnnounceChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Announce = GetConVarBool(cvar);
}

public OnSwitchWeaponChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SwitchToNewWeapon = GetConVarBool(cvar);
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public OnDebugModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DebugMode = GetConVarInt(cvar);
}

public OnUseHPRestrictChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseHPRestrict = GetConVarBool(cvar);
}

public OnRatio1HPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Ratio1HP = GetConVarInt(cvar);
}

public OnRatio2HPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Ratio2HP = GetConVarInt(cvar);
}

public OnRatio3HPChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Ratio3HP = GetConVarInt(cvar);
}