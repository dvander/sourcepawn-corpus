/*
 * SourceMod April Fools Plugin Created by shapeshifter
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

// ConVars
ConVar g_cEnableAprilFools = null;
ConVar g_cLogType = null;
ConVar g_cLogPath = null;
ConVar g_cDatabaseName = null;
ConVar g_cJoinMessage = null;
ConVar g_cCommandName = null;
ConVar g_cAprilFoolsMessage = null;
ConVar g_cDisplayTime = null;
ConVar g_cDateCheck = null;
ConVar g_cEnableDateTimestamp = null;
ConVar g_cDisableDateTimestamp = null;
ConVar g_cDisplayAprilFoolsMenu = null;
ConVar g_cAprilFoolsMenuTitle = null;

// ConVar Values
bool g_bEnableAprilFools;
int g_iLogType;
char g_sLogPath[PLATFORM_MAX_PATH + 1];
char g_sDatabaseName[MAX_NAME_LENGTH];
char g_sJoinMessage[1024];
char g_sCommandName[64];
char g_sAprilFoolsMessage[1024];
float g_fDisplayTime;
bool g_bDateCheck;
int g_iEnableDateTimestamp;
int g_iDisableDateTimestamp;
bool g_bDisplayAprilFoolsMenu;
char g_sAprilFoolsMenuTitle[1024];

// Global Variables
int g_iFooled[MAXPLAYERS + 1] = 0;
int g_iFooledTotal = 0;
int g_iFooledTotalLastCheck = 0;

Handle DisplayMessageTimer[MAXPLAYERS + 1];

Database g_Database = null;

public Plugin myinfo =
{
    name = "April Fools",
    author = "shapeshifter",
    description = "Fool your players. Supports logging with MySQL or Flat File.",
    version = "1.1",
    url = "https://forums.alliedmods.net/showthread.php?p=2688686"
};

public void OnPluginStart()
{
    g_cEnableAprilFools = CreateConVar("sm_af_enable", "1", "Enable the plugin? 0 = Disabled. 1 = Enabled(default).", _, true, 0.0, true, 1.0);
    HookConVarChange(g_cEnableAprilFools, ConVarChanged);
    
    g_cLogType = CreateConVar("sm_af_log_type", "1", "How would you like to store the data? 0 = Disabled 1 = Flat File(default). 2 = MySQL.", _, true, 0.0, true, 2.0);
    HookConVarChange(g_cLogType, ConVarChanged);
    
    g_cLogPath = CreateConVar("sm_af_log_path", "logs/april-fools.log", "Path to april-fools.log Must have sm_april_fools_log_type = 1");
    HookConVarChange(g_cLogPath, ConVarChanged);
    
    g_cDatabaseName = CreateConVar("sm_af_mysql_database_name", "april_fools", "The database name entry in databases.cfg if using sm_april_fools_log_type = 2");
    HookConVarChange(g_cDatabaseName, ConVarChanged);
    
    g_cJoinMessage = CreateConVar("sm_af_join_message", "{default}You have connected as an {darkred}Admin{default}. Type {lightgreen}/acommands {default}for a list of commands.", "The April Fools message a player will see when they connect.");
    HookConVarChange(g_cJoinMessage, ConVarChanged);
    
    g_cCommandName = CreateConVar("sm_af_command_name", "acommands", "The command to trigger the april fools message");
    HookConVarChange(g_cCommandName, ConVarChanged);
    
    g_cAprilFoolsMessage = CreateConVar("sm_af_message", "{green}APRIL FOOLS! XD", "The message to display when someone triggers your command.");
    HookConVarChange(g_cAprilFoolsMessage, ConVarChanged);
    
    g_cDisplayTime = CreateConVar("sm_af_display_time", "16.0", "How many seconds after the player has connected should the message be displayed?");
    HookConVarChange(g_cDisplayTime, ConVarChanged);
    
    g_cDateCheck = CreateConVar("sm_af_date_check", "1", "Enable the plugin to automatically activate/deactivate for the date/time you specify. 0 = Disabled 1 = Enabled(default)", _, true, 0.0, true, 1.0);
    HookConVarChange(g_cDateCheck, ConVarChanged);
    
    g_cEnableDateTimestamp = CreateConVar("sm_af_enable_date_timestamp", "1585713600", "The date/time as a unix timestamp that you would like this plugin to begin working! Use epochconverter.com with your local time to get the correct time. 1585713600 = Wednesday, April 1, 2020 12:00:00 AM GMT-04:00 DST");
    HookConVarChange(g_cEnableDateTimestamp, ConVarChanged);
    
    g_cDisableDateTimestamp = CreateConVar("sm_af_disable_date_timestamp", "1585800000", "The date/time as a unix timestamp that you would like this plugin to be disabled! 1585800000 = Thursday, April 2, 2020 12:00:00 AM GMT-04:00 DST");
    HookConVarChange(g_cDisableDateTimestamp, ConVarChanged);
    
    g_cDisplayAprilFoolsMenu = CreateConVar("sm_af_display_menu", "1", "Display a menu before revealing its a joke? 0 = Disabled. 1 = Enabled(default).", _, true, 0.0, true, 1.0);
    HookConVarChange(g_cDisplayAprilFoolsMenu, ConVarChanged);
    
    g_cAprilFoolsMenuTitle = CreateConVar("sm_af_menu_title", "Admin Commands", "The title of the menu. Only required if sm_af_display_menu = 1");
    HookConVarChange(g_cAprilFoolsMenuTitle, ConVarChanged);
    
    AutoExecConfig(true, "april_fools");
    
    RegConsoleCmd("sm_fools", Command_FoolsCheck, "Check how many players have been fooled!");
}

public void OnConfigsExecuted()
{
    ForwardValues();
}

public void ConVarChanged(Handle hConVar, const char[] sOldValue, const char[] sNewValue)
{
    ForwardValues();
}

public void ForwardValues()
{
    g_bEnableAprilFools = GetConVarBool(g_cEnableAprilFools);
    g_iLogType = GetConVarInt(g_cLogType);
    GetConVarString(g_cLogPath, g_sLogPath, sizeof(g_sLogPath));
    GetConVarString(g_cDatabaseName, g_sDatabaseName, sizeof(g_sDatabaseName));
    GetConVarString(g_cJoinMessage, g_sJoinMessage, sizeof(g_sJoinMessage));
    GetConVarString(g_cCommandName, g_sCommandName, sizeof(g_sCommandName));
    GetConVarString(g_cAprilFoolsMessage, g_sAprilFoolsMessage, sizeof(g_sAprilFoolsMessage));
    g_fDisplayTime = GetConVarFloat(g_cDisplayTime);
    g_bDateCheck = GetConVarBool(g_cDateCheck);
    g_iEnableDateTimestamp = GetConVarInt(g_cEnableDateTimestamp);
    g_iDisableDateTimestamp = GetConVarInt(g_cDisableDateTimestamp);
    g_bDisplayAprilFoolsMenu = GetConVarBool(g_cDisplayAprilFoolsMenu);
    GetConVarString(g_cAprilFoolsMenuTitle, g_sAprilFoolsMenuTitle, sizeof(g_sAprilFoolsMenuTitle));
    
    if (g_bDateCheck)
    {
        int currentUnixTime = GetTime();
    
        if (currentUnixTime >= g_iEnableDateTimestamp && currentUnixTime < g_iDisableDateTimestamp)
        {
            g_bEnableAprilFools = true;
        }
        else
        {
            g_bEnableAprilFools = false;
        }
    }
    
    char sCommand[128];
    Format(sCommand, sizeof(sCommand), "sm_%s", g_sCommandName);
    if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)
    {
        RegConsoleCmd(sCommand, Command_AprilFools, "The Command.");
    }
    
    if (g_iLogType == 1)
    {
        BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), g_sLogPath); 
    }
    else if (g_iLogType == 2)
    {
        if (g_Database == null)
        {
            SQL_TConnect(T_Connect, g_sDatabaseName);
        }
    }
}

public void OnClientAuthorized(int iClient)
{
    if (g_bEnableAprilFools && g_iLogType == 2 && !IsFakeClient(iClient) && g_Database != null)
    {
        char sQuery[256], sSteamid[32];
        GetClientAuthId(iClient, AuthId_Steam2, sSteamid, sizeof(sSteamid));
        FormatEx(sQuery, sizeof(sQuery), "SELECT steam_id FROM `april_fools` WHERE steam_id = '%s'", sSteamid);
        SQL_TQuery(g_Database, T_LoadData, sQuery, GetClientUserId(iClient));
    }
}

public void OnClientPostAdminCheck(int iClient)
{
    if (g_bEnableAprilFools && g_iFooled[iClient] == 0)
    {
        DisplayMessageTimer[iClient] = CreateTimer (g_fDisplayTime, Timer_DisplayMessage, iClient);
    }
}

public void OnClientDisconnect(int iClient)
{
    g_iFooled[iClient] = 0;
    
    if (DisplayMessageTimer[iClient] != null)
    {
        KillTimer(DisplayMessageTimer[iClient]);
        DisplayMessageTimer[iClient] = null;
    }
}

public Action Timer_DisplayMessage(Handle hTimer, any iClient)
{
    CPrintToChat(iClient, g_sJoinMessage);
    if (DisplayMessageTimer[iClient] != null)
    {
        KillTimer(DisplayMessageTimer[iClient]);
        DisplayMessageTimer[iClient] = null;
    }
}

public int AprilFoolsMenuHandler(Menu menu, MenuAction action, int iClient, int param2)
{
    if (action == MenuAction_Select)
    {
        CPrintToChat(iClient, g_sAprilFoolsMessage);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public Action CreateAprilFoolsMenu(int iClient)
{
    Menu menu = new Menu(AprilFoolsMenuHandler, MENU_ACTIONS_ALL);
    menu.SetTitle("%s", g_sAprilFoolsMenuTitle);
    
    KeyValues kv = new KeyValues("april_fools");
    kv.ImportFromFile("addons/sourcemod/configs/april_fools.cfg");
    
    if(!KvGotoFirstSubKey(kv))
    {
        delete kv;
        return Plugin_Handled;
    }
    
    char menuNumber[64], menuName[255];
    do
    {
        kv.GetSectionName(menuNumber, sizeof(menuNumber));
        kv.GetString("name", menuName, sizeof(menuName));
        AddMenuItem(menu, menuNumber, menuName);
    } 
    while (KvGotoNextKey(kv));
    CloseHandle(kv);
    DisplayMenu(menu, iClient, 15);
    return Plugin_Handled;
}

//Database Stuff
public void T_Connect(Handle hOwner, Handle hDB, const char[] sError, any data)
{
    if (g_Database != null)
    {
        delete hDB;
        return;
    }
    
    g_Database = view_as<Database>(hDB);
    
    if(g_Database == null)
    {
        LogError("T_Connect returned invalid Database Handle");
        return;
    }
    
    char sCreateTableQuery[1024];
    Format(sCreateTableQuery, sizeof(sCreateTableQuery), "CREATE TABLE IF NOT EXISTS `april_fools` (`id` bigint(20) NOT NULL AUTO_INCREMENT, `steam_id` VARCHAR(32), `message` VARCHAR(254), PRIMARY KEY (`id`)) ENGINE = InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;");
    SQL_TQuery(g_Database, T_Generic, sCreateTableQuery);
    
    PrintToServer("[April Fools] Connected to Database.");
    return;
}

public void T_Generic(Handle hOwner, Handle hDB, const char[] sError, any data)
{
    if(hOwner == null || hDB == null)
    {
        LogError("T_Generic returned error: %s", sError);
        return;
    }
}

public void T_LoadData(Handle hOwner, Handle hDB, const char[] sError, any data)
{
    if (hOwner == null || hDB == null)
    {
        LogError("T_LoadData returned error: %s", sError);
        return;
    }
    
    int iClient = GetClientOfUserId(data); 
    
    if (iClient == 0)
    {
        return;
    }
    
    int steamidCol;
    SQL_FieldNameToNum(hDB, "steam_id", steamidCol);
    
    if (SQL_FetchRow(hDB))
    {
        g_iFooled[iClient] = 1;
    }
    else
    {
        g_iFooled[iClient] = 0;
    }
}

public void T_GetFooledTotal(Handle hOwner, Handle hDB, const char[] sError, any data)
{
    if (hOwner == null || hDB == null)
    {
        LogError("T_GetFooledTotal returned error: %s", sError);
        return;
    }
    
    int iClient = GetClientOfUserId(data); 
    
    if (iClient == 0)
    {
        return;
    }
    
    int totalFooledCol;
    SQL_FieldNameToNum(hDB, "total_fooled", totalFooledCol);
    
    if (SQL_FetchRow(hDB))
    {
        g_iFooledTotal = SQL_FetchInt(hDB, totalFooledCol);
    }
    CPrintToChat(iClient, "Fooled Total: {green}%i", g_iFooledTotal);
}

// Commands
public Action Command_AprilFools(int iClient, int iArgs)
{
    if (!g_bEnableAprilFools)
    {
        return Plugin_Handled;
    }
    
    char sMessage[128];
    Format(sMessage, sizeof(sMessage), "%L was fooled!", iClient);
    
    if (g_iFooled[iClient] == 0)
    {
        if (g_iLogType == 1)
        {
            LogToFileEx(g_sLogPath, sMessage);
        }
        else if (g_iLogType == 2)
        {
            g_iFooledTotal = g_iFooledTotal + 1;
            
            char sSteamid[32], sMessageEsc[256];
            GetClientAuthId(iClient, AuthId_Steam2, sSteamid, sizeof(sSteamid));
            SQL_EscapeString(g_Database, sMessage, sMessageEsc, sizeof(sMessageEsc));
            char sQuery[256]; Format(sQuery, sizeof(sQuery), "INSERT INTO `april_fools` (steam_id, message) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE steam_id = '%s';", sSteamid, sMessageEsc, sSteamid);
            SQL_TQuery(g_Database, T_Generic, sQuery);
        }
        
        g_iFooled[iClient] = 1;
    }
    
    if (g_bDisplayAprilFoolsMenu)
    {
        CreateAprilFoolsMenu(iClient);
    }
    else
    {
        CPrintToChat(iClient, g_sAprilFoolsMessage);
    }
    return Plugin_Handled;
}

public Action Command_FoolsCheck(int iClient, int iArgs)
{
    if (!g_bEnableAprilFools)
    {
        return Plugin_Handled;
    }
    else if (g_iLogType < 2)
    {
        CPrintToChat(iClient, "{default}Sorry this command is not available in this mode!");
        return Plugin_Handled;
    }
    
    int currentUnixTime = GetTime();
    
    if (currentUnixTime >= g_iFooledTotalLastCheck)
    {
        g_iFooledTotalLastCheck = currentUnixTime + 300;
        
        char sQuery[256], sSteamid[32];
        GetClientAuthId(iClient, AuthId_Steam2, sSteamid, sizeof(sSteamid));
        Format(sQuery, sizeof(sQuery), "SELECT COUNT(*) AS 'total_fooled' FROM `april_fools`;");
        SQL_TQuery(g_Database, T_GetFooledTotal, sQuery, GetClientUserId(iClient));
    }
    else
    {
        CPrintToChat(iClient, "Fooled Total: {green}%i", g_iFooledTotal);
    }
    return Plugin_Handled;
}