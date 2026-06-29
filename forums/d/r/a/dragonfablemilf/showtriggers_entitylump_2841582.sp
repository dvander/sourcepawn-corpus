#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_tempents>
#include <clientprefs>
#include <entitylump>
#include <dbi>
#include <datapack>

#define PLUGIN_NAME "showtriggers_entitylump"
#define PLUGIN_AUTHOR "feedbacker"
#define PLUGIN_DESCRIPTION "showtriggers with entitylump"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://midnightmass.fun"

#define EF_NODRAW 32
#define MAX_INDIVIDUAL_TRIGGERS 2048

// trigger type indices
enum
{
    TRIGGER_MULTIPLE = 0,
    TRIGGER_PUSH,
    TRIGGER_TELEPORT,
    TRIGGER_TELEPORT_RELATIVE,
    MAX_TYPES
};

// special trigger_multiple subtypes (cached at map load)
enum TriggerMultipleType
{
    TM_NORMAL = 0,
    TM_GRAVITY,
    TM_ANTIGRAVITY,
    TM_BASEVELOCITY,
    TM_MAX
};

// menu action constants
#define MENU_ENABLE_ALL  -2
#define MENU_DISABLE_ALL -1

// display modes.. todo: beam stuff is unfinished
enum TriggerDisplayMode
{
    DISPLAY_SOLID = 0,
    DISPLAY_OUTLINE,
    DISPLAY_BOTH
};

#define BEAM_MODEL "materials/sprites/laserbeam.vmt"
#define BEAM_HALO "materials/sprites/halo01.vmt"
#define BEAM_INTERVAL 0.2
#define BEAM_WIDTH 2.0
#define BEAM_END_WIDTH 2.0
#define BEAM_LIFE 0.2
#define BEAM_AMPLITUDE 0.0
#define BEAM_FADE 0
#define BEAM_SPEED 0
#define OUTLINE_MAX_DIST 2500.0
#define PROFILE_INDIV_MAX 8192
#define TYPE_MASK_UNSET -1

static const char g_szTriggerNames[][] =
{
    "trigger_multiple",
    "trigger_push",
    "trigger_teleport",
    "trigger_teleport_relative"
};

static const char g_szSpecialNames[][] =
{
    "normal",
    "gravity",
    "anti-gravity",
    "base velocity"
};

static const char g_szOutputKeys[][] =
{
    "OnStartTouch",
    "OnStartTouchAll",
    "OnEndTouch",
    "OnEndTouchAll",
    "OnTouching",
    "OnTrigger",
    "OnUser1",
    "OnUser2",
    "OnUser3",
    "OnUser4"
};

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

// per-client trigger type visibility
bool g_bTypeEnabled[MAXPLAYERS + 1][MAX_TYPES];

// per-client individual trigger data (entity ref, enabled, custom color)
enum struct IndividualTrigger
{
    int entRef;
    int color[4];  // rgba, -1 means use default
}

enum struct OutputInfo
{
    char output[32];
    char target[64];
    char input[64];
    char param[96];
    float delay;
    int once;
}

ArrayList g_alClientTriggers[MAXPLAYERS + 1];  // arraylist of individualtrigger

// cached trigger_multiple subtypes (indexed by entity index)
TriggerMultipleType g_eTriggerMultipleType[2049];

// offset for m_feffects
int g_iOffsetMFEffects = -1;

// global hook state
bool g_bHooksActive;

// search state per client
ArrayList g_alSearchResults[MAXPLAYERS + 1];
int g_iSearchPage[MAXPLAYERS + 1];
char g_szLastSearch[MAXPLAYERS + 1][64];

// info menu state
int g_iLastInfoEntRef[MAXPLAYERS + 1];

// color settings per client (rgba now)
int g_iColors[MAXPLAYERS + 1][MAX_TYPES][4];
int g_iColorsSpecial[MAXPLAYERS + 1][TM_MAX][4];

// color cookies
Cookie g_hColorCookie[MAX_TYPES];
Cookie g_hColorCookieSpecial[TM_MAX];

// display mode cookie
Cookie g_hDisplayModeCookie;

// hammerid to trigger_multiple subtype mapping
StringMap g_smHammerIdToType;

// hammerid to outputs mapping
StringMap g_smHammerIdToOutputs;

// per-client display mode
TriggerDisplayMode g_eDisplayMode[MAXPLAYERS + 1];

// beam outline state
Handle g_hBeamTimer = null;
int g_iBeamSprite = -1;
int g_iBeamHalo = -1;

// sqlite profile storage
Database g_hDatabase = null;
bool g_bDatabaseReady = false;

// default colors (rgba) - designed for visibility and distinction
static const int g_iDefaultColors[MAX_TYPES][4] = {
    {255, 200,   0, 180},  // trigger_multiple - gold/yellow
    {128, 255,   0, 180},  // trigger_push - lime green
    {  0, 128, 255, 180},  // trigger_teleport - blue
    {180,   0, 255, 180}   // trigger_teleport_relative - purple
};

static const int g_iDefaultColorsSpecial[TM_MAX][4] = {
    {255, 200,   0, 180},  // normal - gold (same as trigger_multiple)
    {255, 100,   0, 180},  // gravity - orange
    {  0, 220, 255, 180},  // anti-gravity - cyan/light blue
    {255,   0, 180, 180}   // base velocity - magenta/pink
};

// ============================================================================
// plugin lifecycle
// ============================================================================

public void OnPluginStart()
{
    g_iOffsetMFEffects = FindSendPropInfo("CBaseEntity", "m_fEffects");
    if (g_iOffsetMFEffects == -1)
    {
        SetFailState("[showtriggers] could not find cbaseentity::m_feffects");
    }

    CreateConVar("sm_showtriggers_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION,
        FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);

    // main menu command
    RegConsoleCmd("sm_showtriggers", Command_MainMenu, "open show triggers menu");
    RegConsoleCmd("sm_st", Command_MainMenu, "open show triggers menu");

    // search command
    RegConsoleCmd("sm_stsearch", Command_Search, "search triggers: sm_stsearch [term] - leave empty for all");
    RegConsoleCmd("sm_searchtriggers", Command_Search, "search triggers: sm_searchtriggers [term]");

    // console commands for rgb/rgba
    RegConsoleCmd("sm_stcolor", Command_SetColor, "set trigger type color: sm_stcolor <type> <r> <g> <b> [a]");
    RegConsoleCmd("sm_stcolor_special", Command_SetSpecialColor, "set special type color: sm_stcolor_special <type> <r> <g> <b> [a]");
    RegConsoleCmd("sm_stcolor_ent", Command_SetEntityColor, "set individual trigger color: sm_stcolor_ent <index> <r> <g> <b> [a]");
    RegConsoleCmd("sm_stopacity", Command_SetOpacity, "set trigger opacity for all types: sm_stopacity <0-255>");
    RegConsoleCmd("sm_stmode", Command_SetDisplayMode, "set trigger display mode: sm_stmode <solid>");
    RegConsoleCmd("sm_stdisplay", Command_SetDisplayMode, "set trigger display mode: sm_stdisplay <solid>");
    RegConsoleCmd("sm_identifytrigger", Command_IdentifyTrigger, "identify trigger under crosshair and open settings");
    RegConsoleCmd("sm_stprofile_save", Command_ProfileSave, "save display profile: sm_stprofile_save <name> [public]");
    RegConsoleCmd("sm_stprofile_load", Command_ProfileLoad, "load display profile: sm_stprofile_load <name> [public] [map]");
    RegConsoleCmd("sm_stprofile_list", Command_ProfileList, "list display profiles: sm_stprofile_list [public] [map]");
    RegConsoleCmd("sm_stprofile_copy", Command_ProfileCopy, "copy profile from another map: sm_stprofile_copy <name> <frommap> [public] [newname]");
    RegConsoleCmd("sm_sthelp", Command_Help, "show all show triggers commands");

    // create color cookies
    for (int i = 0; i < MAX_TYPES; i++)
    {
        char szCookieName[48];
        FormatEx(szCookieName, sizeof(szCookieName), "st_color_%s", g_szTriggerNames[i]);
        g_hColorCookie[i] = new Cookie(szCookieName, "trigger color preference", CookieAccess_Protected);
    }

    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        char szCookieName[48];
        FormatEx(szCookieName, sizeof(szCookieName), "st_color_special_%d", i);
        g_hColorCookieSpecial[i] = new Cookie(szCookieName, "special trigger color", CookieAccess_Protected);
    }

    g_hDisplayModeCookie = new Cookie("st_display_mode", "trigger display mode preference", CookieAccess_Protected);

    InitDatabase();

    // late load support
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
        {
            OnClientPutInServer(client);
            if (AreClientCookiesCached(client))
            {
                OnClientCookiesCached(client);
            }
        }
    }
}

public void OnPluginEnd()
{
    UnhookAllTriggers();
    StopBeamTimer();

    delete g_smHammerIdToType;
    ClearHammerIdOutputs();

    if (g_hDatabase != null)
    {
        delete g_hDatabase;
        g_hDatabase = null;
        g_bDatabaseReady = false;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        delete g_alClientTriggers[client];
        delete g_alSearchResults[client];
    }
}

public void OnMapStart()
{
    g_bHooksActive = false;
    StopBeamTimer();

    g_iBeamSprite = PrecacheModel(BEAM_MODEL, true);
    g_iBeamHalo = PrecacheModel(BEAM_HALO, true);

    CacheTriggerMultipleTypes();
}

public void OnMapEnd()
{
    StopBeamTimer();
    g_iBeamSprite = -1;
    g_iBeamHalo = -1;

    for (int i = 0; i < sizeof(g_eTriggerMultipleType); i++)
    {
        g_eTriggerMultipleType[i] = TM_NORMAL;
    }

    delete g_smHammerIdToType;
    g_smHammerIdToType = null;

    ClearHammerIdOutputs();

    for (int client = 1; client <= MaxClients; client++)
    {
        for (int t = 0; t < MAX_TYPES; t++)
        {
            g_bTypeEnabled[client][t] = false;
        }
        if (g_alClientTriggers[client] != null)
        {
            g_alClientTriggers[client].Clear();
        }
        if (g_alSearchResults[client] != null)
        {
            g_alSearchResults[client].Clear();
        }
    }
}

public void OnClientPutInServer(int client)
{
    for (int i = 0; i < MAX_TYPES; i++)
    {
        g_bTypeEnabled[client][i] = false;
    }

    delete g_alClientTriggers[client];
    g_alClientTriggers[client] = new ArrayList(sizeof(IndividualTrigger));

    delete g_alSearchResults[client];
    g_alSearchResults[client] = new ArrayList();

    InitClientColors(client);
    g_eDisplayMode[client] = DISPLAY_SOLID;
    g_iSearchPage[client] = 0;
    g_szLastSearch[client][0] = '\0';
    g_iLastInfoEntRef[client] = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
    for (int i = 0; i < MAX_TYPES; i++)
    {
        g_bTypeEnabled[client][i] = false;
    }

    delete g_alClientTriggers[client];
    g_alClientTriggers[client] = null;

    delete g_alSearchResults[client];
    g_alSearchResults[client] = null;

    UpdateHookState();
}

public void OnClientCookiesCached(int client)
{
    LoadClientColors(client);
    LoadClientDisplayMode(client);
}

// ============================================================================
// database (sqlite profiles)
// ============================================================================

void InitDatabase()
{
    SQL_TConnect(OnDatabaseConnected, "triggerprefs");
}

public void OnDatabaseConnected(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null || error[0] != '\0')
    {
        char sqliteError[256];
        Database db = SQLite_UseDatabase("triggerprefs", sqliteError, sizeof(sqliteError));
        if (db == null)
        {
            LogError("[st] database connection failed: %s", error);
            LogError("[st] sqlite fallback failed: %s", sqliteError);
            g_bDatabaseReady = false;
            return;
        }
        g_hDatabase = db;
        g_bDatabaseReady = true;
        CreateProfileTables();
        return;
    }

    g_hDatabase = view_as<Database>(hndl);
    g_bDatabaseReady = true;

    CreateProfileTables();
}

void CreateProfileTables()
{
    if (g_hDatabase == null)
    {
        return;
    }

    char query[512];
    FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS st_profiles (id INTEGER PRIMARY KEY AUTOINCREMENT, steamid TEXT NOT NULL, map TEXT NOT NULL, name TEXT NOT NULL, public INTEGER NOT NULL DEFAULT 0, display_mode INTEGER NOT NULL, type_mask INTEGER NOT NULL DEFAULT -1, colors TEXT NOT NULL, colors_special TEXT NOT NULL, indiv_data TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL, UNIQUE(steamid, map, name));");
    SQL_FastQuery(g_hDatabase, query);

    // add new column if upgrading from older schema.
    SQL_FastQuery(g_hDatabase, "ALTER TABLE st_profiles ADD COLUMN indiv_data TEXT NOT NULL DEFAULT '';");
    SQL_FastQuery(g_hDatabase, "ALTER TABLE st_profiles ADD COLUMN type_mask INTEGER NOT NULL DEFAULT -1;");
}

// ============================================================================
// entitylump parsing
// ============================================================================

void CacheTriggerMultipleTypes()
{
    for (int i = 0; i < sizeof(g_eTriggerMultipleType); i++)
    {
        g_eTriggerMultipleType[i] = TM_NORMAL;
    }

    ClearHammerIdOutputs();

    int iLumpLength = EntityLump.Length();

    for (int i = 0; i < iLumpLength; i++)
    {
        EntityLumpEntry entry = EntityLump.Get(i);
        if (entry == null)
        {
            continue;
        }

        char szClassname[64];
        if (entry.GetNextKey("classname", szClassname, sizeof(szClassname)) == -1)
        {
            delete entry;
            continue;
        }

        int iTriggerType = GetTriggerType(szClassname);
        if (iTriggerType == -1)
        {
            delete entry;
            continue;
        }

        char szHammerId[16];
        if (entry.GetNextKey("hammerid", szHammerId, sizeof(szHammerId)) == -1)
        {
            delete entry;
            continue;
        }

        int iHammerId = StringToInt(szHammerId);
        if (iHammerId <= 0)
        {
            delete entry;
            continue;
        }

        TriggerMultipleType eType = TM_NORMAL;
        if (iTriggerType == TRIGGER_MULTIPLE)
        {
            char szOutput[256];
            int pos = -1;

            while ((pos = entry.GetNextKey("OnStartTouch", szOutput, sizeof(szOutput), pos)) != -1)
            {
                if (StrContains(szOutput, "gravity 40", false) != -1 ||
                    StrContains(szOutput, "gravity 0.4", false) != -1)
                {
                    eType = TM_GRAVITY;
                    break;
                }
            }

            if (eType == TM_NORMAL)
            {
                pos = -1;
                while ((pos = entry.GetNextKey("OnEndTouch", szOutput, sizeof(szOutput), pos)) != -1)
                {
                    if (StrContains(szOutput, "gravity -", false) != -1)
                    {
                        eType = TM_ANTIGRAVITY;
                        break;
                    }
                    if (StrContains(szOutput, "basevelocity", false) != -1)
                    {
                        eType = TM_BASEVELOCITY;
                        break;
                    }
                }
            }

            if (eType != TM_NORMAL)
            {
                StoreHammerIdType(iHammerId, eType);
            }
        }

        ArrayList outputs = CollectOutputsFromEntry(entry);
        if (outputs != null)
        {
            StoreHammerIdOutputs(iHammerId, outputs);
        }

        delete entry;
    }
}

void StoreHammerIdType(int iHammerId, TriggerMultipleType eType)
{
    if (g_smHammerIdToType == null)
    {
        g_smHammerIdToType = new StringMap();
    }

    char szKey[16];
    IntToString(iHammerId, szKey, sizeof(szKey));
    g_smHammerIdToType.SetValue(szKey, eType);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!StrEqual(classname, "trigger_multiple"))
    {
        return;
    }

    if (g_smHammerIdToType == null)
    {
        return;
    }

    RequestFrame(Frame_ResolveTriggerType, EntIndexToEntRef(entity));
}

void Frame_ResolveTriggerType(int iEntRef)
{
    int entity = EntRefToEntIndex(iEntRef);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
    {
        return;
    }

    int iHammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
    if (iHammerId <= 0)
    {
        return;
    }

    char szKey[16];
    IntToString(iHammerId, szKey, sizeof(szKey));

    TriggerMultipleType eType;
    if (g_smHammerIdToType != null && g_smHammerIdToType.GetValue(szKey, eType))
    {
        g_eTriggerMultipleType[entity] = eType;
    }
}

// ============================================================================
// console commands
// ============================================================================

Action Command_Help(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    PrintToChat(client, " ");
    PrintToChat(client, "[st] === show triggers commands ===");
    PrintToChat(client, "[st] !st - open main menu");
    PrintToChat(client, "[st] !stsearch [term] - search triggers (empty = all)");
    PrintToChat(client, "[st] sm_stcolor <0-3> <r> <g> <b> [a] - set type color");
    PrintToChat(client, "[st]   types: 0=multiple, 1=push, 2=teleport, 3=teleport_rel");
    PrintToChat(client, "[st] sm_stcolor_special <0-3> <r> <g> <b> [a] - special color");
    PrintToChat(client, "[st]   types: 0=normal, 1=gravity, 2=antigrav, 3=basevel");
    PrintToChat(client, "[st] sm_stcolor_ent <index> <r> <g> <b> [a] - entity color");
    PrintToChat(client, "[st] sm_stopacity <0-255> - set opacity for all trigger types");
    PrintToChat(client, "[st] sm_stmode solid - display style (outline disabled)");
    PrintToChat(client, "[st] sm_identifytrigger - open settings for trigger under crosshair");
    PrintToChat(client, "[st] sm_stprofile_save <name> [public] - save profile");
    PrintToChat(client, "[st] sm_stprofile_load <name> [public] [map] - load profile");
    PrintToChat(client, "[st] sm_stprofile_list [public] [map] - list profiles");
    PrintToChat(client, "[st] sm_stprofile_copy <name> <frommap> [public] [newname] - copy profile to current map");

    return Plugin_Handled;
}

Action Command_SetColor(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args < 4)
    {
        ReplyToCommand(client, "[st] usage: sm_stcolor <type 0-3> <r> <g> <b> [a]");
        ReplyToCommand(client, "[st] types: 0=multiple, 1=push, 2=teleport, 3=teleport_relative");
        return Plugin_Handled;
    }

    char szArg[16];
    GetCmdArg(1, szArg, sizeof(szArg));
    int iType = StringToInt(szArg);

    if (iType < 0 || iType >= MAX_TYPES)
    {
        ReplyToCommand(client, "[st] invalid type. use 0-3.");
        return Plugin_Handled;
    }

    GetCmdArg(2, szArg, sizeof(szArg));
    int r = ClampColor(StringToInt(szArg));
    GetCmdArg(3, szArg, sizeof(szArg));
    int g = ClampColor(StringToInt(szArg));
    GetCmdArg(4, szArg, sizeof(szArg));
    int b = ClampColor(StringToInt(szArg));

    int a = 255;
    if (args >= 5)
    {
        GetCmdArg(5, szArg, sizeof(szArg));
        a = ClampColor(StringToInt(szArg));
    }

    g_iColors[client][iType][0] = r;
    g_iColors[client][iType][1] = g;
    g_iColors[client][iType][2] = b;
    g_iColors[client][iType][3] = a;

    SaveClientColor(client, iType);
    ReplyToCommand(client, "[st] set %s color to [%d, %d, %d, %d]", g_szTriggerNames[iType], r, g, b, a);

    return Plugin_Handled;
}

Action Command_SetSpecialColor(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args < 4)
    {
        ReplyToCommand(client, "[st] usage: sm_stcolor_special <type 0-3> <r> <g> <b> [a]");
        ReplyToCommand(client, "[st] types: 0=normal, 1=gravity, 2=antigrav, 3=basevel");
        return Plugin_Handled;
    }

    char szArg[16];
    GetCmdArg(1, szArg, sizeof(szArg));
    int iType = StringToInt(szArg);

    if (iType < 0 || iType >= view_as<int>(TM_MAX))
    {
        ReplyToCommand(client, "[st] invalid type. use 0-3.");
        return Plugin_Handled;
    }

    GetCmdArg(2, szArg, sizeof(szArg));
    int r = ClampColor(StringToInt(szArg));
    GetCmdArg(3, szArg, sizeof(szArg));
    int g = ClampColor(StringToInt(szArg));
    GetCmdArg(4, szArg, sizeof(szArg));
    int b = ClampColor(StringToInt(szArg));

    int a = 255;
    if (args >= 5)
    {
        GetCmdArg(5, szArg, sizeof(szArg));
        a = ClampColor(StringToInt(szArg));
    }

    g_iColorsSpecial[client][iType][0] = r;
    g_iColorsSpecial[client][iType][1] = g;
    g_iColorsSpecial[client][iType][2] = b;
    g_iColorsSpecial[client][iType][3] = a;

    SaveClientSpecialColor(client, iType);
    ReplyToCommand(client, "[st] set %s color to [%d, %d, %d, %d]", g_szSpecialNames[iType], r, g, b, a);

    return Plugin_Handled;
}

Action Command_SetEntityColor(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args < 4)
    {
        ReplyToCommand(client, "[st] usage: sm_stcolor_ent <entity_index> <r> <g> <b> [a]");
        return Plugin_Handled;
    }

    char szArg[16];
    GetCmdArg(1, szArg, sizeof(szArg));
    int entity = StringToInt(szArg);

    if (!IsValidEntity(entity))
    {
        ReplyToCommand(client, "[st] invalid entity index.");
        return Plugin_Handled;
    }

    GetCmdArg(2, szArg, sizeof(szArg));
    int r = ClampColor(StringToInt(szArg));
    GetCmdArg(3, szArg, sizeof(szArg));
    int g = ClampColor(StringToInt(szArg));
    GetCmdArg(4, szArg, sizeof(szArg));
    int b = ClampColor(StringToInt(szArg));

    int a = 255;
    if (args >= 5)
    {
        GetCmdArg(5, szArg, sizeof(szArg));
        a = ClampColor(StringToInt(szArg));
    }

    SetEntityColorForClient(client, entity, r, g, b, a);
    ReplyToCommand(client, "[st] set entity %d color to [%d, %d, %d, %d]", entity, r, g, b, a);

    return Plugin_Handled;
}

Action Command_SetOpacity(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[st] usage: sm_stopacity <0-255>");
        return Plugin_Handled;
    }

    char szArg[16];
    GetCmdArg(1, szArg, sizeof(szArg));
    int iAlpha = ClampColor(StringToInt(szArg));

    ApplyClientOpacity(client, iAlpha);
    ReplyToCommand(client, "[st] opacity set to %d%%", (iAlpha * 100) / 255);
    return Plugin_Handled;
}

Action Command_SetDisplayMode(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[st] usage: sm_stmode <solid>");
        return Plugin_Handled;
    }

    char szArg[16];
    GetCmdArg(1, szArg, sizeof(szArg));

    int iMode = -1;
    bool bOutlineRequested = false;
    if (StrEqual(szArg, "solid", false) || StrEqual(szArg, "0"))
    {
        iMode = view_as<int>(DISPLAY_SOLID);
    }
    else if (StrEqual(szArg, "outline", false) || StrEqual(szArg, "1") ||
             StrEqual(szArg, "both", false) || StrEqual(szArg, "2"))
    {
        iMode = view_as<int>(DISPLAY_SOLID);
        bOutlineRequested = true;
    }

    if (iMode == -1)
    {
        ReplyToCommand(client, "[st] invalid mode. use: solid.");
        return Plugin_Handled;
    }

    g_eDisplayMode[client] = DISPLAY_SOLID;
    SaveClientDisplayMode(client);
    UpdateHookState();
    if (bOutlineRequested)
    {
        ReplyToCommand(client, "[st] outline mode is disabled; using solid.");
    }
    else
    {
        ReplyToCommand(client, "[st] display mode set to solid");
    }
    return Plugin_Handled;
}

Action Command_IdentifyTrigger(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    int ent = FindTriggerInCrosshair(client);
    if (ent == -1)
    {
        ReplyToCommand(client, "[st] no trigger found under crosshair.");
        return Plugin_Handled;
    }

    DisplayTriggerActionsMenu(client, ent);
    return Plugin_Handled;
}

Action Command_ProfileSave(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (!g_bDatabaseReady || g_hDatabase == null)
    {
        ReplyToCommand(client, "[st] database not ready.");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[st] usage: sm_stprofile_save <name> [public]");
        return Plugin_Handled;
    }

    char szName[64];
    GetCmdArg(1, szName, sizeof(szName));
    TrimString(szName);
    if (szName[0] == '\0')
    {
        ReplyToCommand(client, "[st] invalid profile name.");
        return Plugin_Handled;
    }

    bool bPublic = false;
    if (args >= 2)
    {
        char szArg[16];
        GetCmdArg(2, szArg, sizeof(szArg));
        bPublic = StrEqual(szArg, "public", false) || StrEqual(szArg, "1");
    }

    char szSteamId[64];
    if (!GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId)))
    {
        strcopy(szSteamId, sizeof(szSteamId), "unknown");
    }

    char szMap[64];
    GetCurrentMap(szMap, sizeof(szMap));

    char colors[256];
    char colorsSpecial[256];
    char indivData[PROFILE_INDIV_MAX];
    SerializeColors(client, colors, sizeof(colors));
    SerializeColorsSpecial(client, colorsSpecial, sizeof(colorsSpecial));
    SerializeIndividual(client, indivData, sizeof(indivData));
    int typeMask = GetClientTypeMask(client);

    QueueProfileSave(client, szName, szSteamId, szMap, bPublic,
        view_as<int>(g_eDisplayMode[client]), typeMask, colors, colorsSpecial, indivData, "profile saved.");
    return Plugin_Handled;
}

Action Command_ProfileLoad(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (!g_bDatabaseReady || g_hDatabase == null)
    {
        ReplyToCommand(client, "[st] database not ready.");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        ReplyToCommand(client, "[st] usage: sm_stprofile_load <name> [public] [map]");
        return Plugin_Handled;
    }

    char szName[64];
    GetCmdArg(1, szName, sizeof(szName));
    TrimString(szName);
    if (szName[0] == '\0')
    {
        ReplyToCommand(client, "[st] invalid profile name.");
        return Plugin_Handled;
    }

    bool bPublic = false;
    char szMapOverride[64];
    szMapOverride[0] = '\0';

    if (args >= 2)
    {
        char szArg[64];
        GetCmdArg(2, szArg, sizeof(szArg));
        if (StrEqual(szArg, "public", false) || StrEqual(szArg, "1"))
        {
            bPublic = true;
            if (args >= 3)
            {
                GetCmdArg(3, szMapOverride, sizeof(szMapOverride));
            }
        }
        else
        {
            strcopy(szMapOverride, sizeof(szMapOverride), szArg);
        }
    }

    char szSteamId[64];
    if (!GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId)))
    {
        strcopy(szSteamId, sizeof(szSteamId), "unknown");
    }

    char szMap[64];
    if (szMapOverride[0])
    {
        strcopy(szMap, sizeof(szMap), szMapOverride);
    }
    else
    {
        GetCurrentMap(szMap, sizeof(szMap));
    }

    char escName[128], escSteam[96], escMap[96];
    EscapeStringSafe(szName, escName, sizeof(escName));
    EscapeStringSafe(szSteamId, escSteam, sizeof(escSteam));
    EscapeStringSafe(szMap, escMap, sizeof(escMap));

    char query[512];
    if (bPublic)
    {
        FormatEx(query, sizeof(query), "SELECT display_mode, type_mask, colors, colors_special, indiv_data FROM st_profiles WHERE map='%s' AND name='%s' AND public=1 ORDER BY updated_at DESC LIMIT 1;",
            escMap, escName);
    }
    else
    {
        FormatEx(query, sizeof(query), "SELECT display_mode, type_mask, colors, colors_special, indiv_data FROM st_profiles WHERE map='%s' AND name='%s' AND steamid='%s' ORDER BY updated_at DESC LIMIT 1;",
            escMap, escName, escSteam);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(bPublic ? 1 : 0);
    pack.WriteString(szName);
    SQL_TQuery(g_hDatabase, OnProfileLoad, query, pack);
    return Plugin_Handled;
}

Action Command_ProfileList(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (!g_bDatabaseReady || g_hDatabase == null)
    {
        ReplyToCommand(client, "[st] database not ready.");
        return Plugin_Handled;
    }

    bool bPublic = false;
    char szMapOverride[64];
    szMapOverride[0] = '\0';

    if (args >= 1)
    {
        char szArg[64];
        GetCmdArg(1, szArg, sizeof(szArg));
        if (StrEqual(szArg, "public", false) || StrEqual(szArg, "1"))
        {
            bPublic = true;
            if (args >= 2)
            {
                GetCmdArg(2, szMapOverride, sizeof(szMapOverride));
            }
        }
        else
        {
            strcopy(szMapOverride, sizeof(szMapOverride), szArg);
        }
    }

    char szSteamId[64];
    if (!GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId)))
    {
        strcopy(szSteamId, sizeof(szSteamId), "unknown");
    }

    char szMap[64];
    if (szMapOverride[0])
    {
        strcopy(szMap, sizeof(szMap), szMapOverride);
    }
    else
    {
        GetCurrentMap(szMap, sizeof(szMap));
    }

    char escSteam[96], escMap[96];
    EscapeStringSafe(szSteamId, escSteam, sizeof(escSteam));
    EscapeStringSafe(szMap, escMap, sizeof(escMap));

    char query[512];
    if (bPublic)
    {
        FormatEx(query, sizeof(query), "SELECT name, steamid FROM st_profiles WHERE map='%s' AND public=1 ORDER BY name ASC LIMIT 50;",
            escMap);
    }
    else
    {
        FormatEx(query, sizeof(query), "SELECT name, public FROM st_profiles WHERE map='%s' AND steamid='%s' ORDER BY name ASC LIMIT 50;",
            escMap, escSteam);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(bPublic ? 1 : 0);
    SQL_TQuery(g_hDatabase, OnProfileList, query, pack);
    return Plugin_Handled;
}

Action Command_ProfileCopy(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (!g_bDatabaseReady || g_hDatabase == null)
    {
        ReplyToCommand(client, "[st] database not ready.");
        return Plugin_Handled;
    }

    if (args < 2)
    {
        ReplyToCommand(client, "[st] usage: sm_stprofile_copy <name> <frommap> [public] [newname]");
        return Plugin_Handled;
    }

    char szName[64];
    char szFromMap[64];
    GetCmdArg(1, szName, sizeof(szName));
    GetCmdArg(2, szFromMap, sizeof(szFromMap));
    TrimString(szName);
    TrimString(szFromMap);

    if (szName[0] == '\0' || szFromMap[0] == '\0')
    {
        ReplyToCommand(client, "[st] invalid arguments.");
        return Plugin_Handled;
    }

    bool bPublic = false;
    char szNewName[64];
    szNewName[0] = '\0';

    if (args >= 3)
    {
        char szArg[64];
        GetCmdArg(3, szArg, sizeof(szArg));
        if (StrEqual(szArg, "public", false) || StrEqual(szArg, "1"))
        {
            bPublic = true;
            if (args >= 4)
            {
                GetCmdArg(4, szNewName, sizeof(szNewName));
                TrimString(szNewName);
            }
        }
        else
        {
            strcopy(szNewName, sizeof(szNewName), szArg);
        }
    }

    if (szNewName[0] == '\0')
    {
        strcopy(szNewName, sizeof(szNewName), szName);
    }

    char szSteamId[64];
    if (!GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId)))
    {
        strcopy(szSteamId, sizeof(szSteamId), "unknown");
    }

    char escName[128], escSteam[96], escMap[96];
    EscapeStringSafe(szName, escName, sizeof(escName));
    EscapeStringSafe(szSteamId, escSteam, sizeof(escSteam));
    EscapeStringSafe(szFromMap, escMap, sizeof(escMap));

    char query[512];
    if (bPublic)
    {
        FormatEx(query, sizeof(query), "SELECT display_mode, type_mask, colors, colors_special, indiv_data FROM st_profiles WHERE map='%s' AND name='%s' AND public=1 ORDER BY updated_at DESC LIMIT 1;",
            escMap, escName);
    }
    else
    {
        FormatEx(query, sizeof(query), "SELECT display_mode, type_mask, colors, colors_special, indiv_data FROM st_profiles WHERE map='%s' AND name='%s' AND steamid='%s' ORDER BY updated_at DESC LIMIT 1;",
            escMap, escName, escSteam);
    }

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(bPublic ? 1 : 0);
    pack.WriteString(szNewName);
    SQL_TQuery(g_hDatabase, OnProfileCopy, query, pack);
    return Plugin_Handled;
}

Action Command_MainMenu(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    DisplayMainMenu(client);
    return Plugin_Handled;
}

Action Command_Search(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    if (args == 0)
    {
        // no args = show all triggers
        SearchTriggers(client, "");
    }
    else
    {
        // combine all args into search term
        char szSearchTerm[64];
        GetCmdArgString(szSearchTerm, sizeof(szSearchTerm));
        StripQuotes(szSearchTerm);
        TrimString(szSearchTerm);
        SearchTriggers(client, szSearchTerm);
    }

    return Plugin_Handled;
}

// ============================================================================
// main menu system
// ============================================================================

void DisplayMainMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Main);

    // count active triggers for status
    int iActiveTypes = 0;
    for (int i = 0; i < MAX_TYPES; i++)
    {
        if (g_bTypeEnabled[client][i])
            iActiveTypes++;
    }
    int iIndividual = (g_alClientTriggers[client] != null) ? g_alClientTriggers[client].Length : 0;

    menu.SetTitle("show triggers\n \nactive: %d types, %d individual", iActiveTypes, iIndividual);

    menu.AddItem("visibility", "toggle by type");
    menu.AddItem("search", "search & toggle triggers");
    menu.AddItem("individual", "my enabled triggers");
    menu.AddItem("display", "display settings");
    menu.AddItem("help", "commands & help");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[32];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            if (StrEqual(szInfo, "visibility"))
            {
                DisplayVisibilityMenu(param1);
            }
            else if (StrEqual(szInfo, "search"))
            {
                DisplaySearchMenu(param1);
            }
            else if (StrEqual(szInfo, "individual"))
            {
                DisplayIndividualTriggersMenu(param1, 0);
            }
            else if (StrEqual(szInfo, "display"))
            {
                DisplayDisplayMenu(param1);
            }
            else if (StrEqual(szInfo, "help"))
            {
                DisplayHelpMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// visibility menu
// ============================================================================

void DisplayVisibilityMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Visibility, MenuAction_DrawItem | MenuAction_DisplayItem);

    // show current status in title
    int iEnabled = 0;
    for (int i = 0; i < MAX_TYPES; i++)
    {
        if (g_bTypeEnabled[client][i])
            iEnabled++;
    }

    menu.SetTitle("toggle by type\n \n%d of %d types enabled\nclick to toggle:", iEnabled, MAX_TYPES);

    menu.AddItem("-2", "[+] enable all types");
    menu.AddItem("-1", "[-] disable all types\n ");

    for (int i = 0; i < MAX_TYPES; i++)
    {
        char szInfo[8];
        IntToString(i, szInfo, sizeof(szInfo));
        menu.AddItem(szInfo, g_szTriggerNames[i]);
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Visibility(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[8];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            int iType = StringToInt(szInfo);
            switch (iType)
            {
                case MENU_ENABLE_ALL:
                {
                    for (int i = 0; i < MAX_TYPES; i++)
                    {
                        g_bTypeEnabled[param1][i] = true;
                    }
                    PrintToChat(param1, "[st] all triggers enabled.");
                }
                case MENU_DISABLE_ALL:
                {
                    for (int i = 0; i < MAX_TYPES; i++)
                    {
                        g_bTypeEnabled[param1][i] = false;
                    }
                    PrintToChat(param1, "[st] all triggers disabled.");
                }
                default:
                {
                    if (iType >= 0 && iType < MAX_TYPES)
                    {
                        g_bTypeEnabled[param1][iType] = !g_bTypeEnabled[param1][iType];
                        PrintToChat(param1, "[st] %s: %s", g_szTriggerNames[iType],
                            g_bTypeEnabled[param1][iType] ? "on" : "off");
                    }
                }
            }

            UpdateHookState();
            DisplayVisibilityMenu(param1);
        }
        case MenuAction_DrawItem:
        {
            char szInfo[8];
            menu.GetItem(param2, szInfo, sizeof(szInfo));
            int iType = StringToInt(szInfo);

            switch (iType)
            {
                case MENU_ENABLE_ALL:
                {
                    for (int i = 0; i < MAX_TYPES; i++)
                    {
                        if (!g_bTypeEnabled[param1][i])
                            return ITEMDRAW_DEFAULT;
                    }
                    return ITEMDRAW_DISABLED;
                }
                case MENU_DISABLE_ALL:
                {
                    for (int i = 0; i < MAX_TYPES; i++)
                    {
                        if (g_bTypeEnabled[param1][i])
                            return ITEMDRAW_DEFAULT;
                    }
                    return ITEMDRAW_DISABLED;
                }
            }
            return ITEMDRAW_DEFAULT;
        }
        case MenuAction_DisplayItem:
        {
            char szInfo[8], szDisplay[64];
            menu.GetItem(param2, szInfo, sizeof(szInfo), _, szDisplay, sizeof(szDisplay));

            int iType = StringToInt(szInfo);
            if (iType >= 0 && iType < MAX_TYPES)
            {
                Format(szDisplay, sizeof(szDisplay), "%s: [%s]",
                    szDisplay, g_bTypeEnabled[param1][iType] ? "on" : "off");
                return RedrawMenuItem(szDisplay);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// search menu
// ============================================================================

void DisplaySearchMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Search);
    menu.SetTitle("search & toggle triggers\n \nconsole: !stsearch [term]");

    menu.AddItem("all", "browse all triggers");
    menu.AddItem("new", "search by keyword...");

    if (g_alSearchResults[client] != null && g_alSearchResults[client].Length > 0)
    {
        char szDisplay[64];
        if (g_szLastSearch[client][0] != '\0')
        {
            FormatEx(szDisplay, sizeof(szDisplay), "last: \"%s\" (%d found)", g_szLastSearch[client], g_alSearchResults[client].Length);
        }
        else
        {
            FormatEx(szDisplay, sizeof(szDisplay), "last results (%d triggers)", g_alSearchResults[client].Length);
        }
        menu.AddItem("prev", szDisplay);
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Search(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[32];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            if (StrEqual(szInfo, "all"))
            {
                SearchTriggers(param1, "");
            }
            else if (StrEqual(szInfo, "new"))
            {
                DisplaySearchInputMenu(param1);
            }
            else if (StrEqual(szInfo, "prev"))
            {
                g_iSearchPage[param1] = 0;
                DisplaySearchResultsMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void DisplaySearchInputMenu(int client)
{
    Menu menu = new Menu(MenuHandler_SearchInput);
    menu.SetTitle("quick search keywords\n \nor use console:\n!stsearch <keyword>");

    // common surf/bhop/timer keywords
    menu.AddItem("start", "start (start zones)");
    menu.AddItem("end", "end (end zones)");
    menu.AddItem("teleport", "teleport");
    menu.AddItem("push", "push (boosts)");
    menu.AddItem("boost", "boost");
    menu.AddItem("zone", "zone");
    menu.AddItem("checkpoint", "checkpoint / cp");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_SearchInput(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[32];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            // handle special multi-term searches
            if (StrEqual(szInfo, "checkpoint"))
            {
                SearchTriggersMulti(param1, "checkpoint", "cp");
            }
            else
            {
                SearchTriggers(param1, szInfo);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack || param2 == MenuCancel_Exit)
            {
                if (g_iSearchPage[param1] > 0)
                {
                    g_iSearchPage[param1]--;
                    DisplaySearchResultsMenu(param1);
                }
                else
                {
                    DisplaySearchMenu(param1);
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void SearchTriggers(int client, const char[] szSearchTerm)
{
    if (g_alSearchResults[client] == null)
    {
        g_alSearchResults[client] = new ArrayList();
    }
    g_alSearchResults[client].Clear();

    strcopy(g_szLastSearch[client], sizeof(g_szLastSearch[]), szSearchTerm);

    char szClassName[64], szTargetname[128];
    bool bShowAll = (szSearchTerm[0] == '\0');

    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntityClassname(ent, szClassName, sizeof(szClassName));
        if (GetTriggerType(szClassName) == -1)
        {
            continue;
        }

        if (bShowAll)
        {
            g_alSearchResults[client].Push(EntIndexToEntRef(ent));
            continue;
        }

        GetEntPropString(ent, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

        if (StrContains(szTargetname, szSearchTerm, false) != -1 ||
            StrContains(szClassName, szSearchTerm, false) != -1)
        {
            g_alSearchResults[client].Push(EntIndexToEntRef(ent));
        }
    }

    if (g_alSearchResults[client].Length > 0)
    {
        g_iSearchPage[client] = 0;
        DisplaySearchResultsMenu(client);
    }
    else
    {
        PrintToChat(client, "[st] no triggers found%s%s",
            bShowAll ? "" : " matching: ", bShowAll ? "" : szSearchTerm);
        DisplaySearchMenu(client);
    }
}

void SearchTriggersMulti(int client, const char[] szTerm1, const char[] szTerm2)
{
    if (g_alSearchResults[client] == null)
    {
        g_alSearchResults[client] = new ArrayList();
    }
    g_alSearchResults[client].Clear();

    char szDisplayTerm[64];
    FormatEx(szDisplayTerm, sizeof(szDisplayTerm), "%s/%s", szTerm1, szTerm2);
    strcopy(g_szLastSearch[client], sizeof(g_szLastSearch[]), szDisplayTerm);

    char szClassName[64], szTargetname[128];

    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntityClassname(ent, szClassName, sizeof(szClassName));
        if (GetTriggerType(szClassName) == -1)
        {
            continue;
        }

        GetEntPropString(ent, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

        if (StrContains(szTargetname, szTerm1, false) != -1 ||
            StrContains(szTargetname, szTerm2, false) != -1 ||
            StrContains(szClassName, szTerm1, false) != -1 ||
            StrContains(szClassName, szTerm2, false) != -1)
        {
            g_alSearchResults[client].Push(EntIndexToEntRef(ent));
        }
    }

    if (g_alSearchResults[client].Length > 0)
    {
        g_iSearchPage[client] = 0;
        DisplaySearchResultsMenu(client);
    }
    else
    {
        PrintToChat(client, "[st] no triggers found matching: %s", szDisplayTerm);
        DisplaySearchMenu(client);
    }
}

void DisplaySearchResultsMenu(int client)
{
    if (g_alSearchResults[client] == null)
    {
        DisplaySearchMenu(client);
        return;
    }

    Menu menu = new Menu(MenuHandler_SearchResults);
    menu.Pagination = MENU_NO_PAGINATION;
    menu.ExitButton = true;

    PruneEntRefList(g_alSearchResults[client]);

    int iTotalItems = g_alSearchResults[client].Length;
    int iItemsPerPage = 7;
    int iTotalPages = (iTotalItems + iItemsPerPage - 1) / iItemsPerPage;
    if (iTotalPages == 0)
    {
        PrintToChat(client, "[st] no triggers found.");
        DisplaySearchMenu(client);
        delete menu;
        return;
    }

    if (g_iSearchPage[client] >= iTotalPages)
    {
        g_iSearchPage[client] = iTotalPages - 1;
    }
    if (g_iSearchPage[client] < 0)
    {
        g_iSearchPage[client] = 0;
    }

    int iStartItem = g_iSearchPage[client] * iItemsPerPage;
    int iEndItem = iStartItem + iItemsPerPage;
    if (iEndItem > iTotalItems) iEndItem = iTotalItems;

    if (g_szLastSearch[client][0] != '\0')
    {
        menu.SetTitle("search: \"%s\"\n%d found (page %d/%d)\n \nclick to toggle:",
            g_szLastSearch[client], iTotalItems, g_iSearchPage[client] + 1, iTotalPages);
    }
    else
    {
        menu.SetTitle("all triggers\n%d found (page %d/%d)\n \nclick to toggle:",
            iTotalItems, g_iSearchPage[client] + 1, iTotalPages);
    }

    char szEntRef[16], szDisplay[128], szClassName[64], szTargetname[64];

    for (int i = iStartItem; i < iEndItem; i++)
    {
        int iEntRef = g_alSearchResults[client].Get(i);
        int ent = EntRefToEntIndex(iEntRef);

        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
        {
            continue;
        }

        IntToString(iEntRef, szEntRef, sizeof(szEntRef));
        GetEntityClassname(ent, szClassName, sizeof(szClassName));
        GetEntPropString(ent, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

        bool bEnabled = IsEntityEnabledForClient(client, ent);
        FormatEx(szDisplay, sizeof(szDisplay), "%s%s (%s)",
            bEnabled ? "[on] " : "[off] ",
            szTargetname[0] ? szTargetname : "(unnamed)",
            szClassName);

        menu.AddItem(szEntRef, szDisplay);
    }

    // navigation
    if (iEndItem < iTotalItems)
    {
        menu.AddItem("next", "next page >>");
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_SearchResults(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[16];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            if (StrEqual(szInfo, "prev"))
            {
                g_iSearchPage[param1]--;
                DisplaySearchResultsMenu(param1);
            }
            else if (StrEqual(szInfo, "next"))
            {
                g_iSearchPage[param1]++;
                DisplaySearchResultsMenu(param1);
            }
            else
            {
                int iEntRef = StringToInt(szInfo);
                int ent = EntRefToEntIndex(iEntRef);

                if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
                {
                    ToggleEntityForClient(param1, ent);
                    DisplaySearchResultsMenu(param1);
                }
                else
                {
                    DisplaySearchResultsMenu(param1);
                }
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplaySearchMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// display settings menus
// ============================================================================

void DisplayDisplayMenu(int client)
{
    Menu menu = new Menu(MenuHandler_DisplayMain);

    int iAlpha = g_iColors[client][TRIGGER_MULTIPLE][3];
    menu.SetTitle("display settings\n \nmode: solid (outline disabled)\nopacity: %d%%", (iAlpha * 100) / 255);

    menu.AddItem("mode", "display mode (solid only)");
    menu.AddItem("opacity", "change opacity");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_DisplayMain(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[16];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            if (StrEqual(szInfo, "mode"))
            {
                DisplayDisplayModeMenu(param1);
            }
            else if (StrEqual(szInfo, "opacity"))
            {
                DisplayAlphaMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void DisplayDisplayModeMenu(int client)
{
    Menu menu = new Menu(MenuHandler_DisplayMode);
    menu.SetTitle("display mode\n \nsolid = filled brush\noutline mode disabled");

    menu.AddItem("solid", "[x] solid");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_DisplayMode(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            g_eDisplayMode[param1] = DISPLAY_SOLID;
            SaveClientDisplayMode(param1);
            UpdateHookState();
            DisplayDisplayModeMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayDisplayMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// trigger actions menu (for individual triggers)
// ============================================================================

void DisplayTriggerActionsMenu(int client, int entity)
{
    char szClassName[64], szTargetname[64];
    GetEntityClassname(entity, szClassName, sizeof(szClassName));
    GetEntPropString(entity, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

    Menu menu = new Menu(MenuHandler_TriggerActions);
    menu.SetTitle("%s\n%s\nentity: %d",
        szTargetname[0] ? szTargetname : "(unnamed)",
        szClassName,
        entity);

    char szEntStr[16];
    IntToString(EntIndexToEntRef(entity), szEntStr, sizeof(szEntStr));

    bool bEnabled = IsEntityEnabledForClient(client, entity);
    bool bHasCustomColor = false;
    int iIndex = GetEntityIndexForClient(client, entity);
    if (iIndex != -1)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(iIndex, trig);
        bHasCustomColor = (trig.color[0] >= 0);
    }

    char szToggle[32];
    FormatEx(szToggle, sizeof(szToggle), "toggle_%s", szEntStr);
    menu.AddItem(szToggle, bEnabled ? "visibility: on (click to disable)" : "visibility: off (click to enable)");

    char szInfo[32];
    FormatEx(szInfo, sizeof(szInfo), "info_%s", szEntStr);
    menu.AddItem(szInfo, "view trigger info");

    char szColor[32];
    FormatEx(szColor, sizeof(szColor), "color_%s", szEntStr);
    menu.AddItem(szColor, "set custom color (use command)");

    char szReset[32];
    FormatEx(szReset, sizeof(szReset), "reset_%s", szEntStr);
    menu.AddItem(szReset, "reset to default color", bHasCustomColor ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_TriggerActions(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[32];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            char szParts[2][16];
            ExplodeString(szInfo, "_", szParts, 2, 16);

            int iEntRef = StringToInt(szParts[1]);
            int ent = EntRefToEntIndex(iEntRef);

            if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
            {
                PrintToChat(param1, "[st] entity no longer valid.");
                DisplaySearchResultsMenu(param1);
                return 0;
            }

            if (StrEqual(szParts[0], "toggle"))
            {
                ToggleEntityForClient(param1, ent);
                DisplayTriggerActionsMenu(param1, ent);
            }
            else if (StrEqual(szParts[0], "info"))
            {
                DisplayTriggerInfoMenu(param1, ent);
            }
            else if (StrEqual(szParts[0], "color"))
            {
                PrintToChat(param1, "[st] use: sm_stcolor_ent %d <r> <g> <b> [a]", ent);
                DisplayTriggerActionsMenu(param1, ent);
            }
            else if (StrEqual(szParts[0], "reset"))
            {
                ResetEntityColorForClient(param1, ent);
                PrintToChat(param1, "[st] color reset to default.");
                DisplayTriggerActionsMenu(param1, ent);
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplaySearchResultsMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// trigger info menu
// ============================================================================

void DisplayTriggerInfoMenu(int client, int entity)
{
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))
    {
        PrintToChat(client, "[st] entity no longer valid.");
        DisplaySearchResultsMenu(client);
        return;
    }

    g_iLastInfoEntRef[client] = EntIndexToEntRef(entity);

    char szClassName[64], szTargetname[64];
    GetEntityClassname(entity, szClassName, sizeof(szClassName));
    GetEntPropString(entity, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

    int iHammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
    int iSpawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");

    float origin[3], mins[3], maxs[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

    for (int i = 0; i < 3; i++)
    {
        mins[i] += origin[i];
        maxs[i] += origin[i];
    }

    int iParent = GetEntPropEnt(entity, Prop_Data, "m_hMoveParent");
    char szParentName[64];
    szParentName[0] = '\0';
    if (iParent > 0 && IsValidEntity(iParent))
    {
        GetEntPropString(iParent, Prop_Data, "m_iName", szParentName, sizeof(szParentName));
    }

    Menu menu = new Menu(MenuHandler_TriggerInfo);
    menu.SetTitle("trigger info");

    int line = 0;
    AddInfoLine(menu, line, "class: %s", szClassName);
    AddInfoLine(menu, line, "name: %s", szTargetname[0] ? szTargetname : "(none)");
    AddInfoLine(menu, line, "entity: %d", entity);
    AddInfoLine(menu, line, "hammerid: %d", iHammerId);
    AddInfoLine(menu, line, "spawnflags: %d", iSpawnFlags);
    AddInfoLine(menu, line, "origin: %.0f %.0f %.0f", origin[0], origin[1], origin[2]);
    AddInfoLine(menu, line, "bounds: (%.0f %.0f %.0f) -> (%.0f %.0f %.0f)",
        mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
    if (iParent > 0)
    {
        AddInfoLine(menu, line, "parent: %s (#%d)", szParentName[0] ? szParentName : "(unnamed)", iParent);
    }
    else
    {
        AddInfoLine(menu, line, "parent: (none)");
    }

    ArrayList outputs = GetOutputsForHammerId(iHammerId);
    if (outputs != null && outputs.Length > 0)
    {
        AddInfoLine(menu, line, "outputs: %d", outputs.Length);
        int shown = 0;
        for (int i = 0; i < outputs.Length && shown < 6; i++)
        {
            OutputInfo info;
            outputs.GetArray(i, info);

            if (info.target[0] == '\0')
            {
                continue;
            }

            char paramShort[32];
            if (info.param[0])
            {
                strcopy(paramShort, sizeof(paramShort), info.param);
                if (strlen(paramShort) > 24)
                {
                    paramShort[24] = '\0';
                }
            }
            else
            {
                paramShort[0] = '\0';
            }

            if (paramShort[0])
            {
                AddInfoLine(menu, line, " %s -> %s:%s [p=%s d=%.2f once=%d]",
                    info.output, info.target, info.input, paramShort, info.delay, info.once);
            }
            else
            {
                AddInfoLine(menu, line, " %s -> %s:%s [d=%.2f once=%d]",
                    info.output, info.target, info.input, info.delay, info.once);
            }
            shown++;
        }
        if (outputs.Length > shown)
        {
            AddInfoLine(menu, line, " ...and %d more", outputs.Length - shown);
        }

        ArrayList targets = CollectUniqueTargets(outputs);
        if (targets != null && targets.Length > 0)
        {
            AddInfoLine(menu, line, "connections:");
            int tShown = 0;
            char szTarget[64];
            for (int i = 0; i < targets.Length && tShown < 6; i++)
            {
                targets.GetString(i, szTarget, sizeof(szTarget));
                int count = CountEntitiesWithTargetname(szTarget);
                AddInfoLine(menu, line, " %s (%d)", szTarget, count);
                tShown++;
            }
            if (targets.Length > tShown)
            {
                AddInfoLine(menu, line, " ...and %d more", targets.Length - tShown);
            }
        }
        delete targets;
    }
    else
    {
        AddInfoLine(menu, line, "outputs: (none)");
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_TriggerInfo(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                int ent = EntRefToEntIndex(g_iLastInfoEntRef[param1]);
                if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
                {
                    DisplayTriggerActionsMenu(param1, ent);
                }
                else
                {
                    DisplayMainMenu(param1);
                }
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// individual triggers menu
// ============================================================================

void DisplayIndividualTriggersMenu(int client, int page)
{
    PruneClientTriggers(client);
    if (g_alClientTriggers[client] == null || g_alClientTriggers[client].Length == 0)
    {
        Menu menu = new Menu(MenuHandler_IndividualEmpty);
        menu.SetTitle("my enabled triggers\n \nno triggers enabled.\nuse search to find and enable triggers.");
        menu.AddItem("search", "go to search");
        menu.ExitBackButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
        return;
    }

    Menu menu = new Menu(MenuHandler_Individual);

    int iTotalItems = g_alClientTriggers[client].Length;
    int iItemsPerPage = 7;
    int iTotalPages = (iTotalItems + iItemsPerPage - 1) / iItemsPerPage;
    if (iTotalPages == 0)
    {
        DisplayIndividualTriggersMenu(client, 0);
        delete menu;
        return;
    }

    if (page >= iTotalPages) page = iTotalPages - 1;
    if (page < 0) page = 0;

    int iStartItem = page * iItemsPerPage;
    int iEndItem = iStartItem + iItemsPerPage;
    if (iEndItem > iTotalItems) iEndItem = iTotalItems;

    menu.SetTitle("my enabled triggers (%d)\npage %d/%d", iTotalItems, page + 1, iTotalPages);

    char szEntRef[16], szDisplay[128], szClassName[64], szTargetname[64];

    for (int i = iStartItem; i < iEndItem; i++)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(i, trig);

        int ent = EntRefToEntIndex(trig.entRef);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
        {
            continue;
        }

        IntToString(trig.entRef, szEntRef, sizeof(szEntRef));
        GetEntityClassname(ent, szClassName, sizeof(szClassName));
        GetEntPropString(ent, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

        bool bHasCustomColor = (trig.color[0] >= 0);
        FormatEx(szDisplay, sizeof(szDisplay), "%s (%s)%s",
            szTargetname[0] ? szTargetname : "(unnamed)",
            szClassName,
            bHasCustomColor ? " [custom]" : "");

        menu.AddItem(szEntRef, szDisplay);
    }

    // navigation
    char szNavInfo[16];
    if (page > 0)
    {
        FormatEx(szNavInfo, sizeof(szNavInfo), "prev_%d", page);
        menu.AddItem(szNavInfo, "<< previous");
    }
    if (iEndItem < iTotalItems)
    {
        FormatEx(szNavInfo, sizeof(szNavInfo), "next_%d", page);
        menu.AddItem(szNavInfo, "next >>");
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_IndividualEmpty(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            DisplaySearchMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

int MenuHandler_Individual(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[16];
            menu.GetItem(param2, szInfo, sizeof(szInfo));

            if (StrContains(szInfo, "prev_") == 0 || StrContains(szInfo, "next_") == 0)
            {
                char szParts[2][8];
                ExplodeString(szInfo, "_", szParts, 2, 8);
                int iCurrentPage = StringToInt(szParts[1]);

                if (StrContains(szInfo, "prev_") == 0)
                {
                    DisplayIndividualTriggersMenu(param1, iCurrentPage - 1);
                }
                else
                {
                    DisplayIndividualTriggersMenu(param1, iCurrentPage + 1);
                }
            }
            else
            {
                int iEntRef = StringToInt(szInfo);
                int ent = EntRefToEntIndex(iEntRef);

                if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
                {
                    DisplayTriggerActionsMenu(param1, ent);
                }
                else
                {
                    DisplayIndividualTriggersMenu(param1, 0);
                }
            }
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// opacity menu
void DisplayAlphaMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Alpha);
    menu.SetTitle("opacity settings\n \nset opacity for all trigger types:");

    menu.AddItem("255", "100% (solid)");
    menu.AddItem("200", "80%");
    menu.AddItem("150", "60%");
    menu.AddItem("100", "40%");
    menu.AddItem("50", "20%");
    menu.AddItem("25", "10%");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Alpha(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char szInfo[8];
            menu.GetItem(param2, szInfo, sizeof(szInfo));
            int iAlpha = StringToInt(szInfo);

            ApplyClientOpacity(param1, iAlpha);

            PrintToChat(param1, "[st] all trigger opacity set to %d%%", (iAlpha * 100) / 255);
            DisplayDisplayMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayDisplayMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// help menu
void DisplayHelpMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Help);
    menu.SetTitle("commands & help\n \nchat commands:\n!st - main menu\n!stsearch [term] - search triggers\n!identifytrigger - open trigger settings");

    menu.AddItem("types", "trigger types:\n  0=multiple, 1=push\n  2=teleport, 3=teleport_rel");
    menu.AddItem("special", "special types (trigger_multiple):\n  0=normal, 1=gravity\n  2=antigrav, 3=basevel");
    menu.AddItem("display", "display commands:\n  sm_stmode solid\n  sm_stopacity <0-255>");
    menu.AddItem("profile", "profiles:\n  sm_stprofile_save <name> [public]\n  sm_stprofile_load <name> [public] [map]\n  sm_stprofile_list [public] [map]\n  sm_stprofile_copy <name> <frommap> [public] [newname]");
    menu.AddItem("color", "color commands:\n  sm_stcolor <type> <r> <g> <b> [a]\n  sm_stcolor_special <type> ...\n  sm_stcolor_ent <entity> ...");

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_Help(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            // just redisplay
            DisplayHelpMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                DisplayMainMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

// ============================================================================
// hook state management
// ============================================================================

void UpdateHookState()
{
    bool bNeedSolid = ShouldRenderSolid();
    bool bNeedOutline = ShouldRenderOutline();

    if (bNeedSolid && !g_bHooksActive)
    {
        HookAllTriggers();
        g_bHooksActive = true;
    }
    else if (!bNeedSolid && g_bHooksActive)
    {
        UnhookAllTriggers();
        g_bHooksActive = false;
    }

    if (bNeedOutline)
    {
        StartBeamTimer();
    }
    else
    {
        StopBeamTimer();
    }
}

bool ShouldRenderSolid()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
        {
            continue;
        }

        if (!ClientHasEnabledTriggers(client))
        {
            continue;
        }

        if (g_eDisplayMode[client] == DISPLAY_SOLID || g_eDisplayMode[client] == DISPLAY_BOTH)
        {
            return true;
        }
    }
    return false;
}

bool ShouldRenderOutline()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
        {
            continue;
        }

        if (!ClientHasEnabledTriggers(client))
        {
            continue;
        }

        if (g_eDisplayMode[client] == DISPLAY_OUTLINE || g_eDisplayMode[client] == DISPLAY_BOTH)
        {
            return true;
        }
    }
    return false;
}

void HookAllTriggers()
{
    char szClassName[64];

    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntityClassname(ent, szClassName, sizeof(szClassName));

        if (GetTriggerType(szClassName) == -1)
        {
            continue;
        }

        int iEffects = GetEntData(ent, g_iOffsetMFEffects);
        SetEntData(ent, g_iOffsetMFEffects, iEffects & ~EF_NODRAW);
        ChangeEdictState(ent, g_iOffsetMFEffects);

        int iEdictFlags = GetEdictFlags(ent);
        SetEdictFlags(ent, iEdictFlags & ~FL_EDICT_DONTSEND);

        SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

void UnhookAllTriggers()
{
    char szClassName[64];

    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntityClassname(ent, szClassName, sizeof(szClassName));

        if (GetTriggerType(szClassName) == -1)
        {
            continue;
        }

        int iEffects = GetEntData(ent, g_iOffsetMFEffects);
        SetEntData(ent, g_iOffsetMFEffects, iEffects | EF_NODRAW);
        ChangeEdictState(ent, g_iOffsetMFEffects);

        int iEdictFlags = GetEdictFlags(ent);
        SetEdictFlags(ent, iEdictFlags | FL_EDICT_DONTSEND);

        SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

// ============================================================================
// settransmit hook
// ============================================================================

Action Hook_SetTransmit(int entity, int client)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    int color[4];
    if (!GetTriggerColorForClient(client, entity, color))
    {
        return Plugin_Handled;
    }

    SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
    return Plugin_Continue;
}

// ============================================================================
// individual trigger management
// ============================================================================

int GetEntityIndexForClient(int client, int entity)
{
    if (g_alClientTriggers[client] == null)
    {
        return -1;
    }

    int iEntRef = EntIndexToEntRef(entity);

    for (int i = 0; i < g_alClientTriggers[client].Length; i++)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(i, trig);

        if (trig.entRef == iEntRef)
        {
            return i;
        }
    }

    return -1;
}

bool IsEntityEnabledForClient(int client, int entity)
{
    return GetEntityIndexForClient(client, entity) != -1;
}

void ToggleEntityForClient(int client, int entity)
{
    if (g_alClientTriggers[client] == null)
    {
        g_alClientTriggers[client] = new ArrayList(sizeof(IndividualTrigger));
    }

    int iIndex = GetEntityIndexForClient(client, entity);

    char szClassName[64], szTargetname[64];
    GetEntityClassname(entity, szClassName, sizeof(szClassName));
    GetEntPropString(entity, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname));

    if (iIndex == -1)
    {
        // add
        IndividualTrigger trig;
        trig.entRef = EntIndexToEntRef(entity);
        trig.color[0] = -1;  // use default
        trig.color[1] = -1;
        trig.color[2] = -1;
        trig.color[3] = -1;

        g_alClientTriggers[client].PushArray(trig);
        PrintToChat(client, "[st] enabled: %s (%s)",
            szTargetname[0] ? szTargetname : "(unnamed)", szClassName);
    }
    else
    {
        // remove
        g_alClientTriggers[client].Erase(iIndex);
        PrintToChat(client, "[st] disabled: %s (%s)",
            szTargetname[0] ? szTargetname : "(unnamed)", szClassName);
    }

    UpdateHookState();
}

void SetEntityColorForClient(int client, int entity, int r, int g, int b, int a)
{
    if (g_alClientTriggers[client] == null)
    {
        g_alClientTriggers[client] = new ArrayList(sizeof(IndividualTrigger));
    }

    int iIndex = GetEntityIndexForClient(client, entity);

    if (iIndex == -1)
    {
        // add with color
        IndividualTrigger trig;
        trig.entRef = EntIndexToEntRef(entity);
        trig.color[0] = r;
        trig.color[1] = g;
        trig.color[2] = b;
        trig.color[3] = a;

        g_alClientTriggers[client].PushArray(trig);
    }
    else
    {
        // update color
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(iIndex, trig);

        trig.color[0] = r;
        trig.color[1] = g;
        trig.color[2] = b;
        trig.color[3] = a;

        g_alClientTriggers[client].SetArray(iIndex, trig);
    }

    UpdateHookState();
}

void ResetEntityColorForClient(int client, int entity)
{
    int iIndex = GetEntityIndexForClient(client, entity);
    if (iIndex == -1)
    {
        return;
    }

    IndividualTrigger trig;
    g_alClientTriggers[client].GetArray(iIndex, trig);

    trig.color[0] = -1;
    trig.color[1] = -1;
    trig.color[2] = -1;
    trig.color[3] = -1;

    g_alClientTriggers[client].SetArray(iIndex, trig);
}

// ============================================================================
// color management
// ============================================================================

void InitClientColors(int client)
{
    for (int i = 0; i < MAX_TYPES; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            g_iColors[client][i][j] = g_iDefaultColors[i][j];
        }
    }

    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        for (int j = 0; j < 4; j++)
        {
            g_iColorsSpecial[client][i][j] = g_iDefaultColorsSpecial[i][j];
        }
    }
}

void LoadClientColors(int client)
{
    char szCookieValue[24];

    for (int i = 0; i < MAX_TYPES; i++)
    {
        if (g_hColorCookie[i] == null)
        {
            continue;
        }

        g_hColorCookie[i].Get(client, szCookieValue, sizeof(szCookieValue));
        if (szCookieValue[0] != '\0')
        {
            ParseColorString(szCookieValue, g_iColors[client][i]);
        }
    }

    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        if (g_hColorCookieSpecial[i] == null)
        {
            continue;
        }

        g_hColorCookieSpecial[i].Get(client, szCookieValue, sizeof(szCookieValue));
        if (szCookieValue[0] != '\0')
        {
            ParseColorString(szCookieValue, g_iColorsSpecial[client][i]);
        }
    }
}

void ParseColorString(const char[] szInput, int iColor[4])
{
    char szParts[4][8];
    int iParts = ExplodeString(szInput, ",", szParts, 4, 8);

    if (iParts >= 3)
    {
        iColor[0] = ClampColor(StringToInt(szParts[0]));
        iColor[1] = ClampColor(StringToInt(szParts[1]));
        iColor[2] = ClampColor(StringToInt(szParts[2]));
        iColor[3] = (iParts >= 4) ? ClampColor(StringToInt(szParts[3])) : 255;
    }
}

void SaveClientColor(int client, int iTriggerType)
{
    if (iTriggerType < 0 || iTriggerType >= MAX_TYPES || g_hColorCookie[iTriggerType] == null)
    {
        return;
    }

    char szValue[24];
    FormatEx(szValue, sizeof(szValue), "%d,%d,%d,%d",
        g_iColors[client][iTriggerType][0],
        g_iColors[client][iTriggerType][1],
        g_iColors[client][iTriggerType][2],
        g_iColors[client][iTriggerType][3]);

    g_hColorCookie[iTriggerType].Set(client, szValue);
}

void SaveClientSpecialColor(int client, int iColorType)
{
    if (iColorType < 0 || iColorType >= view_as<int>(TM_MAX) || g_hColorCookieSpecial[iColorType] == null)
    {
        return;
    }

    char szValue[24];
    FormatEx(szValue, sizeof(szValue), "%d,%d,%d,%d",
        g_iColorsSpecial[client][iColorType][0],
        g_iColorsSpecial[client][iColorType][1],
        g_iColorsSpecial[client][iColorType][2],
        g_iColorsSpecial[client][iColorType][3]);

    g_hColorCookieSpecial[iColorType].Set(client, szValue);
}

// ============================================================================
// display mode & opacity
// ============================================================================

void ApplyClientOpacity(int client, int iAlpha)
{
    for (int i = 0; i < MAX_TYPES; i++)
    {
        g_iColors[client][i][3] = iAlpha;
        SaveClientColor(client, i);
    }
    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        g_iColorsSpecial[client][i][3] = iAlpha;
        SaveClientSpecialColor(client, i);
    }
}

TriggerDisplayMode NormalizeDisplayMode(TriggerDisplayMode mode)
{
    // outline modes are disabled; force solid.
    if (mode != DISPLAY_SOLID)
    {
        return DISPLAY_SOLID;
    }
    return mode;
}

void SaveClientDisplayMode(int client)
{
    if (g_hDisplayModeCookie == null)
    {
        return;
    }

    char szValue[8];
    IntToString(view_as<int>(g_eDisplayMode[client]), szValue, sizeof(szValue));
    g_hDisplayModeCookie.Set(client, szValue);
}

void LoadClientDisplayMode(int client)
{
    if (g_hDisplayModeCookie == null)
    {
        return;
    }

    char szValue[8];
    g_hDisplayModeCookie.Get(client, szValue, sizeof(szValue));
    if (szValue[0] == '\0')
    {
        return;
    }

    int iMode = StringToInt(szValue);
    if (iMode >= view_as<int>(DISPLAY_SOLID) && iMode <= view_as<int>(DISPLAY_BOTH))
    {
        TriggerDisplayMode normalized = NormalizeDisplayMode(view_as<TriggerDisplayMode>(iMode));
        g_eDisplayMode[client] = normalized;
        if (normalized != view_as<TriggerDisplayMode>(iMode))
        {
            SaveClientDisplayMode(client);
        }
    }
}

// ============================================================================
// beam outline rendering
// ============================================================================

void StartBeamTimer()
{
    if (g_hBeamTimer != null)
    {
        return;
    }

    g_hBeamTimer = CreateTimer(BEAM_INTERVAL, Timer_BeamOutlines, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopBeamTimer()
{
    if (g_hBeamTimer == null)
    {
        return;
    }

    CloseHandle(g_hBeamTimer);
    g_hBeamTimer = null;
}

Action Timer_BeamOutlines(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client))
        {
            continue;
        }

        if (g_eDisplayMode[client] == DISPLAY_SOLID)
        {
            continue;
        }

        if (!ClientHasEnabledTriggers(client))
        {
            continue;
        }

        float eyePos[3];
        GetClientEyePosition(client, eyePos);

        for (int ent = MaxClients + 1; ent <= 2048; ent++)
        {
            if (!IsValidEntity(ent))
            {
                continue;
            }

            int color[4];
            if (!GetTriggerColorForClient(client, ent, color))
            {
                continue;
            }

            float origin[3];
            GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
            if (GetVectorDistance(eyePos, origin) > OUTLINE_MAX_DIST)
            {
                continue;
            }

            DrawEntityOutline(client, ent, color);
        }
    }

    return Plugin_Continue;
}

void DrawEntityOutline(int client, int entity, const int color[4])
{
    if (g_iBeamSprite == -1)
    {
        return;
    }

    float origin[3], mins[3], maxs[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

    for (int i = 0; i < 3; i++)
    {
        mins[i] += origin[i];
        maxs[i] += origin[i];
    }

    float v[8][3];
    v[0][0] = mins[0]; v[0][1] = mins[1]; v[0][2] = mins[2];
    v[1][0] = maxs[0]; v[1][1] = mins[1]; v[1][2] = mins[2];
    v[2][0] = maxs[0]; v[2][1] = maxs[1]; v[2][2] = mins[2];
    v[3][0] = mins[0]; v[3][1] = maxs[1]; v[3][2] = mins[2];
    v[4][0] = mins[0]; v[4][1] = mins[1]; v[4][2] = maxs[2];
    v[5][0] = maxs[0]; v[5][1] = mins[1]; v[5][2] = maxs[2];
    v[6][0] = maxs[0]; v[6][1] = maxs[1]; v[6][2] = maxs[2];
    v[7][0] = mins[0]; v[7][1] = maxs[1]; v[7][2] = maxs[2];

    SendBeam(client, v[0], v[1], color);
    SendBeam(client, v[1], v[2], color);
    SendBeam(client, v[2], v[3], color);
    SendBeam(client, v[3], v[0], color);

    SendBeam(client, v[4], v[5], color);
    SendBeam(client, v[5], v[6], color);
    SendBeam(client, v[6], v[7], color);
    SendBeam(client, v[7], v[4], color);

    SendBeam(client, v[0], v[4], color);
    SendBeam(client, v[1], v[5], color);
    SendBeam(client, v[2], v[6], color);
    SendBeam(client, v[3], v[7], color);
}

void SendBeam(int client, const float start[3], const float end[3], const int color[4])
{
    int clients[1];
    clients[0] = client;

    TE_SetupBeamPoints(start, end, g_iBeamSprite, g_iBeamHalo, 0, 0, BEAM_LIFE,
        BEAM_WIDTH, BEAM_END_WIDTH, BEAM_FADE, BEAM_AMPLITUDE, color, BEAM_SPEED);
    TE_Send(clients, 1, 0.0);
}

// ============================================================================
// output cache helpers
// ============================================================================

ArrayList CollectOutputsFromEntry(EntityLumpEntry entry)
{
    ArrayList outputs = new ArrayList(sizeof(OutputInfo));
    char szOutput[256];

    for (int i = 0; i < sizeof(g_szOutputKeys); i++)
    {
        int pos = -1;
        while ((pos = entry.GetNextKey(g_szOutputKeys[i], szOutput, sizeof(szOutput), pos)) != -1)
        {
            OutputInfo info;
            strcopy(info.output, sizeof(info.output), g_szOutputKeys[i]);
            ParseOutputString(szOutput, info.target, sizeof(info.target), info.input, sizeof(info.input),
                info.param, sizeof(info.param), info.delay, info.once);
            outputs.PushArray(info);
        }
    }

    if (outputs.Length == 0)
    {
        delete outputs;
        return null;
    }

    return outputs;
}

void StoreHammerIdOutputs(int iHammerId, ArrayList outputs)
{
    if (outputs == null || outputs.Length == 0)
    {
        delete outputs;
        return;
    }

    if (g_smHammerIdToOutputs == null)
    {
        g_smHammerIdToOutputs = new StringMap();
    }

    char szKey[16];
    IntToString(iHammerId, szKey, sizeof(szKey));

    ArrayList existing;
    if (g_smHammerIdToOutputs.GetValue(szKey, existing))
    {
        delete existing;
    }

    g_smHammerIdToOutputs.SetValue(szKey, outputs);
}

void ClearHammerIdOutputs()
{
    if (g_smHammerIdToOutputs == null)
    {
        return;
    }

    StringMapSnapshot snap = g_smHammerIdToOutputs.Snapshot();
    char szKey[16];
    for (int i = 0; i < snap.Length; i++)
    {
        snap.GetKey(i, szKey, sizeof(szKey));
        ArrayList outputs;
        if (g_smHammerIdToOutputs.GetValue(szKey, outputs))
        {
            delete outputs;
        }
    }
    delete snap;

    delete g_smHammerIdToOutputs;
    g_smHammerIdToOutputs = null;
}

ArrayList GetOutputsForHammerId(int iHammerId)
{
    if (iHammerId <= 0 || g_smHammerIdToOutputs == null)
    {
        return null;
    }

    char szKey[16];
    IntToString(iHammerId, szKey, sizeof(szKey));

    ArrayList outputs;
    if (g_smHammerIdToOutputs.GetValue(szKey, outputs))
    {
        return outputs;
    }

    return null;
}

ArrayList CollectUniqueTargets(ArrayList outputs)
{
    if (outputs == null || outputs.Length == 0)
    {
        return null;
    }

    ArrayList targets = new ArrayList(ByteCountToCells(64));
    StringMap seen = new StringMap();

    for (int i = 0; i < outputs.Length; i++)
    {
        OutputInfo info;
        outputs.GetArray(i, info);

        if (info.target[0] == '\0')
        {
            continue;
        }

        int dummy;
        if (!seen.GetValue(info.target, dummy))
        {
            seen.SetValue(info.target, 1);
            targets.PushString(info.target);
        }
    }

    delete seen;
    return targets;
}

int CountEntitiesWithTargetname(const char[] szTarget)
{
    if (szTarget[0] == '\0')
    {
        return 0;
    }

    char szName[64];
    int count = 0;
    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntPropString(ent, Prop_Data, "m_iName", szName, sizeof(szName));
        if (szName[0] && StrEqual(szName, szTarget, false))
        {
            count++;
        }
    }
    return count;
}

void ParseOutputString(const char[] szOutput, char[] target, int targetLen, char[] input, int inputLen,
    char[] param, int paramLen, float &delay, int &once)
{
    char parts[5][128];
    int count = ExplodeString(szOutput, ",", parts, 5, 128);

    if (count >= 1)
    {
        strcopy(target, targetLen, parts[0]);
    }
    else
    {
        target[0] = '\0';
    }

    if (count >= 2)
    {
        strcopy(input, inputLen, parts[1]);
    }
    else
    {
        input[0] = '\0';
    }

    if (count >= 3)
    {
        strcopy(param, paramLen, parts[2]);
    }
    else
    {
        param[0] = '\0';
    }

    if (count >= 4)
    {
        delay = StringToFloat(parts[3]);
    }
    else
    {
        delay = 0.0;
    }

    if (count >= 5)
    {
        once = StringToInt(parts[4]);
    }
    else
    {
        once = 0;
    }
}

// ============================================================================
// utility functions
// ============================================================================

void SerializeColors(int client, char[] buffer, int maxlen)
{
    buffer[0] = '\0';
    char tmp[8];

    for (int i = 0; i < MAX_TYPES; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            FormatEx(tmp, sizeof(tmp), "%d", g_iColors[client][i][j]);
            if (buffer[0] != '\0')
            {
                StrCat(buffer, maxlen, ",");
            }
            StrCat(buffer, maxlen, tmp);
        }
    }
}

void SerializeColorsSpecial(int client, char[] buffer, int maxlen)
{
    buffer[0] = '\0';
    char tmp[8];

    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        for (int j = 0; j < 4; j++)
        {
            FormatEx(tmp, sizeof(tmp), "%d", g_iColorsSpecial[client][i][j]);
            if (buffer[0] != '\0')
            {
                StrCat(buffer, maxlen, ",");
            }
            StrCat(buffer, maxlen, tmp);
        }
    }
}

void SerializeIndividual(int client, char[] buffer, int maxlen)
{
    buffer[0] = '\0';
    if (g_alClientTriggers[client] == null || g_alClientTriggers[client].Length == 0)
    {
        return;
    }

    char entry[64];
    for (int i = 0; i < g_alClientTriggers[client].Length; i++)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(i, trig);

        int ent = EntRefToEntIndex(trig.entRef);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
        {
            continue;
        }

        int hammerId = GetEntProp(ent, Prop_Data, "m_iHammerID");
        if (hammerId <= 0)
        {
            continue;
        }

        FormatEx(entry, sizeof(entry), "%d:%d:%d:%d:%d",
            hammerId, trig.color[0], trig.color[1], trig.color[2], trig.color[3]);

        int curLen = strlen(buffer);
        int addLen = strlen(entry) + 1;
        if (curLen + addLen >= maxlen)
        {
            break;
        }

        if (curLen > 0)
        {
            StrCat(buffer, maxlen, ";");
        }
        StrCat(buffer, maxlen, entry);
    }
}

int GetClientTypeMask(int client)
{
    int mask = 0;
    for (int i = 0; i < MAX_TYPES; i++)
    {
        if (g_bTypeEnabled[client][i])
        {
            mask |= (1 << i);
        }
    }
    return mask;
}

void ApplyTypeMask(int client, int mask)
{
    if (mask == TYPE_MASK_UNSET)
    {
        return;
    }

    for (int i = 0; i < MAX_TYPES; i++)
    {
        g_bTypeEnabled[client][i] = ((mask & (1 << i)) != 0);
    }
}

void DeserializeColors(const char[] buffer, int colors[MAX_TYPES][4])
{
    char parts[32][8];
    int count = ExplodeString(buffer, ",", parts, sizeof(parts), sizeof(parts[]));
    int idx = 0;

    for (int i = 0; i < MAX_TYPES; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            if (idx >= count)
            {
                return;
            }
            colors[i][j] = ClampColor(StringToInt(parts[idx++]));
        }
    }
}

void DeserializeColorsSpecial(const char[] buffer, int colors[TM_MAX][4])
{
    char parts[32][8];
    int count = ExplodeString(buffer, ",", parts, sizeof(parts), sizeof(parts[]));
    int idx = 0;

    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        for (int j = 0; j < 4; j++)
        {
            if (idx >= count)
            {
                return;
            }
            colors[i][j] = ClampColor(StringToInt(parts[idx++]));
        }
    }
}

void DeserializeIndividual(int client, const char[] buffer)
{
    if (g_alClientTriggers[client] == null)
    {
        g_alClientTriggers[client] = new ArrayList(sizeof(IndividualTrigger));
    }
    else
    {
        g_alClientTriggers[client].Clear();
    }

    if (buffer[0] == '\0')
    {
        return;
    }

    char entry[64];
    int len = strlen(buffer);
    int epos = 0;

    for (int i = 0; i <= len; i++)
    {
        char c = buffer[i];
        if (c == ';' || c == '\0')
        {
            if (epos > 0)
            {
                entry[epos] = '\0';
                ParseIndividualEntry(client, entry);
                epos = 0;
            }
        }
        else if (epos < sizeof(entry) - 1)
        {
            entry[epos++] = c;
        }
    }
}

void EscapeStringSafe(const char[] input, char[] output, int maxlen)
{
    if (g_hDatabase == null)
    {
        strcopy(output, maxlen, input);
        return;
    }
    SQL_EscapeString(g_hDatabase, input, output, maxlen);
}

void ApplyProfileToClient(int client, int mode, int typeMask, const char[] colors, const char[] colorsSpecial, const char[] indivData)
{
    DeserializeColors(colors, g_iColors[client]);
    DeserializeColorsSpecial(colorsSpecial, g_iColorsSpecial[client]);

    if (mode >= view_as<int>(DISPLAY_SOLID) && mode <= view_as<int>(DISPLAY_BOTH))
    {
        g_eDisplayMode[client] = NormalizeDisplayMode(view_as<TriggerDisplayMode>(mode));
    }

    ApplyTypeMask(client, typeMask);

    DeserializeIndividual(client, indivData);

    for (int i = 0; i < MAX_TYPES; i++)
    {
        SaveClientColor(client, i);
    }
    for (int i = 0; i < view_as<int>(TM_MAX); i++)
    {
        SaveClientSpecialColor(client, i);
    }
    SaveClientDisplayMode(client);
    UpdateHookState();
}

void QueueProfileSave(int client, const char[] name, const char[] steamid, const char[] map, bool bPublic,
    int mode, int typeMask, const char[] colors, const char[] colorsSpecial, const char[] indivData, const char[] message)
{
    if (g_hDatabase == null)
    {
        return;
    }

    char escName[128], escSteam[96], escMap[96], escColors[512], escColorsSpecial[512], escIndiv[PROFILE_INDIV_MAX * 2];
    EscapeStringSafe(name, escName, sizeof(escName));
    EscapeStringSafe(steamid, escSteam, sizeof(escSteam));
    EscapeStringSafe(map, escMap, sizeof(escMap));
    EscapeStringSafe(colors, escColors, sizeof(escColors));
    EscapeStringSafe(colorsSpecial, escColorsSpecial, sizeof(escColorsSpecial));
    EscapeStringSafe(indivData, escIndiv, sizeof(escIndiv));

    char query[4096];
    FormatEx(query, sizeof(query), "INSERT OR REPLACE INTO st_profiles (steamid, map, name, public, display_mode, type_mask, colors, colors_special, indiv_data, updated_at) VALUES ('%s','%s','%s',%d,%d,%d,'%s','%s','%s',strftime('%%s','now'));",
        escSteam, escMap, escName, bPublic ? 1 : 0, mode, typeMask, escColors, escColorsSpecial, escIndiv);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteString(message);
    SQL_TQuery(g_hDatabase, OnProfileSave, query, pack);
}

void ParseIndividualEntry(int client, const char[] entry)
{
    char parts[5][16];
    int count = ExplodeString(entry, ":", parts, 5, 16);
    if (count < 1)
    {
        return;
    }

    int hammerId = StringToInt(parts[0]);
    if (hammerId <= 0)
    {
        return;
    }

    int ent = GetTriggerEntityByHammerId(hammerId);
    if (ent == -1)
    {
        return;
    }

    IndividualTrigger trig;
    trig.entRef = EntIndexToEntRef(ent);
    trig.color[0] = -1;
    trig.color[1] = -1;
    trig.color[2] = -1;
    trig.color[3] = -1;

    if (count >= 5)
    {
        trig.color[0] = StringToInt(parts[1]);
        trig.color[1] = StringToInt(parts[2]);
        trig.color[2] = StringToInt(parts[3]);
        trig.color[3] = StringToInt(parts[4]);
    }

    int idx = GetEntityIndexForClient(client, ent);
    if (idx == -1)
    {
        g_alClientTriggers[client].PushArray(trig);
    }
    else
    {
        g_alClientTriggers[client].SetArray(idx, trig);
    }
}

int GetTriggerEntityByHammerId(int hammerId)
{
    if (hammerId <= 0)
    {
        return -1;
    }

    char szClass[64];
    for (int ent = MaxClients + 1; ent <= 2048; ent++)
    {
        if (!IsValidEntity(ent))
        {
            continue;
        }

        GetEntityClassname(ent, szClass, sizeof(szClass));
        if (GetTriggerType(szClass) == -1)
        {
            continue;
        }

        if (GetEntProp(ent, Prop_Data, "m_iHammerID") == hammerId)
        {
            return ent;
        }
    }
    return -1;
}

// ============================================================================
// profile db callbacks
// ============================================================================

public void OnProfileSave(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int userid = pack.ReadCell();
    char message[96];
    pack.ReadString(message, sizeof(message));
    delete pack;

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    if (error[0] != '\0')
    {
        PrintToChat(client, "[st] profile save failed: %s", error);
        return;
    }

    PrintToChat(client, "[st] %s", message);
}

public void OnProfileLoad(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int userid = pack.ReadCell();
    bool bPublic = pack.ReadCell() == 1;
    char szName[64];
    pack.ReadString(szName, sizeof(szName));
    delete pack;

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    if (error[0] != '\0' || hndl == null)
    {
        PrintToChat(client, "[st] profile load failed: %s", error);
        return;
    }

    if (!SQL_FetchRow(hndl))
    {
        PrintToChat(client, "[st] no %sprofile found: %s", bPublic ? "public " : "", szName);
        return;
    }

    int mode = SQL_FetchInt(hndl, 0);
    int typeMask = SQL_FetchInt(hndl, 1);
    char colors[256];
    char colorsSpecial[256];
    char indivData[PROFILE_INDIV_MAX];
    SQL_FetchString(hndl, 2, colors, sizeof(colors));
    SQL_FetchString(hndl, 3, colorsSpecial, sizeof(colorsSpecial));
    SQL_FetchString(hndl, 4, indivData, sizeof(indivData));

    ApplyProfileToClient(client, mode, typeMask, colors, colorsSpecial, indivData);

    PrintToChat(client, "[st] loaded %sprofile: %s", bPublic ? "public " : "", szName);
}

public void OnProfileCopy(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int userid = pack.ReadCell();
    bool bPublic = pack.ReadCell() == 1;
    char szNewName[64];
    pack.ReadString(szNewName, sizeof(szNewName));
    delete pack;

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    if (error[0] != '\0' || hndl == null)
    {
        PrintToChat(client, "[st] profile copy failed: %s", error);
        return;
    }

    if (!SQL_FetchRow(hndl))
    {
        PrintToChat(client, "[st] source profile not found.");
        return;
    }

    int mode = SQL_FetchInt(hndl, 0);
    int typeMask = SQL_FetchInt(hndl, 1);
    char colors[256];
    char colorsSpecial[256];
    char indivData[PROFILE_INDIV_MAX];
    SQL_FetchString(hndl, 2, colors, sizeof(colors));
    SQL_FetchString(hndl, 3, colorsSpecial, sizeof(colorsSpecial));
    SQL_FetchString(hndl, 4, indivData, sizeof(indivData));

    ApplyProfileToClient(client, mode, typeMask, colors, colorsSpecial, indivData);
    int saveMask = (typeMask == TYPE_MASK_UNSET) ? GetClientTypeMask(client) : typeMask;

    char szSteamId[64];
    if (!GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId)))
    {
        strcopy(szSteamId, sizeof(szSteamId), "unknown");
    }

    char szMap[64];
    GetCurrentMap(szMap, sizeof(szMap));

    QueueProfileSave(client, szNewName, szSteamId, szMap, bPublic, mode, saveMask, colors, colorsSpecial, indivData,
        "profile copied to current map.");
}

public void OnProfileList(Handle owner, Handle hndl, const char[] error, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int userid = pack.ReadCell();
    bool bPublic = pack.ReadCell() == 1;
    delete pack;

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    if (error[0] != '\0' || hndl == null)
    {
        PrintToChat(client, "[st] profile list failed: %s", error);
        return;
    }

    int count = 0;
    char name[64];
    if (bPublic)
    {
        char ownerName[64];
        while (SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 0, name, sizeof(name));
            SQL_FetchString(hndl, 1, ownerName, sizeof(ownerName));
            PrintToChat(client, "[st] public: %s (by %s)", name, ownerName);
            count++;
        }
    }
    else
    {
        int pub;
        while (SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 0, name, sizeof(name));
            pub = SQL_FetchInt(hndl, 1);
            PrintToChat(client, "[st] %s%s", name, pub ? " [public]" : "");
            count++;
        }
    }

    if (count == 0)
    {
        PrintToChat(client, "[st] no %sprofiles found.", bPublic ? "public " : "");
    }
}

void AddInfoLine(Menu menu, int &line, const char[] fmt, any ...)
{
    char buffer[192];
    VFormat(buffer, sizeof(buffer), fmt, 4);

    char info[8];
    IntToString(line++, info, sizeof(info));
    menu.AddItem(info, buffer, ITEMDRAW_DISABLED);
}

void PruneEntRefList(ArrayList list)
{
    if (list == null)
    {
        return;
    }

    for (int i = list.Length - 1; i >= 0; i--)
    {
        int ent = EntRefToEntIndex(list.Get(i));
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
        {
            list.Erase(i);
        }
    }
}

void PruneClientTriggers(int client)
{
    if (g_alClientTriggers[client] == null)
    {
        return;
    }

    for (int i = g_alClientTriggers[client].Length - 1; i >= 0; i--)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(i, trig);
        int ent = EntRefToEntIndex(trig.entRef);
        if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent))
        {
            g_alClientTriggers[client].Erase(i);
        }
    }
}

bool ClientHasEnabledTriggers(int client)
{
    for (int t = 0; t < MAX_TYPES; t++)
    {
        if (g_bTypeEnabled[client][t])
        {
            return true;
        }
    }

    PruneClientTriggers(client);
    return (g_alClientTriggers[client] != null && g_alClientTriggers[client].Length > 0);
}

bool GetTriggerColorForClient(int client, int entity, int color[4])
{
    char szClassName[64];
    GetEntityClassname(entity, szClassName, sizeof(szClassName));

    int iType = GetTriggerType(szClassName);
    if (iType == -1)
    {
        return false;
    }

    int iIndivIndex = GetEntityIndexForClient(client, entity);
    bool bIndividualEnabled = (iIndivIndex != -1);
    bool bTypeEnabled = g_bTypeEnabled[client][iType];

    if (!bIndividualEnabled && !bTypeEnabled)
    {
        return false;
    }

    if (bIndividualEnabled)
    {
        IndividualTrigger trig;
        g_alClientTriggers[client].GetArray(iIndivIndex, trig);

        if (trig.color[0] >= 0)
        {
            color[0] = trig.color[0];
            color[1] = trig.color[1];
            color[2] = trig.color[2];
            color[3] = trig.color[3];
            return true;
        }
    }

    if (iType == TRIGGER_MULTIPLE)
    {
        TriggerMultipleType eSubType = g_eTriggerMultipleType[entity];
        color[0] = g_iColorsSpecial[client][eSubType][0];
        color[1] = g_iColorsSpecial[client][eSubType][1];
        color[2] = g_iColorsSpecial[client][eSubType][2];
        color[3] = g_iColorsSpecial[client][eSubType][3];
    }
    else
    {
        color[0] = g_iColors[client][iType][0];
        color[1] = g_iColors[client][iType][1];
        color[2] = g_iColors[client][iType][2];
        color[3] = g_iColors[client][iType][3];
    }

    return true;
}

int FindTriggerInCrosshair(int client)
{
    float eyePos[3], eyeAng[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);

    ArrayList candidates = new ArrayList();
    TR_EnumerateEntities(eyePos, eyeAng, PARTITION_TRIGGER_EDICTS, RayType_Infinite, TraceEnum_TriggerCandidates, candidates);

    int bestEnt = -1;
    float bestFrac = 1.0;

    for (int i = 0; i < candidates.Length; i++)
    {
        int ent = candidates.Get(i);
        if (ent == INVALID_ENT_REFERENCE || ent <= 0 || !IsValidEntity(ent))
        {
            continue;
        }

        TR_ClipRayToEntity(eyePos, eyeAng, MASK_ALL, RayType_Infinite, ent);
        bool bStartSolid = TR_StartSolid();
        if (!TR_DidHit() && !bStartSolid)
        {
            continue;
        }

        float frac = bStartSolid ? 0.0 : TR_GetFraction();
        if (frac < bestFrac)
        {
            bestFrac = frac;
            bestEnt = ent;
            if (bestFrac <= 0.0)
            {
                break;
            }
        }
    }

    delete candidates;
    return bestEnt;
}

public bool TraceEnum_TriggerCandidates(int entity, any data)
{
    if (entity <= 0 || entity <= MaxClients)
    {
        return true;
    }

    if (!IsValidEntity(entity))
    {
        return true;
    }

    char szClassName[64];
    GetEntityClassname(entity, szClassName, sizeof(szClassName));
    if (GetTriggerType(szClassName) == -1)
    {
        return true;
    }

    ArrayList list = view_as<ArrayList>(data);
    if (list != null)
    {
        list.Push(entity);
    }
    return true;
}

int GetTriggerType(const char[] szClassName)
{
    for (int i = 0; i < MAX_TYPES; i++)
    {
        if (StrEqual(szClassName, g_szTriggerNames[i]))
        {
            return i;
        }
    }
    return -1;
}

int ClampColor(int value)
{
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
}

bool IsValidClient(int client)
{
    return (client > 0 &&
            client <= MaxClients &&
            IsClientConnected(client) &&
            IsClientInGame(client) &&
            !IsFakeClient(client));
}
