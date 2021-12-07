#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new Handle:g_hConVar_FoV;

public Plugin:myinfo = {
    name = "FoV Changer",
    author = "bl4nk",
    description = "Set everyone's FoV to a specific value",
    version = "1.0.0",
    url = "http://forums.joe.to/"
};

public OnPluginStart() {
    g_hConVar_FoV = CreateConVar("sm_setfov", "0", "Set everyone's FoV to this value (0 = disable)", FCVAR_PLUGIN, true, 0.0);
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            SDKHook(i, SDKHook_ThinkPost, OnThinkPost);
        }
    }
}

public OnClientPutInServer(iClient) {
    SDKHook(iClient, SDKHook_ThinkPost, OnThinkPost);
}

public Action:OnThinkPost(iClient) {
    if (IsPlayerAlive(iClient)) {
        new iFoV = GetConVarInt(g_hConVar_FoV);
        if (iFoV > 0) {
            SetEntProp(iClient, Prop_Send, "m_iFOV", iFoV);
            SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFoV);
        }
    }
}