#pragma semicolon 1
#include <sourcemod>
#include <vanillaweps>
#undef REQUIRE_PLUGIN
#include <updater>
#include <tNoUnlocksPls>

#define VERSION			"0.4.0"
#define UPDATE_URL    	"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.vanillaweps.cfg"

#define WEIGHT			5

new bool:g_bCoreAvailable = false;

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - VanillaWeps",
	author      = "Thrawn",
	description = "Block unlocks using the UnlockBlock extension.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};


public OnPluginStart() {
	CreateConVar("sm_tnounlockspls_vanillaweps_version", VERSION, "[TF2] tNoUnlocksPls - VanillaWeps", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

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

public bool:OnClientCanUseItem(iClient, iItemDefinitionIndex, slot, iQuality) {
	if(!g_bCoreAvailable || !tNUP_IsEnabled() || !tNUP_UseThisModule())
		return true;

	if(tNUP_BlockStrangeWeapons() && iQuality == QUALITY_STRANGE) {
		tNUP_AnnounceBlock(iClient, iItemDefinitionIndex);
		return false;
	}

	if(tNUP_BlockSetHats() && tNUP_IsSetHatAndShouldBeBlocked(iItemDefinitionIndex)) {
		tNUP_AnnounceBlock(iClient, iItemDefinitionIndex);
		return false;
	}

	if(tNUP_IsItemBlocked(iItemDefinitionIndex)) {
		tNUP_AnnounceBlock(iClient, iItemDefinitionIndex);
		return false;
	}

	return true;
}