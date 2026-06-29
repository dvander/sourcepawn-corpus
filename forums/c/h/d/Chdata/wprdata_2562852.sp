/*
    Weapon Pick Rate Database
    1/26/2017
    By: Chdata

    Format for the database is as follows:

    COL: id, slot, name, picks/class

    `id`          is the ItemDefinitionIndex of a weapon
    `slot`        is the weapon slot of the weapon
    `p1`          is the number of times it was chosen for Scout
    `p2`          is the number of times it was chosen for Sniper
    `p3`          is the number of times it was chosen for Soldier
    `p4`          is the number of times it was chosen for Demoman
    `p5`          is the number of times it was chosen for Medic
    `p6`          is the number of times it was chosen for Heavy
    `p7`          is the number of times it was chosen for Pyro
    `p8`          is the number of times it was chosen for Spy
    `p9`          is the number of times it was chosen for Engineer

    if (`id` == -1) then `p` is the number of times that `class` was chosen.

    Stats are only updated when a player dies or the round ends (in which case you chose the weapon, but didn't necessarily die), because that says the player intentionally chose to play with the loadout they have equipped.
    As opposed to choosing what they spawn with, where a player can be immediately switching weapons.

    The idea to do it this way came from Youtube, which tries to discern a person intentionally watching a video, versus just quickly opening a window to try and register a view.

    Stats are also updated when the round ends, during which saving stats based on death is disabled.

    Format for the trie is as follows:

    "id"    "slot"   // Weapon slot that weapon is equipped in.
    "id_1"  "p1"     // Number of times the weapon was picked for that class.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <saxtonhale>
#define REQUIRE_PLUGIN

/*
    When DEBUG is defined, the plugin will compile without the SQL Database setup and merely print out debug messages in their place.
*/
//#define DEBUG

#define PLUGIN_VERSION          "0x01"

public Plugin:myinfo = {
    name = "[TF2] Weapon Pick Rate Database",
    author = "Chdata",
    description = "Stores statistics for how often weapons are picked in TF2.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

#if !defined DEBUG
static Handle:g_hDb = INVALID_HANDLE;
#endif

static Handle:g_hSDKGetEquippedWearable = INVALID_HANDLE;

static Handle:g_hCacheTrie = INVALID_HANDLE;

static Handle:g_cvErrorLogging = INVALID_HANDLE;
static Handle:g_cvTableName = INVALID_HANDLE;

static bool:g_bErrorLogging;
static String:g_szTableName[32];

static bool:g_bIsVSHRunning;
static bool:g_bContinueTrackingDeaths; // When false, this plugin will no longer store anything to the database when a player dies.
static bool:g_bDisableInternalTracking; // When true, this plugin will no longer store anything to the database at all.
static bool:g_bDisableTracking[MAXPLAYERS + 1]; // Same as above, but for a single player only.

public APLRes:AskPluginLoad2(Handle:hSelf, bool:bLate, String:szError[], iErrMax)
{
#if !defined DEBUG
    if (SQL_CheckConfig("wprdata")) // This checks databases.cfg for a section titled "wprdata"
    {
        g_hDb = SQL_Connect("wprdata", true, szError, iErrMax); // One of the parts required to start a database connection.
    }
    else
    {
        g_hDb = SQL_Connect("default", true, szError, iErrMax); // If database.cfg wasn't edited to add wprdata, we use the default database
    }
    
    if (g_hDb == INVALID_HANDLE)
    {
        return APLRes_Failure;
    }
#endif

    CreateNative("WPR_GetClassPicks", Native_GetClassPicks);
    CreateNative("WPR_GetWeaponPicks", Native_GetWeaponPicks);
    CreateNative("WPR_SetAutoTracking", Native_SetAutoTracking);
    CreateNative("WPR_IncrementWeaponPicks", Native_IncrementWeaponPicks);

    RegPluginLibrary("wprdata");
    
    return APLRes_Success;
}

public OnAllPluginsLoaded()
{
    g_bIsVSHRunning = LibraryExists("saxtonhale");
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "saxtonhale"))
    {
        g_bIsVSHRunning = true;
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "saxtonhale"))
    {
        g_bIsVSHRunning = false;
    }
}

public OnPluginStart()
{
    CreateConVar(
        "cv_wprdata_version", PLUGIN_VERSION,
        "Weapon Pick Rate Data Version",
        FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT
    );

    g_cvErrorLogging = CreateConVar(
        "cv_wprdata_errorlog", "0",
        "1 = log SQL errors | 0 = don't log SQL errors",
        FCVAR_NOTIFY
    );

    g_cvTableName = CreateConVar(
        "cv_wprdata_tablename", "wprdata",
        "Name of the table to use for this server",
        FCVAR_NOTIFY
    );

    HookConVarChange(g_cvTableName, ConVar_OnChange);
    HookConVarChange(g_cvErrorLogging, ConVar_OnChange);

    AutoExecConfig(true, "ch.wpr");

    g_hCacheTrie = CreateTrie();

    SDK_RegisterWeaponData();

    /*
        Even though it defaults to _Post, I include that because I always forget and this makes it easier to change if I wanna edit it.

        Of course, any plugin calling TF2_RegeneratePlayer(iClient) will also cause TF2 to send more post_inventory_application events, thus spoofing the results a little.
        For example, Versus Saxton Hale (with its old decrepit code) calls this multiple times on players while replacing their weapons.

        player_spawn is also often called twice in arena game modes, once before the teamplay_round_start event and once after.
        player_spawn is also of course, called every time a player is respawned for any reason.
    */
    //HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    //HookEvent("post_inventory_application", Event_PostInventoryApplication, EventHookMode_Post);

    HookEvent("teamplay_setup_finished", Event_TeamplaySetupFinished, EventHookMode_Post);
    HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_Post);
    HookEvent("teamplay_round_win", Event_TeamplayRoundWin, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public ConVar_OnChange(Handle:hCvar, const String:szOldValue[], const String:szNewValue[])
{
    if (hCvar == g_cvErrorLogging)
    {
        g_bErrorLogging = GetConVarBool(g_cvErrorLogging);
    }
    else if (hCvar == g_cvTableName)
    {
        SQL_InitializeTable();
        SQL_LoadAllToCache();
    }
}

public OnConfigsExecuted()
{
    g_bErrorLogging = GetConVarBool(g_cvErrorLogging);
    SQL_InitializeTable();
    SQL_LoadAllToCache(); // Must be called AFTER SQL_InitializeTable()
}

public OnMapStart() // Handles late loads.
{
    g_bContinueTrackingDeaths = true;
    g_bDisableInternalTracking = false;
}

public Event_TeamplaySetupFinished(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
#if defined DEBUG
    PrintToChatAll("Event Fired: %s %i", szName, GameRules_GetRoundState());
#endif

    g_bContinueTrackingDeaths = true;
}

public Event_ArenaRoundStart(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
#if defined DEBUG
    PrintToChatAll("Event Fired: %s %i", szName, GameRules_GetRoundState());
#endif

    g_bContinueTrackingDeaths = true;
}

public Event_TeamplayRoundWin(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
#if defined DEBUG
    PrintToChatAll("Event Fired: %s %i", szName, GameRules_GetRoundState());
#endif

    g_bContinueTrackingDeaths = false;

    if (g_bDisableInternalTracking)
    {
        return;
    }

    for (new iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && !g_bDisableTracking[iClient])
        {
            new iUserId = GetClientUserId(iClient);

            if (g_bIsVSHRunning && iUserId == VSH_GetSaxtonHaleUserId()) // Ignore Versus Saxton Hale bosses.
            {
                continue;
            }

            if (IsFakeClient(iClient))
            {
                continue;
            }

            new TFClassType:iClass = TF2_GetPlayerClass(iClient);
            SQL_SaveToDatabase(-1, iClass);

            for (new i = 0; i < 8; i++)
            {
                new iWeapon = GetPlayerWeaponSlot(iClient, i);
                if (iWeapon == -1)
                {
                    iWeapon = SDK_GetEquippedWearable(iClient, i);
                }

                if (iWeapon > MaxClients && IsValidEntity(iWeapon))
                {
                    new iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

                    if (iIndex > -1)
                    {
                        SQL_SaveToDatabase(iIndex, iClass, i);
                    }
                }
            }
        }
    }
}

public Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
#if defined DEBUG
    PrintToChatAll("RoundState: %i", GameRules_GetRoundState()); // Turns out the value of RoundState is unreliable, in arena for example.
#endif

    if (g_bDisableInternalTracking)
    {
        return;
    }

    if (!g_bContinueTrackingDeaths)
    {
        return;
    }

    // This is just something I commonly use (and see some other people use) when creating fake copies of this event, which do get detected by this callback.
    if (GetEventBool(hEvent, "sourcemod"))
    {
        return;
    }

    new iUserId = GetEventInt(hEvent, "userid");

    if (g_bIsVSHRunning && iUserId == VSH_GetSaxtonHaleUserId()) // Ignore Versus Saxton Hale bosses.
    {
        return;
    }

    new iVictim = GetClientOfUserId(iUserId);

    if (!iVictim || !IsClientInGame(iVictim) || g_bDisableTracking[iVictim]) // Should be impossible for this to happen but who knows.
    {
        return;
    }

    if (IsFakeClient(iVictim))
    {
        return;
    }

    new iDeathFlags = GetEventInt(hEvent, "death_flags");

    if (!(iDeathFlags & TF_DEATHFLAG_DEADRINGER)) // Ignore Spy feigned deaths.
    {
        new TFClassType:iClass = TF2_GetPlayerClass(iVictim);
        SQL_SaveToDatabase(-1, iClass);

        for (new i = 0; i < 8; i++)
        {
            new iWeapon = GetPlayerWeaponSlot(iVictim, i);
            if (iWeapon == -1)
            {
                iWeapon = SDK_GetEquippedWearable(iVictim, i);
            }

            if (iWeapon > MaxClients && IsValidEntity(iWeapon))
            {
                new iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

                if (iIndex > -1)
                {
                    SQL_SaveToDatabase(iIndex, iClass, i);
                }
            }
        }
    }
}

SQL_InitializeTable() // OnConfigsExecuted() (First)
{
    GetConVarString(g_cvTableName, g_szTableName, sizeof(g_szTableName));

    decl String:szQuery[512];
    Format(szQuery, sizeof(szQuery),
        "CREATE TABLE IF NOT EXISTS `%s` (id int(11) NOT NULL, " ...
        "slot int(11) NOT NULL, " ...
        "p1 int(11) NOT NULL, " ...
        "p2 int(11) NOT NULL, " ...
        "p3 int(11) NOT NULL, " ...
        "p4 int(11) NOT NULL, " ...
        "p5 int(11) NOT NULL, " ...
        "p6 int(11) NOT NULL, " ...
        "p7 int(11) NOT NULL, " ...
        "p8 int(11) NOT NULL, " ...
        "p9 int(11) NOT NULL, " ...
        "PRIMARY KEY (id)) ENGINE=InnoDB  DEFAULT CHARSET=utf8",
        g_szTableName
    );

#if !defined DEBUG
    SQL_TQuery(g_hDb, SQLErrorCheckCallback, szQuery);
#else
    PrintToChatAll(szQuery);
    PrintToServer(szQuery);
#endif
}

SQL_LoadAllToCache() // OnConfigsExecuted() (Second)
{
    if (g_szTableName[0] == '\0')
    {
        LogError("You need to set a table name in cv_wprdata_tablename for this plugin to work.");
        return;
    }

    decl String:szQuery[512];
    Format(szQuery, sizeof(szQuery), "SELECT * FROM `%s`", g_szTableName); // Read everything from the table.

#if !defined DEBUG
    SQL_TQuery(g_hDb, SQL_OnAllDataLoaded, szQuery);
#else
    PrintToChatAll(szQuery);
    PrintToServer(szQuery);
#endif
}

#if !defined DEBUG
public SQL_OnAllDataLoaded(Handle:hOwner, Handle:hHndl, const String:szError[], any:Null)
{
    if (hHndl == INVALID_HANDLE)
    {
        SQL_LogError("WPRData Read Error: %s", szError);
    }
    else 
    {
        decl String:szKey[32];
        while (SQL_FetchRow(hHndl))
        {
            new iIndex = SQL_FetchInt(hHndl, 0);
            new iSlot = SQL_FetchInt(hHndl, 1);

            IntToString(iIndex, szKey, sizeof(szKey));
            SetTrieValue(g_hCacheTrie, szKey, iSlot);

            for (new i = 1; i < 10; i++) // Iterate through the 9 TF2 classes.
            {
                Format(szKey, sizeof(szKey), "%i_%i", iIndex, i);
                SetTrieValue(g_hCacheTrie, szKey, SQL_FetchInt(hHndl, i+1)); // This pretty much outputs our whole row into these tries
            }
        }
    }
}
#endif

stock SQL_SaveToDatabase(iItemDefinitionIndex, TFClassType:iClass, iSlot = -1)
{
#if !defined DEBUG
    if (g_hDb == INVALID_HANDLE)
    {
        SQL_LogError("Unable to create table: Failed to create database handle");
        return;
    }
#else
    PrintToChatAll("Weapon %i", iItemDefinitionIndex);
#endif

    if (g_szTableName[0] == '\0')
    {
        LogError("You need to set a table name in cv_wprdata_tablename for this plugin to work.");
        return;
    }

    if (iClass == TFClass_Unknown) // We shouldn't be storing data when their class isn't even set yet.
    {
        return;
    }

    if (iItemDefinitionIndex == -1)
    {
        iSlot = -1;
    }

    decl String:szQuery[256];
    Format(szQuery, sizeof(szQuery), "SELECT `p%i`, `slot` FROM `%s` WHERE `id` = %i",
        iClass,
        g_szTableName,
        iItemDefinitionIndex
    );

#if !defined DEBUG
    new Handle:hData = CreateDataPack();
    WritePackCell(hData, iItemDefinitionIndex);
    WritePackCell(hData, iClass);
    WritePackCell(hData, iSlot);
    SQL_TQuery(g_hDb, SQL_CheckIdAndSaveWeaponData, szQuery, hData);
#else
    PrintToChatAll("%s", szQuery);
#endif
}

#if !defined DEBUG
public SQL_CheckIdAndSaveWeaponData(Handle:hOwner, Handle:hHndl, const String:szError[], any:Pack)
{
    new Handle:hData = Handle:Pack;
    ResetPack(hData);
    new iItemDefinitionIndex = ReadPackCell(hData);
    new TFClassType:iClass = TFClassType:ReadPackCell(hData);
    new iSlot = ReadPackCell(hData);
    CloseHandle(hData);

    if (hHndl == INVALID_HANDLE)
    {
        SQL_LogError("Failed to check weapon id %i %i %i: %s", iItemDefinitionIndex, iClass, iSlot, szError);
    }
    else 
    {
        if (g_szTableName[0] == '\0')
        {
            LogError("You need to set a table name in cv_wprdata_tablename for this plugin to work.");
            return;
        }

        decl String:szQuery[256];
        if (!SQL_GetRowCount(hHndl)) // This will happen if there is no row for that id yet
        {
            new iSlotBits = 0;
            if (iSlot > -1)
            {
                iSlotBits |= (1<<iSlot);
            }
            else
            {
                iSlotBits = -1;
            }

            Format(szQuery, sizeof(szQuery), "INSERT INTO `%s` SET `id` = %i, `slot` = %i, `p%i` = 1",
                g_szTableName,
                iItemDefinitionIndex,
                iSlotBits,
                iClass
            );                              // We always know it's our first weapon pick if the weapon isn't in the database yet
        }
        else
        {
            new iPicks = -1;
            new iSlotBits = 0;
            while (SQL_FetchRow(hHndl)) // It should never be able to fail at this point, picks should never be able to be -1 after this point. They should be either 0 or 1 by now.
            {
                iPicks = SQL_FetchInt(hHndl, 0) + 1;
                iSlotBits = SQL_FetchInt(hHndl, 1);
            }

            if (iPicks < 1)
            {
                szQuery[0] = '\0';
                SQL_LogError("Failed to update pick count %i %i %i: %i", iItemDefinitionIndex, iClass, iSlot, iPicks);
            }
            else
            {
                if (iSlot > -1)
                {
                    iSlotBits |= (1<<iSlot);
                }
                else
                {
                    iSlotBits = -1;
                }

                Cache_SetNumPicks(iItemDefinitionIndex, iClass, iSlotBits, iPicks);

                Format(szQuery, sizeof(szQuery), "UPDATE `%s` SET `p%i` = %i, `slot` = %i WHERE `id` = %i",
                    g_szTableName,
                    iClass,
                    iPicks,
                    iSlotBits,
                    iItemDefinitionIndex
                );
            }
        }

        if (szQuery[0] != '\0')
        {
            hData = CreateDataPack();
            WritePackCell(hData, iItemDefinitionIndex);
            WritePackCell(hData, iClass);
            WritePackCell(hData, iSlot);
            //WritePackCell(hData, iPicks);
            SQL_TQuery(g_hDb, SQLErrorCheckCallback, szQuery, hData);
        }
    }   
}
#endif

#if !defined DEBUG
public SQLErrorCheckCallback(Handle:hOwner, Handle:hHndl, const String:szError[], any:Null)
{
    if (hHndl == INVALID_HANDLE)
    {
        SQL_LogError("WPRData Error: %s", szError);
    }
}
#endif

#if !defined DEBUG
Cache_SetNumPicks(iItemDefinitionIndex, TFClassType:iClass, iSlotBits, iPicks)
{
    if (iClass == TFClass_Unknown) // We shouldn't be storing data when their class isn't even set yet.
    {
        return;
    }

    decl String:szKey[32];
    IntToString(iItemDefinitionIndex, szKey, sizeof(szKey));

//     decl iCachedSlot;
//     Cache_GetNumPicks(iItemDefinitionIndex, iClass, iCachedSlot);
// 
//     if (iCachedSlot != iSlot && iCachedSlot != -1)  // Strange shotgun can do this between Engie/Soldier/Pyro/Heavy
//     {
//         //LogError("WPRData: Somehow, the weapon slot for item %i changed from %i to %i???", iItemDefinitionIndex, iCachedSlot, iSlot);
//     }

    SetTrieValue(g_hCacheTrie, szKey, iSlotBits, false);

    Format(szKey, sizeof(szKey), "%i_%i", iItemDefinitionIndex, iClass);
    SetTrieValue(g_hCacheTrie, szKey, iPicks);
}
#endif

Cache_GetNumPicks(iItemDefinitionIndex, TFClassType:iClass = TFClass_Unknown, &iSlotBits = 0)
{
    if (iItemDefinitionIndex == -1 && iClass == TFClass_Unknown)
    {
        LogError("WPRData: You cannot search class pick rates and pass an unknown class at the same time.");
        return -1; // Error
    }

    decl String:szKey[32];
    IntToString(iItemDefinitionIndex, szKey, sizeof(szKey));
    if (!GetTrieValue(g_hCacheTrie, szKey, iSlotBits))                               // Gets the weapon slot, if applicable       
    {
        iSlotBits = 0;
    }

    new iValue = 0;
    if (iItemDefinitionIndex == -1)                                             // Gets the Class Pick Rate.
    {
        Format(szKey, sizeof(szKey), "%i_%i", iItemDefinitionIndex, iClass);
        if (GetTrieValue(g_hCacheTrie, szKey, iValue))
        {
            return iValue;
        }
        else
        {
            return 0;
        }
    }
    else                                                                        // Gets a Weapon Pick Rate.
    {
        new iTemp = 0;
        for (new i = 1; i < 10; i++)
        {
            if (iClass == TFClass_Unknown || TFClassType:i == iClass)
            {
                Format(szKey, sizeof(szKey), "%i_%i", iItemDefinitionIndex, iClass);

                if (GetTrieValue(g_hCacheTrie, szKey, iTemp))
                {
                    iValue += iTemp;
                }
            }
        }
    }

    return iValue;
}

/*
    WPR_GetClassPicks(TFClassType:iClass)
*/
public Native_GetClassPicks(Handle:plugin, numParams)
{
    new TFClassType:iClass = TFClassType:GetNativeCell(1);

    return Cache_GetNumPicks(-1, iClass);
}

/*
    WPR_GetWeaponPicks(iItemDefinitionIndex, TFClassType:iClass = TFClass_Unknown, &iSlot = 0)
*/
public Native_GetWeaponPicks(Handle:plugin, numParams)
{
    new iIndex = GetNativeCell(1);
    new TFClassType:iClass = TFClassType:GetNativeCell(2);

    decl iSlot;
    new iPicks = Cache_GetNumPicks(iIndex, iClass, iSlot);
    
    SetNativeCellRef(3, iSlot);

    return iPicks;
}

/*
    WPR_SetAutoTracking(iClient, bool:bOn)
*/
public Native_SetAutoTracking(Handle:plugin, numParams)
{
    new bool:bOn = !GetNativeCell(2);
    new iClient = GetNativeCell(1);

    if (!iClient)
    {
        g_bDisableInternalTracking = bOn;
    }
    else
    {
        g_bDisableTracking[iClient] = bOn;
    }
}

/*
    WPR_IncrementWeaponPicks(iItemDefinitionIndex, TFClassType:iClass, iSlot)
*/
public Native_IncrementWeaponPicks(Handle:plugin, numParams)
{
    new iIndex = GetNativeCell(1);
    new TFClassType:iClass = TFClassType:GetNativeCell(2);
    new iSlot = GetNativeCell(3);

    SQL_SaveToDatabase(iIndex, iClass, iSlot);
}

stock SQL_LogError(const String:szFormat[], any:...)
{
    if (!g_bErrorLogging)
    {
        return;
    }

    decl String:szBuffer[256]; // Magic number
    VFormat(szBuffer, sizeof(szBuffer), szFormat, 2);
    LogError(szBuffer);
}

stock SDK_RegisterWeaponData()
{
    new Handle:hGameData = LoadGameConfigFile("weapon.data");
    if (hGameData == INVALID_HANDLE)
    {
        SetFailState("Unable to load required gamedata (weapon.data.txt)");
    }
    
    //---------------------

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);

    g_hSDKGetEquippedWearable = EndPrepSDKCall();
    if (g_hSDKGetEquippedWearable == INVALID_HANDLE)
    {
        SetFailState("Couldn't load SDK function (CTFPlayer::GetEquippedWearableForLoadoutSlot). SDK call failed");
    }

    //---------------------

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);

    g_hSDKGetEquippedWearable = EndPrepSDKCall();
    if (g_hSDKGetEquippedWearable == INVALID_HANDLE)
    {
        SetFailState("Couldn't load SDK function (CTFPlayer::GetEquippedWearableForLoadoutSlot). SDK call failed");
    }
}

stock SDK_GetEquippedWearable(iClient, iSlot)
{
    if (g_hSDKGetEquippedWearable == INVALID_HANDLE)
    {
        LogError("SDKCall for GetEquippedWearable is invalid!");
        return -1;
    }
    
    return SDKCall(g_hSDKGetEquippedWearable, iClient, iSlot);
}

#endinput

// This works for strings too, just I haven't found a syntax highlighter that highlights this properly:
"CREATE TABLE IF NOT EXISTS `wprdata` (id int(11) NOT NULL, \
slot int(11) NOT NULL, \
p1 int(11) NOT NULL, \
p2 int(11) NOT NULL, \
p3 int(11) NOT NULL, \
p4 int(11) NOT NULL, \
p5 int(11) NOT NULL, \
p6 int(11) NOT NULL, \
p7 int(11) NOT NULL, \
p8 int(11) NOT NULL, \
p9 int(11) NOT NULL, \
PRIMARY KEY (id)) ENGINE=InnoDB  DEFAULT CHARSET=utf8"

        "CREATE TABLE IF NOT EXISTS `wprdata` (id int(11) NOT NULL, " ...
        "slot int(11) NOT NULL, " ...
        "p1 int(11) NOT NULL, " ...
        "p2 int(11) NOT NULL, " ...
        "p3 int(11) NOT NULL, " ...
        "p4 int(11) NOT NULL, " ...
        "p5 int(11) NOT NULL, " ...
        "p6 int(11) NOT NULL, " ...
        "p7 int(11) NOT NULL, " ...
        "p8 int(11) NOT NULL, " ...
        "p9 int(11) NOT NULL, " ...
        "PRIMARY KEY (id)) ENGINE=InnoDB  DEFAULT CHARSET=utf8"

        "name varchar(64), " ...