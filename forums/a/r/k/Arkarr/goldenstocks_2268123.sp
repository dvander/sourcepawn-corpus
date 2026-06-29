#pragma semicolon 1

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2items>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
    name         =        "[TF2] Golden Stocks",
    author        =        "11530 - Edited by Arkarr",
    description    =        "Stock weapons are made golden.",
    version        =        PLUGIN_VERSION,
    url            =        "http://www.sourcemod.net"
};

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hAdminOnly = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hGoldenItem = INVALID_HANDLE;
new Handle:WeaponIndexs = INVALID_HANDLE;

new bool:g_bEnabled;
new bool:g_bAdminOnly;
new bool:g_bNotify;

public OnPluginStart()
{
    CreateConVar("sm_goldenstocks_version", PLUGIN_VERSION, "\"Golden Stocks\" Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    RegAdminCmd("sm_reloadgoldwep", CMD_ReloadWeapons, ADMFLAG_CHEATS, "Reload the config file.");
    
    g_hEnabled = CreateConVar("sm_goldenstocks_enabled", "1", "0 = Disable plugin, 1 = Enable plugin", 0, true, 0.0, true, 1.0);
    HookConVarChange(g_hEnabled, ConVarEnabledChanged);
    g_bEnabled = GetConVarBool(g_hEnabled);
    
    g_hAdminOnly = CreateConVar("sm_goldenstocks_adminonly", "1", "0 = Everyone, 1 = Admin only", 0, true, 0.0, true, 1.0);
    HookConVarChange(g_hAdminOnly, ConVarAdminOnlyChanged);
    g_bAdminOnly = GetConVarBool(g_hAdminOnly);
    
    g_hNotify = CreateConVar("sm_goldenstocks_notify", "1", "0 = Do not notify, 1 = Notify the player", 0, true, 0.0, true, 1.0);
    HookConVarChange(g_hNotify, ConVarNotifyChanged);
    g_bNotify = GetConVarBool(g_hNotify);

    g_hGoldenItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
    TF2Items_SetNumAttributes(g_hGoldenItem, 1);
    TF2Items_SetAttribute(g_hGoldenItem, 0, 150, 1.0);
    
    WeaponIndexs = ReadWeaponIndex();
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarAdminOnlyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_bAdminOnly = (StringToInt(newvalue) == 0 ? false : true);
}

public ConVarNotifyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_bNotify = (StringToInt(newvalue) == 0 ? false : true);
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
    if (g_bEnabled)
    {
        if (FindValueInArray(WeaponIndexs, iItemDefinitionIndex) != -1)
        {
            if (!g_bAdminOnly || (CheckCommandAccess(client, "goldenstocks_override", ADMFLAG_SLAY)))
            {
                if (g_bNotify)
                    PrintToChat(client, "\x05You received a \x07FFD700Golden \x05 wepaon !");            
                hItem = g_hGoldenItem;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

public Action:CMD_ReloadWeapons(client, args)
{
    WeaponIndexs = ReadWeaponIndex();
    if(client != 0)
        PrintToChat(client, "Reloaded config file sucessfully !");
    else
        PrintToServer("Reloaded config file sucessfully !");

        return Plugin_Handled;
}

stock Handle:ReadWeaponIndex()
{
    new Handle:table;
    table = CreateArray(10);
    decl String:path[PLATFORM_MAX_PATH],String:line[128];
    BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/GoldKillsWeapons.txt");
    new Handle:fileHandle=OpenFile(path,"r");
    while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
    {
        PushArrayCell(table, StringToInt(line));
    }
    CloseHandle(fileHandle);
    return table;
}  