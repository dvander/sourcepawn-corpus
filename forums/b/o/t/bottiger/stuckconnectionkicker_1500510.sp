#define PLUGIN_VERSION "1.4"

public Plugin:myinfo = 
{
	name = "Stuck Connection Kicker",
	author = "Bottiger",
	description = "Kick clients stuck connecting",
	version = PLUGIN_VERSION,
	url = "http://tf.skial.com"
};

#include <sourcemod>

enum ConnectionState {
    Disconnected,
    Connecting,
    Connected
}

new ConnectionState:g_connection_state[MAXPLAYERS+1];
new g_connection_time[MAXPLAYERS+1];
new Handle:g_sck_limit;
new Handle:sv_visiblemaxplayers;

public OnPluginStart() {
    CreateConVar("stuck_connection_kicker_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
    g_sck_limit = CreateConVar("sck_limit", "240", "Seconds a client has to fully connect before being kicked.");
    sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
    
    CreateTimer(10.0, CheckLoop, _, TIMER_REPEAT);
}

public Action:CheckLoop(Handle:timer) {
    // only kick if the server is almost full
    new maxslots;
    if(sv_visiblemaxplayers != INVALID_HANDLE) {
        maxslots = GetConVarInt(sv_visiblemaxplayers);
        if(maxslots == -1)
            maxslots = MaxClients;
    }
    
    if(GetClientCount(false) < maxslots)
        return Plugin_Continue;
    
    // begin kicking
    new limit = GetConVarInt(g_sck_limit);
    new now   = GetTime();
    
    for(new i=1;i<=MaxClients;i++) {
        if(g_connection_state[i] != Connecting)
            continue;
        if(now - g_connection_time[i] > limit) {
            LogAction(0, i, "Kicking client taking longer than %i sec to connect.", limit);
            g_connection_state[i] = Disconnected;
            // how can someone not be connected here???
            if(IsClientConnected(i)) {
                KickClient(i, "You are taking too long to connect");
                break;
            }
        }
    }
    return Plugin_Continue;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
    if(IsFakeClient(client))
        return true;
    
    g_connection_state[client] = Connecting;
    g_connection_time[client] = GetTime();
    return true;
}

public OnClientPutInServer(client) {     
    g_connection_state[client] = Connected;
}

public OnClientDisconnected(client) {
    g_connection_state[client] = Disconnected;
}