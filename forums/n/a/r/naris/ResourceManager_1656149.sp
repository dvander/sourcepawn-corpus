/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: ResourceManager.sp
 * Description: Plugin to manage precaching resources globally.
 * Author(s): Naris (Murray Wilson)
 */

#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>

// CONSTANTS
#define PLUGIN_VERSION          "2.3"

#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_NOTIFY

enum State { Unknown=0, Defined, Download, Force, Precached };

// ConVars
new Handle:cvarDownloadThreshold = INVALID_HANDLE;
new Handle:cvarDecalThreshold    = INVALID_HANDLE;
new Handle:cvarModelThreshold    = INVALID_HANDLE;
new Handle:cvarSoundThreshold    = INVALID_HANDLE;
new Handle:cvarSoundLimit        = INVALID_HANDLE;

// Resource Tries
new Handle:g_decalTrie           = INVALID_HANDLE;
new Handle:g_modelTrie           = INVALID_HANDLE;
new Handle:g_soundTrie           = INVALID_HANDLE;

// Variables
new g_iDecalCount                = 0;
new g_iModelCount                = 0;
new g_iSoundCount                = 0;
new g_iDownloadCount             = 0;
new g_iRequiredCount             = 0;
new g_iPrevDownloadIndex         = 0;

new g_iDownloadThreshold         = -1;
new g_iDecalThreshold            = -1;
new g_iModelThreshold            = -1;
new g_iSoundThreshold            = -1;
new g_iSoundLimit                = -1;

public Plugin:myinfo = {
    name = "Resource Manager",
    author = "-=|JFH|=-Naris",
    description = "Manage resources",
    version = PLUGIN_VERSION,
    url = "http://www.jigglysfunhouse.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("SetupDecal",Native_SetupDecal);
    CreateNative("PrepareDecal",Native_PrepareDecal);
    CreateNative("SetupModel",Native_SetupModel);
    CreateNative("PrepareModel",Native_PrepareModel);
    CreateNative("SetupSound",Native_SetupSound);
    CreateNative("PrepareSound",Native_PrepareSound);
    CreateNative("AddFolderToDownloadTable",Native_AddFolderToDownloadTable);

    RegPluginLibrary("ResourceManager");
    return APLRes_Success;
}

public OnPluginStart()
{
    CreateConVar("sm_resource_manager_version", PLUGIN_VERSION, "Resource Manager Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarDownloadThreshold = CreateConVar("rm_download_threshold", "-1", "Number of sounds to download per map start (-1=unlimited, 0=disable downloads).", CVAR_FLAGS);
    cvarDecalThreshold = CreateConVar("rm_decal_threshold", "-1", "Number of decals to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarModelThreshold = CreateConVar("rm_model_threshold", "-1", "Number of models to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarSoundThreshold = CreateConVar("rm_sound_threshold", "0", "Number of sounds to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarSoundLimit     = CreateConVar("rm_sound_max", "-1", "Maximum number of sounds to allow (-1=unlimited).", CVAR_FLAGS);

    // Preload the ConVars.
    g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);
    g_iDecalThreshold    = GetConVarInt(cvarDecalThreshold);
    g_iModelThreshold    = GetConVarInt(cvarModelThreshold);
    g_iSoundThreshold    = GetConVarInt(cvarSoundThreshold);
    g_iSoundLimit        = GetConVarInt(cvarSoundLimit);

    HookConVarChange(cvarDownloadThreshold, CvarUpdated);
    HookConVarChange(cvarDecalThreshold,    CvarUpdated);
    HookConVarChange(cvarModelThreshold,    CvarUpdated);
    HookConVarChange(cvarSoundThreshold,    CvarUpdated);
    HookConVarChange(cvarSoundLimit,        CvarUpdated);
}

public OnConfigsExecuted()
{
    // Update the ConVars with values from the config file (if any).
    g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);
    g_iDecalThreshold    = GetConVarInt(cvarDecalThreshold);
    g_iModelThreshold    = GetConVarInt(cvarModelThreshold);
    g_iSoundLimit        = GetConVarInt(cvarSoundLimit);

    LogToGame("%d/%d Decals loaded by Configs Executed time",
              g_iDecalCount, g_decalTrie ? GetTrieSize(g_decalTrie) : 0);

    LogToGame("%d/%d Models loaded by Configs Executed time",
              g_iModelCount, g_iModelCount, g_modelTrie ? GetTrieSize(g_modelTrie) : 0);

    LogToGame("%d/%d/%d Sounds loaded by Configs Executed time",
              g_iSoundCount, g_soundTrie ? GetTrieSize(g_soundTrie) : 0, g_iSoundLimit);
}

public CvarUpdated(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
    if (hHandle == cvarDownloadThreshold)
        g_iDownloadThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarDecalThreshold)
        g_iDecalThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarModelThreshold)
        g_iModelThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarSoundThreshold)
        g_iSoundThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarSoundLimit)
        g_iSoundLimit = StringToInt(strNewVal);
}

public OnMapEnd()
{
    new numDecals = g_decalTrie ? GetTrieSize(g_decalTrie) : 0;
    LogToGame("%d/%d Decals loaded by Map End time", g_iDecalCount, numDecals);
    if (numDecals > 0)
        LogMessage("%d/%d Decals loaded by Map End time", g_iDecalCount, numDecals);

    new numModels = g_modelTrie ? GetTrieSize(g_modelTrie) : 0;
    LogToGame("%d/%d Models loaded by Map End time", g_iModelCount, numModels);
    if (numModels > 0)
        LogMessage("%d/%d Models loaded by Map End time", g_iModelCount, numModels);

    new numSounds = g_soundTrie ? GetTrieSize(g_soundTrie) : 0;
    LogToGame("%d/%d/%d Sounds loaded by Map End time", g_iSoundCount, numSounds, g_iSoundLimit);
    LogToGame("%d+%d Sounds downloaded by Map End time", g_iDownloadCount, g_iRequiredCount);
    if (numSounds > 0)
    {
        LogMessage("%d/%d/%d Sounds loaded by Map End time", g_iSoundCount, numSounds, g_iSoundLimit);
        LogMessage("%d+%d Sounds downloaded by Map End time", g_iDownloadCount, g_iRequiredCount);
    }

    if (g_iPrevDownloadIndex >= numSounds || g_iDownloadCount < g_iDownloadThreshold)
        g_iPrevDownloadIndex = 0;

    g_iDownloadCount     = 0;
    g_iRequiredCount     = 0;
    g_iSoundCount        = 0;
    g_iModelCount        = 0;
    g_iDecalCount        = 0;

    if (g_decalTrie == INVALID_HANDLE)
        g_decalTrie = CreateTrie();
    else
        ClearTrie(g_decalTrie);

    if (g_modelTrie == INVALID_HANDLE)
        g_modelTrie = CreateTrie();
    else
        ClearTrie(g_modelTrie);

    if (g_soundTrie == INVALID_HANDLE)
        g_soundTrie = CreateTrie();
    else
        ClearTrie(g_soundTrie);
}

/**
 * Sets up a given sound.
 *
 * @param model			Name of the sound to precache.
 * @param force		    If force is true the sound limit will be ignored for this sound.
 * @param download		If download is 2 the file will be added to the downloadables table,
 *                      If download is 1 the file be added if it's within the allotted number of files.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns a model index (if precached).
 *
 * native SetupSound(const String:sound[], download=DOWNLOAD, bool:force=false,
 *                   bool:precache=false, bool:preload=false);
 */
public Native_SetupSound(Handle:plugin,numParams)
{
    decl String:sound[PLATFORM_MAX_PATH+1];
    GetNativeString(1, sound, sizeof(sound));

    if (g_soundTrie == INVALID_HANDLE)
        g_soundTrie = CreateTrie();

    new State:value = Unknown;
    new bool:update = !GetTrieValue(g_soundTrie, sound, value);
    if (update || value < Defined)
    {
        g_iSoundCount++;
        value  = Defined;
        update = true;
    }

    new download = GetNativeCell(3);
    if (download && value < Download && g_iDownloadThreshold != 0)
    {
        decl String:file[PLATFORM_MAX_PATH+1];
        Format(file, PLATFORM_MAX_PATH, "sound/%s", sound);

        if (FileExists(file))
        {
            if (download < 0)
            {
                if (!strncmp(file, "ambient", 7) ||
                    !strncmp(file, "beams", 5) ||
                    !strncmp(file, "buttons", 7) ||
                    !strncmp(file, "coach", 5) ||
                    !strncmp(file, "combined", 8) ||
                    !strncmp(file, "commentary", 10) ||
                    !strncmp(file, "common", 6) ||
                    !strncmp(file, "doors", 5) ||
                    !strncmp(file, "friends", 7) ||
                    !strncmp(file, "hl1", 3) ||
                    !strncmp(file, "items", 5) ||
                    !strncmp(file, "midi", 4) ||
                    !strncmp(file, "misc", 4) ||
                    !strncmp(file, "music", 5) ||
                    !strncmp(file, "npc", 3) ||
                    !strncmp(file, "physics", 7) ||
                    !strncmp(file, "pl_hoodoo", 9) ||
                    !strncmp(file, "plats", 5) ||
                    !strncmp(file, "player", 6) ||
                    !strncmp(file, "resource", 8) ||
                    !strncmp(file, "replay", 6) ||
                    !strncmp(file, "test", 4) ||
                    !strncmp(file, "ui", 2) ||
                    !strncmp(file, "vehicles", 8) ||
                    !strncmp(file, "vo", 2) ||
                    !strncmp(file, "weapons", 7))
                {
                    // If the sound starts with one of those directories
                    // assume it came with the game and doesn't need to
                    // be downloaded.
                    download = 0;
                }
                else
                    download = 1;
            }

            if (download > 0 &&
                (download > 1 || g_iDownloadThreshold < 0 ||
                 (g_iSoundCount > g_iPrevDownloadIndex &&
                  g_iDownloadCount < g_iDownloadThreshold + g_iRequiredCount)))
            {
                AddFileToDownloadsTable(file);

                update = true;
                value  = Download;
                g_iDownloadCount++;

                if (download > 1)
                    g_iRequiredCount++;

                if (download <= 1 || g_iSoundCount == g_iPrevDownloadIndex + 1)
                    g_iPrevDownloadIndex = g_iSoundCount;
            }
        }
    }

    new bool:force = GetNativeCell(2);
    if (value < Precached &&
        ((g_iSoundThreshold > 0 && g_iSoundCount < g_iSoundThreshold) ||
         GetNativeCell(4))) // precache)
    {
        if (force || g_iSoundLimit <= 0 || 
            (g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
        {
            PrecacheSound(sound, GetNativeCell(5)); // preload);
            value  = Precached;
            update = true;
        }
    }
    else if (force && value < Force)
    {
        value  = Force;
        update = true;
    }

    if (update)
        SetTrieValue(g_soundTrie, sound, value);
}

/**
 * Prepares a given sound for use.
 *
 * @param decal			Name of the sound to prepare.
 * @param force		    If force is true the sound limit will be ignored for this sound.
 * @param preload		If preload is true the file will be precached immdiately (if required).
 * @return				Returns false if the sound limit has been reached.
 *
 * native PrepareSound(const String:sound[], bool:force=false, bool:preload=false);
 */
public Native_PrepareSound(Handle:plugin,numParams)
{
    decl String:sound[PLATFORM_MAX_PATH+1];
    GetNativeString(1, sound, sizeof(sound));

    if (g_soundTrie == INVALID_HANDLE)
        g_soundTrie = CreateTrie();

    new State:value = Unknown;
    if (!GetTrieValue(g_soundTrie, sound, value) || value < Precached)
    {
        if (value >= Force || g_iSoundLimit <= 0 || GetNativeCell(2) || // force
            (g_soundTrie ? GetTrieSize(g_soundTrie) : 0) < g_iSoundLimit)
        {
            PrecacheSound(sound, GetNativeCell(3)); // preload);
            SetTrieValue(g_soundTrie, sound, Precached);
        }
        else
            return false;
    }
    return true;
}

/**
 * Sets up a given model.
 *
 * @param model			Name of the model to precache.
 * @param index			Returns the model index (if precached).
 * @param download		If download is true the file will be added to the downloadables table.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns a model index (if precached).
 * 
 * native SetupModel(const String:model[], &index=0, bool:download=true,
 *                   bool:precache=false, bool:preload=false);
 */
public Native_SetupModel(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(1, model, sizeof(model));

    if (g_modelTrie == INVALID_HANDLE)
        g_modelTrie = CreateTrie();

    new index       = -1;
    new bool:update = !GetTrieValue(g_modelTrie, model, index);
    if (update || index < 0)
    {
        g_iModelCount++;
        update = true;
    }

    if (index < 0 && GetNativeCell(3) && FileExists(model)) // download
    {
        AddFileToDownloadsTable(model);

        new Handle:files = Handle:GetNativeCell(6);
        if (files != INVALID_HANDLE)
        {
            decl String:file[PLATFORM_MAX_PATH+1];
            while (PopStackString(files, file, sizeof(file)))
                AddFileToDownloadsTable(file);
        }

        CloseHandle(files);
        update = true;
    }

    if (index <= 0 && (g_iModelCount <= g_iModelThreshold ||
                       g_iModelThreshold < 0 || GetNativeCell(4))) // precache)
    {
        index  = PrecacheModel(model,GetNativeCell(5)); // preload);
        update = true;
    }
    else if (index < 0)
        index  = 0;

    if (update)
        SetTrieValue(g_modelTrie, model, index);

    SetNativeCellRef(2, index);
    return index;
}

/**
 * Prepares a given model for use.
 *
 * @param decal			Name of the model to prepare.
 * @param index			Returns the model index.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @return				Returns a model index.
 * 
 * native PrepareModel(const String:model[], &index=0, bool:preload=true);
 */
public Native_PrepareModel(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(1, model, sizeof(model));

    if (g_modelTrie == INVALID_HANDLE)
        g_modelTrie = CreateTrie();

    new index = GetNativeCellRef(2);
    if (index <= 0)
        GetTrieValue(g_modelTrie, model, index);

    if (index <= 0)
    {
        index = PrecacheModel(model,GetNativeCell(3)); // preload);
        SetTrieValue(g_modelTrie, model, index);
    }

    SetNativeCellRef(2, index);
    return index;
}

/**
 * Sets up a given decal.
 *
 * @param decal			Name of the decal to precache.
 * @param index			Returns the decal index (if precached).
 * @param download		If download is true the file will be added to the downloadables table.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns a decal index (if precached).
 *
 * native SetupDecal(const String:decal[], &index=0, bool:download=true,
 *                   bool:precache=false, bool:preload=false);
 */
public Native_SetupDecal(Handle:plugin,numParams)
{
    decl String:decal[PLATFORM_MAX_PATH+1];
    GetNativeString(1, decal, sizeof(decal));

    if (g_decalTrie == INVALID_HANDLE)
        g_decalTrie = CreateTrie();

    new index       = -1;
    new bool:update = !GetTrieValue(g_decalTrie, decal, index);
    if (update || index < 0)
    {
        g_iModelCount++;
        update = true;
    }

    if (index < 0 && GetNativeCell(3) && FileExists(decal)) // download
        AddFileToDownloadsTable(decal);

    if (index <= 0 && (g_iDecalCount <= g_iDecalThreshold ||
                       g_iDecalThreshold < 0 || GetNativeCell(4))) // precache)
    {
        index = PrecacheDecal(decal,GetNativeCell(5)); // preload);
    }
    else if (index < 0)
        index  = 0;

    if (update)
        SetTrieValue(g_decalTrie, decal, index);

    SetNativeCellRef(2, index);
    return index;
}

/**
 * Prepares a given decal for use.
 *
 * @param decal			Name of the decal to prepare.
 * @param index			Returns the decal index.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @return				Returns a decal index.
 *
 * native PrepareDecal(const String:model[], &index=0, bool:preload=false);
 */
public Native_PrepareDecal(Handle:plugin,numParams)
{
    decl String:decal[PLATFORM_MAX_PATH+1];
    GetNativeString(1, decal, sizeof(decal));

    if (g_decalTrie == INVALID_HANDLE)
        g_decalTrie = CreateTrie();

    new index = GetNativeCellRef(2);
    if (index <= 0)
        GetTrieValue(g_decalTrie, decal, index);

    if (index <= 0)
    {
        index = PrecacheDecal(decal,GetNativeCell(3)); // preload);
        SetTrieValue(g_decalTrie, decal, index);
    }

    SetNativeCellRef(2, index);
    return index;
}

/**
 * Adds all the files in a directory tothe Download Table
 *
 * @param Directory		Name of the directory.
 * @param recursive		If true, descends child directories to recursively add all files therein.
 * @noreturn
 *
 * native AddFolderToDownloadTable(const String:Directory[], bool:recursive=false);
 */
public Native_AddFolderToDownloadTable(Handle:plugin,numParams)
{
    decl String:Directory[PLATFORM_MAX_PATH+1];
    GetNativeString(1, Directory, sizeof(Directory));
    AddFolderToDownloadTable(Directory, bool:GetNativeCell(2));
}

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false)
{
    decl String:Path[PLATFORM_MAX_PATH+1];
    decl String:FileName[PLATFORM_MAX_PATH+1];

    new Handle:Dir = OpenDirectory(Directory), FileType:Type;
    while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
    {
        if (Type == FileType_Directory && recursive)         
        {           
            FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
            AddFolderToDownloadTable(FileName);
        }                 
        else if (Type == FileType_File)
        {
            FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
            AddFileToDownloadsTable(Path);
        }
    }
}
