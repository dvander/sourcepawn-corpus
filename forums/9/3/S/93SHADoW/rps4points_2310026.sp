/*
    ____  ____  _____    __ __     ____        _       __      
   / __ \/ __ \/ ___/   / // /    / __ \____  (_)___  / /______
  / /_/ / /_/ /\__ \   / // /_   / /_/ / __ \/ / __ \/ __/ ___/
 / _, _/ ____/___/ /  /__  __/  / ____/ /_/ / / / / / /_(__  ) 
/_/ |_/_/    /____/     /_/    /_/    \____/_/_/ /_/\__/____/  
	A new way to earn queue points in Freak Fortress 2
					by SHADoW NiNE TR3S
					
					HOW IT WORKS:
				RPS a teammate or a minion.
	Whoever wins earns a certain amount of queue points
	while the loser loses these specified queue points
	
				ADJUSTING PRIZE QUEUE POINTS:
	Set "rps4points_points" to a value higher than 0 to enable.
	This amount gets added to the winner and subtracted from
	the loser, as long as the winner/loser is not a current boss.
	
					   OPTIONAL:
	If you want to slay a boss that loses on RPS, set cvar
	"rps4points_slay_boss" to 1. Kill will be credited to
	the RPS winner.
	
	If you want updater support to receive the latest updates
	and have updater installed, set "rps4points_updater" to 1
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <freak_fortress_2>
#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#if SOURCEMOD_V_MINOR > 7
	#pragma newdecls required
#endif

// Version Number
#define MAJOR_REVISION "1"
#define MINOR_REVISION "1"
//#define PATCH_REVISION "0"

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

public Plugin myinfo = {
	name = "Freak Fortress 2: RPS4Points",
	author = "SHADoW NiNE TR3S",
	description="Gamble for FF2 queue points using Rock, Paper, Scissors taunt",
	version=PLUGIN_VERSION,
};


#if defined _updater_included
#define UPDATE_URL "http://www.shadow93.net/sm/rps4points/update.txt"
#endif

int RPSWinner;
bool RPSLoser[MAXPLAYERS+1]=false;
Handle cvarRPSQueuePoints;
Handle cvarUpdater;
Handle cvarKillBoss;

public void OnPluginStart()
{	
	CreateConVar("rps4points_version", PLUGIN_VERSION, "RPS4Points Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarKillBoss=CreateConVar("rps4points_slay_boss", "0", "0-Don't slay boss if boss loses on RPS, 1-Slay boss if boss loses on RPS", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarUpdater=CreateConVar("rps4points_updater", "0", "0-Disable Updater support, 1-Enable automatic updating (requires Updater)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRPSQueuePoints=CreateConVar("rps4points_points", "10", "Points awarded / removed on RPS result", FCVAR_PLUGIN);

	HookEvent("rps_taunt_event", Event_RPSTaunt);

	LoadTranslations("rps4points.phrases");
	
	HookConVarChange(cvarUpdater, CvarChange);
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _updater_included
	if (StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _updater_included
	if(StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_RemovePlugin();
	}
	#endif
}

public void OnConfigsExecuted()
{
	#if defined _updater_included
	if (LibraryExists("updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

stock bool IsValidClient(int client)
{
	if (client<=0 || client>MaxClients)
		return false;
		
	return IsClientInGame(client);
}

stock bool IsBoss(int client)
{
	if(FF2_GetBossIndex(client)==-1) return false;
	return true;
}

public void Event_RPSTaunt(Event event, const char[] name, bool dontBroadcast)
{
	new winner = GetEventInt(event, "winner");
	new loser = GetEventInt(event, "loser");
	
	// Make sure winner or loser are valid
	if(!IsValidClient(winner) || !IsValidClient(loser)) 
	{
		return;
	}

	// If boss slay cvar is enabled, slay boss if they lose on RPS.
	if(!IsBoss(winner) && IsBoss(loser) && GetConVarBool(cvarKillBoss))
	{
		RPSWinner=winner;
		RPSLoser[loser]=true;
		CreateTimer(3.1, DelayRPSDeath, loser);
		return;
	}
	
	// If both parties are non-bosses, they can RPS for queue points
	if(!IsBoss(winner) && !IsBoss(loser) && FF2_GetQueuePoints(loser)>=GetConVarInt(cvarRPSQueuePoints) && GetConVarInt(cvarRPSQueuePoints)>0)
	{		
		CPrintToChat(winner, "{olive}[FF2]{default} %t", "rps_won", GetConVarInt(cvarRPSQueuePoints), loser);
		FF2_SetQueuePoints(winner, FF2_GetQueuePoints(winner)+GetConVarInt(cvarRPSQueuePoints));
	
		CPrintToChat(loser, "{olive}[FF2]{default} %t", "rps_lost", GetConVarInt(cvarRPSQueuePoints), winner);
		FF2_SetQueuePoints(loser, FF2_GetQueuePoints(loser)-GetConVarInt(cvarRPSQueuePoints));
	}
}

public Action DelayRPSDeath(Handle timer, any client)
{
	if(IsValidClient(client))
	{
		new boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float(FF2_GetBossHealth(boss)), DMG_GENERIC, -1);
		}
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarUpdater)
	{
		#if defined _updater_included
		GetConVarInt(cvarUpdater) ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
		#endif
	}
}

