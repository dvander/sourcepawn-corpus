#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "0.2.0"
#define SPEC_TEAM 1
#define RED_TEAM 2
#define BLUE_TEAM 3
#define LIFE_ALIVE    0

new scouts[32];
new soldiers[32];
new pyros[32];
new demomans[32];
new heavys[32];
new engineers[32];
new medics[32];
new snipers[32];
new spys[32];
new team_blue = 0;
new team_red = 0;
new b_scout = 0;
new b_soldier = 0;
new b_pyro = 0;
new b_demoman = 0;
new b_heavy = 0;
new b_engineer = 0;
new b_medic = 0;
new b_sniper = 0;
new b_spy = 0;
new r_scout = 0;
new r_soldier = 0;
new r_pyro = 0;
new r_demoman = 0;
new r_heavy = 0;
new r_engineer = 0;
new r_medic = 0;
new r_sniper = 0;
new r_spy = 0;
new bi_scout = 0;
new bi_soldier = 0;
new bi_pyro = 0;
new bi_demoman = 0;
new bi_heavy = 0;
new bi_engineer = 0;
new bi_medic = 0;
new bi_sniper = 0;
new bi_spy = 0;
new ri_scout = 0;
new ri_soldier = 0;
new ri_pyro = 0;
new ri_demoman = 0;
new ri_heavy = 0;
new ri_engineer = 0;
new ri_medic = 0;
new ri_sniper = 0;
new ri_spy = 0;
new Handle:g_hHighlander;
new Handle:g_hEnabled;
new Handle:g_hLives;
new Handle:g_hTeamScramble;



public Plugin:myinfo = {
	name        = "TF2 Competitive Mod",
	author      = "Shift`",
	description = "A competive style mod with class queues.",
	version     = PL_VERSION,
	url         = "http://www.combatcorps.com"
}


public OnPluginStart() {
        g_hHighlander = FindConVar("mp_highlander");
        SetConVarInt(g_hHighlander, 1);
        g_hTeamScramble = FindConVar("mp_scrambleteams_auto");
        SetConVarInt(g_hTeamScramble, 0);
       	CreateConVar("sm_comp_version", PL_VERSION, "Competitive Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled      = CreateConVar("sm_comp_enabled",  "0", "Enable/disable TF2 Competivie Mode. Default: 0 (off)");
	g_hLives        = CreateConVar("sm_comp_lives",    "5", "Default amount of lives each player has.");

	HookEvent("player_death",    Event_PlayerDeath);
	HookEvent("player_spawn",    Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);

	RegConsoleCmd("say",      Command_Say,      "Hook say triggers for TF2 Comp Mod.");
}


public OnMapStart() {

}


public OnClientDisconnectPost(client) {
  if(!GetConVarInt(g_hEnabled))
  {
   return Plugin_Continue;
  }
  RemoveId(client);
  ClassId(client, "all");
  return Plugin_Continue;
}


public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(!GetConVarInt(g_hEnabled))
  {
   return Plugin_Continue;
  }
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  ForcePlayerSuicide(client);
  return Plugin_Continue;
}


public OnClientPutInServer(client)
{
  if(!GetConVarInt(g_hEnabled))
  {
    return Plugin_Continue;
  }
  ChangeClientTeam (client, SPEC_TEAM);
  return true;
}



public Action:Command_Say(client, args) {
 if(!GetConVarInt(g_hEnabled))
 {
  return Plugin_Continue;
 }
  new String:arg1[192];
  new String:arg2[192];
  GetCmdArgString(arg1, sizeof(arg1));
  GetCmdArgString(arg2, sizeof(arg2));
  new startidx = 0;
  if (arg1[0] == '"')
  {
   startidx = 1;
   /* Strip the ending quote, if there is one */
   new len = strlen(arg1);
   if (arg1[len-1] == '"')
   {
    arg1[len-1] = '\0';
   }
  }
  new hid = GetClientUserId(client);
  if(StrEqual(arg1[startidx], "!remove"))
  {
    RemoveId(client);
  }
  new String:buffer[32];
  if(StrEqual(arg1[startidx], "!line_scout"))
  {
     new n_id = scouts[0];
     new n_client = GetClientOfUserId(n_id);
       if(n_id != 0)
       {
        GetClientName(n_client, buffer, sizeof(buffer));
        PrintToChat(client, "[TFC]The next scout in line is: %s", buffer);
       }
       else
       {
         PrintToChat(client, "[TFC]There is no one in line!");
       }
  }
  if(StrEqual(arg1[startidx], "!line_soldier"))
  {
   new n_id = soldiers[0];
   new n_client = GetClientOfUserId(n_id);
     if(n_id != 0)
     {
       GetClientName(n_client, buffer, sizeof(buffer));
       PrintToChat(client, "[TFC]The next soldier in line is: %s", buffer);
     }
     else
     {
      PrintToChat(client, "[TFC]There is no one in line!");
     }
  }
  if(StrEqual(arg1[startidx], "!line_pyro"))
  {
    new n_id = pyros[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next pyro in line is: %s", buffer);
    }
    else
    {
      PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_demoman"))
  {
    new n_id = demomans[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next demoman in line is: %s", buffer);
    }
    else
    {
      PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_heavy"))
  {
    new n_id = heavys[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next heavy in line is: %s", buffer);
    }
    else
    {
      PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_engi"))
  {
    new n_id = engineers[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));     
     PrintToChat(client, "[TFC]The next engi in line is: %s", buffer);
    }
    else
    {
     PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_medic"))
  {
    new n_id = medics[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next medic in line is: %s", buffer);
    }
    else
    {
     PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_sniper"))
  {
    new n_id = snipers[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next sniper in line is: %s", buffer);
    }
    else
    {
     PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
  if(StrEqual(arg1[startidx], "!line_spy"))
  {
    new n_id = spys[0];
    new n_client = GetClientOfUserId(n_id);
    if(n_id != 0)
    {
     GetClientName(n_client, buffer, sizeof(buffer));
     PrintToChat(client, "[TFC]The next spy in line is: %s", buffer);
    }
    else
    {
     PrintToChat(client, "[TFC]There is no one in line!");
    }
  }
//=======
//Classes
//=======
  if(StrEqual(arg1[startidx], "!scout"))
  {
   if(CheckLists(client, hid) == false)
   {
    for(new i = 0; i < 9; i++)
    {
     if(scouts[i] == 0)
     {
      scouts[i] = hid;
      PrintToChat(client, "[TFC]You are currently in line for Scout at number: %d", i);
      RefreshLists();
      return Plugin_Continue;
     }
    }
   }
  }
  if(StrEqual(arg1[startidx], "!soldier"))
  {
   if(CheckLists(client, hid) == false)
   {
    for(new i = 0; i < 9; i++)
    {
     if(soldiers[i] == 0)
     {
      soldiers[i] = hid;
      PrintToChat(client, "[TFC]You are currently in line for Soldier at number: %d", i);
      RefreshLists();
      return Plugin_Continue;
     }
    }
   }
  }
  if(StrEqual(arg1[startidx], "!pyro"))
  {
   if(CheckLists(client, hid) == false)
   {
    for(new i = 0; i < 9; i++)
    {
     if(pyros[i] == 0)
     {
      pyros[i] = hid;
      PrintToChat(client, "[TFC]You are currently in line for Pyro at number: %d", i);
      RefreshLists();
      return Plugin_Continue;
     }
    }
   }
  }
  if(StrEqual(arg1[startidx], "!demoman"))
  {
   if(CheckLists(client, hid) == false)
   {
    for(new i = 0; i < 9; i++)
    {
     if(demomans[i] == 0)
     {
      demomans[i] = hid;
      PrintToChat(client, "[TFC]You are currently in line for Demoman at number: %d", i);
      RefreshLists();
      return Plugin_Continue;
     }
    }
   }
  }
  if(StrEqual(arg1[startidx], "!heavy"))
  {
   if(CheckLists(client, hid) == false)
   {
    for(new i = 0; i < 9; i++)
    {
     if(heavys[i] == 0)
     {
      heavys[i] = hid;
      PrintToChat(client, "[TFC]You are currently in line for Heavy at number: %d", i);
      RefreshLists();
      return Plugin_Continue;
      }
     }
    }
   }
   if(StrEqual(arg1[startidx], "!engi"))
   {
    if(CheckLists(client, hid) == false)
    {
     for(new i = 0; i < 9; i++)
     {
      if(engineers[i] == 0)
      {
       engineers[i] = hid;
       PrintToChat(client, "[TFC]You are currently in line for Engineer at number: %d", i);
       RefreshLists();
       return Plugin_Continue;
      }
     }
    }
   }
   if(StrEqual(arg1[startidx], "!medic"))
   {
    if(CheckLists(client, hid) == false)
    {
     for(new i = 0; i < 9; i++)
     {
      if(medics[i] == 0)
      {
       medics[i] = hid;
       PrintToChat(client, "[TFC]You are currently in line for Medic at number: %d", i);
       RefreshLists();
       return Plugin_Continue;
      }
     }
    }
   }
   if(StrEqual(arg1[startidx], "!sniper"))
   {
    if(CheckLists(client, hid) == false)
    {
     for(new i = 0; i < 9; i++)
     {
      if(snipers[i] == 0)
      {
       snipers[i] = hid;
       PrintToChat(client, "[TFC]You are currently in line for Sniper at number: %d", i);
       RefreshLists();
       return Plugin_Continue;
      }
     }
    }
   }
   if(StrEqual(arg1[startidx], "!spy"))
   {
    if(CheckLists(client, hid) == false)
    {
     for(new i = 0; i < 9; i++)
     {
      if(spys[i] == 0)
      {
       spys[i] = hid;
       PrintToChat(client, "[TFC]You are currently in line for Spy at number: %d", i);
       RefreshLists();
       return Plugin_Continue;
      }
     }
    }
   }
return Plugin_Continue;
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
if(!GetConVarInt(g_hEnabled))
{
 return Plugin_Continue;
}
 new client = GetClientOfUserId(GetEventInt(event, "userid"));
 new hid = GetClientUserId(client);
 new cTeam = GetClientTeam(client);
 if (cTeam == RED_TEAM)
 {
  if(ri_scout == hid)
  {
   r_scout = r_scout-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_scout);
   if( r_scout == 0)
   {
    if(scouts[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_scout = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_scout = 0;
     RefreshLists();
    }
   }
  }
  if(ri_soldier == hid)
  {
   r_soldier = r_soldier-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_soldier);
   if( r_soldier == 0)
   {
    if(soldiers[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_soldier = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_soldier = 0;
     RefreshLists();
    }
   }
  }
  if(ri_pyro == hid)
  {
   r_pyro = r_pyro-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_pyro);
   if( r_pyro == 0)
   {
    if(pyros[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_pyro = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_pyro =0;
     RefreshLists();
    }
   }
  }
  if(ri_demoman == hid)
  {
   r_demoman = r_demoman-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_demoman);
   if( r_demoman == 0)
   {
    if(demomans[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_demoman = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_demoman = 0;
     RefreshLists();
    }
   }
  }
  if(ri_heavy == hid)
  {
   r_heavy = r_heavy-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_heavy);
   if( r_heavy == 0)
   {
    if(heavys[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_heavy = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_heavy = 0;
     RefreshLists();
    }
   }
  }
  if(ri_engineer == hid)
  {
   r_engineer = r_engineer-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_engineer);
   if( r_engineer == 0)
   {
    if(engineers[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_engineer = GetConVarInt(g_hLives);
    }
    else
    {
//   newEngi(hid);
     ChangeClientTeam(client, SPEC_TEAM);
     ri_engineer = 0;
     RefreshLists();
    }
   }
  }
  if(ri_medic == hid)
  {
   r_medic = r_medic-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_medic);
   if( r_medic == 0)
   {
    if(medics[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_medic = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_medic = 0;
     RefreshLists();
    }
   }
  }
  if(ri_sniper == hid)
  {
   r_sniper = r_sniper-1;
   PrintToChat(client, "[TFC]Your remaining Lives: %d", r_sniper);
   if( r_sniper == 0)
   {
    if(snipers[0] == 0)
    {
     PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
     r_sniper = GetConVarInt(g_hLives);
    }
    else
    {
     ChangeClientTeam(client, SPEC_TEAM);
     ri_sniper = 0;
     RefreshLists();
    }
   }
  }
  if(ri_spy == hid)
  {
   if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER) // I never really was on your side!
   {
    return Plugin_Continue;
   }
   else
   {
    r_spy = r_spy-1;
    PrintToChat(client, "[TFC]Your remaining Lives: %d", r_spy);
    if( r_spy == 0)
    {
     if(spys[0] == 0)
     {
      PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
      r_spy = GetConVarInt(g_hLives);
     }
     else
     {
      ChangeClientTeam(client, SPEC_TEAM);
      ri_spy = 0;
      RefreshLists();
      }
     }
    }
   }
  }
//=========
//BLUE TEAM
//=========
  if (cTeam == BLUE_TEAM)
  {
   if(bi_scout == hid)
   {
    b_scout = b_scout-1;
    PrintToChat(client, "[TFC]Your remaining Lives: %d", b_scout);
    if(b_scout == 0)
    {
     if(scouts[0] == 0)
     {
      PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
      b_scout = GetConVarInt(g_hLives);
     }
     else
     {
      ChangeClientTeam(client, SPEC_TEAM);
      bi_scout = 0;
      RefreshLists();
     }
    }
   }
   if(bi_soldier == hid)
   {
    b_soldier = b_soldier-1;
    PrintToChat(client, "[TFC]Your remaining Lives: %d", b_soldier);
    if(b_soldier == 0)
    {
     if(soldiers[0] == 0)
     {
      PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
      b_soldier = GetConVarInt(g_hLives);
     }
     else
     {
      ChangeClientTeam(client, SPEC_TEAM);
      bi_soldier = 0;
      RefreshLists();
      }
     }
    }
    if(bi_pyro == hid)
    {
     b_pyro = b_pyro-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_pyro);
     if(b_pyro == 0)
     {
      if(pyros[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_pyro = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_pyro = 0;
       RefreshLists();
      }
     }
    }
    if(bi_demoman == hid)
    {
     b_demoman = b_demoman-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_demoman);
     if(b_demoman == 0)
     {
      if(demomans[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_demoman = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_demoman = 0;
       RefreshLists();
      }
     }
    }
    if(bi_heavy == hid)
    {
     b_heavy = b_heavy-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_heavy);
     if( b_heavy == 0)
     {
      if(heavys[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_heavy = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_heavy = 0;
       RefreshLists();
      }
     }
    }
    if(bi_engineer == hid)
    {
     b_engineer = b_engineer-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_engineer);
     if( b_engineer == 0)
     {
      if(engineers[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_engineer = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_engineer = 0;
       RefreshLists();
       }
      }
     }
    if(bi_medic == hid)
    {
     b_medic = b_medic-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_medic);
     if( b_medic == 0)
     {
      if(medics[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_medic = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_medic = 0;
       RefreshLists();
      }
     }
    }
    if(bi_sniper == hid)
    {
     b_sniper = b_sniper-1;
     PrintToChat(client, "[TFC]Your remaining Lives: %d", b_sniper);
     if( b_sniper == 0)
     {
      if(snipers[0] == 0)
      {
       PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
       b_sniper = GetConVarInt(g_hLives);
      }
      else
      {
       ChangeClientTeam(client, SPEC_TEAM);
       bi_sniper = 0;
       RefreshLists();
      }
     }
    }
    if(bi_spy == hid)
    {
     if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER) // I never really was on your side!
     {
      return Plugin_Continue;
     }
     else
     {
      b_spy = b_spy-1;
      PrintToChat(client, "[TFC]Your remaining Lives: %d", b_spy);
      if( b_spy == 0)
      {
       if(spys[0] == 0)
       {
        PrintToChat(client, "[TFC]No waiting player detected, lives reset.");
        b_spy = GetConVarInt(g_hLives);
       }
       else
       {
        ChangeClientTeam(client, SPEC_TEAM);
       bi_spy = 0;
       RefreshLists();
      }
     }
    }
   }
  }
return Plugin_Continue;
}

ClassId(client, const String:class[])
{
 new id = GetClientUserId(client);
//Find and Remove Client from ID Holders.
 if(ri_scout == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_scout = 0;
   ri_scout = 0;
  }
  if(StrEqual(class[0], "scout"))
  {
   //Do Nothing
  }
  else
  {
   PrintToChat(client,"[TFC]Your ID was removed from red scout");
   r_scout = 0;
   ri_scout = 0;
  }
 }
 if(ri_soldier == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_soldier = 0;
   ri_soldier = 0;
  }
  if(StrEqual(class[0], "soldier"))
  {
   //Do Nothing
  }
  else
  {
   PrintToChat(client,"[TFC]Your ID was removed from red soldier");
   r_soldier = 0;
   ri_soldier = 0;
  }
 }
 if(ri_pyro == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_pyro = 0;
   ri_pyro = 0;
  }
  if(StrEqual(class[0], "pyro"))
  {
   //Do Nothing
  }
  else
  {
  PrintToChat(client,"[TFC]Your ID was removed from red pyro");
  r_pyro = 0;
  ri_pyro = 0;
  }
 }
 if(ri_demoman == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_demoman = 0;
   ri_demoman = 0;
  }
  if(StrEqual(class[0], "demo"))
  {
   //Do Nothing
  }
  else
  {
   PrintToChat(client,"[TFC]Your ID was removed from red demoman.");
   r_demoman = 0;
   ri_demoman = 0;
  }
 }
 if(ri_heavy == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_heavy = 0;
   ri_heavy = 0;
  }
  if(StrEqual(class[0], "heavy"))
  {
   //Do Nothing
  }
  else
  {
   PrintToChat(client,"[TFC]Your ID was removed from red heavy.");
   r_heavy = 0;
   ri_heavy = 0;
  }
 }
 if(ri_engineer == id)
 {
  if(StrEqual(class[0], "all"))
  {
   r_engineer = 0;
   ri_engineer = 0;
  }
  if(StrEqual(class[0], "engi"))
  {
   //Do Nothing
  }
  else
  {
   PrintToChat(client,"[TFC]Your ID was removed from red enginner");
   r_engineer = 0;
   ri_engineer = 0;
   }
  }
  if(ri_medic == id)
  {
   if(StrEqual(class[0], "all"))
   {
    r_medic = 0;
    ri_medic = 0;
   }
   if(StrEqual(class[0], "medic"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from red medic");
    r_medic = 0;
    ri_medic = 0;
   }
  }
  if(ri_sniper == id)
  {
   if(StrEqual(class[0], "all"))
   {
    r_sniper = 0;
    ri_sniper = 0;
   }
   if(StrEqual(class[0], "sniper"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from red sniper");
    r_sniper = 0;
    ri_sniper = 0;
   }
  }
  if(ri_spy == id)
   {
    if(StrEqual(class[0], "all"))
    {
     r_spy = 0;
     ri_spy = 0;
    }
    if(StrEqual(class[0], "spy"))
    {
   //Do Nothing
    }
    else
    {
     PrintToChat(client,"[TFC]Your ID was removed from red spy");
     r_spy = 0;
     ri_spy = 0;
    }
   }
//=====================
//Blue Team
//=====================
   if(bi_scout == id)
   {
    if(StrEqual(class[0], "all"))
    {
     b_scout = 0;
     bi_scout = 0;
    }
    if(StrEqual(class[0], "bscout"))
    {
   //Do Nothing
    }
    else
    {
     PrintToChat(client,"[TFC]Your ID was removed from blue scout");
     b_scout = 0;
     bi_scout = 0;
    }
   }
   if(bi_soldier == id)
   {
    if(StrEqual(class[0], "all"))
    {
     b_soldier = 0;
     bi_soldier = 0;
    }
    if(StrEqual(class[0], "bsoldier"))
    {
   //Do Nothing
    }
    else
    {
     PrintToChat(client,"[TFC]Your ID was removed from blue soldier");
     b_soldier = 0;
     bi_soldier = 0;
    }
   }
   if(bi_pyro == id)
   {
    if(StrEqual(class[0], "all"))
    {
     b_pyro = 0;
     bi_pyro = 0;
    }
    if(StrEqual(class[0], "bpyro"))
    {
   //Do Nothing
    }
    else
    {
     PrintToChat(client,"[TFC]Your ID was removed from blue pyro");
     b_pyro = 0;
     bi_pyro = 0;
    }
   }
   if(bi_demoman == id)
   {
    if(StrEqual(class[0], "all"))
    {
     b_demoman = 0;
     bi_demoman = 0;
    }
    if(StrEqual(class[0], "bdemo"))
    {
   //Do Nothing
    }
    else
    {
     PrintToChat(client,"[TFC]Your ID was removed from blue demoman");
     b_demoman = 0;
     bi_demoman = 0;
    }
   }
   if(bi_heavy == id)
   {
    if(StrEqual(class[0], "all"))
    {
     b_heavy = 0;
     bi_heavy = 0;
    }
   if(StrEqual(class[0], "bheavy"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from blue heavy.");
    b_heavy = 0;
    bi_heavy = 0;
   }
  }
  if(bi_engineer == id)
  {
   if(StrEqual(class[0], "all"))
   {
    b_engineer = 0;
    bi_engineer = 0;
   }
   if(StrEqual(class[0], "bengi"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from blue engi.");
    b_engineer = 0;
    bi_engineer = 0;
   }
  }
  if(bi_medic == id)
  {
   if(StrEqual(class[0], "all"))
   {
    b_medic = 0;
    bi_medic = 0;
   }
   if(StrEqual(class[0], "bmedic"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from blue medic.");
    b_medic = 0;
    bi_medic = 0;
   }
  }
  if(bi_sniper == id)
  {
   if(StrEqual(class[0], "all"))
   {
    b_sniper = 0;
    bi_sniper = 0;
   }
   if(StrEqual(class[0], "bsniper"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from blue sniper.");
    b_sniper = 0;
    bi_sniper = 0;
   }
  }
  if(bi_spy == id)
  {
   if(StrEqual(class[0], "all"))
   {
    b_spy = 0;
    bi_spy = 0;
   }
   if(StrEqual(class[0], "bspy"))
   {
   //Do Nothing
   }
   else
   {
    PrintToChat(client,"[TFC]Your ID was removed from blue spy.");
    b_spy = 0;
    bi_spy = 0;
   }
  }
}


public OnClientAuthorized(client, const String:steamid[])
{
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
if(!GetConVarInt(g_hEnabled))
{
 return Plugin_Continue;
}
 new client  = GetClientOfUserId(GetEventInt(event, "userid"));
 new cl_team = GetClientTeam(client);
 new id = GetClientUserId(client);
 if(cl_team == RED_TEAM)
 {
  if(TF2_GetPlayerClass(client) == TFClass_Scout)
  {
   if(r_scout < GetConVarInt(g_hLives) && r_scout > 0)
   {
    //Do nothing
   }
   else
   {
    ri_scout = id;
    r_scout = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "scout");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Soldier)
  {
   if(r_soldier < GetConVarInt(g_hLives) && r_soldier > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_soldier = id;
    r_soldier = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "soldier");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Pyro)
  {
   if(r_pyro < GetConVarInt(g_hLives) && r_pyro > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_pyro = id;
    r_pyro = GetConVarInt(g_hLives);
    team_red++;
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
  {
   if(r_demoman < GetConVarInt(g_hLives) && r_demoman > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_demoman = id;
    r_demoman = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "demo");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Heavy)
  {
   if(r_heavy < GetConVarInt(g_hLives) && r_heavy > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_heavy = id;
    r_heavy = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "heavy");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Engineer)
  {
   if(r_engineer < GetConVarInt(g_hLives) && r_engineer > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_engineer = id;
    r_engineer = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "engi");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Medic)
  {
   if(r_medic < GetConVarInt(g_hLives) && r_medic > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_medic = id;
    r_medic = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "medic");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Sniper)
  {
   if(r_sniper < GetConVarInt(g_hLives) && r_sniper > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_sniper = id;
    r_sniper = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "sniper");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Spy)
  {
   if(r_spy < GetConVarInt(g_hLives) && r_spy > 0)
   {
    //Do Nothing
   }
   else
   {
    ri_spy = id;
    r_spy = GetConVarInt(g_hLives);
    team_red++;
    ClassId(client, "spy");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
  }
  //==========================
  // Blue Team
  //==========================
  if(cl_team == BLUE_TEAM)
  {
   if(TF2_GetPlayerClass(client) == TFClass_Scout)
   {
    if(b_scout < GetConVarInt(g_hLives) && b_scout > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_scout = id;
     b_scout = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bscout");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Soldier)
   {
    if(b_soldier < GetConVarInt(g_hLives) && b_soldier > 0)
    {
    //Do Nothing
    }
    else
    {
     bi_soldier = id;
     b_soldier = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bsoldier");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Pyro)
   {
    if(b_pyro < GetConVarInt(g_hLives) && b_pyro > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_pyro = id;
     b_pyro = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bpyro");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
  if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
  {
   if(b_demoman < GetConVarInt(g_hLives) && b_demoman > 0)
   {
    //Do Nothing
   }
   else
   {
    bi_demoman = id;
    b_demoman = GetConVarInt(g_hLives);
    team_blue++;
    ClassId(client, "bdemo");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
   }
  }
  if(TF2_GetPlayerClass(client) == TFClass_Heavy)
  {
   if(b_heavy < GetConVarInt(g_hLives) && b_heavy > 0)
   {
    //Do Nothing
   }
   else
   {
    bi_heavy = id;
    b_heavy = GetConVarInt(g_hLives);
    team_blue++;
    ClassId(client, "bheavy");
    PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Engineer)
   {
    if(b_engineer < GetConVarInt(g_hLives) && b_engineer > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_engineer = id;
     b_engineer = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bengi");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Medic)
   {
    if(b_medic < GetConVarInt(g_hLives) && b_medic > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_medic = id;
     b_medic = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bmedic");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Sniper)
   {
    if(b_sniper < GetConVarInt(g_hLives) && b_sniper > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_sniper = id;
     b_sniper = GetConVarInt(g_hLives);
     team_blue++;
     ClassId(client, "bsniper");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
   if(TF2_GetPlayerClass(client) == TFClass_Spy)
   {
    if(b_spy < GetConVarInt(g_hLives) && b_spy > 0)
    {
     //Do Nothing
    }
    else
    {
     bi_spy = id;
     b_spy = GetConVarInt(g_hLives);
      team_blue++;
     ClassId(client, "bspy");
     PrintToChat(client, "[TFC]You now have %d lives", GetConVarInt(g_hLives));
    }
   }
  }
 return Plugin_Continue;
}


bool:CheckLists(client, const int:id)
{
 for(new i = 0; i < 9; i++)
 {
  if(scouts[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Scout at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(soldiers[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Soldier at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(pyros[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Pyro at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(demomans[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Demoman at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(heavys[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Heavy at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(engineers[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Engineer at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(medics[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Medic at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(snipers[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Sniper at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
  if(spys[i] == id)
  {
   PrintToChat(client, "[TFC]You are currently in line for Spy at number: %d", i);
   PrintToChat(client, "[TFC]If you wish to reset your queue type !remove.");
   return true;
  }
 }
return false;
}

SpawnTeams()
{
 PrintToChatAll("[TFC]Spawning New Players...");
 new newPlayer = 0;
 new blue[32] = "blue";
 new red[32] = "red";
 new client = 0;
 team_blue = GetTeamClientCount(BLUE_TEAM);
 team_red = GetTeamClientCount(RED_TEAM);
 if(team_blue <= team_red)
 {
  if( b_scout <= 0 && scouts[0] != 0)
  {
   newPlayer = scouts[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bscout");
   bi_scout = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Scout, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_scout = GetConVarInt(g_hLives);
   scouts[0] = 0;
   team_blue++;
  }
  if( b_soldier <= 0 && soldiers[0] != 0)
  {
   newPlayer = soldiers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bsoldier");
   bi_soldier = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_soldier = GetConVarInt(g_hLives);
   soldiers[0] = 0;
   team_blue++;
  }
  if( b_pyro <= 0 && pyros[0] != 0)
  {
   newPlayer = pyros[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bpyro");
   bi_pyro = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Pyro, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_pyro = GetConVarInt(g_hLives);
   pyros[0] = 0;
   team_blue++;
  }
  if( b_demoman <= 0 && demomans[0] != 0)
  {
   newPlayer = demomans[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bdemo");
   bi_demoman = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_DemoMan, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_demoman = GetConVarInt(g_hLives);
   demomans[0] = 0;
   team_blue++;
  }
  if( b_heavy <= 0 && heavys[0] != 0)
  {
   newPlayer = heavys[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bheavy");
   bi_heavy = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_heavy = GetConVarInt(g_hLives);
   heavys[0] = 0;
   team_blue++;
  }
  if( b_engineer <= 0 && engineers[0] != 0)
  {
   newPlayer = engineers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bengi");
   bi_engineer = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Engineer, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_engineer = GetConVarInt(g_hLives);
   engineers[0] = 0;
   team_blue++;
  }
  if( b_medic <= 0 && medics[0] != 0)
  {
   newPlayer = medics[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bmedic");
   bi_medic = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Medic, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_medic = GetConVarInt(g_hLives);
   medics[0] = 0;
   team_blue++;
  }
  if( b_sniper <= 0 && snipers[0] != 0)
  {
   newPlayer = snipers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bsniper");
   bi_sniper = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Sniper, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_sniper = GetConVarInt(g_hLives);
   snipers[0] = 0;
   team_blue++;
  }
  if( b_spy <= 0 && spys[0] != 0)
  {
   newPlayer = spys[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "bspy");
   bi_spy = newPlayer;
   ForceTeam(blue, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Spy, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   b_spy = GetConVarInt(g_hLives);
   spys[0] = 0;
   team_blue++;
  }
 }
 //----------------------------------------------
 // Red Team
 //----------------------------------------------
  if( r_scout <= 0 && scouts[0] != 0)
  {
   newPlayer = scouts[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "scout");
   ri_scout = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Scout, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_scout = GetConVarInt(g_hLives);
   scouts[0] = 0;
   team_red++;
  }
  if( r_soldier <= 0 && soldiers[0] != 0)
  {
   newPlayer = soldiers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "soldier");
   ForceTeam(red, newPlayer);
   ri_soldier = newPlayer;
   TF2_SetPlayerClass(client, TFClass_Soldier, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_soldier = GetConVarInt(g_hLives);
   soldiers[0] = 0;
   team_red++;
  }
  if( r_pyro <= 0 && pyros[0] != 0)
  {
   newPlayer = pyros[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "pyro");
   ri_pyro = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Pyro, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_pyro = GetConVarInt(g_hLives);
   pyros[0] = 0;
   team_red++;
  }
  if( r_demoman <= 0 && demomans[0] != 0)
  {
   newPlayer = demomans[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "demo");
   ri_demoman = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_DemoMan, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_demoman = GetConVarInt(g_hLives);
   demomans[0] = 0;
   team_red++;
  }
  if( r_heavy <= 0 && heavys[0] != 0)
  {
   newPlayer = heavys[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "heavy");
   ri_heavy = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_heavy = GetConVarInt(g_hLives);
   heavys[0] = 0;
   team_red++;
  }
  if( r_engineer <= 0 && engineers[0] != 0)
  {
   newPlayer = engineers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "engi");
   ri_engineer = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Engineer, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_engineer = GetConVarInt(g_hLives);
   engineers[0] = 0;
   team_red++;
  }
  if( r_medic <= 0 && medics[0] != 0)
  {
   newPlayer = medics[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "medic");
   ri_medic = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Medic, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_medic = GetConVarInt(g_hLives);
   medics[0] = 0;
   team_red++;
  }
  if( r_sniper <= 0 && snipers[0] != 0)
  {
   newPlayer = snipers[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "sniper");
   ri_sniper = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Sniper, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_sniper = GetConVarInt(g_hLives);
   snipers[0] = 0;
   team_red++;
  }
  if( r_spy <= 0 && spys[0] != 0)
  {
   newPlayer = spys[0];
   client = GetClientOfUserId(newPlayer);
   ClassId(client, "spy");
   ri_spy = newPlayer;
   ForceTeam(red, newPlayer);
   TF2_SetPlayerClass(client, TFClass_Spy, false, true);
   TF2_RespawnPlayer(client);
   TF2_RegeneratePlayer(client);
   r_spy = GetConVarInt(g_hLives);
   spys[0] = 0;
   team_red++;
   }
  return Plugin_Continue;
}

RemoveId(client)
{
 new id = GetClientUserId(client);
 for(new i = 0; i < 9; i++)
 {
  if(scouts[i] == id)
  {
   scouts[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Scout queue.");
  }
  if(soldiers[i] == id)
  {
   soldiers[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Soldier queue.");
  }
  if(pyros[i] == id)
  {
   pyros[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Pyro queue.");
  }
  if(demomans[i] == id)
  {
   demomans[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Demoman queue.");
  }
  if(heavys[i] == id)
  {
   heavys[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Heavy queue.");
  }
  if(engineers[i] == id)
  {
   engineers[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Engineer queue.");
  }
  if(medics[i] == id)
  {
   medics[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Medic queue.");
  }
  if(snipers[i] == id)
  {
   snipers[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Sniper queue.");
  }
  if(spys[i] == id)
  {
   spys[i] = 0;
   PrintToChat(client, "[TFC]You have been removed from Spy queue.");
  }
 }
RefreshLists();
}

ForceTeam(const String:g_Team[], hid)
{
 new client = GetClientOfUserId(hid);
 if(StrEqual(g_Team[0], "red"))
 {
  ChangeClientTeam(client, 2);
 }
 if(StrEqual(g_Team[0], "blue"))
 {
  ChangeClientTeam(client, 3);
 }
}

RefreshLists()
{
 new next = 1;
 new temp = 0;
 PrintToChatAll("[TFC]Updating Queues...");
 for(new i = 0; i < 9; i++)
 {
  if(scouts[i] == 0 && scouts[next] != 0)
  {
   temp = scouts[i];
   scouts[i] = scouts[next];
   scouts[next] = temp;
   temp = 0;
  }
  if(soldiers[i] == 0 && soldiers[next] != 0)
  {
   temp = soldiers[i];
   soldiers[i] = soldiers[next];
   soldiers[next] = temp;
   temp = 0;
  }
  if(pyros[i] == 0 && pyros[next] != 0)
  {
   temp = pyros[i];
   pyros[i] = pyros[next];
   pyros[next] = temp;
   temp = 0;
  }
  if(heavys[i] == 0 && heavys[next] != 0)
  {
   temp = heavys[i];
   heavys[i] = heavys[next];
   heavys[next] = temp;
   temp = 0;
  }
  if(demomans[i] == 0 && demomans[next] != 0)
  {
   temp = demomans[i];
   demomans[i] = demomans[next];
   demomans[next] = temp;
   temp = 0;
  }
  if(engineers[i] == 0 && engineers[next] != 0)
  {
   temp = engineers[i];
   engineers[i] = engineers[next];
   engineers[next] = temp;
   temp = 0;
  }
  if(medics[i] == 0 && medics[next] != 0)
  {
   temp = medics[i];
   medics[i] = medics[next];
   medics[next] = temp;
   temp = 0;
  }
  if(snipers[i] == 0 && snipers[next] != 0)
  {
   temp = scouts[i];
   snipers[i] = snipers[next];
   snipers[next] = temp;
   temp = 0;
  }
  if(spys[i] == 0 && spys[next] != 0)
  {
   temp = spys[i];
   spys[i] = spys[next];
   spys[next] = temp;
   temp = 0;
  }
 next++;
 }
 SpawnTeams();
}