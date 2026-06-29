#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>

Handle g_hIgniteEntity = INVALID_HANDLE;
Handle g_hExtinguishEntity = INVALID_HANDLE;

GlobalForward g_fwOnIgniteEntity;
GlobalForward g_fwOnExtinguishEntity;

public Plugin myinfo =
{
    name        = "Fire Staff Hook",
    author      = "Kroytz",
    description = "Hook ignite and extinguish",
    version     = "1.0",
    url         = ""
};

public void OnPluginStart()
{
    // Gamedata.
    Handle hConfig = LoadGameConfigFile("sdktools.games\\engine.csgo");
    if (hConfig == INVALID_HANDLE)
        SetFailState("Why no gamedata??");

    int igniteOffset = GameConfGetOffset(hConfig, "Ignite");
    if (igniteOffset == -1)
        SetFailState("Failed to find Ignite offset");

    int extinguishOffset = GameConfGetOffset(hConfig, "Extinguish");
    if (extinguishOffset == -1)
        SetFailState("Failed to find Extinguish offset");

    CloseHandle(hConfig);

    // Ignite( float flFlameLifetime, bool bNPCOnly, float flSize, bool bCalledByLevelDesigner )
    g_hIgniteEntity = DHookCreate(igniteOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_Ignite);
    DHookAddParam(g_hIgniteEntity, HookParamType_Float);
    DHookAddParam(g_hIgniteEntity, HookParamType_Bool);
    DHookAddParam(g_hIgniteEntity, HookParamType_Float);
    DHookAddParam(g_hIgniteEntity, HookParamType_Bool);

    g_fwOnIgniteEntity = new GlobalForward("OnIgniteEntity", ET_Event, Param_Cell, Param_FloatByRef);

    // Extinguish()
    g_hExtinguishEntity = DHookCreate(extinguishOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_Extinguish);
    g_fwOnExtinguishEntity = new GlobalForward("OnExtinguishEntity", ET_Event, Param_Cell);
}

public void OnClientPostAdminCheck(int client)
{
    DHookEntity(g_hIgniteEntity, false, client);
    DHookEntity(g_hExtinguishEntity, false, client);
}

public MRESReturn Hook_Ignite(int entity, Handle hParams)
{
    if (!IsPlayerExist(entity))
        return MRES_Ignored;

    float time = view_as<float>(DHookGetParam(hParams, 1));

    Action result = Plugin_Continue;
    Call_StartForward(g_fwOnIgniteEntity);
    Call_PushCell(entity);
    Call_PushFloatRef(time);
    Call_Finish(result);

    MRESReturn mresReturn = MRES_Ignored;
    switch (result)
    {
        case Plugin_Handled: mresReturn = MRES_Supercede;
        case Plugin_Changed: mresReturn = MRES_ChangedOverride;
        case Plugin_Stop: mresReturn = MRES_Supercede;
    }

    return mresReturn;
}

public MRESReturn Hook_Extinguish(int entity, Handle hParams)
{
    if (!IsPlayerExist(entity))
        return MRES_Ignored;

    Action result = Plugin_Continue;
    Call_StartForward(g_fwOnExtinguishEntity);
    Call_PushCell(entity);
    Call_Finish(result);

    MRESReturn mresReturn = MRES_Ignored;
    if (result != Plugin_Continue)
        mresReturn = MRES_Supercede;

    return mresReturn;
}

stock bool IsPlayerExist(int client, bool bAlive = true)
{
    // If client isn't valid, then stop
    if (client <= 0 || client > MaxClients)
    {
        return false;
    }

    // If client isn't connected, then stop
    if (!IsClientConnected(client))
    {
        return false;
    }

    // If client isn't in game, then stop
    if (!IsClientInGame(client) || IsClientInKickQueue(client))
    {
        return false;
    }

    // If client is TV, then stop
    if (IsClientSourceTV(client))
    {
        return false;
    }

    // If client isn't alive, then stop
    if (bAlive && !IsPlayerAlive(client))
    {
        return false;
    }

    // If client exist
    return true;
}