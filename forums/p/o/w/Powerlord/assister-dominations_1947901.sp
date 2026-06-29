#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.3"

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
new String:g_ClassNames[TFClassType][16] = { "Unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

public Plugin:myinfo = 
{
	name = "Assister Domination Quotes",
	author = "Powerlord",
	description = "Play domination and revenge lines when an assister gets a domination or revenge",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=215449"
}

new Handle:g_Cvar_Enabled;

public OnPluginStart()
{
	CreateConVar("assisterdomination_version", VERSION, "Assister Domination Quotes version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_Cvar_Enabled = CreateConVar("assisterdomination_enabled", "1", "Enabled Assister Domination Quotes?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	new deathflags = GetEventInt(event, "death_flags");
	new bool:silentKill = GetEventBool(event, "silent_kill");
	
	if (silentKill || dontBroadcast || deathflags & TF_DEATHFLAG_DEADRINGER)
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
//	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if (victim < 1 || victim > MaxClients || !CheckAttacker(assister))
	{
		return;
	}

	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	
	if (deathflags & TF_DEATHFLAG_ASSISTERDOMINATION)
	{
		PlayDominationSound(assister, victimClass, false);
	}
	else if (deathflags & TF_DEATHFLAG_ASSISTERREVENGE)
	{
		PlayDominationSound(assister, victimClass, true);
	}
}

bool:CheckAttacker(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) ||
	TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || 
	TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
	{
		return false;
	}
	
	return true;
}

PlayDominationSound(client, TFClassType:victimClass, bool:revenge=false)
{
	if (revenge)
	{
		SetVariantString("domination:revenge");
	}
	else
	{
		SetVariantString("domination:dominated");
	}
	
	AcceptEntityInput(client, "AddContext");

	new String:victimClassContext[64];
	Format(victimClassContext, sizeof(victimClassContext), "victimclass:%s", g_ClassNames[victimClass]);
	
	SetVariantString(victimClassContext);
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("TLK_KILLED_PLAYER");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	AcceptEntityInput(client, "ClearContext");
}