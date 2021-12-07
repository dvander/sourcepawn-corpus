/*******************************************************************************

  Bots no headshots

  Version: 1.0
  Author: haN
  
  Description : Bots cant do headshots
                
ENJOY !                

*******************************************************************************/

/////////////////////////////////////////////////////////
///////////////  INCLUDES / DEFINES
/////////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

/////////////////////////////////////////////////////////
///////////////  PLUGIN INFO
/////////////////////////////////////////////////////////

public Plugin:myinfo = 
{
    name = "Bots no headshots",
    author = "haN",
    description = "Bots cant do headshots",
    version = VERSION,
    url = "www.sourcemod.net"
};

/////////////////////////////////////////////////////////
///////////////  ESSENTIAL FUNCTIONS
/////////////////////////////////////////////////////////

public OnPluginStart()
{
    HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
}

/////////////////////////////////////////////////////////
///////////////  EVENT HANDLERs
/////////////////////////////////////////////////////////

public EventPlayerHurt(Handle:event, String:name[], bool:dontBroadCast)
{
    new AttackerId = GetEventInt(event, "attacker");
    new Client_Attacker = GetClientOfUserId(AttackerId);
    new HitGroup = GetEventInt(event, "hitgroup");
    if (IsFakeClient(Client_Attacker) && HitGroup == 1)
    {
        SetEventInt(event, "dmg_health", 0);
    }
    return Plugin_Handled;
}