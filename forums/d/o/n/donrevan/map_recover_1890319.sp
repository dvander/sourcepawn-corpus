#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
new bool:bRecovered = false;

#define RECOVER_FILE "map_recover.txt"
#define SOME_DEFAULT_MAP "de_dust"

public Plugin:myinfo = 
{
    name = "Map Recovery",
    author = "DonRevan",
    description = "Recovers the latest map when the Server crashed",
    version = PLUGIN_VERSION
};

public OnPluginStart(){
    CreateConVar("sm_maprecovery_version", PLUGIN_VERSION, "Map Recovery Plugin Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    if(!FileExists(RECOVER_FILE)){
        new Handle:dataFileHandle = OpenFile(RECOVER_FILE, "a");
        WriteFileLine(dataFileHandle, SOME_DEFAULT_MAP);
        CloseHandle(dataFileHandle);
    }
}

public OnMapStart(){
    if(bRecovered) {
        // Just update last map.
        if(FileExists(RECOVER_FILE)) {
            if(!DeleteFile(RECOVER_FILE)) {
                LogError("[Map Recovery] Warning: Failed to delete \"%s\" possibly due to lacking permissions.", RECOVER_FILE);
            }
        }

        new Handle:inf = OpenFile(RECOVER_FILE, "w+");
        if (inf == INVALID_HANDLE){
            LogError("[Map Recovery] Failed to open/create file '%s'",RECOVER_FILE);
            return;
        }
        decl String:CurrentMap[256];
        GetCurrentMap(CurrentMap, sizeof(CurrentMap));

        WriteFileLine(inf, CurrentMap);
        CloseHandle(inf);
    }
    else {
        // Recover the Map.
        new Handle:inf = OpenFile(RECOVER_FILE, "r");
        if (inf == INVALID_HANDLE){
            LogError("[Map Recovery] Failed to open file '%s'",RECOVER_FILE);
            return;
        }
        decl String:LastMap[256];
        ReadFileLine(inf, LastMap, sizeof(LastMap));
        CloseHandle(inf);

        bRecovered = true;

        LogMessage("[Map Recovery] Changed map to %s after crash!", LastMap);
        ForceChangeLevel(LastMap, "Map Recovery");
    }
}
