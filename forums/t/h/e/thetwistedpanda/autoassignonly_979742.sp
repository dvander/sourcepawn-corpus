#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

new Handle:p_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
  name = "Auto Assign Only",
  author = "Panda|USAF",
  description = "Allow players to spawn regardless of when they join.",
  version = PLUGIN_VERSION,
  url = "http://heirsofmortality.com"
}

public OnPluginStart ()
{
  CreateConVar("sm_autoonly_version", PLUGIN_VERSION, "Auto Assign Only Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  p_Enabled  = CreateConVar("sm_autoonly_enabled", "1", "Enables or disables the the ability to only select auto assign. [0=Disabled, 1=Enabled]");
  AutoExecConfig(true);

  RegConsoleCmd("jointeam", Command_Join);
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
      
    if(!isAuto)
    {
      PrintToChat(client, "\x04You can only spawn by selecting \"\x01Auto Assign\x04\"!");
      return Plugin_Handled;
    }
    else
      return Plugin_Continue;
  }
  return Plugin_Continue;
}