// Includes
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION                  "1.01"

#define PATH_ITEMS_GAME                 "scripts/items/items_game.txt"
#define ITEMSGAME_RETURN_INDEX          0
#define ITEMSGAME_RETURN_CLASSNAME      1

#define NAME_ROOT                       "root"

new bool:g_bLoaded = false;
new Handle:g_hItems = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Items Game Manager",
    author = "Mecha the Slag",
    description = "Obtains item information from Items_Game.txt",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    CreateConVar("itemsgame_version", PLUGIN_VERSION, "Items Game Manager version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    LoadItemsGame();
    
    /*
    A few example uses:
    
    new Handle:hArray = ItemsGameSearch("classname => tf_wearable_item, slot => misc", ITEMSGAME_RETURN_INDEX);
    CloseHandle(hArray);
    
    decl String:strName[128];
    ItemsGameInfo(103, "name", strName, sizeof(strName));
    LogMessage("Index 103 is named: %s", strName);
    
    */
}

stock bool:ItemsGameExist() {
    return FileExists(PATH_ITEMS_GAME, true);
}

bool:LoadItemsGame() {
    if (g_hItems != INVALID_HANDLE) CloseHandle(g_hItems);
    g_hItems = INVALID_HANDLE;

    g_bLoaded = false;
    if (!ItemsGameExist()) {
        SetFailState("Unable to find items_game.txt. Reason: Game may not be using the items_game system.", PATH_ITEMS_GAME);
        return false;
    }

    g_hItems = CreateKeyValues(NAME_ROOT);
    if (!FileToKeyValues(g_hItems, PATH_ITEMS_GAME)) {
        SetFailState("Unable to load items_game.txt, despite it obviously being in the GCF. Reason: You may be running a listen server.");
        return false;
    }
    g_bLoaded = true;
    return true;
}

stock Handle:ItemsGameSearch(String:strSearch[], iReturn = ITEMSGAME_RETURN_INDEX) {
    new Handle:hArray = CreateArray();
    if (!g_bLoaded) return hArray;
    
    new Handle:hSearchName = CreateArray(128);
    new Handle:hSearchValue = CreateArray(128);
    
    if (!ParseSearch(strSearch, hSearchName, hSearchValue)) {
        CloseHandle(hSearchName);
        CloseHandle(hSearchValue);
        return hArray;
    }
    
    SetupItemsGame();
    decl String:strIndex[128];
    decl String:strClassname[128];
    decl String:strName[128];
    decl String:strValue[128];
    decl String:strRealValue[128];
    new iIndex;
    new bool:bAcceptable;
    
    KvGotoFirstSubKey(g_hItems, false);
    do {
        KvGetSectionName(g_hItems, strIndex, sizeof(strIndex));
        iIndex = StringToInt(strIndex);
        bAcceptable = true;
        
        for (new i = 0; i < GetArraySize(hSearchName); i++) {
            GetArrayString(hSearchName, i, strName, sizeof(strName));
            GetArrayString(hSearchValue, i, strValue, sizeof(strValue));
            
            if (StrEqual(strName, "index", false)) {
                strcopy(strRealValue, sizeof(strRealValue), strIndex);
            }
            else {
                KvGetString(g_hItems, strName, strRealValue, sizeof(strRealValue));
            }
            if (!StrEqual(strRealValue, strValue, false)) bAcceptable = false;
        }
        
        if (bAcceptable) {
            switch (iReturn) {
                case ITEMSGAME_RETURN_CLASSNAME: {
                    KvGetString(g_hItems, "item_class", strClassname, sizeof(strClassname));
                    if (!ArrayContainsString(hArray, strClassname)) PushArrayString(hArray, strClassname);
                }
                default: {
                    PushArrayCell(hArray, iIndex);
                }
            }
        }
    } while (KvGotoNextKey(g_hItems, false));
    
    return hArray;
}

public Native_ItemsGameSearch(Handle:hPlugin, iNumParams) {
    decl String:strSearch[512];
    GetNativeString(1, strSearch, sizeof(strSearch));
    new iReturn = GetNativeCell(2);
    
    new Handle:hArray = ItemsGameSearch(strSearch, iReturn);

    return _:hArray;
}

stock bool:ItemsGameInfo(iIndex, String:strName[], String:strReturn[], iMaxSize) {
    if (g_bLoaded) {
        SetupItemsGame();
        decl String:strIndex[128];
        new iIndex2;
        
        decl String:strName2[128];
        strcopy(strName2, sizeof(strName2), strName);
        ConvertAlias(strName2, sizeof(strName2));
        
        KvGotoFirstSubKey(g_hItems, false);
        do {
            KvGetSectionName(g_hItems, strIndex, sizeof(strIndex));
            iIndex2 = StringToInt(strIndex);
            
            if (iIndex == iIndex2) {
                KvGetString(g_hItems, strName2, strReturn, iMaxSize);
                return true;
            }
            
            
        } while (KvGotoNextKey(g_hItems, false));
    }
    
    Format(strReturn, iMaxSize, "");
    return false;
}

public Native_ItemsGameInfo(Handle:hPlugin, iNumParams) {
    new iIndex = GetNativeCell(1);
    
    decl String:strName[128];
    GetNativeString(2, strName, sizeof(strName));
    
    new iMaxSize = GetNativeCell(4);
    decl String:strReturn[iMaxSize];
    
    new bool:bResult = ItemsGameInfo(iIndex, strName, strReturn, iMaxSize);
    SetNativeString(3, strReturn, iMaxSize);
    return _:bResult;
}

stock SetupItemsGame(String:strSection[] = "items") {
    if (!g_bLoaded) return;
    KvRewind(g_hItems);
    KvJumpToKey(g_hItems, NAME_ROOT);
    KvJumpToKey(g_hItems, strSection);
}

stock bool:ParseSearch(String:strSearch[], Handle:hSearchName, Handle:hSearchValue) {
    decl String:strSplit[10][256];
    decl String:strSplit2[2][128];
    
    new iCount;
    new iCount2;
    
    iCount = ExplodeString(strSearch, ",", strSplit, sizeof(strSplit), sizeof(strSplit[]));
    if (iCount > 10) {
        LogError("Cannot use more than 10 search values. String: '%s'", strSearch);
        return false;
    }
    
    for (new i = 0; i < iCount; i++) {
        // remove unintended spaces
        ReplaceString(strSplit[i], 256, " ", "");
        
        iCount2 = ExplodeString(strSplit[i], "=>", strSplit2, sizeof(strSplit2), sizeof(strSplit2[]));
        if (iCount2 != 2) {
            LogError("Search parameter %d unreadable. String: '%s'", i+1, strSplit[i]);
            return false;
        }
        
        // remove unintended spaces
        ReplaceString(strSplit2[0], 128, " ", "");
        ReplaceString(strSplit2[1], 128, " ", "");
        
        // alias name
        ConvertAlias(strSplit2[0], 128);
        
        PushArrayString(hSearchName, strSplit2[0]);
        PushArrayString(hSearchValue, strSplit2[1]);
        //LogMessage("'%s' => '%s'", strSplit2[0], strSplit2[1]);
    }
    
    return true;
}

stock bool:ArrayContainsString(Handle:hArray, String:strInput[]) {
    decl String:strValue[128];
    for (new i = 0; i < GetArraySize(hArray); i++) {
        GetArrayString(hArray, i, strValue, sizeof(strValue));
        if (StrEqual(strValue, strInput)) return true;
    }
    return false;
}

stock ConvertAlias(String:strInput[], iMaxSize) {
    if (StrEqual(strInput, "classname", false)) Format(strInput, iMaxSize, "item_class");
    if (StrEqual(strInput, "slot", false)) Format(strInput, iMaxSize, "item_slot");
    if (StrEqual(strInput, "quality", false)) Format(strInput, iMaxSize, "item_quality");
}

/*
stock bool:ArrayContainsValue(Handle:hArray, iValue) {
    for (new i = 0; i < GetArraySize(hArray); i++) {
        if (GetArrayCell(hArray, i) == iValue) return true;
    }
    return false;
}
*/


#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
    public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
    public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
    //LibraryExists("mw_achievements");
    RegPluginLibrary("itemsgame");

    CreateNative("ItemsGameSearch", Native_ItemsGameSearch);
    CreateNative("ItemsGameInfo", Native_ItemsGameInfo);
    //CreateNative("ItemsGameEntityInfo", Native_ItemsGameEntityInfo);

    #if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
        return APLRes_Success;
    #else
        return true;
    #endif
}