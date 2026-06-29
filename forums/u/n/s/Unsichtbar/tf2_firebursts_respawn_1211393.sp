#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION  "1.1.0"

new Handle:ConMinPlayers = INVALID_HANDLE;
new Handle:RsTime = INVALID_HANDLE;

public Plugin:myinfo =
{
  name = "FB Respawner",
  author = "Unsichtbar",
  description = "Disable respawn times on TF2 servers",
  version = PLUGIN_VERSION,
  url = "http://www.fire-bursts.com"
};

public OnPluginStart()
{
  ConMinPlayers = CreateConVar("fb_respawner_minplayers", "12", "FB Respawner Min Players", FCVAR_PLUGIN|FCVAR_NOTIFY);
  CreateConVar("fb_respawner_version", PLUGIN_VERSION, "FB Respawner version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  HookConVarChange(ConMinPlayers, onChange);
  RsTime = FindConVar("mp_disable_respawn_times");
  SetConVarInt(FindConVar("mp_disable_respawn_times"), 1);
}

public OnClientConnected()
{
  doCheck();
}

public OnClientDisconnect()
{
  doCheck();
}

public onChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
  doCheck();
}

public doCheck()
{
  new RsTimes = GetConVarInt(RsTime);
  new MinPlayers = GetConVarInt(ConMinPlayers);
  new NumPlayers = 0;
  
  // COUNT PLAYERS
  for(new i = 1; i <= MaxClients; i++) 
  {
    if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
    {
      NumPlayers++;
    }
  }
  
  // DISABLE/ENABLE RESPAWN TIMES
  if(NumPlayers < MinPlayers)
  {
    if(RsTimes != 1)
    {
      // ServerCommand("mp_disable_respawn_times 1");
      SetConVarInt(FindConVar("mp_disable_respawn_times"), 1);
      PrintToChatAll("Disabling respawn times!");
    }
  }
  else
  {
    if(RsTimes != 0)
    {
      // ServerCommand("mp_disable_respawn_times 0");
      SetConVarInt(FindConVar("mp_disable_respawn_times"), 0);
      PrintToChatAll("Enabling respawn times!");
    }
  }
}