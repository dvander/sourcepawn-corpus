#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.11"
#define MAX_FILE_LEN 80

public Plugin:myinfo =
{
  name = "Halftime teamswitch",
  author = "[30+]Gemeni",
  description = "Moves all players to the opposite team at halftime",
  version = PLUGIN_VERSION,
  url = "http://30plus.ownit.se/"
};

// Global variables
new mapTime;
new g_maxrounds;
new g_winlimit;
new g_roundCount;
new bool:halftime;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new bool:g_soundEnabled;
new Handle:g_h_moneyReset = INVALID_HANDLE;
new Handle:g_h_mp_startmoney = INVALID_HANDLE;
new Handle:g_h_mp_maxrounds = INVALID_HANDLE;
new Handle:g_h_mp_winlimit = INVALID_HANDLE;
new g_mp_startmoney;
new bool:g_resetMoney;
new bool:g_halftime_do_resetMoney = false;
new Handle:g_CvarHalfTimeType = INVALID_HANDLE;
new String:g_HalfTimeType[MAX_FILE_LEN];
new String:g_soundName[MAX_FILE_LEN];
new g_CtScore, g_TScore;

/* forwards */
new Handle:g_f_on_ht = INVALID_HANDLE;

// Offsets
new g_iAccount = -1;


// Setting halftime to false
public OnMapStart(){
  //LogToGame(">>>>>Setting halftime to false, OnMapStart<<<<<");
  halftime = false;
  g_roundCount = 0;

  GetConVarString(g_CvarHalfTimeType, g_HalfTimeType, MAX_FILE_LEN);
  GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
  
  if (StrEqual(g_soundName, "")) {
    g_soundEnabled = false;
  }
  else {
    g_soundEnabled = true;
  }
  
  if (g_soundEnabled) {
    decl String:buffer[MAX_FILE_LEN];
    PrecacheSound(g_soundName, true);
    Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
    AddFileToDownloadsTable(buffer);
  }
  
  new tmp;
  tmp = GetConVarInt(g_h_moneyReset);
  if (tmp == 1) {
    g_resetMoney = true;
  }
  else {
    g_resetMoney = false;
  }

  g_mp_startmoney = GetConVarInt(g_h_mp_startmoney);
  g_maxrounds = GetConVarInt(g_h_mp_maxrounds);
  g_winlimit = GetConVarInt(g_h_mp_winlimit);


}

public OnConfigsExecuted(){
  //LogToGame(">>>>>Setting halftime to false, OnConfigsExecuted<<<<<");
  halftime = false;
}

// Hooking events at plugin start
public OnPluginStart(){
  CreateConVar("sm_halftime_teamswitch_version", PLUGIN_VERSION, "Halftime teamswitch version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  HookEvent("round_start", Event_RoundStart);
  HookEvent("round_end", Event_RoundEnd);

  g_CvarSoundName = CreateConVar("sm_halftime_sound", "gem_sounds/teamswitch.mp3", "The sound to play");
  g_h_moneyReset = CreateConVar("sm_halftime_money_reset", "1", "If weapons should be removed and money reset to mp_startmoney");
  g_h_mp_startmoney = FindConVar("mp_startmoney");
  g_h_mp_maxrounds = FindConVar("mp_maxrounds");
  g_h_mp_winlimit = FindConVar("mp_winlimit");
  
  g_CvarHalfTimeType = CreateConVar("sm_halftime_teamswitch_type", "timelimit", "timelimit|maxrounds|winlimit to determin what critera halftime should be based on");
  
  g_f_on_ht = CreateGlobalForward("gemHalftime", ET_Ignore);
  
  // Finding offset for CS cash
  g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
  if (g_iAccount == -1)
    SetFailState("m_iAccount offset not found");

}

// RoundStart gets the maptime
// Checks to see if halftime has passed, if not then make sure halftime is 0
// Setting halftime false here as well since in some occasions when extending map
// team switch can occur again.
public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
  new wepIdx;
  new playerTeam;

  g_roundCount++;
  //LogMessage(">>> Increasing roundCount %d<<<", g_roundCount);

  GetMapTimeLimit(mapTime);
  mapTime=mapTime*60;
  
  //  new mapTimeLeft;
  //  GetMapTimeLeft(mapTimeLeft);
  //  if(mapTimeLeft>mapTime/2) {
  //    halftime = false;
  //  LogToGame(">>>>>Setting halftime to false, RoundStart<<<<<");
  //  }
  
  if (g_resetMoney && g_halftime_do_resetMoney) {
      for (new client=1; client<=GetMaxClients(); client++)
      {
        if (IsClientInGame (client) && IsClientConnected(client) && !IsFakeClient(client)) {
          for (new w = 0; w < 6; w++)
          {
              if (w != 2 && w != 4 )  
                  while((wepIdx = GetPlayerWeaponSlot(client, w)) != -1)
                    RemovePlayerItem(client, wepIdx);        
          }          
          playerTeam = GetClientTeam(client);
          if (playerTeam == CS_TEAM_T) {
            GivePlayerItem(client, "weapon_glock");
          }
          else if (playerTeam == CS_TEAM_CT) {
            GivePlayerItem(client, "weapon_usp");
            if ((wepIdx = GetPlayerWeaponSlot(client, 6)) != -1)
              RemovePlayerItem(client, wepIdx);        
          }
          SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
          SetEntProp(client, Prop_Send, "m_bHasHelmet", 0, 1);

          SetEntData(client, g_iAccount, g_mp_startmoney, 4, true);
      }
    }
  }
  g_halftime_do_resetMoney = false;
}

// At Round end we check if time left of the map is passed halftime.
// If so and we have not already switched teams before, switch teams and then set halftime to 1
public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
  new mapTimeLeft;
  new bool:doSwap = false;
//  new CTScore, TScore;
  new reason = GetEventInt(event, "reason");
  new winner = GetEventInt(event, "winner");

  // Make sure that we have a normal round end
  // reason 16 is game commencing
  // other reasons are real round ends
  if(reason == 15) {
    g_CtScore = 0;
    g_TScore = 0;
    g_roundCount = 0;
    return;
  }
  
  //LogMessage(">>> winner %d CT:%d T:%d<<<",winner, CS_TEAM_CT, CS_TEAM_T);

  if (winner==CS_TEAM_T)
    g_TScore++;
  if (winner==CS_TEAM_CT)
    g_CtScore++;

  GetMapTimeLeft(mapTimeLeft);
  
  if ((mapTimeLeft<=mapTime/2) && StrEqual("timelimit", g_HalfTimeType)) {
    //LogMessage(">>> Halftime, Swap timelimit<<<");
    doSwap = true;
  }
  else if ((g_roundCount>=g_maxrounds/2) && StrEqual("maxrounds", g_HalfTimeType)) {
    //LogMessage(">>> Halftime, Swap maxrounds %d %d<<<", g_roundCount, g_maxrounds);
    doSwap = true;
  }
  else if ((g_roundCount>=g_winlimit/2) && StrEqual("winlimit", g_HalfTimeType)) {
    //LogMessage(">>> Halftime, Swap winlimit %d %d<<<", g_roundCount, g_maxrounds);
    doSwap = true;
  }
  else {
    //LogMessage(">>> Halftime, No swap <<<");
    doSwap = false;
  }
  
  if(doSwap && (halftime == false)) {
    new playerTeam;

    Call_StartForward(g_f_on_ht);
    Call_Finish();

    PrintToChatAll("Halftime!, switching players to oposite team");
    PrintToChatAll("Removing weapons and resetting money");

    //LogMessage(">>> Halftime, switching players to oposite team <<<");

    //LogToGame(">>>>>Setting halftime to true<<<<<");
    halftime = true;

    //Loop through all players and see if they are in game and that they are on a team
    //LogMessage("Players to switch: %d", GetMaxClients());
    for (new i=1; i<=GetMaxClients(); i++)
    {
      if (IsClientInGame (i) && IsClientConnected(i)) {
        
        if (IsClientInGame (i) && IsClientConnected(i) && IsFakeClient(i)) {
          ForcePlayerSuicide(i);
        }
        
        g_halftime_do_resetMoney = true;
        
        //LogMessage("Player %d is InGame", i);
        playerTeam = GetClientTeam(i);
        if (playerTeam == CS_TEAM_T) {
          //LogMessage("Before switch of %d to CT", i);
          CS_SwitchTeam(i, CS_TEAM_CT);
          if (g_soundEnabled) {
            EmitSoundToClient(i,g_soundName);
          }
          //LogMessage("After switch of %d to CT", i);
        }
        else if (playerTeam == CS_TEAM_CT) {
          //LogMessage("Before switch of %d to T", i);
          CS_SwitchTeam(i, CS_TEAM_T);
          if (g_soundEnabled) {
            EmitSoundToClient(i,g_soundName);
          }
          //LogMessage("After switch of %d to T", i);
        }
        else {
          //LogMessage("No switch, not CT not T");
        }
      }
      else {
        //LogMessage("Player %d is *NOT* InGame", i);
      }
    }
    //CTScore = GetTeamScore(CS_TEAM_CT);
    //TScore = GetTeamScore(CS_TEAM_T);
    //SetTeamScore(CS_TEAM_CT, TScore);
    //SetTeamScore(CS_TEAM_T, CTScore);
    new tmp;
    tmp = g_CtScore;
    g_CtScore = g_TScore;
    g_TScore = tmp;

    //LogMessage(">>>>>halftime switch completed<<<<<");
  }
  SetTeamScore(CS_TEAM_CT, g_CtScore);
  SetTeamScore(CS_TEAM_T, g_TScore);
}
