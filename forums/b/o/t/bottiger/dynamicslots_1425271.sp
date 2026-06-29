public Plugin:myinfo = 
{
	name = "Dynamic Slots",
	author = "Bottiger",
	description = "Expands your maximum slots when you reach X players.",
	version = "1.0",
	url = "http://tf.skial.com"
};

#include <sourcemod>

new Handle:hThreshold;
new Handle:hLow;
new Handle:hHigh;
new Handle:hMaxPlayers

public OnPluginStart() {
    hThreshold = CreateConVar("dynamicslots_threshold", "24", "When you have this many players, expand slots to dynamicslots_high. Dropping below will set to dynamicslots_low");
    hHigh = CreateConVar("dynamicslots_high", "32", "Expands slots to this when players meet or exceed the threshold");
    hLow  = CreateConVar("dynamicslots_low", "24", "Shrinks slots to this when players drop below threshold");
    hMaxPlayers = FindConVar("sv_visiblemaxplayers");
    ExecuteLogic();
}

public OnClientConnected(client) {
    ExecuteLogic();
}

public OnClientDisconnect() {
    ExecuteLogic();
}

public ExecuteLogic() {
    new clients = GetRealClientCount(false);
    new threshold = GetConVarInt(hThreshold);
    if(clients < threshold) {
        PrintToServer("Below threshold. Setting to dynamicslots_low.");
        SetConVarInt(hMaxPlayers, GetConVarInt(hLow));
    } else {
        PrintToServer("Met or above threshold. Setting to dynamicslots_high.");
        SetConVarInt(hMaxPlayers, GetConVarInt(hHigh));
    }
}

GetRealClientCount(bool:inGameOnly=true) {
    new clients = 0;
    for(new i=1;i<=MaxClients; i++ ) {
        if((inGameOnly ? IsClientInGame( i ): IsClientConnected(i)) && !IsFakeClient(i))
            clients++;
    }
    return clients;
}