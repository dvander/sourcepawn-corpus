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
#define PLUGIN_VERSION          "2.0"

#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_NOTIFY

enum State { Unknown=0, Defined, Download, Precached };

// ConVars
new Handle:cvarDecalThreshold    = INVALID_HANDLE;
new Handle:cvarModelThreshold    = INVALID_HANDLE;
new Handle:cvarSoundThreshold    = INVALID_HANDLE;
new Handle:cvarDownloadThreshold = INVALID_HANDLE;

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

new g_iDecalThreshold            = -1;
new g_iModelThreshold            = -1;
new g_iSoundThreshold            = -1;
new g_iDownloadThreshold         = -1;

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

    RegPluginLibrary("ResourceManager");
    return APLRes_Success;
}

public OnPluginStart()
{
    CreateConVar("sm_resource_manager_version", PLUGIN_VERSION, "Resource Manager Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarDecalThreshold = CreateConVar("rm_decal_threshold", "-1", "Number of decals to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarModelThreshold = CreateConVar("rm_model_threshold", "-1", "Number of models to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarSoundThreshold = CreateConVar("rm_sound_threshold", "0", "Number of sounds to precache on map start (-1=unlimited).", CVAR_FLAGS);
    cvarDownloadThreshold = CreateConVar("rm_download_threshold", "25", "Number of sounds to download per map start (-1=unlimited).", CVAR_FLAGS);

    // Preload the ConVars.
    g_iDecalThreshold    = GetConVarInt(cvarDecalThreshold);
    g_iModelThreshold    = GetConVarInt(cvarModelThreshold);
    g_iSoundThreshold    = GetConVarInt(cvarSoundThreshold);
    g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);

    HookConVarChange(cvarDecalThreshold, CvarUpdated);
    HookConVarChange(cvarModelThreshold, CvarUpdated);
    HookConVarChange(cvarSoundThreshold, CvarUpdated);
    HookConVarChange(cvarDownloadThreshold, CvarUpdated);
}

public OnConfigsExecuted()
{
    // Update the ConVars with values from the config file (if any).
    g_iDecalThreshold    = GetConVarInt(cvarDecalThreshold);
    g_iModelThreshold    = GetConVarInt(cvarModelThreshold);
    g_iSoundThreshold    = GetConVarInt(cvarSoundThreshold);
    g_iDownloadThreshold = GetConVarInt(cvarDownloadThreshold);

    LogMessage("%d/%d Decals loaded by Configs Executed time",
               g_iDecalCount, g_decalTrie ? GetTrieSize(g_decalTrie) : 0);

    LogMessage("%d/%d Models loaded by Configs Executed time",
               g_iModelCount, g_iModelCount, g_modelTrie ? GetTrieSize(g_modelTrie) : 0);

    LogMessage("%d/%d Sounds loaded by Configs Executed time",
               g_iSoundCount, g_soundTrie ? GetTrieSize(g_soundTrie) : 0);
}

public CvarUpdated(Handle:hHandle, String:strOldVal[], String:strNewVal[])
{
    if (hHandle == cvarDecalThreshold)
        g_iDecalThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarModelThreshold)
        g_iModelThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarSoundThreshold)
        g_iSoundThreshold = StringToInt(strNewVal);
    else if (hHandle == cvarDownloadThreshold)
        g_iDownloadThreshold = StringToInt(strNewVal);
}

public OnMapEnd()
{
    LogMessage("%d/%d Decals loaded by Map End time",
               g_iDecalCount, g_decalTrie ? GetTrieSize(g_decalTrie) : 0);

    LogMessage("%d/%d Models loaded by Map End time",
               g_iModelCount, g_modelTrie ? GetTrieSize(g_modelTrie) : 0);

    new numSounds = g_soundTrie ? GetTrieSize(g_soundTrie) : 0;
    LogMessage("%d/%d Sounds loaded by Map End time", g_iSoundCount, numSounds);
    LogMessage("%d+%d Sounds downloaded by Map End time", g_iDownloadCount, g_iRequiredCount);

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
 * @param download		If download is 2 the file will be added to the downloadables table,
 *                      If download is 1 the file be added if it's within the allotted number of files.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return				Returns a model index (if precached).
 *
 * native SetupSound(const String:sound[], download=DOWNLOAD,
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

    new download = GetNativeCell(2);
    if (value < Download && download)
    {
        decl String:file[PLATFORM_MAX_PATH+1];
        Format(file, PLATFORM_MAX_PATH, "sound/%s", sound);

        if (FileExists(file))
        {
            if (download > 1 || g_iDownloadThreshold <= 0 ||
                (g_iSoundCount > g_iPrevDownloadIndex &&
                 g_iDownloadCount < g_iDownloadThreshold + g_iRequiredCount))
            {
                update = true;
                value  = Download;
                AddFileToDownloadsTable(file);
                g_iPrevDownloadIndex = g_iSoundCount;
                g_iDownloadCount++;
                if (download > 1)
                    g_iRequiredCount++;
            }
        }
    }

    if (value < Precached && (g_iSoundCount <= g_iSoundThreshold
                              || g_iSoundThreshold < 0
                              || GetNativeCell(3))) // precache)
    {
        PrecacheSound(sound,GetNativeCell(4)); // preload);
        value  = Precached;
        update = true;
    }

    if (update)
        SetTrieValue(g_soundTrie, sound, value);
}

/**
 * Prepares a given sound for use.
 *
 * @param decal			Name of the sound to prepare.
 * @param preload		If preload is true the file will be precached before level startup (if required).
 * @noreturn
 *
 * native PrepareSound(const String:sound[], bool:preload=false);
 */
public Native_PrepareSound(Handle:plugin,numParams)
{
    decl String:sound[PLATFORM_MAX_PATH+1];
    GetNativeString(1, sound, sizeof(sound));

    if (g_soundTrie == INVALID_HANDLE)
        g_soundTrie = CreateTrie();

    new State:value = Unknown;
    if (!GetTrieValue(g_soundTrie, sound, value)
        || value < Precached)
    {
        PrecacheSound(sound,GetNativeCell(2)); // preload);
        SetTrieValue(g_soundTrie, sound, Precached);
    }
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
        update = true;
        index  = 0;
    }

    if (g_iModelCount <= g_iModelThreshold || g_iModelThreshold < 0 ||
        GetNativeCell(4)) // precache)
    {
        index  = PrecacheModel(model,GetNativeCell(4)); // preload);
        update = true;
    }

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
 * native PrepareModel(const String:model[], &index=0, bool:preload=false);
 */
public Native_PrepareModel(Handle:plugin,numParams)
{
    decl String:model[PLATFORM_MAX_PATH+1];
    GetNativeString(1, model, sizeof(model));

    if (g_modelTrie == INVALID_HANDLE)
        g_modelTrie = CreateTrie();

    new index = GetNativeCellRef(2);
    if (index <= 0 && !GetTrieValue(g_modelTrie, model, index))
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

    if (g_iDecalCount <= g_iDecalThreshold || g_iDecalThreshold < 0 ||
        GetNativeCell(4)) // precache)
    {
        index = PrecacheDecal(decal,GetNativeCell(4)); // preload);
    }

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
    if (index <= 0 && !GetTrieValue(g_decalTrie, decal, index))
    {
        index = PrecacheDecal(decal,GetNativeCell(3)); // preload);
        SetTrieValue(g_decalTrie, decal, index);
    }

    SetNativeCellRef(2, index);
    return index;
}
