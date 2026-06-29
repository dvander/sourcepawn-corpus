#pragma semicolon 1

#include <sourcemod>

ConVar mpIdleDealMethodConVar;
ConVar sourceTVConVar;
ConVar lpnaTriggerBelowConVar;
int originalIdleDealMethod = 1;
bool capturedPreviousIdleDealMethod = false;

public Plugin myinfo = {
    name = "Low Population No Autokick",
    author = "MegaLeg",
    description = "Don't kick players for being idle during low pop conditions",
    version = "1.0",
    url = "https://git.upwardmc.net/UpwardMC/TF2/LowPopNoAutokick"
};

public void OnPluginStart() {
    mpIdleDealMethodConVar = FindConVar("mp_idledealmethod");
    sourceTVConVar = FindConVar("tv_enable");
    lpnaTriggerBelowConVar = CreateConVar("lpna_trigger_below", "18", "How many players are required for autokick", FCVAR_NONE, true, 2.0, true, MAXPLAYERS - 1.0);

    HookConVarChange(lpnaTriggerBelowConVar, lpnaTriggerBelowChanged);

    PrintToServer("[LowPopNoAutokick] Plugin loaded");
}

public void OnPluginEnd() {
    SetConVarInt(mpIdleDealMethodConVar, originalIdleDealMethod);
}

public void OnConfigsExecuted() {
    if (!capturedPreviousIdleDealMethod) {
        originalIdleDealMethod = GetConVarInt(mpIdleDealMethodConVar);

        capturedPreviousIdleDealMethod = true;
    }

    checkAutokickThreshold();
}

public void lpnaTriggerBelowChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    checkAutokickThreshold();
}

public void OnClientPutInServer(int client) {
    checkAutokickThreshold();
}

public void OnClientDisconnect_Post(int client) {
    checkAutokickThreshold();
}

void checkAutokickThreshold() {
    // STV bot or TF bots could theoretically join before configs execute
    if (!capturedPreviousIdleDealMethod) {
        return;
    }

    int lpnaTriggerBelowValue = GetConVarInt(lpnaTriggerBelowConVar);
    int connectedClients = GetClientCount(false);

    int sourceTVActiveValue = GetConVarInt(sourceTVConVar);

    if (sourceTVActiveValue != 0) {
        connectedClients = connectedClients - 1;
    }

    bool shouldDisableAutokick = connectedClients < lpnaTriggerBelowValue;

    if (shouldDisableAutokick) {
        SetConVarInt(mpIdleDealMethodConVar, 0);
    } else {
        SetConVarInt(mpIdleDealMethodConVar, originalIdleDealMethod);
    }
}