#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR     "Arkarr"
#define PLUGIN_VERSION     "1.00"
#define TF_TEAM_RED     3
#define TF_TEAM_BLU     2

Handle CVAR_KillLimit;
Handle CVAR_WinLimit;
Handle CVAR_WinDiff;

bool enablePlugin;

int killsR;
int killsB;
int roundWon;

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
    CVAR_WinLimit = FindConVar("mp_winlimit");
    CVAR_WinDiff = FindConVar("mp_windifference");
    
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
} 

public void OnMapStart()
{
    char mapName[45];
    
    roundWon = 0;
    enablePlugin = false;
    
    GetCurrentMap(mapName, sizeof(mapName));
    if(StrContains(mapName, "dm_", true) == 0)
        enablePlugin = true;
}

public void OnMapEnd()
{
    //reset all counters as round is over and to be able to call OnMapStart() again
    roundWon = 0;
    killsR = 0;
    killsB = 0;
    enablePlugin = false;
}
 
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(!enablePlugin)
        return;
        
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int iWinningTeam = -1;    
    
    if(attacker != 0 && victim != attacker)
    {
        if(GetClientTeam(attacker) == TF_TEAM_RED)
            killsR++;
        else if(GetClientTeam(attacker) == TF_TEAM_BLU)
            killsB++;
    }    
        
    if(killsR >= GetConVarInt(CVAR_KillLimit))
        iWinningTeam = TF_TEAM_RED;
    else if(killsB >= GetConVarInt(CVAR_KillLimit))
        iWinningTeam = TF_TEAM_BLU;
        
    if(iWinningTeam == -1)
        return;    
        
    int iEnt = -1;
    iEnt = FindEntityByClassname(iEnt, "game_round_win");
    
    if (iEnt < 1)
    {
        iEnt = CreateEntityByName("game_round_win");
        if (IsValidEntity(iEnt))
            DispatchSpawn(iEnt);
        else
        {
            PrintToServer("Unable to find or create a game_round_win entity!");
            return;
        }
    }
        
    SetVariantInt(iWinningTeam);
    AcceptEntityInput(iEnt, "SetTeam");
    AcceptEntityInput(iEnt, "RoundWin");
        
    roundWon++;
    if(roundWon+1 == GetConVarInt(CVAR_WinLimit) || roundWon+1 == GetConVarInt(CVAR_WinDiff))
    {
        char nextMap[45];
        GetNextMap(nextMap, sizeof(nextMap));
        ServerCommand("sm_map %s", nextMap);
    }
        
}
    
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(enablePlugin)
    {
        killsR = 0;
        killsB = 0;
    }
}  