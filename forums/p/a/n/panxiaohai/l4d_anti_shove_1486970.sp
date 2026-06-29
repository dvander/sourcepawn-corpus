#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.1"

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 
new ZOMBIECLASS_TANK=	5;
new Handle:VisibleTimer[MAXPLAYERS+1];
new Handle:l4d_antishove_pushback[9];
new Handle:l4d_antishove_invisible[9];
new Handle:l4d_antishove_enable ;
new Handle:l4d_antishove_invisible_alpha;
new Handle:l4d_antishove_invisible_time;

new GameMode;
new L4D2Version;
public Plugin:myinfo = 
{
	name = "anti shove",
	author = "Pan Xiaohai",
	description = "when you shove special infected you will be pushed back",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	
	GameCheck(); 	
 
	
	l4d_antishove_enable = CreateConVar("l4d_antishove_enable", "1", "anti shove 0:disable, 1:eanble ", FCVAR_PLUGIN);
 
 	l4d_antishove_pushback[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_pushback_hunter", "80", "probalility of push back when you shove a hunter[0.0,100.0]", FCVAR_PLUGIN);
 	l4d_antishove_pushback[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_pushback_smoker", "20", "", FCVAR_PLUGIN);	
 	l4d_antishove_pushback[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_pushback_boomer", "20", "", FCVAR_PLUGIN);
 	l4d_antishove_pushback[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_pushback_jockey", "50", "", FCVAR_PLUGIN);
 	l4d_antishove_pushback[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_pushback_spitter", "20", "", FCVAR_PLUGIN);	
	l4d_antishove_pushback[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_pushback_charger", "10", "", FCVAR_PLUGIN);
 	l4d_antishove_pushback[ZOMBIECLASS_TANK   ] = CreateConVar("l4d_antishove_pushback_tank", "20", "", FCVAR_PLUGIN); 
	
	l4d_antishove_invisible[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_invisible_hunter", "30", "probalility of a hunter become a invisible hunter when you shove him[0.0,100.0]", FCVAR_PLUGIN);
 	l4d_antishove_invisible[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_invisible_smoker", "20", "", FCVAR_PLUGIN);	
 	l4d_antishove_invisible[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_invisible_boomer", "40", "", FCVAR_PLUGIN);
 	l4d_antishove_invisible[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_invisible_jockey", "20", "", FCVAR_PLUGIN);
 	l4d_antishove_invisible[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_invisible_pitter", "20", "", FCVAR_PLUGIN);	
	l4d_antishove_invisible[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_invisible_charger", "20", "", FCVAR_PLUGIN);
 	l4d_antishove_invisible[ZOMBIECLASS_TANK] =	   CreateConVar("l4d_antishove_invisible_tank", "10", "", FCVAR_PLUGIN);
	
 	l4d_antishove_invisible_time  =	 CreateConVar("l4d_antishove_invisible_time", "8", "invisible duration [5, 20]s", FCVAR_PLUGIN);
	l4d_antishove_invisible_alpha  =	 CreateConVar("l4d_antishove_invisible_alpha", "90", "0,Completely invisible, 255, Completely visible [0, 255]", FCVAR_PLUGIN);
 	
	if(GameMode!=2)
	{ 
		HookEvent("player_shoved", player_shoved); 	
		HookEvent("player_spawn", Event_Player_Spawn);
	}
	AutoExecConfig(true, "l4d_anti_shove");
}
 
GameCheck()
{
	decl String:GameName[16];
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
public Action:Event_Player_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable)==0) return Plugin_Continue;  
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
  	if(client > 0 && GetClientTeam(client) == 3)
	{
		VisibleTimer[client]=INVALID_HANDLE;
	}
	return Plugin_Continue;  
}
public Action:player_shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable)==0) return Plugin_Continue; 
	new victim  = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
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
PushBack(victim, attacker)
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:v[3];
	decl Float:ang[3];
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientAbsOrigin(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos, ang);
	GetVectorAngles(ang, ang); 
	
	new flag=GetEntityFlags(attacker);  //FL_ONGROUND
	
	if(flag & FL_ONGROUND )
	{
		ang[0]=GetRandomFloat(2.0, 6.0);
		
	}
	else 
	{
		ang[0]=0.0-GetRandomFloat(10.0, 15.0);
	}
	ang[1]=ang[1]+GetRandomFloat(-65.0, 65.0);//GetRandomFloat(-180.0, 180.0);
	ang[2]=0.0;
	
	GetAngleVectors(ang, v, NULL_VECTOR,NULL_VECTOR);
	
	NormalizeVector(v,v);
	ScaleVector(v, 0.0-GetRandomFloat(600.0, 1000.0));

	attackerpos[2]+=20.0;
	TeleportEntity(attacker, attackerpos, NULL_VECTOR, v); 
}
Invisible(victim, attacker)
{
	attacker=attacker*1;
	SetEntityRenderMode(victim, RenderMode:3); 
	SetEntityRenderColor(victim, 255, 255, 255, GetConVarInt(l4d_antishove_invisible_alpha));
	new Handle:t=VisibleTimer[victim];
	
	VisibleTimer[victim]=CreateTimer(GetConVarFloat(l4d_antishove_invisible_time), Visible, victim, TIMER_FLAG_NO_MAPCHANGE);
	 
	if(t!=INVALID_HANDLE)
	{ 
		KillTimer(t);
	}
}
public Action:Visible(Handle:timer, any:client)
{
	if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityRenderMode(client, RenderMode:3); 
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
 
	VisibleTimer[client]=INVALID_HANDLE;
	
}
 