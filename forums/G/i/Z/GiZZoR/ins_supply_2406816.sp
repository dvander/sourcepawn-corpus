/**
 * [INS] Supply Point Manager
 *
 * This plugin will set the supply points (tokens) for players on connect to server.
 * Will determine and give highest possible supply to player, based on settings completed.
 *
 * 0.3 = Fixed translations.
 * 0.2 = "ALPHA" Added Join and Rejoin cvars
 * 0.1 = Initial build. CVar and Token testing
*/

#include <sourcemod>

new ConVar:g_S_Enabled;
new ConVar:g_S_Base_Points;
new ConVar:g_S_Rejoin;
new ConVar:g_S_Join;
new Handle:g_S_KV_Players;

public Plugin myinfo =
{
  name = "[INS] Supply Point Manager",
  author = "GiZZoR",
  description = "Set player supply points",
  version = "0.3",
  url = "https://github.com/GiZZoR/ins-sm-plugins"
};

public void OnPluginStart()
{
  // Hook to start of round, for storing players Supply
  HookEvent("round_start", S_RoundStarted);

  // Hook (& Command) to explicitly set a player's supply points. Applies _before_ player spawns in world.
  HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
  RegAdminCmd("sm_supply", Command_Supply, ADMFLAG_BAN,"Sets the supply points of a target");

  // "Boolean": sm_supply_enabled; Enable/disable plugin. Default: 1 (Enabled)
  g_S_Enabled = CreateConVar("sm_supply_enabled" , "1", "Sets whether the plugin is enabled", FCVAR_NONE, true, 0.0, true, 1.0);

  // "Int": sm_supply_base; Number of supply points to give players. Default: 12
  g_S_Base_Points = CreateConVar("sm_supply_base" , "12", "Base / Starting supply points", FCVAR_NOTIFY);

  // "Boolean": sm_supply_restore; Enable/disable restoring player's gained supply points. Default: 1 (Enabled)
  g_S_Rejoin = CreateConVar("sm_supply_restore", "1", "Restore points gained by player on reconnect", FCVAR_NONE, true, 0.0, true, 1.0);

  // "Int": sm_supply_join; Enable/disable setting supply points for new players. Default: 0 (Disabled)
  // Options:
  // 0 - Disabled (Default)
  // 1 - Give new player base supply as set in sm_supply_base. Note: You may want to set this per game mode in server_<mode>.cfg
  // 2 - Give new player the same supply as lowest member in team (Useful for multiple rounds of coop play)
  // 3 - Give new player the team average of supply points (sum all players supply points divided by players)
  g_S_Join = CreateConVar("sm_supply_join", "0", "0 - Disabled; 1 - sm_supply_base; 2 - Team Lowest; 3 - Team Average", FCVAR_NONE, true, 0.0, true, 3.0);
  LoadTranslations("common.phrases");
}

// Reset stored supply values on map change
public void OnMapStart()
{
  char MapName[64];
  GetCurrentMap(MapName, sizeof(MapName));
  g_S_KV_Players = new KeyValues(MapName);
}

public Action:Command_Supply(client, args)
{
  // No arguments supplied to "sm_supply" command
  if (args < 1)
  {
    ReplyToCommand(client, "[SM] Usage: sm_supply <#userid|name>");
    return Plugin_Handled;
  }

  decl String:arg[65];
  GetCmdArg(1, arg, sizeof(arg));

  decl String:target_name[MAX_TARGET_LENGTH];
  decl target_list[MAXPLAYERS], bool:tn_is_ml;
  decl String:arg2[11];
  char Name[128];

  new target_count = ProcessTargetString(
    arg,
    client,
    target_list,
    MAXPLAYERS,
    COMMAND_FILTER_NO_MULTI,
    target_name,
    sizeof(target_name),
    tn_is_ml);

  if (target_count <= 0)
  {
    ReplyToTargetError(client, target_count);
    return Plugin_Handled;
  }

  if (args == 1)
  {
    for (new i = 0; i < target_count; i++)
    {
      new Tokens = GetEntProp(target_list[i], Prop_Send, "m_nRecievedTokens");
      GetClientName(target_list[i], Name, sizeof(Name));
      ReplyToCommand(client,"%s has %i supply points",Name, Tokens);
    }
    return Plugin_Handled;
  }

  GetCmdArg(2, arg2, sizeof(arg2));
  new supply = StringToInt(arg2);
  for (new i=0; i<target_count; ++i) {
    GetClientName(target_list[i], Name, sizeof(Name));
    SetEntProp(target_list[i], Prop_Send, "m_nRecievedTokens", supply)
    ReplyToCommand(client,"Setting supply for %s to %i",Name, supply);
  }
  return Plugin_Handled;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
  // If plugin is disabled, skip (sm_supply_enabled = 0)
  if(g_S_Enabled.IntValue == 0) return Plugin_Handled;

  // Get id for (re-)connecting player
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  // Get the supply points assigned by the server
  new currentTokens = GetEntProp(client, Prop_Send, "m_nRecievedTokens");
  int newTokens = 0;

  // Get player's SteamID
  char SteamID[64];
  GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

  // Don't process bots
  if (StrEqual(SteamID,"BOT",false) == true) return Plugin_Handled;

  // Get team player is joining
  new team = GetEventInt(event, "team");

  // Restore points on rejoin, Enabled?
  if(g_S_Rejoin.IntValue == 1)
  {
    // Is player "re-joining"?
    if(KvJumpToKey(g_S_KV_Players,SteamID,false) == true)
    {
      // Fetch player's previous supply count from KV
      newTokens = KvGetNum(g_S_KV_Players,"supply",10);
    }
  }

  // Set points for new players?
  if (g_S_Join.IntValue > 0)
  {
    if (g_S_Join.IntValue == 1) newTokens = g_S_Base_Points.IntValue;
    if (g_S_Join.IntValue == 2) newTokens = TeamLowestSupply(team,client);
    if (g_S_Join.IntValue == 3) newTokens = TeamAverageSupply(team,client);
  }
  if (newTokens > currentTokens)
  {
    SetEntProp(client, Prop_Send, "m_nRecievedTokens",newTokens);
  }
  return Plugin_Handled;
}

public Action:S_RoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
  // Loop through all players
  for (new S_Client_Loop = 1; S_Client_Loop <= MaxClients; S_Client_Loop++) {
    if (IsClientConnected(S_Client_Loop) && IsClientInGame(S_Client_Loop)) {
      // Get player's Steam ID
      decl String:S_Round_SteamID[64];
      GetClientAuthId(S_Client_Loop, AuthId_Steam2, S_Round_SteamID, sizeof(S_Round_SteamID));

      // Don't track supply points of bots.
      if (StrEqual(S_Round_SteamID,"BOT",false) == false)
      {
        // Get player's team
        new team = GetClientTeam(S_Client_Loop);
        // Get player's supply points
        new supply = GetEntProp(S_Client_Loop, Prop_Send, "m_nRecievedTokens");
        // Store values in Key Value pair
        if(KvJumpToKey(g_S_KV_Players,S_Round_SteamID,true) == true)
        {
          KvSetNum(g_S_KV_Players,"team",team);
          KvSetNum(g_S_KV_Players,"supply",supply);
        }
        KvRewind(g_S_KV_Players);
      }
    }
  }
}

int TeamAverageSupply(int team, int player)
{
  new Float:TeamSupplyTotal = 0.0;
  int PlayerSupply = GetEntProp(player, Prop_Send, "m_nRecievedTokens");
  int PlayerCount = 0;
  for (new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i)) {
      new S_Client_Loop_Team = GetClientTeam(i);
      if (S_Client_Loop_Team == team)
      {
        if(player != i)
        {
          int supply = GetEntProp(i, Prop_Send, "m_nRecievedTokens");
          TeamSupplyTotal = TeamSupplyTotal + float(supply);
          PlayerCount++;
        }
      }
    }
  }

  // If no players in team, return player's base supply. Avoid potential divide by 0.
  if (PlayerCount == 0) return PlayerSupply;

  new Float:TeamAverage = TeamSupplyTotal / PlayerCount;
  return RoundToFloor(TeamAverage);
}

int TeamLowestSupply(int team, int player)
{
  int TeamLowest = 0;
  for (new i = 1; i <= MaxClients; i++)
  {
    if(IsClientInGame(i)) {
      new loop_team = GetClientTeam(i);
      if (loop_team == team)
      {
        if(player != i)
        {
          int supply = GetEntProp(i, Prop_Send, "m_nRecievedTokens");
          if (TeamLowest == 0)
          {
            TeamLowest = supply;
          } else if (supply < TeamLowest) {
            TeamLowest = supply;
          }
        }
      }
    }
  }
  return TeamLowest;
}