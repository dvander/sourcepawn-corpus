#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>

#define debug 0

#define VICTIM_SAVE_INTERVAL 1.2
#define VICTIM_CHECK_INTERVAL 2.0

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

Handle g_hJockeyRideCheck_Timer;
Handle g_hSaveVictimPosition_Timer;

int g_iJockeyVictim;
float g_fVictimPrevPos[3];

public Plugin:myinfo =
{
	name = "Jockey Unteleport",
	author = "larrybrains",
	description = "Teleports a survivor back into the map if they are randomly teleported outside of the map while jockeyed.",
	version = "1.0",
	url = "https://larrymod.com"
};

public OnPluginStart()
{

	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("jockey_killed", Event_JockeyDeath);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

}
public void OnMapStart()
{
	g_hJockeyRideCheck_Timer = null;
	g_hSaveVictimPosition_Timer = null;
}

public Action Event_JockeyDeath(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	delete g_hJockeyRideCheck_Timer;
	delete g_hSaveVictimPosition_Timer;
	g_iJockeyVictim = -1;
	#if debug
		CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Jockey killed.");
	#endif

}

public Action Event_JockeyRideEnd(Event hEvent, const char[] s_Name, bool b_DontBroadcast)
{
	delete g_hJockeyRideCheck_Timer;
	delete g_hSaveVictimPosition_Timer;
	g_iJockeyVictim = -1;

	#if debug
		CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Jockey ride ended.");
	#endif
}

public Action Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{

	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		g_iJockeyVictim = victim;

		if (g_hJockeyRideCheck_Timer == null)
		{
			g_hJockeyRideCheck_Timer = CreateTimer(VICTIM_CHECK_INTERVAL, JockeyRideCheck_Timer, victim, TIMER_REPEAT);

			#if debug
				CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Jockey Ride Check Timer set.");
			#endif
		}
		if (g_hSaveVictimPosition_Timer == null)
		{
			g_hSaveVictimPosition_Timer = CreateTimer(VICTIM_SAVE_INTERVAL, SaveVictimPosition_Timer, victim, TIMER_REPEAT);

			#if debug
				CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Victim Save Position Timer set.");
			#endif
		}
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{

	static int client;
	client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (client != 0) {
		if (client == g_iJockeyVictim) {
			g_iJockeyVictim = -1;
			delete g_hJockeyRideCheck_Timer;
			delete g_hSaveVictimPosition_Timer;
		}
	}
}

public void Event_PlayerDisconnect(Event hEvent, const char[] name, bool dontBroadcast)
{

	static int client;
	client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (client != 0) {
		if (client == g_iJockeyVictim) {
			g_iJockeyVictim = -1;
			delete g_hJockeyRideCheck_Timer;
			delete g_hSaveVictimPosition_Timer;
		}
	}
}

public Action SaveVictimPosition_Timer(Handle timer, any victim)
{
	static float prevVictimPos[3];
	static bool isOutsideWorld;

	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		GetClientAbsOrigin(victim, prevVictimPos);
		isOutsideWorld = TR_PointOutsideWorld(prevVictimPos);

		if ( !isOutsideWorld )
		{
			g_fVictimPrevPos = prevVictimPos;

			#if debug
				CPrintToChatAll("{blue}[Jockey UnTeleport]{default} victim position saved.");
			#endif
		}
	}
	return Plugin_Continue;
}

public Action JockeyRideCheck_Timer(Handle timer, any victim)
{
	static float newVictimPos[3];
	static bool isOutsideWorld;

	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		GetClientAbsOrigin(victim, newVictimPos);
		isOutsideWorld = TR_PointOutsideWorld(newVictimPos);

		if ( isOutsideWorld )
		{
			CPrintToChatAll("[{green}!{default}] {olive}Jockey {default}teleported {green}survivor{default}. Moving {green}survivor {default}back to previous position.");
			TeleportToPrevPos(victim);
		}
	}
	return Plugin_Continue;
}

void TeleportToPrevPos(int victim)
{
	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		TeleportEntity(victim, g_fVictimPrevPos, NULL_VECTOR, NULL_VECTOR);

		#if debug
			CPrintToChatAll("{blue}[Jockey UnTeleport]{default} trying to teleport survivor.");
		#endif
	}
}
