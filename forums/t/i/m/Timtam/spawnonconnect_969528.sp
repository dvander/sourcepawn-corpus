#include <sourcemod>
#include <cstrike>
#define PLUGIN_VERSION "1.1.0"

new Handle:Cvar_SOC_ENABLED

public Plugin:myinfo = 
{
  name = "Respawn on Join",
  author = "Alexander",
  description = "Allows players to respawn when they fist join the server.",
  version = PLUGIN_VERSION,
  url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
  CreateConVar("sm_soc_version", PLUGIN_VERSION, "Current plugin version", 
  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
  Cvar_SOC_ENABLED = CreateConVar("sm_soc_enabled", "1", "Enable/disable plugin 0/1", FCVAR_PLUGIN)
}
public OnMapStart()
{
  if (GetConVarBool(Cvar_SOC_ENABLED)==false) return;
}

public EventJoinTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (client == 0)
  {
    return;
  }
  CreateTimer(1.0, SpawnThePlayer, client);
}

public Action:SpawnThePlayer(Handle:timer, any:client)
{
  new team = GetClientTeam(client);
  if (!IsPlayerAlive(client) && (team == 2 || team == 3))
  {
    CS_RespawnPlayer(client);
  }
  return Plugin_Continue;
}