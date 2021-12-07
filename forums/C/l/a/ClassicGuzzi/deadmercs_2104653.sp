#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.2"

#define EVERYONE 0			//Every player
#define SAME_TEAM 1			//Every player in the same team
#define WITH_VOICE_LINES 2	//Every player in the same team AND with mvm voice lines
#define WITH_VOICE_LINES_NH 3	//Every player in the same team AND with mvm voice lines, not heavy

new Handle:g_Cvar_Enabled;
new Handle:g_Cvar_MaxDist;
new Handle:g_Cvar_MinTime;
new bool:g_canTalk = true;

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
	name = "Class is dead voice systeam",
	author = "Classic",
	description = "Play class-is-dead lines from mvm when someone dies",
	version = VERSION,
	url = ""
}


public OnPluginStart()
{
	CreateConVar("cid_version", VERSION, "Class-is-dead version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("cid_enabled", "1", "Enabled Class is dead voices", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_MaxDist = CreateConVar("cid_maxdist", "10000.0", "Max distance to seach for players", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 10.0 );
	g_Cvar_MinTime = CreateConVar("cid_mintime", "10.0" ,"Min time (secs) that must wait the plugin to respond at new deaths", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0)
	HookEvent("player_death", Event_PlayerDeath);

}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_Enabled) || !g_canTalk)
	{
		return;
	}
	
	new deathflags = GetEventInt(event, "death_flags");
	new bool:silentKill = GetEventBool(event, "silent_kill");
	
	if (silentKill || dontBroadcast)
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim < 1 || victim > MaxClients )
	{
		return;
	}

	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	new nearPlayer 
	if(victimClass == TFClass_Soldier)
	{
		nearPlayer = FindNearestPlayer(victim, WITH_VOICE_LINES);
	}
	else
	{
		nearPlayer = FindNearestPlayer(victim, WITH_VOICE_LINES);
	}
	nearPlayer = FindNearestPlayer(victim, WITH_VOICE_LINES);
	if(nearPlayer != -1 && CheckClient(nearPlayer))
	{
		PlayClassDead(nearPlayer,victimClass);
		new Float:secs = GetConVarFloat(g_Cvar_MinTime);
		if(secs > 0)
		{
			g_canTalk = false;
			CreateTimer(secs, Timer_Wait);
		}
	}
}

public Action:Timer_Wait(Handle:timer)
{
	g_canTalk = true;
}

FindNearestPlayer(client,const type)
{
	new Float:pVec[3];
	new Float:nVec[3];
	GetClientEyePosition(client, pVec); 
	new found = -1;
	new Float:found_dist = GetConVarFloat(g_Cvar_MaxDist);
	new Float:aux_dist; 
	
	switch(type)
	{
		case EVERYONE:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		
		case SAME_TEAM:
		{
			new pTeam = GetClientTeam(client);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i) && pTeam == GetClientTeam(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		case WITH_VOICE_LINES:
		{
			new pTeam = GetClientTeam(client);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i) && pTeam == GetClientTeam(i) && ClientHasVoiceLines(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		case WITH_VOICE_LINES_NH:
		{
			new pTeam = GetClientTeam(client);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i) && pTeam == GetClientTeam(i) && ClientHasVoiceLinesNH(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		
	}
	return found;
}

bool:ClientHasVoiceLines(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Soldier 
	|| TF2_GetPlayerClass(client) == TFClass_Medic 
	|| TF2_GetPlayerClass(client) == TFClass_Heavy 
	|| TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		return true;
	}
	return false;
}
bool:ClientHasVoiceLinesNH(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Soldier 
	|| TF2_GetPlayerClass(client) == TFClass_Medic 
	|| TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		return true;
	}
	return false;
}

PlayClassDead(client,TFClassType:victimClass)
{

	SetVariantString("randomnum:100");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("IsMvMDefender:1");
	AcceptEntityInput(client, "AddContext");
	
	new String:victimClassContext[64];
	Format(victimClassContext, sizeof(victimClassContext), "victimclass:%s", g_ClassNames[victimClass]);

	SetVariantString(victimClassContext);
	AcceptEntityInput(client, "AddContext");

	SetVariantString("TLK_MVM_DEFENDER_DIED");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	AcceptEntityInput(client, "ClearContext");


}

bool:CheckClient(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) ||
	TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || 
	TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
	{
		return false;
	}
	return true;
}
