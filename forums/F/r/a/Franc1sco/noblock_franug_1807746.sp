#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#pragma semicolon 1

#define VERSION "v3.0 csgo reedited"


new Handle:sm_noblock_cts;
new Handle:sm_noblock_ts;
new Handle:sm_noblock_time;
new Handle:noblock2time;

new Handle:noblockcvar = INVALID_HANDLE;

new bool:g_ShouldCollide[MAXPLAYERS+1] = { true, ... };
//new bool:g_IsNoBlock[MAXPLAYERS+1] = {false, ...};
new bool:g_IsNoBlock2[MAXPLAYERS+1] = {false, ...};

new Veces[MAXPLAYERS+1] = 0;



public Plugin:myinfo = 
{
	name = "SM Franug NoBlock",
	author = "Franc1sco Steam: franug",
	description = "Gives players noblock exceeded a limit of players in the game, mixing 2 types of noblock",
	version = VERSION,
	url = "http://www.servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

        HookEvent("player_spawn", PlayerSpawn);

	CreateConVar("sm_noblockug", VERSION, "data", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//CreateConVar("www.servers-cfg.foroactivo.com", "Pagina de configuraciones y plugins en Castellano", "version del plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	sm_noblock_cts = CreateConVar("sm_noblock_cts", "10", "CT max for the noblock in round start");
	sm_noblock_ts = CreateConVar("sm_noblock_ts", "10", "Ts max for the noblock in round start");

	sm_noblock_time = CreateConVar("sm_noblock_time", "6", "time for inicial noblock");

        noblock2time = CreateConVar("sm_noblock2_time", "10", "time for secundary noblock (added after inicial noblock and in !noblock command)");

        RegConsoleCmd("sm_noblock", DONoBlock);
        RegConsoleCmd("sm_nb", DONoBlock);

	noblockcvar = FindConVar("mp_solid_teammates");

    	if (noblockcvar == INVALID_HANDLE)
    	{
        	SetFailState("This plugin is for CS:GO only (need mp_solid_teammates).");
    	}

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

		new Ts, CTs;
		for(new i=1; i <= MaxClients; i++)
		{
			if ( (IsValidClient(i)) && (IsPlayerAlive(i)) )
			{
				if (GetClientTeam(i) == CS_TEAM_T)
					Ts++;
				else if (GetClientTeam(i) == CS_TEAM_CT)
					CTs++;
			}
		}

		SetConVarInt(noblockcvar, 0, false, false);

		if ((Ts > GetConVarInt(sm_noblock_ts)) && (CTs > GetConVarInt(sm_noblock_cts)))
		{
                      for (new i = 1; i < GetMaxClients(); i++)
                      {
	                     if ((IsValidClient(i)) && (IsPlayerAlive(i)))
	                     {
                                    PrintToChat(i, "\x04[SM_NoBlock-ug]\x01 You have %i seconds of total NoBlock", GetConVarInt(sm_noblock_time));
                                    //g_IsNoBlock[i] = true;
                                    
	                     }
                      }
                }
		CreateTimer(GetConVarInt(sm_noblock_time) * 1.0, DesactivadoNB);
}

public Action:DesactivadoNB(Handle:timer)
{
 for (new client = 1; client < GetMaxClients(); client++)
 {
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
   {
         PrintToChat(client, "\x04[SM_NoBlock-ug]\x01 Now you have %i seconds of secundary NoBlock", GetConVarInt(noblock2time));
         //g_IsNoBlock[client] = false;

         Veces[client] = GetConVarInt(noblock2time);
         CreateTimer(1.0, Repetidor, client, TIMER_REPEAT);
         g_IsNoBlock2[client] = true;
   }
 }
 SetConVarInt(noblockcvar, 1, false, false);
}

public Action:DesactivadoNB2(Handle:timer, any:client)
{
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
   {
     if (g_IsNoBlock2[client])
     {
         g_IsNoBlock2[client] = false;
         PrintToChat(client, "\x04[SM_NoBlock-ug]\x01 Now you have not NoBlock");
     }
   }
}

public Action:DONoBlock(client,args)
{
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && !g_IsNoBlock2[client])
   {
         PrintToChat(client, "\x04[SM_NoBlock-ug]\x01 Now you have %i seconds of secundary NoBlock", GetConVarInt(noblock2time));
         CreateTimer(GetConVarInt(noblock2time) * 1.0, DesactivadoNB2, client);
         g_IsNoBlock2[client] = true;
   }
   else
   {
         PrintToChat(client, "\x04[SM_NoBlock-ug]\x01 You have noblock or you not be alive");
   }
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  if (IsValidClient(client) && GetClientTeam(client) != 1 && IsPlayerAlive(client))
  {
/*
    if (g_IsNoBlock[client])
    {
      g_IsNoBlock[client] = false;
    }
*/
    if (g_IsNoBlock2[client])
    {
      g_IsNoBlock2[client] = false;
    }
  }
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	SDKHook(client, SDKHook_StartTouch, Touch);
	SDKHook(client, SDKHook_Touch, Touch);
	SDKHook(client, SDKHook_EndTouch, EndTouch);
}



public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:result)
{
		
	if (contentsmask == 33636363)
	{
		
		if(!g_ShouldCollide[entity])
		{
			result = false;
			return false;
		}
		else
		{
			result = true;
			return true;
		}
	}
	
	return true;
}

public Touch(ent1, ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

        if(g_IsNoBlock2[ent1])
        {
           Veces[ent1] = GetConVarInt(noblock2time);
	   g_ShouldCollide[ent1] = false;
	   g_ShouldCollide[ent2] = false;
        }
}


public EndTouch(ent1, ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

	if(!g_ShouldCollide[ent1])
	{
            CreateTimer(1.0, TurnOnCollision, ent1);
	}

	if(!g_ShouldCollide[ent2])
	{
            CreateTimer(1.0, TurnOnCollision, ent2);
	}
} 

public Action:TurnOnCollision(Handle:timer, any:client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && !g_ShouldCollide[client])
        g_ShouldCollide[client] = true;
        
    return Plugin_Handled;
} 

public Action:Repetidor(Handle:timer, any:client)
{
        if (!IsValidClient(client) || GetClientTeam(client) == 1 || !IsPlayerAlive(client))
        {
		return Plugin_Stop;
        }

        if (Veces[client] == 0)
	{
                g_IsNoBlock2[client] = false;
                PrintToChat(client, "\x04[SM_NoBlock-ug]\x01 Now you have not NoBlock");
		return Plugin_Stop;
	}

        else if(!g_IsNoBlock2[client])
        {
	        return Plugin_Stop;
        }

        Veces[client] -= 1;

	return Plugin_Continue;
}