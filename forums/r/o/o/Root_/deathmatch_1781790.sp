#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Deathmatch",
	author = "|NA| Snip3r",
	description = "Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc).",
	version = VERSION,
	url = "http://www.noammo.co.uk"
};

enum Teams
{
	TeamNone,
	TeamSpectator,
	TeamT,
	TeamCT
};

enum Slots
{
	SlotPrimary,
	SlotSecondary,
	SlotKnife,
	SlotGrenade,
	SlotC4,
	SlotNone
};

#define MAX_SPAWNS 200

// Native console variables
new Handle:mp_startmoney;
new Handle:mp_playercashawards;
new Handle:mp_teamcashawards;
// Native backup variables
new backupStartMoney;
new backupPlayerCashAwards;
new backupTeamCashAwards;
// Console variables
new Handle:cvar_enabled;
new Handle:cvar_removeObjectives;
new Handle:cvar_respawnTime;
new Handle:cvar_lineOfSightSpawning;
new Handle:cvar_lineOfSightAttempts;
new Handle:cvar_spawnDistanceFromEnemies;
new Handle:cvar_spawnProtectionTime;
new Handle:cvar_removeWeapons;
new Handle:cvar_replenishAmmo;
new Handle:cvar_HPPerKill;
new Handle:cvar_HPPerHeadshotKill;
new Handle:cvar_displayHPMessages;
// Variables
new bool:enabled = false;
new bool:removeObjectives;
new Float:respawnTime;
new bool:lineOfSightSpawning;
new lineOfSightAttempts;
new Float:spawnDistanceFromEnemies;
new Float:spawnProtectionTime;
new bool:removeWeapons;
new bool:replenishAmmo;
new HPPerKill;
new HPPerHeadshotKill;
new bool:displayHPMessages;
new bool:roundEnded = false;
new bool:c4Removed = false;
new defaultColour[4] = { 255, 255, 255, 255 };
new tColour[4] = { 255, 0, 0, 200 };
new ctColour[4] = { 0, 0, 255, 200 };
new spawnPointCount = 0;
new Float:spawnPositions[MAX_SPAWNS][3];
new Float:spawnAngles[MAX_SPAWNS][3];
new bool:spawnPointOccupied[MAX_SPAWNS] = {false, ...};
new Float:eyeOffset[3] = { 0.0, 0.0, 64.0 }; // CSGO offset.
new Float:spawnPointOffset[3] = { 0.0, 0.0, 20.0 };
new bool:inEditMode = false;
// Offsets
new ownerOffset;
new armourOffset;
new helmetOffset;
new activeWeaponOffset;
new ammoTypeOffset;
new ammoOffset;
// Menus
new Handle:optionsMenu1 = INVALID_HANDLE;
new Handle:optionsMenu2 = INVALID_HANDLE;
new Handle:primaryMenu = INVALID_HANDLE;
new Handle:secondaryMenu = INVALID_HANDLE;
// Player settings
new lastEditorSpawnPoint[MAXPLAYERS + 1] = { -1, ... };
new String:primaryWeapon[MAXPLAYERS + 1][20];
new String:secondaryWeapon[MAXPLAYERS + 1][20];
new infoMessageCount[MAXPLAYERS + 1] = { 3, ... };
new bool:firstWeaponSelection[MAXPLAYERS + 1] = { true, ... };
new bool:weaponsGivenThisRound[MAXPLAYERS + 1] = { false, ... };
new bool:newWeaponsSelected[MAXPLAYERS + 1] = { false, ... };
new bool:rememberChoice[MAXPLAYERS + 1] = { false, ... };
new bool:playerMoved[MAXPLAYERS + 1] = { false, ... };
// Content
new glowSprite;
// Spawn stats
new numberOfPlayerSpawns = 0;
new losSearchAttempts = 0;
new losSearchSuccesses = 0;
new losSearchFailures = 0;
new distanceSearchAttempts = 0;
new distanceSearchSuccesses = 0;
new distanceSearchFailures = 0;
new spawnPointSearchFailures = 0;

public OnPluginStart()
{
	// Create spawns directory if necessary.
	decl String:spawnsPath[] = "cfg/deathmatch/spawns";
	if (!DirExists(spawnsPath))
		CreateDirectory(spawnsPath, 711);
	// Find offsets
	ownerOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	armourOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	helmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	activeWeaponOffset = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
	ammoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	ammoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	// Create menus
	optionsMenu1 = BuildOptionsMenu(true);
	optionsMenu2 = BuildOptionsMenu(false);
	// Retrieve native console variables
	mp_startmoney = FindConVar("mp_startmoney");
	mp_playercashawards = FindConVar("mp_playercashawards");
	mp_teamcashawards = FindConVar("mp_teamcashawards");
	// Retrieve native console variable values
	backupStartMoney = GetConVarInt(mp_startmoney);
	backupPlayerCashAwards = GetConVarInt(mp_playercashawards);
	backupTeamCashAwards = GetConVarInt(mp_teamcashawards);
	// Create console variables
	CreateConVar("na_dm_version", VERSION, "Deathmatch version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("dm_enabled", "1", "Enable deathmatch.");
	cvar_removeObjectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
	cvar_respawnTime = CreateConVar("dm_respawn_time", "2.0", "Respawn time.");
	cvar_lineOfSightSpawning = CreateConVar("dm_los_spawning", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
	cvar_lineOfSightAttempts = CreateConVar("dm_los_attempts", "10", "Maximum number of attempts to find a suitable line of sight spawn point.");
	cvar_spawnDistanceFromEnemies = CreateConVar("dm_spawn_distance", "0.0", "Minimum distance from enemies at which a player can spawn.");
	cvar_spawnProtectionTime = CreateConVar("dm_sp_time", "1.0", "Spawn protection time.");
	cvar_removeWeapons = CreateConVar("dm_remove_weapons", "1", "Remove ground weapons.");
	cvar_replenishAmmo = CreateConVar("dm_replenish_ammo", "1", "Unlimited player ammo.");
	cvar_HPPerKill = CreateConVar("dm_hp_kill", "5", "HP per kill.");
	cvar_HPPerHeadshotKill = CreateConVar("dm_hp_hs", "10", "HP per headshot kill.");
	cvar_displayHPMessages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
	LoadConfig();
	// Admin commands
	RegAdminCmd("dm_spawn_menu", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens the spawn point menu.");
	RegAdminCmd("dm_respawn_all", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all dead players.");
	RegAdminCmd("dm_stats", Command_Stats, ADMFLAG_CHANGEMAP, "Displays spawn statistics.");
	RegAdminCmd("dm_reset_stats", Command_ResetStats, ADMFLAG_CHANGEMAP, "Resets spawn statistics.");
	// Client Commands
	RegConsoleCmd("sm_guns", Command_Guns, "Opens the !guns menu");
	// Event hooks
	HookConVarChange(cvar_enabled, Event_CvarChange);
	HookConVarChange(cvar_removeObjectives, Event_CvarChange);
	HookConVarChange(cvar_respawnTime, Event_CvarChange);
	HookConVarChange(cvar_lineOfSightSpawning, Event_CvarChange);
	HookConVarChange(cvar_lineOfSightAttempts, Event_CvarChange);
	HookConVarChange(cvar_spawnDistanceFromEnemies, Event_CvarChange);
	HookConVarChange(cvar_spawnProtectionTime, Event_CvarChange);
	HookConVarChange(cvar_removeWeapons, Event_CvarChange);
	HookConVarChange(cvar_replenishAmmo, Event_CvarChange);
	HookConVarChange(cvar_HPPerKill, Event_CvarChange);
	HookConVarChange(cvar_HPPerHeadshotKill, Event_CvarChange);
	HookConVarChange(cvar_displayHPMessages, Event_CvarChange);
	RegConsoleCmd("joinclass", Event_JoinClass);
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);
	AddNormalSoundHook(Event_Sound);
	// Create timers
	CreateTimer(0.5, UpdateSpawnPointStatus, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(1.0, RemoveGroundWeapons, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(10.0, GiveAmmo, INVALID_HANDLE, TIMER_REPEAT);
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
		DisableSpawnProtection(INVALID_HANDLE, i);
	SetBuyZones("Enable");
	SetObjectives("Enable");
	// Close handles
	if (optionsMenu1 != INVALID_HANDLE)
	{
		CancelMenu(optionsMenu1);
		CloseHandle(optionsMenu1);
		optionsMenu1 = INVALID_HANDLE;
	}
	if (optionsMenu2 != INVALID_HANDLE)
	{
		CancelMenu(optionsMenu2);
		CloseHandle(optionsMenu2);
		optionsMenu2 = INVALID_HANDLE;
	}
	if (primaryMenu != INVALID_HANDLE)
	{
		CancelMenu(primaryMenu);
		CloseHandle(primaryMenu);
		primaryMenu = INVALID_HANDLE;
	}
	if (secondaryMenu != INVALID_HANDLE)
	{
		CancelMenu(secondaryMenu);
		CloseHandle(secondaryMenu);
		secondaryMenu = INVALID_HANDLE;
	}
}

public OnConfigsExecuted()
{
	UpdateState();
}

public OnMapStart()
{
	// Precache content
	glowSprite = PrecacheModel("sprites/glow01.vmt", true);
	
	for (new i = 1; i <= MaxClients; i++)
		ResetClientSettings(i);
	LoadMapConfig();
	if (spawnPointCount > 0)
	{
		for (new i = 0; i < spawnPointCount; i++)
			spawnPointOccupied[i] = false;
	}
	if (enabled)
	{
		SetBuyZones("Disable");
		if (removeObjectives)
		{
			SetObjectives("Disable");
			RemoveHostages();
		}
	}
}

public OnClientPutInServer(clientIndex)
{
	ResetClientSettings(clientIndex);
}

ResetClientSettings(clientIndex)
{
	lastEditorSpawnPoint[clientIndex] = -1;
	primaryWeapon[clientIndex] = "none";
	secondaryWeapon[clientIndex] = "none";
	infoMessageCount[clientIndex] = 3;
	firstWeaponSelection[clientIndex] = true;
	weaponsGivenThisRound[clientIndex] = false;
	newWeaponsSelected[clientIndex] = false;
	rememberChoice[clientIndex] = false;
	playerMoved[clientIndex] = false;
	// Bot settings
	if (IsClientConnected(clientIndex) && IsFakeClient(clientIndex))
	{
		primaryWeapon[clientIndex] = "random";
		secondaryWeapon[clientIndex] = "random";
		firstWeaponSelection[clientIndex] = false;
		rememberChoice[clientIndex] = true;
	}
}

public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

LoadConfig()
{
	new Handle:keyValues = CreateKeyValues("Deathmatch Config");
	decl String:path[] = "cfg/deathmatch/deathmatch.ini";
	
	if (!FileToKeyValues(keyValues, path))
		SetFailState("The configuration file could not be read.");
	
	decl String:key[25];
	decl String:value[25];
	
	if (!KvJumpToKey(keyValues, "Options"))
		SetFailState("The configuration file is corrupt (\"Options\" section could not be found).");
	
	KvGetString(keyValues, "remove_objectives", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_removeObjectives, value);
	
	KvGetString(keyValues, "respawn_time", value, sizeof(value), "2.0");
	SetConVarString(cvar_respawnTime, value);
	
	KvGetString(keyValues, "line_of_sight_spawning", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_lineOfSightSpawning, value);
	
	KvGetString(keyValues, "line_of_sight_attempts", value, sizeof(value), "10");
	SetConVarString(cvar_lineOfSightAttempts, value);
	
	KvGetString(keyValues, "spawn_distance_from_enemies", value, sizeof(value), "0.0");
	SetConVarString(cvar_spawnDistanceFromEnemies, value);
	
	KvGetString(keyValues, "spawn_protection_time", value, sizeof(value), "1.0");
	SetConVarString(cvar_spawnProtectionTime, value);
	
	KvGetString(keyValues, "remove_weapons", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_removeWeapons, value);
	
	KvGetString(keyValues, "replenish_ammo", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_replenishAmmo, value);
	
	KvGetString(keyValues, "hp_per_kill", value, sizeof(value), "5");
	SetConVarString(cvar_HPPerKill, value);
	
	KvGetString(keyValues, "hp_per_headshot_kill", value, sizeof(value), "10");
	SetConVarString(cvar_HPPerHeadshotKill, value);
	
	KvGetString(keyValues, "display_hp_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_displayHPMessages, value);
	
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Weapons"))
		SetFailState("The configuration file is corrupt (\"Weapons\" section could not be found).");
	
	if (!KvJumpToKey(keyValues, "Primary"))
		SetFailState("The configuration file is corrupt (\"Primary\" section could not be found).");
	
	if (KvGotoFirstSubKey(keyValues, false))
	{
		primaryMenu = CreateMenu(Menu_Primary);
		SetMenuTitle(primaryMenu, "Primary Weapon:");
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			KvGetString(keyValues, NULL_STRING, value, sizeof(value));
			AddMenuItem(primaryMenu, key, value);
		} while (KvGotoNextKey(keyValues, false));
	}
	
	KvGoBack(keyValues);
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Secondary"))
		SetFailState("The configuration file is corrupt (\"Secondary\" section could not be found).");
		
	if (KvGotoFirstSubKey(keyValues, false))
	{
		secondaryMenu = CreateMenu(Menu_Secondary);
		SetMenuTitle(secondaryMenu, "Secondary Weapon:");
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			KvGetString(keyValues, NULL_STRING, value, sizeof(value));
			AddMenuItem(secondaryMenu, key, value);
		} while (KvGotoNextKey(keyValues, false));
	}
	
	CloseHandle(keyValues);
}

UpdateState()
{
	new oldEnabled = enabled;
	
	enabled = GetConVarBool(cvar_enabled);
	removeObjectives = GetConVarBool(cvar_removeObjectives);
	respawnTime = GetConVarFloat(cvar_respawnTime);
	lineOfSightSpawning = GetConVarBool(cvar_lineOfSightSpawning);
	lineOfSightAttempts = GetConVarInt(cvar_lineOfSightAttempts);
	spawnDistanceFromEnemies = GetConVarFloat(cvar_spawnDistanceFromEnemies);
	spawnProtectionTime = GetConVarFloat(cvar_spawnProtectionTime);
	removeWeapons = GetConVarBool(cvar_removeWeapons);
	replenishAmmo = GetConVarBool(cvar_replenishAmmo);
	HPPerKill = GetConVarInt(cvar_HPPerKill);
	HPPerHeadshotKill = GetConVarInt(cvar_HPPerHeadshotKill);
	displayHPMessages = GetConVarBool(cvar_displayHPMessages);
	
	if (respawnTime < 0.0)
		respawnTime = 0.0;
	
	if (lineOfSightAttempts < 0)
		lineOfSightAttempts = 0;
	
	if (spawnDistanceFromEnemies < 0.0)
		spawnDistanceFromEnemies = 0.0;
	
	if (spawnProtectionTime < 0.0)
		spawnProtectionTime = 0.0;
	
	if (HPPerKill < 0)
		HPPerKill = 0;
	
	if (HPPerHeadshotKill < 0)
		HPPerHeadshotKill = 0;
	
	if (enabled && !oldEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
			ResetClientSettings(i);
		RespawnAll();
		if (removeObjectives)
			RemoveC4();
	}
	else if (!enabled && oldEnabled)
	{
		for (new i = 1; i <= MaxClients; i++)
			DisableSpawnProtection(INVALID_HANDLE, i);
		CancelMenu(optionsMenu1);
		CancelMenu(optionsMenu2);
		CancelMenu(primaryMenu);
		CancelMenu(secondaryMenu);
	}
	
	if (enabled)
	{
		SetBuyZones("Disable");
		decl String:status[10];
		status = (removeObjectives) ? "Disable" : "Enable";
		SetObjectives(status);
	}
	else
	{
		SetBuyZones("Enable");
		SetObjectives("Enable");
	}
	
	if (enabled && !oldEnabled)
	{
		SetConVarInt(mp_startmoney, 0);
		SetConVarInt(mp_playercashawards, 0);
		SetConVarInt(mp_teamcashawards, 0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
				SetEntProp(i, Prop_Send, "m_iAccount", 0);
		}
	}
	else if (!enabled && oldEnabled)
	{
		SetConVarInt(mp_startmoney, backupStartMoney);
		SetConVarInt(mp_playercashawards, backupPlayerCashAwards);
		SetConVarInt(mp_teamcashawards, backupTeamCashAwards);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
				SetEntProp(i, Prop_Send, "m_iAccount", backupStartMoney);
		}
	}
}

LoadMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "cfg/deathmatch/spawns/%s.txt", map);
	
	spawnPointCount = 0;
	
	// Open file
	new Handle:file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
		return;
	// Read file
	decl String:buffer[256];
	decl String:parts[6][16];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		ExplodeString(buffer, " ", parts, 6, 16);
		spawnPositions[spawnPointCount][0] = StringToFloat(parts[0]);
		spawnPositions[spawnPointCount][1] = StringToFloat(parts[1]);
		spawnPositions[spawnPointCount][2] = StringToFloat(parts[2]);
		spawnAngles[spawnPointCount][0] = StringToFloat(parts[3]);
		spawnAngles[spawnPointCount][1] = StringToFloat(parts[4]);
		spawnAngles[spawnPointCount][2] = StringToFloat(parts[5]);
		spawnPointCount++;
	}
	// Close file
	CloseHandle(file);
}

bool:WriteMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "cfg/deathmatch/spawns/%s.txt", map);
	
	// Open file
	new Handle:file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	// Write spawn points
	for (new i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2]);
	// Close file
	CloseHandle(file);
	return true;
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
	static String:triggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };
	static triggerCount = sizeof(triggers);
	
	if (enabled && (clientIndex != 0) && (Teams:GetClientTeam(clientIndex) > TeamSpectator))
	{
		// Retrieve and clean up text
		decl String:text[10];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
	
		for(new i = 0; i < triggerCount; i++)
		{
			if (StrEqual(text, triggers[i], false))
			{
				DisplayOptionsMenu(clientIndex);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

DisplayOptionsMenu(clientIndex)
{
	if (!firstWeaponSelection[clientIndex])
		DisplayMenu(optionsMenu1, clientIndex, MENU_TIME_FOREVER);
	else
		DisplayMenu(optionsMenu2, clientIndex, MENU_TIME_FOREVER);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((clientIndex != 0) && (Teams:GetClientTeam(clientIndex) == TeamSpectator))
		CancelClientMenu(clientIndex);
}

public Action:Event_JoinClass(clientIndex, args)
{
	if (enabled)
		CreateTimer(respawnTime, Respawn, clientIndex);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = false;
	c4Removed = false;
	if (enabled)
	{
		if (removeObjectives)
		{
			RemoveC4();
			RemoveHostages();
		}
		if (removeWeapons)
			RemoveGroundWeapons(INVALID_HANDLE);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = true;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
		if (Teams:GetClientTeam(clientIndex) > TeamSpectator)
		{
			// Display help message
			if (infoMessageCount[clientIndex] > 0)
			{
				PrintToChat(clientIndex, "[\x04DM\x01] Type \x04guns \x01to open the weapons menu.");
				infoMessageCount[clientIndex]--;
			}
			// Teleport player to custom spawn point
			if (spawnPointCount > 0)
				MovePlayer(clientIndex);
			// Enable player spawn protection
			if (spawnProtectionTime > 0.0)
				EnableSpawnProtection(clientIndex);
			// Give equipment
			SetEntData(clientIndex, armourOffset, 100);
			SetEntData(clientIndex, helmetOffset, 1);
			// Give weapons or display menu
			weaponsGivenThisRound[clientIndex] = false;
			RemoveWeapons(clientIndex);
			if (newWeaponsSelected[clientIndex])
			{
				GiveSavedWeapons(clientIndex, true, true);
				newWeaponsSelected[clientIndex] = false;
			}
			else if (rememberChoice[clientIndex])
				GiveSavedWeapons(clientIndex, true, true);
			else
				DisplayOptionsMenu(clientIndex);
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		// Respawn player.
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(respawnTime, Respawn, clientIndex);
		// Reward attacker.
		new bool:headshot = GetEventBool(event, "headshot");
		
		if ((!headshot && (HPPerKill > 0)) || (headshot && (HPPerHeadshotKill > 0)))
		{
			new attackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
			
			if (attackerIndex > 0 && IsPlayerAlive(attackerIndex))
			{
				new attackerHP = GetClientHealth(attackerIndex);
				
				if (attackerHP < 100)
				{
					new addHP = (!headshot) ? HPPerKill : HPPerHeadshotKill;
					new newHP = attackerHP + addHP;
					if (newHP > 100)
						newHP = 100;
					SetEntProp(attackerIndex, Prop_Send, "m_iHealth", newHP, 1);
				}
				if (displayHPMessages)
				{
					if (!headshot)
						PrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 for killing an enemy.", HPPerKill);
					else
						PrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 for killing an enemy (headshot).", HPPerHeadshotKill);
				}
			}
		}
	}
}

public Action:GiveAmmo(Handle:timer)
{
	static ammoCounts[] = { 0, 35, 90, 90, 200, 30, 120, 32, 100, 52, 100, 1, 1, 1, 1, 1 };
	
	if (enabled && replenishAmmo)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!roundEnded && IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				new activeWeapon = GetEntDataEnt2(i, activeWeaponOffset);
				if (activeWeapon != -1)
				{
					new ammoType = GetEntData(activeWeapon, ammoTypeOffset);
					if (ammoType != -1)
						SetEntData(i, ammoOffset + (ammoType * 4), ammoCounts[ammoType], 4, true);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled && removeObjectives && !c4Removed)
	{
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
		StripC4(clientIndex);
	}
}

public Action:Respawn(Handle:timer, any:clientIndex)
{
	if (!roundEnded && IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) > TeamSpectator) && !IsPlayerAlive(clientIndex))
	{
		// We set this here rather than in Event_PlayerSpawn to catch the spawn sounds which occur before Event_PlayerSpawn is called (even with EventHookMode_Pre).
		playerMoved[clientIndex] = false;
		CS_RespawnPlayer(clientIndex);
	}
}

RespawnAll()
{
	for (new i = 1; i <= MaxClients; i++)
		Respawn(INVALID_HANDLE, i);
}

Handle:BuildOptionsMenu(bool:sameWeaponsEnabled)
{
	new sameWeaponsStyle = (sameWeaponsEnabled) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	new Handle:menu = CreateMenu(Menu_Options);
	SetMenuTitle(menu, "Weapon Menu:");
	SetMenuExitButton(menu, false);
	AddMenuItem(menu, "New", "New weapons");
	AddMenuItem(menu, "Same 1", "Same weapons", sameWeaponsStyle);
	AddMenuItem(menu, "Same All", "Same weapons every round", sameWeaponsStyle);
	AddMenuItem(menu, "Random 1", "Random weapons");
	AddMenuItem(menu, "Random All", "Random weapons every round");
	return menu;
}

public Menu_Options(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[20];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "New"))
		{
			if (weaponsGivenThisRound[param1])
				newWeaponsSelected[param1] = true;
			DisplayMenu(primaryMenu, param1, MENU_TIME_FOREVER);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04DM\x01] You will be given the same weapons on next spawn.");
			}
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04DM\x01] You will be given the same weapons starting on next spawn.");
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = true;
		}
		else if (StrEqual(info, "Random 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04DM\x01] You will receive random weapons on next spawn.");
			}
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Random All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04DM\x01] You will receive random weapons starting on next spawn.");
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = true;
		}
	}
}

public Menu_Primary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[20];
		GetMenuItem(menu, param2, info, sizeof(info));
		primaryWeapon[param1] = info;
		GiveSavedWeapons(param1, true, false);
		DisplayMenu(secondaryMenu, param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			primaryWeapon[param1] = "none";
			GiveSavedWeapons(param1, true, false);
			DisplayMenu(secondaryMenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public Menu_Secondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[20];
		GetMenuItem(menu, param2, info, sizeof(info));
		secondaryWeapon[param1] = info;
		GiveSavedWeapons(param1, false, true);
		if (!IsPlayerAlive(param1))
			newWeaponsSelected[param1] = true;
		if (newWeaponsSelected[param1])
			PrintToChat(param1, "[\x04DM\x01] Your new weapons will be given to you on next spawn.");
		firstWeaponSelection[param1] = false;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			if ((param1 > 0) && (param1 <= MaxClients) && IsClientInGame(param1))
			{
				secondaryWeapon[param1] = "none";
				GiveSavedWeapons(param1, false, true);
				if (!IsPlayerAlive(param1))
					newWeaponsSelected[param1] = true;
				if (newWeaponsSelected[param1])
					PrintToChat(param1, "[\x04DM\x01] Your new weapons will be given to you on next spawn.");
				firstWeaponSelection[param1] = false;
			}
		}
	}
}

public Action:Command_Guns(clientIndex, args)
{
	if (enabled)
		DisplayOptionsMenu(clientIndex);
}

GiveSavedWeapons(clientIndex, bool:primary, bool:secondary)
{
	if (!weaponsGivenThisRound[clientIndex] && IsPlayerAlive(clientIndex))
	{
		if (primary && !StrEqual(primaryWeapon[clientIndex], "none"))
		{
			if (StrEqual(primaryWeapon[clientIndex], "random"))
			{
				// Select random menu item (excluding "Random" option)
				new	random = GetRandomInt(0, GetMenuItemCount(primaryMenu) - 2);
				decl String:randomWeapon[20];
				GetMenuItem(primaryMenu, random, randomWeapon, sizeof(randomWeapon));
				GivePlayerItem(clientIndex, randomWeapon);
			}
			else
				GivePlayerItem(clientIndex, primaryWeapon[clientIndex]);
		}
		if (secondary)
		{
			if (!StrEqual(secondaryWeapon[clientIndex], "none"))
			{
				// Strip knife, give pistol, and then give knife. This fixes the bug where pressing Q on spawn would switch to knife rather than pistol.
				new entityIndex = GetPlayerWeaponSlot(clientIndex, _:SlotKnife);
				if (entityIndex != -1)
				{
					RemovePlayerItem(clientIndex, entityIndex);
					AcceptEntityInput(entityIndex, "Kill");
				}
				if (StrEqual(secondaryWeapon[clientIndex], "random"))
				{
					// Select random menu item (excluding "Random" option)
					new random = GetRandomInt(0, GetMenuItemCount(secondaryMenu) - 2);
					decl String:randomWeapon[20];
					GetMenuItem(secondaryMenu, random, randomWeapon, sizeof(randomWeapon));
					GivePlayerItem(clientIndex, randomWeapon);
				}
				else
					GivePlayerItem(clientIndex, secondaryWeapon[clientIndex]);
				GivePlayerItem(clientIndex, "weapon_knife");
			}
			weaponsGivenThisRound[clientIndex] = true;
		}
	}
}

RemoveWeapons(clientIndex)
{
	FakeClientCommand(clientIndex, "use weapon_knife");
	for (new i = 0; i < 4; i++)
	{
		if (i == 2) continue; // Keep knife.
		new entityIndex;
		while ((entityIndex = GetPlayerWeaponSlot(clientIndex, i)) != -1)
		{
			RemovePlayerItem(clientIndex, entityIndex);
			AcceptEntityInput(entityIndex, "Kill");
		}
	}
}

public Action:RemoveGroundWeapons(Handle:timer)
{
	if (enabled && removeWeapons)
	{
		new maxEntities = GetMaxEntities();
		decl String:class[20];
		
		for (new i = MaxClients + 1; i < maxEntities; i++)
		{
			if (IsValidEdict(i) && (GetEntDataEnt2(i, ownerOffset) == -1))
			{
				GetEdictClassname(i, class, sizeof(class));
				if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
				{
					if (StrEqual(class, "weapon_c4"))
					{
						if (removeObjectives)
							c4Removed = true;
						else
							continue;
					}
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

SetBuyZones(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[20];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}

SetObjectives(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[20];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
				AcceptEntityInput(i, status);
		}
	}
}

RemoveC4()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (StripC4(i))
			break;
	}
}

bool:StripC4(clientIndex)
{
	if (IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) == TeamT) && IsPlayerAlive(clientIndex))
	{
		new c4Index = GetPlayerWeaponSlot(clientIndex, _:SlotC4);
		if (c4Index != -1)
		{
			decl String:weapon[20];
			GetClientWeapon(clientIndex, weapon, sizeof(weapon));
			// If the player is holding C4, switch to the best weapon before removing it.
			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(clientIndex, _:SlotPrimary) != -1)
					ClientCommand(clientIndex, "slot1");
				else if (GetPlayerWeaponSlot(clientIndex, _:SlotSecondary) != -1)
					ClientCommand(clientIndex, "slot2");
				else
					ClientCommand(clientIndex, "slot3");
				
			}
			RemovePlayerItem(clientIndex, c4Index);
			AcceptEntityInput(c4Index, "Kill");
			c4Removed = true;
			return true;
		}
	}
	return false;
}

RemoveHostages()
{
	new maxEntities = GetMaxEntities();
	decl String:class[20];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "hostage_entity"))
				AcceptEntityInput(i, "Kill");
		}
	}
}

EnableSpawnProtection(clientIndex)
{
	new Teams:clientTeam = Teams:GetClientTeam(clientIndex);
	// Disable damage
	SetEntProp(clientIndex, Prop_Data, "m_takedamage", 0, 1);
	// Set player colour
	if (clientTeam == TeamT)
		SetPlayerColour(clientIndex, tColour);
	else if (clientTeam == TeamCT)
		SetPlayerColour(clientIndex, ctColour);
	// Create timer to remove spawn protection
	CreateTimer(spawnProtectionTime, DisableSpawnProtection, clientIndex);
}

public Action:DisableSpawnProtection(Handle:Timer, any:clientIndex)
{
	if (IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) > TeamSpectator) && IsPlayerAlive(clientIndex))
	{
		// Enable damage
		SetEntProp(clientIndex, Prop_Data, "m_takedamage", 2, 1);
		// Set player colour
		SetPlayerColour(clientIndex, defaultColour);
	}
}

SetPlayerColour(clientIndex, const colour[4])
{
	new RenderMode:mode = (colour[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR;
	SetEntityRenderMode(clientIndex, mode);
	SetEntityRenderColor(clientIndex, colour[0], colour[1], colour[2], colour[3]);
}

public Action:Command_RespawnAll(clientIndex, args)
{
	RespawnAll();
}

Handle:BuildSpawnEditorMenu()
{
	new Handle:menu = CreateMenu(Menu_SpawnEditor);
	SetMenuTitle(menu, "Spawn Point Editor:");
	SetMenuExitButton(menu, true);
	decl String:editModeItem[20];
	Format(editModeItem, sizeof(editModeItem), "%s Edit Mode", (!inEditMode) ? "Enable" : "Disable");
	AddMenuItem(menu, "Edit", editModeItem);
	AddMenuItem(menu, "Nearest", "Teleport to nearest");
	AddMenuItem(menu, "Previous", "Teleport to previous");
	AddMenuItem(menu, "Next", "Teleport to next");
	AddMenuItem(menu, "Add", "Add position");
	AddMenuItem(menu, "Insert", "Insert position here");
	AddMenuItem(menu, "Delete", "Delete nearest");
	AddMenuItem(menu, "Delete All", "Delete all");
	AddMenuItem(menu, "Save", "Save Configuration");
	return menu;
}

public Action:Command_SpawnMenu(clientIndex, args)
{
	DisplayMenu(BuildSpawnEditorMenu(), clientIndex, MENU_TIME_FOREVER);
}

public Menu_SpawnEditor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[20];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "Edit"))
		{
			inEditMode = !inEditMode;
			if (inEditMode)
			{
				CreateTimer(1.0, RenderSpawnPoints, INVALID_HANDLE, TIMER_REPEAT);
				PrintToChat(param1, "[\x04DM\x01] Edit mode enabled.");
			}
			else
				PrintToChat(param1, "[\x04DM\x01] Edit mode disabled.");
		}
		else if (StrEqual(info, "Nearest"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Previous"))
		{
			if (spawnPointCount == 0)
				PrintToChat(param1, "[\x04DM\x01] There are no spawn points.");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] - 1;
				if (spawnPoint < 0)
					spawnPoint = spawnPointCount - 1;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Next"))
		{
			if (spawnPointCount == 0)
				PrintToChat(param1, "[\x04DM\x01] There are no spawn points.");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] + 1;
				if (spawnPoint >= spawnPointCount)
					spawnPoint = 0;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Add"))
		{
			AddSpawn(param1);
		}
		else if (StrEqual(info, "Insert"))
		{
			InsertSpawn(param1);
		}
		else if (StrEqual(info, "Delete"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				DeleteSpawn(spawnPoint);
				PrintToChat(param1, "[\x04DM\x01] Deleted spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Delete All"))
		{
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "Delete all spawn points?");
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, Panel_ConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
		else if (StrEqual(info, "Save"))
		{
			if (WriteMapConfig())
				PrintToChat(param1, "[\x04DM\x01] Configuration has been saved.");
			else
				PrintToChat(param1, "[\x04DM\x01] Configuration could not be saved.");
		}
		if (!StrEqual(info, "Delete All"))
			DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Panel_ConfirmDeleteAllSpawns(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			spawnPointCount = 0;
			PrintToChat(param1, "[\x04DM\x01] All spawn points have been deleted.");
		}
		DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
}

public Action:RenderSpawnPoints(Handle:timer)
{
	if (!inEditMode)
		return Plugin_Stop;
	
	for (new i = 0; i < spawnPointCount; i++)
	{
		decl Float:spawnPosition[3];
		AddVectors(spawnPositions[i], spawnPointOffset, spawnPosition);
		TE_SetupGlowSprite(spawnPosition, glowSprite, 1.0, 0.5, 255);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

GetNearestSpawn(clientIndex)
{
	if (spawnPointCount == 0)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] There are no spawn points.");
		return -1;
	}
	
	decl Float:clientPosition[3];
	GetClientAbsOrigin(clientIndex, clientPosition);
	
	new nearestPoint = 0;
	new Float:nearestPointDistance = GetVectorDistance(spawnPositions[0], clientPosition, true);
	
	for (new i = 1; i < spawnPointCount; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[i], clientPosition, true);
		if (distance < nearestPointDistance)
		{
			nearestPoint = i;
			nearestPointDistance = distance;
		}
	}
	return nearestPoint;
}

AddSpawn(clientIndex)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] Could not add spawn point (max limit reached).");
		return;
	}
	GetClientAbsOrigin(clientIndex, spawnPositions[spawnPointCount]);
	GetClientAbsAngles(clientIndex, spawnAngles[spawnPointCount]);
	spawnPointCount++;
	PrintToChat(clientIndex, "[\x04DM\x01] Added spawn point #%i (%i total).", spawnPointCount, spawnPointCount);
}

InsertSpawn(clientIndex)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] Could not add spawn point (max limit reached).");
		return;
	}
	
	if (spawnPointCount == 0)
		AddSpawn(clientIndex);
	else
	{
		// Move spawn points down the list to make room for insertion.
		for (new i = spawnPointCount - 1; i >= lastEditorSpawnPoint[clientIndex]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(clientIndex, spawnPositions[lastEditorSpawnPoint[clientIndex]]);
		GetClientAbsAngles(clientIndex, spawnAngles[lastEditorSpawnPoint[clientIndex]]);
		spawnPointCount++;
		PrintToChat(clientIndex, "[\x04DM\x01] Inserted spawn point at #%i (%i total).", lastEditorSpawnPoint[clientIndex] + 1, spawnPointCount);
	}
}

DeleteSpawn(spawnIndex)
{
	for (new i = spawnIndex; i < (spawnPointCount - 1); i++)
	{
		spawnPositions[i] = spawnPositions[i + 1];
		spawnAngles[i] = spawnAngles[i + 1];
	}
	spawnPointCount--;
}

/**
 * Updates the occupation status of all spawn points.
 */
public Action:UpdateSpawnPointStatus(Handle:timer)
{
	if (enabled && (spawnPointCount > 0))
	{
		// Retrieve player positions.
		decl Float:playerPositions[MaxClients][3];
		new numberOfAlivePlayers = 0;
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
				numberOfAlivePlayers++;
			}
		}
	
		// Check each spawn point for occupation by proximity to alive players
		for (new i = 0; i < spawnPointCount; i++)
		{
			spawnPointOccupied[i] = false;
			for (new j = 0; j < numberOfAlivePlayers; j++)
			{
				new Float:distance = GetVectorDistance(spawnPositions[i], playerPositions[j], true);
				if (distance < 10000.0)
				{
					spawnPointOccupied[i] = true;
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}

MovePlayer(clientIndex)
{
	numberOfPlayerSpawns++; // Stats
	
	new Teams:clientTeam = Teams:GetClientTeam(clientIndex);
	
	new spawnPoint;
	new bool:spawnPointFound = false;
	
	decl Float:enemyEyePositions[MaxClients][3];
	new numberOfEnemies = 0;
	
	// Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking).
	if (lineOfSightSpawning || (spawnDistanceFromEnemies > 0.0))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				new bool:enemy = (Teams:GetClientTeam(i) != clientTeam);
				if (enemy)
				{
					GetClientEyePosition(i, enemyEyePositions[numberOfEnemies]);
					numberOfEnemies++;
				}
			}
		}
	}
	
	if (lineOfSightSpawning)
	{
		losSearchAttempts++; // Stats
		
		// Try to find a suitable spawn point with a clear line of sight.
		for (new i = 0; i < lineOfSightAttempts; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (spawnDistanceFromEnemies > 0.0)
			{
				if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
					continue;
			}
			
			decl Float:spawnPointEyePosition[3];
			AddVectors(spawnPositions[spawnPoint], eyeOffset, spawnPointEyePosition);
			
			new bool:hasClearLineOfSight = true;
			
			for (new j = 0; j < numberOfEnemies; j++)
			{
				new Handle:trace = TR_TraceRayFilterEx(spawnPointEyePosition, enemyEyePositions[j], MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterPlayer);
				if (!TR_DidHit(trace))
				{
					hasClearLineOfSight = false;
					CloseHandle(trace);
					break;
				}
				CloseHandle(trace);
			}
			if (hasClearLineOfSight)
			{
				spawnPointFound = true;
				break;
			}
		}
		// Stats
		if (spawnPointFound)
			losSearchSuccesses++;
		else
			losSearchFailures++;
	}
	
	// First fallback. Find a random unccupied spawn point at a suitable distance.
	if (!spawnPointFound && (spawnDistanceFromEnemies > 0.0))
	{
		distanceSearchAttempts++; // Stats
		
		for (new i = 0; i < 50; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
				continue;
			
			spawnPointFound = true;
			break;
		}
		// Stats
		if (spawnPointFound)
			distanceSearchSuccesses++;
		else
			distanceSearchFailures++;
	}
	
	// Final fallback. Find a random unoccupied spawn point.
	if (!spawnPointFound)
	{
		for (new i = 0; i < 100; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (!spawnPointOccupied[spawnPoint])
			{
				spawnPointFound = true;
				break;
			}
		}
	}
	
	if (spawnPointFound)
	{
		TeleportEntity(clientIndex, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
		spawnPointOccupied[spawnPoint] = true;
		playerMoved[clientIndex] = true;
	}
	
	if (!spawnPointFound) spawnPointSearchFailures++; // Stats
}

bool:IsPointSuitableDistance(spawnPoint, const Float:enemyEyePositions[][3], numberOfEnemies)
{
	for (new i = 0; i < numberOfEnemies; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[spawnPoint], enemyEyePositions[i], true);
		if (distance < spawnDistanceFromEnemies)
			return false;
	}
	return true;
}

public bool:TraceEntityFilterPlayer(entityIndex, mask)
{
	if ((entityIndex > 0) && (entityIndex <= MaxClients)) return false;
	return true;
}

public Action:Command_Stats(clientIndex, args)
{
	DisplaySpawnStats(clientIndex);
}

public Action:Command_ResetStats(clientIndex, args)
{
	ResetSpawnStats();
	PrintToChat(clientIndex, "[\x04DM\x01] Spawn statistics have been reset.");
}

ResetSpawnStats()
{
	numberOfPlayerSpawns = 0;
	losSearchAttempts = 0;
	losSearchSuccesses = 0;
	losSearchFailures = 0;
	distanceSearchAttempts = 0;
	distanceSearchSuccesses = 0;
	distanceSearchFailures = 0;
	spawnPointSearchFailures = 0;
}

DisplaySpawnStats(clientIndex)
{
	decl String:text[64];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Spawn Stats:");
	Format(text, sizeof(text), "Number of player spawns: %i", numberOfPlayerSpawns);
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "LoS search success rate: %.2f\%", (float(losSearchSuccesses) / float(losSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "LoS search failure rate: %.2f\%", (float(losSearchFailures) / float(losSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Distance search success rate: %.2f\%", (float(distanceSearchSuccesses) / float(distanceSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Distance search failure rate: %.2f\%", (float(distanceSearchFailures) / float(distanceSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Spawn point search failures: %i", spawnPointSearchFailures);
	DrawPanelItem(panel, text);
	SendPanelToClient(panel, clientIndex, Panel_SpawnStats, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public Panel_SpawnStats(Handle:menu, MenuAction:action, param1, param2) { }

public Action:Event_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (enabled && (spawnPointCount > 0))
	{
		new clientIndex;
		if ((entity > 0) && (entity <= MaxClients))
			clientIndex = entity;
		else
			clientIndex = GetEntDataEnt2(entity, ownerOffset);
	
		// Block ammo pickup sounds.
		if (StrEqual(sample, "items/ammopickup.wav"))
			return Plugin_Stop;
	
		// Block all sounds originating from players not yet moved.
		if ((clientIndex > 0) && (clientIndex <= MaxClients) && !playerMoved[clientIndex])
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (enabled)
	{
		if ((reason == CSRoundEnd_CTWin) || (reason == CSRoundEnd_TerroristWin))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}