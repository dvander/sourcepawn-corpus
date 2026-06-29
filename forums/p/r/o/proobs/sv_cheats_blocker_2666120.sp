#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "sv cheats blocker",
	author = "proobs",
	description = "block for people abusing the new sv cheats bug. Read more about it here: https://www.unknowncheats.me/forum/counterstrike-global-offensive/353709-replicated-cvar-bypass-exploit.html",
	version = "1.2",
	url = "https://github.com/proobs"
};

Handle g_hTimer[MAXPLAYERS + 1];

public void OnClientPutInServer(int client) {
	if(IsClientValid(client)) {
		g_hTimer[client] = CreateTimer(0.5, TIMER_CHECKVAL, client, TIMER_REPEAT);
	}
}

public void OnClientDisconnect(int client) {
	KillTimer(g_hTimer[client]);
}

public Action TIMER_CHECKVAL(Handle timer, any client) {
	if(IsClientInGame(client))
		QueryClientConVar(client, "sv_cheats", ClientConVarChanged);
}

public void ClientConVarChanged(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	if(StrEqual(cvarValue, "1")) {
		KickClient(client, "client tried to enable sv cheats..");
	}
}

stock bool IsClientValid(int client) {
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || !IsClientConnected(client) || IsFakeClient(client))
        return false;
       
    return true;
}