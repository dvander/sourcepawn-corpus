#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// Used mainly in conjunction with WhiteWolf's Observe plugin but not needed
// http://forums.alliedmods.net/showthread.php?t=62324
public Plugin:myinfo = 
{
  name = "SB Status",
  author = "brizad",
  description = "Status Check for SourceBans and WhiteWolf's Observe",
  version = PLUGIN_VERSION,
  url = "http://www.doopalliance.com/"
};

public OnPluginStart()
{
  CreateConVar("sb_status_version", PLUGIN_VERSION, "SB Status Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  RegConsoleCmd("sb_status", commandStatus, "Get Status Information.");
}

public Action:commandStatus(p_iClient, p_iArgs)
{
  if (p_iClient > 0 && IsClientConnected(p_iClient) && !IsFakeClient(p_iClient) && CheckCommandAccess(p_iClient, "sm_users", ADMFLAG_GENERIC))
    ClientCommand(p_iClient, "sm_users");
  else
    if (p_iClient == 0)
      ServerCommand("status");
    else
      if (IsClientConnected(p_iClient) && !IsFakeClient(p_iClient))
        ClientCommand(p_iClient, "status");

  return Plugin_Handled;
}
