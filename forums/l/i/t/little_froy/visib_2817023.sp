#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                float pos[3];
                GetClientEyePosition(i, pos);
                PrintToChatAll("can %N see %N?:%d", client, i, L4D2_IsVisibleToPlayer(client, 2, 3, 0, pos));
            }
        }
    }
}