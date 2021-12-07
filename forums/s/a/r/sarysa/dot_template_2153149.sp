#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <drain_over_time>
#include <drain_over_time_subplugin>

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

new RoundInProgress = false;

#define DE_STRING "dot_example"
new bool:DE_CanUse[MAX_PLAYERS_ARRAY]; // internal
new DE_Product[MAX_PLAYERS_ARRAY]; // internal
new DE_SomeNumber[MAX_PLAYERS_ARRAY]; // arg1

public Plugin:myinfo = {
	name = "Freak Fortress 2: DOT Template",
	author = "sarysa",
	version = "1.0.0",
}

/**
 * METHODS REQUIRED BY ff2 subplugin
 */
public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

// this method required, but is not used by DOTs at all. Only use if you have DOTs and non-DOTs in the same file.
public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status) { return Plugin_Continue; }

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("DOTtest: Event_RoundStart()");
		
	// NOTE: For DOTs, only basic inits go here. The real init happens on a time delay shortly after.
	// It is recommended you don't load anything related to DOTs until then.
	RoundInProgress = true;
	
	// initialize each DOT's array
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		DE_CanUse[i] = false;
		DE_Product[i] = 0;
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// round has ended, this'll kill the looping timer
	RoundInProgress = false;
	
	// cleanup
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		DE_CanUse[i] = false;
		DE_Product[i] = 0;
	}
}

/**
 * METHODS REQUIRED BY dot subplugin
 */
DOTPostRoundStartInit()
{
	if (!RoundInProgress)
	{
		PrintToServer("DOTPostRoundStartInit() called when the round is over?! Shouldn't be possible!");
		return;
	}
	
	for (new bossClientIdx = 1; bossClientIdx < MAX_PLAYERS; bossClientIdx++)
	{
		new bossIdx = FF2_GetBossIndex(bossClientIdx);
		if (bossIdx < 0)
			continue; // this may seem weird, but rages often break on duo bosses if the leader suicides. these DOTs can be an exception. :D
			
		// example
		DE_CanUse[bossClientIdx] = FF2_HasAbility(bossIdx, this_plugin_name, DE_STRING);
		if (DE_CanUse[bossClientIdx])
		{
			DE_SomeNumber[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, DE_STRING, 1);
			PrintToServer("Boss will use example DOT. Probably don't want to see this printout on a live boss.");
		}
	}
}

OnDOTAbilityActivated(bossClientIdx)
{
	if (DE_CanUse[bossClientIdx])
	{
		DE_Product[bossClientIdx] = DE_SomeNumber[bossClientIdx];
		PrintToServer("DOT example activated. Product is now %d", DE_Product[bossClientIdx]);
	}
}

OnDOTAbilityDeactivated(bossClientIdx)
{
	if (DE_CanUse[bossClientIdx])
	{
		DE_Product[bossClientIdx] = 0;
		PrintToServer("DOT example deactivated. Product is now %d", DE_Product[bossClientIdx]);
	}
}

OnDOTUserDeath(bossClientIdx, isInGame)
{
	DE_Product[bossClientIdx] = 0;
	PrintToServer("Boss died. Cleaning up product: %d", DE_Product[bossClientIdx]);
}

OnDOTAbilityTick(bossClientIdx, tickCount)
{
	if (DE_CanUse[bossClientIdx] && tickCount % 3 == 0)
	{
		DE_Product[bossClientIdx] *= DE_SomeNumber[bossClientIdx];
		PrintToServer("DOT example every third tick. Product is now %d", DE_Product[bossClientIdx]);
	}
}
