// Forlix DeadChat
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2009 Dominik Friedrichs
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION            "1.06 beta"
#define PLUGIN_VERSION_CVAR       "forlix_deadchat_version"

// convar defaults
#define RELAY_MODE                "1"

public Plugin:myinfo =
{
  name = "Forlix DeadChat",
  author = "Forlix (Dominik Friedrichs)",
  description = "Relays chat messages of dead players and spectators to alive players",
  version = PLUGIN_VERSION,
  url = "http://forlix.org/"
};

new Handle:h_relay_mode = INVALID_HANDLE;
new relay_mode = 0;

new String:Chat_AllSpec[32];
new String:Chat_AllDead[32];
new String:Chat_Tm2Dead[32];
new String:Chat_Tm3Dead[32];

new bool:broadcast[MAXPLAYERS+1] = {false, ...};


public OnPluginStart()
{
  RegConsoleCmd("say", Command_Say);
  RegConsoleCmd("say_team", Command_SayTeam);

  HookEvent("player_say", Event_PlayerSay);

  decl String:gamedesc[32];
  GetGameDescription(gamedesc, sizeof(gamedesc), true);

  if(StrEqual(gamedesc, "Counter-Strike: Source"))
  {
    Chat_AllSpec = "#Cstrike_Chat_AllSpec";
    Chat_AllDead = "#Cstrike_Chat_AllDead";
    Chat_Tm2Dead = "#Cstrike_Chat_T_Dead";
    Chat_Tm3Dead = "#Cstrike_Chat_CT_Dead";
  }
  else
  if(StrEqual(gamedesc, "Team Fortress"))
  {
    Chat_AllSpec = "#TF_Chat_AllSpec";
    Chat_AllDead = "#TF_Chat_AllDead";
    Chat_Tm2Dead = "#TF_Chat_Team_Dead";
    Chat_Tm3Dead = "#TF_Chat_Team_Dead";
  }
  else
  {
    UnloadWithMessage("Forlix DeadChat: Game not supported.");
    return;
  }

  new Handle:version_cvar = CreateConVar(PLUGIN_VERSION_CVAR,
  PLUGIN_VERSION,
  "Forlix DeadChat plugin version",
  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PRINTABLEONLY);

  SetConVarString(version_cvar, PLUGIN_VERSION, false, false);

  h_relay_mode = CreateConVar("forlix_deadchat_relay_mode",
  RELAY_MODE,
  "Relay all messages to alive players, respecting team-only flag (1), Disable relaying (0)",
  0, true, 0.0, true, 1.0);

  HookConVarChange(h_relay_mode, MyConVarChanged);

  // manually trigger convar readout
  MyConVarChanged(INVALID_HANDLE, "0", "0");

  return;
}


public Action:Command_Say(client, args)
{
  broadcast[client] = true;
  return(Plugin_Continue);
}


public Action:Command_SayTeam(client, args)
{
  broadcast[client] = false;
  return(Plugin_Continue);
}


public Event_PlayerSay(Handle:event,
                       const String:Event_mtype[],
                       bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  if(relay_mode != 1
  || !client
  || IsPlayerAlive(client))
    return;

  decl String:mtype[64];
  decl String:name[MAX_NAME_LENGTH];
  decl String:text[128];

  decl tx_clients[MAXPLAYERS];
  new tx_count = 0;

  GetClientName(client, name, sizeof(name));
  GetEventString(event, "text", text, sizeof(text));

  new team = GetClientTeam(client);

  if(broadcast[client])
  // broadcast message
  {
    if(team == 1)
      mtype = Chat_AllSpec;
    else
      mtype = Chat_AllDead;

    // build list of clients to relay to
    for(new i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i))
    //&& IsPlayerAlive(i))
      tx_clients[tx_count++] = i;
  }
  else
  // team-only message
  {
    switch(team)
    {
      case 2:
        mtype = Chat_Tm2Dead;

      case 3:
        mtype = Chat_Tm3Dead;

      default:
        return;
    }

    // build list of clients to relay to
    for(new i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i)
    //&& IsPlayerAlive(i)
    && GetClientTeam(i) == team)
      tx_clients[tx_count++] = i;
  }

  if(!tx_count)
  // no clients to relay to
    return;

  // finally, relay the message to clients in list
  new Handle:h_saytext2 = StartMessage("SayText2",
  tx_clients,
  tx_count,
  USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

  if(h_saytext2 != INVALID_HANDLE)
  {
    BfWriteByte(h_saytext2, client);
    BfWriteByte(h_saytext2, true);
    BfWriteString(h_saytext2, mtype);
    BfWriteString(h_saytext2, name);
    BfWriteString(h_saytext2, text);
    EndMessage();
  }

  return;
}


UnloadWithMessage(const String:message[])
{
  PrintToServer("%s", message);
  ServerCommand("sm plugins unload forlix_deadchat");

  return;
}


public MyConVarChanged(Handle:convar,
                       const String:oldValue[],
                       const String:newValue[])
{
  relay_mode = GetConVarInt(h_relay_mode);
  return;
}
