
#include <sourcemod>

#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#include <topmenus>
#include <dhooks>
#include <geoip>
#include <regex>

public Plugin myinfo =
{
    name = "L4D2 Helper",
    description = "Provides L4D2 Helping Stuff",
    author = "Hattrick HKS (CARAMEL® HACK)",
    version = __DATE__,
    url = "https://forums.alliedmods.net/",
};

/// #define HKS_LOG_HUGE_DATA

static int g_pnNavAreaOffs[6] = { 0, ... };

static int g_pnNewNavArea[128] = { 0, ... };
static int g_pnOldNavArea[128] = { 0, ... };

static Address g_uNavMesh = Address_Null;

static Handle g_hCTerrorPlayerOnNavAreaChanged = null;

static Handle g_hCNavMeshGetNearestNavAreaVector = null;
static Handle g_hCNavMeshGetNearestNavAreaCBaseEntity = null;

static Handle g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark = null;
static Handle g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark = null;

public APLRes AskPluginLoad2(Handle xSelf, bool bHasBeenAttachedDuringTheGame, char[] pszError, int nErrorMaximumSize)
{
    if (Engine_Left4Dead2 != GetEngineVersion())
    {
        strcopy(pszError, nErrorMaximumSize, "L4D2 REQUIRED");

        return APLRes_Failure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    GameData hGameData = null;

    hGameData = new GameData("hks.games");

    if (!hGameData)
    {
        LogError("GameData() @ `hks.games` Error");

        return;
    }

    g_pnNavAreaOffs[0] = hGameData.GetOffset("m_nNavAreaUnkA");
    g_pnNavAreaOffs[1] = hGameData.GetOffset("m_nNavAreaUnkB");
    g_pnNavAreaOffs[2] = hGameData.GetOffset("m_nNavAreaUnkC");
    g_pnNavAreaOffs[3] = hGameData.GetOffset("m_nNavAreaUnkD");
    g_pnNavAreaOffs[4] = hGameData.GetOffset("m_nNavAreaUnkE");
    g_pnNavAreaOffs[5] = hGameData.GetOffset("m_nNavAreaUnkF");

    if (g_pnNavAreaOffs[0] < 0 || g_pnNavAreaOffs[1] < 0 || g_pnNavAreaOffs[2] < 0 || g_pnNavAreaOffs[3] < 0 || g_pnNavAreaOffs[4] < 0 || g_pnNavAreaOffs[5] < 0)
    {
        delete hGameData;

        LogError("GetOffset() @ `m_nNavAreaUnk[A|B|C|D|E|F]` Error");

        return;
    }

    g_uNavMesh = GameConfGetAddress(hGameData, "NavMesh");

    if (g_uNavMesh == Address_Null)
    {
        delete hGameData;

        LogError("GameConfGetAddress() @ `NavMesh` Error");

        return;
    }

    StartPrepSDKCall(SDKCall_Raw);

    if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNearestNavArea[Vector&]"))
    {
        EndPrepSDKCall();

        delete hGameData;

        LogError("PrepSDKCall_SetFromConf() @ `CNavMesh::GetNearestNavArea[Vector&]` Error");

        return;
    }

    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);

    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    g_hCNavMeshGetNearestNavAreaVector = EndPrepSDKCall();

    if (null == g_hCNavMeshGetNearestNavAreaVector)
    {
        delete hGameData;

        LogError("EndPrepSDKCall() @ `CNavMesh::GetNearestNavArea[Vector&]` Error");

        return;
    }

    StartPrepSDKCall(SDKCall_Raw);

    if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNearestNavArea[CBaseEntity*]"))
    {
        EndPrepSDKCall();

        delete hGameData;

        LogError("PrepSDKCall_SetFromConf() @ `CNavMesh::GetNearestNavArea[CBaseEntity*]` Error");

        return;
    }

    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);

    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    g_hCNavMeshGetNearestNavAreaCBaseEntity = EndPrepSDKCall();

    if (null == g_hCNavMeshGetNearestNavAreaCBaseEntity)
    {
        delete hGameData;

        LogError("EndPrepSDKCall() @ `CNavMesh::GetNearestNavArea[CBaseEntity*]` Error");

        return;
    }

    StartPrepSDKCall(SDKCall_Raw);

    if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInInitialCheckpoint_NoLandmark"))
    {
        EndPrepSDKCall();

        delete hGameData;

        LogError("PrepSDKCall_SetFromConf() @ `TerrorNavMesh::IsInInitialCheckpoint_NoLandmark` Error");

        return;
    }

    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);

    g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark = EndPrepSDKCall();

    if (null == g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark)
    {
        delete hGameData;

        LogError("EndPrepSDKCall() @ `TerrorNavMesh::IsInInitialCheckpoint_NoLandmark` Error");

        return;
    }

    StartPrepSDKCall(SDKCall_Raw);

    if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInExitCheckpoint_NoLandmark"))
    {
        EndPrepSDKCall();

        delete hGameData;

        LogError("PrepSDKCall_SetFromConf() @ `TerrorNavMesh::IsInExitCheckpoint_NoLandmark` Error");

        return;
    }

    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);

    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);

    g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark = EndPrepSDKCall();

    if (null == g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark)
    {
        delete hGameData;

        LogError("EndPrepSDKCall() @ `TerrorNavMesh::IsInExitCheckpoint_NoLandmark` Error");

        return;
    }

    g_hCTerrorPlayerOnNavAreaChanged = DHookCreateFromConf(hGameData, "::CTerrorPlayer::OnNavAreaChanged");

    if (null == g_hCTerrorPlayerOnNavAreaChanged)
    {
        delete hGameData;

        LogError("DHookCreateFromConf() @ `::CTerrorPlayer::OnNavAreaChanged` Error");

        return;
    }

    delete hGameData;

    DHookEnableDetour(g_hCTerrorPlayerOnNavAreaChanged, true, OnPlayerNavAreaChanged_Post);

    AddCommandListener(OnSeeNavArea_Pre, "help_see_nav_area");
}

public MRESReturn OnPlayerNavAreaChanged_Post(int nPlayer, DHookReturn hReturn, DHookParam hParameters)
{
    if (null == hReturn)
    {
        return MRES_Ignored;
    }

    if (null == hParameters)
    {
        return MRES_Ignored;
    }

    if (g_uNavMesh == Address_Null)
    {
        return MRES_Ignored;
    }

    if (null == g_hCTerrorPlayerOnNavAreaChanged)
    {
        return MRES_Ignored;
    }

    if (null == g_hCNavMeshGetNearestNavAreaVector)
    {
        return MRES_Ignored;
    }

    if (null == g_hCNavMeshGetNearestNavAreaCBaseEntity)
    {
        return MRES_Ignored;
    }

    if (null == g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark)
    {
        return MRES_Ignored;
    }

    if (null == g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark)
    {
        return MRES_Ignored;
    }

    if (nPlayer < 1)
    {
        return MRES_Ignored;
    }

    if (nPlayer > MaxClients)
    {
        return MRES_Ignored;
    }

    g_pnNewNavArea[nPlayer] = hParameters.Get(1);
    g_pnOldNavArea[nPlayer] = hParameters.Get(2);

    return MRES_Ignored;
}

public Action OnSeeNavArea_Pre(int nCaller, const char[] szCmd, int nArgs)
{
    static int nNavArea = 0;

#if defined HKS_LOG_HUGE_DATA

    static int nItem = 0;
    static int nIter = 0;

#endif

    static float pfPosition[3] = { 0.000000, ... };

    if (g_uNavMesh == Address_Null)
    {
        return Plugin_Stop;
    }

    if (null == g_hCTerrorPlayerOnNavAreaChanged)
    {
        return Plugin_Stop;
    }

    if (null == g_hCNavMeshGetNearestNavAreaVector)
    {
        return Plugin_Stop;
    }

    if (null == g_hCNavMeshGetNearestNavAreaCBaseEntity)
    {
        return Plugin_Stop;
    }

    if (null == g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark)
    {
        return Plugin_Stop;
    }

    if (null == g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark)
    {
        return Plugin_Stop;
    }

    if (nCaller < 1)
    {
        return Plugin_Stop;
    }

    if (nCaller > MaxClients)
    {
        return Plugin_Stop;
    }

    if (!IsClientConnected(nCaller))
    {
        return Plugin_Stop;
    }

    if (!IsClientInGame(nCaller))
    {
        return Plugin_Stop;
    }

    if (IsFakeClient(nCaller))
    {
        return Plugin_Stop;
    }

    if (!IsPlayerAlive(nCaller))
    {
        return Plugin_Stop;
    }

    if (1 > GetClientHealth(nCaller))
    {
        return Plugin_Stop;
    }

    PrintToChat(nCaller, "*******************");

    PrintToChat(nCaller, "\x001Old Area\x003 %d\x001 & New Area\x004 %d", g_pnOldNavArea[nCaller], g_pnNewNavArea[nCaller]);

    switch (g_pnNewNavArea[nCaller] > 0)
    {
        case true:
        {
            if (SDKCall(g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark, g_uNavMesh, g_pnNewNavArea[nCaller]))
            {
                switch (LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[0]), NumberType_Int32) == -65536 ||
                    LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[1]), NumberType_Int32) == -256 ||
                    LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[2]), NumberType_Int32) == -1 ||
                    LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[3]), NumberType_Int32) == 16777215 ||
                    LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[4]), NumberType_Int32) == 65535 ||
                    LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + g_pnNavAreaOffs[5]), NumberType_Int32) == 255)
                {
                    case true:
                    {
                        PrintToChat(nCaller, "\x003@EXIT");

#if defined HKS_LOG_HUGE_DATA

                        LogMessage("@ Logging Nav Area %d [@EXIT]", g_pnNewNavArea[nCaller]);

                        PrintToServer("@ Logging Nav Area %d [@EXIT]", g_pnNewNavArea[nCaller]);

#endif

                    }

                    default:
                    {
                        PrintToChat(nCaller, "\x005@EXIT (BUT OUTSIDE SAFE ROOM)");

#if defined HKS_LOG_HUGE_DATA

                        LogMessage("@ Logging Nav Area %d [@EXIT (BUT OUTSIDE SAFE ROOM)]", g_pnNewNavArea[nCaller]);

                        PrintToServer("@ Logging Nav Area %d [@EXIT (BUT OUTSIDE SAFE ROOM)]", g_pnNewNavArea[nCaller]);

#endif

                    }
                }

#if defined HKS_LOG_HUGE_DATA

                for (nIter = 0; nIter < 1000; nIter++)
                {
                    nItem = LoadFromAddress(view_as<Address>(g_pnNewNavArea[nCaller] + nIter), NumberType_Int32);

                    LogMessage("OFFS %03d => %d", nIter, nItem);

                    PrintToServer("OFFS %03 => %d", nIter, nItem);
                }

#endif

            }

            else if (SDKCall(g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark, g_uNavMesh, g_pnNewNavArea[nCaller]))
            {
                PrintToChat(nCaller, "\x004@START");
            }

            else
            {
                PrintToChat(nCaller, "\x005@UNKNOWN");
            }
        }

        default:
        {
            PrintToChat(nCaller, "\x005@UNKNOWN");
        }
    }

    nNavArea = SDKCall(g_hCNavMeshGetNearestNavAreaCBaseEntity, g_uNavMesh, nCaller, 0, 16384.000000);

    PrintToChat(nCaller, "\x001Area By\x003 CBaseEntity\x004 %d", nNavArea);

    switch (nNavArea > 0)
    {
        case true:
        {
            if (SDKCall(g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark, g_uNavMesh, nNavArea))
            {
                switch (LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[0]), NumberType_Int32) == -65536 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[1]), NumberType_Int32) == -256 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[2]), NumberType_Int32) == -1 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[3]), NumberType_Int32) == 16777215 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[4]), NumberType_Int32) == 65535 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[5]), NumberType_Int32) == 255)
                {
                    case true:
                    {
                        PrintToChat(nCaller, "\x003@EXIT");
                    }

                    default:
                    {
                        PrintToChat(nCaller, "\x005@EXIT (BUT OUTSIDE SAFE ROOM)");
                    }
                }
            }

            else if (SDKCall(g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark, g_uNavMesh, nNavArea))
            {
                PrintToChat(nCaller, "\x004@START");
            }

            else
            {
                PrintToChat(nCaller, "\x005@UNKNOWN");
            }
        }

        default:
        {
            PrintToChat(nCaller, "\x005@UNKNOWN");
        }
    }

    if (!retrieveEntityPosition(nCaller, pfPosition))
    {
        PrintToChat(nCaller, "\x003(\x001YOUR\x004 POSITION\x001 IS\x005 NULL_VECTOR\x003)");
        PrintToChat(nCaller, "###################");

        return Plugin_Stop;
    }

    nNavArea = SDKCall(g_hCNavMeshGetNearestNavAreaVector, g_uNavMesh, pfPosition, false, 16384.000000, false, false, false);

    PrintToChat(nCaller, "\x001Area By\x003 Vector\x004 %d", nNavArea);

    switch (nNavArea > 0)
    {
        case true:
        {
            if (SDKCall(g_hTerrorNavMeshIsInExitCheckpoint_NoLandmark, g_uNavMesh, nNavArea))
            {
                switch (LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[0]), NumberType_Int32) == -65536 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[1]), NumberType_Int32) == -256 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[2]), NumberType_Int32) == -1 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[3]), NumberType_Int32) == 16777215 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[4]), NumberType_Int32) == 65535 ||
                    LoadFromAddress(view_as<Address>(nNavArea + g_pnNavAreaOffs[5]), NumberType_Int32) == 255)
                {
                    case true:
                    {
                        PrintToChat(nCaller, "\x003@EXIT");
                    }

                    default:
                    {
                        PrintToChat(nCaller, "\x005@EXIT (BUT OUTSIDE SAFE ROOM)");
                    }
                }
            }

            else if (SDKCall(g_hTerrorNavMeshIsInInitialCheckpoint_NoLandmark, g_uNavMesh, nNavArea))
            {
                PrintToChat(nCaller, "\x004@START");
            }

            else
            {
                PrintToChat(nCaller, "\x005@UNKNOWN");
            }
        }

        default:
        {
            PrintToChat(nCaller, "\x005@UNKNOWN");
        }
    }

    return Plugin_Stop;
}

static bool hasEntityDataProperty(int nEntity, const char[] pszProp)
{
    return FindDataMapInfo(nEntity, pszProp) > -1;
}

static bool hasEntitySendProperty(int nEntity, const char[] pszProp)
{
    static char szClass[128] = { EOS, ... };

    if (!GetEntityNetClass(nEntity, szClass, sizeof szClass))
    {
        return false;
    }

    return FindSendPropInfo(szClass, pszProp) > -1;
}

static bool retrieveEntityPosition(int nEntity, float pfPosition[3])
{
    if (hasEntitySendProperty(nEntity, "m_vecOrigin"))
    {
        GetEntPropVector(nEntity, Prop_Send, "m_vecOrigin", pfPosition);

        if (pfPosition[0] || pfPosition[1] || pfPosition[2])
        {
            return true;
        }

        return false;
    }

    if (hasEntityDataProperty(nEntity, "m_vecOrigin"))
    {
        GetEntPropVector(nEntity, Prop_Data, "m_vecOrigin", pfPosition);

        if (pfPosition[0] || pfPosition[1] || pfPosition[2])
        {
            return true;
        }

        return false;
    }

    if (hasEntitySendProperty(nEntity, "m_vecAbsOrigin"))
    {
        GetEntPropVector(nEntity, Prop_Send, "m_vecAbsOrigin", pfPosition);

        if (pfPosition[0] || pfPosition[1] || pfPosition[2])
        {
            return true;
        }

        return false;
    }

    if (hasEntityDataProperty(nEntity, "m_vecAbsOrigin"))
    {
        GetEntPropVector(nEntity, Prop_Data, "m_vecAbsOrigin", pfPosition);

        if (pfPosition[0] || pfPosition[1] || pfPosition[2])
        {
            return true;
        }

        return false;
    }

    GetClientAbsOrigin(nEntity, pfPosition);

    if (pfPosition[0] || pfPosition[1] || pfPosition[2])
    {
        return true;
    }

    return false;
}
