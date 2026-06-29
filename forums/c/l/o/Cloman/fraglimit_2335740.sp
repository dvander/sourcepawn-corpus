#include <sourcemod>
#include <sdktools>


#define PLUGIN_AUTHOR     "Arkarr And Cloman"
#define PLUGIN_VERSION     "2.00"
#define TF_TEAM_RED     3
#define TF_TEAM_BLU     2

new Handle:CVAR_KillLimit;

new bool:enablePlugin = false;
new String:mapName[60];

new killsR = 0;
new killsB = 0;
new roundWon = 0;
new iWinningTeam = -1;

public Plugin myinfo = 
{
    name = "[ANY] Kill End Round",
    author = PLUGIN_AUTHOR,
    description = "End the round until a certain ammount of kills is reached.",
    version = PLUGIN_VERSION,
    url = "http://www.google.com"
};

public void OnPluginStart()
{
    CVAR_KillLimit = CreateConVar("dm_fraglimit", "30", "Set after how much kill the round end.", _, true, 1.0, false, _);
    
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_round_win", Event_RoundEnd);
    HookEvent("teamplay_round_stalemate", Event_RoundEnd);
}

public OnPluginEnd()
{
    //dont need to do anything but is needed for onpluginstart().
}

public void OnMapStart()
{
    roundWon = 0;
    enablePlugin = false;
    GetCurrentMap(mapName, 60);
}

public void OnMapEnd()
{
    //reset all counters as round is over and to be able to call OnMapStart() again
    roundWon = 0;
    killsR = 0;
    killsB = 0;
    iWinningTeam = -1;
    enablePlugin = false;
}
 
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!enablePlugin){
        return Plugin_Handled;
    }
        
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new deathflags = GetEventInt(event, "death_flags");
    new bool:nofakekill = true;
    
    if (deathflags & 32)
    {
        nofakekill = false;
    }
    
    if (nofakekill == false)
    {
        return Plugin_Handled;
    }
    
    if(attacker != 0 && victim != attacker)
    {
        if(GetClientTeam(attacker) == TF_TEAM_RED)
            killsR++;
        else if(GetClientTeam(attacker) == TF_TEAM_BLU)
            killsB++;
    }
    else{
        return Plugin_Handled;
    }
        
    if(killsR >= GetConVarInt(CVAR_KillLimit))
        iWinningTeam = TF_TEAM_RED;
    else if(killsB >= GetConVarInt(CVAR_KillLimit))
        iWinningTeam = TF_TEAM_BLU;
        
    if(iWinningTeam == -1)
        return Plugin_Handled;    
        
    int iEnt = -1;
    iEnt = FindEntityByClassname(iEnt, "game_round_win");
    
    if (iEnt < 1)
    {
        iEnt = CreateEntityByName("game_round_win");
        if (IsValidEntity(iEnt))
            DispatchSpawn(iEnt);
        else
        {
            LogMessage("Unable to find or create a game_round_win entity!");
            PrintToServer("Unable to find or create a game_round_win entity!");
            return Plugin_Handled;
        }
    }
        
    SetVariantInt(iWinningTeam);
    AcceptEntityInput(iEnt, "SetTeam");
    AcceptEntityInput(iEnt, "RoundWin");

    return Plugin_Handled;
}


public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
    if(enablePlugin){
        enablePlugin = false;
    }
    
    if(iWinningTeam > 0){
        roundWon = GetTeamScore(iWinningTeam) + 1;
        SetTeamScore(iWinningTeam, roundWon);
    }
}
    
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(StrContains(mapName, "dm_", true) == 0){
        enablePlugin = true;
    }
    
    if(enablePlugin)
    {
        killsR = 0;
        killsB = 0;
        iWinningTeam = -1;
    }

    return Plugin_Handled;
}  