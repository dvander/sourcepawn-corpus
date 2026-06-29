#pragma semicolon 1
#include <sourcemod>
#include <builtinvotes>
//get here: https://forums.alliedmods.net/showthread.php?t=162164

#undef REQUIRE_PLUGIN
#include <confogl>
#define REQUIRE_PLUGIN
//get proper version here: https://bitbucket.org/vintik/confogl-old

#define L4D_TEAM_SPECTATE 1
#define MATCHMODES_PATH   "configs/matchmodes.txt"
#define ShouldAutoVote() (GetConVarBool(hAutoVote))

new Handle:g_hVote = INVALID_HANDLE;
new Handle:g_hModesKV = INVALID_HANDLE;
new Handle:g_hCvarPlayerLimit = INVALID_HANDLE;
new Handle:hAutoVote;
new String:g_sCfg[32];
new bool:g_bIsConfoglAvailable;
new bool:g_bIsFirstPlayer = true;
new Handle:g_hIsReadyUpEnabled;
new bool: g_bIsReadyUpEnabled;
new bool: g_bConVarsSetupSuccess;

public Plugin:myinfo =
{
  name = "Match Vote",
  author = "vintik, raecher",
  description = "!match !rmatch",
  version = "1.5f",
  url = "https://bitbucket.org/vintik/various-plugins"
}

public OnPluginStart()
{
  decl String:sBuffer[128];
  GetGameFolderName(sBuffer, sizeof(sBuffer));
  if (!StrEqual(sBuffer, "left4dead2", false))
  {
    SetFailState("Plugin supports Left 4 dead 2 only!");
  }
  g_hModesKV = CreateKeyValues("MatchModes");
  BuildPath(Path_SM, sBuffer, sizeof(sBuffer), MATCHMODES_PATH);
  if (!FileToKeyValues(g_hModesKV, sBuffer))
  {
    SetFailState("Couldn't load matchmodes.txt!");
  }

  RegConsoleCmd("sm_match", MatchRequest);
  RegConsoleCmd("sm_rmatch", MatchReset);
  hAutoVote = CreateConVar("sm_autovote", "1", "1=Autovote on 2=Autovote off", FCVAR_PLUGIN);

  g_hCvarPlayerLimit = CreateConVar("sm_match_player_limit", "2", "Minimum # of players in game to start the vote", FCVAR_PLUGIN);
  g_bIsConfoglAvailable = LibraryExists("confogl");
  g_bIsFirstPlayer = true;

  if(ShouldAutoVote())
  {
    CreateTimer(3.0, SetupConVars);
    HookEvent("player_disconnect", PlayerDisconnect_Event);
  }
}

public OnPluginEnd()
{
  g_bIsFirstPlayer = true;
}

public OnClientPostAdminCheck(client)
{
  if (!g_bIsFirstPlayer) return;
  g_bIsFirstPlayer = false;
  if (!g_bIsReadyUpEnabled) {CreateTimer(20.0, OnTeamChangeDelay);}
}

public Action:OnTeamChangeDelay(Handle:timer, any:client)
{
  for(new i = 1; i <= MaxClients; i++)
  {
    if(!IsValidClient(i)) continue;
    if(GetClientTeam(i) == 1) continue;

    MatchModeMenu(i);
  }
  return Plugin_Handled;
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (IsHumanOnServer()) return;
  g_bIsFirstPlayer = true;
}

public Action:SetupConVars(Handle:timer)
{
  g_hIsReadyUpEnabled = FindConVar("l4d_ready_enabled");
  if (g_hIsReadyUpEnabled != INVALID_HANDLE)  // Only proceed if the L4D2 Ready Up ConVars exist. Note that ConVars created by a plugin persist even if the plugin is unloaded.
  {
    g_bConVarsSetupSuccess = true;
  }
}

public OnConfigsExecuted()
{
  if (g_bConVarsSetupSuccess)
  {
    g_bIsReadyUpEnabled = GetConVarBool(g_hIsReadyUpEnabled);
  }
}

public OnLibraryRemoved(const String:name[])
{
  if (StrEqual(name, "confogl")) g_bIsConfoglAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
  if (StrEqual(name, "confogl")) g_bIsConfoglAvailable = true;
}

public Action:MatchRequest(client, args)
{
  if ((!client) || (!g_bIsConfoglAvailable)) return Plugin_Handled;
  if (args > 0)
  {
    //config specified
    decl String:sCfg[64], String:sName[64], String:sCfgPath[256];
    GetCmdArg(1, sCfg, sizeof(sCfg));
    BuildPath(Path_SM, sCfgPath, sizeof(sCfgPath), "../../cfg/confogl/%s", sCfg);
    if (DirExists(sCfgPath))
    {
      if (!FindConfigName(sCfg, sName, sizeof(sName)))
        strcopy(sName, sizeof(sName), sCfg);
      if (StartMatchVote(client, sName))
      {
        strcopy(g_sCfg, sizeof(g_sCfg), sCfg);
        //caller is voting for
        FakeClientCommand(client, "Vote Yes");
      }
      return Plugin_Handled;
    }
  }
  //show main menu
  MatchModeMenu(client);
  return Plugin_Handled;
}

bool:FindConfigName(const String:cfg[], String:name[], maxlength)
{
  KvRewind(g_hModesKV);
  if (KvGotoFirstSubKey(g_hModesKV))
  {
    do
    {
      if (KvJumpToKey(g_hModesKV, cfg))
      {
        KvGetString(g_hModesKV, "name", name, maxlength);
        return true;
      }
    } while (KvGotoNextKey(g_hModesKV, false));
  }
  return false;
}

MatchModeMenu(client)
{
  new Handle:hMenu = CreateMenu(MatchModeMenuHandler);
  SetMenuTitle(hMenu, "Welcome to L4D2");
  new String:sBuffer[64];
  KvRewind(g_hModesKV);
  if (KvGotoFirstSubKey(g_hModesKV))
  {
    do
    {
      KvGetSectionName(g_hModesKV, sBuffer, sizeof(sBuffer));
      AddMenuItem(hMenu, sBuffer, sBuffer);
    } while (KvGotoNextKey(g_hModesKV, false));
  }
  DisplayMenu(hMenu, client, 30);
}

public MatchModeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
  {
    new String:sInfo[64], String:sBuffer[64];
    GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
    KvRewind(g_hModesKV);
    if (KvJumpToKey(g_hModesKV, sInfo) && KvGotoFirstSubKey(g_hModesKV))
    {
      new Handle:hMenu = CreateMenu(ConfigsMenuHandler);
      Format(sBuffer, sizeof(sBuffer), "Select %s config:", sInfo);
      SetMenuTitle(hMenu, sBuffer);
      do
      {
        KvGetSectionName(g_hModesKV, sInfo, sizeof(sInfo));
        KvGetString(g_hModesKV, "name", sBuffer, sizeof(sBuffer));
        AddMenuItem(hMenu, sInfo, sBuffer);
      } while (KvGotoNextKey(g_hModesKV));
      DisplayMenu(hMenu, param1, 30);
    }
    else
    {
      PrintToChat(param1, "No configs for such mode were found.");
      MatchModeMenu(param1);
    }
  }
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
}

public ConfigsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
  {
    new String:sInfo[64], String:sBuffer[64];
    GetMenuItem(menu, param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
    if (StartMatchVote(param1, sBuffer))
    {
      strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
      //caller is voting for
      FakeClientCommand(param1, "Vote Yes");
    }
    else
    {
      MatchModeMenu(param1);
    }
  }
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  if (action == MenuAction_Cancel)
  {
    MatchModeMenu(param1);
  }
}

bool:StartMatchVote(client, const String:cfgname[])
{
  if (GetClientTeam(client) == L4D_TEAM_SPECTATE)
  {
    PrintToChat(client, "Match voting isn't allowed for spectators.");
    return false;
  }
  if (LGO_IsMatchModeLoaded())
  {
    PrintToChat(client, "Match vote cannot be started. Match is already running.");
    return false;
  }
  if (IsNewBuiltinVoteAllowed())
  {
    new iNumPlayers;
    decl iPlayers[MaxClients];
    //list of non-spectators players
    for (new i=1; i<=MaxClients; i++)
    {
      if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
      {
        continue;
      }
      iPlayers[iNumPlayers++] = i;
    }
    if (iNumPlayers < GetConVarInt(g_hCvarPlayerLimit))
    {
      PrintToChat(client, "Match vote cannot be started. Not enough players.");
      return false;
    }
    new String:sBuffer[64];
    g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
    Format(sBuffer, sizeof(sBuffer), "Load confogl '%s' config?", cfgname);
    SetBuiltinVoteArgument(g_hVote, sBuffer);
    SetBuiltinVoteInitiator(g_hVote, client);
    SetBuiltinVoteResultCallback(g_hVote, MatchVoteResultHandler);
    DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
    return true;
  }
  PrintToChat(client, "Match vote cannot be started now.");
  return false;
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
  switch (action)
  {
    case BuiltinVoteAction_End:
    {
      g_hVote = INVALID_HANDLE;
      CloseHandle(vote);
    }
    case BuiltinVoteAction_Cancel:
    {
      DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
    }
  }
}

public MatchVoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
  for (new i=0; i<num_items; i++)
  {
    if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
    {
      if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
      {
        DisplayBuiltinVotePass(vote, "Confogl is loading...");
        ServerCommand("sm_forcematch %s", g_sCfg);
        return;
      }
    }
  }
  DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public Action:MatchReset(client, args)
{
  if ((!client) || (!g_bIsConfoglAvailable)) return Plugin_Handled;
  //voting for resetmatch
  StartResetMatchVote(client);
  return Plugin_Handled;
}

StartResetMatchVote(client)
{
  if (GetClientTeam(client) == L4D_TEAM_SPECTATE)
  {
    PrintToChat(client, "Resetmatch voting isn't allowed for spectators.");
    return;
  }
  if (!LGO_IsMatchModeLoaded())
  {
    PrintToChat(client, "Resetmatch vote cannot be started. No match is running.");
    return;
  }
  if (IsNewBuiltinVoteAllowed())
  {
    new iNumPlayers;
    decl iPlayers[MaxClients];
    for (new i=1; i<=MaxClients; i++)
    {
      if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
      {
        continue;
      }
      iPlayers[iNumPlayers++] = i;
    }
    if (iNumPlayers < GetConVarInt(g_hCvarPlayerLimit))
    {
      PrintToChat(client, "Resetmatch vote cannot be started. Not enough players.");
      return;
    }
    g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
    SetBuiltinVoteArgument(g_hVote, "Turn off confogl?");
    SetBuiltinVoteInitiator(g_hVote, client);
    SetBuiltinVoteResultCallback(g_hVote, ResetMatchVoteResultHandler);
    DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
    FakeClientCommand(client, "Vote Yes");
    return;
  }
  PrintToChat(client, "Resetmatch vote cannot be started now.");
}

public ResetMatchVoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
  for (new i=0; i<num_items; i++)
  {
    if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
    {
      if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
      {
        DisplayBuiltinVotePass(vote, "Confogl is unloading...");
        ServerCommand("sm_resetmatch");
        return;
      }
    }
  }
  DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}
/*
bool:IsVersus()
{
  decl String:GameMode[32];
  GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
  if(StrContains(GameMode, "versus", false) != -1)
  {
    return true;
  }
  return false;
}

bool:IsScavenge()
{
  decl String:GameMode[32];
  GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
  if(StrContains(GameMode, "scavenge", false) != -1)
  {
    return true;
  }
  return false;
}
*/
bool:IsHumanOnServer()
{
  for(new i=1;i<=MaxClients;i++)
  {
    if(IsClientConnected(i) && !IsFakeClient(i))
    {
      return true;
    }
  }
  return false;
}

bool:IsValidClient(client)
{
  if (client <= 0 || client > MaxClients) return false;
  if (!IsClientInGame(client)) return false;
  if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
  return true;
}