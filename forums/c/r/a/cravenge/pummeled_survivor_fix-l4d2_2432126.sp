#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.31"

bool bSmoked[MAXPLAYERS+1];
float fLastPos[MAXPLAYERS+1][3];

public Plugin myinfo = 
{
	name = "[L4D2] Pummeled Survivor Fix",
	author = "cravenge",
	description = "Fixes Issues Where Survivors Are Suddenly Pummeled.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	CreateConVar("pummeled_survivor_fix-l4d2_version", PLUGIN_VERSION, "Pummeled Survivor Fix Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("finale_win", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("tongue_grab", OnTongueGrab);
	HookEvent("tongue_release", OnTongueRelease);
	
	AddNormalSoundHook(OnPummelSoundFix);
	
	CreateTimer(0.1, SaveClientPosition, _, TIMER_REPEAT);
	CreateTimer(1.0, CheckForPummelBugs, _, TIMER_REPEAT);
}

public Action OnPummelSoundFix(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrContains(sample, "mortification", false) != -1 && GetEntPropEnt(entity, Prop_Send, "m_pummelAttacker") < 1)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action SaveClientPosition(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if (bSmoked[i] || GetEntProp(i, Prop_Send, "m_pounceAttacker") > 0 || GetEntProp(i, Prop_Send, "m_jockeyAttacker") > 0 || 
				GetEntProp(i, Prop_Send, "m_carryAttacker") > 0 || GetEntProp(i, Prop_Send, "m_pummelAttacker") > 0)
			{
				continue;
			}
			
			float fPos[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos);
			
			fLastPos[i] = fPos;
		}
	}
	
	return Plugin_Continue;
}

public Action CheckForPummelBugs(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			int iPummelVictim = GetEntPropEnt(i, Prop_Send, "m_pummelVictim");
			if (iPummelVictim < 1 || iPummelVictim > MaxClients || !IsClientInGame(iPummelVictim) || GetClientTeam(iPummelVictim) != 2 || !IsPlayerAlive(iPummelVictim))
			{
				continue;
			}
			
			if (GetEntProp(i, Prop_Send, "m_zombieClass") < 6 || (GetEntProp(i, Prop_Send, "m_zombieClass") == 6 && GetEntProp(i, Prop_Send, "m_isGhost", 1)) || GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
			{
				if (GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
				{
					ForcePlayerSuicide(i);
					PrintToChatAll("\x04[FIX]\x01 Slayed \x03%N\x01 For Having \x05Pummeled Survivor Bug\x01!", i);
				}
				else
				{
					PrintToChatAll("\x04[FIX]\x01 Prevented \x03%N\x01 From Bugging \x03%N\x01!", iPummelVictim, i);
				}
				
				Event eChargerPummelEnd = CreateEvent("charger_pummel_end", true);
				eChargerPummelEnd.SetInt("userid", GetClientUserId(i));
				eChargerPummelEnd.SetInt("victim", GetClientUserId(iPummelVictim));
				eChargerPummelEnd.Fire();
				
				TeleportEntity(iPummelVictim, fLastPos[iPummelVictim], NULL_VECTOR, NULL_VECTOR);
				
				SetEntPropEnt(i, Prop_Send, "m_pummelVictim", -1);
				SetEntPropEnt(iPummelVictim, Prop_Send, "m_pummelAttacker", -1);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	UnhookEvent("round_start", OnRoundEvents);
	UnhookEvent("round_end", OnRoundEvents);
	UnhookEvent("finale_win", OnRoundEvents);
	UnhookEvent("mission_lost", OnRoundEvents);
	UnhookEvent("map_transition", OnRoundEvents);
	
	UnhookEvent("tongue_grab", OnTongueGrab);
	UnhookEvent("tongue_release", OnTongueRelease);
	
	RemoveNormalSoundHook(OnPummelSoundFix);
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			bSmoked[i] = false;
		}
	}
}

public void OnTongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int grabbed = GetClientOfUserId(event.GetInt("victim"));
	if (grabbed < 1 || grabbed > MaxClients || !IsClientInGame(grabbed) || GetClientTeam(grabbed) != 2 || bSmoked[grabbed])
	{
		return;
	}
	
	bSmoked[grabbed] = true;
}

public void OnTongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int released = GetClientOfUserId(event.GetInt("victim"));
	if (released < 1 || released > MaxClients || !IsClientInGame(released) || GetClientTeam(released) != 2 || bSmoked[released])
	{
		return;
	}
	
	bSmoked[released] = false;
}


