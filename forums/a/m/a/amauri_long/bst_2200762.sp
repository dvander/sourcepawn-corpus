#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombiereloaded>

#define PLUGIN_AUTHOR	"Amauri :) mapple"
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

new g_Time = 10;
new bool:g_RoundEnd = false;

new gPlayerMoney;


public Plugin:myinfo = 
{
	name = "boost Mapple",
	author = PLUGIN_AUTHOR,
	description = "Say !boost to buy a boost.",
	version = PLUGIN_VERSION,
	url = "www.mapple.com.net"
};

public OnPluginStart()
{
	RegConsoleCmd( "say", Command_BuyRedByll );
	RegConsoleCmd( "say_team", Command_BuyRedByll );
	
	CreateConVar( "redbull_version", PLUGIN_VERSION, "Red Bull: Source", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	gRedBullEnabled = CreateConVar( "redbull_enabled", "1" );
	gRedBullCost = CreateConVar( "redbull_cost", "8000" );
	gRedBullEffectTime = CreateConVar( "redbull_time", "6.0" );
	gRedBullHealth = CreateConVar( "redbull_health", "0" );
	gRedBullArmor = CreateConVar( "redbull_armor", "0" );
	gRedBullSpeed = CreateConVar( "redbull_speed", "2.0" );

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
public OnMapStart()
{
	AddFileToDownloadsTable("sound/zombie_plague/mario_boost1.wav");
	PrecacheSound("zombie_plague/mario_boost1.wav", true);
}
public OnTimeCvarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Time = GetConVarInt(cvar);
}
public Action:Command_BuyRedByll( id, args )
{
	decl String:Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!boost" ) || StrEqual( Said, "!bst" ) )
	{
		if( GetConVarInt( gRedBullEnabled ) == 0 )
		{
			PrintToChat( id, "\x01[BOOST] \x03The plugin is disaled!" );
			
			return Plugin_Continue;
		}
		
		if( !IsPlayerAlive( id ) )
		{
			PrintToChat( id, "\x01[BOOST] \x03Only alive players can buy a BOOST!" );
		
			return Plugin_Continue;
		}
		
		if( bUserHasRedBull[ id ] )
		{
			PrintToChat( id, "\x01[BOOST] \x03You already have BOOST effects on you." );
			
			return Plugin_Continue;
		}
		
		new money = GetClientMoney( id );
		new cost = GetConVarInt( gRedBullCost );
		
		if( money < cost )
		{
			PrintToChat( id, "\x01[BOOST] \x03You don't have enough money to buy a BOOST! You need %d$!", cost );
			return Plugin_Continue;
		}
	 
		if (ZR_IsClientZombie(id))
		{
		PrintToChat( id, "\x01[BOOST] \x03PORRA ZOMBIE NAO TEM !BoosT" );
		return Plugin_Continue;
		}
	
		bUserHasRedBull[ id ] = true;
		SetClientMoney( id, money - cost );
		CreateTimer( GetConVarFloat( gRedBullEffectTime ), RedBullEffectOff, id );

		SetEntPropFloat( id, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat( gRedBullSpeed ) );
		SetEntProp( id, Prop_Data, "m_iHealth", GetClientHealth( id ) + GetConVarInt( gRedBullHealth ) );
		SetEntProp( id, Prop_Data, "m_ArmorValue", GetClientArmor( id ) + GetConVarInt( gRedBullArmor ) );

		CreateTimer(0.5, Timer_COR, id, TIMER_REPEAT);
		EmitSoundToAll("zombie_plague/mario_boost1.wav");
		
	}
	
	return Plugin_Continue;
}
public Action:Timer_COR(Handle:timer, any:client)
{
static times = 0;
if (g_RoundEnd)
{
times = 0;
return Plugin_Stop;
}
if (times < g_Time)
	{
	//Defalt SetEntityRenderColor(client, 0, 0, 0, 0);//invisivel
	if(times<1){
	SetEntityRenderColor(client, 255, 255, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<2){
	SetEntityRenderColor(client, 250, 130, 0, 500);//cor
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);//ativa
	}else if(times<3){
	SetEntityRenderColor(client, 255, 120, 175, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<4){
	SetEntityRenderColor(client, 0, 255, 255, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<5){
	SetEntityRenderColor(client, 128, 0, 128, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<6){
	SetEntityRenderColor(client, 255, 255, 255, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<7){
	SetEntityRenderColor(client, 255, 0, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<8){
	SetEntityRenderColor(client, 0, 255, 0, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<9){
	SetEntityRenderColor(client, 0, 0, 255, 500);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}else if(times<10){
	SetEntityRenderColor(client, 0, 0, 0, 0);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}
	times++;
	}else{
		times = 0;
		SetEntityRenderColor(client, 255, 255, 255, 255);//visivel
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);//ativador
		return Plugin_Stop;
		}
return Plugin_Continue;
}
	
public Action:RedBullEffectOff( Handle:timer, any:id )
{
	bUserHasRedBull[ id ] = false;
	SetEntPropFloat( id, Prop_Data, "m_flLaggedMovementValue", 1.0 );
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


