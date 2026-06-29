#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 

#pragma semicolon 1
#pragma newdecls required

#define CVAR_FLAGS FCVAR_NOTIFY

#define action_no 0
#define action_stop_pounce 1
#define action_move 2
#define action_attack 3

ConVar g_hCvarEnable;
ConVar g_hCvarIEvilHunterChance;

int HunterVictim[MAXPLAYERS+1];
int HunterAttacker[MAXPLAYERS+1];
float HunterActionTime[MAXPLAYERS+1]; 
float HunterAttackDir[MAXPLAYERS+1][3]; 
int HunterAction[MAXPLAYERS+1];
int HunterTick[MAXPLAYERS+1];
int g_bEnabled;
float g_fCvarIEvilHunterChance;


public Plugin myinfo = 
{
	name 		= "Evil Hunter",
	author 		= "Pan XiaoHai, Edited By Ernecio",
	description = "<- Description ->",
	version 	= "1.7",
	url 		= "<- URL ->"
}

public void OnPluginStart()
{
	g_hCvarEnable 				= CreateConVar("l4d_evil_hunter",			"1", 		"Enables/Disables The Plugin.\n1 = Plugin ON\n0 = Plugin OFF", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarIEvilHunterChance 	= CreateConVar("l4d_evil_hunter_chance", 	"100.0", 	"Chance of change target", CVAR_FLAGS, true, 0.0, true, 150.0);
	
	AutoExecConfig(true, "l4d_evil_hunter");
	
	HookConVarChange(g_hCvarEnable,		ConVarChanged);
	GetCvars();	
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;	
	g_fCvarIEvilHunterChance = g_hCvarIEvilHunterChance.FloatValue;
	
	InitHook();
}

public void OnMapStart()
{
	ResetAllState();
}

void InitHook()
{
	static bool bHooked;

	if (g_bEnabled) 
	{
		if (!bHooked) 
		{
			HookEvent("lunge_pounce",		Event_BlockHunter);
			HookEvent("pounce_end",			Event_BlockEndHunt);
			HookEvent("round_start", 		Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("round_end",			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("finale_win", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("mission_lost", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = true;
		}
	}
	else 
	{
		if (bHooked) 
		{
			UnhookEvent("lunge_pounce",			Event_BlockHunter);
			UnhookEvent("pounce_end",			Event_BlockEndHunt);
			UnhookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("round_end",			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("finale_win", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("mission_lost", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{ 
	ResetAllState();
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
}


void ResetAllState()
{
	for(int i=0; i<=MaxClients; i++)
	{
		HunterVictim[i]=0;
		HunterAttacker[i]=0;
		HunterAction[i]=action_no; 
	}
}

public Action Event_BlockHunter(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetRandomFloat(0.0, 100.0) < g_fCvarIEvilHunterChance)
	{
		if(victim > 0 && attacker > 0 && IsFakeClient(attacker))
		{		
			HunterVictim[attacker] = victim;
			HunterAttacker[victim] = attacker; 
			HunterAction[attacker] = action_no;
			HunterActionTime[attacker] = GetEngineTime();
			HunterTick[attacker] = 0;
			SetEntityMoveType(attacker, MOVETYPE_WALK); 
			//PrintToChatAll("lunge_pounce %N %N", attacker, victim);
		} 
	}
}

public Action Event_BlockEndHunt(Handle event, const char[] name, bool dontBroadcast)
{ 
	int victim = GetClientOfUserId(GetEventInt(event, "victim")); 
	if(victim > 0 )
	{
		int attacker=HunterAttacker[victim];
		HunterVictim[attacker] = 0;
		HunterAttacker[victim] = 0;
		SetEntityMoveType(attacker, MOVETYPE_WALK); 
		//PrintToChatAll("pounce_end  %N %N", stop, victim); 
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(HunterAction[client] == action_stop_pounce)
	{
		if(!IsHunter(client))return StopHunter(client);
		float time = GetEngineTime();
		if(time-HunterActionTime[client] > 0.1)
		{
			HunterAction[client] = action_move;
			SetEntityMoveType(client, MOVETYPE_WALK); 
			HunterActionTime[client] = time;		
			//PrintToChatAll(" force jump %N", client); 
			buttons = 0;  
			return Plugin_Changed; 
		}
		return Plugin_Continue;	
	}
	else if(HunterAction[client] == action_move)
	{
		if(!IsHunter(client))return StopHunter(client);
		float time=GetEngineTime();
		HunterAction[client]=action_attack;		 
		HunterActionTime[client]=time;		
		//PrintToChatAll(" force attack %N", client);
		HunterTick[client]=0;
		buttons = buttons | IN_ATTACK;
		buttons = buttons | IN_DUCK;  
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, HunterAttackDir[client]);				
		return Plugin_Changed;	
	}
	else if(HunterAction[client]==action_attack)
	{
		if(!IsHunter(client))return StopHunter(client);
		float time=GetEngineTime();
		if(time-HunterActionTime[client]>3.0)HunterAction[client]=action_no;
		//HunterAction[client]=action_no;
		HunterTick[client]++;
		buttons=0;  
		if(HunterTick[client]%2==0)
		{
			buttons = buttons | IN_ATTACK;
			//PrintToChatAll("+");
		}
		else
		{
			buttons = buttons & ~IN_ATTACK;
			//PrintToChatAll("-");
		}
		buttons=  buttons | IN_DUCK;  
		return Plugin_Changed; 
	}
	
	if(HunterVictim[client] == 0) return Plugin_Continue;
	if(!IsHunter(client))return StopHunter(client);
		
	float time = GetEngineTime();
	if(time-HunterActionTime[client] > 0.2)
	{
		HunterActionTime[client]=time;
		int victim = HunterVictim[client];
		if(!IsSurvivor(victim))return StopHunter(client);
		int incap = GetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
		if(incap)
		{				
			if(HelperComing(client,victim))
			{
				HunterAction[client]=action_stop_pounce;
				SetEntityMoveType(client, MOVETYPE_NOCLIP);   
				//PrintToChatAll("force end %N", client);
			}			 
		}
	}
	 
	return Plugin_Continue;
}
Action StopHunter(int client)
{
	HunterVictim[client] = 0; 
	HunterAction[client] = action_no;
	return Plugin_Continue;
}
bool IsHunter(int client)
{
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client)) return true;
	return false;	
}
bool IsSurvivor(int client)
{
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))return true;
	return false;	 
}
bool HelperComing(int hunter, int victim)
{
	int count=0;
	float pos[3];
	float hunterPos[3];
	GetClientEyePosition(hunter,  hunterPos);
	for(int client = 1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && client != victim)
		{
			if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) continue;
			GetClientEyePosition(client,  pos);
			if(GetVectorDistance(pos, hunterPos)<300.0)
			{
				count++;
				//SubtractVectors(pos, hunterPos, HunterAttackDir[hunter]);
				HunterAttackDir[hunter][2]=0.0;
				HunterAttackDir[hunter][0]=GetRandomFloat(-1.0, 1.0);
				HunterAttackDir[hunter][1]=GetRandomFloat(-1.0, 1.0);
				NormalizeVector(HunterAttackDir[hunter],HunterAttackDir[hunter]);
				HunterAttackDir[hunter][2]=0.5;
				NormalizeVector(HunterAttackDir[hunter],HunterAttackDir[hunter]);
				ScaleVector(HunterAttackDir[hunter], 800.0);
				break;
			}
		}
	}
	return count > 0;
}