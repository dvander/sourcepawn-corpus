/*
 * Allow a max of 2v2 (or 3v3), everyone else should be forced to spectator.
 */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define MAX_TEAM_LENGTH  32

public Plugin:myinfo = {
  name = "BBall Limit Players",
  author = "Yarr! goosmurf (smurfy@mooh.org)",
  description = "Limit the game to 2v2 or 3v3, everyone else must spectate",
  version = "1.0",
  url = "http://steamcommunity.com/groups/smurfy-tf2"
}

new Handle:g_MaxPlayers;

public OnPluginStart() {
  g_MaxPlayers = CreateConVar("bball_limit_players", "4",
                              "Max players (use 4 for 2v2, 6 for 3v3 etc)",
                              FCVAR_PLUGIN & FCVAR_DONTRECORD,
                              true, 2.0, true, 24.0);

  AddCommandListener(Command_ChangeTeam, "jointeam");
  AddCommandListener(Command_ChangeTeam, "autoteam");
}

public Action:Command_ChangeTeam(client, String:command[], argc) {
  new total_players = GetTeamClientCount(_:TFTeam_Blue) +
                      GetTeamClientCount(_:TFTeam_Red);
  new current_team = GetClientTeam(client);

  if (total_players >= GetConVarInt(g_MaxPlayers)) {
    // if the player is currently on a team, they can do whatever they like
    if (current_team == _:TFTeam_Blue || current_team == _:TFTeam_Red) {
      return Plugin_Continue
    }

    PrintToChat(client, "\x04[BBall] \x03BBall \x01works best when the game is 2v2 or 3v3");
    PrintToChat(client, "\x04[BBall] \x03The teams are currently full, please wait your turn :)");
    ChangeClientTeam(client, _:TFTeam_Spectator);
    return Plugin_Handled;
  }

  return Plugin_Continue;
}
