/* 
DESCRIPTION
*	This plugin will enforce kill/frag limits for sniper rifles.
*	Sniper rifles are the AWPS and AUTOs and can be the scout, if set in config file
*	
*	The idea behind this plugin was from another valve admin mod that has been abandoned.
*	It's to help keep the awp whores to a minimum.
*	
*	You can set the number of allowed sniper kills/frags and if the player gets a
*	replacement weapon when they reach that limit or not.
*
VERSION
*	*	1.0 		- Initial release
*	* 	1.1 		- Updated restricted buy, fixed sound not being added to download table - thanks Dr!fter :)
*	* 	1.2 		- Cleaned up code a bit
*	* 	1.3 		- Added bool for destroy dropped weapon by request (Iggy)
*	*	1.4 		- Fixed Weapon Drop for CSS:DM mod - changed from SDKCall to CS_DropWeapon
*				-	*** Plugin now requires SM 1.4.0+ ***
*	*	1.5.0 		- Changed the way the plugin handles the purchasing of restricted weapons (uses new CS_OnBuyCommand)
*	*	1.5.1 		- Changed from hooking item_pickup to using SDKHook_WeaponCanUse
*	*	1.5.2 		- Removed DestroyPickedUpWeapon since SDKHooks will not allow a player with restriction to pick it up
*	*	1.5.3 		- Added ability to maintain the sniper restriction for entire map even if player disconnects via a cvar sm_SniperRestrict_MaintainRestrictions
*	*	1.5.4 		- Added Updater capability
*	*	1.5.5 		- Increased a minor update for testing Updater - it worked :)
*	*	1.5.6 		- Enhanced plugin to give replacement weapon on respawns if running CSS:DM and player tries to get restricted weapon
*	*	1.5.7 		- Fixed [SM] Native "CloseHandle" reported: Handle 0 is invalid (error 4)
*	*	1.5.8 		- Bug fixes, translation file added, and immune player addition
*				*	Fixed CheckTimer (now ClearTimer, thanks to Antithasys from http://forums.alliedmods.net/showthread.php?t=167160
*				*	Added CheckCommandAccess and assigned "doNot_Restrict_Snipers" or ADMFLAG_CUSTOM2 to allow players to not 
*					be affected by this plugin.
*				* 	Inclusion of colors.inc for colored chat with translation files
*	*	1.5.9	 	- Fixed sm_sniperrestrict_version from displaying old information contained in config file
*	* 	1.6.0 		- Changed all CVars and file names to be all lowercase so as to not cause issues with those running linux and this plugin
*				*	Change from SniperRestrict to sniper_restrict
*				* 	Added CVar for Updater - defaulted to off
*		1.6.1		- Added CVar to make weapon drop at round end instead of immediately
*					*	Requested by Noitartsiger (https://forums.alliedmods.net/member.php?u=149049)
*				+ Added CVar to notify all players when another player reaches sniper kill limit.
*				* Changed back from sniper_restrict to SniperRestrict
*		1.6.2		- Added CVar for player notifications for remaining sniper kills
*		1.6.3 		- 	General clean up of code per Asherkins request.
*				+	Added a CVar so you can define your own "sniper" weapons
*				*	Fixed sound to work with CS:GO
*		1.6.3.1	*	Cleaned up client timer codes
*				*	Moved from 3 digit to 4 digit version numbers
* 
* 		1.6.3.2	*	Updated and added some translation phrases
* 				+	Added a longer advertise so players have a chance to read it before it fades away.
* 				-	Removed need for sound.txt file
* 
* 		1.6.3.3	+	Added CVar to control if admin notification on cooldown are sent.
*
CREDITS
*	*	dalto and RedSwordfor weapon drop stuff and gamedata file
*	* 	Dr!fter and RedSword because I learned a lot looking at their plugins
*	* 	I know there are probably more because I looked at a LOT of different code and started going crossed eyed
*
TO DO LIST
*	*	[DONE] Clean up code - there is a lot of redundancy in it right now - KyleS Hates Handles
*	* 	[DONE v1.5] Add code to check if they bought a restricted weapon and refund their money if they did (or block it entirely)
*		-	Further enhanced using the new CS_OnBuyCommand
*	*	[DONE v1.5.8] Add translation file
*	Make a suggestion :)
*/
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <smlib/clients>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/3266762/SniperRestrict.txt"

#define PLUGIN_VERSION "1.6.3.3"
#define PLUGIN_AUTHOR "TnTSCS"

#define MAX_FILE_LEN 256
#define MAX_WEAPON_NAME 80

// Handle for Trie
new Handle:h_Trie;

// This plugin's timer handles
new Handle:g_ClientTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

// This plugin's variables
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
new bool:AdvisePlayer = true;
new bool:GameIsCSGO = false;

new MaxSniperKills;
new SniperKills[MAXPLAYERS+1];
new CoolDownRoundAmount = 0;
new CoolDownRounds[MAXPLAYERS+1];
new bool:NotifyAdminCooldown = false;

new String:s_SniperReplacement[MAX_WEAPON_NAME];
new String:s_SniperWeapons[120];
new String:s_FriendlyNames[120];

new String:SOUND_FILE[MAX_FILE_LEN];

new AdvertiseCount[MAXPLAYERS+1] = {false, ...};

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
	
	LoadTranslations("SniperRestrict.phrases");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_end", OnRoundEnd);
	
	RegConsoleCmd("sm_snipers", Command_Snipers);
	
	SoundPrecache();
	
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
	new Handle:Check_CSSDM = FindConVar("cssdm_enabled");
	
	// Check if CS:S DM is loaded and enabled
	if (Check_CSSDM != INVALID_HANDLE)
	{
		CSSDM_InUse = GetConVarBool(Check_CSSDM);
		
		if (CSSDM_InUse)
		{
			LogMessage("CSSDM is ENABLED!!!  Setting Variable for SniperRestrict!");
		}
		
		CloseHandle(Check_CSSDM);
	}
	
	// If CVar to use Updater is true, check if plugin Updater exists, if it does, add this plugin to its list of managed plugins
	if (UseUpdater && LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	CheckSniperReplacement();
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
	
	for (new i = 1; i <= MaxClients; i++)
	{
		ClearTimer(g_ClientTimer[i]);
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
	AdvertiseCount[client] = 0;
	CoolDownRounds[client] = 0;
	
	if (IsClientConnected(client) && IsClientInGame(client) && MaxSniperKills >= 1 && !IsFakeClient(client))
	{
		if (AdvertiseToPlayers)
		{
			CPrintToChat(client, "%t", "Plugin Announce", PLUGIN_VERSION, PLUGIN_AUTHOR);
			CreateTimer(10.0, t_Advertise, GetClientSerial(client));
		}
		
		SnipersRestricted[client] = false;
		
		if (CheckCommandAccess(client, "sm_SniperRestrict_chat", ADMFLAG_CHAT))
		{
			PlayerReceiveChat[client] = true;
		}
		else
		{
			PlayerReceiveChat[client] = false;
		}
		
		// If immune, stop processing here no need to worry about the Trie
		if (CheckCommandAccess(client, "donot_restrict_snipers", ADMFLAG_CUSTOM2))
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
		if (GetTrieValue(h_Trie, authString, Player_Kills))
		{
			if (MaintainRestrictions)
			{
				SniperKills[client] = Player_Kills;
			}
			
			if (SniperKills[client] >= MaxSniperKills)
			{
				SnipersRestricted[client] = true;
				SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			}
				
			RemoveFromTrie(h_Trie, authString);
		}
	}
}

public Action:t_Advertise(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
	
	if (IsPlayerImmune[client])
	{
		CPrintToChat(client, "%t", "Chat Advertise Immune");
	}
	else
	{
		CPrintToChat(client, "%t", "Chat Advertise Snipers", MaxSniperKills, s_FriendlyNames);
	}
	
	CreateTimer(3.0, t_Advertise2, serial, TIMER_REPEAT);
}

public Action:t_Advertise2(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return Plugin_Stop;
	
	AdvertiseCount[client]++;
	if (AdvertiseCount[client] <= 4)
	{
		Advertise(client);
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public Action:t_AdvisePlayer(Handle:timer, any:client)
{
	// As long as player is still in the game and alive, advertise to them
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_ClientTimer[client] != INVALID_HANDLE)
	{
		PrintHintText(client, "%t", "Advise Player");
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
	if (!SnipersRestricted[client])
	{
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		return Plugin_Continue;
	}
	
	decl String:sWeapon[MAX_WEAPON_NAME];
	sWeapon[0] = '\0';
	
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));

	if (StrContains(s_SniperWeapons, sWeapon, false) != -1)
	{
		if (CSSDM_InUse)
		{
			CreateTimer(0.1, t_CSSDM_Restrict, GetClientSerial(client));
			return Plugin_Continue;
		}
		
		// Do not allow the weapon to be picked up
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (DropOnRoundEnd)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			ClearTimer(g_ClientTimer[i]);
			
			if (NeedsToDrop[i])
			{
				if (IsPlayerAlive(i)) //Player might have a different primary weapon
				{
					// Get and store weapon name
					decl String:wname[MAX_WEAPON_NAME];
					wname[0] = '\0';
					new weapon = Client_GetWeaponBySlot(i, 0);
					
					if (weapon == -1)
					{
						NoticeToPlayer(i);
						return;
					}
					
					GetEntityClassname(weapon, wname, sizeof(wname));
					
					if (StrContains(s_SniperWeapons, wname, false) != -1)
					{
						RestrictWeapon(i);
						return;
					}
				}
				
				NoticeToPlayer(i);
			}
		}
	}
	
	if (CoolDownRoundAmount > 0)
	{
		CheckCoolDown();
	}
}

CheckCoolDown()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !SnipersRestricted[i])
			continue;
		
		CoolDownRounds[i]++;
		
		if (CoolDownRounds[i] >= CoolDownRoundAmount)
		{
			CoolDownRounds[i] = 0;
			SniperKills[i] = 0;
			SnipersRestricted[i] = false;
			CPrintToChat(i, "%t", "Allow Post Cooldown");
			
			if (NotifyAdminCooldown)
			{
				new String:s_msg[MAX_MESSAGE_LENGTH];
				Format(s_msg, sizeof(s_msg), "%t", "Notify Admin Post Cooldown", i);
				NoticeToAdmin(i, s_msg);
			}
		}
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!RestrictForBots && IsFakeClient(killer))
	{
		return;
	}
	
	// If attacker isn't another player or the player (killer) is immune
	if ((killer < 1 || killer > MaxClients) || IsPlayerImmune[killer])
	{
		return;
	}
	
	// If plugin is enabled and player is not currently restricted from using sniper weapons
	if (MaxSniperKills >= 1 && !SnipersRestricted[killer])
	{
		// Get and store weapon name
		decl String:wname[MAX_WEAPON_NAME];
		wname[0] = '\0';
		
		// Get weapon short name from player_death event (awp, scout - not weapon_awp)
		GetEventString(event, "weapon", wname, sizeof(wname));
		
		if (StrContains(s_SniperWeapons, wname, false) != -1)
		{
			RestrictInform(killer);
		}
	}
}

CheckSniperReplacement()
{
	// Check if replacement weapon is listed in the list of sniper weapons, if it is, stop plugin and advise admins.
	if (StrContains(s_SniperWeapons, s_SniperReplacement, false) != -1)
	{
		SetFailState("Sniper replacement weapon is listed as a restricted weapon.");
	}
}

/**
* Function to notify the admins when a player reaches their max sniper kills
*
* @param client	Client index of player who reached the sniper limit
* @noreturn
*/
NoticeToAdmin(any:client, const String:msg[])
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		// Notify admins that a player has reached their Sniper Kill limit (if enabled)
		for (new i = 1; i <= MaxClients; i++)
		{
			// Use AdminOverride and add "sm_SniperRestrict_chat" to allow people to receive chat, or just let plugin use ADMFLAG_CHAT
			if (IsClientInGame(i) && PlayerReceiveChat[i])
			{
				CPrintToChat(i, "%s", msg);
			}
		}
	}
}

NoticeToPlayers(client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		// Notify all players that another player has reached their Sniper Kill limit (if enabled)
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				CPrintToChat(i, "%t", "Notice To Players", client);
			}
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
	if (SniperKills[client] >= MaxSniperKills)
	{
		if (DropOnRoundEnd && !SnipersRestricted[client])
		{
			SnipersRestricted[client] = true;
			NeedsToDrop[client] = true;
			
			if (AdvisePlayer)
			{
				if (g_ClientTimer[client] == INVALID_HANDLE)
				{
					g_ClientTimer[client] = CreateTimer(3.0, t_AdvisePlayer, client, TIMER_REPEAT);
				}
			}
		}
		else
		{		
			RestrictWeapon(client);
		}
	}
	
	if (AdvisePlayer)
	{
		PrintHintText(client, "%t", "Log Sniper Kill", SniperKills[client], MaxSniperKills);
	}
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
	if (weapon != -1)
	{
		// Force drop the weapon in slot 0 (uses gamedata file)
		CS_DropWeapon(client, weapon, true, true);
		
		if (DestroyWeapon)
		{
			// Set location for teleport
			new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
			
			// Get rid of weapon
			TeleportEntity(weapon, orgin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	NoticeToPlayer(client);
		
	if (StrEqual(s_SniperReplacement, "none", false))
	{
		SwitchToNextWeaponSlot(client);
		return;
	}
	else
	{
		// Allow a 0.1 buffer to give replacement weapon
		CreateTimer(0.1, t_GiveReplacementWeapon, GetClientSerial(client));
	}
}

SwitchToNextWeaponSlot(client)
{
	new weapon;
	weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if (weapon == -1)
	{
		weapon = GetPlayerWeaponSlot(client, 2); // knife
	}
	
	if (weapon != -1)
	{
		EquipPlayerWeapon(client, weapon);
	}
}

NoticeToPlayer(client)
{
	CPrintToChat(client, "%t", "Restricted Snipers", MaxSniperKills, s_FriendlyNames);
	
	if (NotifyPlayers)
	{
		NoticeToPlayers(client);
	}
	else
	{
		if (NotifyAdmin)
		{
			new String:msg[MAX_MESSAGE_LENGTH];
			Format(msg, sizeof(msg), "%t", "Notice To Admins", client);
			NoticeToAdmin(client, msg);
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
	if (SnipersRestricted[client])
	{
		if (StrContains(s_SniperWeapons, weapon, false) != -1)
		{
			CPrintToChat(client, "%t", "Restricted Snipers", MaxSniperKills, s_FriendlyNames);
			SR_PlaySound(client);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public SR_PlaySound(client)
{
	// Play restricted weapon sound
	if (strcmp(SOUND_FILE, "") == 1)
	{
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		
		if (GameIsCSGO)
		{
			ClientCommand(client, "play *%s", SOUND_FILE);
		}
		else
		{
			EmitAmbientSound(SOUND_FILE, vec, client, SNDLEVEL_RAIDSIREN);
		}
	}
}

public Action:t_GiveReplacementWeapon(Handle:timer, any:serial)
{
	new killer = GetClientFromSerial(serial);
	
	if (killer == 0)
		return;
	
	GivePlayerItem(killer, s_SniperReplacement);
}

public Action:t_CSSDM_Restrict(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client == 0)
		return;
	
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if (weapon != -1)
	{
		// Force drop the weapon in slot 0 (uses gamedata file)
		CS_DropWeapon(client, weapon, true, true);
	}
	
	if (StrEqual(s_SniperReplacement, "none", false))
	{
		SwitchToNextWeaponSlot(client);
		return;
	}
	else
	{
		CreateTimer(0.1, t_GiveReplacementWeapon, GetClientSerial(client));
	}
}

// Taken from http://forums.alliedmods.net/showthread.php?t=167160 - thanks Antithasys (as of 1.5.8)
ClearTimer(&Handle:timer)
{  
	if (timer != INVALID_HANDLE)
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
	if (IsClientInGame(client))
	{
		ClearTimer(g_ClientTimer[client]);
		
		IsPlayerImmune[client] = false;
		
		if (MaintainRestrictions)
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
		NeedsToDrop[client] = false;
		CoolDownRounds[client] = 0;
		
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
	if (IsClientInGame(client) && MaxSniperKills >= 1)
	{
		if (IsPlayerImmune[client])
		{
			if (GameIsCSGO)
			{
				PrintHintText(client, "%t\n\n%t", "Announce Header", PLUGIN_VERSION, PLUGIN_AUTHOR, "Player Immune");
			}
			else
			{
				Client_PrintKeyHintText(client, "%t\n\n%t", "Announce Header", PLUGIN_VERSION, PLUGIN_AUTHOR, "Player Immune");
			}
			return;
		}
		
		new String:smsg[MAX_MESSAGE_LENGTH];
		Format(smsg, sizeof(smsg), "%t\n", "Sniper Weapons", s_FriendlyNames);
		Format(smsg, sizeof(smsg), "%s%t\n", smsg, "Allowed Sniper Kills", MaxSniperKills);
		Format(smsg, sizeof(smsg), "%s%t\n\n", smsg, "Replacement Weapon", s_SniperReplacement);
		Format(smsg, sizeof(smsg), "%s%t", smsg, "Number of Kills", SniperKills[client]);
		
		if (GameIsCSGO)
		{
			PrintToChat(client, "%s", smsg);
		}
		else
		{
			Client_PrintKeyHintText(client, "%s", smsg);
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
	if (client == 0)
	{
		decl String:szText[254];
		szText[0] = '\0';
		
		new playersrestricted = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			// Is the player restricted from using Snipers?
			if (SnipersRestricted[i])
			{
				Format(szText, sizeof(szText), "%s%N\n", szText, i);
				playersrestricted++;
			}
		}
		
		if (playersrestricted == 0)
		{
			szText = "No players are restricted from using snipers";
		}
		else if (playersrestricted >= 1)
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
		if (IsClientInGame(i))
		{
			SniperKills[i] = 0;
			SnipersRestricted[i] = false;
		}
	}
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

public CreateMyCVars()
{
	decl String:gdir[PLATFORM_MAX_PATH];
	gdir[0] = '\0';
	
	GetGameFolderName(gdir,sizeof(gdir));
	
	if (StrEqual(gdir,"csgo",false))
	{
		GameIsCSGO = true;
	}
	
	new Handle:hRandom; //KyleS HATES Handles
	
	// Create Plugin ConVars
	HookConVarChange((CreateConVar("sm_SniperRestrict_version", PLUGIN_VERSION, 
	"The version of 'Sniper Restrict'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_sniperreplace", "weapon_scout", 
	"(weapon_name, none) Weapon to equip player once they've reached their MaxSniperKills limit")), SniperReplaceChanged);
	GetConVarString(hRandom, s_SniperReplacement, sizeof(s_SniperReplacement));
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_maxsniperkills", "5", 
	"(0 to disable, number) Sets the max number of kills allowed with Snipers, per map", _, true, 0.0, true, 100.0)), MaxSniperKillsChanged);
	MaxSniperKills = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_adminnotify", "1", 
	"(0,1) Notify admins when a player reaches their sniper kill limit - default is yes (1)", _, true, 0.0, true, 1.0)), NotifyAdminChanged);
	NotifyAdmin = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_adminnotifycooldown", "1", 
	"(0,1) Notify admins when a player finishes their cooldown after being restricted?", _, true, 0.0, true, 1.0)), NotifyAdminCooldownChanged);
	NotifyAdminCooldown = GetConVarBool(hRandom);
	
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
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_advise", "1",
	"Advise to players how many remaining sniper kills they have used?", _, true, 0.0, true, 1.0)), AdvisePlayerChanged);
	AdvisePlayer = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_snipers", "weapon_awp weapon_g3sg1 weapon_sg550",
	"List of weapons to consider sniper rifles, seperate weapon names with a space")), SnipersChanged);
	GetConVarString(hRandom, s_SniperWeapons, sizeof(s_SniperWeapons));
	
	GetConVarString(hRandom, s_FriendlyNames, sizeof(s_FriendlyNames));
	ReplaceString(s_FriendlyNames, sizeof(s_FriendlyNames), "weapon_", "", false);
	ReplaceString(s_FriendlyNames, sizeof(s_FriendlyNames), " ", " - ", false);
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_sound", "buttons/weapon_cant_buy.wav",
	"Path and file name of sound file to use for restriction sound relative to sound folder.")), SoundChanged);
	SOUND_FILE[0] = '\0';
	GetConVarString(hRandom, SOUND_FILE, sizeof(SOUND_FILE));
	
	HookConVarChange((hRandom = CreateConVar("sm_SniperRestrict_cooldown", "0",
	"Number of rounds that must pass before a player is allowed to use snipers again after being restricted.  Use 0 to not use this feature.", _, true, 0.0, true, 25.0)), CooldownChanged);
	CoolDownRoundAmount = GetConVarInt(hRandom);
	
	CloseHandle(hRandom);
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

public NotifyAdminChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NotifyAdmin = GetConVarBool(cvar);
}

public NotifyAdminCooldownChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NotifyAdminCooldown = GetConVarBool(cvar);
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

public AdvisePlayerChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdvisePlayer = GetConVarBool(cvar);
}

public SnipersChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, s_SniperWeapons, sizeof(s_SniperWeapons));
	
	GetConVarString(cvar, s_FriendlyNames, sizeof(s_FriendlyNames));
	ReplaceString(s_FriendlyNames, sizeof(s_FriendlyNames), "weapon_", "", false);
	ReplaceString(s_FriendlyNames, sizeof(s_FriendlyNames), " ", " - ", false);
}

public SoundChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SOUND_FILE[0] = '\0';
	GetConVarString(cvar, SOUND_FILE, sizeof(SOUND_FILE));
}

public CooldownChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CoolDownRoundAmount = GetConVarInt(cvar);
}