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

CREDITS
	*	dalto and RedSwordfor weapon drop stuff and gamedata file
	* 	Dr!fter and RedSword because I learned a lot looking at their plugins
	* 	I know there are probably more because I looked at a LOT of different code and started going crossed eyed

TO DO LIST
	*	Clean up code - there is a lot of redundancy in it right now
	* 	Add code to check if they bought a restricted weapon and refund their money if they did (or block it entirely)
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <smlib/clients>

#pragma semicolon 1

#define PLUGIN_VERSION "1.4"
#define PLUGIN_ANNOUNCE "\x04[\x03Sniper Restrict\x04]\x01 v1.3 by TnTSCS \x04(type !snipers for more info)"
#define PLUGIN_ANNOUNCE2 "[Sniper Restrict] v1.3 by TnTSCS"

#define MAX_FILE_LEN 256

new SniperKills[MAXPLAYERS+1];
new SnipersRestricted[MAXPLAYERS+1];

//Drop Weapon(Credits:dalto)
new Handle:g_CvarMaxSniperKills = INVALID_HANDLE;
new Handle:g_CvarScoutIsSniper = INVALID_HANDLE;
new Handle:g_CvarSniperReplace = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new Handle:g_CvarNotifyAdmin = INVALID_HANDLE;
new Handle:g_CvarDestroyWeapon = INVALID_HANDLE;

// This set taken from Dr!fters restricted sound
new String:RestrictSound[PLATFORM_MAX_PATH];
new String:g_soundName[MAX_FILE_LEN];
new bool:HasSound = false;
new bool:ScoutIsSniper = false;
new bool:NotifyAdmin = true;
new bool:DestroyWeapon = false;

new MaxSniperKills;
new r_amount;

new String:weaponawp[64] = "awp";
new String:weaponsg550[64] = "sg550";
new String:weapong3sg1[64] = "g3sg1";
new String:weaponscout[64] = "scout";
new String:g_SniperReplacement[64];

public Plugin:myinfo = 
{
	name = "Sniper Restrict",
	author = "TnTSCS aKa ClarKKent",
	description = "This plugin will restrict snipers for a player after they reach X kills with them",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=163588"
}

public OnPluginStart()
{
	// Create Plugin ConVars
	CreateConVar("sm_SniperRestrict_version_build",SOURCEMOD_VERSION, "The version of SourceMod that 'Sniper Restrict' was compiled with.", FCVAR_PLUGIN);
	CreateConVar("sm_SniperRestrict_version", PLUGIN_VERSION, "The version of 'Sniper Restrict'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	// Create My ConVars
	g_CvarSniperReplace = CreateConVar("sm_SniperRestrict_SniperReplace", "weapon_scout", "(weapon_name or none to disable plugin) Weapon to equip player once they've reached their MaxSniperKills limit (if ScoutIsSniper is 1, do not use weapon_scout)");
	g_CvarMaxSniperKills = CreateConVar("sm_SniperRestrict_MaxSniperKills", "5", "(0 to disable, number) Sets the max number of kills allowed with Snipers, per map");
	g_CvarScoutIsSniper = CreateConVar("sm_SniperRestrict_ScoutIsSniper", "0", "(0,1) Include Scout in the Sniper group (this must be 0 if SniperReplace is scout)");
	g_CvarSoundName = CreateConVar("sm_SniperRestrict_sound", "admin_plugin/actions/restrictedweapon.wav", "Weapon Restricted Sound to Play");
	g_CvarNotifyAdmin = CreateConVar("sm_SniperRestrict_AdminNotify", "1", "(0,1) Notify admins when a player reaches their sniper kill limit - default is yes (1)");
	g_CvarDestroyWeapon = CreateConVar("sm_SniperRestrict_DestroyWeapon", "0", "(0,1) Destroy the Sniper weapon when MaxSniperKills is reached");
	
	// Execute the config file
	AutoExecConfig(true, "SniperRestrict.plugin");
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("item_pickup", Event_ItemPickup);
	
	RegConsoleCmd("say", Command_Snipers);
	RegConsoleCmd("say_team", Command_Snipers);
	
	//Load game config + allow weapon drop (Credits : dalto + AltPluzF4 and RedSword)
	new Handle:hGameConf = LoadGameConfigFile("wpndrop-cstrike.games");
	if(Handle:hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/wpndrop-cstrike.games.txt not loadable");
	}
	
	// Get weapon_name of replacement weapon
	GetConVarString(g_CvarSniperReplace, g_SniperReplacement, sizeof(g_SniperReplacement));
	
	// Find MaxSniperKills
	MaxSniperKills = GetConVarInt(g_CvarMaxSniperKills);
	
	// Find out if Scout is sniper (1) or not (0)
	ScoutIsSniper = GetConVarBool(g_CvarScoutIsSniper);
	
	// Get path and filename of restricted sound
	GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	
	// Find out if admins should get notified when players reach their kill limit
	NotifyAdmin = GetConVarBool(g_CvarNotifyAdmin);
	
	// Find out if plugin should destroy the weapon once MaxSniperKills is reached
	DestroyWeapon = GetConVarBool(g_CvarDestroyWeapon);
		
	decl String:buffer[MAX_FILE_LEN];
	
	if (strcmp(g_soundName, ""))
	{
		PrecacheSound(g_soundName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}	
	PrecacheSound(g_soundName, true);

	HookConVarChange(g_CvarSniperReplace, OnConVarChange);
	HookConVarChange(g_CvarMaxSniperKills, OnConVarChange);
	HookConVarChange(g_CvarScoutIsSniper, OnConVarChange);
	HookConVarChange(g_CvarSoundName, OnConVarChange);
	HookConVarChange(g_CvarNotifyAdmin, OnConVarChange);
	HookConVarChange(g_CvarDestroyWeapon, OnConVarChange);
	
	LoadSound(); // Taken from Dr!fter's weapon restrict plugin, uses the same sound
}

public OnMapStart()
{	
	if(HasSound)
		PrecacheSound(RestrictSound, true);
	
	ResetLimits();
}

public OnMapEnd()
{
	ResetLimits();
}

public OnConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == g_CvarSniperReplace)
	{
		g_CvarSniperReplace = FindConVar("sm_SniperRestrict_SniperReplace");
		GetConVarString(g_CvarSniperReplace, g_SniperReplacement, sizeof(g_SniperReplacement));
	}
	else if(cvar == g_CvarMaxSniperKills)
	{
		g_CvarMaxSniperKills = FindConVar("sm_SniperRestrict_MaxSniperKills");
		MaxSniperKills = GetConVarInt(g_CvarMaxSniperKills);
	}
	else if(cvar == g_CvarScoutIsSniper)
	{
		g_CvarScoutIsSniper = FindConVar("sm_SniperRestrict_ScoutIsSniper");
		ScoutIsSniper = GetConVarBool(g_CvarScoutIsSniper);
	}
	else if(cvar == g_CvarSoundName)
	{
		GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	}
	else if(cvar == g_CvarNotifyAdmin)
	{
		g_CvarNotifyAdmin = FindConVar("sm_SniperRestrict_AdminNotify");
		NotifyAdmin = GetConVarBool(g_CvarNotifyAdmin);
	}
	else if(cvar == g_CvarDestroyWeapon)
	{
		g_CvarDestroyWeapon = FindConVar("sm_SniperRestrict_DestroyWeapon");
		DestroyWeapon = GetConVarBool(g_CvarDestroyWeapon);
	}
}

public OnClientPutInServer(client)
{
	CreateTimer(10.0, t_Advertise, client);
	PrintToChat(client, PLUGIN_ANNOUNCE);
}

public Action:t_Advertise(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		Advertise(client);
}

public Action:Event_ItemPickup(Handle:event,const String:name[],bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If player (not bots) has restricted sniper status
	if(!IsFakeClient(player) && SnipersRestricted[player] > 0)
	{
		// Get name (string) of item picked up
		new String:weapon[32];
		GetEventString(event, "item", weapon, sizeof(weapon));
		
		// If item picked up is awp, g3sg1, or sg550
		if(StrEqual(weapon, weaponsg550, false) || StrEqual(weapon, weaponawp, false) || StrEqual(weapon, weapong3sg1, false))
		{
			PrintToChat(player, "\x04[\x03Sniper Restrict\x04] AWPs and AUTOs \x01are restricted for you since you've reached the max kills of %i with them.  You can still use a \x04scout", MaxSniperKills);
			RestrictDropRepay(player, weapon);
			return Plugin_Continue;
		}
		
		// If item picked up is scout
		if(ScoutIsSniper && StrEqual(weapon, weaponscout, false))
		{
			PrintToChat(player, "\x04[\x03Sniper Restrict\x04] Scouts, AWPs and AUTOs \x01are restricted for you since you've reached the max kills of %i with them.", MaxSniperKills);
			RestrictDropRepay(player, weapon);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// If attacker isn't another player
	if(killer == 0)
		return Plugin_Continue;
	
	// If plugin is enabled (>=1) or disabled (0)
	if(!IsFakeClient(killer) && MaxSniperKills >= 1)
	{
		if(ScoutIsSniper && StrEqual(g_SniperReplacement, "weapon_scout", false))
		{			
			// Message admins about error in config file if scout is listed as both a sniper and a replacement
			ErrorMsgToAdmin();
			return Plugin_Continue;
		}
		
		decl String:kname[64]; // For killer
		decl String:wname[64]; // For weapon
		
		// Get killer's player name
		GetClientName(killer, kname, sizeof(kname));
		// Get weapon short name from player_death event (awp, scout - not weapon_awp)
		GetEventString(event, "weapon", wname, sizeof(wname));
		
		// If weapon used was an AWP or an AUTO (SG550 or G3SG1)
		if(StrEqual(wname, weaponsg550, false) || StrEqual(wname, weaponawp, false) || StrEqual(wname, weapong3sg1, false))
			RestrictInform(killer, kname);
		
		// See if scouts are listed as snipers and weapon used was a scout
		if(ScoutIsSniper && StrEqual(wname, weaponscout, false)) // If Scout
			RestrictInform(killer, kname);
	}
	
	// Plugin is not enabled, sm_SniperRestrict_MaxSniperKills set to 0
	return Plugin_Continue;
}

public NoticeToAdmin(const String:playername[])
{
	// Notify admins that a player has reached their Sniper Kill limit (if enabled)
	for (new i = 1; i <= MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
			PrintToChat(i, "\x04[\x03Sniper Restrict\x04] ADMIN MSG\x01 - %s reached their sniper limit", playername);
	}
}

public ErrorMsgToAdmin()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
			PrintToChat(i, "\x04[\x03Sniper Restrict\x04] ERROR ALERT \x01Take a look at the config for Sniper Restrict plugin, it has the scout as a sniper and a replacement.");
	}
}

public RestrictInform(any:killer, const String:kname[])
{
	// Add 1 kill to killer's SniperKills
	SniperKills[killer]++;
	
	// If killer has reached their frag limit with the Sniper weapon
	if(SniperKills[killer] >= MaxSniperKills)
	{
		// Set player has restricted sniper status
		SnipersRestricted[killer] = 1;
		
		new weapon = GetPlayerWeaponSlot(killer, 0);
		
		// Make sure player has a weapon in slot 0 (primary)
		if(weapon != -1)
		{
			// Force drop the weapon in slot 0 (uses gamedata file)
			CS_DropWeapon(killer, weapon, true, true);
			
			if(DestroyWeapon)
			{
				// Set location for teleport
				new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
				
				// Get rid of weapon
				TeleportEntity(weapon, orgin, NULL_VECTOR, NULL_VECTOR);
			}
			
			if(ScoutIsSniper)
			{
				PrintToChat(killer, "\x04[\x03Sniper Restrict\x04]\x01 Scouts, AWPs, and Autos are restricted for you since you've reached the max kills of [%i] with them.", MaxSniperKills);
			}
			else
			{
				PrintToChat(killer, "\x04[\x03Sniper Restrict\x04]\x01 AWPs and Autos are restricted for you since you've reached the max kills of [%i] with them.  You can still use a \x04scout", MaxSniperKills);
			}
			
			if(NotifyAdmin)
			{
				NoticeToAdmin(kname);
			}
			
			if(StrEqual(g_SniperReplacement, "none", false))
			{
				return;// Plugin_Continue;
			}
			else
			{
				// Allow a 0.1 buffer to give replacement weapon
				CreateTimer(0.1, t_GiveReplacementWeapon, killer);
			}		
		}
	}
	else
	{
		PrintToConsole(killer, "[Sniper Restrict] You have [%i] out of [%i] allowed sniper kills", SniperKills[killer], MaxSniperKills);
	}
}

public RestrictDropRepay(any:client, const String:weapon[])
{
	// Play restricted weapon sound
	if (strcmp(g_soundName, ""))
	{
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_soundName, vec, client, SNDLEVEL_RAIDSIREN);
	}
	
	new weapon2 = GetPlayerWeaponSlot(client, 0);
	
	// Make sure player has a weapon in slot 0 (primary)
	if(weapon2 != -1)
	{
		// Set location for teleport
		new Float:orgin[3] = {-10000.0, -10000.0, -10000.0};
		
		// Force drop the weapon in slot 0 (uses gamedata file)
		CS_DropWeapon(client, weapon2, true, true);
		
		// Get rid of weapon so player doesn't go ino infinite loop of pickup/drop
		TeleportEntity(weapon2, orgin, NULL_VECTOR, NULL_VECTOR);
	}
	
	if(GetEntProp(client, Prop_Send, "m_bInBuyZone") == 1)
	{
		// Set refund amount based on weapon
		if(StrEqual(weapon, weaponsg550, false)) r_amount = 4200;
		else if(StrEqual(weapon, weaponawp, false)) r_amount = 4750;
		else if(StrEqual(weapon, weapong3sg1, false)) r_amount = 5000;
		else if(StrEqual(weapon, weaponscout, false)) r_amount = 2750;
		
		// Refund purchase of restricted weapon
		new val = GetEntProp(client, Prop_Send, "m_iAccount");
		SetEntProp(client, Prop_Send, "m_iAccount", val + r_amount);
	}
}

public Action:t_GiveReplacementWeapon(Handle:timer, any:killer)
{
	// Equip player with replacement weapon
	if(IsClientInGame(killer))
	{
		GivePlayerItem(killer, g_SniperReplacement);
	}
}

public OnClientDisconnect(client)
{
	// Reset the player's sniper restriction status
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		SniperKills[client] = 0;
		SnipersRestricted[client] = 0;
	}
}

public Advertise(client)
{	
	// If MaxSniperKills is 0, then plugin is considered disabled
	if(!IsFakeClient(client) && MaxSniperKills >= 1)
	{		
		if(ScoutIsSniper)
		{
			if(StrEqual(g_SniperReplacement, "none", false))
			{
				Client_PrintKeyHintText(client, "%s\n\nWeapons grouped as Snipers - [Scout, AWP, G3SG1, & SG550]\nAllowed Sniper Kills: [%i]\nReplacement weapon: [NONE]\n\nYou have [%i] sniper kills.", PLUGIN_ANNOUNCE2, MaxSniperKills, SniperKills[client]);
			}
			else
			{
				Client_PrintKeyHintText(client, "%s\n\nWeapons grouped as Snipers - [Scout, AWP, G3SG1, & SG550]\nAllowed Sniper Kills: [%i]\nReplacement weapon: [%s]\n\nYou have [%i] sniper kills.", PLUGIN_ANNOUNCE2, MaxSniperKills, g_SniperReplacement, SniperKills[client]);
			}
			PrintToChat(client, "\x04[\x03Sniper Restrict\x04]\x01 This server allows [\x04%i\x01] sniper kills with the following weapons before they are restricted - \x04[\x03Scout - AWP - G3SG1 - SG550\x04]", MaxSniperKills);
		}
		else
		{
			if(StrEqual(g_SniperReplacement, "none", false))
			{
				Client_PrintKeyHintText(client, "%s\n\nWeapons grouped as Snipers - [AWP, G3SG1, & SG550]\nAllowed Sniper Kills: [%i]\nReplacement weapon: [NONE]\n\nYou have [%i] sniper kills.", PLUGIN_ANNOUNCE2, MaxSniperKills, SniperKills[client]);
			}
			else
			{
				Client_PrintKeyHintText(client, "%s\n\nWeapons grouped as Snipers - [AWP, G3SG1, & SG550]\nAllowed Sniper Kills: [%i]\nReplacement weapon: [%s]\n\nYou have [%i] sniper kills.", PLUGIN_ANNOUNCE2, MaxSniperKills, g_SniperReplacement, SniperKills[client]);
			}
			PrintToChat(client, "\x04[\x03Sniper Restrict\x04]\x01 This server allows [\x04%i\x01] sniper kills with the following weapons before they are restricted - \x04[\x03AWP - G3SG1 - SG550\x04]", MaxSniperKills);
		}		
	}
}

public Action:Command_Snipers(client, args)
{
	// When someone types !snipers
	decl String:text[192], String:command[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	if(strcmp(text[startidx], "!snipers", false) == 0 || strcmp(text[startidx], "/snipers", false) == 0)
	{
		Advertise(client);
	}
	return Plugin_Continue;
}

ResetLimits()
{
	new maxclients = GetMaxClients();
	
	// Reset the Sniper Restrictions for clients
	for (new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SniperKills[i] = 0;
			SnipersRestricted[i] = 0;
		}
	}
}

LoadSound() // using the exact same as weapon_restrict.smx by Dr!fter
{
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