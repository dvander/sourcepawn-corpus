#include <sourcemod>
#include <cstrike>

Handle roundCvar = INVALID_HANDLE;
Handle teamScore = INVALID_HANDLE;

public OnPluginStart()
{
    roundCvar = CreateConVar("sm_sc_after_wins", "8", "after .. rounds teams will be scrambled");
    HookEvent("round_end", Scramble);
    AutoExecConfig(true, "plugin.scramble", "sourcemod");
}

public Action:Scramble(Handle: event , const String: name[] , bool: dontBroadcast)
{
    if (CS_GetTeamScore(CS_TEAM_T) == GetConVarInt(roundCvar))
    {
        ServerCommand("mp_scrambleteams");
        PrintToChatAll("Teams was scrambled, beacuse Terrorits won %i rounds", roundCvar);
    }
}  
