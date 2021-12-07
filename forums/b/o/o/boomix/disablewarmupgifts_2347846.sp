#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Disable warmup gifts", 
	author = "boomix", 
	description = "Disable warmup gifts", 
	version = SOURCEMOD_VERSION, 
	url = "http://steamcommunity.com/id/boomix69/ [When your inviting me, leave comment in profile! :)]"
};

bool g_RoundStart = true;

public void OnPluginStart()
{
	HookEvent("round_start", Gift_RoundStart);
}

public void OnConfigsExecuted()
{
	GiftChange();
	g_RoundStart = false;
}

public void OnGameFrame()
{
	if(GameRules_GetProp("m_bWarmupPeriod") == 1) {
		GiftChange();
	}
	
	if(g_RoundStart) {
		GiftChange();
	}
}

public Action Gift_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_RoundStart = true;
	CreateTimer(5.0, StopRoundStart);
}

public Action StopRoundStart(Handle timer, any:client)
{
	g_RoundStart = false;
}

public void GiftChange()
{
	GameRules_SetProp("m_numGlobalGiftsGiven", -1, 1);
	GameRules_SetProp("m_numGlobalGifters", -1, 1);
	GameRules_SetProp("m_numGlobalGiftsPeriodSeconds", -1, 1);
}
