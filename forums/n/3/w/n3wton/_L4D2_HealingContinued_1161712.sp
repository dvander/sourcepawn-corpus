#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:ClientHealing[MAXPLAYERS+1] = { false, false, false, false, false, false, false, false, false };
new Float:AmountHealed[MAXPLAYERS+1] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
new Float:StartHeal[MAXPLAYERS+1] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
new Handle:HealTimer[MAXPLAYERS+1];
new Handle:HealResetTimer[MAXPLAYERS+1];
new ClientHealer[MAXPLAYERS+1];

new Handle:g_hDecreaseRate;
new Handle:g_hDecreaseAmount;
new Handle:g_hHealthAmount;

#define VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "",
	author = "n3wton",
	description = "",
	version = VERSION
};

public OnPluginStart()
{
	g_hDecreaseRate = CreateConVar( "l4d2_HealCont_DecreaseRate", "5.0", "How often in seconds the heal pecentage should decrease", FCVAR_PLUGIN );
	g_hDecreaseAmount = CreateConVar( "l4d2_HealCont_DecreaseAmount", "0.5", "Amount to decrease by every DecreaseRate", FCVAR_PLUGIN );
	g_hHealthAmount = CreateConVar( "l4d2_HealCont_HealthIncrease", "60", "Amount health a medpack restores", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]HealingCountinued" );

	HookEvent( "heal_begin", Event_HealStart, EventHookMode_Pre );
	HookEvent( "heal_interrupted", Event_HealInterrupted, EventHookMode_Pre );
	HookEvent( "heal_success", Event_HealSuccess, EventHookMode_Pre );
	HookEvent( "round_start", Event_RoundStart );
	
	RegConsoleCmd( "sm_health", Cmd_Health );
}

public Action:Cmd_Health(client, args)
{
	PrintToChat( client, "Your Health is %d", GetClientHealth( client ) );
	PrintToChat( client, "Revive Count is %d", GetEntProp(client,Prop_Send,"m_currentReviveCount") );
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	for( new i = 0; i <= MAXPLAYERS; i++ )
	{
		AmountHealed[i] = 0.0;
		StartHeal[i] = 0.0;
		ClientHealing[i] = false;
	}
}

public Action:Event_HealStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "subject" ) );
	new healer = GetClientOfUserId( GetEventInt( event, "userid" ) );
	ClientHealer[client] = healer;
	
	if( !ClientHealing[client] )
	{
		ClientHealing[client] = true;
		SetupProgressBar( client, 5.0 );
		
		if( HealResetTimer[client] != INVALID_HANDLE )
		{
			KillTimer( HealResetTimer[client] );
		}
		HealTimer[client] = CreateTimer( 5.0 - AmountHealed[client], Timer_CheckHealed, client );
	}
	
	return Plugin_Handled;
}

public Action:Event_HealInterrupted( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "subject" ) );
	
	if( ClientHealing[client] )
	{
		ClientHealing[client] = false;
		HealResetTimer[client] = CreateTimer( GetConVarFloat(g_hDecreaseRate), Timer_HealReset, client );
		KillProgressBar( client );
		KillTimer( HealTimer[client] );
	}
	return Plugin_Handled;
}

public Action:Event_HealSuccess( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "subject" ) );
	
	if( ClientHealing[client] )
	{	
		ClientHealing[client] = false;
		new count = GetEntProp( client, Prop_Send, "m_currentReviveCount" );
		if( count != 0 ) 
		{
			SetEntProp( client, Prop_Send, "m_currentReviveCount", 0 );
			SetEntProp( client, Prop_Send, "m_iHealth", GetConVarInt(g_hHealthAmount) );
		} else {
			new health = GetClientHealth( client ) + GetConVarInt(g_hHealthAmount);
			if( health > 98 ) health = 98;
			SetEntProp( client, Prop_Send, "m_iHealth", health );
		}
		
		if( client == ClientHealer[client] )
		{
			RemovePlayerItem( client, GetPlayerWeaponSlot( client, 3 ) );
		} else {
			RemovePlayerItem( ClientHealer[client], GetPlayerWeaponSlot( ClientHealer[client], 3 ) );
		}
	}
	return Plugin_Handled;
}

public Action:Timer_CheckHealed( Handle:timer, any:client )
{
	KillProgressBar( client );
	AmountHealed[client] = 0.0;
	
	new Handle:HealSuccessEvent = CreateEvent( "heal_success" );
	SetEventInt( HealSuccessEvent, "userid", GetClientUserId( ClientHealer[client] ) );
	SetEventInt( HealSuccessEvent, "subject", GetClientUserId( client ) );
	SetEventInt( HealSuccessEvent, "health_restored", 80 );
	FireEvent( HealSuccessEvent );
}

public Action:Timer_HealReset( Handle:timer, any:client )
{
	AmountHealed[client] -= GetConVarFloat( g_hDecreaseAmount );
	if( AmountHealed[client] < 0.0 ) 
	{
		AmountHealed[client] = 0.0;
	} else {
		HealResetTimer[client] = CreateTimer( GetConVarFloat(g_hDecreaseRate), Timer_HealReset, client );
	}
}

stock SetupProgressBar( client, Float:time )
{
	new Float:GameTime = GetGameTime() - AmountHealed[client];
	StartHeal[client] = GameTime;
	SetEntPropFloat( client, Prop_Send, "m_flProgressBarStartTime", GameTime );
	SetEntPropFloat( client, Prop_Send, "m_flProgressBarDuration", time );
	if( client != ClientHealer[client] )
	{
		SetEntPropFloat( ClientHealer[client], Prop_Send, "m_flProgressBarStartTime", GameTime );
		SetEntPropFloat( ClientHealer[client], Prop_Send, "m_flProgressBarDuration", time );	
	}
}

stock KillProgressBar( client )
{
	new Float:GameTime = GetGameTime();
	AmountHealed[client] = GameTime - StartHeal[client];
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GameTime);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	if( client != ClientHealer[client] )
	{
		SetEntPropFloat( ClientHealer[client], Prop_Send, "m_flProgressBarStartTime", GameTime );
		SetEntPropFloat( ClientHealer[client], Prop_Send, "m_flProgressBarDuration", 0.0 );
	}
}