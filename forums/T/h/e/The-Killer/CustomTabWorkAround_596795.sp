//Created by The-Killer
//
//Changelog:
//0.1 - Initial Release
//0.2 - added heartbeat after list switch
//0.3 - Fix for crash on mapchange

#pragma semicolon 1

#include <sourcemod>

new Handle:sv_visiblemaxplayers;
new Handle:sv_tags;
new bool:set=false;
new bool:suspend=true;

public Plugin:myinfo = 
{
	name = "Custom Tab Work Around",
	author = "The-Killer",
	description = "Puts your server on the Internet list when > 24 slots, Custom Tab if not",
	version = "0.3",
	url = "http://www.righttorule.com/"
};

public OnPluginStart()
{
  CreateConVar("sm_CustWorkAround", "0.3", "Custom Tab Work Around Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  sv_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
  sv_tags = FindConVar("sv_tags");
}

public OnConfigsExecuted()
{
  slotcheck();
}

public OnClientPutInServer(client)
{
  slotcheck();
}
public OnClientDisconnect_Post(client)
{
	slotcheck();
}

public slotcheck()
{
  if(suspend==false)
  {
    if (GetClientCount(false)<23)
    {		
      set=false;
      SetConVarInt(sv_visiblemaxplayers, 24, false, false);
      SetConVarString(sv_tags, "", false, false);
      ServerCommand("heartbeat");
    }
    else
    {		
      if(set==false)
      {
        set=true;
        SetConVarInt(sv_visiblemaxplayers, -1, false, false);
        SetConVarString(sv_tags, "increased_maxplayers", false, false);
        ServerCommand("heartbeat");
      }
    }
  }
}

public Action:Resume(Handle:timer)
{
  suspend=false;
}

public OnMapStart()
{
  CreateTimer(30.0, Resume);
}

public OnMapEnd()
{
  suspend=true;
}