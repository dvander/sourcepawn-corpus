#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
    HookEvent("arena_round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    FixTeams();
}

FixTeams()
{
    new Float:Ratio;
    for(new i = 1; i <= MaxClients; i++)
    {
        Ratio = Float:GetTeamClientCount(3)/Float:GetTeamClientCount(2)
        if(Ratio<=0.33)
        {
            break;
        }
        if(IsClientInGame(i)&&GetClientTeam(i)==3)
        {
            ChangeClientTeam(i, 2);
        }
    }
}