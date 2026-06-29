#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "Autojoin",
    author = "busted",
    description = "Bot join t, Player join ct",
    version = "1.0",
    url = "https://attawaybaby.com"
};

int Collision_Offsets;

public void OnPluginStart()
{
    Collision_Offsets = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
    HookEvent("player_spawn", PlayerSpawn);
}

public void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
  static bool ignoreSpawnHook;

  if (ignoreSpawnHook)
    return;

  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (!client)
    return;

  ignoreSpawnHook = true;

  if (IsFakeClient(client))
  {
    if (GetClientTeam(client) > CS_TEAM_SPECTATOR)
    {
      ChangeClientTeam(client, CS_TEAM_T);
      CS_RespawnPlayer(client);
      SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
    }
  }
  else if (GetClientTeam(client) == CS_TEAM_T)
  {
    ChangeClientTeam(client, CS_TEAM_CT);
    CS_RespawnPlayer(client);
    SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
  }

  ignoreSpawnHook = false;
}