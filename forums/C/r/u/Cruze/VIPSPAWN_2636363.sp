#include <sourcemod>
#include <multicolors>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "VipSpawn"
#define PLUGIN_AUTHOR "Kewaii"
#define PLUGIN_DESCRIPTION "Advanced Respawn for Vip players"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_TAG "{pink}[VipSpawn by Kewaii]{green}"

bool g_bRevived[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = "http://kewaiigamer.info"
};

public void OnPluginStart()
{
  LoadTranslations("kewaii_vipspawn.phrases");
  RegConsoleCmd("sm_vipspawn", Command_VipSpawn);
  HookEvent("round_start", OnRoundStart);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
  for (int i = 1; i <= MaxClients; i++)
  {
    g_bRevived[i] = false;
  }
}
stock bool IsClientVIP(int client)
{
  if(CheckCommandAccess(client, "", ADMFLAG_RESERVATION, true))
  {
    return true;
  }
  return false;
}
public Action Command_VipSpawn(int client, int args)
{
  if(IsClientInGame(client))
  {
    if(IsClientVIP(client))
    {
      if(IsPlayerAlive(client))
      {
        CPrintToChat(client, "%s %t", PLUGIN_TAG, "DeadPlayer");
      }
      else
      {
        if(g_bRevived[client])
        {
          CPrintToChat(client, "%s %t", PLUGIN_TAG, "PlayerAlreadyUsedVipspawn");
        }
        else
        {
          CS_RespawnPlayer(client);
          char clientName[MAX_NAME_LENGTH];
          GetClientName(client, clientName, sizeof(clientName));
          CPrintToChatAll("%s %t", PLUGIN_TAG, "PlayerUsedVipspawn", clientName);
          g_bRevived[client] = true;
        }
      }
    }
    else
    {
      CPrintToChat(client, "%s %t", PLUGIN_TAG, "PlayerNotVip");
    }
  }
  else
  {
    PrintToServer("%t","Command is in-game only");
  }
  return Plugin_Handled;
}