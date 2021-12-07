#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new propinfoghost;
new bool:jumpdelay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "L4D_Ghostpounce",
    author = " AtomicStryker",
    description = "Left 4 Dead Ghost Pounce",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
    propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
    CreateConVar("l4d_ghostpounce_version", PLUGIN_VERSION, " Ghost Pounce Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnGameFrame()
{
    for (new i=1; i<=MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (IsClientConnected(i))
            {
                new buttons = GetEntProp(i, Prop_Data, "m_nButtons", buttons);
                if(buttons & IN_ATTACK2 && jumpdelay[i] == false)
                {
                PlayerPressesAttack2(i);
                }
            }
        }
    }
}

public Action:PlayerPressesAttack2(client)
{
    if (!IsClientConnected(client)) return Plugin_Continue;
    if (!IsClientInGame(client)) return Plugin_Continue;
    if (GetClientTeam(client)!=3) return Plugin_Continue;
    if (!IsPlayerSpawnGhost(client)) return Plugin_Continue;

    jumpdelay[client] = true;
    CreateTimer(1.0, ResetJumpDelay, client);
    DoPounce(client);

    return Plugin_Continue;
}

public Action:DoPounce(any:client)
{
    new Float:vec[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
    
    if (vec[2] != 0)
    {
    PrintCenterText(client, "You must be on even ground to ghost pounce");
    return Plugin_Handled;
    }
    if (vec[0] == 0)
    {
    PrintCenterText(client, "You must be on the move to ghost pounce");
    return Plugin_Handled;
    }
    if (vec[1] == 0)
    {
    PrintCenterText(client, "You must be on the move to ghost pounce");
    return Plugin_Handled;
    }
    
    vec[0] *= 3;
    vec[1] *= 3;
    vec[2] = 750.0;
    
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
    return Plugin_Continue;
}


bool:IsPlayerSpawnGhost(client)
{
    new isghost = GetEntData(client, propinfoghost, 1);
    
    if (isghost == 1) return true;
    else return false;
}

public Action:ResetJumpDelay(Handle:timer, Handle:client)
{
    jumpdelay[client] = false;
}  