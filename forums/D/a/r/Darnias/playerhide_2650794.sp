#include <sourcemod>
#include <sdktools> 
#include <sdkhooks> 
#include <clientprefs>

#define MAX_2D_DIST 72
#define MAX_VERTICAL_DIST 64
Handle g_hHidePlayersCookie;
new bool:g_playerEnabled[MAXPLAYERS+1] = {true, ...};
new bool:g_showPlayer[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Manic idiot hider",
    author = "Jeremy Johanessohn Barnes",
    description = "Disguises humans as nothingness.",
    version = "1.2.3",
    url = "http://www.burgerking.com/"
};

public OnPluginStart()
{ 
    RegAdminCmd("sm_see", PlayerEnableCmd, 0, "Toggles visibility status.");
    RegAdminCmd("sm_hide", PlayerEnableCmd, 0, "Toggles visibility status.");

    g_hHidePlayersCookie = RegClientCookie("hide_players", "Hide Players", CookieAccess_Protected);

    CreateTimer(0.2, ComputeDistances, _, TIMER_REPEAT);
    for (new i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i)) 
        {
            OnClientPutInServer(i); 
        }
    }
}

public void OnClientCookiesCached(int client)
{
    static char sCookieValue[2];
    GetClientCookie(client, g_hHidePlayersCookie, sCookieValue, sizeof(sCookieValue));
    g_playerEnabled[client] = bool:StringToInt(sCookieValue);
}

public Action:PlayerEnableCmd(client, args)
{
    if(!AreClientCookiesCached(client))
    {
        ReplyToCommand(client, "\x01 \x04[HIDE]\x01 Please wait until your visibility status settings are loaded. ");
        return Plugin_Handled;
    }

    g_playerEnabled[client] = !g_playerEnabled[client];
    if (g_playerEnabled[client])
        PrintToChat(client, "\x01 \x04[HIDE]\x01 Nearby players are now hidden. ");
    else
        PrintToChat(client, "\x01 \x04[HIDE]\x01 Nearby players are now visible. ");

    static char sCookieValue[2];
    IntToString(g_playerEnabled[client], sCookieValue, sizeof(sCookieValue));
    SetClientCookie(client, g_hHidePlayersCookie, sCookieValue);

    return Plugin_Handled;
}

public OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public OnClientDisconnect(int client)
{
    g_playerEnabled[client] = true;
}

public Action:ComputeDistances(Handle Timer) 
{
    for (new i = 1; i < MaxClients; i++) {
        for (new j = i + 1; j <= MaxClients; j++) {
            if (IsClientInGame(i) &&
            	IsClientInGame(j) &&
            	IsPlayerAlive(i) && 
                IsPlayerAlive(j)) 
            {
                new Float:observer[3];
                new Float:observed[3];
                GetClientAbsOrigin(i, Float:observer);
                GetClientAbsOrigin(j, Float:observed);

                // Get the distance
                new Float:dist[3];
                SubtractVectors(observer, observed, dist);

                // Check whether the players see eachother or not
                new bool:seeEachother = (dist[0] * dist[0] + dist[1] * dist[1] < MAX_2D_DIST * MAX_2D_DIST && FloatAbs(dist[2]) < MAX_VERTICAL_DIST);

                // Set the symmetrical blocks to whatever state
                g_showPlayer[i][j] = seeEachother;
                g_showPlayer[j][i] = seeEachother;
            }
        }
    }
}

public Action Hook_SetTransmit(int entity, int client)
{
    if (client != entity && 
        0 < entity && 
        entity <= MaxClients && 
        g_showPlayer[client][entity] && 
        g_playerEnabled[client] &&
        IsPlayerAlive(client) && 
        IsPlayerAlive(entity) && 
        GetClientTeam(client) == GetClientTeam(entity)) 
    {
            return Plugin_Handled;
    }
    return Plugin_Continue;
}