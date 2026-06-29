#pragma semicolon 1                  // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME             "Field of View"
#define PLUGIN_DESC             "Modify Field of View (FoV) for a client"
#define PLUGIN_AUTHOR           "Mecha the Slag"
#define PLUGIN_VERSION          "1.1"
#define PLUGIN_CONTACT          "www.mechaware.net/"

#define DEFAULT_FOV             75

new g_Fov[MAXPLAYERS+1] = DEFAULT_FOV;
new g_CFov[MAXPLAYERS+1] = DEFAULT_FOV;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{
    RegAdminCmd("sm_fov", Command_Fov, ADMFLAG_SLAY, "sm_fov <#userid|name> [value]");
    CreateConVar("fov_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
    HookEvent("player_spawn", Player_Spawn, EventHookMode_PostNoCopy);
}

public Action:Command_Fov(client, args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_fov <#userid|name> [value]");
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    decl String:Sarg2[65];
    GetCmdArg(2, Sarg2, sizeof(Sarg2));
    new arg2 = StringToInt(Sarg2);

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        if (IsValidClient(client)) ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (new i = 0; i < target_count; i++) {
        new target = target_list[i];
        if (IsValidClient(target)) {
            g_Fov[target] = arg2;
        }
    }

    if (tn_is_ml)
    {
        ShowActivity2(client, "[SM] ", "Changed FoV on target", target_name);
    }
    else
    {
        ShowActivity2(client, "[SM] ", "Changed FoV on target", "_s", target_name);
    }

    return Plugin_Handled;
}

public Action:Player_Spawn(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    g_CFov[client] = g_Fov[client];
    SetEntProp(client, Prop_Send, "m_iFOV", g_CFov[client]);
    SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_CFov[client]);
}

public OnGameFrame()
{
    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsPlayerAlive(i)) {
            new fov = g_CFov[i];
            if (fov != g_Fov[i]) {
                new fov2 = fov + (g_Fov[i] - fov)/4;
                if (fov2 == fov && g_Fov[i] > fov2) fov2 += 1;
                if (fov2 == fov && g_Fov[i] < fov2) fov2 -= 1;
                g_CFov[i] = fov2;
                SetEntProp(i, Prop_Send, "m_iFOV", g_CFov[i]);
                SetEntProp(i, Prop_Send, "m_iDefaultFOV", g_CFov[i]);
            }
        }
    }
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public OnClientPutInServer(client) {
    g_Fov[client] = DEFAULT_FOV;
    g_CFov[client] = DEFAULT_FOV;
    
}

public OnClientDisconnect(client) {
    g_Fov[client] = DEFAULT_FOV;
    g_CFov[client] = DEFAULT_FOV;
}
