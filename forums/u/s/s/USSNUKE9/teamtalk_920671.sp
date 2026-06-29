#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0"

new bool:teamtalking = false;

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
        RegConsoleCmd("teamtalk", teamtalktoggle, "toggles teamtalk on/off", FCVAR_GAMEDLL);
}

public Action:teamtalkon(client, args) {
  new myteam = GetClientTeam(client);
        
  teamtalking = true;
    
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
}

public Action:teamtalkoff(client, args) {
  teamtalking = false;
  for (new i = 1; i <= GetMaxClients(); i++) {
    if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
      SetClientListening(i,client,false);
    }
  }
  
  return Plugin_Handled;
}

public Action:teamtalktoggle(client, args)
{
    if (!teamtalking){
        teamtalkon(client, args);
        PrintToChat(client,"\x01\x04[SM] Now talking to team only.")
    }
    else {
        teamtalkoff(client, args);
        PrintToChat(client,"\x01\x04[SM] Now talking to everyone.")
    }
    return;
}