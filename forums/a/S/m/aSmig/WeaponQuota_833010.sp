#include <sourcemod>
#include <keyvalues>

#pragma semicolon 1
#define VERSION "0.0.3"

/* Untested */

public Plugin:myinfo = {
    name = "WeaponQuota",
    author = "aSmig",
    description = "Limit the number of times each player may purchase or pick up a weapon per map.",
    version = VERSION,
    url = "http://ta.failte.romhat.net/blog/?cat=4"
};

new Handle:quota_file;
new Handle:quota_counts;
new String:path[PLATFORM_MAX_PATH];

public OnPluginStart(){
    if (FindPluginByFile("UserRestrict.smx") == INVALID_HANDLE) {
	PrintToServer("[WeaponQuota] This script requires UserRestrict by theY4Kman.  Go install that now.");
	SetFailState("Missing UserRestrict.smx. Aborting.");
	return;
    }
    quota_file = CreateKeyValues("WeaponQuota");
    quota_counts = CreateKeyValues("QuotaCounts");
    BuildPath(Path_SM, path, sizeof(path), "configs/WeaponQuota.cfg");
    FileToKeyValues(quota_file, path);
    KvGotoFirstSubKey(quota_file);

    HookEvent("item_pickup", WQIdentifyItem, EventHookMode_Post);
    HookEvent("player_death", WQPlayerDeath, EventHookMode_Post);
    HookEvent("game_newmap", WQNewMap, EventHookMode_PostNoCopy);
    CreateConVar("weapon_quota_version", VERSION, "The version of WeaponQuota running.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    PrintToServer("[WeaponQuota] by aSmig loaded");
}

public OnPluginEnd(){
    CloseHandle(quota_file);
    CloseHandle(quota_counts);
    PrintToServer("[WeaponQuota] by aSmig unloaded");
}

public Action:WQIdentifyItem(Handle:event, const String:name[], bool:dontBroadcast){
    new String:weapon[32];
    new playerId = GetEventInt(event, "userid");
    new player = GetClientOfUserId(playerId);
    new String:steam[32];

    GetClientAuthString(player, steam, sizeof(steam));
    GetEventString(event, "item", weapon, sizeof(weapon));

    KvRewind(quota_file);
    if(KvGetNum(quota_file, weapon)){
	KvRewind(quota_counts);
	KvJumpToKey(quota_counts, steam, true);
	KvSetNum(quota_counts, weapon, KvGetNum(quota_counts, weapon) + 1);
    }

    return Plugin_Continue;
}

public Action:WQPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
    new playerId = GetEventInt(event, "userid");
    new player = GetClientOfUserId(playerId);
    new String:steam[32];

    GetClientAuthString(player, steam, sizeof(steam));
    KvRewind(quota_counts);
    if(KvJumpToKey(quota_counts, steam)) {
	decl String:weapon[32];
	new moretodo = 0;
	if(KvGotoFirstSubKey(quota_counts, false)) {
	    do {
		KvGetSectionName(quota_counts, weapon, sizeof(weapon));
		PrintToChat(player,"%cThis key has name: %c%s%c and number: %c%d%c.",0x03,0x04,weapon,0x03,0x04,KvGetNum(quota_counts, NULL_STRING),0x03);

		KvRewind(quota_file);
		if (KvGetNum(quota_counts, NULL_STRING) >= KvGetNum(quota_file, weapon)) {
		    PrintToChat(player,"%cYou have reached your quota for the %c%s%c.",0x03,0x04,weapon,0x03);
		    ServerCommand("user_restrict %d %s", playerId, weapon);
		    moretodo = KvDeleteThis(quota_counts);
		    continue;
		}
		moretodo = KvGotoNextKey(quota_counts);
	    } while (moretodo == 1);
	}
    }

    return Plugin_Continue;
}

public Action:WQNewMap(Handle:event, const String:name[], bool:dontBroadcast){
    CloseHandle(quota_counts);
    quota_counts = CreateKeyValues("QuotaCounts");
    //unrestrict all
}
