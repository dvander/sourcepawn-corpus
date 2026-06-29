#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.1"

new Float:startPosition[MAXPLAYERS+1][3];
new Float:endPosition[MAXPLAYERS+1][3];
new UserMsg:g_FadeUserMsgId;

new Handle:g_hEnabled;
new Handle:g_hBlindAmount;
new Handle:g_hPounceScale;
new Handle:g_hPounceCap;
new Handle:g_hPounceMinShow;

public Plugin:myinfo =
{
	name = "Jockey Pounce Damage",
	author = "N3wton",
	description = "Adds Damage to the survivor been riden if the jock attacks from a great height.",
	version = VERSION
};

public OnPluginStart()
{
	g_hEnabled = CreateConVar( "l4d2_JockeyPounce_enabled", "1", "Should the plugin be enabled", FCVAR_PLUGIN );
	g_hBlindAmount = CreateConVar( "l4d2_JockeyPounce_blind", "150", "How much the jockey should blind the player (0: non, 255:completely)", FCVAR_PLUGIN );
	g_hPounceScale = CreateConVar( "l4d2_JockeyPounce_scale", "1.0", "Scale how much damage the pounce does (e.g. 0.5 will half the default damage, 5 will make it 5 times more powerfull)", FCVAR_PLUGIN );
	g_hPounceCap = CreateConVar( "l4d2_JockeyPounce_cap", "100", "Cap of the maximum damage a pounce can do", FCVAR_PLUGIN );
	g_hPounceMinShow = CreateConVar( "l4d2_JockeyPounce_minshow", "3", "Minimum damage a pounce should do to show the pounce message", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]JockeyPounce" );

	HookEvent( "jockey_ride", Event_JockeyRide );
	HookEvent( "jockey_ride_end", Event_JockeyRideEnd );
	HookEvent( "player_incapacitated", Event_Incap );
	HookEvent( "player_jump", Event_JockeyJump );
	
	g_FadeUserMsgId = GetUserMessageId( "Fade" );
}

PerformBlind(target, amount)
{
	new targets[2];
	targets[0] = target;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}

public Action:Event_JockeyJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetConVarBool(g_hEnabled) )
	{
		decl String:ClientModel[128];
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		GetClientModel( client, ClientModel, 128 );
		if( StrContains( ClientModel, "jockey", false ) >= 0 )
		{
			GetClientAbsOrigin( client, startPosition[client] );
		}
	}
	return Plugin_Continue;
}

public Action:Event_Incap( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool(g_hEnabled) )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
		PerformBlind( client, 0 );
	}
	return Plugin_Continue;
}

public Action:Event_JockeyRideEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool(g_hEnabled) )
	{
		new victim = GetClientOfUserId( GetEventInt( event, "victim" ) );
		PerformBlind( victim, 0 );
	}
	return Plugin_Continue;
}

public Action:Event_JockeyRide( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool(g_hEnabled) )
	{
		new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
		new victim = GetClientOfUserId( GetEventInt( event, "victim" ) );
		
		GetClientAbsOrigin( client, endPosition[client] );
		DistanceJumped( client, victim );		
		PerformBlind( victim, GetConVarInt(g_hBlindAmount) );
	}
	return Plugin_Continue;
}

stock DistanceJumped( client, victim )
{
	new damage = RoundFloat( startPosition[client][2] - endPosition[client][2] );
	
	if( damage < 0.0 )
	{
		damage = -damage;
	}
	
	damage = RoundFloat( ( damage / 100 ) * GetConVarFloat(g_hPounceScale) );

	damage = RoundFloat(((damage*damage)*0.8)+1);
	
	if( damage > GetConVarInt(g_hPounceCap) ) damage = GetConVarInt(g_hPounceCap);
	
	if( damage >= GetConVarInt(g_hPounceMinShow) )
	{
		PrintHintTextToAll( "%N jockey pounced %N for %d damage", client, victim, damage );	
	}
	
	new health = GetClientHealth( victim ) - damage;
	if( health < 0 ) health = 0;
	SetEntProp( victim, Prop_Send, "m_iHealth", health );
}