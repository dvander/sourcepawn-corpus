#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#pragma newdecls required

ConVar g_hScareTauntFixEnabled;
#define TF_STUNFLAG_GHOSTEFFECT     (1 << 7)	// ghost particles
#define PLUGIN_VERSION "1.0"
public Plugin myinfo =
{
	name = "No Taunt Scare",
	author = "TonyBaretta",
	description = "No Taunt Scare",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
}
bool g_bscare[MAXPLAYERS+1] = false;

public void OnPluginStart()
{
	g_hScareTauntFixEnabled = CreateConVar("tf_fix_scare_taunt", "1", "Enables/disables scare taunt fix", FCVAR_NONE, true, 0.0, true, 1.0);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	AddCommandListener(BlockTaunt, "taunt");
	CreateConVar("notauntscare_version", PLUGIN_VERSION, "no taunt scare version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	g_bscare[userid] = false;
}
public Action BlockTaunt(int client, const char[] command, int args)
{
	if(g_hScareTauntFixEnabled.IntValue){
		if(g_bscare[client])
		{
			return Plugin_Handled;
		}
		else
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(g_hScareTauntFixEnabled.IntValue){
		if(condition == TFCond_Dazed)
		{
			g_bscare[client] = true;
			//CreateTimer(5.0, unlocktaunt, client);
		}
	}
}
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(g_hScareTauntFixEnabled.IntValue){
		if(condition == TFCond_Dazed)
		{
			g_bscare[client] = false;
		}
	}
}
stock bool IsValidClient(int iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}