#include <sdktools>

public Plugin:myinfo =
{
	name = "Third Person",
	author = "Bottiger",
	description = "Third Person Plugin",
	version = "1.1",
	url = "http://skial.com"
};

new bool:g_enabled[MAXPLAYERS+1] = {false, ...};

public OnPluginStart() {
    HookEvent("player_spawn", OnSpawn);
    
    RegConsoleCmd("firstperson", ToggleThirdPerson);
    RegConsoleCmd("thirdperson", ToggleThirdPerson);
    RegConsoleCmd("3", ToggleThirdPerson);
}

public OnClientDisconnect(client) {
    g_enabled[client] = false;
}

public Action:ToggleThirdPerson(client, args) {
    if(g_enabled[client]) {
        SetThirdPerson(client, 0);
        g_enabled[client] = false;
        PrintToChat(client, "Thirdperson off. Type !3 to turn it on.");
    } else {
        SetThirdPerson(client, 1);
        g_enabled[client] = true;
        PrintToChat(client, "Thirdperson on. Type !3 to turn it off.");
    }
}

public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_enabled[client]) {
        CreateTimer(0.5, AfterSpawn, GetClientUserId(client));   
    }
}

public Action:AfterSpawn(Handle:timer, any:userid) {
    new client = GetClientOfUserId(userid);
    if(client && g_enabled[client]) {
        SetThirdPerson(client, 1);
        PrintToChat(client, "[Thirdperson] Thirdperson enabled. Type !3 to toggle.");
    }
}

stock SetThirdPerson(client, on_or_off) {
    SetVariantInt(on_or_off);
    AcceptEntityInput(client, "SetForcedTauntCam");
}