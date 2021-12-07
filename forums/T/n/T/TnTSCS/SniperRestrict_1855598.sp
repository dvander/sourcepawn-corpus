/* 
DESCRIPTION
	This plugin will enforce kill/frag limits for sniper rifles.
	Sniper rifles are the AWPS and AUTOs and can be the scout, if set in config file
	
	The idea behind this plugin was from another valve admin mod that has been abandoned.
	It's to help keep the awp whores to a minimum.
	
	You can set the number of allowed sniper kills/frags and if the player gets a
	replacement weapon when they reach that limit or not.

VERSION
	*	1.0 - Initial release
	* 	1.1 - Updated restricted buy, fixed sound not being added to download table - thanks Dr!fter :)
	* 	1.2 - Cleaned up code a bit
	* 	1.3 - Added bool for destroy dropped weapon by request (Iggy)
	*	1.4 - Fixed Weapon Drop for CSS:DM mod - changed from SDKCall to CS_DropWeapon
		-	*** Plugin now requires SM 1.4.0+ ***
	*	1.5.0 - Changed the way the plugin handles the purchasing of restricted weapons (uses new CS_OnBuyCommand)
	*	1.5.1 - Changed from hooking item_pickup to using SDKHook_WeaponCanUse
	*	1.5.2 - Removed DestroyPickedUpWeapon since SDKHooks will not allow a player with restriction to pick it up
	*	1.5.3 - Added ability to maintain the sniper restriction for entire map even if player disconnects via a cvar sm_SniperRestrict_MaintainRestrictions
	*	1.5.4 - Added Updater capability
	*	1.5.5 - Increased a minor update for testing Updater - it worked :)
	*	1.5.6 - Enhanced plugin to give replacement weapon on respawns if running CSS:DM and player tries to get restricted weapon
	*	1.5.7 - Fixed [SM] Native "CloseHandle" reported: Handle 0 is invalid (error 4)
	*	1.5.8 - Bug fixes, translation file added, and immune player addition
				*	Fixed CheckTimer (now ClearTimer, thanks to Antithasys from http://forums.alliedmods.net/showthread.php?t=167160
				*	Added CheckCommandAccess and assigned "doNot_Restrict_Snipers" or ADMFLAG_CUSTOM2 to allow players to not 
					be affected by this plugin.
				* 	Inclusion of colors.inc for colored chat with translation files
	*	1.5.9 - Fixed sm_sniperrestrict_version from displaying old information contained in config file
	* 	1.6.0 - Changed all CVars and file names to be all lowercase so as to not cause issues with those running linux and this plugin
				*	Change from SniperRestrict to sniper_restrict
				* 	Added CVar for Updater - defaulted to off
		1.6.1	- Added CVar to make weapon drop at round end instead of immediately
				*	Requested by Noitartsiger (https://forums.alliedmods.net/member.php?u=149049)
			+ Added CVar to notify all players when another player reaches sniper kill limit.
			* Changed back from sniper_restrict to SniperRestrict

CREDITS
	*	dalto and RedSwordfor weapon drop stuff and gamedata file
	* 	Dr!fter and RedSword because I learned a lot looking at their plugins
	* 	I know there are probably more because I looked at a LOT of different code and started going crossed eyed

TO DO LIST
	*	[DONE] Clean up code - there is a lot of redundancy in it right now - KyleS Hates Handles
	* 	[DONE v1.5] Add code to check if they bought a restricted weapon and refund their money if they did (or block it entirely)
		-	Further enhanced using the new CS_OnBuyCommand
	*	[DONE v1.5.8] Add translation file
	Make a suggestion :)
*/
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <colors> // As of 1.5.8
#include <smlib/clients>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/SniperRestrict.txt"

#define PLUGIN_VERSION "1.6.1"
#define PLUGIN_AUTHOR "TnTSCS"

#define MAX_FILE_LEN 256
#define MAX_WEAPON_NAME 80

// Handle for Trie
new Handle:h_Trie;

// This plugin's timer handles
new Handle:g_ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_ClientTimer2[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_ClientTimer3[MAXPLAYERS+1] = INVALID_HANDLE;

// This set taken from Dr!fters restricted sound
new String:RestrictSound[PLATFORM_MAX_PATH];
new String:g_soundName[MAX_FILE_LEN];
new bool:HasSound = false;

// This plugin's variables
new bool:ScoutIsSniper = false;
new bool:NotifyAdmin = true;
new bool:NotifyPlayers = false;
new bool:DestroyWeapon = false;
new bool:RestrictForBots = true;
new bool:SnipersRestricted[MAXPLAYERS+1] = {false, ...};
new bool:MaintainRestrictions = false;
new bool:CSSDM_InUse = false;
new bool:IsPlayerImmune[MAXPLAYERS+1] = {false, ...};
new bool:PlayerReceiveChat[MAXPLAYERS+1] = {false, ...};
new bool:UseUpdater = false;
new bool:DropOnRoundEnd = false;
new bool:NeedsToDrop[MAXPLAYERS+1] = {false, ...};
new bool:AdvertiseToPlayers = true;

new MaxSniperKills;
new SniperKills[MAXPLAYERS+1];

new String:weaponawp[MAX_WEAPON_NAME] = "awp";
new String:weaponsg550[MAX_WEAPON_NAME] = "sg550";
new String:weapong3sg1[MAX_WEAPON_NAME] = "g3sg1";
new String:weaponscout[MAX_WEAPON_NAME] = "scout";
new String:s_SniperReplacement[MAX_WEAPON_NAME];

public Plugin:myinfo = 
{
	name = "Sniper Restrict",
	author = "TnTSCS aka ClarkKent",
	description = "This plugin will restrict snipers for a player after they reach X kills with them",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=163588"
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
	// Create My ConVars
	CreateMyCVars();
	
	// Execute the config file and auto name it to plugin.filename.cfg
	AutoExecConfig(true);
	
	// Load translation file (as of 1.5.8)
	LoadTranslations("SniperRestrict.phrases");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_end", OnRoundEnd);
	
	RegConsoleCmd("sm_snipers", Command_Snipers);
	
	LoadSound(); // Taken from Dr!fter's weapon restrict plugin, uses the same sound
	
	h_Trie = CreateTrie();
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
	if(UseUpdater && StrEqual(name, "updater"))
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
	new Handle:Check_CSSDM = FindConVar("cssdm_enabled");
	
	// Check if CS:S DM is loaded and enabled
	if(Check_CSSDM != INVALID_HANDLE)
	{
		CSSDM_InUse = GetConVarBool(Check_CSSDM);
		
		if(CSSDM_InUse)
		{
			LogMessage("CSSDM is ENABLED!!!  Setting Variable for SniperRestrict!");
		}
		
		CloseHandle(Check_CSSDM);
	}
	
	// If CVar to use Updater is true, check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if(UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/**
 * Called when the map is loaded.
 *
 * @note This used to be OnServerLoad(), which is now deprecated.
 * Plugins still using the old forward will work.
 */
public OnMapStart()
{	
	if(HasSound)
	{
		PrecacheSound(RestrictSound, true);
	}
	
	// Clear all entries of the Trie
	ClearTrie(h_Trie);
	
	ResetLimits();
}

/**
 * Called right before a map ends.
 */
public OnMapEnd()
{
	ResetLimits();
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
	if(IsClientConnected(client) && IsClientInGame(client) && MaxSniperKills >= 1 && !IsFakeClient(client))
	{
		if(AdvertiseToPlayers)
		{
			CPrintToChat(client, "%t", "Plugin Announce", PLUGIN_VERSION, PLUGIN_AUTHOR);
			g_ClientTimer[client] = CreateTimer(10.0, t_Advertise, client);
		}
		
		SnipersRestricted[client] = false;
		
		if(CheckCommandAccess(client, "sm_SniperRestrict_chat", ADMFLAG_CHAT))
		{
			PlayerReceiveChat[client] = true;
		}
		else
		{
			PlayerReceiveChat[client] = false;
		}
		
		// If immune, stop processing here (as of 1.5.8)
		if(CheckCommandAccess(client, "donot_restrict_snipers", ADMFLAG_CUSTOM2))
		{
			IsPlayerImmune[client] = true;
			return;
		}
		else
		{
			IsPlayerImmune[client] = false;
		}
		
		// Get and store the client's SteamID
		decl String:authString[20];
		authString[0] = '\0';
		
		GetClientAuthString(client, authString, 20);
		
		new Player_Kills;
		
		// Retrieve the value of the Trie, if it exists and store that value in the Player_Kills variable
		if(GetTrieValue(h_Trie, authString, Player_Kills))
		{
			if(MaintainRestrictions)
			{
				SniperKills[client] = Player_Kills;
			}
			
			if(SniperKills[client] >= MaxSniperKills)
			{
				SnipersRestricted[client] = true;
				SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}
				
			RemoveFromTrie(h_Trie, authString);
		}
	}
}

public Action:t_Advertise(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && g_ClientTimer[client] != INVALID_HANDLE)
	{
		Advertise(client);	
		g_ClientTimer[client] = INVALID_HANDLE;
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
	// Snipers aren't restricted for client then allow the weapon pickup, otherwise, continue with further checking
	if(!SnipersRestricted[client])
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		return Plugin_Continue;
	}
	
	// If No restriction for bots and client is a bot then allow the weapon pickup, otherwise, continue with further checking
	//if(!RestrictForBots && IsFakeClient(client))
	//{
	//	return Plugin_Continue;
	//}

	decl String:sWeapon[MAX_WEAPON_NAME];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	if(StrEqual(sWeapon, "weapon_sg550", false) || StrEqual(sWeapon, "weapon_awp", false) || StrEqual(sWeapon, "weapon_g3sg1", false))
	{
		if(CSSDM_InUse)
		{
			g_ClientTimer2[client] = CreateTimer(0.1, t_CSSDM_Restrict, client);
			return Plugin_Continue;
		}
		
		// Do not allow the weapon to be picked up
		return Plugin_Handled;
	}
	
	if(ScoutIsSniper && StrEqual(sWeapon, "weapon_scout", false))
	{
		if(CSSDM_InUse)
		{
			g_ClientTimer[client] = CreateTimer(0.1, t_CSSDM_Restrict, client);
			return Plugin_Continue;
		}
		
		// Do not allow the scout to be picked up
		return Plugin_Handled;
	}
	
	// If the weapon is not an AWP, or AUTO (or a Scout if scout's are considered snipers), then allow the weapon to be picked up
	return Plugin_Continue;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DropOnRoundEnd)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && NeedsToDrop[i])
			{
				if(IsPlayerAlive(i)) //Player might have a different primary weapon
				{
					// Get and store weapon name
					decl String:wname[MAX_WEAPON_NAME];
					wname[0] = '\0';
					new weapon = Client_GetWeaponBySlot(i, 0);
					
					if(weapon == -1)
					{
						NoticeToPlayer(i);
						return;
					}
					
					//GetEventString(event, "weapon", wname, sizeof(wname));
					GetEntityClassname(weapon, wname, sizeof(wname));
					
					// If weapon used was an AWP or an AUTO (SG550 or G3SG1)
					if(StrEqual(wname, "weapon_sg550", false) || StrEqual(wname, "weapon_awp", false) || StrEqual(wname, "weapon_g3sg1", false))
					{
						RestrictWeapon(i);
					}
					
					// See if scouts are listed as snipers and weapon used was a scout
					if(ScoutIsSniper && StrEqual(wname, "weapon_scout", false))
					{
						RestrictWeapon(i);
					}
					
					return;
				}
				else
				{
					NoticeToPlayer(i);
				}
			}
		}
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!RestrictForBots && IsFakeClient(killer))
	{
		return;
	}
	
	// If attacker isn't another player or the player (killer) is immune
	if((killer < 1 || killer > MaxClients) || IsPlayerImmune[killer])
	{
		return;
	}
	
	// If plugin is enabled and player is not currently restricted from using sniper weapons
	if(MaxSniperKills >= 1 && !SnipersRestricted[killer])
	{
		if(ScoutIsSniper && StrEqual(s_SniperReplacement, "weapon_scout", false))
		{
			// Message admins about error in config file if scout is listed as both a sniper and a replacement
			ErrorMsgToAdmin();
			return;
		}
		
		// Get and store weapon name
		decl String:wname[MAX_WEAPON_NAME];
		wname[0] = '\0';
		
		// Get weapon short name from player_death event (awp, scout - not weapon_awp)
		GetEventString(event, "weapon", wname, sizeof(wname));
		
		// If weapon used was an AWP or an AUTO (SG550 or G3SG1)
		if(StrEqual(wname, weaponsg550, false) || StrEqual(wname, weaponawp, false) || StrEqual(wname, weapong3sg1, false))
		{
			RestrictInform(killer);
		}
		
		// See if scouts are listed as snipers and weapon used was a scout
		if(ScoutIsSniper && StrEqual(wname, weaponscout, false))
		{
			RestrictInform(killer);
		}
	}
}

/**
* Function to notify the admins when a player reaches their max sniper kills
*
* @param client	Client index of player who reached the sniper limit
* @noreturn
*/
NoticeToAdmin(client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		// Notify admins that a player has reached their Sniper Kill limit (if enabled)
		for(new i = 1; i <= MaxClients; i++)
		{
			// Use AdminOverride and add "sm_SniperRestrict_chat" to allow people to receive chat, or just let plugin use ADMFLAG_CHAT
			if(IsClientInGame(i) && PlayerReceiveChat[i])
			{
				CPrintToChat(i, "%t", "Notice To Admins", client);
			}
		}
	}
}

NoticeToPlayers(client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		// Notify all players that another player has reached their Sniper Kill limit (if enabled)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				CPrintToChat(i, "%t", "Notice To Players", client);
			}
		}
	}
}

ErrorMsgToAdmin()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CheckCommandAccess(i, "sm_SniperRestrict_chat", ADMFLAG_CHAT))
		{
			CPrintToChat(i, "%t", "Msg To Admins");
		}
	}
}

/**
* Function for when a player reaches their MaxSniperKills
*
* @param client	Client index of player who reached their max sniper kills
* @noreturn
*/
RestrictInform(client)
{
	// Add 1 kill to client's SniperKills
	SniperKills[client]++;
	
	// If client has reached their frag limit with the Sniper weapon
	if(SniperKills[client] >= MaxSniperKills)
	{
		if(DropOnRoundEnd && !SnipersRestricted[client])
		{
			SnipersRestricted[client] = true;
			NeedsToDrop[client] = true;
		}
		else
		{		
			RestrictWeapon(client);
		}
	}
	
	PrintToConsole(client, "%t", "Log Sniper Kill", SniperKills[client], MaxSniperKills);
}

/**
* Function to restrict the sniper weapon
*
* @param client	Client index of player to have restriction placed on
* @noreturn
*/
RestrictWeapon(client)
{
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	// Make sure player has a weapon in slot 0 (primary)
	if(weapon != -1)
	{
		// Force drop the weapon in slot 0 (uses gamedata file)
		CS_DropWeapon(client, weapon, true, true);
		
		if(DestroyWeapon)
		{
			// Set location for teleport
			new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
			
			// Get rid of weapon
			TeleportEntity(weapon, orgin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	NoticeToPlayer(client);
		
	if(StrEqual(s_SniperReplacement, "none", false))
	{
		return;
	}
	else
	{
		// Allow a 0.1 buffer to give replacement weapon
		g_ClientTimer3[client] = CreateTimer(0.1, t_GiveReplacementWeapon, client);
	}
}

NoticeToPlayer(client)
{
	if(ScoutIsSniper)
	{
		CPrintToChat(client, "%t", "Restricted Scout", MaxSniperKills);
	}
	else
	{
		CPrintToChat(client, "%t", "Restricted noScout", MaxSniperKills);
	}
	
	if(NotifyPlayers)
	{
		NoticeToPlayers(client);
	}
	else
	{
		if(NotifyAdmin)
		{
			NoticeToAdmin(client);
		}
	}
		
	// Set player has restricted sniper status
	SnipersRestricted[client] = true;
	
	NeedsToDrop[client] = false;
	
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client	Client index
 * @param weapon	User input for weapon name
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if(SnipersRestricted[client])
	{
		// If item picked up is awp, g3sg1, or sg550
		if(StrEqual(weapon, weaponsg550, false) || StrEqual(weapon, weaponawp, false) || StrEqual(weapon, weapong3sg1, false))
		{
			CPrintToChat(client, "%t", "Restricted noScout", MaxSniperKills);
			SR_PlaySound(client);
			return Plugin_Handled;
		}
		
		// If item picked up is scout
		if(ScoutIsSniper && StrEqual(weapon, weaponscout, false))
		{
			CPrintToChat(client, "%t", "Restricted Scout", MaxSniperKills);
			SR_PlaySound(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public SR_PlaySound(client)
{
	// Play restricted weapon sound
	if (strcmp(g_soundName, ""))
	{
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_soundName, vec, client, SNDLEVEL_RAIDSIREN);
	}
}

public Action:t_GiveReplacementWeapon(Handle:timer, any:killer)
{
	g_ClientTimer3[killer] = INVALID_HANDLE;
	
	if(IsClientInGame(killer))// && g_ClientTimer3[killer] != INVALID_HANDLE)
	{
		// Equip player with replacement weapon
		GivePlayerItem(killer, s_SniperReplacement);
	}
}

public Action:t_CSSDM_Restrict(Handle:timer, any:client)
{
	g_ClientTimer2[client] = INVALID_HANDLE;
	
	if(IsClientInGame(client))// && g_ClientTimer2[client] != INVALID_HANDLE)
	{
		//RestrictWeapon(client);
		new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		
		if(weapon != -1)
		{
			// Force drop the weapon in slot 0 (uses gamedata file)
			CS_DropWeapon(client, weapon, true, true);
		}
		
		if(StrEqual(s_SniperReplacement, "none", false))
		{
			return;
		}
		else
		{
			g_ClientTimer3[client] = CreateTimer(0.1, t_GiveReplacementWeapon, client);
		}
	}
}

// Taken from http://forums.alliedmods.net/showthread.php?t=167160 - thanks Antithasys (as of 1.5.8)
stock ClearTimer(&Handle:timer)
{  
	if(timer != INVALID_HANDLE)
	{  
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}      
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 */
// You still need to check IsClientInGame(client) if you want to do the client specific stuff (exvel)
public OnClientDisconnect(client)
{
	// Reset the player's sniper restriction status
	if(IsClientInGame(client))
	{		
		ClearTimer(g_ClientTimer[client]);
		ClearTimer(g_ClientTimer2[client]);
		ClearTimer(g_ClientTimer3[client]);
		
		IsPlayerImmune[client] = false;
		
		if(MaintainRestrictions)
		{
			// Get and store the client's SteamID
			decl String:authString[20];
			authString[0] = '\0';
			
			GetClientAuthString(client, authString, 20);
			
			new sKills = SniperKills[client];
			
			SetTrieValue(h_Trie, authString, sKills, true);
		}
		
		SniperKills[client] = 0;
		SnipersRestricted[client] = false;
		
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

/**
 * Used to send KeyHintText and Chat to player.
 *
 * @param client		Client index.
 * @noreturn
 */
public Advertise(client)
{
	// If MaxSniperKills is 0, then plugin is considered disabled
	if(IsClientInGame(client) && MaxSniperKills >= 1)
	{
		if(IsPlayerImmune[client])
		{
			Client_PrintKeyHintText(client, "%t\n\n%t", "Announce Header", PLUGIN_VERSION, PLUGIN_AUTHOR, "Player Immune");
			CPrintToChat(client, "%t", "Chat Advertise Immune");
			return;
		}
		
		if(ScoutIsSniper)
		{
			Client_PrintKeyHintText(client, "%t\n\n%t\n%t\n%t\n\n%t", "Announce Header", PLUGIN_VERSION, PLUGIN_AUTHOR, "Scout Is Sniper", "Allowed Sniper Kills", MaxSniperKills, "Replacement Weapon", s_SniperReplacement, "Number of Kills", SniperKills[client]);
			CPrintToChat(client, "%t", "Chat Advertise Scout", MaxSniperKills);
		}
		else
		{
			Client_PrintKeyHintText(client, "%t\n\n%t\n%t\n%t\n\n%t", "Announce Header", PLUGIN_VERSION, PLUGIN_AUTHOR, "Scout Is Not Sniper", "Allowed Sniper Kills", MaxSniperKills, "Replacement Weapon", s_SniperReplacement, "Number of Kills", SniperKills[client]);
			CPrintToChat(client, "%t", "Chat Advertise noScout", MaxSniperKills);
		}
	}
}

/**
* Function to use for callback for after the command sm_snipers (or !snipers) is invoked
*
* @param client 	Client Index invoking the command
*/
public Action:Command_Snipers(client, args)
{
	if(client == 0)
	{
		decl String:szText[254];
		szText[0] = '\0';
		
		new playersrestricted = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			// Is the player restricted from using Snipers?
			if(SnipersRestricted[i])
			{
				Format(szText, sizeof(szText), "%s%N\n", szText, i);
				playersrestricted++;
			}
		}
		
		if(playersrestricted == 0)
		{
			szText = "No players are restricted from using snipers";
		}
		else if(playersrestricted >= 1)
		{
			Format(szText, sizeof(szText), "Snipers are restricted for:\n%s", szText);
		}
		
		ReplyToCommand(client, szText);
		return Plugin_Continue;
	}
	
	Advertise(client);
	return Plugin_Continue;
}

/**
* Function to use to reset all client specific variables
*/
ResetLimits()
{
	// Reset the Sniper Restrictions for clients
	for (new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SniperKills[i] = 0;
			SnipersRestricted[i] = false;
		}
	}
}

/**
* using the exact same as weapon_restrict.smx by Dr!fter
*/
LoadSound()
{
	decl String:buffer[MAX_FILE_LEN];
	
	if (strcmp(g_soundName, ""))
	{
		PrecacheSound(g_soundName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}	
	PrecacheSound(g_soundName, true);
	

	HasSound = false;
	new Handle:kv = CreateKeyValues("WeaponRestrictSounds");
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/restrict/sound.txt");
	if(FileExists(file))
	{
		FileToKeyValues(kv, file);
		if(KvJumpToKey(kv, "sounds", false))
		{
			new String:dtfile[PLATFORM_MAX_PATH];
			KvGetString(kv, "restricted", dtfile, sizeof(dtfile), "");
			if(FileExists(dtfile) && strlen(dtfile) > 0)
			{
				AddFileToDownloadsTable(dtfile);
				if(StrContains(dtfile, "sound/", false) == 0)
				{
					ReplaceStringEx(dtfile, sizeof(dtfile), "sound/", "", -1, -1, false);
					strcopy(RestrictSound, PLATFORM_MAX_PATH, dtfile);
				}
				PrecacheSound(RestrictSound, true);
				if(IsSoundPrecached(RestrictSound))
				{
					HasSound = true;
				}
				else
				{
					LogError("Failed to precache restrict sound please make sure path is correct in %s and sound is in the sounds folder", file);
				}
			}
			else
			{
				LogError("Sound %s dosnt exist", dtfile);
			}
		}
		else
		{
			LogError("sounds key missing from %s");
		}
	}
	else
	{
		LogError("File %s dosnt exist", file);
	}
	CloseHandle(kv);
}

public CreateMyCVars()
{
	new Handle:hRandom;// KyleS Hates handles
	
	// Create Plugin ConVars
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_version", PLUGIN_VERSION, 
	"The version of 'Sniper Restrict'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_sniperreplace", "weapon_scout", 
	"(weapon_name, none) Weapon to equip player once they've reached their MaxSniperKills limit (if ScoutIsSniper is 1, do not use weapon_scout)")), SniperReplaceChanged);
	GetConVarString(hRandom, s_SniperReplacement, sizeof(s_SniperReplacement));
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_maxsniperkills", "5", 
	"(0 to disable, number) Sets the max number of kills allowed with Snipers, per map", _, true, 0.0, true, 100.0)), MaxSniperKillsChanged);
	MaxSniperKills = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_scoutissniper", "0", 
	"(0,1) Include Scout in the Sniper group (this must be 0 if SniperReplace is scout)", _, true, 0.0, true, 1.0)), ScoutIsSniperChanged);
	ScoutIsSniper = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_sound", "admin_plugin/actions/restrictedweapon.wav", 
	"Weapon Restricted Sound to Play")), SoundNameChanged);
	GetConVarString(hRandom, g_soundName, sizeof(g_soundName));
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_adminnotify", "1", 
	"(0,1) Notify admins when a player reaches their sniper kill limit - default is yes (1)", _, true, 0.0, true, 1.0)), NotifyAdminChanged);
	NotifyAdmin = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_destroyweapon", "0", 
	"(0,1) Destroy the Sniper weapon the player is holding when they reach their MaxSniperKills?", _, true, 0.0, true, 1.0)), DestroyWeaponChanged);
	DestroyWeapon = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_restrictforbots", "1", 
	"(0,1) Restrict applies to bots as well as hunans?", _, true, 0.0, true, 1.0)), RestrictForBotsChanged);
	RestrictForBots = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_maintainrestrictions", "0", 
	"(0,1) Maintain restrictions until map changes?  If set to no (0) then players can just reconnect to be able to purchase snipers again.", _, true, 0.0, true, 1.0)), MaintainRestrictionsChanged);
	MaintainRestrictions = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_useupdater", "0", 
	"Utilize 'Updater' plugin to auto-update Sniper Restrict when updates are published?\n1=yes, 0=no", _, true, 0.0, true, 1.0)), OnUseUpdaterChanged);
	UseUpdater = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_notifyplayers", "0",
	"Notify all players when another player reaches their sniper kill limit?", _, true, 0.0, true, 1.0)), NotifyPlayersChanged);
	NotifyPlayers = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_droproundend", "0",
	"Drop the sniper weapon for the player who reached their limit at the rounds end?", _, true, 0.0, true, 1.0)), DropOnRoundEndChanged);
	DropOnRoundEnd = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_advertise", "1",
	"Advertise this plugin to joining players?", _, true, 0.0, true, 1.0)), AdvertiseChanged);
	AdvertiseToPlayers = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public SniperReplaceChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, s_SniperReplacement, sizeof(s_SniperReplacement));
}
	
public MaxSniperKillsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaxSniperKills = GetConVarInt(cvar);
}
	
public ScoutIsSniperChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ScoutIsSniper = GetConVarBool(cvar);
}
	
public SoundNameChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_soundName, sizeof(g_soundName));
}
	
public NotifyAdminChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NotifyAdmin = GetConVarBool(cvar);
}
	
public DestroyWeaponChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DestroyWeapon = GetConVarBool(cvar);
}
	
public RestrictForBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RestrictForBots = GetConVarBool(cvar);
}
	
public MaintainRestrictionsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	MaintainRestrictions = GetConVarBool(cvar);
}

public OnUseUpdaterChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UseUpdater = GetConVarBool(cvar);
}

public NotifyPlayersChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NotifyPlayers = GetConVarBool(cvar);
}

public DropOnRoundEndChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropOnRoundEnd = GetConVarBool(cvar);
}

public AdvertiseChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdvertiseToPlayers = GetConVarBool(cvar);
}