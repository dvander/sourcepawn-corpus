#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.8"

new Handle:g_hVoteMenu;
new Handle:g_hCVarUnsForAll;
new Handle:g_hCVarPlugin;
new bool:g_bUnscopeOn;
new bool:g_bVoteOn;
new fov_offset;
new zoom_offset;
new g_iListClients[2];

public Plugin:myinfo = 
{
  name = "AWP Unscope",
  author = "Raijojp",
  description = "Unscope vote when its 1 vs 1",
  version = PLUGIN_VERSION,
  url = "http://forum.supreme-elite.fr"
};

public OnPluginStart()
{
  CreateConVar("sm_awp_unscope", PLUGIN_VERSION, "AWP Unscope Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  g_hCVarPlugin = CreateConVar("unscope_vote", "1", "Enable (1)/Disable (0) the unscope vote when its 1 vs 1");
  g_hCVarUnsForAll = CreateConVar("unscope_all", "0", "Enable (1)/Disable (0) the unscope for everyone");
  
  AutoExecConfig(true, "scopevote");

  HookEvent("round_start",	Event_RoundStart);
  HookEvent("player_spawn",	Event_PlayerSpawn);
  HookEvent("player_death",	Event_PlayerDeath);
  HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
  
  fov_offset = FindSendPropOffs("CBasePlayer", "m_iFOV");
  zoom_offset = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (GetConVarInt(g_hCVarUnsForAll)) g_bUnscopeOn = true;
  else g_bUnscopeOn = false;
  g_bVoteOn = false;
  g_iListClients[0] = 0;
  g_iListClients[1] = 0;
}

public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  GivePlayerItem(client, "weapon_awp");
}

public Event_PlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
  new iNbTAlive = 0;
  new iNbCTAlive = 0;
  new iMaxClients = GetMaxClients();

  for (new i = 1; i <= iMaxClients; i ++)
  {
    if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if (GetClientTeam(i) == 2) iNbTAlive ++;
      else iNbCTAlive ++;
    }
  }

  if (!GetConVarInt(g_hCVarUnsForAll))
  {
    if (iNbTAlive == 1 && iNbCTAlive == 1 && GetConVarInt(g_hCVarPlugin)) VoteUnscope();
    if ((iNbTAlive == 0 || iNbCTAlive == 0) && g_bVoteOn) CloseHandle(g_hVoteMenu);
  }
}

public Event_PlayerDisconnect(Handle:event,const String:name[],bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (g_bVoteOn && (g_iListClients[0] = client || g_iListClients[1] == client)) CloseHandle(g_hVoteMenu);
}

VoteUnscope ()
{
  if (g_bVoteOn) return;
  
  g_hVoteMenu = CreateMenu(Handle_VoteMenu);
  SetMenuTitle(g_hVoteMenu, "Do you want a unscope battle ?");
  SetVoteResultCallback(g_hVoteMenu, Handle_VoteResults);
  AddMenuItem(g_hVoteMenu, "Yes", "Yes");
  AddMenuItem(g_hVoteMenu, "No", "No");
  SetMenuExitButton(g_hVoteMenu, false);

  new iMaxClients = GetMaxClients();
  new iNb = 0;
  for (new i = 1; i <= iMaxClients; i ++)
  {
    if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      g_iListClients[iNb] = i;
      iNb ++;
    }
  }
  
  VoteMenu(g_hVoteMenu, g_iListClients, 2, 20);

  g_bVoteOn = true;
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
  {
    CloseHandle(menu);
    g_bVoteOn = false;    
  }
}

public Handle_VoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
  if (item_info[0][VOTEINFO_ITEM_VOTES] == 2)
  {
    g_bUnscopeOn = true;
    RemoveWeapons();
    PrintToChatAll("\x03Unscope enable");
  }
  else
  {
    PrintToChatAll("\x03Unscope disabled");
    g_bUnscopeOn = false;
  }
  g_bVoteOn = false;
}

RemoveWeapons()
{
  new iMaxClients = GetMaxClients();
  for (new i = 1; i <= iMaxClients; i ++)
  {
    if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
    {
      if (IsValidEntity(GetPlayerWeaponSlot(i, 1))) RemovePlayerItem(i, GetPlayerWeaponSlot(i, 1));
    
      SetEntData(i, fov_offset, 90, 4, true);
      SetEntData(i, zoom_offset, 90, 4, true);
    }
  }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
  if (IsClientInGame(client) && IsPlayerAlive(client) && g_bUnscopeOn)
  {
    if (buttons & IN_ATTACK2) 
    {
      SetEntData(client, fov_offset, 90, 4, true);
      SetEntData(client, zoom_offset, 90, 4, true);
      return Plugin_Changed;
    }
  }
  return Plugin_Continue;
}