/****************************************************************************************************
* Plugin     : L4D - no clone of infected
* Version    : 0.0.1
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : www.l4d.com
* Purpose    : 
* Code snippets: Martts tanks checks / Harry Potter Ontakedamage and Timer idea
****************************************************************************************************/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

static bool g_bL4D2;
static bool g_bswitchongoin=false;
static int g_iTankClass;
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8



public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    g_bL4D2 = (engine == Engine_Left4Dead2);
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
  
 	if (victim && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !IsFakeClient(victim) && g_bswitchongoin==true)
    	{
		//PrintToChatAll("OnTakeDamage victim: %d,attacker: %d, damage is %f", victim, attacker, damage);
		if (damage != 0)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
	}   
	return Plugin_Continue; 
} 

public void OnPluginStart()
{
	HookEvent("player_team", event_onplayerchangeteam, EventHookMode_PostNoCopy);
}



public void event_onplayerchangeteam(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    g_bswitchongoin=true;
    CreateTimer(0.1,RealPlayerChangeTeamEvent,userid); //delay 
}


public Action RealPlayerChangeTeamEvent(Handle timer, int userid)
{
    g_bswitchongoin=false;
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED && IsFakeClient(client) && !IsPlayerTank(client))
    {
        KickClient(client);
       // PrintToChatAll("player_team event delay check. We have an infeced bot right here.");
    } 
    return Plugin_Continue;
} 

bool IsPlayerTank(int client)
{
    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    if (GetZombieClass(client) != g_iTankClass)
        return false;

    return true;
}

int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

