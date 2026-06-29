#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.4"

float startPosition[MAXPLAYERS+1][3];
float endPosition[MAXPLAYERS+1][3];
UserMsg g_FadeUserMsgId;

ConVar cvar_Enabled;
ConVar cvar_BlindAmount;
ConVar cvar_PounceScale;
ConVar cvar_PounceCap;
ConVar cvar_PounceMinShow;
ConVar cvar_PounceDisplay;
ConVar cvar_PounceDisplayMax;
ConVar cvar_PounceStoreStats;

Handle g_dbJockeyDamge = null;

public Plugin myinfo =
{
	name = "Jockey Pounce Damage",
	author = "N3wton & $pirit $atanic",
	description = "Adds Damage to the survivor been riden if the jock attacks from a great height.",
	version = VERSION
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if( !StrEqual(GameName, "left4dead2") )
	{
		SetFailState( "Jockey pounce damage supports Left 4 Dead 2 only" );
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvar_Enabled			= CreateConVar( "l4d2_JockeyPounce_enabled", "1", "Should the plugin be enabled");
	cvar_BlindAmount		= CreateConVar( "l4d2_JockeyPounce_blind", "150", "How much the jockey should blind the player (0: non, 255:completely)");
	cvar_PounceScale		= CreateConVar( "l4d2_JockeyPounce_scale", "1.0", "Scale how much damage the pounce does (e.g. 0.5 will half the default damage, 5 will make it 5 times more powerfull)");
	cvar_PounceCap			= CreateConVar( "l4d2_JockeyPounce_cap", "100", "Cap of the maximum damage a pounce can do");
	cvar_PounceMinShow		= CreateConVar( "l4d2_JockeyPounce_minshow", "3", "Minimum damage a pounce should do to show the pounce message");
	cvar_PounceDisplay		= CreateConVar( "l4d2_JockeyPounce_display", "2", "How message should be shown, 0 - Disabled, 1 - Chat message, 2 - Hint Message");
	cvar_PounceDisplayMax	= CreateConVar( "l4d2_JockeyPounce_display_max", "0", "Show the damagecap in the display message");
	cvar_PounceStoreStats	= CreateConVar( "l4d2_JockeyPounce_store_stats", "0", "Save the pounces in a database");
	AutoExecConfig( true, "[L4D2]JockeyPounce" );

	HookEvent( "jockey_ride", Event_JockeyRide );
	HookEvent( "jockey_ride_end", Event_JockeyRideEnd );
	HookEvent( "player_incapacitated", Event_Incap );
	HookEvent( "player_jump", Event_JockeyJump );
	HookEvent( "player_score", Event_PlayerScore );
	
	g_FadeUserMsgId = GetUserMessageId( "Fade" );
	
	char error[40];
	g_dbJockeyDamge = SQLite_UseDatabase( "[L4D2] JockeyPounce", error, 40 );
	if( g_dbJockeyDamge != null )
	{
		Handle Query = SQL_Query( g_dbJockeyDamge, "SELECT steamID FROM DamageTable" );
		if( Query == null )
		{
			Query = SQL_Query( g_dbJockeyDamge, "CREATE TABLE DamageTable( steamID varchar(255), name varchar(255), damage int )" );
		}
		CloseHandle( Query );
	}
	
	RegConsoleCmd( "sm_jpd", Command_JPD );	
}

/* Plugin Commands */

public Action Command_JPD( client, args )
{
	if( cvar_PounceStoreStats.BoolValue )
	{
		if( g_dbJockeyDamge != null )
		{
			char QueryString[255];
			char name[64];
			int damage = 0;
			Format( QueryString, 255, "SELECT name, damage FROM DamageTable ORDER BY damage DESC" );
			Handle Query = SQL_Query( g_dbJockeyDamge, QueryString );
			if( Query != null )
			{
				for( int i = 1; i <= 5; i++ )
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
	else
	{
		PrintToChat( client, "Jockey pounce stats have been disabled on this server" );
	}
}

/* Plugin Events */

public Action Event_PlayerScore(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId( event.GetInt( "userid" ) );
	PrintToChat( client, "Your Score Has Changed" );
}

public Action Event_JockeyJump(Event event, const char[] name, bool dontBroadcast)
{
	if( cvar_Enabled.BoolValue )
	{
		char ClientModel[128];
		int client = GetClientOfUserId(event.GetInt("userid"));
		GetClientModel( client, ClientModel, 128 );
		if( StrContains( ClientModel, "jockey", false ) >= 0 )
		{
			GetClientAbsOrigin( client, startPosition[client] );
		}
	}
	return Plugin_Continue;
}

public Action Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	if( cvar_Enabled.BoolValue )
	{
		int client = GetClientOfUserId( event.GetInt( "userid" ) );
		PerformBlind( client, 0 );
	}
	return Plugin_Continue;
}

public Action Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	if( cvar_Enabled.BoolValue )
	{
		int victim = GetClientOfUserId( event.GetInt( "victim" ) );
		PerformBlind( victim, 0 );
	}
	return Plugin_Continue;
}

public Action Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	if( cvar_Enabled.BoolValue )
	{
		int client = GetClientOfUserId( event.GetInt( "userid" ) );
		int victim = GetClientOfUserId( event.GetInt( "victim" ) );
		
		GetClientAbsOrigin( client, endPosition[client] );
		DistanceJumped( client, victim );		
		PerformBlind( victim, cvar_BlindAmount.IntValue );
	}
	return Plugin_Continue;
}

/* Plugin Stocks */

stock DistanceJumped( int client, int victim )
{
	int damage = RoundFloat( startPosition[client][2] - endPosition[client][2] );
	
	if( damage < 0.0 )
	{
		return;
	}
	
	damage = RoundFloat( ( damage / 100.0 ) );

	damage = RoundFloat( ( ( ( damage * damage )*0.8 ) + 1 ) * cvar_PounceScale.FloatValue );
	
	if( damage > cvar_PounceCap.IntValue ) damage = cvar_PounceCap.IntValue;
	
	if( damage >= GetConVarInt(cvar_PounceMinShow) )
	{
		char max[10];
		if( cvar_PounceDisplayMax.BoolValue )
		{
			Format( max, 10, " Max %d", cvar_PounceCap.IntValue );
		} else {
			Format( max, 10, "" );
		}
		if( !IsFakeClient( client ) )
		{
			if( cvar_PounceDisplay.IntValue == 1 ) PrintToChatAll( "%N jockey pounced %N for %d damage%s", client, victim, damage, max );	
			if( cvar_PounceDisplay.IntValue == 2 ) PrintHintTextToAll( "%N jockey pounced %N for %d damage%s", client, victim, damage, max );	
		}
	}
	
	applyDamage( damage, victim, client );
	
	if( g_dbJockeyDamge != null && !IsFakeClient( client ) && cvar_PounceStoreStats.BoolValue )
	{
		char SteamID[60];
		char QueryString[255];
		GetClientAuthId( client, AuthId_Steam2, SteamID, sizeof(SteamID) );
		
		Format( QueryString, 255, "SELECT steamID FROM DamageTable WHERE steamID='%s'", SteamID );
		Handle Query = SQL_Query( g_dbJockeyDamge, QueryString );
		if( SQL_GetRowCount( Query ) > 0 )
		{
			Format( QueryString, 255, "SELECT damage FROM DamageTable WHERE steamID='%s'", SteamID );
			Query = SQL_Query( g_dbJockeyDamge, QueryString );
			SQL_FetchRow( Query );
			int oldDamage = SQL_FetchInt( Query, 0 );
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

stock PerformBlind(int target, int amount)
{
	int targets[2];
	targets[0] = target;
	
	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
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

/* timer idea by dirtyminuth, damage dealing by pimpinjuice http://forums.alliedmods.net/showthread.php?t=111684 added some L4D2 specific checks */

static applyDamage(damage, victim, attacker)
{ 
	DataPack dataPack = CreateDataPack();
	WritePackCell(dataPack, damage);  
	WritePackCell(dataPack, victim);
	WritePackCell(dataPack, attacker);
	
	CreateTimer(0.10, timer_stock_applyDamage, dataPack); 
}

public Action timer_stock_applyDamage(Handle timer, Handle dataPack)
{
	ResetPack(dataPack);
	int damage = ReadPackCell(dataPack);  
	int victim = ReadPackCell(dataPack);
	int attacker = ReadPackCell(dataPack);
	CloseHandle(dataPack);   

	float victimPos[3];
	char strDamage[16];
	char strDamageTarget[16];
	
	GetClientEyePosition(victim, victimPos);
	IntToString(damage, strDamage, sizeof(strDamage));
	Format(strDamageTarget, sizeof(strDamageTarget), "hurtme%d", victim);
	
	int entPointHurt = CreateEntityByName("point_hurt");
	if(!entPointHurt) return;

	// Config, create point_hurt
	DispatchKeyValue(victim, "targetname", strDamageTarget);
	DispatchKeyValue(entPointHurt, "DamageTarget", strDamageTarget);
	DispatchKeyValue(entPointHurt, "Damage", strDamage);
	DispatchKeyValue(entPointHurt, "DamageType", "0"); // DMG_GENERIC
	DispatchSpawn(entPointHurt);
	
	// Teleport, activate point_hurt
	TeleportEntity(entPointHurt, victimPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entPointHurt, "Hurt", (attacker && attacker < MaxClients && IsClientInGame(attacker)) ? attacker : -1);
	
	// Config, delete point_hurt
	DispatchKeyValue(entPointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "null");
	RemoveEdict(entPointHurt);
}