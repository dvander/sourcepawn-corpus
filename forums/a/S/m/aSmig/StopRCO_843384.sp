#include <sourcemod>
#include <clients>
#pragma semicolon 1
#define VERSION "1.0.2"

public Plugin:myinfo = {
    name = "StopRCO",
    author = "aSmig",
    description = "Stop people from doing a reliable channel overflow attack.",
    version = VERSION,
    url = "http://ta.failte.romhat.net/blog/?cat=4"
};

new a_Spam[MAXPLAYERS+1];
new Handle:a_SpamTimers[MAXPLAYERS+1];
new Handle:g_Cvar_Ban = INVALID_HANDLE;
new Handle:g_Cvar_BanTime = INVALID_HANDLE;

public OnPluginStart() {
    RegConsoleCmd("timeleft", Command_Spam);
    RegConsoleCmd("ma_timeleft", Command_Spam);
    RegConsoleCmd("sm_timeleft", Command_Spam);
    RegConsoleCmd("nextmap", Command_Spam);
    RegConsoleCmd("ma_nextmap", Command_Spam);
    RegConsoleCmd("sm_nextmap", Command_Spam);
    RegConsoleCmd("listmaps", Command_Spam);
    RegConsoleCmd("ping", Command_Spam);
    RegConsoleCmd("status", Command_Spam);
    CreateConVar("stoprco_version", VERSION, "This version of StopRCO is running.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_Cvar_Ban = CreateConVar("stoprco_ban", "1", "If an offender should be banned for doing a reliable channel overflow attack.");
    g_Cvar_BanTime = CreateConVar("stoprco_bantime", "0", "Number of minutes to ban an offender for, 0 for forever.");
    PrintToServer("[StopRCO] v%s loaded.", VERSION);
}

public OnConfigsExecuted() {
    for (new i=0; i<=MAXPLAYERS; i++) a_Spam[i] = 0;
}

public OnClientDisconnect_Post(client) {
    a_Spam[client] = 0;
    if (a_SpamTimers[client] != INVALID_HANDLE) {
	CloseHandle(a_SpamTimers[client]);
	a_SpamTimers[client] = INVALID_HANDLE;
    }
}

public OnPluginEnd() {
    PrintToServer("[StopRCO] unloaded.");
}
 
public Action:ResetCount(Handle:timer, any:client) {
    a_SpamTimers[client] = INVALID_HANDLE;
    a_Spam[client] = 0;
}

public Action:Command_Spam(client, args) {
    if (client && IsClientConnected(client) && a_Spam[client]++ > 3) {
	new String:name[255];
	GetClientName(client, name, sizeof name);
	new String:steam[32];
	GetClientAuthString(client, steam, sizeof(steam));
	if (GetConVarInt(g_Cvar_Ban)) {
	    BanClient(client, GetConVarInt(g_Cvar_BanTime), BANFLAG_AUTHID||BANFLAG_AUTO, "Reliable channel overflow attack.", "pwnd n00b");
	} else {
	    KickClientEx(client, "pwnd n00b");
	}
	PrintToChatAll("User %s (%s) was kicked for attempting to use the reliable channel overflow exploit", name, steam);
	return Plugin_Stop;
    } else {
	if (a_SpamTimers[client] != INVALID_HANDLE) CloseHandle(a_SpamTimers[client]);
	a_SpamTimers[client] = CreateTimer(5.0, ResetCount, client);
	return Plugin_Continue;
    }
}
