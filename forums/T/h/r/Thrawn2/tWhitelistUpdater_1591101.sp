#pragma semicolon 1
#include <sourcemod>
#include <regex>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://updates.thrawn.de/tWhitelistUpdater/package.tWhitelistUpdater.cfg"

#define VERSION 				"0.1.12"
#define PATH_ITEMS_GAME			"scripts/items/items_game.txt"

new Handle:g_hCvarAutoupdate = INVALID_HANDLE;
new Handle:g_hCvarAllowWeaponSets = INVALID_HANDLE;
new Handle:g_hCvarAllowHats = INVALID_HANDLE;
new Handle:g_hCvarAllowActionItems = INVALID_HANDLE;
new Handle:g_hCvarAllowNoiseMaker = INVALID_HANDLE;
new Handle:g_hCvarAllowWeaponSkins = INVALID_HANDLE;
//new Handle:g_hCvarAllowRenamedWeapons = INVALID_HANDLE;

new bool:g_bAllowWeaponSets = false;
new bool:g_bAllowHats = true;
new bool:g_bAllowRenamedWeapons = true;
new bool:g_bAllowActionItems = true;
new bool:g_bAllowWeaponSkins = true;
new bool:g_bAllowNoiseMaker = true;
new bool:g_bUpdateOnStart = true;

new bool:g_bMinimalOutput = false;

new Handle:g_hForwardWhitelistUpdated;
new Handle:g_hForwardWhitelistUpdatedAll;

// Cache
new Handle:g_hItems;
new Handle:g_hTrieDefaults;
new Handle:g_hArrayAttributelessItemsets;
new Handle:g_hTriePrefabs;
new Handle:g_hArrayPrefabs;

enum States {
	Ok = 0,
	State_ConfigMissing_AllowedWeapons = 1,
	State_ConfigMissing_Skins = 2
}

public Plugin:myinfo =
{
	name 		= "tWhitelistUpdater",
	author 		= "Thrawn",
	description = "Updates the whitelist to include all the latest gimmicks",
	version 	= VERSION,
};

public OnPluginStart() {
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}

	if(!FileExists(PATH_ITEMS_GAME, true)) {
		SetFailState("items_game.txt does not exist. Something is seriously wrong!");
		return;
	}

	g_hItems = CreateKeyValues("");
	if (!FileToKeyValues(g_hItems, PATH_ITEMS_GAME)) {
		SetFailState("Could not parse items_game.txt. Something is seriously wrong!");
		return;
	}

	// Preload some stuff, so we don't have to do it for every whitelist
	LoadDefaultTrie();
	LoadAllowedItemSets();
	LoadPrefabs();

	CreateConVar("sm_twhitelistupdater_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Other plugins get notified by finished whitelist updates (e.g. to upload them to a webserver)
	g_hForwardWhitelistUpdated = CreateGlobalForward("OnWhitelistUpdated", ET_Ignore, Param_String);
	g_hForwardWhitelistUpdatedAll = CreateGlobalForward("OnWhitelistsUpdated", ET_Ignore);

	g_hCvarAutoupdate = CreateConVar("sm_twhitelistupdater_auto", "1", "Automatically update all whitelists on server start", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAllowWeaponSets = CreateConVar("sm_twhitelistupdater_weaponsets", "0", "Allow weapon sets", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAllowHats = CreateConVar("sm_twhitelistupdater_hats", "1", "Allow hats", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAllowActionItems = CreateConVar("sm_twhitelistupdater_actionitems", "1", "Allow action items", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAllowNoiseMaker = CreateConVar("sm_twhitelistupdater_noisemaker", "1", "Allow noisemaker", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAllowWeaponSkins = CreateConVar("sm_twhitelistupdater_weaponskins", "1", "Allow weapon skins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//g_hCvarAllowRenamedWeapons = CreateConVar("sm_twhitelistupdater_renamedweapons", "1", "Allow renamed base weapons", FCVAR_PLUGIN, true, 0.0, true, 1.0);


	HookConVarChange(g_hCvarAutoupdate, Cvar_Changed);
	HookConVarChange(g_hCvarAllowWeaponSets, Cvar_Changed);
	HookConVarChange(g_hCvarAllowHats, Cvar_Changed);
	HookConVarChange(g_hCvarAllowActionItems, Cvar_Changed);
	HookConVarChange(g_hCvarAllowNoiseMaker, Cvar_Changed);
	HookConVarChange(g_hCvarAllowWeaponSkins, Cvar_Changed);
	//HookConVarChange(g_hCvarAllowRenamedWeapons, Cvar_Changed);


	RegAdminCmd("sm_updatewhitelist", CMD_UpdateWhitelist, ADMFLAG_KICK);
	RegAdminCmd("sm_updatewhitelist_all", CMD_UpdateAllWhitelists, ADMFLAG_KICK);
}

public OnLibraryAdded(const String:name[]) {
    if (StrEqual(name, "updater"))Updater_AddPlugin(UPDATE_URL);
}

public OnAllPluginsLoaded() {
	OnConfigsExecuted();

	if(g_bUpdateOnStart) {
		// We need to delay this a little bit more
		CreateTimer(2.0, Timer_GenerateAll);
	}
}

public Action:Timer_GenerateAll(Handle:timer, any:data) {
	GenerateAllWhitelists();
}

public OnConfigsExecuted() {
	g_bUpdateOnStart = GetConVarBool(g_hCvarAutoupdate);

	g_bAllowWeaponSets = GetConVarBool(g_hCvarAllowWeaponSets);
	g_bAllowHats = GetConVarBool(g_hCvarAllowHats);
	g_bAllowActionItems = GetConVarBool(g_hCvarAllowActionItems);
	g_bAllowNoiseMaker = GetConVarBool(g_hCvarAllowNoiseMaker);
	g_bAllowWeaponSkins = GetConVarBool(g_hCvarAllowWeaponSkins);
	//g_bAllowRenamedWeapons = GetConVarBool(g_hCvarAllowRenamedWeapons);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

//----------------------------------------
//	Commands
//----------------------------------------
public Action:CMD_UpdateWhitelist(client,args) {
	if(args != 1) {
		ReplyToCommand(client, "[Usage] sm_updatewhitelist <config>");
		return Plugin_Handled;
	}

	new String:sBuffer[64];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	new States:iState = GenerateWhitelist(sBuffer);

	// Output State if client is not the server console (gets States logged anyway)
	if(client != 0)PrintStateToClient(client, iState, sBuffer);

	return Plugin_Handled;
}

public Action:CMD_UpdateAllWhitelists(client,args) {
	GenerateAllWhitelists(client);
	return Plugin_Handled;
}

GenerateAllWhitelists(iClient = 0) {
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/whitelists/");

	new Handle:hDir = OpenDirectory(sPath);

	new String:pattern[64] = "(.*)\\.ini$";
	new Handle:rCFGOnly = CompileRegex(pattern, PCRE_CASELESS);

	new FileType:ftType;
	new String:sBuffer[64];
	while(ReadDirEntry(hDir, sBuffer, sizeof(sBuffer), ftType)) {
		if(ftType == FileType_File && MatchRegex(rCFGOnly, sBuffer) > 0) {
			new String:sCFG[64];
			GetRegexSubString(rCFGOnly, 1, sCFG, sizeof(sCFG));

			new States:iState = GenerateWhitelist(sCFG);

			if(iClient != 0 && IsClientConnected(iClient) && IsClientInGame(iClient)) {
				PrintStateToClient(iClient, iState, sCFG);
			}

			Call_StartForward(g_hForwardWhitelistUpdated);
			Call_PushString(sCFG);
			Call_Finish();
		}
	}

	Call_StartForward(g_hForwardWhitelistUpdatedAll);
	Call_Finish();
}

public States:GenerateWhitelist(const String:sConfig[]) {
	new Handle:hConfig = LoadWeaponConfig(sConfig);

	if(hConfig == INVALID_HANDLE) {
		LogError("Config missing: %s", sConfig);
		return State_ConfigMissing_AllowedWeapons;
	}

	new Handle:hSkins = LoadSkins();
	if(hSkins == INVALID_HANDLE) {
		CloseWeaponConfig(hConfig);
		LogError("Config missing: skins.cfg");
		return State_ConfigMissing_Skins;
	}

	new Handle:hResult = GetResultTrie(hConfig, hSkins);
	ResultToFile(hResult, hConfig, sConfig);
	RecursiveCloseTrieHandleDefaults(hResult);
	CloseHandle(hResult);
	CloseHandle(hSkins);

	CloseWeaponConfig(hConfig);

	LogMessage("Whitelist generated from config: %s", sConfig);

	return Ok;
}


//----------------------------------------
//	Load Configurations
//----------------------------------------

public CloseWeaponConfig(Handle:hConfig) {
	RecursiveCloseHandleAtomic(hConfig, "Allowed");
	RecursiveCloseHandleAtomic(hConfig, "ForceBlock");
	RecursiveCloseHandleAtomic(hConfig, "ForceAllow");
	RecursiveCloseHandleAtomic(hConfig, "Global");
	CloseHandle(hConfig);
}

public Handle:LoadWeaponConfig(const String:sConfig[]) {
	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/whitelists/%s.ini", sConfig);

	if(!FileExists(sPath)) {
		LogError("Config %s does not exist", sConfig);
		return INVALID_HANDLE;
	}

	new Handle:hCfgFile = OpenFile(sPath, "r");
	if(hCfgFile == INVALID_HANDLE) {
		LogError("Could not open config file: %s", sPath);
		return INVALID_HANDLE;
	}

	new Handle:hAllowedWeapons = CreateArray(64);
	new Handle:hForceBlockedWeapons = CreateArray(64);
	new Handle:hForceAllowedItems = CreateArray(64);
	new Handle:hSettings = CreateTrie();

	new Handle:rSection = CompileRegex("^\\[(.*)\\]", PCRE_CASELESS);
	new Handle:rValue = CompileRegex("^(.*)=(.*)$", PCRE_CASELESS);

	// Lines that have no section, should be considered as 'Allowed'
	new String:sSection[64] = "Allowed";


	new String:sLine[64];
	while(ReadFileLine(hCfgFile, sLine, sizeof(sLine))) {
		TrimString(sLine);
		if(strlen(sLine) == 0)continue;
		if(strncmp(sLine, "//", 2, false) == 0)continue;

		if(MatchRegex(rSection, sLine) > 0) {
			GetRegexSubString(rSection, 1, sSection, sizeof(sSection));
			continue;
		}

		if(StrEqual(sSection, "Allowed")) {
			PushArrayString(hAllowedWeapons, sLine);
			continue;
		}

		if(StrEqual(sSection, "ForceBlock")) {
			PushArrayString(hForceBlockedWeapons, sLine);
			continue;
		}

		if(StrEqual(sSection, "ForceAllow")) {
			PushArrayString(hForceAllowedItems, sLine);
			continue;
		}

		if(StrEqual(sSection, "Global")) {
			if(MatchRegex(rValue, sLine) > 0) {
				decl String:sKey[64];
				GetRegexSubString(rValue, 1, sKey, sizeof(sKey));

				decl String:sValue[64];
				GetRegexSubString(rValue, 2, sValue, sizeof(sValue));

				if(StrEqual(sValue, "1")) {
					SetTrieValue(hSettings, sKey, 1);
				} else if(StrEqual(sValue, "0")) {
					SetTrieValue(hSettings, sKey, 0);
				} else {
					SetTrieString(hSettings, sKey, sValue);
				}
				continue;
			}
		}
	}

	CloseHandle(hCfgFile);
	CloseHandle(rSection);
	CloseHandle(rValue);

	new Handle:hResult = CreateTrie();
	SetTrieValue(hResult, "Allowed", hAllowedWeapons);
	SetTrieValue(hResult, "ForceBlock", hForceBlockedWeapons);
	SetTrieValue(hResult, "ForceAllow", hForceAllowedItems);
	SetTrieValue(hResult, "Global", hSettings);

	return hResult;
}

public Handle:LoadSkins() {
	// Now, read the skin config file
	new String:sSkinsPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sSkinsPath, sizeof(sSkinsPath), "configs/skins.cfg");

	new Handle:hSkins = CreateKeyValues("");
	if (!FileToKeyValues(hSkins, sSkinsPath)) {
		LogError("Unable to load keyvalues from skins.cfg.");
		return INVALID_HANDLE;
	}

	return hSkins;
}

public LoadPrefabs() {
	// Load prefabs
	g_hTriePrefabs = CreateTrie();
	g_hArrayPrefabs = CreateArray(64);
	KvRewind(g_hItems);
	if(KvJumpToKey(g_hItems, "prefabs")) {
		// There is a prefabs section

		KvGotoFirstSubKey(g_hItems, false);
		do {
			decl String:sPFName[64];
			KvGetSectionName(g_hItems, sPFName, sizeof(sPFName));

			new Handle:hKvPrefab = CreateKeyValues(sPFName);
			KvCopySubkeys(g_hItems, hKvPrefab);

			SetTrieValue(g_hTriePrefabs, sPFName, hKvPrefab);
			PushArrayString(g_hArrayPrefabs, sPFName);
		} while (KvGotoNextKey(g_hItems, false));
	}
}

KvCopySubkeysSafe_Iterate(Handle:hOrigin, Handle:hDest, bool:bReplace=true, bool:bFirst=true) {
do {
		new String:sSection[255];
		KvGetSectionName(hOrigin, sSection, sizeof(sSection));

		new String:sValue[255];
		KvGetString(hOrigin, "", sValue, sizeof(sValue));

		new bool:bIsSubSection = ((KvNodesInStack(hOrigin) == 0) || (KvGetDataType(hOrigin, "") == KvData_None && KvNodesInStack(hOrigin) > 0));

		if(!bIsSubSection) {
			new bool:bExists = !(KvGetNum(hDest, sSection, -1337) == -1337);
			if(!bExists || (bReplace && bExists)) {
				KvSetString(hDest, sSection, sValue);
			}
		} else {
			if (KvGotoFirstSubKey(hOrigin, false)) {
				if(bFirst) {
					KvCopySubkeysSafe_Iterate(hOrigin, hDest, bReplace, false);
				} else {
					KvJumpToKey(hDest, sSection, true);
					KvCopySubkeysSafe_Iterate(hOrigin, hDest, bReplace, false);
					KvGoBack(hDest);
				}

				KvGoBack(hOrigin);
			}
		}

    } while (KvGotoNextKey(hOrigin, false));
}

public LoadAllowedItemSets() {
	// Allow itemsets with no attributes
	g_hArrayAttributelessItemsets = CreateArray(64);
	KvRewind(g_hItems);
	if(KvJumpToKey(g_hItems, "item_sets")) {
		KvGotoFirstSubKey(g_hItems, false);
		do {
			decl String:sSetName[64];
			KvGetSectionName(g_hItems, sSetName, sizeof(sSetName));

			new iCount = 0;
			if(KvJumpToKey(g_hItems, "attributes")) {
				if(KvGotoFirstSubKey(g_hItems, false)) {
					do {
						decl String:sAttributeName[64];
						KvGetSectionName(g_hItems, sAttributeName, sizeof(sAttributeName));

						// Some attributes don't affect gameplay, 'special dsp' is ok for a itemset (engineer halloween)
						if(StrEqual(sAttributeName, "special dsp"))continue;
						if(StrEqual(sAttributeName, "mystery solving time decrease"))continue;
						if(StrEqual(sAttributeName, "chance of hunger decrease"))continue;

						iCount++;
					} while (KvGotoNextKey(g_hItems, false));
					KvGoBack(g_hItems);
				}
				KvGoBack(g_hItems);
			}

			if(iCount == 0)PushArrayStringUnique(g_hArrayAttributelessItemsets, sSetName);
		} while (KvGotoNextKey(g_hItems, false));
	}

}

public LoadDefaultTrie() {
	// Handle 'default' entry in 'items'
	g_hTrieDefaults = CreateTrie();

	KvRewind(g_hItems);
	KvJumpToKey(g_hItems, "items");
	if(KvJumpToKey(g_hItems, "default")) {
		// Default key exists
		new String:sItemSlot[16];
		KvGetString(g_hItems, "item_slot", sItemSlot, sizeof(sItemSlot));

		new String:sItemClass[16];
		KvGetString(g_hItems, "item_class", sItemClass, sizeof(sItemClass));

		SetTrieString(g_hTrieDefaults, "item_slot", sItemSlot);
		SetTrieString(g_hTrieDefaults, "item_class", sItemClass);
	}
}


//----------------------------------------
//	Output
//----------------------------------------
public ResultToFile(Handle:hResult, Handle:hConfig, const String:sBuffer[]) {
	new Handle:hSettings = INVALID_HANDLE;
	GetTrieValue(hConfig, "Global", hSettings);

	new bool:bMinimal			= GetSetting(hSettings, "MinimalOutput", g_bMinimalOutput);
	new bool:bAllowWeaponSets	= GetSetting(hSettings, "AllowWeaponSets", g_bAllowWeaponSets);
	new bool:bAllowWeaponSkins	= GetSetting(hSettings, "AllowWeaponSkins", g_bAllowWeaponSkins);
	new bool:bAllowActionItems	= GetSetting(hSettings, "AllowActionItems", g_bAllowActionItems);
	new bool:bAllowNoiseMaker	= GetSetting(hSettings, "AllowNoiseMaker", g_bAllowNoiseMaker);
	new bool:bAllowHats			= GetSetting(hSettings, "AllowHats", g_bAllowHats);

	new String:sOutputPath[PLATFORM_MAX_PATH];
	new String:sFilename[PLATFORM_MAX_PATH];
	if(GetTrieString(hSettings, "Filename", sFilename, sizeof(sFilename))) {
		Format(sOutputPath, sizeof(sOutputPath), "cfg/%s", sFilename);
	} else {
		Format(sOutputPath, sizeof(sOutputPath), "cfg/%s_whitelist.txt", sBuffer);
	}

	new Handle:hFile = OpenFile(sOutputPath, "w");

	decl String:sHeader[255];
	if(GetTrieString(hSettings, "Header", sHeader, sizeof(sHeader))) {
		WriteFileLine(hFile, "// %s", sHeader);
	} else {
		WriteFileLine(hFile, "// %s item whitelist", sBuffer);
	}
	WriteFileLine(hFile, "//");
	if(GetTrieArraySize(hResult, "AllowedWeaponsForMain") <= GetTrieArraySize(hResult, "BlockedWeaponsForMain")) {
		PrintHeader(hFile, "Allowed weapons for Main classes:", hResult, "AllowedWeaponsForMain");
	} else {
		PrintHeader(hFile, "Blocked weapons for Main classes:", hResult, "BlockedWeaponsForMain");
	}

	WriteFileLine(hFile, "//");

	if(GetTrieArraySize(hResult, "BlockedWeaponsForSupp") <= GetTrieArraySize(hResult, "AllowedWeaponsForSupp")) {
		PrintHeader(hFile, "Blocked weapons for Support classes:", hResult, "BlockedWeaponsForSupp");
	} else {
		PrintHeader(hFile, "Allowed weapons for Support classes:", hResult, "AllowedWeaponsForSupp");
	}
	WriteFileLine(hFile, "//");
	WriteFileLine(hFile, "// %20s %s", "Weapon sets are:",	bAllowWeaponSets	? "allowed" : "banned");
	WriteFileLine(hFile, "// %20s %s", "Weapon skins are:",	bAllowWeaponSkins	? "allowed" : "banned");
	WriteFileLine(hFile, "// %20s %s", "Action items are:",	bAllowActionItems	? "allowed" : "banned");
	WriteFileLine(hFile, "// %20s %s", "Noise Maker are:",	bAllowNoiseMaker	? "allowed" : "banned");
	WriteFileLine(hFile, "// %20s %s", "Hats are:",			bAllowHats			? "allowed" : "banned");

	//WriteFileLine(hFile, "// %20s %s", "Renamed base-weapons are:", g_bAllowRenamedWeapons ? "allowed" : "banned");

	WriteFileLine(hFile, "");

	WriteFileLine(hFile, "\"item_whitelist\"\n{\n    \"unlisted_items_default_to\"                        \"0\"");
	PrintArray(hFile, hResult, "AllowedWeapons",	"Allowed Weapons:", true, bMinimal);
	PrintArray(hFile, hResult, "RenamedWeapons",	"Renamed Weapons:", g_bAllowRenamedWeapons, bMinimal);
	PrintArray(hFile, hResult, "WeaponSkins", 		"Weapon Skins:", bAllowWeaponSkins, bMinimal);
	PrintArray(hFile, hResult, "BlockedWeapons",	"Blocked Weapons:", false, bMinimal);
	PrintArray(hFile, hResult, "BlockedHats", 		"Blocked Items:", false, bMinimal);
	PrintArray(hFile, hResult, "AllowedHats", 		"Allowed Hats:", bAllowHats, bMinimal);
	PrintArray(hFile, hResult, "MiscItems", 		"Misc Items:", bAllowHats, bMinimal);
	PrintArray(hFile, hResult, "ActionItems", 		"Action Items:", bAllowActionItems, bMinimal);
	PrintArray(hFile, hResult, "NoiseMaker", 		"Noise Maker:", bAllowNoiseMaker, bMinimal);

	WriteFileLine(hFile, "}\n");
	CloseHandle(hFile);
}

public PrintHeader(Handle:hFile, const String:sHeader[64], Handle:hResult, const String:sSection[64]) {
	new Handle:hResultPart;
	GetTrieValue(hResult, sSection, hResultPart);
	WriteFileLine(hFile, "// %s", sHeader);
	new iSize = GetArraySize(hResultPart);

	if(iSize > 0) {
		for(new i=0; i < iSize; i++) {
			new String:sBuffer[64];
			GetArrayString(hResultPart, i, sBuffer, sizeof(sBuffer));
			WriteFileLine(hFile, "//  - %s", sBuffer);
		}
	} else {
		WriteFileLine(hFile, "// None");
	}
}

public PrintArray(Handle:hFile, Handle:hResult, const String:sSection[], const String:sHeader[], bool:bState, bool:bMinimal) {
	if(bMinimal && !bState)return;

	new Handle:hResultPart;
	GetTrieValue(hResult, sSection, hResultPart);
	new iSize = GetArraySize(hResultPart);

	WriteFileLine(hFile, "\n    // %s (Total: %i)", sHeader, iSize);
	if(iSize == 0) {
		WriteFileLine(hFile, "    // None", sHeader);
	} else {
		for(new i=0; i < iSize; i++) {
			new String:sBuffer[128];
			GetArrayString(hResultPart, i, sBuffer, sizeof(sBuffer));
			Format(sBuffer, sizeof(sBuffer), "\"%s\"", sBuffer);
			WriteFileLine(hFile, "    %50s \"%i\"", sBuffer, bState ? 1 : 0);
		}
	}
}

public PrintStateToClient(client, States:iState, String:sConfig[]) {
	switch(iState) {
		case State_ConfigMissing_AllowedWeapons: {
			PrintToChat(client, "Could not load config: %s", sConfig);
		}
		case State_ConfigMissing_Skins: {
			PrintToChat(client, "Could not load skin config");
		}

		case Ok: {
			PrintToChat(client, " > Whitelist for config %s generated.", sConfig);
		}
	}
}

public GetTrieArraySize(Handle:hResult, const String:sSection[64]) {
	new Handle:hResultPart;
	GetTrieValue(hResult, sSection, hResultPart);
	return GetArraySize(hResultPart);
}


//----------------------------------------
//	The actual logic
//----------------------------------------
public bool:GetSetting(Handle:hConfig, const String:sSetting[], bool:defaultValue) {
	new bool:iValue;
	if(GetTrieValue(hConfig, sSetting, iValue)) {
		return iValue;
	}

	return defaultValue;
}

public Handle:GetResultTrie(Handle:hConfig, Handle:hSkins) {
	new Handle:hAllowedWeapons = INVALID_HANDLE;
	GetTrieValue(hConfig, "Allowed", hAllowedWeapons);

	new Handle:hForceBlockedWeapons = INVALID_HANDLE;
	GetTrieValue(hConfig, "ForceBlock", hForceBlockedWeapons);

	new Handle:hForceAllowedItems = INVALID_HANDLE;
	GetTrieValue(hConfig, "ForceAllow", hForceAllowedItems);


	new Handle:hSettings = INVALID_HANDLE;
	GetTrieValue(hConfig, "Global", hSettings);

	new Handle:hArrayAllowedWeapons = CreateArray(64);
	new Handle:hArrayBlockedWeapons = CreateArray(64);
	new Handle:hArrayBlockedWeaponIDs = CreateArray(4);

	new Handle:hArrayRenamedWeapons = CreateArray(64);

	new Handle:hArrayAllowHatsFromSet = CreateArray(64);
	PushArrayString(hArrayAllowHatsFromSet, "hidden_detective_set");

	new Handle:hArrayBlockedItems = CreateArray(64);

	new Handle:hArrayAllowedHats = CreateArray(64);
	new Handle:hArrayActionItems = CreateArray(64);
	new Handle:hArrayNoiseMaker = CreateArray(64);
	new Handle:hArrayMiscItems = CreateArray(64);
	new Handle:hArrayWeaponSkins = CreateArray(64);

	new Handle:hArrayAllowedWeaponsForMain = CreateArray(64);
	new Handle:hArrayAllowedWeaponsForSupp = CreateArray(64);
	new Handle:hArrayBlockedWeaponsForSupp = CreateArray(64);
	new Handle:hArrayBlockedWeaponsForMain = CreateArray(64);

	new bool:bAllowAllWeapons = GetSetting(hSettings, "AllowAllWeapons", false);

	//The first run will handle ONLY the weapons
	// We need that to see which set hats can be allowed
	KvRewind(g_hItems);
	KvJumpToKey(g_hItems, "items");
	KvGotoFirstSubKey(g_hItems, false);

	new String:sIndex[8]; new iIndex;
	do {
		KvGetSectionName(g_hItems, sIndex, sizeof(sIndex));


		//Skip item with id 'default'
		if(StrEqual(sIndex, "default"))continue;


		//Skip default weapons
		iIndex = StringToInt(sIndex);
		if(iIndex  < 31)continue;
		if(iIndex == 735)continue;


		// Get basic information about the item: Defaults < Prefabs < Values
		new String:sItemSlot[16];
		new String:sItemClass[16];
		new String:sName[128];
		GetItemInfo(sItemSlot, sizeof(sItemSlot), sItemClass, sizeof(sItemClass), sName, sizeof(sName));


		// Skip all items that are no weapons
		if(IsUnrelatedItemClass(sItemClass))
			continue;

		if(!IsWeaponSlot(sItemSlot))
			continue;

		new bool:bForceBlocked = (FindStringInArray(hForceBlockedWeapons, sName) != -1);
		//new bool:bForceAllowed = (FindStringInArray(hForceBlockedWeapons, sName) != -1);


		// Allow all weapons that are specified in the config (either by name or by id)
		if((FindStringInArray(hAllowedWeapons, sName) != -1 || FindStringInArray(hAllowedWeapons, sIndex) != -1) && !bForceBlocked) {
			PushArrayString(hArrayAllowedWeapons, sName);

			// Also sort them into the "pretty" arrays for a nice header output
			if(KvJumpToKey(g_hItems, "used_by_classes")) {
				if(KvGotoFirstSubKey(g_hItems, false)) {
					do {
						decl String:sClass[64];
						KvGetSectionName(g_hItems, sClass, sizeof(sClass));

						PushArrayStringUnique(IsMainClass(sClass) ? hArrayAllowedWeaponsForMain : hArrayAllowedWeaponsForSupp, sName);
					} while (KvGotoNextKey(g_hItems, false));

					KvGoBack(g_hItems);
				}

				KvGoBack(g_hItems);
			}

			// No further processing for this weapon necessary
			continue;
		}


		// Deal with 'upgradable'/'renamable' weapons seperately
		if(strncmp("Upgradeable", sName, 11, false) == 0) {
			PushArrayString(hArrayRenamedWeapons, sName);
			continue;
		}


		// Skins will be allowed if their original is allowed
		// Uargs: At this point we assume that a skin always has a higher ID than their original counterpart
		//        and therefore must have already been blocked. This is because we are doing this strictly
		//        linear instead of "pre-reading" certain item-indexes.
		//        As long as Valve keeps it this way, all's good.
		new iSkin = IsSkin(hSkins, iIndex);
		if(iSkin != -1 && !bForceBlocked) {
			if(!(iSkin > 0 && FindValueInArray(hArrayBlockedWeaponIDs, iSkin) != -1)) {
				PushArrayString(hArrayWeaponSkins, sName);
				continue;
			}
		}

		// If all weapons should be allowed except the ones specified in the blocked section
		if(bAllowAllWeapons && !bForceBlocked) {
			PushArrayString(hArrayAllowedWeapons, sName);

			// Also sort them into the "pretty" arrays for a nice header output
			if(KvJumpToKey(g_hItems, "used_by_classes")) {
				KvGotoFirstSubKey(g_hItems, false);
				do {
					decl String:sClass[64];
					KvGetSectionName(g_hItems, sClass, sizeof(sClass));

					PushArrayStringUnique(IsMainClass(sClass) ? hArrayAllowedWeaponsForMain : hArrayAllowedWeaponsForSupp, sName);
				} while (KvGotoNextKey(g_hItems, false));

				KvGoBack(g_hItems);
			}
			KvGoBack(g_hItems);

			// No further processing for this weapon necessary
			continue;
		}

		// At this point weapons have no way of being allowed anymore
		PushArrayString(hArrayBlockedWeapons, sName);
		PushArrayCell(hArrayBlockedWeaponIDs, iIndex);


		// This is purely for cosmetic purposes to be able to have a nice header
		if(KvJumpToKey(g_hItems, "used_by_classes")) {
			KvGotoFirstSubKey(g_hItems, false);
			do {
				new String:sClass[64];
				KvGetSectionName(g_hItems, sClass, sizeof(sClass));

				PushArrayStringUnique(IsMainClass(sClass) ? hArrayBlockedWeaponsForMain : hArrayBlockedWeaponsForSupp, sName);
			} while (KvGotoNextKey(g_hItems, false));
			KvGoBack(g_hItems);
		}
		KvGoBack(g_hItems);


		// If we've just blocked a weapon belonging to a weapon set, we can safely
		// allow all hats/miscs from that set.
		new String:sItemSet[64];
		KvGetString(g_hItems, "item_set", sItemSet, sizeof(sItemSet));
		if(strlen(sItemSet) > 0)PushArrayStringUnique(hArrayAllowHatsFromSet, sItemSet);

	} while (KvGotoNextKey(g_hItems, false));



	//The second pass only deals with hats, misc and action items
	KvRewind(g_hItems);
	KvJumpToKey(g_hItems, "items");
	KvGotoFirstSubKey(g_hItems, false);
	do {
		KvGetSectionName(g_hItems, sIndex, sizeof(sIndex));
		iIndex = StringToInt(sIndex);

		//Skip all weapons
		if(iIndex  < 31)continue;

		decl String:sItemSlot[16];
		decl String:sItemClass[16];
		decl String:sName[128];
		GetItemInfo(sItemSlot, sizeof(sItemSlot), sItemClass, sizeof(sItemClass), sName, sizeof(sName));

		if(IsWeaponSlot(sItemSlot))
			continue;

		if(IsUnrelatedItemClass(sItemClass))
			continue;

		new bool:bForceBlocked = (FindStringInArray(hForceBlockedWeapons, sName) != -1);
		new bool:bForceAllowed = (FindStringInArray(hForceAllowedItems, sName) != -1);

		// Block hats which could complete a set
		if(!bForceAllowed && !GetSetting(hSettings, "AllowWeapons", g_bAllowWeaponSets)) {
			new String:sItemSet[64];
			KvGetString(g_hItems, "item_set", sItemSet, sizeof(sItemSet), "");
			if(strlen(sItemSet) > 0) {
				if(FindStringInArray(hArrayAllowHatsFromSet, sItemSet) == -1 && FindStringInArray(g_hArrayAttributelessItemsets, sItemSet) == -1) {
					PushArrayString(hArrayBlockedItems, sName);
					continue;
				}
			}
		}

		if(StrEqual(sItemSlot, "action")) {
			// If it's a noise maker, sort it into an own array
			if(KvJumpToKey(g_hItems, "attributes")) {
				new bool:bIsNoisemaker = false;
				if(KvGotoFirstSubKey(g_hItems, false)) {
					do {
						decl String:sAttributeName[64];
						KvGetSectionName(g_hItems, sAttributeName, sizeof(sAttributeName));

						if(!StrEqual(sAttributeName, "noise maker"))continue;
						bIsNoisemaker = true;
						break;
					} while (KvGotoNextKey(g_hItems, false));
					KvGoBack(g_hItems);
				}
				KvGoBack(g_hItems);

				if(bIsNoisemaker) {
					if(!bForceBlocked) {
						PushArrayString(hArrayNoiseMaker, sName);
					} else {
						PushArrayString(hArrayBlockedItems, sName);
					}
					continue;
				}
			}

			// Otherwise it is indeed an action item
			PushArrayString(hArrayActionItems, sName);
			continue;
		}

		if(StrEqual(sItemSlot, "head")) {
			if(!bForceBlocked && (bForceAllowed || GetSetting(hSettings, "AllowHats", g_bAllowHats))) {
				PushArrayString(hArrayAllowedHats, sName);
			} else PushArrayString(hArrayBlockedItems, sName);

			continue;
		}

		if(StrEqual(sItemSlot, "misc")) {
			if(!bForceBlocked && (bForceAllowed || GetSetting(hSettings, "AllowHats", g_bAllowHats))) {
				PushArrayString(hArrayMiscItems, sName);
			} else PushArrayString(hArrayBlockedItems, sName);

			continue;
		}


	} while (KvGotoNextKey(g_hItems, false));

	new Handle:hResultTrie = CreateTrie();
	SetTrieValue(hResultTrie, "AllowedWeapons", 		hArrayAllowedWeapons);
	SetTrieValue(hResultTrie, "BlockedWeapons", 		hArrayBlockedWeapons);
	SetTrieValue(hResultTrie, "BlockedWeaponIDs",		hArrayBlockedWeaponIDs);

	SetTrieValue(hResultTrie, "RenamedWeapons",			hArrayRenamedWeapons);

	SetTrieValue(hResultTrie, "AllowHatsFromSet",		hArrayAllowHatsFromSet);
	SetTrieValue(hResultTrie, "BlockedHats",			hArrayBlockedItems);

	SetTrieValue(hResultTrie, "AllowedHats",			hArrayAllowedHats);
	SetTrieValue(hResultTrie, "ActionItems",			hArrayActionItems);
	SetTrieValue(hResultTrie, "NoiseMaker",				hArrayNoiseMaker);
	SetTrieValue(hResultTrie, "MiscItems",				hArrayMiscItems);
	SetTrieValue(hResultTrie, "WeaponSkins",			hArrayWeaponSkins);

	SetTrieValue(hResultTrie, "AllowedWeaponsForMain",	hArrayAllowedWeaponsForMain);
	SetTrieValue(hResultTrie, "BlockedWeaponsForSupp",	hArrayBlockedWeaponsForSupp);
	SetTrieValue(hResultTrie, "BlockedWeaponsForMain",	hArrayBlockedWeaponsForMain);
	SetTrieValue(hResultTrie, "AllowedWeaponsForSupp",	hArrayAllowedWeaponsForSupp);

	return hResultTrie;
}

public GetItemInfo(String:sItemSlot[], maxLenIS, String:sItemClass[], maxLenIC, String:sName[], maxLenName) {
	// Default values first
	GetTrieString(g_hTrieDefaults, "item_slot", sItemSlot, maxLenIS);
	GetTrieString(g_hTrieDefaults, "item_class", sItemClass, maxLenIC);

	// Then overwrite those with prefab values
	new String:sPrefabSlot[64];
	KvGetString(g_hItems, "prefab", sPrefabSlot, sizeof(sPrefabSlot), "");

	while(strlen(sPrefabSlot) > 0) {
		KvSetString(g_hItems, "prefab", "");
		new String:sPrefabBuffers[8][64];
		new iPrefabsUsed = ExplodeString(sPrefabSlot, " ", sPrefabBuffers, 8, 64);

		for(new iPrefabIdx = 0; iPrefabIdx < iPrefabsUsed; iPrefabIdx++) {
			new Handle:hKvPrefab = INVALID_HANDLE;
			if(GetTrieValue(g_hTriePrefabs, sPrefabBuffers[iPrefabIdx], hKvPrefab) && hKvPrefab != INVALID_HANDLE) {
				//KvGetString(hKvPrefab, "item_slot", sItemSlot, maxLenIS, sItemSlot);
				//KvGetString(hKvPrefab, "item_class", sItemClass, maxLenIC, sItemClass);

				KvCopySubkeysSafe_Iterate(hKvPrefab, g_hItems, true, true);
			}
		}

		KvGetString(g_hItems, "prefab", sPrefabSlot, sizeof(sPrefabSlot), "");
	}

	// And finally use the values defined in the section directly
	KvGetString(g_hItems, "item_slot", sItemSlot, maxLenIS, sItemSlot);
	KvGetString(g_hItems, "item_class", sItemClass, maxLenIC, sItemClass);

	// Always load the name from the KeyValues
	KvGetString(g_hItems, "name", sName, maxLenName);
}

public bool:IsUnrelatedItemClass(String:sItemClass[]) {
	return (
			StrEqual(sItemClass, "tool") ||
			StrEqual(sItemClass, "supply_crate") ||
			StrEqual(sItemClass, "map_token") ||
			StrEqual(sItemClass, "class_token") ||
			StrEqual(sItemClass, "slot_token") ||
			StrEqual(sItemClass, "bundle") ||
			StrEqual(sItemClass, "upgrade") ||
			StrEqual(sItemClass, "craft_item"));
}

public bool:IsWeaponSlot(String:sItemSlot[]) {
	return (
			StrEqual(sItemSlot, "melee") ||
			StrEqual(sItemSlot, "primary") ||
			StrEqual(sItemSlot, "secondary") ||
			StrEqual(sItemSlot, "pda2") ||
			StrEqual(sItemSlot, "building") ||
			StrEqual(sItemSlot, "pda")
	);
}

public bool:IsMainClass(String:sClass[]) {
	return (
			StrEqual(sClass, "scout") ||
			StrEqual(sClass, "soldier") ||
			StrEqual(sClass, "heavy") ||
			StrEqual(sClass, "demo") ||
			StrEqual(sClass, "demoman") ||
			StrEqual(sClass, "medic")
	);
}

public PushArrayStringUnique(Handle:hArray, String:sString[]) {
	if(FindStringInArray(hArray, sString) == -1)PushArrayString(hArray, sString);
}

public IsSkin(Handle:hSkins, iID) {
	KvRewind(hSkins);
	KvJumpToKey(hSkins, "Skins");

	new String:sKey[8];
	Format(sKey, sizeof(sKey), "%i", iID);
	return KvGetNum(hSkins, sKey, -1);
}


//----------------------------------------
//	Cleanup
//----------------------------------------

public OnPluginEnd() {
	// Cleanup no longer needed Handles
	RecursiveCloseKeyValuesByArray(g_hArrayPrefabs, g_hTriePrefabs);

	CloseHandle(g_hItems);
	CloseHandle(g_hTrieDefaults);
	CloseHandle(g_hArrayAttributelessItemsets);
}

public RecursiveCloseKeyValuesByArray(Handle:hArray, Handle:hTrie) {
	for(new iPos = 0; iPos < GetArraySize(hArray); iPos++) {
		new String:sKey[64];
		GetArrayString(hArray, iPos, sKey, sizeof(sKey));

		RecursiveCloseHandleAtomic(hTrie, sKey);
	}

	CloseHandle(hArray);
	CloseHandle(hTrie);
}

public RecursiveCloseTrieHandleDefaults(Handle:hTrie) {
	RecursiveCloseHandleAtomic(hTrie, "AllowedWeapons");
	RecursiveCloseHandleAtomic(hTrie, "BlockedWeapons");
	RecursiveCloseHandleAtomic(hTrie, "BlockedWeaponIDs");

	RecursiveCloseHandleAtomic(hTrie, "RenamedWeapons");

	RecursiveCloseHandleAtomic(hTrie, "AllowHatsFromSet");
	RecursiveCloseHandleAtomic(hTrie, "BlockedHats");

	RecursiveCloseHandleAtomic(hTrie, "AllowedHats");
	RecursiveCloseHandleAtomic(hTrie, "ActionItems");
	RecursiveCloseHandleAtomic(hTrie, "NoiseMaker");
	RecursiveCloseHandleAtomic(hTrie, "MiscItems");
	RecursiveCloseHandleAtomic(hTrie, "WeaponSkins");

	RecursiveCloseHandleAtomic(hTrie, "AllowedWeaponsForMain");
	RecursiveCloseHandleAtomic(hTrie, "BlockedWeaponsForSupp");
	RecursiveCloseHandleAtomic(hTrie, "BlockedWeaponsForMain");
	RecursiveCloseHandleAtomic(hTrie, "AllowedWeaponsForSupp");
}

public RecursiveCloseHandleAtomic(Handle:hTrie, const String:sEntry[64]) {
	new Handle:hResultPart = INVALID_HANDLE;
	GetTrieValue(hTrie, sEntry, hResultPart);
	CloseHandle(hResultPart);
}