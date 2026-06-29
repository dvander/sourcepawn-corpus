#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.5" 
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define action_no 0
#define action_stop_pounce 1
#define action_move 2
#define action_attack 3

public Plugin myinfo = 
{
	name = "Evil Hunter",
	author = "Pan XiaoHai",
	description = "<- Description ->",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead(2)\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar l4d_evil_hunter_on, l4d_evil_hunter_chance;
int HunterVictim[MAXPLAYERS + 1] = {0, ...}, HunterAttacker[MAXPLAYERS + 1] = {0, ...}, HunterAction[MAXPLAYERS + 1] = {0, ...}, HunterTick[MAXPLAYERS + 1] = {0, ...};
float fEvilHunterChance = 0.0, HunterActionTime[MAXPLAYERS + 1] = {0.0, ...}, HunterAttackDir[MAXPLAYERS + 1][3];
bool bHooked = false;

public void OnPluginStart()
{
	CreateConVar("l4d_evil_hunter_version", PLUGIN_VERSION, "Evil Hunter plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	l4d_evil_hunter_on = CreateConVar("l4d_evil_hunter_on", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	l4d_evil_hunter_chance = CreateConVar("l4d_evil_hunter_chance", "100.0", "chance of change target", CVAR_FLAGS);
	l4d_evil_hunter_on.AddChangeHook(ConVarPluginOnChanged);
	l4d_evil_hunter_chance.AddChangeHook(ConVarsChanged);
	AutoExecConfig(true, "evil_hunter_l4d");
}

public void OnMapStart()
{
	ResetAllState();
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    fEvilHunterChance = l4d_evil_hunter_chance.FloatValue;
}

void IsAllowed()
{
	bool bPlugonOn = l4d_evil_hunter_on.BoolValue;
	if (bPlugonOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("lunge_pounce", lunge_pounce);
		HookEvent("pounce_end", pounce_end);
		HookEvent("round_start", round);
		HookEvent("round_end", round);
		HookEvent("finale_win", round);
		HookEvent("mission_lost", round);
		HookEvent("map_transition",  round);
	}
	else if (!bPlugonOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("lunge_pounce", lunge_pounce);
		UnhookEvent("pounce_end", pounce_end);
		UnhookEvent("round_start", round);
		UnhookEvent("round_end", round);
		UnhookEvent("finale_win", round);
		UnhookEvent("mission_lost", round);
		UnhookEvent("map_transition",  round);
	}
}

void round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
}

void ResetAllState()
{
	for(int i = 0; i <= MaxClients; i++)
	{
		HunterVictim[i] = 0;
		HunterAttacker[i] = 0;
		HunterAction[i] = action_no; 
	}
}

void lunge_pounce(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if(GetRandomFloat(0.0, 100.0) < fEvilHunterChance)
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

void pounce_end(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim")); 
	if(victim > 0)
	{
		int attacker = HunterAttacker[victim];
		HunterVictim[attacker] = 0;
		HunterAttacker[victim] = 0;
		SetEntityMoveType(attacker, MOVETYPE_WALK); 
		//PrintToChatAll("pounce_end  %N %N", stop, victim); 
	}
}
 
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(HunterAction[client] == action_stop_pounce)
	{
		if(!IsHunter(client)) return StopHunter(client);
		float Time = GetEngineTime();
		if(Time - HunterActionTime[client] > 0.1)
		{
			HunterAction[client] = action_move;
			SetEntityMoveType(client, MOVETYPE_WALK); 
			HunterActionTime[client] = Time;		
			//PrintToChatAll(" force jump %N", client); 
			buttons = 0;
			return Plugin_Changed;
		}
		return Plugin_Continue;	
	}
	else if(HunterAction[client] == action_move)
	{
		if(!IsHunter(client)) return StopHunter(client);
		float Time = GetEngineTime();
		HunterAction[client] = action_attack;		 
		HunterActionTime[client] = Time;		
		//PrintToChatAll(" force attack %N", client);
		HunterTick[client] = 0;
		buttons = buttons|IN_ATTACK;
		buttons = buttons|IN_DUCK;  
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, HunterAttackDir[client]);				
		return Plugin_Changed;	
	}
	else if(HunterAction[client] == action_attack)
	{
		if(!IsHunter(client)) return StopHunter(client);
		float Time = GetEngineTime();
		if(Time - HunterActionTime[client] > 3.0) HunterAction[client] = action_no;
		//HunterAction[client] = action_no;
		HunterTick[client]++;
		buttons = 0;  
		if((HunterTick[client] % 2) == 0)
		{
			buttons = buttons|IN_ATTACK;
			//PrintToChatAll("+");
		}
		else
		{
			buttons = buttons & ~IN_ATTACK;
			//PrintToChatAll("-");
		}
		buttons = buttons|IN_DUCK;  
		return Plugin_Changed; 
	}

	if(HunterVictim[client] == 0)return Plugin_Continue;
	if(!IsHunter(client)) return StopHunter(client);
		
	float Time = GetEngineTime();
	if(Time - HunterActionTime[client] > 0.2)
	{
		HunterActionTime[client] = Time;
		int victim = HunterVictim[client];
		if(!IsSurvivor(victim)) return StopHunter(client);
		if(view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)))
		{	
			if(HelperComing(client, victim))
			{
				HunterAction[client] = action_stop_pounce;
				SetEntityMoveType(client, MOVETYPE_NOCLIP);   
				//PrintToChatAll("force end %N", client);
			}			 
		}
	}

	return Plugin_Continue;
}

Action StopHunter(int client)
{
	if(client > 0)
	{
		HunterVictim[client] = 0; 
		HunterAction[client] = action_no;
	}
	return Plugin_Continue;
}

bool IsHunter(int client)
{
	return client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client);
}

bool IsSurvivor(int client)
{
	return client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);	 
}

bool HelperComing(int hunter, int victim)
{
	int count = 0;
	float pos[3], hunterPos[3];
	GetClientEyePosition(hunter,  hunterPos);
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && client != victim)
		{
			if(!view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)))
			{
				GetClientEyePosition(client,  pos);
				if(GetVectorDistance(pos, hunterPos) < 300.0)
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
	}
	return count > 0;
}
