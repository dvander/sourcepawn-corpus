// vim: set filetype=c :

#include <sourcemod>

#define CVAR_BAN_MSG        0
#define CVAR_VERSION        1
#define CVAR_NUM_CVARS      2

#define FLYTRAP_VERSION     "1.0"

public Plugin:myinfo = {
    name = "Command Exploit Flytrap",
    author = "FLOOR_MASTER",
    description = "Automatically ban anyone attempting server-crashing debug commands",
    version = FLYTRAP_VERSION,
    url = "http://www.2fort2furious.com"
};

new Handle:g_cvars[CVAR_NUM_CVARS];

public OnPluginStart() {
    RegConsoleCmd("sv_benchmark_force_start", Command_BenchMark);
    RegConsoleCmd("sv_soundscape_printdebuginfo", Command_SoundScape);
	RegConsoleCmd("achievement_unlock_all", Command_achieve);

    g_cvars[CVAR_BAN_MSG] = CreateConVar(
        "flytrap_banmsg",
        "Banned for using a prohibited command",
        "Message to display when kicking/banning the player",
        FCVAR_PLUGIN);

    g_cvars[CVAR_VERSION] = CreateConVar(
        "flytrap_version",
        FLYTRAP_VERSION,
        "Command Exploit Flytrap Version",
        FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action:Command_BenchMark(client, args) {
    decl String:ban_msg[128];
    GetConVarString(g_cvars[CVAR_BAN_MSG], ban_msg, sizeof(ban_msg));

    LogAction(client, -1, "%L attempted sv_benchmark_force_start, banning", client);
    BanClient(client, 0, BANFLAG_AUTHID, ban_msg, ban_msg);
    return Plugin_Handled;
}

public Action:Command_SoundScape(client, args) {
    decl String:ban_msg[128];
    GetConVarString(g_cvars[CVAR_BAN_MSG], ban_msg, sizeof(ban_msg));

    LogAction(client, -1, "%L attempted sv_soundscape_printdebuginfo, banning", client);
    BanClient(client, 0, BANFLAG_AUTHID, ban_msg, ban_msg);
    return Plugin_Handled;
}

public Action:Command_achieve(client, args) {
    decl String:ban_msg[128];
    GetConVarString(g_cvars[CVAR_BAN_MSG], ban_msg, sizeof(ban_msg));

    LogAction(client, -1, "%L attempted achievement_unlock_all, banning", client);
    BanClient(client, 0, BANFLAG_AUTHID, ban_msg, ban_msg);
    return Plugin_Handled;
}
