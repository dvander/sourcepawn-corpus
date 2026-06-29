#pragma semicolon 1

#include <sourcemod>

// =====================================================================
// INIT
// =====================================================================

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = "Scoreboard Block",
    description = "Block scoreboard on map end",
    author = "Otstrel.ru Team",
    version = PLUGIN_VERSION,
    url = "http://otstrel.ru"
};

// =====================================================================
// GLOBAL VARIABLES
// =====================================================================

// =====================================================================
// LOAD & UNLOAD
// =====================================================================
public OnPluginStart() {
    new Handle:Version = CreateConVar("sm_scoresblock_version", PLUGIN_VERSION,    "Scoreboard Block version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    // Just to make sure they it updates the convar version if they just had the plugin reload on map change
    SetConVarString(Version, PLUGIN_VERSION);

    HookUserMessage(GetUserMessageId("VGUIMenu"), Event_VGUIMenu, true);
}

// =====================================================================
// EVENTS & HOOKS
// =====================================================================

public Action:Event_VGUIMenu(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit) {
    new String:buffer[10];
    BfReadString(hBitBuffer, buffer, sizeof(buffer));

    // Read parameters, filter scoreboard
    if ( strcmp(buffer, "scores", false) == 0 ) {
        if ( BfReadByte(hBitBuffer) == 1 && BfReadByte(hBitBuffer) == 0 ) {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

// =====================================================================
// HELPERS
// =====================================================================
