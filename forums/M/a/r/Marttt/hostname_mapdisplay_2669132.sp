// ====================================================================================================
// File
// ====================================================================================================
#file "hostname_mapdisplay.sp"

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                  "[ANY] Hostname - Display Map Name"
#define PLUGIN_AUTHOR                "Mart"
#define PLUGIN_DESCRIPTION           "Displays the specified map name in the hostname."
#define PLUGIN_VERSION               "1.0.1"
#define PLUGIN_URL                   "https://forums.alliedmods.net/showthread.php?t=319046"

/*
// ====================================================================================================
Change Log:
1.0.1 (20-November-2019)
    - Added support to {gamemode} and {GAMEMODE} tags. {GAMEMODE} will upper case the gamemode string. (e.g.: coop => COOP)
    - Updated the structure of the KeyValue file located at data folder.
    - Added "hostname" and "format" configs through a new section ("Host") in the KeyValue file to support Unicode texts (thanks to "water19753" for the report).

1.0.0 (07-October-2019)
    - Initial release.
*/

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>

// ====================================================================================================
// Defines
// ====================================================================================================
#define CVAR_FLAGS                   FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION    FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define CONFIG_FILENAME              "hostname_mapdisplay"

#define KEYVALUE_FILENAME            "hostname_mapdisplay"
#define KEYVALUE_ROOTNAME            "Settings"
#define KEYVALUE_MAP                 "Map"
#define KEYVALUE_HOST                "Host"
#define KEYVALUE_HOST_HOSTNAME       "hostname"
#define KEYVALUE_HOST_FORMAT         "format"

// ====================================================================================================
// Plugin Cvar Handles
// ====================================================================================================
static Handle hCvar_MPGameMode = INVALID_HANDLE;
static Handle hCvar_Enabled = INVALID_HANDLE;
static Handle hCvar_HostName = INVALID_HANDLE;
static Handle hCvar_HostNameFormat = INVALID_HANDLE;
static Handle hCvar_MapNotFound = INVALID_HANDLE;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
static bool   bCvar_Enabled;
static bool   bCvar_MapNotFound;
static bool   bUseHostName_txt;
static bool   bUseHostNameFormat_txt;

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
static char   sCvar_DefaultHostName[256];
static char   sCvar_CurrentGameMode[256];
static char   sCvar_CurrentGameModeUpper[256];
static char   sCvar_HostName[256];
static char   sCvar_HostNameFormat[256];
static char   sHostName_txt[256];
static char   sHostNameFormat_txt[256];
static char   sNewHostName[256];
static char   sMapDevName[256];
static char   sMapName[256];
static char   sDataPath[PLATFORM_MAX_PATH];

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    BuildPath(Path_SM, sDataPath, PLATFORM_MAX_PATH, "data/%s.txt", KEYVALUE_FILENAME);

    GetConVarString(FindConVar("hostname"), sCvar_DefaultHostName, sizeof(sCvar_DefaultHostName));
    hCvar_MPGameMode = FindConVar("mp_gamemode");

    CreateConVar("hostname_mapdisplay_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    hCvar_Enabled        = CreateConVar("hostname_mapdisplay_enabled", "1", "Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    hCvar_HostName       = CreateConVar("hostname_mapdisplay_hostname", sCvar_DefaultHostName, "Hostname used by the {hostname} tag.\nNote: If the \"hostname\" attribute is set in the KeyValue file located at data folder, this cvar will be ignored.", CVAR_FLAGS);
    hCvar_HostNameFormat = CreateConVar("hostname_mapdisplay_format", "{hostname} | {GAMEMODE} | {mapname}", "Display format.\nAvailable tags: {hostname},{mapname},{gamemode},{GAMEMODE}\nNote: If the \"format\" attribute is set in the KeyValue file located at data folder, this cvar will be ignored.", CVAR_FLAGS);
    hCvar_MapNotFound    = CreateConVar("hostname_mapdisplay_mapnotfound", "0", "Enables/Disables the plugin when the map is not found in the KeyValue file located at data folder. 0 = OFF, 1 = ON (shows the map dev name).", CVAR_FLAGS, true, 0.0, true, 1.0);

    HookConVarChange(hCvar_MPGameMode, Event_ConVarChanged);
    HookConVarChange(hCvar_Enabled, Event_ConVarChanged);
    HookConVarChange(hCvar_HostName, Event_ConVarChanged);
    HookConVarChange(hCvar_HostNameFormat, Event_ConVarChanged);
    HookConVarChange(hCvar_MapNotFound, Event_ConVarChanged);
    HookConVarChange(hCvar_MapNotFound, Event_ConVarChanged);

    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_hostname_mapdisplay_reload", AdmCmdReload, ADMFLAG_ROOT, "Reloads the hostname based on a KeyValue file located at data folder.");
    RegAdminCmd("sm_hostname_mapdisplay_print_cvars", AdmCmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

// ====================================================================================================
// ConVars
// ====================================================================================================
void Event_ConVarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();
}

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    GetConVarString(hCvar_MPGameMode, sCvar_CurrentGameMode, sizeof(sCvar_CurrentGameMode));
    String_ToUpper(sCvar_CurrentGameMode, sCvar_CurrentGameModeUpper, sizeof(sCvar_CurrentGameModeUpper));
    GetCurrentMap(sMapDevName, sizeof(sMapDevName));

    bCvar_Enabled = GetConVarBool(hCvar_Enabled);
    GetConVarString(hCvar_HostName, sCvar_HostName, sizeof(sCvar_HostName));
    TrimString(sCvar_HostName);
    GetConVarString(hCvar_HostNameFormat, sCvar_HostNameFormat, sizeof(sCvar_HostNameFormat));
    TrimString(sCvar_HostNameFormat);
    bCvar_MapNotFound = GetConVarBool(hCvar_MapNotFound);

    ChangeHostName();
}

/****************************************************************************************************/
void ChangeHostName()
{
    KeyValues kv = new KeyValues(KEYVALUE_ROOTNAME);
    kv.ImportFromFile(sDataPath);
    
    kv.JumpToKey(KEYVALUE_HOST);
    kv.GetString(KEYVALUE_HOST_HOSTNAME, sHostName_txt, sizeof(sHostName_txt));
    TrimString(sHostName_txt);
    kv.GetString(KEYVALUE_HOST_FORMAT, sHostNameFormat_txt, sizeof(sHostNameFormat_txt));
    TrimString(sHostNameFormat_txt);
    kv.GoBack();
    
    kv.JumpToKey(KEYVALUE_MAP);
    kv.GetString(sMapDevName, sMapName, sizeof(sMapName));
    delete kv;
    
    bUseHostName_txt = (sHostName_txt[0] != '\0');
    bUseHostNameFormat_txt = (sHostNameFormat_txt[0] != '\0');
    strcopy(sNewHostName, sizeof(sNewHostName), bUseHostNameFormat_txt ? sHostNameFormat_txt : sCvar_HostNameFormat);

    if(sMapName[0] != '\0')
    {
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{hostname}", bUseHostName_txt ? sHostName_txt : sCvar_HostName, false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{mapname}", sMapName, false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{GAMEMODE}", sCvar_CurrentGameModeUpper, true);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{gamemode}", sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", sNewHostName);
        return;
    }
    else if (bCvar_MapNotFound)
    {
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{hostname}", bUseHostName_txt ? sHostName_txt : sCvar_HostName, false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{mapname}", sMapDevName, false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{GAMEMODE}", sCvar_CurrentGameModeUpper, true);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{gamemode}", sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", sNewHostName);
        return;
    }
    else
    {
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{hostname}", bUseHostName_txt ? sHostName_txt : sCvar_HostName, false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{mapname}", "", false);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{GAMEMODE}", sCvar_CurrentGameModeUpper, true);
        ReplaceString(sNewHostName, sizeof(sNewHostName), "{gamemode}", sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", sNewHostName);
        return;
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action AdmCmdReload(int client, int args)
{
    ChangeHostName();
    
    PrintToChat(client, "*hostname_mapdisplay* KeyValue file reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action AdmCmdPrintCvars(int client, int args)
{
    char sHostnameNow[256];
    GetConVarString(FindConVar("hostname"), sHostnameNow, sizeof(sHostnameNow));

    PrintToConsole(client, "");
    PrintToConsole(client, "================================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------- Plugin Cvars (hostname_mapdisplay) ----------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "hostname_mapdisplay_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "hostname_mapdisplay_enabled : %b (%s)", bCvar_Enabled, bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "hostname_mapdisplay_hostname : %s %s", sCvar_HostName, bUseHostName_txt ? "<ignored because of txt file>" : "");
    PrintToConsole(client, "hostname_mapdisplay_format : %s %s", sCvar_HostNameFormat, bUseHostNameFormat_txt ? "<ignored because of txt file>" : "");
    PrintToConsole(client, "hostname_mapdisplay_mapnotfound : %b (%s)", bCvar_MapNotFound, bCvar_MapNotFound ? "true" : "false");
    PrintToConsole(client, "--------------------------------------------------------------------------------");
    PrintToConsole(client, "mp_gamemode : %s", sCvar_CurrentGameMode);
    PrintToConsole(client, "Map : %s", sMapDevName);
    PrintToConsole(client, "Map name (txt) : %s", sMapName[0] == '\0' ? "<not found>" : sMapName);
    PrintToConsole(client, "Using txt hostname? : %b (%s)", bUseHostName_txt, bUseHostName_txt ? "true" : "false");
    PrintToConsole(client, "Hostname (txt) : %s", sHostName_txt[0] == '\0' ? "<empty>" : sHostName_txt);
    PrintToConsole(client, "Using txt hostname format? : %b (%s)", bUseHostNameFormat_txt, bUseHostNameFormat_txt ? "true" : "false");
    PrintToConsole(client, "Format (txt) : %s", sHostNameFormat_txt[0] == '\0' ? "<empty>" : sHostNameFormat_txt);
    PrintToConsole(client, "--------------------------------------------------------------------------------");
    PrintToConsole(client, "Hostname displaying as : %s", sHostnameNow);
    PrintToConsole(client, "");
    PrintToConsole(client, "================================================================================");
    PrintToConsole(client, "");
    return Plugin_Handled;
}

// Code snippet from SMLIB
/**
 * Converts the whole String to upper case.
 * Only works with alphabetical characters (not öäü) because Sourcemod suxx !
 * The Output String can be the same as the Input String.
 *
 * @param input                Input String.
 * @param output            Output String.
 * @param size                Max Size of the Output String
 * @noreturn
 */
stock void String_ToUpper(const char[] input, char[] output, int size)
{
    size--;

    int i = 0;
    while (input[i] != '\0' && i < size) {
        output[i] = CharToUpper(input[i]);
        i++;
    }

    output[i] = '\0';
}