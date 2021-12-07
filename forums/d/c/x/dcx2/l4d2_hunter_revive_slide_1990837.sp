#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

// Plugin fields used in multiple places
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "dcx2"
#define PLUGIN_NAME "L4D2 Hunter Revive Slide"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY


// %1 = victim, [%2 = attacker]
#define SET_HUNTER_ATTACKER(%1,%2)  SetEntPropEnt(%1, Prop_Send, "m_pounceAttacker", %2)
#define GET_HUNTER_ATTACKER(%1) 	(GetEntPropEnt(%1, Prop_Send, "m_pounceAttacker"))

// %1 = attacker, %2 = victim
#define SET_HUNTER_VICTIM(%1,%2)  SetEntPropEnt(%1, Prop_Send, "m_pounceVictim", %2)


// %1 = client
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define IS_PLAYER_INCAPACITATED(%1) (GetEntProp(%1, Prop_Send, "m_isIncapacitated", 1))


static g_ReviveOwners[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Hunters who land on incapacitated Survivors can slide off onto anyone reviving the Survivor",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=220804"
};

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{
	// Require Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		Format(error, err_max, "Plugin only supports Left4Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	
	CreateConVar("l4d2_revive_slide_ver", PLUGIN_VERSION, "Version of the Hunter Revive Slide plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
//	LoadTranslations("common.phrases");

	HookEvent("revive_begin", Event_ReviveBegin, EventHookMode_Pre);
	HookEvent("revive_end", Event_ReviveEnd, EventHookMode_Pre);
	HookEvent("revive_success", Event_ReviveEnd, EventHookMode_Pre);
	HookEvent("lunge_pounce", Event_LungePounce, EventHookMode_Pre);
}

public Action:Event_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ReviveOwner = GetClientOfUserId(GetEventInt(event, "userid"));
	new ReviveTarget = GetClientOfUserId(GetEventInt(event, "subject"));

	g_ReviveOwners[ReviveTarget] = ReviveOwner;
//	PrintToChatAll("%N reviving %N", ReviveOwner, ReviveTarget);
}

public Action:Event_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
//	new ReviveOwner = GetClientOfUserId(GetEventInt(event, "userid"));
	new ReviveTarget = GetClientOfUserId(GetEventInt(event, "subject"));

	g_ReviveOwners[ReviveTarget] = 0;
//	PrintToChatAll("%N reviving %N", ReviveOwner, ReviveTarget);
}



public Action:Event_LungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
//	new distance = GetEventInt(event, "distance");
	
//	if (GetConVarBool(g_cvarDebug))		PrintToChatAll("[LungePounce] attacker: %N victim: %N distance: %d", attacker, victim, distance);

	//PrintToChat(attacker, "[LungePounce] attacker: %N victim: %N distance: %d", attacker, victim, distance);
	
	if (IS_PLAYER_INCAPACITATED(victim))
	{
//		PrintToChat(attacker, "Victim %N is down, ReviveOwner %d", victim, g_ReviveOwners[victim]);

		new client = g_ReviveOwners[victim];
		if (IS_SURVIVOR_ALIVE(client))
		{
			CreateTimer(0.1, HunterPinSwap, victim);
			PrintToChat(attacker, "Hunter Revive Slide from %N to %N", victim, client);
		}
	}

	return Plugin_Continue;
}

public Action:HunterPinSwap(Handle:timer, any:victim)
{
	new reviver = g_ReviveOwners[victim];
	g_ReviveOwners[victim] = 0;
	new attacker = GET_HUNTER_ATTACKER(victim);
	if (IS_SURVIVOR_ALIVE(victim) && IS_SURVIVOR_ALIVE(reviver) && IS_INFECTED_ALIVE(attacker))
	{
		// they were being revived
		// leave the incapped guy alone and go for his rescuer
		SET_HUNTER_ATTACKER(victim, -1);
		SET_HUNTER_VICTIM(attacker, reviver);
		SET_HUNTER_ATTACKER(reviver, attacker);
		L4D2Direct_DoAnimationEvent(reviver, 86);
	}
}
