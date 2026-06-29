#include <sourcemod>
#include <sdktools_functions>
#include <cstrike>

#pragma semicolon 1
 
#define PLUGIN_VERSION "1.2"
 
public Plugin:myinfo = {
    name = "RoundCron",
    author = "Bawitdaba",
    description = "Runs configs based on map round.",
    version = PLUGIN_VERSION,
    url = "http://www.soucemod.net"
};
 
new Handle:writeOnMapChange;
new CurrentRound = 0;
new ScoreboardRound = 0;
new maxRounds = 0;
new SecondToLastRound = 0;
 
public OnPluginStart(){
  
    writeOnMapChange = CreateConVar("sm_roundcron", "1", "If set to 1 this will exec rounds\round#.cfg",FCVAR_PLUGIN);
  
    // Set the version cvar
    CreateConVar("sm_roundcron_version",PLUGIN_VERSION,"The version of the SourceMod plugin RoundCron, by Bawitdaba",FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
  
    // Hook Events
    HookEvent("game_start", GameEvents_GameStart);
    HookEvent("round_start", GameEvents_RoundStart, EventHookMode_PostNoCopy);
  
    // Finally, we'll tell the server that the plugin is initialized
    PrintToServer("[SM RoundCron] Loaded");
}

public OnMapStart()
{
    CurrentRound = 1;
}

public Action:GameEvents_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    CurrentRound = 1;
    
    return Plugin_Continue;
}
public GameEvents_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new ctScore = 0;
    new tScore = 0;

    ctScore = GetTeamScore(CS_TEAM_CT);
    tScore = GetTeamScore(CS_TEAM_T);

    if(ctScore == 0 && tScore == 0){
        CurrentRound = 1;
    }
	
    maxRounds = GetConVarInt(FindConVar("mp_maxrounds"));
    SecondToLastRound = maxRounds - 1;
    ScoreboardRound = maxRounds + 1;

    // Debug Messages
    // PrintToServer("Current Round: %d", CurrentRound);
    // PrintToServer("Max Rounds: %d", maxRounds);
    // PrintToServer("Scoreboard Round: %d", ScoreboardRound);
    // PrintToServer("Last Playable Round: %d", SecondToLastRound);

    if(GetConVarInt(writeOnMapChange) == 1){
        if(CurrentRound == ScoreboardRound && maxRounds != 0) {
            // Last Round (Scoreboard)
            ServerCommand("exec rounds/scoreboard.cfg");
        } else {
            if(CurrentRound == maxRounds && maxRounds != 0) {
                // Last Playable Round (Last Round)
                ServerCommand("exec rounds/lastround.cfg");
            } else {
                if(CurrentRound == SecondToLastRound && maxRounds != 0) {
                    // Second to Last Playable Round
                    ServerCommand("exec rounds/2ndtolastround.cfg");
                } else {
                    // Normal Round
                    ServerCommand("exec rounds/round%i.cfg", CurrentRound);
                }
            }
        }
    }

    CurrentRound = CurrentRound + 1;
}