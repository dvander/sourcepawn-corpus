#pragma semicolon 1

/*--------------------------------------------------------------------------------
/ Includes
/-------------------------------------------------------------------------------*/

#include <sourcemod>
#include <sdktools>

/*--------------------------------------------------------------------------------
/ Globals
/-------------------------------------------------------------------------------*/

#define PLUGIN_NAME "[TF2] Duel Info"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_AUTHOR "AW 'Swixel' Stanley"
#define PLUGIN_URL "https://forums.alliedmods.net"
#define PLUGIN_DESCRIPTION "Simple plugin to check duel information."

/*--------------------------------------------------------------------------------
/ Handles (they can handle it)
/-------------------------------------------------------------------------------*/

new Handle:hGameConf;
new Handle:hIsInDuel;

/*--------------------------------------------------------------------------------
/ Plugin
/-------------------------------------------------------------------------------*/

public Plugin:myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL,
};

public OnPluginStart ()
{
  /* With intent to extend, have a cvar! */
  CreateConVar("sm_tf_duelinfo", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

  /* Prep the SDK Call for checking the duel status */
  hGameConf = LoadGameConfigFile("duel.tf2");
  StartPrepSDKCall(SDKCall_Static);
  PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IsInDuel");
  PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
  PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
  hIsInDuel = EndPrepSDKCall();

  /* Register commands for the admin */
  RegAdminCmd("sm_checkduel", Command_CheckDuelStatus, ADMFLAG_BAN, "Checks Duel Status\n   Format: sm_checkduel <target>"); 
}

/*--------------------------------------------------------------------------------
/ Functions (heavy lifting)
/-------------------------------------------------------------------------------*/

/* Function form for later ab/use */
bool:IsInDuel(target)
{
  return SDKCall(hIsInDuel, target);
}


/*--------------------------------------------------------------------------------
/ Commands (P.R. Department)
/-------------------------------------------------------------------------------*/

/* Prints duel status of player to chat */
public Action:Command_CheckDuelStatus(client, args)
{
  if(GetCmdArgs() != 1)
  {
    ReplyToCommand(client, "Format: sm_checkduel <target>");
  }
  else
  {
    /* Get query string ... */
    new String:arg[32];
    GetCmdArg(1, arg, sizeof(arg));

    /* We might want a name, and a return string */
    new String:name[MAX_TARGET_LENGTH];
    new String:rtn[128]; /* Huge return string */

    /* Find players ... */
    new String:target_name[MAX_TARGET_LENGTH];
    new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
    if ((target_count = ProcessTargetString(arg,client,target_list,MAXPLAYERS,0,target_name,sizeof(target_name),tn_is_ml)) <= 0)
    {
      if (IsClientInGame(client)) ReplyToTargetError(client, target_count);
      return Plugin_Handled;
    }

    for (new i = 0; i < target_count; i++)
    {
      new target = target_list[i];

      /* Who is this person? */
      GetClientName(target, name, sizeof(name));

      if(IsInDuel(target))
      {
        Format(rtn, sizeof(rtn), "[SM] %s is engaged in a duel.",name);
      }
      else
      {
        Format(rtn, sizeof(rtn), "[SM] %s is NOT engaged in a duel.",name);
      }

      ReplyToCommand(client, rtn);
    }
  }

  return Plugin_Handled;
}
