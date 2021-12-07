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

#pragma semicolon 1

#define PLUGIN_VERSION            "1.15"
#define PLUGIN_VERSION_CVAR       "forlix_deadchat_version"

#define MTYPE_LEN                 32
#define NAME_LEN                  32
#define MSG_LEN                   128

#define BCTYPE_ALL                1
#define BCTYPE_TEAM               2

// convar defaults
#define RELAY_MODE                "1"

public Plugin:myinfo =
{
  name = "Forlix AdminsOnly DeadChat",
  author = "Forlix, Will",
  description = "Relays chat messages of dead players and spectators to admins with generic admin flag",
  version = PLUGIN_VERSION,
  url = "http://forlix.org/"
};

new String:Chat_AllSpec[MTYPE_LEN];
new String:Chat_AllDead[MTYPE_LEN];
new String:Chat_Tm2Dead[MTYPE_LEN];
new String:Chat_Tm3Dead[MTYPE_LEN];

new Handle:h_relay_mode = INVALID_HANDLE;
new relay_mode = 0;

new bctype[MAXPLAYERS+1] = {0, ...};


public OnPluginStart()
{
  RegConsoleCmd("say", Command_Say);
  RegConsoleCmd("say_team", Command_SayTeam);

  HookEvent("player_say", Event_PlayerSay);

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

  // game-specific setup
  decl String:gamedir[16];
  GetGameFolderName(gamedir, sizeof(gamedir));

  if(StrEqual(gamedir, "cstrike"))
  {
    Chat_AllSpec = "Cstrike_Chat_AllSpec";
    Chat_AllDead = "Cstrike_Chat_AllDead";
    Chat_Tm2Dead = "Cstrike_Chat_T_Dead";
    Chat_Tm3Dead = "Cstrike_Chat_CT_Dead";
  }
  else
  if(StrEqual(gamedir, "tf"))
  {
    Chat_AllSpec = "TF_Chat_AllSpec";
    Chat_AllDead = "TF_Chat_AllDead";
    Chat_Tm2Dead = "TF_Chat_Team_Dead";
    Chat_Tm3Dead = "TF_Chat_Team_Dead";
  }
  else
    UnloadWithMessage("Forlix DeadChat: Game not supported");

  return;
}


public OnClientPutInServer(client)
{
  bctype[client] = 0;
  return;
}


public Action:Command_Say(client, args)
{
  bctype[client] = BCTYPE_ALL;
  return(Plugin_Continue);
}


public Action:Command_SayTeam(client, args)
{
  bctype[client] = BCTYPE_TEAM;
  return(Plugin_Continue);
}


public Event_PlayerSay(Handle:event,
                       const String:Event_mtype[],
                       bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));

  if(!relay_mode
  || !bctype[client]
  || dontBroadcast
  || !client
  || IsPlayerAlive(client))
    return;

  decl String:mtype[MTYPE_LEN];
  decl String:name[NAME_LEN];
  decl String:text[MSG_LEN];

  decl tx_clients[MAXPLAYERS];
  new tx_count = 0;

  if(!GetClientName(client, name, sizeof(name)))
    return;

  GetEventString(event, "text", text, sizeof(text));

  new team = GetClientTeam(client);

  switch(bctype[client])
  {
    case BCTYPE_ALL:
    // broadcast message
    {
      if(team == 1)
        mtype = Chat_AllSpec;
      else
        mtype = Chat_AllDead;

      // build list of clients to relay to
      // Modification by Will - only admins with ADMFLAG_GENERIC can see dead and team messages
      for(new i = 1; i <= MaxClients; i++)
      {
        if (IsClientInGame(i) && IsPlayerAlive(i) && (GetUserFlagBits(i) & (ADMFLAG_GENERIC)) )
        {
          tx_clients[tx_count++] = i;
        }
      }
    }

    case BCTYPE_TEAM:
    // team-only message
    {
      switch(team)
      // only process teams that can have alive players
      // eg. spectators are all dead, no need to relay
      {
        case 2:
          mtype = Chat_Tm2Dead;

        case 3:
          mtype = Chat_Tm3Dead;

        default:
          return;
      }

      // build list of clients to relay to
      // Modification by Will - only admins with ADMFLAG_GENERIC can see dead and team messages
      for(new i = 1; i <= MaxClients; i++)
      {
        if (IsClientInGame(i) && IsPlayerAlive(i) && (GetUserFlagBits(i) & (ADMFLAG_GENERIC)) )
        {
          tx_clients[tx_count++] = i;
        }
      }
    }

    default:
      return;
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

  bctype[client] = 0;
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
