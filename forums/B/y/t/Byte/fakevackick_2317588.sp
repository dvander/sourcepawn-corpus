#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

new bool:isBeingKicked;

public Plugin:myinfo =
{
  name = "Fake VAC kick",
  author = "Invex | Byte",
  description = "Kick a player from server with fake VAC notice",
  version = "1.01",
  url = "https://www.invexgaming.com.au"
};

public OnPluginStart()
{
  RegAdminCmd("sm_fakevackick", Command_FakeVACKick, ADMFLAG_KICK, "sm_fakevackick <#userid|name>");
  HookEvent( "player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre );
  
  isBeingKicked = false;
}

public Action:Command_FakeVACKick(client, args)
{
  if (args < 1)
  {
    ReplyToCommand(client, "[SM] Usage: sm_fakevackick <#userid|name>");
    return Plugin_Handled;
  }

  decl String:Arguments[256];
  GetCmdArgString(Arguments, sizeof(Arguments));

  decl String:arg[65];
  new len = BreakString(Arguments, arg, sizeof(arg));
  
  if (len == -1)
  {
    /* Safely null terminate */
    len = 0;
    Arguments[0] = '\0';
  }

  decl String:target_name[MAX_TARGET_LENGTH];
  decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
  
  if ((target_count = ProcessTargetString(
      arg,
      client, 
      target_list, 
      MAXPLAYERS, 
      COMMAND_FILTER_CONNECTED,
      target_name,
      sizeof(target_name),
      tn_is_ml)) > 0)
  {
    //Set bool
    isBeingKicked = true;
    
    decl String:reason[64];
    Format(reason, sizeof(reason), Arguments[len]);

    PrintToChatAll(" \x02Player %s left the game (VAC banned from secure server)", target_name);
    
    new kick_self = 0;
    
    for (new i = 0; i < target_count; i++)
    {
      /* Kick everyone else first */
      if (target_list[i] == client)
      {
        kick_self = client;
      }
      else
      {
        PerformKick(target_list[i]);
      }
    }
    
    if (kick_self)
    {
      PerformKick(client);
    }
  }
  else
  {
    ReplyToTargetError(client, target_count);
  }

  return Plugin_Handled;
}

//Kick client showing VAC ban message
PerformKick(target)
{
  KickClient(target, "%s", "You have been VAC banned");
}

//Block the regular player has left message
public Action:PlayerDisconnect_Event( Handle:event, const String:name[], bool:dontBroadcast )
{
  if (isBeingKicked) {
    // Overwrite Disconnection Message
    SetEventString( event, "reason", "" );
    isBeingKicked = false;
  }
  
  return Plugin_Continue;
}