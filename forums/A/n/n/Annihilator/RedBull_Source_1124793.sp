#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"tuty"
#define PLUGIN_VERSION	"1.1"
#define FFADE_IN  	0x0001
#pragma semicolon 1

new Handle:gRedBullEnabled = INVALID_HANDLE;
new Handle:gRedBullCost = INVALID_HANDLE;
new Handle:gRedBullEffectTime = INVALID_HANDLE;
new Handle:gRedBullHealth = INVALID_HANDLE;
new Handle:gRedBullArmor = INVALID_HANDLE;
new Handle:gRedBullSpeed = INVALID_HANDLE;
new bool:bUserHasRedBull[ 33 ];
new gPlayerMoney;

public Plugin:myinfo = 
{
	name = "Red Bull: Source",
	author = PLUGIN_AUTHOR,
	description = "Say !redbull to buy a redbull.",
	version = PLUGIN_VERSION,
	url = "www.ligs.us"
};
public OnPluginStart()
{
	RegConsoleCmd( "say", Command_BuyRedByll );
	RegConsoleCmd( "say_team", Command_BuyRedByll );
	
	CreateConVar( "redbull_version", PLUGIN_VERSION, "Red Bull: Source", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gRedBullEnabled = CreateConVar( "redbull_enabled", "1" );
	gRedBullCost = CreateConVar( "redbull_cost", "2000" );
	gRedBullEffectTime = CreateConVar( "redbull_time", "20.0" );
	gRedBullHealth = CreateConVar( "redbull_health", "50" );
	gRedBullArmor = CreateConVar( "redbull_armor", "50" );
	gRedBullSpeed = CreateConVar( "redbull_speed", "3.9" );

	gPlayerMoney = FindSendPropOffs( "CCSPlayer", "m_iAccount" );
	AutoExecConfig();
}	
public OnClientConnected( id )
{
	bUserHasRedBull[ id ] = false;
}
public OnClientDisconnect( id )
{
	bUserHasRedBull[ id ] = false;
}
public Action:Command_BuyRedByll( id, args )
{
	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!redbull" ) || StrEqual( Said, "!RedBull" ) )
	{
		if( GetConVarInt( gRedBullEnabled ) == 0 )
		{
			PrintToChat( id, "\x01[Red Bull: Source] \x03The plugin is disaled!" );
			
			return Plugin_Continue;
		}
		
		if( !IsPlayerAlive( id ) )
		{
			PrintToChat( id, "\x01[Red Bull: Source] \x03Only alive players can buy a RedBull!" );
		
			return Plugin_Continue;
		}
		
		if( bUserHasRedBull[ id ] )
		{
			PrintToChat( id, "\x01[Red Bull: Source] \x03You already have RedBull effects on you." );
			
			return Plugin_Continue;
		}
		
		new money = GetClientMoney( id );
		new cost = GetConVarInt( gRedBullCost );
		
		if( money < cost )
		{
			PrintToChat( id, "\x01[Red Bull: Source] \x03You don't have enough money to buy a RedBull! You need %d$!", cost );
			
			return Plugin_Continue;
		}
		
		bUserHasRedBull[ id ] = true;
		SetClientMoney( id, money - cost );
		CreateTimer( GetConVarFloat( gRedBullEffectTime ), RedBullEffectOff, id );

		SetEntPropFloat( id, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat( gRedBullSpeed ) );
		SetEntProp( id, Prop_Data, "m_iHealth", GetClientHealth( id ) + GetConVarInt( gRedBullHealth ) );
		SetEntProp( id, Prop_Data, "m_ArmorValue", GetClientArmor( id ) + GetConVarInt( gRedBullArmor ) );
		
		PrintToChat( id, "\x01[Red Bull: Source] \x03RedBull gives you wings!" );
		PrintToChat( id, "\x01[Red Bull: Source] \x03RedBull improves performance, especially during times of increases stress or strain!" );
		SetClientScreenFade( id, 6, 255, 0, 0, 100 );
	}
	
	return Plugin_Continue;
}		
public Action:RedBullEffectOff( Handle:timer, any:id )
{
	bUserHasRedBull[ id ] = false;
	SetClientScreenFade( id, 0, 0, 0, 0, 0 );
	SetEntPropFloat( id, Prop_Data, "m_flLaggedMovementValue", 1.0 );
	PrintToChat( id, "\x01[Red Bull: Source] \x03RedBull's effects are only temporary!" );
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
stock SetClientScreenFade( index, delay, red, green, blue, alpha )
{
	new duration = delay * 1000;
	
	new Handle:FadeMsg = StartMessageOne( "Fade", index );
	BfWriteShort( FadeMsg, 500 );
	BfWriteShort( FadeMsg, duration );
	BfWriteShort( FadeMsg, FFADE_IN );
	BfWriteByte( FadeMsg, red );
	BfWriteByte( FadeMsg, green );
	BfWriteByte( FadeMsg, blue );	
	BfWriteByte( FadeMsg, alpha );
	EndMessage();
}