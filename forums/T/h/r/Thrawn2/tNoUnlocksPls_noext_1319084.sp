#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <updater>
#include <tNoUnlocksPls>

#define VERSION			"0.4.0"
#define UPDATE_URL    	"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.noext.cfg"

#define WEIGHT			10

new bool:g_bCoreAvailable = false;

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - NoExt",
	author      = "Thrawn",
	description = "Tries to block unlocks without any extension.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};


public OnPluginStart() {
	CreateConVar("sm_tnounlockspls_noext_version", VERSION, "[TF2] tNoUnlocksPls - NoExtension", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}

	if (LibraryExists("tNoUnlocksPls")) {
		tNUP_ReportWeight(WEIGHT);
		g_bCoreAvailable = true;
	}

	HookEvent("post_inventory_application", CallCheckInventory, EventHookMode_Post);
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



public Action:CallCheckInventory(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!g_bCoreAvailable || !tNUP_IsEnabled() || !tNUP_UseThisModule())
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, CheckInventory, client);

	return Plugin_Continue;
}

public Action:CheckInventory(Handle:timer, any:client) {
	ReplaceItemsWithClassname(client, "tf_wearable");
	ReplaceItemsWithClassname(client, "tf_wearable_demoshield");

	LOOP_CLIENTWEAPONS(client, weapon, index) {
		ReplaceItem(client, weapon);
	}
}

public ReplaceItemsWithClassname(client, String:sClassname[]) {
	new iWearable = MaxClients + 1;
	while((iWearable = FindEntityByClassname(iWearable, sClassname)) != -1) {
		if(Entity_GetParent(iWearable) == client) {
			ReplaceItem(client, iWearable);
		}
	}
}

public ReplaceItem(client, iEntity) {
	new iItemDefinitionIndex = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
	new iItemQuality = GetEntProp(iEntity, Prop_Send, "m_iEntityQuality");
	if(iItemQuality == -1)return;

	new iSlot = tNUP_GetWeaponSlotByIDI(iItemDefinitionIndex);
	new bool:bIsBlocked = tNUP_IsItemBlocked(iItemDefinitionIndex) || (iItemQuality == QUALITY_STRANGE && tNUP_BlockStrangeWeapons());

	//LogMessage("Slot %d, Quality %d, IDI %d --> blocked: %s", iSlot, iItemQuality, iItemDefinitionIndex, bIsBlocked ? "yes" : "no");

	if(bIsBlocked) {
		new String:sWeaponClassName[128];
		if(tNUP_GetDefaultWeaponForClass(TF2_GetPlayerClass(client), iSlot, sWeaponClassName, sizeof(sWeaponClassName))) {
			tNUP_AnnounceBlock(client, iItemDefinitionIndex);

			if(Client_GetActiveWeapon(client) == iEntity) {
				Client_ChangeToLastWeapon(client);
			}

			RemovePlayerItem(client, iEntity);
			Entity_Kill(iEntity, true);

			Client_GiveWeapon(client, sWeaponClassName, false);
		}
	}
}