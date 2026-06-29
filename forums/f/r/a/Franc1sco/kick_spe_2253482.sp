#include <sourcemod>

new Handle:g_cvar_checktime = INVALID_HANDLE;

public OnPluginStart() {
    g_cvar_checktime = CreateConVar("checktime", " 60", "How often in seconds that players will be counted and action accordingly taken.");
    
    AutoExecConfig(true, "kickspec");
}

public OnMapStart()
{
	CreateTimer(GetConVarFloat(g_cvar_checktime), CountPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CountPlayers(Handle:timer) {
    if (GetClientCount() >= GetMaxHumanPlayers()) {
        for (new i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && GetClientTeam(i) < 2)
                KickClient(i, "AFK on full server.");
        }
    }
}  