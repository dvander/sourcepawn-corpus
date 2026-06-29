#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_PREFIX "\x04[Map Weapons Manager]\x01 "

#define MAX_WEAPON_SPAWNS 256

public Plugin myinfo = {
	name = "Map Weapons Manager",
	author = "godzcsgo",
	version = "1.0.0",
};

Handle g_hWeaponSpawns = null;
bool g_bLateLoaded;

bool g_bCvarOn;
bool g_bCvarDebug;
float g_fCvarTime;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    g_bLateLoaded = late;
    return APLRes_Success;
}

public void OnPluginStart() {
    Handle hCvar;

    hCvar = CreateConVar("sm_map_weapons_manager_on", "1", "Enable/Disable the plugin", FCVAR_NOTIFY);
    HookConVarChange(hCvar, OnWeaponsManagerOnChange);
    g_bCvarOn = GetConVarBool(hCvar);

    hCvar = CreateConVar("sm_map_weapons_manager_debug", "0", "Enable/Disable debug messages", FCVAR_NOTIFY);
    HookConVarChange(hCvar, OnWeaponsManagerDebugChange);
    g_bCvarDebug = GetConVarBool(hCvar);

    hCvar = CreateConVar("sm_map_weapons_manager_time", "10", "Time in seconds to respawn weapons after pickup", FCVAR_NOTIFY);
    HookConVarChange(hCvar, OnWeaponsManagerTimeChange);
    g_fCvarTime = GetConVarFloat(hCvar);

    g_hWeaponSpawns = CreateArray(MAX_WEAPON_SPAWNS);

    RegAdminCmd("sm_create_weapon_spawn", CMD_CreateWeaponSpawn, ADMFLAG_GENERIC, "Create a weapon spawn at your current location");

    LoadTranslations("map_weapons_manager.phrases");

    AutoExecConfig(true);

    if (g_bLateLoaded) {
        for (int i; i <= MaxClients; i++) {
            if (IsClientValid(i)) {
                SDKHook(i, SDKHook_WeaponEquip, OnWeaponEquip);
            }
        } 
    }
}

public void OnMapStart() {
    ReadWeaponSpawnLocations();
}

public void OnConfigsExecuted() {
	AutoExecConfig();
}

public void OnClientPostAdminCheck(int client) {
    if (IsClientValid(client)) {
        SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	}
}

public void OnWeaponsManagerOnChange(Handle hCvar, const char[] oldValue, const char[] newValue) {
    g_bCvarOn = GetConVarBool(hCvar);
}

public void OnWeaponsManagerDebugChange(Handle hCvar, const char[] oldValue, const char[] newValue) {
    g_bCvarDebug = GetConVarBool(hCvar);
}

public void OnWeaponsManagerTimeChange(Handle hCvar, const char[] oldValue, const char[] newValue) {
    g_fCvarTime = GetConVarFloat(hCvar);
}

public Action OnWeaponEquip(int client, int entity) {
    if (!g_bCvarOn) return Plugin_Continue;

    char weapon_name[64];
    GetEntPropString(entity, Prop_Data, "m_iClassname", weapon_name, sizeof(weapon_name));

    if (StrContains(weapon_name, "weapon_", false) != -1) {
        float weapon_coords[3];
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", weapon_coords);

        float weapon_angles[3];
        GetEntPropVector(entity, Prop_Data, "m_angRotation", weapon_angles);

        g_bCvarDebug && PrintToConsole(client, "sm_create_weapon_spawn %s %f %f %f %f %f %f", weapon_name, weapon_coords[0], weapon_coords[1], weapon_coords[2], weapon_angles[0], weapon_angles[1], weapon_angles[2]);

        int size = GetArraySize(g_hWeaponSpawns);

        for (int i = 0; i < size; i++) {
            Handle trie = GetArrayCell(g_hWeaponSpawns, i);

            float coords[3];
            GetTrieArray(trie, "coords", coords, sizeof(coords));

            float angles[3];
            GetTrieArray(trie, "angles", angles, sizeof(angles));

            char weapon[64];
            GetTrieString(trie, "weapon", weapon, sizeof(weapon));

            float dist = GetVectorDistance(weapon_coords, coords);

            if (dist < 0.1 && StrEqual(weapon, weapon_name)) {
                g_bCvarDebug && PrintToConsole(client, "%t", "Weapon_Picked_Up", weapon_name, g_fCvarTime);
                CreateTimer(g_fCvarTime, RespawnWeapon, i, TIMER_FLAG_NO_MAPCHANGE);
                break;
            }
        }
    }

    return Plugin_Continue;
}

public Action CMD_CreateWeaponSpawn(int client, int args) {
    if (args != 7) {
        PrintToChat(client, "%s%t", PLUGIN_PREFIX, "CMD_CreateWeaponSpawn_Usage");
        return Plugin_Handled;
    }

    char weapon[64];
    GetCmdArg(1, weapon, sizeof(weapon));

    char coords_x[32];
    GetCmdArg(2, coords_x, sizeof(coords_x));

    char coords_y[32];
    GetCmdArg(3, coords_y, sizeof(coords_y));

    char coords_z[32];
    GetCmdArg(4, coords_z, sizeof(coords_z));

    float coords[3];
    coords[0] = StringToFloat(coords_x);
    coords[1] = StringToFloat(coords_y);
    coords[2] = StringToFloat(coords_z);

    char angles_x[32];
    GetCmdArg(5, angles_x, sizeof(angles_x));

    char angles_y[32];
    GetCmdArg(6, angles_y, sizeof(angles_y));

    char angles_z[32];
    GetCmdArg(7, angles_z, sizeof(angles_z));

    float angles[3];
    angles[0] = StringToFloat(angles_x);
    angles[1] = StringToFloat(angles_y);
    angles[2] = StringToFloat(angles_z);

    Handle trie = CreateTrie();

    SetTrieArray(trie, "coords", coords, 3);
    SetTrieArray(trie, "angles", angles, 3);
    SetTrieString(trie, "weapon", weapon);

    PushArrayCell(g_hWeaponSpawns, trie);

    SaveWeaponSpawnLocation(client);

    return Plugin_Handled;
}

public Action RespawnWeapon(Handle timer, int spawn_index) {
    g_bCvarDebug && PrintToServer("%t", "Respawning_Weapon", spawn_index);

    Handle trie = GetArrayCell(g_hWeaponSpawns, spawn_index);

    float coords[3];
    GetTrieArray(trie, "coords", coords, sizeof(coords));

    float angles[3];
    GetTrieArray(trie, "angles", angles, sizeof(angles));

    char weapon[64];
    GetTrieString(trie, "weapon", weapon, sizeof(weapon));

    int index = CreateEntityByName(weapon);
    if (index == -1) return Plugin_Stop;

    DispatchKeyValueVector(index, "origin", coords);
    DispatchKeyValueVector(index, "angles", angles);
    DispatchKeyValue(index, "spawnflags", "1");
    DispatchSpawn(index);

    return Plugin_Continue;
}

public void ReadWeaponSpawnLocations() {
    int size = GetArraySize(g_hWeaponSpawns);

    if (size > 0) {
        for (int i = 0; i < size; i++) {
            CloseHandle(GetArrayCell(g_hWeaponSpawns, i));
        }
    }

    ClearArray(g_hWeaponSpawns);

    char path[512];
    BuildPath(Path_SM, path, sizeof(path), "configs/map_weapon_spawns");
    if (!DirExists(path)) CreateDirectory(path, 0o777);

    char map[64];
    GetCurrentMap(map, sizeof(map));
    StringToLowerCase(map);

    BuildPath(Path_SM, path, sizeof(path), "configs/map_weapon_spawns/%s.spawns.txt", map);

    if (!FileExists(path)) {
        Handle kv = CreateKeyValues("Spawns");
        KeyValuesToFile(kv, path);
    }

    Handle kv = CreateKeyValues("Spawns");
    FileToKeyValues(kv, path);

    if (!KvGotoFirstSubKey(kv)) {
        g_bCvarDebug && PrintToServer("[ERROR] No spawn entries found for map config: %s", path);
        return;
    }

    float coords[3];
    float angles[3];
    char weapon[64];

    do {
        KvGetVector(kv, "coords", coords);
        KvGetVector(kv, "angles", angles);
        KvGetString(kv, "weapon", weapon, sizeof(weapon));

        Handle trie = CreateTrie();

        SetTrieArray(trie, "coords", coords, 3);
        SetTrieArray(trie, "angles", angles, 3);
        SetTrieString(trie, "weapon", weapon);

        PushArrayCell(g_hWeaponSpawns, trie);
    } while (KvGotoNextKey(kv));

    CloseHandle(kv);
}

public void SaveWeaponSpawnLocation(int client) {
    char map[64];
    GetCurrentMap(map, sizeof(map));
    StringToLowerCase(map);

    char path[512];
    BuildPath(Path_SM, path, sizeof(path), "configs/map_weapon_spawns/%s.spawns.txt", map);

    Handle file = OpenFile(path, "w+");
    CloseHandle(file);

    float coords[3];
    float angles[3];
    char weapon[64];
    char sect_name[64];

    int size = GetArraySize(g_hWeaponSpawns);

    Handle kv = CreateKeyValues("Spawns");

    for (int i = 0; i < size; i++) {
        IntToString(i, sect_name, sizeof(sect_name));

        Handle trie = GetArrayCell(g_hWeaponSpawns, i);

        GetTrieArray(trie, "coords", coords, sizeof(coords));
        GetTrieArray(trie, "angles", angles, sizeof(angles));
        GetTrieString(trie, "weapon", weapon, sizeof(weapon));

        KvJumpToKey(kv, sect_name, true);

        KvSetVector(kv, "coords", coords);
        KvSetVector(kv, "angles", angles);
        KvSetString(kv, "weapon", weapon);

        KvGoBack(kv);
    }

    KeyValuesToFile(kv, path);

    CloseHandle(kv);

    if (client != 0) PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Weapon_Spawns_Saved");
}

stock void StringToLowerCase(char[] input) {
    int i = 0;

    while (input[i] != EOS) {
        if (!IsCharLower(input[i])) {
            input[i] = CharToLower(input[i]);
        } else {
            input[i] = input[i];
        }

        i++;
    }

    input[i + 1] = EOS;
}

stock bool IsClientValid(int client) {
    if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
        return true;
	}

    return false;
}