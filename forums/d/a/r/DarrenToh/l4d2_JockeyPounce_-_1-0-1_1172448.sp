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
new Handle:g_hPounceDisplay;
new Handle:g_hPounceDisplayMax;

new Handle:g_dbJockeyDamge = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Jockey Pounce Damage",
	author = "N3wton",
	description = "Adds Damage to the survivor been riden if the jock attacks from a great height.",
	version = VERSION
};

public OnPluginStart()
{
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if( !StrEqual(GameName, "left4dead2") )
		SetFailState( "Jockey pounce damage supports Left 4 Dead 2 only" );

	g_hEnabled = CreateConVar( "l4d2_JockeyPounce_enabled", "1", "Should the plugin be enabled", FCVAR_PLUGIN );
	g_hBlindAmount = CreateConVar( "l4d2_JockeyPounce_blind", "150", "How much the jockey should blind the player (0: non, 255:completely)", FCVAR_PLUGIN );
	g_hPounceScale = CreateConVar( "l4d2_JockeyPounce_scale", "1.0", "Scale how much damage the pounce does (e.g. 0.5 will half the default damage, 5 will make it 5 times more powerfull)", FCVAR_PLUGIN );
	g_hPounceCap = CreateConVar( "l4d2_JockeyPounce_cap", "100", "Cap of the maximum damage a pounce can do", FCVAR_PLUGIN );
	g_hPounceMinShow = CreateConVar( "l4d2_JockeyPounce_minshow", "3", "Minimum damage a pounce should do to show the pounce message", FCVAR_PLUGIN );
	g_hPounceDisplay = CreateConVar( "l4d2_JockeyPounce_display", "2", "How message should be shown, 0 - Disabled, 1 - Chat message, 2 - Hint Message", FCVAR_PLUGIN );
	g_hPounceDisplayMax = CreateConVar( "l4d2_JockeyPounce_display_max", "0", "Show the damagecap in the display message", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]JockeyPounce" );

	HookEvent( "jockey_ride", Event_JockeyRide );
	HookEvent( "jockey_ride_end", Event_JockeyRideEnd );
	HookEvent( "player_incapacitated", Event_Incap );
	HookEvent( "player_jump", Event_JockeyJump );
	
	g_FadeUserMsgId = GetUserMessageId( "Fade" );
	
	decl String:error[40];
	g_dbJockeyDamge = SQLite_UseDatabase( "[L4D2] JockeyPounce", error, 40 );
	if( g_dbJockeyDamge != INVALID_HANDLE )
	{
		new Handle:Query = SQL_Query( g_dbJockeyDamge, "SELECT steamID FROM DamageTable" );
		if( Query == INVALID_HANDLE )
		{
			Query = SQL_Query( g_dbJockeyDamge, "CREATE TABLE DamageTable( steamID varchar(255), name varchar(255), damage int )" );
		}
		CloseHandle( Query );
	}
	
	RegConsoleCmd( "sm_jpd", Command_JPD );
	
}

public Action:Command_JPD( client, args )
{
	if( g_dbJockeyDamge != INVALID_HANDLE )
	{
		decl String:QueryString[255];
		decl String:name[64];
		new damage = 0;
		Format( QueryString, 255, "SELECT name, damage FROM DamageTable" );
		new Handle:Query = SQL_Query( g_dbJockeyDamge, QueryString );
		if( Query != INVALID_HANDLE )
		{
			for( new i = 1; i <= 5; i++ )
			{
				if( SQL_FetchRow( Query ) )
				{
					SQL_FetchString( Query, 0, name, 64 );
					damage = SQL_FetchInt( Query, 1 );
					PrintToChat( client, "%d : %s         %d", i, name, damage );
				}				
			}
		}
	}
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
		return;
	}
	
	damage = RoundFloat( ( damage / 100.0 ) );

	damage = RoundFloat( ( ( ( damage * damage )*0.8 ) + 1 ) * GetConVarFloat( g_hPounceScale ) );
	
	if( damage > GetConVarInt(g_hPounceCap) ) damage = GetConVarInt(g_hPounceCap);
	
	if( damage >= GetConVarInt(g_hPounceMinShow) )
	{
		decl String:max[10];
		if( GetConVarBool( g_hPounceDisplayMax ) )
		{
			Format( max, 10, "(Max: %d)", GetConVarInt(g_hPounceCap) );
		} else {
			Format( max, 10, "" );
		}
		if( GetConVarInt( g_hPounceDisplay ) == 1 ) PrintToChatAll( "Jockey %N pounced %N for %d HP!%s", client, victim, damage, max );	
		if( GetConVarInt( g_hPounceDisplay ) == 2 ) PrintHintTextToAll( "Jockey %N pounced %N for %d HP!%s", client, victim, damage, max );	
	}
	
	new health = GetClientHealth( victim ) - damage;
	if( health < 0 ) health = 0;
	SetEntProp( victim, Prop_Send, "m_iHealth", health );
	
	if( g_dbJockeyDamge != INVALID_HANDLE && !IsFakeClient( client ) )
	{
		decl String:SteamID[60];
		decl String:QueryString[255];
		GetClientAuthString( client, SteamID, 60 );
		
		Format( QueryString, 255, "SELECT steamID FROM DamageTable WHERE steamID='%s'", SteamID );
		new Handle:Query = SQL_Query( g_dbJockeyDamge, QueryString );
		if( SQL_GetRowCount( Query ) > 0 )
		{
			Format( QueryString, 255, "SELECT damage FROM DamageTable WHERE steamID='%s'", SteamID );
			Query = SQL_Query( g_dbJockeyDamge, QueryString );
			SQL_FetchRow( Query );
			new oldDamage = SQL_FetchInt( Query, 0 );
			if( damage > oldDamage )
			{
				Format( QueryString, 255, "UPDATE DamageTable SET name='%N', damage='%d' WHERE steamID='%s'", client, damage, SteamID );
				SQL_FastQuery( g_dbJockeyDamge, QueryString );
			}
		} 
		else
		{
			Format( QueryString, 255, "INSERT INTO DamageTable ( steamID, name, damage ) VALUES ( '%s', '%N', '%d' )", SteamID, client, damage );
			SQL_FastQuery( g_dbJockeyDamge, QueryString );
		}
		CloseHandle( Query );	
	}
}