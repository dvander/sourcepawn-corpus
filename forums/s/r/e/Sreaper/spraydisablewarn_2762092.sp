#include <sdktools>
#pragma semicolon	1
#pragma newdecls required;

#define PLUGIN_VERSION			"0.9"

char g_sSprayDisable[22] = "cl_spraydisable";

public Plugin myinfo = {
	name = "Are sprays disabled?",
	author = "Timely",
	description = "Warns client if sprays are disabled",
	version = PLUGIN_VERSION,
	url = "nourl"
};

Handle g_hTimer = INVALID_HANDLE;

public void OnPluginStart() {
    if (GetEngineVersion() == Engine_Left4Dead2)
        g_sSprayDisable = "cl_playerspraydisable";
}

public void OnMapStart() {
	g_hTimer = CreateTimer(60.0, Timer_CheckAllClientsConVar, _, TIMER_REPEAT);
}

public void OnMapEnd() {
	if (g_hTimer != INVALID_HANDLE)
		KillTimer(g_hTimer);
	g_hTimer = INVALID_HANDLE;
}

public Action Timer_CheckAllClientsConVar(Handle hTimer, any nothing) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
		QueryClientConVar(i, g_sSprayDisable, QueryClient_ConVar, i);
	}
	return Plugin_Continue;
}

public void QueryClient_ConVar(QueryCookie qCookie, int iClient, ConVarQueryResult qResult,
		const char[] sCVarName, const char[] sCVarValue) {
    if (StrEqual(sCVarValue, "1")) {
        PrintToChat(iClient, "\x07FFFFFF[Sprays] You have\x0734eb64 %s \x07FFFFFFset to\x0734eb64 1\x07FFFFFF. Is that intentional?", g_sSprayDisable);
    }
}