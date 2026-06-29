#include <sourcemod>
#include <tf2>
#pragma semicolon 1

#define SPAWNSLIMIT 1
new iPlayerRespawns[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "Respawn",
    author = "ShowTeK",
    description = "Respawn with Time Restriction",
    version = "1.0.1",
}

public OnPluginStart()
{
    RegConsoleCmd("sm_spawn", Command_Spawn);
}

new bool:global_boolean_Stop = false;

public Action:Command_Spawn(client, args)
{
    if(client >0 && IsClientConnected(client) && IsClientInGame(client))
    {
        if(iPlayerRespawns[client] < SPAWNSLIMIT)
        {
            if(!IsPlayerAlive(client))
            {
                TF2_RespawnPlayer(client);
                PrintToChat(client, "You have Respawned!");
                iPlayerRespawns[client]++;
            }
            else
            {
                PrintToChat(client, "You have to be dead");
            }
        }
        else
        {
            PrintToChat(client, "Respawn Limit by 25 Mins", SPAWNSLIMIT);
        }
    }
    if(global_boolean_Stop)
    { 
        return Plugin_Handled;
    } 

    CreateTimer(1500.0, MyTimer);
    global_boolean_Stop = true;
    
    return Plugin_Handled;
}

public Action:MyTimer(Handle:timer) 
{ 
    ResetSpawns();
    global_boolean_Stop = false;
}

ResetSpawns()
{
    new len = sizeof(iPlayerRespawns);
    for(new i; i<len; i++)
    {
        iPlayerRespawns[i] = 0;
    }
}  