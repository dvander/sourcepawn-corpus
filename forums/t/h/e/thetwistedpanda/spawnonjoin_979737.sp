#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

new g_hasDied[MAXPLAYERS];
new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_StopRespawns = INVALID_HANDLE;

public Plugin:myinfo = 
{
  name = "Spawn on Join",
  author = "Panda|USAF",
  description = "Allow players to spawn regardless of when they join.",
  version = PLUGIN_VERSION,
  url = "http://heirsofmortality.com"
}

public OnPluginStart ()
{
  CreateConVar("sm_joinspawn_version", PLUGIN_VERSION, "Spawn on Join Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  p_Enabled  = CreateConVar("sm_joinspawn_enabled", "1", "Enables or disables the ability to spawn upon joining. [0=Disabled, 1=Enabled]");
  p_StopRespawns  = CreateConVar("sm_joinspawn_stop_respawn", "1", "If enabled, players who die are unable to respawn by joining teams. [0=Disabled, 1=Enabled]");
  AutoExecConfig(true);
  
  HookEvent("player_death", OnPlayerDeath);
  RegConsoleCmd("jointeam", Command_Join);
 }
 
public OnClientPostAdminCheck(client)
{
  if (GetConVarInt(p_Enabled) && GetConVarInt(p_StopRespawns))
    if (IsClientInGame(client))
      g_hasDied[client] = false;
}
 
 public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (GetConVarInt(p_Enabled) && GetConVarInt(p_StopRespawns))
  {
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    g_hasDied[client] = true;
  }
}

public Action:Command_Join(client, args)
{
  if (GetConVarInt(p_Enabled))
  {
    decl String:iHasAString[3];
    GetCmdArg(1, iHasAString, sizeof(iHasAString));
    new bool:isAuto = StrEqual(iHasAString, "0");
    
    StripQuotes(iHasAString);
    TrimString(iHasAString);
    if(strlen(iHasAString) == 0)
      return Plugin_Handled;

    new team = StringToInt(iHasAString);
    if(team != TERRORIST_TEAM && team != COUNTER_TERRORIST_TEAM || isAuto)
      return Plugin_Continue;
      
    if(GetConVarInt(p_StopRespawns))
      if(g_hasDied[client])
        return Plugin_Handled;
        
    if(IsValidEntity(client) && IsClientInGame(client) && IsClientObserver(client) && !IsPlayerAlive(client))
      CS_RespawnPlayer(client);
  }
  return Plugin_Continue;
}