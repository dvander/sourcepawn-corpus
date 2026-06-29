#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo = 
{
	name = "Max Money After X Rounds",
	author = "RedSword / Bob Le Ponge",
	description = "Gives player max (or less) money every round after X rounds",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAX_CASH 16000
#define STR_ACCOUNT_PROP "m_iAccount"

//ConVars
new Handle:g_hMaxMoney;
new Handle:g_hMaxMoney_value;
new Handle:g_hMaxMoney_value_respect16k;
new Handle:g_hMaxMoney_verbose;

//Caching
new g_iMaxMoney;
new g_iMaxMoney_value;
new bool:g_bMaxMoney_value_respect16k;
new g_iMaxMoney_verbose;

//===== Forwards

public OnPluginStart()
{
	//CVars
	CreateConVar( "maxmoneyafterxroundsversion",
	PLUGIN_VERSION, 
	"Different Teams Start Money/Cash version", 
	FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hMaxMoney = CreateConVar( "sm_maxmoney",
	"2", 
	"A which round should the players get extra cash upon spawning ? 0=disable plugin, 1=pistol round, 2=after pistol round (default).", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	
	g_hMaxMoney_value = CreateConVar( "sm_maxmoney_value",
	"16000", 
	"How much to add to the player's money per round when he spawns, after <sm_maxmoney> rounds. Def. 16000.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0 );
	g_hMaxMoney_value_respect16k = CreateConVar( "sm_maxmoney_value_16k",
	"1", 
	"Respect 16k limit (if unsure, let '1') ?", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	g_hMaxMoney_verbose = CreateConVar( "sm_maxmoney_verbose",
	"1", 
	"Tell the player when they receive money? 1=Yes, 0=No. Def. 1.", 
		FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0 );
	
	AutoExecConfig(true, "maxmoneyafterxrounds");
	
	LoadTranslations( "maxmoneyafterxrounds.phrases" );
	
	//Hooks event
	HookEvent( "player_spawn", Event_PlayerSpawn );
	
	//Hooks ConVarChanges (caching)
	g_iMaxMoney = GetConVarInt( g_hMaxMoney );
	g_iMaxMoney_value = GetConVarInt( g_hMaxMoney_value );
	g_bMaxMoney_value_respect16k = GetConVarBool( g_hMaxMoney_value_respect16k );
	g_iMaxMoney_verbose = GetConVarInt( g_hMaxMoney_verbose );
	HookConVarChange( g_hMaxMoney, ConVarChange_MaxMoney );
	HookConVarChange( g_hMaxMoney_value, ConVarChange_MaxMoney_value );
	HookConVarChange( g_hMaxMoney_value_respect16k, ConVarChange_MaxMoney_value_16k );
	HookConVarChange( g_hMaxMoney_verbose, ConVarChange_MaxMoney_verbose );
}

//===== Events

public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_iMaxMoney && GetTeamScore( 2 ) + GetTeamScore( 3 ) + 1 >= g_iMaxMoney )
	{
		new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		if ( iClient && IsClientInGame( iClient ) )
		{
			new shouldHaveCash = GetEntProp( iClient, Prop_Send, STR_ACCOUNT_PROP ) + g_iMaxMoney_value;
			if ( shouldHaveCash > MAX_CASH && g_bMaxMoney_value_respect16k )
			{
				shouldHaveCash = MAX_CASH;
			}
			SetEntProp( iClient, Prop_Send, STR_ACCOUNT_PROP, shouldHaveCash);
			
			if ( g_iMaxMoney_verbose && GetClientTeam( iClient ) >= 2 )
			{
				PrintToChat( iClient, "\x04[SM] \x01%t", g_iMaxMoney_value >= MAX_CASH && g_bMaxMoney_value_respect16k ? "FullCash" : "SomeCash" );
			}
		}
	}
	
	return Action:Plugin_Continue;
}

//===== ConVarChanges

public ConVarChange_MaxMoney(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMaxMoney = GetConVarInt( g_hMaxMoney );
}
public ConVarChange_MaxMoney_value(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMaxMoney_value = GetConVarInt( g_hMaxMoney_value );
}
public ConVarChange_MaxMoney_value_16k(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bMaxMoney_value_respect16k = GetConVarBool( g_hMaxMoney_value_respect16k );
}
public ConVarChange_MaxMoney_verbose(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMaxMoney_verbose = GetConVarInt( g_hMaxMoney_verbose );
}