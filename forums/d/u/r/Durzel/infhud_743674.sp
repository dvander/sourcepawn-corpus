/*
 * Infected HUD
 * by Darren "Durzel" Coleman
 * daz@superficial.net
 *
 * Visit http://forums.alliedmods.net/showthread.php?t=83279 for latest version
 */

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0.4c"
#define DEBUG 0
#define TEAM_INFECTED 3
 
new respawnDelay[MAXPLAYERS+1]; 			// Used to store individual player respawn delays after death
new hudDisabled[MAXPLAYERS+1];				// Stores the client preference for whether HUD is shown
new clientGreeted[MAXPLAYERS+1]; 			// Stores whether or not client has been shown the mod commands/announce
new zombieHP[4];					// Stores special infected max HP
new Handle:cvarZombieHP[4];				// Array of handles to the 4 cvars we have to hook to monitor HP changes
new Handle:cvarVSCheck;					// Handle that hooks the VS mode cvar (director_no_human_zombies)
new isTankOnFire		= false; 		// Used to store whether tank is on fire
new burningTankTimeLeft		= 0; 			// Stores number of seconds Tank has left before he dies
new roundInProgress 		= false;		// Flag that marks whether or not a round is currently in progress
new Handle:infHUDTimer 		= INVALID_HANDLE;	// The main HUD refresh timer
new Handle:respawnTimer 	= INVALID_HANDLE;	// Respawn countdown timer
new Handle:doomedTankTimer 	= INVALID_HANDLE;	// "Tank on Fire" countdown timer
new Handle:delayedDmgTimer 	= INVALID_HANDLE;	// Delayed damage update timer
new Handle:pInfHUD 		= INVALID_HANDLE;	// The panel shown to all infected users
new Handle:usrHUDPref 		= INVALID_HANDLE;	// Stores the client HUD preferences persistently

// Console commands
new Handle:cvarInfHUD		= INVALID_HANDLE;
new Handle:cvarAnnounce 	= INVALID_HANDLE;
new Handle:cvarHUDStartOn	= INVALID_HANDLE;
new Handle:cvarMaxNameLen	= INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "L4D Infected HUD",
	author = "Darren 'Durzel' Coleman <daz@superficial.net>",
	description = "Shows a enhanced team status HUD to players on the Infected team, lets player Tank know how long they have left when on fire",
	version = PLUGIN_VERSION,
	url = "http://www.superficial.net/"
};

public OnPluginStart()
{
	// Sanity check - if we are not running on a VS server then stop the plugin, inform the admin and anyone
	// currently connected (as applicable) when plugin is loaded.
	cvarVSCheck = FindConVar("director_no_human_zombies");
	if (cvarVSCheck != INVALID_HANDLE) {
		// Unfortunately we can't rely on the value of director_no_human_zombies when a server starts up (i.e. when this code is ran)
		// because the game engine automatically sets it depending on the map that is loaded.  We *could* check the name of the map
		// being loaded but that's not exactly very elegant because a) the plugin could be loaded when there is no map running at all and 
		// b) relying on "_vs_" being in a map is a terrible kludge that will break if/when we get community maps, therefore we *have* to
		// work around the foibles of the director_no_human_zombies cvar.  Instead, we hook it and do our main initialisation when we detect 
		// it has been changed.
		HookConVarChange(cvarVSCheck, cvarGameModeChanged);

		// ..an exception to this is when the plugin is loaded when the game is already versus (this can't happen on a fresh server startup) 
		// and round is already in progress (e.g. admin loaded plugin manually midgame).  If this is the case we can initialise here.
		if (roundInProgress && GetConVarInt(cvarVSCheck) == 0) {
			HookGameEvents(Bool:true);
			if (infHUDTimer == INVALID_HANDLE) {
				infHUDTimer = CreateTimer(5.0, showInfHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	} else {
		// Can't find versus cvar?  Possibly not even running Left 4 Dead (another game/mod?)
		LogError("Infected HUD v%s plugin stopped - this plugin is for Left 4 Dead only.", PLUGIN_VERSION);
		SetFailState("[infhud] Infected HUD v%s plugin stopped - this plugin is for Left 4 Dead only.", PLUGIN_VERSION);
	}

	// Hook "say" so clients can toggle HUD on/off for themselves
	RegConsoleCmd("say", Command_Say);

	// ----- Plugin cvars ------------------------
	CreateConVar("infhud_version", PLUGIN_VERSION, "L4D Infected HUD version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarInfHUD = CreateConVar("infhud_enable", "1", "Toggle whether L4D Infected HUD plugin is active or not.");
	cvarAnnounce = CreateConVar("infhud_announce", "1", "Toggle whether L4D Infected HUD plugin announces itself to clients.");
	cvarHUDStartOn = CreateConVar("infhud_starton", "1", "Toggles whether HUD defaults to being enabled or disabled.");
	cvarMaxNameLen = CreateConVar("infhud_maxnamelen", "15", "Maximum number of characters displayed for a players name on the HUD, anything longer is truncated.");

	// ----- Zombie HP hooks ---------------------	
	// We store the special infected max HP values in an array and then hook the cvars used to modify them
	// just in case another plugin (or an admin) decides to modify them.  Whilst unlikely if we don't do
	// this then the HP percentages on the HUD will end up screwy, and since it's a one-time initialisation
	// when the plugin loads there's a trivial overhead.
	cvarZombieHP[0] = FindConVar("z_hunter_health");
	cvarZombieHP[1] = FindConVar("z_gas_health");
	cvarZombieHP[2] = FindConVar("z_exploding_health");
	cvarZombieHP[3] = FindConVar("z_tank_health");

	zombieHP[0] = 250;	// Hunter default HP
	if (cvarZombieHP[0] != INVALID_HANDLE) {
		zombieHP[0] = GetConVarInt(cvarZombieHP[0]); 
		HookConVarChange(cvarZombieHP[0], cvarZombieHPChanged);
	}
	zombieHP[1] = 250;	// Smoker default HP
	if (cvarZombieHP[1] != INVALID_HANDLE) {
		zombieHP[1] = GetConVarInt(cvarZombieHP[1]); 
		HookConVarChange(cvarZombieHP[1], cvarZombieHPChanged);
	}
	zombieHP[2] = 50;	// Boomer default HP
	if (cvarZombieHP[2] != INVALID_HANDLE) {
		zombieHP[2] = GetConVarInt(cvarZombieHP[2]);
		HookConVarChange(cvarZombieHP[2], cvarZombieHPChanged);
	}
	zombieHP[3] = 6000;	// Tank default HP
	if (cvarZombieHP[3] != INVALID_HANDLE) {
		zombieHP[3] = RoundToFloor(GetConVarInt(cvarZombieHP[3]) * 1.5);	// Tank health is multiplied by 1.5x in VS	
		HookConVarChange(cvarZombieHP[3], cvarZombieHPChanged);
	}

	// Create persistent storage for client HUD preferences 
	usrHUDPref = CreateTrie();

#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] \x03Infected HUD v%s\x01 started.", GetGameTime(), PLUGIN_VERSION);
#endif	
}

public OnPluginEnd()
{
	// Destroy the persistent storage for client HUD preferences
	if (usrHUDPref != INVALID_HANDLE) {
		CloseHandle(usrHUDPref);
	}

#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] \x03Infected HUD\x01 stopped.", GetGameTime());
#endif
}

public HookGameEvents(Bool:doHook) 
{
#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] %s game events needed by plugin.", GetGameTime(), ((doHook) ? "Hooking" : "Unhooking"));
#endif
	if (doHook) {
		HookEvent("player_death", evtInfectedDeath);
		HookEvent("player_spawn", evtInfectedSpawn);
		HookEvent("player_hurt", evtInfectedHurt);
		HookEvent("player_team", evtTeamSwitch);
		HookEvent("round_start", evtRoundStart);
		HookEvent("round_end", evtRoundEnd);
		HookEvent("ghost_spawn_time", evtInfectedWaitSpawn);
	} else {
		UnhookEvent("player_death", evtInfectedDeath);
		UnhookEvent("player_spawn", evtInfectedSpawn);
		UnhookEvent("player_hurt", evtInfectedHurt);
		UnhookEvent("player_team", evtTeamSwitch);
		UnhookEvent("round_start", evtRoundStart);
		UnhookEvent("round_end", evtRoundEnd);
		UnhookEvent("ghost_spawn_time", evtInfectedWaitSpawn);
	}
}

public OnClientPutInServer(client) 
{
	decl String:clientSteamID[32];
	new foundKey, doHideHUD;

	GetClientAuthString(client, clientSteamID, 32);
	
	// Default server behaviour in the absence of any other info is to respect the global "show HUD" setting
	hudDisabled[client] = (GetConVarBool(cvarHUDStartOn) ? 0 : 1);

	// Try and find their HUD visibility preference
	foundKey = GetTrieValue(Handle:usrHUDPref, clientSteamID, doHideHUD);
#if DEBUG
	if (!foundKey) {
		PrintToChat(client, "\x01\x04[infhud]\x01 [%f] No HUD preference found for you (default)", GetGameTime());
	} else if (doHideHUD == 1) {
		PrintToChat(client, "\x01\x04[infhud]\x01 [%f] Your HUD preference is 'HUD disabled'", GetGameTime());
	} else {
		// Because we remove the value from the trie when someone elects to view the HUD (the default behaviour)
		// this code should never get executed, but stranger things can happen...
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] Found 'HUD visible' preference for client %i!", GetGameTime(), client);
	}
#endif	
	// If we have a stored setting for this user override the server-wide default
	if (foundKey) {
		hudDisabled[client] = (doHideHUD) ? 1 : 0;
	}
}

public OnClientDisconnect(client)
{
	// When a client disconnects we need to restore their HUD preferences to default for when 
	// a new client joins and fill the space.
	hudDisabled[client] = (GetConVarBool(cvarHUDStartOn) ? 0 : 1);
	clientGreeted[client] = 0;
}

public cvarGameModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Handles the game mode cvar (director_no_human_zombies) being changed.  This could be changed automagically by 
	// the server itself (when a versus map is loaded), or by an admin.  Either way we need to handle it because there
	// is no point running any of this plugin code if we're not playing VS.
	if (GetConVarInt(cvarVSCheck) == 1) {
		// ARGH! CO-OP mode!
		// Unhook events, shut down active timer(s)
		HookGameEvents(Bool:false);
		roundInProgress = false;
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] Gamemode detected as/changed to CO-OP, plugin going idle.", GetGameTime());
	} else {
		HookGameEvents(Bool:true);
		// Because round_start may fire before the cvar is changed we need to check to see whether the main HUD timer
		// is already running and if it isn't we start it up.  We will assume the round has already started until told otherwise.
		roundInProgress = true;
		if (infHUDTimer == INVALID_HANDLE) {
			infHUDTimer = CreateTimer(5.0, showInfHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] Gamemode detected as/changed to VERSUS, plugin will activate when round restarts.", GetGameTime());
	}
}

public cvarZombieHPChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Handle a sysadmin modifying the special infected max HP cvars
	new String:cvarStr[255];
	GetConVarName(convar, cvarStr, sizeof(cvarStr));

#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] cvarZombieHPChanged(): Infected HP cvar '%s' changed from '%s' to '%s'", GetGameTime(), cvarStr, oldValue, newValue);
#endif

	if (StrEqual(cvarStr, "z_hunter_health", false)) {
		zombieHP[0] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_gas_health", false)) {
		zombieHP[1] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_exploding_health", false)) {
		zombieHP[2] = StringToInt(newValue);
	} else if (StrEqual(cvarStr, "z_tank_health", false)) {
		zombieHP[3] = RoundToFloor(StringToInt(newValue) * 1.5);	// Tank health is multiplied by 1.5x in VS
	}
}

public Action:Command_Say(client, args)
{
	new String:clientSteamID[32];
	new String:text[192];

	if (client == 0) return Plugin_Handled;

	GetCmdArgString(text, sizeof(text));
	GetClientAuthString(client, clientSteamID, 32);

	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}


	if (StrEqual(text[startidx], "!infhud")) {
		if (GetConVarBool(cvarInfHUD)) {
			// Note: We have to swap the logic of storing a users preference if the server-wide "HUD starts on" variable
			// has been changed.  If the server admin has decided to disable the HUD unless people choose to view it, then 
			// we have to store the "HUD enabled" user preference, and vice versa.
			if (hudDisabled[client] == 0) {
				PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD DISABLED - say !infhud to re-enable.");
				if (GetConVarBool(cvarHUDStartOn)) {
					SetTrieValue(usrHUDPref, clientSteamID, 1);
				} else {
					RemoveFromTrie(usrHUDPref, clientSteamID);
				}
				hudDisabled[client] = 1;
			} else {
				PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD ENABLED - say !infhud to disable.");
				if (GetConVarBool(cvarHUDStartOn)) {
					RemoveFromTrie(usrHUDPref, clientSteamID);
				} else {
					SetTrieValue(usrHUDPref, clientSteamID, 0);
				}
				hudDisabled[client] = 0;
			}
		} else {
			// Server admin has disabled Infected HUD server-wide
			PrintToChat(client, "\x01\x04[infhud]\x01 Infected HUD is currently DISABLED on this server for all players.");
		}	
		return Plugin_Handled;
	} 
	return Plugin_Continue;
}

public Action:evtRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Show the HUD to the connected clients.
	roundInProgress = true;
	infHUDTimer = CreateTimer(5.0, showInfHUD, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);		
}

public Action:evtRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundInProgress = false;
	
	// Zero all respawn times ready for the next round
	for (new i = 1; i <= GetMaxClients(); i++) {
		respawnDelay[i] = 0;
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			// Show welcoming instruction message to client
			PrintToChat(client, "\x01\x04[infhud]\x01 This server runs \x03Infected HUD v%s\x01 - say !infhud to toggle HUD on/off", PLUGIN_VERSION);

			// This client now knows about the mod, don't tell them again for the rest of the game.
			clientGreeted[client] = 1;
		}
	}
}

public Action:monitorRespawn(Handle:timer)
{
	// Counts down any active respawn timers
	new i, foundActiveRTmr = false;
	
	// If round has ended then end timer gracefully
	if (!roundInProgress) {
		respawnTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	for (i = 1; i <= GetMaxClients(); i++) {
		if (respawnDelay[i] > 0) {
			respawnDelay[i]--;
			foundActiveRTmr = true;
		}
	}

	if (!foundActiveRTmr && (respawnTimer != INVALID_HANDLE)) {
		// Being a ghost doesn't trigger an event which we can hook (player_spawn fires when player actually spawns),
		// so as a nasty kludge after the respawn timer expires for at least one player we set a timer for 1 second 
		// to update the HUD so it says "SPAWNING"
		if (delayedDmgTimer == INVALID_HANDLE) {
			delayedDmgTimer = CreateTimer(1.0, delayedDmgUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
		}

		// We didn't decrement any of the player respawn times, therefore we don't 
		// need to run this timer anymore.
		respawnTimer = INVALID_HANDLE;
		return Plugin_Stop;
	} else {
		if (doomedTankTimer == INVALID_HANDLE) ShowInfectedHUD(2);
	}
	return Plugin_Continue;
}

public Action:doomedTankCountdown(Handle:timer)
{
	// If round has ended then end timer gracefully
	if (!roundInProgress) {
		doomedTankTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	// Counts down the number of seconds before the Tank will die automatically
	// from fire damage (if not before from gun damage)
	if (isTankOnFire) {
		if (--burningTankTimeLeft <= 0) {
			// Tank is dead :(
#if DEBUG
			PrintToChatAll("\x01\x04[infhud]\x01 [%f] Tank died automatically from fire timer expiry.", GetGameTime());
#endif
			isTankOnFire = false;
			doomedTankTimer = INVALID_HANDLE;
			return Plugin_Stop;
		} else {
			// This is almost the same as the respawnTimer code (which only updates the HUD in one of the two 1-second update
			// timer functions, however there may well be an instance in the game where both the Tank is on fire, and people are
			// respawning - therefore we need to make sure *at least one* of the 1-second timers updates the HUD, so we choose this
			// one (as it's rarer in game and therefore more optimal to do two extra code checks to achieve the same result).
			if (respawnTimer == INVALID_HANDLE || (doomedTankTimer != INVALID_HANDLE && respawnTimer != INVALID_HANDLE)) {
				ShowInfectedHUD(4);
			}
		}			
	} else {
		// If tank isn't on fire we shouldn't be running this function at all.
		doomedTankTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:delayedDmgUpdate(Handle:timer) 
{
	delayedDmgTimer = INVALID_HANDLE;
	ShowInfectedHUD(3);
	return Plugin_Handled;
}


public queueHUDUpdate(src)
{
	// queueHUDUpdate basically ensures that we're not constantly refreshing the HUD when there are one or more
	// timers active.  For example, if we have a respawn countdown timer (which is likely at any given time) then
	// there is no need to refresh 

	// Don't bother with infected HUD updates if the round has ended.
	if (!roundInProgress) return;

	if (respawnTimer == INVALID_HANDLE && doomedTankTimer == INVALID_HANDLE) {
		ShowInfectedHUD(src);
#if DEBUG
	} else {
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] queueHUDUpdate(): Instant HUD update ignored, 1-sec timer active.", GetGameTime());
#endif
	}	
}

public Action:showInfHUD(Handle:timer) 
{
	if (roundInProgress) {
		ShowInfectedHUD(1);
		return Plugin_Continue;
	} else {
		infHUDTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}		
}

public Menu_InfHUDPanel(Handle:menu, MenuAction:action, param1, param2) { return; }

public ShowInfectedHUD(src)
{
	if (!GetConVarBool(cvarInfHUD) || IsVoteInProgress()) {
		return;
	}

#if DEBUG
	decl String:calledFunc[255];
	switch (src) {
		case 1: strcopy(calledFunc, sizeof(calledFunc), "showInfHUD");
		case 2: strcopy(calledFunc, sizeof(calledFunc), "monitorRespawn");
		case 3: strcopy(calledFunc, sizeof(calledFunc), "delayedDmgUpdate");
		case 4: strcopy(calledFunc, sizeof(calledFunc), "doomedTankCountdown");
		case 10: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - client join");
		case 11: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - team switch");
		case 12: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - spawn");
		case 13: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - death");
		case 14: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - menu closed");
		case 15: strcopy(calledFunc, sizeof(calledFunc), "evtRoundEnd");
		default: strcopy(calledFunc, sizeof(calledFunc), "UNKNOWN");
	}

	PrintToChatAll("\x01\x04[infhud]\x01 [%f] ShowInfectedHUD() called by [\x04%i\x01] '\x03%s\x01'", GetGameTime(), src, calledFunc);
#endif 

	new i, team, ghostOffset, maxNameLength;
	new playerIsAlive, playerIsGhost;
 	decl String:iName[MAX_NAME_LENGTH+1];
	decl String:iClass[100];
	new iHP;

	decl String:lineBuf[100];
	decl String:iStatus[15];

	// Display information panel to infected clients
	pInfHUD = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	//SetPanelTitle(pInfHUD, "INFECTED TEAM STATUS:");
	DrawPanelItem(pInfHUD, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(pInfHUD, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelText(pInfHUD, "INFECTED TEAM STATUS:");

	if (roundInProgress) {
		// Offset to detect whether player is a ghost or not
		ghostOffset = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
			
		// Loop through infected players and show their status
		for (i = 1; i <= GetMaxClients(); i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)) {
				if (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None) {
					team = GetClientTeam(i);
					if (team == TEAM_INFECTED) {
						GetClientName(i, iName, sizeof(iName));
						maxNameLength = GetConVarInt(cvarMaxNameLen);
						// Truncate name if it exceeds server name length restriction
						if (strlen(iName) > maxNameLength && (maxNameLength >= 5 && maxNameLength < MAX_NAME_LENGTH)) {
							GetClientName(i, iName, maxNameLength+1);
						}

						// Work out what they're playing as
						GetClientModel(i, iClass, sizeof(iClass));
						if (StrContains(iClass, "hunter", false) != -1) {
							strcopy(iClass, sizeof(iClass), "Hunter - ");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[0]) * 100);
						} else if (StrContains(iClass, "smoker", false) != -1) {
							strcopy(iClass, sizeof(iClass), "Smoker - ");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[1]) * 100);
						} else if (StrContains(iClass, "boomer", false) != -1) {
							strcopy(iClass, sizeof(iClass), "Boomer - ");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[2]) * 100);
						} else if (StrContains(iClass, "hulk", false) != -1) {
							strcopy(iClass, sizeof(iClass), "Tank - ");
							iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[3]) * 100);	
						}

						// Work out what the client is currently doing
						playerIsAlive = IsPlayerAlive(i);
						playerIsGhost = GetEntData(i,ghostOffset,1)
						if (playerIsAlive) {
							// Check to see if they are a ghost or not
							if (playerIsGhost == 1) {
								strcopy(iStatus, sizeof(iStatus), "SPAWNING");
							} else {
								strcopy(iStatus, sizeof(iStatus), "ALIVE");
							}
						} else {
							if (respawnDelay[i] > 0) {
								Format(iStatus, sizeof(iStatus), "WAITING (%i)", respawnDelay[i]);
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
							} else {
								Format(iStatus, sizeof(iStatus), "DEAD");
								strcopy(iClass, sizeof(iClass), "");
								// As a failsafe if they're dead/waiting set HP to 0
								iHP = 0;
							}
						}

						// Special case - if player is Tank and on fire, show the countdown
						if (StrContains(iClass, "Tank", false) != -1 && isTankOnFire && playerIsAlive) {
							Format(iStatus, sizeof(iStatus), "ON FIRE (%i)", burningTankTimeLeft);
						}
							
						// If maxNameLength is 0 don't show the name at all
						if (maxNameLength == 0) {
							Format(lineBuf, sizeof(lineBuf), "[%i%%] %s%s", iHP, iClass, iStatus);
						} else {
							Format(lineBuf, sizeof(lineBuf), "[%i%%] %s - %s%s", iHP, iName, iClass, iStatus);
						}

						DrawPanelItem(pInfHUD, lineBuf);
					}
#if DEBUG
				} else {
					PrintToChat(i, "x01\x04[infhud]\x01 [%f] Not showing infected HUD as vote/menu (%i) is active", GetClientMenu(i), GetGameTime());
#endif
				}
			}
		}
	}

	// Output the current team status to all infected clients
	// Technically the below is a bit of a kludge but we can't be 100% sure that a client status doesn't change
	// between building the panel and displaying it.
	for (i = 1; i <= GetMaxClients(); i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)) {
			team = GetClientTeam(i);
			if (team == TEAM_INFECTED && hudDisabled[i] == 0 && (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None)) {	
				SendPanelToClient(pInfHUD, i, Menu_InfHUDPanel, 5);
			}
		}
	}

	CloseHandle(pInfHUD);
}


public Action:evtTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check to see if player joined infected team and if so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			queueHUDUpdate(11);
		} else {
			// If player teamswitched to survivor, remove the HUD from their screen
			// immediately to stop them getting an advantage
			if (GetClientMenu(client) == MenuSource_RawPanel) {
				CancelClientMenu(client);
			}
		} 
	}
}

public Action:evtInfectedSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Infected player spawned, so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && !IsFakeClient(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			queueHUDUpdate(12); 
	
			// If player joins server and doesn't have to wait to spawn they might not see the announce
			// until they next die (and have to wait).  As a fallback we check when they spawn if they've 
			// already seen it or not.
			if (clientGreeted[client] == 0 && GetConVarBool(cvarAnnounce)) {		
				CreateTimer(3.0, TimerAnnounce, client);	
			}
		}
	}
}

public Action:evtInfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Infected player died, so refresh the HUD
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:class[100];

	if (client && !IsFakeClient(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			// If player is tank and dies before the fire would've killed them, kill the fire timer
			GetClientModel(client, class, sizeof(class));
			if (StrContains(class, "hulk", false) != -1 && isTankOnFire && (doomedTankTimer != INVALID_HANDLE)) {
#if DEBUG
				PrintToChatAll("\x01\x04[infhud]\x01 [%f] Tank died naturally before fire timer expired.", GetGameTime());
#endif
				isTankOnFire = false;
				KillTimer(doomedTankTimer);
				doomedTankTimer = INVALID_HANDLE;  
			}

			queueHUDUpdate(13);
		}
	}
}

public Action:evtInfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The life of a regular special infected is pretty transient, they won't take many shots before they 
	// are dead (unlike the survivors) so we can afford to refresh the HUD reasonably quickly when they take damage.
	// The exception to this is the Tank - with 5000 health the survivors could be shooting constantly at it 
	// resulting in constant HUD refreshes which is not efficient.  So, we check to see if the entity being 
	// shot is a Tank or not and adjust the non-repeating timer accordingly.

	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;

	new mFlagsOffset;

	decl String:class[100];
	decl Handle:fireTankExpiry;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && !IsFakeClient(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			GetClientModel(client, class, sizeof(class));
			if (StrContains(class, "hulk", false) != -1) {

				// If player is a tank and is on fire, we start the 
				// 30-second guaranteed death timer and let his fellow Infected guys know.
				
				mFlagsOffset = FindSendPropOffs("CTerrorPlayer", "m_fFlags");
				if ((GetEntData(client, mFlagsOffset) & FL_ONFIRE) && (doomedTankTimer == INVALID_HANDLE) && IsPlayerAlive(client)) {
					isTankOnFire = true;
					fireTankExpiry = FindConVar("tank_burn_duration_vs");
					burningTankTimeLeft = (fireTankExpiry != INVALID_HANDLE) ? GetConVarInt(fireTankExpiry) : 30;
					doomedTankTimer = CreateTimer(1.0, doomedTankCountdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);										
				}		
			}

			// If we only have the 5 second timer running then we do a delayed damage update
			// (in reality with 4 players playing it's unlikely all of them will be alive at the same time
			// so we will probably have at least one faster timer running)
			if (delayedDmgTimer == INVALID_HANDLE && respawnTimer == INVALID_HANDLE && doomedTankTimer == INVALID_HANDLE) {
				delayedDmgTimer = CreateTimer(2.0, delayedDmgUpdate, _, TIMER_FLAG_NO_MAPCHANGE);
			} 

		}
	}
}

public Action:evtInfectedWaitSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;

	// Store this players respawn time in an array so we can present it to other clients
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new timetowait = GetEventInt(event, "spawntime");

	if (client && !IsFakeClient(client)) {
		respawnDelay[client] = timetowait;
		// Only start timer if we don't have one already going.
		if (respawnTimer == INVALID_HANDLE) {
			// Note: If we have to start a new timer then there will be a 1 second delay before it starts, so 
			// subtract 1 from the pending spawn time
			respawnDelay[client] = (timetowait-1);
			respawnTimer = CreateTimer(1.0, monitorRespawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}

		// Send mod details/commands to the client, unless they have seen the announce already.
		// Note: We can't do this in OnClientPutInGame because the client may not be on the infected team
		// when they connect, and we can't put it in evtTeamSwitch because it won't register if the client
		// joins the server already on the Infected team.
		if (clientGreeted[client] == 0 && GetConVarBool(cvarAnnounce)) {
			CreateTimer(8.0, TimerAnnounce, client);	
		}
	}
}