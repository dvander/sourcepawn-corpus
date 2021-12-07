#pragma semicolon 1

#define PLUGIN_AUTHOR "Tak (chaosxk)"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <tf2>

#pragma newdecls required

ConVar g_cDuration;

int g_iTarget[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2] Taunt Notify",
	author = PLUGIN_AUTHOR,
	description = "Notify player that they have been taunted.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=289757"
};

public void OnPluginStart()
{
	CreateConVar("sm_tn_version", PLUGIN_VERSION, "Taunt Notify Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cDuration = CreateConVar("sm_tn_duration", "3.0", "Duration of how long they can still be notified after their death.");
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientPostAdminCheck(int client)
{
	g_iTarget[client] = 0;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker_userid = event.GetInt("attacker");
	int client_userid = event.GetInt("userid");
	int attacker = GetClientOfUserId(attacker_userid);
	
	g_iTarget[attacker] = client_userid;
	
	CreateTimer(g_cDuration.FloatValue, Timer_Reset, attacker_userid);
}

public Action Timer_Reset(Handle timer, int attacker_userid)
{
	int attacker = GetClientOfUserId(attacker_userid);
	
	if (IsValidClient(attacker))
		g_iTarget[attacker] = 0;
}

public void TF2_OnConditionAdded(int attacker, TFCond condition)
{
	if (condition != TFCond_Taunting)
		return;
		
	if (!g_iTarget[attacker])
		return;
		
	int client = GetClientOfUserId(g_iTarget[attacker]);
	
	if(IsValidClient(client))
	{
		PrintToChat(client, "%N has just taunted you after killing you!", attacker);
	}
}

bool IsValidClient(int client)
{
	return 1 <= client <= MaxClients && IsClientInGame(client);
}