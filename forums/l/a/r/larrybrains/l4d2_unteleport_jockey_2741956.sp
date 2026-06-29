#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <left4dhooks>

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
new Handle:hDisableJockeyUnteleportMaps;

int g_iJockeyVictim;
int g_iJockey;
float g_fVictimPrevPos[3];
float g_fMapCenter[3];
bool g_bIsEnabled;

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

	hDisableJockeyUnteleportMaps = CreateTrie();

	RegServerCmd("jockey_unteleport_disabled", DisableJockeyUnteleport);

}

public Action:DisableJockeyUnteleport(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hDisableJockeyUnteleportMaps, mapname, true);
}

public void OnMapStart()
{
	g_hJockeyRideCheck_Timer = null;
	g_hSaveVictimPosition_Timer = null;

	g_fMapCenter[0] = 0.0;
	g_fMapCenter[1] = 0.0;
	g_fMapCenter[2] = 0.0;

	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));

	decl dummy;
	if (GetTrieValue(hDisableJockeyUnteleportMaps, mapname, dummy))
	{
		g_bIsEnabled = false;

		#if debug
			CPrintToChatAll("{blue}[Jockey UnTeleport]{default} is disabled.");
		#endif

	}
	else
	{
		g_bIsEnabled = true;

		#if debug
			CPrintToChatAll("{blue}[Jockey UnTeleport]{default} is enabled.");
		#endif

	}
}

public Action Event_JockeyDeath(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	if (!g_bIsEnabled)
		return Plugin_Handled;

	delete g_hJockeyRideCheck_Timer;
	delete g_hSaveVictimPosition_Timer;
	g_iJockeyVictim = -1;
	g_iJockey = -1;
	#if debug
		CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Jockey killed.");
	#endif

	return Plugin_Continue;
}

public Action Event_JockeyRideEnd(Event hEvent, const char[] s_Name, bool b_DontBroadcast)
{
	if (!g_bIsEnabled)
		return Plugin_Handled;

	delete g_hJockeyRideCheck_Timer;
	delete g_hSaveVictimPosition_Timer;
	g_iJockeyVictim = -1;
	g_iJockey = -1;

	#if debug
		CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Jockey ride ended.");
	#endif

	return Plugin_Continue;
}

public Action Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsEnabled)
		return Plugin_Handled;

	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	static float startVictimPos[3];

	if (IsClientInGame(jockey))
	{
		if (IsPlayerAlive(jockey))
		{
			g_iJockey = jockey;
		}
	}

	if (IsClientInGame(victim))
	{
		if (IsPlayerAlive(victim))
		{

			GetClientAbsOrigin(victim, startVictimPos);
			g_fVictimPrevPos = startVictimPos;

			#if debug
				CPrintToChatAll("{blue}[Jockey UnTeleport]{default} initial victim position saved. Origin: %.1f, %.1f, %.1f", g_fVictimPrevPos[0], g_fVictimPrevPos[1], g_fVictimPrevPos[2] );
			#endif

			g_iJockeyVictim = victim;

			if (g_hJockeyRideCheck_Timer == null)
			{
				g_hJockeyRideCheck_Timer = CreateTimer(VICTIM_CHECK_INTERVAL, JockeyRideCheck_Timer, victim, TIMER_REPEAT);
			}
			if (g_hSaveVictimPosition_Timer == null)
			{
				g_hSaveVictimPosition_Timer = CreateTimer(VICTIM_SAVE_INTERVAL, SaveVictimPosition_Timer, victim, TIMER_REPEAT);
			}
		}
	}
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (!g_bIsEnabled)
		return;

	static int client;
	client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (client != 0) {
		if (client == g_iJockeyVictim || client == g_iJockey) {
			g_iJockeyVictim = -1;
			g_iJockey = -1;
			delete g_hJockeyRideCheck_Timer;
			delete g_hSaveVictimPosition_Timer;
		}
	}
}

public void Event_PlayerDisconnect(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (!g_bIsEnabled)
		return;

	static int client;
	client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (client != 0) {
		if (client == g_iJockeyVictim || client == g_iJockey ) {
			g_iJockeyVictim = -1;
			g_iJockey = -1;
			delete g_hJockeyRideCheck_Timer;
			delete g_hSaveVictimPosition_Timer;
		}
	}
}

public Action SaveVictimPosition_Timer(Handle timer, any victim)
{
	if (!g_bIsEnabled)
		return Plugin_Stop;

	static float prevVictimPos[3];
	static bool isOutsideWorld;
	if (IsClientInGame(victim))
	{
		if (IsPlayerAlive(victim))
		{
			GetClientAbsOrigin(victim, prevVictimPos);
			isOutsideWorld = TR_PointOutsideWorld(prevVictimPos);
			float distanceToCenter = GetVectorDistance(prevVictimPos, g_fMapCenter);

			if ( !isOutsideWorld && distanceToCenter >= 150)
			{
				g_fVictimPrevPos = prevVictimPos;

				#if debug
					CPrintToChatAll("{blue}[Jockey UnTeleport]{default} victim position saved. Origin: %.1f, %.1f, %.1f", g_fVictimPrevPos[0], g_fVictimPrevPos[1], g_fVictimPrevPos[2] );
				#endif
			}
		}
	}
	return Plugin_Continue;
}

public Action JockeyRideCheck_Timer(Handle timer, any victim)
{
	if (!g_bIsEnabled)
		return Plugin_Stop;

	static float newVictimPos[3];
	static bool isOutsideWorld;
	if(IsClientInGame(victim))
	{
		if (IsPlayerAlive(victim))
		{
			GetClientAbsOrigin(victim, newVictimPos);
			isOutsideWorld = TR_PointOutsideWorld(newVictimPos);
			float distance = GetVectorDistance(newVictimPos, g_fVictimPrevPos);
			float distanceToCenter = GetVectorDistance(newVictimPos, g_fMapCenter);

			if ( isOutsideWorld || distance >= 750 || distanceToCenter < 150 )
			{
				TeleportToPrevPos(victim);

				#if debug
					CPrintToChatAll("{blue}[Jockey UnTeleport]{default} Player %N teleported by Jockey %N, origin: %.1f, %.1f, %.1f distance: %.1f distance to center: %.1f world:(%s)", victim, g_iJockey, newVictimPos[0], newVictimPos[1], newVictimPos[2], distance, distanceToCenter, isOutsideWorld ? "OutsideWorld" : "InsideWorld");
				#endif

				CPrintToChatAll("[{green}!{default}] Jockey ({olive}%N{default}) teleported survivor ({green}%N{default}). Moving {green}survivor {default}back to previous position.", g_iJockey, victim);
				LogAction(-1, -1, "[Jockey UnTeleport] Player %N teleported by Jockey %N, origin: %.1f, %.1f, %.1f distance: %.1f distance to center: %.1f world:(%s)", victim, g_iJockey, newVictimPos[0], newVictimPos[1], newVictimPos[2], distance, distanceToCenter, isOutsideWorld ? "OutsideWorld" : "InsideWorld");


			}
		}
	}
	return Plugin_Continue;
}

void TeleportToPrevPos(int victim)
{
	if(IsClientInGame(victim))
	{
		if (IsPlayerAlive(victim))
		{
			TeleportEntity(victim, g_fVictimPrevPos, NULL_VECTOR, NULL_VECTOR);

			#if debug
				CPrintToChatAll("{blue}[Jockey UnTeleport]{default} trying to teleport survivor.");
			#endif
		}
	}
}
