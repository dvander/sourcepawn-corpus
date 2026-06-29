#pragma semicolon 1

#include <sourcemod>
#include <panorama_check>

#pragma newdecls required

public Plugin myinfo = 
{
    name = "Panorama Check(CS:GO)",
    author = "Charles_(hypnos)",
    description = "Allows you to detect if a client is using the CS:GO panorama UI.",
    version = "1.0",
    url = "https://forums.alliedmods.net/member.php?u=261532"
}

bool g_bIsPanorama[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_CSGO)
    {
        FormatEx(error, err_max, "The plugin only works on CS:GO");
        return APLRes_Failure;
    }

    CreateNative("UseClientPanorama", Native_UseClientPanorama);

    return APLRes_Success;
}

void PanoramaCheck(int client)
{
    g_bIsPanorama[client] = false;
    QueryClientConVar(client, "@panorama_debug_overlay_opacity", ClientConVar);
}

public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (result != ConVarQuery_Okay) {
        g_bIsPanorama[client] = false;
        return;
    }
    else
    {
        g_bIsPanorama[client] = true;
        return;
    }
}

public void OnClientPostAdminCheck(int client)
{
    PanoramaCheck(client);
}

public int Native_UseClientPanorama(Handle plugin, int numParams)
{
    return g_bIsPanorama[GetNativeCell(1)];
}