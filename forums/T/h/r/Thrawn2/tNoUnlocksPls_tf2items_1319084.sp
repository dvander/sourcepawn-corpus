#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <smlib>
#include <tf2items>
#undef REQUIRE_PLUGIN
#include <tNoUnlocksPls>
#include <updater>

#define VERSION			"0.4.0"
#define UPDATE_URL    	"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.tf2items.cfg"

#define WEIGHT			50

new bool:g_bCoreAvailable = false;

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - TF2Items",
	author      = "Thrawn",
	description = "Block unlocks using the TF2Items extension.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};

public OnPluginStart() {
	CreateConVar("sm_tnounlockspls_tf2items_version", VERSION, "[TF2] tNoUnlocksPls - TF2Items", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}

	if (LibraryExists("tNoUnlocksPls")) {
		tNUP_ReportWeight(WEIGHT);
		g_bCoreAvailable = true;
	}
}

public OnLibraryAdded(const String:name[]) {
    if (StrEqual(name, "tNoUnlocksPls")) {
    	tNUP_ReportWeight(WEIGHT);
    	g_bCoreAvailable = true;
    }

    if (StrEqual(name, "updater"))Updater_AddPlugin(UPDATE_URL);
}

public OnLibraryRemoved(const String:name[]) {
    if (StrEqual(name, "tNoUnlocksPls")) {
    	g_bCoreAvailable = false;
    }
}

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], iItemDefinitionIndex, itemLevel, itemQuality, entityIndex) {
	if(!g_bCoreAvailable || !tNUP_IsEnabled() || !tNUP_UseThisModule() || iItemDefinitionIndex < 35)
		return;

	if(tNUP_BlockSetHats() && tNUP_IsSetHatAndShouldBeBlocked(iItemDefinitionIndex)) {
		tNUP_AnnounceBlock(client, iItemDefinitionIndex);

		new Handle:hTrie = CreateTrie();
		SetTrieValue(hTrie, "client", client);
		SetTrieValue(hTrie, "entityIndex", entityIndex);

		CreateTimer(0.1, Timer_ReplaceWeapon, hTrie);

		return;
	}

	if(tNUP_IsItemBlocked(iItemDefinitionIndex) || (tNUP_BlockStrangeWeapons() && itemQuality != QUALITY_STRANGE)) {
		tNUP_AnnounceBlock(client, iItemDefinitionIndex);

		new Handle:hTrie = CreateTrie();
		SetTrieValue(hTrie, "client", client);
		SetTrieValue(hTrie, "itemDefinitionIndex", iItemDefinitionIndex);
		SetTrieValue(hTrie, "entityIndex", entityIndex);

		CreateTimer(0.01, Timer_ReplaceWeapon, hTrie);

		return;
	}
}

public Action:Timer_ReplaceWeapon(Handle:timer, any:hTrie) {
	new entityIndex = -1;
	GetTrieValue(hTrie, "entityIndex", entityIndex);

	new client = -1;
	GetTrieValue(hTrie, "client", client);

	new iItemDefinitionIndex = -1;
	GetTrieValue(hTrie, "itemDefinitionIndex", iItemDefinitionIndex);
	CloseHandle(hTrie);

	if(IsValidEntity(entityIndex)) {
		RemovePlayerItem(client, entityIndex);
		Entity_Kill(entityIndex, true);

		if(iItemDefinitionIndex != -1) {
			GiveReplacementItem(client, iItemDefinitionIndex);
		}
	}
}

public GiveReplacementItem(client, iItemDefinitionIndex) {
	new iSlot = tNUP_GetWeaponSlotByIDI(iItemDefinitionIndex);
	new String:sWeaponClassName[128];
	if(tNUP_GetDefaultWeaponForClass(TF2_GetPlayerClass(client), iSlot, sWeaponClassName, sizeof(sWeaponClassName))) {
		new iOverrideIDI = tNUP_GetDefaultIDIForClass(TF2_GetPlayerClass(client), iSlot);

		new Handle:hItem = TF2Items_CreateItem(OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
		TF2Items_SetClassname(hItem, sWeaponClassName);
		TF2Items_SetItemIndex(hItem, iOverrideIDI);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetNumAttributes(hItem, 0);

		new iWeapon = TF2Items_GiveNamedItem(client, hItem);
		CloseHandle(hItem);

		EquipPlayerWeapon(client, iWeapon);
	}
}