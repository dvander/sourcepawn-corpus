#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 				"2.0.1"
#define PATH_ITEMS_GAME			"scripts/items/items_game.txt"

new Handle:g_hWeapons;
new Handle:g_hWeaponsArray;

new Handle:g_hItems;
new Handle:g_hTrieDefaults;
new Handle:g_hTriePrefabs;
new Handle:g_hArrayPrefabs;

new Handle:g_hCvarFile = INVALID_HANDLE;
new Handle:g_hCvarNoScopeBody = INVALID_HANDLE;
new Handle:g_hCvarNoScopeHead = INVALID_HANDLE;
new Handle:g_hCvarShowMissedParticle = INVALID_HANDLE;
new Handle:g_hCvarEnabled = INVALID_HANDLE;

new String:g_sCfgFile[255];
new Float:g_fNoScopeModifierBody;
new Float:g_fNoScopeModifierHead;
new bool:g_bShowMissedParticle;
new bool:g_bEnabled;

public Plugin:myinfo =
{
	name 		= "tHeadshotOnly",
	author 		= "Thrawn",
	description = "Restricts certain weapons to headshots only. Uses SDKHooks.",
	version 	= VERSION,
};

public OnPluginStart() {
	// Declare some cvars

	CreateConVar("sm_theadshotonly_version", VERSION, "[TF2] tHeadshotOnly", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Convar to enable/disable the plugin
	g_hCvarEnabled = CreateConVar("sm_theadshotonly_enable", "1", "Enable/disable this plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	// Convar to store the config file in
	g_hCvarFile = CreateConVar("sm_theadshotonly_cfgfile", "tHeadshotOnly.cfg", "File to store configuration in", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarFile, Cvar_Changed);

	// Convars for the no-scope-modifiers
	g_hCvarNoScopeBody = CreateConVar("sm_theadshotonly_noscope_body", "0.0", "Modifier for body-shot damage dealt when not zoomed in", FCVAR_PLUGIN, true, 0.0);
	g_hCvarNoScopeHead = CreateConVar("sm_theadshotonly_noscope_head", "1.0", "Modifier for head-shot damage dealt when not zoomed in", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCvarNoScopeBody, Cvar_Changed);
	HookConVarChange(g_hCvarNoScopeHead, Cvar_Changed);


	// Convar to enable the miss particle
	g_hCvarShowMissedParticle = CreateConVar("sm_theadshotonly_particle", "1", "If enabled bodyshots with a 0.0 dmg modifier pop up 'miss' particles", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarShowMissedParticle, Cvar_Changed);

	// Command to reload the config
	RegAdminCmd("sm_theadshotonly_reloadconfig", CMD_ReloadConfig, ADMFLAG_CONFIG);

	// Abort if there is no items_game.txt
	if(!FileExists(PATH_ITEMS_GAME, true)) {
		SetFailState("items_game.txt does not exist. Something is seriously wrong!");
		return;
	}

	// Start with reading in the items_game.txt
	g_hItems = CreateKeyValues("");
	if (!FileToKeyValues(g_hItems, PATH_ITEMS_GAME)) {
		SetFailState("Could not parse items_game.txt. Something is seriously wrong!");
		return;
	}

	// Preload some stuff
	LoadDefaultTrie();
	LoadPrefabs();

	// Account for late loading
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		if(IsClientInGame(iClient)) {
			SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_hCvarFile) {
		GetConVarString(g_hCvarFile, g_sCfgFile, sizeof(g_sCfgFile));
		BuildPath(Path_SM, g_sCfgFile, sizeof(g_sCfgFile), "configs/%s", g_sCfgFile);

		LoadConfig();
	} else if(convar == g_hCvarShowMissedParticle) {
		g_bShowMissedParticle = GetConVarBool(g_hCvarShowMissedParticle);
	} else if(convar == g_hCvarNoScopeHead) {
		g_fNoScopeModifierHead = GetConVarFloat(g_hCvarNoScopeHead);
	} else if(convar == g_hCvarNoScopeBody) {
		g_fNoScopeModifierBody = GetConVarFloat(g_hCvarNoScopeBody);
	} else if(convar == g_hCvarEnabled) {
		g_bEnabled = GetConVarBool(g_hCvarEnabled);
	}
}

public OnConfigsExecuted() {
	g_fNoScopeModifierBody = GetConVarFloat(g_hCvarNoScopeBody);
	g_fNoScopeModifierHead = GetConVarFloat(g_hCvarNoScopeHead);
	g_bShowMissedParticle = GetConVarBool(g_hCvarShowMissedParticle);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);

	GetConVarString(g_hCvarFile, g_sCfgFile, sizeof(g_sCfgFile));
	BuildPath(Path_SM, g_sCfgFile, sizeof(g_sCfgFile), "configs/%s", g_sCfgFile);

	LoadConfig();
}

public Action:CMD_ReloadConfig(client,args) {
	LoadConfig();

	ReplyToCommand(client, "tHeadshotOnly config reloaded. Found %i weapons.", GetArraySize(g_hWeaponsArray));

	return Plugin_Handled;
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

public LoadConfig() {
	// First load the current config file
	new Handle:hKvCfg = CreateKeyValues("tHeadshotOnly");
	FileToKeyValues(hKvCfg, g_sCfgFile);

	// Preload the config with weapons that have no scope as far as we know
	// to this day 2014-05-29
	// This would not be necessary if there was a way to detect whether a
	// weapon has a scope or not.
	if(KvJumpToKey(hKvCfg, "Weapons without scope", true)) {
		KvSetNum(hKvCfg, "The Ambassador", 1);
		KvSetNum(hKvCfg, "The Huntsman", 1);
		KvSetNum(hKvCfg, "Festive Ambassador", 1);
		KvSetNum(hKvCfg, "Festive Huntsman", 1);
		KvSetNum(hKvCfg, "The Fortified Compound", 1);
		KvGoBack(hKvCfg);
	}


	// Clear the current runtime config
	if(g_hWeapons != INVALID_HANDLE && g_hWeaponsArray != INVALID_HANDLE) {
		RecursiveCloseHandlesByArray(g_hWeaponsArray, g_hWeapons);
	}

	// Initialize an empty trie/array combo
	g_hWeapons = CreateTrie();
	g_hWeaponsArray = CreateArray();

	// Then iterate over all weapons and find all that have the tag "can_headshot"
	KvRewind(g_hItems);
	KvJumpToKey(g_hItems, "items");
	KvGotoFirstSubKey(g_hItems, false);

	new String:sIndex[8];
	do {
		KvGetSectionName(g_hItems, sIndex, sizeof(sIndex));

		//Skip item with id 'default'
		if(StrEqual(sIndex, "default")) {
			continue;
		}

		// Get basic information about the item: Defaults < Prefabs < Values
		new String:sItemSlot[16];
		new String:sItemClass[64];
		new String:sName[128];
		GetItemInfo(sItemSlot, sizeof(sItemSlot), sItemClass, sizeof(sItemClass), sName, sizeof(sName));

		// Skip all items that are no weapons
		if(IsUnrelatedItemClass(sItemClass)) {
			continue;
		}

		if(!IsWeaponSlot(sItemSlot)) {
			continue;
		}

		// Skip all weapons that don't have the "can_headshot" tag
		new bool:bCanHeadshot = false;
		if(KvJumpToKey(g_hItems, "tags")) {
			if(KvGotoFirstSubKey(g_hItems, false)) {
				do {
					new String:sTag[64];
					KvGetSectionName(g_hItems, sTag, sizeof(sTag));

					if(StrEqual(sTag, "can_headshot")) {
						bCanHeadshot = true;
						break;
					}
				} while (KvGotoNextKey(g_hItems, false));
				KvGoBack(g_hItems);
			}
			KvGoBack(g_hItems);
		}

		if(!bCanHeadshot) {
			continue;
		}

		// At this point only weapons that can headshot remain
		// Load the value from the current config and re-set it.
		// This makes sure new weapons are being added to the
		// config file automatically.

		// Get Bodyshot modifier
		KvJumpToKey(hKvCfg, "Bodyshot Modifiers", true);
		new Float:fBodyshotModifier = KvGetFloat(hKvCfg, sName);
		if(fBodyshotModifier < 0) {
			fBodyshotModifier = 0.0;
		}
		KvSetFloat(hKvCfg, sName, fBodyshotModifier);
		KvGoBack(hKvCfg);

		// Get Headshot modifier
		KvJumpToKey(hKvCfg, "Headshot Modifiers", true);
		new Float:fHeadshotModifier = KvGetFloat(hKvCfg, sName, 1.0);
		if(fHeadshotModifier < 0) {
			fHeadshotModifier = 0.0;
		}
		KvSetFloat(hKvCfg, sName, fHeadshotModifier);
		KvGoBack(hKvCfg);

		// Get whether this weapon has a scope attached, i.e. is zoomable
		new bool:bHasNoScope = false;
		if(KvJumpToKey(hKvCfg, "Weapons without scope")) {
			bHasNoScope = bool:KvGetNum(hKvCfg, sName, 0);
			KvGoBack(hKvCfg);
		}

		// Pack everything we need later in a trie...
		new Handle:hWeapon = CreateTrie();
		SetTrieString(hWeapon, "name",	sName);
		SetTrieString(hWeapon, "class",	sItemClass);
		SetTrieValue(hWeapon, "modifier_body", fBodyshotModifier);
		SetTrieValue(hWeapon, "modifier_head", fHeadshotModifier);
		SetTrieValue(hWeapon, "has_no_scope", bHasNoScope);

		// and store it in another trie/array indexed by the weapon id.
		PushArrayCell(g_hWeaponsArray, StringToInt(sIndex));
		SetTrieValue(g_hWeapons, sIndex, hWeapon);
	} while (KvGotoNextKey(g_hItems, false));


	KvRewind(hKvCfg);
	KvGoBack(hKvCfg);

	// Save the config file back to disk. There might be new weapons :)
	KeyValuesToFile(hKvCfg, g_sCfgFile);
	CloseHandle(hKvCfg);
}

// this is being called by the method above and is just a convenience wrapper
// around some keyvalues loading. It basically loads in all prefab values for
// an item.
GetItemInfo(String:sItemSlot[], maxLenIS, String:sItemClass[], maxLenIC, String:sName[], maxLenName) {
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

		// Copy each prefab into this item directly. Do that recursively, so entries like
		// used_by_classes and tags don't get truncated.
		for(new iPrefabIdx = 0; iPrefabIdx < iPrefabsUsed; iPrefabIdx++) {
			new Handle:hKvPrefab = INVALID_HANDLE;
			if(GetTrieValue(g_hTriePrefabs, sPrefabBuffers[iPrefabIdx], hKvPrefab) && hKvPrefab != INVALID_HANDLE) {
				KvCopySubkeysSafe_Iterate(hKvPrefab, g_hItems, true, true);
			}
		}

		// Empty out the prefab entry, so we don't do this stuff again on config
		// reload.
		KvGetString(g_hItems, "prefab", sPrefabSlot, sizeof(sPrefabSlot), "");
	}

	// And finally use the values defined in the section directly
	KvGetString(g_hItems, "item_slot", sItemSlot, maxLenIS, sItemSlot);
	KvGetString(g_hItems, "item_class", sItemClass, maxLenIC, sItemClass);

	// Always load the name from the KeyValues
	KvGetString(g_hItems, "name", sName, maxLenName);
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

public RecursiveCloseHandlesByArray(Handle:hArray, Handle:hTrie) {
	for(new iPos = 0; iPos < GetArraySize(hArray); iPos++) {
		new iKey = GetArrayCell(hArray, iPos);
		new String:sKey[64];
		IntToString(iKey, sKey, sizeof(sKey));

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



public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) {
	if(!g_bEnabled) {
		return Plugin_Continue;
	}

	if(attacker > 0 && attacker <= MaxClients) {
		decl String:sWeapon[32]; decl String:sInflictor[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		GetEdictClassname(inflictor, sInflictor, sizeof(sInflictor));

		if((damagetype & DMG_SLASH)) {
			return Plugin_Continue;
		}


		// Skip weapons we don't care about
		new iWeaponId = TF2_GetCurrentWeapon(attacker);
		decl String:sIndex[8];
		IntToString(iWeaponId, sIndex, sizeof(sIndex));

		new Handle:hWeapon = INVALID_HANDLE;
		GetTrieValue(g_hWeapons, sIndex, hWeapon);

		if(hWeapon == INVALID_HANDLE) {
			return Plugin_Continue;
		}

		// Grab a few more facts about the shot
		new bool:bIsBodyshot = (damagecustom != TF_CUSTOM_HEADSHOT && damagecustom != TF_CUSTOM_HEADSHOT_DECAPITATION);
		new bool:bZoomed = TF2_IsPlayerInCondition(attacker, TFCond_Zoomed);

		new bool:bHasNoScope = false;
		GetTrieValue(hWeapon, "has_no_scope", bHasNoScope);

		// Determine modifier based on zoom state and hitzone (body vs head)
		new Float:fModifier = 1.0;
		if(bZoomed || bHasNoScope) {
			if(bIsBodyshot) {
				GetTrieValue(hWeapon, "modifier_body", fModifier);
			} else {
				GetTrieValue(hWeapon, "modifier_head", fModifier);
			}
		} else {
			if(bIsBodyshot) {
				fModifier = g_fNoScopeModifierBody;
			} else {
				fModifier = g_fNoScopeModifierHead;
			}
		}

		damage *= fModifier;

		if(g_bShowMissedParticle && fModifier == 0.0 && IsClientInGame(attacker)) {
			decl Float:pos[3];
			GetClientEyePosition(victim, pos);
			pos[2] += 4.0;

			TE_ParticleToClient(attacker, "miss_text", pos);
		}

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

stock TF2_GetCurrentWeapon(client) {
	if( client > 0 && client < MaxClients) {
		new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(iWeapon == -1 || !IsValidEntity(iWeapon))return -1;
		return GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	}
	return -1;
}

stock TE_ParticleToClient(client,
			String:Name[],
            Float:origin[3]=NULL_VECTOR,
            Float:start[3]=NULL_VECTOR,
            Float:angles[3]=NULL_VECTOR,
            entindex=-1,
            attachtype=-1,
            attachpoint=-1,
            bool:resetParticles=true,
            Float:delay=0.0)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE)
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }

    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    TE_SendToClient(client, delay);
}
