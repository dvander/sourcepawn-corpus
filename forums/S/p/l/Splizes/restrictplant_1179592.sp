#include <sdktools>

new bombsite[2]
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
    HookEvent("round_start",Event_RoundStart);
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

public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
    if ((bombsite[0] != -1) && (bombsite[1] != -1))
    {
        new Players[4]
        new cTeam
        for(new i = 1; i <= MaxClients; i++) {
            if((IsClientInGame(i)) && (!IsFakeClient(i))) {
                cTeam = GetClientTeam(i)
                Players[cTeam]++
            }
        }
        if ((Players[2] < TeamLimitSize) && (Players[3] < TeamLimitSize))
        {
            AcceptEntityInput(bombsite[0],"Disable")
            PrintToChatAll("\x04[SM] \x01Bomb Site \x03B \x01has been restricted, less than \x03%i\x01v\x03%i", TeamLimitSize, TeamLimitSize)
        } else {
            AcceptEntityInput(bombsite[0],"Enable")
            PrintToChatAll("\x04[SM] \x01Bomb Site \x03B \x01has been unrestricted, teams are \x03%i\x01v\x03%i \x01or more", TeamLimitSize, TeamLimitSize)
        }
    }
}
    