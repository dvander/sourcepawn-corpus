#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

bool g_bWarmingUpTime = true;

public Plugin myinfo =
{
	name = "Team Randomizer",
	author = "Thiry",
	description = "team randomize when warmup end",
	version = PLUGIN_VERSION,
	url = "http://five-seven.net/"
};

public void OnPluginStart()
{
	HookEvent("round_start",Event_OnRoundStart);
}

public void OnMapStart()
{
	g_bWarmingUpTime = true;
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bWarmingUpTime)
	{
		if(GameRules_GetProp("m_bWarmupPeriod") == 0)
		{
			g_bWarmingUpTime = false;
			ServerCommand("mp_scrambleteams");
			PrintToChatAll("\x04[Shuffle] \x01Teams have been successfully \x05balanced");
		}
	}
}