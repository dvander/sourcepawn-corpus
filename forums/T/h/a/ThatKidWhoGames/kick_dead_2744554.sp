#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>

EngineVersion g_Engine = Engine_Unknown;

public void OnPluginStart()
{
	g_Engine = GetEngineVersion();

	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_Engine == Engine_TF2 && (hEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient != 0 && !IsClientInKickQueue(iClient))
	{
		KickClient(iClient, "You died, you get kicked");
	}
}