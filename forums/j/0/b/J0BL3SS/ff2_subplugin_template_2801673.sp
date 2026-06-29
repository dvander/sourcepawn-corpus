#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: My Stock Subplugin"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"It's a template ff2 subplugin"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 *	Defines "test_ability"
 */
#define TEST_STRING "test_ability"		// I do not suggest using AMS
bool AMS_TEST[MAXPLAYERARRAY];


public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]!=1 || version[1]<11)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");

	FF2_GetForkVersion(version);
	if(version[0]!=1 || version[1]<19)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_active", Event_RoundStart, EventHookMode_PostNoCopy); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy); // for non-arena maps
	
	HookEvent("player_spawn", Event_PlayerSpawn);									// for late-spawn bosses
	HookEvent("post_inventory_application", Event_PlayerInventoryApplication);		// for late-spawn bosses
	
	if(FF2_GetRoundState() == 1)	// In case the plugin is loaded in late
		Event_RoundStart(view_as<Event>(INVALID_HANDLE), "plugin_lateload", false);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)	
{
	CreateTimer(0.3, Timer_PrepareHooks, _, TIMER_FLAG_NO_MAPCHANGE);	// Delayed Hooks
}

public Action Timer_PrepareHooks(Handle timer)
{
	ClearEverything();	// Clear previous variables twice
	MainBoss_PrepareAbilities(); //Now hook the abilities for the boss(s)
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	
	if(IsValidClient(GetClientOfUserId(UserIdx)))
	{
		CreateTimer(0.3, LateBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);	// Check if player is a boss
	}
	else
	{
		FF2_LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public void Event_PlayerInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetEventInt(event, "userid");
	if(IsValidClient(iClient))
	{
		CreateTimer(0.3, LateBoss_PrepareAbilities, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);	// Check if player is a boss
	}
	else
	{
		FF2_LogError("ERROR: Invalid client index. %s:Event_PlayerInventoryApplication()", this_plugin_name);
	}
}

public Action LateBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;

	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)	// If player has boss index, most likely late-spawned
		{
			HookAbilities(bossIdx, bossClientIdx);	// Hook the abilities
		}
	}
	else
	{
		FF2_LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}

public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		FF2_LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();	// Clear previous variables
}

public void ClearEverything()
{	
	for(int i = 1; i<= MaxClients; i++)
	{
		AMS_TEST[i] = false;
	}
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, TEST_STRING))
		{
			//AMS Triggers
			AMS_TEST[bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, TEST_STRING);
			if(AMS_TEST[bossClientIdx])
			{
				AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, TEST_STRING, "TEST");
			}
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	if(!strcmp(ability_name, TEST_STRING))
	{
		if(AMS_TEST[bossClientIdx])
		{
			if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))	// some servers still use .ff2 file extension, if you use .smx, change it otherwise.
			{
				AMS_TEST[bossClientIdx] = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		if(!AMS_TEST[bossClientIdx])
		{
			TEST_Invoke(bossClientIdx);	
		}	
	}
	return Plugin_Continue;
}

public bool TEST_CanInvoke(int bossClientIdx)
{
	return true;
}

public void TEST_Invoke(int bossClientIdx)
{
	FF2_EmitRandomSound(bossClientIdx, "sound_myability");
	
	
	// Do things
	
	
}

stock bool IsInvuln(int client)
{
	//Borrowed from Batfoxkid
	if(!IsValidClient(client))	
		return true;
	
	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	//Borrowed from Batfoxkid
	
	if(client <= 0 || client > MaxClients)
		return false;

	if(!IsClientInGame(client) || !IsClientConnected(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

public void FF2_EmitRandomSound(int bossClientIdx, const char[] keyvalue)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	char sound[PLATFORM_MAX_PATH];
	if(FF2_RandomSound(keyvalue, sound, sizeof(sound), bossIdx))
	{
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
	}
}