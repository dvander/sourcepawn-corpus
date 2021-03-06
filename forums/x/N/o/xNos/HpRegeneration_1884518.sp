/* Plugin Template generated by Pawn Studio */
/*
1.4:
Code Improvement

1.2:
Added "AutoExecConfig"

1.0: 
This is original version of Hp Regeneration by xNos.


ConVars:
sm_regeneration_enabeld "1"		-	( Default: 1 	)		-	Enables Hp Regeneration
sm_regeneration_timer 	"1.0"	-	( Default: 1.0 	)		-	After how match sec the client get his regeneration
sm_regeneration_maxhp 	"100"	-	( Default: 100 	)		-	Whats the maximum hp the player can get
sm_regeneration_amount 	"10"	-	( Default: 10 	)		-	How match hp the player gets every regenerate

Credit to sNeeP for the "IsValidClient" Code.
*/


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:g_rEnabled;
new Handle:g_rTimer;
new Handle:g_rMaxHp;
new Handle:g_rAmount;

public Plugin:myinfo = 
{
	name = "Hp Regeneration",
	author = "xNos",
	description = "Regeneration the player hp after getting hurt.",
	version = "1.4",
	url = "HL2.co.il"
}

public OnPluginStart()
{
	g_rEnabled 	= 	CreateConVar( "sm_regeneration_enabeld", "1", "Enables Hp Regeneration" );								//( Default: 1 )
	g_rTimer 	= 	CreateConVar( "sm_regeneration_timer", "1.0", "After how match sec the client get his regeneration" );	//( Default: 1.0 )
	g_rMaxHp 	= 	CreateConVar( "sm_regeneration_maxhp", "100", "Whats the maximum hp the player can get" );				//( Default: 100 )
	g_rAmount 	= 	CreateConVar( "sm_regeneration_amount", "10", "How match hp the player gets every regenerate" );		//( Default: 10 )
	
	CreateTimer( GetConVarFloat( g_rTimer ), HpRegeneration, _, TIMER_REPEAT );
	
	AutoExecConfig( true, "HpRegeneration" );
}
public Action:HpRegeneration( Handle:timer )
{
	for( new i; i <= MaxClients; i++ )
	{
		if( IsValidClient( i, true ) )
		{
			if( GetConVarInt( g_rEnabled ) )
			{
				new ClientHealth = GetClientHealth( i );
				
				if( ClientHealth > ( GetConVarInt( g_rMaxHp ) ) )
				{
					SetEntityHealth( i, GetConVarInt( g_rMaxHp ) );
					return Plugin_Stop;
				}
				
				if( ClientHealth < GetConVarInt( g_rMaxHp ) )
				{
					SetEntityHealth( i, ClientHealth + GetConVarInt( g_rAmount ) );
					return Plugin_Continue;
				}
				
				return Plugin_Continue;
			}
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}

stock bool:IsValidClient( Client, bool:bAlive = false )
{
	if( Client >= 1 && Client <= MaxClients && IsClientConnected( Client ) && IsClientInGame( Client ) && !IsFakeClient( Client ) && !IsClientSourceTV( Client ) && ( bAlive == false || IsPlayerAlive( Client ) ) )
	{
		return true;
	}
	
	return false;
}
