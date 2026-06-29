#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

ConVar sb_all_bot_game;

public Plugin myinfo = {
    name = "[L4D2] Prevent Versus Game From Shutting Down",
    author = "MoRanYue",
    description = "Prevent versus game from shutting down if there is only 1 player.",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int error_len) {
    EngineVersion engine_version = GetEngineVersion();
    if (engine_version != Engine_Left4Dead2) {
        strcopy(error, error_len, "This plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }

    MarkNativeAsOptional("InfoEditor_GetString");

    return APLRes_Success;
}

public void OnPluginStart() {
    sb_all_bot_game = FindConVar("sb_all_bot_game");
}

public void OnClientAuthorized(int client, const char[] auth) {
    if (!sb_all_bot_game.BoolValue) {
        sb_all_bot_game.SetBool(true, false, false);
        PrintToServer("sb_all_bot_game is enabled now.");
    }
}
public void OnClientDisconnect(int client) {
    CreateTimer(3.0, SetSbAllBotGame);
}

public void SetSbAllBotGame(Handle timer) {
    if (!IsARealPlayerIn()) {
        sb_all_bot_game.RestoreDefault(false, false);
        PrintToServer("sb_all_bot_game is disabled now.");
    }
}

bool IsARealPlayerIn() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && !IsFakeClient(i)) {
            return true;
        }
    }
    return false;
}