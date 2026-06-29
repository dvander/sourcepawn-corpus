/*
"special_point_teleport"
{
    "cooldown"         "6.0"      // Time in seconds before the ability can be used again
    "initial"          "8.0"      // Initial cooldown when ability is first gained
    "charges"          "1"        // How many charges are available at once
    "recharge"         "10.0"     // Time in seconds to recharge one charge
    "stack"            "3"        // Maximum number of charges that can be held
    "maxdist"          "9999.0"   // Maximum distance allowed for teleportation
    "preverse"         "0"        // Teleport in reverse order? 0 = No, 1 = Yes
    "buttonmode"       "11"       // Keybind: 11 = Mouse2, 13 = Reload, 25 = Mouse3
    "hud_x"            "-1.0"     // HUD X position (-1 = auto)
    "hud_y"            "0.75"     // HUD Y position (0.75 = 75% from top)
    "strings"          "Point Teleports: [%s][%d/%d]"   // Text displayed on HUD

    "clone"            "2.0"      // Duration (in seconds) of teleport clone
    "cost"             "25"       // Rage cost to use the ability

    "do slot before low"   "1"    // Ability slot to run BEFORE this one (low range)
    "do slot before high"  "2"    // Ability slot to run BEFORE this one (high range)
    "do slot after low"    "3"    // Ability slot to run AFTER this one (low range)
    "do slot after high"   "4"    // Ability slot to run AFTER this one (high range)

    "plugin_name"      "ff2r_point_teleport"   // Plugin providing this ability
}


*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_NAME    "Freak Fortress 2 Rewrite: Point Teleport"
#define PLUGIN_AUTHOR  "Haunted Bone"
#define PLUGIN_DESC    "Advanced Point Teleport ability for FF2R"

#define MAJOR_REVISION "2"
#define MINOR_REVISION "0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXTF2PLAYERS    MAXPLAYERS+1
#define NOPE_AVI         "vo/engineer_no01.mp3"
#define AB_DENYUSE       "common/wpn_denyselect.wav"

public Plugin myinfo = 
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

float g_fCooldown[MAXPLAYERS+1];
float g_fNextRecharge[MAXPLAYERS+1];
int g_iUses[MAXPLAYERS+1];
int g_iMaxStack[MAXPLAYERS+1];
bool g_bHasAbility[MAXPLAYERS+1];
bool g_bPreserveMomentum[MAXPLAYERS+1];
int g_iButtonMode[MAXPLAYERS+1];
float g_fMaxDist[MAXPLAYERS+1];
float g_fHudX[MAXPLAYERS+1];
float g_fHudY[MAXPLAYERS+1];
char g_sHudFormat[MAXPLAYERS+1][128];
float g_fCloneDuration[MAXPLAYERS+1];
float g_fCost[MAXPLAYERS+1];
int g_iSlotBeforeLow[MAXPLAYERS+1];
int g_iSlotBeforeHigh[MAXPLAYERS+1];
int g_iSlotAfterLow[MAXPLAYERS+1];
int g_iSlotAfterHigh[MAXPLAYERS+1];

Handle g_hHudSync;
bool ResizeTraceFailed;

public void OnPluginStart()
{
    g_hHudSync = CreateHudSynchronizer();
}

public void OnClientDisconnect(int client)
{
    ResetClientVariables(client);
}

void ResetClientVariables(int client)
{
    g_bHasAbility[client] = false;
    g_fCooldown[client] = 0.0;
    g_fNextRecharge[client] = 0.0;
    g_iUses[client] = 0;
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
    if (!setup || FF2R_GetGamemodeType() != 2)
        return;

    if (!IsClientInBlueTeam(client))
        return;

    AbilityData ability = cfg.GetAbility("special_point_teleport");
    if (ability != null && ability.IsMyPlugin())
    {
        LoadAbilitySettings(client, ability);
        g_bHasAbility[client] = true;
    }
    else
    {
        ResetClientVariables(client);
    }
}

void LoadAbilitySettings(int client, AbilityData ability)
{
    float initial = ability.GetFloat("initial", 8.0);
    g_fCooldown[client] = (initial > 0.0) ? GetGameTime() + initial : 0.0;
    
    g_iUses[client] = ability.GetInt("charges", 1);
    g_iMaxStack[client] = ability.GetInt("stack", 3);
    
    if (g_iUses[client] < g_iMaxStack[client])
    {
        g_fNextRecharge[client] = GetGameTime() + ability.GetFloat("recharge", 10.0);
    }
    
    g_fMaxDist[client] = ability.GetFloat("maxdist", 9999.0);
    if (g_fMaxDist[client] > 9999.0) g_fMaxDist[client] = 9999.0;
    
    g_bPreserveMomentum[client] = ability.GetBool("preverse", false);
    g_iButtonMode[client] = ability.GetInt("buttonmode", 11);
    g_fHudX[client] = ability.GetFloat("hud_x", -1.0);
    g_fHudY[client] = ability.GetFloat("hud_y", 0.75);
    ability.GetString("strings", g_sHudFormat[client], sizeof(g_sHudFormat[]), "Point Teleports: [%s][%d/%d]");
    
    // New parameters
    g_fCloneDuration[client] = ability.GetFloat("clone", 0.0);
    g_fCost[client] = ability.GetFloat("cost", 0.0);
    g_iSlotBeforeLow[client] = ability.GetInt("do slot before low", -1);
    g_iSlotBeforeHigh[client] = ability.GetInt("do slot before high", -1);
    g_iSlotAfterLow[client] = ability.GetInt("do slot after low", -1);
    g_iSlotAfterHigh[client] = ability.GetInt("do slot after high", -1);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!ShouldProcessClient(client))
        return Plugin_Continue;

    ProcessButtonPress(client, buttons);
    UpdateRechargeSystem(client);
    DisplayHud(client);

    return Plugin_Continue;
}

bool ShouldProcessClient(int client)
{
    return (g_bHasAbility[client] && 
            IsPlayerAlive(client) && 
            IsClientInBlueTeam(client) && 
            FF2R_GetBossData(client) != null);
}

void ProcessButtonPress(int client, int buttons)
{
    static int oldButtons[MAXPLAYERS+1];
    int button = GetClientButton(g_iButtonMode[client]);

    if ((buttons & button) && !(oldButtons[client] & button))
    {
        AttemptTeleport(client);
    }
    oldButtons[client] = buttons;
}

void AttemptTeleport(int client)
{
    float gameTime = GetGameTime();
    
    if (g_fCooldown[client] > gameTime)
    {
        EmitSoundToClient(client, NOPE_AVI);
        return;
    }

    if (g_iUses[client] <= 0)
        return;

    if (g_fCost[client] > 0.0)
    {
        BossData boss = FF2R_GetBossData(client);
        float rage = GetBossCharge(boss, "0") + boss.GetFloat("ragemin", 0.0);
        if (rage < g_fCost[client])
        {
            EmitSoundToClient(client, AB_DENYUSE);
            return;
        }
    }

    float targetPos[3];
    if (GetSafeAimLocation(client, g_fMaxDist[client], targetPos))
    {
        if (g_fCloneDuration[client] > 0.0)
        {
            CreateClone(client, g_fCloneDuration[client]);
        }

        if (g_iSlotBeforeLow[client] != -1 || g_iSlotBeforeHigh[client] != -1)
        {
            FF2R_DoBossSlot(client, g_iSlotBeforeLow[client], g_iSlotBeforeHigh[client]);
        }

        ExecuteTeleport(client, targetPos);

        if (g_iSlotAfterLow[client] != -1 || g_iSlotAfterHigh[client] != -1)
        {
            FF2R_DoBossSlot(client, g_iSlotAfterLow[client], g_iSlotAfterHigh[client]);
        }

        if (g_fCost[client] > 0.0)
        {
            BossData boss = FF2R_GetBossData(client);
            float rage = GetBossCharge(boss, "0") + boss.GetFloat("ragemin", 0.0);
            SetBossCharge(boss, "0", rage - g_fCost[client]);
        }
    }
    else
    {
        EmitSoundToClient(client, NOPE_AVI);
    }
}

void CreateClone(int client, float lifetime)
{
    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);

    int clone = CreateEntityByName("prop_dynamic_override");
    if (IsValidEntity(clone))
    {
        char model[PLATFORM_MAX_PATH];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        DispatchKeyValue(clone, "model", model);
        DispatchKeyValue(clone, "spawnflags", "256");
        DispatchKeyValue(clone, "solid", "0");
        SetEntProp(clone, Prop_Send, "m_CollisionGroup", 11);

        int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
        float cycle = GetEntPropFloat(client, Prop_Send, "m_flCycle");
        float playbackRate = GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate");
        
        float scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
        SetEntPropFloat(clone, Prop_Send, "m_flModelScale", scale);

        DispatchSpawn(clone);
        TeleportEntity(clone, pos, ang, NULL_VECTOR);
        
        SetEntProp(clone, Prop_Send, "m_nSequence", sequence);
        SetEntPropFloat(clone, Prop_Send, "m_flCycle", cycle);
        SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", playbackRate);

        SetEntityRenderMode(clone, RENDER_NORMAL);
        SetEntityRenderColor(clone, 255, 255, 255, 255);

        CreateTimer(lifetime, Timer_RemoveClone, EntIndexToEntRef(clone), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_RemoveClone(Handle timer, any ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity > MaxClients && IsValidEntity(entity))
        AcceptEntityInput(entity, "Kill");
        
    return Plugin_Continue;
}

bool GetSafeAimLocation(int client, float maxDistance, float result[3])
{
    float sizeMultiplier = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
    
    float startPos[3], endPos[3], testPos[3], eyeAng[3];
    
    GetClientEyePosition(client, startPos);
    GetClientEyeAngles(client, eyeAng);
    
    TR_TraceRayFilter(startPos, eyeAng, MASK_PLAYERSOLID, RayType_Infinite, TracePlayersAndBuildings, client);
    TR_GetEndPosition(endPos);
    
    float distance = GetVectorDistance(startPos, endPos);
    if (distance < 82.0)
        return false;
        
    if (distance > maxDistance)
        constrainDistance(startPos, endPos, distance, maxDistance);
    else
        constrainDistance(startPos, endPos, distance, distance - 1.0);
    
    bool found = false;
    for (int x = 0; x < 3; x++)
    {
        if (found) break;
    
        float xOffset;
        if (x == 0) xOffset = 0.0;
        else if (x == 1) xOffset = 12.5 * sizeMultiplier;
        else xOffset = 25.0 * sizeMultiplier;
        
        if (endPos[0] < startPos[0])
            testPos[0] = endPos[0] + xOffset;
        else if (endPos[0] > startPos[0])
            testPos[0] = endPos[0] - xOffset;
        else if (xOffset != 0.0)
            break;
    
        for (int y = 0; y < 3; y++)
        {
            if (found) break;

            float yOffset;
            if (y == 0) yOffset = 0.0;
            else if (y == 1) yOffset = 12.5 * sizeMultiplier;
            else yOffset = 25.0 * sizeMultiplier;

            if (endPos[1] < startPos[1])
                testPos[1] = endPos[1] + yOffset;
            else if (endPos[1] > startPos[1])
                testPos[1] = endPos[1] - yOffset;
            else if (yOffset != 0.0)
                break;
        
            for (int z = 0; z < 3; z++)
            {
                if (found) break;

                float zOffset;
                if (z == 0) zOffset = 0.0;
                else if (z == 1) zOffset = 41.5 * sizeMultiplier;
                else zOffset = 83.0 * sizeMultiplier;

                if (endPos[2] < startPos[2])
                    testPos[2] = endPos[2] + zOffset;
                else if (endPos[2] > startPos[2])
                    testPos[2] = endPos[2] - zOffset;
                else if (zOffset != 0.0)
                    break;

                static float tmpPos[3];
                TR_TraceRayFilter(endPos, testPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceWallsOnly, client);
                TR_GetEndPosition(tmpPos);
                if(testPos[0] != tmpPos[0] || testPos[1] != tmpPos[1] || testPos[2] != tmpPos[2])
                    continue;
                
                found = IsSpotSafe(client, testPos, sizeMultiplier);
            }
        }
    }
    
    if(!found)
        return false;
    
    result = testPos;
    return true;
}

bool IsSpotSafe(int client, float playerPos[3], float sizeMultiplier)
{
    ResizeTraceFailed = false;
    static float mins[3];
    static float maxs[3];
    mins[0] = -24.0 * sizeMultiplier;
    mins[1] = -24.0 * sizeMultiplier;
    mins[2] = 0.0;
    maxs[0] = 24.0 * sizeMultiplier;
    maxs[1] = 24.0 * sizeMultiplier;
    maxs[2] = 82.0 * sizeMultiplier;

    if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2], client)) return false;
    if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2], client)) return false;

    return true;
}

bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset, int clientIdx)
{
    static float tmpOrigin[3];
    tmpOrigin[0] = bossOrigin[0];
    tmpOrigin[1] = bossOrigin[1];
    tmpOrigin[2] = bossOrigin[2];
    
    static float targetOrigin[3];
    targetOrigin[0] = bossOrigin[0] + xOffset;
    targetOrigin[1] = bossOrigin[1] + yOffset;
    targetOrigin[2] = bossOrigin[2];
    
    if (!(xOffset == 0.0 && yOffset == 0.0))
        if (!Resize_OneTrace(tmpOrigin, targetOrigin, clientIdx))
            return false;
            
    tmpOrigin[0] = targetOrigin[0];
    tmpOrigin[1] = targetOrigin[1];
    tmpOrigin[2] = targetOrigin[2] + zOffset;

    if (!Resize_OneTrace(targetOrigin, tmpOrigin, clientIdx))
        return false;
        
    targetOrigin[0] = bossOrigin[0];
    targetOrigin[1] = bossOrigin[1];
    targetOrigin[2] = bossOrigin[2] + zOffset;
        
    if (!(xOffset == 0.0 && yOffset == 0.0))
        if (!Resize_OneTrace(tmpOrigin, targetOrigin, clientIdx))
            return false;
        
    return true;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3], int clientIdx)
{
    static float result[3];
    TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, Resize_TracePlayersAndBuildings, clientIdx);
    if(ResizeTraceFailed)
        return false;
        
    TR_GetEndPosition(result);
    if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
        return false;
    
    return true;
}

public bool Resize_TracePlayersAndBuildings(int entity, int contentsMask, any clientIdx)
{
    if(IsValidClient(entity) && IsPlayerAlive(entity) && GetClientTeam(entity) != GetClientTeam(clientIdx))
        ResizeTraceFailed = true;
    else if(IsValidEntity(entity))
    {
        static char classname[48];
        GetEntityClassname(entity, classname, sizeof(classname));
        if (StrEqual(classname, "obj_sentrygun") || 
            StrEqual(classname, "obj_dispenser") || 
            StrEqual(classname, "obj_teleporter") || 
            StrEqual(classname, "prop_dynamic") || 
            StrEqual(classname, "func_physbox") || 
            StrEqual(classname, "func_breakable"))
        {
            ResizeTraceFailed = true;
        }
    }
    
    return false;
}

void ExecuteTeleport(int client, const float pos[3])
{
    EmitSoundToAll("misc/halloween/spell_teleport.wav", client);
    
    float velocity[3];
    if (g_bPreserveMomentum[client])
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    else
        velocity = view_as<float>({0.0, 0.0, 0.0});
    
    TeleportEntity(client, pos, NULL_VECTOR, velocity);

    AbilityData ability = FF2R_GetBossData(client).GetAbility("special_point_teleport");
    if (ability != null)
    {
        g_fCooldown[client] = GetGameTime() + ability.GetFloat("cooldown", 6.0);
    }
    
    g_iUses[client]--;
    
    if (g_iUses[client] < g_iMaxStack[client] && g_fNextRecharge[client] <= 0.0)
    {
        g_fNextRecharge[client] = GetGameTime() + ability.GetFloat("recharge", 10.0);
    }
}

void UpdateRechargeSystem(int client)
{
    float gameTime = GetGameTime();
    
    if (g_iUses[client] < g_iMaxStack[client] && g_fNextRecharge[client] > 0.0 && gameTime >= g_fNextRecharge[client])
    {
        g_iUses[client]++;
        
        if (g_iUses[client] < g_iMaxStack[client])
        {
            AbilityData ability = FF2R_GetBossData(client).GetAbility("special_point_teleport");
            if (ability != null)
            {
                g_fNextRecharge[client] = gameTime + ability.GetFloat("recharge", 10.0);
            }
        }
        else
        {
            g_fNextRecharge[client] = 0.0;
        }
    }
}

void DisplayHud(int client)
{
    char statusInfo[64];
    int color[4] = {255, 255, 255, 255};

    float remainingCooldown = g_fCooldown[client] - GetGameTime();
    
    if (g_iUses[client] <= 0)
    {
        Format(statusInfo, sizeof(statusInfo), "Empty");
        color = {255, 64, 64, 255};
    }
    else if (remainingCooldown > 0.0)
    {
        Format(statusInfo, sizeof(statusInfo), "%.1fs", remainingCooldown);
        color = {255, 255, 64, 255};
    }
    else
    {
        Format(statusInfo, sizeof(statusInfo), "Ready");
        color = {64, 255, 64, 255};
    }

    SetHudTextParams(g_fHudX[client], g_fHudY[client], 0.1, color[0], color[1], color[2], color[3]);
    ShowSyncHudText(client, g_hHudSync, g_sHudFormat[client], statusInfo, g_iUses[client], g_iMaxStack[client]);
}

public bool TracePlayersAndBuildings(int entity, int contentsMask, any clientIdx)
{
    if(IsValidClient(entity) && IsPlayerAlive(entity) && GetClientTeam(entity) != GetClientTeam(clientIdx))
        return true;
    else if(IsValidClient(entity) && IsPlayerAlive(entity))
        return false;
    
    return IsValidEntity(entity);
}

public bool TraceWallsOnly(int entity, int contentsMask, any clientIdx)
{
    return false;
}

void constrainDistance(const float startPoint[3], float endPoint[3], float distance, float maxDistance)
{
    float constrainFactor = maxDistance / distance;
    endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
    endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
    endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

float GetBossCharge(ConfigData cfg, const char[] slot, float defaul = 0.0)
{
    int length = strlen(slot)+7;
    char[] buffer = new char[length];
    Format(buffer, length, "charge%s", slot);
    return cfg.GetFloat(buffer, defaul);
}

void SetBossCharge(ConfigData cfg, const char[] slot, float amount)
{
    int length = strlen(slot)+7;
    char[] buffer = new char[length];
    Format(buffer, length, "charge%s", slot);
    cfg.SetFloat(buffer, amount);
}

stock bool IsClientInBlueTeam(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == view_as<int>(TFTeam_Blue));
}

stock int GetClientButton(int key)
{
    switch (key)
    {
        case 11: return IN_ATTACK2;
        case 13: return IN_RELOAD;
        case 25: return IN_ATTACK3;
        default: return IN_ATTACK2;
    }
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
    if (client <= 0 || client > MaxClients)
        return false;
    if (!IsClientInGame(client) || !IsClientConnected(client))
        return false;
    if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
        return false;
    return true;
}