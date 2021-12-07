/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
 
new bool:L4D2Version;
new GameMode;
public Plugin:myinfo = 
{
	name = "hunter pounce push",
	author = "Pan XiaoHai & Marcus101RR & AtomicStryker",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

new Handle:SdkShove = INVALID_HANDLE;
new Handle:l4d_hunter_pounce_jockey = INVALID_HANDLE;
new Handle:l4d_hunter_pounce_smoker = INVALID_HANDLE; 
new Handle:l4d_hunter_pounce_charger = INVALID_HANDLE; 
new Handle:l4d_hunter_pounce_radius = INVALID_HANDLE; 
new Handle:l4d_hunter_pounce_infected = INVALID_HANDLE; 
public OnPluginStart()
{ 
	GameCheck();
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
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x85\xC9\x74", 32))
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
	}
	HookEvent("lunge_pounce", lunge_pounce);
	HookEvent("tongue_grab", tongue_grab);
	if(L4D2Version)
	{
		HookEvent("jockey_ride", jockey_ride); 
		HookEvent("charger_pummel_start", charger_pummel_start);
		HookEvent("charger_carry_start", charger_carry_start );
	}
	l4d_hunter_pounce_jockey = CreateConVar("l4d_hunter_pounce_jockey", "1", "1: enable the function for jockey, 2: do not enable for jockey" );
	l4d_hunter_pounce_smoker = CreateConVar("l4d_hunter_pounce_smoker", "1", "1: enable the function for smoker, 2: do not enable for smoker" );
	l4d_hunter_pounce_charger = CreateConVar("l4d_hunter_pounce_charger", "1", "1: enable the function for charger, 2: do not enable for charger" );

	l4d_hunter_pounce_radius = CreateConVar("l4d_hunter_pounce_radius", "200.0", "shove radius" );
	l4d_hunter_pounce_infected = CreateConVar("l4d_hunter_pounce_infected", "1", "1: shove infected, 2: do not shove infected" );
	AutoExecConfig(true, "hunter_pounce_l4d");
	
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
		 
		L4D2Version=true;
	}	
	else
	{
		 
		L4D2Version=false;
	}
 
}

public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==1)
	{
		//SetConVarFloat(FindConVar("z_pounce_stumble_radius"), GetConVarFloat(l4d_hunter_pounce_radius));
		if(GetConVarInt(l4d_hunter_pounce_charger)==1)
		{
			new attacker = GetClientOfUserId(GetEventInt(event, "userid"));  
			new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
			if(attacker>0 && victim>0)
			{		
				StartShove(attacker,victim );
			} 
		}  
	} 
} 
public jockey_ride (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_hunter_pounce_jockey)==1)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));  
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
		if(attacker>0 && victim>0)
		{		
			StartShove(attacker, victim);
		} 
	}  
}
public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_hunter_pounce_smoker)==1)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));  
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
		if(attacker>0 && victim>0)
		{		
			StartShove(victim,attacker );
		} 
	} 
}
public charger_pummel_start (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_hunter_pounce_charger)==1)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));  
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
		if(attacker>0 && victim>0)
		{		
			StartShove(attacker,victim );
		} 
	} 
	//PrintToChatAll("charger_pummel_start"); 
}
public charger_carry_start (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_hunter_pounce_charger)==1)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));  
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
		if(attacker>0 && victim>0)
		{		
			StartShove(attacker,victim );
		} 
	} 
	//PrintToChatAll("charger_carry_start"); 
}
 
StartShove(attacker, victim)
{
	decl Float:attackerPos[3];
	decl Float:pos[3];
	decl Float:dir[3];
	GetClientAbsOrigin(attacker, attackerPos);
	new Float:radius=GetConVarFloat(l4d_hunter_pounce_radius);
	new infected=GetConVarInt(l4d_hunter_pounce_infected);
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i!=victim && i!=attacker)
		{
			if(infected==0 && GetClientTeam(i)==3)continue;
			GetClientAbsOrigin(i, pos);
			SubtractVectors(pos, attackerPos, dir);
			if(GetVectorLength(dir)<=radius)
			{
				NormalizeVector(dir, dir); 
				SDKCall(SdkShove, i, attacker, dir);
			}
		}
	}
}