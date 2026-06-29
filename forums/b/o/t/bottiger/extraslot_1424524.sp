public Plugin:myinfo = 
{
	name = "Extra Slot",
	author = "Bottiger",
	description = "Makes an extra slot by enabling SourceTV",
	version = "1.0",
	url = "http://tf.skial.com"
};

#include <sourcemod>

new Handle:h_tv_enable;

public OnPluginStart() {
    h_tv_enable = FindConVar("tv_enable");
    if( GetConVarInt(h_tv_enable) == 0 ) {
        SetConVarInt(h_tv_enable, 1);
        KickSourceTV();
    }
}

public OnConfigsExecuted() {
    KickSourceTV();
}

public KickSourceTV() {
    decl String:name[256];
    for(new i=1;i<=MaxClients;i++) {
        if(IsClientConnected(i) && IsFakeClient(i)) {
            GetClientName(i, name, sizeof(name));
            if(strcmp("SourceTV", name) == 0) {
                KickClient(i);
                return;
            }
        }
    }
    return;
}