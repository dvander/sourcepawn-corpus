/**
 * vim: set ai et ts=4 sw=4 :
 * File: buildlimit.sp
 * Description: Build Restrictions for TF2
 * Author(s): Tsunami
 */

#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "0.5"

public Plugin:myinfo = {
    name        = "TF2 Build Restrictions",
    author      = "Tsunami",
    description = "Restrict buildings in TF2.",
    version     = PL_VERSION,
    url         = "http://www.tsunami-productions.nl"
}

new g_iMaxEntities;
new Handle:g_hEnabled;
new Handle:g_hImmunity;
new Handle:g_hLimits[4][4];

new bool:g_bNativeControl = false;
new g_iAllowed[MAXPLAYERS+1][4]; // how many buildings each player is allowed

// forwards
new Handle:g_fwdOnBuild;
new bool:g_bBuildHooked = false;

public OnPluginStart()
{
    CreateConVar("sm_buildlimit_version", PL_VERSION, "Restrict buildings in TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled      = CreateConVar("sm_buildlimit_enabled",                "1", "Enable/disable restricting buildings in TF2.");
    g_hImmunity     = CreateConVar("sm_buildlimit_immunity",               "0", "Enable/disable admin immunity for restricting buildings in TF2.");
    g_hLimits[2][0] = CreateConVar("sm_buildlimit_red_dispensers",         "1", "Limit for Red dispensers in TF2.");
    g_hLimits[2][1] = CreateConVar("sm_buildlimit_red_teleport_entrances", "1", "Limit for Red teleport entrances in TF2.");
    g_hLimits[2][2] = CreateConVar("sm_buildlimit_red_teleport_exits",     "1", "Limit for Red teleport exits in TF2.");
    g_hLimits[2][3] = CreateConVar("sm_buildlimit_red_sentries",           "1", "Limit for Red sentries in TF2.");
    g_hLimits[3][0] = CreateConVar("sm_buildlimit_blu_dispensers",         "1", "Limit for Blu dispensers in TF2.");
    g_hLimits[3][1] = CreateConVar("sm_buildlimit_blu_teleport_entrances", "1", "Limit for Blu teleport entrances in TF2.");
    g_hLimits[3][2] = CreateConVar("sm_buildlimit_blu_teleport_exits",     "1", "Limit for Blu teleport exits in TF2.");
    g_hLimits[3][3] = CreateConVar("sm_buildlimit_blu_sentries",           "1", "Limit for Blu sentries in TF2.");

    RegConsoleCmd("build", Command_Build, "Restrict buildings in TF2.");

    // Initialize g_iAllowed array to allow 1 of each for everyone
    for (new c=0; c<sizeof(g_iAllowed); c++)
    {
        for (new i=0; i<sizeof(g_iAllowed[]); i++)
            g_iAllowed[c][i] = 1;
    }
}

public OnMapStart()
{
    g_iMaxEntities  = GetMaxEntities();
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    for (new i=0; i < sizeof(g_iAllowed[]); i++)
        g_iAllowed[client][i] = 1;

    return true;
}

public OnClientDisconnect(client)
{
    for (new i=0; i < sizeof(g_iAllowed[]); i++)
        g_iAllowed[client][i] = 1;
}

public Action:Command_Build(client, args)
{
    new Action:iResult = Plugin_Continue;

    if (g_bNativeControl ||
        (GetConVarBool(g_hEnabled) && (!(GetConVarBool(g_hImmunity) &&
                                       (GetUserFlagBits(client) & ADMFLAG_GENERIC|ADMFLAG_ROOT)))))
    {
        decl String:sObject[2];
        GetCmdArg(1, sObject, sizeof(sObject));

        new iObject = StringToInt(sObject);
        if (iObject >= 4) // Always allow unlimited Sappers
            return Plugin_Continue;

        new iCount;
        if (!CheckBuild(client, iObject, iCount))
            return Plugin_Handled;

        if (g_bNativeControl && g_bBuildHooked)
        {
            Call_StartForward(g_fwdOnBuild);
            Call_PushCell(client);
            Call_PushCell(iObject);
            Call_PushCell(iCount);
            Call_Finish(iResult);
        }
    }

    return iResult;
}

bool:CheckBuild(client, iObject, &iCount)
{
    if (iObject >= 4) // Don't check sappers or invalid objects
    {
        iCount = -1;
        return true;
    }
    else
    {
        new iLimit = g_bNativeControl ? g_iAllowed[client][iObject]
                                      : GetConVarInt(g_hLimits[GetClientTeam(client)][iObject]);
        if (iLimit == 0)
        {
            iCount = -1;
            return false;
        }
        else if (iLimit > 0)
        {
            iCount = 0;
            decl String:sClassName[32];
            for (new i = MaxClients + 1; i < g_iMaxEntities; i++)
            {
                if (IsValidEntity(i))
                {
                    GetEntityNetClass(i, sClassName, sizeof(sClassName));

                    if (0        == strncmp(sClassName, "CObject", 7)            &&
                        iObject  == GetEntProp(i,    Prop_Send, "m_iObjectType") &&
                        client   == GetEntPropEnt(i, Prop_Send, "m_hBuilder")    &&
                        ++iCount >= iLimit)
                    {
                        return false;
                    }
                }
            }
        }
        else
            iCount = -1;
    }
    return true;
}

public bool:AskPluginLoad(Handle:myself,bool:late,String:error[],err_max)
{
    // Register Natives
    CreateNative("ControlBuild",Native_ControlBuild);
    CreateNative("ResetBuild",Native_ResetBuild);
    CreateNative("CheckBuild",Native_CheckBuild);
    CreateNative("GiveBuild",Native_GiveBuild);
    CreateNative("HookBuild",Native_HookBuild);

    // Register Forwards
    g_fwdOnBuild=CreateForward(ET_Hook,Param_Cell,Param_Cell,Param_Cell);

    RegPluginLibrary("buildlimit");
    return true;
}

public Native_ControlBuild(Handle:plugin,numParams)
{
    if (numParams == 0)
        g_bNativeControl = true;
    else if (numParams == 1)
        g_bNativeControl = GetNativeCell(1);
}

public Native_GiveBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_iAllowed[client][3] = (numParams >= 2) ? GetNativeCell(2) : 1; // sentry
        g_iAllowed[client][0] = (numParams >= 3) ? GetNativeCell(3) : 1; // dispenser
        g_iAllowed[client][1] = (numParams >= 4) ? GetNativeCell(4) : 1; // teleporter_entry
        g_iAllowed[client][2] = (numParams >= 5) ? GetNativeCell(5) : 1; // teleporter_exit
    }
}

public Native_ResetBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        for (new i=0; i < sizeof(g_iAllowed[]); i++)
            g_iAllowed[client][i] = 1;
    }
}

public Native_CheckBuild(Handle:plugin,numParams)
{
    if (numParams >= 2)
    {
        new iCount;
        new bool:result = CheckBuild(GetNativeCell(1), GetNativeCell(2), iCount);

        if (numParams >= 3)
            SetNativeCellRef(3, iCount);

        return result;
    }
    else
        return false;
}

public Native_HookBuild(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        AddToForward(g_fwdOnBuild, plugin, Function:GetNativeCell(1));
        g_bBuildHooked = true;
    }
}
