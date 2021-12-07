#include <sourcemod>
#include <sdktools>

// Definitions
#define PLUGIN_VERSION      "1.2"
#define PLUGIN_NAME         "[TF2] Fake Items"

#define QUALITY_NORMAL      0
#define QUALITY_VINTAGE     3
#define QUALITY_UNUSUAL     5
#define QUALITY_UNIQUE      6
#define QUALITY_COMMUNITY   7
#define QUALITY_DEVELOPER   8
#define QUALITY_SELFMADE    9
#define QUALITY_CUSTOMIZED  10

#define OBTAIN_DROP         0
#define OBTAIN_CRAFT        1
#define OBTAIN_TRADE        2
#define OBTAIN_UNBOXED      4
#define OBTAIN_GIFT         5
#define OBTAIN_EARNED       8

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = "Mecha the Slag",
    description = "Fakes item found",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    // G A M E  C H E C K //
    decl String:strGame[32];
    GetGameFolderName(strGame, sizeof(strGame));
    if (!(StrEqual(strGame, "tf"))) SetFailState("This plugin is only for Team Fortress 2, not '%s'", strGame);

    RegAdminCmd("sm_fakeitem", CommandFakeItem, ADMFLAG_SLAY, "sm_fakeitem <#userid|name> <item> <rarity> <obtainmethod>");
    CreateConVar("fakeitem_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public Action:CommandFakeItem(iClient, iArgs) {
    if (iArgs < 2) {
        ReplyToCommand(iClient, "[SM] Usage: sm_fakeitem <#userid|name> <item> <rarity> <obtainmethod>");
        return Plugin_Handled;
    }

    decl String:strUser[65];
    GetCmdArg(1, strUser, sizeof(strUser));
    decl String:strItem[PLATFORM_MAX_PATH];
    GetCmdArg(2, strItem, sizeof(strItem));
    
    new iQuality = 6;
    decl String:strQuality[65];
    if (iArgs >= 3) {
        GetCmdArg(3, strQuality, sizeof(strQuality));
        iQuality = StringToInt(strQuality);
        if (iQuality == 0) iQuality = QUALITY_UNIQUE;
        if (StrContains(strQuality, "unu", false) != -1) iQuality = QUALITY_UNUSUAL;
        if (StrContains(strQuality, "vin", false) != -1) iQuality = QUALITY_VINTAGE;
        if (StrContains(strQuality, "norm", false) != -1) iQuality = QUALITY_NORMAL;
        if (StrContains(strQuality, "uni", false) != -1) iQuality = QUALITY_UNIQUE;
        if (StrContains(strQuality, "def", false) != -1) iQuality = QUALITY_UNIQUE;
        if (StrContains(strQuality, "com", false) != -1) iQuality = QUALITY_COMMUNITY;
        if (StrContains(strQuality, "self", false) != -1) iQuality = QUALITY_SELFMADE;
        if (StrContains(strQuality, "made", false) != -1) iQuality = QUALITY_SELFMADE;
        if (StrContains(strQuality, "dev", false) != -1) iQuality = QUALITY_DEVELOPER;
        if (StrContains(strQuality, "val", false) != -1) iQuality = QUALITY_DEVELOPER;
        if (StrContains(strQuality, "cust", false) != -1) iQuality = QUALITY_CUSTOMIZED;
    }
    
    new iObtain = OBTAIN_DROP;
    decl String:strObtain[65];
    if (iArgs >= 4) {
        GetCmdArg(4, strObtain, sizeof(strObtain));
        iObtain = StringToInt(strObtain);
        if (StrContains(strObtain, "drop", false) != -1) iObtain = OBTAIN_DROP;
        if (StrContains(strObtain, "found", false) != -1) iObtain = OBTAIN_DROP;
        if (StrContains(strObtain, "find", false) != -1) iObtain = OBTAIN_DROP;
        if (StrContains(strObtain, "craft", false) != -1) iObtain = OBTAIN_CRAFT;
        if (StrContains(strObtain, "trade", false) != -1) iObtain = OBTAIN_TRADE;
        if (StrContains(strObtain, "crate", false) != -1) iObtain = OBTAIN_UNBOXED;
        if (StrContains(strObtain, "unbox", false) != -1) iObtain = OBTAIN_UNBOXED;
        if (StrContains(strObtain, "box", false) != -1) iObtain = OBTAIN_UNBOXED;
        if (StrContains(strObtain, "gift", false) != -1) iObtain = OBTAIN_GIFT;
        if (StrContains(strObtain, "recieve", false) != -1) iObtain = OBTAIN_GIFT;
        if (StrContains(strObtain, "earn", false) != -1) iObtain = OBTAIN_EARNED;
    }
    
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
            strUser,
            iClient,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE & COMMAND_FILTER_DEAD,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        if (IsValidClient(iClient)) ReplyToTargetError(iClient, target_count);
        return Plugin_Handled;
    }

    for (new i = 0; i < target_count; i++) {
        new iTarget = target_list[i];
        if (IsValidClient(iTarget)) {
            FireItemFound(iTarget, iQuality, strItem, iObtain);
        }
    }

    return Plugin_Handled;
}

FireItemFound(iClient, iQuality, String:strItem[], iObtain) {
    new Handle:hEvent = CreateEvent( "item_found" );
    if( hEvent != INVALID_HANDLE ) {
        SetEventInt( hEvent, "player", iClient );
        SetEventInt( hEvent, "quality", iQuality );
        SetEventString( hEvent, "item", strItem );
        SetEventInt( hEvent, "method", iObtain );
        SetEventBool( hEvent, "propername", true );
        FireEvent( hEvent );
    }
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}