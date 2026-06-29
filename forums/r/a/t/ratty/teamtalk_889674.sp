#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
        name = "Team talk",
        author = "Ratty",
        description = "Lets you talk to just your team when alltalk enabled",
        version = PLUGIN_VERSION,
        url = "http://www.nom-nom-nom.us"
}

public OnPluginStart()
{
        RegConsoleCmd("+teamtalk", teamtalkon,  "use in conjunction with +voicerecord", FCVAR_GAMEDLL);
        RegConsoleCmd("-teamtalk", teamtalkoff, "use in conjunction with +voicerecord", FCVAR_GAMEDLL);
}

public OnMapStart()
{
  PrecacheSound("buttons/button9.wav");
  PrecacheSound("buttons/button19.wav");
}

public Action:teamtalkon(client, args) {
  new myteam = GetClientTeam(client);

  switch (myteam) {
    case 2:
      DoTeamTalk(client,3);
    case 3:
      DoTeamTalk(client,2);
    default:
      PrintToChat(client, "You must be on a team to use team chat. Spectators hear and talk to everybody.");
  }

  return Plugin_Handled;
}

DoTeamTalk(client,team) {
  for (new i = 1; i <= GetMaxClients(); i++) {
    if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
        SetClientListening(i,client,true);
  }
  EmitSoundToClient(client,"buttons/button9.wav");
}

public Action:teamtalkoff(client, args) {
  for (new i = 1; i <= GetMaxClients(); i++) {
    if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
      SetClientListening(i,client,false);
    }
  }
  EmitSoundToClient(client,"buttons/button19.wav");
  return Plugin_Handled;
}
