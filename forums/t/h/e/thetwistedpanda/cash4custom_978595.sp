#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
  name = "CS:S Cash 4 Custom",
  author = "Panda|USAF",
  description = "Quick and dirty script to give players with custom flags cash on round_start.",
  version = "PLUGIN_VERSION",
  url = "http://alliedmods.net"
};

new Handle:p_isEnabled = INVALID_HANDLE;
new Handle:p_Amount = INVALID_HANDLE;

public OnPluginStart()
{
  CreateConVar("sm_cash4custom_version", PLUGIN_VERSION, "Cah 4 Custom Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  p_isEnabled  = CreateConVar("sm_cash4custom_enabled", "1", "If enabled, players with the specified custom flags receive cash on round_start [0=Disabled, 1=Enabled]");
  p_Amount  = CreateConVar("sm_cash4custom_amount", "10000", "The amount of extra cash players will receive on round_start.");
  AutoExecConfig(true);

  HookEvent("round_start", OnRoundStart);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(GetConVarInt(p_isEnabled))
    for(new i = 1; i < MaxClients; i++)
      if(IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
        if(HasAccess(i))
          SetEntProp(i, Prop_Send, "m_iAccount", GetConVarInt(p_Amount));
}

public HasAccess(client)
{
  if(GetUserFlagBits(client) & (ADMFLAG_ROOT))
    return true;

  for(new i = 15; i <= 20; i++)
    if(GetUserFlagBits(client) & (1<<i) == (1<<i))
      return true;
      
  return false;
}