#include<sourcemod>
#include<sdktools>
#define PLUGIN_VERSION "1.0.0"


new bool:IsWarmUp=true;

public Plugin:myinfo =
{
    name = "Team Randomizer",
    author = "Thiry",
    description = "team randomize when warmup end",
    version = PLUGIN_VERSION,
    url = "http://five-seven.net/"
};

public OnPluginStart()
{
    HookEvent("round_start",ev_round_start);
}
public OnMapStart()
{
    IsWarmUp=true;

}

public Action:ev_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(IsWarmUp)
    {
        if(GameRules_GetProp("m_bWarmupPeriod")==0)
        {
            IsWarmUp=false;
            PrintToChatAll("[Team Randomizer] scramble teams...");
            ServerCommand("mp_scrambleteams");
        }
    }
}