#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.6.1"

new String:LEFT4DEAD_DIR[] = "left4dead";

public Plugin:myinfo = {
    name = "Maplister",
    author = "theY4Kman",
    description = "Uses the maps in the /maps (or /addons for L4D) folder to write or display a maplist.",
    version = PLUGIN_VERSION,
    url = "http://y4kstudios.com/sourcemod/"
};

enum OutputType
{
    Output_Console = 0,
    Output_File = 1,
};

new bool:g_writeOnMapChange;
new Handle:g_hExcludeMaps = INVALID_HANDLE;

new bool:g_bIsL4D = false;

public OnPluginStart()
{
    new String:gamedir[32];
    GetGameFolderName(gamedir, sizeof(gamedir));
    
    if (strncmp(gamedir, LEFT4DEAD_DIR, sizeof(LEFT4DEAD_DIR), false) == 0)
        g_bIsL4D = true;
    
    /* Everyone is allowed to use sm_maplist
    * But only Admins can use sm_writemaplist
    */
    RegConsoleCmd("sm_maplist", MapListCmd);
    RegAdminCmd("sm_writemaplist", WriteMapListCmd, ADMFLAG_GENERIC);

    new Handle:writeOnMapChange = CreateConVar("sm_auto_maplist", "1",
        "If set to 1 will write a new maplist whenever the map changes.");

    if (writeOnMapChange == INVALID_HANDLE)
        writeOnMapChange = FindConVar("sm_auto_maplist");
    
    HookConVarChange(writeOnMapChange, auto_maplistChanged);
    g_writeOnMapChange = GetConVarBool(writeOnMapChange);

    CreateConVar("sm_maplister_version", PLUGIN_VERSION, 
        "The version of the SourceMod plugin MapLister, by theY4Kman",
        FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
    
    decl String:excludeMaps[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, excludeMaps, sizeof(excludeMaps), "configs/maplister_excludes.cfg");
    
    g_hExcludeMaps = OpenFile(excludeMaps, "r");

    PrintToServer("[Maplister] Loaded");
}

public OnPluginEnd()
{
    if (g_hExcludeMaps != INVALID_HANDLE)
        CloseHandle(g_hExcludeMaps);
}

public OnMapStart()
{
    if (g_writeOnMapChange)
        MapLister(Output_File, "maplist.txt", 0, "");
}

public auto_maplistChanged(Handle:convar, const String:oldValue[],
                           const String:newValue[])
{
    g_writeOnMapChange = GetConVarBool(convar);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("ListMapsToClient", native_MapList);
    CreateNative("WriteNewMapList", native_WriteMapList);
    
    return APLRes_Success;
}

public native_MapList(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    
    if (client > GetMaxClients() || client < 0)
        return ThrowError("Client index %d is invalid", client);
    else if(!IsClientConnected(client))
        return ThrowError("Client %d is not connected", client);
    
    decl String:filter[PLATFORM_MAX_PATH];
    filter[0] = '\0';
    
    if (numParams > 1)
        GetNativeString(2, filter, sizeof(filter));
    
    MapLister(Output_Console, "", client, filter);
    
    return true;
}

public native_WriteMapList(Handle:plugin, numParams)
{
    decl String:filter[PLATFORM_MAX_PATH];
    filter[0] = '\0';
    
    if (numParams > 1)
        GetNativeString(2, filter, sizeof(filter));
    
    decl String:path[PLATFORM_MAX_PATH];
    GetNativeString(1, path, sizeof(path));
    
    return MapLister(Output_File, path, 0, filter);
}

public Action:MapListCmd(client, args)
{
    decl String:filter[PLATFORM_MAX_PATH];
    filter[0] = '\0';
    
    if (args >= 1)
        GetCmdArg(1, filter, sizeof(filter));
    
    MapLister(Output_Console, "", client, filter);
    
    return Plugin_Handled;
}

public Action:WriteMapListCmd(client, args)
{
    if (args > 2)
    {
        ReplyToCommand(client, "Too many arguments.");
        ReplyToCommand(client, "Usage: sm_writemaplist <output file> [filter]");
        
        return Plugin_Handled;
    }
    
    decl String:filename[PLATFORM_MAX_PATH];
    decl String:filter[PLATFORM_MAX_PATH];
    filter[0] = '\0';
    
    if (args >= 1)
        GetCmdArg(1, filename, sizeof(filename));
    else
        strcopy(filename, sizeof(filename), "maplist.txt");
    
    if (args >= 2)
        GetCmdArg(2, filter, sizeof(filter));
    
    MapLister(Output_File, filename, client, filter);
    
    ReplyToCommand(client, "[Maplister] Generated a fresh maplist!");
    LogMessage("%L generated a fresh maplist in %s", client,
        filename);
    
    return Plugin_Handled;
}

MapLister(OutputType:type, const String:path[], client, const String:filter[])
{
    new Handle:maplist;
    if (type == Output_File)
    {
        maplist = OpenFile(path, "w");
        if (maplist == INVALID_HANDLE)
            return false;
    }
    
    new Handle:mapdir = OpenDirectory("maps/");
    if (mapdir == INVALID_HANDLE)
        return false;

    decl String:name[PLATFORM_MAX_PATH];
    new Handle:array = CreateArray(PLATFORM_MAX_PATH/4);
    new FileType:filetype;
    new namelen;
    
    new filterlen = strlen(filter);
    new bool:exclude = false;
    
    decl String:fileMap[PLATFORM_MAX_PATH];
    if (g_hExcludeMaps != INVALID_HANDLE)
        FileSeek(g_hExcludeMaps, SEEK_SET, 0);
    
    for (new i=0; i<2; i++)
    {
        while (ReadDirEntry(mapdir, name, sizeof(name), filetype))
        {
            if (filetype != FileType_File)
                continue;
            
            namelen = strlen(name) - 4;
            if (StrContains(name, ".bsp", false) != namelen ||
                (g_bIsL4D && StrContains(name, ".vpk", false) != namelen))
                continue;
            
            name[namelen] = '\0';
            
            if (strncmp(filter, name, filterlen) != 0)
                exclude = true;
            else if (g_hExcludeMaps != INVALID_HANDLE)
            {
                while (ReadFileLine(g_hExcludeMaps, fileMap, sizeof(fileMap)))
                {
                    if (strncmp(fileMap, name, strlen(name)) == 0)
                    {
                        exclude = true;
                        break;
                    }
                }
            }
            
            if (!exclude)
                PushArrayString(array, name);
            
            exclude = false;
            
            if (g_hExcludeMaps != INVALID_HANDLE)
                FileSeek(g_hExcludeMaps, SEEK_SET, 0);
        }
        
        if (!g_bIsL4D)
            break;
        
        CloseHandle(mapdir);
        
        mapdir = OpenDirectory("addons/");
        if (mapdir == INVALID_HANDLE)
            break;
    }
    
    CloseHandle(mapdir);
    
    SortADTArray(array, Sort_Ascending, Sort_String);
    
    new i;
    new len = GetArraySize(array);
    for (i=0; i<len; i++)
    {
        GetArrayString(array, i, name, sizeof(name));
        
        if (type == Output_Console)
            PrintToConsole(client, "%s", name);
        else
            WriteFileLine(maplist, "%s", name);
    }
    
    if (type == Output_File)
        CloseHandle(maplist);
    else
    {
        if (len > 0)
            ReplyToCommand(client, "[Maplister] Map list printed to console.");
        else
            ReplyToCommand(client, "[Maplister] No maps found.");
    }
    
    return true;
}
