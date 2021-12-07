/*
   - v1.2.2 Fully functioning general release version
   - In this version the deadtalk function is per-player choice. Players who have it off will not
   -  hear dead players with it on and vice versa. This mode needs the interrogate.inc.
*/

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <interrogate>

#define VERSION "1.3.0"
#pragma newdecls required

float CALLOUT_TIME = 5.0; //Easy change how long before a dead player is put in Deadtalk
Handle Cvar_Deadtalk = INVALID_HANDLE; //Stores if plugin is enabled

public Plugin myinfo =
{
   name = "Bazooka's Deadtalk Plugin",
   description = "Plugin that enables the deadtalk function. Dead players can talk to and hear all other dead players, while also hearing their team; live players do not hear dead teammates.",
   author = "bazooka",
   version = VERSION,
   url = "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
   //Setup convars
   CreateConVar("sm_deadtalk_version", VERSION,"Bazooka's deadtalk plugin version");
   Cvar_Deadtalk = CreateConVar("sm_deadtalk_enable", "1", "1 - Enable deadtalk | 0 - Disable deadtalk");

   //Setup hooks
   HookEvent("player_spawn", Event_PlayerSpawn);
   HookEvent("player_death", Event_PlayerDeath);
}

public void OnEventShutdown()
{
   UnhookEvent("player_spawn", Event_PlayerSpawn);
   UnhookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
   if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
   {
      return Plugin_Stop;
   }

   int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get client that spawned

   if(IsClientInInterrogation(client))
   {
      return Plugin_Handled;
   }

   //loop through every other client in server
   for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
   {
      if(!IsClientInGame(otherClient) || client == otherClient)
      {
         //Ignore if other client disconnected or found own client
         continue;
      }

      if(IsClientInInterrogation(otherClient))
      {
         continue;
      }

      //Reset client listening
      SetListenOverride(client, otherClient, Listen_Default);
   }

   return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
   if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
   {
      return Plugin_Stop;
   }

   int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get the client that died

   if(!IsClientInGame(client) || IsPlayerAlive(client))
   {
      return Plugin_Continue;
   }

   if(IsClientInInterrogation(client))
   {
      return Plugin_Continue;
   }

   //Alert client they have 5 seconds to callout
   CPrintToChat(client, "{orchid}Deadtalk: {default}You now have %.0f seconds to callout before deadtalk begins.", CALLOUT_TIME);
   CreateTimer(CALLOUT_TIME, deadtalk_timer, client);

   return Plugin_Continue;
}

public Action deadtalk_timer(Handle timer, any client)
{
   if(!IsClientInGame(client) || IsPlayerAlive(client))
   {
      return Plugin_Continue;
   }

   if(IsClientInInterrogation(client))
   {
      return Plugin_Continue;
   }

   CPrintToChat(client, "{orchid}Deadtalk: {default}Now in deadtalk. Live teammates cannot hear you, but you may talk with all other dead players.");

   for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
   {
      if(!IsClientInGame(otherClient) || otherClient == client)
      {
         //Ignore if other client not in game or found own client
         continue;
      }

      if(IsClientInInterrogation(otherClient))
      {
         continue;
      }

      if(!IsPlayerAlive(otherClient))
      {
         //If other client is also dead with deadtalk enabled, set clients can hear each other
         SetListenOverride(client, otherClient, Listen_Yes);
         SetListenOverride(otherClient, client, Listen_Yes);
      }
      else if(GetClientTeam(otherClient) == GetClientTeam(client)) //Clients are on same team
      {
         //Dead clients can still hear clients on their own team, but live teammates cant hear dead
         SetListenOverride(client, otherClient, Listen_Yes);
         SetListenOverride(otherClient, client, Listen_No);
      }
   }

   return Plugin_Continue;
}
