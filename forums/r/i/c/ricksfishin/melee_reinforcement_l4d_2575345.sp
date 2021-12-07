#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
 

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 
new ZOMBIECLASS_TANK=	5;
new Handle:VisibleTimer[MAXPLAYERS+1];
new Handle:l4d_shove_pushback[9];
new Handle:l4d_melee_pushback[9];
new Handle:l4d_claw_fling[9];
new Handle:l4d_antishove_enable ;
 

new GameMode;
new L4D2Version;
new Handle:SdkShove = INVALID_HANDLE;
new Handle:SdkFling = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "Melee Reinforcement - Mutation of Shove And Claw",
	author = "Pan Xiaohai",
	description = " ",
	version = "1.0",	
}

public OnPluginStart()
{
	
	GameCheck(); 	
 
	
	l4d_antishove_enable = CreateConVar("l4d_antishove_enable", "1", "anti shove 0:disable, 1:eanble ", FCVAR_NOTIFY);
 
  	l4d_melee_pushback[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_melee_pushback_hunter", "0", "probalility of push back when you melee attacke a hunter[0.0,100.0]", FCVAR_NOTIFY);
 	l4d_melee_pushback[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_melee_pushback_smoker", "0", "", FCVAR_NOTIFY);	
 	l4d_melee_pushback[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_melee_pushback_boomer", "0", "", FCVAR_NOTIFY);
 	l4d_melee_pushback[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_melee_pushback_jockey", "0", "", FCVAR_NOTIFY);
 	l4d_melee_pushback[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_melee_pushback_spitter", "0", "", FCVAR_NOTIFY);	
	l4d_melee_pushback[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_melee_pushback_charger", "30", "", FCVAR_NOTIFY);
 	l4d_melee_pushback[ZOMBIECLASS_TANK   ] = CreateConVar("l4d_melee_pushback_tank", "100", "", FCVAR_NOTIFY); 
 
 	l4d_shove_pushback[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_shove_pushback_hunter", "0", "probalility of push back when you shove a hunter[0.0,100.0]", FCVAR_NOTIFY);
 	l4d_shove_pushback[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_shove_pushback_smoker", "0", "", FCVAR_NOTIFY);	
 	l4d_shove_pushback[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_shove_pushback_boomer", "100", "", FCVAR_NOTIFY);
 	l4d_shove_pushback[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_shove_pushback_jockey", "0", "", FCVAR_NOTIFY);
 	l4d_shove_pushback[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_shove_pushback_spitter", "0", "", FCVAR_NOTIFY);	
	l4d_shove_pushback[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_shove_pushback_charger", "100", "", FCVAR_NOTIFY);
 	l4d_shove_pushback[ZOMBIECLASS_TANK   ] = CreateConVar("l4d_shove_pushback_tank", "100", "", FCVAR_NOTIFY); 
	
	l4d_claw_fling[ZOMBIECLASS_HUNTER]  	= CreateConVar("l4d_claw_fling_hunter", "100", "probalility of been fling when you shoved by hunter[0.0,100.0]", FCVAR_NOTIFY);
 	l4d_claw_fling[ZOMBIECLASS_SMOKER]  	= CreateConVar("l4d_claw_fling_smoker", "0", "", FCVAR_NOTIFY);	
 	l4d_claw_fling[ZOMBIECLASS_BOOMER]  	= CreateConVar("l4d_claw_fling_boomer", "100", "", FCVAR_NOTIFY);
 	l4d_claw_fling[ZOMBIECLASS_JOCKEY]  	= CreateConVar("l4d_claw_fling_jockey", "0", "", FCVAR_NOTIFY);
 	l4d_claw_fling[ZOMBIECLASS_SPITTER]		= CreateConVar("l4d_claw_fling_pitter", "100", "", FCVAR_NOTIFY);	
	l4d_claw_fling[ZOMBIECLASS_CHARGER] 	= CreateConVar("l4d_claw_fling_charger", "100", "", FCVAR_NOTIFY);
 	l4d_claw_fling[ZOMBIECLASS_TANK] =		  CreateConVar("l4d_claw_fling_tank", "100", "", FCVAR_NOTIFY);
 
	if(L4D2Version)
	{

		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x55\x33\xED\x3B\xCD\x74", 35))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			SetFailState("Unable to find the 'shove' signature");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x53\x8B\xDC\x83\xEC\x08\x83\xE4\xF0\x83\xC4\x04\x55\x8B\x6B\x04\x89\x6C\x24\x04\x8B\xEC\x81\xEC\xA8\x00\x00\x00\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x2A\x8B\x43\x10", 41))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer5FlingERK6Vector17PlayerAnimEvent_tP20CBaseCombatCharacterf", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		SdkFling = EndPrepSDKCall();
		if(SdkFling == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
			//SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
		}		
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x81\xEC\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\xC5\x89\x45\xFC\x53\x8B\x5D\x08\x56\x57\x8B\x7D\x0C\x8B\xF1", 30))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			SetFailState("Unable to find the 'shove' signature");
		}		
		SdkFling=INVALID_HANDLE;
		PrintToServer("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	} 
	
	if(GameMode!=2)
	{ 
		HookEvent("player_shoved", player_shoved); 	
		HookEvent("player_spawn", Event_Player_Spawn);
		HookEvent("player_hurt", player_hurt);
		HookEvent("player_incapacitated", player_incapacitated);
	}
	AutoExecConfig(true, "melee_reinforcement_l4d");
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
	
	//PrintToChatAll("shove %N %N", attacker, victim);
 
	if(GetClientTeam(victim) == 3)
	{
		new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_shove_pushback[class]))
		{			
			PushBack(attacker,victim);
		} 
	}
  	return Plugin_Continue;
}

public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable)==0) return Plugin_Continue; 
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(victim>0 && attacker>0 )
	{
		
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, 64);		
		//PrintToChatAll("player_hurt %d %d  weapon %s", attacker,victim, weapon);
		new victimTeam=GetClientTeam(victim);
		if(victimTeam==2 && (StrContains(weapon, "claw")>=0  ))
		{	 
			new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
			if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_claw_fling[attackerClass]))
			{	
				if(SdkFling!=INVALID_HANDLE)Fling(victim, attacker);
				else PushBack(victim, attacker );
			}
		}
		if(victimTeam==3 && StrEqual(weapon, "melee")) 
		{
			new victimClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); 
			if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_melee_pushback[victimClass]))
			{			
				PushBack(attacker, victim);
			} 
			
		}
	}
	return Plugin_Continue; 
}
public Action:player_incapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_antishove_enable)==0) return Plugin_Continue; 
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(victim>0 && attacker>0 )
	{ 
		//PrintToChatAll("player_incapacitated %d %d ", attacker,victim); 
		if(GetClientTeam(attacker)==3 && GetClientTeam(victim)==2)
		{	 
			new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
			if( GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_claw_fling[attackerClass]))
			{			
				Fling(victim,  attacker, true);
			}			
		} 
	}
	return Plugin_Continue; 
}
Fling(victim,  attacker, incapacitatedStart=false)
{ 
	if(SdkFling==INVALID_HANDLE)return;	
	new m_pounceAttacker=GetEntProp(victim, Prop_Send, "m_pounceAttacker");
	new m_tongueOwner=GetEntProp(victim, Prop_Send, "m_tongueOwner");
	new m_isIncapacitated=GetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
	new m_isHangingFromLedge=GetEntProp(victim, Prop_Send, "m_isHangingFromLedge", 1);
	if(L4D2Version)
	{
		new m_pummelAttacker=GetEntProp(victim, Prop_Send, "m_pummelAttacker", 1);
		new m_jockeyAttacker=GetEntProp(victim, Prop_Send, "m_jockeyAttacker", 1);
		if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_pummelAttacker>0 || m_jockeyAttacker>0 )return;
	}
	else
	{
		if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 )return;
	}
	new Float:force=300.0;
	new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
	if(attackerClass==ZOMBIECLASS_TANK && m_isIncapacitated==0 && !incapacitatedStart)return;
	if(incapacitatedStart && attackerClass==ZOMBIECLASS_TANK)force=500.0;
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:dir[3]; 
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientEyePosition(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos,dir);
	NormalizeVector(dir, dir);
	ScaleVector(dir, force);
	SDKCall(SdkFling, victim, dir, 96, attacker, 2.0); // 96
}
PushBack(victim, attacker)
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:dir[3]; 
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientAbsOrigin(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos,dir);
	SDKCall(SdkShove, victim, attacker,  dir);
}
stock WindowsOrLinux()
{
     new Handle:conf = LoadGameConfigFile("windowsorlinux.gamedata.txt");
     new WindowsOrLinux = GameConfGetOffset(conf, "WindowsOrLinux");
     CloseHandle(conf);
     return WindowsOrLinux; //1 for windows; 2 for linux
}

 