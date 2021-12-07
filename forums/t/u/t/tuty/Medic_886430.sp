#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION 	"1.0"
#define PLUGIN_AUTHOR	"tuty"

#define SOUND_FILE	"misc/medic.wav"

new Handle:gPluginEnabled = INVALID_HANDLE;
new Handle:gHealthAmount = INVALID_HANDLE;
new Handle:gMinHealth = INVALID_HANDLE;
new Handle:gMedicCost = INVALID_HANDLE;
new Handle:gShowInChat = INVALID_HANDLE;
new Handle:gMaxTimeUse = INVALID_HANDLE;

new gPlayerMoney;
new gUsedMedic[ 33 ];


public Plugin:myinfo = 
{
	name = "CSS Medic",
	author = PLUGIN_AUTHOR,
	description = "You can call a medic.",
	version = PLUGIN_VERSION,
	url = "www.ligs.us"
};
public OnPluginStart()
{
	HookEvent( "player_spawn", Event_PlayerSpawn );
	RegConsoleCmd( "say", Command_Medic );
	RegConsoleCmd( "say_team", Command_Medic );

	CreateConVar( "cssmedic_version", PLUGIN_VERSION, "CSS Medic Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );

	gPluginEnabled = CreateConVar( "css_medic", "1" );
	gMinHealth = CreateConVar( "css_medic_minhealth", "40" );
	gHealthAmount = CreateConVar( "css_medic_healhealth", "100" );
	gMedicCost = CreateConVar( "css_medic_cost", "2000" );
	gShowInChat = CreateConVar( "css_medic_showcall", "1" );
	gMaxTimeUse = CreateConVar( "css_medic_maxuse", "1" );
	
	gPlayerMoney = FindSendPropOffs( "CCSPlayer", "m_iAccount" );
}
public OnClientConnected( id )
{
	gUsedMedic[ id ] = 0;
}
public OnClientDisconnect( id )
{
	gUsedMedic[ id ] = 0;
}
public OnMapStart()
{
	decl String:MedicSound[ 100 ];
	FormatEx( MedicSound, sizeof( MedicSound ) - 1, "sound/%s", SOUND_FILE );
	
	if( FileExists( MedicSound )  )
	{
		AddFileToDownloadsTable( MedicSound );
		PrecacheSound( SOUND_FILE, true );
	}
}
public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );

		gUsedMedic[ id ] = 0;
	}
}
public Action:Command_Medic( id, args )
{
	decl String:Said[ 128 ];

	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!medic" ) || StrEqual( Said, "!doctor" ) )
	{
		if( GetConVarInt( gPluginEnabled ) == 0 )
		{
			PrintToChat( id, "\x03[CSS Medic] \x01Sorry, you can't call a \x04Medic\x01 !" );
			
			return Plugin_Continue;
		}
			
		if( !IsPlayerAlive( id ) )
		{
			PrintToChat( id, "\x03[CSS Medic] \x01You can't call \x04Medic \x01while you are dead!" );
		
			return Plugin_Continue;
		}
	
		new maxtime = GetConVarInt( gMaxTimeUse );

		if( gUsedMedic[ id ] >= maxtime )
		{
			PrintToChat( id, "\x03[CSS Medic] \x01You can call \x04Medic \x01only \x03%d \x01times per round!", maxtime );
			
			return Plugin_Continue;
		}
		
		new money = GetClientMoney( id );
		new cost = GetConVarInt( gMedicCost );
		
		if( money < cost )
		{
			PrintToChat( id, "\x03[CSS Medic] \x01You don't have enough money to call a \x04Medic\x01 ! You need %d$", cost );
			
			return Plugin_Continue;
		}
		
		if( GetClientHealth( id ) >= GetConVarInt( gMinHealth ) )
		{
			PrintToChat( id, "\x03[CSS Medic] \x01Hey dude! You have enough health, and you don't need a \x04Medic \x01! Go back to fight!" );
			
			return Plugin_Continue;
		}
		
		gUsedMedic[ id ]++;

		SetEntProp( id, Prop_Data, "m_iHealth", GetConVarInt( gHealthAmount ) );
		SetClientMoney( id, money - cost );
		PrintToChat( id, "\x03[CSS Medic] \x01Successfully called a \x04Medic\x01 ! You are now healed." );
	
		if( GetConVarInt( gShowInChat ) != 0 )
		{
			decl String:Name[ 32 ];
			GetClientName( id, Name, sizeof( Name ) - 1 );

			PrintToChatAll( "\x03%s \x01(CALLED): \x04Medic!", Name );
		}
		
		new Float:fOrigin[ 3 ];
		GetClientAbsOrigin( id, Float:fOrigin );
		
		EmitAmbientSound( SOUND_FILE, fOrigin, id, SNDLEVEL_CONVO );
		AttachClientIcon( id );
	}
	
	return Plugin_Continue;
}	
stock SetClientMoney( index, money )
{
	if( gPlayerMoney != -1 )
	{
		SetEntData( index, gPlayerMoney, money );
	}
}
stock GetClientMoney( index )
{
	if( gPlayerMoney != -1 )
	{
		return GetEntData( index, gPlayerMoney );
	}
	
	return 0;
}
stock AttachClientIcon( index )
{
	TE_Start( "RadioIcon" );
	TE_WriteNum( "m_iAttachToClient", index );
	TE_SendToAll();
}
