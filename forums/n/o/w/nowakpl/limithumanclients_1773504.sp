#include <sourcemod>
#include <sdktools>

new Handle:cvar_sm_maxhumanclients = INVALID_HANDLE;

#define PLUGIN_VERSION "1"
public Plugin:myinfo = {
    name = "limit human clients",
    author = "nowakpl",
    description = "reject client connects above sm_maxhumanclients",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart() {
    cvar_sm_maxhumanclients = CreateConVar("sm_maxhumanclients", "-1", "");
}
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
    new sm_maxhumanclients = GetConVarInt(cvar_sm_maxhumanclients);
    if (sm_maxhumanclients < 0) {
        return true;
    }
    new cc = 0;
    for (new i = 1; i <= MaxClients; ++i) {
        if ((IsClientConnected(i) || IsClientInGame(i)) && !IsFakeClient(i)) {
            ++cc;
        }
    }
    if (cc > sm_maxhumanclients) {
        strcopy(rejectmsg, maxlen, "no client slots available");
        return false;
    }
    return true;
}
