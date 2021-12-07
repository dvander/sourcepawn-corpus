#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"tuty"
#define PLUGIN_VERSION	"1.0"
#define FFADE_IN  	0x0001
#pragma semicolon 1

new Handle:gHealthAmount = INVALID_HANDLE;
new Handle:gPluginEnabled = INVALID_HANDLE;
new Handle:gMinHealth = INVALID_HANDLE;
new Handle:gMaxTimeUse = INVALID_HANDLE;
new MedicUsed[ 33 ];

public Plugin:myinfo = 
{
	name = "DoD:S Call Medic",
	author = PLUGIN_AUTHOR,
	description = "Use medic voice to heal.",
	version = PLUGIN_VERSION,
	url = "http://www.ligs.us/"
};
public OnPluginStart()
{
	HookEvent( "player_spawn", Event_PlayerSpawn );
	RegConsoleCmd( "voice_medic", CommandCall_Medic );
	RegConsoleCmd( "say", CommandSay );
	RegConsoleCmd( "say_team", CommandSay );
	
	CreateConVar( "dodmedic_version", PLUGIN_VERSION, "DoD:S Call Medic", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gPluginEnabled = CreateConVar( "dod_medic", "1" );
	gMinHealth = CreateConVar( "dod_medic_minhealth", "80" );
	gHealthAmount = CreateConVar( "dod_medic_health", "100" );
	gMaxTimeUse = CreateConVar( "dod_medic_maxuse", "2" );
}
public Action:CommandCall_Medic( id, args )
{
	if( GetConVarInt( gPluginEnabled ) == 0 )
	{
		PrintHintText( id, "Sorry, you can't call a Medic!" );
		PrintToChat( id, "[DoD:S Medic] Sorry, you can't call a Medic!" );
		
		return Plugin_Handled;
	}
	
	if( !IsPlayerAlive( id ) )
	{
		PrintHintText( id, "You can't call Medic while you are dead!" );
		PrintToChat( id, "[DoD:S Medic] You can't call Medic while you are dead!" );
		
		return Plugin_Handled;
	}

	new muse = GetConVarInt( gMaxTimeUse );

	if( MedicUsed[ id ] >= muse )
	{
		PrintHintText( id, "You can't call a Medic anymore! Only '%d' times.", muse );
		PrintToChat( id, "[DoD:S Medic] You can't call a Medic anymore! Only '%d' times.", muse );

		return Plugin_Handled;
	}
		
	new min = GetConVarInt( gMinHealth );
	
	if( GetClientHealth( id ) >= min )
	{
		PrintHintText( id, "Your health must be lower than '%d' to call a Medic!", min );
		PrintToChat( id, "[DoD:S Medic] Your health must be lower than '%d' to call a Medic!", min );
		
		return Plugin_Handled;
	}
	
	SetClientHealth( id, GetConVarInt( gHealthAmount ) );
	PrintHintText( id, "Successfully called a Medic. You are now healed." );
	PrintToChat( id, "[DoD:S Medic] Successfully called Medic. You are now healed." );
	SetClientScreenFade( id, 255, 0, 0, 60, 1 );
	MedicUsed[ id ]++;

	return Plugin_Continue;
}
public Action:CommandSay( id, args )
{
	decl String:Said[ 128 ];
	
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{
		if( StrEqual( Said, "!medic" ) || StrEqual( Said, "medic" ) || StrEqual( Said, "/medic" ) )
		{
			PrintHintText( id, "If you want to call a Medic, you must 'bind <key> voice_medic' and press that <key>!" );
			PrintToChat( id, "[DoD:S Medic] If you want to call a Medic, you must 'bind <key> voice_medic' and press that <key>!" );
		}
	}
}
public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gPluginEnabled ) == 1 )
	{	
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );

		MedicUsed[ id ] = 0;
	}
}
stock SetClientHealth( index, health )
{
	SetEntProp( index, Prop_Data, "m_iHealth", health );
	return 1;
}
stock SetClientScreenFade( index, red, green, blue, alpha, delay )
{
	new duration = delay * 1000;
	
	new  Handle:MsgFade = StartMessageOne( "Fade", index );
	BfWriteShort( MsgFade, 500 );
	BfWriteShort( MsgFade, duration );
	BfWriteShort( MsgFade, FFADE_IN );
	BfWriteByte( MsgFade, red );
	BfWriteByte( MsgFade, green );
	BfWriteByte( MsgFade, blue );	
	BfWriteByte( MsgFade, alpha );
	EndMessage();
}
