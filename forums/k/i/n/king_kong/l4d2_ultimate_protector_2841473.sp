#include <sourcemod>
#include <sdktools>
#include <sourcescramble>
#include <dhooks>

#define ENT_THRESHOLD 1850 
#define ENT_CRITICAL 2010 

public Plugin myinfo = { 
    name = "L4D2 Ultimate Entity Protector", 
    author = "AI", 
    version = "2.4" 
};

MemoryPatch g_hEdictPatch;

public void OnPluginStart() { 
    GameData hGameData = new GameData("l4d2_entity_fix"); 
    if (hGameData == null) SetFailState("Gamedata l4d2_entity_fix.txt not found"); 

    // 1. SourceScramble Patch 
    g_hEdictPatch = MemoryPatch.CreateFromConf(hGameData, "Ignore_Edict_Overflow"); 
    if (g_hEdictPatch != null && g_hEdictPatch.Validate()) { 
        g_hEdictPatch.Enable(); 
    } 

    // 2. DHooks Detour 
    DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "DD::CreateEntityByName"); 
    if (hDetour != null) { 
        hDetour.Enable(Hook_Pre, Detour_OnCreateEntity); 
    } 

    // --- 保留你的 Hook，並加上關鍵保障事件 ---
    HookEvent("round_end", Event_RoundEnd); 
    HookEvent("mission_lost", Event_RoundEnd); // 【新增保障】團滅瞬間執行清理
    HookEvent("map_transition", Event_RoundEnd); // 【新增保障】換圖執行清理

    CreateTimer(30.0, Timer_AutoClean, _, TIMER_REPEAT); 
    delete hGameData; 
} 

public MRESReturn Detour_OnCreateEntity(DHookReturn hReturn, DHookParam hParams) { 
    if (GetEntityCount() < ENT_THRESHOLD) return MRES_Ignored; 

    char classname[64]; 
    hParams.GetString(1, classname, sizeof(classname)); 
    if (StrContains(classname, "gib") != -1 || StrContains(classname, "particle") != -1 || StrContains(classname, "env_physics_blocker") != -1) { 
        hReturn.Value = -1; // 修改為-1，這是更安全的拒絕方式
        return MRES_Supercede; 
    } 
    return MRES_Ignored; 
} 

public Action Timer_AutoClean(Handle timer) {
    if (GetEntityCount() > ENT_THRESHOLD) {
        ForceCleanAllGarbage();
    }
    return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) { 
    ForceCleanAllGarbage(); 
} 

// 補完你之前中斷的函數
int ForceCleanAllGarbage() { 
    int count = 0; 
    char classname[64]; 
    for (int i = MaxClients + 1; i <= GetMaxEntities(); i++) { 
        if (!IsValidEntity(i)) continue; 
        
        GetEntityClassname(i, classname, sizeof(classname)); 

        // 判定清理目標
        if (StrContains(classname, "gib") != -1 || 
            StrContains(classname, "physics") != -1 ||
            (StrContains(classname, "weapon_") != -1 && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1)) 
        { 
            AcceptEntityInput(i, "Kill"); // 使用最穩定的 Kill
            count++; 
        } 
    } 
    return count;
}
