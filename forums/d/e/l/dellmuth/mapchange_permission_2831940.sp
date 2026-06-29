// Plugin: Map Change Permission
// Description: Allows certain players to change the map
// Game: Counter-Strike: Source

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "MapChangePermission"
#define PLUGIN_VERSION "1.0"
#define PERMISSION_FLAG ADMFLAG_CUSTOM1
#define COMMAND_MAP_CHANGE "sm_changemap"

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = "Xl Oldie Dellmuth",
    description = "Allows specific players to change maps.",
    version = PLUGIN_VERSION,
    url = "www.xloldies.de"
};

public void OnPluginStart() {
    // Register the command
    RegAdminCmd(COMMAND_MAP_CHANGE, Command_ChangeMap, PERMISSION_FLAG);
    PrintToServer("%s v%s loaded successfully!", PLUGIN_NAME, PLUGIN_VERSION);
}

// Map change command handler
public Action:Command_ChangeMap(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "[MapChange] Usage: sm_changemap <mapname>");
        return Plugin_Handled;
    }

    char mapName[64];
    GetCmdArg(1, mapName, sizeof(mapName));

    if (!ValidateMap(mapName)) {
        ReplyToCommand(client, "[MapChange] Invalid map name: %s", mapName);
        return Plugin_Handled;
    }

    // Announce the map change
    PrintToChatAll("[MapChange] %N changed the map to %s", client, mapName);

    // Change the map
    ServerCommand("changelevel %s", mapName);

    return Plugin_Handled;
}

// Helper function to check if a map exists
bool:ValidateMap(const char[] mapName) {
    char mapPath[PLATFORM_MAX_PATH];
    Format(mapPath, sizeof(mapPath), "maps/%s.bsp", mapName);

    return FileExists(mapPath);
}
