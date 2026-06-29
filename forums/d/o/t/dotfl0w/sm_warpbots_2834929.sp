#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define TEAM_SURVIVOR 2

public OnPluginStart() {
    RegAdminCmd("sm_warpbots", Command_warpBots, ADMFLAG_SLAY);
}

public Action Command_warpBots(int client, int args) {
    if (!client) {
        PrintToServer("[SM] Unable to execute this command from the server console!");
        return Plugin_Handled;
    }
    
    float clientPos[3];
    GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientPos);
    
    bool botFound = false;
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) continue;
        if (!IsFakeClient(i)) continue;
        if (GetClientTeam(i) != TEAM_SURVIVOR) continue;

        // V1.1: Check if bot is incapacitated, alive, or hanging
        bool isIncapacitated = GetEntProp(i, Prop_Send, "m_isIncapacitated") > 0;
        bool isHanging = GetEntProp(i, Prop_Send, "m_isHangingFromLedge") == 1;

        if (!IsPlayerAlive(i) && !isIncapacitated && !isHanging) continue;

        // V1.2: If bot is hanging, make them drop first
        if (isHanging) {
            SetEntProp(i, Prop_Send, "m_isHangingFromLedge", 0);
        }

        TeleportEntity(i, clientPos, NULL_VECTOR, NULL_VECTOR);
        ReplyToCommand(client, "[SM] Teleported %N to you.", i);
        botFound = true;
    }
    
    if (!botFound) {
        ReplyToCommand(client, "[SM] Could not find any bots to teleport.");
    }
    
    return Plugin_Handled;
}