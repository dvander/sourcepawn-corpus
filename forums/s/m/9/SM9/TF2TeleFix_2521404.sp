#pragma semicolon 1

#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "TF2 Tele Fix",
	author = "SM9();",
	description = "Prevent Team or Class changes during Teleportation.",
	version = "0.2"
};

public void OnPluginStart()
{
	AddCommandListener(Command_Listener, "jointeam");
	AddCommandListener(Command_Listener, "joinclass");
	AddCommandListener(Command_Listener, "join_class");
	AddCommandListener(Command_Listener, "autoteam");
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public Action Command_Listener(int iClient, const char[] szComman, int iArgs)
{
	if(!IsValidClient(iClient)) {
		return Plugin_Handled;
	}
	
	if(!TF2_IsPlayerInCondition(iClient, TFCond_Teleporting)) {
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Event evEvent, char[] chEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(evEvent.GetInt("userid"));
	
	if(!IsValidClient(iClient)) {
		return Plugin_Handled;
	}
	
	if(!TF2_IsPlayerInCondition(iClient, TFCond_Teleporting)) {
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

stock bool IsValidClient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients) {
		return false;
	}
	
	if (!IsClientInGame(iClient)) {
		return false;
	}
	
	return true;
}