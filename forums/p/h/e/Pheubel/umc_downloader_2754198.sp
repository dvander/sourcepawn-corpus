#pragma semicolon 1

#include "umc_downloader.inc"
#include <sdktools_stringtables>
#include <logging>
#include <json>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define UMC_LIB "umccore"
#define UMDATER_LIB "updater"

#define UMCD_UPDATE_URL "https://raw.githubusercontent.com/Pheubel/UMC-Downloader/master/updatefile.txt"
#define UMC_MAPCYCLE_FILE_DEFAULT_LOCATION "umc_mapcycle.txt"
#define UMCD_CONFIG_FILE_DEFAULT_LOCATION "umc_downloader.json"

#define UMCD_KEY_ALWAYS "always"
#define UMCD_KEY_UMC_GROUP "groups"
#define UMCD_KEY_MAP_GROUP "maps"
#define UMCD_KEY_FILES "files"
#define UMCD_KEY_GENERIC "generic"
#define UMCD_KEY_DECALS "decals"
#define UMCD_KEY_SOUNDS "sounds"
#define UMCD_KEY_MODELS "models"

public Plugin pluginInfo = {
    name = "UMC Downloader",
    author = "Pheubel",
    description = "A downloader plugin that adds files and diretories to the downloads table and precaches them based on UMC groups and map names.",
    version = UMCD_VERSION,
    url = "https://github.com/Pheubel/UMC-Downloader"
}

enum UMCD_CACHE_TYPE {
    UMCD_NO_PRECACHE,
    UMCD_CACHE_GENERIC,
    UMCD_CACHE_DECALS,
    UMCD_CACHE_SOUNDS,
    UMCD_CACHE_MODELS
};

bool umcdLoaded;

public void OnPluginStart(){
    if(umcdLoaded) {
        return;
    }
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_ENTRY)
        LogMessage("loaded through plugin start.");
#endif

    ReadDownloadFile();
    umcdLoaded = true;
}

#if defined (_updater_included)
public void OnLibraryAdded(const char[] name) {
    if (StrEqual(name, UMDATER_LIB)) {
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_ENTRY)
        LogMessage("updater lib loaded.");
#endif
        Updater_AddPlugin(UMCD_UPDATE_URL);
    }
}
#endif

public void OnMapStart() {
    if(!umcdLoaded && LibraryExists(UMC_LIB)) {
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_ENTRY)
        LogMessage("loaded through map start.");
#endif

        ReadDownloadFile();
        umcdLoaded = true;
    }
}

public void OnMapEnd() {
    umcdLoaded = false;
}

void ReadDownloadFile() {
    char mapGroup[PLATFORM_MAX_PATH];
    char currentMap[PLATFORM_MAX_PATH];

    GetCurrentMap(currentMap, sizeof(currentMap));
    FindGroupOfMap(currentMap, mapGroup, sizeof(mapGroup));

#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_GROUP)
    LogMessage("Current map: \"%s\". Current map group: \"%s\".", currentMap, mapGroup);
#endif

    int size = FileSize(UMCD_CONFIG_FILE_DEFAULT_LOCATION) + 1;
    File jsonFile = OpenFile(UMCD_CONFIG_FILE_DEFAULT_LOCATION, "rb");
    char[] rawJson = new char[size];

    if (ReadFileString(jsonFile, rawJson, size, -1) == -1) {
        LogError("could not read file \"%s\"", UMCD_CONFIG_FILE_DEFAULT_LOCATION);
        return;
    }

    JSON_Object rootObject = json_decode(rawJson);
    if(rootObject == INVALID_HANDLE) {
        LogError("Malformed json in: \"%s\"", UMCD_CONFIG_FILE_DEFAULT_LOCATION);
        return;
    }

    // read always download
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_SET)
    JSON_Object alwaysSet = rootObject.GetObject(UMCD_KEY_ALWAYS);
    if (alwaysSet == INVALID_HANDLE) {
        LogMessage("Could not find key for \"%s\"", UMCD_KEY_ALWAYS);
    } else {
        AddSetToDownloads(alwaysSet);
    }
#else
    AddSetToDownloads(rootObject.GetObject(UMCD_KEY_ALWAYS));
#endif

    // read group downloads
    JSON_Object groups = rootObject.GetObject(UMCD_KEY_UMC_GROUP);
    if (groups != INVALID_HANDLE) {
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_SET)
        JSON_Object group = groups.GetObject(mapGroup);
        if(group == INVALID_HANDLE) {
            LogMessage("Could not find key for group: \"%s\"", mapGroup);
        } else {
            LogMessage("Found group: \"%s\"", mapGroup);
            AddSetToDownloads(group);
        }
#else
        AddSetToDownloads(groups.GetObject(mapGroup));
#endif
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_SET)
    } else {
        LogMessage("Could not find \"%s\" key", UMCD_KEY_UMC_GROUP);
#endif
    }

    // read map downloads
    JSON_Object maps = rootObject.GetObject(UMCD_KEY_MAP_GROUP);
    if (maps != INVALID_HANDLE) {
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_SET)
        JSON_Object map = maps.GetObject(currentMap);
        if(map == INVALID_HANDLE) {
            LogMessage("Could not find key for map: \"%s\"", currentMap);
        } else {
            LogMessage("Found map: \"%s\"", currentMap);
            AddSetToDownloads(map);
        }
#else
        AddSetToDownloads(maps.GetObject(currentMap));
#endif
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_SET)
    } else {
        LogMessage("Could not find \"%s\" key", UMCD_KEY_MAP_GROUP);
#endif
    }

    json_cleanup_and_delete(rootObject);
    CloseHandle(jsonFile);
}

void AddSetToDownloads(JSON_Object set) {
    if(set == INVALID_HANDLE) {
        return;
    }

    AddJsonArrayToDownloads(view_as<JSON_Array>(set.GetObject(UMCD_KEY_FILES)), UMCD_NO_PRECACHE);
    AddJsonArrayToDownloads(view_as<JSON_Array>(set.GetObject(UMCD_KEY_GENERIC)), UMCD_CACHE_GENERIC);
    AddJsonArrayToDownloads(view_as<JSON_Array>(set.GetObject(UMCD_KEY_DECALS)), UMCD_CACHE_DECALS);
    AddJsonArrayToDownloads(view_as<JSON_Array>(set.GetObject(UMCD_KEY_SOUNDS)), UMCD_CACHE_SOUNDS);
    AddJsonArrayToDownloads(view_as<JSON_Array>(set.GetObject(UMCD_KEY_MODELS)), UMCD_CACHE_MODELS);
}

void AddJsonArrayToDownloads(JSON_Array array, UMCD_CACHE_TYPE cacheType) {
    if (array == INVALID_HANDLE) {
        return;
    }

    int length = array.Length;
    char path[PLATFORM_MAX_PATH];

    for (int i = 0; i < length; i++) {
        array.GetString(i, path, sizeof(path));

        // check if the string target as a file or a directory
        if (DirExists(path)) {
            AddDirectory(path, cacheType);
        } else {
            AddFile(path, cacheType);
        }
    }
}

void AddFile(char[] filePath, UMCD_CACHE_TYPE cacheType) {
    if(!FileExists(filePath)) {
        LogMessage("File \"%s\" could not be found.", filePath);
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_FILE)
    } else {
        LogMessage("File \"%s\" found.", filePath);
#endif
    }

    switch(cacheType) {
        case UMCD_CACHE_GENERIC: {
            PrecacheGeneric(filePath, true);
        }
        case UMCD_CACHE_DECALS: {
            PrecacheDecal(filePath, true);
        }
        case UMCD_CACHE_SOUNDS: {
            PrecacheSound(filePath, true);
        }
        case UMCD_CACHE_MODELS: {
            PrecacheModel(filePath, true);
        }
    }

    AddFileToDownloadsTable(filePath);

#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_FILE)
    LogMessage("Loaded file: \"%s\".", filePath);
#endif
}

void AddDirectory(char[] directoryPath, UMCD_CACHE_TYPE cacheType) {
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_DIRECTORY)
    LogMessage("Current directory path: \"%s\".", directoryPath);
#endif
    Handle dir = OpenDirectory(directoryPath);

    if (dir == INVALID_HANDLE) {
        LogMessage("Directory \"%s\" could not be found.", directoryPath);
        return;
#if (UMCD_DEBUG & UMCD_DEBUG_FLAG_DIRECTORY)
    } else {
        LogMessage("Directory \"%s\" found.", directoryPath);
#endif
    }


    FileType fileType = FileType_Unknown;
    char entryBuffer[PLATFORM_MAX_PATH];

    while (ReadDirEntry(dir, entryBuffer, sizeof(entryBuffer), fileType)) {
        if(StrEqual(entryBuffer, ".") || StrEqual(entryBuffer, "..")) {
            continue;
        }

        char subPath[PLATFORM_MAX_PATH];
        Format(subPath, sizeof(subPath), "%s/%s", directoryPath, entryBuffer);

        if (fileType == FileType_Directory) {
            AddDirectory(subPath, cacheType);
        } else {
            AddFile(subPath, cacheType);
        }
    }

    CloseHandle(dir);
}

bool FindGroupOfMap(char[] map, char[] groupBuffer, int bufferSize) {
    KeyValues kv = CreateKeyValues("umc_rotation");
    if (!FileToKeyValues(kv, UMC_MAPCYCLE_FILE_DEFAULT_LOCATION)) {
        return false;
    }

    if (!KvGotoFirstSubKey(kv)) {
        CloseHandle(kv);
        return false;
    }

    char mapName[PLATFORM_MAX_PATH];
    char groupName[PLATFORM_MAX_PATH];
    do {
        KvGetSectionName(kv, groupName, sizeof(groupName));

        if (!KvGotoFirstSubKey(kv)) {
            continue;
        }

        do {
            KvGetSectionName(kv, mapName, sizeof(mapName));
            if (StrEqual(mapName, map, false)) {
                KvGoBack(kv);
                KvGoBack(kv);
                strcopy(groupBuffer, bufferSize, groupName);
                CloseHandle(kv);
                return true;
            }
        } while (KvGotoNextKey(kv));

        KvGoBack(kv);
    } while (KvGotoNextKey(kv));

    CloseHandle(kv);
    return false;
}