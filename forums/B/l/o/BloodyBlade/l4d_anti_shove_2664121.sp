#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.1"

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 
int ZOMBIECLASS_TANK = 5;
Handle VisibleTimer[MAXPLAYERS+1];
ConVar l4d_antishove_pushback[9];
ConVar l4d_antishove_invisible[9];
ConVar l4d_antishove_enable ;
ConVar l4d_antishove_invisible_alpha;
ConVar l4d_antishove_invisible_time;

int GameMode;
int L4D2Version;

public Plugin myinfo = 
{
	name = "anti shove",
	author = "Pan Xiaohai",
	description = "when you shove special infected you will be pushed back",
	version = PLUGIN_VERSION,	
}

public void OnPluginStart()
{
	GameCheck(); 	
	
	l4d_antishove_enable = CreateConVar("l4d_antishove_enable", "1", "anti shove 0:disable, 1:eanble ", FCVAR_NONE);
 
 	l4d_antishove_pushback[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_pushback_hunter", "80.0", "probalility of push back when you shove a hunter[0.0,100.0]", FCVAR_NONE);
 	l4d_antishove_pushback[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_pushback_smoker", "20.0", "", FCVAR_NONE);
 	l4d_antishove_pushback[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_pushback_boomer", "20.0", "", FCVAR_NONE);
 	l4d_antishove_pushback[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_pushback_jockey", "50.0", "", FCVAR_NONE);
 	l4d_antishove_pushback[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_pushback_spitter", "20.0", "", FCVAR_NONE);	
	l4d_antishove_pushback[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_pushback_charger", "10.0", "", FCVAR_NONE);
 	l4d_antishove_pushback[ZOMBIECLASS_TANK   ] = CreateConVar("l4d_antishove_pushback_tank", "20.0", "", FCVAR_NONE); 
	
	l4d_antishove_invisible[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_invisible_hunter", "30.0", "probalility of a hunter become a invisible hunter when you shove him[0.0,100.0]", FCVAR_NONE);
 	l4d_antishove_invisible[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_invisible_smoker", "20.0", "", FCVAR_NONE);
 	l4d_antishove_invisible[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_invisible_boomer", "40.0", "", FCVAR_NONE);
 	l4d_antishove_invisible[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_invisible_jockey", "20.0", "", FCVAR_NONE);
 	l4d_antishove_invisible[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_invisible_spitter", "20.0", "", FCVAR_NONE);	
	l4d_antishove_invisible[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_invisible_charger", "20.0", "", FCVAR_NONE);
 	l4d_antishove_invisible[ZOMBIECLASS_TANK] =	   CreateConVar("l4d_antishove_invisible_tank", "10.0", "", FCVAR_NONE);
	
 	l4d_antishove_invisible_time  =	 CreateConVar("l4d_antishove_invisible_time", "8", "invisible duration [5, 20]s", FCVAR_NONE);
	l4d_antishove_invisible_alpha  =	 CreateConVar("l4d_antishove_invisible_alpha", "90", "0,Completely invisible, 255, Completely visible [0, 255]", FCVAR_NONE);
 	
	if(GameMode != 2)
	{ 
		HookEvent("player_shoved", player_shoved); 	
		HookEvent("player_spawn", Event_Player_Spawn);
	}
	AutoExecConfig(true, "l4d_anti_shove");
}
 
int GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
	L4D2Version=!!L4D2Version;
}

public Action Event_Player_Spawn(Event event, char[] event_name, bool dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable) == 0) return Plugin_Continue;  
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
  	if(client > 0 && GetClientTeam(client) == 3)
	{
		VisibleTimer[client]=INVALID_HANDLE;
	}
	return Plugin_Continue;  
}

public Action player_shoved(Event event, char[] event_name, bool dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable) == 0) return Plugin_Continue; 
	int victim  = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if(GetClientTeam(victim) == 3)
	{
		if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_antishove_pushback[class]))
		{
			
			PushBack(victim , attacker);
		}
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_antishove_invisible[class]))
		{
			
			Invisible(victim , attacker);
		}
	}
  	return Plugin_Continue;
}

void PushBack(int victim, int attacker)
{
	float victimpos[3];
	float attackerpos[3];
	float v[3];
	float ang[3];
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientAbsOrigin(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos, ang);
	GetVectorAngles(ang, ang); 
	
	int flag = GetEntityFlags(attacker);  //FL_ONGROUND
	if(flag & FL_ONGROUND )
	{
		ang[0] = GetRandomFloat(2.0, 6.0);
	}
	else 
	{
		ang[0] = 0.0 - GetRandomFloat(10.0, 15.0);
	}
	ang[1] = ang[1] + GetRandomFloat(-65.0, 65.0);//GetRandomFloat(-180.0, 180.0);
	ang[2] = 0.0;
	
	GetAngleVectors(ang, v, NULL_VECTOR,NULL_VECTOR);
	
	NormalizeVector(v,v);
	ScaleVector(v, 0.0 - GetRandomFloat(600.0, 1000.0));

	attackerpos[2] += 20.0;
	TeleportEntity(attacker, attackerpos, NULL_VECTOR, v); 
}

void Invisible(int victim, int attacker)
{
	attacker = attacker * 1;
	SetEntityRenderMode(victim, view_as<RenderMode>(3)); 
	SetEntityRenderColor(victim, 255, 255, 255, GetConVarInt(l4d_antishove_invisible_alpha));
	Handle t = VisibleTimer[victim];
	
	VisibleTimer[victim] = CreateTimer(GetConVarFloat(l4d_antishove_invisible_time), Visible, victim, TIMER_FLAG_NO_MAPCHANGE);
	 
	if(t != INVALID_HANDLE)
	{ 
		KillTimer(t);
	}
}

public Action Visible(Handle timer, any client)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, view_as<RenderMode>(3));
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
	VisibleTimer[client] = null;
}
 