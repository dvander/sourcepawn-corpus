#include <sdktools>

new bombsite[2]
new bool:SiteOpen
new TeamLimitSize = 5

public Plugin:myinfo =
{
    name = "Bombsite Limiter",
    author = "Splizes",
    description = "Simple limiter of BombSites",
    version = "0.0.1",
    url = ""
}

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart)
    HookEvent("bomb_beginplant", Event_BombBPlant, EventHookMode_Pre)
}

public OnMapStart()
{
    new index = -1
    bombsite[0] = -1, bombsite[1] = -1
    while ((index = FindEntityByClassname(index,"func_bomb_target")) != -1)
    {
        if (bombsite[0] == -1)
        {
            bombsite[0] = index;
        }
        if ((bombsite[1] == -1)  && (index != bombsite[0]))
        {
            bombsite[1] = index;
        }
    }
}

public Action:Event_BombBPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
    if ((GetEventInt(event, "site") == bombsite[0]) && (!SiteOpen)) {
        new user = GetClientOfUserId(GetEventInt(event, "userid"))
        new Handle:abort = CreateEvent("bomb_abortplant")
        SetEventInt(abort, "userid", user)
        SetEventInt(abort, "site", bombsite[0])
        FireEvent(abort)
        AcceptEntityInput(bombsite[0],"Disable")
        CreateTimer(0.5, EnableBombSite, user)
        return Plugin_Handled
    }
    return Plugin_Continue
}

public Action:EnableBombSite(Handle:timer, any:user)
{
    AcceptEntityInput(bombsite[0],"Enable")
    PrintCenterText(user, "[SM] Bomb site B has been restricted, 5v5 required for unrestrict") 
}

public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
    if ((bombsite[0] != -1) && (bombsite[1] != -1))
    {
        new Players[4]
        new cTeam
        for(new i = 1; i <= MaxClients; i++) {
            if((IsClientInGame(i))) {
                cTeam = GetClientTeam(i)
                Players[cTeam]++
            }
        }
        if ((Players[2] < TeamLimitSize) || (Players[3] < TeamLimitSize)) {
            //AcceptEntityInput(bombsite[0],"Disable")
            SiteOpen = false
            PrintToChatAll("\x04[SM] \x01Bomb Site \x03B \x01has been restricted, less than \x03%i\x01 players per team.", TeamLimitSize)
        } else {
            //AcceptEntityInput(bombsite[0],"Enable")
            SiteOpen = true
            PrintToChatAll("\x04[SM] \x01Bomb Site \x03B \x01has been unrestricted, more than \x03%i\x01 players per team.", TeamLimitSize)
        }
    }
}
    