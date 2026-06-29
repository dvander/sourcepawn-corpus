#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#define MAX_PLAYERS 256

new ClientSuicides[MAX_PLAYERS + 1];

public Plugin:myinfo =
{
    name = "kicks players who suicide 10 or more times",
    author = "starsfan",
    description = "kicks players who suicide 10 or more times",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
  HookEvent("player_death", CheckForSuicide);
}

public void OnClientPutInServer(int client)
{
  ClientSuicides[client] = 0;
}



public CheckForSuicide(Handle:event, const String:name[], bool:dontBroadcast)
{

  new userid = GetEventInt(event, "userid");
  new attacker = GetEventInt(event, "attacker");


  if (userid == attacker)
  {
    ClientSuicides[userid]++;
  }


  if (ClientSuicides[userid] >= 10) 
    ServerCommand("sm_kick #%d Suicide spamming", userid);


}