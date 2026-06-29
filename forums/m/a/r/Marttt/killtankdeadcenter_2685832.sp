#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

static char sCurrentMap[256];

public Plugin myinfo =
{
    name = "Kill Tank on Dead Center Map 1",
    author = "Mart",
    description = "",
    version = "1.0.0.0",
    url = ""
}

public void OnPluginStart()
{
    GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

    HookEvent("tank_spawn", tank_spawn);
}

public void tank_spawn(Event event, const char[] name, bool dontBroadcast)
{
    if (StrEqual(sCurrentMap, "c1m1_hotel", false))
    {
        int tank = GetClientOfUserId(event.GetInt("userid"));
        AcceptEntityInput(tank, "Kill");
    }
}