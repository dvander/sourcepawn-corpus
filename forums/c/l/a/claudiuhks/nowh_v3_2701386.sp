#include    <sourcemod>
#include    <sdktools>
#include    <sdkhooks>
#include    <cstrike>
#define     CONDITION_TO_RUN    (nAlivePlayers > 1 && nAlivePlayers < 11)   // Only Run If This Condition Is True
#define     MAX_EDICTS          32768
#define     IS_CLIENT(%1)       ((1) <= (%1) <= (MAXPLAYERS - 1))
#define     TIME_TO_TICK(%1)    (RoundToNearest((%1) / GetTickInterval()))
#define     TICK_TO_TIME(%1)    ((float(%1)) * GetTickInterval())
public Plugin myinfo =
{
    name        =   "SourceMod Anti-Cheat: No Wall Hack"                    , \
    author      =   "The SMAC Development Team"                             , \
    description =   "Blocks Any Kind Of Wall Hack"                          , \
    version     =   "0.8.7.3"                                               , \
    url         =   "https://github.com/Silenci0/SMAC"                      ,
};
enum
{
    OBS_MODE_NONE       = 0 , \
    OBS_MODE_DEATHCAM       , \
    OBS_MODE_FREEZECAM      , \
    OBS_MODE_FIXED          , \
    OBS_MODE_IN_EYE         , \
    OBS_MODE_CHASE          , \
    OBS_MODE_ROAMING        ,
};
bool g_bEnabled = false;
int g_iMaxTraces = 524288;
int g_iPVSCache[MAXPLAYERS][MAXPLAYERS];
bool g_bIsVisible[MAXPLAYERS][MAXPLAYERS];
bool g_bIsObserver[MAXPLAYERS];
bool g_bIsFake[MAXPLAYERS];
bool g_bProcess[MAXPLAYERS];
bool g_bIgnore[MAXPLAYERS];
int g_iWeaponOwner[MAX_EDICTS] = { 0, ... };
int g_iTeam[MAXPLAYERS] = { CS_TEAM_NONE, ... };
float g_vMins[MAXPLAYERS][3];
float g_vMaxs[MAXPLAYERS][3];
float g_vAbsCentre[MAXPLAYERS][3];
float g_vEyePos[MAXPLAYERS][3];
float g_vEyeAngles[MAXPLAYERS][3];
int g_iTotalThreads = 1, g_iCurrentThread = 1, g_iThread[MAXPLAYERS] = { 1, ... };
int g_iCacheTicks, g_iTraceCount;
int g_iTickCount, g_iCmdTickCount[MAXPLAYERS];
ConVar g_hEnabled = null;
ConVar g_hMaxTraces = null;
public APLRes AskPluginLoad2(Handle hSelf, bool bLateLoaded, char[] szError, int nErrorMaxLen)
{
    if (Engine_CSGO != GetEngineVersion())
    {
        FormatEx(szError, nErrorMaxLen, "This Plug-in Only Works On Counter-Strike: Global Offensive");
        return APLRes_Failure;
    }
    return APLRes_Success;
}
public void OnPluginStart()
{
    g_hEnabled = CreateConVar("smac_wallhack", "0", "DISABLES WALL HACKS", FCVAR_NONE, true, 0.0, true, 1.0);
    OnSettingsChanged(g_hEnabled, "", "");
    HookConVarChange(g_hEnabled, OnSettingsChanged);
    g_hMaxTraces = CreateConVar("smac_wallhack_maxtraces", "524288", "MAXIMUM ENGINE TRACES EACH TICK", FCVAR_NONE, true, 4.0, true, 524288.0);
    OnMaxTracesChanged(g_hMaxTraces, "", "");
    HookConVarChange(g_hMaxTraces, OnMaxTracesChanged);
    g_iCacheTicks = TIME_TO_TICK(0.75);
    RequireFeature(FeatureType_Capability, FEATURECAP_PLAYERRUNCMD_11PARAMS, "This Plug-in Requires A Newer Version Of SourceMod");
    for (int i = 0; i < sizeof(g_bIsVisible); i++)
    {
        for (int j = 0; j < sizeof(g_bIsVisible[]); j++)
        {
            g_bIsVisible[i][j] = true;
        }
    }
    CreateTimer(1.0, Timer_Setting, INVALID_HANDLE, TIMER_REPEAT);
}
public Action Timer_Setting(Handle hTimer)
{
    int nAlivePlayers =         H_CountAlive();
    bool bShouldBeEnabled =     CONDITION_TO_RUN ? true : false;
    if (g_hEnabled.BoolValue != bShouldBeEnabled)
    {
        ServerCommand("smac_wallhack %d;",  bShouldBeEnabled ? 1 : 0);
    }
}
public void OnClientPutInServer(int client)
{
    if (g_bEnabled)
    {
        Wallhack_Hook(client);
        Wallhack_UpdateClientCache(client);
    }
}
public void OnClientDisconnect(int client)
{
    g_bIsObserver[client] = false;
    g_bProcess[client] = false;
    g_bIgnore[client] = false;
    Wallhack_Unhook(client);
}
public void OnMapEnd()
{
    for (int nClient = 1; nClient < MAXPLAYERS; nClient++)
    {
        Wallhack_Unhook(nClient);
    }
}
public void OnPluginEnd()
{
    for (int nClient = 1; nClient < MAXPLAYERS; nClient++)
    {
        Wallhack_Unhook(nClient);
    }
}
public void OnClientDisconnect_Post(int client)
{
    for (int i = 0; i < sizeof(g_iPVSCache); i++)
    {
        g_iPVSCache[i][client] = 0;
        g_bIsVisible[i][client] = true;
    }
    Wallhack_Unhook(client);
}
public Action Event_PlayerStateChanged(Event event, const char[] name, bool dontBroadcast)
{
    if (event != null)
    {
        CreateTimer(0.001, Timer_PlayerStateChanged, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
    }
}
public Action Timer_PlayerStateChanged(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (IS_CLIENT(client) && IsClientInGame(client))
    {
        Wallhack_UpdateClientCache(client);
    }
}
void Wallhack_UpdateClientCache(int client)
{
    g_iTeam[client] = GetClientTeam(client);
    g_bIsObserver[client] = IsClientObserver(client);
    g_bIsFake[client] = IsFakeClient(client);
    g_bProcess[client] = IsPlayerAlive(client);
    g_bIgnore[client] = g_bIsFake[client];
    int nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "planted_c4")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "inferno")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "hegrenade_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "flashbang_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "decoy_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "incgrenade_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "smokegrenade_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
    nEntity = INVALID_ENT_REFERENCE;
    while ((nEntity = FindEntityByClassname(nEntity, "molotov_projectile")) != INVALID_ENT_REFERENCE)
    {
        g_iWeaponOwner[nEntity] = 0;
        SDKUnhook(nEntity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
}
public void OnSettingsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    bool bNewValue = convar.BoolValue;
    if (bNewValue && !g_bEnabled)
    {
        Wallhack_Enable();
    }
    else if (!bNewValue && g_bEnabled)
    {
        Wallhack_Disable();
    }
}
public void OnMaxTracesChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    g_iMaxTraces = GetConVarInt(convar);
}
void Wallhack_Enable()
{
    g_bEnabled = true;
    HookEventEx("player_spawn", Event_PlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_death", Event_PlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_team",  Event_PlayerStateChanged, EventHookMode_Post);
    for (int i = 1; i < MAXPLAYERS; i++)
    {
        if (IsClientInGame(i))
        {
            Wallhack_Hook(i);
            Wallhack_UpdateClientCache(i);
        }
    }
    for (int i = MAXPLAYERS; i < (GetEntityCount() + 1); i++)
    {
        if (IsValidEdict(i))
        {
            static int m_hOwnerEntity = -8192;
            if (m_hOwnerEntity == -8192)
            {
                m_hOwnerEntity = FindDataMapInfo(i, "m_hOwnerEntity");
            }
            int owner = GetEntDataEnt2(i, m_hOwnerEntity);
            if (IS_CLIENT(owner))
            {
                g_iWeaponOwner[i] = owner;
                SDKHookEx(i, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
            }
        }
    }
}
void Wallhack_Disable()
{
    g_bEnabled = false;
    UnhookEvent("player_spawn", Event_PlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_death", Event_PlayerStateChanged, EventHookMode_Post);
    UnhookEvent("player_team",  Event_PlayerStateChanged, EventHookMode_Post);
    for (int i = 1; i < MAXPLAYERS; i++)
    {
        if (IsClientInGame(i))
        {
            Wallhack_Unhook(i);
        }
    }
    for (int i = MAXPLAYERS; i < (GetEntityCount() + 1); i++)
    {
        if (g_iWeaponOwner[i])
        {
            g_iWeaponOwner[i] = 0;
            SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
        }
    }
}
void Wallhack_Hook(int client)
{
    SDKHookEx(client, SDKHook_SetTransmit,      Hook_SetTransmit);
    SDKHookEx(client, SDKHook_WeaponEquipPost,  Hook_WeaponEquipPost);
    SDKHookEx(client, SDKHook_WeaponDropPost,   Hook_WeaponDropPost);
}
void Wallhack_Unhook(int client)
{
    SDKUnhook(client, SDKHook_SetTransmit,      Hook_SetTransmit);
    SDKUnhook(client, SDKHook_WeaponEquipPost,  Hook_WeaponEquipPost);
    SDKUnhook(client, SDKHook_WeaponDropPost,   Hook_WeaponDropPost);
}
public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity > (MAXPLAYERS - 1) && entity < MAX_EDICTS)
    {
        g_iWeaponOwner[entity] = 0;
    }
}
public void OnEntityDestroyed(int entity)
{
    if (entity > (MAXPLAYERS - 1) && entity < MAX_EDICTS)
    {
        g_iWeaponOwner[entity] = 0;
        SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
}
public void Hook_WeaponEquipPost(int client, int weapon)
{
    if (weapon > (MAXPLAYERS - 1) && weapon < MAX_EDICTS)
    {
        g_iWeaponOwner[weapon] = client;
        SDKHookEx(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
}
public void Hook_WeaponDropPost(int client, int weapon)
{
    if (weapon > (MAXPLAYERS - 1) && weapon < MAX_EDICTS)
    {
        g_iWeaponOwner[weapon] = 0;
        SDKUnhook(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
    }
}
public void OnGameFrame()
{
    if (!g_bEnabled)
    {
        return;
    }
    g_iTickCount = GetGameTickCount();
    if (++g_iCurrentThread > g_iTotalThreads)
    {
        g_iCurrentThread = 1;
        if (g_iTraceCount)
        {
            g_iTotalThreads = g_iTraceCount / g_iMaxTraces + 1;
            int iThreadAssign = 1;
            for (int i = 1; i < MAXPLAYERS; i++)
            {
                if (g_bProcess[i])
                {
                    g_iThread[i] = iThreadAssign;
                    if (++iThreadAssign > g_iTotalThreads)
                    {
                        iThreadAssign = 1;
                    }
                }
            }
            g_iTraceCount = 0;
        }
    }
}
public Action Hook_SetTransmit(int entity, int client)
{
    static int iLastChecked[MAXPLAYERS][MAXPLAYERS];
    if (g_bProcess[client] && !g_bProcess[entity])
    {
        g_bIsVisible[entity][client] = false;
        iLastChecked[entity][client] = g_iTickCount;
        return Plugin_Handled;
    }
    if (iLastChecked[entity][client] == g_iTickCount)
    {
        return g_bIsVisible[entity][client] ? Plugin_Continue : Plugin_Handled;
    }
    iLastChecked[entity][client] = g_iTickCount;
    if (g_bProcess[client])
    {
        if (g_bProcess[entity] && g_iTeam[client] != g_iTeam[entity] && !g_bIgnore[client])
        {
            if (g_iThread[client] == g_iCurrentThread)
            {
                UpdateClientData(client);
                UpdateClientData(entity);
                if (IsAbleToSee(entity, client))
                {
                    g_bIsVisible[entity][client] = true;
                    g_iPVSCache[entity][client] = g_iTickCount + g_iCacheTicks;
                }
                else if (g_iTickCount > g_iPVSCache[entity][client])
                {
                    g_bIsVisible[entity][client] = false;
                }
            }
        }
        else
        {
            g_bIsVisible[entity][client] = true;
        }
    }
    else if (!g_bIsFake[client] && g_bProcess[entity] && GetClientObserverMode(client) == OBS_MODE_IN_EYE)
    {
        int iTarget = GetClientObserverTarget(client);
        if (IS_CLIENT(iTarget))
        {
            g_bIsVisible[entity][client] = g_bIsVisible[entity][iTarget];
        }
        else
        {
            g_bIsVisible[entity][client] = true;
        }
    }
    else
    {
        g_bIsVisible[entity][client] = true;
    }
    return g_bIsVisible[entity][client] ? Plugin_Continue : Plugin_Handled;
}
public Action Hook_SetTransmitWeapon(int entity, int client)
{
    return g_bIsVisible[g_iWeaponOwner[entity]][client] ? Plugin_Continue : Plugin_Handled;
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!g_bEnabled || !g_bProcess[client])
    {
        return Plugin_Continue;
    }
    g_vEyeAngles[client] = angles;
    g_iCmdTickCount[client] = tickcount;
    return Plugin_Continue;
}
void UpdateClientData(int client)
{
    static int iLastCached[MAXPLAYERS];
    if (iLastCached[client] == g_iTickCount)
    {
        return;
    }
    iLastCached[client] = g_iTickCount;
    GetClientMins(client, g_vMins[client]);
    GetClientMaxs(client, g_vMaxs[client]);
    GetClientAbsOrigin(client, g_vAbsCentre[client]);
    GetClientEyePosition(client, g_vEyePos[client]);
    g_vMaxs[client][2] /= 2.0;
    g_vMins[client][2] -= g_vMaxs[client][2];
    g_vAbsCentre[client][2] += g_vMaxs[client][2];
    float vVelocity[3];
    static int m_vecAbsVelocity = -8192;
    if (m_vecAbsVelocity == -8192)
    {
        m_vecAbsVelocity = FindDataMapInfo(client, "m_vecAbsVelocity");
    }
    GetEntDataVector(client, m_vecAbsVelocity, vVelocity);
    if (!H_IsVectorZero(vVelocity))
    {
        int iTargetTick;
        if (g_bIsFake[client])
        {
            iTargetTick = g_iTickCount - 1;
        }
        else
        {
            float fCorrect = GetClientLatency(client, NetFlow_Outgoing);
            static int m_fLerpTime = -8192;
            if (m_fLerpTime == -8192)
            {
                m_fLerpTime = FindDataMapInfo(client, "m_fLerpTime");
            }
            int iLerpTicks = TIME_TO_TICK(GetEntDataFloat(client, m_fLerpTime));
            fCorrect += TICK_TO_TIME(iLerpTicks);
            if (fCorrect < 0.0)
            {
                fCorrect = 0.0;
            }
            if (fCorrect > 1.0)
            {
                fCorrect = 1.0;
            }
            iTargetTick = g_iCmdTickCount[client] - iLerpTicks;
            if (FloatAbs(fCorrect - TICK_TO_TIME(g_iTickCount - iTargetTick)) > 0.2)
            {
                iTargetTick = g_iTickCount - TIME_TO_TICK(fCorrect);
            }
        }
        float vTemp[3];
        vTemp[0] = FloatAbs(vVelocity[0]) * 0.01;
        vTemp[1] = FloatAbs(vVelocity[1]) * 0.01;
        vTemp[2] = FloatAbs(vVelocity[2]) * 0.01;
        float vPredicted[3];
        ScaleVector(vVelocity, TICK_TO_TIME((g_iTickCount - iTargetTick) * g_iTotalThreads));
        AddVectors(g_vAbsCentre[client], vVelocity, vPredicted);
        TR_TraceHullFilter(vPredicted, vPredicted, view_as<float>({-5.0, -5.0, -5.0}), view_as<float>({5.0, 5.0, 5.0}), MASK_PLAYERSOLID_BRUSHONLY, Filter_WorldOnly);
        g_iTraceCount++;
        if (!TR_DidHit())
        {
            g_vAbsCentre[client] = vPredicted;
            AddVectors(g_vEyePos[client], vVelocity, g_vEyePos[client]);
        }
        if (vTemp[0] > 1.0)
        {
            g_vMins[client][0] *= vTemp[0];
            g_vMaxs[client][0] *= vTemp[0];
        }
        if (vTemp[1] > 1.0)
        {
            g_vMins[client][1] *= vTemp[1];
            g_vMaxs[client][1] *= vTemp[1];
        }
        if (vTemp[2] > 1.0)
        {
            g_vMins[client][2] *= vTemp[2];
            g_vMaxs[client][2] *= vTemp[2];
        }
    }
}
bool IsAbleToSee(int entity, int client)
{
    if (IsInFieldOfView(g_vEyePos[client], g_vEyeAngles[client], g_vAbsCentre[entity]))
    {
        if (IsPointVisible(g_vEyePos[client], g_vAbsCentre[entity]))
        {
            return true;
        }
        if (IsFwdVecVisible(g_vEyePos[client], g_vEyeAngles[entity], g_vEyePos[entity]))
        {
            return true;
        }
        if (IsRectangleVisible(g_vEyePos[client], g_vAbsCentre[entity], g_vMins[entity], g_vMaxs[entity], 1.30))
        {
            return true;
        }
        if (IsRectangleVisible(g_vEyePos[client], g_vAbsCentre[entity], g_vMins[entity], g_vMaxs[entity], 0.65))
        {
            return true;
        }
    }
    return false;
}
bool IsInFieldOfView(const float start[3], const float angles[3], const float end[3])
{
    float normal[3], plane[3];
    GetAngleVectors(angles, normal, NULL_VECTOR, NULL_VECTOR);
    SubtractVectors(end, start, plane);
    NormalizeVector(plane, plane);
    return GetVectorDotProduct(plane, normal) > 0.0;
}
public bool Filter_WorldOnly(int entity, int mask)
{
    return false;
}
public bool Filter_NoPlayers(int entity, int mask)
{
    static int m_hOwnerEntity = -8192;
    if (entity > (MAXPLAYERS - 1) && m_hOwnerEntity == -8192)
    {
        m_hOwnerEntity = FindDataMapInfo(entity, "m_hOwnerEntity");
    }
    return entity > (MAXPLAYERS - 1) && !IS_CLIENT(GetEntDataEnt2(entity, m_hOwnerEntity));
}
bool IsPointVisible(const float start[3], const float end[3])
{
    TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Filter_NoPlayers);
    g_iTraceCount++;
    return TR_GetFraction() == 1.0;
}
bool IsFwdVecVisible(const float start[3], const float angles[3], const float end[3])
{
    float fwd[3];
    GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(fwd, 50.0);
    AddVectors(end, fwd, fwd);
    return IsPointVisible(start, fwd);
}
bool IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale)
{
    float ZpozOffset = maxs[2];
    float ZnegOffset = mins[2];
    float WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;
    if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0)
    {
        return IsPointVisible(start, end);
    }
    ZpozOffset *= scale;
    ZnegOffset *= scale;
    WideOffset *= scale;
    float angles[3], fwd[3], right[3];
    SubtractVectors(start, end, fwd);
    NormalizeVector(fwd, fwd);
    GetVectorAngles(fwd, angles);
    GetAngleVectors(angles, fwd, right, NULL_VECTOR);
    float vRectangle[4][3], vTemp[3];
    if (FloatAbs(fwd[2]) <= 0.7071)
    {
        ScaleVector(right, WideOffset);
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vRectangle[0]);
        SubtractVectors(vTemp, right, vRectangle[1]);
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vRectangle[2]);
        SubtractVectors(vTemp, right, vRectangle[3]);
    }
    else if (fwd[2] > 0.0)
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[0]);
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[1]);
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[2]);
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[3]);
    }
    else
    {
        fwd[2] = 0.0;
        NormalizeVector(fwd, fwd);
        ScaleVector(fwd, scale);
        ScaleVector(fwd, WideOffset);
        ScaleVector(right, WideOffset);
        vTemp = end;
        vTemp[2] += ZpozOffset;
        AddVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[0]);
        vTemp = end;
        vTemp[2] += ZpozOffset;
        SubtractVectors(vTemp, right, vTemp);
        AddVectors(vTemp, fwd, vRectangle[1]);
        vTemp = end;
        vTemp[2] += ZnegOffset;
        AddVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[2]);
        vTemp = end;
        vTemp[2] += ZnegOffset;
        SubtractVectors(vTemp, right, vTemp);
        SubtractVectors(vTemp, fwd, vRectangle[3]);
    }
    for (int i = 0; i < 4; i++)
    {
        if (IsPointVisible(start, vRectangle[i]))
        {
            return true;
        }
    }
    return false;
}
int GetClientObserverMode(int client)
{
    static int offs = 0;
    if (offs < 1)
    {
        offs = FindSendPropInfo("CBasePlayer", "m_iObserverMode");
    }
    if (offs < 1)
    {
        SetFailState("Bad m_iObserverMode Offset");
        return OBS_MODE_NONE;
    }
    return GetEntData(client, offs);
}
int GetClientObserverTarget(int client)
{
    static int offs = 0;
    if (offs < 1)
    {
        offs = FindSendPropInfo("CBasePlayer", "m_hObserverTarget");
    }
    if (offs < 1)
    {
        SetFailState("Bad m_hObserverTarget Offset");
        return INVALID_ENT_REFERENCE;
    }
    return GetEntDataEnt2(client, offs);
}
bool H_IsVectorZero(const float fVec[3])
{
    return fVec[0] == 0.0 && fVec[1] == 0.0 && fVec[2] == 0.0;
}
bool H_IsValidClient(int nClient)
{
    if (nClient < 1                             || \
        nClient > (MAXPLAYERS - 1)              || \
        !IsClientConnected(nClient)             || \
        !IsClientInGame(nClient))
    {
        return false;
    }
    return true;
}
int H_CountAlive()
{
    int nTotal =        0;
    for (int nClient =  1; nClient < MAXPLAYERS; nClient++)
    {
        if (H_IsValidClient(nClient) && IsPlayerAlive(nClient))
        {
            nTotal++;
        }
    }
    return nTotal;
}
