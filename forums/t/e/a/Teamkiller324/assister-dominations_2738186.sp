#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.4"

#pragma semicolon 1
#pragma newdecls required

/*
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
	*/
char g_ClassNames[][16] = { "Unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

public Plugin myinfo = 
{
	name = "Assister Domination Quotes",
	author = "Powerlord",
	description = "Play domination and revenge lines when an assister gets a domination or revenge",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=215449"
}

ConVar g_Cvar_Enabled;

public void OnPluginStart()
{
	CreateConVar("assisterdomination_version", VERSION, "Assister Domination Quotes version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Cvar_Enabled = CreateConVar("assisterdomination_enabled", "1", "Enabled Assister Domination Quotes?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookEvent("player_death", Event_PlayerDeath);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_Cvar_Enabled.BoolValue)
		return;
	
	int deathflags = event.GetInt("death_flags");
	bool silentKill = event.GetBool("silent_kill");
	
	if(silentKill || dontBroadcast || deathflags & TF_DEATHFLAG_DEADRINGER)
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
//	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	
	if(victim < 1 || victim > MaxClients || !CheckAttacker(assister))
		return;

	TFClassType victimClass = TF2_GetPlayerClass(victim);
	
	if(deathflags & TF_DEATHFLAG_ASSISTERDOMINATION)
		PlayDominationSound(assister, victimClass, false);
	else if(deathflags & TF_DEATHFLAG_ASSISTERREVENGE)
		PlayDominationSound(assister, victimClass, true);
}

bool CheckAttacker(int client)
{
	if(!IsClientInGame(client))
		return false;
	if(client < 1 || client > MaxClients)
		return false;
	if(!IsPlayerAlive(client))
		return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return false;
	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
		return false;	
	if(TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
		return false;
	return true;
}

void PlayDominationSound(int client, TFClassType victimClass, bool revenge=false)
{
	switch(revenge)
	{
		case true:	SetVariantString("domination:revenge");
		case false:	SetVariantString("domination:dominated");
	}
	
	AcceptEntityInput(client, "AddContext");

	char victimClassContext[64];
	Format(victimClassContext, sizeof(victimClassContext), "victimclass:%s", g_ClassNames[victimClass]);
	
	SetVariantString(victimClassContext);
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("TLK_KILLED_PLAYER");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	AcceptEntityInput(client, "ClearContext");
}