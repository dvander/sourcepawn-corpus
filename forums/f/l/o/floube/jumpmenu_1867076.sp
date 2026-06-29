#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#pragma semicolon 1

/****************************************************************
			C O N S T A N T S
*****************************************************************/

#define PLUGIN_VERSION	"1.09"
#define MAX_TEAM_NUM	4
#define MAX_CLASS_NUM	10

/****************************************************************
			G L O B A L   C O N S T A N T   V A R S
*****************************************************************/

static const g_iClassMaxHealth[TFClassType] =
{
	 -1,		// Unknown
	125,		// Scout
	125,		// Sniper
	200,		// Soldier
	175,		// Demoman
	150,		// Medic
	300,		// Heavy
	175,		// Pyro
	125,		// Spy
	125,		// Engineer
};

static const String:g_sSounds[][] = 
{
	"regenerate",
	"ammo_pickup",
	"pain"
};

/****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo =
{
	name = "Jump Menu",
	author = "floube",
	description = "Features for TF2 Jumping",
	version = PLUGIN_VERSION,
	url = "http://www.styria-games.eu/"
};

/****************************************************************
			P L U G I N   V A R S
*****************************************************************/

new Handle:g_hPluginEnabled;
new Handle:g_hNoBlock;

/****************************************************************
			C L I E N T   V A R S
*****************************************************************/

new bool:g_bFirstSpawn[MAXPLAYERS + 1];
new bool:g_bHasReset[MAXPLAYERS + 1];

/****************************************************************
			S Q L   V A R S
*****************************************************************/

new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hDatabaseSupport;
new bool:g_bLoadedPlayerSettings[MAXPLAYERS + 1];

/****************************************************************
			A M M O   V A R S
*****************************************************************/

new Handle:g_hCaber;
new Handle:g_hCaberTimer;
new Handle:g_hAmmo;
new Handle:g_hAmmoTimer;

// Non-Database
new bool:g_bAmmoEnabled[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM];
new g_iAmmoRestore[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM][2];

// Database
new bool:g_bDatabaseAmmoEnabled[MAXPLAYERS + 1];
new g_iDatabaseAmmoRestore[MAXPLAYERS + 1][2];

/****************************************************************
			H E A L T H   V A R S
*****************************************************************/

new Handle:g_hHealth;
new Handle:g_hHealthMode;
new Handle:g_hHealthTimer;

// Non-Database
new bool:g_bHealthEnabled[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM];

// Database
new bool:g_bDatabaseHealthEnabled[MAXPLAYERS + 1];

/****************************************************************
			S U P E R M A N   V A R S
*****************************************************************/

new Handle:g_hSuperman;

// Non-Database
new bool:g_bSupermanEnabled[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM];

// Database
new bool:g_bDatabaseSupermanEnabled[MAXPLAYERS + 1];

/****************************************************************
			S A V E   V A R S
*****************************************************************/

new Handle:g_hSave;

// Non-Database
new bool:g_bSavedOnce[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM];
new Float:g_fSaveLocation[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM][3];
new Float:g_fSaveAngles[MAXPLAYERS + 1][MAX_TEAM_NUM][MAX_CLASS_NUM][3];

// Database
new Float:g_fDatabaseSaveLocation[MAXPLAYERS + 1][3];
new Float:g_fDatabaseSaveAngles[MAXPLAYERS + 1][3];

/****************************************************************
			A N N O U N C E M E N T   V A R S
*****************************************************************/

new Handle:g_hAnnounce;
new Handle:g_hAnnounceTimer;

/****************************************************************
			S O U N D S   V A R S
*****************************************************************/

new Handle:g_hSounds;

/****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart() {
	CreateConVar("sm_jmenu_version", PLUGIN_VERSION, "Jump Menu Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hPluginEnabled = CreateConVar("sm_jmenu_enabled", "1", "0 = Jump Menu Plugin disabled; 1 = Jump Menu Plugin enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAmmo = CreateConVar("sm_jmenu_ammo", "0.1", "0 = Ammo-Regen disabled; X = Fill the players ammo every X seconds", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hCaber = CreateConVar("sm_jmenu_caber", "1.0", "0 = Caber-Reset disabled; X = Reset the Caber every X seconds", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hHealth = CreateConVar("sm_jmenu_health", "0.1", "0 = HP-Regen disabled; X = Fill the players HP every X seconds", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hHealthMode = CreateConVar("sm_jmenu_health_mode", "0", "0 = Heal to maximum HP (class-specific); X = Heal up to X HP", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hSuperman = CreateConVar("sm_jmenu_superman", "1", "0 = Superman-Feature disabled; 1 = Superman-Feature enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hSave = CreateConVar("sm_jmenu_save", "1", "0 = Save-Teleport-Feature disabled; 1 = Save-Teleport-Feature enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAnnounce = CreateConVar("sm_jmenu_announce", "120.0", "0 = Announcements disabled; X = Fire announcement every X seconds", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hDatabaseSupport = CreateConVar("sm_jmenu_database", "0", "0 = Database support disabled; 1 = Database support enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hNoBlock = CreateConVar("sm_jmenu_noblock", "1", "0 = Players block each other; 1 = Players don't block each other", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hSounds = CreateConVar("sm_jmenu_sounds", "1", "0 = Sounds disabled; 1 = Sounds enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// AutoExecConfig(true, "plugin.jumpmenu");

	if (GetConVarBool(g_hPluginEnabled)) {
		RegConsoleCmd("sm_ammo", Command_AmmoRegen, "Regenerates your ammo.");

		RegConsoleCmd("sm_hp", Command_HealthRegen, "Regenerates your HP.");
		RegConsoleCmd("sm_regen", Command_HealthRegen, "Regenerates your HP.");

		RegConsoleCmd("sm_superman", Command_Superman, "Makes you strong like superman.");

		RegConsoleCmd("sm_s", Command_Save, "Saves your current location.");
		RegConsoleCmd("sm_save", Command_Save, "Saves your current location.");
		RegConsoleCmd("sm_jm_saveloc", Command_Save, "Saves your current location.");

		RegConsoleCmd("sm_t", Command_Teleport, "Teleports you to your saved location.");
		RegConsoleCmd("sm_tp", Command_Teleport, "Teleports you to your saved location.");
		RegConsoleCmd("sm_tele", Command_Teleport, "Teleports you to your saved location.");
		RegConsoleCmd("sm_teleport", Command_Teleport, "Teleports you to your saved location.");
		RegConsoleCmd("sm_jm_teleport", Command_Teleport, "Teleports you to your saved location.");

		RegConsoleCmd("sm_goto", Command_Goto, "Teleports you to a player.");
		RegConsoleCmd("sm_send", Command_Send, "Teleports a player to another player.");

		RegConsoleCmd("sm_reset", Command_Reset, "Sends you back to the beginning without deleting your save.");
		RegConsoleCmd("sm_restart", Command_Restart, "Sends you back to the beginning and deletes your save.");

		RegConsoleCmd("sm_jmenu", Command_Menu, "Opens the Jump Menu.");

		RegConsoleCmd("sm_jsettings", Command_Settings, "Shows with which settings you are playing.");

		AddNormalSoundHook(NormalSHook:SoundHook);

		HookEvent("player_changeclass", Event_PlayerChangeClass);
		HookEvent("player_team", Event_PlayerChangeTeam);
		HookEvent("player_spawn", Event_PlayerSpawn);

		HookConVarChange(g_hAmmo, CvarChange_GeneralFloat);
		HookConVarChange(g_hCaber, CvarChange_GeneralFloat);
		HookConVarChange(g_hHealth, CvarChange_GeneralFloat);
		HookConVarChange(g_hHealthMode, CvarChange_GeneralFloat);
		HookConVarChange(g_hSuperman, CvarChange_Superman);
		HookConVarChange(g_hSave, CvarChange_GeneralBool);
		HookConVarChange(g_hAnnounce, CvarChange_Announce);
		HookConVarChange(g_hDatabaseSupport, CvarChange_DatabaseSupport);
		HookConVarChange(g_hNoBlock, CvarChange_NoBlock);
		HookConVarChange(g_hSounds, CvarChange_GeneralBool);

		StartAnnounce();
		StartAmmoRegen();
		StartCaberReset();
		StartHealthRegen();

		if (g_hDatabase == INVALID_HANDLE) {
			ConnectToDatabase();
		}

		// Check SQL tables
		CheckSQLTables();

		// Plugin late load, re-load
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				// OnClientPutInServer(i);
			}
		}

		LoadTranslations("common.phrases");
	}
	
	HookConVarChange(g_hPluginEnabled, CvarChange_PluginEnabled);
}

public OnMapStart() {	
	if (GetConVarBool(g_hPluginEnabled)) {
		ConnectToDatabase();
	}
}

public OnClientPutInServer(iClient) {
	if (GetConVarBool(g_hPluginEnabled) || !IsFakeClient(iClient)) {
		if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
			for (new i = 0; i < MAX_CLASS_NUM; i++) {
				for (new j = 0; j < MAX_TEAM_NUM; j++) {
					g_bAmmoEnabled[iClient][j][i] = false;
					g_bHealthEnabled[iClient][j][i] = false;
					g_bSupermanEnabled[iClient][j][i] = false;

					g_iAmmoRestore[iClient][j][i][0] = GetClientClip(iClient, 0);
					g_iAmmoRestore[iClient][j][i][1] = GetClientClip(iClient, 1);

					g_bSavedOnce[iClient][j][i] = false;
					g_fSaveLocation[iClient][j][i] = Float:{0.0, 0.0, 0.0};
					g_fSaveAngles[iClient][j][i] = Float:{0.0, 0.0, 0.0};
				}
			}
		}

		else { // Database support enabled
			if (!g_bLoadedPlayerSettings[iClient]) {
				new String:sSteamID[32]; 
				GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));

				LoadPlayerProfile(iClient, sSteamID);
				LoadPlayerData(iClient);
			}
		}

		g_bFirstSpawn[iClient] = true;
		g_bHasReset[iClient] = false;
	}
}

public OnClientPostAdminCheck(iClient) {
	if (GetConVarBool(g_hPluginEnabled) || !IsFakeClient(iClient)) {
		new String:sSteamID[32]; 
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		
		LoadPlayerProfile(iClient, sSteamID);
	}
}

public OnClientDisconnect(iClient) {
	if (GetConVarBool(g_hPluginEnabled) || !IsFakeClient(iClient)) {
		g_bDatabaseAmmoEnabled[iClient] = false;
		g_bDatabaseHealthEnabled[iClient] = false;
		g_bLoadedPlayerSettings[iClient] = false;

		EraseLocs(iClient);
	}
}

/****************************************************************
			S O U N D   H O O K
*****************************************************************/

public Action:SoundHook(iClients[64], &iClientCount, String:sSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:fVolume, &iLevel, &iPitch, &iFlags) {
	if (!GetConVarBool(g_hPluginEnabled) || GetConVarBool(g_hSounds)) { 
		return Plugin_Continue; 
	}

	for (new i = 0; i < sizeof(g_sSounds); i++) {
		if (StrContains(sSample, g_sSounds[i], false) != -1) {
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/****************************************************************
			C V A R   C H A N G E   F U N C T I O N S
*****************************************************************/

public CvarChange_PluginEnabled(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hPluginEnabled, false);

		PrintToChatAll("\x04[Jump Menu] \x01Plugin is now disabled.");
		ServerCommand("sm plugins reload jumpmenu");
	} else {
		SetConVarBool(g_hPluginEnabled, true);

		PrintToChatAll("\x04[Jump Menu] \x01Plugin is now enabled.");
		ServerCommand("sm plugins reload jumpmenu");
	}
}

public CvarChange_DatabaseSupport(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hDatabaseSupport, false);

		PrintToChatAll("\x04[Jump Menu] \x01Database support is now disabled.");
		ServerCommand("sm plugins reload jumpmenu");
	} else {
		SetConVarBool(g_hDatabaseSupport, true);

		PrintToChatAll("\x04[Jump Menu] \x01Database support is now enabled.");
		ServerCommand("sm plugins reload jumpmenu");
	}
}

public CvarChange_Superman(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hSuperman, false);

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (!IsValidClient(iClient, true))
				continue;

			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		}
	} else {
		SetConVarBool(g_hSuperman, true);

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (!IsValidClient(iClient, true))
				continue;

			if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
				if (g_bSupermanEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
					SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
				}
			} 

			else { // Database support enabled
				if (g_bDatabaseSupermanEnabled[iClient]) {
					SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
				}

			}
		}
	}

	new String:sCvarName[33];
	GetConVarName(g_hSuperman, sCvarName, sizeof(sCvarName));

	PrintToChatAll("\x04[Jump Menu] \x01Plugin cvar '%s' changed to %d", sCvarName, StringToInt(sNewValue));
}

public CvarChange_NoBlock(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hNoBlock, false);

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (!IsValidClient(iClient, true))
				continue;

			SetEntData(iClient, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
		}
	} else {
		SetConVarBool(g_hNoBlock, true);

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (!IsValidClient(iClient, true))
				continue;
			
			SetEntData(iClient, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
		}
	}

	new String:sCvarName[33];
	GetConVarName(g_hNoBlock, sCvarName, sizeof(sCvarName));

	PrintToChatAll("\x04[Jump Menu] \x01Plugin cvar '%s' changed to %d", sCvarName, StringToInt(sNewValue));
}

public CvarChange_Announce(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {	
	SetConVarFloat(g_hAnnounce, StringToFloat(sNewValue));

	new String:sCvarName[33];
	GetConVarName(g_hAnnounce, sCvarName, sizeof(sCvarName));

	if (GetConVarFloat(g_hAnnounce) <= 0) {
		if (g_hAnnounceTimer != INVALID_HANDLE) {
			CloseHandle(g_hAnnounceTimer);
			g_hAnnounceTimer = INVALID_HANDLE;
		}
	} else {
		StartAnnounce();
	}

	PrintToChatAll("\x04[Jump Menu] \x01Plugin cvar '%s' changed to %f", sCvarName, StringToFloat(sNewValue));
}

public CvarChange_GeneralFloat(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	SetConVarFloat(hCvar, StringToFloat(sNewValue));

	new String:sCvarName[33];
	GetConVarName(hCvar, sCvarName, sizeof(sCvarName));

	PrintToChatAll("\x04[Jump Menu] \x01Plugin cvar '%s' changed to %f", sCvarName, StringToFloat(sNewValue));
}

public CvarChange_GeneralBool(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(hCvar, false);
	} else {
		SetConVarBool(hCvar, true);
	}

	new String:sCvarName[33];
	GetConVarName(hCvar, sCvarName, sizeof(sCvarName));

	PrintToChatAll("\x04[Jump Menu] \x01Plugin cvar '%s' changed to %d", sCvarName, StringToInt(sNewValue));
}

/****************************************************************
			E V E N T   F U N C T I O N S
*****************************************************************/

public Action:Event_PlayerChangeClass(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new String:sSteamID[32];

	if (GetConVarBool(g_hDatabaseSupport)) {
		EraseLocs(iClient);
		TF2_RespawnPlayer(iClient);

		if (g_bFirstSpawn[iClient]) {
			// Executed on first spawn only

			CreateTimer(2.0, Timer_ShowSettings, iClient);

			ReloadPlayerData(iClient);
			CreateTimer(0.5, Timer_TeleportClient, iClient);

			g_bFirstSpawn[iClient] = false;
		}

		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));

		LoadPlayerProfile(iClient, sSteamID);
	}

	return Plugin_Handled;
}

public Action:Event_PlayerChangeTeam(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iTeam = GetEventInt(hEvent, "team");

	if (iTeam == 1 || iTeam == 0) {
		EraseLocs(iClient);
	} else {
		CreateTimer(0.1, Timer_PlayerChangeTeam, iClient);
	}

	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (GetConVarBool(g_hDatabaseSupport) && !g_bFirstSpawn[iClient] && !g_bHasReset[iClient]) {
		LoadPlayerData(iClient);
	}

	if (GetConVarBool(g_hNoBlock)) { // Noblock is enabled
		SetEntData(iClient, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
	}

	return Plugin_Handled;
}

/****************************************************************
			S Q L   F U N C T I O N S
*****************************************************************/

stock ConnectToDatabase() {
	if (GetConVarBool(g_hDatabaseSupport)) {
		SQL_TConnect(SQL_OnConnect, "jumpmenu");
	}
}

stock CheckSQLTables() {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sError[255];
		new String:sQuery[512];

		new Handle:hDatabase = SQL_Connect("jumpmenu", true, sError, sizeof(sError));
		SQL_LockDatabase(hDatabase);

		if (hDatabase == INVALID_HANDLE) {
			LogError("Could not connect to Database: %s", sError);
			SQL_UnlockDatabase(hDatabase);
		} else {
			// Player Saves
			// Needed: GRANT SELECT, INSERT, UPDATE, DELETE ON <database>.* TO '<user>'@'<host>';
			Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS player_saves (id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT, steam_id VARCHAR(32) NOT NULL, player_class INT(2) NOT NULL, player_team INT(1) NOT NULL, player_map VARCHAR(50) NOT NULL, save1 FLOAT(7,2) NOT NULL, save2 FLOAT(7,2) NOT NULL, save3 FLOAT(7,2) NOT NULL, save4 FLOAT(7,2) NOT NULL, save5 FLOAT(7,2) NOT NULL, save6 FLOAT(7,2) NOT NULL)");
			if (!SQL_Query(hDatabase, sQuery)) {
				SQL_GetError(hDatabase, sError, sizeof(sError));
				LogError("Failed to query (error: %s)", sError);
				SQL_UnlockDatabase(hDatabase);
			}

			// Player Profiles/Settings
			Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS player_profiles (id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT, steam_id VARCHAR(32) NOT NULL, hp_regen INT(1) NOT NULL DEFAULT 0, ammo_regen INT(1) NOT NULL DEFAULT 0, superman INT(1) NOT NULL DEFAULT 0, comment TEXT DEFAULT NULL, UNIQUE (steam_id))");
			if (!SQL_Query(hDatabase, sQuery)) {
				SQL_GetError(hDatabase, sError, sizeof(sError));
				LogError("Failed to query (error: %s)", sError);
				SQL_UnlockDatabase(hDatabase);
			}

			PrintToServer("[Jump Menu] Checked SQL tables.");
		}

		SQL_UnlockDatabase(hDatabase);
		CloseHandle(hDatabase);
	}
}

stock LoadPlayerProfile(iClient, String:sSteamID[]) {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512];

		Format(sQuery, sizeof(sQuery), "SELECT * FROM player_profiles WHERE steam_id = '%s'", sSteamID);
		SQL_TQuery(g_hDatabase, SQL_OnLoadPlayerProfile, sQuery, iClient);
	}
}

stock CreatePlayerProfile(iClient, String:sSteamID[]) {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sDate[20];

		FormatTime(sDate, sizeof(sDate), "%Y-%m-%d %H:%M:%S");
		Format(sQuery, sizeof(sQuery), "INSERT IGNORE INTO player_profiles (steam_id, hp_regen, ammo_regen, superman, comment) VALUES ('%s', '0', '0', '0', 'Added on %s')", sSteamID, sDate);
		
		SQL_TQuery(g_hDatabase, SQL_OnCreatePlayerProfile, sQuery, iClient);
	}
}

stock UpdatePlayerProfile(iClient) { 
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32];
		
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));

		Format(sQuery, sizeof(sQuery), "UPDATE player_profiles SET hp_regen = '%d', ammo_regen = '%d', superman = '%d' WHERE steam_id = '%s'", g_bDatabaseHealthEnabled[iClient], g_bDatabaseAmmoEnabled[iClient], g_bDatabaseSupermanEnabled[iClient], sSteamID);
		
		SQL_TQuery(g_hDatabase, SQL_OnDefaultCallback, sQuery, iClient);
	}
}

stock LoadPlayerData(iClient) {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[64], String:sCurrentMap[50];

		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID)); 
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);

		Format(sQuery, sizeof(sQuery), "SELECT save1, save2, save3, save4, save5, save6 FROM player_saves WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", sSteamID, iTeam, iClass, sCurrentMap);

		SQL_TQuery(g_hDatabase, SQL_OnLoadPlayerData, sQuery, iClient);
	}
}

stock ReloadPlayerData(iClient) {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];

		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID)); 
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);

		Format(sQuery, sizeof(sQuery), "SELECT save1, save2, save3, save4, save5, save6 FROM player_saves WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", sSteamID, iTeam, iClass, sCurrentMap);

		SQL_TQuery(g_hDatabase, SQL_OnReloadPlayerData, sQuery, iClient);
	}
}

stock GetPlayerData(iClient) { 
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];
		
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID)); 
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);
		
		Format(sQuery, sizeof(sQuery), "SELECT * FROM player_saves WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", sSteamID, iTeam, iClass, sCurrentMap);

		SQL_TQuery(g_hDatabase, SQL_OnGetPlayerData, sQuery, iClient);
	}
}

stock SavePlayerData(iClient) { 
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];
		
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		
		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);

		new Float:fSaveLocation[MAXPLAYERS + 1][3];
		new Float:fSaveAngles[MAXPLAYERS + 1][3];
		
		GetClientAbsOrigin(iClient, fSaveLocation[iClient]);
		GetClientAbsAngles(iClient, fSaveAngles[iClient]);

		Format(sQuery, sizeof(sQuery), "INSERT INTO player_saves (steam_id, player_class, player_team, player_map, save1, save2, save3, save4, save5, save6) VALUES ('%s', '%d', '%d', '%s', '%f', '%f', '%f', '%f', '%f', '%f')", sSteamID, iClass, iTeam, sCurrentMap, fSaveLocation[iClient][0], fSaveLocation[iClient][1], fSaveLocation[iClient][2], fSaveAngles[iClient][0], fSaveAngles[iClient][1], fSaveAngles[iClient][2]);
		
		fSaveLocation[iClient] = Float:{0.0, 0.0, 0.0};
		fSaveAngles[iClient] = Float:{0.0, 0.0, 0.0};

		SQL_TQuery(g_hDatabase, SQL_OnDefaultCallback, sQuery, iClient);
	}
}

stock UpdatePlayerData(iClient) { 
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];
		
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		
		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);

		new Float:fSaveLocation[MAXPLAYERS + 1][3];
		new Float:fSaveAngles[MAXPLAYERS + 1][3];
		
		GetClientAbsOrigin(iClient, fSaveLocation[iClient]);
		GetClientAbsAngles(iClient, fSaveAngles[iClient]);

		Format(sQuery, sizeof(sQuery), "UPDATE player_saves SET save1 = '%f', save2 = '%f', save3 = '%f', save4 = '%f', save5 = '%f', save6 = '%f' WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", fSaveLocation[iClient][0], fSaveLocation[iClient][1], fSaveLocation[iClient][2], fSaveAngles[iClient][0], fSaveAngles[iClient][1], fSaveAngles[iClient][2], sSteamID, iTeam, iClass, sCurrentMap);
		
		fSaveLocation[iClient] = Float:{0.0, 0.0, 0.0};
		fSaveAngles[iClient] = Float:{0.0, 0.0, 0.0};

		SQL_TQuery(g_hDatabase, SQL_OnDefaultCallback, sQuery, iClient);
	}
}

stock DeletePlayerData(iClient) {
	if (GetConVarBool(g_hDatabaseSupport)) {
		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];
			
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
			
		new iTeam = GetClientTeam(iClient);
		new iClass = int:TF2_GetPlayerClass(iClient);

		Format(sQuery, sizeof(sQuery), "SELECT * FROM player_saves WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", sSteamID, iTeam, iClass, sCurrentMap);

		SQL_TQuery(g_hDatabase, SQL_OnDeletePlayerData, sQuery, iClient);
	}
}

/****************************************************************
			S Q L   C A L L B A C K   F U N C T I O N S
*****************************************************************/

public SQL_OnDefaultCallback(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) {
	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
	} else { 
		// Place Holder
	} 
}

public SQL_OnConnect(Handle:hOwner, Handle:hDatabase, const String:sError[], any:iData) { 
	if (hDatabase == INVALID_HANDLE) { 
		LogError("Database failure: %s", sError);
		SetFailState("Error: %s", sError);
	} else {
		g_hDatabase = hDatabase;

		// Database changed, reload clients
		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsClientInGame(iClient)) {
				new String:sSteamID[32];
				GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));

				LoadPlayerProfile(iClient, sSteamID);
				ReloadPlayerData(iClient);
			}
		}
	}
}

public SQL_OnLoadPlayerProfile(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) {
	new iClient = iData;

	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
		return false;
	} else if (SQL_GetRowCount(hTable)) {
		// Profile found, load the settings.

		SQL_FetchRow(hTable);
		new iHealthRegen = SQL_FetchInt(hTable, 2), iAmmoRegen = SQL_FetchInt(hTable, 3), iSuperman = SQL_FetchInt(hTable, 4);
		
		// Load the settings
		if (iHealthRegen == 1) {
		 	g_bDatabaseHealthEnabled[iClient] = true;
		} else {
			g_bDatabaseHealthEnabled[iClient] = false;
		}

		if (iAmmoRegen == 1) {
			g_bDatabaseAmmoEnabled[iClient] = true;
		} else {
			g_bDatabaseAmmoEnabled[iClient] = false;
		}

		if (iSuperman == 1) {
			g_bDatabaseSupermanEnabled[iClient] = true;

			SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
		} else {
			g_bDatabaseSupermanEnabled[iClient] = false;

			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		}

		g_bLoadedPlayerSettings[iClient] = true;
	
		return true;
	} else {
		// No profile found

		new String:sSteamID[32]; 

		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		CreatePlayerProfile(iClient, sSteamID);

		return false;
	}
}

public SQL_OnCreatePlayerProfile(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) {
	new iClient = iData;

	if (hTable == INVALID_HANDLE) {
		LogError("Query failed! %s", sError); 
		return false;
	}
	
	g_bDatabaseHealthEnabled[iClient] = false;
	g_bDatabaseAmmoEnabled[iClient] = false;

	g_bLoadedPlayerSettings[iClient] = false;

	return true;
}

public SQL_OnLoadPlayerData(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) { 
	new iClient = iData;

	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
		return false;
	} else if (SQL_GetRowCount(hTable)) {
		// Player data found

		SQL_FetchRow(hTable);
		g_fDatabaseSaveLocation[iClient][0] = SQL_FetchFloat(hTable, 0);
		g_fDatabaseSaveLocation[iClient][1] = SQL_FetchFloat(hTable, 1);
		g_fDatabaseSaveLocation[iClient][2] = SQL_FetchFloat(hTable, 2);

		g_fDatabaseSaveAngles[iClient][0] = SQL_FetchFloat(hTable, 3);
		g_fDatabaseSaveAngles[iClient][1] = SQL_FetchFloat(hTable, 4);
		g_fDatabaseSaveAngles[iClient][2] = SQL_FetchFloat(hTable, 5);
		
		if (!(g_fDatabaseSaveLocation[iClient][0] == 0.0 && g_fDatabaseSaveLocation[iClient][1] == 0.0 && g_fDatabaseSaveLocation[iClient][2] == 0.0)) {
			TeleportClient(iClient);
		}
	} 

	return true;
}

// Reload save position without teleporting
public SQL_OnReloadPlayerData(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) { 
	new iClient = iData;

	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
		return false;
	} else if (SQL_GetRowCount(hTable)) {
		// Player data found

		SQL_FetchRow(hTable);
		g_fDatabaseSaveLocation[iClient][0] = SQL_FetchFloat(hTable, 0);
		g_fDatabaseSaveLocation[iClient][1] = SQL_FetchFloat(hTable, 1);
		g_fDatabaseSaveLocation[iClient][2] = SQL_FetchFloat(hTable, 2);
		
		g_fDatabaseSaveAngles[iClient][0] = SQL_FetchFloat(hTable, 3);
		g_fDatabaseSaveAngles[iClient][1] = SQL_FetchFloat(hTable, 4);
		g_fDatabaseSaveAngles[iClient][2] = SQL_FetchFloat(hTable, 5);
	}

	return true;
}

public SQL_OnGetPlayerData(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) { 
	new iClient = iData;

	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
		return false;
	} else if (SQL_GetRowCount(hTable)) {
		// Player does exist, update

		UpdatePlayerData(iClient);	
	} else {
		// Player does not exist, create new

		SavePlayerData(iClient); 
	} 

	return true;
}

public SQL_OnDeletePlayerData(Handle:hOwner, Handle:hTable, const String:sError[], any:iData) {
	new iClient = iData;

	new iTeam = GetClientTeam(iClient);
	new iClass = int:TF2_GetPlayerClass(iClient);

	if (hTable == INVALID_HANDLE) { 
		LogError("Query failed! %s", sError); 
		return false;
	} else if (SQL_GetRowCount(hTable)) {
		// Found player data, erase from database

		SQL_FetchRow(hTable);

		new String:sQuery[512], String:sSteamID[32], String:sCurrentMap[50];
		
		GetClientAuthString(iClient, sSteamID, sizeof(sSteamID));
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		
		Format(sQuery, sizeof(sQuery), "DELETE FROM player_saves WHERE steam_id = '%s' AND player_team = '%d' AND player_class = '%d' AND player_map = '%s'", sSteamID, iTeam, iClass, sCurrentMap);
		SQL_TQuery(g_hDatabase, SQL_OnDefaultCallback, sQuery, iClient);

		EraseLocs(iClient);
		TF2_RespawnPlayer(iClient);

		PrintToChat(iClient, "\x04[Jump Menu] \x01You have been restarted.");
	} else {
		// Did not find player data on database
		
		EraseLocs(iClient);
		TF2_RespawnPlayer(iClient);

		PrintToChat(iClient, "\x04[Jump Menu] \x01You have been restarted.");
	}

	return true;
}

/****************************************************************
			S T O C K   F U N C T I O N S
*****************************************************************/

stock EraseLocs(iClient) {
	g_fDatabaseSaveLocation[iClient] = Float:{0.0, 0.0, 0.0};
	g_fDatabaseSaveAngles[iClient] = Float:{0.0, 0.0, 0.0};
}

stock TeleportClient(iClient, bool:bDontBroadcast=false) {
	new iClass = int:TF2_GetPlayerClass(iClient);
	new iTeam = GetClientTeam(iClient);

	new String:sClass[32], String:sTeam[32];

	new Float:fVelocity[3];
	fVelocity = Float:{0.0, 0.0, 0.0};

	switch (iClass) {
		case 1:	{ Format(sClass, sizeof(sClass), "Scout"); }
		case 2: { Format(sClass, sizeof(sClass), "Sniper"); }
		case 3: { Format(sClass, sizeof(sClass), "Soldier"); }
		case 4: { Format(sClass, sizeof(sClass), "Demoman"); }
		case 5: { Format(sClass, sizeof(sClass), "Medic"); }
		case 6: { Format(sClass, sizeof(sClass), "Heavy"); }
		case 7: { Format(sClass, sizeof(sClass), "Pyro"); }
		case 8: { Format(sClass, sizeof(sClass), "Spy"); }
		case 9: { Format(sClass, sizeof(sClass), "Engineer"); }
	}

	if (iTeam == 2) {
		sTeam = "Red Team";
	} else if (iTeam == 3) {
		sTeam = "Blue Team";
	}

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		if (!IsPlayerAlive(iClient)) {
			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You must be alive to teleport.");
		} else if (g_fSaveLocation[iClient][GetClientTeam(iClient)][GetClientClass(iClient)][0] == 0.0) {
			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You don't have a save for \x03%s\x01 on the \x03%s\x01.", sClass, sTeam);
		} else {
			TeleportEntity(iClient, g_fSaveLocation[iClient][GetClientTeam(iClient)][GetClientClass(iClient)], g_fSaveAngles[iClient][GetClientTeam(iClient)][GetClientClass(iClient)], fVelocity);

			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You have been teleported.");
		}
	}

	else { // Database support enabled
		if (!IsPlayerAlive(iClient)) {
			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You must be alive to teleport.");
		} else if (g_fDatabaseSaveLocation[iClient][0] == 0.0 && g_fDatabaseSaveLocation[iClient][1] == 0.0 && g_fDatabaseSaveLocation[iClient][2] == 0.0) {
			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You don't have a save for \x03%s\x01 on the \x03%s\x01.", sClass, sTeam);
		} else {
			TeleportEntity(iClient, g_fDatabaseSaveLocation[iClient], g_fDatabaseSaveAngles[iClient], fVelocity);

			if (!bDontBroadcast) PrintToChat(iClient, "\x04[Jump Menu] \x01You have been teleported.");
		}
	}
}

stock GetClientClass(iClient) {
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	return _:iClass;
}

stock StartAnnounce() {
	if (g_hAnnounceTimer != INVALID_HANDLE) {
		CloseHandle(g_hAnnounceTimer);
		g_hAnnounceTimer = INVALID_HANDLE;
	}

	if (GetConVarFloat(g_hAnnounce) == 0) 
		return;

	if (GetConVarFloat(g_hAnnounce) < 0) {
		PrintToServer("[Jump Menu] Invalid announce time set ('sm_jmenu_announce', value: '%f')", GetConVarFloat(g_hAnnounce));
		return;
	}

	if (g_hAnnounceTimer == INVALID_HANDLE) {
		g_hAnnounceTimer = CreateTimer(GetConVarFloat(g_hAnnounce), Timer_Announce, _, TIMER_REPEAT);
	}
}

stock StartAmmoRegen() {
	if (g_hAmmoTimer != INVALID_HANDLE) {
		CloseHandle(g_hAmmoTimer);
		g_hAmmoTimer = INVALID_HANDLE;
	}

	if (GetConVarFloat(g_hAmmo) == 0) 
		return;

	if (GetConVarFloat(g_hAmmo) < 0) {
		PrintToServer("[Jump Menu] Invalid ammo interval set ('sm_jmenu_ammo', value: '%f')", GetConVarFloat(g_hAmmo));
		return;
	}

	if (g_hAmmoTimer == INVALID_HANDLE) {
		g_hAmmoTimer = CreateTimer(GetConVarFloat(g_hAmmo), Timer_AmmoRegen, _, TIMER_REPEAT);
	}
}

stock StartCaberReset() {
	if (g_hCaberTimer != INVALID_HANDLE) {
		CloseHandle(g_hCaberTimer);
		g_hCaberTimer = INVALID_HANDLE;
	}

	if (GetConVarFloat(g_hCaber) == 0) 
		return;

	if (GetConVarFloat(g_hCaber) < 0) {
		PrintToServer("[Jump Menu] Invalid caber interval set ('sm_jmenu_caber', value: '%f')", GetConVarFloat(g_hCaber));
		return;
	}

	if (g_hCaberTimer == INVALID_HANDLE) {
		g_hCaberTimer = CreateTimer(GetConVarFloat(g_hCaber), Timer_CaberReset, _, TIMER_REPEAT);
	}
}

stock StartHealthRegen() {
	if (g_hHealthTimer != INVALID_HANDLE) {
		CloseHandle(g_hHealthTimer);
		g_hHealthTimer = INVALID_HANDLE;
	}

	if (GetConVarFloat(g_hHealth) == 0) 
		return;

	if (GetConVarFloat(g_hHealth) < 0) {
		PrintToServer("[Jump Menu] Invalid ammo interval set ('sm_jmenu_health', value: '%f')", GetConVarFloat(g_hHealth));
		return;
	}

	if (g_hHealthTimer == INVALID_HANDLE) {
		g_hHealthTimer = CreateTimer(GetConVarFloat(g_hHealth), Timer_HealthRegen, _, TIMER_REPEAT);
	}
}

stock bool:IsValidClient(iClient, bool:bInGameOnly=false) {
	return (iClient > 0 && iClient <= MaxClients && bInGameOnly ? (IsClientConnected(iClient) && IsClientInGame(iClient)) : true);
}

stock ResupplyClient(iClient) {
	if (!IsValidClient(iClient, true)) 
		return;

	new iWeapon[2];
	iWeapon[TFWeaponSlot_Primary] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
	iWeapon[TFWeaponSlot_Secondary] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);

	if (!IsValidEntity(iWeapon[TFWeaponSlot_Primary]))
		return;

	// Primary Weapons
	switch (GetEntProp(iWeapon[TFWeaponSlot_Primary], Prop_Send, "m_iItemDefinitionIndex")) {

		// Rocket Launchers
		case 18, 127, 205, 513, 658, 800, 809, 889, 898, 907, 916, 965, 974: {
			SetClientClip(iClient, TFWeaponSlot_Primary, 4);
			SetClientAmmo(iClient, TFWeaponSlot_Primary, 20);
		}
		
		// Black Box, Liberty Launcher
		case 228, 414: {
			SetClientClip(iClient, TFWeaponSlot_Primary, 3);
			SetClientAmmo(iClient, TFWeaponSlot_Primary, 20);
		}
		
		// Rocket Jumper
		case 237: {
			SetClientClip(iClient, TFWeaponSlot_Primary, 4);
			SetClientAmmo(iClient, TFWeaponSlot_Primary, 60);
		}

		// Flamethrowers
		case 21, 40, 208, 215, 594, 659, 741, 798, 807, 887, 896, 905, 914, 963, 972: {
			SetClientClip(iClient, TFWeaponSlot_Primary, 200);
		}

		// Force-A-Nature
		case 45: {
			SetClientAmmo(iClient, TFWeaponSlot_Primary, 32);
		}
	}

	if (!IsValidEntity(iWeapon[TFWeaponSlot_Secondary]))
		return;

	// Secondary Weapons
	switch (GetEntProp(iWeapon[TFWeaponSlot_Secondary], Prop_Send, "m_iItemDefinitionIndex")) {

		// Stickybomb Launchers
		case 20, 207, 661, 797, 806, 886, 895, 904, 913, 962, 971: {
			SetClientClip(iClient, TFWeaponSlot_Secondary, 8);
			SetClientAmmo(iClient, TFWeaponSlot_Secondary, 24);
		}
		
		// Sticky Jumper
		case 265: {
			SetClientClip(iClient, TFWeaponSlot_Secondary, 8);
			SetClientAmmo(iClient, TFWeaponSlot_Secondary, 72);
		}
		
		// Scottish Resistance
		case 130: {	
			SetClientClip(iClient, TFWeaponSlot_Secondary, 8);
			SetClientAmmo(iClient, TFWeaponSlot_Secondary, 36);
		}
		
		// Shotguns
		case 9, 10, 12, 199: {
			SetClientClip(iClient, TFWeaponSlot_Secondary, 6);
			SetClientAmmo(iClient, TFWeaponSlot_Secondary, 32);
		}

		// Reserve Shooter
		case 415: {
			SetClientClip(iClient, TFWeaponSlot_Secondary, 3);
			SetClientAmmo(iClient, TFWeaponSlot_Secondary, 32);
		}
	}
}

stock GetClientClip(iClient, iSlot) {	
	if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
		new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		
		if (IsValidEntity(iWeapon)) {
			return GetEntProp(iWeapon, Prop_Send, "m_iClip1");
		}
	}

	return -1;
}

stock SetClientClip(iClient, iSlot, iClip) {	
	if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
		new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		
		if (IsValidEntity(iWeapon)) {
			new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
			SetEntData(iWeapon, iAmmoTable, iClip, 4, true);
		}
	}
}

stock SetClientAmmo(iClient, iSlot, iAmmo) {
	if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
		new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);

		if (IsValidEntity(iWeapon)) {
			new iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");

			if (iAmmoType != -1) {
				SetEntProp(iClient, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
			}
		}
	}
}

stock SetClientHealth(iClient) {
	if (GetConVarInt(g_hHealthMode) <= 0) {
		new TFClassType:iClass = TF2_GetPlayerClass(iClient);

		SetEntityHealth(iClient, g_iClassMaxHealth[iClass]);
	} else {
		SetEntityHealth(iClient, GetConVarInt(g_hHealthMode));
	}
}

stock SetClientMetal(iClient, iMetal) {
	SetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), iMetal, 4);
}

stock ShowSettings(iClient) {
	new String:sHint[128];

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		if (g_bHealthEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "HP-Regen: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "HP-Regen: OFF\n");
		}

		if (g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Ammo-Regen: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Ammo-Regen: OFF\n");
		}

		if (g_bSupermanEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Superman: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Superman: OFF\n");
		}
	}

	else { // Database support enabled
		if (g_bDatabaseHealthEnabled[iClient]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "HP-Regen: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "HP-Regen: OFF\n");
		}

		if (g_bDatabaseAmmoEnabled[iClient]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Ammo-Regen: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Ammo-Regen: OFF\n");
		}

		if (g_bDatabaseSupermanEnabled[iClient]) {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Superman: ON\n");
		} else {
			Format(sHint, sizeof(sHint), "%s%s", sHint, "Superman: OFF\n");
		}
	}

	PrintHintText(iClient, sHint);
}

stock bool:IsClientAdmin(iClient) { 
	return CheckCommandAccess(iClient, "generic_admin", ADMFLAG_GENERIC, false);
}  

/****************************************************************
			T I M E R S
*****************************************************************/

public Action:Timer_TeleportClient(Handle:hTimer, any:iClient) {
	if (!IsValidClient(iClient, true))
		return Plugin_Handled;

	TeleportClient(iClient, true);

	return Plugin_Handled;
}

public Action:Timer_ShowSettings(Handle:hTimer, any:iClient) {
	if (!IsValidClient(iClient, true))
		return Plugin_Handled;

	ShowSettings(iClient);

	return Plugin_Handled;
}

public Action:Timer_PlayerChangeTeam(Handle:hTimer, any:iClient) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	EraseLocs(iClient);

	return Plugin_Handled;
}

public Action:Timer_Announce(Handle:hTimer) {
	PrintToChatAll("\x04[Jump Menu] \x01Type \x04!jmenu \x01to open the Jump Menu.");
}

public Action:Timer_AmmoRegen(Handle:hTimer) {
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
			if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
				if (g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
					/*SetClientClip(iClient, 0, 99);
					SetClientClip(iClient, 1, 99);
					SetClientMetal(iClient, 200);*/
					ResupplyClient(iClient);
				}
			} 

			else { // Database support enabled
				if (g_bDatabaseAmmoEnabled[iClient]) {
					/*SetClientClip(iClient, 0, 99);
					SetClientClip(iClient, 1, 99);
					SetClientMetal(iClient, 200);*/
					ResupplyClient(iClient);
				}
			}

			//SetClientAmmo(iClient, 0, 99);
			//SetClientAmmo(iClient, 1, 99);
		}	
	}
}

public Action:Timer_CaberReset(Handle:hTimer) {
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
			if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
				if (g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
					if (TF2_GetPlayerClass(iClient) == TFClass_DemoMan) {					
						// Check if the melee weapon is the Caber
						if (GetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iItemDefinitionIndex") == 307) {
							// Check if the Caber has been used							
							if (GetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iDetonated") == 1) {
								SetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iDetonated", 0);
							}
						}
					}
				}
			}

			else { // Database support enabled
				if (g_bDatabaseAmmoEnabled[iClient]) {
					if (TF2_GetPlayerClass(iClient) == TFClass_DemoMan) {
						// Check if the melee weapon is the Caber
						if (GetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iItemDefinitionIndex") == 307) {
							// Check if the Caber has been used							
							if (GetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iDetonated") == 1) {
								SetEntProp(GetPlayerWeaponSlot(iClient, 2), Prop_Send, "m_iDetonated", 0);
							}
						}
					}
				}
			}
		}	
	}
}

public Action:Timer_HealthRegen(Handle:hTimer) {
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsValidClient(iClient) && IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
			if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
				if (g_bHealthEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
					SetClientHealth(iClient);
				}
			} 

			else { // Database support enabled
				if (g_bDatabaseHealthEnabled[iClient]) {
					SetClientHealth(iClient);
				}
			}
		}	
	}
}

/****************************************************************
			C L I E N T   C O M M A N D S
*****************************************************************/

public Action:Command_AmmoRegen(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (GetConVarFloat(g_hAmmo) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Ammo-Regen is not enabled.");
		return Plugin_Handled;
	}

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		if (g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			// Turned off
			PrintToChat(iClient, "\x04[Jump Menu] \x07FF2A2AYou turned Ammo-Regen off.");

			SetClientClip(iClient, 0, g_iAmmoRestore[iClient][GetClientTeam(iClient)][GetClientClass(iClient)][0]);
			SetClientClip(iClient, 1, g_iAmmoRestore[iClient][GetClientTeam(iClient)][GetClientClass(iClient)][1]);

			g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = false;
		} else {
			// Turned on
			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned Ammo-Regen on.");

			g_iAmmoRestore[iClient][GetClientTeam(iClient)][GetClientClass(iClient)][0] = GetClientClip(iClient, 0);
			g_iAmmoRestore[iClient][GetClientTeam(iClient)][GetClientClass(iClient)][1] = GetClientClip(iClient, 1);

			g_bAmmoEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = true;
		}
	} 

	else { // Database support enabled
		if (g_bDatabaseAmmoEnabled[iClient]) {
			// Turned off
			PrintToChat(iClient, "\x04[Jump Menu] \x07FF2A2AYou turned Ammo-Regen off.");

			SetClientClip(iClient, 0, g_iDatabaseAmmoRestore[iClient][0]);
			SetClientClip(iClient, 1, g_iDatabaseAmmoRestore[iClient][1]);

			g_bDatabaseAmmoEnabled[iClient] = false;
		} else {
			// Turned on
			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned Ammo-Regen on.");

			g_iDatabaseAmmoRestore[iClient][0] = GetClientClip(iClient, 0);
			g_iDatabaseAmmoRestore[iClient][1] = GetClientClip(iClient, 1);

			g_bDatabaseAmmoEnabled[iClient] = true;
		}

		UpdatePlayerProfile(iClient);
	}

	return Plugin_Handled;
}

public Action:Command_HealthRegen(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (GetConVarFloat(g_hHealth) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01HP-Regen is not enabled.");
		return Plugin_Handled;
	}

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		if (g_bHealthEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			// Turned off
			PrintToChat(iClient, "\x04[Jump Menu] \x07FF0000You turned HP-Regen off.");

			new TFClassType:iClass = TF2_GetPlayerClass(iClient);
			SetEntityHealth(iClient, g_iClassMaxHealth[iClass]);

			g_bHealthEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = false;
		} else {
			// Turned on
			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned HP-Regen on.");

			g_bHealthEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = true;
		}
	} 

	else { // Database support enabled
		if (g_bDatabaseHealthEnabled[iClient]) {
			// Turned off
			PrintToChat(iClient, "\x04[Jump Menu] \x07FF0000You turned HP-Regen off.");

			new TFClassType:iClass = TF2_GetPlayerClass(iClient);
			SetEntityHealth(iClient, g_iClassMaxHealth[iClass]);

			g_bDatabaseHealthEnabled[iClient] = false;
		} else {
			// Turned on
			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned HP-Regen on.");

			g_bDatabaseHealthEnabled[iClient] = true;
		}

		UpdatePlayerProfile(iClient);
	}

	return Plugin_Handled;
}

public Action:Command_Superman(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (GetConVarFloat(g_hSuperman) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Superman-Feature is not enabled.");
		return Plugin_Handled;
	}

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		if (g_bSupermanEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]) {
			// Turned off
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);

			PrintToChat(iClient, "\x04[Jump Menu] \x07FF0000You turned Superman off.");

			g_bSupermanEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = false;
		} else {
			// Turned on
			SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);

			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned Superman on.");

			g_bSupermanEnabled[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = true;
		}
	} 

	else { // Database support enabled
		if (g_bDatabaseSupermanEnabled[iClient]) {
			// Turned off
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);

			PrintToChat(iClient, "\x04[Jump Menu] \x07FF0000You turned Superman off.");

			g_bDatabaseSupermanEnabled[iClient] = false;
		} else {
			// Turned on
			SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);

			PrintToChat(iClient, "\x04[Jump Menu] \x03You turned Superman on.");

			g_bDatabaseSupermanEnabled[iClient] = true;
		}

		UpdatePlayerProfile(iClient);
	}

	return Plugin_Handled;
}

public Action:Command_Save(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (GetConVarFloat(g_hSave) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Save-Teleport-Feature is not enabled.");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't save your position while being dead.");
		return Plugin_Handled;
	}

	if (!(GetEntityFlags(iClient) & FL_ONGROUND)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't save your position while flying around.");
		return Plugin_Handled;
	}

	if (GetEntProp(iClient, Prop_Send, "m_bDucked") == 1) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't save your position while crouching.");
		return Plugin_Handled;
	}

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		GetClientAbsOrigin(iClient, g_fSaveLocation[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]);
		GetClientAbsAngles(iClient, g_fSaveAngles[iClient][GetClientTeam(iClient)][GetClientClass(iClient)]);
		g_bSavedOnce[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = true;
	} 

	else { // Database support enabled
		GetClientAbsOrigin(iClient, g_fDatabaseSaveLocation[iClient]);
		GetClientAbsAngles(iClient, g_fDatabaseSaveAngles[iClient]);
		GetPlayerData(iClient);
	}

	PrintToChat(iClient, "\x04[Jump Menu] \x01Your position has been saved.");

	return Plugin_Handled;
}

public Action:Command_Teleport(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (GetConVarFloat(g_hSave) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Save-Teleport-Feature is not enabled.");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't teleport while being dead.");
		return Plugin_Handled;
	}

	TeleportClient(iClient);

	return Plugin_Handled;
}

public Action:Command_Goto(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (!IsClientAdmin(iClient))
		return Plugin_Handled;

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't use goto while being dead.");
		return Plugin_Handled;
	}

	if (iArgs != 1) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Usage: !goto <target>");
		return Plugin_Handled;
	}

	new String:sTarget[MAX_NAME_LENGTH + 1];
	new iTarget = -1;

	GetCmdArg(1, sTarget, sizeof(sTarget));
	iTarget = FindTarget(iClient, sTarget);

	if (iTarget > 1 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget)) {
		new Float:fTargetLocation[3], Float:fTargetAngles[3], Float:fVelocity[3];
		GetClientAbsOrigin(iTarget, fTargetLocation);
		GetClientAbsAngles(iTarget, fTargetAngles);
		fVelocity = Float:{0.0, 0.0, 0.0};

		TeleportEntity(iClient, fTargetLocation, fTargetAngles, fVelocity);

		PrintToChat(iClient, "\x04[Jump Menu] \x01You have been teleported to %N.", iTarget);
		PrintToChat(iTarget, "\x04[Jump Menu] \x01%N has teleported to you.", iClient);
	} else {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Couldn't find player %s.", sTarget);
	}

	return Plugin_Handled;
}

public Action:Command_Send(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (!IsClientAdmin(iClient))
		return Plugin_Handled;
	
	if (iArgs != 2) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Usage: !send <target> <destination target>");
		return Plugin_Handled;
	}

	new String:sTarget[MAX_NAME_LENGTH + 1], String:sDestinationTarget[MAX_NAME_LENGTH + 1];
	new iTarget = -1, iDestinationTarget = -1;

	GetCmdArg(1, sTarget, sizeof(sTarget));
	iTarget = FindTarget(iClient, sTarget);

	GetCmdArg(2, sDestinationTarget, sizeof(sDestinationTarget));
	iDestinationTarget = FindTarget(iClient, sDestinationTarget);

	if (iTarget < 1 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Couldn't find player %s.", sTarget);
		return Plugin_Handled;
	}

	if (iDestinationTarget < 1 || iDestinationTarget > MaxClients || !IsClientInGame(iDestinationTarget) || !IsPlayerAlive(iDestinationTarget)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Couldn't find player %s.", sDestinationTarget);
		return Plugin_Handled;
	}

	new Float:fDestinationTargetLocation[3], Float:fDestinationTargetAngles[3], Float:fVelocity[3];
	GetClientAbsOrigin(iDestinationTarget, fDestinationTargetLocation);
	GetClientAbsAngles(iDestinationTarget, fDestinationTargetAngles);
	fVelocity = Float:{0.0, 0.0, 0.0};

	TeleportEntity(iTarget, fDestinationTargetLocation, fDestinationTargetAngles, fVelocity);

	PrintToChat(iTarget, "\x04[Jump Menu] \x01You have been teleported to %N.", iDestinationTarget);
	PrintToChat(iDestinationTarget, "\x04[Jump Menu] \x01%N has been teleported to you.", iTarget);

	return Plugin_Handled;
}

public Action:Command_Reset(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't reset while being dead.");
		return Plugin_Handled;
	}

	// Only teleport back to start

	g_bHasReset[iClient] = true;

	TF2_RespawnPlayer(iClient);

	PrintToChat(iClient, "\x04[Jump Menu] \x01You have been teleported back to the start.");

	return Plugin_Handled;
}

public Action:Command_Restart(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01You can't restart while being dead.");
		return Plugin_Handled;
	}

	if (GetConVarFloat(g_hSave) <= 0) {
		PrintToChat(iClient, "\x04[Jump Menu] \x01Save-Teleport-Feature is not enabled.");
		return Plugin_Handled;
	}

	// Reset the saved position and teleport back to start

	if (!GetConVarBool(g_hDatabaseSupport)) { // Database support disabled
		g_fSaveLocation[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = Float:{0.0, 0.0, 0.0};
		g_fSaveAngles[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = Float:{0.0, 0.0, 0.0};
		g_bSavedOnce[iClient][GetClientTeam(iClient)][GetClientClass(iClient)] = false;
	} 

	else { // Database support enabled
		g_fDatabaseSaveLocation[iClient] = Float:{0.0, 0.0, 0.0};
		g_fDatabaseSaveAngles[iClient] = Float:{0.0, 0.0, 0.0};

		DeletePlayerData(iClient);
	}

	TF2_RespawnPlayer(iClient);

	PrintToChat(iClient, "\x04[Jump Menu] \x01Your save has been deleted and you have been teleported back to the start.");

	return Plugin_Handled;
}

public Action:Command_Menu(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	new Handle:hMenu = CreateMenu(MenuHandler);
	SetMenuTitle(hMenu, "Jump Menu by floube (v%s)", PLUGIN_VERSION);

	AddMenuItem(hMenu, "health", "Toggle HP-Regen (or !hp)");
	AddMenuItem(hMenu, "ammo", "Toggle Ammo-Regen (or !ammo)");
	AddMenuItem(hMenu, "superman", "Toggle Superman (or !superman)");
	AddMenuItem(hMenu, "save", "Save current location (or !s)");
	AddMenuItem(hMenu, "teleport", "Teleport to saved location (or !t)");
	AddMenuItem(hMenu, "reset", "Teleport to the beginning (or !reset)");
	AddMenuItem(hMenu, "restart", "Delete save and teleport back (or !restart)");
	AddMenuItem(hMenu, "settings", "Show your current settings");
	AddMenuItem(hMenu, "help", "Show help");

	SetMenuExitButton(hMenu, true);

	DisplayMenu(hMenu, iClient, 0);

	return Plugin_Handled;
}

public Action:Command_Settings(iClient, iArgs) {
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	ShowSettings(iClient);

	return Plugin_Handled;
}

/****************************************************************
			M E N U   H A N D L E R
*****************************************************************/

public MenuHandler(Handle:hMenu, MenuAction:mAction, iClient, iSelect) {
	if (mAction == MenuAction_Select) {
		new String:sSelectName[32];
		GetMenuItem(hMenu, iSelect, sSelectName, sizeof(sSelectName));

		if (StrEqual(sSelectName, "health")) {
			ClientCommand(iClient, "sm_regen");

		} else if (StrEqual(sSelectName, "ammo")) {
			ClientCommand(iClient, "sm_ammo");

		} else if (StrEqual(sSelectName, "superman")) {
			ClientCommand(iClient, "sm_superman");

		} else if (StrEqual(sSelectName, "save")) {
			ClientCommand(iClient, "sm_save");

		} else if (StrEqual(sSelectName, "teleport")) {
			ClientCommand(iClient, "sm_teleport");

		} else if (StrEqual(sSelectName, "reset")) {
			ClientCommand(iClient, "sm_reset");

		} else if (StrEqual(sSelectName, "restart")) {
			ClientCommand(iClient, "sm_restart");

		} else if (StrEqual(sSelectName, "settings")) {
			ClientCommand(iClient, "sm_jsettings");

		} else if (StrEqual(sSelectName, "help")) {
			PrintToChat(iClient, "\x04[Jump Menu] \x01See console for output.");

			new String:sConsoleOutput[2048];
			
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "\n-------------------------------------------------------\n");
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "              Jump Menu by floube (v%s)              ");
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "\n-------------------------------------------------------\n");

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			if (GetConVarFloat(g_hHealth) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  HP-Regen enabled");
				
				if (GetConVarFloat(g_hHealthMode) <= 0) {
					Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "    > Heals up to maximum class HP");
				} else {
					Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s%d\n", sConsoleOutput, "    > Heals up to ", GetConVarInt(g_hHealthMode));
				}
			} else {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  HP-Regen disabled");
			}

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);
			
			if (GetConVarFloat(g_hAmmo) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Ammo-Regen enabled");
				
				if (GetConVarFloat(g_hCaber) > 0) {
					Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "    > Caber-Reset enabled");
				} else {
					Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "    > Caber-Reset disabled");
				}
			} else {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Ammo-Regen disabled");
			}
			
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			if (GetConVarFloat(g_hSave) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Save-Teleport-Feature enabled");
			} else {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Save-Teleport-Feature disabled");
			}

			if (GetConVarFloat(g_hSounds) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Sounds enabled");
			} else {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  Sounds disabled");
			}
						
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "\n-------------------------------------------------------\n");
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "                   Command Overview                    ");
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "\n-------------------------------------------------------\n");

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			if (GetConVarFloat(g_hHealth) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !hp, !regen \t\t\t\t\t Regenerates your HP.");
			}

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);
			
			if (GetConVarFloat(g_hAmmo) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !ammo \t\t\t\t\t Regenerates your ammo.");
			}
			
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			if (GetConVarFloat(g_hSuperman) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !superman \t\t\t\t\t Makes you strong like superman.");
			}
			
			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			if (GetConVarFloat(g_hSave) > 0) {
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !s, !save, !jm_saveloc \t\t\t Saves your current location.");
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !t, !tp, !tele, !teleport, !jm_teleport \t Teleports you to your saved location.");
				Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !restart \t\t\t\t\t Sends you back to the beginning and deletes your save.");
			}

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !reset \t\t\t\t\t Sends you back to the beginning without deleting your save.");

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !jmenu \t\t\t\t\t Opens the Jump Menu.");

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s\n", sConsoleOutput);

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s\n", sConsoleOutput, "  !jsettings \t\t\t\t\t Shows your current jump settings.");

			Format(sConsoleOutput, sizeof(sConsoleOutput), "%s%s", sConsoleOutput, "\n-------------------------------------------------------\n");

			PrintToConsole(iClient, sConsoleOutput);
		}

		Command_Menu(iClient, 0);		
	} else if (mAction == MenuAction_End) {
		// If the menu has ended, destroy it

		CloseHandle(hMenu);
	}
}