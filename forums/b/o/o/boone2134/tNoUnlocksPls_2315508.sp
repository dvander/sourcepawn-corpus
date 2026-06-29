#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    			"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.cfg"
#define PATH_ITEMS_GAME			"scripts/items/items_game.txt"

#define VERSION			"0.4.8"

new bool:g_bAnnounce;
new bool:g_bEnabled;
new bool:g_bBlockSetHats;
new bool:g_bBlockStrangeWeapons;
new bool:g_bDefault;		//true == replace weapons by default, unless told so with sm_toggleunlock <iIDI>

new String:g_sCfgFile[255];

new Handle:g_hCvarDefault;
new Handle:g_hCvarEnabled;
new Handle:g_hCvarBlockSetHats;
new Handle:g_hCvarBlockStrange;

new Handle:g_hCvarFile;
new Handle:g_hCvarAnnounce;

new bool:g_bSomethingChanged = false;

new g_iMaxWeight = 0;
new Handle:g_hModuleToUse = INVALID_HANDLE;

new Handle:g_hSlotMap = INVALID_HANDLE;
new Handle:g_hWeapons = INVALID_HANDLE;
new Handle:g_hTranslatable = INVALID_HANDLE;

new Handle:g_hForwardAnnounce = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - Core",
	author      = "Thrawn",
	description = "Replaces unlocks with their original.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};

public OnPluginStart() {
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}

	if(!FileExists(PATH_ITEMS_GAME, true)) {
		SetFailState("items_game.txt does not exist. Something is seriously wrong!");
		return;
	}

	CreateConVar("sm_tnounlockspls_version", VERSION, "[TF2] tNoUnlocksPls", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarDefault = CreateConVar("sm_tnounlockspls_default", "1", "1 == block weapons by default.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarEnabled = CreateConVar("sm_tnounlockspls_enable", "1", "Enable disable this plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarBlockSetHats = CreateConVar("sm_tnounlockspls_blocksets", "0", "If all weapons of a certain set are allowed, block the hat if this is set to 1.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarBlockStrange = CreateConVar("sm_tnounlockspls_blockstrange", "0", "Block all strange weapons if this is set to 1.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarAnnounce = CreateConVar("sm_tnounlockspls_announce", "1", "Announces the removal of weapons/attributes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarFile = CreateConVar("sm_tnounlockspls_cfgfile", "tNoUnlocksPls.cfg", "File to store configuration in", FCVAR_PLUGIN);

	g_hForwardAnnounce = CreateGlobalForward("tNUP_OnAnnounce", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	HookConVarChange(g_hCvarDefault, Cvar_Changed);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
	HookConVarChange(g_hCvarBlockSetHats, Cvar_Changed);
	HookConVarChange(g_hCvarFile, Cvar_Changed);
	HookConVarChange(g_hCvarBlockStrange, Cvar_Changed);
	HookConVarChange(g_hCvarAnnounce, Cvar_Changed);

	AutoExecConfig();
}

public OnLibraryAdded(const String:name[]) {
    if (StrEqual(name, "updater"))Updater_AddPlugin(UPDATE_URL);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_hCvarFile) {
		GetConVarString(g_hCvarFile, g_sCfgFile, sizeof(g_sCfgFile));
		BuildPath(Path_SM, g_sCfgFile, sizeof(g_sCfgFile), "configs/%s", g_sCfgFile);

		g_bSomethingChanged = true;
	} else {
		g_bDefault = GetConVarBool(g_hCvarDefault);
		g_bEnabled = GetConVarBool(g_hCvarEnabled);
		g_bBlockSetHats = GetConVarBool(g_hCvarBlockSetHats);
		g_bBlockStrangeWeapons = GetConVarBool(g_hCvarBlockStrange);
		g_bAnnounce = GetConVarBool(g_hCvarAnnounce);
	}
}

public OnConfigsExecuted() {
	g_bDefault = GetConVarBool(g_hCvarDefault);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_bBlockSetHats = GetConVarBool(g_hCvarBlockSetHats);
	g_bBlockStrangeWeapons = GetConVarBool(g_hCvarBlockStrange);
	g_bAnnounce = GetConVarBool(g_hCvarAnnounce);

	GetConVarString(g_hCvarFile, g_sCfgFile, sizeof(g_sCfgFile));
	BuildPath(Path_SM, g_sCfgFile, sizeof(g_sCfgFile), "configs/%s", g_sCfgFile);

	g_hTranslatable = LoadTranslationList();
	GetWeaponSlotMap(g_hSlotMap, g_hWeapons);
	LoadWeaponConfig();
}

public OnMapEnd() {
	if(g_bSomethingChanged) {
		//We need to save our changes
		SaveWeaponConfig();
	}
}

/////////////////
//   D A T A   //
/////////////////
public Handle:LoadTranslationList() {
	decl String:translationPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, translationPath, PLATFORM_MAX_PATH, "translations/weapons.phrases.tf.txt");

	new Handle:hHasTranslation = CreateArray(128);
	if(FileExists(translationPath)) {
		LoadTranslations("weapons.phrases.tf.txt");

		new Handle:kv = CreateKeyValues("Phrases");
		FileToKeyValues(kv, translationPath);
		KvGotoFirstSubKey(kv, true);

		do {
			new String:sTranslationString[128];
			KvGetSectionName(kv, sTranslationString, sizeof(sTranslationString));

			PushArrayString(hHasTranslation, sTranslationString);
		} while (KvGotoNextKey(kv, true));

		CloseHandle(kv);
	}

	return hHasTranslation;
}

public GetWeaponSlotMap(&Handle:hSlotMap, &Handle:hWeapons) {
	if(hSlotMap != INVALID_HANDLE)return;
	if(hWeapons != INVALID_HANDLE)return;

	new Handle:hKvItems = CreateKeyValues("");
	if (!FileToKeyValues(hKvItems, PATH_ITEMS_GAME)) {
		SetFailState("Could not parse items_game.txt. Something is seriously wrong!");
		return;
	}

	// Load Defaults
	new Handle:hTrieDefaults = CreateTrie();
	KvJumpToKey(hKvItems, "items");
	if(KvJumpToKey(hKvItems, "default")) {
		// Default key exists
		new String:sItemSlot[16];
		KvGetString(hKvItems, "item_slot", sItemSlot, sizeof(sItemSlot));

		new String:sItemClass[16];
		KvGetString(hKvItems, "item_class", sItemClass, sizeof(sItemClass));

		new String:sItemName[128];
		KvGetString(hKvItems, "item_name", sItemName, sizeof(sItemName));

		SetTrieString(hTrieDefaults, "item_slot", sItemSlot);
		SetTrieString(hTrieDefaults, "item_class", sItemClass);
		SetTrieString(hTrieDefaults, "item_name", sItemName);
	}


	// Load prefabs
	new Handle:hTriePrefabs = CreateTrie();
	new Handle:hArrayPrefabs = CreateArray(128);
	KvRewind(hKvItems);
	if(KvJumpToKey(hKvItems, "prefabs")) {
		// There is a prefabs section

		KvGotoFirstSubKey(hKvItems, false);
		do {
			decl String:sPFName[64];
			KvGetSectionName(hKvItems, sPFName, sizeof(sPFName));

			new Handle:hKvPrefab = CreateKeyValues(sPFName);
			KvCopySubkeys(hKvItems, hKvPrefab);

			SetTrieValue(hTriePrefabs, sPFName, hKvPrefab);
			PushArrayString(hArrayPrefabs, sPFName);
		} while (KvGotoNextKey(hKvItems, false));
	}


	// Iterate over all weapons and store them
	hSlotMap = CreateTrie();
	hWeapons = CreateArray(4);

	KvRewind(hKvItems);
	KvJumpToKey(hKvItems, "items");
	KvGotoFirstSubKey(hKvItems, false);
	new String:sIndex[8];
	do {
		KvGetSectionName(hKvItems, sIndex, sizeof(sIndex));

		//Skip default weapons
		new iIndex = StringToInt(sIndex);
		if(iIndex  < 31)continue;
		if(iIndex == 735)continue;

		// Get basic information about the item: Defaults < Prefabs < Values
		new String:sItemSlot[16];
		new String:sItemClass[16];
		new String:sItemName[128];
		new String:sName[128];

		// Default values first
		GetTrieString(hTrieDefaults, "item_slot", sItemSlot, sizeof(sItemSlot));
		GetTrieString(hTrieDefaults, "item_class", sItemClass, sizeof(sItemClass));
		GetTrieString(hTrieDefaults, "item_name", sItemName, sizeof(sItemName));

		// Then overwrite the original kv structure with values from their prefab(s)
		new String:sPrefabSlot[64];
		KvGetString(hKvItems, "prefab", sPrefabSlot, sizeof(sPrefabSlot), "");
		while(strlen(sPrefabSlot) > 0) {
			KvSetString(hKvItems, "prefab", "");
			new String:sPrefabBuffers[8][64];
			new iPrefabsUsed = ExplodeString(sPrefabSlot, " ", sPrefabBuffers, 8, 64);

			for(new iPrefabIdx = 0; iPrefabIdx < iPrefabsUsed; iPrefabIdx++) {
				new Handle:hKvPrefab = INVALID_HANDLE;
				if(GetTrieValue(hTriePrefabs, sPrefabBuffers[iPrefabIdx], hKvPrefab) && hKvPrefab != INVALID_HANDLE) {
					// No, don't replace values by default, obviously keep the value
					// that was mentioned first. But: that function will still replace
					// entries with key 'prefab'.
					KvCopySubkeysSafe_Iterate(hKvPrefab, hKvItems, false, true);
				}
			}

			KvGetString(hKvItems, "prefab", sPrefabSlot, sizeof(sPrefabSlot), "");
		}

		// Then read from the original kv structure, these are already overwritten with prefab values
		KvGetString(hKvItems, "item_slot", sItemSlot, sizeof(sItemSlot), sItemSlot);
		KvGetString(hKvItems, "item_class", sItemClass, sizeof(sItemClass), sItemClass);

		// Load the translateable name, trim and upper-case it.
		KvGetString(hKvItems, "item_name", sItemName, sizeof(sItemName), sItemName);
		strcopy(sItemName, sizeof(sItemName), sItemName[1]);
		StrToUpper(sItemName, sItemName, sizeof(sItemName));

		// Always use the name from the KeyValues
		KvGetString(hKvItems, "name", sName, sizeof(sName));

		// Skip upgradeable weapons
		if(strncmp(sName, "Upgradeable ", 12) == 0)continue;

		// Skip all items that are no weapons
		if(IsUnrelatedItemClass(sItemClass))
			continue;

		new iWeaponSlot = IsWeaponSlot(sItemSlot);
		if(iWeaponSlot == -1)continue;

		new Handle:hItemTrie = CreateTrie();
		SetTrieValue(hItemTrie, "item_slot", iWeaponSlot);
		SetTrieString(hItemTrie, "item_class", sItemClass);
		SetTrieString(hItemTrie, "item_name", sItemName);
		SetTrieString(hItemTrie, "name", sName);
		SetTrieValue(hItemTrie, "translatable", FindStringInArray(g_hTranslatable, sItemName) != -1);

		PushArrayCell(hWeapons, StringToInt(sIndex));
		SetTrieValue(hSlotMap, sIndex, hItemTrie);
	} while (KvGotoNextKey(hKvItems, false));

	RecursiveCloseKeyValuesByArray(hArrayPrefabs, hTriePrefabs);
	CloseHandle(hKvItems);
	CloseHandle(hTrieDefaults);
}

public LoadWeaponConfig() {
	if(!FileExists(g_sCfgFile)) {
		return;
	}

	new Handle:kv = CreateKeyValues("WeaponToggles");
	FileToKeyValues(kv, g_sCfgFile);
	KvGotoFirstSubKey(kv, false);

	new iToggledCount = 0;
	do {
		new String:sIDI[255];
		KvGetSectionName(kv, sIDI, sizeof(sIDI));
		new iState = KvGetNum(kv, NULL_STRING, 0);

		new Handle:hTrieItem = INVALID_HANDLE;
		GetTrieValue(g_hSlotMap, sIDI, hTrieItem);

		if(hTrieItem == INVALID_HANDLE) {
			LogMessage("Item at index '%s' is not a weapon. Removing from config...", sIDI);
			continue;
		}

		SetTrieValue(hTrieItem, "toggled", iState);

		if(iState != 0)iToggledCount++;
	} while (KvGotoNextKey(kv, false));

	LogMessage("By default all items are %s", g_bDefault ? "blocked" : "allowed");
	LogMessage("There are %i weapons in total. %i of them are %s.", GetArraySize(g_hWeapons), iToggledCount, g_bDefault ? "allowed" : "blocked");

	CloseHandle(kv);
}

public SaveWeaponConfig() {
	new Handle:kv = CreateKeyValues("WeaponToggles");

	for(new i = 0; i < GetArraySize(g_hWeapons); i++) {
		new iItemDefinitionIndex = GetArrayCell(g_hWeapons, i);
		new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);

		new iState = 0;
		GetTrieValue(hTrieItem, "toggled", iState);

		new String:sIDX[8];
		IntToString(iItemDefinitionIndex, sIDX, sizeof(sIDX));
		KvSetNum(kv, sIDX, iState);
	}

	KeyValuesToFile(kv, g_sCfgFile);
	CloseHandle(kv);
}

/////////////////
//N A T I V E S//
/////////////////
public Native_IsEnabled(Handle:hPlugin, iNumParams) {
	return g_bEnabled;
}

public Native_BlockByDefault(Handle:hPlugin, iNumParams) {
	return !g_bDefault;
}

public Native_BlockStrangeWeapons(Handle:hPlugin, iNumParams) {
	return g_bBlockStrangeWeapons;
}

public Native_BlockSetHats(Handle:hPlugin, iNumParams) {
	return g_bBlockSetHats;
}

public Native_ToggleItem(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);

	ToggleItem(iItemDefinitionIndex);
}

public Native_IsItemToggled(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE) {
		new iState = 0;
		GetTrieValue(hTrieItem, "toggled", iState);

		return bool:iState;
	}

	return false;
}

public Native_GetItemTrie(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);

	SetNativeCellRef(2, hTrieItem);
	return true;
}

public Native_GetPrettyName(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	new iClient = GetNativeCell(2);

	new iMaxLen = GetNativeCell(4);

	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE) {
		new String:sItemName[128];
		GetTrieString(hTrieItem, "item_name", sItemName, sizeof(sItemName));

		new String:sName[128];
		GetTrieString(hTrieItem, "name", sName, sizeof(sName));

		new bool:bTranslatable = false;
		GetTrieValue(hTrieItem, "translatable", bTranslatable);

		decl String:sAnnounce[255];
		if(bTranslatable) {
			Format(sAnnounce, sizeof(sAnnounce), "%T", sItemName, iClient);
		} else {
			strcopy(sAnnounce, sizeof(sAnnounce), sName);
		}

		SetNativeString(3, sAnnounce, iMaxLen, false);
		return true;
	}

	return false;
}


public Native_GetWeaponArray(Handle:hPlugin, iNumParams) {
	SetNativeCellRef(1, g_hWeapons);
	return true;
}

public Native_GetTransString(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	new iMaxLen = GetNativeCell(3);

	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE) {
		new String:sItemName[128];
		GetTrieString(hTrieItem, "item_name", sItemName, sizeof(sItemName));

		SetNativeString(2, sItemName, iMaxLen, false);
		return true;
	}

	return false;
}

public Native_IsItemBlocked(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);

	return IsItemBlocked(iItemDefinitionIndex);
}

public Native_AnnounceBlock(Handle:hPlugin, iNumParams) {
	if(!g_bAnnounce)return;
	new iClient = GetNativeCell(1);
	new iItemDefinitionIndex = GetNativeCell(2);

	//forward tNUP_OnAnnounce(iClient, iItemDefinitionIndex, Handle:hTrieItem);
	Call_StartForward(g_hForwardAnnounce);
	Call_PushCell(iClient);
	Call_PushCell(iItemDefinitionIndex);
	Call_PushCell(GetItemTrie(iItemDefinitionIndex));
	Call_Finish();
}

public Native_ReportWeight(Handle:hPlugin, iNumParams) {
	new iWeight = GetNativeCell(1);

	if(iWeight >= g_iMaxWeight) {
		g_hModuleToUse = hPlugin;
		g_iMaxWeight = iWeight;
	}

	return g_iMaxWeight;
}

public Native_UseThisModule(Handle:hPlugin, iNumParams) {
	if(g_hModuleToUse == hPlugin)return true;
	return false;
}

public Native_IsSetHatAndShouldBeBlocked(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	return IsSetHatAndShouldBeBlocked(iItemDefinitionIndex);
}

public Native_GetDefaultIDIForClass(Handle:hPlugin, iNumParams) {
	new TFClassType:xClass = TFClassType:GetNativeCell(1);
	new iSlot = GetNativeCell(2);

	return GetDefaultIDIForClass(xClass, iSlot);
}

public Native_GetDefaultWeaponForClass(Handle:hPlugin, iNumParams) {
	new TFClassType:xClass = TFClassType:GetNativeCell(1);
	new iSlot = GetNativeCell(2);
	new iMaxLen = GetNativeCell(4);

	new String:sClassName[iMaxLen];
	if(GetDefaultWeaponForClass(xClass, iSlot, sClassName, iMaxLen)) {
		SetNativeString(3, sClassName, iMaxLen, false);
		return true;
	}

	return false;
}

public Native_GetWeaponSlotByIDI(Handle:hPlugin, iNumParams) {
	new iItemDefinitionIndex = GetNativeCell(1);
	return GetWeaponSlot(iItemDefinitionIndex);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("tNUP_IsEnabled", Native_IsEnabled);
	CreateNative("tNUP_BlockByDefault", Native_BlockByDefault);

	CreateNative("tNUP_ToggleItem", Native_ToggleItem);

	CreateNative("tNUP_BlockStrangeWeapons", Native_BlockStrangeWeapons);
	CreateNative("tNUP_BlockSetHats", Native_BlockSetHats);

	CreateNative("tNUP_IsItemBlocked", Native_IsItemBlocked);
	CreateNative("tNUP_GetWeaponToggleState", Native_IsItemToggled);

	CreateNative("tNUP_GetPrettyName", Native_GetPrettyName);
	CreateNative("tNUP_GetWeaponTranslationString", Native_GetTransString);
	CreateNative("tNUP_GetWeaponArray", Native_GetWeaponArray);
	CreateNative("tNUP_GetItemTrie", Native_GetItemTrie);

	CreateNative("tNUP_IsSetHatAndShouldBeBlocked", Native_IsSetHatAndShouldBeBlocked);
	CreateNative("tNUP_UseThisModule", Native_UseThisModule);
	CreateNative("tNUP_ReportWeight", Native_ReportWeight);

	CreateNative("tNUP_AnnounceBlock", Native_AnnounceBlock);

	CreateNative("tNUP_GetDefaultWeaponForClass", Native_GetDefaultWeaponForClass);
	CreateNative("tNUP_GetDefaultIDIForClass", Native_GetDefaultIDIForClass);

	CreateNative("tNUP_GetWeaponSlotByIDI", Native_GetWeaponSlotByIDI);


	RegPluginLibrary("tNoUnlocksPls");
	return APLRes_Success;
}


/////////////////
//H E L P E R S//
/////////////////
KvCopySubkeysSafe_Iterate(Handle:hOrigin, Handle:hDest, bool:bReplace=true, bool:bFirst=true) {
do {
		new String:sSection[255];
		KvGetSectionName(hOrigin, sSection, sizeof(sSection));

		new String:sValue[255];
		KvGetString(hOrigin, "", sValue, sizeof(sValue));

		new bool:bIsSubSection = ((KvNodesInStack(hOrigin) == 0) || (KvGetDataType(hOrigin, "") == KvData_None && KvNodesInStack(hOrigin) > 0));

		if(!bIsSubSection) {
			new bool:bExists = !(KvGetDataType(hDest, sSection) == KvData_None);

			// Always overwrite the prefab section, so we actually dive deeper into
			// the keyvalues tree.
			if(!bExists || (bExists && bReplace) || StrEqual(sSection, "prefab")) {
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

public RecursiveCloseKeyValuesByArray(Handle:hArray, Handle:hTrie) {
	for(new iPos = 0; iPos < GetArraySize(hArray); iPos++) {
		new String:sKey[64];
		GetArrayString(hArray, iPos, sKey, sizeof(sKey));

		RecursiveCloseHandleAtomic(hTrie, sKey);
	}

	CloseHandle(hArray);
	CloseHandle(hTrie);
}

public RecursiveCloseHandleAtomic(Handle:hTrie, const String:sEntry[64]) {
	new Handle:hResultPart = INVALID_HANDLE;
	GetTrieValue(hTrie, sEntry, hResultPart);
	CloseHandle(hResultPart);
}

public ToggleItem(iItemDefinitionIndex) {
	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE) {
		new iState = 0;
		GetTrieValue(hTrieItem, "toggled", iState);
		SetTrieValue(hTrieItem, "toggled", !iState);
		g_bSomethingChanged = true;
	}
}

public IsItemBlocked(iItemDefinitionIndex) {
	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE) {
		new iState = 0;
		GetTrieValue(hTrieItem, "toggled", iState);

		new bool:bIsToggled = (iState == 1);
		new bool:bResult = g_bDefault;
		if(bIsToggled)bResult = !bResult;

		return bResult;
	}

	return false;
}

public Handle:GetItemTrie(iItemDefinitionIndex) {
	new Handle:hItemPrefab = INVALID_HANDLE;

	new String:sKey[8];
	Format(sKey, sizeof(sKey), "%i", iItemDefinitionIndex);
	GetTrieValue(g_hSlotMap, sKey, hItemPrefab);

	return hItemPrefab;
}

public GetWeaponSlot(iItemDefinitionIndex) {
	new iSlot = -1;
	new Handle:hTrieItem = GetItemTrie(iItemDefinitionIndex);
	if(hTrieItem != INVALID_HANDLE)GetTrieValue(hTrieItem, "item_slot", iSlot);

	return iSlot;
}

stock CloseTrieHandlesByArray(Handle:hTrie, Handle:hArray, iArrayElementSize = 64) {
	for(new i = 0; i < GetArraySize(hArray); i++) {
		new String:sEntry[iArrayElementSize];
		GetArrayString(hArray, i, sEntry, iArrayElementSize);

		new Handle:hResultPart = INVALID_HANDLE;
		GetTrieValue(hTrie, sEntry, hResultPart);
		CloseHandle(hResultPart);
	}

	CloseHandle(hTrie);
	CloseHandle(hArray);
}

stock StrToUpper(const String:str[], String:buffer[], bufsize) {
	new n=0, x=0;
	while (str[n] != '\0' && x < (bufsize-1)) {
		new charpls = str[n++];
		if (IsCharLower(charpls))charpls = CharToUpper(charpls);
		buffer[x++] = charpls;
	}

	buffer[x++] = '\0';

	return x;
}


/////////////////
// STATIC DATA //
/////////////////
public IsWeaponSlot(String:sItemSlot[]) {
	if(StrEqual(sItemSlot, "primary"))return 0;
	if(StrEqual(sItemSlot, "secondary"))return 1;
	if(StrEqual(sItemSlot, "melee"))return 2;
	if(StrEqual(sItemSlot, "pda"))return 3;
	if(StrEqual(sItemSlot, "pda2"))return 4;
	return -1;
}

public bool:IsUnrelatedItemClass(String:sItemClass[]) {
	return (StrEqual(sItemClass, "tool") ||
			StrEqual(sItemClass, "supply_crate") ||
			StrEqual(sItemClass, "map_token") ||
			StrEqual(sItemClass, "class_token") ||
			StrEqual(sItemClass, "slot_token") ||
			StrEqual(sItemClass, "bundle") ||
			StrEqual(sItemClass, "upgrade") ||
			StrEqual(sItemClass, "craft_item"));
}

public bool:GetDefaultWeaponForClass(TFClassType:xClass, iSlot, String:sOutput[], maxlen) {
	switch(xClass) {
		case TFClass_Scout: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_scattergun"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_pistol_scout"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_bat"); return true; }
			}
		}
		case TFClass_Sniper: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_sniperrifle"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_smg"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_club"); return true; }
			}
		}
		case TFClass_Soldier: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_rocketlauncher"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_shotgun_soldier"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_shovel"); return true; }
			}
		}
		case TFClass_DemoMan: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_grenadelauncher"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_pipebomblauncher"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_bottle"); return true; }
			}
		}
		case TFClass_Medic: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_syringegun_medic"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_medigun"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_bonesaw"); return true; }
			}
		}
		case TFClass_Heavy: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_minigun"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_shotgun_hwg"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_fists"); return true; }
			}
		}
		case TFClass_Pyro: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_flamethrower"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_shotgun_pyro"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_fireaxe"); return true; }
			}
		}
		case TFClass_Spy: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_revolver"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_builder"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_knife"); return true; }
				case 4: { Format(sOutput, maxlen, "tf_weapon_invis"); return true; }				
			}
		}
		case TFClass_Engineer: {
			switch(iSlot) {
				case 0: { Format(sOutput, maxlen, "tf_weapon_shotgun_primary"); return true; }
				case 1: { Format(sOutput, maxlen, "tf_weapon_pistol"); return true; }
				case 2: { Format(sOutput, maxlen, "tf_weapon_wrench"); return true; }
				case 3: { Format(sOutput, maxlen, "tf_weapon_pda_engineer_build"); return true; }
			}
		}
	}

	Format(sOutput, maxlen, "");
	return false;
}

public GetDefaultIDIForClass(TFClassType:xClass, iSlot) {
	switch(xClass) {
		case TFClass_Scout: {
			switch(iSlot) {
				case 0: { return 13; }
				case 1: { return 23; }
				case 2: { return 0; }
			}
		}
		case TFClass_Sniper: {
			switch(iSlot) {
				case 0: { return 14; }
				case 1: { return 16; }
				case 2: { return 3; }
			}
		}
		case TFClass_Soldier: {
			switch(iSlot) {
				case 0: { return 18; }
				case 1: { return 10; }
				case 2: { return 6; }
			}
		}
		case TFClass_DemoMan: {
			switch(iSlot) {
				case 0: { return 19; }
				case 1: { return 20; }
				case 2: { return 1; }
			}
		}
		case TFClass_Medic: {
			switch(iSlot) {
				case 0: { return 17; }
				case 1: { return 29; }
				case 2: { return 8; }
			}
		}
		case TFClass_Heavy: {
			switch(iSlot) {
				case 0: { return 15; }
				case 1: { return 11; }
				case 2: { return 5; }
			}
		}
		case TFClass_Pyro: {
			switch(iSlot) {
				case 0: { return 21; }
				case 1: { return 12; }
				case 2: { return 2; }
			}
		}
		case TFClass_Spy: {
			switch(iSlot) {
				case 0: { return 24; }
				case 1: { return 735; }
				case 2: { return 4; }
				case 4: { return 30; }				
			}
		}
		case TFClass_Engineer: {
			switch(iSlot) {
				case 0: { return 9; }
				case 1: { return 22; }
				case 2: { return 7; }
				case 3: { return 25; }
			}
		}
	}

	return -1;
}

// %%START%%
stock bool:IsSetHatAndShouldBeBlocked(iIDI) {
	// Set: polycount_sniper
	// Hat: Ol' Snaggletooth
	// Weapons: The Sydney Sleeper, Darwin's Danger Shield, The Bushwacka
	if(iIDI == 229 && !IsItemBlocked(230) && !IsItemBlocked(231) && !IsItemBlocked(232))return true;

	// Set: polycount_scout
	// Hat: The Milkman
	// Weapons: The Shortstop, The Holy Mackerel, Mad Milk
	if(iIDI == 219 && !IsItemBlocked(220) && !IsItemBlocked(221) && !IsItemBlocked(222))return true;

	// Set: polycount_soldier
	// Hat: The Grenadier's Softcap
	// Weapons: The Battalion's Backup, The Black Box
	if(iIDI == 227 && !IsItemBlocked(226) && !IsItemBlocked(228))return true;

	// Set: polycount_pyro
	// Hat: The Attendant
	// Weapons: The Powerjack, The Degreaser
	if(iIDI == 213 && !IsItemBlocked(214) && !IsItemBlocked(215))return true;

	// Set: polycount_spy
	// Hat: The Familiar Fez
	// Weapons: L'Etranger, Your Eternal Reward
	if(iIDI == 223 && !IsItemBlocked(224) && !IsItemBlocked(225))return true;

	// The following sets won't be blocked even if sm_tnounlockspls_blocksets is enabled!
	// Sets without hats: medieval_medic, rapid_repair, hibernating_bear, experts_ordnance
	// Sets without attributes: drg_moonman, drg_victory, black_market, bonk_fan, winter2011_scout_elf, gangland_spy, swashbucklers_swag, general_suit, airborne_armaments, drg_brainiac, desert_sniper, desert_demo

	return false;
}
// %%END%%