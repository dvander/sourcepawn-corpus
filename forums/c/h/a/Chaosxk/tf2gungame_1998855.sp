/*
	v.1.2.1
	- Fixes -1 entity call stack error
	
	v.1.2.0
	- Fixed tfgg_model and tfgg_resize not resetting players back to normal
	- Fixed config not reloading properly on map change
	- Fixed flamethrower afterburn from doing damage after you upgraded to the next level
	- Changed the default value for gungame_weapons.cfg "enabled" to 0, so if "enabled" is not specified then the plugin will disable
	- Fixed translation files having a different plugin name
	- Added map prefixes like... koth_ or gg_
	- Fixed issue with errors and plugin not disabling if map change to something not in gungame_maps.cfg
	
	v.1.1.0
	- Renamed plugin since it was too similar with the other one
	- Added tf2attributes, tf2itemsinfo
	- You can now add attributes to each weapons, see o.p on gungame_weapons.cfg for details
	- Renamed levels_config to weapons_config in the gungame_maps.cfg
	- Renamed gungame_levels.cfg to gungame_weapons.cfg
	- Fixed ctf_ maps where winning does not reset the round
	- Added HUD display of levels
*/

#pragma semicolon 1
#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2items_giveweapon>
#include <tf2items>
#include <sdkhooks>
#include <clientprefs>
#include <morecolors>
#include <tf2attributes>
#include <tf2itemsinfo>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.2.1"
#define SND_WARNING "gungame/warning.mp3"
#define	SND_STAGE_CLEAR "gungame/stage_clear.wav"
#define SND_LEVEL_DOWN "gungame/level_down.wav"
#define SND_LEVEL_UP "gungame/level_up.wav"
#define SND_WARNING2 "sound/gungame/warning.mp3"
#define	SND_STAGE_CLEAR2 "sound/gungame/stage_clear.wav"
#define SND_LEVEL_DOWN2 "sound/gungame/level_down.wav"
#define SND_LEVEL_UP2 "sound/gungame/level_up.wav"
#define UPDATE_URL "http://dl.dropboxusercontent.com/u/100132876/tf2gungame.txt"

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarLevel = INVALID_HANDLE;
new Handle:cvarAssist = INVALID_HANDLE;
new Handle:cvarDelevel = INVALID_HANDLE;
new Handle:cvarResize = INVALID_HANDLE;
new Handle:cvarModel = INVALID_HANDLE;
new Handle:hudText = INVALID_HANDLE;
new Handle:GunGameCookies = INVALID_HANDLE;

new String:LevelConfigs[PLATFORM_MAX_PATH];
new TFClassType:WeaponClass[PLATFORM_MAX_PATH];
new Weapon[PLATFORM_MAX_PATH];
new Float:PlayerSize[PLATFORM_MAX_PATH];
new String:PlayerModel[PLATFORM_MAX_PATH][PLATFORM_MAX_PATH];
new String:Attributes[PLATFORM_MAX_PATH][PLATFORM_MAX_PATH];

new clientRank[MAXPLAYERS+1];
new assistLevel[MAXPLAYERS+1];
new delevel[MAXPLAYERS+1];
new playerCookie[MAXPLAYERS+1];
new bool:g_joined[MAXPLAYERS+1]; 
new g_iSetScore[MAXPLAYERS+1] = { 0, ... };

new hasWinner;
new bool:lateLoaded;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	lateLoaded = late;
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "[TF2] TFGunGame",
	author = "Tak (Chaosxk)",
	description = "A working, original gamemode for TF2, Gungame.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() {
	CreateConVar("tfgg_version", PLUGIN_VERSION, "Plugin Version of TFGungame", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("tfgg_enabled", "1", "Enable or disable this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarLevel = CreateConVar("tfgg_level", "26", "How many levels should be played before a winner is announced?");
	cvarAssist = CreateConVar("tfgg_assist", "2", "How many assists before a player levels up? (0 - Disable)");
	cvarDelevel = CreateConVar("tfgg_delevel", "3", "How many deaths before a player delevels? (0 - Disable)");
	cvarResize = CreateConVar("tfgg_resize", "1", "Allows player to resize from the levels config. (0 - Disable)" , FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarModel = CreateConVar("tfgg_model", "1", "Allows player to change model from the levels config. (0 - Disable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath);
	HookConVarChange(cvarEnabled, cvarChange);
	HookConVarChange(cvarResize, cvarChange);
	HookConVarChange(cvarModel, cvarChange);
	
	RegAdminCmd("tfgg_reload_configs", ReloadConfig, ADMFLAG_GENERIC, "Reloads both the map and levels config.");
	GunGameCookies = RegClientCookie("tf2gungamecookies", "GunGame Cookies.", CookieAccess_Public);
	AddCommandListener(ClassListener, "joinclass"); 
	
	LoadTranslations("common.phrases");
	LoadTranslations("tf2gungame.phrases");
	
	AutoExecConfig(true, "tf2gungame");
	
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnPluginEnd() {
	UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", OnPlayerDeath);
	
	UnhookConVarChange(cvarEnabled, cvarChange);
	UnhookConVarChange(cvarResize, cvarChange);
	UnhookConVarChange(cvarModel, cvarChange);
	
	RemoveCommandListener(ClassListener, "joinclass"); 
	EnableLockerRoom();
}

public OnMapStart() {
	AddFileToDownloadsTable(SND_WARNING2);
	AddFileToDownloadsTable(SND_STAGE_CLEAR2);
	AddFileToDownloadsTable(SND_LEVEL_DOWN2);
	AddFileToDownloadsTable(SND_LEVEL_UP2);
	PrecacheSound(SND_WARNING, true);
	PrecacheSound(SND_STAGE_CLEAR, true);
	PrecacheSound(SND_LEVEL_DOWN, true);
	PrecacheSound(SND_LEVEL_UP, true);
	
	new iIndex = FindEntityByClassname(MaxClients+1, "tf_player_manager");
	if(iIndex == -1) {
		new ent = CreateEntityByName("tf_player_manager");
		SDKHook(ent, SDKHook_ThinkPost, Hook_OnThinkPost);
	}
	else SDKHook(iIndex, SDKHook_ThinkPost, Hook_OnThinkPost);
}

public OnLibraryAdded(const String:name[]) {
	if(StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnConfigsExecuted() {
	SetUpGungameMap("gungame_maps.cfg");
	if(lateLoaded) {
		new bool:enabled = GetConVarBool(cvarEnabled);
		switch(enabled) {
			case true: {
				SetFlags(0);
				DisableLockerRoom();
			}
			case false: {
				SetFlags(1);
				EnableLockerRoom();
			}
		}
		for(new i = 1; i <= MaxClients; i++) {
			if(IsValidClient(i)) {
				GetCookie(i);
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		hasWinner = 0;
		lateLoaded = false;
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarEnabled) {
		switch(StringToInt(newValue)) {
			case 0: {
				EnableLockerRoom();
				SetFlags(1);
			}
			case 1: {
				DisableLockerRoom();
				SetFlags(0);
			}
		}
	}
	else if(convar == cvarResize) {
		if(StringToInt(newValue) == 0) {
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
				}
			}
		}
	}
	else if(convar == cvarModel) {
		if(StringToInt(newValue) == 0) {
			for(new i = 1; i <= MaxClients; i++) {
				if(IsValidClient(i)) {
					SetVariantString("");
					AcceptEntityInput(i, "SetCustomModel");
				}
			}
		}
	}
}

public OnClientPostAdminCheck(client) {
	ResetClientVariables(client);
	g_joined[client] = false; 
	GetCookie(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public TF2_OnWaitingForPlayersEnd() {
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i)) return;
		clientRank[i] = 0;
		g_iSetScore[i] = 0;
	}
}

public Action:ReloadConfig(client, args) {
	SetUpGungameMap("gungame_maps.cfg");
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) {
	if(GetConVarBool(cvarEnabled)) {
		if(IsValidClient(attacker) && IsValidEntity(weapon)) {
			new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			new wep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(wep)) {
				new wepIndex = GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex");
				if(wepIndex != weaponIndex) {
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Hook_OnThinkPost(iEnt) {
	static iTotalScoreOffset = -1;
	if (iTotalScoreOffset == -1) {
		iTotalScoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");
	}
	new iTotalScore[MAXPLAYERS+1];
	GetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && g_iSetScore[i] > -1) {
			iTotalScore[i] = g_iSetScore[i];
		}
	}  
	SetEntDataArray(iEnt, iTotalScoreOffset, iTotalScore, MaxClients+1);
}

public Action:OnRoundStart(Handle:event, String:name[], bool:dontBroadcast) {
	if(!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	SetFlags(0);
	DisableLockerRoom();
	hasWinner = 0;
	return Plugin_Continue;
}

public Action:ClassListener(client, const String:command[], args) {
	if(!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	if(!IsValidClient(client)) return Plugin_Continue; 
	if(g_joined[client]) return Plugin_Continue;
	CPrintToChat(client, "%t", "Connect", PLUGIN_VERSION);
	g_joined[client] = true; 
	return Plugin_Continue; 
}  

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	if(!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
	GiveClientWeapons(client);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	if(!GetConVarBool(cvarEnabled)) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new level = GetConVarInt(cvarLevel)-1;
	if(hasWinner == 1) return Plugin_Continue;
	if(IsValidClient(client)) {
		if(GetConVarInt(cvarDelevel) > 0) {
			delevel[client]++;
			if(GetConVarInt(cvarDelevel) == delevel[client]) {
				delevel[client] = 0;
				if(clientRank[client] > 0) {
					clientRank[client]--;
					g_iSetScore[client] = clientRank[client];
					CPrintToChat(client, "%t", "Downgraded", clientRank[client]);
					EmitSoundToClient(client, SND_LEVEL_DOWN);
				}
			}
		}
		if(IsValidClient(attacker)) {
			if(attacker != client) {
				if(clientRank[attacker] <= level) {
					clientRank[attacker]++;
					g_iSetScore[attacker] = clientRank[attacker];
					if(level - clientRank[attacker]+1 == 3) {
						decl String:iName[MAX_NAME_LENGTH];
						GetClientName(attacker, iName, sizeof(iName));
						CPrintToChatAll("%t", "Warning", iName);
						EmitSoundToAll(SND_WARNING);
					}
					CPrintToChat(attacker, "%t", "Upgraded", clientRank[attacker]);
					EmitSoundToClient(attacker, SND_LEVEL_UP);
					if(IsPlayerAlive(attacker)) {
						GiveClientWeapons(attacker);
						assistLevel[attacker] = 0;
						delevel[attacker] = 0;
					}
				}
				else if(clientRank[attacker] > level) {
					if(hasWinner == 0) ToggleWinner(attacker);
				}
			}
		}
	}
	if(IsValidClient(assister)) {
		if(GetConVarInt(cvarAssist) > 0) {
			assistLevel[assister]++;
			if(GetConVarInt(cvarAssist) == assistLevel[assister]) {
				assistLevel[assister] = 0;
				if(clientRank[assister] <= level) {
					clientRank[assister]++;
					g_iSetScore[assister] = clientRank[assister];
					if(level - clientRank[assister]+1 == 3) {
						decl String:iName[MAX_NAME_LENGTH];
						GetClientName(assister, iName, sizeof(iName));
						CPrintToChatAll("%t", "Warning", iName);
						EmitSoundToAll(SND_WARNING);
					}
					CPrintToChat(assister, "%t", "Upgraded", clientRank[assister]);
					EmitSoundToClient(assister, SND_LEVEL_UP);
					if(IsPlayerAlive(assister)) {
						GiveClientWeapons(assister);
						delevel[assister] = 0;
					}
				}
				else if(clientRank[attacker] > level) {
					ToggleWinner(attacker);
				}
			}
		}
	}
	return Plugin_Continue;
}

GiveClientWeapons(client) {
	if(!TF2II_IsItemSchemaPrecached()) {
		CreateTimer(0.1, RedoWeapon, GetClientUserId(client));
		return;
	}
	new rank = clientRank[client];
	if(WeaponClass[rank] != TFClass_Unknown) {
		if(Weapon[rank] < 0) {
			LogError("[GunGame] Error: Not a valid weapon index: %d", Weapon[rank]);
			return;
		}
		TF2_SetPlayerClass(client, WeaponClass[rank], false, false);
		TF2_RegeneratePlayer(client);
		GG_RemoveAllWeapons(client);
		TF2Items_GiveWeapon(client, Weapon[rank]);
		//prevent overhealing
		new maxHP = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		SetEntProp(client, Prop_Data, "m_iHealth", maxHP);
		//set players size
		if(GetConVarBool(cvarResize)) {
			if(PlayerSize[rank] > 0) {
				if(PlayerSize[rank] != GetEntPropFloat(client, Prop_Send, "m_flModelScale")) {
					SetEntPropFloat(client, Prop_Send, "m_flModelScale", PlayerSize[rank]);
				}
			}
		}
		//sets player model
		if(GetConVarBool(cvarModel)) {
			SetVariantString(PlayerModel[rank]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		}
		AddAttributeToWeapon(client);
		//shows client rank
		if(hudText != INVALID_HANDLE) {
			ClearSyncHud(client, hudText);
			CloseHandle(hudText);
			hudText = INVALID_HANDLE;
		}
		hudText = CreateHudSynchronizer();
		new bool:team = (GetClientTeam(client) == 2);
		SetHudTextParams(-0.46, 0.85, 100.0, team ? 255 : 0, 0, team ? 0 : 255, 255);
		ShowSyncHudText(client, hudText, "Rank: %d/%d", rank, GetConVarInt(cvarLevel));
		//CloseHandle(hudText);*/
	}
}

public Action:RedoWeapon(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(IsPlayerAlive(client)) {
			GiveClientWeapons(client);
		}
	}
	return Plugin_Handled;
}

ToggleWinner(client) {
	playerCookie[client]++;
	if(hudText != INVALID_HANDLE) {
		ClearSyncHud(client, hudText);
		CloseHandle(hudText);
		hudText = INVALID_HANDLE;
	}
	hudText = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.20, 100.0, 255, 255, 255, 255);
	decl String:iName[MAX_NAME_LENGTH];
	GetClientName(client, iName, sizeof(iName));
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			ShowSyncHudText(i, hudText, "%t", "Winner", iName, iName, playerCookie[client]);
			clientRank[i] = 0;
			if(i != client) {
				TF2_StunPlayer(i, GetConVarFloat(FindConVar("mp_bonusroundtime")), 1.0, TF_STUNFLAGS_GHOSTSCARE, 0);
			}
		}
	}
	//CloseHandle(hudText);
	new team = GetClientTeam(client);
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "team_control_point_master")) != -1) {
		AcceptEntityInput(ent, "Enable");
		SetVariantInt(team);
		AcceptEntityInput(ent, "SetWinner");
	}
	//for ctf_maps, may/maynot conflict with other maps
	SetConVarInt(FindConVar("mp_restartgame"), GetConVarInt(FindConVar("mp_bonusroundtime")));
	SaveCookie(client);
	hasWinner = 1;
	EmitSoundToAll(SND_STAGE_CLEAR);
}

AddAttributeToWeapon(client) {
	//Apparently precache of the itemschema happens after this plugin loads and spawns weapon attributes
	if(!TF2II_IsItemSchemaPrecached()) {
		CreateTimer(0.1, RedoAttribute, GetClientUserId(client));
		return;
	}
	new rank = clientRank[client];
	new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(wep)) return;
	decl String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(Attributes[rank], " ; ", weaponAttribsArray, sizeof(weaponAttribsArray), sizeof(weaponAttribsArray[]));
	if(attribCount <= 0 || StrEqual(Attributes[rank], "")) return;
	new attribute;
	new Float:value;
	for(new i = 0; i < attribCount; i+=2) {
		attribute = StringToInt(weaponAttribsArray[i]);
		value = StringToFloat(weaponAttribsArray[i+1]);
		decl String:strAttributeName[32]; 
		TF2II_GetAttributeNameByID(attribute, strAttributeName, sizeof(strAttributeName));
		AddAttribute(wep, strAttributeName, value);
		//LogMessage("attribute: %s value: %f", strAttributeName, value);
	}
}

public Action:RedoAttribute(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if(IsValidClient(client)) {
		if(IsPlayerAlive(client)) {
			AddAttributeToWeapon(client);
		}
	}
	return Plugin_Handled;
}

SetFlags(value) {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
		switch(value) {
			case 0: AcceptEntityInput(ent, "Disable");
			case 1: AcceptEntityInput(ent, "Enable");
		}
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent, "team_control_point")) != -1) {
		switch(value) {
			case 0: AcceptEntityInput(ent, "Disable");
			case 1: AcceptEntityInput(ent, "Enable");
		}
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_capture_area")) != -1) {
		switch(value) {
			case 0: AcceptEntityInput(ent, "Disable");
			case 1: AcceptEntityInput(ent, "Enable");
		}
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent, "team_control_point_master")) != -1) {
		switch(value) {
			case 0: AcceptEntityInput(ent, "Disable");
			case 1: AcceptEntityInput(ent, "Enable");
		}
	}
}

EnableLockerRoom() {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_regenerate")) != -1) {
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "Enable");
			SDKUnhook(ent, SDKHook_StartTouch, OnTouch);
		}
	}
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if(IsPlayerAlive(i)) {
				TF2_RegeneratePlayer(i);
			}
			ResetClientVariables(i);
			hudText = CreateHudSynchronizer();
			ClearSyncHud(i, hudText);
			CloseHandle(hudText);
		}
	}
}

//Better than giving player new weapons and then removing and replacing it again..
DisableLockerRoom() {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_regenerate")) != -1) {
		if(IsValidEntity(ent)) {
			AcceptEntityInput(ent, "Disable");
			SDKHook(ent, SDKHook_StartTouch, OnTouch);
		}
	}
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if(IsPlayerAlive(i)) {
				GiveClientWeapons(i);
			}
			ResetClientVariables(i);
		}
	}
}

ResetClientVariables(client) {
	clientRank[client] = 0;
	assistLevel[client] = 0;
	delevel[client] = 0;
	g_iSetScore[client] = 0;
}

public Action:OnTouch(ent, client) {
	if(IsValidClient(client)) {
		GiveClientWeapons(client);
	}
}

//tf2_removeallweapons = crash :/
stock GG_RemoveAllWeapons(client) {
	for(new i = 0 ; i <= 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);
		if(!IsValidEntity(weapon)) return;
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "kill");
	}
}

stock SetUpGungameMap(const String:sFile[]) {
	new String:sPath[PLATFORM_MAX_PATH]; 
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(!FileExists(sPath)) {
		LogError("[GunGame] Error: Can not find map filepath %s", sPath);
		SetFailState("Error: Can not find map filepath %s", sPath);
	}
	new Handle:kv = CreateKeyValues("GunGame Maps");
	FileToKeyValues(kv, sPath);

	if(!KvGotoFirstSubKey(kv)) SetFailState("Could not read maps file: %s", sPath);
	
	new ConfigEnabled = 0;
	decl String:MapName[PLATFORM_MAX_PATH];
	decl String:realMap[PLATFORM_MAX_PATH];
	GetCurrentMap(realMap, sizeof(realMap));
	do {
		KvGetSectionName(kv, MapName, sizeof(MapName));
		if(StrContains(realMap, MapName, false) == 0 || StrEqual(MapName, realMap)) {
			ConfigEnabled = KvGetNum(kv, "enabled", 0);
			KvGetString(kv, "weapons_config", LevelConfigs, sizeof(LevelConfigs), "gungame_weapons.cfg");
			LogMessage("Map: %s, Enabled: %s, Config: %s", MapName, ConfigEnabled ? "Yes" : "No", LevelConfigs); 
		}
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	if(ConfigEnabled != 0) {
		SetConVarInt(cvarEnabled, 1);
		SetUpGungameWeapons(LevelConfigs);
	}
	else if(ConfigEnabled == 0) {
		SetConVarInt(cvarEnabled, 0);
	}
	LogMessage("Loaded Map configs successfully."); 
}

stock SetUpGungameWeapons(const String:sFile[]) {
	new String:sPath[PLATFORM_MAX_PATH]; 
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(!FileExists(sPath)) {
		LogError("[GunGame] Error: Can not find weapon filepath %s", sPath);
		SetFailState("Error: Can not find weapon filepath %s", sPath);
	}
	new Handle:kv = CreateKeyValues("GunGame Weapons");
	FileToKeyValues(kv, sPath);

	if(!KvGotoFirstSubKey(kv)) SetFailState("Could not read weapons file: %s", sPath);
	
	new Levels = GetConVarInt(cvarLevel);
	new String:classString[PLATFORM_MAX_PATH];
	for(new i = 0; i <= Levels; i++) {
		KvGotoFirstSubKey(kv);
		KvGetString(kv, "class", classString, sizeof(classString));
		WeaponClass[i] = TF2_GetClass(classString);
		Weapon[i] = KvGetNum(kv, "index", 0);
		PlayerSize[i] = KvGetFloat(kv, "size", 1.0);
		KvGetString(kv, "model", PlayerModel[i], sizeof(PlayerModel), "");
		KvGetString(kv, "attributes", Attributes[i], sizeof(Attributes[]), "");
		//logs debug
		//LogMessage("Attributes: %s", Attributes[i]); 
		KvGotoNextKey(kv);
	}
	LogMessage("Loaded Weapons configs successfully."); 
}

stock GetCookie(client) {
	if(IsValidClient(client)) {
		new String:cookie[PLATFORM_MAX_PATH];
		GetClientCookie(client, GunGameCookies, cookie, sizeof(cookie));
		playerCookie[client] = StringToInt(cookie);
	}
} 

stock SaveCookie(client) {
	if(IsValidClient(client)) {
		new String:cookies[PLATFORM_MAX_PATH];
		IntToString(playerCookie[client], cookies, sizeof(cookies));
		SetClientCookie(client, GunGameCookies, cookies);
	}
}

stock AddAttribute(weapon, String:attribute[], Float:value) {
	TF2Attrib_SetByName(weapon, attribute, value);
}

stock RemoveAttribute(weapon, String:attribute[]) {
	TF2Attrib_RemoveByName(weapon, attribute);
}

stock ClampInt(&iValue, iMin, iMax) {
	if (iValue < iMin) {
		iValue = iMin;
	} 
	else if (iValue > iMax) {
		iValue = iMax;
	}
}  

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}