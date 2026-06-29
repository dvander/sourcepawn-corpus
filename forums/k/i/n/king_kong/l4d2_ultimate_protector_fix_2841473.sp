#include <sourcemod>
#include <sdktools>
#include <sourcescramble>
#include <dhooks>

#define ENT_THRESHOLD 1850 
#define ENT_CRITICAL 2010 

public Plugin myinfo = { 
    name = "L4D2 Ultimate Entity Protector", 
    author = "AI", 
    version = "2.5" 
};

MemoryPatch g_hEdictPatch;

public void OnPluginStart() { 
    GameData hGameData = new GameData("l4d2_entity_fix"); 
    if (hGameData == null) SetFailState("Gamedata l4d2_entity_fix.txt not found"); 

    // 1. SourceScramble Patch (防止底層 ED_Alloc 報錯)
    g_hEdictPatch = MemoryPatch.CreateFromConf(hGameData, "Ignore_Edict_Overflow"); 
    if (g_hEdictPatch != null && g_hEdictPatch.Validate()) { 
        g_hEdictPatch.Enable(); 
    } 

    // 2. DHooks Detour (攔截生成指令)
    DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "DD::CreateEntityByName"); 
    if (hDetour != null) { 
        hDetour.Enable(Hook_Pre, Detour_OnCreateEntity); 
    } 

    HookEvent("round_end", Event_RoundEnd); 
    HookEvent("mission_lost", Event_RoundEnd); 
    HookEvent("map_transition", Event_RoundEnd); 

    CreateTimer(30.0, Timer_AutoClean, _, TIMER_REPEAT); 
    delete hGameData; 
} 

public MRESReturn Detour_OnCreateEntity(DHookReturn hReturn, DHookParam hParams) { 
    int iCurrentCount = GetEntityCount();

    // 【行動 1】2010 最後防線：全面禁生，確保玩家不閃退
    if (iCurrentCount >= ENT_CRITICAL) {
        hReturn.Value = -1;
        return MRES_Supercede;
    }

    // 【行動 2】1850 預防線：若低於 1850 則完全不干預
    if (iCurrentCount < ENT_THRESHOLD) return MRES_Ignored; 

    // --- 以下為您原有的垃圾過濾邏輯 ---
    char classname[64]; 
    hParams.GetString(1, classname, sizeof(classname)); 
    
    if (StrContains(classname, "gib") != -1 || 
        StrContains(classname, "particle") != -1 || 
        StrContains(classname, "env_physics_blocker") != -1) { 
        hReturn.Value = -1; 
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

// 補完後的清理函數
int ForceCleanAllGarbage() { 
    int count = 0; 
    char classname[64]; 
    int maxEnts = GetMaxEntities();
    for (int i = MaxClients + 1; i <= maxEnts; i++) { 
        if (!IsValidEntity(i)) continue; 
        
        GetEntityClassname(i, classname, sizeof(classname)); 

        if (StrContains(classname, "gib") != -1 || 
            StrContains(classname, "physics") != -1 ||
            (StrContains(classname, "weapon_") != -1 && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1)) 
        { 
            AcceptEntityInput(i, "Kill"); 
            count++; 
        } 
    } 
    return count;
}

