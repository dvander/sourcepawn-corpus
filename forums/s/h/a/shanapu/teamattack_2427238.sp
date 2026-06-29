//includes
#include <sourcemod>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Teamattack message",
	author = "shanapu",
	description = "Teamattack message to admin",
	version = "1.0",
	url = "shanapu.de"
};

public void OnPluginStart() 
{
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
}

public Action PlayerHurt(Handle event, char [] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int dhealth = GetEventInt(event, "dmg_health");
	char wname[64];
	GetEventString(event, "weapon", wname, sizeof(wname));
	
	if(GetClientTeam(victim) ==  GetClientTeam(attacker))
	{
		for(int i = 1; i <= MaxClients; i++) if (CheckCommandAccess(i, "sm_map", ADMFLAG_CHANGEMAP, true)) PrintToChat(i, "TEAMATTACK! victim: %N attacker: %N damage: %i HP",victim, attacker, dhealth);
	}
	return Plugin_Handled;
}