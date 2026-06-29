#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <zombiereloaded>

#define VERSION "v1.0"

new bool:infeccion = false;
new g_offsCollisionGroup;

public Plugin:myinfo = 
{
	name = "SM ZR NoBlock",
	author = "Franc1sco Steam: franug",
	description = "Gives noblock before infection",
	version = VERSION,
	url = "http://www.servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{

	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");

	if (g_offsCollisionGroup == -1)
	{
		SetFailState("Failed to get offset for CBaseEntity::m_CollisionGroup");
	}


	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
        HookEvent("player_spawn", PlayerSpawn);
	CreateConVar("zr_noblock", VERSION, "data", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	infeccion = false;

}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  if (!infeccion)
  	SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
  if (!infeccion)
  {
  	     for (new i = 1; i < GetMaxClients(); i++)
             {
	                     if (IsClientInGame(i) && IsPlayerAlive(i))
	                     {
                                    SetEntData(i, g_offsCollisionGroup, 5, 4, true);
                                    
	                     }
             }
	     infeccion = true;
  }
}