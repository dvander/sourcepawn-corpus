#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// Definitions
#define PLUGIN_VERSION "1.3"
#define KRITZ_INDEX 35
#define KRITZ_NAME "tf_weapon_medigun"
#define TF2_PLAYER_TAUNTING	    (1 << 7)    // 128 Taunting

// Arrays
new Handle:g_Timers[MAXPLAYERS+1] = INVALID_HANDLE;

// HANDLES
new Handle:cvarPath;

public Plugin:myinfo = {
    name = "Smoke Weed Every Day",
    author = "Mecha the Slag",
    description = "Plays a very popular tune when medics heal with the kritzkrieg!",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    CreateConVar("weed_version", PLUGIN_VERSION, "Version of the plugin");
    cvarPath = CreateConVar("weed_path", "imgay/SmokeWeedErryDay.mp3", "Path to the sound to play");
    RegConsoleCmd("taunt", Command_Taunt, "Taunt");
    HookEvent("player_spawn", Player_Spawn);
}

public OnMapStart() {
    new String:path[PLATFORM_MAX_PATH];
    GetConVarString(cvarPath, path, sizeof(path));
    PrecacheSound(path);
    new String:input[PLATFORM_MAX_PATH];
    Format(input, sizeof(input), "sound/%s", path);
    AddFileToDownloadsTable(input);
}

public Action:Command_Taunt(client, args) {
    if( !IsValidClient(client) || !IsPlayerAlive(client))
        return Plugin_Continue;
        
    new String:weapon[128];
    GetClientWeapon(client, weapon, sizeof(weapon));
    
    if(TF2_GetPlayerClass(client) == TFClass_Medic && StrEqual(weapon, KRITZ_NAME) && !(GetEntData(client, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_TAUNTING) && g_Timers[client] == INVALID_HANDLE) {
        g_Timers[client] = CreateTimer(2.0, Timer_Taunt, client);
    }    

    return Plugin_Continue;
}

public Action:Timer_Taunt(Handle:timer, any:client) {
    if (!IsValidClient(client)) return;
    if (g_Timers[client] == INVALID_HANDLE) return;
    g_Timers[client] = INVALID_HANDLE;
    if (IsPlayerAlive(client)) {
        new edict;
        new defIdx;
        new String:weapon[128];
        GetClientWeapon(client, weapon, sizeof(weapon));
        if (TF2_GetPlayerClass(client) == TFClass_Medic && StrEqual(weapon, KRITZ_NAME) && (GetEntData(client, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & TF2_PLAYER_TAUNTING)) {
            for (new x=0; x<11; x++) {
                if((edict = GetPlayerWeaponSlot(client, x)) != -1) {
                    defIdx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
                    if (defIdx == KRITZ_INDEX) {
                        new String:path[PLATFORM_MAX_PATH];
                        GetConVarString(cvarPath, path, sizeof(path));
                        EmitSoundToAll(path, client);
                    }
                }
            }
        }
    }
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(client)) {
        g_Timers[client] = INVALID_HANDLE;
    }
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}